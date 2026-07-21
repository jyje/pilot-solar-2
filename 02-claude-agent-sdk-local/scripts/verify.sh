#!/usr/bin/env bash
#
# Runs src/demo.py end-to-end against Upstage's Solar Open2 model via the
# Claude Agent SDK (claude-agent-sdk), and fails loudly if any of its
# three methods don't check out:
#   A. query()          - one-shot call, structured message types
#   B. ClaudeSDKClient   - multi-turn session, context retained across turns
#   C. query() + tool use - a ToolUseBlock surfaces in the structured stream
#
# Requires: `uv` and `claude` (npm i -g @anthropic-ai/claude-code) on PATH,
# UPSTAGE_API_KEY set. Model under test: $SOLAR_MODEL, defaulting to
# solar-open2 (read by demo.py). Retries the full A/B/C run up to 5 times
# with a flat 30s backoff — this repo's cases share one Upstage
# account/rate limit, so a run can 429 simply because another case just
# ran.

set -euo pipefail

# Always run from this topic's own directory, regardless of the caller's
# cwd (same reasoning as topic 01's verify.sh).
cd "$(dirname "${BASH_SOURCE[0]}")/.."

export SOLAR_MODEL="${SOLAR_MODEL:-solar-open2}"

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }
ok()   { printf '✓ %s\n' "$1"; }

[ -n "${UPSTAGE_API_KEY:-}" ] || fail "UPSTAGE_API_KEY is not set"
command -v uv >/dev/null 2>&1 || fail "uv not found"
command -v claude >/dev/null 2>&1 || fail "claude CLI not found (npm install -g @anthropic-ai/claude-code)"

cd src

echo "== Model under test: $SOLAR_MODEL =="
echo "== demo.py: Methods A/B/C against $SOLAR_MODEL =="
out=""
passed=false
for attempt in 1 2 3 4 5; do
  if out="$(timeout 180 uv run python demo.py 2>&1)"; then
    passed=true
    break
  fi
  printf '%s\n' "$out" >&2
  if [ "$attempt" -lt 5 ]; then
    printf '  attempt %s failed (possibly rate-limited) — retrying in 30s\n' "$attempt" >&2
    sleep 30
  fi
done
[ "$passed" = true ] || fail "demo.py exited non-zero after 5 attempts"

# Same noise-stripping as topic 01's verify.sh — this warning is emitted
# by `claude` whenever an alternate auth source is set, it's not signal.
printf '%s\n' "$out" | grep -v 'connectors are disabled' || true

printf '%s' "$out" | grep -q 'All checks passed.' \
  || fail "demo.py did not report success: $out"

ok "All checks passed."
