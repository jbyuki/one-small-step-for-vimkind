# one-small-step-for-vimkind


`one-small-step-for-vimkind` is an **adapter** for the Neovim lua language. See the [DAP protocol](https://microsoft.github.io/debug-adapter-protocol/overview) to know more about adapters. It allows you to debug any lua code running in a Neovim instance.

## Install

After installing `one-small-step-for-vimkind`, you will also need a DAP plugin which will allow you to interact with the adapter. There are mainly two available:

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

## Quickstart

* Launch the server in the debuggee using `require"osv".launch()`
* Open another Neovim instance with the source file
* Place breakpoint
* Connect using the DAP client
* Run your script/plugin in the debuggee

Alternaltively you can:

* Open a lua file
* Place breakpoint
* Invoke `require"osv".run_this()`

See [osv.txt](https://github.com/jbyuki/lua-debug.nvim/blob/main/doc/osv.txt) for more detailed instructions.

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
* [x] pause
* [ ] terminate
* [x] disconnect
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

* [x] variableReferences
* [ ] condition
* [ ] hit condition
* [ ] watch
* [ ] hover

## Name

> it's a debugger for the moon language. - @tjdevries

## Credits

* [mfussenegger/nvim-lua-debugger](https://github.com/mfussenegger/nvim-lua-debugger)
