#!/usr/bin/env bash
#
# Waits for Upstage rate-limit headroom for the given model (via
# wait-for-upstage-headroom.sh), then runs the given case's own
# scripts/verify.sh with that model. Shared by verify-all-sequential.yml
# (CI) and available for local ad-hoc runs — same script, same behavior
# either way. Not case-specific, so it lives here at the repo root like
# wait-for-upstage-headroom.sh, not inside any single case's own
# scripts/ directory.
#
# Usage: verify-case.sh <case-dir> <model>
#   e.g. verify-case.sh 01-solar-open2-harness solar-open2
#
# Requires: UPSTAGE_API_KEY set, plus whatever <case-dir>/scripts/verify.sh
# itself requires (see that case's own header comment) already on PATH.

set -euo pipefail

case_dir="${1:?usage: verify-case.sh <case-dir> <model>}"
model="${2:?usage: verify-case.sh <case-dir> <model>}"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

[ -d "$case_dir/scripts" ] || {
  printf '✗ %s\n' "no such case directory: $case_dir" >&2
  exit 1
}

# claude-upstage (Case 01) installs here; harmless to prepend for every
# other case too.
export PATH="$HOME/.local/bin:$PATH"

./scripts/wait-for-upstage-headroom.sh "$model"

echo
SOLAR_MODEL="$model" "./$case_dir/scripts/verify.sh"
