return {
 "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    local disable_markdown = vim.fn.has("nvim-0.12") == 1

    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- nvim-treesitter ships a Haskell parser, but not separate parsers for
    -- literate Haskell or Cabal files.
    vim.treesitter.language.register("haskell", "lhaskell")

    -- Neovim core calls `vim.treesitter.start()` directly on the LSP hover
    -- popup (markdown filetype), bypassing nvim-treesitter's own
    -- enable/disable config above. nvim-treesitter's markdown injection
    -- query then crashes in `set-lang-from-info-string!`: it assumes
    -- `match[capture_id]` is a bare TSNode (via a now-defunct `all=false`
    -- compat opt), but this Neovim's query engine always hands directives
    -- `table<integer, TSNode[]>` (a list per capture, per core's own
    -- `offset!` handler). Re-register a version that unwraps the list
    -- instead of calling `:range()` on it, so a fenced code block in
    -- hover docs can't take down the UI.
    do
      local non_filetype_match_injection_language_aliases = {
        ex = "elixir",
        pl = "perl",
        sh = "bash",
        uxn = "uxntal",
        ts = "typescript",
      }

      require("nvim-treesitter.query_predicates")

      vim.treesitter.query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
        local captured = match[pred[2]]
        local node = type(captured) == "table" and captured[#captured] or captured
        if type(node) ~= "userdata" then
          return
        end

        local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
        if not ok then
          return
        end

        local injection_alias = text:lower()
        local filetype = vim.filetype.match({ filename = "a." .. injection_alias })
        metadata["injection.language"] = filetype
          or non_filetype_match_injection_language_aliases[injection_alias]
          or injection_alias
      end, { force = true })
    end

    -- configure treesitter
    treesitter.setup({ -- enable syntax highlighting
      highlight = {
        enable = true,
        disable = disable_markdown and { "markdown", "markdown_inline" } or {},
      },
      -- Treesitter indent can override normal `o`/`O` newline indent behavior.
      indent = { enable = false },
      -- enable autotagging (w/ nvim-ts-autotag plugin)
      autotag = {
        enable = true,
      },
      -- ensure these language parsers are installed
      ensure_installed = {
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "html",
        "css",
        "prisma",
        "markdown",
        "markdown_inline",
        "svelte",
        "graphql",
        "bash",
        "lua",
        "vim",
        "dockerfile",
        "gitignore",
        "query",
        "vimdoc",
        "c",
        "cpp",
        "haskell",
        "gdscript",
        "gdshader",
        "godot_resource",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })
  end,
}
