#!/bin/bash
# Sets the iTerm tab status (OSC 21337) from Claude Code hook events.

input=$(cat)
IFS=$'\x1f' read -r event cwd session < <(
  printf '%s' "$input" | jq -r '[.hook_event_name, .cwd, .session_id] | map(. // "") | join("\u001f")'
)

pid=$PPID
while [ "${pid:-1}" -gt 1 ]; do
  [ "$(ps -o comm= -p "$pid")" = claude ] && break
  pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
done
[ "${pid:-1}" -gt 1 ] || exit 0
tty=$(ps -o tty= -p "$pid" | tr -d ' ')
[ -n "$tty" ] && [ "$tty" != "??" ] && [ -w "/dev/$tty" ] || exit 0

state_file="${TMPDIR:-/tmp}/claude-tab-status/${session:-$pid}"
mkdir -p "${state_file%/*}"

send() {
  printf '\e]21337;status=%s;indicator=%s;status-color=%s\a' "$1" "$2" "$3" > "/dev/$tty"
}

where() {
  local top branch
  top=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$top" ]; then
    printf '%s' "${cwd/#$HOME/~}"
    return
  fi
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [[ "$branch" =~ ^([A-Z]+-[A-Z0-9]+)- ]]; then
    branch=${BASH_REMATCH[1]}
  elif [ "${#branch}" -gt 24 ]; then
    branch="${branch:0:23}…"
  fi
  printf '%s @ %s' "${top##*/}" "$branch"
}

bg_count() {
  ps -A -o ppid=,command= | awk -v p="$pid" '$1 == p && /shell-snapshots\/snapshot-/' | wc -l | tr -d ' '
}

case "$event" in
  UserPromptSubmit)
    send "Working · $(where)" '#0a84ff' '#8e8e93'
    echo working > "$state_file" ;;
  Notification|PreToolUse)
    send "Waiting · $(where)" '#ff9f0a' '#ff9f0a'
    echo waiting > "$state_file" ;;
  PostToolUse)
    [ "$(cat "$state_file" 2>/dev/null)" = waiting ] || exit 0
    send "Working · $(where)" '#0a84ff' '#8e8e93'
    echo working > "$state_file" ;;
  Stop)
    n=$(bg_count)
    if [ "$n" -gt 0 ]; then
      send "Running · $(where) · $n bg" '#bf5af2' '#bf5af2'
    else
      send "Done $(date +%H:%M) · $(where)" '#30d158' '#8e8e93'
    fi
    echo done > "$state_file" ;;
  SessionEnd)
    printf '\e]21337;status=;indicator=;status-color=\a' > "/dev/$tty"
    rm -f "$state_file" ;;
esac
exit 0
