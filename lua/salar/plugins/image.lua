return {
	"3rd/image.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		backend = "kitty",
		integrations = {
			markdown = {
				enabled = true,
				only_render_image_at_cursor = false,
			},
		},
		editor_only_render_when_focused = true,
		window_overlap_clear_enabled = true,
	},
}
