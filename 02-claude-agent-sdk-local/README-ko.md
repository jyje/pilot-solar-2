# Case 02 — Solar Open2 x Claude Agent SDK

[English](README.md) / [한국어](README-ko.md)

[← 리포 개요로 돌아가기](../README.md) · 직접 실행해보고 싶다면?
[`REPRODUCE-ko.md`](REPRODUCE-ko.md)에서 단계별 로컬 실행 방법을
확인하세요.

**상태:** 검증 완료 — Python Claude Agent SDK(`claude-agent-sdk`)만으로
로컬 Claude Code 세션을 완전히 프로그래밍 방식으로 실행하며, Upstage의
Solar Open2 모델을 기반으로 합니다. 3가지 방식 모두 로컬과 CI에서
종단 간 검증되었습니다.

## 목표

터미널에서 CLI를 직접 조작하지 않고, 공식 Python `claude-agent-sdk`만으로 Claude Code를
**프로그래밍 방식**으로 실행하며, 이것이 Case 01의 원시 CLI + 셸 스크립트
방식 대비 실제로 무엇을 가져다주는지 보여줍니다: stdout 텍스트를
파싱하거나 텍스트 기반으로 추출하는 대신 **구조화된, 타입이 있는 메시지 객체**를 받는다는 점입니다.

## 동작 원리

