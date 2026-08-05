#!/usr/bin/env bash
# Stop hook while mechatronics-docs is active. Blocks the turn end (max 2x
# per session, then fail-open with a visible report) while vault files
# touched this session carry ERRORs that were introduced this session
# (ratcheted against the git HEAD baseline). Fails open on crash.
SKILL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
out=$(python3 "$SKILL_DIR/validate_vault.py" --hook stop 2>/dev/null)
rc=$?
if [ $rc -eq 2 ]; then
  # systemMessage on stdout, not a line on stderr. This is the one message
  # that says enforcement is currently OFF, and stderr of a hook exiting 0
  # reaches nobody - measured on Claude Code 2.1.220, same dead channel as
  # the plain stdout of issue #44.
  printf '%s\n' '{"systemMessage":"vault validator crashed - stop gate released, vault rules are NOT enforced this turn"}'
  exit 0
fi
[ -n "$out" ] && printf '%s\n' "$out"
exit 0
