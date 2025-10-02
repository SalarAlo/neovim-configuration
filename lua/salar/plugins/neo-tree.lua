return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- optional but nice
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true, -- close neo-tree if it's the last window
      filesystem = {
        follow_current_file = { enabled = true }, -- keep tree synced with current file
        hijack_netrw_behavior = "open_current",   -- hijack :Ex to open in current buffer
        use_libuv_file_watcher = true,            -- auto refresh
      },
      window = {
        position = "current", -- 👈 full-buffer mode
        mappings = {
          ["q"] = "close_window",
        },
      },
    })

    -- keymaps
    local keymap = vim.keymap
    keymap.set("n", "<C-n>", "<cmd>Neotree reveal current<CR>", { desc = "Reveal current file in explorer (fullscreen)" })
    keymap.set("n", "<leader>e", "<cmd>Neotree focus current<CR>", { desc = "Focus file explorer (fullscreen)" })
  end,
}
