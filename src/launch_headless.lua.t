##lua-debug
@launch_headless_instance_with_clean_environment+=
local clean_args = { vim.v.progpath, '-u', 'NONE', '-i', 'NONE', '-n', '--embed', '--headless' }
nvim_server = vim.fn.jobstart(clean_args, {rpc = true})
vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', 'vim.o.runtimepath = ...', { vim.o.runtimepath })
