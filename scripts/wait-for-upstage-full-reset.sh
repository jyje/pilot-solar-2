#!/usr/bin/env bash
#
# Waits, at the start of each case, until Upstage's rate-limit window for
# $1 is fully reset (not just "some headroom") before letting that case
# begin — so every case starts with a full budget regardless of what
# earlier cases in the same sequential run already used. Confirmed live
# (run 29841216939): Case 04 starved on its 3rd question because it
# started with only ~15k tokens left over from Cases 01-03, even though
# wait-for-upstage-headroom.sh's threshold check (25k) had judged that
# "enough" headroom to begin the case at all.
#
# Hard 10-minute cap: if the window hasn't shown as fully reset by then,
# fail loudly rather than hang the whole sequential run indefinitely.
#
# Distinct from wait-for-upstage-headroom.sh, which Case 04's own
# scripts/verify.sh still uses internally between its 3 questions (a
# lighter "is there enough left for one more call" check, not a full
# reset) — this script is only for the once-per-case entry point in
# verify-case.sh.
#
# Usage: wait-for-upstage-full-reset.sh <model>
# Requires: UPSTAGE_API_KEY set.

set -euo pipefail

model="${1:?usage: wait-for-upstage-full-reset.sh <model>}"
deadline=$(($(date +%s) + 600))

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }

[ -n "${UPSTAGE_API_KEY:-}" ] || fail "UPSTAGE_API_KEY is not set"

probe() {
  local headers
  headers="$(mktemp)"
  curl -s -o /dev/null -D "$headers" \
    -H "Authorization: Bearer $UPSTAGE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}" \
    https://api.upstage.ai/v1/solar/chat/completions \
    || {
      rm -f "$headers"
      fail "probe request to Upstage failed"
    }
  cat "$headers"
  rm -f "$headers"
}

header_value() {
  # $1 = header name, $2 = raw header text. May legitimately be absent.
  printf '%s' "$2" | grep -i "^$1:" | tr -d '\r' | awk '{print $2}' | tail -n1 || true
}

attempt=0
while :; do
  attempt=$((attempt + 1))
  headers_text="$(probe)"

  remaining_tokens="$(header_value 'X-Upstage-RateLimit-Remaining-Tokens' "$headers_text")"
  limit_tokens="$(header_value 'X-Upstage-RateLimit-Limit-Tokens' "$headers_text")"
  remaining_requests="$(header_value 'X-Upstage-RateLimit-Remaining-Requests' "$headers_text")"
  limit_requests="$(header_value 'X-Upstage-RateLimit-Limit-Requests' "$headers_text")"
  reset_tokens="$(header_value 'X-Upstage-RateLimit-Reset-Tokens' "$headers_text")"

  echo "== $model reset-check #$attempt: tokens ${remaining_tokens:-?}/${limit_tokens:-?}, requests ${remaining_requests:-?}/${limit_requests:-?} =="

  # "Fully reset" = remaining is at (or extremely close to) the limit —
  # a small epsilon since this very probe call itself costs a sliver of
  # the budget, so an exact match is never realistic.
  if [ -n "$remaining_tokens" ] && [ -n "$limit_tokens" ] \
    && [ -n "$remaining_requests" ] && [ -n "$limit_requests" ] \
    && [ "$((limit_tokens - remaining_tokens))" -le 100 ] 2>/dev/null \
    && [ "$((limit_requests - remaining_requests))" -le 2 ] 2>/dev/null; then
    echo "Budget is fresh — starting the case."
    exit 0
  fi

  now="$(date +%s)"
  [ "$now" -lt "$deadline" ] || fail "budget never showed as fully reset within 10 minutes"

  wait_secs=15
  if [ -n "$reset_tokens" ] && [ "$reset_tokens" -gt "$now" ] 2>/dev/null; then
    candidate=$((reset_tokens - now + 5))
    [ "$candidate" -gt "$wait_secs" ] && wait_secs="$candidate"
  fi
  remaining_budget=$((deadline - now))
  [ "$wait_secs" -gt "$remaining_budget" ] && wait_secs="$remaining_budget"

  echo "Not fresh yet — waiting ${wait_secs}s before checking again."
  sleep "$wait_secs"
done
