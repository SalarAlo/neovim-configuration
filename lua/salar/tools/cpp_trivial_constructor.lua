local M = {}

local VALUE_PRIMITIVES = {
	bool = true,
	char = true,
	["char8_t"] = true,
	["char16_t"] = true,
	["char32_t"] = true,
	wchar_t = true,
	short = true,
	int = true,
	long = true,
	float = true,
	double = true,
	["signed"] = true,
	["unsigned"] = true,
	size_t = true,
	ptrdiff_t = true,
	["std::size_t"] = true,
	["std::ptrdiff_t"] = true,
}

local ACCESS_SPECIFIERS = {
	["public"] = true,
	["private"] = true,
	["protected"] = true,
}

local CPP_KEYWORDS = {}
for _, keyword in ipairs({
	"alignas",
	"alignof",
	"and_eq",
	"asm",
	"auto",
	"bitand",
	"bitor",
	"bool",
	"break",
	"case",
	"catch",
	"char",
	"char8_t",
	"char16_t",
	"char32_t",
	"class",
	"compl",
	"concept",
	"const",
	"consteval",
	"constexpr",
	"constinit",
	"const_cast",
	"continue",
	"co_await",
	"co_return",
	"co_yield",
	"decltype",
	"default",
	"delete",
	"do",
	"double",
	"dynamic_cast",
	"else",
	"enum",
	"explicit",
	"export",
	"extern",
	"false",
	"float",
	"for",
	"friend",
	"goto",
	"if",
	"inline",
	"int",
	"long",
	"mutable",
	"namespace",
	"new",
	"noexcept",
	"not",
	"not_eq",
	"nullptr",
	"operator",
	"or_eq",
	"private",
	"protected",
	"public",
	"register",
	"reinterpret_cast",
	"requires",
	"return",
	"short",
	"signed",
	"sizeof",
	"static",
	"static_assert",
	"static_cast",
	"struct",
	"switch",
	"template",
	"this",
	"thread_local",
	"throw",
	"true",
	"try",
	"typedef",
	"typeid",
	"typename",
	"union",
	"unsigned",
	"using",
	"virtual",
	"void",
	"volatile",
	"while",
	"xor_eq",
}) do
	CPP_KEYWORDS[keyword] = true
end

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "CppTrvCtr" })
end

local function trim(text)
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
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

local function find_first_named_child(node, wanted_type)
	for child in iter_named_children(node) do
		if child:type() == wanted_type then return child end
	end

	return nil
end

local function find_class_body(class_node)
	return get_field_child(class_node, "body") or find_first_named_child(class_node, "field_declaration_list")
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

local function class_kind(class_node)
	return class_node:type() == "struct_specifier" and "struct" or "class"
end

local function normalize_ws(text)
	return trim((text:gsub("%s+", " ")))
end

local function line_indent(line)
	return line:match("^%s*") or ""
end

local function direct_child_has_type(node, wanted_type)
	for child in iter_named_children(node) do
		if child:type() == wanted_type then return true end
	end
	return false
end

local function contains_type(node, wanted)
	if node:type() == wanted then return true end
	for child in iter_named_children(node) do
		if contains_type(child, wanted) then return true end
	end
	return false
end

local function has_function_typed_declarator(field)
	for child in iter_named_children(field) do
		if child:type() == "function_declarator" then
			local first = child:named_child(0)
			return first and first:type() ~= "field_identifier"
		end
	end

	return false
end

local function find_name_node(node)
	local field_name = get_field_child(node, "name")
	if field_name then return field_name end

	local kind = node:type()
	if kind == "field_identifier" or kind == "identifier" then return node end

	for child in iter_named_children(node) do
		local found = find_name_node(child)
		if found then return found end
	end

	return nil
end

local function is_static_field(bufnr, field)
	for child in iter_named_children(field) do
		if child:type() == "storage_class_specifier" and trim(get_node_text(child, bufnr)) == "static" then
			return true
		end
	end
	return false
end

local function strip_top_level_const(type_text)
	local updated = trim(type_text)
	updated = trim(updated:gsub("^const%f[%W]%s*", ""))
	updated = trim(updated:gsub("%s+const%s*$", ""))
	return updated
end

local function has_reference(type_text)
	return type_text:find("&", 1, true) ~= nil
end

local function has_rvalue_reference(type_text)
	return type_text:find("&&", 1, true) ~= nil
end

local function is_pointer_type(type_text)
	return type_text:find("*", 1, true) ~= nil
end

