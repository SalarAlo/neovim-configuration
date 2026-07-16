return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = true,
	event = { "BufReadPre *.md", "BufNewFile *.md" },
	cmd = {
		"ObsidianBacklinks",
		"ObsidianDailies",
		"ObsidianExtractNote",
		"ObsidianFollowLink",
		"ObsidianLink",
		"ObsidianLinkNew",
		"ObsidianLinks",
		"ObsidianNew",
		"ObsidianNewFromTemplate",
		"ObsidianOpen",
		"ObsidianPasteImg",
		"ObsidianQuickSwitch",
		"ObsidianRename",
		"ObsidianSearch",
		"ObsidianTags",
		"ObsidianTemplate",
		"ObsidianToday",
		"ObsidianToggleCheckbox",
		"ObsidianTomorrow",
		"ObsidianTOC",
		"ObsidianYesterday",
	},
	keys = {
		{ "<leader>ob", "<cmd>ObsidianBacklinks<CR>", desc = "Obsidian backlinks" },
		{ "<leader>od", "<cmd>ObsidianToday<CR>", desc = "Obsidian daily note" },
		{ "<leader>ol", "<cmd>ObsidianLinks<CR>", desc = "Obsidian note links" },
		{ "<leader>oo", "<cmd>ObsidianOpen<CR>", desc = "Open in Obsidian" },
		{ "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", desc = "Obsidian quick switch" },
		{ "<leader>os", "<cmd>ObsidianSearch<CR>", desc = "Search Obsidian notes" },
		{ "<leader>ot", "<cmd>ObsidianTemplate<CR>", desc = "Insert Obsidian template" },
		{ "<leader>oT", "<cmd>ObsidianTOC<CR>", desc = "Obsidian table of contents" },
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"hrsh7th/nvim-cmp",
	},
	init = function()
		local group = vim.api.nvim_create_augroup("salar-obsidian-markdown", { clear = true })

		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			pattern = "markdown",
			callback = function(args)
				if vim.bo[args.buf].buftype ~= "" then
					return
				end

				require("salar.core.obsidian").setup_markdown_buffer(args.buf)
			end,
		})
	end,
	opts = function()
		return require("salar.core.obsidian").opts()
	end,
	config = function(_, opts)
		require("obsidian").setup(opts)
		require("salar.core.obsidian").patch_template_substitutions()
	end,
}
