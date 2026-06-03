local lang = require("lang_detect")

-- 画像ファイルをクリップボードにコピー (OS 別 fallback)。
-- macOS: osascript, Linux/Wayland: wl-copy, Linux/X11: xclip。
local function copy_image_to_clipboard(path)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = "osascript -e 'set the clipboard to (read (POSIX file \""
      .. path .. "\") as «class PNGf»)'"
  elseif vim.fn.executable("wl-copy") == 1 then
    cmd = "wl-copy --type image/png < " .. vim.fn.shellescape(path)
  elseif vim.fn.executable("xclip") == 1 then
    cmd = "xclip -selection clipboard -t image/png -i " .. vim.fn.shellescape(path)
  else
    return false, "no clipboard tool (need osascript / wl-copy / xclip)"
  end
  vim.fn.system(cmd)
  return vim.v.shell_error == 0, nil
end

-- カーソル位置のセルの出力画像をクリップボードにコピー
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
  local ok, err = copy_image_to_clipboard(path)
  if ok then
    vim.notify("Copied: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
  else
    vim.notify("Failed to copy image" .. (err and (": " .. err) or ""), vim.log.levels.ERROR)
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

-- .ipynb を開いた際にキー操作ガイドを winbar に常時表示。
-- 左側に Notebook (molten) 操作、 区切りを挟んで右側に検索系。
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
      "%#Comment#│%*",
      "%#Title# Find %*",
      " /:Buf n/N:↑↓ Esc:Clr",
      " ␣fg:Grep",
      " ␣ff:File",
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
    -- NOTE: Neovim の vim.fn.system() は stderr も戻り値に混ぜる。 id 無しセルの
    -- .ipynb を読むと nbformat が出す MissingIDFieldWarning が buffer 先頭に
    -- 混入し、 次回保存時の py:percent round-trip を壊して markdown セルが脱落
    -- していた。 stderr を捨てて stdout (= py:percent) だけを buffer に入れる。
    local result = vim.fn.system(
      "jupytext --to py:percent --from ipynb --output - " .. vim.fn.shellescape(filename) .. " 2>/dev/null"
    )
    if vim.v.shell_error == 0 then
      local lines = vim.split(result, "\n")
      -- 末尾の空行を除去
      if lines[#lines] == "" then
        table.remove(lines)
      end
      -- LSP が既にアタッチしていると、バッファ全置換時に lsp/sync.lua の
      -- compute_end_range が assert 失敗する (E5108)。 先にデタッチし、
      -- filetype 設定後に Python LSP が自動で再アタッチされるようにする。
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
        vim.lsp.buf_detach_client(ev.buf, client.id)
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
    init = function()
      -- VSCode notebook 並みの大きさで画像 / セル出力を表示するための拡張。
      -- 旧設定 `molten_output_win_max_height = 40` だと matplotlib 標準の
      -- figsize=(6,3) (= 600x300 px ≈ 70 col × 35 行) でも float が 40 行に
      -- 切られて画像が縮小されていた。
      vim.g.molten_output_win_max_height = 999999
      -- 幅は現在の editor window に合わせて動的に設定する。
      -- 999999 だと float が Neo-tree 等のサイドバーに被る。
      -- BufEnter/WinEnter で都度更新し、 サイドバーを開閉しても追従する。
      vim.g.molten_output_win_max_width = 80 -- fallback
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinResized" }, {
        pattern = "*",
        callback = function()
          local ft = vim.bo.filetype
          if ft == "python" or vim.fn.expand("%:e") == "ipynb" then
            vim.g.molten_output_win_max_width = vim.api.nvim_win_get_width(0)
          end
        end,
      })
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
      -- 既にこの buffer に kernel が attach 済みの場合は再 init を抑止。
      -- <leader>mi を連打しても kernel が増殖しない (= "lab-cpu_1", "lab-cpu_2" …
      -- と orphan が並ぶ事故を防ぐ)。 強制的に新規 kernel を立てたい場合は
      -- <leader>mI (大文字) を使う。 既存 kernel を作り直したい時は :MoltenRestart!
      {
        "<leader>mi",
        function()
          local ok, running = pcall(vim.fn.MoltenRunningKernels, true)
          if ok and type(running) == "table" and #running > 0 then
            vim.notify(
              "Molten: kernel '"
                .. running[1]
                .. "' は既にこの buffer に attach 済み。\n"
                .. "  再作成: :MoltenRestart!\n"
                .. "  強制新規: <leader>mI",
              vim.log.levels.WARN
            )
            return
          end
          vim.cmd("MoltenInit")
        end,
        desc = "Molten: Init kernel (skip if already attached)",
      },
      {
        "<leader>mI",
        "<cmd>MoltenInit<cr>",
        desc = "Molten: Force new kernel (no gate)",
      },
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
