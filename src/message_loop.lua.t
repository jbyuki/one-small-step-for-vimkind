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
  log(vim.inspect(msg))
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
  vim.fn.rpcnotify(debug_hook_conn, "nvim_exec_lua", [[require"osv".add_message(...)]], {msg})
end

@script_variables+=
local lock_debug_loop = false

@implement+=
function M.add_message(msg)
  lock_debug_loop = true
  table.insert(M.server_messages, msg)
  lock_debug_loop = false
end

@implement+=
M.server_messages = {}
