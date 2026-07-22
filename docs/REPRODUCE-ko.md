# 유즈케이스 가이드

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← 리포 개요로 돌아가기](../README-ko.md)

이 문서는 단계별 가이드입니다.

케이스마다 각자의 유즈케이스 가이드가 따로 있고, 아래에서 링크로
연결됩니다.

이 문서에서는 모든 케이스에 공통되는 부분만 다룹니다: API 키 발급,
공유 레이트리밋 이해, 실행 방법 선택. 이 문서를 한 번 읽고 나서, 원하는
케이스로 바로 넘어가세요.

각 케이스의 `README.md`/`README-ko.md`에는 더 자세한 이야기가 있습니다 —
발견 사항, 참고한 선행 사례, 실제 검증 로그까지. 유즈케이스 가이드는 딱
하나의 질문에만 답합니다. *지금, 내 컴퓨터에서, 어떻게 직접 돌려볼 수
있는가?*

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

어떤 케이스가 429 비슷한 에러나 레이트리밋 에러로 실패하면, 1분 정도
기다렸다가 다시 시도해보세요 — 어차피 각 케이스의 `verify.sh`는 이미
자동 재시도를 하도록 되어 있어서(5회, 30초 간격), 일시적인 실패라면
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

## 케이스별 유즈케이스 가이드

| Case | 목표 | 유즈케이스 가이드 |
| --- | --- | --- |
| Case 01 | Claude Code 자체를 Solar Open2로 구동 | [`01-solar-open2-harness/REPRODUCE-ko.md`](../01-solar-open2-harness/REPRODUCE-ko.md) |
| Case 02 | Claude Agent SDK로 Claude Code를 프로그래밍 방식 구동 | [`02-claude-agent-sdk-local/REPRODUCE-ko.md`](../02-claude-agent-sdk-local/REPRODUCE-ko.md) |
| Case 03 | `langchain-upstage`로 `deepagents`를 코드 레벨에서 초기화 | [`03-langchain-upstage-deepagents/REPRODUCE-ko.md`](../03-langchain-upstage-deepagents/REPRODUCE-ko.md) |
| Case 04 | `openwiki`가 이 리포를 문서화, Solar Open2로 구동 | [`04-langchain-openwiki-solar-open2/REPRODUCE-ko.md`](../04-langchain-openwiki-solar-open2/REPRODUCE-ko.md) |
| Case 05 | Hermes Agent 내장 Upstage provider, 공식 Docker 이미지 | [`05-hermes-agent-solar-open2/REPRODUCE-ko.md`](../05-hermes-agent-solar-open2/REPRODUCE-ko.md) |

각 문서 상단의 `[English]` 링크를 따라가면 영문판도 볼 수 있습니다.

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
