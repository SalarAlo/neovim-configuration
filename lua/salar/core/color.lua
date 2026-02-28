local set = vim.api.nvim_set_hl

vim.opt.background = vim.opt.background:get()

vim.cmd("hi clear")
vim.cmd("syntax reset")

vim.g.colors_name = "dosbox-black"

local function hl(group, opts)
	set(0, group, opts)
end

if vim.o.background == "light" then
	hl("Boolean", { fg = "#707070" })
	hl("ColorColumn", { bg = "#f5f5f5" })
	hl("Comment", { fg = "#969696" })
	hl("Conceal", { fg = "#707070" })
	hl("Conditional", { fg = "#4a4a4a" })
	hl("Constant", { fg = "#707070" })
	hl("Cursor", { reverse = true })
	hl("CursorColumn", { bg = "#f5f5f5" })
	hl("CursorLine", { bg = "#f5f5f5" })
	hl("CursorLineNr", { fg = "#969696" })

	hl("DiffAdd", { bg = "#f0fff0" })
	hl("DiffChange", { bg = "#f5f5f5" })
	hl("DiffDelete", { bg = "#fff0f0" })
	hl("DiffText", { bg = "#e3e3e3" })

	hl("Directory", { fg = "#4a4a4a" })
	hl("Error", { bg = "#fff0f0" })
	hl("ErrorMsg", { bg = "#fff0f0" })

	hl("FoldColumn", { fg = "#c2c2c2" })
	hl("Folded", { fg = "#969696" })

	hl("IncSearch", { bg = "#e3e3e3" })
	hl("LineNr", { fg = "#c2c2c2" })
	hl("MatchParen", { bg = "#e3e3e3" })
	hl("NonText", { fg = "#c2c2c2" })

	hl("Normal", { fg = "#000000", bg = "#ffffff" })
	hl("Number", { fg = "#707070" })

	hl("Pmenu", { bg = "#f5f5f5" })
	hl("PmenuSbar", { bg = "#ededed" })
	hl("PmenuSel", { bg = "#e3e3e3" })
	hl("PmenuThumb", { bg = "#dbdbdb" })

	hl("Search", { bg = "#ededed" })
	hl("SignColumn", { fg = "#c2c2c2" })

	hl("Special", { fg = "#707070" })
	hl("SpecialKey", { fg = "#c2c2c2" })

	hl("SpellBad", { undercurl = true, bg = "#fff0f0" })
	hl("SpellLocal", { undercurl = true, bg = "#f0fff0" })
	hl("SpellRare", { undercurl = true, bg = "#ededed" })

	hl("Statement", { fg = "#4a4a4a" })
	hl("StatusLine", { fg = "#262626", bg = "#ededed" })
	hl("StatusLineNC", { fg = "#969696", bg = "#ededed" })

	hl("StorageClass", { fg = "#4a4a4a" })
	hl("String", { fg = "#707070" })

	hl("TabLine", { fg = "#969696", bg = "#ededed" })
	hl("TabLineFill", { bg = "#ededed" })
	hl("TabLineSel", { fg = "#262626", bg = "#ededed" })

	hl("Title", { fg = "#707070" })
	hl("Todo", { standout = true })
	hl("Type", { fg = "#4a4a4a" })

	hl("VertSplit", { fg = "#e3e3e3" })
	hl("Visual", { bg = "#e3e3e3" })

	hl("WarningMsg", { bg = "#fff0f0" })
	hl("WildMenu", { bg = "#d1d1d1" })
elseif vim.o.background == "dark" then
	hl("Boolean", { fg = "#ecfef6" })
	hl("ColorColumn", { bg = "#1a1a1a" })
	hl("Comment", { fg = "#d04863" })
	hl("Conceal", { fg = "#808080" })
	hl("Conditional", { fg = "#fef5fd" })
	hl("Constant", { fg = "#808080" })
	hl("Cursor", { reverse = true })
	hl("CursorColumn", { bg = "#1a1a1a" })
	hl("CursorLine", { bg = "#1a1a1a" })
	hl("CursorLineNr", { fg = "#707070" })

	hl("DiffAdd", { bg = "#092509" })
	hl("DiffChange", { bg = "#1a1a1a" })
	hl("DiffDelete", { bg = "#250909" })
	hl("DiffText", { bg = "#333333" })

	hl("Directory", { fg = "#8f8f8f" })
	hl("Error", { bg = "#250909" })
	hl("ErrorMsg", { bg = "#250909" })

	hl("FoldColumn", { fg = "#616161" })
	hl("Folded", { fg = "#707070" })

	hl("IncSearch", { bg = "#333333" })
	hl("LineNr", { fg = "#616161" })
	hl("MatchParen", { bg = "#333333" })
	hl("NonText", { fg = "#616161" })

	hl("Normal", { fg = "#b1b2b9", bg = "#000000" })
	hl("Number", { fg = "#7c80f8" })

	hl("Pmenu", { bg = "#1a1a1a" })
	hl("PmenuSbar", { bg = "#262626" })
	hl("PmenuSel", { bg = "#333333" })
	hl("PmenuThumb", { bg = "#424242" })

	hl("Search", { bg = "#262626" })
	hl("SignColumn", { fg = "#616161" })

	hl("Special", { fg = "#f7ce82" })
	hl("SpecialKey", { fg = "#616161" })

	hl("SpellBad", { undercurl = true, bg = "#250909" })
	hl("SpellLocal", { undercurl = true, bg = "#092509" })
	hl("SpellRare", { undercurl = true, bg = "#262626" })

	hl("Statement", { fg = "#f5fef8" })
	hl("StatusLine", { fg = "#000000", bg = "#787878" })
	hl("StatusLineNC", { fg = "#707070", bg = "#262626" })

	hl("StorageClass", { fg = "#e9f1e9" })
	hl("String", { fg = "#3fb6a6" })

	hl("TabLine", { fg = "#000000", bg = "#8f8f8f" })
	hl("TabLineFill", { fg = "#e6e6f0", bg = "#8c8c8c" })
	hl("TabLineSel", { fg = "#000000", bg = "#8f8f8f", bold = true })

	hl("Title", { fg = "#808080" })
	hl("Todo", { standout = true })
	hl("Type", { fg = "#eaf0e5" })

	hl("VertSplit", { fg = "#333333" })
	hl("Visual", { bg = "#333333" })

	hl("WarningMsg", { bg = "#250909" })
	hl("WildMenu", { bg = "#525252" })
end
