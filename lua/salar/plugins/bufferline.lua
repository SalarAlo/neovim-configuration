return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		local bufferline = require("bufferline")

		bufferline.setup({
			options = {
				mode = "buffers",
				separator_style = "slant",
				always_show_bufferline = true,
				sort_by = "insert_after_current",
				show_buffer_close_icons = false,
				show_close_icon = false,
			},
		})

		-- VSCode-aligned palette
		local bg        = "#1b1b1b"
		local panel     = "#232323"
		local accent    = "#569cd6"
		local inactive  = "#808080"
		local sep       = "#2a2a2a"
		local active_fg = "#d4d4d4"

		-- Fill
		vim.api.nvim_set_hl(0, "BufferLineFill", { bg = bg })

		-- Background buffers
		vim.api.nvim_set_hl(0, "BufferLineBackground", { fg = inactive, bg = bg })
		vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { fg = inactive, bg = bg })

		-- Selected buffer
		vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { fg = active_fg, bg = panel, bold = true })
		vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { fg = accent, bg = panel })
		vim.api.nvim_set_hl(0, "BufferLineModifiedSelected", { fg = accent, bg = panel })

		-- Separators
		vim.api.nvim_set_hl(0, "BufferLineSeparator", { fg = bg, bg = bg })
		vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { fg = bg, bg = bg })
		vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { fg = bg, bg = panel })

		-- Modified (inactive)
		vim.api.nvim_set_hl(0, "BufferLineModified", { fg = sep, bg = bg })

		-- Keymaps
		vim.keymap.set("n", "<leader>h", ":BufferLineMovePrev<CR>", { silent = true, desc = "Move buffer left" })
		vim.keymap.set("n", "<leader>l", ":BufferLineMoveNext<CR>", { silent = true, desc = "Move buffer right" })
	end,
}
