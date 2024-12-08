local config = {
  window_opacity = 0.8,
  window_width = 200,
  window_height = 60,
  get_window_position = function(self, display_mode)
    return { x = display_mode.w - self.window_width, y = display_mode.h / 10 }
  end,
  window_color_rgba = {0, 0, 0, 255},
  text_color_rgba = {255, 255, 255, 255},
  show_notification_ms = 5000,
}

return config
