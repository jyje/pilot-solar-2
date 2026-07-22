# Case 04 — Use Case Guide

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← back to this case's README](README.md) · [← all cases' use case guides](../docs/REPRODUCE.md)

Goal: use `openwiki` to document this very repo and answer questions
about it, powered by Solar Open2.

Full narrative, findings, and verified transcripts: [`README.md`](README.md).

Haven't set up `UPSTAGE_API_KEY` or read about the shared Tier-0 rate
limit yet? Start at [`docs/REPRODUCE.md`](../docs/REPRODUCE.md) first —
this page assumes both are already handled.

This is the most involved case to set up locally. The public `openwiki`
release doesn't yet have a fix this case needs, so you build a small
patched fork yourself.

## What you need

- `git`
- Node.js + `pnpm`
- a patched `openwiki` build, on `PATH`

## Build the patched `openwiki`

```bash
git clone https://github.com/jyje/openwiki.git
cd openwiki
git checkout fix/disable-streaming-for-tool-calling-providers
pnpm install
pnpm run build
npm link
```

Confirm it's the right build:

```bash
openwiki --version
```

Why a fork at all? Solar Open2 drops the tool-call function name in
**streamed** responses. The public `openwiki` has no switch to turn
streaming off. This fork adds one (`OPENWIKI_DISABLE_STREAMING=true`).
Full trace of how that was diagnosed is in
[`README.md`](README.md#finding-2-solar-open2-drops-the-tool_call-function-name-when-streaming)'s
Finding 2.

## Run it

From the repo root, `cd` into this directory first, then run its script:

```bash
cd 04-langchain-openwiki-solar-open2
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

This shallow-clones the repo into a gitignored `scratch/` folder inside
this directory and runs `openwiki` there — your real checkout, its
`AGENTS.md`, and its git history are never touched.

## What success looks like

Three questions get asked and answered — that's the hard pass/fail gate:

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

A fourth step, full documentation generation (`openwiki code --update`),
runs best-effort after the three questions. It's allowed to fail — it
often burns Upstage's whole per-minute token budget by itself on a
Tier-0 account. A `warn` line there is expected, not a failure of this
case.

## If something goes wrong

- **`command not found: openwiki`** — the `npm link` step above didn't
  put it on `PATH`, or you're in a shell that hasn't picked up the link
  yet. Re-open your shell, or check `npm root -g`.
- **`400 Invalid function name: ''`** — you're on the *unpatched* public
  `openwiki`, not the fork. Rebuild from the fork branch above.
- **Doc-generation step fails/warns** — expected on a Tier-0 account, per
  Finding 3 in [`README.md`](README.md). It doesn't fail the script.
- **`solar-pro3` (not `solar-open2`) times out or rate-limits** — expected
  on Tier 0, per [`PLAN.md`](../PLAN.md#case-04--solar-open2-x-langchain-openwiki)'s
  Case 04, Finding 4. This repo only verifies `solar-open2`.
