return {
	"rcarriga/nvim-notify",
	lazy = false, -- must load early
	opts = {
		stages = "fade_in_slide_out",
		timeout = 3000,
		max_height = function()
			return math.floor(vim.o.lines * 0.75)
		end,
		max_width = function()
			return math.floor(vim.o.columns * 0.75)
		end,
		render = "wrapped-compact",
		background_colour = "#000000",
	},
	config = function(_, opts)
		local notify = require("notify")
		notify.setup(opts)

		-- 🔴 THIS IS THE IMPORTANT PART
		vim.notify = notify
	end,
}
