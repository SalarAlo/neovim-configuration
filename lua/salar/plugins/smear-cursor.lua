return {
  {
    "https://github.com/sphamba/smear-cursor.nvim",
    config = function()
      require("smear_cursor").setup({
        -- enabled = false,
        cursor_color = "#ffffff",

        never_draw_over_target = true,

        smear_insert_mode = false,
        min_vertical_distance_smear = 2,
        min_horizontal_distance_smear = 2,

        time_interval = 17, -- ms
        stiffness = 0.9,
        trailing_stiffness = 0.4,
        damping = 0.99, -- stops bouncing

        -- anticipation = 0.2,
        -- distance_stop_animating = 0.6,
      })
    end,
  },
}
