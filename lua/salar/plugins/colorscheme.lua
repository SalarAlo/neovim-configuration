
return {
  "Mofiqul/vscode.nvim",
  priority = 1000,
  config = function()
    require("vscode").setup({
      transparent = false,
      italic_comments = false,
      disable_nvimtree_bg = true,
      color_overrides = {
        vscBack = "#0a0a0a", -- true black background
      },
    })
    vim.cmd("colorscheme vscode")
  end
}

