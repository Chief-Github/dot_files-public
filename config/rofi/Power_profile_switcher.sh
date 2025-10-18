#!/usr/bin/env bash
#   /***********************/
#      Made by Chief-github
#    /**********************/
set -euo pipefail

pp_performance='Performance'
pp_balanced='Balanced'
pp_powersaver='Power-saving'



case "${ROFI_RETV:-0}" in
  0)
    # First run: print menu entries
    printf '%s\n%s\n%s\n%s\n%s\n' "$pp_performance" "$pp_balanced" "$pp_powersaver"
    ;;
  1)
    # Second run: handle selection
    case "$1" in
      "$pp_performance") powerprofilesctl set performance; notify-send "Power_switcher" --transient "set to performance ⚡" ;;
      "$pp_balanced") powerprofilesctl set balanced; notify-send "Power_switcher" --transient "set to balanced ⚖️" ;;
      "$pp_powersaver")  powerprofilesctl set power-saver; notify-send "Power_switcher" --transient "set to powersave 🌿" ;;
    esac
    ;;
esac
