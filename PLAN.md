# Plan: pilot-solar-2 — three agent-harness experiments

## Context

This repo exists to give three independent experiments a shared, portfolio
and seminar-ready home:

1. Building a Claude Code harness (skills, etc.) on top of Upstage's
   **Solar Open2** model.
2. Driving a **local Claude Code** instance programmatically with the
   **Claude Agent SDK**.
3. Initializing **deepagents** at the code level using the
   **LangChain Upstage SDK**.

Each topic is scoped to be independently readable, runnable, and
presentable — someone should be able to open one topic folder and follow it
without needing the other two.

## Summary

| # | Topic | Goal | Key tech | Status |
| --- | --- | --- | --- | --- |
| 01 | Solar Open2 harness | Stand up a minimal Claude Code harness (custom skills, project config) that routes through Upstage's Solar Open2 model | Solar Open2, Claude Code, `.claude/skills/` | Verified |
| 02 | Claude Agent SDK, local | Drive a local Claude Code instance programmatically via the Claude Agent SDK (no manual CLI interaction) | Claude Agent SDK, Python/TS | Planned |
| 03 | LangChain Upstage deepagents | Initialize a `deepagents`-based agent at the code level using `langchain-upstage` as the model backend | LangChain, `langchain-upstage`, `deepagents` | Planned |

## Topic 01 — Solar Open2 harness

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

## Topic 02 — Claude Agent SDK, local

- **Goal**: run Claude Code locally driven entirely through the Claude
  Agent SDK, not the interactive CLI — i.e. a program that opens sessions,
  sends turns, and reads results programmatically.
- **Approach**: scaffold a small uv-managed Python (or Node/TS) project
  that uses the Claude Agent SDK to launch and drive a local Claude Code
  session against a sample task, capturing input/output for the writeup.
- **Expected output**: a runnable script/CLI in
  `02-claude-agent-sdk-local/src/`, plus a README with setup + a captured
  example run.

## Topic 03 — LangChain Upstage deepagents

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

## Repo structure

See [`CLAUDE.md`](CLAUDE.md) for the directory tree and repo conventions
(English-only source/comments, README language policy, required
`python-lint` workflow for Python changes, `git-commit-helper` commit
policy).

## Next steps

- Confirm which topic to implement first (order isn't fixed by this plan).
- Per topic, once implementation starts: `uv init` a `src/` inside that
  topic's directory, add real dependencies, and write a `REPORT.md` inside
  that topic folder once there's a working demo to document (mirrors the
  plan → implement → report lifecycle used in other `pilot-*` repos).
