-- Generated using ntangle.nvim
-- local host_neovim_conn_add = [[\\.\pipe\nvim-21064-0]]
-- local host_neovim_conn = vim.fn.sockconnect('pipe', host_neovim_conn_add, {rpc = true})
local host_neovim_conn = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless'}, {rpc = true})

vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", [[debug_output = {}]], {})


local server = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", "return require'osv'.launch()", {})
-- vim.fn.rpcnotify(host_neovim_conn, "nvim_exec_lua", "require'osv'.wait_attach()", {})


-- local debug_neovim_conn_add = [[\\.\pipe\nvim-9368-0]]
-- local debug_neovim_conn = vim.fn.sockconnect('pipe', debug_neovim_conn_add, {rpc = true})
local debug_neovim_conn = vim.fn.jobstart({vim.v.progpath, '--embed', '--headless'}, {rpc = true})


vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", [[require"dap".configurations.lua = {...  }]], { { type = 'nlua', request = 'attach', name = "Attach to running Neovim instance", host = server.host, port = server.port } })
vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", [[require"dap".adapters.nlua = function(callback, config) callback({ type = 'server', host = config.host, port = config.port }) end]], {})



vim.fn.rpcnotify(debug_neovim_conn, "nvim_feedkeys", ':edit input.lua\n', "n", false)

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


local result = vim.fn.rpcnotify(host_neovim_conn, "nvim_exec", [[luafile input.lua]], true)
print(vim.inspect(result))


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

vim.wait(500)
local output = vim.fn.rpcrequest(host_neovim_conn, "nvim_exec_lua", [[return debug_output]], {})

for _, line in ipairs(output) do
  print(line)
end

local found = false
for _, line in ipairs(output) do
  if line == "breakpoint hit" then
    found = true
    break
  end
end
assert(found, "breakpoint not hit")


vim.fn.rpcrequest(debug_neovim_conn, "nvim_exec_lua", "vim.api.nvim_buf_delete(...)", {0, {force = true}})


if host_neovim_conn then
  vim.fn.jobstop(host_neovim_conn)
  host_neovim = nil
end

if debug_neovim_conn then
  vim.fn.jobstop(debug_neovim_conn)
  debug_neovim_conn = nil
end


local f = io.open("result.txt", "w")
f:write("OK")
f:close()
print("OK!")

