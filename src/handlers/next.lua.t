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
stack_level = depth

@set_next_variable+=
next = true
monitor_stack = true

@disable_next+=
next = false
monitor_stack = false

@check_if_next+=
elseif event == "line" and next and depth >= 0 and depth <= stack_level then
  @send_stopped_event_step
  @disable_next

  @freeze_neovim_instance

@get_stack_depth_with_debug_getinfo+=
local surface = 0
local off = 0
while true do
  local info = debug.getinfo(off, "S")
  if not info then
    break
  end

  local inside_osv = false
  @check_if_inside_osv
  if inside_osv then
    surface = off
  end
  off = off + 1
end
@save_for_next_head_start
depth = (off - 1) - surface
