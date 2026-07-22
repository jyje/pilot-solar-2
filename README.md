<div align="center">

# jyje/pilot-upstage-solar-open2

<img height="240" src="https://raw.githubusercontent.com/jyje/pilot-upstage-solar-open2/main/docs/images/pilot-upstage-solar-open2.png" alt="Claude Code × Upstage Solar Open2 × Hermes Agent"/>

🧪 Claude Code, the Claude Agent SDK, LangChain, OpenWiki, and Hermes Agent — every use case built on Upstage Solar Open2!

[![verify-all-sequential](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml)

[English](README.md) / [한국어](README-ko.md)

</div>

A single repo hosting several independent, seminar-ready use cases around
building and running agent harnesses on Upstage's Solar Open2 model across
the Claude, LangChain, OpenWiki, and Hermes Agent ecosystems. Each case
lives in its own top-level directory and can be read, run, and presented
independently.

## Cases

| Case | Summary | Status |
| --- | --- | --- |
| [Case 01 — Solar Open2 x Claude Code](01-solar-open2-harness/) | Build a Claude Code harness (skills, etc.) backed by Upstage's Solar Open2 model | Verified |
| [Case 02 — Solar Open2 x Claude Agent SDK](02-claude-agent-sdk-local/) | Drive a local Claude Code instance programmatically with the Claude Agent SDK | Verified |
| [Case 03 — Solar Open2 x LangChain Deepagents](03-langchain-upstage-deepagents/) | Initialize deepagents at the code level using the LangChain Upstage SDK | Verified |
| [Case 04 — Solar Open2 x LangChain OpenWiki](04-langchain-openwiki-solar-open2/) | Use `openwiki` to document this repo and answer questions about it, powered by Solar Open2 | Verified |
| [Case 05 — Solar Open2 x Hermes Agent](05-hermes-agent-solar-open2/) | Run Hermes Agent through its officially bundled Upstage provider and the official Docker image | Verified |

## Composition & intent

Each case demonstrates the same model, Solar Open2, wired into a
*different* existing, popular agent harness or framework — not a custom
harness built from scratch for this repo. The point is to show that Solar
Open2 is a drop-in backend for the open agent ecosystem people already
use, not something that requires bespoke tooling:

- **Case 01/02** — Anthropic's own Claude Code CLI and Claude Agent SDK,
  routed at Solar Open2 instead of Anthropic's models.
- **Case 03** — LangChain's `deepagents`, with `langchain-upstage`
  supplying the model.
- **Case 04** — `openwiki` (LangChain AI), an agent-readable-wiki
  generator, documenting this very repo.
- **Case 05** — NousResearch's Hermes Agent, via its own bundled Upstage
  provider.

Every case is self-contained: its own `README.md`/`README-ko.md`, its own
`scripts/verify.sh` that exercises real Upstage API calls (no mocks), and
its own entry in the shared CI workflow. See [`PLAN.md`](PLAN.md) for the
full plan and findings behind each case, [`AGENTS.md`](AGENTS.md) for repo
structure and conventions, and [`CONTRIBUTING.md`](CONTRIBUTING.md) for how
to add a new case or run everything locally.

Want to run a case yourself, step by step, right now? The
[Use Case Guide](docs/REPRODUCE.md) walks through the exact prerequisites
and commands for every case, one case at a time (English/Korean).

## Why Solar Open2 fits existing agent harnesses

Every case above reached Solar Open2 through a wire-compatible endpoint a
mainstream framework already speaks, not a custom client:

- Case 01/02 route Claude Code / the Claude Agent SDK at Solar Open2's
  Anthropic-compatible endpoint via `ANTHROPIC_BASE_URL` +
  `ANTHROPIC_AUTH_TOKEN` (a real finding along the way: `ANTHROPIC_API_KEY`
  hangs against Upstage, `ANTHROPIC_AUTH_TOKEN` is required).
- Case 03's `ChatUpstage` (from `langchain-upstage`) is a thin
  `BaseChatOpenAI` subclass pointed at Upstage's OpenAI-compatible
  endpoint — no bridge, no proxy.
- Case 04's `openwiki` reaches Solar Open2 through its generic
  `openai-compatible` provider. Its `anthropic` provider is a confirmed
  dead end here: the client only ever sends `apiKey` (`x-api-key`), never
  `authToken` (`Authorization: Bearer`), and Upstage's Anthropic-compatible
  endpoint rejects `x-api-key` outright — see
  [Case 04's README](04-langchain-openwiki-solar-open2/README.md) for the
  full trace.
- Case 05's Hermes Agent ships a first-class, built-in `upstage` provider
  — no bridge needed at all.

The practical upshot: adding a new agent harness to this list is mostly
configuration (base URL, auth style, model ID), not new integration code,
as long as the harness already speaks OpenAI- or Anthropic-shaped wire
formats.

## Verified against Tier 0 — limits & mitigations

Every case here runs against Upstage's **default Tier 0** account limits:
100 requests/minute and 50,000 tokens/minute for Solar chat models (see
[Upstage's rate-limit guide](https://console.upstage.ai/ko/docs/guides/rate-limits)).
Building a reliable CI verification loop on top of that surfaced three
real failure modes, and how each is handled:

1. **Leftover budget between cases.** Running all 5 cases back-to-back in
   one sequential job, a case starting right after a heavier one could
   inherit partial headroom that looked "enough" by a naive threshold
   check but wasn't. Fixed: every case now waits for the token/request
   budget to be **fully** reset before it starts
   ([`scripts/wait-for-upstage-full-reset.sh`](scripts/wait-for-upstage-full-reset.sh),
   10-minute cap).
2. **A single call exhausting the budget.** Case 04's `openwiki` makes
   several sequential tool-calling round trips per question, each
   resending the full system prompt and tool schemas — one question alone
   was observed to burn 36,440 of a 49,998-token budget. Because
   Upstage's limit is a *rolling* per-minute window, not a fixed reset
   clock, retries kept seeing 0 tokens remaining even past the reported
   reset instant. Fixed: the same full-reset wait runs before every retry
   attempt inside Case 04, not just once per case.
3. **`solar-pro3` needs more than Tier 0 offers** for Case 04
   specifically — its agentic loop's cumulative usage across a handful of
   calls exceeds the 50k/minute budget outright, independent of any
   leftover-budget issue. Not a bug in this repo's code; expected to work
   once the account is on **Tier 1 or above**. Full trace in
   [`PLAN.md`](PLAN.md)'s Case 04, Finding 4.

This is why [`verify-all-sequential.yml`](.github/workflows/verify-all-sequential.yml)
runs the 5 cases **one at a time**, waiting on real Upstage rate-limit
response headers instead of a fixed guessed delay — expect a full run to
take on the order of 10-20+ minutes on a Tier-0 account. A higher tier
would make the waits mostly disappear, but nothing here assumes one.

## Latest verification run

✅ 5/5 cases passed against `solar-open2` —
[run 29870650705](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29870650705)
(2026-07-21):

| Case | solar-open2 |
| --- | --- |
| Case 01 — Solar Open2 x Claude Code | ✅ |
| Case 02 — Solar Open2 x Claude Agent SDK | ✅ |
| Case 03 — Solar Open2 x LangChain Deepagents | ✅ |
| Case 04 — Solar Open2 x LangChain OpenWiki | ✅ |
| Case 05 — Solar Open2 x Hermes Agent | ✅ |

See the badge above for the latest status, or browse
[every run](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml).

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for repo conventions, local dev
commands for every case, and how to add a new one.
