<div align="center">

# jyje/pilot-upstage-solar-open2

<img height="240" src="https://raw.githubusercontent.com/jyje/pilot-upstage-solar-open2/main/docs/images/pilot-upstage-solar-open2.png" alt="Claude Code × Upstage Solar Open2 × Hermes Agent"/>

🧪 Claude Code, Claude Agent SDK, LangChain, OpenWiki, Hermes Agent까지 — Upstage Solar Open2를 활용한 모든 유즈케이스!

[![verify-all-sequential](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml)

[English](README.md) / [한국어](README-ko.md)

</div>

Upstage의 Solar Open2 모델을 Claude, LangChain, OpenWiki, Hermes Agent
생태계의 에이전트 하네스로 구축하고 구동해보는 여러 독립적인
유즈케이스를 한 리포에 모았습니다. 세미나/포트폴리오 공유를 염두에 두고
구성했으며, 각 Case는 최상위 디렉토리 하나씩을 차지하고 독립적으로 읽고
실행하고 발표할 수 있습니다.

## Case 목록

| Case | 요약 | 상태 |
| --- | --- | --- |
| [Case 01 — Solar Open2 x Claude Code](01-solar-open2-harness/) | Upstage Solar Open2 모델을 백엔드로 하는 Claude Code 하네스(스킬 등) 구성 | 검증 완료 |
| [Case 02 — Solar Open2 x Claude Agent SDK](02-claude-agent-sdk-local/) | Claude Agent SDK로 로컬 Claude Code 인스턴스를 프로그래밍 방식으로 구동 | 검증 완료 |
| [Case 03 — Solar Open2 x LangChain Deepagents](03-langchain-upstage-deepagents/) | LangChain Upstage SDK를 이용해 코드 레벨에서 deepagents 초기화 | 검증 완료 |
| [Case 04 — Solar Open2 x LangChain OpenWiki](04-langchain-openwiki-solar-open2/) | `openwiki`로 이 리포를 문서화하고 질문에 답변 — Solar Open2로 구동 | 검증 완료 |
| [Case 05 — Solar Open2 x Hermes Agent](05-hermes-agent-solar-open2/) | Hermes Agent에 공식 번들된 Upstage provider와 공식 Docker 이미지로 구동 | 검증 완료 |

전체 계획은 [`PLAN.md`](PLAN.md), 리포 규칙은 [`AGENTS.md`](AGENTS.md)를 참고하세요.

> 소스 코드와 코드 주석은 영문 전용이며, README는 루트를 포함한 모든
> Case가 EN+KO 쌍으로 제공됩니다.
