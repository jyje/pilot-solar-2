# Plan: pilot-upstage-solar-open2 — agent-harness experiments

## Context

This repo exists to give several independent experiments a shared,
portfolio and seminar-ready home:

1. Building a Claude Code harness (skills, etc.) on top of Upstage's
   **Solar Open2** model.
2. Driving a **local Claude Code** instance programmatically with the
   **Claude Agent SDK**.
3. Initializing **deepagents** at the code level using the
   **LangChain Upstage SDK**.
4. Documenting this repo itself with **LangChain OpenWiki**, powered by
   Solar Open2.
5. Running **Solar Open2 x Hermes Agent** through Hermes's officially
   bundled Upstage provider.

Each case is scoped to be independently readable, runnable, and
presentable — someone should be able to open one case's folder and follow
it without needing any of the others.

## Summary

| Case | Goal | Key tech | Status |
| --- | --- | --- | --- |
| Case 01 — Solar Open2 x Claude Code | Stand up a minimal Claude Code harness (custom skills, project config) that routes through Upstage's Solar Open2 model | Solar Open2, Claude Code, `.claude/skills/` | Verified |
| Case 02 — Solar Open2 x Claude Agent SDK | Drive a local Claude Code instance programmatically via the Claude Agent SDK (no manual CLI interaction) | Claude Agent SDK, Python | Verified |
| Case 03 — Solar Open2 x LangChain Deepagents | Initialize a `deepagents`-based agent at the code level using the LangChain Upstage SDK (`langchain-upstage`) as the model backend | LangChain, `langchain-upstage`, `deepagents` | Verified |
| Case 04 — Solar Open2 x LangChain OpenWiki | Document this repo itself with `openwiki`, configured to run on Solar Open2 | LangChain, `openwiki`, Solar Open2 | Verified |
| Case 05 — Solar Open2 x Hermes Agent | Run Hermes Agent against Solar Open2 through its officially bundled Upstage provider | Hermes Agent, Docker, Solar Open2 | Verified |

## Case 01 — Solar Open2 x Claude Code

- **Goal**: show that a Claude Code-style harness (custom skills, project
  conventions, `.claude/` config) can run against Upstage's Solar Open2
  model instead of Anthropic's own models, and demonstrate a couple of
  simple custom skills built for it.
- **Approach**: point Claude Code's model routing at Solar Open2 (directly
  via Upstage's OpenAI-compatible endpoint, or via a proxy such as LiteLLM —
  see `jyje/cluster`'s `clusters/r4spi/apps/litellm.yaml` for a prior
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
  (`.github/workflows/verify-all-sequential.yml`). See
  `01-solar-open2-harness/README.md` for transcripts and the finding about
  `claude-upstage`'s argument passthrough.

## Case 02 — Solar Open2 x Claude Agent SDK

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
  (`.github/workflows/verify-all-sequential.yml`), reusing the
  `UPSTAGE_API_KEY` secret from Case 01. See
  `02-claude-agent-sdk-local/README.md` for details.

## Case 03 — Solar Open2 x LangChain Deepagents

- **Goal**: initialize a `deepagents`-based agent at the code level with
  `langchain-upstage` supplying the model, showing how deepagents composes
  with a non-Anthropic, non-OpenAI backend.
- **Approach**: start from the `create_deep_agent()` pattern already used in
  `jyje/pilot-deep-agents` and the middleware composition style in
  `jyje/pilot-deepagents-rubrics`, swapping the model for
  `langchain-upstage`.
- **Prior art to reference (not copy verbatim)**: `jyje/pilot-deep-agents`
  (`create_deep_agent()` + simple tool demo), `jyje/pilot-deepagents-rubrics`
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
  in CI (`.github/workflows/verify-all-sequential.yml`,
  reusing the `UPSTAGE_API_KEY` secret, no Node/`claude`-CLI step
  needed). See `03-langchain-upstage-deepagents/README.md` for details.

## Case 04 — Solar Open2 x LangChain OpenWiki

- **Goal**: use `openwiki` (github.com/langchain-ai/openwiki) — a CLI
  that builds/maintains an agent-readable wiki for a codebase —
  configured to run on Solar Open2, targeting `pilot-upstage-solar-open2` itself:
  document its latest commit and answer questions about it.
