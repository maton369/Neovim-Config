return {
  {
    "3rd/image.nvim",
    ft = { "markdown", "norg", "python" },
    opts = {
      backend = "kitty",
      integrations = {
        markdown = { enabled = true },
      },
      max_width_window_percentage = 100,
      max_height_window_percentage = 100,
      window_overlap_clear_enabled = true,
    },
    config = function(_, opts)
      -- image.nvim utils/term.lua の get_tty() は io.popen("tty 2>/dev/null") で
      -- TTY パスを取ろうとするが、 stdin が pipe / 一部の embed context だと
      -- "tty: 端末ではありません" (ja_JP) や "not a tty" (en_US) が stdout に
      -- 残ってそれが TTY パス扱いされる。 すると kitty backend の helpers.lua が
      -- io.open(その文字列, "w") して、 graphics escape を **ファイル**に書き込んで
      -- しまう (CWD に "tty ではありません" 等の謎ファイルが生まれる)。
      -- backend/kitty/init.lua は require 時に editor_tty を 1 回だけ読むので、
      -- setup() より前に get_tty を上書きして $SSH_TTY を優先させる。
      --
      -- 重要: Lua の require は "image.utils.term" (ドット) と "image/utils/term"
      -- (スラッシュ) を別キャッシュエントリとして扱う (= 別テーブルが返る)。
      -- image.nvim 内部はスラッシュ表記を使うのでそちらをパッチする必要がある。
      local patched_get_tty
      patched_get_tty = function(original_get_tty)
        return function()
          local env_tty = vim.env.SSH_TTY or vim.env.TTY
          if env_tty and env_tty:match("^/dev/") then return env_tty end
          local cmd_tty = original_get_tty()
          if cmd_tty and cmd_tty:match("^/dev/") then return cmd_tty end
          return nil
        end
      end
      for _, modname in ipairs({ "image/utils/term", "image.utils.term" }) do
        local ok, term = pcall(require, modname)
        if ok and type(term) == "table" and type(term.get_tty) == "function" then
          term.get_tty = patched_get_tty(term.get_tty)
        end
      end
      require("image").setup(opts)
    end,
  },
}
