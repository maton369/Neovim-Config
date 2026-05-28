-- 各言語ツールチェインの存在判定。lazy.nvim の `enabled` / mason の
-- ensure_installed / conform.formatters_by_ft などから参照して、ツールが入っていない
-- 言語の関連プラグインを最初から install / load しないようにするための共通モジュール。
local M = {}

function M.has(cmd)
  return vim.fn.executable(cmd) == 1
end

M.python = M.has("python3")
M.node = M.has("node")
M.go = M.has("go")
M.rust = M.has("cargo") or M.has("rustc")
-- notebook 関連 (molten / jupynium / .ipynb 変換) は ~/.config/nvim/venv に
-- jupytext などが入っている前提。setup.sh の §7 で構築される。
M.notebook = M.has("jupytext")

return M
