return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local rndr = require("rndr")

		telescope.setup({
			defaults = {
				buffer_previewer_maker = rndr.telescope_buffer_previewer_maker,
				file_ignore_patterns = {
					"node_modules",
					"vendor",
					"build",
					"%.git",
				},
				path_display = { "smart" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<C-t>"] = require("trouble.sources.telescope").open,
					},
				},
			},
		})

		telescope.load_extension("fzf")

		local keymap = vim.keymap
		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find recent files" })
		keymap.set("n", "<leader>fw", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", {
			desc = "Find string under cursor in cwd",
		})
	end,
}
