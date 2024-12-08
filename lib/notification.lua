local create_notification = require("create_notification")
local get_dependencies = require("get_dependencies")
local obs = obslua

local events_text = {
  [obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED] = "Replay saved",
  [obs.OBS_FRONTEND_EVENT_STREAMING_STARTED] = "Stream started",
  [obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED] = "Stream stopped",
  [obs.OBS_FRONTEND_EVENT_RECORDING_STARTED] = "Recording started",
  [obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED] = "Recording stopped",
}

local function create_on_event(send_notification)
  return function(event)
    local event_text = events_text[event]

    if event_text ~= nil then
      send_notification(event_text)
    end
  end
end

function script_load()
  print("Load obs-notification script")
  local dependencies = get_dependencies(script_path())
  local send_notification = create_notification(dependencies)

  obs.obs_frontend_add_event_callback(create_on_event(send_notification))
end

function script_description()
  return "Get notifications from OBS just like in ShadowPlay"
end
