##../lua-debug
@implement_handlers+=
function handlers.next(request)
  local depth = 0
  @get_stack_depth_with_debug_getinfo
  @set_stack_level_to_current
  @set_next_variable
  @continue_running
  sendProxyDAP(make_response(request, {}))
end

@script_variables+=
local stack_level = 0
local next = false
local monitor_stack = false

@set_stack_level_to_current+=
stack_level = depth-1

@set_next_variable+=
next = true
monitor_stack = true

@disable_next+=
next = false
monitor_stack = false

@check_if_next+=
elseif event == "line" and next and depth <= stack_level then
  @send_stopped_event_step
  @disable_next

  @freeze_neovim_instance

@get_stack_depth_with_debug_getinfo+=
while true do
  local info = debug.getinfo(depth+3, "S")
  if not info then
    break
  end
  depth = depth + 1
end

