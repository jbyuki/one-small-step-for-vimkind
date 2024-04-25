##lua-debug
@implement+=
M.stop_freeze = false

@accept_server+=
M.stop_freeze = false

@send_disconnect+=
vim.fn.rpcrequest(debug_hook_conn, "nvim_exec_lua", [[require"osv".unfreeze()]], {})

@implement+=
function M.unfreeze()
  if not running then
    M.stop_freeze = true
  end
end

@check_disconnected+=
if M.stop_freeze then
  M.stop_freeze = false
  break
end
