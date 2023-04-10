##../lua-debug
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
