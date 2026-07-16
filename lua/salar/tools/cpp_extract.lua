local M = {}

local HEADER_PATTERNS = { "%.h$", "%.hh$", "%.hpp$", "%.hxx$" }
local STRIP_DECL_KEYWORDS = { "static", "inline", "virtual", "friend", "explicit", "override" }

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "CppExtractDefinitions" })
end

local function is_header(path)
	for _, pattern in ipairs(HEADER_PATTERNS) do
		if path:match(pattern) then return true end
	end

	return false
end

local function trim(text)
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_lines(text)
	return vim.split(text, "\n", { plain = true })
end

local function get_node_text(node, bufnr)
	return vim.treesitter.get_node_text(node, bufnr)
end

local function get_field_child(node, field)
	if not node then return nil end

	if node.child_by_field_name then
		return node:child_by_field_name(field)
	end

	if node.field then
		local children = node:field(field)
		if children and children[1] then return children[1] end
	end

	return nil
end

local function get_text_range(bufnr, start_row, start_col, end_row, end_col)
	return table.concat(vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {}), "\n")
end

local function normalize_ws(text)
	return trim((text:gsub("%s+", " ")))
end

local function node_contains(node, row, col)
	local sr, sc, er, ec = node:range()
	if row < sr or row > er then return false end
	if row == sr and col < sc then return false end
	if row == er and col >= ec then return false end
	return true
end

local function iter_named_children(node)
	local index = 0
	local count = node:named_child_count()

	return function()
		if index >= count then return nil end
		local child = node:named_child(index)
		index = index + 1
		return child
	end
end

local function find_enclosing_class(node, row, col)
	local best = nil

	local function walk(current)
		if not node_contains(current, row, col) then return end

		local kind = current:type()
		if kind == "class_specifier" or kind == "struct_specifier" then
			best = current
		end

		for child in iter_named_children(current) do
			walk(child)
		end
	end

	walk(node)
	return best
end

local function find_enclosing_function(node, row, col)
	local best = nil

	local function walk(current)
		if not node_contains(current, row, col) then return end

		if current:type() == "function_definition" then
			best = current
		end

		for child in iter_named_children(current) do
			walk(child)
		end
	end

	walk(node)
	return best
end

local function find_first_named_child(node, wanted_type)
	for child in iter_named_children(node) do
		if child:type() == wanted_type then return child end
	end

	return nil
end

local function find_direct_named_child(node, wanted_type)
	if not node then return nil end

	for child in iter_named_children(node) do
		if child:type() == wanted_type then return child end
	end

	return nil
end

local function has_template_ancestor(node)
	local current = node and node:parent() or nil

	while current do
		if current:type() == "template_declaration" then return true end
		current = current:parent()
	end

	return false
end

local function get_class_name(class_node, bufnr)
	local name_node = get_field_child(class_node, "name")
	if name_node then return trim(get_node_text(name_node, bufnr)) end

	for child in iter_named_children(class_node) do
		local kind = child:type()
		if kind == "type_identifier" or kind == "identifier" then
			return trim(get_node_text(child, bufnr))
		end
	end

	return nil
end

local function parse_namespace_name(ns_node, bufnr)
	local name_node = get_field_child(ns_node, "name")
	if name_node then
		local text = trim(get_node_text(name_node, bufnr))
		if text ~= "" then return text end
	end

	local text = get_node_text(ns_node, bufnr)
	local header = text:match("^[^{]+") or text
	return trim((header:match("namespace%s+([%w_:]+)") or ""))
end

local function get_namespace_parts(node, bufnr)
	local parts = {}
	local current = node and node:parent() or nil

	while current do
		if current:type() == "namespace_definition" then
			local name = parse_namespace_name(current, bufnr)
			if name ~= "" then
				local namespace_parts = {}
				for _, part in ipairs(vim.split(name, "::", { plain = true })) do
					if part ~= "" then table.insert(namespace_parts, part) end
				end

				for index = #namespace_parts, 1, -1 do
					table.insert(parts, 1, namespace_parts[index])
				end
			end
		end

		current = current:parent()
	end

	return parts
end

local function find_class_body(class_node)
	return get_field_child(class_node, "body") or find_first_named_child(class_node, "field_declaration_list")
end

local function find_containing_class(node)
	local current = node and node:parent() or nil

	while current do
		local kind = current:type()
		if kind == "class_specifier" or kind == "struct_specifier" then return current end
		current = current:parent()
	end

	return nil
end

local function resolve_function_name_node(declarator)
	if not declarator then return nil end

	local kind = declarator:type()
	if kind == "qualified_identifier" then
		return get_field_child(declarator, "name") or declarator
	end

	if kind == "identifier" or kind == "field_identifier" or kind == "operator_name" or kind == "destructor_name" then
		return declarator
	end

	local name_node = get_field_child(declarator, "name")
	if name_node then return name_node end

	local inner = get_field_child(declarator, "declarator")
	if inner then
		return resolve_function_name_node(inner)
	end

	if declarator:named_child_count() == 1 then
		return resolve_function_name_node(declarator:named_child(0))
	end

	return declarator
