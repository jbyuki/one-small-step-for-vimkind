##../lua-debug
@script_variables+=
local limit = 0

@attach_to_current_instance+=
debug.sethook(function(event, line)
  if lock_debug_loop then return end

  @handle_new_messages
  @clear_messages

  local depth = -1
  @speedup_stack_monitor
  if monitor_stack and not skip_monitor then
    @get_stack_depth_with_debug_getinfo
    @disable_monitor_for_speedup
  end

  @check_if_breakpoint_hit
  @check_if_step_into
  @check_if_next
  @check_if_step_out
  @check_if_pause
  end
end, "clr")

@implement_handlers+=
function handlers.attach(request)
  @acknowledge_attach
end


@acknowledge_attach+=
sendProxyDAP(make_response(request, {}))
