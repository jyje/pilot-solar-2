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
#   D. a subagent (Task tool) call, to confirm CLAUDE_CODE_SUBAGENT_MODEL
#      keeps subagent traffic on solar-open2 too
#
# Each method prints a one-line, <=100-char preview of its real response
# (noise like the "connectors are disabled" warning stripped, newlines
# collapsed) so the CI log itself carries visible, inspectable evidence
# instead of just a pass/fail line.
#
# Requires: `claude` and `claude-upstage` on PATH, UPSTAGE_API_KEY set.

set -euo pipefail

# Always run from this topic's own directory, regardless of the caller's
# cwd — Method D asks a subagent to list "the current directory," and that
# must resolve the same way whether invoked as `./scripts/verify.sh` from
# here or as `01-solar-open2-harness/scripts/verify.sh` from the repo root
# (as CI does).
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }
ok()   { printf '✓ %s\n' "$1"; }

# preview <text> — one line, <=100 chars, real content only.
preview() {
  s="$1"
  s="$(printf '%s' "$s" | grep -v 'connectors are disabled' || true)"
  s="${s//$'\n'/ }"
  s="$(printf '%s' "$s" | sed -E 's/ +/ /g; s/^ //; s/ $//')"
  if [ "${#s}" -gt 100 ]; then
    printf '  -> %s ...(truncated)\n' "${s:0:100}"
  else
    printf '  -> %s\n' "$s"
  fi
}

# strip_wrapper_banner <text> — for claude-upstage's own launch banner
# (host/model/key lines), keep only what `claude` itself printed after it.
strip_wrapper_banner() {
  after="$(printf '%s' "$1" | sed -n '/Launching claude/,$p' | tail -n +2)"
  [ -n "$after" ] && printf '%s' "$after" || printf '%s' "$1"
}

# Runs `claude -p "$1"` against Solar Open2 with the same ANTHROPIC_* env
# vars claude-upstage sets, so Methods B-D share one recipe. $2 overrides
# the default timeout — subagent calls (Method D) run a nested agent and
# need more headroom than a direct completion.
claude_solar() {
  ANTHROPIC_BASE_URL="https://api.upstage.ai" \
  ANTHROPIC_AUTH_TOKEN="$UPSTAGE_API_KEY" \
  ANTHROPIC_MODEL="solar-open2" \
  ANTHROPIC_SMALL_FAST_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="solar-open2" \
  ANTHROPIC_DEFAULT_FABLE_MODEL="solar-open2" \
  CLAUDE_CODE_SUBAGENT_MODEL="solar-open2" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
  timeout "${2:-90}" claude -p "$1" 2>&1
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
preview "$(strip_wrapper_banner "$method_a_out")"

echo
echo "== Method B: official claude CLI with manual ANTHROPIC_* env vars =="
method_b_out="$(claude_solar "hello")" || fail "claude -p \"hello\" exited non-zero"
[ -n "$method_b_out" ] || fail "claude -p \"hello\" produced no output"
ok "claude -p \"hello\" (official CLI, alternate API) produced a response"
preview "$method_b_out"

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
preview "$method_c_out"

echo
echo "== Method D: subagent (Task tool) call via CLAUDE_CODE_SUBAGENT_MODEL =="
method_d_out="$(claude_solar 'Use the Explore agent (a subagent) to list every file directly inside the current directory. Report just the file list.' 180)" \
  || fail "subagent-invocation prompt exited non-zero"
# README.md is a fixed, always-present file in this directory — its
# presence in the report is a cheap, deterministic proxy for "the subagent
# actually ran (on solar-open2, per CLAUDE_CODE_SUBAGENT_MODEL) and saw
# the real filesystem," without pinning exact wording.
printf '%s' "$method_d_out" | grep -q 'README.md' \
  || fail "subagent call didn't report README.md: $method_d_out"
ok "subagent call completed on solar-open2 and saw the real directory"
preview "$method_d_out"

echo
ok "All checks passed."
