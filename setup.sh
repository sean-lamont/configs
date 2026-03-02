#!/bin/bash

echo "Starting Ultimate Machine-Agnostic ML Dotfiles Setup..."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 1. Install Homebrew (Linux/macOS) ---
# This ensures we have a consistent package manager across all environments
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Set up shellenv for the current session to ensure follow-up commands work
    if [ "$(uname)" == "Linux" ]; then
        test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
        test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# --- 2. Install Core Dependencies ---
echo "Installing core packages via Homebrew..."
# Added rofi for better app searching and picom/feh for i3 visuals
brew install zsh tmux vim git entr curl xclip starship mcfly rofi picom feh

if [ "$(uname)" == "Linux" ]; then
    # Set Zsh as the default shell 
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Changing default shell to Zsh..."
        chsh -s $(which zsh)
    fi

    # --- 3. Install JetBrainsMono Nerd Font (Linux Only) ---
    if [ ! -d "$HOME/.local/share/fonts/JetBrainsMono" ]; then
        echo "Installing JetBrainsMono Nerd Font for Starship and i3..."
        mkdir -p ~/.local/share/fonts
        wget -qO /tmp/jb.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
        unzip -qo /tmp/jb.zip -d ~/.local/share/fonts/ && fc-cache -fv
        rm /tmp/jb.zip
    fi
fi

# --- 4. Dynamic Miniconda Install ---
# Detects OS and Architecture (Intel vs Apple Silicon) automatically 
if ! command -v conda &>/dev/null; then
    echo "Conda not found. Installing Miniconda3..."
    ARCH=$(uname -m)
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    
    if [ "$OS" == "darwin" ]; then
        [ "$ARCH" == "arm64" ] && INSTALLER="Miniconda3-latest-MacOSX-arm64.sh"
        [ "$ARCH" == "x86_64" ] && INSTALLER="Miniconda3-latest-MacOSX-x86_64.sh"
    else
        INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
    fi
    
    wget "https://repo.anaconda.com/miniconda/$INSTALLER" -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3" && rm /tmp/miniconda.sh
fi

# --- 5. Zsh Plugins & Configuration ---
echo "Setting up Zsh plugins..."
mkdir -p ~/.zsh ~/.config/i3
[ ! -d "$HOME/.zsh/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
[ ! -d "$HOME/.zsh/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting

# Configure Starship for ML (Python version disabled as requested)
cat << 'EOF' > ~/.config/starship.toml
add_newline = false
[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"
[git_branch]
symbol = " "
style = "bold purple"
[conda]
symbol = " "
format = "via [$symbol$environment]($style) "
style = "bold green"
ignore_base = false
[python]
disabled = true
EOF

# --- 6. Secure Symlinking ---
# Links files from your git repo to your home directory 
echo "Linking dotfiles to $HOME..."
ln -sfn "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sfn "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
ln -sfn "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
ln -sfn "$DOTFILES_DIR/.ideavimrc" "$HOME/.ideavimrc"
ln -sfn "$DOTFILES_DIR/i3_config" "$HOME/.config/i3/config"

# --- 7. Headless Plugin Initialization ---
echo "Finalizing plugin installations..."
# Install Vim plugins without opening the UI
vim +PlugInstall +qall

# --- 8. Local Secrets Reminder ---
if [ ! -f "$HOME/.local_secrets.zsh" ]; then
    echo "CREATING: ~/.local_secrets.zsh. Please add your GITHUB_ACCESS_TOKEN here."
    touch "$HOME/.local_secrets.zsh"
fi

echo "================================================="
echo "Setup Complete!"
echo "1. Log out and back in to switch to Zsh."
echo "2. Your new i3 config is active with Rofi for app searches ($mod+d)."
echo "3. Remember to populate your token in ~/.local_secrets.zsh."
echo "================================================="