- **Approach**: shallow-clone this repo into a gitignored `scratch/`
  directory inside `04-langchain-openwiki-solar-open2/` and run
  `openwiki` there, so the real root `AGENTS.md` is never touched and no
  auto-PR bot goes live on this repo.
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
  4. `solar-pro3` needs more than a Tier-0 account's 50k-tokens/minute
     budget to answer even one question here: its agentic tool-calling
     loop makes 4-5 sequential round trips per question, and each one
     resends the cached system prompt + all 16 tool schemas
     (~13-15k tokens/call) — cumulative usage across just 4 calls
     already exceeds 50k. Confirmed with a local logging proxy showing
     real per-call `usage`, alongside a `reasoning_effort=low` patch to
     the fork (branch `feat/reasoning-effort-passthrough`, committed but
     not yet pushed/merged) that ruled out reasoning overhead as the
     cause — `reasoning_tokens: 0` on every call, same result. Not a
     code bug: `solar-open2` needs fewer round trips for the same
     question and comfortably fits the same budget. Expected to work on
     Upstage's Tier 1 and above (higher RPM/TPM); just not verifiable on
     this repo's Tier-0 account.
  Verified locally and in CI
  (`.github/workflows/verify-all-sequential.yml`,
  building the patched fork from source, reusing the `UPSTAGE_API_KEY`
  secret). See `04-langchain-openwiki-solar-open2/README.md` for
  details.

## Case 05 — Solar Open2 x Hermes Agent

- **Goal**: run NousResearch's Hermes Agent against Upstage's Solar Open2
  model with no bridge or proxy in the request path.
- **Finding**: the current Hermes Agent release includes `upstage` as a
  built-in provider (`solar` is an alias), and its bundled implementation
  explicitly handles the `solar-open*` family. The originally considered
  named custom-provider configuration is therefore unnecessary. This is
  distinct from Upstage's public model catalog: its current console example
  uses `solar-pro3`, so `solar-open2` availability must still be confirmed
  against the repository's account by the live check.
- **Approach**: set `model.provider: upstage` and `model.default:
  solar-open2` in `config.yaml`, pass `UPSTAGE_API_KEY` only through the
  environment, and run the digest-pinned official
  `nousresearch/hermes-agent` image directly. Verify the configuration with
  `hermes doctor`, then make a non-interactive `hermes chat -m solar-open2
  --provider upstage -q "<prompt>" --max-turns 2` round trip.
- **Prior art**: `jyje/hermes-agent-helm` established the official image and
  non-interactive `hermes chat` verification pattern on Kubernetes. This
  case uses the same image directly through Docker and replaces the chart's
  proxy-oriented example with Hermes's newer bundled Upstage provider.
- **Output**: a self-contained `05-hermes-agent-solar-open2/` case with a
  `config.yaml`, verification script, English/Korean README pair, and
  matching GitHub Actions workflow.
- **Status**: verified locally on 2026-07-20 with Hermes Agent v0.18.2.
  `hermes doctor` confirmed Upstage connectivity and a non-interactive
  `solar-open2` chat returned the expected `hermes-ready` response.

## Repo structure

See [`AGENTS.md`](AGENTS.md) for the directory tree and repo conventions
(English-only source/comments, README language policy, required
`python-lint` workflow for Python changes, `git-commit-helper` commit
policy).

## Next steps

Cases 01-05 are implemented and verified. Open items:
- Revisit Case 03's Python 3.14 pin once `tokenizers` ships a `cp314`
  wheel, to bring every case onto the same Python version.
- Decide whether to open an upstream issue/PR against
  `langchain-ai/openwiki` for Case 04's two findings (the `anthropic`
  provider auth gap and the streaming tool-name bug) — not done yet,
  a separate decision from building Case 04 itself.
- Revisit a direct OpenAI Codex integration once there's a clearer path
  between Codex's Responses-API provider interface and Upstage's Chat
  Completions endpoint; earlier exploration is archived in
  `draft/codex-upstage-solar-open2/`.
