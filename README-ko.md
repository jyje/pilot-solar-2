<div align="center">

# jyje/pilot-upstage-solar-open2

<img height="240" src="https://raw.githubusercontent.com/jyje/pilot-upstage-solar-open2/main/docs/images/pilot-upstage-solar-open2.png" alt="Claude Code × Upstage Solar Open2 × Hermes Agent"/>

🧪 Claude Code, Claude Agent SDK, LangChain, OpenWiki, Hermes Agent까지 — Upstage Solar Open2를 활용한 모든 유즈케이스!

[![verify-all-sequential](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml/badge.svg)](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml)

[English](README.md) / [한국어](README-ko.md)

</div>

Upstage의 Solar Open2 모델을 Claude, LangChain, OpenWiki, Hermes Agent
생태계의 에이전트 하네스로 구축하고 구동해보는 여러 독립적인
유즈케이스를 한 리포에 모았습니다. 세미나 공유를 염두에 두고 구성했으며,
각 Case는 최상위 디렉토리 하나씩을 차지하고 독립적으로 읽고 실행하고
발표할 수 있습니다.

## Case 목록

| Case | 요약 | 상태 |
| --- | --- | --- |
| [Case 01 — Solar Open2 x Claude Code](01-solar-open2-harness/) | Upstage Solar Open2 모델을 백엔드로 하는 Claude Code 하네스(스킬 등) 구성 | 검증 완료 |
| [Case 02 — Solar Open2 x Claude Agent SDK](02-claude-agent-sdk-local/) | Claude Agent SDK로 로컬 Claude Code 인스턴스를 프로그래밍 방식으로 구동 | 검증 완료 |
| [Case 03 — Solar Open2 x LangChain Deepagents](03-langchain-upstage-deepagents/) | LangChain Upstage SDK를 이용해 코드 레벨에서 deepagents 초기화 | 검증 완료 |
| [Case 04 — Solar Open2 x LangChain OpenWiki](04-langchain-openwiki-solar-open2/) | `openwiki`로 이 리포를 문서화하고 질문에 답변 — Solar Open2로 구동 | 검증 완료 |
| [Case 05 — Solar Open2 x Hermes Agent](05-hermes-agent-solar-open2/) | Hermes Agent에 공식 번들된 Upstage provider와 공식 Docker 이미지로 구동 | 검증 완료 |

## 구성과 의도

각 Case는 동일한 모델(Solar Open2)을 서로 *다른*, 이미 널리 쓰이는
에이전트 하네스/프레임워크에 연결합니다 — 이 리포만을 위한 커스텀
하네스를 새로 만드는 게 아닙니다. 요점은 Solar Open2가 사람들이 이미
쓰고 있는 오픈 에이전트 생태계에 별도의 전용 도구 없이 바로 꽂히는
백엔드라는 걸 보여주는 것입니다:

- **Case 01/02** — Anthropic 자체 Claude Code CLI와 Claude Agent SDK를
  Anthropic 모델 대신 Solar Open2로 라우팅.
- **Case 03** — LangChain의 `deepagents`에 `langchain-upstage`가 모델을
  공급.
- **Case 04** — `openwiki`(LangChain AI)가 이 리포 자체를 문서화.
- **Case 05** — NousResearch의 Hermes Agent가 자체 번들된 Upstage
  provider로 구동.

모든 Case는 독립적입니다 — 각자 `README.md`/`README-ko.md`, 실제 Upstage
API를 호출하는(모킹 없음) 자체 `scripts/verify.sh`, 그리고 공유 CI
워크플로우 내 자체 스텝을 갖습니다. 각 Case 뒤의 전체 계획과 발견 사항은
[`PLAN.md`](PLAN.md), 리포 구조와 규칙은 [`AGENTS.md`](AGENTS.md), 새
Case 추가나 로컬 실행 방법은 [`CONTRIBUTING.md`](CONTRIBUTING.md)를
참고하세요.

지금 바로, 단계별로 직접 실행해보고 싶다면?
[유즈케이스 가이드](docs/REPRODUCE-ko.md)에서 각 Case마다 필요한 준비물과
정확한 명령어를 하나씩 안내합니다(영문/한글 모두 제공).

## Solar Open2가 기존 에이전트 하네스에 잘 맞는 이유

위 모든 Case는 커스텀 클라이언트가 아니라, 주류 프레임워크가 이미
사용하는 와이어 호환 엔드포인트를 통해 Solar Open2에 도달했습니다:

- Case 01/02는 Claude Code / Claude Agent SDK를 Solar Open2의 Anthropic
  호환 엔드포인트로 `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN`을 통해
  라우팅합니다(실제 발견 사항: `ANTHROPIC_API_KEY`는 Upstage 상대로
  행이 걸리고, `ANTHROPIC_AUTH_TOKEN`이 필요합니다).
- Case 03의 `ChatUpstage`(`langchain-upstage`)는 Upstage의 OpenAI 호환
  엔드포인트를 바라보는 얇은 `BaseChatOpenAI` 서브클래스입니다 — 브리지도
  프록시도 없습니다.
