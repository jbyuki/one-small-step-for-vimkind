##../lua-debug
@implement_handlers+=
function handlers.disconnect(request)
  @disable_hooks
  @send_disconnect_aknowledge
	@exit_debuggee_if_requested
  @reset_internal_states
	@if_still_running_wait_for_next_connection
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
	vim.fn.jobstop(nvim_server)
	log("SERVER TERMINATED")
  nvim_server = nil
end

@if_still_running_wait_for_next_connection+=
if not request.terminateDebuggee then
	vim.schedule(M.wait_attach)
end
