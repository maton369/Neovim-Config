local lang = require("lang_detect")

-- カーソル位置のセルの出力画像をクリップボードにコピー（macOS）
local function copy_cell_image()
  local ok, image_api = pcall(require, "image")
  if not ok then
    vim.notify("image.nvim not loaded", vim.log.levels.ERROR)
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local images = image_api.get_images({ buffer = bufnr })
  if #images == 0 then
    vim.notify("No output image found", vim.log.levels.WARN)
    return
  end
  -- カーソルに最も近い（直下の）画像を選択
  local best = nil
  local best_dist = math.huge
  for _, img in ipairs(images) do
    if img.geometry and img.geometry.y then
      local dist = math.abs(img.geometry.y - cursor_row)
      if dist < best_dist then
        best_dist = dist
        best = img
      end
    end
  end
  if not best or not best.original_path then
    vim.notify("No image near cursor", vim.log.levels.WARN)
    return
  end
  local path = best.original_path
  vim.fn.system("osascript -e 'set the clipboard to (read (POSIX file \"" .. path .. "\") as «class PNGf»)'")
  if vim.v.shell_error == 0 then
    vim.notify("Copied: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
  else
    vim.notify("Failed to copy image", vim.log.levels.ERROR)
  end
end

-- 全セル実行（カーネルは事前に <leader>mi で初期化しておくこと）
local function run_all_cells()
  -- カーネルが起動済みか確認
  local ok = pcall(vim.cmd, "MoltenInterrupt")
  if not ok then
    vim.notify("カーネル未起動。先に <leader>mi で初期化してください", vim.log.levels.WARN)
    return
  end
  local nn = require("notebook-navigator")
  local save_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd("normal! gg")
  nn.move_cell("d") -- 最初のセルへ
  local max = vim.api.nvim_buf_line_count(0)
  local visited = {}
  while true do
    local pos = vim.api.nvim_win_get_cursor(0)[1]
    if visited[pos] then break end
    visited[pos] = true
    nn.run_and_move()
    if vim.api.nvim_win_get_cursor(0)[1] >= max then
      nn.run_cell()
      break
    end
  end
  pcall(vim.api.nvim_win_set_cursor, 0, save_pos)
end

-- .ipynb を開いた際にキー操作ガイドを winbar に常時表示
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.ipynb",
  callback = function()
    vim.wo.winbar = table.concat({
      "%#Title# Notebook %*",
      "%#Comment#│%*",
      " ␣mi Init",
      " ␣ma All",
      " ␣mx Run",
      " ␣mX Run+Move",
      " ␣ml Line",
      " ␣mr ReEval",
      " ]c [c Move",
      " ␣ms Show",
      " ␣mh Hide",
      " ␣md Del",
      " ␣my Copy",
    }, " ")
  end,
})

-- .ipynb をメモリ上で Python percent 形式に変換（中間ファイル不要）。
-- jupytext が無いマシン (notebook 用 venv 未構築) では autocmd 自体登録しない。
-- 登録だけして system 呼び出しが silent fail すると buffer が JSON のまま残って
-- 何が起きたか分からなくなるので、明示的に gate する。
local ipynb_group = vim.api.nvim_create_augroup("IpynbInMemory", { clear = true })

if lang.notebook then
vim.api.nvim_create_autocmd("BufReadPost", {
  group = ipynb_group,
  pattern = "*.ipynb",
  callback = function(ev)
    local filename = vim.api.nvim_buf_get_name(ev.buf)
    local result = vim.fn.system(
      "jupytext --to py:percent --from ipynb --output - " .. vim.fn.shellescape(filename)
    )
    if vim.v.shell_error == 0 then
      local lines = vim.split(result, "\n")
      -- 末尾の空行を除去
      if lines[#lines] == "" then
        table.remove(lines)
      end
      vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, lines)
      vim.bo[ev.buf].filetype = "python"
      vim.bo[ev.buf].modified = false
    end
  end,
})

vim.api.nvim_create_autocmd("BufWriteCmd", {
  group = ipynb_group,
  pattern = "*.ipynb",
  callback = function(ev)
    local filename = vim.api.nvim_buf_get_name(ev.buf)
    local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
    -- 空のセル（# %% の後に空行のみ）をバッファ全体から除去
    local cleaned = {}
    local i = 1
    while i <= #lines do
      if lines[i]:match("^# %%%%") then
        -- # %% を見つけたら、次の # %% か末尾まで中身があるか確認
        local cell_start = i
        local has_content = false
        i = i + 1
        while i <= #lines and not lines[i]:match("^# %%%%") do
          if not lines[i]:match("^%s*$") and not lines[i]:match("^# ---") then
            has_content = true
          end
          i = i + 1
        end
        if has_content then
          for j = cell_start, i - 1 do
            table.insert(cleaned, lines[j])
          end
        end
      else
        table.insert(cleaned, lines[i])
        i = i + 1
      end
    end
    local content = table.concat(cleaned, "\n") .. "\n"
    local result = vim.fn.system(
      "jupytext --to ipynb --from py:percent --output " .. vim.fn.shellescape(filename) .. " -",
      content
    )
    if vim.v.shell_error == 0 then
      vim.bo[ev.buf].modified = false
      vim.api.nvim_exec_autocmds("BufWritePost", { pattern = filename })
    else
      vim.notify("jupytext save failed: " .. result, vim.log.levels.ERROR)
    end
  end,
})
end -- if lang.notebook (BufReadPost / BufWriteCmd 一括 gate)

