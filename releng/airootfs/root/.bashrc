#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

alias r="ranger"

eval "$(zoxide init bash --cmd cd)"
eval "$(starship init bash)"

alias sync="sudo pacman -S"
alias search_sync="sudo pacman -Ss "
alias show_all="ls $(echo $PATH | tr ':' ' ') "
alias vim="nvim"

export sox="~/Downloads/sox-14.4.2/"

# Added by cua-driver-rs installer — see https://github.com/trycua/cua
export PATH="/home/amine/.local/bin:$PATH"
