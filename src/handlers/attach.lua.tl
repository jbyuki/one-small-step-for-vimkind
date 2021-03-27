##../lua-debug
@script_variables+=
local limit = 0

@attach_to_current_instance+=
debug.sethook(function(event, line)
  @handle_new_messages
  @clear_messages

  @if_call_or_return_update_stack_level

  @check_if_breakpoint_hit
  @check_if_step_into
  @check_if_next
  @check_if_step_out
  @check_if_pause
  end
end, "clr")

@implement_handlers+=
function handlers.attach(request)
  log("Attached!")
  @acknowledge_attach
end


@acknowledge_attach+=
sendProxyDAP(make_response(request, {}))
