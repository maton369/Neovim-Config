return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Comment toggle current line" },
      { "gc", mode = { "n", "v" }, desc = "Comment toggle" },
    },
    opts = {},
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },
  -- flash.nvim（高速カーソル移動）
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    },
  },
  -- undotree（undo 履歴の可視化）
  {
    "mbbill/undotree",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undotree" },
    },
  },
  -- multicursor（複数カーソル編集）
  {
    "jake-stewart/multicursor.nvim",
    event = "VeryLazy",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()
      local map = vim.keymap.set
      map({ "n", "v" }, "<C-d>", function() mc.matchAddCursor(1) end, { desc = "Add cursor on next match" })
      map({ "n", "v" }, "<C-S-d>", function() mc.matchAddCursor(-1) end, { desc = "Add cursor on prev match" })
      map("n", "<Esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        elseif mc.hasCursors() then
          mc.clearCursors()
        else
          vim.cmd("nohlsearch")
        end
      end)
    end,
  },
  -- nvim-spider（camelCase/snake_case 対応ワード移動）
  {
    "chrisgrieser/nvim-spider",
    keys = {
      { "w", "<cmd>lua require('spider').motion('w')<cr>", mode = { "n", "o", "x" }, desc = "Spider w" },
      { "e", "<cmd>lua require('spider').motion('e')<cr>", mode = { "n", "o", "x" }, desc = "Spider e" },
      { "b", "<cmd>lua require('spider').motion('b')<cr>", mode = { "n", "o", "x" }, desc = "Spider b" },
    },
  },
  -- refactoring.nvim（関数抽出・変数インライン化等）
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>re", function() require("refactoring").refactor("Extract Function") end, mode = "v", desc = "Extract Function" },
      { "<leader>rv", function() require("refactoring").refactor("Extract Variable") end, mode = "v", desc = "Extract Variable" },
      { "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, mode = { "n", "v" }, desc = "Inline Variable" },
      { "<leader>rf", function() require("refactoring").refactor("Extract Block To File") end, desc = "Extract Block To File" },
      { "<leader>rr", function() require("telescope").extensions.refactoring.refactors() end, mode = "v", desc = "Refactor menu" },
    },
    config = function()
      require("refactoring").setup()
      require("telescope").load_extension("refactoring")
    end,
  },
  -- neogen（ドキュメントコメント自動生成）
  {
    "danymat/neogen",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>cn", function() require("neogen").generate() end, desc = "Generate docstring" },
    },
    opts = {
      snippet_engine = "luasnip",
    },
  },
  -- inc-rename.nvim（リアルタイムプレビュー付きリネーム）
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    keys = {
      { "<leader>rn", function() return ":IncRename " .. vim.fn.expand("<cword>") end, expr = true, desc = "Rename (preview)" },
    },
    opts = {},
  },
  -- cellular-automaton（息抜きアニメーション）
  {
    "Eandrju/cellular-automaton.nvim",
    keys = {
      { "<leader>fml", "<cmd>CellularAutomaton make_it_rain<cr>", desc = "Make it rain" },
    },
  },
  -- yanky.nvim（ヤンク履歴リング）
  {
    "gbprod/yanky.nvim",
    dependencies = { "kkharji/sqlite.lua" },
    event = "VeryLazy",
    opts = {
      ring = { storage = "sqlite" },
    },
    keys = {
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before" },
      { "<C-p>", "<Plug>(YankyPreviousEntry)", desc = "Yanky: Previous entry" },
      { "<C-n>", "<Plug>(YankyNextEntry)", desc = "Yanky: Next entry" },
      { "<leader>fy", "<cmd>Telescope yank_history<cr>", desc = "Yank history" },
    },
    config = function(_, opts)
      require("yanky").setup(opts)
      require("telescope").load_extension("yank_history")
    end,
  },
  -- marks.nvim（マーク位置の可視化）
  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {},
  },
  -- codesnap.nvim（コードスクリーンショット）
  {
    "mistricky/codesnap.nvim",
    build = "make",
    cmd = { "CodeSnap", "CodeSnapSave" },
    keys = {
      { "<leader>cs", "<cmd>CodeSnap<cr>", mode = "v", desc = "Code snapshot (clipboard)" },
      { "<leader>cS", "<cmd>CodeSnapSave<cr>", mode = "v", desc = "Code snapshot (save)" },
    },
    opts = {
      mac_window_bar = true,
      watermark = "",
      has_breadcrumbs = true,
    },
  },
  -- avante.nvim（Cursor AI 風のAIペアプログラミング）
  {
    "yetone/avante.nvim",
    version = false,
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    cmd = { "AvanteAsk", "AvanteEdit", "AvanteToggle" },
    opts = {
      provider = "copilot",
    },
    keys = {
      { "<leader>aa", "<cmd>AvanteAsk<cr>", mode = { "n", "v" }, desc = "Avante: Ask" },
      { "<leader>ae", "<cmd>AvanteEdit<cr>", mode = "v", desc = "Avante: Edit selection" },
      { "<leader>at", "<cmd>AvanteToggle<cr>", desc = "Avante: Toggle" },
    },
  },
  -- CopilotChat（Copilot Chat をエディタ内で）
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      "github/copilot.vim",
      "nvim-lua/plenary.nvim",
    },
    build = "make tiktoken",
    cmd = { "CopilotChat", "CopilotChatExplain", "CopilotChatReview", "CopilotChatTests" },
    keys = {
      { "<leader>ac", "<cmd>CopilotChat<cr>", mode = { "n", "v" }, desc = "Copilot Chat" },
      { "<leader>ax", "<cmd>CopilotChatExplain<cr>", mode = "v", desc = "Copilot: Explain" },
      { "<leader>ar", "<cmd>CopilotChatReview<cr>", mode = "v", desc = "Copilot: Review" },
      { "<leader>aT", "<cmd>CopilotChatTests<cr>", mode = "v", desc = "Copilot: Generate tests" },
    },
    opts = {},
  },
  -- AI 補完（GitHub Copilot）
  {
    "github/copilot.vim",
    event = "InsertEnter",
    init = function()
      vim.g.copilot_no_tab_map = true
    end,
    config = function()
      vim.keymap.set("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        desc = "Copilot: Accept",
      })
      vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)", { desc = "Copilot: Dismiss" })
      vim.keymap.set("i", "<M-]>", "<Plug>(copilot-next)", { desc = "Copilot: Next suggestion" })
      vim.keymap.set("i", "<M-[>", "<Plug>(copilot-previous)", { desc = "Copilot: Prev suggestion" })
    end,
  },
}
