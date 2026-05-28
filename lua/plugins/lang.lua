local lang = require("lang_detect")

return {
  -- Go 開発ツール
  {
    "ray-x/go.nvim",
    enabled = lang.go,
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()',
    opts = {
      lsp_cfg = false,
      lsp_gofumpt = false,
      dap_debug = true,
    },
    keys = {
      { "<leader>cgt", "<cmd>GoTest<cr>", ft = "go", desc = "Go: Test" },
      { "<leader>cgr", "<cmd>GoRun<cr>", ft = "go", desc = "Go: Run" },
      { "<leader>cga", "<cmd>GoAddTag json<cr>", ft = "go", desc = "Go: Add json tags" },
      { "<leader>cgR", "<cmd>GoRmTag json<cr>", ft = "go", desc = "Go: Remove json tags" },
      { "<leader>cge", "<cmd>GoIfErr<cr>", ft = "go", desc = "Go: if err snippet" },
    },
  },

  -- TypeScript 強化（ts_ls より高速な専用 LSP）
  {
    "pmizio/typescript-tools.nvim",
    enabled = lang.node,
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {
      settings = {
        tsserver_max_memory = "auto",
        separate_diagnostic_server = true,
        publish_diagnostic_on = "insert_leave",
        complete_function_calls = true,
      },
    },
  },

  -- HTML タグ自動閉じ・リネーム
  {
    "windwp/nvim-ts-autotag",
    ft = { "html", "xml", "jsx", "tsx", "typescriptreact", "javascriptreact", "vue", "svelte" },
    opts = {},
  },

  -- Emmet（HTML/CSS ショートカット展開）
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "scss", "jsx", "tsx", "typescriptreact", "javascriptreact", "vue", "svelte" },
    init = function()
      vim.g.user_emmet_leader_key = "<C-z>"
    end,
  },

  -- Tailwind CSS カラーヒント・クラス補完
  {
    "luckasRanarison/tailwind-tools.nvim",
    enabled = lang.node, -- tailwindcss-language-server (npm) に依存
    name = "tailwind-tools",
    build = ":UpdateRemotePlugins",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "html", "css", "jsx", "tsx", "typescriptreact", "javascriptreact", "vue", "svelte" },
    opts = {},
  },

  -- YAML スキーマ選択（Kubernetes, GitHub Actions 等）
  {
    "someone-stole-my-name/yaml-companion.nvim",
    enabled = lang.node, -- yamlls (npm) を setup する
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    ft = { "yaml", "yml" },
    config = function()
      local cfg = require("yaml-companion").setup({
        lspconfig = {
          settings = {
            yaml = {
              validate = true,
              schemaStore = { enable = false, url = "" },
            },
          },
        },
      })
      require("lspconfig").yamlls.setup(cfg)
      require("telescope").load_extension("yaml_schema")
    end,
    keys = {
      { "<leader>fY", "<cmd>Telescope yaml_schema<cr>", ft = { "yaml", "yml" }, desc = "YAML Schema" },
    },
  },

  -- Rust 開発ツール
  {
    "mrcjkb/rustaceanvim",
    enabled = lang.rust,
    version = "^5",
    lazy = false,
  },
  -- Cargo.toml のバージョン管理
  {
    "saecki/crates.nvim",
    enabled = lang.rust,
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
      },
    },
  },
  -- overseer.nvim（タスクランナー）
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerRun", "OverseerToggle", "OverseerOpen" },
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer: Run task" },
      { "<leader>oo", "<cmd>OverseerToggle<cr>", desc = "Overseer: Toggle" },
    },
    opts = {},
  },
  -- vim-dadbod（データベースクライアント）
  {
    "tpope/vim-dadbod",
    cmd = "DB",
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      "tpope/vim-dadbod",
      "kristijanhusak/vim-dadbod-completion",
    },
    cmd = { "DBUI", "DBUIToggle" },
    keys = {
      { "<leader>od", "<cmd>DBUIToggle<cr>", desc = "Database UI" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  -- ccc.nvim（カラーピッカー＆ハイライト）
  {
    "uga-rosa/ccc.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "CccPick", "CccHighlighterToggle" },
    keys = {
      { "<leader>cp", "<cmd>CccPick<cr>", desc = "Color picker" },
      { "<leader>ch", "<cmd>CccHighlighterToggle<cr>", desc = "Color highlight toggle" },
    },
    opts = {
      highlighter = {
        auto_enable = true,
        lsp = true,
      },
    },
  },
  -- ecolog.nvim（.env ファイル補完＆機密マスキング）
  {
    "philosofonusus/ecolog.nvim",
    dependencies = { "hrsh7th/nvim-cmp" },
    keys = {
      { "<leader>fe", "<cmd>EcologGoto<cr>", desc = "Env: Go to var" },
    },
    opts = {
      integrations = {
        nvim_cmp = true,
      },
      shelter = {
        configuration = {
          partial_mode = false,
          mask_char = "*",
        },
        modules = {
          cmp = true,
        },
      },
    },
  },
  -- live-server（HTML ライブリロード）
  {
    "barrett-ruth/live-server.nvim",
    enabled = lang.node, -- build hook が `npm i -g live-server` を走らせる
    cmd = { "LiveServerStart", "LiveServerStop" },
    build = "npm i -g live-server",
    keys = {
      { "<leader>ls", "<cmd>LiveServerStart<cr>", ft = "html", desc = "Live Server Start" },
      { "<leader>lS", "<cmd>LiveServerStop<cr>", ft = "html", desc = "Live Server Stop" },
    },
    opts = {},
  },
  -- CSV 表示・編集
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    opts = {
      view = {
        display_mode = "border",
      },
    },
    keys = {
      { "<leader>cv", "<cmd>CsvViewToggle<cr>", ft = { "csv", "tsv" }, desc = "CSV: Toggle view" },
    },
  },
}
