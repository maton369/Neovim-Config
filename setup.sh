#!/bin/bash
# Neovim development environment setup script
# Supported: macOS (Homebrew) / Ubuntu 22.04+ (apt)
#
# Usage: setup.sh [OPTIONS]
#   --research       Jupyter/ノートブック環境を含める (luarocks, magick, jupytext,
#                    jupyter, ipykernel 等)。デフォルトでは入れない。
#   --conda-kernels  ~/{miniforge3,anaconda3,miniconda3}/envs/* で ipykernel が
#                    入っている conda env を Jupyter kernel として登録する
#                    (:MoltenInit のピッカーに並ぶ)。 デフォルトでは行わない。

set -euo pipefail

RESEARCH=false
INSTALL_CONDA_KERNELS=false
for arg in "$@"; do
  case "$arg" in
    --research) RESEARCH=true ;;
    --conda-kernels) INSTALL_CONDA_KERNELS=true ;;
    -h|--help)
      sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  PLATFORM="mac"
  echo "Detected: macOS"
elif [ -f /etc/os-release ]; then
  PLATFORM="linux"
  echo "Detected: Linux"
else
  echo "Error: unsupported OS" >&2
  exit 1
fi

echo "=== Neovim Environment Setup ==="
if $RESEARCH; then
  echo "(--research mode: including Jupyter/notebook environment)"
fi

# -----------------------------------------------------------
# 1. System packages
# -----------------------------------------------------------
echo "[1/8] Installing system packages..."
if [ "$PLATFORM" = "mac" ]; then
  if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew is required on macOS. Install from https://brew.sh" >&2
    exit 1
  fi
  brew install git curl wget cmake ripgrep fd python3 yazi

  if $RESEARCH; then
    brew install luarocks imagemagick
  fi
else
  # NOTE: golang-go は Ubuntu 22.04 で Go 1.18 のため gopls v0.22.0 を build できない。
  # Go は §5 で公式 tarball から 1.23+ を入れるのでここでは入れない。
  sudo apt update
  sudo apt install -y \
    git curl wget unzip \
    build-essential cmake \
    ripgrep fd-find \
    python3 python3-pip python3-venv \
    xclip wl-clipboard

  if $RESEARCH; then
    sudo apt install -y \
      luarocks lua5.1 liblua5.1-0-dev libmagickwand-dev
  fi

  # fd-find is installed as 'fdfind' on Ubuntu; create symlink
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
  fi

  # yazi (file manager for yazi.nvim)
  if ! command -v yazi &>/dev/null; then
    echo "  → Installing yazi..."
    curl -Lo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
    unzip -o /tmp/yazi.zip -d /tmp
    sudo install /tmp/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin
    rm -rf /tmp/yazi.zip /tmp/yazi-x86_64-unknown-linux-gnu
  else
    echo "  ✓ yazi (already installed)"
  fi
fi

# image.nvim (kitty graphics backend) needs lua-magick. Build it against
# the system Lua 5.1 / ImageMagick libs installed above.
if $RESEARCH; then
  if command -v luarocks &>/dev/null && ! [ -f "$HOME/.luarocks/lib/lua/5.1/magick.so" ]; then
    luarocks --local --lua-version=5.1 install magick || \
      echo "warning: luarocks install magick failed; image.nvim image rendering will be unavailable"
  fi
fi

# -----------------------------------------------------------
# 2. Neovim (latest stable)
# -----------------------------------------------------------
echo "[2/8] Installing Neovim..."
if [ "$PLATFORM" = "mac" ]; then
  brew install neovim
  echo "Neovim $(nvim --version | head -1) installed"
else
  if ! nvim --version 2>/dev/null | grep -q 'NVIM v0\.\(1[0-9]\|[2-9][0-9]\)'; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
    echo "Neovim $(nvim --version | head -1) installed"
  else
    echo "Neovim already up to date: $(nvim --version | head -1)"
  fi
fi

# -----------------------------------------------------------
# 3. Node.js (required for Mason LSP servers: pyright, jsonls, yamlls, ...)
# -----------------------------------------------------------
echo "[3/8] Installing Node.js..."
if [ "$PLATFORM" = "mac" ]; then
  brew install node
  echo "Node.js $(node --version) installed"
