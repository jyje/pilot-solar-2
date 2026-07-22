# Case 02 — Use Case Guide

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← back to this case's README](README.md) · [← all cases' use case guides](../docs/REPRODUCE.md)

Goal: drive Claude Code programmatically through the Python
`claude-agent-sdk`, against Solar Open2.

Full narrative, findings, and verified transcripts: [`README.md`](README.md).

Haven't set up `UPSTAGE_API_KEY` or read about the shared Tier-0 rate
limit yet? Start at [`docs/REPRODUCE.md`](../docs/REPRODUCE.md) first —
this page assumes both are already handled.

## What you need

- [`uv`](https://docs.astral.sh/uv/)
- the official Claude Code CLI (same install as [Case 01A](../01-solar-open2-harness/REPRODUCE.md#install--case-01a-official-claude-code-cli))

## Run it

From the repo root, `cd` into this directory first, then run its script:

```bash
cd 02-claude-agent-sdk-local
npm install -g @anthropic-ai/claude-code  # if not already installed
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

The script runs `uv run python demo.py` under the hood — `uv` resolves
and installs the project's Python dependencies on first run automatically.
No separate install step needed.

## What success looks like

```
== Model under test: solar-open2 ==
== demo.py: Methods A/B/C against solar-open2 ==
...
✓ All checks passed.
```

## If something goes wrong

- **The call hangs, never returns** — a strong sign `ANTHROPIC_API_KEY`
  is set somewhere in your environment instead of `ANTHROPIC_AUTH_TOKEN`.
  `verify.sh` sets this correctly already; only relevant if you're
  running `demo.py` directly with your own env.
- **`uv not found`** — install it per the
  [uv docs](https://docs.astral.sh/uv/getting-started/installation/),
  then re-run.

## Before committing a change here

```bash
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

All four must pass.
