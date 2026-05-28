local function has(cmd)
  return vim.fn.executable(cmd) == 1
end

-- 実在するツールだけ formatters_by_ft / linters_by_ft に積む。
-- (ruff 未 install のマシンで Python ファイルを保存すると conform/nvim-lint が
--  ENOENT エラーを毎回吐くので、ここで先に弾く)
local formatters_by_ft = {}
if has("stylua") then formatters_by_ft.lua = { "stylua" } end
if has("ruff") then formatters_by_ft.python = { "ruff_format" } end
local has_prettier = has("prettierd") or has("prettier")
if has_prettier then
  local prettier_list = { "prettierd", "prettier", stop_after_first = true }
  for _, ft in ipairs({
    "javascript", "typescript", "typescriptreact", "javascriptreact",
    "json", "yaml", "html", "css", "markdown",
  }) do
    formatters_by_ft[ft] = prettier_list
  end
end
if has("gofmt") then formatters_by_ft.go = { "gofmt" } end
if has("rustfmt") then formatters_by_ft.rust = { "rustfmt" } end
if has("shfmt") then formatters_by_ft.sh = { "shfmt" } end

local linters_by_ft = {}
if has("ruff") then linters_by_ft.python = { "ruff" } end
if has("eslint_d") then
  for _, ft in ipairs({ "javascript", "typescript", "typescriptreact", "javascriptreact" }) do
    linters_by_ft[ft] = { "eslint_d" }
  end
end

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = formatters_by_ft,
      format_on_save = {
        timeout_ms = 3000,
        lsp_format = "fallback",
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = linters_by_ft
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
