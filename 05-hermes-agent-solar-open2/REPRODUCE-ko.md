# Case 05 — 유즈케이스 가이드

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← 이 케이스의 README로 돌아가기](README-ko.md) · [← 전체 케이스 유즈케이스 가이드](../docs/REPRODUCE-ko.md)

목표: Hermes Agent에 내장된 자체 Upstage provider로, 공식 Docker
이미지를 통해 Solar Open2를 구동합니다 — 브리지도 프록시도 없이.

전체 이야기, 발견 사항, 검증 로그: [`README-ko.md`](README-ko.md).

`UPSTAGE_API_KEY` 설정이나 공유 Tier-0 레이트리밋 설명을 아직 안 봤다면
[`docs/REPRODUCE-ko.md`](../docs/REPRODUCE-ko.md)를 먼저 읽어보세요 — 이
문서는 둘 다 이미 준비됐다고 가정합니다.

## 필요한 것

- Docker (데몬이 실행 중이어야 함)

이게 전부입니다. Node도, Python도, `openwiki`도 필요 없습니다.

## 실행

리포 루트에서 먼저 이 디렉토리로 이동한 뒤, 스크립트를 실행하세요:

```bash
cd 05-hermes-agent-solar-open2
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

첫 실행에서는 digest로 고정된 `nousresearch/hermes-agent` 이미지를
받습니다 — 이 다운로드는 처음 한 번만 발생합니다.

## 성공했을 때 화면

```
== Model under test: solar-open2 ==
...
hermes-ready
✓ Hermes completed a live solar-open2 round trip
```

## 문제가 생겼다면

- **`Docker daemon is not available`** — Docker Desktop(또는 Docker
  서비스)을 실행한 뒤 다시 시도하세요.
- **이미지 받는 게 느리다** — 처음 실행이라면 정상입니다. digest로
  고정해뒀기 때문에 이후 실행은 같은 캐시 레이어를 재사용합니다.

## 직접 손으로 테스트해보기

이미지 검증이 끝났다면, 스크립트가 실행하는 것과 동일한 호출을 직접
원하는 프롬프트로 실행해볼 수 있습니다. Hermes는 파일 하나가 아니라
`/opt/data` 디렉토리 전체를 기대하므로, 먼저 디렉토리를 준비하세요
(`05-hermes-agent-solar-open2/` 안에서 실행):

```bash
hermes_home="$(mktemp -d)"
cp config.yaml "$hermes_home/config.yaml"
touch "$hermes_home/.env"
chmod 755 "$hermes_home"
chmod 644 "$hermes_home/config.yaml" "$hermes_home/.env"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e UPSTAGE_API_KEY \
  -v "$hermes_home:/opt/data" \
  --entrypoint hermes \
  nousresearch/hermes-agent@sha256:bb4d1e414918773b9c40e9a50582d582933beb85029b7050164d125f14e3f417 \
  chat --provider upstage --model solar-open2 \
  --query "Reply with exactly: hermes-ready" --max-turns 2 --quiet --ignore-rules

rm -rf "$hermes_home"
```
