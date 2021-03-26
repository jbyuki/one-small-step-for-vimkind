##../lua-debug
@attach_to_current_instance+=
debug.sethook(function(event, line)
  @handle_new_messages
  @clear_messages

  @check_if_breakpoint_hit
  @check_if_step_into
end, "l")

@implement_handlers+=
function handlers.attach(request)
  log("Attached!")
  @acknowledge_attach
end


@acknowledge_attach+=
sendProxyDAP(make_response(request, {}))
