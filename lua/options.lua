local opt = vim.opt

-- 行番号
opt.number = true
opt.relativenumber = true

-- インデント
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- 検索
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- 表示
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

-- ファイル
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.autoread = true

-- 外部変更の自動検知（フォーカス時・バッファ切替時に自動リロード）
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function() vim.cmd("silent! checktime") end,
})

-- 分割
opt.splitbelow = true
opt.splitright = true

-- その他
-- クリップボードプロバイダ検出を遅延（起動時の外部コマンド検索を回避）
opt.clipboard = ""
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)
opt.mouse = "a"
opt.updatetime = 250
opt.timeoutlen = 300
opt.completeopt = "menu,menuone,noselect"

-- 不可視文字表示
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Python provider（Neovim専用venv）
vim.g.python3_host_prog = vim.fn.expand("~/.config/nvim/venv/bin/python3")

-- PDF 表示（ローカル: Preview.app + テキスト、SSH: テキストのみ）
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = "*.pdf",
  callback = function(ev)
    local filename = vim.api.nvim_buf_get_name(ev.buf)
    -- ローカル環境なら Preview.app で開く
    if not os.getenv("SSH_CONNECTION") then
      vim.fn.system("open " .. vim.fn.shellescape(filename))
    end
    -- バッファにはテキスト版を表示（検索・コピー用）
    local result = vim.fn.system("pdftotext -layout " .. vim.fn.shellescape(filename) .. " -")
    if vim.v.shell_error == 0 then
      local lines = vim.split(result, "\n")
      vim.bo[ev.buf].modifiable = true
      vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, lines)
      vim.bo[ev.buf].filetype = "text"
      vim.bo[ev.buf].buftype = "nofile"
      vim.bo[ev.buf].modifiable = false
      vim.bo[ev.buf].modified = false
    end
  end,
})
