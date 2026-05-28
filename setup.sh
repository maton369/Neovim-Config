#!/bin/bash
# Neovim development environment setup script
# Tested on Ubuntu 22.04+
set -euo pipefail

echo "=== Neovim Environment Setup ==="

# -----------------------------------------------------------
# 1. System packages
# -----------------------------------------------------------
# NOTE: golang-go は Ubuntu 22.04 で Go 1.18 のため gopls v0.22.0 を build できない。
# Go は §5 で公式 tarball から 1.23+ を入れるのでここでは入れない。
echo "[1/7] Installing system packages..."
sudo apt update
sudo apt install -y \
  git curl wget unzip \
  build-essential cmake \
  ripgrep fd-find \
  python3 python3-pip python3-venv \
  luarocks lua5.1 liblua5.1-0-dev libmagickwand-dev

# fd-find is installed as 'fdfind' on Ubuntu; create symlink
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# image.nvim (kitty graphics backend) needs lua-magick. Build it against
# the system Lua 5.1 / ImageMagick libs installed above.
if command -v luarocks &>/dev/null && ! [ -f "$HOME/.luarocks/lib/lua/5.1/magick.so" ]; then
  luarocks --local --lua-version=5.1 install magick || \
    echo "warning: luarocks install magick failed; image.nvim image rendering will be unavailable"
fi

# -----------------------------------------------------------
# 2. Neovim (latest stable)
# -----------------------------------------------------------
echo "[2/7] Installing Neovim..."
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
# 3. Node.js (required for Mason LSP servers: pyright, jsonls, yamlls, ...)
# -----------------------------------------------------------
echo "[3/7] Installing Node.js..."
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
echo "[4/7] Installing Rust..."
if ! command -v rustc &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  echo "Rust $(rustc --version) installed"
else
  echo "Rust already installed: $(rustc --version)"
fi

# -----------------------------------------------------------
# 5. Go (>=1.23 for gopls; Ubuntu 22.04 apt golang-go is 1.18 = too old)
# -----------------------------------------------------------
echo "[5/7] Installing Go..."
GO_VERSION="1.23.4"
GO_REQUIRED_MAJOR=1
GO_REQUIRED_MINOR=23
need_go_install=true
if command -v go &>/dev/null; then
  current="$(go version | awk '{print $3}' | sed 's/go//')"
  cur_major="${current%%.*}"
  cur_rest="${current#*.}"
  cur_minor="${cur_rest%%.*}"
  if [ "$cur_major" -gt "$GO_REQUIRED_MAJOR" ] || \
     { [ "$cur_major" -eq "$GO_REQUIRED_MAJOR" ] && [ "$cur_minor" -ge "$GO_REQUIRED_MINOR" ]; }; then
    echo "Go already adequate: $(go version)"
    need_go_install=false
  else
    echo "Go $current is too old, installing ${GO_VERSION}..."
  fi
fi
if [ "$need_go_install" = true ]; then
  tmpdir="$(mktemp -d)"
  curl -fSL -o "${tmpdir}/go.tar.gz" "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "${tmpdir}/go.tar.gz"
  rm -rf "${tmpdir}"
  # symlink into /usr/local/bin to guarantee it's on PATH (overrides /usr/bin/go via apt)
  sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
  sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
  hash -r 2>/dev/null || true
  echo "Go $(/usr/local/go/bin/go version) installed"
fi

# -----------------------------------------------------------
# 6. Neovim config
# -----------------------------------------------------------
echo "[6/7] Setting up Neovim config..."
if [ ! -d "$HOME/.config/nvim/.git" ]; then
  mkdir -p "$HOME/.config"
  git clone git@github.com:maton369/Neovim-Config.git "$HOME/.config/nvim"
  echo "Config cloned"
else
  cd "$HOME/.config/nvim" && git pull
  echo "Config updated"
fi

# -----------------------------------------------------------
# 7. Python venv for notebook (.ipynb) + Python tooling
#    - jupytext: BufReadPost autocmd が .ipynb を py:percent に変換するのに使用
#    - pynvim / jupyter_client / ipykernel: molten-nvim 用
#    - jupyter: 一通り使えるよう
#    - ruff: formatting.lua の conform formatter + nvim-lint linter
# -----------------------------------------------------------
echo "[7/7] Setting up notebook venv..."
VENV_DIR="$HOME/.config/nvim/venv"
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel
"$VENV_DIR/bin/pip" install pynvim jupyter_client ipykernel jupytext jupyter ruff
# notebook.lua / formatting.lua がベア名でこれらを呼ぶので PATH に通す
mkdir -p "$HOME/.local/bin"
ln -sf "$VENV_DIR/bin/jupytext" "$HOME/.local/bin/jupytext"
ln -sf "$VENV_DIR/bin/ruff" "$HOME/.local/bin/ruff"
echo "Notebook venv ready at $VENV_DIR"

echo ""
echo "=== Setup complete! ==="
echo "Run 'nvim' to start. Plugins will install automatically on first launch."
echo "Note: claude (Claude Code CLI) is not installed by this script. Run"
echo "      'npm install -g @anthropic-ai/claude-code' manually if you want the"
echo "      right-pane terminal in init.lua to work."
