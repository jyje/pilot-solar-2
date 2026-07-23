# Case 04 — Solar Open 2 x LangChain Deepagents

[English](README.md) / [한국어](README-ko.md)

[← back to repo overview](../README.md) · Want to run this yourself?
See [`REPRODUCE.md`](REPRODUCE.md) for step-by-step local setup.

**Status:** Verified — a `deepagents` agent initialized at the code level
with `langchain-upstage` as the model backend, against Upstage's Solar
Open 2 model. All three methods confirmed working end to end (locally and
in CI).

## Goal

Initialize a [`deepagents`](https://pypi.org/project/deepagents/) agent
purely at the code level, using
[`langchain-upstage`](https://pypi.org/project/langchain-upstage/) to
supply Solar Open 2 as the model. Unlike Case 01 and Case 03, there's no Claude Code
CLI involved anywhere in this path — this is LangChain/LangGraph talking
to Upstage directly.

## How it works

`ChatUpstage` (from `langchain-upstage`) is a thin `BaseChatOpenAI`
subclass pointed at Upstage's **OpenAI-compatible** endpoint
(`https://api.upstage.ai/v1/solar` by default) and reads `UPSTAGE_API_KEY`
from the environment automatically:

```python
from langchain_upstage import ChatUpstage
from deepagents import create_deep_agent

model = ChatUpstage(model="solar-open2")
agent = create_deep_agent(model=model, tools=[...], system_prompt="...")
agent.invoke({"messages": [{"role": "user", "content": "..."}]})
```

That's the whole auth story — no `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN`
dance, no `claude` CLI subprocess. Case 01 and Case 03 had to route through
Anthropic's Messages API wire format (Upstage exposes that compatibility
layer too, at a different host path). This case skips it entirely,
using Upstage's native OpenAI-compatible endpoint through the LangChain
integration Upstage itself publishes.

## Finding: Python 3.14 doesn't work here (yet)

This repo's other cases pin Python 3.14, but Case 04 pins **3.13**.

The cause, confirmed by actually trying it: `langchain-upstage` depends
on `tokenizers` (a Rust/PyO3 extension), and no `tokenizers` release —
checked `0.20.3` through the current `0.23.1` — ships a `cp314` wheel
yet. Building it from source also failed in this environment: a real
`cargo`/PyO3 compile error, not a missing-toolchain issue.

This is an upstream ecosystem gap, not something a config change can work
around. Case 04 will move back to 3.14 once `tokenizers` (or an
alternative Upstage integration that doesn't pull it in) supports it.

## Three methods

### Method A — tool use

```python
def get_weather(city: str) -> str:
    """Get the weather for a city."""
    return f"It is sunny in {city}."

agent = create_deep_agent(model=model, tools=[get_weather], ...)
agent.invoke({"messages": [{"role": "user", "content": "What is the weather in Seoul?"}]})
```

A plain custom tool the agent must call correctly to answer.

### Method B — deepagents' built-in virtual filesystem

```python
agent = create_deep_agent(model=model, system_prompt="...file tools...")
result = agent.invoke({"messages": [{"role": "user", "content":
    "Write the text HELLO-DEEPAGENTS to a file named note.txt using your file tools."}]})
result["files"]["/note.txt"]["content"]  # -> "HELLO-DEEPAGENTS"
```

`deepagents` ships a mock/virtual filesystem out of the box — no real
disk I/O, the file lives in the agent's state. Deterministic to check.

### Method C — subagent delegation

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

The main agent delegates arithmetic to a named subagent instead of doing
it itself — both the main agent and the subagent run on Solar Open 2.

## Verified methods

Real output from one CI run of `verify.sh` — `demo.py`'s own preview now
shows up to ~700 chars (10+ wrapped lines) instead of a single <=100-char
line, same as every other case. Not hand-picked or edited. Click through
to read the run yourself:

**Evidence run:** [`verify` job, 2026-07-23](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30008688179/job/89210972882)
(or browse [every run](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml) for the latest)

| Method | Result |
| --- | --- |
| A — tool use | `It's sunny in Seoul!` |
| B — virtual filesystem | `HELLO-DEEPAGENTS` (`result["files"]["/note.txt"]["content"]`) |
| C — subagent delegation | `17 + 25 = **42**` (from the `math-agent` subagent) |

[Full output →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30008688179/job/89210972882)

## Verification

[`scripts/verify.sh`](scripts/verify.sh) runs `src/demo.py`, which
executes all three methods for real against Solar Open 2. It exits
non-zero if any of them don't check out: Method A's answer missing
"sunny"/"Seoul", Method B's file content wrong, or Method C's reply
missing "42".

Python changes here go through the `python-lint` skill's workflow —
`ruff check`, `ruff format --check`, `ty check`, `pytest` — before
`verify.sh` runs, both locally and in CI.

Run locally with `UPSTAGE_API_KEY` set:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

Runs as a step in CI (manual dispatch, solar-open2 only):
[`.github/workflows/verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml) —
no Node/`claude`-CLI install step needed, unlike Case 01 and Case 03 — reusing the
same `UPSTAGE_API_KEY` repository secret.

See the repo-level [`PLAN.md`](../PLAN.md) for full context.
