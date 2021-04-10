##../lua-debug
@implement_handlers+=
function handlers.disconnect(request)
  @disable_hooks
  @send_disconnect_aknowledge
  vim.wait(1000)
  @terminate_adapter_server_process
end

@disable_hooks+=
debug.sethook()

@send_disconnect_aknowledge+=
sendProxyDAP(make_response(request, {}))

@terminate_adapter_server_process+=
if nvim_server then
  vim.fn.jobstop(nvim_server)
  nvim_server = nil
end
