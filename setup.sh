#!/bin/bash
# Neovim development environment setup script
# Tested on Ubuntu 22.04+
set -euo pipefail

echo "=== Neovim Environment Setup ==="

# -----------------------------------------------------------
# 1. System packages
# -----------------------------------------------------------
echo "[1/5] Installing system packages..."
sudo apt update
sudo apt install -y \
  git curl wget unzip \
  build-essential cmake \
  ripgrep fd-find \
  python3 python3-pip python3-venv \
  golang-go

# fd-find is installed as 'fdfind' on Ubuntu; create symlink
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# -----------------------------------------------------------
# 2. Neovim (latest stable)
# -----------------------------------------------------------
echo "[2/5] Installing Neovim..."
if ! nvim --version 2>/dev/null | grep -q 'NVIM v0\.\(1[0-9]\|[2-9][0-9]\)'; then
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm nvim-linux-x86_64.tar.gz
  echo "Neovim $(nvim --version | head -1) installed"
else
  echo "Neovim already up to date: $(nvim --version | head -1)"
fi

# -----------------------------------------------------------
# 3. Node.js (required for Mason LSP servers)
# -----------------------------------------------------------
echo "[3/5] Installing Node.js..."
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt install -y nodejs
  echo "Node.js $(node --version) installed"
else
  echo "Node.js already installed: $(node --version)"
fi

# -----------------------------------------------------------
# 4. Rust (for rust-analyzer)
# -----------------------------------------------------------
echo "[4/5] Installing Rust..."
if ! command -v rustc &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  echo "Rust $(rustc --version) installed"
else
  echo "Rust already installed: $(rustc --version)"
fi

# -----------------------------------------------------------
# 5. Neovim config
# -----------------------------------------------------------
echo "[5/5] Setting up Neovim config..."
if [ ! -d "$HOME/.config/nvim/.git" ]; then
  mkdir -p "$HOME/.config"
  git clone git@github.com:maton369/Neovim-Config.git "$HOME/.config/nvim"
  echo "Config cloned"
else
  cd "$HOME/.config/nvim" && git pull
  echo "Config updated"
fi

echo ""
echo "=== Setup complete! ==="
echo "Run 'nvim' to start. Plugins will install automatically on first launch."
