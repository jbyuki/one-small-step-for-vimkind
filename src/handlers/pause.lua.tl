##../lua-debug
@implement_handlers+=
function handlers.pause(request)
  @set_pause
end

@script_variables+=
local pause = false

@set_pause+=
pause = true

@disable_pause+=
pause = false

@check_if_pause+=
elseif event == "line" and pause then
  @disable_pause
  @send_stopped_event_pause
  @freeze_neovim_instance

@send_stopped_event_pause+=
local msg = make_event("stopped")
msg.body = {
  reason = "pause",
  threadId = 1
}
sendProxyDAP(msg)
