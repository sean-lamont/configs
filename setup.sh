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
    rm /tmp/JetBrainsMono.zip

    # --- 3. Configure GNOME Terminal ---
    echo "Applying font to GNOME Terminal..."
    PROFILE=$(dconf read /org/gnome/terminal/legacy/profiles:/default | tr -d \')
    if [ -n "$PROFILE" ]; then
        dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/use-system-font false
        dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/font "'JetBrainsMono Nerd Font 12'"
        echo "GNOME Terminal successfully updated!"
    fi
fi

# --- 4. Inject Conda and Tmux Auto-start into Shell Config ---
echo "Configuring $RC_FILE for Conda and Tmux auto-start..."

# Use grep to check if we've already added this block, avoiding duplicates
if ! grep -q "# --- Tmux & Conda Auto-Setup ---" "$RC_FILE"; then
    cat << 'EOF' >> "$RC_FILE"

# --- Tmux & Conda Auto-Setup ---
# 1. Auto-restore active Conda environment in new Tmux panes
if command -v conda &> /dev/null && [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" != "base" ]; then
    conda activate "$CONDA_DEFAULT_ENV"
fi

# 2. Auto-start Tmux (only in interactive shells, and not inside an existing Tmux)
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [ -z "$TMUX" ]; then
    exec tmux new-session -A -s main
fi
EOF
    echo "Successfully injected shell configurations into $RC_FILE."
else
    echo "Shell configurations already exist in $RC_FILE. Skipping."
fi

echo "================================================="
echo "Setup complete! Please restart your terminal."
echo "Once Tmux opens, press 'Ctrl+Space' then 'Shift+I' to install your plugins."
echo "================================================="
