##lua-debug
@wait_for_attach_message+=
local has_attach = false
for _,msg in ipairs(M.server_messages) do
  if msg.command == "attach" then
    has_attach = true
  end
end

@handle_new_messages+=
local i = 1
while i <= #M.server_messages do
  local msg = M.server_messages[i]
  local f = handlers[msg.command]
  if f then
    f(msg)
  else
    log("Could not handle " .. msg.command)
  end
  i = i + 1
end

@clear_messages+=
M.server_messages = {}

@add_message_to_hook_instance+=
if debug_hook_conn then
  vim.fn.rpcrequest(debug_hook_conn, "nvim_exec_lua", [[table.insert(require"one-small-step-for-vimkind".server_messages, ...)]], {msg})
end

@implement+=
M.server_messages = {}
