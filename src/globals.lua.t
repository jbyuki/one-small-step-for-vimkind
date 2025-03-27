##lua-debug
@script_variables-=
local uv = vim.uv or vim.loop
local json_encode, json_decode = vim.json.encode, vim.json.decode
local rpcrequest, rpcnotify = vim.rpcrequest, vim.rpcnotify
