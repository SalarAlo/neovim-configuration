return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  opts = {
    options = {
      mode = "buffers",
      separator_style = "thin",
      always_show_bufferline = true,
      sort_by = "insert_after_current",
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)

    -- Dark black background
    local bg = "#0a0a0a"
    -- Bright bluish accent for active items
    local accent = "#569CD6"
    -- Medium gray for separators and inactive tabs
    local sep = "#2d2d2d"
    -- Lighter gray for visible but not distracting inactive text
    local inactive_fg = "#808080"
    -- White text for selected buffer
    local active_fg = "#ffffff"

    -- Backgrounds
    vim.api.nvim_set_hl(0, "BufferLineFill", { bg = bg })
    vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = bg, fg = inactive_fg })

    -- Separators
    vim.api.nvim_set_hl(0, "BufferLineSeparator", { fg = sep, bg = bg })
    vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { fg = sep, bg = bg })
    vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { fg = accent, bg = bg })

    -- Active tab
    vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { fg = active_fg, bg = bg, bold = true })
    vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { fg = accent, bg = bg })
    vim.api.nvim_set_hl(0, "BufferLineModifiedSelected", { fg = accent, bg = bg })

    -- Inactive tabs
    vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { fg = inactive_fg, bg = bg })
    vim.api.nvim_set_hl(0, "BufferLineModified", { fg = sep, bg = bg })

    -- Move buffer shortcuts
    vim.keymap.set("n", "<leader>h", ":BufferLineMovePrev<CR>", { silent = true, desc = "Move buffer left" })
    vim.keymap.set("n", "<leader>l", ":BufferLineMoveNext<CR>", { silent = true, desc = "Move buffer right" })
  end,
}
