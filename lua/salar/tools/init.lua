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

-- Typst auto-compile
local typst_job = nil

vim.api.nvim_create_autocmd("BufWritePost", {
	group = group,
	pattern = "*.typ",
	callback = function(args)
		local file = vim.api.nvim_buf_get_name(args.buf)
		local pdf = file:gsub("%.typ$", ".pdf")

		if typst_job then
			vim.fn.jobstop(typst_job)
		end

		typst_job = vim.fn.jobstart({ "typst", "compile", file, pdf })
	end,
})

vim.api.nvim_create_user_command("TypstPreview", function()
	local file = vim.fn.expand("%")
	local pdf = file:gsub("%.typ$", ".pdf")
	vim.fn.jobstart({ "zathura", pdf })
end, {})

return M
