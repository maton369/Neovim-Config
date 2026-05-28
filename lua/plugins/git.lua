return {
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },
  -- inline git blame（行末に blame 情報を表示）
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    opts = {
      enabled = true,
      date_format = "%Y-%m-%d",
      message_when_not_committed = "Not committed yet",
    },
    keys = {
      { "<leader>gB", "<cmd>GitBlameToggle<cr>", desc = "Git Blame toggle" },
    },
  },
  -- git-worktree（ワークツリー管理）
  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      { "<leader>gw", function() require("telescope").extensions.git_worktree.git_worktrees() end, desc = "Git Worktrees" },
      { "<leader>gW", function() require("telescope").extensions.git_worktree.create_git_worktree() end, desc = "Git Worktree Create" },
    },
    config = function()
      require("git-worktree").setup()
      require("telescope").load_extension("git_worktree")
    end,
  },
}
