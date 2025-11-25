return {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },

    config = function()
        require("nvim-dap-virtual-text").setup({
            enabled = true,
            highlight_changed_variables = true,
            show_stop_reason = true,
        })
    end,
}
