#!/usr/bin/env bash
#
# Runs `openwiki` (github.com/langchain-ai/openwiki) against a scratch
# shallow clone of this very repo (pilot-upstage-solar-open2), configured to use
# Upstage's Solar Open2 model via the `openai-compatible` provider —
# not `anthropic`, which openwiki's own code can't point at Upstage (see
# README.md's first Finding). Never touches this repo's real
# AGENTS.md — everything happens inside scratch/, gitignored.
#
# Requires a patched `openwiki` build — see README.md's second Finding:
# Solar Open2 drops the tool_call function name when streaming, so
# OPENWIKI_DISABLE_STREAMING=true is required (a fix added to
# jyje/openwiki, not yet upstream). `git`, `openwiki` on PATH,
# UPSTAGE_API_KEY set.
#
# The 3-question Q&A is the hard pass/fail gate — cheap, reliable calls.
# Full documentation generation (`code --update`) is attempted as a
# best-effort step and does NOT fail the script: it's a much heavier,
# multi-turn call that has hit Upstage's default 50k-tokens/minute rate
# limit in practice (see README.md's third Finding) — a capacity/tier
# constraint, not a code bug.

set -euo pipefail

# Always run from this case's own directory, regardless of the caller's cwd.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

SOLAR_MODEL="${SOLAR_MODEL:-solar-open2}"
# Absolute path, captured before any `cd` below — ask() calls this before
# every attempt of every question, not just once for the whole case. A
# single upfront check isn't enough: one question alone (openwiki's
# multi-round-trip tool-calling loop) can burn most of the per-minute
# token budget by itself (confirmed live in run 29869480343: question 1
# alone used 36,440 of a 49,998-token budget), so headroom that looked
# fine before question 1 can be gone by question 3. A lighter "wait only
# if headroom looks thin" threshold check wasn't enough either: retries
# kept reporting 0 tokens remaining even after waiting past the reported
# reset instant, since Upstage's limit is a rolling per-minute window,
# not a hard reset clock — so this waits for a *full* reset instead
# (wait-for-upstage-full-reset.sh, 10-minute cap per wait).
FULL_RESET_SCRIPT="$(cd .. && pwd)/scripts/wait-for-upstage-full-reset.sh"

fail() { printf '✗ %s\n' "$1" >&2; exit 1; }
ok()   { printf '✓ %s\n' "$1"; }
warn() { printf '⚠ %s\n' "$1" >&2; }

# preview <text> — one line, <=100 chars, real content only.
preview() {
  s="${1//$'\n'/ }"
  s="$(printf '%s' "$s" | sed -E 's/ +/ /g; s/^ //; s/ $//')"
  if [ "${#s}" -gt 100 ]; then
    printf '  -> %s ...(truncated)\n' "${s:0:100}"
  else
    printf '  -> %s\n' "$s"
  fi
}

[ -n "${UPSTAGE_API_KEY:-}" ] || fail "UPSTAGE_API_KEY is not set"
command -v openwiki >/dev/null 2>&1 || fail "openwiki not found (needs the jyje/openwiki patched build on PATH)"
command -v git >/dev/null 2>&1 || fail "git not found"

echo "== Model under test: $SOLAR_MODEL =="
echo "== cloning a fresh shallow copy of pilot-upstage-solar-open2 into scratch/target =="
rm -rf scratch
mkdir -p scratch
git clone --depth=1 https://github.com/jyje/pilot-upstage-solar-open2 scratch/target >/dev/null 2>&1 \
  || fail "shallow clone failed"
ok "cloned $(git -C scratch/target rev-parse --short HEAD)"

cd scratch/target

export OPENWIKI_PROVIDER=openai-compatible
export OPENAI_COMPATIBLE_API_KEY="$UPSTAGE_API_KEY"
export OPENAI_COMPATIBLE_BASE_URL="https://api.upstage.ai/v1/solar"
export OPENWIKI_MODEL_ID="$SOLAR_MODEL"
export OPENWIKI_DISABLE_STREAMING=true

echo
echo "== 3 questions about this project (hard gate) =="
questions=(
  "What is this repository (pilot-upstage-solar-open2) about?"
  "What did the most recent commit change?"
  "How many experiment cases does this repo have, and what does each one demonstrate?"
)
ask() {
  # Each question alone can consume most of Upstage's default
  # 50k-tokens/minute budget (large system prompt + tool-calling round
  # trips), so wait for a *full* budget reset before every attempt
  # instead of a fixed guessed delay or a "some headroom" threshold. 5
  # attempts, each preceded by a fresh full-reset wait, absorb a real
  # per-minute exhaustion (confirmed live: question 3 kept 429ing across
  # every retry despite waiting past the reported reset instant, because
  # the limit is a rolling window) without masking a genuine failure.
  local q="$1" out=""
  for attempt in 1 2 3 4 5; do
    "$FULL_RESET_SCRIPT" "$SOLAR_MODEL" >&2
    if out="$(timeout 180 openwiki code -p "$q" 2>&1)" && [ -n "$out" ]; then
      printf '%s' "$out"
      return 0
    fi
    if [ "$attempt" -lt 5 ]; then
      warn "attempt $attempt failed — retrying after a fresh headroom check"
      preview "$out" >&2
    fi
  done
  preview "$out" >&2
  return 1
}

for i in "${!questions[@]}"; do
  q="${questions[$i]}"
  echo
  echo "== Question $((i + 1)): $q =="
  a="$(ask "$q")" || fail "question $((i + 1)) failed after retry"
  preview "$a"
  ok "question $((i + 1)) answered"
done
ok "all 3 questions answered"

echo
echo "== openwiki code --update: generate documentation (best-effort) =="
if doc_out="$(timeout 300 openwiki code --update --print \
  "Please generate documentation for this repository, focusing on its purpose and its most recent commit." 2>&1)"; then
  preview "$doc_out"
  if [ -d openwiki ]; then
    ok "documentation generated (openwiki/ exists in the scratch clone)"
  else
    warn "command succeeded but openwiki/ was not created"
  fi
else
  warn "documentation generation failed (known: heavy multi-turn calls can exceed Upstage's default rate limit) — not gating this script's exit status"
  preview "$doc_out"
fi

echo
ok "All checks passed (3-question Q&A gate)."
