<div align="center">

# jyje/pilot-upstage-solar-open2

<img width="96" src="https://unpkg.com/@lobehub/icons-static-svg@1.91.0/icons/upstage-color.svg" alt="Upstage" title="Upstage"/> <img width="96" src="https://unpkg.com/@lobehub/icons-static-svg@1.91.0/icons/claude-color.svg" alt="Claude" title="Claude"/>

🧪 Three portfolio experiments in agent harnessing — Upstage Solar Open2, the Claude Agent SDK, and LangChain's Upstage integration with deepagents

[![verify-solar-open2-harness](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-solar-open2-harness.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-solar-open2-harness.yml)
[![verify-claude-agent-sdk-local](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-claude-agent-sdk-local.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-claude-agent-sdk-local.yml)
[![verify-langchain-upstage-deepagents](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-upstage-deepagents.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-upstage-deepagents.yml)
[![verify-langchain-openwiki-solar-open2](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-openwiki-solar-open2.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-openwiki-solar-open2.yml)

[English](README.md) / [한국어](README-ko.md)

</div>

A single repo hosting three independent, seminar/portfolio-ready experiments
around building and running Claude Code-style agent harnesses on top of
Upstage's Solar Open2 model and the broader Claude/LangChain agent tooling
ecosystem. Each experiment lives in its own top-level directory and can be
read, run, and presented independently.

## Experiments

| Case | Summary | Status |
| --- | --- | --- |
| [Case 01 — Solar Open2 harness](01-solar-open2-harness/) | Build a Claude Code harness (skills, etc.) backed by Upstage's Solar Open2 model | Verified |
| [Case 02 — Claude Agent SDK, local](02-claude-agent-sdk-local/) | Drive a local Claude Code instance programmatically with the Claude Agent SDK | Verified |
| [Case 03 — LangChain Upstage deepagents](03-langchain-upstage-deepagents/) | Initialize deepagents at the code level using the LangChain Upstage SDK | Verified |

## Special Use Cases

Additional, more specific integrations tried against Solar Open2 — separate
from the three core Experiments above, and expected to grow over time.

| Case | Summary | Status |
| --- | --- | --- |
| [Case 04 — LangChain OpenWiki](04-langchain-openwiki-solar-open2/) | Use `openwiki` to document this repo and answer questions about it, powered by Solar Open2 | Verified |

See [`PLAN.md`](PLAN.md) for the full plan and [`CLAUDE.md`](CLAUDE.md) for repo conventions.
