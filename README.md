# Neovim Config

[lazy.nvim](https://github.com/folke/lazy.nvim) ベースの個人用 Neovim 設定です。

## 起動時のレイアウト

起動すると Neo-tree（左）、エディタ（中央上）、ターミナル（中央下）、Claude Code（右）が自動で配置されます。

## 必要なもの

- Neovim >= 0.10
- Git
- Node.js >= 18（Mason LSP サーバーに必要）
- Python 3 + pip
- [ripgrep](https://github.com/BurntSushi/ripgrep)（Telescope の grep 検索用）
- [fd](https://github.com/sharkdp/fd)（Telescope のファイル検索用）
- C コンパイラ — Treesitter パーサーのビルドに必要（Linux: gcc / clang、Windows: zig）
- 任意: Go, Rust, [Claude Code](https://github.com/anthropics/claude-code)

## セットアップ

### Ubuntu / Linux

```bash
git clone git@github.com:maton369/Neovim-Config.git ~/.config/nvim
~/.config/nvim/setup.sh
```

### Windows（PowerShell）

```powershell
git clone git@github.com:maton369/Neovim-Config.git $env:LOCALAPPDATA\nvim
powershell -ExecutionPolicy Bypass -File $env:LOCALAPPDATA\nvim\setup.ps1
```

> Windows では設定は `%LOCALAPPDATA%\nvim`（`~\AppData\Local\nvim`）に配置されます。

セットアップスクリプトが依存ツールのインストールと設定の配置を行います。プラグインは初回起動時に自動でインストールされます。

### 手動セットアップ

```bash
# Linux / macOS
git clone git@github.com:maton369/Neovim-Config.git ~/.config/nvim

# Windows (PowerShell)
git clone git@github.com:maton369/Neovim-Config.git $env:LOCALAPPDATA\nvim

# Neovim を起動（プラグインは lazy.nvim により自動インストール）
nvim
```

## ディレクトリ構成

```
~/.config/nvim/
├── init.lua                 # エントリーポイント: リーダーキー、lazy.nvim、起動レイアウト
├── lua/
│   ├── options.lua          # エディタ設定（行番号、インデント、検索など）
│   ├── keymaps.lua          # グローバルキーマップ、チートシートコマンド
│   └── plugins/
│       ├── colorscheme.lua  # Catppuccin テーマ
│       ├── lsp.lua          # LSP 設定、Mason、nvim-cmp 補完
│       ├── treesitter.lua   # シンタックスハイライト、テキストオブジェクト
│       ├── telescope.lua    # ファジーファインダー
│       ├── ui.lua           # Lualine, Neo-tree, Noice, Oil など
│       ├── git.lua          # Gitsigns, LazyGit, git-worktree
│       ├── editing.lua      # Flash, マルチカーソル, surround, autopairs
│       ├── terminal.lua     # ToggleTerm
│       ├── debug.lua        # DAP（デバッガー）
│       ├── testing.lua      # Neotest
│       ├── formatting.lua   # conform.nvim
│       ├── notebook.lua     # Jupyter ノートブック（Jupynium, Molten）
│       ├── markdown.lua     # Markdown プレビュー
│       ├── lang.lua         # 言語別設定（Go, Rust, Tailwind など）
│       ├── image.lua        # ターミナル内画像プレビュー
│       ├── remote.lua       # distant.nvim, devcontainer
│       ├── diffview.lua     # 差分ビューア
│       ├── tmux.lua         # tmux 連携（smart-splits）
│       ├── utilities.lua    # Spectre, Harpoon, Undotree など
│       └── whichkey.lua     # キーバインドヒントポップアップ
├── setup.sh                 # Linux 向けセットアップスクリプト
└── setup.ps1                # Windows 向けセットアップスクリプト
```

## キーバインド

リーダーキー: `Space`

| カテゴリ | キー | 機能 |
|----------|------|------|
| **ファイル** | `SPC ff` | ファイル検索 |
| | `SPC fg` | テキスト検索（grep） |
| | `SPC fb` | バッファ一覧 |
| | `SPC e` | Neo-tree 開閉 |
| **LSP** | `gd` | 定義へジャンプ |
| | `gr` | 参照一覧 |
| | `K` | ホバー情報 |
| | `SPC rn` | リネーム |
| | `SPC ca` | コードアクション |
| **Git** | `SPC gg` | LazyGit |
| | `SPC gc` | コミット履歴 |
| | `SPC gB` | Git blame |
| **デバッグ** | `SPC bb` | ブレークポイント切替 |
| | `SPC bc` | 実行継続 |
| | `SPC bu` | デバッグ UI 切替 |
| **テスト** | `SPC Tn` | 最寄りのテスト実行 |
| | `SPC Tf` | ファイル内テスト実行 |
| **ウィンドウ** | `C-h/j/k/l` | ウィンドウ移動（tmux 対応） |
| | `S-h / S-l` | 前後のバッファ |
| **その他** | `SPC ?` | チートシート表示 |
| | `SPC tc` | Claude ターミナルにフォーカス |

Neovim 内で `:Cheatsheet` を実行すると全キーバインドを確認できます。

## LSP サーバー（Mason で自動インストール）

lua_ls, pyright, gopls, rust_analyzer, jsonls, yamlls, html, cssls, bashls, dockerls, tailwindcss

## ライセンス

MIT
