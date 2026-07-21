#!/usr/bin/env bash
# Verifies Hermes Agent -> Upstage -> Solar Open2 with the official Docker
# image and Hermes's built-in Upstage provider.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

SOLAR_MODEL="${SOLAR_MODEL:-solar-open2}"

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }
ok() { printf '✓ %s\n' "$1"; }

image="${HERMES_IMAGE:-nousresearch/hermes-agent@sha256:bb4d1e414918773b9c40e9a50582d582933beb85029b7050164d125f14e3f417}"
hermes_home="$(mktemp -d)"
cleanup() {
  rm -rf "$hermes_home"
}
trap cleanup EXIT

[ -n "${UPSTAGE_API_KEY:-}" ] || fail "UPSTAGE_API_KEY is not set"
command -v docker >/dev/null 2>&1 || fail "docker is not installed"
docker info >/dev/null 2>&1 || fail "Docker daemon is not available"

cp config.yaml "$hermes_home/config.yaml"
touch "$hermes_home/.env"
chmod 755 "$hermes_home"
chmod 644 "$hermes_home/config.yaml" "$hermes_home/.env"

hermes() {
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e UPSTAGE_API_KEY \
    -v "$hermes_home:/opt/data" \
    --entrypoint hermes \
    "$image" "$@"
}

echo "== Model under test: $SOLAR_MODEL =="

echo
echo "== Check 1: official Hermes Agent image starts =="
version="$(hermes --version)" || fail "Hermes Agent image did not start"
printf '%s\n' "$version"
printf '%s' "$version" | grep -q 'Hermes Agent' \
  || fail "unexpected Hermes version output"
ok "official Hermes Agent image started"

echo
echo "== Check 2: hermes doctor accepts the Upstage configuration =="
doctor_output="$(hermes doctor 2>&1)" || {
  printf '%s\n' "$doctor_output" >&2
  fail "hermes doctor failed"
}
printf '%s\n' "$doctor_output"
printf '%s' "$doctor_output" | grep -qi 'upstage' \
  || fail "hermes doctor did not detect the Upstage provider"
ok "Hermes accepted the Upstage configuration"

echo
echo "== Check 3: live chat round trip via the built-in Upstage provider =="
# This repo's cases share one Upstage account/rate limit, so a chat call
# can 429 simply because another case just ran — retry with backoff.
chat_output=""
passed=false
for attempt in 1 2 3 4 5; do
  if chat_output="$(hermes chat \
    --provider upstage \
    --model "$SOLAR_MODEL" \
    --query 'Reply with exactly: hermes-ready' \
    --max-turns 2 \
    --quiet \
    --ignore-rules 2>&1)" && printf '%s' "$chat_output" | grep -q 'hermes-ready'; then
    passed=true
    break
  fi
  printf '%s\n' "$chat_output" >&2
  if [ "$attempt" -lt 5 ]; then
    printf '  attempt %s failed (possibly rate-limited) — retrying in 30s\n' "$attempt" >&2
    sleep 30
  fi
done
printf '%s\n' "$chat_output"
[ "$passed" = true ] \
  || fail "$SOLAR_MODEL response did not contain hermes-ready after 5 attempts"
ok "Hermes completed a live $SOLAR_MODEL round trip"
