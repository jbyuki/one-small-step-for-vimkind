local conn = vim.fn.jobstart({'nvim', '--embed', '--headless'}, {rpc = true})
vim.fn.rpcrequest(conn, "nvim_exec_lua", [[events = {}]], {})
vim.fn.rpcrequest(conn, "nvim_exec_lua", [[debug.sethook(function(event, line) if line == 2 then table.insert(events, {line, debug.getinfo(2, 'S')}) end end, "l")]], {})
local results = vim.fn.rpcrequest(conn, "nvim_exec", [[luafile test4.lua]], true)
local events = vim.fn.rpcrequest(conn, "nvim_exec_lua", [[return events]], {})
print(vim.inspect(results))
for _, el in ipairs(events) do
  print(vim.inspect(el[2]))
end
vim.fn.jobstop(conn)
