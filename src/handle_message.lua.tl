##lua-debug
@add_message_to_hook_instance+=
if debug_hook_conn then
  vim.fn.rpcnotify(debug_hook_conn, "nvim_exec_lua", [[table.insert(require"lua-debug".server_messages, ...)]], {msg})
end

@script_variables+=
local server_messages = {}

@implement+=
M.server_messages = server_messages
