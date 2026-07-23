# Case 03 — Solar Open 2 x Claude Agent SDK

[English](README.md) / [한국어](README-ko.md)

[← back to repo overview](../README.md) · Want to run this yourself?
See [`REPRODUCE.md`](REPRODUCE.md) for step-by-step local setup.

**Status:** Verified — a local Claude Code session driven entirely through
the Python Claude Agent SDK (`claude-agent-sdk`), against Upstage's Solar
Open 2 model. All three methods confirmed working end to end (locally and
in CI).

## Goal

Drive Claude Code **programmatically**, with no manual CLI interaction,
using the official Python `claude-agent-sdk`. Show what that actually
buys over Case 01's raw-CLI-plus-shell-script approach: **structured,
typed message objects** instead of scraping text out of stdout.

## How it works

`claude-agent-sdk` (PyPI, `pip install claude-agent-sdk` / here via
`uv add claude-agent-sdk`) drives the same `claude` CLI binary as a
subprocess. It's not a separate implementation, so the exact Solar Open 2
env var recipe verified in
[Case 01](../01-solar-open2-harness/README.md#how-it-works) still
applies — just passed through `ClaudeAgentOptions(env={...})` instead of
shell `export`:

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

## Finding: the SDK's own docs example doesn't work against Upstage

The [Python Agent SDK docs](https://code.claude.com/docs/en/agent-sdk/python)
show custom endpoints configured with `env={"ANTHROPIC_API_KEY": ...}`.
Tried verbatim against Upstage, that **hangs** — no message ever comes
back before timing out.

Swapping in `ANTHROPIC_AUTH_TOKEN` (the same variable Case 01 found the
plain CLI needs) works immediately. It's the same underlying cause as
Case 01's finding, seen from the other side: whatever `claude` expects
for a non-default auth source, it's `ANTHROPIC_AUTH_TOKEN`, not
`ANTHROPIC_API_KEY`. That holds however you launch `claude` — CLI flags
or SDK.

## Two entry points, three methods

`claude-agent-sdk` has two ways to drive a session:
[`query()`](https://code.claude.com/docs/en/agent-sdk/python) for one-off
calls, and `ClaudeSDKClient` for a session that keeps context across
multiple turns. Three methods, each proving something the other can't:

### Method A — `query()`, structured message types

```python
from claude_agent_sdk import AssistantMessage, TextBlock, query

async for message in query(prompt="hello", options=solar_options()):
    print(type(message).__name__)  # SystemMessage, AssistantMessage, ResultMessage, ...
```

Unlike Case 01's shell script, which had to grep/parse `claude`'s stdout
text, the SDK hands back typed Python objects (`SystemMessage`,
`AssistantMessage`, `ResultMessage`, with `TextBlock`/`ToolUseBlock`
content) — structure, not string-scraping.

### Method B — `ClaudeSDKClient`, session memory across turns

```python
async with ClaudeSDKClient(options=solar_options()) as client:
    await client.query("Remember the number 42. Reply with just OK.")
    async for _ in client.receive_response():
        pass
    await client.query("What number did I just ask you to remember?")
    # -> "42", from the *same* session, no restart
```

Deterministic and CI-checkable: turn 2 must contain "42", or the check
fails. This is what a retained session gets you that spawning a fresh
`claude -p` per question (Case 01's approach) cannot.

### Method C — tool-use visibility

```python
from claude_agent_sdk import AssistantMessage, ToolUseBlock, query

async for message in query(
    prompt="Use a tool to list the files in the current directory. Do not guess.",
    options=solar_options(cwd=os.getcwd()),
):
    if isinstance(message, AssistantMessage):
        for block in message.content:
            if isinstance(block, ToolUseBlock):
                ...  # a real tool call, seen as structured data
```

Asserts a `ToolUseBlock` actually appears in the message stream —
programmatic proof a tool call happened, not a string match on the reply.

## Verified methods

Real output from one CI run of `verify.sh` — `demo.py`'s own preview now
shows up to ~700 chars (10+ wrapped lines) instead of a single <=100-char
line, same as every other case. Not hand-picked or edited. Click through
to read the run yourself:

**Evidence run:** [`verify` job, 2026-07-23](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30008688179/job/89210972882)
(or browse [every run](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml) for the latest)

| Method | Result |
| --- | --- |
| A — `query()` | message types seen: `AssistantMessage`, `ResultMessage`, `SystemMessage`; reply: "Hello! How can I help you today?" (full reply, well under the new cap) |
| B — `ClaudeSDKClient` session memory | `42` (recalled correctly in turn 2) |
| C — tool-use visibility | `saw_tool_use=True` (a real `ToolUseBlock` appeared in the message stream) |

[Full output →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30008688179/job/89210972882)

## Verification

[`scripts/verify.sh`](scripts/verify.sh) runs `src/demo.py`, which
executes all three methods for real against Solar Open 2. It exits
non-zero if any of them don't check out: Method B's "42" missing, or
Method C seeing no `ToolUseBlock`.

Python changes here also go through the `python-lint` skill's workflow —
`ruff check`, `ruff format --check`, `ty check`, `pytest` — before
`verify.sh` runs, both locally and in CI.

Run locally with `UPSTAGE_API_KEY` set:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

Runs as a step in CI (manual dispatch, solar-open2 only):
[`.github/workflows/verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml),
reusing the same `UPSTAGE_API_KEY` repository secret Case 01 set up —
no new secret, no cost for a separate Anthropic key.

See the repo-level [`PLAN.md`](../PLAN.md) for full context.
