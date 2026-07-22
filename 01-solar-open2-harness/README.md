# Case 01 — Solar Open2 x Claude Code

[English](README.md) / [한국어](README-ko.md)

[← back to repo overview](../README.md) · Want to run this yourself?
See [`REPRODUCE.md`](REPRODUCE.md) for step-by-step local setup.

**Status:** Verified — Claude Code runs against Upstage's Solar Open2 model
two different ways, and both its custom-skill system and subagent/Task
calls work through that backend too. All four checks are confirmed
working end to end (locally and in CI).

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
export ANTHROPIC_DEFAULT_FABLE_MODEL="solar-open2"
export CLAUDE_CODE_SUBAGENT_MODEL="solar-open2"

claude -p "hello"
```

Every model *slot* Claude Code has needs to point at `solar-open2` —
Upstage only serves that one model, so any slot left unmapped risks a
background or subagent call requesting a model name the backend doesn't
have. `ANTHROPIC_DEFAULT_FABLE_MODEL` and `CLAUDE_CODE_SUBAGENT_MODEL`
(per the [model configuration docs](https://code.claude.com/docs/en/model-config#environment-variables))
close the two slots the installed `claude-upstage` (below) doesn't cover —
its own `set_claude_env` maps haiku/sonnet/opus/small-fast but predates
both the `fable` alias and the dedicated subagent-model variable, so a
`fable`-aliased or subagent/Task-tool call routed purely through
`claude-upstage` isn't guaranteed to land on Solar Open2.

No fork, no patch, no proxy — the stock `claude` binary from
`@anthropic-ai/claude-code` just needs to be told where to send requests.
`claude-upstage` (see below) is a convenience wrapper that sets most of
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

Every sample below is real output from one CI run of `verify.sh`
(truncated to <=100 chars, same as the script itself prints) — not
hand-picked or edited. Click through to read the untruncated response
yourself:

**Evidence run:** [`verify` job, 2026-07-14](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)
(or browse [every run](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml) for the latest)

### Method A — `claude-upstage`, piped stdin

```bash
echo "hello" | claude-upstage
```
> Hello! 👋 How can I help you with the `pilot-upstage-solar-open2` project today? I can assist with the three inde ...(truncated)

[Full output →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)

### Method B — official `claude` CLI, plain env vars

```bash
export ANTHROPIC_BASE_URL="https://api.upstage.ai"
export ANTHROPIC_AUTH_TOKEN="$UPSTAGE_API_KEY"
export ANTHROPIC_MODEL="solar-open2"
claude -p "hello"
```
> Hello! 👋 I'm ready to help you with your `pilot-upstage-solar-open2` project. This repo contains three agent-har ...(truncated)

[Full output →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)

Both responses read this repo's actual `AGENTS.md`/state, not a canned
reply, confirming Solar Open2 answers through the full agentic Claude
Code harness (tool access included), not just a raw chat completion.

## Skills through Solar Open2

The harness ships three custom skills (`.claude/skills/`, ported from
`jyje/skills` in an earlier pass). Do they actually get honored when Solar
Open2 is the model, not just when a Claude model is? Tested with
`git-commit-helper`, whose output format is strict enough to check
mechanically: `<gitmoji> <type>(<domain>): <title>`.

**Finding: autonomous skill-selection is unreliable, explicit invocation
is not.** Asked to just "write the commit message" (no skill named, a
one-off manual check, not part of the automated suite), Solar Open2
produced a plausible-looking message that silently dropped the required
format:

```bash
claude -p "Using this repo's git-commit-helper skill conventions, write \
  the commit message for a new file docs/hello.txt. Output only the \
  commit message."
```
> docs: add hello.txt greeting

No gitmoji, no `(domain)` — the skill's own required format wasn't
applied, even though the skill was named in the prompt's wording. Asked
the same thing but telling the model outright to *use* the skill — this
is Method C, which runs in CI every time:

```bash
claude -p "Use the git-commit-helper skill. A new file docs/hello.txt \
  with a greeting was just added to this repo as a new doc. Write the \
  commit message per that skill's exact format (gitmoji + type(domain): \
  title). Output only the commit message."
```
> 📄 docs(docs): add greeting file

[Full output →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)

Correct once the skill is explicitly invoked — gitmoji, type, and
`(domain):` all present. The gap between these two prompts is small in
wording but large in outcome: Solar Open2 can follow a skill's contract
precisely once told to load it, but doesn't reliably decide *on its own*
that a skill applies just because its subject matches the skill's
`description` trigger phrases the way Claude models tend to. **Practical
takeaway:** when running Claude Code on Solar Open2, name the skill
explicitly in prompts that need it rather than relying on automatic
trigger-phrase matching.

## Subagents stay on Solar Open2 too

`CLAUDE_CODE_SUBAGENT_MODEL="solar-open2"` is what keeps subagent/Task-tool
calls (e.g. the Explore agent) on Solar Open2 instead of falling back to
whatever the SDK's default subagent model would otherwise be. Verified
directly — asked the harness to hand a file-listing task to the Explore
subagent (this is Method D):

```bash
claude -p "Use the Explore agent (a subagent) to list every file \
  directly inside the current directory. Report just the file list."
```
> Files directly inside the current directory (`/home/runner/work/pilot-upstage-solar-open2/pilot-upstage-solar-open2/01-solar ...(truncated)

[Full output →](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29304170180/job/86994029784)

The reported path is the CI runner's actual checkout of this directory —
confirming the subagent call really executed against the real filesystem,
routed through `solar-open2` the whole way down.

## Verification

[`scripts/verify.sh`](scripts/verify.sh) runs four checks —
`claude-upstage doctor`, Method A, Method B, the explicit
`git-commit-helper` skill invocation (Method C), and a subagent call
gated on `CLAUDE_CODE_SUBAGENT_MODEL` (Method D) — and fails loudly if any
of them don't hold up. The skill check doesn't pin exact wording (the
title text isn't deterministic); it asserts the two structural things the
skill's format contract requires: a gitmoji (a non-ASCII byte) and a
`(domain):` segment. The subagent check looks for `README.md` — a file
that's always present in this directory — in the subagent's report, as a
deterministic proxy for "it actually ran against the real filesystem."
Run it locally with `UPSTAGE_API_KEY` set:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

It also runs as a step in CI (manual dispatch, solar-open2 only):
[`.github/workflows/verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml),
using the `UPSTAGE_API_KEY` repository secret.

See the repo-level [`PLAN.md`](../PLAN.md) for full context.
