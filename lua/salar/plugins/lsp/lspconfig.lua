return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim",                   opts = {} },
	},
	config = function()
		local lspconfig = require("lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local keymap = vim.keymap


		-- setup keymaps when LSP attaches
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }

				local client = vim.lsp.get_client_by_id(ev.data.client_id)
				if client and client.server_capabilities.semanticTokensProvider then
					client.server_capabilities.semanticTokensProvider = nil
				end

				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Show documentation under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

				-- Enable inlay hints if supported
				local client = vim.lsp.get_client_by_id(ev.data.client_id)
				local ft = vim.bo[ev.buf].filetype
				local path = vim.api.nvim_buf_get_name(ev.buf)
				local disable_inlay_hints = vim.tbl_contains({ "c", "cpp", "objc", "objcpp" }, ft)
					or path:match("%.h$")
					or path:match("%.hh$")
					or path:match("%.hpp$")
					or path:match("%.hxx$")
					or path:match("%.inl$")

				if client and client.server_capabilities.inlayHintProvider and not disable_inlay_hints then
					vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
				end
			end,
		})

		-- LSP completion capabilities
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- diagnostic signs
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		-- inline diagnostics (virtual text)
		vim.diagnostic.config({
			virtual_text = {
				prefix = "●",
				spacing = 2,
			},
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		-- ============================
		-- Language servers
		-- ============================

		-- TypeScript / TSX
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- ============================
		-- TypeScript / TSX (NEW API)
		-- ============================
		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
			filetypes = {
				"typescript",
				"typescriptreact",
				"javascript",
				"javascriptreact",
			},
		})

		vim.lsp.enable("ts_ls")

		-- ============================
		-- Clang
		-- ============================
		vim.lsp.config("clangd", {
			capabilities = capabilities,
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--query-driver=/usr/bin/c++,/usr/bin/g++",
			},
		})
		vim.lsp.enable("clangd")

		-- ============================
		-- Lua
		-- ============================
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
		})
		vim.lsp.enable("lua_ls")

		-- auto-format on save (C/C++)
		vim.api.nvim_create_autocmd("BufWritePre", {
			callback = function(ev)
				local ft = vim.bo[ev.buf].filetype


				-- Typst uses typstyle (not LSP)
				if ft == "typst" then
					require("conform").format({ bufnr = ev.buf })
					return
				end

				vim.lsp.buf.format({
					bufnr = ev.buf,
					async = false,
				})
			end,
		})
		-- ============================
		-- Rust
		-- ============================
		vim.lsp.config("rust_analyzer", {
			capabilities = capabilities,
			settings = {
				["rust-analyzer"] = {
					inlayHints = {
						typeHints = { enable = true },

						parameterHints = { enable = false },
						chainingHints = { enable = false },
						bindingModeHints = { enable = false },
						closureReturnTypeHints = { enable = "never" },
						lifetimeElisionHints = { enable = "never" },
						reborrowHints = { enable = false },
						closingBraceHints = { enable = false },
					},
				},
			},
		})

		vim.lsp.enable("rust_analyzer")

		-- ============================
		-- Typst
		-- ============================
		vim.lsp.config("tinymist", {
			cmd = { "tinymist" },
			filetypes = { "typst" },
			root_markers = { ".git" },
			capabilities = capabilities,
		})

		vim.lsp.enable("tinymist")
	end,


}
