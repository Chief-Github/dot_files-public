#!/usr/bin/env bash


#   /***********************/
#      Made by Chief-github
#    /**********************/


# https://github.com/Chief-Github

set -euo pipefail

Purple='Car/purple'
Sunset='Sunset'
holiday="Holiday"
random_theme_wallpaper='Random theme wallpaper'
Disableconky='Disable conky'
Enableconky='Enable conky'
reloadall='Reload all'
debug='debug'

theme=$(<"$HOME/.config/rofi/current_theme.txt")

############################################################################################################

do_change_sunset() {
  pkill -9 conky 2>/dev/null || true
  pkill -9 cava 2>/dev/null || true
  do_set_wallpaper "sunset"
  set_theme "sunset"
  (conky & disown) >/dev/null 2>&1
  do_reload_all "sunset_cava.conf"
  eww reload
  hyprctl keyword general:col.active_border 0xffFF9320 0xffFFB86C 0xffFF784F 0xffFF5F6D 0xffFF9472 0xffFFD369 0xffFCEFD2 180deg > /dev/null 2>&1

  echo sunset > ~/.config/rofi/current_theme.txt
  notify-send "Theme Switcher" --transient "Theme switched to Sunset 🌇"
  
}

############################################################################################################

do_change_to_car() {
  pkill -9 conky 2>/dev/null || true
  pkill -9 cava 2>/dev/null || true
  do_set_custom_wall "purple/firstcar.jpg"
  set_theme "purple"
  (conky  & disown) >/dev/null 2>&1
  do_reload_all "purple_cava.conf"
  hyprctl keyword general:col.active_border 0xffc084fc 0xffa855f7 0xff9333ea 0xff7c2ae8 0xff5b1fd6 0xff3a0ca3 0xff312e81 0xff3730a3 0xff4338ca 0xff4f46e5 360deg > /dev/null 2>&1
  eww reload
  echo car > ~/.config/rofi/current_theme.txt
  notify-send "Theme Switcher" --transient "Theme switched - 🚗 Car Mode Activated"
}

############################################################################################################

do_change_holiday() {
  pkill -9 conky 2>/dev/null || true
  pkill -9 cava 2>/dev/null || true
  do_set_wallpaper "holiday"
  set_theme "holiday"
#  (conky & disown) >/dev/null 2>&1
  do_reload_all "holiday_cava.conf"
  eww reload
  echo holiday > ~/.config/rofi/current_theme.txt
  hyprctl keyword general:col.active_border 0xff00f5eb 0xff00C2BA 0xff0094C6 0xff005B96 0xff003F6E 180deg > /dev/null 2>&1
  notify-send "Theme Switcher" --transient "Theme switched to holiday! 🏴"

}

############################################################################################################


do_change_random_theme_wallpaper() {
  if [ $theme = "sunset" ]; then
  do_set_wallpaper "sunset"
  elif [ $theme = "car" ]; then
  do_set_wallpaper "purple"
  elif [ $theme = "holiday" ]; then
  do_set_wallpaper "holiday"  
  fi
}

do_reload_all() {
  local cavaconf="$1"
  swaync-client -rs >/dev/null 2>&1
  pkill -USR1 kitty  # reload kitty config
  pkill -USR2 waybar
  pkill swayosd-server
  setsid -f swayosd-server >/dev/null 2>&1 &
  setsid -f kitty +kitten panel \
      --edge=background --instance-group=cava-startup \
      --config="$HOME/.config/kitty/cava_kitty.conf" \
      --margin-top=238 --margin-right=1200 --margin-left=2 --margin-bottom=3 \
      --name=cava-startup cava -p "$HOME/.config/cava/themes/$cavaconf" >/dev/null 2>&1
}

set_theme() {
  local theme="$1"
  ln -sf ~/.config/conky/themes/conky_$theme.conf ~/.config/conky/conky.conf
  ln -sf ~/.config/kitty/themes/kitty_$theme.conf ~/.config/kitty/kitty.conf
  ln -sf ~/.config/waybar/themes/waybar_$theme.css ~/.config/waybar/style.css
  ln -sf ~/.config/starship-themes/starship_$theme.toml ~/.config/starship.toml
  ln -sf ~/.config/eww/themes/eww_$theme.scss ~/.config/eww/eww.scss
  ln -sf ~/.config/rofi/themes/rofi_$theme.rasi ~/.config/rofi/config.rasi
  ln -sf ~/.config/swaync/themes/swaync_$theme.css ~/.config/swaync/style.css
  ln -sf ~/.config/wlogout/themes/wlogout_$theme.css ~/.config/wlogout/style.css
  ln -sf ~/.config/swayosd/themes/swayosd_$theme.css ~/.config/swayosd/style.css

}

do_set_wallpaper() {
  local wall="$1"
  swww img "$(find "$HOME/wallpaper/$wall" -type f | shuf -n 1)" --transition-type grow --transition-pos 0.5,0.5 --transition-duration 2 --transition-fps 60

}

do_set_custom_wall() {
  local wall="$1"
  swww img "$(find "$HOME/wallpaper/$wall")" --transition-type grow --transition-pos 0.5,0.5 --transition-duration 2 --transition-fps 60
}

do_disable_conky() {
  notify-send "Theme Switcher" --transient "Conky disabled"
  pkill -9 conky 2>/dev/null || true 
}

do_enable_conky() {
  notify-send "Theme Switcher" --transient "Conky enabled"
  if [ $theme = "holiday" ]; then
    do_set_custom_wall "holiday/Holiday_8.jpg"
    (conky & disown) >/dev/null 2>&1
  elif:
    (conky & disown) >/dev/null 2>&1
  fi
}

do_debug() {
  notify-send "Theme Switcher" --transient "current theme is: $theme"
  notify-send
}

case "${ROFI_RETV:-0}" in
  0)
    # First run: print menu entries
    printf '%s\n' "$Purple" "$Sunset" "$holiday" "----------" "$random_theme_wallpaper" "----------" "$Disableconky" "$Enableconky" "----------" "$reloadall" "$debug"
    # old '%s\n%s\n%s\n%s\n%s\n'
    ;;
  1)
    # Second run: handle selection
    case "$1" in
      "$Purple") do_change_to_car ;;
      "$Sunset") do_change_sunset ;;
      "$holiday") do_change_holiday ;;
      "$random_theme_wallpaper") do_change_random_theme_wallpaper ;;
      "$Disableconky") do_disable_conky ;;
      "$Enableconky") do_enable_conky ;;
      "$debug") do_debug ;;
    esac
    ;;
esac
