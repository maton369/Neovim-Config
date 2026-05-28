return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<leader>tt", function()
        local has_neotree = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
            has_neotree = true
            break
          end
        end
        if has_neotree then vim.cmd("Neotree close") end
        vim.cmd("ToggleTerm direction=horizontal")
        if has_neotree then vim.cmd("Neotree show") end
      end, desc = "Terminal (horizontal)" },
      { "<leader>tv", function()
        if vim.bo.filetype == "neo-tree" then vim.cmd("wincmd l") end
        local size = math.floor(vim.o.columns * 0.4)
        vim.cmd("ToggleTerm direction=vertical size=" .. size)
      end, desc = "Terminal (vertical)" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal (float)" },
    },
    opts = {
      shade_terminals = true,
      direction = "horizontal",
      size = function(term)
        if term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
        return math.floor(vim.o.lines * 0.2)
      end,
    },
  },
}
