# ==========================================
# 1. HISTORY & CORE
# ==========================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory histignorealldups

# ==========================================
# 2. DYNAMIC PATHS & CUDA
# ==========================================
# Load Secrets (Tokens/Keys)
[ -f "$HOME/.local_secrets.zsh" ] && source "$HOME/.local_secrets.zsh"

# Homebrew Initialization (Dynamic for Linux/macOS)
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d "$HOME/.linuxbrew" ]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
elif [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Find Latest CUDA automatically
CUDA_LATEST=$(ls -d /usr/local/cuda-[0-9]* 2>/dev/null | sort -V | tail -n 1)
if [ -n "$CUDA_LATEST" ]; then
    export CUDA_HOME="$CUDA_LATEST"
    export PATH="$CUDA_HOME/bin:$PATH"
    export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$CUDA_HOME/lib:$LD_LIBRARY_PATH"
fi

export PATH="$HOME/.local/bin:$PATH"
export TERM="xterm-256color"

# ==========================================
# 3. ALIASES & TOOLS
# ==========================================
alias c='xclip -selection clipboard'
alias ls='ls --color=auto'
alias ll='ls -alF'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(fc -ln -1)"'

# Tool Hooks
[ -f "$HOME/miniconda3/bin/conda" ] && eval "$("$HOME/miniconda3/bin/conda" 'shell.zsh' 'hook')"
command -v mcfly &>/dev/null && eval "$(mcfly init zsh)"
[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ==========================================
# 4. UI & PLUGINS
# ==========================================
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
command -v starship &>/dev/null && eval "$(starship init zsh)"

# ==========================================
# 5. TMUX & CONDA PERSISTENCE
# ==========================================
if [ -n "$TMUX" ]; then
    precmd() { tmux set-env TMUX_CONDA_ENV "$CONDA_DEFAULT_ENV" 2>/dev/null; }
    SAVED_ENV=$(tmux show-env TMUX_CONDA_ENV 2>/dev/null | cut -d= -f2)
    if [ -n "$SAVED_ENV" ] && [ "$SAVED_ENV" != "base" ]; then
        conda activate "$SAVED_ENV" 2>/dev/null
    fi
fi

# Auto-start Tmux outside of IDE terminals
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
    exec tmux new-session -A -s main
fi