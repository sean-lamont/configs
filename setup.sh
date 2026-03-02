#!/bin/bash

echo "Starting Machine-Agnostic ML Dotfiles Setup..."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 1. Install Homebrew (Linux/macOS) ---
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Set up shellenv for the current session
    if [ "$(uname)" == "Linux" ]; then
        test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
        test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# --- 2. Install System Dependencies via Brew ---
echo "Installing core packages..."
brew install zsh tmux vim git entr curl xclip starship mcfly

if [ "$(uname)" == "Linux" ]; then
    # Set Zsh as default
    [ "$SHELL" != "$(which zsh)" ] && chsh -s $(which zsh)

    # --- 3. Install Nerd Font (Linux) ---
    if [ ! -d "$HOME/.local/share/fonts/JetBrainsMono" ]; then
        echo "Installing JetBrainsMono Nerd Font..."
        mkdir -p ~/.local/share/fonts
        wget -qO /tmp/jb.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
        unzip -qo /tmp/jb.zip -d ~/.local/share/fonts/ && fc-cache -fv
        rm /tmp/jb.zip
    fi
fi

# --- 4. Dynamic Miniconda Install ---
if ! command -v conda &>/dev/null; then
    echo "Installing Miniconda..."
    ARCH=$(uname -m)
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    [ "$OS" == "darwin" ] && [ "$ARCH" == "arm64" ] && INSTALLER="Miniconda3-latest-MacOSX-arm64.sh"
    [ "$OS" == "darwin" ] && [ "$ARCH" == "x86_64" ] && INSTALLER="Miniconda3-latest-MacOSX-x86_64.sh"
    [ "$OS" == "linux" ] && INSTALLER="Miniconda3-latest-Linux-x86_64.sh"

    wget "https://repo.anaconda.com/miniconda/$INSTALLER" -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3" && rm /tmp/miniconda.sh
fi

# --- 5. Zsh Plugins ---
mkdir -p ~/.zsh ~/.config
[ ! -d "$HOME/.zsh/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
[ ! -d "$HOME/.zsh/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting

# --- 6. Symlink Dotfiles ---
echo "Linking dotfiles..."
for file in .zshrc .vimrc .tmux.conf .ideavimrc; do
    ln -sfn "$DOTFILES_DIR/$file" "$HOME/$file"
done

# --- 7. Headless Vim Plugin Install ---
vim +PlugInstall +qall

echo "Setup complete! Restart your terminal to apply changes."