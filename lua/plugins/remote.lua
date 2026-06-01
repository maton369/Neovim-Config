return {
  {
    "chipsenkbeil/distant.nvim",
    branch = "v0.3",
    enabled = false,
    config = function()
      require("distant"):setup()
    end,
  },
  {
    "esensar/nvim-dev-container",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("devcontainer").setup({
        attach_mounts = {
          neovim_config = {
            enabled = true,
            options = { "readonly" },
          },
          neovim_data = {
            enabled = false,
            options = {},
          },
        },
        compose_command = "docker compose",
        -- コンテナ内でNeovimを起動する（リモートにVim不要、自動でインストールされる）
        nvim_installation_commands_provider = function()
          return {
            "apt-get update",
            "apt-get install -y curl git",
            "curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz",
            "tar -C /opt -xzf nvim-linux-x86_64.tar.gz",
            "ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim",
            "rm nvim-linux-x86_64.tar.gz",
          }
        end,
      })

      -- devcontainer.json があるプロジェクトを開いた時の自動検出
      vim.api.nvim_create_autocmd("DirChanged", {
        callback = function()
          local devcontainer_path = vim.fn.findfile("devcontainer.json", ".devcontainer/")
          if devcontainer_path ~= "" then
            vim.notify("DevContainer detected. Use :DevcontainerUp to start.", vim.log.levels.INFO)
          end
        end,
      })
    end,
    keys = {
      { "<leader>Du", "<cmd>DevcontainerUp<cr>", desc = "DevContainer Up (start)" },
      { "<leader>Dc", "<cmd>DevcontainerConnect<cr>", desc = "DevContainer Connect" },
      { "<leader>Dd", "<cmd>DevcontainerDown<cr>", desc = "DevContainer Down (stop)" },
      { "<leader>De", "<cmd>DevcontainerExec<cr>", desc = "DevContainer Exec" },
    },
  },
}
