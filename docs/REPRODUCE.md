# Use Case Guide

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← back to repo overview](../README.md)

This is a step-by-step guide.

Each case has its own dedicated use case guide, linked below.

This page only covers what's shared across all of them: getting an API
key, understanding the shared rate limit, and picking how to run a case.
Read this once, then jump to whichever case you want.

Each case's own `README.md` still holds the full story — findings, prior
art, verified transcripts. The use case guides only answer one
question: *how do I run it myself, right now, on my machine?*

## Before you start

### 1. Get an Upstage API key

Every case calls the real Upstage API.

There is no mocked or offline mode.

Get a key at <https://console.upstage.ai/api-keys>.

Export it once per shell session:

```bash
export UPSTAGE_API_KEY="up_..."
```

Keep it out of shell history and out of any committed file.

Each case ships a `.env.sample` showing the one variable it needs — copy
it to `.env` locally if you prefer a file over an export, but never commit
`.env` (already gitignored at the repo root).

### 2. Know the shared rate limit

All 5 cases share one Upstage account.

The default account tier (**Tier 0**) allows 100 requests/minute and
50,000 tokens/minute for Solar chat models.

That budget is shared across whichever case you run.

Running one case alone rarely hits the limit.

Running several back to back can.

If a case fails with something that looks like a 429 or a rate error,
wait a minute and retry — every case's own `verify.sh` already retries
automatically (5 attempts, 30s apart), so a single flaky attempt usually
resolves itself.

The root [`README.md`](../README.md#verified-against-tier-0--limits--mitigations)
has the full detail on why, and on the shared wrapper script
(`scripts/verify-case.sh`) that waits out a full budget reset before
each case starts — reach for it if you want the same safety net CI uses.

### 3. Pick your path

Two ways to run any case:

- **Direct** — call that case's own `./scripts/verify.sh`. Fastest, no
  extra waiting, fine for a single isolated run.
- **Wrapped** — call `./scripts/verify-case.sh <case-dir> solar-open2`
  from the repo root. Waits for a full rate-limit reset first. Safer when
  you're about to run more than one case in a row.

```bash
# direct
UPSTAGE_API_KEY="..." ./01-solar-open2-harness/scripts/verify.sh

# wrapped (repo root)
UPSTAGE_API_KEY="..." ./scripts/verify-case.sh 01-solar-open2-harness solar-open2
```

Both run the exact same check.

The wrapper just adds a wait in front.

## Every case's use case guide

| Case | Goal | Use case guide |
| --- | --- | --- |
| Case 01 | Claude Code itself, against Solar Open2 | [`01-solar-open2-harness/REPRODUCE.md`](../01-solar-open2-harness/REPRODUCE.md) |
| Case 02 | Claude Code driven programmatically via the Claude Agent SDK | [`02-claude-agent-sdk-local/REPRODUCE.md`](../02-claude-agent-sdk-local/REPRODUCE.md) |
| Case 03 | `deepagents` initialized at the code level via `langchain-upstage` | [`03-langchain-upstage-deepagents/REPRODUCE.md`](../03-langchain-upstage-deepagents/REPRODUCE.md) |
| Case 04 | `openwiki` documenting this repo, powered by Solar Open2 | [`04-langchain-openwiki-solar-open2/REPRODUCE.md`](../04-langchain-openwiki-solar-open2/REPRODUCE.md) |
| Case 05 | Hermes Agent's built-in Upstage provider, official Docker image | [`05-hermes-agent-solar-open2/REPRODUCE.md`](../05-hermes-agent-solar-open2/REPRODUCE.md) |

Each page has its own Korean twin — follow the `[한국어]` link at its top.

## Running all 5 in sequence, like CI does

Same order CI uses, each case waiting for a full rate-limit reset before
it starts:

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

Expect this to take 10-20+ minutes on a Tier-0 account.

Most of that time is waiting, not computing — the wait is what keeps
every case's budget clean, not a sign anything is stuck.

## Common errors across every case

A short table for the errors that show up in more than one case:

| Symptom | Cause | Fix |
| --- | --- | --- |
| A call hangs and never returns | `ANTHROPIC_API_KEY` set instead of `ANTHROPIC_AUTH_TOKEN` | Every `verify.sh` here already sets this correctly — only bites you if running the underlying tool by hand |
| `429` or a rate-limit-shaped error | Tier-0's shared 100 req/min, 50k tokens/min budget | Wait ~60s and retry, or use `scripts/verify-case.sh` for the built-in full-reset wait |
| `UPSTAGE_API_KEY is not set` | Forgot to export it in this shell | `export UPSTAGE_API_KEY="up_..."` before the command, every new shell |
| Any script exits with a `✗` line | The check itself printed the real reason on the line above it | Read the line right above the `✗` — every script prints the failing response verbatim before failing |

## See also

- [`README.md`](../README.md) — repo overview, the Tier-0 rate-limit
  section, and why each case fits its harness
- [`PLAN.md`](../PLAN.md) — full plan and findings behind every case
- [`AGENTS.md`](../AGENTS.md) — repo structure and conventions
- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — conventions for changing code
  here, and how to add a new case
