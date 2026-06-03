-- PDF viewer: convert pages to images via pdftoppm, display in markdown buffer
-- with image.nvim rendering.
-- Requires: poppler (pdftoppm) — installed via setup.sh §1.

local group = vim.api.nvim_create_augroup("PdfViewer", { clear = true })

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  pattern = "*.pdf",
  callback = function(ev)
    if not vim.fn.executable("pdftoppm") then
      vim.notify("pdftoppm not found. Install poppler.", vim.log.levels.ERROR)
      return
    end

    local pdf_path = vim.api.nvim_buf_get_name(ev.buf)
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

    -- Build markdown buffer with inline images
    local lines = {
      "# " .. vim.fn.fnamemodify(pdf_path, ":t"),
      "",
    }
    for i, page_path in ipairs(pages) do
      table.insert(lines, string.format("## Page %d / %d", i, #pages))
      table.insert(lines, "")
      table.insert(lines, string.format("![page %d](%s)", i, page_path))
      table.insert(lines, "")
    end

    -- Replace buffer content
    vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, lines)
    vim.bo[ev.buf].filetype = "markdown"
    vim.bo[ev.buf].buftype = "nofile"
    vim.bo[ev.buf].modifiable = false
    vim.bo[ev.buf].modified = false

    -- Clean up temp images when buffer is wiped
    vim.api.nvim_create_autocmd("BufWipeout", {
      buffer = ev.buf,
      callback = function()
        vim.fn.delete(tmp_dir, "rf")
      end,
    })
  end,
})

return {}
