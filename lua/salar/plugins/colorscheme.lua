local colorschemes = require("salar.core.colorschemes")

return vim.tbl_map(function(item)
	local spec = {
		item.repo,
		lazy = true,
		priority = 1000,
	}

	if item.name then
		spec.name = item.name
	end

	return spec
end, colorschemes.items)