return {
  {
    "benlubas/molten-nvim",
    enabled = lang.notebook,
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    lazy = false,
    init = function()
      vim.g.molten_output_win_max_height = 40
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_wrap_output = true
      vim.g.molten_output_show_exec_time = true
      vim.g.molten_output_crop_border = false
      -- image.nvim との連携（kitty backend）
      vim.g.molten_image_provider = "image.nvim"
      -- Python パス（venv内の pynvim/jupyter を使用）
      vim.g.python3_host_prog = vim.fn.expand("~/.config/nvim/venv/bin/python3")

      -- molten のセル出力 (virtual text / virtual lines) は default で Comment
      -- にリンクされて薄いイタリックで読みづらい。 Normal の前景色寄りの
      -- 明るい色に上書きして可読性を上げる。 ColorScheme 切り替えにも追従。
      local function set_molten_hl()
        vim.api.nvim_set_hl(0, "MoltenVirtualText", { fg = "#dcdfe4", italic = false })
        vim.api.nvim_set_hl(0, "MoltenOutputBorder", { fg = "#7aa2f7" })
        vim.api.nvim_set_hl(0, "MoltenOutputBorderSuccess", { fg = "#9ece6a" })
        vim.api.nvim_set_hl(0, "MoltenOutputBorderFail", { fg = "#f7768e" })
        vim.api.nvim_set_hl(0, "MoltenOutputWin", { link = "Normal" })
      end
      set_molten_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_molten_hl })
    end,
    keys = {
      { "<leader>mi", "<cmd>MoltenInit<cr>", desc = "Molten: Init kernel" },
      { "<leader>mo", "<cmd>MoltenEvaluateOperator<cr>", desc = "Molten: Evaluate operator" },
      { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>", desc = "Molten: Evaluate line" },
      { "<leader>mr", "<cmd>MoltenReevaluateCell<cr>", desc = "Molten: Re-evaluate cell" },
      { "<leader>mv", ":<C-u>MoltenEvaluateVisual<cr>", mode = "v", desc = "Molten: Evaluate visual" },
      { "<leader>md", "<cmd>MoltenDelete<cr>", desc = "Molten: Delete cell" },
      { "<leader>mh", "<cmd>MoltenHideOutput<cr>", desc = "Molten: Hide output" },
      { "<leader>ms", "<cmd>MoltenShowOutput<cr>", desc = "Molten: Show output" },
      { "<leader>my", copy_cell_image, desc = "Molten: Copy image to clipboard" },
    },
  },
  {
    "GCBallesteros/NotebookNavigator.nvim",
    enabled = lang.notebook,
    dependencies = {
      "echasnovski/mini.comment",
      "benlubas/molten-nvim",
    },
    event = { "BufEnter *.ipynb" },
    opts = {
      activate_hydra_keys = nil,
      show_cell_markers = true,
      cell_markers = {
        python = "# %%",
      },
      repl_provider = "molten",
    },
    keys = {
      { "]c", function() require("notebook-navigator").move_cell("d") end, desc = "Next cell" },
      { "[c", function() require("notebook-navigator").move_cell("u") end, desc = "Prev cell" },
      { "<leader>mx", function() require("notebook-navigator").run_cell() end, desc = "Run cell" },
      { "<leader>mX", function() require("notebook-navigator").run_and_move() end, desc = "Run cell & move" },
      { "<leader>ma", run_all_cells, desc = "Run all cells" },
    },
  },
  -- Jupyter カーネル補完（nvim-cmp ソース）
  {
    "lkhphuc/jupyter-kernel.nvim",
    enabled = lang.notebook,
    opts = { timeout = 0.5 },
    cmd = { "JupyterAttach", "JupyterInspect", "JupyterExecute" },
    keys = {
      { "<leader>mk", "<cmd>JupyterAttach<cr>", desc = "Jupyter: Attach kernel" },
    },
  },
  -- Jupynium（ブラウザ同期 Jupyter）
  {
    "kiyoon/jupynium.nvim",
    enabled = lang.notebook, -- build hook が venv の pip を叩く
    build = vim.fn.expand("~/.config/nvim/venv/bin/pip") .. " install jupynium",
    cmd = { "JupyniumStartAndAttachToServer", "JupyniumStartSync" },
    keys = {
      { "<leader>mj", "<cmd>JupyniumStartAndAttachToServer<cr>", desc = "Jupynium: Start server" },
      { "<leader>mJ", "<cmd>JupyniumStartSync<cr>", desc = "Jupynium: Start sync" },
    },
  },
  -- セルテキストオブジェクト（ih/ah でセル内/外を選択）
  {
    "GCBallesteros/vim-textobj-hydrogen",
    dependencies = { "kana/vim-textobj-user" },
    ft = "python",
  },
}
