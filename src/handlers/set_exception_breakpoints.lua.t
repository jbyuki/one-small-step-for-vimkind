##../lua-debug
@implement_handlers+=
function handlers.setExceptionBreakpoints(request)
  local args = request.arguments

  -- For now just send back an empty 
  -- answer
  sendProxyDAP(make_response(request, {
    body = {
      breakpoints = {}
    }
  }))
end
