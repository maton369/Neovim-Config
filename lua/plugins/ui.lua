return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local function hints()
        -- diffview のタブ内 (中央/右の diff pane 含む) はファイル種別に関わらず
        -- 「q で閉じる」 ヒントを優先。 戻り方が分からず迷子になる事故を防ぐ。
        if vim.t.diffview_view_initialized then
          return "q:Close diff  gT/gt:Tab  ␣gq:Close"
        end
        local ft = vim.bo.filetype
        if ft == "python" and vim.api.nvim_buf_get_name(0):match("%.ipynb$") then
          return "␣mi:Init ␣mx:Run ␣ms:Show ]c[c:Cell /:Find ␣fg:Grep ␣ff:File ␣?:Help"
        elseif ft == "toggleterm" then
          return "C-\\:Toggle C-h/k:Win ␣tt:Term ␣?:Help"
        elseif ft == "neo-tree" then
          return "/:Fnd C-x:Clr ⌫↑"
        elseif ft == "go" then
          return "␣cgt:Test ␣cgr:Run ␣cge:IfErr /:Find ␣fg:Grep ␣?:Help"
        elseif ft == "csv" or ft == "tsv" then
          return "␣cv:CSV View /:Find ␣?:Help"
        elseif ft == "markdown" then
          return "␣mp:Preview /:Find ␣fg:Grep ␣?:Help"
        end
        -- 全 ft の fallback。 検索系 (/:buf 内, ␣ff:filename, ␣fg:grep) を必ず含める。
        return "C-h/j/k/l:Win S-h/l:Buf /:Find ␣ff:Files ␣fg:Grep ␣tt:Term ␣?:Help"
      end
      local hints_component = { hints, color = { fg = "#7f849c" } }
      -- neo-tree pane の statusline ヒント。 pane 幅 (window.width) に収まる長さに
      -- 切り詰める必要があるため記号で圧縮。 / は fuzzy find (filter)、 C-x は
      -- filter クリア (find モードからの脱出)、 ⌫↑ は root を一階上に戻す。
      -- < > のソース切替は winbar に Files|Git|Bufs タブが見えるので省略。
      local neotree_hint = "/:Fnd C-x:Clr ⌫↑"
      local neotree_ext = {
        sections = {
          lualine_a = { function() return "Explorer" end },
          lualine_c = { { function() return neotree_hint end, color = { fg = "#7f849c" } } },
        },
        inactive_sections = {
          lualine_a = { function() return "Explorer" end },
          lualine_c = { { function() return neotree_hint end, color = { fg = "#7f849c" } } },
        },
        filetypes = { "neo-tree" },
      }
      local toggleterm_ext = {
        sections = {
          lualine_a = { function() return "Terminal" end },
          lualine_c = { { function() return "C-\\:Toggle C-h/k:Win ␣tt:Term ␣?:Help" end, color = { fg = "#7f849c" } } },
        },
        inactive_sections = {
          lualine_a = { function() return "Terminal" end },
          lualine_c = { { function() return "C-\\:Toggle C-h/k:Win ␣tt:Term ␣?:Help" end, color = { fg = "#7f849c" } } },
        },
        filetypes = { "toggleterm" },
      }
      -- diffview のファイルパネル / ファイル履歴パネル用 (DiffviewFiles /
      -- DiffviewFileHistory)。 上の hints() 関数は filetype が markdown 等の
      -- 通常型を返すケースで diff 本体 pane を救済するので、 こちらは panel 専用。
      local diffview_hint = "q:Close  j/k:↑↓  <cr>:Open file"
      local diffview_ext = {
        sections = {
          lualine_a = { function() return "Diffview" end },
          lualine_c = { { function() return diffview_hint end, color = { fg = "#7f849c" } } },
        },
        inactive_sections = {
          lualine_a = { function() return "Diffview" end },
          lualine_c = { { function() return diffview_hint end, color = { fg = "#7f849c" } } },
        },
        filetypes = { "DiffviewFiles", "DiffviewFileHistory" },
      }
      return {
        sections = {
          lualine_c = { "filename", hints_component },
        },
        inactive_sections = {
          lualine_c = { "filename", hints_component },
        },
        extensions = { neotree_ext, toggleterm_ext, diffview_ext },
      }
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  -- noice.nvim（コマンドライン・検索・通知の UI 刷新）
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
        lsp_doc_border = true,
      },
    },
  },
  -- nvim-notify（通知ポップアップ）
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 3000,
      max_height = function() return math.floor(vim.o.lines * 0.75) end,
      max_width = function() return math.floor(vim.o.columns * 0.75) end,
    },
  },
  -- dropbar.nvim（パンくずリスト winbar）
  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      bar = {
        enable = function(buf, win)
          -- .ipynb ではnotebook.lua側のwinbarを使うため無効化
          local name = vim.api.nvim_buf_get_name(buf)
          if name:match("%.ipynb$") then return false end
          return vim.fn.win_gettype(win) == ""
        end,
      },
    },
  },
  -- dashboard-nvim（起動画面）
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      theme = "hyper",
      config = {
        week_header = { enable = true },
        shortcut = {
          { desc = " Find File", group = "Label", action = "Telescope find_files", key = "f" },
          { desc = " Recent", group = "Label", action = "Telescope oldfiles", key = "r" },
          { desc = " Grep", group = "Label", action = "Telescope live_grep", key = "g" },
          { desc = " Lazy", group = "Label", action = "Lazy", key = "l" },
          { desc = " Quit", group = "Label", action = "qa", key = "q" },
        },
      },
    },
  },
  -- twilight.nvim（カーソル周辺以外を薄暗く表示）
  {
    "folke/twilight.nvim",
    keys = {
      { "<leader>tw", "<cmd>Twilight<cr>", desc = "Twilight toggle" },
    },
    opts = {},
  },
  -- tint.nvim（非アクティブウィンドウを薄暗く表示）
  {
    "levouh/tint.nvim",
    event = "VeryLazy",
    opts = {
      tint = -45,
      saturation = 0.6,
    },
  },
  -- neominimap.nvim（コードミニマップ）
  {
    "Isrothy/neominimap.nvim",
    version = "v3.*.*",
    event = "VeryLazy",
    init = function()
      vim.g.neominimap = {
        auto_enable = false,
      }
    end,
    keys = {
      { "<leader>nm", "<cmd>Neominimap toggle<cr>", desc = "Minimap toggle" },
    },
  },
  -- zen-mode（集中モード）
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = { width = 120 },
    },
  },
  -- lsp_lines（診断を仮想行で表示）
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    event = "LspAttach",
    config = function()
      require("lsp_lines").setup()
      -- デフォルトの virtual_text を無効化（lsp_lines と重複するため）
      vim.diagnostic.config({ virtual_text = false })
    end,
    keys = {
      {
        "<leader>dl",
        function()
          local new = not vim.diagnostic.config().virtual_lines
          vim.diagnostic.config({ virtual_lines = new, virtual_text = not new })
        end,
        desc = "Toggle lsp_lines",
      },
    },
  },
  -- nvim-scrollbar（スクロールバーに診断・検索・Git 表示）
  {
    "petertriho/nvim-scrollbar",
    event = "VeryLazy",
    dependencies = { "lewis6991/gitsigns.nvim" },
    config = function()
      require("scrollbar").setup()
      require("scrollbar.handlers.gitsigns").setup()
    end,
  },
  -- oil.nvim（ファイルシステムをバッファとして編集）
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Oil: Open parent dir" },
    },
    opts = {
      view_options = {
        show_hidden = true,
      },
    },
  },
  -- smart-splits（Neovim⇔tmux/kitty のウィンドウ移動統一）
  {
    "mrjones2014/smart-splits.nvim",
    event = "VeryLazy",
    config = function()
      local ss = require("smart-splits")
      ss.setup()
      vim.keymap.set("n", "<C-h>", ss.move_cursor_left, { desc = "Move left" })
      vim.keymap.set("n", "<C-j>", ss.move_cursor_down, { desc = "Move down" })
      vim.keymap.set("n", "<C-k>", ss.move_cursor_up, { desc = "Move up" })
      vim.keymap.set("n", "<C-l>", ss.move_cursor_right, { desc = "Move right" })
      vim.keymap.set("n", "<M-h>", ss.resize_left, { desc = "Resize left" })
      vim.keymap.set("n", "<M-j>", ss.resize_down, { desc = "Resize down" })
      vim.keymap.set("n", "<M-k>", ss.resize_up, { desc = "Resize up" })
      vim.keymap.set("n", "<M-l>", ss.resize_right, { desc = "Resize right" })
    end,
  },
  -- yazi.nvim（フローティングファイルマネージャ）
  {
    "mikavilpas/yazi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>y", "<cmd>Yazi<cr>", desc = "Yazi (current file)" },
      { "<leader>Y", "<cmd>Yazi cwd<cr>", desc = "Yazi (cwd)" },
    },
    opts = {},
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = { 
      "nvim-lua/plenary.nvim", 
      "nvim-tree/nvim-web-devicons", 
      "MunifTanjim/nui.nvim" 
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer NeoTree" },
      { "<leader>gs", "<cmd>Neotree git_status toggle<cr>", desc = "Git Status (Neo-tree)" },
    },
    opts = {
      source_selector = {
        winbar = true,
        sources = {
          { source = "filesystem", display_name = " Files" },
          { source = "git_status", display_name = " Git" },
          { source = "buffers", display_name = " Bufs" },
        },
      },
      window = {
        -- statusline のヒント (<>:Tab .↓ ⌫↑ ?:H) が "Explorer" ラベルと並んで
        -- 入る最低幅。 25 だと左側が truncate されてキー名が読めなくなる。
        width = 28,
      },
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      -- Git タブ (Neotree git_status) で Enter / o したら、 そのパスを path filter
      -- として diffview に投げる。 git_status は flat list なので展開する子要素を
      -- 持たない (toggle_node が空振りする) ためツリー展開はしない代わりに、
      -- ディレクトリ / submodule の場合はその配下の変更ファイル一覧を diffview
      -- 左パネルに並べて差分を見比べられるようにする。
      git_status = {
        window = {
          mappings = {
            ["<cr>"] = "diff_open",
            ["o"]    = "diff_open",
          },
        },
        commands = {
          diff_open = function(state)
            local node = state.tree:get_node()
            if not node then return end
            vim.cmd("DiffviewOpen -- " .. vim.fn.fnameescape(node.path))
          end,
        },
      },
      default_component_configs = {
        -- VSCode 方式: シンボルアイコンは出さず、 ファイル名の色だけで git status を
        -- 表現する。 (元設定の ✚ ✖ 󰁕 󰄱 等はファイル名の右に出てコード領域に
        -- 食い込んでいたため)。 色は下の set_neotree_git_hl() で上書き。
        git_status = {
          symbols = {
            added     = "",
            modified  = "",
            deleted   = "",
            renamed   = "",
            untracked = "",
            ignored   = "",
            unstaged  = "",
            staged    = "",
            conflict  = "",
          },
        },
        -- LSP diagnostic の Error/Warn 等を示す E / W / I / H 文字も同様に消す。
        -- VSCode はエクスプローラでファイル名に色を付けて伝えるので、 そちらに揃える
        -- (色は NeoTreeFileNameOpened など別系統で出る)。
        diagnostics = {
          symbols = {
            hint  = "",
            info  = "",
            warn  = "",
            error = "",
          },
        },
        name = {
          use_git_status_colors = true,
        },
      },
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)

      -- VSCode (workbench.colorCustomizations の gitDecoration.*) の色に合わせる:
      --   modifiedResourceForeground: #E2C08D (黄褐)
      --   addedResourceForeground:    #81B88B (緑)
      --   deletedResourceForeground:  #C74E39 (赤)
      --   untrackedResourceForeground: #73C991 (明緑)
      --   ignoredResourceForeground:  #8C8C8C (灰)
      --   conflictingResourceForeground: #E4676B (赤寄り)
      local function set_neotree_git_hl()
        vim.api.nvim_set_hl(0, "NeoTreeGitModified",  { fg = "#e2c08d" })
        vim.api.nvim_set_hl(0, "NeoTreeGitAdded",     { fg = "#81b88b" })
        vim.api.nvim_set_hl(0, "NeoTreeGitDeleted",   { fg = "#c74e39" })
        vim.api.nvim_set_hl(0, "NeoTreeGitRenamed",   { fg = "#e2c08d" })
        vim.api.nvim_set_hl(0, "NeoTreeGitUntracked", { fg = "#73c991" })
        vim.api.nvim_set_hl(0, "NeoTreeGitIgnored",   { fg = "#8c8c8c" })
        vim.api.nvim_set_hl(0, "NeoTreeGitConflict",  { fg = "#e4676b" })
        vim.api.nvim_set_hl(0, "NeoTreeGitStaged",    { fg = "#81b88b" })
        vim.api.nvim_set_hl(0, "NeoTreeGitUnstaged",  { fg = "#e2c08d" })
      end
      set_neotree_git_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_neotree_git_hl })
    end,
    -- 起動時の Neotree 表示は init.lua の VimEnter layout autocmd が担当する
    -- (ここで重ねて vim.schedule すると window 1000 への戻り先参照が遅延 callback で
    --  発火する頃に init.lua の `only` でその window が消えていて Invalid window id
    --  エラーになる)。
  }
}