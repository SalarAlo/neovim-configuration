local M = {}
local colorschemes = require("salar.core.colorschemes")

local config = {
	themes = colorschemes.names(),
	default = "koda",
	state_file = vim.fn.stdpath("state") .. "/theme.txt",
}

local function index_of(name)
	for i, theme in ipairs(config.themes) do
		if theme == name then
			return i
		end
	end

	return nil
end

local function persist(name)
	local dir = vim.fn.fnamemodify(config.state_file, ":h")
	vim.fn.mkdir(dir, "p")
	vim.fn.writefile({ name }, config.state_file)
end

local function read_persisted()
	if vim.fn.filereadable(config.state_file) == 0 then
		return nil
	end

	local lines = vim.fn.readfile(config.state_file)
	return lines[1]
end

local function apply(name, opts)
	opts = opts or {}

	if not index_of(name) then
		vim.notify(("Unknown theme: %s"):format(name), vim.log.levels.ERROR)
		return false
	end

	local ok, err = pcall(vim.cmd.colorscheme, name)
	if not ok then
		vim.notify(("Failed to load theme %s: %s"):format(name, err), vim.log.levels.ERROR)
		return false
	end

	if opts.persist ~= false then
		persist(name)
	end

	if opts.notify then
		vim.notify(("Theme: %s"):format(name), vim.log.levels.INFO)
	end

	return true
end

function M.names()
	return vim.deepcopy(config.themes)
end

function M.current()
	return vim.g.colors_name
end

function M.set(name, opts)
	return apply(name, opts)
end

function M.cycle(step)
	step = step or 1

	local current = M.current()
	local current_index = index_of(current) or index_of(config.default) or 1
	local next_index = ((current_index - 1 + step) % #config.themes) + 1

	return apply(config.themes[next_index], { notify = true })
end

function M.select()
	vim.ui.select(config.themes, {
		prompt = "Select theme",
		format_item = function(item)
			if item == M.current() then
				return item .. " (current)"
			end

			return item
		end,
	}, function(choice)
		if choice then
			apply(choice, { notify = true })
		end
	end)
end

function M.load()
	local name = read_persisted() or config.default

	if apply(name, { persist = false }) then
		return
	end

	if name ~= config.default then
		apply(config.default)
	end
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	vim.api.nvim_create_user_command("Theme", function(command_opts)
		if command_opts.args == "" then
			M.select()
			return
		end

		M.set(command_opts.args, { notify = true })
	end, {
		nargs = "?",
		complete = function(arg_lead)
			return vim.tbl_filter(function(theme)
				return theme:find(arg_lead, 1, true) == 1
			end, config.themes)
		end,
		desc = "Select or set the active theme",
	})

	vim.api.nvim_create_user_command("ThemeNext", function()
		M.cycle(1)
	end, { desc = "Cycle to the next theme" })

	vim.api.nvim_create_user_command("ThemePrev", function()
		M.cycle(-1)
	end, { desc = "Cycle to the previous theme" })

	M.load()
end

return M
