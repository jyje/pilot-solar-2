# Case 03 — Use Case Guide

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← back to this case's README](README.md) · [← all cases' use case guides](../docs/REPRODUCE.md)

Goal: initialize a `deepagents` agent at the code level, with
`langchain-upstage` supplying Solar Open2 as the model — no `claude` CLI
anywhere in this path.

Full narrative, findings, and verified transcripts: [`README.md`](README.md).

Haven't set up `UPSTAGE_API_KEY` or read about the shared Tier-0 rate
limit yet? Start at [`docs/REPRODUCE.md`](../docs/REPRODUCE.md) first —
this page assumes both are already handled.

## What you need

- [`uv`](https://docs.astral.sh/uv/)
- Python 3.13 (this case pins 3.13, not 3.14 — see [`README.md`](README.md#finding-python-314-doesnt-work-here-yet)
  for why; `uv` provisions it automatically if you don't have it)

Nothing else. No Node, no `claude` CLI.

## Run it

From the repo root, `cd` into this directory first, then run its script:

```bash
cd 03-langchain-upstage-deepagents
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

## What success looks like

```
== Model under test: solar-open2 ==
== demo.py: Methods A/B/C against solar-open2 ==
...
✓ All checks passed.
```

## If something goes wrong

- **A `tokenizers`/Rust build error during `uv run`** — you're likely on
  Python 3.14. Let `uv` use the pinned 3.13 instead of overriding it;
  don't try to force 3.14 here yet.

## Before committing a change here

```bash
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

All four must pass.
