##lua-debug-test
@../test/test.lua=
@declare
@implement
@script_variables
-- local host_neovim_conn_add = [[\\.\pipe\nvim-21064-0]]
-- local host_neovim_conn = vim.fn.sockconnect('pipe', host_neovim_conn_add, {rpc = true})
@create_host_neovim_instance
@redefine_print_in_host_neovim_instance

@start_debug_adapter

-- local debug_neovim_conn_add = [[\\.\pipe\nvim-9368-0]]
-- local debug_neovim_conn = vim.fn.sockconnect('pipe', debug_neovim_conn_add, {rpc = true})
@create_debug_neovim_instance

@send_dap_configuration

@open_lua_file
@start_dap_session

@execute_in_host

vim.wait(500)

-- @next_in_debug_session
-- @step_in_debug_session
-- @continue_in_debug_session
-- @step_out_debug_session
-- @test_hover_debug_session
-- @test_repl
-- @test_pause_session
-- @test_disconnect_session
-- @test_next_over

@capture_output_from_host
@check_capture_output

@close_lua_file

@close_host_neovim_instance
@close_debug_neovim_instance

@output_result_ok

@create_debug_neovim_instance+=
local debug_neovim_conn = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless'}, {rpc = true})

@close_debug_neovim_instance+=
if debug_neovim_conn then
  vim.fn.jobstop(debug_neovim_conn)
  debug_neovim_conn = nil
end

@open_lua_file+=
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':edit input.lua\n', "n", false)

@close_lua_file+=
vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", "vim.api.nvim_buf_delete(...)", {0, {force = true}})

@create_host_neovim_instance+=
local host_neovim_conn = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless'}, {rpc = true})

@close_host_neovim_instance+=
if host_neovim_conn then
  vim.fn.jobstop(host_neovim_conn)
  host_neovim = nil
end

@start_debug_adapter+=
local server = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", "return require'osv'.launch()", {})
-- vim.fn.rpcnotify(host_neovim_conn, "nvim_exec_lua", "require'osv'.wait_attach()", {})

@start_dap_session+=
-- for some reason I can't nvim_exec_lua here
-- vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", 'jjjj', "n", false) -- go down one line
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", '3gg', "n", false) -- go down one line
vim.wait(200)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".toggle_breakpoint()\n', "n", false)
vim.wait(200)
-- vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", 'jj', "n", false) -- go down one line
-- vim.wait(200)
-- vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".toggle_breakpoint()\n', "n", false)
-- vim.wait(200)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".continue()\n', "n", false)
vim.wait(200)
print("Done!")

@redefine_print_in_host_neovim_instance+=
vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", [[debug_output = {}]], {})

@send_dap_configuration+=
vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", [[require"dap".configurations.lua = {...  }]], { { type = 'nlua', request = 'attach', name = "Attach to running Neovim instance", host = server.host, port = server.port } })
vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", [[require"dap".adapters.nlua = function(callback, config) callback({ type = 'server', host = config.host, port = config.port }) end]], {})


@execute_in_host+=
local result = vim.fn.rpcnotify(host_neovim_conn, "nvim_exec", [[luafile input.lua]], true)
print(vim.inspect(result))

@capture_output_from_host+=
vim.wait(500)
local output = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", [[return debug_output]], {})

for _, line in ipairs(output) do
  print(line)
end

@step_in_debug_session+=
for i=1,11 do
  vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".step_into()\n', "n", false)
  vim.wait(500)
end

@next_in_debug_session+=
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".step_over()\n', "n", false)
vim.wait(500)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".step_over()\n', "n", false)
vim.wait(500)

@continue_in_debug_session+=
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".continue()\n', "n", false)
vim.wait(500)

@step_out_debug_session+=
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".step_out()\n', "n", false)
vim.wait(500)

@test_hover_debug_session+=
vim.fn.rpcnotify(debug_neovim_conn, "nvim_win_set_cursor", 0, {3, 6})
vim.wait(100)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap.ui.variables".hover()\n', "n", false)
vim.wait(100)

@test_repl+=
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".repl.open()\n', "n", false)
vim.wait(200)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_exec", "wincmd p", false)
vim.wait(200)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", 'i2*a\n', "n", false)
vim.wait(200)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", '10+10\n', "n", false)
vim.wait(200)

local results = vim.fn.rpcrequest(debug_neovim_conn, "nvim_buf_get_lines", 0, 0, -1, true)
print(vim.inspect(results))

@test_pause_session+=
vim.wait(50)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".continue()\n', "n", false)
vim.wait(50)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".pause(1)\n', "n", false)
vim.wait(200)

@test_disconnect_session+=
vim.wait(50)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".disconnect()\n', "n", false)

@test_next_over+=
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".step_over()\n', "n", false)
vim.wait(200)
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".step_over()\n', "n", false)
vim.wait(200)

@check_capture_output+=
local found = false
for _, line in ipairs(output) do
  if line == "breakpoint hit" then
    found = true
    break
  end
end
assert(found, "breakpoint not hit")

@output_result_ok+=
local f = io.open("result.txt", "w")
f:write("OK")
f:close()
print("OK!")
