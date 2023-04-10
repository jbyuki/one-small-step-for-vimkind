##../lua-debug
@implement_handlers+=
function handlers.disconnect(request)
  @disable_hooks
  @send_disconnect_aknowledge
	@exit_debuggee_if_requested
  @reset_internal_states
end

@disable_hooks+=
debug.sethook()

@send_disconnect_aknowledge+=
sendProxyDAP(make_response(request, {}))

@support_capabilities+=
supportTerminateDebuggee = true,

@exit_debuggee_if_requested+=
if request.terminateDebuggee == true then
	M.stop()
end

@terminate_adapter_server_process+=
if nvim_server then
  vim.fn.rpcnotify(nvim_server, 'nvim_command', [[qa!]])
  log("jobwait " .. vim.inspect(vim.fn.jobwait({nvim_server}, 500)))
  nvim_server = nil
end
