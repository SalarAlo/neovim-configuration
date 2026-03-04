local M = {}

M.items = {
	{
		repo = "oskarnurm/koda.nvim",
		schemes = { "koda", "koda-dark", "koda-light", "koda-glade", "koda-moss" },
	},
	{
		repo = "andreypopp/vim-colors-plain",
		schemes = { "plain", "plain-cterm" },
	},
	{
		repo = "folke/tokyonight.nvim",
		schemes = {
			"tokyonight",
			"tokyonight-night",
			"tokyonight-storm",
			"tokyonight-day",
			"tokyonight-moon",
		},
	},
	{
		repo = "catppuccin/nvim",
		name = "catppuccin",
		schemes = {
			"catppuccin",
			"catppuccin-latte",
			"catppuccin-frappe",
			"catppuccin-macchiato",
			"catppuccin-mocha",
		},
	},
	{
		repo = "rebelot/kanagawa.nvim",
		schemes = { "kanagawa", "kanagawa-wave", "kanagawa-dragon", "kanagawa-lotus" },
	},
	{
		repo = "rose-pine/neovim",
		name = "rose-pine",
		schemes = { "rose-pine", "rose-pine-main", "rose-pine-moon", "rose-pine-dawn" },
	},
	{
		repo = "ellisonleao/gruvbox.nvim",
		schemes = { "gruvbox" },
	},
	{
		repo = "shaunsingh/nord.nvim",
		schemes = { "nord" },
	},
	{
		repo = "navarasu/onedark.nvim",
		schemes = { "onedark" },
	},
	{
		repo = "EdenEast/nightfox.nvim",
		schemes = { "nightfox", "dayfox", "dawnfox", "duskfox", "nordfox", "terafox", "carbonfox" },
	},
	{
		repo = "sainnhe/everforest",
		schemes = { "everforest" },
	},
	{
		repo = "sainnhe/sonokai",
		schemes = { "sonokai" },
	},
	{
		repo = "sainnhe/edge",
		schemes = { "edge" },
	},
	{
		repo = "marko-cerovac/material.nvim",
		schemes = {
			"material",
			"material-darker",
			"material-deep-ocean",
			"material-lighter",
			"material-oceanic",
			"material-palenight",
		},
	},
	{
		repo = "Mofiqul/dracula.nvim",
		schemes = { "dracula", "dracula-soft" },
	},
	{
		repo = "projekt0n/github-nvim-theme",
		schemes = {
			"github_dark",
			"github_dark_default",
			"github_dark_dimmed",
			"github_dark_high_contrast",
			"github_light",
			"github_light_default",
			"github_light_high_contrast",
		},
	},
	{
		repo = "nyoom-engineering/oxocarbon.nvim",
		schemes = { "oxocarbon" },
	},
	{
		repo = "RRethy/base16-nvim",
		schemes = { "base16-default-dark", "base16-default-light" },
	},
}

function M.names()
	local names = {}

	for _, item in ipairs(M.items) do
		vim.list_extend(names, item.schemes)
	end

	return names
end

return M
