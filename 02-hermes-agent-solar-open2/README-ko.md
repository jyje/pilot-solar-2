# Case 02 — Solar Open 2 x Hermes Agent

[English](README.md) / [한국어](README-ko.md)

[← 리포 개요로 돌아가기](../README-ko.md) · 직접 실행해보고 싶다면?
[`REPRODUCE-ko.md`](REPRODUCE-ko.md)에서 단계별 로컬 실행 방법을
확인하세요.

**상태:** 검증 완료 — 공식 Hermes Agent 이미지가 내장 Upstage
provider를 통해 `solar-open2`와 실제 연결 테스트를 완료했습니다.

## 목표

공식 Docker 이미지의 [Hermes
Agent](https://github.com/NousResearch/hermes-agent)를 프로토콜 변환
프록시 없이 Upstage **Solar Open 2** 모델에 직접 연결합니다.

## 공식 지원 확인

**Hermes 연동은 공식 지원입니다.** Hermes Agent v0.18.2의 공식
Docker 이미지에 `upstage` provider가 번들되어 있고 `solar`도
별칭으로 지원합니다. 번들 provider 구현은 `solar-open*` 모델
계열을 명시적으로 처리하여 Upstage의 OpenAI-compatible API로
라우팅합니다. 로컬 플러그인, custom endpoint, LiteLLM 프록시,
소스 패치가 필요하지 않습니다.

따라서 모델 설정은 다음이 전부입니다.

```yaml
model:
  provider: upstage
  default: solar-open2
```

인증 정보는 YAML에 저장하지 않고 `UPSTAGE_API_KEY` 환경 변수로
전달합니다. Hermes가 직접 유지보수·배포하는 provider 경로입니다.

### `solar-open2` 자체도 공식 제공될까요?

**Hermes provider 지원**과 **Upstage 모델 제공 여부**는 구분해야 합니다.

- Hermes는 Upstage provider를 공식 지원하고 Solar Open 모델 계열을
  명시적으로 인식합니다.
- Upstage의 현재 공개 콘솔 예제는 `solar-pro3`를 사용하며,
  `solar-open2`를 현재 기본 공개 모델로 안내하지는 않습니다.

따라서 이 Case는 모든 신규 Upstage 계정에서 `solar-open2`를 선택할
수 있다고 단정하지 않습니다. 이 리포지토리의 계정에 해당 모델이
여전히 활성화되어 있는지는 실제 연결 테스트로 확정합니다.
이 리포의 다른 네 Case가 이미 그 계정에서 `solar-open2`를 검증했고,
이 Case는 2026-07-20에 다시 확인했습니다.

## 실행

Upstage 개발용 키를 설정한 다음 검증 스크립트를 실행합니다.

```bash
export UPSTAGE_API_KEY="..."
./scripts/verify.sh
```

스크립트는 digest로 고정한 공식 Hermes Agent 이미지를 사용하고,
[`config.yaml`](config.yaml)이 들어 있는 임시 `/opt/data` 디렉터리를
마운트한 후 세 가지를 확인합니다.

1. 이미지가 Hermes Agent 버전을 출력하는지
2. `hermes doctor`가 Upstage 설정을 인식하는지
3. non-interactive `hermes chat`이 `solar-open2`에서 `hermes-ready`를
   반환하는지

에이전트의 terminal backend는 `local`입니다. 따라서 tool 명령은 이미
격리된 Hermes 컨테이너 안에서 실행됩니다. 이 검증에서는 호스트
리포지토리를 컨테이너에 마운트하지 않습니다.

## 수동 실행

스크립트가 실제로 호출하는 명령은 다음과 같습니다.

```bash
hermes chat \
  --provider upstage \
  --model solar-open2 \
  --query "Reply with exactly: hermes-ready" \
  --max-turns 2 \
  --quiet \
  --ignore-rules
```

연결된 GitHub Actions workflow는 리포지토리의 기존
`UPSTAGE_API_KEY` secret을 재사용합니다.

## 검증 결과

2026-07-20에 로컬로 검증했고, 2026-07-23 CI
([`verify` job](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30008688179/job/89210972882))에서
다시 확인했습니다. 구성은 다음과 같습니다.

- Hermes Agent v0.18.2 (`2026.7.7.2`, upstream `59fdd41f`)
- digest로 고정한 공식 `nousresearch/hermes-agent` 이미지
- Hermes에 번들된 `upstage` provider
- Upstage 모델 ID `solar-open2`

`hermes doctor`는 `Upstage Solar` 연결을 정상으로 판정했습니다. 다른
Case들과 달리 이 스크립트는 채팅 출력을 전혀 자르지 않습니다 —
2026-07-23 CI 실행의 실제 응답에는 Solar Open 2가 정해진 답을 내놓기
전에 거친 짧은 추론 과정까지 그대로 담겨 있습니다.

```text
The user wants me to reply with exactly "hermes-ready" with no other
text or formatting.The user wants me to reply with exactly
"hermes-ready" with no other text or formatting.
hermes-ready
```

## 출처

- [Hermes Agent CLI 레퍼런스](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/reference/cli-commands.md)
- [Hermes Agent provider 가이드](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/integrations/providers.md)
- [Hermes Agent Docker 가이드](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/docker.md)
- [Upstage Chat with Reasoning 예제](https://console.upstage.ai/api-keys?api=chat-reasoning)
