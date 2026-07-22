# Case 04 — Solar Open2 x LangChain OpenWiki로 pilot-upstage-solar-open2 문서화

[English](README.md) / [한국어](README-ko.md)

[← 리포 개요로 돌아가기](../README.md) · 직접 실행해보고 싶다면?
[`REPRODUCE-ko.md`](REPRODUCE-ko.md)에서 단계별 로컬 실행 방법을
확인하세요.

**상태:** 검증 완료 — [`openwiki`](https://github.com/langchain-ai/openwiki)가
Upstage의 Solar Open2 모델로 구동되어 이 리포 자체에 대한 실제 질문에
답합니다. 그 과정에서 발견한 실제 스트리밍 버그를 고친 패치 빌드를
사용합니다.

## 목표

`openwiki`(코드베이스용 에이전트 읽기용 위키를 만들고 유지하는 CLI)를
평소의 Anthropic/OpenAI 기본값이 아닌 **Solar Open2**로 구동해, **이
리포 자체**(`pilot-upstage-solar-open2`)를 대상으로 최신 커밋을 문서화하고 질문에
답하게 합니다.

## 동작 원리

`openwiki`는 현재 작업 디렉토리를 대상으로 동작합니다 — 별도의 대상
경로 플래그 없이 그냥 원하는 체크아웃 안에서 `cd`한 뒤 실행하면 됩니다.

이 리포의 실제 루트를 건드리지 않기 위해(`AGENTS.md`에 블록 주입 없음,
`openwiki/` 폴더 생성 없음, 자동 PR 봇 없음)
[`scripts/verify.sh`](scripts/verify.sh)는 `pilot-upstage-solar-open2`를
git-ignore된 `scratch/` 디렉토리에 shallow clone한 뒤 그 안에서
`openwiki`를 실행합니다.

## 발견 1: `anthropic` provider로는 Solar Open2에 도달할 수 없음

`openwiki`는 `anthropic` provider를 지원하지만, 소스코드
(`src/agent/index.ts`)를 보면 `ChatAnthropic`을 `apiKey`(→ `x-api-key`
헤더)만으로 생성합니다. Case 01·02의 Python 도구들과 달리 `authToken`(→
`Authorization: Bearer`)은 전혀 보내지 않습니다.

직접 확인했습니다: raw `@anthropic-ai/sdk` JS 클라이언트로 `apiKey`만
사용해 Upstage의 Anthropic 호환 엔드포인트를 호출하니 **즉시 401
`invalid_api_key`**가 돌아왔습니다. 행이 아니라 명확한 거부입니다 —
Upstage의 Anthropic 호환 엔드포인트가 `x-api-key` 인증을 그냥
거부합니다. 현재 코드로는 확실한 막다른 길입니다.

**사용한 우회책:** 범용 `openai-compatible` provider — Bearer 인증
방식이라 Upstage의 OpenAI 호환 엔드포인트(Case 03에서 `ChatUpstage`가
쓴 것과 동일)와 정확히 맞습니다:

```bash
OPENWIKI_PROVIDER=openai-compatible
OPENAI_COMPATIBLE_API_KEY=$UPSTAGE_API_KEY
OPENAI_COMPATIBLE_BASE_URL=https://api.upstage.ai/v1/solar
OPENWIKI_MODEL_ID=solar-open2
```

## 발견 2: 스트리밍 시 Solar Open2가 tool_call의 function name을 누락함

`openai-compatible`로 바꾸는 것만으로는 부족했습니다. 툴을 쓰는
실행마다 `400 Invalid function name: ''`로 실패했습니다. Upstage API
앞에 작은 로컬 로깅 프록시를 두고 실제 와이어 트래픽을 추적했습니다:

- **요청**은 항상 `openwiki`의 16개 툴 이름이 전부 정확하게(`ls`,
  `read_file`, `write_file`, `task` 등) 담겨 있었습니다. 잘못된 요청이
  아니었습니다.
- **응답**(스트리밍)은 `ls` 툴에 맞는 인자(`{"path":"/"}`)를 담은 tool
  call을 돌려줬지만 `function.name`이 **비어 있었습니다**. `openwiki`는
  알 수 없는 `""` 툴을 정확히 거부하고 그 에러를 되돌려보냈는데,
  Upstage는 *다음* 턴에서 이를 거부했습니다. 대화 이력에 이름이 빈
  `tool_call`이 있으면 자체 스키마 검증에 걸리기 때문입니다.
- raw 최소 요청으로 더 좁혀봤습니다: 완전히 동일한 요청을 `stream:
  false`로 보내면 이름이 정확히(`"ls"`) 돌아옵니다. **스트리밍 응답에서만
  이름이 빠집니다.**

이건 `openwiki`나 `deepagents` 자체 코드 문제가 아니라 실제
Upstage/Solar Open2 스트리밍 버그입니다 — 어쩌면 클라이언트-서버 청킹
불일치일 수도 있지만, 어느 쪽이든 `openwiki`나 `deepagents` 쪽 코드
문제는 아닙니다. 다만 `openwiki`는 이 provider 경로에서 스트리밍을 끌
방법을 제공하지 않았습니다.

그래서 **포크에 작은 패치를 추가**했습니다(`jyje/openwiki`, 브랜치
`fix/disable-streaming-for-tool-calling-providers`): 새
`OPENWIKI_DISABLE_STREAMING=true` 환경변수가 범용 provider 분기의
`ChatOpenAI`에 `streaming: false`를 설정하도록 만들었습니다. 옵트인
방식이라 다른 모든 `openai-compatible` 계열 provider는 기존처럼
스트리밍을 유지합니다. 확인 결과, 이 플래그를 설정하면 동일하게
실패하던 요청이 이제 정확한 툴 이름과 함께 성공합니다.

## 발견 3: 전체 문서 생성은 기본 rate limit을 초과함

`openwiki code --update`(실제로 `openwiki/` 문서를 쓰는 명령)는 매 턴
큰(~57KB) 시스템 프롬프트를 보내고, 이 리포처럼 여러 Case가 있는
저장소를 탐색하려면 여러 번의 tool-calling 왕복이 필요합니다. 다른
트래픽과 무관하게 단일 실행만으로도 Upstage 기본 **분당 50,000 토큰**
rate limit을 초과하기 충분합니다.

이건 코드 버그가 아니라 용량/티어 제약입니다. `scripts/verify.sh`는
여전히 이를 시도(best-effort)하지만 통과 여부를 게이팅하지 않습니다 —
아래 3가지 질문(저렴하고 단일 턴인 호출)이 안정적으로 통과하는 핵심
체크입니다.

## 3가지 질문

`openwiki code -p "<question>"` 실행의 실제 답변입니다 — 손으로 고르거나
편집하지 않았습니다:

1. **"What is this repository (pilot-upstage-solar-open2) about?"**
2. **"What did the most recent commit change?"**
3. **"How many experiment cases does this repo have, and what does each one demonstrate?"**

## 검증된 방식

`verify.sh`의 실제 CI 실행 결과입니다 — 손으로 고르거나 편집하지
않았습니다. 직접 클릭해서 실행 로그를 확인할 수 있습니다:

**검증 실행:** [`verify` job, 2026-07-15](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29380954792/job/87244280144)
(또는 [모든 실행](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml) 목록에서 최신 것을 확인하세요)

| 질문 | 답변(잘린 미리보기) |
| --- | --- |
| Q1 — 이 리포는 무엇에 관한 것인가 | This repository (`jyje/pilot-upstage-solar-open2`, pilot-upstage-solar-open2) is a single repo hosting **three i ...(truncated) |
| Q2 — 최신 커밋이 무엇을 바꿨는가 | The most recent commit (`003c1a8`) is a large init-style commit that adds: - **Bug fix**: `warn()` i ...(truncated) |
| Q3 — 몇 개의 Case가 있고 각각 무엇을 보여주는가 | There are **4 experiment cases** in this repo. Let me read their detail pages to give you a full bre ...(truncated) |

[전체 출력 보기 →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29380954792/job/87244280144)

## 검증

[`scripts/verify.sh`](scripts/verify.sh)가 이 리포를 shallow clone한 뒤
위 3가지 질문에 `openwiki code -p`로 답하고(핵심 게이트), 전체 문서
생성도 `openwiki code --update`로 시도합니다(발견 3에 따라
best-effort).

[`jyje/openwiki`](https://github.com/jyje/openwiki/tree/fix/disable-streaming-for-tool-calling-providers)의
패치된 빌드가 필요합니다 — 공식 npm 배포판에는 아직 스트리밍 수정이
반영되지 않았습니다.

`UPSTAGE_API_KEY`를 설정하고 패치된 `openwiki`가 PATH에 있는 상태로
로컬에서 실행하세요:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

CI에서도 한 단계로 실행됩니다(수동 실행, `solar-open2`만):
[`.github/workflows/verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml) —
패치된 포크를 소스에서 빌드하며(`pnpm install && pnpm run build && npm
link`), 다른 모든 Case와 동일한 `UPSTAGE_API_KEY` 저장소 시크릿을
재사용합니다.

전체 맥락은 리포 레벨의 [`PLAN.md`](../PLAN.md)를 참고하세요.
