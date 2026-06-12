return {
  -- トラブル（診断一覧パネル）
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
    },
    opts = {},
  },
  -- Todo コメントハイライト
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  -- インデントスコープアニメーション
  {
    "echasnovski/mini.indentscope",
    event = { "BufReadPre", "BufNewFile" },
    opts = { symbol = "│" },
  },
  -- harpoon（ファイルマーク＆瞬時切り替え）
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon: Add file" },
      { "<leader>hh", function() local harpoon = require("harpoon"); harpoon.ui:toggle_quick_menu(harpoon:list()) end, desc = "Harpoon: Menu" },
      { "<C-1>", function() require("harpoon"):list():select(1) end, desc = "Harpoon: File 1" },
      { "<C-2>", function() require("harpoon"):list():select(2) end, desc = "Harpoon: File 2" },
      { "<C-3>", function() require("harpoon"):list():select(3) end, desc = "Harpoon: File 3" },
      { "<C-4>", function() require("harpoon"):list():select(4) end, desc = "Harpoon: File 4" },
    },
    config = function()
      require("harpoon"):setup()
    end,
  },
  -- nvim-spectre（プロジェクト全体の検索＆置換）
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>sr", function() require("spectre").open() end, desc = "Search & Replace (Spectre)" },
      { "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, desc = "Search current word" },
      { "<leader>sr", function() require("spectre").open_visual() end, mode = "v", desc = "Search selection" },
    },
  },
  -- auto-session（セッション自動保存/復元）
  {
    "rmagatti/auto-session",
    event = "VimEnter",
    -- SSH 経由ではセッション復元が VimEnter レイアウト構築と競合するため無効化
    cond = function()
      return not (vim.env.SSH_CLIENT or vim.env.SSH_TTY)
    end,
    opts = {
      suppressed_dirs = { "~/", "~/Downloads", "/tmp" },
      pre_save_cmds = {
        "Neotree close",
        "ToggleTermToggleAll",
        -- セッション保存前にターミナルバッファを全て閉じる
        function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].buftype == "terminal" then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end,
      },
      bypass_save_filetypes = { "neo-tree", "toggleterm", "trouble", "terminal" },
    },
  },
  -- nvim-bqf（quickfix 強化）
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {},
  },
  -- nvim-ufo（高機能コード折りたたみ）
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "VeryLazy",
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
      { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
    },
    opts = {
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
    },
  },
  -- nvim-early-retirement（非アクティブバッファ自動クローズ）
  {
    "chrisgrieser/nvim-early-retirement",
    event = "VeryLazy",
    opts = {
      retirementAgeMins = 20,
    },
  },
  -- バッファタブ
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    keys = {
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete Buffer" },
    },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        offsets = {
          { filetype = "neo-tree", text = "Explorer", highlight = "Directory" },
        },
        -- バッファ移動キーヒントを タブ列の左 (バッファタブの直前) に常時表示。
        -- :bp / :bn と等価の S-h / S-l がデフォルト keymap (keys 参照)。
        custom_areas = {
          left = function()
            return {
              { text = " :bp ⇧h ", fg = "#7aa2f7" },
              { text = " :bn ⇧l ", fg = "#7aa2f7" },
              { text = " :bd ␣bd ", fg = "#f7768e" },
              { text = " │ " },
            }
          end,
        },
      },
    },
  },
}
