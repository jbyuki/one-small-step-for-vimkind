##../lua-debug
@implement_handlers+=
function handlers.next(request)
  @set_stack_level_to_zero
  @set_next_variable
  @continue_running
  sendProxyDAP(make_response(request, {}))
end

@script_variables+=
local stack_level = 0
local next = false
local monitor_stack = false

@set_stack_level_to_zero+=
stack_level = 0

@set_next_variable+=
next = true
monitor_stack = true

@disable_next+=
next = false
monitor_stack = false

@if_call_or_return_update_stack_level+=
if monitor_stack and event == "call" then
  @check_that_is_not_c_function
  if not c_function then
    stack_level = stack_level + 1
  end
elseif monitor_stack and event == "return" then
  stack_level = stack_level - 1
end

@check_if_next+=
elseif event == "line" and next and stack_level == 0 then
  @send_stopped_event_step
  @disable_next

  @freeze_neovim_instance

@check_that_is_not_c_function+=
local info = debug.getinfo(2, "S")
local c_function = info.what == "C"
