# lua-debug.nvim

`lua-debug.nvim` is an **adapter** to debug a running Neovim instance. See the [DAP protocol](https://microsoft.github.io/debug-adapter-protocol/overview) to know more about adapters. It allows you to debug any lua code running in a Neovim instance. This means it can be used to debug running plugins.

## Install

In addition to installing `lua-debug.nvim`, you will also need a DAP plugin which will allow you to interact with the adapter. There are mainly two available:

  * [nvim-dap](https://github.com/mfussenegger/nvim-dap) (recommanded)
  * [vimspector](https://github.com/puremourning/vimspector) 

See the project respective pages for additionnal configurations.

## Configuration

Add these lines to work with [nvim-dap](https://github.com/mfussenegger/nvim-dap).

```lua
local dap = require"dap"
dap.configurations.lua = { 
  { 
    type = 'nlua', 
    request = 'attach',
    name = "Attach to running Neovim instance",
  }
}

dap.adapters.nlua = function(callback, config)
  local server = require"lua-debug".launch()
  callback({ type = 'server', host = server.host, port = server.port })
end
```

## Status

Handlers:

* [x] attach
* [x] scope
* [x] setBreakpoints
* [x] stackTrace
* [x] threads
* [x] variables

Events:

* [x] initialized
* [x] stopped

Status: **Not working yet!**

## Credits

* [mfussenegger/nvim-lua-debugger](https://github.com/mfussenegger/nvim-lua-debugger)
