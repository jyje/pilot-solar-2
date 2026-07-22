# Case 01 — Use Case Guide

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← back to this case's README](README.md) · [← all cases' use case guides](../docs/REPRODUCE.md)

Goal: run Claude Code itself against Solar Open2, two independent ways
(Case 01A, Case 01B), and confirm its custom skills and subagents still
work through that backend.

Full narrative, findings, and verified transcripts: [`README.md`](README.md).

Haven't set up `UPSTAGE_API_KEY` or read about the shared Tier-0 rate
limit yet? Start at [`docs/REPRODUCE.md`](../docs/REPRODUCE.md) first —
this page assumes both are already handled.

`scripts/verify.sh` runs both sub-cases in one pass — there's no need to
pick just one to try locally.

## What you need

- Node.js 18+
- the official Claude Code CLI (Case 01A)
- Upstage's `claude-upstage` wrapper (Case 01B)

## Install — Case 01A: official Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

## Install — Case 01B: `claude-upstage` wrapper

```bash
curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh -s install
```

Prefer to read a script before piping it into `sh`? Fetch it first:

```bash
curl -fsSL https://console.upstage.ai/claude-upstage.sh -o claude-upstage.sh
less claude-upstage.sh
sh claude-upstage.sh
```

## Run it

From the repo root, `cd` into this directory first, then run its script:

```bash
cd 01-solar-open2-harness
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

## What success looks like

The script prints six checks, one per line, each starting with `✓` — the
first two cover Case 01B, the rest cover Case 01A:

```
✓ claude-upstage doctor passed
✓ claude-upstage (piped stdin) produced a response
✓ claude -p "hello" (official CLI, alternate API) produced a response
✓ git-commit-helper skill format honored via solar-open2
✓ subagent call completed on solar-open2 and saw the real directory
✓ All checks passed.
```

## If something goes wrong

- **`claude-upstage: unknown command '-p'`** — expected, and not a bug in
  this repo (Case 01B only). `claude-upstage` doesn't forward `-p`. The
  script already pipes stdin instead (`echo "hello" | claude-upstage`);
  if you're poking at it manually, do the same.
- **A response that isn't Solar Open2** — check every `ANTHROPIC_*`
  model-slot variable is set, not just `ANTHROPIC_MODEL` (Case 01A). See
  [`README.md`](README.md#how-it-works)'s Case 01A "How it works" section
  (English) or [`README-ko.md`](README-ko.md#동작-원리)'s Case 01A "동작
  원리" section (Korean) for the full list.