local function is_builtin_value_type(type_text)
	local no_cv = strip_top_level_const(type_text)
	no_cv = trim(no_cv:gsub("%f[%w_]volatile%f[%W]%s*", ""))
	no_cv = normalize_ws(no_cv)

	if VALUE_PRIMITIVES[no_cv] then return true end
	if no_cv:find("[<>&*:%[%]%(%){}]", 1) then return false end

	local saw_primitive = false
	for token in no_cv:gmatch("[%a_][%w_]*") do
		if not VALUE_PRIMITIVES[token] then return false end
		if token ~= "signed" and token ~= "unsigned" and token ~= "short" and token ~= "long" then
			saw_primitive = true
		end
	end

	return saw_primitive or no_cv:match("^(signed|unsigned|short|long)$") ~= nil
end

local function build_param_type(type_text)
	local raw = trim(type_text)
	local stripped = strip_top_level_const(raw)

	if has_rvalue_reference(raw) then
		return nil, "rvalue-reference members are unsupported"
	end

	if has_reference(raw) then
		return raw
	end

	if is_pointer_type(raw) then
		return trim(raw:gsub("%s+const%s*$", ""))
	end

	if is_builtin_value_type(stripped) then
		return stripped
	end

	return "const " .. stripped .. "&"
end

local function sanitize_param_name(name)
	local param = name
	param = param:gsub("^m_", "")
	param = param:gsub("^_", "")
	param = param:gsub("_$", "")

	if param == "" or not param:match("^[%a_][%w_]*$") or CPP_KEYWORDS[param] then
		param = name .. "_value"
	end

	if param == "" or not param:match("^[%a_][%w_]*$") or CPP_KEYWORDS[param] then
		param = "value"
	end

	return param
end

local function unique_param_name(base, used)
	local candidate = base
	local suffix = 2

	while used[candidate] or CPP_KEYWORDS[candidate] do
		candidate = base .. suffix
		suffix = suffix + 1
	end

	used[candidate] = true
	return candidate
end

local function collect_decl_names(field)
	local names = {}

	for child in iter_named_children(field) do
		local kind = child:type()
		if kind == "field_identifier" then
			table.insert(names, child)
		elseif kind:match("declarator$") then
			local name_node = find_name_node(child)
			if name_node then table.insert(names, name_node) end
		end
	end

	return names
end

local function member_type_for_name(bufnr, field, name_node, first_name_node)
	if first_name_node and first_name_node ~= name_node then
		return member_type_for_name(bufnr, field, first_name_node)
	end

	local fsr, fsc = field:range()
	local nsr, nsc = name_node:range()
	return trim(get_text_range(bufnr, fsr, fsc, nsr, nsc))
end

local function collect_members(bufnr, class_node)
	local body = find_class_body(class_node)
	if not body then return nil, "Cursor is not inside a C++ class definition" end

	if contains_type(body, "preproc_if")
		or contains_type(body, "preproc_ifdef")
		or contains_type(body, "preproc_ifndef")
		or contains_type(body, "preproc_else")
		or contains_type(body, "preproc_elif")
	then
		return nil, "conditional compilation inside the class body is unsupported"
	end

	local members = {}
	local used_params = {}

	for child in iter_named_children(body) do
		local kind = child:type()
		if kind == "class_specifier" or kind == "struct_specifier" then
			-- Nested classes are not members of the selected class for this command.
		elseif kind == "union_specifier" then
			return nil, "union members are unsupported"
		elseif kind == "field_declaration" then
			local field_text = normalize_ws(get_node_text(child, bufnr))
			if is_static_field(bufnr, child) then
				-- Static fields are not initialized by instance constructors.
			elseif contains_type(child, "union_specifier") then
				return nil, "union members are unsupported"
			elseif contains_type(child, "array_declarator") then
				return nil, "array members are unsupported: " .. field_text
			elseif contains_type(child, "bitfield_clause") then
				return nil, "bit-field members are unsupported: " .. field_text
			elseif has_function_typed_declarator(child) then
				return nil, "function-typed members are unsupported: " .. field_text
			elseif direct_child_has_type(child, "function_declarator") then
				-- Tree-sitter uses field_declaration for member function declarations.
			elseif direct_child_has_type(child, "ERROR") or contains_type(child, "ERROR") then
				return nil, "unsupported member declaration: " .. field_text
			else
				local name_nodes = collect_decl_names(child)
				if vim.tbl_isempty(name_nodes) then
					return nil, "member has no usable name: " .. field_text
				end

				for _, name_node in ipairs(name_nodes) do
					local name = trim(get_node_text(name_node, bufnr))
					local type_text = member_type_for_name(bufnr, child, name_node, name_nodes[1])
					type_text = trim(type_text:gsub("%f[%w_]mutable%f[%W]%s*", ""))

					if type_text == "" then
						return nil, "unable to determine member type: " .. field_text
					end

					local param_type, err = build_param_type(type_text)
					if not param_type then
						return nil, err .. ": " .. field_text
					end

					table.insert(members, {
						name = name,
						param_type = param_type,
						param_name = unique_param_name(sanitize_param_name(name), used_params),
					})
				end
			end
		end
	end

	return members, nil
