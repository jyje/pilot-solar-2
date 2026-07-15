<div align="center">

# jyje/pilot-upstage-solar-open2

<img width="96" src="https://unpkg.com/@lobehub/icons-static-svg@1.91.0/icons/upstage-color.svg" alt="Upstage" title="Upstage"/> <img width="96" src="https://unpkg.com/@lobehub/icons-static-svg@1.91.0/icons/claude-color.svg" alt="Claude" title="Claude"/>

🧪 Upstage Solar Open2, Claude Agent SDK, LangChain의 Upstage × deepagents 연동까지 — 포트폴리오용 3대 에이전트 하네스 실험

[![verify-solar-open2-harness](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-solar-open2-harness.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-solar-open2-harness.yml)
[![verify-claude-agent-sdk-local](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-claude-agent-sdk-local.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-claude-agent-sdk-local.yml)
[![verify-langchain-upstage-deepagents](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-upstage-deepagents.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-upstage-deepagents.yml)
[![verify-langchain-openwiki-solar-open2](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-openwiki-solar-open2.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-openwiki-solar-open2.yml)

[English](README.md) / [한국어](README-ko.md)

</div>

Upstage의 Solar Open2 모델과 Claude/LangChain 에이전트 툴링 생태계 위에서
Claude Code 스타일의 에이전트 하네스를 구축하고 구동해보는 세 가지 독립적인
실험을 한 리포에 모았습니다. 세미나/포트폴리오 공유를 염두에 두고 구성했으며,
각 실험은 최상위 디렉토리 하나씩을 차지하고 독립적으로 읽고 실행하고
발표할 수 있습니다.

## 실험 목록

| Case | 요약 | 상태 |
| --- | --- | --- |
| [Case 01 — Solar Open2 하네스](01-solar-open2-harness/) | Upstage Solar Open2 모델을 백엔드로 하는 Claude Code 하네스(스킬 등) 구성 | 검증 완료 |
| [Case 02 — Claude Agent SDK, 로컬 구동](02-claude-agent-sdk-local/) | Claude Agent SDK로 로컬 Claude Code 인스턴스를 프로그래밍 방식으로 구동 | 검증 완료 |
| [Case 03 — LangChain Upstage deepagents](03-langchain-upstage-deepagents/) | LangChain Upstage SDK를 이용해 코드 레벨에서 deepagents 초기화 | 검증 완료 |

## Special Use Cases

위 3가지 핵심 실험과는 별개로, Solar Open2를 대상으로 시도한 좀 더
구체적인 연동 사례입니다 — 앞으로 계속 늘어날 수 있습니다.

| Case | 요약 | 상태 |
| --- | --- | --- |
| [Case 04 — LangChain OpenWiki](04-langchain-openwiki-solar-open2/) | `openwiki`로 이 리포를 문서화하고 질문에 답변 — Solar Open2로 구동 | 검증 완료 |

전체 계획은 [`PLAN.md`](PLAN.md), 리포 규칙은 [`CLAUDE.md`](CLAUDE.md)를 참고하세요.

> 소스 코드와 코드 주석은 영문 전용이며, README는 루트를 포함한 모든
> Case가 EN+KO 쌍으로 제공됩니다.
