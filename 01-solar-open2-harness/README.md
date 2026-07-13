# 01 — Solar Open2 harness

[← back to repo overview](../README.md)

**Status:** Planned

## Goal

Build a minimal Claude Code harness — custom skills, project conventions,
`.claude/` config — that runs against Upstage's **Solar Open2** model
instead of Anthropic's own models, and demonstrate it with a couple of
simple custom skills.

## Approach

- Route Claude Code's model calls to Solar Open2, either directly via
  Upstage's OpenAI-compatible endpoint or through a proxy (e.g. LiteLLM).
- Build 1-2 small custom skills to exercise the harness end to end.
- Document the setup and capture a demo transcript for the writeup.

## Planned tech

Upstage Solar Open2, Claude Code, `.claude/skills/`

See the repo-level [`PLAN.md`](../PLAN.md) for full context.