end

local function find_function_name_node(declarator)
	if not declarator then return nil end

	local kind = declarator:type()
	if kind == "identifier" or kind == "field_identifier" then return declarator end

	local name_node = get_field_child(declarator, "name")
	if name_node then return name_node end

	for child in iter_named_children(declarator) do
		local found = find_function_name_node(child)
		if found then return found end
	end

	return nil
end

local function strip_param_name(param_text)
	local text = trim(param_text)
	text = text:gsub("%s*=%s*.+$", "")
	text = trim(text)

	local without_name = text:match("^(.-)%s+[%a_][%w_]*$")
	if without_name and without_name ~= "" then
		return trim(without_name)
	end

	without_name = text:match("^(.-)([%*&])%s*[%a_][%w_]*$")
	if without_name and without_name ~= "" then
		return trim(without_name)
	end

	return text
end

local function constructor_param_types(bufnr, function_node)
	local declarator = get_field_child(function_node, "declarator") or find_first_named_child(function_node, "function_declarator")
	local params = declarator and find_first_named_child(declarator, "parameter_list") or nil
	if not params then return {} end

	local types = {}
	for child in iter_named_children(params) do
		if child:type() == "parameter_declaration" or child:type() == "optional_parameter_declaration" then
			table.insert(types, normalize_ws(strip_param_name(get_node_text(child, bufnr))))
		end
	end

	return types
end

local function constructor_initializer_names(bufnr, function_node)
	local initializer_list = find_first_named_child(function_node, "field_initializer_list")
	if not initializer_list then return nil end

	local names = {}
	for child in iter_named_children(initializer_list) do
		if child:type() == "field_initializer" then
			local name_node = find_first_named_child(child, "field_identifier")
			if name_node then
				table.insert(names, trim(get_node_text(name_node, bufnr)))
			end
		end
	end

	return names
end

local function same_ordered_names(left, right)
	if not left or #left ~= #right then return false end

	for index, name in ipairs(left) do
		if name ~= right[index] then return false end
	end

	return true
end

local function is_constructor_node(bufnr, node, class_name)
	local kind = node:type()
	if kind ~= "declaration" and kind ~= "function_definition" then return false end

	local declarator = get_field_child(node, "declarator") or find_first_named_child(node, "function_declarator")
	local name_node = find_function_name_node(declarator)
	return name_node and trim(get_node_text(name_node, bufnr)) == class_name
end

local function existing_constructor_status(bufnr, class_node, class_name, generated_param_types, member_names)
	local body = find_class_body(class_node)
	if not body then return nil end

	for child in iter_named_children(body) do
		if is_constructor_node(bufnr, child, class_name) then
			local param_types = constructor_param_types(bufnr, child)
			if #param_types == #generated_param_types then
				local same = true
				for index, generated_type in ipairs(generated_param_types) do
					if normalize_ws(generated_type) ~= normalize_ws(param_types[index] or "") then
						same = false
						break
					end
				end

				if same then
					if child:type() == "function_definition"
						and same_ordered_names(constructor_initializer_names(bufnr, child), member_names)
					then
						return "equivalent"
					end

					return "conflict"
				end
			end
		end
	end

	return nil
end

local function infer_indents(bufnr, body)
	local bsr, _, ber = body:range()
	local close_line = vim.api.nvim_buf_get_lines(bufnr, ber, ber + 1, false)[1] or ""
	local class_indent = line_indent(close_line)
	local fallback_child = class_indent .. string.rep(" ", vim.bo[bufnr].shiftwidth > 0 and vim.bo[bufnr].shiftwidth or 4)

	for child in iter_named_children(body) do
		local sr = child:range()
		if sr > bsr then
			local line = vim.api.nvim_buf_get_lines(bufnr, sr, sr + 1, false)[1] or ""
			local indent = line_indent(line)
			if #indent > #class_indent then return class_indent, indent end
		end
	end

	return class_indent, fallback_child