else
  if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
    echo "Node.js $(node --version) installed"
  else
    echo "Node.js already installed: $(node --version)"
  fi
fi

# -----------------------------------------------------------
# 4. Rust (for rust-analyzer)
# -----------------------------------------------------------
echo "[4/8] Installing Rust..."
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
echo "[5/8] Installing Go..."
if [ "$PLATFORM" = "mac" ]; then
  brew install go
  echo "Go $(go version) installed"
else
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
fi

# -----------------------------------------------------------
# 6. Neovim config
# -----------------------------------------------------------
echo "[6/8] Setting up Neovim config..."
REPO_SSH="git@github.com:maton369/Neovim-Config.git"
REPO_HTTPS="https://github.com/maton369/Neovim-Config.git"
if [ ! -d "$HOME/.config/nvim/.git" ]; then
  mkdir -p "$HOME/.config"
  # SSH 鍵が登録済みなら SSH (push もそのまま使える)、 未登録なら HTTPS で fallback
  if git clone "$REPO_SSH" "$HOME/.config/nvim" 2>/dev/null; then
    echo "Config cloned via SSH"
  else
    echo "  SSH unavailable, falling back to HTTPS..."
    git clone "$REPO_HTTPS" "$HOME/.config/nvim"
    echo "Config cloned via HTTPS (push したい場合は 'git remote set-url origin $REPO_SSH' で SSH に切り替え)"
  fi
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
echo "[7/8] Setting up notebook venv..."
VENV_DIR="$HOME/.config/nvim/venv"
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel
"$VENV_DIR/bin/pip" install pynvim ruff
mkdir -p "$HOME/.local/bin"
ln -sf "$VENV_DIR/bin/ruff" "$HOME/.local/bin/ruff"

if $RESEARCH; then
  echo "  → Installing Jupyter/notebook packages..."
  "$VENV_DIR/bin/pip" install jupyter_client ipykernel jupytext jupyter
  # notebook.lua / formatting.lua がベア名でこれらを呼ぶので PATH に通す
  ln -sf "$VENV_DIR/bin/jupytext" "$HOME/.local/bin/jupytext"
  # jupyter_client が connection JSON を書く runtime dir。 venv の jupyter は
  # XDG_RUNTIME_DIR を見ず fallback の ~/.local/share/jupyter/runtime を期待する
  # (が、 環境によっては自動作成されず ENOENT で :MoltenInit が落ちる)。
  mkdir -p "$HOME/.local/share/jupyter/runtime"
fi
echo "Notebook venv ready at $VENV_DIR"

