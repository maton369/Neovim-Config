# Neovim Config

Personal Neovim configuration built with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Screenshot

On startup, Neovim opens with Neo-tree (left), editor (center-top), terminal (center-bottom), and Claude Code (right).

## Requirements

- Neovim >= 0.10
- Git
- Node.js >= 18 (for Mason LSP servers)
- Python 3 + pip
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for Telescope live grep)
- [fd](https://github.com/sharkdp/fd) (for Telescope find files)
- C compiler (gcc/clang) for Treesitter parsers
- Optional: Go, Rust, [Claude Code](https://github.com/anthropics/claude-code)

## Quick Setup (Ubuntu)

```bash
git clone git@github.com:maton369/Neovim-Config.git ~/.config/nvim
~/.config/nvim/setup.sh
```

The setup script installs all dependencies and clones this config. Plugins install automatically on first launch.

## Manual Setup

```bash
# Clone config
git clone git@github.com:maton369/Neovim-Config.git ~/.config/nvim

# Launch Neovim (plugins auto-install via lazy.nvim)
nvim
```

## Structure

```
~/.config/nvim/
├── init.lua                 # Entry point: leader key, lazy.nvim bootstrap, startup layout
├── lua/
│   ├── options.lua          # Editor options (line numbers, indent, search, etc.)
│   ├── keymaps.lua          # Global keymaps and cheatsheet command
│   └── plugins/
│       ├── colorscheme.lua  # Catppuccin theme
│       ├── lsp.lua          # LSP config, Mason, nvim-cmp completion
│       ├── treesitter.lua   # Syntax highlighting, text objects
│       ├── telescope.lua    # Fuzzy finder
│       ├── ui.lua           # Lualine, Neo-tree, Noice, Oil, etc.
│       ├── git.lua          # Gitsigns, LazyGit, git-worktree
│       ├── editing.lua      # Flash, multi-cursor, surround, autopairs
│       ├── terminal.lua     # ToggleTerm
│       ├── debug.lua        # DAP (debugger)
│       ├── testing.lua      # Neotest
│       ├── formatting.lua   # conform.nvim
│       ├── notebook.lua     # Jupyter notebook support (Jupynium, Molten)
│       ├── markdown.lua     # Markdown preview
│       ├── lang.lua         # Language-specific (Go, Rust, Tailwind, etc.)
│       ├── image.lua        # Image preview in terminal
│       ├── remote.lua       # distant.nvim, devcontainer
│       ├── diffview.lua     # Diff viewer
│       ├── tmux.lua         # Tmux integration (smart-splits)
│       ├── utilities.lua    # Spectre, Harpoon, Undotree, etc.
│       └── whichkey.lua     # Keybinding hints popup
└── setup.sh                 # One-line setup script for Ubuntu
```

## Key Bindings

Leader key: `Space`

| Category | Key | Action |
|----------|-----|--------|
| **File** | `SPC ff` | Find files |
| | `SPC fg` | Live grep |
| | `SPC fb` | Buffers |
| | `SPC e` | Toggle Neo-tree |
| **LSP** | `gd` | Go to definition |
| | `gr` | References |
| | `K` | Hover |
| | `SPC rn` | Rename |
| | `SPC ca` | Code action |
| **Git** | `SPC gg` | LazyGit |
| | `SPC gc` | Git commits |
| | `SPC gB` | Git blame |
| **Debug** | `SPC bb` | Toggle breakpoint |
| | `SPC bc` | Continue |
| | `SPC bu` | Toggle debug UI |
| **Test** | `SPC Tn` | Run nearest test |
| | `SPC Tf` | Run file tests |
| **Window** | `C-h/j/k/l` | Move between windows (tmux-aware) |
| | `S-h / S-l` | Prev/next buffer |
| **Other** | `SPC ?` | Show full cheatsheet |
| | `SPC tc` | Focus Claude terminal |

Run `:Cheatsheet` in Neovim for the complete keybinding reference.

## LSP Servers (auto-installed by Mason)

lua_ls, pyright, gopls, rust_analyzer, jsonls, yamlls, html, cssls, bashls, dockerls, tailwindcss

## License

MIT
