local ffi = require("ffi")
local config = require("config")

ffi.cdef [[
  // SDL
  enum {
    SDL_INIT_VIDEO = 0x00000020,
  };

  typedef uint32_t SDL_PropertiesID;
  typedef struct SDL_Window SDL_Window;
  typedef struct SDL_Renderer SDL_Renderer;
  typedef uint32_t SDL_DisplayID;
  typedef struct SDL_DisplayMode {
    SDL_DisplayID displayID;
    uint32_t format;
    int w;
    int h;
    float pixel_density;
    float refresh_rate;
    int refresh_rate_numerator;
    int refresh_rate_denominator;
  } SDL_DisplayMode;
  typedef struct SDL_Color {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
  } SDL_Color;
  typedef struct SDL_FRect {
    float x;
    float y;
    float w;
    float h;
  } SDL_FRect;
  typedef struct SDL_BlitMap SDL_BlitMap;
  typedef struct SDL_Surface {
    uint32_t flags;
    int format;
    int w;
    int h;
    int pitch;
    void *pixels;
    int refcount;
  } SDL_Surface;
  typedef struct SDL_Texture SDL_Texture;

  const char* SDL_GetError();
  bool SDL_Init(uint32_t flags);
  void SDL_Quit();
  SDL_PropertiesID SDL_CreateProperties(void);
  void SDL_DestroyProperties(SDL_PropertiesID props);
  bool SDL_SetNumberProperty(SDL_PropertiesID props, const char* name, int64_t value);
  bool SDL_SetStringProperty(SDL_PropertiesID props, const char* name, const char* value);
  bool SDL_SetBooleanProperty(SDL_PropertiesID props, const char* name, bool value);
  SDL_Window* SDL_CreateWindowWithProperties(SDL_PropertiesID props);
  void SDL_DestroyWindow(SDL_Window* window);
  SDL_Renderer* SDL_CreateRenderer(SDL_Window* window, const char* name);
  void SDL_DestroyRenderer(SDL_Renderer* renderer);
  void SDL_RenderClear(SDL_Renderer* renderer);
  bool SDL_RenderTexture(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_FRect* srcrect, const SDL_FRect* dstrect);
  void SDL_RenderPresent(SDL_Renderer* renderer);
  bool SDL_SetRenderDrawColor(SDL_Renderer* renderer, uint8_t r, uint8_t g, uint8_t b, uint8_t a);
  SDL_Texture* SDL_CreateTextureFromSurface(SDL_Renderer* renderer, SDL_Surface* surface);
  void SDL_DestroyTexture(SDL_Texture* texture);
  void SDL_DestroySurface(SDL_Surface* surface);
  void SDL_Delay(int ms);
  SDL_DisplayID* SDL_GetDisplays(int* count);
  const SDL_DisplayMode* SDL_GetCurrentDisplayMode(SDL_DisplayID display_id);
  SDL_Surface* SDL_LoadBMP(const char* file);

  // SDL_ttf
  typedef struct TTF_Font TTF_Font;

  bool TTF_Init();
  void TTF_Quit();
  TTF_Font* TTF_OpenFont(const char* path, float ptsize);
  void TTF_CloseFont(TTF_Font* font);
  SDL_Surface* TTF_RenderText_Blended_Wrapped(TTF_Font* font, const char* text, size_t length, SDL_Color fg, int wrap_width);
  void TTF_SetFontWrapAlignment(TTF_Font* font, int align);
]]

local window_props = {
  title = "SDL.window.create.title",
  x = "SDL.window.create.x",
  y = "SDL.window.create.y",
  height = "SDL.window.create.height",
  width = "SDL.window.create.width",
  focusable = "SDL.window.create.focusable",
  always_on_top = "SDL.window.create.always_on_top",
  borderless = "SDL.window.create.borderless",
  transparent = "SDL.window.create.transparent",
  utility = "SDL.window.create.utility",
}

