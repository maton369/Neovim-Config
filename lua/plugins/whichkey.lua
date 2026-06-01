return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>c", group = "Code" },
        { "<leader>d", group = "Diagnostics" },
        { "<leader>D", group = "DevContainer" },
        { "<leader>r", group = "Rename" },
        { "<leader>t", group = "Terminal" },
        { "<leader>b", group = "Debug" },
        { "<leader>T", group = "Test" },
        { "<leader>m", group = "Notebook" },
        { "<leader>h", group = "Harpoon" },
        { "<leader>s", group = "Search/Replace" },
        { "<leader>o", group = "Overseer" },
        { "<leader>z", desc = "Zen Mode" },
        { "<leader>a", group = "AI" },
      },
    },
  },
}
