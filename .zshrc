# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="hyper-oh-my-zsh"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias ls='ls --color=auto'
alias autoremove='yay -Yc'
alias update='yay -Syu'
alias source='source ~/.bashrc'
alias grep='grep --color=auto'
alias list-packages='pacman -Qe'
alias powermode-current='cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
alias powermode-list='cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors'
alias powermode-performance='echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
alias powermode-powersave='echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
alias powermode-conservative='echo conservative | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
alias powermode-ondemand='echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
alias powermode-default='echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
alias nvidia='__NV_PRIME_RENDER_OFFLOAD=1 GLX_VENDOR_LIBRARY_NAME=nvidia'
alias cd..=' cd ..'
alias install='yay -S'
alias remove='yay -R'
alias gcommit='git commit -m'
alias gadd='git add .'
alias gpush='git push'
alias gpull='git pull'
alias gcheckout='git checkout'
alias gstat='git status'
alias cmatrix='cmatrix -b -k'

fds() {
  local cmd=$(fc -ln -1)
  echo "→ sudo $cmd"
  sudo zsh -c "$cmd"
}

#AUTO SUGGEST SETTINGS
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7a89,standout'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1


#SYNTAX HIGLIGH SETTINGS
# Core syntax
ZSH_HIGHLIGHT_STYLES[command]='fg=#ccdde8'          # off-blue (less vibrant)
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ccdde8'               # subtle variant for builtins
ZSH_HIGHLIGHT_STYLES[alias]='fg=#ccdde8'                 # same calm tone for aliases
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#8aa4b8,italic'  # muted blue-gray (if/then/do/fi)

ZSH_HIGHLIGHT_STYLES[unknown-command]='fg=#d13030,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#d13030,bold'

# Sudo stays subtle but recognizable
ZSH_HIGHLIGHT_STYLES[sudo]='fg=#6faad1'

# PATH SETTING
autoload -U colors && colors

# Iceberg-inspired color tuning
local FG_LAVENDER="%F{139}"
local RESET="%f"
local FG_PATH="%F{109}"

PROMPT="%B${FG_LAVENDER}%n${RESET}:${FG_LAVENDER}%m ${FG_PATH}%~${RESET}%b %# "
