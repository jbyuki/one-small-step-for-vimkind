##lua-debug
@implement+=
function M.start_server(host, port, do_log)
  @init_logger_server
  @create_server
  @bind_server
  @listen_server
  @connect_to_hook
	@create_autocommand_when_exit_in_server

  return {
    host = host,
    port = server:getsockname().port
  }
end

@init_logger_server+=
if do_log then
  log_filename = vim.fn.stdpath("data") .. "/osv.log"
end

@create_server+=
local server = vim.loop.new_tcp()

@bind_server+=
server:bind(host, port)

@script_variables+=
-- for now, only accepts a single
-- connection
local client

@listen_server+=
server:listen(128, function(err)
  @accept_server
  @socket_variables

  client = sock

  @create_reading_coroutine
  @start_reading
end)

if not server:getsockname() then
	return nil
end

print("Server started on " .. server:getsockname().port)

@accept_server+=
local sock = vim.loop.new_tcp()
server:accept(sock)

@script_variables+=
local debug_hook_conn 

@connect_to_hook+=
if debug_hook_conn_address then
  debug_hook_conn = vim.fn.sockconnect("pipe", debug_hook_conn_address, {rpc = true})
end

