# OBS Notification

Get notifications on your desktop screen after successful OBS events

![](./assets/notification.gif)

Events:
- OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED
- OBS_FRONTEND_EVENT_STREAMING_STARTED
- OBS_FRONTEND_EVENT_STREAMING_STOPPED
- OBS_FRONTEND_EVENT_RECORDING_STARTED
- OBS_FRONTEND_EVENT_RECORDING_STOPPED

> [!IMPORTANT]
> Notification will not work if you have app open in fullscreen mode
>
> For example in games, make sure to use a borderless window instead of fullscreen mode

## Installation

> [!NOTE]
> Tested only on Windows 10

Copy repo with `git clone` or just Download ZIP to folder you want

### Windows

1. Download [SDL3](https://github.com/libsdl-org/SDL/releases/tag/release-3.2.10) and [SDL_TTF3](https://github.com/libsdl-org/SDL_ttf/releases/tag/release-3.2.2)
(`*-win32-x64.zip` or `*-win32-x86.zip` depending on your system)

1. Extract `SDL3.dll` and `SDL3_ttf.dll` from archives and save them in `lib/resources` folder

### Linux and macOS

Get binary files for your OS:

- `libSDL3.so` and `libSDL3_ttf.so` for linux
- `libSDL3.dylib` and `libSDL3_ttf.dylib` for macOS

## Configuration

### Dependencies settings

`lib/get_dependencies.lua` file defines default dependency settings for each OS

If necessary, you can change these settings

### Notification window config

`lib/config.lua` file defines default notification window config

## Add to OBS

`OBS` > `Tools` > `Scripts`, click on `+` button, find folder with saved project and select `lib/notification.lua`
