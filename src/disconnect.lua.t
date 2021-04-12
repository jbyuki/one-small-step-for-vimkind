##lua-debug
@implement+=
M.disconnected = false

@accept_server+=
M.disconnected = false

@send_disconnect+=
vim.fn.rpcrequest(debug_hook_conn, "nvim_exec_lua", [[require"osv".disconnected = true]], {})

@check_disconnected+=
if M.disconnected then
  break
end
