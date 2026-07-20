<div align="center">

# jyje/pilot-upstage-solar-open2

<img width="96" src="https://unpkg.com/@lobehub/icons-static-svg@1.91.0/icons/upstage-color.svg" alt="Upstage" title="Upstage"/> <img width="96" src="https://unpkg.com/@lobehub/icons-static-svg@1.91.0/icons/claude-color.svg" alt="Claude" title="Claude"/> <img width="96" src="https://unpkg.com/@lobehub/icons-static-svg@1.91.0/icons/nousresearch.svg" alt="Hermes Agent" title="Hermes Agent"/>

🧪 Claude Code, Claude Agent SDK, LangChain, OpenWiki, Hermes Agent까지 — Upstage Solar Open2를 활용한 모든 유즈케이스!

[![verify-solar-open2-harness](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-solar-open2-harness.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-solar-open2-harness.yml)
[![verify-claude-agent-sdk-local](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-claude-agent-sdk-local.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-claude-agent-sdk-local.yml)
[![verify-langchain-upstage-deepagents](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-upstage-deepagents.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-upstage-deepagents.yml)
[![verify-langchain-openwiki-solar-open2](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-openwiki-solar-open2.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-langchain-openwiki-solar-open2.yml)
[![verify-hermes-agent-solar-open2](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-hermes-agent-solar-open2.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-hermes-agent-solar-open2.yml)

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

## 멀티 모델 검증 이력

위 케이스별 CI 배지는 `solar-open2`만 확인합니다. 이와 별개로
[`verify-all-sequential.yml`](.github/workflows/verify-all-sequential.yml)은
모든 케이스를 여러 Solar 모델로, 케이스×모델 조합 하나씩 순차적으로,
Upstage의 레이트리밋 응답 헤더를 확인하며 대기해가며 실행합니다.
이 계정이 Upstage의 **기본(0) 티어** 한도라고 가정하기 때문에, 코드
버그가 아닌 모델별 간헐적 실패가 있을 수 있습니다 — 아래 표는 단발성
결과가 아니라 반복 실행에 걸친 실제 결과를 기록합니다.

| 날짜 | 실행 | 결과 | 비고 |
| --- | --- | --- | --- |
| 2026-07-20 | [run](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29786476787) | 6/10 | Case 01, 02(`solar-pro3`만): Upstage의 Anthropic 호환 엔드포인트에서 간헐적 `400` — 같은 날 다른 실행에서는 통과했으므로 완전한 미지원은 아님. Case 04(두 모델 모두): 같은 날 반복 테스트로 인한 레이트리밋 소진 — 이후 헤드룸 안전 여유치를 올렸습니다(커밋 `5857fc2`). |

전체 계획은 [`PLAN.md`](PLAN.md), 리포 규칙은 [`AGENTS.md`](AGENTS.md)를 참고하세요.

> 소스 코드와 코드 주석은 영문 전용이며, README는 루트를 포함한 모든
> Case가 EN+KO 쌍으로 제공됩니다.
