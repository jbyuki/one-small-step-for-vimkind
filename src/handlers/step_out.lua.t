##../lua-debug
@implement_handlers+=
function handlers.stepOut(request)
  @set_step_out
  local depth = 0
  @get_stack_depth_with_debug_getinfo
  @set_stack_level_to_current
  @continue_running

  @acknowledge_step_out
end

@acknowledge_step_out+=
sendProxyDAP(make_response(request, {}))

@script_variables+=
local step_out = false

@set_step_out+=
step_out = true
monitor_stack = true

@disable_step_out+=
step_out = false
monitor_stack = false

@check_if_step_out+=
elseif event == "line" and step_out and depth >= 0 and stack_level-1 == depth then
  @send_stopped_event_step
  @disable_step_out

  @freeze_neovim_instance
