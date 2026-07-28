#!/usr/bin/env bash
# Pre-commit hook: validates the staged vault files without Claude Code.
#
# The Claude Code hooks only fire for Edit/Write/MultiEdit inside one
# editor. Human Obsidian edits, Bash mutations and subagent writes bypass
# them entirely - this hook closes those routes at commit time.
#
# Scope is the staged files, not the whole vault: a vault with unaudited
# history would otherwise report hundreds of legacy findings on every
# commit. The contract is "what you touch, you keep clean".
#
# Reports by default and never blocks. Set MECHDOCS_PRECOMMIT_BLOCK=1 to
# make it refuse a commit whose staged files carry ERRORs.
#
# Install:
#   ln -sf ../../.claude/skills/mechatronics-docs/hooks/pre_commit_vault.sh \
#          .git/hooks/pre-commit
# In a repo without the skill checked in, symlink the copy under
# ~/.claude/skills/mechatronics-docs instead - the fallback below finds it.

SKILL_DIR=$(cd -P -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)
VALIDATOR="$SKILL_DIR/validate_vault.py"
[ -f "$VALIDATOR" ] || VALIDATOR="$HOME/.claude/skills/mechatronics-docs/validate_vault.py"

# Fail open on a missing prerequisite - a hook that blocks commits because
# of its own environment is a hook that gets deleted.
if ! command -v python3 >/dev/null 2>&1; then
  echo "vault validator: python3 not found - validation skipped" >&2
  exit 0
fi
if [ ! -f "$VALIDATOR" ]; then
  echo "vault validator: $VALIDATOR not found - validation skipped" >&2
  exit 0
fi

# -z plus core.quotePath=false: vault filenames carry spaces
# ("REQ_Measurement (MEG).md") and non-ASCII ("...uebersicht.md"), which
# the default output would split or C-quote into an unopenable path.
# ACMR rather than ACM: renaming a note across domains is a routine vault
# operation and is exactly what the filename-prefix check exists for.
findings=""
errors=0
while IFS= read -r -d '' f; do
  case "$f" in *.md) ;; *) continue ;; esac
  [ -f "$f" ] || continue
  out=$(python3 "$VALIDATOR" --file "$f" 2>&1); rc=$?
  if [ $rc -eq 2 ]; then
    # "no vault root" means the file simply lives outside a vault; any
    # other exit 2 is a validator crash and stays visible, fail-open.
    case "$out" in
      *"no vault root found"*) : ;;
      *) echo "vault validator: crashed on $f - validation skipped" >&2 ;;
    esac
    continue
  fi
  hits=$(printf '%s\n' "$out" | grep -E '^(ERROR|WARN) ')
  if [ -n "$hits" ]; then
    findings="${findings}${hits}"$'\n'
    n=$(printf '%s\n' "$hits" | grep -c '^ERROR ')
    errors=$((errors + n))
  fi
done < <(git -c core.quotePath=false diff --cached --name-only --diff-filter=ACMR -z)

[ -n "$findings" ] || exit 0

echo "vault validator - findings in the staged files:"
printf '%s' "$findings" | sed 's/^/  /'

if [ "$errors" -gt 0 ] && [ "${MECHDOCS_PRECOMMIT_BLOCK:-0}" = "1" ]; then
  echo "commit refused: $errors ERROR(s) in staged vault files." >&2
  echo "Fix them, or commit once with MECHDOCS_PRECOMMIT_BLOCK=0." >&2
  exit 1
fi

if [ "$errors" -gt 0 ]; then
  echo "-> $errors ERROR(s), reported only. Set MECHDOCS_PRECOMMIT_BLOCK=1 to block."
fi
exit 0
