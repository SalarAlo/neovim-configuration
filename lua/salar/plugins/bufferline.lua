return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		local bufferline = require("bufferline")

		local function hl(name)
			return vim.api.nvim_get_hl(0, { name = name, link = false })
		end

		local function fg_or_nil(group)
			local value = hl(group)
			return value and value.fg or nil
		end

		local function sync_fill_highlight()
			local tabline_fill = hl("TabLineFill")
			local tabline = hl("TabLine")
			local normal = hl("Normal")
			local fill_bg = (tabline_fill and tabline_fill.bg) or (tabline and tabline.bg) or (normal and normal.bg)

			if fill_bg then
				vim.api.nvim_set_hl(0, "BufferLineFill", { bg = fill_bg })
			end
		end

		local function sync_tab_highlights()
			local normal = hl("Normal")
			local tabline = hl("TabLine")
			local tabline_sel = hl("TabLineSel")

			if not normal then
				return
			end

			local base_bg = (tabline and tabline.bg) or normal.bg
			local base_fg = (tabline and tabline.fg) or normal.fg
			local selected_bg = (tabline_sel and tabline_sel.bg) or normal.bg or base_bg
			local selected_fg = (tabline_sel and tabline_sel.fg) or normal.fg

			vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = base_bg, fg = base_fg })
			vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = base_bg, fg = base_fg })
			vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { bg = selected_bg, fg = selected_fg, bold = true })
			vim.api.nvim_set_hl(0, "BufferLineDuplicate", { bg = base_bg, fg = base_fg })
			vim.api.nvim_set_hl(0, "BufferLineDuplicateVisible", { bg = base_bg, fg = base_fg })
			vim.api.nvim_set_hl(0, "BufferLineDuplicateSelected", { bg = selected_bg, fg = selected_fg, bold = true })
			vim.api.nvim_set_hl(0, "BufferLineModified", { bg = base_bg, fg = fg_or_nil("DiagnosticWarn") or base_fg })
			vim.api.nvim_set_hl(0, "BufferLineModifiedVisible", { bg = base_bg, fg = fg_or_nil("DiagnosticWarn") or base_fg })
			vim.api.nvim_set_hl(0, "BufferLineModifiedSelected", { bg = selected_bg, fg = fg_or_nil("DiagnosticWarn") or selected_fg })
			vim.api.nvim_set_hl(0, "BufferLineSeparator", { bg = base_bg, fg = base_bg })
			vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { bg = base_bg, fg = base_bg })
			vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { bg = selected_bg, fg = selected_bg })
			vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { bg = selected_bg, fg = fg_or_nil("Special") or selected_fg })
		end

		local options = {
			options = {
				mode = "buffers",
				separator_style = "thin",
				always_show_bufferline = true,
				sort_by = "insert_after_current",
				show_buffer_close_icons = false,
				show_close_icon = false,
			},
		}

		bufferline.setup(options)
		sync_fill_highlight()
		sync_tab_highlights()

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("SalarBufferlineThemeSync", { clear = true }),
			callback = function()
				bufferline.setup(options)
				sync_fill_highlight()
				sync_tab_highlights()
			end,
		})

		-- Keymaps
		vim.keymap.set("n", "<leader>h", ":BufferLineMovePrev<CR>", { silent = true, desc = "Move buffer left" })
		vim.keymap.set("n", "<leader>l", ":BufferLineMoveNext<CR>", { silent = true, desc = "Move buffer right" })
	end,
}
