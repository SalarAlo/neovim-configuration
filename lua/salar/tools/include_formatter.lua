-- lua/salar/tools/include_formatter.lua
local M = {}

-----------------------------------------------------------------------
-- Standard library header allow-list (C + C++ up to C++23)
-----------------------------------------------------------------------

local STD_HEADERS = {
	-- C headers
	"assert.h", "ctype.h", "errno.h", "fenv.h", "float.h",
	"inttypes.h", "limits.h", "locale.h", "math.h",
	"setjmp.h", "signal.h", "stdarg.h", "stdbool.h",
	"stddef.h", "stdint.h", "stdio.h", "stdlib.h",
	"string.h", "tgmath.h", "time.h", "uchar.h",
	"wchar.h", "wctype.h", "cstddef",

	-- C++ headers
	"algorithm", "any", "array", "atomic", "barrier", "bit",
	"bitset", "charconv", "chrono", "codecvt", "compare",
	"complex", "concepts", "condition_variable", "coroutine",
	"deque", "exception", "execution", "filesystem",
	"format", "forward_list", "fstream", "functional",
	"future", "generator", "initializer_list", "iomanip",
	"ios", "iosfwd", "iostream", "istream", "iterator",
	"latch", "limits", "list", "locale", "map",
	"memory", "memory_resource", "mutex", "new",
	"numbers", "numeric", "optional", "ostream",
	"queue", "random", "ranges", "ratio", "regex",
	"scoped_allocator", "semaphore", "set",
	"shared_mutex", "source_location", "span", "sstream",
	"stack", "stdexcept", "stop_token", "streambuf",
	"string", "string_view", "strstream", "syncstream",
	"system_error", "thread", "tuple", "type_traits",
	"typeindex", "typeinfo", "unordered_map",
	"unordered_set", "utility", "valarray", "variant",
	"vector", "version",
}

local STD_SET = {}
for _, h in ipairs(STD_HEADERS) do
	STD_SET[h] = true
end

local function is_std_header(path)
	-- Accept both <vector> and <sys/types.h>-style headers
	if STD_SET[path] then
		return true
	end
	local base = path:match("([^/]+)$")
	return base and STD_SET[base] or false
end


-----------------------------------------------------------------------
-- Parsing utilities
-----------------------------------------------------------------------

local function parse_include(line)
	local delim, path = line:match('^%s*#include%s*([<"])(.-)([>"])%s*$')
	if not delim or not path or path == "" then
		return nil
	end

	local close = line:match('^%s*#include%s*[<"].-([>"])%s*$')
	if (delim == "<" and close ~= ">") or (delim == '"' and close ~= '"') then
		return nil
	end

	return {
		kind = (delim == "<") and "angle" or "quote",
		path = path,
	}
end

local function is_conditional_directive(line)
	return line:match("^%s*#%s*(if|ifdef|ifndef|elif|else|endif)%f[%s]") ~= nil
end

local function conditional_delta(line)
	local kw = line:match("^%s*#%s*(%a+)%f[%s]")
	if not kw then return 0 end
	if kw == "if" or kw == "ifdef" or kw == "ifndef" then
		return 1
	elseif kw == "endif" then
		return -1
	end
	return 0
end

local function dirname_of(path)
	return path:match("^(.*)/[^/]+$") or ""
end

local function filename_stem(path)
	local file = path:match("([^/]+)$") or path
	return file:match("^(.*)%.") or file
end

