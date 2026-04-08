local M = {}

local HEADER_EXTENSIONS = { "h", "hpp", "hh", "hxx" }
local ROOT_MARKERS = { "compile_commands.json", "compile_flags.txt", "CMakeLists.txt", ".git" }

local function normalize(path)
	return (path or ""):gsub("\\", "/")
end

local function is_file(path)
	local stat = path and vim.uv.fs_stat(path)
	return stat and stat.type == "file" or false
end

local function path_join(...)
	return normalize(table.concat({ ... }, "/")):gsub("//+", "/")
end

local function dedupe(list)
	local seen = {}
	local result = {}

	for _, item in ipairs(list) do
		if item and item ~= "" and not seen[item] then
			seen[item] = true
			result[#result + 1] = item
		end
	end

	return result
end

local function pascal_case_from_snake(name)
	local parts = vim.split(name, "_", { plain = true })
	for i, p in ipairs(parts) do
		parts[i] = p:sub(1, 1):upper() .. p:sub(2)
	end
	return table.concat(parts, "")
end

local function project_root(path)
	return vim.fs.root(path or vim.api.nvim_buf_get_name(0), ROOT_MARKERS) or vim.loop.cwd()
end

local function project_namespace()
	local root = vim.fn.fnamemodify(project_root(), ":t")
	return pascal_case_from_snake(root)
end

local function filename_stem()
	return vim.fn.expand("%:t:r")
end

local function current_file_path()
	return normalize(vim.fn.expand("%:p"))
end

local function strip_known_prefix(relpath)
	if not relpath then
		return nil
	end

	local stripped = relpath
	for _, prefix in ipairs({ "src/", "source/", "sources/", "lib/" }) do
		stripped = stripped:gsub("^" .. vim.pesc(prefix), "")
	end

	return stripped
end

local function candidate_header_paths(source_path, root)
	local source_dir = vim.fn.fnamemodify(source_path, ":h")
	local stem = vim.fn.fnamemodify(source_path, ":t:r")
	local rel_source = vim.fs.relpath(root, source_path)
	local stripped = strip_known_prefix(rel_source and normalize(vim.fn.fnamemodify(rel_source, ":h")) or "")
	local candidates = {}

	for _, ext in ipairs(HEADER_EXTENSIONS) do
		candidates[#candidates + 1] = path_join(source_dir, stem .. "." .. ext)

		if stripped and stripped ~= "." and stripped ~= "" then
			candidates[#candidates + 1] = path_join(root, "include", stripped, stem .. "." .. ext)
			candidates[#candidates + 1] = path_join(root, "src", stripped, stem .. "." .. ext)
			candidates[#candidates + 1] = path_join(root, stripped, stem .. "." .. ext)
		else
			candidates[#candidates + 1] = path_join(root, "include", stem .. "." .. ext)
			candidates[#candidates + 1] = path_join(root, "src", stem .. "." .. ext)
			candidates[#candidates + 1] = path_join(root, stem .. "." .. ext)
		end
	end

	return dedupe(candidates)
end

local function collect_header_matches(source_path, root)
	local matches = {}

	for _, candidate in ipairs(candidate_header_paths(source_path, root)) do
		if is_file(candidate) then
			matches[#matches + 1] = candidate
		end
	end

	if #matches > 0 then
		return dedupe(matches)
	end

	local stem = vim.fn.fnamemodify(source_path, ":t:r")
	for _, ext in ipairs(HEADER_EXTENSIONS) do
		local basename = stem .. "." .. ext
		local found = vim.fs.find(basename, {
			path = root,
			type = "file",
			limit = 50,
		})

		for _, file in ipairs(found) do
			matches[#matches + 1] = normalize(file)
		end
	end

	return dedupe(matches)
end

local function score_header_candidate(source_path, header_path, root)
	local score = 0
	local source_dir = normalize(vim.fn.fnamemodify(source_path, ":h"))
	local header_dir = normalize(vim.fn.fnamemodify(header_path, ":h"))

	if source_dir == header_dir then
		score = score + 100
	end

	local rel = normalize(vim.fs.relpath(root, header_path) or "")
	if rel:match("^include/") then
		score = score + 80
	end
	if rel:match("^src/") then
		score = score + 40
	end

	local rel_source = normalize(vim.fs.relpath(root, source_path) or "")
	local stripped_source = strip_known_prefix(rel_source)
	local stripped_header = strip_known_prefix(rel)
	if stripped_source and stripped_header then
		local source_without_ext = stripped_source:gsub("%.[^.]+$", "")
		local header_without_ext = stripped_header:gsub("%.[^.]+$", "")
		if source_without_ext == header_without_ext then
			score = score + 120
		end
	end

	score = score - #rel
	return score
end

local function matching_header_for_source(source_path)
	local root = project_root(source_path)
	local matches = collect_header_matches(source_path, root)
	if #matches == 0 then
		return nil, root
	end

	table.sort(matches, function(a, b)
		return score_header_candidate(source_path, a, root) > score_header_candidate(source_path, b, root)
	end)

	return matches[1], root
end

local function find_compile_commands(root)
	local direct = path_join(root, "compile_commands.json")
	if is_file(direct) then
		return direct
	end

	local nested = vim.fs.find("compile_commands.json", {
		path = root,
		type = "file",
		limit = 10,
	})

	if #nested > 0 then
		table.sort(nested, function(a, b)
			return #a < #b
		end)
		return normalize(nested[1])
	end
end

local function decode_json_file(path)
	if not is_file(path) then
		return nil
	end

	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return nil
	end

	local ok_json, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok_json then
		return nil
	end

	return decoded
end

local function split_shell_words(command)
	local words = {}
	local current = {}
	local quote
	local escaped = false

	for i = 1, #command do
		local ch = command:sub(i, i)
		if escaped then
			current[#current + 1] = ch
			escaped = false
		elseif ch == "\\" then
			escaped = true
		elseif quote then
			if ch == quote then
				quote = nil
			else
				current[#current + 1] = ch
			end
		elseif ch == "'" or ch == '"' then
			quote = ch
		elseif ch:match("%s") then
			if #current > 0 then
				words[#words + 1] = table.concat(current)
				current = {}
			end
		else
			current[#current + 1] = ch
		end
	end

	if #current > 0 then
		words[#words + 1] = table.concat(current)
	end

	return words
end

local function extract_include_dirs(args, directory)
	local include_dirs = {}
	local i = 1

	while i <= #args do
		local arg = args[i]
		local value

		if arg == "-I" or arg == "-iquote" or arg == "-isystem" then
			value = args[i + 1]
			i = i + 1
		elseif arg:match("^%-I.+") then
			value = arg:sub(3)
		elseif arg:match("^%-iquote.+") then
			value = arg:sub(8)
		elseif arg:match("^%-isystem.+") then
			value = arg:sub(9)
		end

		if value and value ~= "" then
			if not value:match("^/") then
				value = path_join(directory, value)
			end
			include_dirs[#include_dirs + 1] = normalize(vim.fn.fnamemodify(value, ":p"))
		end

		i = i + 1
	end

	return dedupe(include_dirs)
end

local function compile_entries_for_file(compile_commands_path, target_file)
	local db = decode_json_file(compile_commands_path)
	if type(db) ~= "table" then
		return {}
	end

	local target_abs = normalize(vim.fn.fnamemodify(target_file, ":p"))
	local target_dir = normalize(vim.fn.fnamemodify(target_abs, ":h"))
	local matches = {}

	for _, entry in ipairs(db) do
		local file = entry.file and normalize(vim.fn.fnamemodify(entry.file, ":p")) or nil
		if file == target_abs then
			matches[#matches + 1] = entry
		elseif file and normalize(vim.fn.fnamemodify(file, ":h")) == target_dir then
			matches[#matches + 1] = entry
		end
	end

	return matches
end

local function include_roots_from_compile_commands(root, source_path)
	local compile_commands_path = find_compile_commands(root)
	if not compile_commands_path then
		return {}
	end

	local include_roots = {}
	for _, entry in ipairs(compile_entries_for_file(compile_commands_path, source_path)) do
		local args = entry.arguments or (entry.command and split_shell_words(entry.command)) or {}
		local directory = normalize(entry.directory or root)
		for _, include_dir in ipairs(extract_include_dirs(args, directory)) do
			include_roots[#include_roots + 1] = include_dir
		end
	end

	return dedupe(include_roots)
end

local function include_candidates(source_path, header_path, root)
	local source_dir = normalize(vim.fn.fnamemodify(source_path, ":h"))
	local compile_roots = include_roots_from_compile_commands(root, source_path)
	local conventional_roots = {
		path_join(root, "include"),
		path_join(root, "src"),
		path_join(root, "source"),
		root,
	}

	local candidates = {}

	if source_dir == normalize(vim.fn.fnamemodify(header_path, ":h")) then
		candidates[#candidates + 1] = {
			path = vim.fn.fnamemodify(header_path, ":t"),
			priority = 300,
		}
	end

	for _, include_root in ipairs(compile_roots) do
		local rel = vim.fs.relpath(include_root, header_path)
		if rel then
			candidates[#candidates + 1] = {
				path = normalize(rel),
				priority = 220,
			}
		end
	end

	for _, include_root in ipairs(conventional_roots) do
		local rel = vim.fs.relpath(include_root, header_path)
		if rel then
			candidates[#candidates + 1] = {
				path = normalize(rel),
				priority = 120,
			}
		end
	end

	local rel_from_root = vim.fs.relpath(root, header_path)
	if rel_from_root then
		local normalized = normalize(rel_from_root)
		candidates[#candidates + 1] = {
			path = normalized,
			priority = 50,
		}

		local stripped = strip_known_prefix(normalized)
		if stripped ~= normalized then
			candidates[#candidates + 1] = {
				path = stripped,
				priority = 40,
			}
		end
	end

	local best_by_path = {}
	for _, candidate in ipairs(candidates) do
		local current = best_by_path[candidate.path]
		if not current or candidate.priority > current.priority then
			best_by_path[candidate.path] = candidate
		end
	end

	local unique = vim.tbl_values(best_by_path)
	table.sort(unique, function(a, b)
		if a.priority == b.priority then
			return #a.path < #b.path
		end
		return a.priority > b.priority
	end)

	return unique
end

local function include_path_for_source(source_path)
	local header_path, root = matching_header_for_source(source_path)
	if not header_path then
		return filename_stem() .. ".h"
	end

	local candidates = include_candidates(source_path, header_path, root)
	if #candidates > 0 then
		return candidates[1].path
	end

	return vim.fn.fnamemodify(header_path, ":t")
end

local function is_header_extension(ext)
	return vim.tbl_contains(HEADER_EXTENSIONS, ext)
end

function M.insert()
	local ext = vim.fn.expand("%:e")
	local ns = project_namespace()
	local cls = filename_stem()
	local file_path = current_file_path()
	local lines

	if is_header_extension(ext) then
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
	elseif ext == "cpp" or ext == "cc" or ext == "cxx" then
		lines = {
			'#include "' .. include_path_for_source(file_path) .. '"',
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
