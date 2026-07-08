local map = vim.keymap.set

-- ウィンドウ移動・リサイズは smart-splits.nvim に委譲（tmux/kitty 連携対応）

-- フォントサイズ変更 — iTerm2 (macOS) 専用。 Linux 端末は端末側のショートカット
-- (kitty/alacritty/foot/wezterm 等は Ctrl-= / Ctrl--) を使う想定なので登録しない。
if vim.fn.has("mac") == 1 then
  local function change_iterm_font_size(delta)
    vim.fn.system(string.format([[osascript -e '
      tell application "iTerm2"
        tell current session of current window
          set curFont to name of profile
        end tell
        tell profile curFont
          set normalFont to normal font
          -- フォント名からサイズを取得して変更
        end tell
      end tell' 2>/dev/null]], delta))
    -- 確実な方法: キーストロークをシミュレート
    if delta > 0 then
      vim.fn.system([[osascript -e 'tell application "System Events" to keystroke "+" using command down']])
    else
      vim.fn.system([[osascript -e 'tell application "System Events" to keystroke "-" using command down']])
    end
  end

  map("n", "<leader>=", function() change_iterm_font_size(1) end, { desc = "Font size +" })
  map("n", "<leader>-", function() change_iterm_font_size(-1) end, { desc = "Font size -" })
end

-- 行移動（ビジュアルモード）
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- jk で ESC（Insert / Visual / Command モード）
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("v", "jk", "<Esc>", { desc = "Exit visual mode" })
map("c", "jk", "<C-c>", { desc = "Exit command mode" })

-- 検索ハイライト解除
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- ターミナルモード (`:terminal` / `terminal claude` 等) からの操作。
-- nvim 標準の terminal 抜けは <C-\><C-n> で押しづらい。 ただし Esc 系を上書きすると
-- claude TUI 等の cancel が壊れるので、 ウィンドウ移動に直接バインドして
-- 「terminal 抜け + 別 window へ移動」 を 1 ストロークで行えるようにする。
-- 単に外に出たいだけなら <C-\><C-n> もそのまま使える。
for _, lr in ipairs({ { "h", "left" }, { "j", "down" }, { "k", "up" }, { "l", "right" } }) do
  local key, dir = lr[1], lr[2]
  map("t", "<C-" .. key .. ">", function()
    vim.cmd("stopinsert")
    local ok, ss = pcall(require, "smart-splits")
    if ok then
      ss["move_cursor_" .. dir]()
    else
      vim.cmd("wincmd " .. key)
    end
  end, { desc = "Terminal -> move " .. dir })
end

-- ターミナルモードでの UTF-8 安全ペースト。
-- Neovim の libvterm はペースト時にマルチバイト UTF-8 をバイト境界で分割し
-- 文字化けさせるバグがある (neovim/neovim#16245)。
-- vim.paste をオーバーライドして Cmd+V (ブラケットペースト) でも
-- nvim_chan_send 経由で一括送信し、vterm を迂回して文字化けを防ぐ。
local orig_paste = vim.paste
vim.paste = function(lines, phase)
  if vim.api.nvim_get_mode().mode == "t" then
    local chan = vim.b.terminal_job_id
    if chan then
      vim.api.nvim_chan_send(chan, table.concat(lines, "\n"))
      return true
    end
  end
  return orig_paste(lines, phase)
end

-- C-S-v でも明示的にペースト可能（レジスタ経由）
map("t", "<C-S-v>", function()
  local content = vim.fn.getreg("+")
  if content ~= "" then
    local chan = vim.b.terminal_job_id
    if chan then
      vim.api.nvim_chan_send(chan, content)
    end
  end
end, { desc = "Paste to terminal (UTF-8 safe)" })

-- ファイル全体をクリップボードにコピー
map("n", "<leader>by", '<cmd>%y+<cr>', { desc = "Copy entire file" })

-- バッファ保存
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

-- 新規 .ipynb 作成
vim.api.nvim_create_user_command("Nbnew", function(opts)
  local name = opts.args ~= "" and opts.args or "main.ipynb"
  if not name:match("%.ipynb$") then name = name .. ".ipynb" end
  local f = io.open(name, "w")
  f:write('{"cells":[],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}')
  f:close()
  vim.cmd("edit " .. name)
end, { nargs = "?", desc = "Create a new Jupyter notebook" })

-- リモートファイルをローカルにダウンロード（scp コマンドをクリップボードにコピー）
vim.api.nvim_create_user_command("Download", function(opts)
  local file
  if opts.args ~= "" then
    file = vim.fn.fnamemodify(opts.args, ":p")
  else
    file = vim.fn.expand("%:p")
  end
  if file == "" then
    vim.notify("No file specified", vim.log.levels.WARN)
    return
  end
  local user = vim.env.USER or "user"
  -- 優先順位: $SCP_HOST (ユーザー設定) > hostname
  -- サーバの .bashrc 等で `export SCP_HOST=myserver` を設定すると
  -- ローカルの ~/.ssh/config の Host 名と一致させられる
  local host = vim.env.SCP_HOST or vim.fn.hostname()
  local scp_cmd = string.format("scp %s@%s:%s ~/Downloads/", user, host, vim.fn.shellescape(file))
  vim.fn.setreg("+", scp_cmd)
  vim.notify("Copied to clipboard:\n" .. scp_cmd, vim.log.levels.INFO)
end, { nargs = "?", complete = "file", desc = "Copy scp download command to clipboard" })

map("n", "<leader>dl", "<cmd>Download<cr>", { desc = "Download: copy scp command" })

-- ローカル(Mac)のクリップボード画像をリモートへアップロードする one-liner をコピー。
-- Download の逆向き: OSC52 でローカルのクリップボードに command を送り、Mac 側で実行する。
-- 手順: (1) Mac でスクショを撮る (Cmd+Shift+Ctrl+4 → クリップボードへ)
--       (2) nvim で :Upload → command がローカルのクリップボードにコピーされる
--       (3) Mac のシェルに貼って実行 → pngpaste で画像を temp に書き出し scp で送信
--       (4) 通知に出るリモートパスを Claude Code のプロンプトに貼る
-- 前提: Mac 側に pngpaste (`brew install pngpaste`)。
vim.api.nvim_create_user_command("Upload", function(opts)
  local user = vim.env.USER or "user"
  -- 優先順位: $SCP_HOST (ユーザー設定) > hostname （Download と揃える）
  local host = vim.env.SCP_HOST or vim.fn.hostname()
  -- リモート側の保存先ディレクトリ: 引数があればそれ、無ければ cwd
  local remote_dir = opts.args ~= "" and vim.fn.fnamemodify(opts.args, ":p") or vim.fn.getcwd()
  remote_dir = remote_dir:gsub("/$", "")
  local name = string.format("cc_%d.png", os.time())
  local remote_path = remote_dir .. "/" .. name
  local local_tmp = "/tmp/" .. name
  -- Mac 側で実行する one-liner: クリップボード画像を書き出し → scp → temp 削除
  local cmd = string.format(
    "pngpaste %s && scp %s %s@%s:%s && rm %s",
    local_tmp,
    local_tmp,
    user,
    host,
    vim.fn.shellescape(remote_path),
    local_tmp
  )
  vim.fn.setreg("+", cmd)
  vim.notify(
    "Copied upload command (run on your Mac):\n"
      .. cmd
      .. "\n\nThen reference in Claude Code:\n"
      .. remote_path,
    vim.log.levels.INFO
  )
end, { nargs = "?", complete = "dir", desc = "Copy scp upload command for clipboard screenshot" })

map("n", "<leader>du", "<cmd>Upload<cr>", { desc = "Upload: copy scp command (clipboard screenshot)" })

-- チートシート表示
vim.api.nvim_create_user_command("Cheatsheet", function()
  local lines = {
    "╔══════════════════════════════════════════════════════════════════╗",
    "║                     KEYBINDINGS CHEATSHEET                     ║",
    "╚══════════════════════════════════════════════════════════════════╝",
    "",
    "── 基本 ──────────────────────────────────────────────────────────",
    "  SPC w        Save                SPC q        Quit",
    "  SPC e        Explorer            SPC z        Zen Mode",
    "  SPC u        Undotree            -            Oil (parent dir)",
    "  SPC y / Y    Yazi (file/cwd)",
    "",
    "── 検索 (SPC f) ──────────────────────────────────────────────────",
    "  SPC ff       Find Files          SPC fg       Live Grep",
    "  SPC fb       Buffers             SPC fr       Recent Files",
    "  SPC fs       Document Symbols    SPC fw       Workspace Symbols",
    "  SPC fk       Keymaps             SPC fh       Help Tags",
    "  SPC fd       Diagnostics         SPC fy       Yank History",
    "  SPC fY       YAML Schema         SPC fe       Env vars",
    "",
    "── LSP (gd/gr/K) ────────────────────────────────────────────────",
    "  gd           Go to Definition    gr           References",
    "  gi           Implementation      K            Hover",
    "  SPC rn       Rename (preview)    SPC ca       Code Action",
    "  SPC D        Type Definition     SPC cn       Generate Docstring",
    "  [d / ]d      Prev/Next Diag      SPC dq       Diag to Loclist",
    "  SPC dl       Toggle lsp_lines",
    "",
    "── Git (SPC g) ───────────────────────────────────────────────────",
    "  SPC gg       LazyGit             SPC gc       Git Commits",
    "  SPC gb       Git Branches        SPC gB       Git Blame toggle",
    "  SPC gw       Git Worktrees       SPC gW       Create Worktree",
    "",
    "── Debug (SPC b) ────────────────────────────────────────────────",
    "  SPC bb       Breakpoint          SPC bB       Conditional BP",
    "  SPC bc       Continue            SPC bi       Step Into",
    "  SPC bo       Step Over           SPC bO       Step Out",
    "  SPC bu       Toggle Debug UI     SPC bt       Terminate",
    "  SPC br       REPL                SPC bl       Run Last",
    "  SPC bx       Clear All BPs",
    "",
    "── Test (SPC T) ──────────────────────────────────────────────────",
    "  SPC Tn       Run Nearest         SPC Tf       Run File",
    "  SPC Ts       Summary             SPC To       Output",
    "  SPC Td       Debug Test          SPC TS       Stop",
    "  ]T / [T      Next/Prev Failed",
    "",
    "── AI (SPC a) ────────────────────────────────────────────────────",
    "  SPC aa       Avante Ask          SPC ae       Avante Edit (V)",
    "  SPC at       Avante Toggle       SPC ac       Copilot Chat",
    "  SPC ax       Explain (V)         SPC ar       Review (V)",
    "  SPC aT       Generate Tests (V)  C-j          Accept Copilot",
    "",
    "── Notebook (SPC m) ─────────────────────────────────────────────",
    "  SPC mi       Init Kernel         SPC ma       Run All Cells",
    "  SPC mx       Run Cell            SPC mX       Run & Move",
    "  SPC ml       Run Line            SPC mr       Re-evaluate",
    "  SPC ms       Show Output         SPC mh       Hide Output",
    "  SPC md       Delete Cell         SPC my       Copy Image",
    "  SPC mk       Jupyter Attach      SPC mj       Jupynium Start",
    "  ]c / [c      Next/Prev Cell",
    "",
    "── Refactor (SPC r) ─────────────────────────────────────────────",
    "  SPC re       Extract Function(V) SPC rv       Extract Variable(V)",
    "  SPC ri       Inline Variable     SPC rf       Extract to File",
    "  SPC rr       Refactor Menu (V)",
    "",
    "── 編集 ──────────────────────────────────────────────────────────",
    "  s            Flash Jump          S            Flash Treesitter",
    "  C-d          Add Cursor (multi)  w/e/b        Spider motion",
    "  p → C-p/C-n  Yanky cycle         ih/ah        Cell text obj",
    "",
    "── Window / Buffer ──────────────────────────────────────────────",
    "  C-S-v        Paste (UTF-8 safe)  (terminal mode, avoids vterm bug)",
    "  C-h/j/k/l   Window Move (tmux)  M-h/j/k/l   Window Resize",
    "  S-h / S-l    Prev/Next Buffer    SPC bd       Delete Buffer",
    "  SPC by       Copy entire file",
    "  C-1~4        Harpoon Files       SPC ha       Harpoon Add",
    "",
    "── Search & Replace ─────────────────────────────────────────────",
    "  SPC sr       Spectre Open        SPC sw       Search Word",
    "",
    "── 言語別 ────────────────────────────────────────────────────────",
    "  SPC cgt      Go Test             SPC cgr      Go Run",
    "  SPC cga      Go Add Tags         SPC cge      Go if err",
    "  SPC cp       Color Picker        SPC ch       Color Highlight",
    "  SPC cv       CSV View Toggle     SPC cs       Code Snap (V)",
    "  SPC mp       Markdown Preview    SPC ls       Live Server",
    "  SPC od       Database UI         SPC or       Overseer Run",
    "",
    "── Fold ──────────────────────────────────────────────────────────",
    "  zR           Open All Folds      zM           Close All Folds",
    "  zK           Peek Fold",
    "",
    "── Other ─────────────────────────────────────────────────────────",
    "  SPC nm       Minimap Toggle      SPC tw       Twilight Toggle",
    "  SPC xx       Trouble Diagnostics SPC fml      Make it Rain",
    "  SPC dl       Download (scp)      :Download    Copy scp command",
    "  SPC du       Upload (scp)        :Upload      Clipboard screenshot",
    "  :Cheatsheet  This cheatsheet     :Nbnew       New Notebook",
    "",
    "  ※ SPC = Space  C- = Ctrl  M- = Alt  (V) = Visual mode",
  }
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.modifiable = false
  vim.bo.filetype = "markdown"
end, { desc = "Show keybindings cheatsheet" })

map("n", "<leader>?", "<cmd>Cheatsheet<cr>", { desc = "Cheatsheet" })

-- ヤンク時にハイライト
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})
