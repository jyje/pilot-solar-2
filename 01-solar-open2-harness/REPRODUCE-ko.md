# Case 01 — 유즈케이스 가이드

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← 이 케이스의 README로 돌아가기](README-ko.md) · [← 전체 케이스 유즈케이스 가이드](../docs/REPRODUCE-ko.md)

목표: Claude Code 자체를 Solar Open2로 구동하고, 커스텀 스킬과
서브에이전트가 이 백엔드에서도 그대로 동작하는지 확인합니다.

전체 이야기, 발견 사항, 검증 로그: [`README-ko.md`](README-ko.md).

`UPSTAGE_API_KEY` 설정이나 공유 Tier-0 레이트리밋 설명을 아직 안 봤다면
[`docs/REPRODUCE-ko.md`](../docs/REPRODUCE-ko.md)를 먼저 읽어보세요 — 이
문서는 둘 다 이미 준비됐다고 가정합니다.

## 필요한 것

- Node.js 18 이상
- 공식 Claude Code CLI
- Upstage의 `claude-upstage` 래퍼

## 설치

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

```bash
curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh -s install
```

`sh`로 바로 실행하기 전에 스크립트를 먼저 읽어보고 싶다면:

```bash
curl -fsSL https://console.upstage.ai/claude-upstage.sh -o claude-upstage.sh
less claude-upstage.sh
sh claude-upstage.sh
```

## 실행

리포 루트에서 먼저 이 디렉토리로 이동한 뒤, 스크립트를 실행하세요:

```bash
cd 01-solar-open2-harness
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

## 성공했을 때 화면

스크립트는 네 개의 체크 결과를 한 줄씩, 각각 `✓`로 시작하게 출력합니다:

```
✓ claude-upstage doctor
✓ Method A ...
✓ git-commit-helper skill format honored via solar-open2
✓ subagent call completed on solar-open2 and saw the real directory
✓ All checks passed.
```

## 문제가 생겼다면

- **`claude-upstage: unknown command '-p'`** — 예상된 동작이며, 이 리포의
  버그가 아닙니다. `claude-upstage`는 `-p`를 전달하지 않습니다. 스크립트는
  이미 표준입력을 파이프하는 방식(`echo "hello" | claude-upstage`)을 쓰고
  있습니다 — 직접 손으로 테스트할 때도 똑같이 하세요.
- **응답이 Solar Open2가 아닌 것 같다** — `ANTHROPIC_MODEL` 하나만이 아니라
  모든 `ANTHROPIC_*` 모델 슬롯 변수가 설정됐는지 확인하세요. 전체 목록은
  [`README-ko.md`](README-ko.md#동작-원리)의 "동작 원리" 절을 참고하세요.
