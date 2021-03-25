##lua-debug
@implement+=
function M.launch()
  @spawn_nvim_instance_for_server
  @set_hook_instance_address
  @launch_server
  log("Server started on port " .. server.port)
  return server
end

@script_variables+=
local nvim_server

@spawn_nvim_instance_for_server+=
nvim_server = vim.fn.jobstart({'nvim', '--embed', '--headless'}, {rpc = true})

@set_hook_instance_address+=
local hook_address = vim.fn.serverstart()
vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[debug_hook_conn_address = ...]], {hook_address})

@launch_server+=
local server = vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[return require"lua-debug".start_server()]], {})

@implement+=
function M.wait_attach()
  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    @wait_for_attach_message
    if not has_attach then return end
    log("Attach!")
    timer:close()

    local handlers = {}
    @attach_variables
    @implement_handlers
    @attach_to_current_instance
  end))
end
