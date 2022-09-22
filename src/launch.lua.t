##lua-debug
@implement+=
function M.launch(opts)
  @verify_launch_arguments

  @init_logger
  @spawn_nvim_instance_for_server
  @detect_if_nvim_is_blocking
  @set_hook_instance_address
  @launch_server
  print("Server started on port " .. server.port)
  M.disconnected = false
  vim.defer_fn(M.wait_attach, 0)
  return server
end

@script_variables+=
local nvim_server

@spawn_nvim_instance_for_server+=
if opts.config_file then
  nvim_server = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless', '-u', config_file}, {rpc = true})
else
  nvim_server = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless'}, {rpc = true})
end

@script_variables+=
local hook_address

@set_hook_instance_address+=
if not hook_addres then
  hook_address = vim.fn.serverstart()
end

vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[debug_hook_conn_address = ...]], {hook_address})

@launch_server+=
local host = (opts and opts.host) or "127.0.0.1"
local port = (opts and opts.port) or 0
local server = vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[return require"osv".start_server(...)]], {host, port})

@implement+=
function M.wait_attach()
  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    @wait_for_attach_message
    if not has_attach then return end
    timer:close()

    local handlers = {}
    @attach_variables
    @implement_handlers
    @attach_to_current_instance
  end))
end

@verify_launch_arguments+=
vim.validate {
  opts = {opts, 't', true}
}

if opts then
  vim.validate {
    ["opts.host"] = {opts.host, "s", true},
    ["opts.port"] = {opts.port, "n", true},
  }
end

@detect_if_nvim_is_blocking+=
local mode = vim.fn.rpcrequest(nvim_server, "nvim_get_mode")
assert(not mode.blocking, "Neovim is waiting for input at startup. Aborting.")

@verify_launch_arguments+=
if opts then
  vim.validate {
    ["opts.config_file"] = {opts.config_file, "s", true},
  }
end