local function buf_basename_stem(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then return "" end
	local tail = vim.fn.fnamemodify(name, ":t")
	return tail:match("^(.*)%.") or tail
end

local function is_blank(line)
	return line:match("^%s*$") ~= nil
end

local function has_noincludeformat_marker(lines)
	for _, line in ipairs(lines) do
		if is_blank(line) then
			-- skip leading blank lines
		elseif line:match("^%s*//%s*noincludeformat%s*$") then
			return true
		else
			return false
		end
	end
	return false
end

local function is_comment(line)
	return line:match("^%s*//") or line:match("^%s*/%*")
end

-----------------------------------------------------------------------
-- Include block detection
-----------------------------------------------------------------------

local function detect_include_block(lines)
	local depth = 0
	local start_idx, end_idx
	local items = {}
	local started = false

	for i = 1, #lines do
		local line = lines[i]
		local delta = conditional_delta(line)

		if started and is_conditional_directive(line) then
			return nil
		end

		if not started then
			if depth == 0 then
				local inc = parse_include(line)
				if inc then
					started = true
					start_idx = i
					end_idx = i
					items[#items + 1] = { inc = inc }
				end
			end
		else
			local inc = parse_include(line)
			if inc then
				end_idx = i
				items[#items + 1] = { inc = inc }
			elseif is_blank(line) or is_comment(line) then
				end_idx = i
			else
				break
			end
		end

		depth = depth + delta
		if depth < 0 then depth = 0 end
	end

	if not started then
		return nil
	end

	return {
		start_idx = start_idx,
		end_idx = end_idx,
		include_items = items,
	}
end

-----------------------------------------------------------------------
-- Formatting
-----------------------------------------------------------------------

local function normalize_include(kind, path)
	if kind == "angle" then
		return "#include <" .. path .. ">"
	end
	return '#include "' .. path .. '"'
end

local function format_block(bufnr, include_items)
	local angle_std, angle_third, quoted = {}, {}, {}
	local seen = {}

	for _, item in ipairs(include_items) do
		local kind = item.inc.kind
		local path = item.inc.path
		local key = kind .. "\0" .. path

		if not seen[key] then
			seen[key] = true
			if kind == "angle" then
				if is_std_header(path) then
					angle_std[#angle_std + 1] = path
				else
					angle_third[#angle_third + 1] = path
				end
			else
				quoted[#quoted + 1] = path
			end
		end
	end

	table.sort(angle_third)
	table.sort(angle_std)
	table.sort(quoted)

	local out = {}
	local function push(l) out[#out + 1] = l end
	local function blank()
		if #out > 0 and out[#out] ~= "" then
			out[#out + 1] = ""
		end
	end

	for _, p in ipairs(angle_third) do
		push(normalize_include("angle", p))
	end
	if #angle_third > 0 and #angle_std > 0 then blank() end
	for _, p in ipairs(angle_std) do
		push(normalize_include("angle", p))
	end

	if #quoted > 0 then
		if #angle_std > 0 or #angle_third > 0 then blank() end

		local self_stem = buf_basename_stem(bufnr)
		local self_inc

		for _, p in ipairs(quoted) do
			if filename_stem(p) == self_stem then
				self_inc = self_inc and math.min(self_inc, p) or p
			end
		end

		if self_inc then
			push(normalize_include("quote", self_inc))
			blank()
		end

		local groups, keys = {}, {}
		for _, p in ipairs(quoted) do
			if p ~= self_inc then
				local k = dirname_of(p)
				if not groups[k] then
					groups[k] = {}
					keys[#keys + 1] = k
				end
				groups[k][#groups[k] + 1] = p
			end
		end

		table.sort(keys)
		for i, k in ipairs(keys) do
			table.sort(groups[k])
			for _, p in ipairs(groups[k]) do
				push(normalize_include("quote", p))
			end
			if i < #keys then blank() end
		end
	end

	return out
end

-----------------------------------------------------------------------
-- Entry point
-----------------------------------------------------------------------

function M.format(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then return end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	if has_noincludeformat_marker(lines) then
		return
	end

	local block = detect_include_block(lines)
	if not block then return end

	local formatted = format_block(bufnr, block.include_items)

	local after = lines[block.end_idx + 1]
	if after and not is_blank(after) then
		formatted[#formatted + 1] = ""
	end

	vim.api.nvim_buf_set_lines(
		bufnr,
		block.start_idx - 1,
		block.end_idx,
		false,
		formatted
	)
end

return M