end

local function strip_decl_only_keywords(text)
	local updated = text

	for _, keyword in ipairs(STRIP_DECL_KEYWORDS) do
		updated = updated:gsub("(%f[%a_])" .. keyword .. "(%f[^%a_])%s*", "")
	end

	return updated
end

local function build_definition_prefix(bufnr, function_node, scope_prefix)
	local body_node = get_field_child(function_node, "body")
	local declarator = get_field_child(function_node, "declarator")
	if not body_node or not declarator then return nil, "Unsupported function declarator" end

	local name_node = resolve_function_name_node(declarator)
	if not name_node then return nil, "Unsupported function name" end

	local fsr, fsc = function_node:range()
	local bsr, bsc = body_node:range()
	local nsr, nsc, ner, nec = name_node:range()
	local prefix = get_text_range(bufnr, fsr, fsc, bsr, bsc)

	local before_name = get_text_range(bufnr, fsr, fsc, nsr, nsc)
	local after_name = get_text_range(bufnr, ner, nec, bsr, bsc)
	local scoped_name = scope_prefix .. get_node_text(name_node, bufnr)

	local rewritten = before_name .. scoped_name .. after_name
	return trim(strip_decl_only_keywords(rewritten)), nil
end

local function build_declaration(bufnr, function_node)
	local body_node = get_field_child(function_node, "body")
	if not body_node then return nil end

	local fsr, fsc = function_node:range()
	local end_row, end_col = body_node:range()
	local initializer_list = find_direct_named_child(function_node, "field_initializer_list")
	if initializer_list then
		end_row, end_col = initializer_list:range()
	end

	local prefix = trim(get_text_range(bufnr, fsr, fsc, end_row, end_col))
	return prefix .. ";"
end

local function build_free_function_declaration(bufnr, function_node)
	local declaration = build_declaration(bufnr, function_node)
	if not declaration then return nil end

	return trim(strip_decl_only_keywords(declaration))
end

local function collect_inline_member_functions(class_node)
	local body = find_class_body(class_node)
	if not body then return {} end

	local functions = {}

	local function walk(node)
		for child in iter_named_children(node) do
			local kind = child:type()

			if kind == "class_specifier" or kind == "struct_specifier" then
				-- Ignore nested types while processing the current class.
			elseif kind == "function_definition" then
				if not has_template_ancestor(child) then
					table.insert(functions, child)
				end
			else
				walk(child)
			end
		end
	end

	walk(body)
	table.sort(functions, function(a, b)
		local ar = { a:range() }
		local br = { b:range() }
		if ar[1] == br[1] then return ar[2] < br[2] end
		return ar[1] < br[1]
	end)

	return functions
end

local function build_definition_text(bufnr, function_node, scope_prefix)
	local prefix, err = build_definition_prefix(bufnr, function_node, scope_prefix)
	if not prefix then return nil, err end

	local body_node = get_field_child(function_node, "body")
	local body = get_node_text(body_node, bufnr)
	return prefix .. " " .. body
end

local function wrap_in_namespaces(namespace_parts, definitions)
	if vim.tbl_isempty(definitions) then return {} end

	if vim.tbl_isempty(namespace_parts) then
		local lines = {}
		for index, definition in ipairs(definitions) do
			if index > 1 then table.insert(lines, "") end
			vim.list_extend(lines, split_lines(definition))
		end
		return lines
	end

	local lines = { "namespace " .. table.concat(namespace_parts, "::") .. " {", "" }

	for index, definition in ipairs(definitions) do
		if index > 1 then table.insert(lines, "") end
		vim.list_extend(lines, split_lines(definition))
	end

	table.insert(lines, "")
	table.insert(lines, "}")
	return lines
end

local function flatten_namespace_stack(stack)
	local parts = {}

	for _, entry in ipairs(stack) do
		vim.list_extend(parts, entry.parts)
	end

	return parts
end

local function namespace_parts_equal(left, right)
	if #left ~= #right then return false end

	for index = 1, #left do
		if left[index] ~= right[index] then return false end
	end

	return true
end

local function parse_namespace_decl_parts(line)
	local name = line:match("^%s*namespace%s+([%w_:]+)%s*{")
	if not name or name == "" then return nil end

	local parts = {}
	for _, part in ipairs(vim.split(name, "::", { plain = true })) do
		if part ~= "" then table.insert(parts, part) end
	end

	if vim.tbl_isempty(parts) then return nil end
	return parts
end

