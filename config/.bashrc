#
# ~/.bashrc
# Made by Chief-Github
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias wbb='nohup setsid waybar >> /dev/null 2>&1 &'
# PS1='[\u@\h \W]\$ '
fastfetch --config ~/.config/fastfetch/fastneofetch.jsonc #A smaller fastfetch for normal terminal usage
eval "$(starship init bash)"
alias ls='lsd -a'
# alias cat='bat'
alias wpe='linux-wallpaperengine --screen-root eDP-1'
eval "$(thefuck --alias)"
alias pkexec='pkexec env XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR WAYLAND_DISPLAY=$WAYLAND_DISPLAY GTK_THEME=Adwaita:dark'
alias mon='sudo airmon-ng start wlan0'
alias monstop='sudo airmon-ng stop wlan0mon'
alias monoff='sudo airmon-ng stop wlan0mon && sudo systemctl restart NetworkManager'
alias monhelp='echo mon = start - monstop = stop - monoff = restart NM and stop'
export PATH="$HOME/.local/bin:$PATH"
alias ccc='cd ~/scratch && claude'
#alias gen=$'matugen image "$(swww query | grep -oP \'(?<=image: ).*\')"' && hyprctl keyword general:col.active_border $(cat ~/.config/hypr/matugen_colors.txt) 360deg /dev/null 2>&1

alias gen='matugen image "$(swww query | grep -oP '"'"'(?<=image: ).*'"'"')" && hyprctl keyword general:col.active_border $(cat ~/.config/hypr/matugen_colors.txt) 360deg'
