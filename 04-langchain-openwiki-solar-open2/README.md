# Case 04 — LangChain OpenWiki, documenting pilot-solar-2 with Solar Open2

[English](README.md) / [한국어](README-ko.md)

[← back to repo overview](../README.md)

**Status:** Verified — [`openwiki`](https://github.com/langchain-ai/openwiki)
answers real questions about this very repo, powered by Upstage's Solar
Open2 model, via a patched build that fixes a real streaming bug
uncovered along the way.

## Goal

Use `openwiki` — a CLI that builds and maintains an agent-readable wiki
for a codebase — configured to run on **Solar Open2** instead of its
typical Anthropic/OpenAI defaults, targeting **this repo itself**
(`pilot-solar-2`): document its latest commit and answer questions about
it. This is the first of what may become a growing set of **Special Use
Cases** (Case 04+), separate from the three core Experiments (Cases
01-03).

## How it works

`openwiki` operates on its current working directory — no target-path
flag needed, just `cd` into a checkout and run it. To keep this repo's
real root untouched (no injected `CLAUDE.md`/`AGENTS.md` blocks, no
`openwiki/` folder, no auto-PR bot), [`scripts/verify.sh`](scripts/verify.sh)
shallow-clones `pilot-solar-2` into a gitignored `scratch/` directory and
runs `openwiki` there instead of against the live checkout.

## Finding 1: the `anthropic` provider can't reach Solar Open2

`openwiki` supports an `anthropic` provider, but its source
(`src/agent/index.ts`) constructs `ChatAnthropic` with only `apiKey` (→
`x-api-key` header) — never `authToken` (→ `Authorization: Bearer`),
unlike the Python tools in Cases 01-02. Confirmed directly: called
Upstage's Anthropic-compatible endpoint with the raw `@anthropic-ai/sdk`
JS client using `apiKey`, got an immediate **401 `invalid_api_key`** (not
a hang — Upstage's Anthropic-compatible endpoint plainly rejects
`x-api-key` auth). A real, confirmed dead end as currently written.

**Workaround used:** the generic `openai-compatible` provider, which is
Bearer-authenticated and matches Upstage's OpenAI-compatible endpoint
exactly (the same one `ChatUpstage` used in Case 03):

```bash
OPENWIKI_PROVIDER=openai-compatible
OPENAI_COMPATIBLE_API_KEY=$UPSTAGE_API_KEY
OPENAI_COMPATIBLE_BASE_URL=https://api.upstage.ai/v1/solar
OPENWIKI_MODEL_ID=solar-open2
```

## Finding 2: Solar Open2 drops the tool_call function name when streaming

Switching to `openai-compatible` wasn't enough on its own — every
tool-using run failed with `400 Invalid function name: ''`. Traced the
actual wire traffic with a small local logging proxy in front of
Upstage's API:

- The **request** always sent all 16 of `openwiki`'s tools correctly
  named (`ls`, `read_file`, `write_file`, `task`, ...) — not a
  malformed request.
- The **response** (streamed) came back with a tool call whose
  arguments matched the `ls` tool (`{"path":"/"}`) but whose
  `function.name` was **empty**. `openwiki` correctly rejected the
  unknown `""` tool and fed that error back — which Upstage then
  rejected on the *next* turn, since an empty-named `tool_call` in the
  conversation history fails its own schema validation.
- Isolated it further with a raw, minimal request: the exact same
  request with `stream: false` comes back with the correct name
  (`"ls"`). **Only the streamed response drops the name.**

This is a genuine Upstage/Solar Open2 streaming bug (or a
client/server chunking mismatch), not something in `openwiki`'s or
`deepagents`'s own code. But `openwiki` had no way to opt out of
streaming for this provider path, so a **small patch was added to a
fork** (`jyje/openwiki`, branch `fix/disable-streaming-for-tool-calling-providers`):
a new `OPENWIKI_DISABLE_STREAMING=true` env var that sets `streaming:
false` on the underlying `ChatOpenAI` for the generic
provider branch — an opt-in escape hatch, so every other
`openai-compatible`-family provider keeps streaming as before. Verified:
with this flag set, the exact same failing request now succeeds and
returns the correct tool name.

## Finding 3: full documentation generation exceeds the default rate limit

`openwiki code --update` (the command that actually writes `openwiki/`
docs) sends a large (~57KB) system prompt on every turn and needs
several tool-calling round trips to explore a multi-case repo like this
one — enough to exceed Upstage's default **50,000-tokens/minute** rate
limit within a single run, independent of any other traffic. This is a
capacity/tier constraint, not a code bug. `scripts/verify.sh` still
attempts it (best-effort) but doesn't gate on it; the 3-question Q&A
below — cheap, single-turn calls — is the hard, reliably-passing check.

## The 3 questions

Real answers from an `openwiki code -p "<question>"` run — not
hand-picked or edited:

1. **"What is this repository (pilot-solar-2) about?"**
2. **"What did the most recent commit change?"**
3. **"How many experiment cases does this repo have, and what does each one demonstrate?"**

## Verified methods

Evidence run: *(added after the first CI run on this case — see
[Verification](#verification))*

## Verification

[`scripts/verify.sh`](scripts/verify.sh) shallow-clones this repo,
answers the 3 questions above via `openwiki code -p` (hard gate), and
attempts full documentation generation via `openwiki code --update`
(best-effort, per Finding 3). Requires the patched `openwiki` build from
[`jyje/openwiki`](https://github.com/jyje/openwiki/tree/fix/disable-streaming-for-tool-calling-providers) —
the public npm release doesn't have the streaming fix yet.

Run locally with `UPSTAGE_API_KEY` set and the patched `openwiki` on
PATH:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

Runs in CI on every push/PR that touches this directory:
[`.github/workflows/verify-langchain-openwiki-solar-open2.yml`](../.github/workflows/verify-langchain-openwiki-solar-open2.yml) —
builds the patched fork from source (`pnpm install && pnpm run build &&
npm link`), reusing the same `UPSTAGE_API_KEY` repository secret as
every other case.

See the repo-level [`PLAN.md`](../PLAN.md) for full context.
