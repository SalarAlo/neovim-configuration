return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		heading = {
			enabled = true,
			sign = true,
			position = "inline",
			icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
		},
		code = {
			enabled = true,
			sign = false,
			width = "block",
			right_pad = 1,
		},
		bullet = {
			enabled = true,
			icons = { "•", "◦", "▪", "▫" },
		},
		checkbox = {
			enabled = true,
			unchecked = "󰄱 ",
			checked = "󰄵 ",
			custom = {
				todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
			},
		},
		quote = {
			enabled = true,
			icon = "▍",
		},
	},
}
