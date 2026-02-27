#!/bin/bash

echo "Starting ultimate portable Tmux & ML environment setup..."

# Determine the correct shell configuration file based on OS
if [ "$(uname)" == "Darwin" ]; then
    RC_FILE="$HOME/.zshrc"
elif [ "$(uname)" == "Linux" ]; then
    RC_FILE="$HOME/.bashrc"
fi

# --- 1. Install Dependencies (entr for tmux-autoreload) ---
if [ "$(uname)" == "Darwin" ]; then
    echo "macOS detected. Checking for Homebrew..."
    if command -v brew &> /dev/null; then
        echo "Installing entr via Homebrew..."
        brew install entr
    else
        echo "Homebrew not found! Please install Homebrew to automate macOS setup."
    fi

elif [ "$(uname)" == "Linux" ]; then
    echo "Linux detected. Installing entr and font utilities..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y entr unzip wget fontconfig
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y entr unzip wget fontconfig
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm entr unzip wget fontconfig
    else
        echo "Unsupported package manager. Please install 'entr' manually."
    fi

    # --- 2. Install JetBrainsMono Nerd Font (Linux Only) ---
    echo "Downloading and installing JetBrainsMono Nerd Font..."
    mkdir -p ~/.local/share/fonts
    wget -qO /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -qo /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/
    fc-cache -fv
    rm -f /tmp/JetBrainsMono.zip

    # --- 3. Configure GNOME Terminal ---
    echo "Applying font to GNOME Terminal..."
    PROFILE=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d \')
    if [ -n "$PROFILE" ]; then
        dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/use-system-font false
        dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/font "'JetBrainsMono Nerd Font 12'"
        echo "GNOME Terminal successfully updated!"
    else
        echo "Could not find default GNOME Terminal profile. You may need to set the font manually."
    fi
fi

# --- 4. Inject Conda and Tmux Auto-start into Shell Config ---
echo "Configuring $RC_FILE for Conda and Tmux auto-start..."

# Use grep to check if we've already added this block, avoiding duplicates
if ! grep -q "# --- Tmux & Conda Auto-Setup ---" "$RC_FILE"; then
    cat << 'EOF' >> "$RC_FILE"

# --- Tmux & Conda Auto-Setup ---
# 1. If we are INSIDE Tmux, set up the environment sync
if [ -n "$TMUX" ]; then

    # A. Every time the prompt appears, tell Tmux which Conda env we are in
    if [ -n "$BASH_VERSION" ]; then
        PROMPT_COMMAND="tmux set-env TMUX_CONDA_ENV \"\$CONDA_DEFAULT_ENV\" 2>/dev/null; ${PROMPT_COMMAND:-}"
    elif [ -n "$ZSH_VERSION" ]; then
        precmd() { tmux set-env TMUX_CONDA_ENV "$CONDA_DEFAULT_ENV" 2>/dev/null; }
    fi

    # B. When a new pane boots up, ask Tmux what the last used environment was
    SAVED_ENV=$(tmux show-env TMUX_CONDA_ENV 2>/dev/null | cut -d= -f2)

    # C. If a custom environment was saved, activate it instantly
    if command -v conda &> /dev/null && [ -n "$SAVED_ENV" ] && [ "$SAVED_ENV" != "base" ]; then
        eval "$(conda shell.$(basename $SHELL) hook)"
        conda activate "$SAVED_ENV"
    fi
fi

# 2. If we are OUTSIDE Tmux, auto-start a session (and don't loop!)
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [ -z "$TMUX" ]; then
    exec tmux new-session -A -s main
fi
EOF
    echo "Successfully injected shell configurations into $RC_FILE."
else
    echo "Shell configurations already exist in $RC_FILE. Skipping."
fi

echo "================================================="
echo "Setup complete! Please completely close this terminal and open a new one."
echo "Once Tmux opens, press 'Ctrl+Space' then 'Shift+I' to install your plugins."
echo "================================================="