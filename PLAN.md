# Plan: pilot-upstage-solar-open2 — three agent-harness experiments

## Context

This repo exists to give three independent experiments a shared, portfolio
and seminar-ready home:

1. Building a Claude Code harness (skills, etc.) on top of Upstage's
   **Solar Open2** model.
2. Driving a **local Claude Code** instance programmatically with the
   **Claude Agent SDK**.
3. Initializing **deepagents** at the code level using the
   **LangChain Upstage SDK**.

Each case is scoped to be independently readable, runnable, and
presentable — someone should be able to open one case's folder and follow
it without needing the other two.

## Summary

| Case | Goal | Key tech | Status |
| --- | --- | --- | --- |
| Case 01 — Solar Open2 harness | Stand up a minimal Claude Code harness (custom skills, project config) that routes through Upstage's Solar Open2 model | Solar Open2, Claude Code, `.claude/skills/` | Verified |
| Case 02 — Claude Agent SDK, local | Drive a local Claude Code instance programmatically via the Claude Agent SDK (no manual CLI interaction) | Claude Agent SDK, Python | Verified |
| Case 03 — LangChain Upstage deepagents | Initialize a `deepagents`-based agent at the code level using `langchain-upstage` as the model backend | LangChain, `langchain-upstage`, `deepagents` | Verified |

## Case 01 — Solar Open2 harness

- **Goal**: show that a Claude Code-style harness (custom skills, project
  conventions, `.claude/` config) can run against Upstage's Solar Open2
  model instead of Anthropic's own models, and demonstrate a couple of
  simple custom skills built for it.
- **Approach**: point Claude Code's model routing at Solar Open2 (directly
  via Upstage's OpenAI-compatible endpoint, or via a proxy such as LiteLLM —
  see `~/repo/jyje/cluster/clusters/r4spi/apps/litellm.yaml` for a prior
  `upstage/solar-open2` routing config to reference), then build 1-2 small
  skills to exercise it end to end.
- **Prior art to reference (not copy verbatim)**: the LiteLLM routing config
  above; this repo's own `.claude/skills/` for skill authoring conventions.
- **Expected output**: a working `.claude/skills/` setup in
  `01-solar-open2-harness/`, plus a README documenting the setup and a
  short demo transcript/recording.
- **Result**: done. Verified two ways — the official `claude-upstage`
  wrapper (piped stdin, since it doesn't forward a `-p`-style flag to
  `claude`) and the plain `claude` CLI pointed at Upstage's
  Anthropic-compatible endpoint via `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN`.
  Both confirmed locally and wired into CI
  (`.github/workflows/verify-solar-open2-harness.yml`). See
  `01-solar-open2-harness/README.md` for transcripts and the finding about
  `claude-upstage`'s argument passthrough.

## Case 02 — Claude Agent SDK, local

- **Goal**: run Claude Code locally driven entirely through the Claude
  Agent SDK, not the interactive CLI — i.e. a program that opens sessions,
  sends turns, and reads results programmatically.
- **Approach**: scaffold a small uv-managed Python (or Node/TS) project
  that uses the Claude Agent SDK to launch and drive a local Claude Code
  session against a sample task, capturing input/output for the writeup.
- **Expected output**: a runnable script/CLI in
  `02-claude-agent-sdk-local/src/`, plus a README with setup + a captured
  example run.
- **Result**: done. `claude-agent-sdk` (Python) drives the same `claude`
  CLI as a subprocess, so the Solar Open2 env var recipe from Case 01
  carries over unchanged — passed via `ClaudeAgentOptions(env={...})`
  instead of shell `export`. Same auth-variable finding surfaced from the
  SDK side: its own docs example (`ANTHROPIC_API_KEY`) hangs against
  Upstage, `ANTHROPIC_AUTH_TOKEN` is required. Three methods verified:
  `query()` structured message types, `ClaudeSDKClient` multi-turn session
  memory (a number recalled across turns), and `ToolUseBlock` visibility
  for a tool call. Verified locally and in CI
  (`.github/workflows/verify-claude-agent-sdk-local.yml`), reusing the
  `UPSTAGE_API_KEY` secret from Case 01. See
  `02-claude-agent-sdk-local/README.md` for details.

## Case 03 — LangChain Upstage deepagents

- **Goal**: initialize a `deepagents`-based agent at the code level with
  `langchain-upstage` supplying the model, showing how deepagents composes
  with a non-Anthropic, non-OpenAI backend.