local function find_namespace_insert_index(lines, namespace_parts)
	if vim.tbl_isempty(namespace_parts) then return nil end

	local brace_depth = 0
	local namespace_stack = {}
	local target_entry = nil

	for index, line in ipairs(lines) do
		local decl_parts = parse_namespace_decl_parts(line)
		if decl_parts then
			local entry = {
				parts = decl_parts,
				close_depth = brace_depth,
			}
			table.insert(namespace_stack, entry)
			if namespace_parts_equal(flatten_namespace_stack(namespace_stack), namespace_parts) then
				target_entry = entry
			end
		end

		local opens = select(2, line:gsub("{", ""))
		local closes = select(2, line:gsub("}", ""))
		brace_depth = brace_depth + opens - closes

		while #namespace_stack > 0 and brace_depth == namespace_stack[#namespace_stack].close_depth do
			local closing_entry = table.remove(namespace_stack)
			if closing_entry == target_entry then
				return index
			end
		end
	end

	return nil
end

local function insert_lines_at(lines, insert_at, new_lines)
	for offset = #new_lines, 1, -1 do
		table.insert(lines, insert_at, new_lines[offset])
	end
end

local function replace_function_with_declaration(bufnr, function_node, declaration)
	local sr, sc, er, ec = function_node:range()
	vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, split_lines(declaration))
end

local function header_include_line(header_path)
	return string.format('#include "%s"', vim.fn.fnamemodify(header_path, ":t"))
end

local function ensure_cpp_include(cpp_path, include_line)
	local lines = {}
	if vim.fn.filereadable(cpp_path) == 1 then
		lines = vim.fn.readfile(cpp_path)
	end

	for _, line in ipairs(lines) do
		if trim(line) == include_line then return lines, false end
	end

	if #lines == 0 then
		return { include_line, "" }, true
	end

	table.insert(lines, 1, "")
	table.insert(lines, 1, include_line)
	return lines, true
end

local function append_missing_definitions(cpp_path, include_line, definition_entries, namespace_parts)
	local lines, changed = ensure_cpp_include(cpp_path, include_line)
	local existing = table.concat(lines, "\n")
	local normalized_existing = normalize_ws(existing)
	local appended = 0
	local new_definitions = {}

	for _, entry in ipairs(definition_entries) do
		local has_local = normalized_existing:find(entry.local_signature, 1, true) ~= nil
		local has_full = normalized_existing:find(entry.full_signature, 1, true) ~= nil
		if not has_local and not has_full then
			table.insert(new_definitions, entry.definition)
			normalized_existing = normalized_existing .. " " .. normalize_ws(entry.definition)
			appended = appended + 1
		end
	end

	if appended > 0 then
		local insert_at = find_namespace_insert_index(lines, namespace_parts)
		if insert_at then
			local payload = wrap_in_namespaces({}, new_definitions)
			local chunk = {}
			local previous_line = lines[insert_at - 1]
			if previous_line and trim(previous_line) ~= "" then table.insert(chunk, "") end
			vim.list_extend(chunk, payload)
			if #chunk > 0 and trim(chunk[#chunk]) ~= "" then table.insert(chunk, "") end
			insert_lines_at(lines, insert_at, chunk)
		else
			if #lines > 0 and lines[#lines] ~= "" then table.insert(lines, "") end
			vim.list_extend(lines, wrap_in_namespaces(namespace_parts, new_definitions))
		end
		changed = true
	end

	while #lines > 0 and lines[#lines] == "" do
		table.remove(lines)
	end

	if changed then
		vim.fn.writefile(lines, cpp_path)
	end

	return appended
end

local function header_to_cpp_path(path)
	return vim.fn.fnamemodify(path, ":r") .. ".cpp"
end

local function get_cpp_parser_tree(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "cpp")
	if not ok or not parser then
		notify("C++ Treesitter parser is not available", vim.log.levels.ERROR)
		return nil
	end

	local tree = parser:parse()[1]
	if not tree then
		notify("Unable to parse the current buffer", vim.log.levels.ERROR)
		return nil
	end

	return tree
end

local function build_definition_entry(bufnr, function_node, declaration_builder, scope_prefix, full_scope_prefix)
	local declaration = declaration_builder(bufnr, function_node)
	local definition, err = build_definition_text(bufnr, function_node, scope_prefix)
	if not declaration or not definition then return nil, err end

	local local_signature = normalize_ws(definition:match("^(.-)%s*%b{}") or definition)
	local full_definition = build_definition_text(bufnr, function_node, full_scope_prefix)
	local full_signature = normalize_ws((full_definition or definition):match("^(.-)%s*%b{}") or (full_definition or definition))

	return {
		definition = definition,
		declaration = declaration,
		local_signature = local_signature,
		full_signature = full_signature,
		node = function_node,
	}, nil
end