`claude-agent-sdk`(PyPI, `pip install claude-agent-sdk` / 이 리포에서는
`uv add claude-agent-sdk`)는 동일한 `claude` CLI 바이너리를 서브프로세스로
실행됩니다. 별도 구현체가 아니므로, [Case 01](../01-solar-open2-harness/README-ko.md#동작-원리)에서
검증한 Solar Open2 env var 레시피가 그대로 적용됩니다 — 셸 `export` 대신
`ClaudeAgentOptions(env={...})`로 전달할 뿐입니다:

```python
from claude_agent_sdk import ClaudeAgentOptions

options = ClaudeAgentOptions(
    model="solar-open2",
    env={
        "ANTHROPIC_BASE_URL": "https://api.upstage.ai",
        "ANTHROPIC_AUTH_TOKEN": upstage_api_key,
    },
)
```

## 발견: SDK 공식 문서의 예제가 Upstage에서는 동작하지 않음

[Python Agent SDK 문서](https://code.claude.com/docs/en/agent-sdk/python)는
커스텀 엔드포인트를 `env={"ANTHROPIC_API_KEY": ...}`로 설정하는 예시를
보여줍니다. 이를 Upstage 대상으로 그대로 시도하면 **행(hang)**이
걸립니다 — 타임아웃 전까지 어떤 메시지도 돌아오지 않습니다.

`ANTHROPIC_AUTH_TOKEN`(Case 01에서 순정 CLI에 필요하다고 확인한 것과
동일한 변수)으로 바꾸면 즉시 동작합니다. Case 01의 발견과 근본 원인이
같고, 이번엔 반대편(SDK)에서 확인된 것뿐입니다. `claude`가 비-기본
인증 소스에 기대하는 것은 `ANTHROPIC_API_KEY`가 아니라
`ANTHROPIC_AUTH_TOKEN`입니다. CLI 플래그로 실행하든 SDK로 실행하든
동일하게 적용됩니다.

## 두 가지 진입점, 세 가지 방식

`claude-agent-sdk`는 세션을 실행하는 두 가지 방법을 제공합니다:
단발성 호출을 위한 [`query()`](https://code.claude.com/docs/en/agent-sdk/python)와,
여러 턴에 걸쳐 컨텍스트를 유지하는 `ClaudeSDKClient`. 각각 다른 것을
증명하는 세 가지 방식을 검증합니다:

### 방식 A — `query()`, 구조화된 메시지 타입

```python
from claude_agent_sdk import AssistantMessage, TextBlock, query

async for message in query(prompt="hello", options=solar_options()):
    print(type(message).__name__)  # SystemMessage, AssistantMessage, ResultMessage, ...
```

`claude`의 stdout 텍스트를 grep/파싱해야 했던 Case 01의 셸 스크립트와
달리, SDK는 타입이 있는 파이썬 객체(`SystemMessage`, `AssistantMessage`,
`ResultMessage`, 그 안의 `TextBlock`/`ToolUseBlock` 콘텐츠)를 그대로
돌려줍니다 — 문자열 스크래핑이 아니라 구조입니다.

### 방식 B — `ClaudeSDKClient`, 턴 간 세션 메모리

```python
async with ClaudeSDKClient(options=solar_options()) as client:
    await client.query("Remember the number 42. Reply with just OK.")
    async for _ in client.receive_response():
        pass
    await client.query("What number did I just ask you to remember?")
    # -> "42", 재시작 없이 *같은* 세션에서
```

결정론적이라 CI에서 체크하기 좋습니다: 두 번째 턴 응답에 "42"가 없으면
바로 실패합니다. 질문마다 새 `claude -p`를 띄우는 Case 01 방식으로는 얻을
수 없는, 유지되는 세션만의 이점입니다.

### 방식 C — 툴 사용 가시성

```python
from claude_agent_sdk import AssistantMessage, ToolUseBlock, query

async for message in query(
    prompt="Use a tool to list the files in the current directory. Do not guess.",
    options=solar_options(cwd=os.getcwd()),
):
    if isinstance(message, AssistantMessage):
        for block in message.content:
            if isinstance(block, ToolUseBlock):
                ...  # 실제 툴 호출이 구조화된 데이터로 보임
```

메시지 스트림에 `ToolUseBlock`이 실제로 등장하는지 단언합니다 —
답변 텍스트에 대한 문자열 매칭이 아니라, 툴 호출이 일어났다는
프로그래밍적 증거입니다.

## 검증된 방식

아래는 `verify.sh`의 실제 CI 실행 결과(스크립트가 출력하는 것과 동일하게
100자 이하로 truncate됨)이며, 손으로 고르거나 편집하지 않았습니다.
링크를 클릭하면 truncate되지 않은 전체 응답을 직접 확인할 수 있습니다:

**검증 실행:** [`verify` job, 2026-07-14](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29306803664/job/87001673982)
(또는 최신 결과를 보려면 [전체 실행 목록](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml) 참고)

| 방식 | 결과 |
| --- | --- |
| A — `query()` | 확인된 메시지 타입: `SystemMessage`, `AssistantMessage`, `ResultMessage`; 응답: "Hello! I'm Solar Open2, an AI assistant trained by Upstage AI (a Korean startup). Nice to meet you!  ...(truncated)" |
| B — `ClaudeSDKClient` 세션 메모리 | `42` (두 번째 턴에서 정확히 회상함) |
| C — 툴 사용 가시성 | `saw_tool_use=True` (메시지 스트림에 실제 `ToolUseBlock`이 등장함) |

[전체 출력 →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29306803664/job/87001673982)

## 검증

[`scripts/verify.sh`](scripts/verify.sh)가 `src/demo.py`를 실행하며,
이는 Solar Open2를 대상으로 세 가지 방식을 실제로 실행합니다. 하나라도
어긋나면(방식 B에서 "42"가 빠지거나, 방식 C에서 `ToolUseBlock`을 보지
못하면) 즉시 실패합니다.

이 디렉토리의 파이썬 변경 사항은 `verify.sh` 실행 전에 `python-lint`
스킬의 절차(`ruff check`, `ruff format --check`, `ty check`, `pytest`)도
로컬과 CI 모두에서 거칩니다.

`UPSTAGE_API_KEY`를 설정하고 로컬에서 실행하세요:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

CI에서도 한 단계로 실행됩니다(수동 실행, `solar-open2`만):
[`.github/workflows/verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml),
Case 01에서 만들어둔 동일한 `UPSTAGE_API_KEY` 저장소 시크릿을 재사용합니다 —
새 시크릿도, 별도 Anthropic 키 비용도 필요 없습니다.

전체 맥락은 리포 레벨의 [`PLAN.md`](../PLAN.md)를 참고하세요.
