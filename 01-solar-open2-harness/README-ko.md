# Case 01 — Solar Open2 x Claude Code

[English](README.md) / [한국어](README-ko.md)

[← 리포 개요로 돌아가기](../README.md) · 직접 실행해보고 싶다면?
[`REPRODUCE-ko.md`](REPRODUCE-ko.md)에서 단계별 로컬 실행 방법을
확인하세요.

**상태:** 검증 완료. Claude Code는 Upstage의 Solar Open2 모델 위에서 두
가지 독립된 방식으로 동작합니다 — 아래의 Case 01A와 Case 01B입니다.
커스텀 스킬 시스템과 서브에이전트/Task 호출도 같은 백엔드에서 잘
동작합니다. 이 네 가지 체크는 모두 로컬과 CI에서 end-to-end로
확인했습니다.

## 목표

Claude Code 하네스가 Anthropic 자체 모델이 아니라 Upstage의 **Solar
Open2** 모델로도 동작함을 보여주는 것이 목표입니다.

이를 위해 서로 독립된 두 가지 방식을 검증합니다. 각 방식은 아래에서 별도
서브 케이스로 다루며, 각자 자기만의 설치 방법과 검증 로그를 갖습니다:

- **[Case 01A](#case-01a--공식-claude-code-cli)** — **공식** `claude`
  CLI를 순수 환경변수만으로 설정합니다. 래퍼도, 프록시도 없습니다.
- **[Case 01B](#case-01b--claude-upstage-래퍼)** — Upstage 공식
  `claude-upstage` 편의 래퍼입니다.

이 리포의 커스텀 `.claude/skills/`와 서브에이전트/Task-tool 지원은 Case
01A의 설정을 기준으로 검증합니다. 자세한 내용은 해당 절에서 다룹니다.

두 서브 케이스 모두 <https://console.upstage.ai/api-keys>에서 발급받은
API 키가 필요합니다.

---

## Case 01A — 공식 Claude Code CLI

### 동작 원리

Upstage는 `https://api.upstage.ai`에서 Anthropic Messages API와 호환되는
엔드포인트를 제공합니다. 공식 `claude` CLI는 이미 환경변수만으로 임의의
Anthropic 호환 엔드포인트와 통신할 수 있습니다. 그래서 Anthropic 대신
Upstage를 바라보게 하는 건 다음과 같이 간단합니다:

```bash
export ANTHROPIC_BASE_URL="https://api.upstage.ai"
export ANTHROPIC_AUTH_TOKEN="$UPSTAGE_API_KEY"
export ANTHROPIC_MODEL="solar-open2"
export ANTHROPIC_SMALL_FAST_MODEL="solar-open2"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="solar-open2"
export ANTHROPIC_DEFAULT_SONNET_MODEL="solar-open2"
export ANTHROPIC_DEFAULT_OPUS_MODEL="solar-open2"
export ANTHROPIC_DEFAULT_FABLE_MODEL="solar-open2"
export CLAUDE_CODE_SUBAGENT_MODEL="solar-open2"

claude -p "hello"
```

Claude Code가 가진 모델 *슬롯*은 전부 `solar-open2`로 맞춰야 합니다.
Upstage는 이 모델 하나만 서빙하기 때문에, 매핑되지 않은 슬롯이 하나라도
있으면 백그라운드나 서브에이전트 호출이 백엔드에 없는 모델명을 요청할
위험이 있습니다.

이 중 두 변수는 Case 01B의 `claude-upstage` 래퍼가 채우지 못하는 빈틈을
메웁니다: `ANTHROPIC_DEFAULT_FABLE_MODEL`과
`CLAUDE_CODE_SUBAGENT_MODEL`입니다
([모델 설정 공식 문서](https://code.claude.com/docs/en/model-config#environment-variables)
참고). 래퍼 자체의 `set_claude_env`는 haiku/sonnet/opus/small-fast는
매핑하지만, `fable` 별칭과 서브에이전트 전용 변수보다 먼저 작성됐습니다.
그래서 `claude-upstage`만 거쳐 이루어지는 `fable` 별칭 호출이나
서브에이전트/Task-tool 호출은 Solar Open2로 간다는 보장이 없습니다.
아래의 스킬·서브에이전트 체크가 Case 01B의 래퍼가 아니라 Case 01A의
순수 환경변수 설정을 기준으로 돌아가는 이유 중 하나가 바로 이것입니다.

포크도, 패치도, 프록시도 없습니다. `@anthropic-ai/claude-code`의 순정
`claude` 바이너리는 그저 요청을 어디로 보낼지만 알려주면 됩니다.
`claude-upstage`(아래 Case 01B)는 이 변수들 대부분을 대신 설정해준 뒤
`claude`를 `exec`하는 편의 래퍼일 뿐입니다.

### 설치

Node.js 18+ 가 필요합니다:

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

이 리포는 버전을 고정하지 않습니다. 그래서 `npm install -g
@anthropic-ai/claude-code`는 항상 CI 실행 시점의 최신 버전을 설치합니다.
아래 검증 실행은 Claude Code CLI **v2.1.208**을 기준으로 검증했습니다.

### 검증: hello 체크

아래는 `verify.sh`의 실제 CI 실행 결과입니다. 스크립트가 출력하는 것과
동일하게 100자 이하로 truncate했으며, 손으로 고르거나 편집하지
않았습니다. 링크를 클릭하면 truncate되지 않은 전체 응답을 직접 확인할
수 있습니다:

**검증 실행:** [`verify` job, 2026-07-14](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)
(또는 최신 결과를 보려면 [전체 실행 목록](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml) 참고)

```bash
export ANTHROPIC_BASE_URL="https://api.upstage.ai"
export ANTHROPIC_AUTH_TOKEN="$UPSTAGE_API_KEY"
export ANTHROPIC_MODEL="solar-open2"
claude -p "hello"
```
> Hello! 👋 I'm ready to help you with your `pilot-upstage-solar-open2` project. This repo contains three agent-har ...(truncated)

[전체 출력 →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)

`scripts/verify.sh`에서는 이를 **방식 B**라고 부릅니다. 이 응답은 이
리포의 실제 `AGENTS.md`/상태를 읽고 답한 것이지, 정해진 답변이
아닙니다. Solar Open2가 단순 채팅 완성이 아니라 완전한 에이전틱 Claude
Code 하네스(툴 접근 포함)를 통해 응답한다는 뜻입니다.

### Solar Open2를 통한 스킬 동작

이 리포는 `.claude/skills/` 아래에 작은 커스텀 스킬 3종을 갖추고
있습니다. 하나는 README 헤더를 일관된 중앙 정렬 레이아웃으로
포맷합니다. 하나는 모든 커밋 메시지에 gitmoji + conventional-commit
스타일을 강제합니다. 나머지 하나는 Python 코드가 바뀔 때마다
lint/타입체크/테스트 워크플로우를 실행합니다.

이 스킬들은 Claude 모델뿐 아니라 Solar Open2가 모델일 때도 실제로
지켜질까요? `git-commit-helper`로 테스트했습니다. 이 스킬은 출력 형식이
엄격해서 기계적으로 검증하기 좋습니다: `<gitmoji> <type>(<domain>):
<title>`.

**발견: 자율적인 스킬 선택은 신뢰할 수 없지만, 명시적 호출은
신뢰할 수 있습니다.**

먼저 스킬명을 언급하지 않고 그냥 "커밋 메시지 써줘"라고
요청했습니다(자동 검증 스위트에는 포함되지 않은 1회성 수동 확인).
Solar Open2는 그럴듯해 보이는 메시지를 만들었지만, 필수 형식을 조용히
빠뜨렸습니다:

```bash
claude -p "Using this repo's git-commit-helper skill conventions, write \
  the commit message for a new file docs/hello.txt. Output only the \
  commit message."
```
> docs: add hello.txt greeting

gitmoji도 없고 `(domain)`도 없습니다. 프롬프트 문구에 "git-commit-helper"가
분명히 언급되어 있었는데도, 스킬의 필수 형식은 적용되지 않았습니다.

이번에는 같은 요청을 하되, 모델에게 그 스킬을 **사용하라고** 명시적으로
지시했습니다. `scripts/verify.sh`에서는 이를 **방식 C**라고 부르며,
CI에서 매번 실행됩니다(역시 Case 01A의 순수 환경변수 설정 기준입니다):

```bash
claude -p "Use the git-commit-helper skill. A new file docs/hello.txt \
  with a greeting was just added to this repo as a new doc. Write the \
  commit message per that skill's exact format (gitmoji + type(domain): \
  title). Output only the commit message."
```
> 📄 docs(docs): add greeting file

[전체 출력 →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)

스킬을 명시적으로 호출하니 정확합니다. gitmoji, type, `(domain):` 모두
있습니다.

두 프롬프트는 문구 차이가 작지만 결과 차이는 큽니다. Solar Open2는
스킬을 로드하라고 지시받으면 그 규약을 정확히 따릅니다. 하지만 주제가
스킬의 `description` 트리거 문구와 일치한다는 이유만으로 스스로 스킬
적용 여부를 판단하는 데는 신뢰도가 낮습니다 — Claude 모델이 흔히 하는
것과는 다릅니다.

**실전 팁:** Solar Open2에서 Claude Code를 운용할 때는 자동 트리거
문구 매칭에 기대지 마세요. 필요한 프롬프트에는 스킬명을 직접
언급하세요.

### 서브에이전트도 Solar Open2에서 동작

`CLAUDE_CODE_SUBAGENT_MODEL="solar-open2"`는 서브에이전트/Task-tool
호출(예: Explore 에이전트)을 Solar Open2에 계속 머물게 해줍니다. 이
변수가 없으면 SDK의 기본 서브에이전트 모델로 빠질 수 있습니다.

이 부분은 직접 검증했습니다. 하네스에게 파일 목록 작업을 Explore
서브에이전트에 맡기도록 요청했습니다. `scripts/verify.sh`에서는 이를
**방식 D**라고 부르며, 이 역시 Case 01A의 설정 기준입니다:

```bash
claude -p "Use the Explore agent (a subagent) to list every file \
  directly inside the current directory. Report just the file list."
```
> Files directly inside the current directory (`/home/runner/work/pilot-upstage-solar-open2/pilot-upstage-solar-open2/01-solar ...(truncated)

[전체 출력 →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)

보고된 경로는 CI 러너가 실제로 체크아웃한 이 디렉토리의 경로입니다.
서브에이전트 호출이 실제 파일시스템에 대해 실행됐고, 끝까지
`solar-open2`를 통해 라우팅됐다는 뜻입니다.

---

## Case 01B — `claude-upstage` 래퍼

### 동작 원리

`claude-upstage`는 `console.upstage.ai`에 게시된 Upstage 공식 편의
래퍼입니다. 자체 `set_claude_env`를 통해 Case 01A의 `ANTHROPIC_*` 변수
대부분을 대신 설정해준 뒤, 동일한 순정 `claude` 바이너리를 `exec`합니다.

`claude` 자체에 대한 포크도 패치도 없습니다. 이 래퍼는 Case 01A가 직접
바라보는 것과 동일한 엔드포인트에 도달하는, 조금 더 얇은 경로일
뿐입니다.

### 설치

```bash
# 설치 없이 1회 실행:
curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh

# 먼저 검토한 뒤 실행:
curl -fsSL https://console.upstage.ai/claude-upstage.sh -o claude-upstage.sh
less claude-upstage.sh && sh claude-upstage.sh

# ~/.local/bin에 설치해서 다음부터는 `claude-upstage`만 실행:
curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh -s install
```

`claude-upstage login`으로 OS 키체인에 API 키를 저장할 수 있습니다.
현재 셸에서만 쓸 거라면 `UPSTAGE_API_KEY`를 export하는 것으로
충분합니다.

`claude-upstage`는 자체 버전 번호가 없습니다. Upstage가
`console.upstage.ai`에서 계속 갱신하는 롤링 스크립트일 뿐, 고정된
릴리스가 아닙니다. Claude Code 자체를 설치하거나 번들링하지도
않습니다 — PATH에 이미 있는 `claude`를 확인해서 그 실행 파일을 그대로
`exec`할 뿐입니다. 그래서 Case 01A가 쓰는 로컬 Claude Code 설치본과
완전히 동일한 버전으로 동작합니다 — 비슷한 버전이 아니라 같은 파일,
같은 버전입니다. 아래 검증 실행 기준으로는 Claude Code CLI
**v2.1.208**이었습니다.

### 발견: `claude-upstage`는 `-p`를 전달하지 않음

하네스가 지원할 것으로 예상했던 형태 —
`claude-upstage -p "hello"` — 는 **실패**합니다:
`claude-upstage: unknown command '-p'`.

로컬에 설치된 사본과 `console.upstage.ai`에서 새로 받은 최신 스크립트
(한 줄만 다르고 나머지는 동일) 둘 다에서 확인했습니다. 그러니 오래된
설치본 문제가 아닙니다 — 래퍼의 인자 파서가 원래 그렇게 작성되어
있습니다. `claude-upstage`는 `--model`, `-c`/`--continue`,
`-r`/`--resume`만 `claude`로 전달합니다. 그 외에는 `claude`가 호출되기도
전에 거부됩니다.

non-interactive하게 동작하는 우회법도 있습니다: `-p`를 넘기는 대신
`claude-upstage`에 입력을 파이프하면 됩니다. stdin이 tty가 아니면, 내부
`claude` 프로세스는 이를 `-p`와 마찬가지로 단발성 프롬프트로 처리합니다:

```bash
echo "hello" | claude-upstage
```

### 검증: 파이프 stdin hello 체크

아래는 같은 CI 실행에서 나온 실제 `verify.sh` 결과입니다. 스크립트가
출력하는 것과 동일하게 100자 이하로 truncate했으며, 손으로 고르거나
편집하지 않았습니다:

**검증 실행:** [`verify` job, 2026-07-14](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)
(또는 최신 결과를 보려면 [전체 실행 목록](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml) 참고)

```bash
echo "hello" | claude-upstage
```
> Hello! 👋 How can I help you with the `pilot-upstage-solar-open2` project today? I can assist with the three inde ...(truncated)

[전체 출력 →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)

`scripts/verify.sh`에서는 이를 **방식 A**라고 부릅니다. 이 응답 역시
Case 01A와 마찬가지로 이 리포의 실제 `AGENTS.md`/상태를 읽고 답한
것입니다. 래퍼도 동일한 완전한 에이전틱 Claude Code 하네스에
도달합니다 — 단순 채팅 완성이 아닙니다.

---

## 검증

[`scripts/verify.sh`](scripts/verify.sh)는 두 서브 케이스와
스킬/서브에이전트 체크를 한 번에 실행합니다: `claude-upstage doctor`,
Case 01B의 파이프 stdin 체크(방식 A), Case 01A의 hello 체크(방식 B),
명시적 `git-commit-helper` 스킬 호출(방식 C), 그리고
`CLAUDE_CODE_SUBAGENT_MODEL`로 게이팅된 서브에이전트 호출(방식 D)까지
입니다. 하나라도 어긋나면 즉시 실패합니다.

스킬 체크는 정확한 문구를 고정하지 않습니다. 타이틀 텍스트는
결정론적이지 않기 때문입니다. 대신 스킬 형식 규약이 요구하는 두 가지
구조적 요소만 확인합니다: gitmoji(비-ASCII 바이트)와 `(domain):`
세그먼트입니다.

서브에이전트 체크는 이 디렉토리에 항상 존재하는 파일인 `README.md`가
서브에이전트 보고에 등장하는지를 확인합니다. "실제 파일시스템에 대해
실행되었다"는 것을 보여주는 결정론적 대용 지표입니다.

`UPSTAGE_API_KEY`를 설정하고 로컬에서 실행해보세요:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

CI에서도 한 단계로 실행됩니다(수동 실행, `solar-open2`만):
[`.github/workflows/verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml),
`UPSTAGE_API_KEY` 저장소 시크릿을 사용합니다.

전체 맥락은 리포 레벨의 [`PLAN.md`](../PLAN.md)를 참고하세요.
