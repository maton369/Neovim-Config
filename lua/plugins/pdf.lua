-- PDF viewer: convert pages to images via pdftoppm, display in buffer
-- with image.nvim rendering (API direct call — avoids treesitter/nofile issues).
-- Requires: poppler (pdftoppm) — installed via setup.sh §1.

local group = vim.api.nvim_create_augroup("PdfViewer", { clear = true })

-- BufReadCmd で PDF バイナリを読み込む前に横取りする。
-- BufReadPost だと先にバイナリが buffer に入り、Neo-tree 等から開くと
-- ゴミが表示されたり binary 判定で autocmd が飛ばないことがある。
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = group,
  pattern = "*.pdf",
  callback = function(ev)
    if not vim.fn.executable("pdftoppm") then
      vim.notify("pdftoppm not found. Install poppler.", vim.log.levels.ERROR)
      return
    end

    local pdf_path = vim.api.nvim_buf_get_name(ev.buf)
    if not vim.loop.fs_stat(pdf_path) then
      vim.notify("File not found: " .. pdf_path, vim.log.levels.ERROR)
      return
    end

    local tmp_dir = vim.fn.tempname() .. "_pdf"
    vim.fn.mkdir(tmp_dir, "p")

    -- Convert PDF pages to PNG images
    vim.fn.system(string.format(
      "pdftoppm -png -r 200 %s %s/page",
      vim.fn.shellescape(pdf_path),
      vim.fn.shellescape(tmp_dir)
    ))
    if vim.v.shell_error ~= 0 then
      vim.notify("pdftoppm failed", vim.log.levels.ERROR)
      return
    end

    -- Collect page images (sorted)
    local pages = {}
    for _, f in ipairs(vim.fn.globpath(tmp_dir, "page-*.png", false, true)) do
      table.insert(pages, f)
    end
    table.sort(pages)

    if #pages == 0 then
      vim.notify("No pages rendered", vim.log.levels.WARN)
      return
    end

    -- Build buffer with page headers (images are rendered by image.nvim API below)
    -- 各ページヘッダの行番号を記録して、その次の行に image.nvim で画像を配置する
    local lines = {
      "# " .. vim.fn.fnamemodify(pdf_path, ":t") .. "  (" .. #pages .. " pages)",
      "",
    }
    local image_positions = {} -- { { line = 0-indexed row, path = "..." }, ... }
    for i, page_path in ipairs(pages) do
      table.insert(lines, string.format("## Page %d / %d", i, #pages))
      table.insert(lines, "")
      -- 画像を配置する空行 (0-indexed)
      local img_line = #lines -- #lines は次に挿入される行の 0-indexed 位置
      table.insert(lines, "") -- 画像用の空行
      table.insert(lines, "")
      table.insert(image_positions, { line = img_line, path = page_path })
    end

    -- Set buffer content
    vim.bo[ev.buf].modifiable = true
    vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, lines)
    vim.bo[ev.buf].buftype = "nofile"
    vim.bo[ev.buf].modifiable = false
    vim.bo[ev.buf].modified = false

    -- image.nvim API で画像を直接配置（markdown 連携の treesitter 解析を迂回）
    vim.defer_fn(function()
      local ok, image_api = pcall(require, "image")
      if not ok then return end

      local win = vim.fn.bufwinid(ev.buf)
      if win == -1 then return end

      for _, pos in ipairs(image_positions) do
        local img_ok, img = pcall(image_api.from_file, pos.path, {
          buffer = ev.buf,
          window = win,
          with_virtual_padding = true,
          namespace = "pdf_viewer",
        })
        if img_ok and img then
          img.geometry = {
            x = 0,
            y = pos.line,
          }
          pcall(function() img:render() end)
        end
      end
    end, 200)

    -- Clean up temp images and image.nvim objects when buffer is wiped
    vim.api.nvim_create_autocmd("BufWipeout", {
      buffer = ev.buf,
      callback = function()
        local ok, image_api = pcall(require, "image")
        if ok then
          local imgs = image_api.get_images({ buffer = ev.buf })
          for _, img in ipairs(imgs) do
            img:clear()
          end
        end
        vim.fn.delete(tmp_dir, "rf")
      end,
    })
  end,
})

return {}
