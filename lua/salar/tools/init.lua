-- lua/salar/tools/init.lua
local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("SalarIncludeFormatter", { clear = true })

	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		pattern = { "*.h", "*.hpp", "*.hh", "*.hxx", "*.c", "*.cc", "*.cpp", "*.cxx" },
		callback = function(args)
			-- Only current buffer; no external tools.
			require("salar.tools.include_formatter").format(args.buf)
		end,
	})

	-- register :Skel
	vim.api.nvim_create_user_command("Skel", function()
		require("salar.tools.skeleton").insert()
	end, {})
end

return M
