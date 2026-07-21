# 케이스별 로컬 재현 가이드

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← 리포 개요로 돌아가기](../README-ko.md)

이 문서는 단계별 가이드입니다.

원하는 케이스 하나를 골라, 위에서 아래로 그대로 따라 하면 됩니다.

`PLAN.md`나 `AGENTS.md`를 먼저 읽지 않아도 됩니다.

각 케이스의 `README.md`/`README-ko.md`에는 더 자세한 이야기가 있습니다 —
발견 사항, 참고한 선행 사례, 실제 검증 로그까지.

이 문서는 딱 하나의 질문에만 답합니다. *지금, 내 컴퓨터에서, 어떻게 직접
돌려볼 수 있는가?*

## 시작하기 전에

### 1. Upstage API 키 발급

모든 케이스는 실제 Upstage API를 호출합니다.

모킹(mock)이나 오프라인 모드는 없습니다.

<https://console.upstage.ai/api-keys>에서 키를 발급받으세요.

셸 세션마다 한 번 export 해두면 됩니다:

```bash
export UPSTAGE_API_KEY="up_..."
```

이 키는 셸 히스토리에도, 커밋되는 파일에도 남기지 마세요.

각 케이스에는 필요한 변수 하나만 담은 `.env.sample`이 있습니다. export
대신 파일을 선호한다면 `.env`로 복사해서 로컬에서만 쓰세요 — 단, `.env`는
절대 커밋하지 마세요(리포 루트에서 이미 gitignore 처리되어 있습니다).

### 2. 공유 레이트리밋 이해하기

5개 케이스 모두 하나의 Upstage 계정을 공유합니다.

기본 계정 등급(**Tier 0**)은 Solar 챗 모델 기준 분당 100 요청, 분당
5만 토큰까지 허용합니다.

이 예산은 어떤 케이스를 돌리든 함께 소모됩니다.

케이스 하나만 단독으로 돌리면 한도에 걸릴 일은 거의 없습니다.

여러 케이스를 연달아 돌리면 얘기가 달라집니다.

아래 단계 중 어딘가에서 429 비슷한 에러나 레이트리밋 에러가 나면, 1분
정도 기다렸다가 다시 시도해보세요 — 어차피 각 케이스의 `verify.sh`는
이미 자동 재시도를 하도록 되어 있어서(5회, 30초 간격), 일시적인 실패라면
대부분 저절로 풀립니다.

