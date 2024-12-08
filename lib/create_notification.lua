local ffi = require("ffi")
local bit = require("bit")
local config = require("config")

ffi.cdef [[
  // SDL
  enum {
    SDL_INIT_VIDEO = 0x00000020,
    SDL_QUIT = 0x100,
    SDL_WINDOW_SHOWN = 0x00000004,
    SDL_WINDOW_SKIP_TASKBAR = 0x00010000,
    SDL_WINDOW_BORDERLESS = 0x00000010,
    SDL_RENDERER_ACCELERATED = 0x00000002,
  };

  typedef struct SDL_Window SDL_Window;
  typedef struct SDL_Renderer SDL_Renderer;
  typedef struct SDL_DisplayMode {
    uint32_t format;
    int w;
    int h;
    int refresh_rate;
    void *driverdata;
  } SDL_DisplayMode;
  typedef struct SDL_Color {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
  } SDL_Color;
  typedef struct SDL_Rect {
    int x;
    int y;
    int w;
    int h;
  } SDL_Rect;
  typedef struct SDL_PixelFormat SDL_PixelFormat;
  typedef struct SDL_BlitMap SDL_BlitMap;
  typedef struct SDL_Surface {
    uint32_t flags;
    SDL_PixelFormat *format;
    int w, h;
    int pitch;
    void *pixels;
    void *userdata;
    int locked;
    void *list_blitmap;
    SDL_Rect clip_rect;
    SDL_BlitMap *map;
    int refcount;
  } SDL_Surface;
  typedef struct SDL_Texture SDL_Texture;
  typedef enum SDL_bool {
    SDL_FALSE,
    SDL_TRUE,
  } SDL_bool;

  const char* SDL_GetError();
  int SDL_Init(unsigned int flags);
  void SDL_Quit();
  SDL_Window* SDL_CreateWindow(const char *title, int x, int y, int w, int h, unsigned int flags);
  void SDL_DestroyWindow(SDL_Window* window);
  void SDL_SetWindowAlwaysOnTop(SDL_Window* window, SDL_bool on_top);
  int SDL_SetWindowOpacity(SDL_Window* window, float opacity);
  SDL_Renderer* SDL_CreateRenderer(SDL_Window* window, int index, unsigned int flags);
  void SDL_DestroyRenderer(SDL_Renderer* renderer);
  void SDL_RenderClear(SDL_Renderer* renderer);
  int SDL_RenderCopy(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_Rect* srcrect, const SDL_Rect* dstrect);
  void SDL_RenderPresent(SDL_Renderer* renderer);
  int SDL_SetRenderDrawColor(SDL_Renderer* renderer, unsigned int r, unsigned int g, unsigned int b, unsigned int a);
  SDL_Texture* SDL_CreateTextureFromSurface(SDL_Renderer* renderer, SDL_Surface* surface);
  void SDL_DestroyTexture(SDL_Texture* texture);
  void SDL_FreeSurface(SDL_Surface* surface);
  void SDL_Delay(int ms);
  int SDL_GetCurrentDisplayMode(int display_index, SDL_DisplayMode* mode);
  void* SDL_RWFromFile(const char* file, const char* mode);
  SDL_Surface* SDL_LoadBMP_RW(void* src, int freesrc);

  // SDL_ttf
  typedef struct TTF_Font TTF_Font;

  int TTF_Init();
  void TTF_Quit();
  TTF_Font* TTF_OpenFont(const char* path, int ptsize);
  void TTF_CloseFont(TTF_Font* font);
  SDL_Surface* TTF_RenderText_Blended_Wrapped(TTF_Font* font, const char* text, SDL_Color color, int wrapLength);
  void TTF_SetFontWrappedAlign(TTF_Font *font, int align);
]]

