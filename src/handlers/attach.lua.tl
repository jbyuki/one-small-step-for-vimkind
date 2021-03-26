##../lua-debug
@attach_to_current_instance+=
debug.sethook(function(event, line)
  @handle_new_messages
  @clear_messages

  @check_if_breakpoint_hit
end, "l")

@implement_handlers+=
function handlers.attach(msg)
  log("Attached!")
end