local function create_notification(dependencies)
  local sdl = ffi.load(dependencies.sdl_path)
  local sdl_ttf = ffi.load(dependencies.sdl_ttf_path)

  return function(text)
    -- Init libs
    assert(sdl.SDL_Init(ffi.C.SDL_INIT_VIDEO), "SDL_Init failed: " .. ffi.string(sdl.SDL_GetError()))
    assert(sdl_ttf.TTF_Init(), "TTF_Init failed: " .. ffi.string(sdl.SDL_GetError()))

    -- Get display mode
    local display_index = 0
    local display_count_ptr = ffi.new("int[1]")
    local displays = sdl.SDL_GetDisplays(display_count_ptr)
    local display_count = display_count_ptr[0]

    assert(display_count > 0 and displays ~= nil, "Not found displays")

    local display_mode = sdl.SDL_GetCurrentDisplayMode(displays[display_index])
    assert(display_mode ~= nil, "SDL_GetCurrentDisplayMode failed: " .. ffi.string(sdl.SDL_GetError()))

    -- Setup window
    local props = sdl.SDL_CreateProperties()
    assert(props ~= nil, "SDL_CreateProperties failed: " .. ffi.string(sdl.SDL_GetError()))

    local window_width = config.window_width
    local window_height = config.window_height
    local window_position = config:get_window_position(display_mode)

    sdl.SDL_SetStringProperty(props, window_props.title, "OBS Notification")
    sdl.SDL_SetNumberProperty(props, window_props.height, window_height)
    sdl.SDL_SetNumberProperty(props, window_props.width, window_width)
    sdl.SDL_SetNumberProperty(props, window_props.x, window_position.x)
    sdl.SDL_SetNumberProperty(props, window_props.y, window_position.y)
    sdl.SDL_SetBooleanProperty(props, window_props.always_on_top, true)
    sdl.SDL_SetBooleanProperty(props, window_props.borderless, true)
    sdl.SDL_SetBooleanProperty(props, window_props.utility, true)
    sdl.SDL_SetBooleanProperty(props, window_props.transparent, true)
    sdl.SDL_SetBooleanProperty(props, window_props.focusable, false)
    local window = sdl.SDL_CreateWindowWithProperties(props)
    sdl.SDL_DestroyProperties(props)
    assert(window ~= nil, "SDL_CreateWindowWithProperties failed: " .. ffi.string(sdl.SDL_GetError()))

    -- Setup renderer
    local renderer = sdl.SDL_CreateRenderer(window, nil)
    assert(renderer ~= nil, "SDL_CreateRenderer failed: " .. ffi.string(sdl.SDL_GetError()))

    -- Setup icon
    local icon_surface = sdl.SDL_LoadBMP(dependencies.icon_path)
    assert(icon_surface ~= nil, "SDL_LoadBMP failed: " .. ffi.string(sdl.SDL_GetError()))

    local icon_texture = sdl.SDL_CreateTextureFromSurface(renderer, icon_surface);
    sdl.SDL_DestroySurface(icon_surface);
    assert(icon_texture ~= nil, "SDL_CreateTextureFromSurface failed: " .. ffi.string(sdl.SDL_GetError()))

    local icon_size = window_height * 0.7
    local icon_position = (window_height - icon_size) / 2
    local icon_rect = ffi.new("SDL_FRect", { icon_position, icon_position, icon_size, icon_size })

    -- Setup text
    local font = sdl_ttf.TTF_OpenFont(dependencies.font_path, dependencies.font_size)
    assert(font ~= nil, "TTF_OpenFont failed: " .. ffi.string(sdl.SDL_GetError()))

    sdl_ttf.TTF_SetFontWrapAlignment(font, 1)

    local wrap_width = window_width - window_height
    local text_color = ffi.new("SDL_Color", config.text_color_rgba)
    local text_surface = sdl_ttf.TTF_RenderText_Blended_Wrapped(font, text, 0, text_color, wrap_width)
    assert(text_surface ~= nil, "TTF_RenderText_Blended_Wrapped failed: " .. ffi.string(sdl.SDL_GetError()))

    local text_texture = sdl.SDL_CreateTextureFromSurface(renderer, text_surface)
    assert(text_texture ~= nil, "SDL_CreateTextureFromSurface failed: " .. ffi.string(sdl.SDL_GetError()))

    local text_width = text_surface.w
    local text_height = text_surface.h
    sdl.SDL_DestroySurface(text_surface)
    local text_position_x = (window_width - text_width) / 2 + window_height / 2
    local text_position_y = (window_height - text_height) / 2

    local text_rect = ffi.new("SDL_FRect", { text_position_x, text_position_y, text_width, text_height })
    local window_color = config.window_color_rgba

    -- Render phase
    sdl.SDL_SetRenderDrawColor(renderer, window_color[1], window_color[2], window_color[3], window_color[4])
    sdl.SDL_RenderClear(renderer)
    sdl.SDL_RenderTexture(renderer, icon_texture, nil, icon_rect)
    sdl.SDL_RenderTexture(renderer, text_texture, nil, text_rect)
    sdl.SDL_RenderPresent(renderer)
    sdl.SDL_Delay(config.show_notification_ms)

    -- Destroy and free phase
    sdl.SDL_DestroyTexture(text_texture)
    sdl.SDL_DestroyRenderer(renderer)
    sdl.SDL_DestroyWindow(window)
    sdl_ttf.TTF_CloseFont(font)
    sdl_ttf.TTF_Quit()
    sdl.SDL_Quit()
  end
end

return create_notification
