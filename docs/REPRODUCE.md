# Reproducing every case locally

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← back to repo overview](../README.md)

This is a step-by-step guide.

Follow it top to bottom for any single case.

No prior context from `PLAN.md` or `AGENTS.md` is assumed.

Each case's own `README.md` still holds the full story — findings, prior
art, verified transcripts. This guide only answers one question: *how do
I run it myself, right now, on my machine?*

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

If a step below fails with something that looks like a 429 or a rate
error, wait a minute and retry — every case's own `verify.sh` already
retries automatically (5 attempts, 30s apart), so a single flaky attempt
usually resolves itself.

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

---

## Case 01 — Solar Open2 x Claude Code

Goal: run Claude Code itself against Solar Open2, and confirm its custom
skills and subagents still work through that backend.

Full narrative: [`01-solar-open2-harness/README.md`](../01-solar-open2-harness/README.md).

### What you need

- Node.js 18+
- the official Claude Code CLI
- Upstage's `claude-upstage` wrapper

### Install

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

```bash
curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh -s install
```

Prefer to read a script before piping it into `sh`? Fetch it first:

```bash
curl -fsSL https://console.upstage.ai/claude-upstage.sh -o claude-upstage.sh
less claude-upstage.sh
sh claude-upstage.sh
```

### Run it

```bash
export UPSTAGE_API_KEY="up_..."
./01-solar-open2-harness/scripts/verify.sh
```

### What success looks like

The script prints four checks, one per line, each starting with `✓`:

```
✓ claude-upstage doctor
✓ Method A ...
✓ git-commit-helper skill format honored via solar-open2
✓ subagent call completed on solar-open2 and saw the real directory
✓ All checks passed.
```

### If something goes wrong

- **`claude-upstage: unknown command '-p'`** — expected, and not a bug in
  this repo. `claude-upstage` doesn't forward `-p`. The script already
  pipes stdin instead (`echo "hello" | claude-upstage`); if you're poking
  at it manually, do the same.
- **A response that isn't Solar Open2** — check every `ANTHROPIC_*`
  model-slot variable is set, not just `ANTHROPIC_MODEL`. See the
  case README's "How it works" section for the full list.

---

## Case 02 — Solar Open2 x Claude Agent SDK

Goal: drive Claude Code programmatically through the Python
`claude-agent-sdk`, against Solar Open2.

Full narrative: [`02-claude-agent-sdk-local/README.md`](../02-claude-agent-sdk-local/README.md).

### What you need

