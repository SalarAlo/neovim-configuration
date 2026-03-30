return {
	"SalarAlo/rndr.nvim",
	build = "make",
	config = function()
		require("rndr").setup({
			preview = {
				auto_open = true,
				events = { "BufReadPost" },
			},
			window = {
				termguicolors = true,
				size = {
					width_offset = 0,
					height_offset = 0,
				},
			},
			renderer = {
				supersample = 2,
				background = "0d0f14",
			},
			controls = {
				rotate_step = 15,
				keymaps = {
					close = "q",
					rerender = "R",
					reset_view = "0",
					rotate_left = "h",
					rotate_right = "l",
					rotate_up = "k",
					rotate_down = "j",
				},
			},
		})
	end,
}
