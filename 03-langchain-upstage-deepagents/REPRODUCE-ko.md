# Case 03 — 유즈케이스 가이드

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← 이 케이스의 README로 돌아가기](README-ko.md) · [← 전체 케이스 유즈케이스 가이드](../docs/REPRODUCE-ko.md)

목표: `langchain-upstage`가 Solar Open2를 모델로 공급하는 `deepagents`
에이전트를 코드 레벨에서 초기화합니다 — 이 경로에는 `claude` CLI가
전혀 등장하지 않습니다.

전체 이야기, 발견 사항, 검증 로그: [`README-ko.md`](README-ko.md).

`UPSTAGE_API_KEY` 설정이나 공유 Tier-0 레이트리밋 설명을 아직 안 봤다면
[`docs/REPRODUCE-ko.md`](../docs/REPRODUCE-ko.md)를 먼저 읽어보세요 — 이
문서는 둘 다 이미 준비됐다고 가정합니다.

## 필요한 것

- [`uv`](https://docs.astral.sh/uv/)
- Python 3.13 (이 케이스는 3.14가 아닌 3.13을 고정합니다 — 이유는
  [`README-ko.md`](README-ko.md#발견-python-314는-아직-여기서-동작하지-않음)
  참고. 없다면 `uv`가 알아서 준비해줍니다)

그 외엔 없습니다. Node도, `claude` CLI도 필요 없습니다.

## 실행

리포 루트에서 먼저 이 디렉토리로 이동한 뒤, 스크립트를 실행하세요:

```bash
cd 03-langchain-upstage-deepagents
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

## 성공했을 때 화면

```
== Model under test: solar-open2 ==
== demo.py: Methods A/B/C against solar-open2 ==
...
✓ All checks passed.
```

## 문제가 생겼다면

- **`uv run` 중 `tokenizers` 관련 Rust 빌드 에러** — Python 3.14를 쓰고
  있을 가능성이 큽니다. 3.14를 강제하지 말고, `uv`가 고정해둔 3.13을
  그대로 쓰세요.

## 이 케이스를 변경하고 커밋하기 전에

```bash
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

네 개 모두 통과해야 합니다.
