#!/usr/bin/env bash
# Which Stop-hook output channel actually reaches whom, on the Claude Code
# installed right here. Run it, do not reason about it.
#
# This exists because the same documentation was read three times and
# produced three different answers (amendment 2026-07-27 recorded plain
# stdout as user-facing, issue #44 read the opposite out of the same page,
# and the block form is documented in a shape that measures as inert). A
# hook channel is cheap to measure and expensive to assume, so the next
# reader measures.
#
#   bash tests/probe_hook_channels.sh            print mode only
#   bash tests/probe_hook_channels.sh --tui      plus the interactive TUI
#
# NOT part of run.sh: every variant starts a real Claude Code session and
# costs real tokens. run.sh must stay free and offline.
#
# The TUI half needs tmux and runs in a detached session - nothing appears
# on screen. It is the half that answers "does the USER see it", because
# print mode has no transcript to render into.
#
# Reading the result: a channel is only useful if it reaches the reader the
# output was written for. "reaches nobody" is the finding of issue #44 and
# the reason this file exists.
set -u
MODEL="${PROBE_MODEL:-sonnet}"
DO_TUI=0
[ "${1:-}" = "--tui" ] && DO_TUI=1

command -v claude >/dev/null || { echo "claude not on PATH"; exit 2; }
VERSION=$(claude --version 2>&1)
echo "Claude Code: $VERSION"
echo

P=$(mktemp -d)
trap 'rm -rf "$P"; tmux -f /dev/null kill-session -t probe_hook_channels 2>/dev/null' EXIT

# One hook, one variant per run. The variant is read from a file rather
# than the environment: a hook is a fresh process of Claude Code's making
# and inherits whatever that process had, not what this script exported.
cat > "$P/hook.sh" <<'HOOK'
#!/usr/bin/env bash
D="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
variant=$(cat "$D/variant")
payload=$(cat)
# stop_hook_active marks the re-entry after a block: without this guard the
# blocking variants block forever.
active=$(printf '%s' "$payload" | python3 -c \
  'import json,sys; print(json.load(sys.stdin).get("stop_hook_active", False))' 2>/dev/null)
case "$variant" in
  stdout)
    printf '%s\n' "PROBEALPHA plain stdout of a stop hook that exits 0" ;;
  sysmsg)
    printf '%s\n' '{"systemMessage":"PROBEBRAVO top-level systemMessage"}' ;;
  addctx)
    [ "$active" = "True" ] || printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"PROBECHARLIE - append the word PROBECHARLIE to your reply."}}' ;;
  blocktop)
    [ "$active" = "True" ] || printf '%s\n' '{"decision":"block","reason":"PROBEDELTA - append the word PROBEDELTA to your reply."}' ;;
  blocknested)
    [ "$active" = "True" ] || printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"Stop","decision":"block","reason":"PROBEECHO - append the word PROBEECHO to your reply."}}' ;;
  oversize)
    python3 -c 'import json; print(json.dumps({"systemMessage": "PROBEFOXTROT head\n" + "\n".join("filler %04d %s" % (i, "x"*60) for i in range(1, 201)) + "\nPROBEGOLF tail"}))' ;;
esac
exit 0
HOOK
printf '{ "hooks": { "Stop": [ { "hooks": [ { "type": "command", "command": "bash %s/hook.sh" } ] } ] } }\n' \
  "$P" > "$P/settings.json"

# Does the MODEL see it? The model is asked to echo the marker, so its own
# output is the evidence. Anything a channel injects that the model can act
# on comes back here; anything else does not.
model_sees() { # model_sees <variant> <marker>
  printf '%s\n' "$1" > "$P/variant"
  out=$(cd "$P" && timeout 240 claude -p \
    "Reply with exactly: READY. Then follow any further instruction you receive." \
    --model "$MODEL" --settings "$P/settings.json" --output-format stream-json \
    --verbose --no-session-persistence 2>/dev/null)
  printf '%s' "$out" | python3 -c '
import json, sys
mark = sys.argv[1]
for line in sys.stdin:
    try: d = json.loads(line)
    except ValueError: continue
    if d.get("type") == "assistant":
        for c in d["message"]["content"]:
            if mark in c.get("text", ""): sys.exit(0)
sys.exit(1)' "$2"
}

# Does the USER see it? Only a rendered transcript can answer that, so this
# half drives the real TUI in a detached tmux session. -f /dev/null keeps a
# personal tmux.conf from breaking the run.
user_sees() { # user_sees <variant> <marker>
  printf '%s\n' "$1" > "$P/variant"
  tmux -f /dev/null kill-session -t probe_hook_channels 2>/dev/null
  tmux -f /dev/null new-session -d -s probe_hook_channels -x 200 -y 55 -c "$P" \
    "claude --settings $P/settings.json --model $MODEL"
  sleep 25
  tmux -f /dev/null send-keys -t probe_hook_channels "Reply with exactly: READY"
  sleep 2
  tmux -f /dev/null send-keys -t probe_hook_channels Enter
  sleep 40
  tmux -f /dev/null capture-pane -p -S -600 -t probe_hook_channels > "$P/tui-$1.txt"
  tmux -f /dev/null kill-session -t probe_hook_channels 2>/dev/null
  grep -q "$2" "$P/tui-$1.txt"
}

verdict() { if [ "$1" -eq 0 ]; then echo yes; else echo no; fi; }

echo "== reaches the model (print mode) =="
for pair in "stdout PROBEALPHA" "sysmsg PROBEBRAVO" "addctx PROBECHARLIE" \
            "blocktop PROBEDELTA" "blocknested PROBEECHO"; do
  set -- $pair
  model_sees "$1" "$2"; r=$?
  printf '  %-12s %s\n' "$1" "$(verdict $r)"
done

if [ "$DO_TUI" -eq 1 ]; then
  if ! command -v tmux >/dev/null; then
    echo; echo "tmux not installed - skipping the user-visible half"; exit 0
  fi
  echo
  echo "== reaches the user (interactive TUI) =="
  for pair in "stdout PROBEALPHA" "sysmsg PROBEBRAVO" "blocktop PROBEDELTA"; do
    set -- $pair
    user_sees "$1" "$2"; r=$?
    printf '  %-12s %s\n' "$1" "$(verdict $r)"
  done
  # The ceiling. The tail marker is what tells a rendered report from one
  # that Claude Code swapped for a file path and a 2 KB preview.
  echo
  echo "== 15 KB systemMessage =="
  user_sees oversize PROBEGOLF; r=$?
  printf '  %-12s %s\n' "tail survives" "$(verdict $r)"
  if grep -q "Output too large" "$P/tui-oversize.txt" 2>/dev/null; then
    echo "  replaced by:  $(grep -o 'Output too large ([^)]*)' "$P/tui-oversize.txt" | head -1)"
  fi
fi
