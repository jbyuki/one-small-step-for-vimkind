##lua-debug
@add_message_to_hook_instance+=
if debug_hook_conn then
  vim.fn.rpcrequest(debug_hook_conn, "nvim_exec_lua", [[table.insert(require"lua-debug".server_messages, ...)]], {msg})
end

@implement+=
M.server_messages = {}
