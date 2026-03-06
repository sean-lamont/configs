#!/bin/bash

echo "Starting Ultimate Machine-Agnostic ML Dotfiles Setup..."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname | tr '[:upper:]' '[:lower:]')"

# --- 1. System GUI Packages (Linux i3 Setup) ---
echo "Checking System-Level Packages..."
if [ "$OS" == "linux" ]; then
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        # Use APT for X11/GUI tools to ensure they hook into the OS correctly
        sudo apt-get install -y i3 rofi feh xclip wl-clipboard jq unzip curl wget git build-essential
    else
        echo "Warning: apt-get not found. Ensure you have i3 and GUI tools installed manually."
    fi
fi

# --- 2. Locate and Load Homebrew ---
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew &>/dev/null; then
    echo "Homebrew not found on system. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [ "$OS" == "linux" ]; then
        test -d ~/.linuxbrew && eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
        test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew is installed and loaded."
fi

# --- 3. Install Terminal Dependencies via Brew ---
echo "Installing CLI packages via Homebrew..."
BREW_PKGS=(zsh tmux starship mcfly neovim)

for pkg in "${BREW_PKGS[@]}"; do
    if ! brew list --formula | grep -q "^${pkg}\$"; then
        brew install "$pkg"
    else
        echo "$pkg is already installed."
    fi
done

# --- 4. Zsh Default Shell Configuration ---
ZSH_PATH="$(command -v zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
    echo "Changing default shell to Zsh..."
    # Ensure Zsh is an allowed system shell before switching
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    chsh -s "$ZSH_PATH"
fi

# --- 5. Install JetBrainsMono Nerd Font (Linux Only) ---
if [ "$OS" == "linux" ] && [ ! -d "$HOME/.local/share/fonts/JetBrainsMono" ]; then
    echo "Installing JetBrainsMono Nerd Font for Starship and i3..."
    mkdir -p ~/.local/share/fonts
    wget -qO /tmp/jb.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -qo /tmp/jb.zip -d ~/.local/share/fonts/ && fc-cache -fv
    rm /tmp/jb.zip
fi

# --- 6. Dynamic Miniconda Install ---
if [ ! -d "$HOME/miniconda3" ]; then
    echo "Conda directory not found. Installing Miniconda3..."
    ARCH=$(uname -m)
    
    if [ "$OS" == "darwin" ]; then
        [ "$ARCH" == "arm64" ] && INSTALLER="Miniconda3-latest-MacOSX-arm64.sh"
        [ "$ARCH" == "x86_64" ] && INSTALLER="Miniconda3-latest-MacOSX-x86_64.sh"
    else
        INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
    fi
    
    wget "https://repo.anaconda.com/miniconda/$INSTALLER" -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3" && rm /tmp/miniconda.sh
else
    echo "Miniconda already exists at $HOME/miniconda3."
fi

# --- 7. Zsh Plugins & Configuration ---
echo "Setting up Zsh plugins..."
mkdir -p ~/.zsh ~/.config/i3
[ ! -d "$HOME/.zsh/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
[ ! -d "$HOME/.zsh/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting

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

# --- 8. Secure Symlinking ---
echo "Linking dotfiles to $HOME..."
ln -sfn "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sfn "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
ln -sfn "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
ln -sfn "$DOTFILES_DIR/.ideavimrc" "$HOME/.ideavimrc"
ln -sfn "$DOTFILES_DIR/i3_config" "$HOME/.config/i3/config"
ln -sfn "$DOTFILES_DIR/antigravity_settings.json" "$HOME/.config/Antigravity/User/settings.json"
ln -sfn "$DOTFILES_DIR/antigravity_keybindings.json" "$HOME/.config/Antigravity/User/keybindings.json"

# --- 9. Headless Vim & Catppuccin Initialization ---
echo "Initializing Vim and Catppuccin Theme..."
# Download vim-plug automatically if it's missing, otherwise the theme won't install
if [ ! -f ~/.vim/autoload/plug.vim ]; then
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
# Install plugins (including Catppuccin) without opening UI
vim +PlugInstall +qall

# --- 10. Local Secrets Reminder ---
if [ ! -f "$HOME/.local_secrets.zsh" ]; then
    echo "CREATING: ~/.local_secrets.zsh. Please add your GITHUB_ACCESS_TOKEN here."
    touch "$HOME/.local_secrets.zsh"
fi

echo "================================================="
echo "Setup Complete!"
echo "1. Log out and back in to fully apply i3 and Zsh."
echo "2. Initialize conda in your shell: ~/miniconda3/bin/conda init zsh"
echo "================================================="


