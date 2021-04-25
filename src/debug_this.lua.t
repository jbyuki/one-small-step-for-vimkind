##lua-debug
@implement+=
function M.debug_this()
  @create_neovim_instance
  @launch_osv_server
  @run_nvim_dap
end

@create_neovim_instance+=
local nvim = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless'}, {rpc = true})

@launch_osv_server+=
local server = vim.fn.rpcrequest(nvim, "nvim_exec_lua", [[return require"osv".launch()]], {})

@run_nvim_dap+=
local osv_config = {
  type = "nlua",
  request = "attach",
  host = server.host,
  port = server.port,
}
local dap = require"dap"
dap.run(osv_config)
dap.listeners.after['attach']['osv'] = function(session, body)
  @wait_for_breakpoints
  @run_current_script
end

@run_current_script+=
vim.fn.rpcnotify(nvim, "nvim_command", "luafile " .. vim.fn.expand("%"))

@wait_for_breakpoints+=
-- Currently I didn't find a better
-- way to do this. An arbitrary amount of
-- time is waited for the breakpoints to 
-- be set
vim.wait(1000)
