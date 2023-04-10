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
