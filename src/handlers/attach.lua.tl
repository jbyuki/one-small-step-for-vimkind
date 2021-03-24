##../lua-debug
@attach_to_current_instance+=
debug.sethook(function(event, line)
  @handle_new_messages
  @clear_messages

  @check_if_breakpoint_hit
end, "l")

@handle_new_messages+=
local i = 1
while i <= #server_messages do
  local msg = server_messages[i]
  local f = handlers[msg.command]
  if f then
    f(msg)
  else
    log("Could not handle " .. msg.command)
  end
  i = i + 1
end

@clear_messages+=
server_messages = {}

@implement_handlers+=
function handlers.attach(msg)
  log("Attached!")
end

