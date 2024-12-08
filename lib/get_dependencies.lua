local ffi = require("ffi")

local function get_dependencies(script_path)
  local icon_path = script_path .. "resources/obs.bmp"

  local dependencies_by_os = {
    Windows = {
      sdl_path = script_path .. "resources/SDL2.dll",
      sdl_ttf_path = script_path .. "resources/SDL2_ttf.dll",
      font_path = "C:/Windows/Fonts/Arial.ttf",
      font_size = 20,
      icon_path = icon_path,
    },
    Linux = {
      sdl_path = "/usr/local/lib/libSDL2.so",
      sdl_ttf_path = "/usr/local/lib/libSDL2_ttf.so",
      font_path = "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
      font_size = 20,
      icon_path = icon_path,
    },
    OSX = {
      sdl_path = "/usr/local/lib/libSDL2.dylib",
      sdl_ttf_path = "/usr/local/lib/libSDL2_ttf.dylib",
      font_path = "/Library/Fonts/Arial.ttf",
      font_size = 20,
      icon_path = icon_path,
    },
  }

  local dependencies = dependencies_by_os[ffi.os]

  assert(dependencies ~= nil, "Your os is not supported")

  return dependencies
end

return get_dependencies