local function create_notification(dependencies)
  local sdl = ffi.load(dependencies.sdl_path)
  local sdl_ttf = ffi.load(dependencies.sdl_ttf_path)

  return function(text)
    -- Init libs
    assert(sdl.SDL_Init(ffi.C.SDL_INIT_VIDEO) == 0, "SDL_Init failed: " .. ffi.string(sdl.SDL_GetError()))
    assert(sdl_ttf.TTF_Init() == 0, "TTF_Init failed: " .. ffi.string(sdl.SDL_GetError()))

    -- Get display mode
    local display_index = 0
    local display_mode = ffi.new("SDL_DisplayMode")
    assert(sdl.SDL_GetCurrentDisplayMode(display_index, display_mode) == 0,
      "SDL_GetCurrentDisplayMode failed: " .. ffi.string(sdl.SDL_GetError()))

    -- Setup window
    local window_width = config.window_width
    local window_height = config.window_height
    local window_position = config:get_window_position(display_mode)
    local window_flags = bit.bor(ffi.C.SDL_WINDOW_SHOWN, ffi.C.SDL_WINDOW_SKIP_TASKBAR, ffi.C.SDL_WINDOW_BORDERLESS)
    local window = sdl.SDL_CreateWindow("OBS Notification", window_position.x, window_position.y, window_width,
      window_height, window_flags)
    assert(window ~= nil, "SDL_CreateWindow failed: " .. ffi.string(sdl.SDL_GetError()))

    sdl.SDL_SetWindowAlwaysOnTop(window, ffi.C.SDL_TRUE)

    if sdl.SDL_SetWindowOpacity(window, config.window_opacity) ~= 0 then
      print("SDL_SetWindowOpacity failed: " .. ffi.string(sdl.SDL_GetError()))
    end

    -- Setup renderer
    local renderer = sdl.SDL_CreateRenderer(window, -1, ffi.C.SDL_RENDERER_ACCELERATED)
    assert(renderer ~= nil, "SDL_CreateRenderer failed: " .. ffi.string(sdl.SDL_GetError()))

    -- Setup icon
    local icon_surface = sdl.SDL_LoadBMP_RW(sdl.SDL_RWFromFile(dependencies.icon_path, "rb"), 1)
    assert(icon_surface ~= nil, "SDL_LoadBMP failed: " .. ffi.string(sdl.SDL_GetError()))

    local icon_texture = sdl.SDL_CreateTextureFromSurface(renderer, icon_surface);
    sdl.SDL_FreeSurface(icon_surface);
    assert(icon_texture ~= nil, "SDL_CreateTextureFromSurface failed: " .. ffi.string(sdl.SDL_GetError()))

    local icon_size = window_height * 0.7
    local icon_position = (window_height - icon_size) / 2
    local icon_rect = ffi.new("SDL_Rect", { icon_position, icon_position, icon_size, icon_size })

    -- Setup text
    local font = sdl_ttf.TTF_OpenFont(dependencies.font_path, dependencies.font_size)
    assert(font ~= nil, "TTF_OpenFont failed: " .. ffi.string(sdl.SDL_GetError()))

    sdl_ttf.TTF_SetFontWrappedAlign(font, 1)

    local wrap_length = window_width - window_height
    local text_color = ffi.new("SDL_Color", config.text_color_rgba)
    local text_surface = sdl_ttf.TTF_RenderText_Blended_Wrapped(font, text, text_color, wrap_length)
    assert(text_surface ~= nil, "TTF_RenderText_Blended_Wrapped failed: " .. ffi.string(sdl.SDL_GetError()))

    local text_texture = sdl.SDL_CreateTextureFromSurface(renderer, text_surface)
    assert(text_texture ~= nil, "SDL_CreateTextureFromSurface failed: " .. ffi.string(sdl.SDL_GetError()))

    local text_width = text_surface.w
    local text_height = text_surface.h
    sdl.SDL_FreeSurface(text_surface)
    local text_position_x = (window_width - text_width) / 2 + window_height / 2
    local text_position_y = (window_height - text_height) / 2

    local text_rect = ffi.new("SDL_Rect", { text_position_x, text_position_y, text_width, text_height })
    local window_color = config.window_color_rgba

    -- Render phase
    sdl.SDL_SetRenderDrawColor(renderer, window_color[1], window_color[2], window_color[3], window_color[4])
    sdl.SDL_RenderClear(renderer)
    sdl.SDL_RenderCopy(renderer, icon_texture, nil, icon_rect)
    sdl.SDL_RenderCopy(renderer, text_texture, nil, text_rect)
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
