##../lua-debug
@implement_handlers+=
function handlers.continue(request)
  @continue_running
  @acknowledge_continue
end

@acknowledge_continue+=
sendProxyDAP(make_response(request,{}))