local function extract_class_functions(functions, class_node, bufnr, path)
	local class_name = get_class_name(class_node, bufnr)
	if not class_name then
		notify("Unable to resolve class name", vim.log.levels.ERROR)
		return
	end

	if vim.tbl_isempty(functions) then
		notify("No non-template inline member definitions found in the current class", vim.log.levels.INFO)
		return
	end

	local namespace_parts = get_namespace_parts(class_node, bufnr)
	local class_scope_prefix = class_name .. "::"
	local full_scope_parts = vim.list_extend(vim.deepcopy(namespace_parts), { class_name })
	local full_scope_prefix = table.concat(full_scope_parts, "::") .. "::"
	local definition_entries = {}
	local replacements = {}

	for _, function_node in ipairs(functions) do
		local entry, err = build_definition_entry(bufnr, function_node, build_declaration, class_scope_prefix, full_scope_prefix)
		if entry then
			table.insert(definition_entries, entry)
			table.insert(replacements, { node = entry.node, declaration = entry.declaration })
		elseif err then
			notify(err, vim.log.levels.WARN)
		end
	end

	if vim.tbl_isempty(replacements) then
		notify("No supported inline member definitions found", vim.log.levels.WARN)
		return
	end

	for index = #replacements, 1, -1 do
		local item = replacements[index]
		replace_function_with_declaration(bufnr, item.node, item.declaration)
	end

	vim.cmd("silent write")

	local cpp_path = header_to_cpp_path(path)
	local include_line = header_include_line(path)
	local appended = append_missing_definitions(cpp_path, include_line, definition_entries, namespace_parts)

	notify(string.format(
		"Extracted %d definition(s) from %s and appended %d new definition(s) to %s",
		#replacements,
		class_name,
		appended,
		vim.fn.fnamemodify(cpp_path, ":t")
	))
end

local function extract_namespace_function(function_node, bufnr, path)
	local namespace_parts = get_namespace_parts(function_node, bufnr)
	local full_scope_prefix = ""
	if not vim.tbl_isempty(namespace_parts) then
		full_scope_prefix = table.concat(namespace_parts, "::") .. "::"
	end

	local entry, err = build_definition_entry(
		bufnr,
		function_node,
		build_free_function_declaration,
		"",
		full_scope_prefix
	)
	if not entry then
		notify(err or "Unsupported function definition", vim.log.levels.WARN)
		return
	end

	replace_function_with_declaration(bufnr, entry.node, entry.declaration)
	vim.cmd("silent write")

	local cpp_path = header_to_cpp_path(path)
	local include_line = header_include_line(path)
	local appended = append_missing_definitions(cpp_path, include_line, { entry }, namespace_parts)
	local name_node = resolve_function_name_node(get_field_child(function_node, "declarator"))
	local function_name = name_node and trim(get_node_text(name_node, bufnr)) or ""

	notify(string.format(
		"Extracted %s and appended %d new definition(s) to %s",
		function_name ~= "" and function_name or "function definition",
		appended,
		vim.fn.fnamemodify(cpp_path, ":t")
	))
end

function M.extract_current_class()
	local bufnr = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(bufnr)

	if path == "" or not is_header(path) then
		notify("Run this command from a C++ header buffer", vim.log.levels.ERROR)
		return
	end

	local tree = get_cpp_parser_tree(bufnr)
	if not tree then return end
	local root = tree:root()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local col = cursor[2]
	local class_node = find_enclosing_class(root, row, col)

	if not class_node then
		notify("Place the cursor inside the target class", vim.log.levels.ERROR)
		return
	end

	local functions = collect_inline_member_functions(class_node)
	extract_class_functions(functions, class_node, bufnr, path)
end

function M.extract_current_function()
	local bufnr = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(bufnr)

	if path == "" or not is_header(path) then
		notify("Run this command from a C++ header buffer", vim.log.levels.ERROR)
		return
	end

	local tree = get_cpp_parser_tree(bufnr)
	if not tree then return end
	local root = tree:root()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local col = cursor[2]
	local function_node = find_enclosing_function(root, row, col)
	if not function_node then
		notify("Place the cursor inside the function definition to extract", vim.log.levels.ERROR)
		return
	end

	if has_template_ancestor(function_node) then
		notify("Template function definitions should stay in the header", vim.log.levels.WARN)
		return
	end

	local class_node = find_containing_class(function_node)
	if class_node then
		extract_class_functions({ function_node }, class_node, bufnr, path)
		return
	end

	extract_namespace_function(function_node, bufnr, path)
end

function M.setup()
	vim.api.nvim_create_user_command("CppExtractDefinitions", function()
		M.extract_current_class()
	end, {
		desc = "Extract inline C++ member definitions from the current class into a .cpp file",
	})

	vim.api.nvim_create_user_command("CppExtractFunctionDefinition", function()
		M.extract_current_function()
	end, {
		desc = "Extract the current C++ function definition into a .cpp file",
	})
end

return M
