vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 未使用プロバイダ無効化（起動時の実行ファイル検索を省く）
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- luarocks パス（image.nvim の magick ライブラリ用）
local home = vim.fn.expand("$HOME")
package.path = package.path .. ";" .. home .. "/.luarocks/share/lua/5.1/?.lua;" .. home .. "/.luarocks/share/lua/5.1/?/init.lua"
package.cpath = package.cpath .. ";" .. home .. "/.luarocks/lib/lua/5.1/?.so"

-- ~/.local/bin を PATH 先頭に prepend (nvim 起動元 shell context によらず
-- mason / claude / nvm-installed node や ~/.local/go を確実に発見させるため)。
-- 重複は除いて先頭に 1 つだけ配置。
local local_bin = home .. "/.local/bin"
local kept = {}
for entry in string.gmatch(vim.env.PATH or "", "[^:]+") do
  if entry ~= local_bin then
    table.insert(kept, entry)
  end
end
vim.env.PATH = local_bin .. ":" .. table.concat(kept, ":")

require("options")
require("keymaps")

-- Lazy.nvimのインストール（自動）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lua/plugins フォルダ内のファイルをすべて読み込む設定
require("lazy").setup("plugins", {
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- 起動時のレイアウト構築
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- headless (UI なし) 起動ではレイアウト構築は意味が無く、 むしろ
    -- terminal claude / belowright split が予期せぬエラーになるので skip。
    -- setup.sh の `nvim --headless +Lazy! sync +UpdateRemotePlugins +qa` 用。
    if #vim.api.nvim_list_uis() == 0 then return end

    local function try_layout(attempts)
      -- Lazy install UI など floating window が出ているうちはリトライ待機。
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative ~= "" then
          if attempts > 0 then
            vim.defer_fn(function() try_layout(attempts - 1) end, 500)
          end
          return
        end
      end
      -- 1. ターミナルバッファを全て削除
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buftype == "terminal" then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
      -- 2. ウィンドウを1つにリセット（確実に白紙から組み立てる）
      pcall(vim.cmd, "Neotree close")
      pcall(vim.cmd, "only")
      -- 3. 下にターミナル
      local height = math.floor(vim.o.lines * 0.2)
      vim.cmd("belowright split | terminal")
      vim.cmd("resize " .. height)
      vim.cmd("setlocal nobuflisted")
      vim.cmd("stopinsert")
      -- 4. エディタに戻る
      vim.cmd("wincmd k")
      -- 5. 右に Claude
      local width = math.floor(vim.o.columns * 0.4)
      vim.cmd("belowright vsplit | terminal claude")
      vim.cmd("vertical resize " .. width)
      vim.cmd("setlocal nobuflisted")
      vim.cmd("stopinsert")
      -- 6. エディタに戻る
      vim.cmd("wincmd h")
      -- 7. Neo-tree を開く
      pcall(vim.cmd, "Neotree show")
    end

    -- 最大 20 回 (10 秒) リトライ — Lazy UI が閉じた後にレイアウト構築
    vim.defer_fn(function() try_layout(20) end, 500)
  end,
})

-- Claude ターミナルにフォーカス (既存があれば)、 無ければ起動時と同じ右ペインで開く
vim.keymap.set("n", "<leader>tc", function()
  -- 1. 既存の claude ターミナルを探す → フォーカス
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):find("claude") then
      vim.api.nvim_set_current_win(win)
      vim.cmd("startinsert")
      return
    end
  end
  -- 2. 無ければ右側に vsplit + terminal claude (init.lua VimEnter と同じレイアウト)
  local width = math.floor(vim.o.columns * 0.4)
  vim.cmd("botright vsplit | terminal claude")
  vim.cmd("vertical resize " .. width)
  vim.cmd("setlocal nobuflisted")
end, { desc = "Focus/Open Claude terminal" })
