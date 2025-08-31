#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias wbb='nohup setsid waybar >> /dev/null 2>&1 &'
# PS1='[\u@\h \W]\$ '
neofetch
eval "$(starship init bash)"

