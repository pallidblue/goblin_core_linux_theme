#!/usr/bin/env bash

set -euo pipefail

WINDOW="volume-popup"
DURATION="4s"
COMMAND="${1:-}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCK_FILE="$RUNTIME_DIR/eww-volume-popup-${UID}.lock"
STATE_FILE="$RUNTIME_DIR/eww-volume-popup-${UID}.state"

case "$COMMAND" in
  up)   pamixer --increase 5 ;;
  down) pamixer --decrease 5 ;;
  mute) pamixer --toggle-mute ;;
  set)
    if [[ -z "${2:-}" ]]; then
      echo "Usage: $0 set <0-100>" >&2
      exit 1
    fi
    pamixer --set-volume "$2"
    ;;
  get)
    pamixer --get-volume
    exit 0
    ;;
  *)
    echo "Usage: $0 <up|down|mute|set|get> [value]" >&2
    exit 1
    ;;
esac

vol=$(pamixer --get-volume)
mute=$(pamixer --get-mute)

eww update volume_percent="$vol"
eww update volume_mute="$mute"

request_id="${BASHPID}-$(date +%s%N)"
(
  flock -x 9
  if ! eww active-windows | grep -Fq ": $WINDOW"; then
    eww open "$WINDOW"
  fi
  printf '%s\n' "$request_id" > "$STATE_FILE"
) 9>"$LOCK_FILE"

(
  sleep "${DURATION%s}"
  flock -x 9
  if [[ "$(cat "$STATE_FILE" 2>/dev/null || true)" == "$request_id" ]]; then
    eww close "$WINDOW"
    rm -f "$STATE_FILE"
  fi
) 9>"$LOCK_FILE" >/dev/null 2>&1 &