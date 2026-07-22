# Case 04 — 유즈케이스 가이드

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← 이 케이스의 README로 돌아가기](README-ko.md) · [← 전체 케이스 유즈케이스 가이드](../docs/REPRODUCE-ko.md)

목표: `openwiki`로 이 리포 자체를 문서화하고 질문에 답하게 하되, Solar
Open2로 구동합니다.

전체 이야기, 발견 사항, 검증 로그: [`README-ko.md`](README-ko.md).

`UPSTAGE_API_KEY` 설정이나 공유 Tier-0 레이트리밋 설명을 아직 안 봤다면
[`docs/REPRODUCE-ko.md`](../docs/REPRODUCE-ko.md)를 먼저 읽어보세요 — 이
문서는 둘 다 이미 준비됐다고 가정합니다.

로컬에서 준비하기 가장 손이 많이 가는 케이스입니다. 공개 `openwiki`
릴리스에는 이 케이스에 필요한 수정이 아직 반영되지 않아서, 패치된 포크를
직접 빌드해야 합니다.

## 필요한 것

- `git`
- Node.js + `pnpm`
- 패치된 `openwiki` 빌드, `PATH`에 등록된 상태

## 패치된 `openwiki` 빌드하기

```bash
git clone https://github.com/jyje/openwiki.git
cd openwiki
git checkout fix/disable-streaming-for-tool-calling-providers
pnpm install
pnpm run build
npm link
```

올바른 빌드인지 확인:

```bash
openwiki --version
```

왜 굳이 포크가 필요할까요? Solar Open2는 **스트리밍** 응답에서 tool-call
함수 이름을 누락시킵니다. 공개 `openwiki`에는 스트리밍을 끄는 스위치가
없습니다. 이 포크는 그 스위치(`OPENWIKI_DISABLE_STREAMING=true`)를
추가합니다. 어떻게 이 문제를 진단했는지는
[`README-ko.md`](README-ko.md#발견-2-스트리밍-시-solar-open2가-tool_call의-function-name을-누락함)의
발견 2에 전체 추적 과정이 있습니다.

## 실행

리포 루트에서 먼저 이 디렉토리로 이동한 뒤, 스크립트를 실행하세요:

```bash
cd 04-langchain-openwiki-solar-open2
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

이 스크립트는 이 디렉토리 안의 gitignore된 `scratch/` 폴더로 리포를
shallow-clone한 뒤 그 안에서 `openwiki`를 실행합니다 — 실제 체크아웃,
그 안의 `AGENTS.md`, git 히스토리는 전혀 건드리지 않습니다.

## 성공했을 때 화면

세 개의 질문이 나오고 답이 달리는 것 — 이게 통과/실패를 가르는 핵심
게이트입니다:

```
== Question 1: What is this repository (pilot-upstage-solar-open2) about? ==
✓ question 1 answered
== Question 2: What did the most recent commit change? ==
✓ question 2 answered
== Question 3: How many experiment cases does this repo have, ... ==
✓ question 3 answered
✓ all 3 questions answered
...
✓ All checks passed (3-question Q&A gate).
```

세 질문 뒤에는 전체 문서 생성(`openwiki code --update`) 단계가
best-effort로 이어집니다. 이 단계는 실패해도 괜찮습니다 — Tier-0
계정에서는 이 단계 하나만으로 분당 토큰 예산을 다 써버리는 경우가
흔합니다. 여기서 `warn` 줄이 나오는 건 이 케이스가 잘못됐다는 뜻이
아닙니다.

## 문제가 생겼다면

- **`command not found: openwiki`** — 위의 `npm link` 단계가 `PATH`에
  제대로 반영되지 않았거나, 아직 링크를 인식하지 못한 셸에 있는
  것입니다. 셸을 새로 열거나 `npm root -g`를 확인하세요.
- **`400 Invalid function name: ''`** — 패치된 포크가 아니라 *패치되지
  않은* 공개 `openwiki`를 쓰고 있는 것입니다. 위의 포크 브랜치로 다시
  빌드하세요.
- **문서 생성 단계 실패/경고** — Tier-0 계정에서는
  [`README-ko.md`](README-ko.md)의 발견 3에 따라 예상된 동작입니다.
  스크립트 전체를 실패시키지 않습니다.
- **`solar-open2`가 아닌 `solar-pro3`가 타임아웃/레이트리밋에 걸린다** —
  [`PLAN.md`](../PLAN.md#case-04--solar-open2-x-langchain-openwiki)의
  Case 04, Finding 4에 따라 Tier 0에서는 예상된 동작입니다(영문). 이
  리포는 `solar-open2`만 검증합니다.
