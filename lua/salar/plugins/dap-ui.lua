return {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap" },

    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        -----------------------------------------------------------------------
        -- UI SETUP
        -----------------------------------------------------------------------

        dapui.setup({
            layouts = {
                {
                    elements = {
                        "scopes",
                        "breakpoints",
                        "stacks",
                        "watches",
                    },
                    size = 40,
                    position = "left",
                },
            },
            controls = { enabled = false },
        })

        -----------------------------------------------------------------------
        -- AUTO OPEN / CLOSE UI
        -----------------------------------------------------------------------

        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end

        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end

        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        -----------------------------------------------------------------------
        -- KEYMAPS
        -----------------------------------------------------------------------

        vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI toggle" })

        -- Watches API
        vim.keymap.set("n", "<leader>dw", function()
            local expr = vim.fn.input("Watch expression: ")
            if expr ~= "" then
                dapui.elements.watches.add(expr)
            end
        end, { desc = "DapUI add watch" })

        vim.keymap.set("n", "<leader>dW", function()
            dapui.elements.watches.remove()
        end, { desc = "DapUI remove watch" })

        vim.keymap.set("n", "<leader>dC", function()
            dapui.elements.watches.clear()
        end, { desc = "DapUI clear watches" })
    end,
}
