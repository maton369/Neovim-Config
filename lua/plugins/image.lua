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
      -- scale_factor は画像をセル換算サイズに変換するときの倍率。 デフォルト 1.0 だと
      -- matplotlib 標準 figsize (= 600x300 px ≈ 75 col × 30 行) はウィンドウより小さく
      -- 表示される。 3.0 を入れて scale 後のサイズが必ずウィンドウより大きくなるよう
      -- にし、 後続の max_*_window_percentage = 100 で window 一杯にクランプさせる。
      -- renderer.lua の adjust_to_aspect_ratio がアスペクト比を保持するので、
      -- 縦長/横長画像でも歪まず VSCode notebook の inline 表示と同程度の大きさになる。
      scale_factor = 3.0,
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

      -- ローカル PC 側で tmux を使い、 サーバには tmux が無いケース用の hack:
      -- image.nvim は $TMUX env var を「サーバ側で」 見て tmux 判定するため、
      -- サーバに tmux が無いと is_tmux=false になり、 kitty graphics を生の APC
      -- (`\e_G...\e\\`) のまま送出する。 これは手元 PC の tmux に届くと
      -- (たとえ allow-passthrough on でも) DCS ラップされていないため破棄される。
      -- is_tmux=true を強制すると image.nvim は `\ePtmux;...\e\\` で DCS ラップして
      -- 送出し、 手元 tmux が剥がして Ghostty に渡してくれる。
      -- 副作用: tmux ペイン位置取得 cmd が失敗するが silent fallback で 0,0 になる
      -- ので画像座標は問題なし。
      if vim.env.SSH_CLIENT or vim.env.SSH_TTY then
        for _, modname in ipairs({ "image/utils/tmux", "image.utils.tmux" }) do
          local ok, tmux = pcall(require, modname)
          if ok and type(tmux) == "table" then
            tmux.is_tmux = true
            tmux.has_passthrough = true
          end
        end
      end

      require("image").setup(opts)

      -- molten-nvim → image.nvim の橋渡しモジュール (load_image_nvim) の image_size()
      -- は「画像の自然サイズ (画像 px ÷ セル px)」 のみ返し、 image.nvim の
      -- state.options.scale_factor を無視する。 結果 molten が作る float window が
      -- 自然サイズ通りに小さくなり、 image.nvim 側で scale_factor を上げても効かない。
      -- ここで image_size を倍率付きでラップして molten に大きい float を作らせる。
      -- 倍率は opts.scale_factor と一致させる (両者で揃わないと float サイズと
      -- 画像描画サイズがズレる)。
      local sf = opts.scale_factor or 1.0
      if sf > 1.0 then
        local mol_ok, mol = pcall(require, "load_image_nvim")
        if mol_ok and mol.image_api and not mol._scale_factor_patched then
          local orig_image_size = mol.image_api.image_size
          mol.image_api.image_size = function(id)
            local size = orig_image_size(id)
            return {
              width = math.ceil((size.width or 0) * sf),
              height = math.ceil((size.height or 0) * sf),
            }
          end
          mol._scale_factor_patched = true
        end
      end
    end,
  },
}
