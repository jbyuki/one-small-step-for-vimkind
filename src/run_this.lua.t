##lua-debug
@implement+=
function M.run_this(opts)
  local dap = require"dap"
  assert(dap, "nvim-dap not found. Please make sure it's installed.")

  @close_previous_neovim_instance
  @create_neovim_instance
  @check_neovim_is_not_blocking
  @launch_osv_server
  @check_has_adapter_config
  @run_nvim_dap
end

@create_neovim_instance+=
@copy_args
@copy_env
auto_nvim = vim.fn.jobstart(args, {rpc = true, env = env})

@launch_osv_server+=
local server = vim.fn.rpcrequest(auto_nvim, "nvim_exec_lua", [[return require"osv".launch(...)]], { opts })
vim.wait(100)

@check_has_adapter_config+=
assert(dap.adapters.nlua, "nvim-dap adapter configuration for nlua not found. Please refer to the README.md or :help osv.txt")

@run_nvim_dap+=
local osv_config = {
  type = "nlua",
  request = "attach",
  name = "Debug current file",
  host = server.host,
  port = server.port,
}
dap.run(osv_config)

dap.listeners.after['setBreakpoints']['osv'] = function(session, body)
  vim.schedule(function()
    @run_current_script
  end)
end

@run_current_script+=
vim.fn.rpcnotify(auto_nvim, "nvim_command", "luafile " .. vim.fn.expand("%:p"))

@script_variables+=
local auto_nvim

@close_previous_neovim_instance+=
if auto_nvim then
  vim.fn.jobstop(auto_nvim)
  auto_nvim = nil
end

@check_neovim_is_not_blocking+=
local mode = vim.fn.rpcrequest(auto_nvim, "nvim_get_mode")
assert(not mode.blocking, "Neovim is waiting for input at startup. Aborting.")

@create_neovim_instance+=
assert(auto_nvim, "Could not create neovim instance with jobstart!")


