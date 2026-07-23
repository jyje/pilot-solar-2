# Case 06 — Solar Open 2 x Grok Build

[English](README.md) / [한국어](README-ko.md)

[← 리포 개요로 돌아가기](../README.md) · 직접 실행해보고 싶다면?
[`REPRODUCE-ko.md`](REPRODUCE-ko.md)에서 단계별 로컬 실행 방법을
확인하세요.

**상태:** 검증 완료 — [xAI의 Grok Build](https://github.com/xai-org/grok-build)
CLI가 커스텀 모델 provider로 Solar Open 2를 상대로 실제 응답을
생성하며, 아래 세 가지 방식 모두 CI를 통과합니다. 알려진 한계: 내장
tool-calling에서는
[Case 05의 Finding 2](../05-langchain-openwiki-solar-open2/README-ko.md#발견-2-스트리밍-시-solar-open-2가-tool_call의-function-name을-누락함)에서
문서화한 것과 동일한 Upstage 스트리밍 버그가 발생하며, Grok Build가
closed-source라 클라이언트 쪽 우회 방법이 없습니다.

## 목표

xAI의 새 터미널 코딩 에이전트 Grok Build(2026년 5월 출시)가 프로토콜
브리지 없이, 자체 문서화된 "임의의 커스텀 모델" 메커니즘만으로 **Solar
Open 2**를 모델로 실행할 수 있는지 확인하고, 되는 것과 안 되는 것을
정직하게 기록합니다.

## 동작 원리

Grok Build는 `$GROK_HOME/config.toml`(`$GROK_HOME`이 없으면
`~/.grok/config.toml`)에서 모델 정의를 읽습니다.

```toml
[model.solar-open2]
model = "solar-open2"
base_url = "https://api.upstage.ai/v1/solar"
name = "Solar Open 2 (Upstage)"
env_key = "UPSTAGE_API_KEY"
api_backend = "chat_completions"

[models]
default = "solar-open2"
```

핵심은 `api_backend = "chat_completions"`입니다. Responses API
프로토콜에 고정된 [Codex 초안](../draft/codex-upstage-solar-open2/README-ko.md)과
달리, Grok Build는 커스텀 모델마다 와이어 프로토콜
(`chat_completions`, `responses`, `messages`)을 직접 고를 수 있어서,
Upstage가 실제로 제공하는 OpenAI 호환 Chat Completions 포맷을 그대로
사용할 수 있습니다 — 브리지가 필요 없습니다.

## 발견: 커스텀 모델은 user-level 설정에서만 동작함

Grok Build는 프로젝트 로컬 `.grok/config.toml`도 인식하긴 하지만
(`grok inspect`로 확인함), 공식 문서에는
["프로젝트 설정은 MCP 서버·플러그인·권한 규칙으로만 한정되며, 전체 user 설정은 아니다"](https://docs.x.ai/build/settings)라고
명시돼 있습니다 — 거기에 `[model.X]` 항목을 넣어도 조용히 무시됩니다.
모델을 user-level `config.toml`로 옮기기 전까지는 `grok models`와 실제
`-p` 프롬프트 모두 계속 `unknown model id`를 반환했습니다.

**사용한 우회 방법:** 이 Case는 실제 `~/.grok`을 건드릴 수 없고 그래서도
안 되므로, [`scripts/verify.sh`](scripts/verify.sh)는 실행 동안만
`$GROK_HOME` 환경 변수를 임시 디렉터리로 돌려서 생성된
`config.toml`을 가리키게 합니다 — Case 02가 Hermes Agent의 홈
디렉터리를 격리하는 방식, Case 03이 `CODEX_HOME`을 쓰는 방식과 동일한
패턴입니다.

## 발견: tool-calling이 깨짐 — Case 05와 동일한 근본 원인

Grok Build의 내장 파일 도구로 로컬 파일을 읽어달라고 `solar-open2`에
요청하면 매번 이렇게 실패합니다.

```text
Internal error: {
  "message": "API error (status 400 Bad Request): invalid_request_error:
  Invalid function name: ''. Function names can only include
  alphanumeric characters (a-z, A-Z, 0-9), underscores (_), or hyphens
  (-), and should be no longer than 64 characters.",
  ...
}
```

이는 [Case 05의 Finding 2](../05-langchain-openwiki-solar-open2/README-ko.md#발견-2-스트리밍-시-solar-open-2가-tool_call의-function-name을-누락함)와
정확히 같은 시그니처입니다 — Upstage의 스트리밍 Chat Completions
응답이 tool call의 `function.name`을 누락시켜서, 클라이언트가 그
호출을 어디로도 라우팅하지 못합니다. Case 05는 `openwiki`가
오픈소스라서 우회할 수 있었습니다 — 작은 fork에 opt-in
`OPENWIKI_DISABLE_STREAMING` 플래그를 추가했습니다. Grok Build는
closed-source 컴파일 바이너리라 커스텀 provider에 그런 플래그가
노출돼 있지 않아서, 이 리포가 패치로 우회할 수 없는 확실한 막다른
길로 남습니다.

`scripts/verify.sh`는 이 체크를 매번 실제로 실행합니다(그래야 발견
사항이 정직하게 유지되고, Upstage가 언젠가 이 버그를 고치면 바로
알 수 있습니다) — 다만 이걸로 스크립트를 실패시키지는 않습니다. 아래
세 방식만 pass/fail을 결정합니다.

## 세 가지 방식

### 방식 A — 결정론적 단일 턴 응답

```bash
grok -p "Reply with exactly: grok-solar-ready" -m solar-open2
```

Grok Build의 headless 모드(`-p`)를 통한 순수 비-tool 왕복이며, 정확한
문자열로 확인합니다.

### 방식 B — 추론이 필요한 프롬프트

```bash
grok -p "Explain step by step why the sum of the first 50 positive integers equals 1275. Show your reasoning." -m solar-open2
```

툴을 전혀 쓰지 않으므로 위 스트리밍 버그의 영향을 받지 않습니다 —
Solar Open 2 자체의 추론만 확인하며, 정확한 숫자 답으로 검증합니다.

### 방식 C — 간단한 코딩 작업

```bash
grok -p "Write a Python function named is_prime(n) that returns True if n is a prime number and False otherwise. Include a brief docstring. Output only the code in a single fenced code block." -m solar-open2
```

Grok Build가 존재하는 실제 이유인 "코드 작성"을 확인합니다. 순수 텍스트
출력만 요청해서 tool-calling 버그의 영향을 받지 않습니다. 응답에
`def is_prime`가 있는지로 확인합니다.

## 검증된 방식

| 방식 | 결과 |
| --- | --- |
| A — 단일 턴 응답 | `grok-solar-ready` |
| B — 추론 프롬프트 | Gauss 공식과 페어링 방법 둘 다로 `1275`를 정확히 도출함(CI 출력 자체에 ~700자 전체 내용 포함) |
| C — 코딩 작업 | 정확하고 동작하는 `is_prime(n)` 구현 + docstring(전체 코드는 CI 출력에 포함) |
| 발견 — tool-calling | 재현 가능하게 실패함: `Invalid function name: ''` (Case 05와 동일한 버그) |

실제, 편집 없는 전체 내용은 아래 [증거 실행](#증거-실행)을 참고하세요.

## 검증

[`scripts/verify.sh`](scripts/verify.sh)가 `grok`을 Solar Open 2 상대로
세 번(방식 A, B, C 모두 게이트) headless로 실행하고, tool-use 발견
체크 하나를 게이트 없이 추가로 실행합니다. 방식 A의 응답에
`grok-solar-ready`가 없거나, 방식 B의 답변에 `1275`가 없거나, 방식
C의 코드에 `def is_prime`가 없을 때만 0이 아닌 코드로 종료합니다.

`UPSTAGE_API_KEY`를 설정하고 `grok`을 설치한 뒤
(`curl -fsSL https://x.ai/cli/install.sh | bash`) 로컬에서 실행하세요.

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

CI에서는 두 가지 방식으로 실행됩니다(둘 다 수동 실행, `solar-open2`만):
다른 모든 Case와 함께
[`verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml)의
한 스텝으로, 그리고 단독으로
[`verify-06-grok-build-solar-open2.yml`](../.github/workflows/verify-06-grok-build-solar-open2.yml)로 —
둘 다 동일한 `UPSTAGE_API_KEY` 저장소 시크릿을 재사용하고 `grok`을
공식 설치 스크립트로 설치합니다.

## 증거 실행

**증거 실행:** [`verify` job, 2026-07-23](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30018053983/job/89243180618),
이 Case 전용 단일 워크플로우
[`verify-06-grok-build-solar-open2.yml`](../.github/workflows/verify-06-grok-build-solar-open2.yml)로
실행했습니다(또는 최신 결과를 보려면
[전체 실행 목록](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-06-grok-build-solar-open2.yml)
참고). 실제, 편집 없는 출력입니다 — 손으로 고르거나 편집하지
않았습니다:

**방식 A**

> grok-solar-ready

**방식 B**

> This is a classic math problem! Let me walk through why the sum of
> the first 50 positive integers (1 + 2 + 3 + ... + 50) equals 1275.
>
> ## Step 1: Understand the problem
>
> We're summing: **1 + 2 + 3 + ... + 48 + 49 + 50**
>
> There are 50 terms total, and this is an arithmetic sequence where
> each term increases by 1.
>
> ## Step 2: Use the proven formula
>
> The sum of the first **n** positive integers has a well-known formula
> (discovered by Gauss as a child):
>
> $$S = \frac{n(n+1)}{2}$$
>
> This formula can be proven by pairing numbers from opposite ends of
> the sequence.
>
> ## Step 3: Apply the formula with n = 50
>
> $$S = \frac{50(50+1)}{2}$$
> $$S = \frac{50 \times 51}{2}$$
> $$S = \frac{2550}{2}$$
> $$S = 1275$$
>
> ...(truncated)

**방식 C**

> ```python
> def is_prime(n: int) -> bool:
>     """Return True if n is a prime number, False otherwise."""
>     if n < 2:
>         return False
>     if n == 2:
>         return True
>     if n % 2 == 0:
>         return False
>     for i in range(3, int(n**0.5) + 1, 2):
>         if n % i == 0:
>             return False
>     return True
> ```

**발견 체크 — tool-use (게이트 없음)**

> Internal error: {
>   "message": "API error (status 400 Bad Request):
>   invalid_request_error: Invalid function name: ''. Function names can
>   only include alphanumeric characters (a-z, A-Z, 0-9), underscores
>   (_), or hyphens (-), and should be no longer than 64 characters.",
>   "http_status": 400, ...
> }

전체 맥락은 리포 레벨의 [`PLAN.md`](../PLAN.md)를 참고하세요.
