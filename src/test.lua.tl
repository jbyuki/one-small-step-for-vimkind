##lua-debug-test
@*=
@declare
@implement
@script_variables
-- local host_neovim_conn_add = [[\\.\pipe\nvim-18104-0]]
-- local host_neovim_conn = vim.fn.sockconnect('pipe', host_neovim_conn_add, {rpc = true})
@create_host_neovim_instance
@redefine_print_in_host_neovim_instance

@start_debug_adapter

-- local debug_neovim_conn_add = [[\\.\pipe\nvim-19528-0]]
-- local debug_neovim_conn = vim.fn.sockconnect('pipe', debug_neovim_conn_add, {rpc = true})
@create_debug_neovim_instance

@send_dab_configuration

@open_lua_file
@start_dap_session


@execute_in_host

@capture_output_from_host

@close_lua_file

@close_host_neovim_instance
@close_debug_neovim_instance

@create_debug_neovim_instance+=
local debug_neovim_conn = vim.fn.jobstart({'nvim', '--embed', '--headless'}, {rpc = true})

@close_debug_neovim_instance+=
if debug_neovim_conn then
  vim.fn.jobstop(debug_neovim_conn)
  debug_neovim_conn = nil
end

@open_lua_file+=
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':edit test4.lua\n', "n", false)

@close_lua_file
vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec", "bw", true)

@create_host_neovim_instance+=
local host_neovim_conn = vim.fn.jobstart({'nvim', '--embed', '--headless'}, {rpc = true})

@close_host_neovim_instance+=
if host_neovim_conn then
  vim.fn.jobstop(host_neovim_conn)
  host_neovim = nil
end

@start_debug_adapter+=
local server = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", "return require'lua-debug'.launch()", {})
vim.fn.rpcnotify(host_neovim_conn, "nvim_exec_lua", "require'lua-debug'.wait_attach()", {})

@start_dap_session+=
-- for some reason I can't nvim_exec_lua here
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".toggle_breakpoint()\n', "n", false)
vim.wait(200)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".continue()\n', "n", false)
vim.wait(200)
print("Done!")



@redefine_print_in_host_neovim_instance+=
vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", [[debug_output = {}]], {})

@send_dab_configuration+=
vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", [[require"dap".configurations.lua = { { type = 'nlua', request = 'attach', name = "Attach to running Neovim instance", host = '127.0.0.1', port = ]] .. server.port .. [[} }]], {})

@execute_in_host+=
local pwd = vim.fn.rpcrequest(host_neovim_conn, "nvim_get_mode")
print(vim.inspect(pwd))
local result = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec", [[luafile test4.lua]], true)
print(vim.inspect(result))
vim.wait(100)

@capture_output_from_host+=
local output = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", [[return debug_output]], {})
print(vim.inspect(output))
