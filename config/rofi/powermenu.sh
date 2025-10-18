#!/usr/bin/env bash
#   /***********************/
#      Made by Chief-github
#    /**********************/
set -euo pipefail

shutdown='⏻ Shutdown'
reboot=' Reboot'
lock=' Lock'
suspend=' Suspend'
logout=' Logout'

have() { command -v "$1" >/dev/null 2>&1; }

do_lock() {
  if   have hyprlock; then hyprlock
  else notify-send "No lock tool found (Make sure hyprlock is installed!)."
  fi
}

do_logout() {
  if   have hyprctl; then hyprctl dispatch exit
  else notify-send "Hyprctl dispatch exit failed"
  fi
}

case "${ROFI_RETV:-0}" in
  0)
    # First run: print menu entries
    printf '%s\n%s\n%s\n%s\n%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown"
    ;;
  1)
    # Second run: handle selection
    case "$1" in
      "$lock") do_lock ;;
      "$suspend") systemctl suspend ;;
      "$logout")  do_logout ;;
      "$reboot")  systemctl reboot ;;
      "$shutdown")systemctl poweroff ;;
    esac
    ;;
esac
