#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|MultiEdit) while mechatronics-docs is active.
# Validates the file just written if it lies inside a baseproject vault and
# feeds findings back as additionalContext. Fails open on validator crash
# (exit 2) so a validator bug can never brick a session.
SKILL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
out=$(python3 "$SKILL_DIR/validate_vault.py" --hook post 2>/dev/null)
rc=$?
if [ $rc -eq 2 ]; then
  echo "vault validator crashed - validation skipped for this write" >&2
  exit 0
fi
[ -n "$out" ] && printf '%s\n' "$out"
exit 0
