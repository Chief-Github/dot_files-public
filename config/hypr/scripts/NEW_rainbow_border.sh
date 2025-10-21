#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for rainbow borders animation
# /* ----    Modified by Chief-Github     ---- */ 

function random_hex() {
    random_hex=("0xff$(openssl rand -hex 3)")
    echo $random_hex
}
# PURPLE=(
#   "$(hex '#3a0ca3')"  # indigo
#   "$(hex '#5b1fd6')"
#   "$(hex '#7c2ae8')"  # your main purple
#   "$(hex '#a855f7')"  # light purple
#   "$(hex '#7c2ae8')"
#   "$(hex '#5b1fd6')"
#   "$(hex '#3a0ca3')"
# )
# 
# rainbow colors only for active window
hyprctl keyword general:col.active_border 0xffc084fc 0xffa855f7 0xff9333ea 0xff7c2ae8 0xff5b1fd6 0xff3a0ca3 0xff312e81 0xff3730a3 0xff4338ca 0xff4f46e5 360deg

# rainbow colors for inactive window (uncomment to take effect)
#hyprctl keyword general:col.inactive_border 0xff4b5563 0xff6b7280 0xff7c2ae8 eg
