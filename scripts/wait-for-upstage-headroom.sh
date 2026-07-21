#!/usr/bin/env bash
#
# Probes Upstage's rate-limit response headers for $1 (the model the
# *next* CI step is about to use) and sleeps only if headroom is
# actually low or already exceeded — waiting exactly until the reported
# reset/retry-after time, not a guessed fixed duration. Used between
# steps in verify-all-sequential.yml; not part of any case's own
# scripts/verify.sh, since it isn't case-specific.
#
# Every Upstage API response (success or 429) carries these headers —
# there's no separate "check quota" endpoint. See:
# https://console.upstage.ai/ko/docs/guides/rate-limits
#
# Usage: wait-for-upstage-headroom.sh <model>
# Requires: UPSTAGE_API_KEY set.

set -euo pipefail

model="${1:?usage: wait-for-upstage-headroom.sh <model>}"

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }

[ -n "${UPSTAGE_API_KEY:-}" ] || fail "UPSTAGE_API_KEY is not set"

headers="$(mktemp)"
trap 'rm -f "$headers"' EXIT

# A minimal, cheap request — its purpose is reading the response
# headers, not the answer itself.
curl -s -o /dev/null -D "$headers" \
  -H "Authorization: Bearer $UPSTAGE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}" \
  https://api.upstage.ai/v1/solar/chat/completions \
  || fail "probe request to Upstage failed"

header_value() {
  # The header may legitimately be absent (e.g. Retry-After only appears
  # on a 429) — grep finding no match is not a real failure here.
  grep -i "^$1:" "$headers" | tr -d '\r' | awk '{print $2}' | tail -n1 || true
}

remaining_requests="$(header_value 'X-Upstage-RateLimit-Remaining-Requests')"
remaining_tokens="$(header_value 'X-Upstage-RateLimit-Remaining-Tokens')"
reset_requests="$(header_value 'X-Upstage-RateLimit-Reset-Requests')"
reset_tokens="$(header_value 'X-Upstage-RateLimit-Reset-Tokens')"
retry_after_requests="$(header_value 'X-Upstage-RateLimit-Retry-After-Requests')"
retry_after_tokens="$(header_value 'X-Upstage-RateLimit-Retry-After-Tokens')"

echo "== $model headroom: requests remaining=${remaining_requests:-?} tokens remaining=${remaining_tokens:-?} =="

now="$(date +%s)"
wait_until=0

# A 429 on the probe itself means Retry-After is authoritative.
for ts in "$retry_after_requests" "$retry_after_tokens"; do
  if [ -n "$ts" ] && [ "$ts" -gt "$wait_until" ] 2>/dev/null; then
    wait_until="$ts"
  fi
done

# Otherwise, only wait if the remaining headroom looks thin — a whole
# case can make several calls, so leave margin rather than cutting it
# exactly to zero. The token margin is deliberately large: a single
# heavy call (e.g. Case 04's openwiki, large system prompt + tool
# calling) can burn tens of thousands of tokens by itself — a probe
# showing "headroom available" isn't enough if that one call alone
# would blow through most of what's left (seen live: Case 04 failed
# with headroom reported "available" right before it, in run
# 29786476787).
if [ "$wait_until" -eq 0 ]; then
  if [ -n "$remaining_requests" ] && [ "$remaining_requests" -le 5 ] 2>/dev/null \
    && [ -n "$reset_requests" ] && [ "$reset_requests" -gt "$wait_until" ] 2>/dev/null; then
    wait_until="$reset_requests"
  fi
  if [ -n "$remaining_tokens" ] && [ "$remaining_tokens" -le 25000 ] 2>/dev/null \
    && [ -n "$reset_tokens" ] && [ "$reset_tokens" -gt "$wait_until" ] 2>/dev/null; then
    wait_until="$reset_tokens"
  fi
fi

if [ "$wait_until" -gt "$now" ] 2>/dev/null; then
  # +12s, not +2: confirmed live that a request landing right at the
  # reported reset instant can still 429 (window refill isn't perfectly
  # instantaneous, and there's real network/API latency on top).
  secs=$((wait_until - now + 12))
  echo "Headroom low — waiting ${secs}s for Upstage's rate-limit window to reset."
  sleep "$secs"
else
  echo "Headroom available — proceeding immediately."
fi
