##lua-debug
@implement+=
function M.run_this()
  local dap = require"dap"
  assert(dap, "nvim-dap not found. Please make sure it's installed.")

  @create_neovim_instance
  @launch_osv_server
  @check_has_adapter_config
  @run_nvim_dap
end

@create_neovim_instance+=
local nvim = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless'}, {rpc = true})

@launch_osv_server+=
local server = vim.fn.rpcrequest(nvim, "nvim_exec_lua", [[return require"osv".launch()]], {})
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

dap.listeners.after['attach']['osv'] = function(session, body)
  vim.schedule(function()
    @wait_for_breakpoints
    @run_current_script
  end)
end

@run_current_script+=
vim.fn.rpcnotify(nvim, "nvim_command", "luafile " .. vim.fn.expand("%:p"))

@wait_for_breakpoints+=
-- Currently I didn't find a better
-- way to do this. An arbitrary amount of
-- time is waited for the breakpoints to 
-- be set
vim.wait(100)
