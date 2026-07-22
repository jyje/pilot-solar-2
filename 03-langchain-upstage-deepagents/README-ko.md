# Case 03 — Solar Open2 x LangChain Deepagents

[English](README.md) / [한국어](README-ko.md)

[← 리포 개요로 돌아가기](../README.md) · 직접 실행해보고 싶다면?
[`REPRODUCE-ko.md`](REPRODUCE-ko.md)에서 단계별 로컬 실행 방법을
확인하세요.

**상태:** 검증 완료 — `langchain-upstage`를 모델 백엔드로 사용해 코드
레벨에서 `deepagents` 에이전트를 초기화했으며, Upstage의 Solar Open2
모델을 대상으로 합니다. 3가지 방식 모두 로컬과 CI에서 end-to-end로
확인되었습니다.

## 목표

[`deepagents`](https://pypi.org/project/deepagents/) 에이전트를 순수
코드 레벨에서 초기화하되, [`langchain-upstage`](https://pypi.org/project/langchain-upstage/)로
Solar Open2를 모델로 공급합니다. Case 01·02와 달리 이 경로에는 Claude Code
CLI가 전혀 관여하지 않습니다 — LangChain/LangGraph가 Upstage와 직접
통신합니다.

## 동작 원리

`langchain-upstage`의 `ChatUpstage`는 Upstage의 **OpenAI 호환**
엔드포인트(기본값 `https://api.upstage.ai/v1/solar`)를 바라보는 얇은
`BaseChatOpenAI` 서브클래스이며, `UPSTAGE_API_KEY`를 환경변수에서
자동으로 읽습니다:

```python
from langchain_upstage import ChatUpstage
from deepagents import create_deep_agent

model = ChatUpstage(model="solar-open2")
agent = create_deep_agent(model=model, tools=[...], system_prompt="...")
agent.invoke({"messages": [{"role": "user", "content": "..."}]})
```

인증 관련해서는 이게 전부입니다 — `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN`
설정도, `claude` CLI 서브프로세스도 필요 없습니다. Case 01·02는 Anthropic
Messages API 와이어 포맷을 거쳐야 했습니다(Upstage가 다른 호스트
경로에서 이 호환 레이어도 제공하긴 합니다). 이번 케이스는 Upstage가
직접 공개한 LangChain 통합을 통해 Upstage 네이티브 OpenAI 호환
엔드포인트를 사용해 그 과정을 완전히 건너뜁니다.

## 발견: Python 3.14는 아직 여기서 동작하지 않음

이 리포의 다른 케이스들은 Python 3.14를 고정하지만, Case 03은 **3.13**을
고정합니다.

실제로 시도해서 확인한 원인은 이렇습니다: `langchain-upstage`가
`tokenizers`(Rust/PyO3 익스텐션)에 의존하는데, `0.20.3`부터 최신
`0.23.1`까지 확인해봐도 어떤 `tokenizers` 릴리스도 아직 `cp314` wheel을
제공하지 않습니다. 이 환경에서 소스 빌드도 실패했습니다 — 툴체인 누락이
아니라 실제 `cargo`/PyO3 컴파일 에러입니다.

설정으로 우회할 수 있는 문제가 아니라 업스트림 생태계의 공백입니다.
`tokenizers`가 지원하거나(또는 이를 끌어오지 않는 대체 Upstage 통합이
나오면) Case 03도 3.14로 돌아갈 예정입니다.

## 세 가지 방식

### 방식 A — 툴 사용

```python
def get_weather(city: str) -> str:
    """Get the weather for a city."""
    return f"It is sunny in {city}."

agent = create_deep_agent(model=model, tools=[get_weather], ...)
agent.invoke({"messages": [{"role": "user", "content": "What is the weather in Seoul?"}]})
```

에이전트가 정확히 답하려면 반드시 호출해야 하는 평범한 커스텀 툴입니다.

### 방식 B — deepagents 내장 가상 파일시스템

```python
agent = create_deep_agent(model=model, system_prompt="...파일 툴...")
result = agent.invoke({"messages": [{"role": "user", "content":
    "Write the text HELLO-DEEPAGENTS to a file named note.txt using your file tools."}]})
result["files"]["/note.txt"]["content"]  # -> "HELLO-DEEPAGENTS"
```

`deepagents`는 기본적으로 모의/가상 파일시스템을 제공합니다 — 실제 디스크
I/O 없이 에이전트 상태 안에 파일이 존재합니다. 결정론적으로 검증하기
좋습니다.

### 방식 C — 서브에이전트 위임

```python
subagents = [{
    "name": "math-agent",
    "description": "Use this subagent for any arithmetic/math task.",
    "system_prompt": "You are a math specialist. Use the add_numbers tool.",
    "tools": [add_numbers],
}]
agent = create_deep_agent(model=model, subagents=subagents, ...)
agent.invoke({"messages": [{"role": "user", "content":
    "Use the math-agent subagent to compute 17 + 25, then tell me the result."}]})
```

메인 에이전트가 산수를 직접 하지 않고 이름이 지정된 서브에이전트에
위임합니다 — 메인 에이전트와 서브에이전트 모두 Solar Open2에서
동작합니다.

## 검증된 방식

아래는 `verify.sh`의 실제 CI 실행 결과이며, 손으로 고르거나 편집하지
않았습니다. 링크를 클릭하면 실행 자체를 직접 확인할 수 있습니다:

**검증 실행:** [`verify` job, 2026-07-14](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29313121694/job/87021080894)
(또는 최신 결과를 보려면 [전체 실행 목록](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml) 참고)

| 방식 | 결과 |
| --- | --- |
| A — 툴 사용 | `It is sunny in Seoul.` |
| B — 가상 파일시스템 | `HELLO-DEEPAGENTS` (`result["files"]["/note.txt"]["content"]`) |
| C — 서브에이전트 위임 | `17 + 25 = 42` (`math-agent` 서브에이전트로부터) |

[전체 출력 →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29313121694/job/87021080894)

## 검증

[`scripts/verify.sh`](scripts/verify.sh)가 `src/demo.py`를 실행하며,
이는 Solar Open2를 대상으로 세 가지 방식을 실제로 실행합니다. 하나라도
어긋나면(방식 A의 답변에 "sunny"/"Seoul"이 없거나, 방식 B의 파일 내용이
틀리거나, 방식 C의 응답에 "42"가 없으면) 즉시 실패합니다.

이 디렉토리의 파이썬 변경 사항은 `verify.sh` 실행 전에 `python-lint`
스킬의 절차(`ruff check`, `ruff format --check`, `ty check`, `pytest`)도
로컬과 CI 모두에서 거칩니다.

`UPSTAGE_API_KEY`를 설정하고 로컬에서 실행하세요:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

CI에서도 한 단계로 실행됩니다(수동 실행, `solar-open2`만):
[`.github/workflows/verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml) —
Case 01·02와 달리 Node/`claude` CLI 설치 과정이 필요 없습니다 — 동일한
`UPSTAGE_API_KEY` 저장소 시크릿을 재사용합니다.

전체 맥락은 리포 레벨의 [`PLAN.md`](../PLAN.md)를 참고하세요.
