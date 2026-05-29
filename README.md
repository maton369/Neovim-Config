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

`setup.sh` のオプション:

- `--conda-kernels` — `~/{miniforge3,anaconda3,miniconda3}/envs/*` 配下で `ipykernel` が入っている conda env を Jupyter kernel として `--user` 登録する。`:MoltenInit` のピッカーに並ぶようになる。デフォルトでは行わない。

### リモートサーバで使う (SSH)

このコンフィグは「手元 PC のターミナルから SSH でサーバに入り、サーバ側で nvim を動かす」用途も想定しています。**画像表示 (matplotlib / molten + image.nvim) を動かしたい場合は手元 PC 側の構成にいくつか前提があります**。

#### 動作する手元端末の構成

| 構成 | 画像表示 | 備考 |
|---|---|---|
| **Ghostty + tmux + ssh** | ✅ | このリポジトリで主に検証してきた構成。下記「tmux 設定」参照 |
| **kitty + ssh** (tmux なし) | ✅ | tmux なしで kitty 直 SSH。`lua/plugins/image.lua` の DCS ラップ強制ブロックを外す必要あり (後述) |
| **wezterm + ssh** | ✅ | kitty graphics protocol 対応。kitty と同様 |
| **Cursor / VSCode 内蔵ターミナル** | ❌ | Electron / xterm.js 製で kitty graphics 非対応。コード編集のみ可、画像は別アプリで確認 |
| **GNOME Terminal / xterm 等** | ❌ | kitty graphics protocol も sixel も非対応 |

サーバ側にターミナルを入れる必要は **ありません**。kitty graphics protocol は「手元端末がレンダリング、サーバはエスケープシーケンスを TTY に流すだけ」の仕組みで、SSH バイトストリームを透過します。

#### 手元 tmux を使う場合の設定 (Ghostty / kitty + tmux)

tmux はデフォルトで kitty graphics の APC sequence を破棄します。手元 PC の `~/.tmux.conf` に以下を追加して有効化:

```tmux
set -g allow-passthrough on
```

反映:

```bash
tmux source-file ~/.tmux.conf
# または
tmux kill-server && tmux
```

確認:

```bash
tmux show-options -g | grep allow-passthrough
# → allow-passthrough on
```

要件は tmux **3.3 以降** (`tmux -V` で確認)。それ未満なら `apt install tmux` の最新版や homebrew で更新する必要あり。

#### tmux を使わない場合 (kitty / wezterm 直 SSH)

`lua/plugins/image.lua` の以下のブロックは「手元に tmux が居る」前提で kitty graphics escape を DCS でラップして送出します。tmux を経由しない構成では端末が DCS を理解できず画像が出ません。

```lua
if vim.env.SSH_CLIENT or vim.env.SSH_TTY then
  for _, modname in ipairs({ "image/utils/tmux", "image.utils.tmux" }) do
    ...
    tmux.is_tmux = true
    tmux.has_passthrough = true
  end
end
```

このブロックを削除するか、`vim.env.TMUX` を追加条件にして「手元に tmux 環境変数が SSH で渡ってくる時のみ」 にすると素 SSH でも動きます。

#### 動作確認

`notebooks/画像表示テスト.ipynb` を開いて:

```vim
<leader>mi    " kernel init (Python (lab-cpu) などを選択)
]c            " plt.show() を含むセルへ移動
<leader>mx    " 実行
<leader>ms    " float window に画像描画
```

sin/cos の線グラフ、散布図、ヒートマップ、サブプロットなどが描画されればパス全体が通っています。

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
