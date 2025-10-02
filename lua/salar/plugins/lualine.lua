return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status") -- to configure lazy pending updates count

    local colors = {
      black0 = "#000000", -- pure black
      black1 = "#111111", -- slightly lighter
      black2 = "#1a1a1a",
      black3 = "#222222",
      black4 = "#2a2a2a",
      gray   = "#aaaaaa",
      fg     = "#cccccc",
    }

    local my_lualine_theme = {
      normal = {
        a = { bg = colors.black1, fg = colors.fg, gui = "bold" },
        b = { bg = colors.black2, fg = colors.gray },
        c = { bg = colors.black3, fg = colors.gray },
      },
      insert = {
        a = { bg = colors.black2, fg = colors.fg, gui = "bold" },
        b = { bg = colors.black3, fg = colors.gray },
        c = { bg = colors.black4, fg = colors.gray },
      },
      visual = {
        a = { bg = colors.black3, fg = colors.fg, gui = "bold" },
        b = { bg = colors.black2, fg = colors.gray },
        c = { bg = colors.black4, fg = colors.gray },
      },
      command = {
        a = { bg = colors.black4, fg = colors.fg, gui = "bold" },
        b = { bg = colors.black2, fg = colors.gray },
        c = { bg = colors.black3, fg = colors.gray },
      },
      replace = {
        a = { bg = colors.black0, fg = colors.fg, gui = "bold" },
        b = { bg = colors.black2, fg = colors.gray },
        c = { bg = colors.black3, fg = colors.gray },
      },
      inactive = {
        a = { bg = colors.black0, fg = colors.gray, gui = "bold" },
        b = { bg = colors.black0, fg = colors.gray },
        c = { bg = colors.black0, fg = colors.gray },
      },
    }

    -- configure lualine with modified theme
    lualine.setup({
      options = {
        theme = my_lualine_theme,
      },
      sections = {
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = "#888888" }, -- subtle highlight for updates
          },
          { "encoding" },
          { "fileformat" },
          { "filetype" },
        },
      },
    })
  end,
}
