#!/usr/bin/env bash
#
# Verifies that Claude Code can be driven against Upstage's Solar Open2
# model, and that its skill system works through that backend:
#   A. the `claude-upstage` convenience wrapper (piped stdin, since it
#      doesn't pass an interactive `-p`-style flag through to `claude`)
#   B. the official `claude` CLI directly, with ANTHROPIC_* env vars
#      pointed at Upstage's Anthropic-compatible endpoint
#   C. explicit invocation of the ported `git-commit-helper` skill,
#      checked against its gitmoji + type(domain) format contract
#
# Requires: `claude` and `claude-upstage` on PATH, UPSTAGE_API_KEY set.

set -euo pipefail

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }
ok()   { printf '✓ %s\n' "$1"; }

# Runs `claude -p "$1"` against Solar Open2 with the same ANTHROPIC_* env
# vars claude-upstage sets, so Method B and C share one recipe.
claude_solar() {
  ANTHROPIC_BASE_URL="https://api.upstage.ai" \
  ANTHROPIC_AUTH_TOKEN="$UPSTAGE_API_KEY" \
  ANTHROPIC_MODEL="solar-open2" \
  ANTHROPIC_SMALL_FAST_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="solar-open2" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
  timeout 60 claude -p "$1" 2>&1
}

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
method_b_out="$(claude_solar "hello")" || fail "claude -p \"hello\" exited non-zero"
[ -n "$method_b_out" ] || fail "claude -p \"hello\" produced no output"
ok "claude -p \"hello\" (official CLI, alternate API) produced a response"

echo
echo "== Method C: explicit git-commit-helper skill invocation =="
method_c_out="$(claude_solar 'Use the git-commit-helper skill. A new file docs/hello.txt with a greeting was just added to this repo as a new doc. Write the commit message per that skill'"'"'s exact format (gitmoji + type(domain): title). Output only the commit message.')" \
  || fail "skill-invocation prompt exited non-zero"
[ -n "$method_c_out" ] || fail "skill-invocation prompt produced no output"
# Format contract from git-commit-helper: "<gitmoji> <type>(<domain>): <title>".
# Check loosely — a non-ASCII byte (the gitmoji) and a "(domain):" segment —
# rather than exact wording, since the title text itself isn't deterministic.
printf '%s' "$method_c_out" | LC_ALL=C grep -q '[^ -~]' \
  || fail "skill output has no gitmoji: $method_c_out"
printf '%s' "$method_c_out" | grep -Eq '\([A-Za-z0-9_.-]+\):' \
  || fail "skill output has no type(domain): segment: $method_c_out"
ok "git-commit-helper skill format honored via Solar Open2"

echo
ok "All checks passed."
