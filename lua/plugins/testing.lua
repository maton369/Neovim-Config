return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      -- テストアダプター
      "nvim-neotest/neotest-python",
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-go",
    },
    keys = {
      { "<leader>Tn", function() require("neotest").run.run() end, desc = "Test: Nearest" },
      { "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Test: File" },
      { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Test: Summary" },
      { "<leader>To", function() require("neotest").output.open({ enter_mode = "float" }) end, desc = "Test: Output" },
      { "<leader>Tp", function() require("neotest").output_panel.toggle() end, desc = "Test: Output Panel" },
      { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Test: Debug nearest" },
      { "<leader>TS", function() require("neotest").run.stop() end, desc = "Test: Stop" },
      { "[T", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev failed test" },
      { "]T", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            runner = "pytest",
          }),
          require("neotest-vitest"),
          require("neotest-go"),
        },
      })
    end,
  },
}
