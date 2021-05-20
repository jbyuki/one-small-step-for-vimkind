-- Generated using ntangle.nvim
-- local host_neovim_conn_add = [[\\.\pipe\nvim-3456-0]]
-- local host_neovim_conn = vim.fn.sockconnect('pipe', host_neovim_conn_add, {rpc = true})
local host_neovim_conn = vim.fn.jobstart({'nvim', '--embed', '--headless'}, {rpc = true})

vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", [[debug_output = {}]], {})


local server = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", "return require'osv'.launch()", {})
-- vim.fn.rpcnotify(host_neovim_conn, "nvim_exec_lua", "require'osv'.wait_attach()", {})


-- local debug_neovim_conn_add = [[\\.\pipe\nvim-23120-0]]
-- local debug_neovim_conn = vim.fn.sockconnect('pipe', debug_neovim_conn_add, {rpc = true})
local debug_neovim_conn = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless'}, {rpc = true})


vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':edit test.lua\n', "n", false)

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
vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", [[require"dap".run(...)]], {{type = "nlua", request = "attach", name = "Debug current file", host = server.host, port = server.port}})

vim.wait(2000)
print("Done!")


vim.fn.rpcnotify(host_neovim_conn, "nvim_feedkeys", ':luafile test.lua\n', "n", false)


vim.wait(2000)

-- @next_in_debug_session
-- @step_in_debug_session
vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':lua require"dap".continue()\n', "n", false)
vim.wait(500)

-- @step_out_debug_session
-- @test_hover_debug_session
-- @test_repl
-- @test_pause_session
-- @test_disconnect_session
-- @test_next_over

vim.wait(500)
local output = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", [[return debug_output]], {})

for _, line in ipairs(output) do
  print(line)
end


vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", "vim.api.nvim_buf_delete(0, {force = true})", {})


-- @close_host_neovim_instance
-- @close_debug_neovim_instance