end

local function find_public_insert_row(bufnr, body, kind)
	local _, _, body_end_row = body:range()
	local default_access = kind == "struct" and "public" or "private"
	local access = default_access
	local selected_public = kind == "struct" and { start_row = nil, end_row = body_end_row } or nil

	for child in iter_named_children(body) do
		local child_kind = child:type()
		local sr = child:range()

		if child_kind == "access_specifier" then
			local spec = trim(get_node_text(child, bufnr))
			if ACCESS_SPECIFIERS[spec] then
				if selected_public and selected_public.end_row == body_end_row then
					selected_public.end_row = sr
				end
				access = spec
				if access == "public" then
					local line_row = sr
					selected_public = { start_row = line_row + 1, end_row = body_end_row }
				end
			end
		elseif selected_public and access == "public" then
			selected_public.end_row = body_end_row
		end
	end

	if selected_public then
		return selected_public.end_row, false
	end

	return body_end_row, true
end

local function build_constructor_lines(class_name, members, class_indent, child_indent, needs_public, trailing_blank)
	local indent_step = child_indent:sub(#class_indent + 1)
	if indent_step == "" then
		indent_step = string.rep(" ", vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or 4)
	end
	local continuation_indent = child_indent .. indent_step
	local params = {}
	local initializers = {}

	for _, member in ipairs(members) do
		table.insert(params, member.param_type .. " " .. member.param_name)
		table.insert(initializers, member.name .. "(" .. member.param_name .. ")")
	end

	local prefix = #members == 1 and "explicit " or ""
	local lines = { "" }

	if needs_public then
		table.insert(lines, class_indent .. "public:")
	end

	local signature = child_indent .. prefix .. class_name .. "(" .. table.concat(params, ", ") .. ")"
	if #members == 1 then
		table.insert(lines, signature)
		table.insert(lines, continuation_indent .. ": " .. initializers[1] .. " {}")
	else
		table.insert(lines, signature)
		table.insert(lines, continuation_indent .. ": " .. initializers[1] .. ",")
		for index = 2, #initializers do
			local suffix = index == #initializers and " {}" or ","
			table.insert(lines, continuation_indent .. "  " .. initializers[index] .. suffix)
		end
	end

	if trailing_blank then
		table.insert(lines, "")
	end

	return lines
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

function M.generate()
	local bufnr = vim.api.nvim_get_current_buf()
	local tree = get_cpp_parser_tree(bufnr)
	if not tree then return end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local col = cursor[2]
	local class_node = find_enclosing_class(tree:root(), row, col)
	if not class_node then
		notify("Cursor is not inside a C++ class definition", vim.log.levels.ERROR)
		return
	end

	local body = find_class_body(class_node)
	local class_name = get_class_name(class_node, bufnr)
	if not body or not class_name or class_name == "" then
		notify("Cursor is not inside a C++ class definition", vim.log.levels.ERROR)
		return
	end

	local members, err = collect_members(bufnr, class_node)
	if not members then
		notify(err, vim.log.levels.WARN)
		return
	end

	if vim.tbl_isempty(members) then
		notify("No eligible instance members found", vim.log.levels.INFO)
		return
	end

	local generated_param_types = vim.tbl_map(function(member)
		return member.param_type
	end, members)
	local member_names = vim.tbl_map(function(member)
		return member.name
	end, members)
	local existing_status = existing_constructor_status(bufnr, class_node, class_name, generated_param_types, member_names)
	if existing_status == "equivalent" then
		notify("Equivalent all-members constructor already exists", vim.log.levels.INFO)
		return
	elseif existing_status == "conflict" then
		notify("Generated signature conflicts with an existing constructor", vim.log.levels.WARN)
		return
	end

	local insert_row, needs_public = find_public_insert_row(bufnr, body, class_kind(class_node))
	local class_indent, child_indent = infer_indents(bufnr, body)
	local _, _, body_end_row = body:range()
	local lines = build_constructor_lines(class_name, members, class_indent, child_indent, needs_public, insert_row < body_end_row)

	vim.api.nvim_buf_set_lines(bufnr, insert_row, insert_row, false, lines)
	notify("Generated trivial constructor for " .. class_name)
end

function M.setup()
	vim.api.nvim_create_user_command("CppTrvCtr", function()
		M.generate()
	end, {
		desc = "Generate a simple memberwise C++ constructor for the current class",
	})
end

return M
