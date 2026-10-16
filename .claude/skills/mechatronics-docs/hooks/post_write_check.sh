#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|MultiEdit) while mechatronics-docs is active.
# Validates the file just written if it lies inside a baseproject vault and
# feeds findings back as additionalContext. Fails open on validator crash
# (exit 2) so a validator bug can never brick a session.
SKILL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
out=$(python3 "$SKILL_DIR/validate_vault.py" --hook post 2>/dev/null)
rc=$?
if [ $rc -eq 2 ]; then
  # One JSON object on stdout, not a line on stderr: stderr of a hook exiting
  # 0 reaches nobody. systemMessage tells the user, additionalContext tells
  # the model - the session is the one asked to verify the write by hand.
  printf '%s\n' '{"systemMessage":"vault validator crashed - validation skipped for this write, vault rules are NOT enforced for it","hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"vault validator crashed - validation skipped for this write. Verify the file against the vault conventions by hand."}}'
  exit 0
fi
[ -n "$out" ] && printf '%s\n' "$out"
exit 0
