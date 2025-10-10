return {
  -- Highlight same word under cursor
  {
    "RRethy/vim-illuminate",
    config = function()
      require("illuminate").configure({
        delay = 200,
        large_file_cutoff = 2000,
        min_count_to_highlight = 2,
      })
    end,
  },
}
