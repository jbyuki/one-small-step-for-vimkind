##../lua-debug
@support_capabilities+=
supportTerminateDebuggee = true,

@declare+=
local sendProxyDAPSync

@implement+=
function sendProxyDAPSync(data)
  log(vim.inspect(data))
  vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[require"osv".sendDAP(...)]], {data})
end

@implement_handlers+=
function handlers.disconnect(request)
	sendProxyDAPSync(make_response(request, {}))
	if request.terminateDebuggee == true then
		stop()
	end
end

