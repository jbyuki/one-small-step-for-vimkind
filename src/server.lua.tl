##lua-debug
@implement+=
function M.start_server()
  @create_server
  @bind_server
  @listen_server
  @connect_to_hook

  return {
    host = host,
    port = server:getsockname().port
  }
end

@create_server+=
local server = vim.loop.new_tcp()

@script_variables+=
local host = "127.0.0.1"

@bind_server+=
server:bind(host, 0)

@script_variables+=
-- for now, only accepts a single
-- connection
local client

@listen_server+=
server:listen(128, function(err)
  @accept_server
  @socket_variables
  @socket_functions

  client = sock

  @create_reading_coroutine
  @start_reading
end)

log("Server started on " .. server:getsockname().port)

@implement+=
function M.test()
  return 2
end

@accept_server+=
local sock = vim.loop.new_tcp()
server:accept(sock)
