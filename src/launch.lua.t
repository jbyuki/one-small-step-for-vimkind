##lua-debug
@implement+=
function M.launch(opts)
  @verify_launch_arguments
  @abort_early_if_already_running

  @init_logger
  @spawn_nvim_instance_for_server
  @detect_if_nvim_is_blocking
  @set_hook_instance_address
  @clear_messages
  @launch_server
  print("Server started on port " .. server.port)
  M.stop_freeze = false
	@create_autocommand_when_exit
  if not opts or not opts.blocking then
    vim.schedule(M.wait_attach)
  else
    @wait_attach_blocking
  end

  return server
end

@script_variables+=
local nvim_server

@spawn_nvim_instance_for_server+=
@if_exists_use_custom_for_launching_server
else
  @launch_headless_instance_with_clean_environment
end

@script_variables+=
local hook_address

@set_hook_instance_address+=
if not hook_address then
  hook_address = vim.fn.serverstart()
end

vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[debug_hook_conn_address = ...]], {hook_address})

@launch_server+=
local host = (opts and opts.host) or "127.0.0.1"
local port = (opts and opts.port) or 0
local server = vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[return require"osv".start_server(...)]], {host, port, opts and opts.log})
if server == vim.NIL then
	vim.api.nvim_echo({{("Server failed to launch on port %d"):format(port), "ErrorMsg"}}, true, {})
	@terminate_adapter_server_process
	return
end

@implement+=
function M.wait_attach()
  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    @wait_for_attach_message
    if not has_attach then return end
    timer:close()
    M.attach()
  end))
end

@implement+=
function M.attach()
  local handlers = {}
  @attach_variables
  @implement_handlers
  @attach_to_current_instance
end

@verify_launch_arguments+=
vim.validate {
  opts = {opts, 't', true}
}

if opts then
  vim.validate {
    ["opts.host"] = {opts.host, "s", true},
    ["opts.port"] = {opts.port, "n", true},
    ["opts.config_file"] = {opts.config_file, "s", true},
    ["opts.output"] = {opts.output, "b", true},
  }
  if opts.output ~= nil then redir_nvim_output = opts.output end
end

@detect_if_nvim_is_blocking+=
local mode = vim.fn.rpcrequest(nvim_server, "nvim_get_mode")
if mode.blocking then
	vim.api.nvim_echo({{"Neovim is waiting for input at startup. Aborting.", "ErrorMsg"}}, true, {})
	@terminate_adapter_server_process
	return
end

@abort_early_if_already_running+=
if M.is_running() then
	vim.api.nvim_echo({{"Server is already running.", "ErrorMsg"}}, true, {})
  return
end


@implement+=
M.on = {}

@if_exists_use_custom_for_launching_server+=
if M.on["start_server"] then
  nvim_server = M.on["start_server"](args, env)
  assert(nvim_server)


@wait_attach_blocking+=
while true do
  @wait_for_attach_message
  if has_attach then break end
  vim.wait(50)
end

M.attach()

