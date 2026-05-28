return {
  -- DAP（Debug Adapter Protocol）
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      { "<leader>bc", function() require("dap").continue() end, desc = "Debug: Continue" },
      { "<leader>bi", function() require("dap").step_into() end, desc = "Debug: Step into" },
      { "<leader>bo", function() require("dap").step_over() end, desc = "Debug: Step over" },
      { "<leader>bO", function() require("dap").step_out() end, desc = "Debug: Step out" },
      { "<leader>br", function() require("dap").repl.open() end, desc = "Debug: REPL" },
      { "<leader>bl", function() require("dap").run_last() end, desc = "Debug: Run last" },
      { "<leader>bt", function() require("dap").terminate() end, desc = "Debug: Terminate" },
      { "<leader>bu", function() require("dapui").toggle() end, desc = "Debug: Toggle UI" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- DAP UI の自動開閉
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Go デバッガ（delve）
      dap.adapters.delve = {
        type = "server",
        port = "${port}",
        executable = {
          command = "dlv",
          args = { "dap", "-l", "127.0.0.1:${port}" },
        },
      }
      dap.configurations.go = {
        {
          type = "delve",
          name = "Debug",
          request = "launch",
          program = "${file}",
        },
        {
          type = "delve",
          name = "Debug test",
          request = "launch",
          mode = "test",
          program = "${file}",
        },
      }
    end,
  },
  -- persistent-breakpoints（ブレークポイントの永続化）
  {
    "Weissle/persistent-breakpoints.nvim",
    dependencies = { "mfussenegger/nvim-dap" },
    event = "VeryLazy",
    opts = {
      load_breakpoints_event = { "BufReadPost" },
    },
    keys = {
      { "<leader>bb", function() require("persistent-breakpoints.api").toggle_breakpoint() end, desc = "Debug: Breakpoint toggle (persistent)" },
      { "<leader>bB", function() require("persistent-breakpoints.api").set_conditional_breakpoint() end, desc = "Debug: Conditional breakpoint" },
      { "<leader>bx", function() require("persistent-breakpoints.api").clear_all_breakpoints() end, desc = "Debug: Clear all breakpoints" },
    },
  },
  -- Python デバッガ設定（debugpy）
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require("dap-python").setup(vim.fn.expand("~/.config/nvim/venv/bin/python3"))
    end,
  },
}
