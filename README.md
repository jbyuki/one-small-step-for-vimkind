# lua-debug.nvim

`lua-debug.nvim` is an **adapter** to debug a running Neovim instance. See the [DAP protocol](https://microsoft.github.io/debug-adapter-protocol/overview) to know more about adapters. It allows you to debug any lua code running in a Neovim instance.

**Disclaimer**: `lua-debug.nvim` has a similar name to [lua-debug](https://github.com/actboy168/lua-debug) but is not affiliated with the latter in any form.

## Install

In addition to installing `lua-debug.nvim`, you will also need a DAP plugin which will allow you to interact with the adapter. There are mainly two available:

  * [nvim-dap](https://github.com/mfussenegger/nvim-dap)
  * [vimspector](https://github.com/puremourning/vimspector) 

## Configuration

Add these lines to work with [nvim-dap](https://github.com/mfussenegger/nvim-dap).

```lua
local dap = require"dap"
dap.configurations.lua = { 
  { 
    type = 'nlua', 
    request = 'attach',
    name = "Attach to running Neovim instance",
    host = function()
      local value = vim.fn.input('Host [127.0.0.1]: ')
      if value ~= "" then
        return value
      end
      return '127.0.0.1'
    end,
    port = function()
      local val = tonumber(vim.fn.input('Port: '))
      assert(val, "Please provide a port number")
      return val
    end,
  }
}

dap.adapters.nlua = function(callback, config)
  callback({ type = 'server', host = config.host, port = config.port })
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
* [x] stepIn
* [x] next
* [x] stepOut
* [x] continue
* [x] evaluate
* [ ] pause
* [ ] terminate
* [ ] disconnect
* [ ] setVariable
* [ ] setFunctionBreakpoints
* [ ] setExceptionBreakpoints
* [ ] breakpointLocations

Events:

* [x] initialized
* [x] stopped
* [ ] terminated
* [ ] exited
* [ ] output

Capabilities:

* [ ] variableReferences
* [ ] condition
* [ ] watch
* [ ] hover

## Credits

* [mfussenegger/nvim-lua-debugger](https://github.com/mfussenegger/nvim-lua-debugger)
