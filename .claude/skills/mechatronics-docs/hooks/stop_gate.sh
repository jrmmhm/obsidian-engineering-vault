#!/usr/bin/env bash
# Stop hook while mechatronics-docs is active. Blocks the turn end (max 2x
# per session, then fail-open with a visible report) while vault files
# touched this session carry ERRORs that were introduced this session
# (ratcheted against the git HEAD baseline). Fails open on crash.
SKILL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
out=$(python3 "$SKILL_DIR/validate_vault.py" --hook stop 2>/dev/null)
rc=$?
if [ $rc -eq 2 ]; then
  echo "vault validator crashed - stop gate released" >&2
  exit 0
fi
[ -n "$out" ] && printf '%s\n' "$out"
exit 0
