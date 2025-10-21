# ~/.bashrc
# Made by Chief-Github

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
