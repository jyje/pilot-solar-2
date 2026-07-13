# 01 — Solar Open2 harness

[← back to repo overview](../README.md)

**Status:** Verified — Claude Code runs against Upstage's Solar Open2 model
two different ways, and its custom-skill system works through that
backend too. All three checks are confirmed working end to end (locally
and in CI).

## Goal

Show that a Claude Code harness can run against Upstage's **Solar Open2**
model instead of Anthropic's own models, and verify it two ways: through
Upstage's own `claude-upstage` wrapper, and through the **official**
`claude` CLI configured with plain environment variables — no wrapper,
no proxy. Also verify that this repo's custom `.claude/skills/` — the
"simple skills" part of the original brief — are actually honored when
Solar Open2 is the backend, not just when Claude models are.

## How it works

Upstage exposes an Anthropic Messages API-compatible endpoint at
`https://api.upstage.ai`. The official `claude` CLI already knows how to
talk to any Anthropic-compatible endpoint via environment variables, so
pointing it at Upstage instead of Anthropic is just:

```bash
export ANTHROPIC_BASE_URL="https://api.upstage.ai"
export ANTHROPIC_AUTH_TOKEN="$UPSTAGE_API_KEY"
export ANTHROPIC_MODEL="solar-open2"
export ANTHROPIC_SMALL_FAST_MODEL="solar-open2"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="solar-open2"
export ANTHROPIC_DEFAULT_SONNET_MODEL="solar-open2"
export ANTHROPIC_DEFAULT_OPUS_MODEL="solar-open2"

claude -p "hello"
```

No fork, no patch, no proxy — the stock `claude` binary from
`@anthropic-ai/claude-code` just needs to be told where to send requests.
`claude-upstage` (see below) is a convenience wrapper that sets exactly
these variables for you and then `exec`s `claude`.

## Installation

**Official Claude Code CLI** (prerequisite for both methods, requires
Node.js 18+):

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

**`claude-upstage`** — Upstage's official wrapper script, published at
`console.upstage.ai`:

```bash
# run once, no install:
curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh

# review first, then run:
curl -fsSL https://console.upstage.ai/claude-upstage.sh -o claude-upstage.sh
less claude-upstage.sh && sh claude-upstage.sh

# install to ~/.local/bin so future runs are just `claude-upstage`:
curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh -s install
```

An API key from <https://console.upstage.ai/api-keys> is required either
way — `claude-upstage login` saves it to the OS keychain, or export
`UPSTAGE_API_KEY` for the current shell.

## Finding: `claude-upstage` doesn't pass `-p` through

The literal form the harness was expected to support —
`claude-upstage -p "hello"` — **fails**: `claude-upstage: unknown command
'-p'`. Checked in both the locally installed copy and the current
canonical script fetched fresh from `console.upstage.ai` (byte-identical
apart from one unrelated line) — this isn't a stale-install issue, it's how
the wrapper's argument parser is currently written. `claude-upstage` only
forwards `--model`, `-c`/`--continue`, and `-r`/`--resume` to `claude`;
anything else is rejected before `claude` is ever invoked.

The workaround that does work non-interactively: pipe input to
`claude-upstage` instead of passing `-p`. With stdin not a tty, the
underlying `claude` process treats it as a single-shot prompt just like
`-p` would:

```bash
echo "hello" | claude-upstage
```

## Verified methods

### Method A — `claude-upstage`, piped stdin

```console
$ echo "hello" | claude-upstage
Verifying API key... ✓ ok

☀ Upstage Solar × Claude Code

  host    https://api.upstage.ai
  model   solar-open2
  key     saved in macOS Keychain

Launching claude ...

안녕하세요! 어떤 도움이 필요하신가요? 🚀

현재 pilot-solar-2 저장소에는 세 가지 주제의 실험이 준비되어 있습니다:
1. Solar Open2 Harness — Claude Code를 Upstage Solar Open2 모델에 적용
2. Claude Agent SDK Local — 로컬에서 Claude Code 구동
3. LangChain Upstage DeepAgents — LangChain Upstage SDK 기반 deepagents 초기화
...
```

### Method B — official `claude` CLI, plain env vars

```console
$ export ANTHROPIC_BASE_URL="https://api.upstage.ai"
$ export ANTHROPIC_AUTH_TOKEN="$UPSTAGE_API_KEY"
$ export ANTHROPIC_MODEL="solar-open2"
$ claude -p "hello"
안녕하세요! 👋

pilot-solar-2 저장소에 잘 오셨습니다. Upstage의 Solar Open2 모델을 중심으로
3개의 독립적인 에이전트 실험을 호스팅하는 포트폴리오 프로젝트입니다.
...
```

Both transcripts are real, captured runs — and both show the model reading
this repo's actual `CLAUDE.md`/state, not a canned reply, confirming Solar
Open2 answers through the full agentic Claude Code harness (tool access
included), not just a raw chat completion.

## Skills through Solar Open2

The harness ships three custom skills (`.claude/skills/`, ported from
`jyje/skills` in an earlier pass). Do they actually get honored when Solar
Open2 is the model, not just when a Claude model is? Tested with
`git-commit-helper`, whose output format is strict enough to check
mechanically: `<gitmoji> <type>(<domain>): <title>`.

**Finding: autonomous skill-selection is unreliable, explicit invocation
is not.** Asked to just "write the commit message" (no skill named), Solar
Open2 produced a plausible-looking message that silently dropped the
required format:

```console
$ claude -p "Using this repo's git-commit-helper skill conventions, \
  write the commit message for a new file docs/hello.txt containing a \
  greeting, added as a brand-new doc. Output only the commit message."
docs: add hello.txt greeting

Add a new documentation file containing a greeting.
```

No gitmoji, no `(domain)` — the skill's own required format wasn't
applied, even though the skill was named in the prompt's wording. Asked
the same thing but telling the model outright to *use* the skill:

```console
$ claude -p "Use the git-commit-helper skill. A new file docs/hello.txt \
  with a greeting was just added to this repo as a new doc. Write the \
  commit message per that skill's exact format (gitmoji + type(domain): \
  title). Output only the commit message."
📄 docs(docs): add hello greeting
```

Correct on the second attempt — gitmoji, type, and `(domain):` all
present. The gap between these two prompts is small in wording but large
in outcome: Solar Open2 can follow a skill's contract precisely once told
to load it, but doesn't reliably decide *on its own* that a skill applies
just because its subject matches the skill's `description` trigger
phrases the way Claude models tend to. **Practical takeaway:** when
running Claude Code on Solar Open2, name the skill explicitly in prompts
that need it rather than relying on automatic trigger-phrase matching.

## Verification

[`scripts/verify.sh`](scripts/verify.sh) runs three checks —
`claude-upstage doctor`, Method A, Method B, and the explicit
`git-commit-helper` skill invocation — and fails loudly if any of them
don't hold up. The skill check doesn't pin exact wording (the title text
isn't deterministic); it asserts the two structural things the skill's
format contract requires: a gitmoji (a non-ASCII byte) and a
`(domain):` segment. Run it locally with `UPSTAGE_API_KEY` set:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

It also runs in CI on every push/PR that touches this directory:
[`.github/workflows/verify-solar-open2-harness.yml`](../.github/workflows/verify-solar-open2-harness.yml),
using the `UPSTAGE_API_KEY` repository secret.

See the repo-level [`PLAN.md`](../PLAN.md) for full context.