# -----------------------------------------------------------
# 7b. Register conda env Jupyter kernels (opt-in: --conda-kernels)
#     ~/{miniforge3,anaconda3,miniconda3}/envs/*/ で ipykernel が入っている env を
#     `python -m ipykernel install --user --name <env>` で Jupyter kernel として
#     登録する。 これで :MoltenInit のピッカーに conda env が並ぶ。
#     idempotent — 既に登録済みでも上書きされるだけで害は無い。
# -----------------------------------------------------------
if [ "$INSTALL_CONDA_KERNELS" = "true" ]; then
  echo "Registering conda env Jupyter kernels..."
  for conda_root in "$HOME/miniforge3" "$HOME/anaconda3" "$HOME/miniconda3"; do
    [ -d "$conda_root/envs" ] || continue
    for env_dir in "$conda_root"/envs/*/; do
      [ -d "$env_dir" ] || continue
      env_name="$(basename "$env_dir")"
      env_python="${env_dir}bin/python"
      [ -x "$env_python" ] || continue
      if "$env_python" -c "import ipykernel" &>/dev/null; then
        "$env_python" -m ipykernel install --user \
          --name "$env_name" --display-name "Python ($env_name)" 2>/dev/null && \
          echo "  registered: $env_name"
      fi
    done
  done
fi

# -----------------------------------------------------------
# 8. Claude Code wrapper
#    nvim init.lua の VimEnter layout は右ペインで `terminal claude` を起動するが、
#    nvim の `:terminal cmd` は non-interactive shell で cmd を実行するため
#    .bashrc 内の nvm 初期化が読まれず、 nvm 経由で入れた claude が解決できない
#    ("コマンドが見つかりません" になる) ことがあった。 ~/.local/bin/claude に
#    ラッパーを置いて、 nvm を source した上で node bin dir 直下の claude を直接
#    exec することで、 nvm route / system Node route の両方で claude が起動する。
#    (claude 本体は別途 `npm install -g @anthropic-ai/claude-code` で導入する)
# -----------------------------------------------------------
echo "[8/8] Installing claude wrapper..."
mkdir -p "$HOME/.local/bin"
# ~/.local/bin/claude が公式 installer / npm install の symlink だと、
# `cat >` がリンクを辿って **本体ファイル**を wrapper script で上書きしてしまう
# (= claude が起動不能になる)。 既存 symlink / 旧 wrapper は unlink してから書く。
rm -f "$HOME/.local/bin/claude"
cat > "$HOME/.local/bin/claude" <<'WRAPPER'
#!/usr/bin/env bash
# nvim の :terminal claude (non-interactive shell) で claude が見つからない問題の回避。
# PATH に nvm の bin dir が乗っていない context (vim/nvim の :terminal, cron,
# IDE 直接起動など) からでも確実に claude を解決する。
# readlink -f is not available on macOS; use python3 as portable fallback
resolve_path() { python3 -c "import os; print(os.path.realpath('$1'))"; }

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# 1. nvm の node がある場合: その bin dir 直下の claude を exec
#    (PATH 解決だと ~/.local/bin の本ラッパーに戻ってきて無限ループするため
#     dirname(node) で絶対パス解決する)
NODE_BIN="$(command -v node 2>/dev/null)"
if [ -n "$NODE_BIN" ]; then
  CLAUDE_BIN="$(dirname "$NODE_BIN")/claude"
  if [ -x "$CLAUDE_BIN" ]; then
    exec "$CLAUDE_BIN" "$@"
  fi
fi

# 2. system Node + sudo npm install -g 経由で /usr/{local/,}bin/claude にある場合
for candidate in /usr/local/bin/claude /usr/bin/claude; do
  # 自分自身を再帰呼び出しすると無限ループになるので除外
  if [ -x "$candidate" ] && [ "$(resolve_path "$candidate")" != "$(resolve_path "$0")" ]; then
    exec "$candidate" "$@"
  fi
done

echo "claude wrapper: claude binary not found. Install via:" >&2
echo "  npm install -g @anthropic-ai/claude-code" >&2
exit 127
WRAPPER
chmod +x "$HOME/.local/bin/claude"
echo "Claude wrapper at $HOME/.local/bin/claude"

# -----------------------------------------------------------
# 9. Bootstrap nvim plugins headlessly
#    - `Lazy! sync` で 全 plugin install + build hook 実行
#    - `UpdateRemotePlugins` で molten-nvim 等 Python rplugin を rplugin.vim に登録。
#    初回 launch 時に lazy 経由で実行される build hook が venv 未準備で空振りした
#    場合 :MoltenInit などが E492 になるので、 venv 完成後に明示的に再走させる。
# -----------------------------------------------------------
if command -v nvim &>/dev/null; then
  echo "Bootstrapping plugins (Lazy sync + UpdateRemotePlugins)..."
  nvim --headless "+Lazy! sync" +qa 2>&1 | tail -3 || true
  nvim --headless "+UpdateRemotePlugins" +qa 2>&1 | tail -3 || true
fi

echo ""
echo "=== Setup complete! ==="
echo "Run 'nvim' to start. Plugins will install automatically on first launch."
echo "Note: claude (Claude Code CLI) 本体はこの script では入れない。"
echo "      'npm install -g @anthropic-ai/claude-code' を別途実行すれば、"
echo "      §8 のラッパー経由で nvim の右ペイン (terminal claude) が動く。"
if ! $RESEARCH; then
  echo "Note: Jupyter/ノートブック環境が必要な場合は"
  echo "      './setup.sh --research' で再実行。"
fi
if [ "$INSTALL_CONDA_KERNELS" != "true" ]; then
  echo "Note: conda env を :MoltenInit のピッカーで使いたい場合は"
  echo "      './setup.sh --conda-kernels' で再実行 (ipykernel 入りの conda env を登録)。"
fi
