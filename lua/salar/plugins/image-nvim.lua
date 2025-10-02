return {
  "3rd/image.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("image").setup({
      backend = "kitty", -- or "ueberzug" if not on Kitty/WezTerm
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
        },
        neorg = { enabled = true },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = 50,
      max_height_window_percentage = 50,
    })
  end,
}