전체 배경은 루트 [`README-ko.md`](../README-ko.md#티어-0-기준-검증--한계와-대처법)에,
그리고 각 케이스 시작 전에 예산이 완전히 리셋될 때까지 기다려주는 공유
래퍼 스크립트(`scripts/verify-case.sh`) — CI가 쓰는 것과 같은 안전장치 —
는 아래에서 다시 다룹니다.

### 3. 실행 방법 고르기

어떤 케이스든 두 가지 방법으로 돌릴 수 있습니다:

- **직접 실행** — 그 케이스의 `./scripts/verify.sh`를 바로 호출합니다.
  가장 빠르고, 추가 대기가 없습니다. 케이스 하나만 단독으로 돌릴 때
  적합합니다.
- **래퍼 경유** — 리포 루트에서 `./scripts/verify-case.sh <케이스-디렉토리>
  solar-open2`를 호출합니다. 시작 전에 레이트리밋이 완전히 리셋될 때까지
  먼저 기다립니다. 여러 케이스를 연달아 돌릴 계획이라면 이쪽이
  안전합니다.

```bash
# 직접 실행
UPSTAGE_API_KEY="..." ./01-solar-open2-harness/scripts/verify.sh

# 래퍼 경유 (리포 루트에서)
UPSTAGE_API_KEY="..." ./scripts/verify-case.sh 01-solar-open2-harness solar-open2
```

두 방법 모두 정확히 같은 검증을 실행합니다.

래퍼는 그 앞에 대기 시간만 하나 더할 뿐입니다.

---

## Case 01 — Solar Open2 x Claude Code

목표: Claude Code 자체를 Solar Open2로 구동하고, 커스텀 스킬과 서브에이전트가
이 백엔드에서도 그대로 동작하는지 확인합니다.

전체 이야기: [`01-solar-open2-harness/README-ko.md`](../01-solar-open2-harness/README-ko.md).

### 필요한 것

- Node.js 18 이상
- 공식 Claude Code CLI
- Upstage의 `claude-upstage` 래퍼

### 설치

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

```bash
curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh -s install
```

`sh`로 바로 실행하기 전에 스크립트를 먼저 읽어보고 싶다면:

```bash
curl -fsSL https://console.upstage.ai/claude-upstage.sh -o claude-upstage.sh
less claude-upstage.sh
sh claude-upstage.sh
```

### 실행

```bash
export UPSTAGE_API_KEY="up_..."
./01-solar-open2-harness/scripts/verify.sh
```

### 성공했을 때 화면

스크립트는 네 개의 체크 결과를 한 줄씩, 각각 `✓`로 시작하게 출력합니다:

```
✓ claude-upstage doctor
✓ Method A ...
✓ git-commit-helper skill format honored via solar-open2
✓ subagent call completed on solar-open2 and saw the real directory
✓ All checks passed.
```

### 문제가 생겼다면

- **`claude-upstage: unknown command '-p'`** — 예상된 동작이며, 이 리포의
  버그가 아닙니다. `claude-upstage`는 `-p`를 전달하지 않습니다. 스크립트는
  이미 표준입력을 파이프하는 방식(`echo "hello" | claude-upstage`)을 쓰고
  있습니다 — 직접 손으로 테스트할 때도 똑같이 하세요.
- **응답이 Solar Open2가 아닌 것 같다** — `ANTHROPIC_MODEL` 하나만이 아니라
  모든 `ANTHROPIC_*` 모델 슬롯 변수가 설정됐는지 확인하세요. 전체 목록은
  해당 케이스 README의 "How it works" 절을 참고하세요.

---

## Case 02 — Solar Open2 x Claude Agent SDK

목표: Python `claude-agent-sdk`로 Claude Code를 프로그래밍 방식으로
구동하며, Solar Open2를 상대로 동작을 확인합니다.

전체 이야기: [`02-claude-agent-sdk-local/README-ko.md`](../02-claude-agent-sdk-local/README-ko.md).

### 필요한 것

- [`uv`](https://docs.astral.sh/uv/)
- 공식 Claude Code CLI (Case 01과 설치 방법 동일)

### 실행

```bash
npm install -g @anthropic-ai/claude-code  # 아직 설치 안 했다면
export UPSTAGE_API_KEY="up_..."
./02-claude-agent-sdk-local/scripts/verify.sh
```

스크립트 내부에서 `uv run python demo.py`를 실행합니다 — 처음 실행할 때
`uv`가 프로젝트의 Python 의존성을 알아서 해석하고 설치해줍니다. 별도의
설치 단계는 필요 없습니다.

### 성공했을 때 화면

```
== Model under test: solar-open2 ==
== demo.py: Methods A/B/C against solar-open2 ==
...
✓ All checks passed.
```

### 문제가 생겼다면

- **호출이 멈추고 응답이 안 온다** — `ANTHROPIC_AUTH_TOKEN` 대신
  `ANTHROPIC_API_KEY`가 환경 어딘가에 설정돼 있다는 강력한 신호입니다.
  `verify.sh`는 이미 올바르게 설정하므로, 직접 `demo.py`를 자신의 환경으로
  돌릴 때만 해당됩니다.
- **`uv not found`** — [uv 문서](https://docs.astral.sh/uv/getting-started/installation/)를
  참고해 설치한 뒤 다시 실행하세요.

### 이 케이스를 변경하고 커밋하기 전에

```bash
cd 02-claude-agent-sdk-local
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

네 개 모두 통과해야 합니다.

---

## Case 03 — Solar Open2 x LangChain Deepagents

목표: `langchain-upstage`가 Solar Open2를 모델로 공급하는 `deepagents`
에이전트를 코드 레벨에서 초기화합니다 — 이 경로에는 `claude` CLI가
전혀 등장하지 않습니다.

전체 이야기: [`03-langchain-upstage-deepagents/README-ko.md`](../03-langchain-upstage-deepagents/README-ko.md).

### 필요한 것

- [`uv`](https://docs.astral.sh/uv/)
- Python 3.13 (이 케이스는 3.14가 아닌 3.13을 고정합니다 — 이유는 케이스
  README 참고. 없다면 `uv`가 알아서 준비해줍니다)

그 외엔 없습니다. Node도, `claude` CLI도 필요 없습니다.

### 실행

```bash
export UPSTAGE_API_KEY="up_..."
./03-langchain-upstage-deepagents/scripts/verify.sh
```

### 성공했을 때 화면

```
== Model under test: solar-open2 ==
== demo.py: Methods A/B/C against solar-open2 ==
...
✓ All checks passed.
```

### 문제가 생겼다면

- **`uv run` 중 `tokenizers` 관련 Rust 빌드 에러** — Python 3.14를 쓰고
  있을 가능성이 큽니다. 3.14를 강제하지 말고, `uv`가 고정해둔 3.13을
  그대로 쓰세요.

### 이 케이스를 변경하고 커밋하기 전에

```bash
cd 03-langchain-upstage-deepagents
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

네 개 모두 통과해야 합니다.

---

## Case 04 — Solar Open2 x LangChain OpenWiki

목표: `openwiki`로 이 리포 자체를 문서화하고 질문에 답하게 하되, Solar
Open2로 구동합니다.

전체 이야기: [`04-langchain-openwiki-solar-open2/README-ko.md`](../04-langchain-openwiki-solar-open2/README-ko.md).

로컬에서 준비하기 가장 손이 많이 가는 케이스입니다. 공개 `openwiki`
릴리스에는 이 케이스에 필요한 수정이 아직 반영되지 않아서, 패치된 포크를
직접 빌드해야 합니다.

### 필요한 것

- `git`
- Node.js + `pnpm`
- 패치된 `openwiki` 빌드, `PATH`에 등록된 상태

### 패치된 `openwiki` 빌드하기

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
추가합니다. 어떻게 이 문제를 진단했는지는 케이스 README의 Finding 2에
전체 추적 과정이 있습니다.

### 실행

```bash
export UPSTAGE_API_KEY="up_..."
./04-langchain-openwiki-solar-open2/scripts/verify.sh
```

이 스크립트는 `04-langchain-openwiki-solar-open2/` 안의 gitignore된
`scratch/` 폴더로 리포를 shallow-clone한 뒤 그 안에서 `openwiki`를
실행합니다 — 실제 체크아웃, 그 안의 `AGENTS.md`, git 히스토리는 전혀
건드리지 않습니다.

### 성공했을 때 화면

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

### 문제가 생겼다면

- **`command not found: openwiki`** — 위의 `npm link` 단계가 `PATH`에
  제대로 반영되지 않았거나, 아직 링크를 인식하지 못한 셸에 있는
  것입니다. 셸을 새로 열거나 `npm root -g`를 확인하세요.
- **`400 Invalid function name: ''`** — 패치된 포크가 아니라 *패치되지
  않은* 공개 `openwiki`를 쓰고 있는 것입니다. 위의 포크 브랜치로 다시
  빌드하세요.
- **문서 생성 단계 실패/경고** — Tier-0 계정에서는 케이스 README의
  Finding 3에 따라 예상된 동작입니다. 스크립트 전체를 실패시키지
  않습니다.
- **`solar-open2`가 아닌 `solar-pro3`가 타임아웃/레이트리밋에 걸린다** —
  Finding 4에 따라 Tier 0에서는 예상된 동작입니다. 이 리포는
  `solar-open2`만 검증합니다.

---

## Case 05 — Solar Open2 x Hermes Agent

목표: Hermes Agent에 내장된 자체 Upstage provider로, 공식 Docker
이미지를 통해 Solar Open2를 구동합니다 — 브리지도 프록시도 없이.

전체 이야기: [`05-hermes-agent-solar-open2/README-ko.md`](../05-hermes-agent-solar-open2/README-ko.md).

### 필요한 것

- Docker (데몬이 실행 중이어야 함)

이게 전부입니다. Node도, Python도, `openwiki`도 필요 없습니다.

### 실행

```bash
export UPSTAGE_API_KEY="up_..."
./05-hermes-agent-solar-open2/scripts/verify.sh
```

첫 실행에서는 digest로 고정된 `nousresearch/hermes-agent` 이미지를
받습니다 — 이 다운로드는 처음 한 번만 발생합니다.

### 성공했을 때 화면

```
== Model under test: solar-open2 ==
...
hermes-ready
✓ Hermes completed a live solar-open2 round trip
```

### 문제가 생겼다면

- **`Docker daemon is not available`** — Docker Desktop(또는 Docker
  서비스)을 실행한 뒤 다시 시도하세요.
- **이미지 받는 게 느리다** — 처음 실행이라면 정상입니다. digest로
  고정해뒀기 때문에 이후 실행은 같은 캐시 레이어를 재사용합니다.

### 직접 손으로 테스트해보기

이미지 검증이 끝났다면, 스크립트가 실행하는 것과 동일한 호출을 직접
원하는 프롬프트로 실행해볼 수 있습니다. Hermes는 파일 하나가 아니라
`/opt/data` 디렉토리 전체를 기대하므로, 먼저 디렉토리를 준비하세요:

```bash
hermes_home="$(mktemp -d)"
cp 05-hermes-agent-solar-open2/config.yaml "$hermes_home/config.yaml"
touch "$hermes_home/.env"
chmod 755 "$hermes_home"
chmod 644 "$hermes_home/config.yaml" "$hermes_home/.env"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e UPSTAGE_API_KEY \
  -v "$hermes_home:/opt/data" \
  --entrypoint hermes \
  nousresearch/hermes-agent@sha256:bb4d1e414918773b9c40e9a50582d582933beb85029b7050164d125f14e3f417 \
  chat --provider upstage --model solar-open2 \
  --query "Reply with exactly: hermes-ready" --max-turns 2 --quiet --ignore-rules

rm -rf "$hermes_home"
```

---

## CI처럼 5개를 순차로 전부 실행하기

CI와 동일한 순서로, 각 케이스가 시작 전에 레이트리밋이 완전히 리셋될
때까지 기다립니다:

```bash
export UPSTAGE_API_KEY="up_..."

for case in \
  01-solar-open2-harness \
  02-claude-agent-sdk-local \
  03-langchain-upstage-deepagents \
  04-langchain-openwiki-solar-open2 \
  05-hermes-agent-solar-open2
do
  ./scripts/verify-case.sh "$case" solar-open2
done
```

Tier-0 계정 기준 10~20분 이상 걸릴 수 있습니다.

이 시간의 대부분은 계산이 아니라 대기입니다 — 뭔가 멈춘 게 아니라, 각
케이스의 예산을 깨끗하게 유지하기 위한 대기입니다.

## 케이스 전반에 걸친 흔한 에러

두 개 이상의 케이스에서 공통으로 나타나는 에러를 표로 정리합니다:

| 증상 | 원인 | 해결 |
| --- | --- | --- |
| 호출이 멈추고 응답이 안 온다 | `ANTHROPIC_AUTH_TOKEN` 대신 `ANTHROPIC_API_KEY`가 설정됨 | 여기 있는 모든 `verify.sh`는 이미 올바르게 설정합니다 — 아래 도구를 직접 손으로 돌릴 때만 해당 |
| `429` 또는 레이트리밋 형태의 에러 | Tier-0의 공유 예산(분당 100 요청, 분당 5만 토큰) 소진 | 약 60초 기다렸다가 재시도하거나, 완전 리셋 대기가 내장된 `scripts/verify-case.sh`를 사용 |
| `UPSTAGE_API_KEY is not set` | 이번 셸에서 export를 깜빡함 | 명령 실행 전에 `export UPSTAGE_API_KEY="up_..."`, 새 셸을 열 때마다 |
| 어떤 스크립트든 `✗` 줄과 함께 종료 | 실패 이유가 바로 위 줄에 그대로 출력됨 | `✗` 바로 위 줄을 읽으세요 — 모든 스크립트는 실패하기 전에 실제 실패 응답을 그대로 출력합니다 |

## 더 보기

- [`README-ko.md`](../README-ko.md) — 리포 개요, 티어 0 레이트리밋 절,
  각 케이스가 왜 그 하네스에 잘 맞는지
- [`PLAN.md`](../PLAN.md) — 모든 케이스의 전체 계획과 발견 사항(영문)
- [`AGENTS.md`](../AGENTS.md) — 리포 구조와 컨벤션(영문)
- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — 코드 변경 컨벤션과 새 케이스
  추가 방법(영문)
