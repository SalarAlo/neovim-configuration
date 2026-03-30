local M = {}

local function is_cpp_path(path)
	return path:match("%.h$") or path:match("%.hh$") or path:match("%.hpp$") or path:match("%.hxx$")
		or path:match("%.inl$") or path:match("%.ipp$") or path:match("%.tpp$")
		or path:match("%.c$") or path:match("%.cc$") or path:match("%.cpp$") or path:match("%.cxx$")
end

local function normalize(path)
	return path:gsub("\\", "/")
end

local function split_path(path)
	local parts = {}
	for p in path:gmatch("[^/]+") do
		parts[#parts + 1] = p
	end
	return parts
end

local function join_path(parts, from_idx, to_idx)
	return table.concat(vim.list_slice(parts, from_idx, to_idx), "/")
end

local function find_project_root(path)
	return vim.fs.root(path, { ".git", "compile_commands.json", "compile_flags.txt" }) or vim.loop.cwd()
end

local function file_count_by_name(root, filename)
	local files = vim.fs.find(function(name)
		return name == filename
	end, {
		path = root,
		type = "file",
		limit = 2,
	})
	return #files
end

local function compute_replacements(old_abs, new_abs)
	local root = find_project_root(old_abs)
	local old_rel = vim.fs.relpath(root, old_abs)
	local new_rel = vim.fs.relpath(root, new_abs)

	if not old_rel or not new_rel then
		return {}, root
	end

	old_rel = normalize(old_rel)
	new_rel = normalize(new_rel)

	local old_parts = split_path(old_rel)
	local new_parts = split_path(new_rel)
	local replacements = {}

	local max_suffix = math.min(#old_parts, #new_parts)
	for n = max_suffix, 2, -1 do
		local old_suffix = join_path(old_parts, #old_parts - n + 1, #old_parts)
		local new_suffix = join_path(new_parts, #new_parts - n + 1, #new_parts)
		replacements[#replacements + 1] = {
			old = old_suffix,
			new = new_suffix,
			priority = n,
		}
	end

	-- Basename-only replacement can be ambiguous, so only allow it if unique.
	local old_base = old_parts[#old_parts]
	local new_base = new_parts[#new_parts]
	if old_base ~= new_base and file_count_by_name(root, old_base) == 1 then
		replacements[#replacements + 1] = {
			old = old_base,
			new = new_base,
			priority = 1,
		}
	end

	table.sort(replacements, function(a, b)
		return a.priority > b.priority
	end)

	return replacements, root
end

local function rewrite_include_line(line, replacements)
	local prefix, include_path, suffix = line:match('^(%s*#%s*include%s*[<"])([^>"]+)([>"].*)$')
	if not include_path then
		return line, false
	end

	local normalized = normalize(include_path)
	for _, item in ipairs(replacements) do
		if normalized == item.old then
			return prefix .. item.new .. suffix, true
		end

		if normalized:sub(-(item.old:len() + 1)) == "/" .. item.old then
			local rewritten = normalized:sub(1, #normalized - #item.old) .. item.new
			return prefix .. rewritten .. suffix, true
		end
	end

	return line, false
end

local function rewrite_includes_in_project(old_abs, new_abs)
	local replacements, root = compute_replacements(old_abs, new_abs)
	if #replacements == 0 then
		return 0
	end

	local changed_files = 0
	local files = vim.fs.find(function()
		return true
	end, {
		path = root,
		type = "file",
	})

	for _, file in ipairs(files) do
		if is_cpp_path(file) then
			local lines = vim.fn.readfile(file)
			local changed = false
			for i, line in ipairs(lines) do
				local rewritten, line_changed = rewrite_include_line(line, replacements)
				if line_changed then
					lines[i] = rewritten
					changed = true
				end
			end

			if changed then
				vim.fn.writefile(lines, file)
				changed_files = changed_files + 1
			end
		end
	end

	return changed_files
end

local function apply_lsp_file_rename(old_abs, new_abs)
	local files = {
		{
			oldUri = vim.uri_from_fname(old_abs),
			newUri = vim.uri_from_fname(new_abs),
		},
	}

	local any_applied = false
	for _, client in ipairs(vim.lsp.get_clients()) do
		if client.supports_method and client:supports_method("workspace/willRenameFiles") then
			local result = client:request_sync("workspace/willRenameFiles", { files = files }, 2000)
			local edit = result and result.result
			if edit then
				vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding or "utf-16")
				any_applied = true
			end
		end
	end

	return any_applied
end

function M.on_node_renamed(data)
	local old_abs = data and data.old_name
	local new_abs = data and data.new_name

	if not old_abs or not new_abs then
		return
	end

	old_abs = normalize(old_abs)
	new_abs = normalize(new_abs)

	if not is_cpp_path(old_abs) or not is_cpp_path(new_abs) then
		return
	end

	if apply_lsp_file_rename(old_abs, new_abs) then
		vim.notify("Updated include references via LSP file-rename edits", vim.log.levels.INFO)
		return
	end

	local changed = rewrite_includes_in_project(old_abs, new_abs)
	if changed > 0 then
		vim.notify(("Updated include references in %d file(s)"):format(changed), vim.log.levels.INFO)
	end
end

function M.setup(api)
	if not api or not api.events or not api.events.subscribe or not api.events.Event then
		return
	end

	api.events.subscribe(api.events.Event.NodeRenamed, M.on_node_renamed)
end

return M
