##test-connect
@*=
vim.api.nvim_command([[edit test.lua]])
vim.api.nvim_win_set_cursor(0, {2, 0})
require"dap".toggle_breakpoint()
local server = require"osv".launch()
vim.wait(1000)
print(server.host)
print(server.port)
require"dap".run({
  type = "nlua",
  request = "attach",
  host = server.host,
  port = server.port,
})
vim.wait(1000)