- [`uv`](https://docs.astral.sh/uv/)
- the official Claude Code CLI (same install as Case 01)

### Run it

```bash
npm install -g @anthropic-ai/claude-code  # if not already installed
export UPSTAGE_API_KEY="up_..."
./02-claude-agent-sdk-local/scripts/verify.sh
```

The script runs `uv run python demo.py` under the hood — `uv` resolves
and installs the project's Python dependencies on first run automatically.
No separate install step needed.

### What success looks like

```
== Model under test: solar-open2 ==
== demo.py: Methods A/B/C against solar-open2 ==
...
✓ All checks passed.
```

### If something goes wrong

- **The call hangs, never returns** — a strong sign `ANTHROPIC_API_KEY`
  is set somewhere in your environment instead of `ANTHROPIC_AUTH_TOKEN`.
  `verify.sh` sets this correctly already; only relevant if you're
  running `demo.py` directly with your own env.
- **`uv not found`** — install it per the
  [uv docs](https://docs.astral.sh/uv/getting-started/installation/),
  then re-run.

### Before committing a change here

```bash
cd 02-claude-agent-sdk-local
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

All four must pass.

---

## Case 03 — Solar Open2 x LangChain Deepagents

Goal: initialize a `deepagents` agent at the code level, with
`langchain-upstage` supplying Solar Open2 as the model — no `claude` CLI
anywhere in this path.

Full narrative: [`03-langchain-upstage-deepagents/README.md`](../03-langchain-upstage-deepagents/README.md).

### What you need

- [`uv`](https://docs.astral.sh/uv/)
- Python 3.13 (this case pins 3.13, not 3.14 — see the case README for
  why; `uv` provisions it automatically if you don't have it)

Nothing else. No Node, no `claude` CLI.

### Run it

```bash
export UPSTAGE_API_KEY="up_..."
./03-langchain-upstage-deepagents/scripts/verify.sh
```

### What success looks like

```
== Model under test: solar-open2 ==
== demo.py: Methods A/B/C against solar-open2 ==
...
✓ All checks passed.
```

### If something goes wrong

- **A `tokenizers`/Rust build error during `uv run`** — you're likely on
  Python 3.14. Let `uv` use the pinned 3.13 instead of overriding it;
  don't try to force 3.14 here yet.

### Before committing a change here

```bash
cd 03-langchain-upstage-deepagents
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

All four must pass.

---

## Case 04 — Solar Open2 x LangChain OpenWiki

Goal: use `openwiki` to document this very repo and answer questions
about it, powered by Solar Open2.

Full narrative: [`04-langchain-openwiki-solar-open2/README.md`](../04-langchain-openwiki-solar-open2/README.md).

This is the most involved case to set up locally. The public `openwiki`
release doesn't yet have a fix this case needs, so you build a small
patched fork yourself.

### What you need

- `git`
- Node.js + `pnpm`
- a patched `openwiki` build, on `PATH`

### Build the patched `openwiki`

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
Full trace of how that was diagnosed is in the case README's Finding 2.

### Run it

```bash
export UPSTAGE_API_KEY="up_..."
./04-langchain-openwiki-solar-open2/scripts/verify.sh
```

This shallow-clones the repo into a gitignored `scratch/` folder inside
`04-langchain-openwiki-solar-open2/` and runs `openwiki` there — your
real checkout, its `AGENTS.md`, and its git history are never touched.

### What success looks like

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

### If something goes wrong

- **`command not found: openwiki`** — the `npm link` step above didn't
  put it on `PATH`, or you're in a shell that hasn't picked up the link
  yet. Re-open your shell, or check `npm root -g`.
- **`400 Invalid function name: ''`** — you're on the *unpatched* public
  `openwiki`, not the fork. Rebuild from the fork branch above.
- **Doc-generation step fails/warns** — expected on a Tier-0 account, per
  Finding 3 in the case README. It doesn't fail the script.
- **`solar-pro3` (not `solar-open2`) times out or rate-limits** — expected
  on Tier 0, per Finding 4. This repo only verifies `solar-open2`.

---

## Case 05 — Solar Open2 x Hermes Agent

Goal: run Hermes Agent's own bundled Upstage provider against Solar
Open2, through the official Docker image — no bridge, no proxy.

Full narrative: [`05-hermes-agent-solar-open2/README.md`](../05-hermes-agent-solar-open2/README.md).

### What you need

- Docker, with the daemon running

That's it. No Node, no Python, no `openwiki`.

### Run it

```bash
export UPSTAGE_API_KEY="up_..."
./05-hermes-agent-solar-open2/scripts/verify.sh
```

The first run pulls the digest-pinned `nousresearch/hermes-agent` image —
expect that one download the first time only.

### What success looks like

```
== Model under test: solar-open2 ==
...
hermes-ready
✓ Hermes completed a live solar-open2 round trip
```

### If something goes wrong

- **`Docker daemon is not available`** — start Docker Desktop (or your
  Docker service), then re-run.
- **Image pull is slow** — normal on the first run; the digest pin means
  every later run reuses the same cached layers.

### Try it by hand

Once the image is verified, this is the same call the script makes,
runnable directly for your own prompts. Hermes expects a whole
`/opt/data` directory, not a single mounted file, so set one up first:

```bash
hermes_home="$(mktemp -d)"
cp 05-hermes-agent-solar-open2/config.yaml "$hermes_home/config.yaml"
touch "$hermes_home/.env"
chmod 755 "$hermes_home"
chmod 644 "$hermes_home/config.yaml" "$hermes_home/.env"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e UPSTAGE_API_KEY \
  -v "$hermes_home:/opt/data" \
  --entrypoint hermes \
  nousresearch/hermes-agent@sha256:bb4d1e414918773b9c40e9a50582d582933beb85029b7050164d125f14e3f417 \
  chat --provider upstage --model solar-open2 \
  --query "Reply with exactly: hermes-ready" --max-turns 2 --quiet --ignore-rules

rm -rf "$hermes_home"
```

---

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
