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
  },
}
