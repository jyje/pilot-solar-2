<div align="center">

# jyje/pilot-upstage-solar-open2

<img height="240" src="https://raw.githubusercontent.com/jyje/pilot-upstage-solar-open2/main/docs/images/pilot-upstage-solar-open2.png" alt="Claude Code × Upstage Solar Open 2 × Hermes Agent"/>

✨ Testing multiple agent harnesses on Upstage Solar Open2: Claude Code, Hermes Agent, Claude Agent SDK, LangChain Deepagents, and OpenWiki

[![verify-all-sequential](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml)

External links:<br>
[![Model on Hugging Face](https://img.shields.io/badge/🤗_Hugging_Face-upstage/solar--open2--250b-yellow)](https://huggingface.co/upstage/Solar-Open2-250B)
[![Technical Report](https://img.shields.io/badge/📄_Technical_Report-PDF-blue)](https://huggingface.co/upstage/Solar-Open2-250B/blob/main/Solar_Open_2_Tech_Report.pdf)
[![Launch Event](https://img.shields.io/badge/📺_Launch_Event-YouTube-red)](https://www.youtube.com/live/6XX-yR3qomM)

[English](README.md) / [한국어](README-ko.md)

</div>

## Solar Open 2

[Solar Open 2](https://huggingface.co/upstage/Solar-Open2-250B) is Upstage's
open-weight, 250B-A15B (250B total, 15B active) Mixture-of-Experts model.
It's purpose-built for long-horizon agentic tasks — tool use, multi-step
reasoning, end-to-end task execution — over a 1M-token context, via a
hybrid linear/softmax attention stack.

It leads comparably sized open-weight models on MMLU-Pro, LiveCodeBench,
and the APEX-Agents agentic suite. On Korean benchmarks, it posts the
highest average of any model compared, including fast-tier closed APIs.

| Feature | Description |
| --- | --- |
| Parameters | 250B total, 15B active (MoE) |
| Context | 1M tokens |
| License | Upstage Solar License |
| Report | [Solar Open 2 Technical Report](https://huggingface.co/upstage/Solar-Open2-250B/blob/main/Solar_Open_2_Tech_Report.pdf) (Jul 22, 2026) |
| Launch event | [Solar Open Weight Day (YouTube Live)](https://www.youtube.com/live/6XX-yR3qomM) |

This repo doesn't re-explain the model itself — see the
[model card](https://huggingface.co/upstage/Solar-Open2-250B) and
[technical report](https://huggingface.co/upstage/Solar-Open2-250B/blob/main/Solar_Open_2_Tech_Report.pdf)
for full details. What follows is how to build agent harnesses on top of
it.

A single repo hosting several independent, seminar-ready use cases around
building and running agent harnesses on Upstage's Solar Open 2 model across
the Claude, LangChain, OpenWiki, and Hermes Agent ecosystems. Each case
lives in its own top-level directory and can be read, run, and presented
independently.

## Cases

| Case | Category | Summary | Status |
| --- | --- | --- | --- |
| [Case 01 — Solar Open 2 x Claude Code](01-solar-open2-harness/) | Review | Build a Claude Code harness (skills, etc.) backed by Upstage's Solar Open 2 model | Verified |
| [Case 02 — Solar Open 2 x Hermes Agent](02-hermes-agent-solar-open2/) | Review | Run Hermes Agent through its officially bundled Upstage provider and the official Docker image | Verified |
| [Case 03 — Solar Open 2 x Claude Agent SDK](03-claude-agent-sdk-local/) | Extend | Drive a local Claude Code instance programmatically with the Claude Agent SDK | Verified |
| [Case 04 — Solar Open 2 x LangChain Deepagents](04-langchain-upstage-deepagents/) | Extend | Initialize deepagents at the code level using the LangChain Upstage SDK | Verified |
| [Case 05 — Solar Open 2 x LangChain OpenWiki](05-langchain-openwiki-solar-open2/) | Extend | Use `openwiki` to document this repo and answer questions about it, powered by Solar Open 2 | Verified |

**Review** cases validate that Solar Open 2 works correctly in an
existing, official harness path. **Extend** cases go further, wiring
Solar Open 2 into a broader ecosystem (LangChain, custom agent code)
beyond what those harnesses ship out of the box.

## Composition & intent

Each case demonstrates the same model, Solar Open 2, wired into a
*different* existing, popular agent harness or framework — not a custom
harness built from scratch for this repo. The point is to show that Solar
Open 2 is a drop-in backend for the open agent ecosystem people already
use, not something that requires bespoke tooling:

- **Case 01/03** — Anthropic's own Claude Code CLI and Claude Agent SDK,
  routed at Solar Open 2 instead of Anthropic's models.
- **Case 02** — NousResearch's Hermes Agent, via its own bundled Upstage
  provider.
- **Case 04** — LangChain's `deepagents`, with `langchain-upstage`
  supplying the model.
- **Case 05** — `openwiki` (LangChain AI), an agent-readable-wiki
  generator, documenting this very repo.

Every case is self-contained: its own `README.md`/`README-ko.md`, its own
`scripts/verify.sh` that exercises real Upstage API calls (no mocks), and
its own entry in the shared CI workflow. See [`PLAN.md`](PLAN.md) for the
full plan and findings behind each case, [`AGENTS.md`](AGENTS.md) for repo
structure and conventions, and [`CONTRIBUTING.md`](CONTRIBUTING.md) for how
to add a new case or run everything locally.

Want to run a case yourself, step by step, right now? The
[Use Case Guide](docs/REPRODUCE.md) walks through the exact prerequisites
and commands for every case, one case at a time (English/Korean).

## Why Solar Open 2 fits existing agent harnesses

Every case above reached Solar Open 2 through a wire-compatible endpoint a
mainstream framework already speaks, not a custom client:

- Case 01/03 route Claude Code / the Claude Agent SDK at Solar Open 2's
  Anthropic-compatible endpoint via `ANTHROPIC_BASE_URL` +
  `ANTHROPIC_AUTH_TOKEN`. A real finding along the way: `ANTHROPIC_API_KEY`
  hangs against Upstage, `ANTHROPIC_AUTH_TOKEN` is required.
- Case 02's Hermes Agent ships a first-class, built-in `upstage` provider.
  No bridge needed at all.
- Case 04's `ChatUpstage` (from `langchain-upstage`) is a thin
  `BaseChatOpenAI` subclass pointed at Upstage's OpenAI-compatible
  endpoint — no bridge, no proxy.
- Case 05's `openwiki` reaches Solar Open 2 through its generic
  `openai-compatible` provider. Its `anthropic` provider is a confirmed
  dead end here: the client only ever sends `apiKey` (`x-api-key`), never
  `authToken` (`Authorization: Bearer`). Upstage's Anthropic-compatible
  endpoint rejects `x-api-key` outright — see
  [Case 05's README](05-langchain-openwiki-solar-open2/README.md) for the
  full trace.

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
   inherit partial headroom. That headroom looked "enough" by a naive
   threshold check, but wasn't. Fixed: every case now waits for the
   token/request budget to be **fully** reset before it starts
   ([`scripts/wait-for-upstage-full-reset.sh`](scripts/wait-for-upstage-full-reset.sh),
   10-minute cap).
2. **A single call exhausting the budget.** Case 05's `openwiki` makes
   several sequential tool-calling round trips per question, each
   resending the full system prompt and tool schemas. One question alone
   was observed to burn 36,440 of a 49,998-token budget. Because
   Upstage's limit is a *rolling* per-minute window, not a fixed reset
   clock, retries kept seeing 0 tokens remaining even past the reported
   reset instant. Fixed: the same full-reset wait now runs before every
   retry attempt inside Case 05, not just once per case.
3. **`solar-pro3` needs more than Tier 0 offers** for Case 05
   specifically. Its agentic loop's cumulative usage across a handful of
   calls exceeds the 50k/minute budget outright, independent of any
   leftover-budget issue. Not a bug in this repo's code — expected to
   work once the account is on **Tier 1 or above**. Full trace in
   [`PLAN.md`](PLAN.md)'s Case 05, Finding 4.

This is why [`verify-all-sequential.yml`](.github/workflows/verify-all-sequential.yml)
runs the 5 cases **one at a time**, waiting on real Upstage rate-limit
response headers instead of a fixed guessed delay. Expect a full run to
take on the order of 10-20+ minutes on a Tier-0 account. A higher tier
would make the waits mostly disappear, but nothing here assumes one.

## Latest verification run

✅ 5/5 cases passed against `solar-open2` —
[run 30008688179](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30008688179)
(2026-07-23), on the `ubuntu-26.04-arm` runner. The recap splits by
Category, matching the Cases table above:

**Review**

| Case | solar-open2 |
| --- | --- |
| Case 01 — Solar Open 2 x Claude Code | ✅ |
| Case 02 — Solar Open 2 x Hermes Agent | ✅ |

**Extend**

| Case | solar-open2 |
| --- | --- |
| Case 03 — Solar Open 2 x Claude Agent SDK | ✅ |
| Case 04 — Solar Open 2 x LangChain Deepagents | ✅ |
| Case 05 — Solar Open 2 x LangChain OpenWiki | ✅ |

Every case's own README now quotes real, unedited excerpts from this
run — up to ~700 characters (10+ wrapped lines) per answer instead of a
single 100-char fragment, specifically so the model's actual reasoning
is visible, not just a pass/fail line. See each case's own README for
its real questions and answers.

See the badge above for the latest status, or browse
[every run](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml).

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for repo conventions, local dev
commands for every case, and how to add a new one.
