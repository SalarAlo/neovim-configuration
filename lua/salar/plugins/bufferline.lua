return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  opts = {
    options = {
      mode = "buffers", -- ✅ important: one tab, multiple buffers
      separator_style = "thin",
      always_show_bufferline = true,
    },
  },
}
