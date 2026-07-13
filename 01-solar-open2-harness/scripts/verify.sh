#!/usr/bin/env bash
#
# Verifies that Claude Code can be driven against Upstage's Solar Open2
# model two ways:
#   A. the `claude-upstage` convenience wrapper (piped stdin, since it
#      doesn't pass an interactive `-p`-style flag through to `claude`)
#   B. the official `claude` CLI directly, with ANTHROPIC_* env vars
#      pointed at Upstage's Anthropic-compatible endpoint
#
# Requires: `claude` and `claude-upstage` on PATH, UPSTAGE_API_KEY set.

set -euo pipefail

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }
ok()   { printf '✓ %s\n' "$1"; }

[ -n "${UPSTAGE_API_KEY:-}" ] || fail "UPSTAGE_API_KEY is not set"
command -v claude >/dev/null 2>&1 || fail "claude CLI not found (npm install -g @anthropic-ai/claude-code)"
command -v claude-upstage >/dev/null 2>&1 || fail "claude-upstage not found (see README.md Installation)"

echo "== claude-upstage doctor =="
claude-upstage doctor || fail "claude-upstage doctor reported a problem"
ok "claude-upstage doctor passed"

echo
echo "== Method A: claude-upstage (piped stdin, non-interactive) =="
method_a_out="$(printf 'hello\n' | timeout 60 claude-upstage 2>&1)" \
  || fail "claude-upstage (piped stdin) exited non-zero"
[ -n "$method_a_out" ] || fail "claude-upstage (piped stdin) produced no output"
ok "claude-upstage (piped stdin) produced a response"

echo
echo "== Method B: official claude CLI with manual ANTHROPIC_* env vars =="
method_b_out="$(
  ANTHROPIC_BASE_URL="https://api.upstage.ai" \
  ANTHROPIC_AUTH_TOKEN="$UPSTAGE_API_KEY" \
  ANTHROPIC_MODEL="solar-open2" \
  ANTHROPIC_SMALL_FAST_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="solar-open2" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
  timeout 60 claude -p "hello" 2>&1
)" || fail "claude -p \"hello\" exited non-zero"
[ -n "$method_b_out" ] || fail "claude -p \"hello\" produced no output"
ok "claude -p \"hello\" (official CLI, alternate API) produced a response"

echo
ok "All checks passed."
