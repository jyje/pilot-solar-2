#!/usr/bin/env bash
#
# Runs src/demo.py end-to-end against Upstage's Solar Open2 model via
# langchain-upstage + deepagents, and fails loudly if any of its three
# methods don't check out:
#   A. tool use            - a plain custom tool, invoked and answered
#   B. virtual filesystem  - deepagents' built-in mock file tools
#   C. subagent delegation - a named subagent handles part of the task
#
# Unlike Cases 1-2, this never shells out to the `claude` CLI — only
# `uv` and UPSTAGE_API_KEY are required. Model under test: $SOLAR_MODEL,
# defaulting to solar-open2 (read by demo.py).

set -euo pipefail

# Always run from this case's own directory, regardless of the caller's
# cwd (same reasoning as Cases 1-2's verify.sh).
cd "$(dirname "${BASH_SOURCE[0]}")/.."

export SOLAR_MODEL="${SOLAR_MODEL:-solar-open2}"

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }
ok()   { printf '✓ %s\n' "$1"; }

[ -n "${UPSTAGE_API_KEY:-}" ] || fail "UPSTAGE_API_KEY is not set"
command -v uv >/dev/null 2>&1 || fail "uv not found"

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

printf '%s\n' "$out"

printf '%s' "$out" | grep -q 'All checks passed.' \
  || fail "demo.py did not report success: $out"

ok "All checks passed."
