# Case 02 — 유즈케이스 가이드

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← 이 케이스의 README로 돌아가기](README-ko.md) · [← 전체 케이스 유즈케이스 가이드](../docs/REPRODUCE-ko.md)

목표: Python `claude-agent-sdk`로 Claude Code를 프로그래밍 방식으로
구동하며, Solar Open2를 상대로 동작을 확인합니다.

전체 이야기, 발견 사항, 검증 로그: [`README-ko.md`](README-ko.md).

`UPSTAGE_API_KEY` 설정이나 공유 Tier-0 레이트리밋 설명을 아직 안 봤다면
[`docs/REPRODUCE-ko.md`](../docs/REPRODUCE-ko.md)를 먼저 읽어보세요 — 이
문서는 둘 다 이미 준비됐다고 가정합니다.

## 필요한 것

- [`uv`](https://docs.astral.sh/uv/)
- 공식 Claude Code CLI ([Case 01](../01-solar-open2-harness/REPRODUCE-ko.md#설치)과 설치 방법 동일)

## 실행

리포 루트에서 먼저 이 디렉토리로 이동한 뒤, 스크립트를 실행하세요:

```bash
cd 02-claude-agent-sdk-local
npm install -g @anthropic-ai/claude-code  # 아직 설치 안 했다면
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

스크립트 내부에서 `uv run python demo.py`를 실행합니다 — 처음 실행할 때
`uv`가 프로젝트의 Python 의존성을 알아서 해석하고 설치해줍니다. 별도의
설치 단계는 필요 없습니다.

## 성공했을 때 화면

```
== Model under test: solar-open2 ==
== demo.py: Methods A/B/C against solar-open2 ==
...
✓ All checks passed.
```

## 문제가 생겼다면

- **호출이 멈추고 응답이 안 온다** — `ANTHROPIC_AUTH_TOKEN` 대신
  `ANTHROPIC_API_KEY`가 환경 어딘가에 설정돼 있다는 강력한 신호입니다.
  `verify.sh`는 이미 올바르게 설정하므로, 직접 `demo.py`를 자신의 환경으로
  돌릴 때만 해당됩니다.
- **`uv not found`** — [uv 문서](https://docs.astral.sh/uv/getting-started/installation/)를
  참고해 설치한 뒤 다시 실행하세요.

## 이 케이스를 변경하고 커밋하기 전에

```bash
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

네 개 모두 통과해야 합니다.