- Case 04의 `openwiki`는 범용 `openai-compatible` provider로 Solar
  Open2에 도달합니다. `anthropic` provider는 여기서 확실한 막다른
  길입니다 — 클라이언트가 `apiKey`(`x-api-key`)만 보내고 `authToken`
  (`Authorization: Bearer`)은 전혀 보내지 않는데, Upstage의 Anthropic
  호환 엔드포인트는 `x-api-key`를 그냥 거부합니다. 전체 추적 과정은
  [Case 04의 README](04-langchain-openwiki-solar-open2/README-ko.md)를
  참고하세요.
- Case 05의 Hermes Agent는 별도 브리지 없이 바로 쓸 수 있는 1급 내장
  `upstage` provider를 제공합니다.

실질적인 결론: 프레임워크가 이미 OpenAI 또는 Anthropic 형태의 와이어
포맷을 구사한다면, 새 에이전트 하네스를 이 목록에 추가하는 작업은 대부분
새로운 통합 코드가 아니라 설정(베이스 URL, 인증 방식, 모델 ID)만으로
끝납니다.

## 티어 0 기준 검증 — 한계와 대처법

이 리포의 모든 Case는 Upstage의 **기본(Tier 0)** 계정 한도로 동작합니다:
Solar 챗 모델 기준 분당 100 요청, 분당 5만 토큰([Upstage rate-limit
가이드](https://console.upstage.ai/ko/docs/guides/rate-limits) 참고).
이 위에서 안정적인 CI 검증 루프를 만들면서 실제로 3가지 실패 양상을
겪었고, 각각 다음과 같이 대응했습니다:

1. **Case 사이에 남은 예산.** 5개 Case를 한 순차 job에서 연달아 돌리면,
   무거운 Case 직후 시작하는 Case는 단순 임계치 검사로는 "충분해
   보이는" 잔여 예산을 물려받았지만 실제로는 부족했습니다. 해결: 이제
   모든 Case는 시작 전에 토큰/요청 예산이 **완전히** 리셋될 때까지
   기다립니다([`scripts/wait-for-upstage-full-reset.sh`](scripts/wait-for-upstage-full-reset.sh),
   최대 10분).
2. **호출 하나가 예산을 다 써버리는 경우.** Case 04의 `openwiki`는 질문
   하나당 여러 번의 순차 tool-calling 왕복을 하며, 매번 전체 시스템
   프롬프트와 툴 스키마를 다시 보냅니다 — 질문 하나만으로 49,998토큰
   예산 중 36,440토큰을 소모한 사례가 관측됐습니다. Upstage의 한도는
   고정된 리셋 시점이 아니라 *rolling* 분당 윈도우이기 때문에, 재시도가
   보고된 리셋 시점을 지나서도 계속 0토큰 잔여로 나타났습니다. 해결:
   Case 04 내부에서는 케이스당 한 번이 아니라 매 재시도 시도 전마다
   동일한 완전 리셋 대기를 적용합니다.
3. **`solar-pro3`는 Case 04에서 Tier 0으로는 부족합니다** — 에이전틱
   루프의 몇 번의 호출 누적 사용량만으로도 분당 5만 토큰 예산을 초과해
   버립니다. 잔여 예산 문제와는 무관합니다. 이 리포 코드의 버그가
   아니라, 계정이 **Tier 1 이상**이면 동작할 것으로 예상됩니다. 전체
   추적 과정은 [`PLAN.md`](PLAN.md)의 Case 04, Finding 4를 참고하세요.

이런 이유로 [`verify-all-sequential.yml`](.github/workflows/verify-all-sequential.yml)은
5개 Case를 고정된 추측성 지연이 아니라 실제 Upstage rate-limit 응답
헤더를 근거로 **한 번에 하나씩** 순차 실행합니다 — Tier-0 계정에서는
전체 실행에 10~20분 이상 걸릴 수 있습니다. 더 높은 티어라면 대기 시간이
대부분 사라지겠지만, 이 리포는 그런 티어를 전제하지 않습니다.

## 최근 검증 실행

✅ `solar-open2` 기준 5/5 Case 통과 —
[run 29870650705](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/29870650705)
(2026-07-21):

| Case | solar-open2 |
| --- | --- |
| Case 01 — Solar Open2 x Claude Code | ✅ |
| Case 02 — Solar Open2 x Claude Agent SDK | ✅ |
| Case 03 — Solar Open2 x LangChain Deepagents | ✅ |
| Case 04 — Solar Open2 x LangChain OpenWiki | ✅ |
| Case 05 — Solar Open2 x Hermes Agent | ✅ |

최신 상태는 위 배지를 확인하거나
[모든 실행 목록](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-all-sequential.yml)을
둘러보세요.

## 기여하기

리포 규칙, Case별 로컬 실행 명령, 새 Case 추가 방법은
[`CONTRIBUTING.md`](CONTRIBUTING.md)를 참고하세요(영문 전용 — 이 리포의
코드/규칙 문서 관례를 따릅니다).

> 소스 코드와 코드 주석은 영문 전용이며, README는 루트를 포함한 모든
> Case가 EN+KO 쌍으로 제공됩니다.