- **Approach**: start from the `create_deep_agent()` pattern already used in
  `~/repo/jyje/pilot-deep-agents` and the middleware composition style in
  `~/repo/jyje/pilot-deepagents-rubrics`, swapping the model for
  `langchain-upstage`.
- **Prior art to reference (not copy verbatim)**: `pilot-deep-agents`
  (`create_deep_agent()` + simple tool demo), `pilot-deepagents-rubrics`
  (`RubricMiddleware` composition).
- **Expected output**: a runnable agent in
  `03-langchain-upstage-deepagents/src/`, plus a README with setup + a
  captured example run.
- **Result**: done. `ChatUpstage` (from `langchain-upstage`) supplies
  Solar Open2 to `create_deep_agent()` — no `claude` CLI, no
  `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN` dance, just `UPSTAGE_API_KEY`
  read automatically via Upstage's OpenAI-compatible endpoint. Finding:
  Python 3.14 (this repo's default elsewhere) doesn't work here yet —
  `tokenizers`, a `langchain-upstage` dependency, has no `cp314` wheel as
  of any release through `0.23.1`, and building it from source fails in
  this environment; Case 03 pins Python 3.13 instead. Three methods
  verified: tool use (weather lookup), deepagents' built-in virtual
  filesystem (write + read back a file), and subagent delegation (a
  named `math-agent` subagent computing `17 + 25`). Verified locally and
  in CI (`.github/workflows/verify-langchain-upstage-deepagents.yml`,
  reusing the `UPSTAGE_API_KEY` secret, no Node/`claude`-CLI step
  needed). See `03-langchain-upstage-deepagents/README.md` for details.

## Special Use Cases

Separate from the three core Experiments above: more specific
integrations tried against Solar Open2, expected to grow over time.

### Case 04 — LangChain OpenWiki

- **Goal**: use `openwiki` (github.com/langchain-ai/openwiki) — a CLI
  that builds/maintains an agent-readable wiki for a codebase —
  configured to run on Solar Open2, targeting `pilot-solar-2` itself:
  document its latest commit and answer questions about it.
- **Approach**: shallow-clone this repo into a gitignored `scratch/`
  directory inside `04-langchain-openwiki-solar-open2/` and run
  `openwiki` there, so the real root `CLAUDE.md`/`AGENTS.md` are never
  touched and no auto-PR bot goes live on this repo.
- **Result**: done, with three real findings along the way:
  1. `openwiki`'s `anthropic` provider can't reach Solar Open2 — its
     `ChatAnthropic` construction only supports `apiKey`
     (`x-api-key`), never `authToken` (`Authorization: Bearer`).
     Confirmed via a direct 401 from Upstage. Worked around with the
     generic `openai-compatible` provider instead.
  2. Solar Open2 drops the `tool_call` function name specifically in
     **streamed** responses (confirmed via a local logging proxy and a
     minimal `stream: false` vs `stream: true` comparison) — a real
     Upstage-side bug, not an `openwiki`/`deepagents` bug. Patched a
     fork (`jyje/openwiki`, branch
     `fix/disable-streaming-for-tool-calling-providers`) with an opt-in
     `OPENWIKI_DISABLE_STREAMING` env var; verified the fix directly.
  3. Full documentation generation (`openwiki code --update`) exceeds
     Upstage's default 50k-tokens/minute rate limit within a single
     run — a capacity/tier constraint, not a bug. The 3-question Q&A
     (cheap, single-turn) is the hard, reliably-passing verification
     gate; doc generation is attempted best-effort.
  Verified locally and in CI
  (`.github/workflows/verify-langchain-openwiki-solar-open2.yml`,
  building the patched fork from source, reusing the `UPSTAGE_API_KEY`
  secret). See `04-langchain-openwiki-solar-open2/README.md` for
  details.

## Repo structure

See [`CLAUDE.md`](CLAUDE.md) for the directory tree and repo conventions
(English-only source/comments, README language policy, required
`python-lint` workflow for Python changes, `git-commit-helper` commit
policy).

## Next steps

All three core Experiments and the first Special Use Case are
implemented and verified. Open items:
- Revisit Case 03's Python 3.14 pin once `tokenizers` ships a `cp314`
  wheel, to bring every case onto the same Python version.
- Decide whether to open an upstream issue/PR against
  `langchain-ai/openwiki` for Case 04's two findings (the `anthropic`
  provider auth gap and the streaming tool-name bug) — not done yet,
  a separate decision from building Case 04 itself.
