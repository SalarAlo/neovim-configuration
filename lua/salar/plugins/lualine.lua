return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		local lazy_status = require("lazy.status") -- to configure lazy pending updates count

		local colors = {
			bg     = "#1b1b1b",
			panel  = "#232323",
			subtle = "#2a2a2a",
			fg     = "#d4d4d4",
			gray   = "#808080",

			blue   = "#569cd6",
			green  = "#608b4e",
			purple = "#c586c0",
			yellow = "#dcdcaa",
			red    = "#f44747",
		}

		local my_lualine_theme = {
			normal = {
				a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
				b = { bg = colors.panel, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.gray },
			},
			insert = {
				a = { bg = colors.green, fg = colors.bg, gui = "bold" },
				b = { bg = colors.panel, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.gray },
			},
			visual = {
				a = { bg = colors.purple, fg = colors.bg, gui = "bold" },
				b = { bg = colors.panel, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.gray },
			},
			replace = {
				a = { bg = colors.red, fg = colors.bg, gui = "bold" },
				b = { bg = colors.panel, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.gray },
			},
			command = {
				a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
				b = { bg = colors.panel, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.gray },
			},
			inactive = {
				a = { bg = colors.bg, fg = colors.gray },
				b = { bg = colors.bg, fg = colors.gray },
				c = { bg = colors.bg, fg = colors.gray },
			},
		}

		-- configure lualine with modified theme
		lualine.setup({
			options = {
				theme = my_lualine_theme,
			},
			sections = {
				lualine_x = {
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
						color = { fg = colors.yellow }, -- subtle highlight for updates
					},
					{ "encoding" },
					{ "fileformat" },
					{ "filetype" },
				},
			},
		})
	end,
}
