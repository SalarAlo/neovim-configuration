-- ~/.config/nvim/lua/salar/tools/skeleton.lua
local M = {}

local function pascal_case_from_kebab(name)
	local parts = vim.split(name, "-", { plain = true })
	for i, p in ipairs(parts) do
		parts[i] = p:sub(1, 1):upper() .. p:sub(2)
	end
	return table.concat(parts, "")
end

local function project_namespace()
	local root = vim.fn.fnamemodify(vim.loop.cwd(), ":t")
	return pascal_case_from_kebab(root)
end

local function filename_stem()
	return vim.fn.expand("%:t:r")
end

local function include_path_for_header()
	local full = vim.fn.expand("%:p:h")
	local rel = vim.fn.fnamemodify(full, ":~:.")
	rel = rel:gsub("^%./", "")
	rel = rel:gsub("^src/", "")

	local cls = filename_stem()
	if rel == "" or rel == "." then
		return cls .. ".h"
	end
	return rel .. "/" .. cls .. ".h"
end

function M.insert()
	local ext = vim.fn.expand("%:e")
	local ns = project_namespace()
	local cls = filename_stem()

	local lines

	if ext == "h" then
		lines = {
			"#pragma once",
			"",
			"namespace " .. ns .. " {",
			"class " .. cls .. " {",
			"public:",
			"",
			"private:",
			"};",
			"",
			"}",
		}
	elseif ext == "cpp" then
		lines = {
			'#include "' .. include_path_for_header() .. '"',
			"",
			"namespace " .. ns .. " {",
			"",
			"}",
		}
	else
		vim.notify("Skel: unsupported file type", vim.log.levels.WARN)
		return
	end

	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

return M
