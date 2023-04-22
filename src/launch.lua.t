##lua-debug
@implement+=
function M.launch(opts)
  @verify_launch_arguments

  @init_logger
  @spawn_nvim_instance_for_server
  @detect_if_nvim_is_blocking
  @set_hook_instance_address
  @clear_messages
  @launch_server
  print("Server started on port " .. server.port)
  M.disconnected = false
	@create_autocommand_when_exit
  vim.defer_fn(M.wait_attach, 0)

  return server
end

@script_variables+=
local nvim_server

@spawn_nvim_instance_for_server+=
local env = nil
local args = {vim.v.progpath, '--embed', '--headless'}
@fill_env_if_lunarvim
@fill_config_file_in_args
nvim_server = vim.fn.jobstart(args, {rpc = true, env = env})

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
local server = vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[return require"osv".start_server(...)]], {host, port, opts and opts.log})

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

@fill_env_if_lunarvim+=
if opts and opts.lvim then
	log("Setting LunarVim envs")

	assert(os.getenv("LUNARVIM_CACHE_DIR") and os.getenv("LUNARVIM_RUNTIME_DIR") and os.getenv("LUNARVIM_CONFIG_DIR") and os.getenv("LUNARVIM_BASE_DIR"), "launch with lvim=true but LUNARVIM environments variables are not set")

	env = {
		["LUNARVIM_CACHE_DIR"] = os.getenv("LUNARVIM_CACHE_DIR"),
		["LUNARVIM_CONFIG_DIR"] = os.getenv("LUNARVIM_CONFIG_DIR"),
		["LUNARVIM_BASE_DIR"] = os.getenv("LUNARVIM_BASE_DIR"),
		["LUNARVIM_RUNTIME_DIR"] = os.getenv("LUNARVIM_RUNTIME_DIR"),
	}
end

@fill_config_file_in_args+=
if opts and opts.lvim then
	table.insert(args, "-u")
	table.insert(args, os.getenv("LUNARVIM_BASE_DIR") .. "/init.lua")
elseif opts and opts.config_file then
	table.insert(args, "-u")
	table.insert(args, opts.config_file)
end

