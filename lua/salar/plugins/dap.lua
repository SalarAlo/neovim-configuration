return {
    "mfussenegger/nvim-dap",
    dependencies = { "nvim-neotest/nvim-nio" },

    config = function()
        local dap = require("dap")

        -----------------------------------------------------------------------
        -- LLDB DAP adapter (works perfectly on Fedora)
        -----------------------------------------------------------------------
        dap.adapters.lldb = {
            type = "executable",
            command = "/usr/bin/lldb-dap",
            name = "lldb"
        }

        -----------------------------------------------------------------------
        -- Debug configurations for C, C++, Rust
        -----------------------------------------------------------------------
        dap.configurations.cpp = {
            {
                name = "Launch C++ program",
                type = "lldb",
                request = "launch",
                program = function()
                    return vim.fn.input("Path to executable: ", "./", "file")
                end,
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
        	externalConsole = true,
		runInTerminal = true,
            }
        }

        dap.configurations.c = dap.configurations.cpp
        dap.configurations.rust = dap.configurations.cpp

        -----------------------------------------------------------------------
        -- Keybindings
        -----------------------------------------------------------------------
        vim.keymap.set("n", "<leader>dc", dap.continue,          { desc = "Continue" })
        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Breakpoint" })
        vim.keymap.set("n", "<leader>ds", dap.step_over,         { desc = "Step Over" })
        vim.keymap.set("n", "<leader>di", dap.step_into,         { desc = "Step Into" })
        vim.keymap.set("n", "<leader>do", dap.step_out,          { desc = "Step Out" })
    end,
}
