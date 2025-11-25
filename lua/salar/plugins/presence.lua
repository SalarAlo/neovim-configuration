return {
    "andweeb/presence.nvim",
    event = "VeryLazy",
    config = function()
        require("presence").setup({
            auto_update         = true,
            neovim_image_text   = "Neovim",
            main_image          = "neovim",
            log_level           = nil,
            debounce_timeout    = 10,
            enable_line_number  = false,
            blacklist           = {},
            buttons             = true,
            show_time           = true,
        })
    end,
}
