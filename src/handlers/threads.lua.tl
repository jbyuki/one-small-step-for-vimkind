##../lua-debug
@implement_handlers+=
function handlers.threads(request)
  sendProxyDAP(make_response(request, {
    body = {
      threads = {
        {
          id = 1,
          name = "main"
        }
      }
    }
  }))
end
