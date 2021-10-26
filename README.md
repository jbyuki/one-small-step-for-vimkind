# one-small-step-for-vimkind


`one-small-step-for-vimkind` is an **adapter** for the Neovim lua language. See the [DAP protocol](https://microsoft.github.io/debug-adapter-protocol/overview) to know more about adapters. It allows you to debug any lua code running in a Neovim instance.

## Install

Install using your prefered method for example using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'jbyuki/one-small-step-for-vimkind'

" You will also need a comptabile DAP client

Plug 'mfussenegger/nvim-dap'
```

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

If you have a init.vim in Vimscript, include the nvim-dap
configurations inside lua delimiters.

```vim
lua << END
  ...
END
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

## Debugging plugins

Breakpoints are path-sensitive so they should always be set in the executed file
even though they might be multiple copies on the system.

This is the case for [packer.nvim](https://github.com/wbthomason/packer.nvim) when developing
local plugins. packer.nvim will create a symlink to the plugins files in the `nvim-data` directory (
it can be located using `:echo stdpath('data')`). Make sure to set the breakpoints inside 
the source files in the `nvim-data` directory and not the local copy. The plugin directory
can be found in `nvim-data/site/pack/packer/start/YOUR_PLUGIN`.

See [osv.txt](https://github.com/jbyuki/lua-debug.nvim/blob/main/doc/osv.txt) for more detailed instructions.

## Dropbox

If you're using a service like Dropbox to share your plugin file, there might be some issue arising with osv. The reason is that the path executed within Neovim and the path opened in dap doesn't match. Consequently, osv has no way to know if the current running script is the same file as the file opened inside the dap client. Try falling back to a local folder to see if this is the cause.

### `Neovim is waiting for input at startup. Aborting`

This appears when the osv's spawned headless neovim instance has an error at startup. Vim will usually wait for an user input but in case of osv, the instance is simply blocked. Resolve any errors that you see at startup. If there are none, the error might be due to the "headlessness". Start using `nvim --headless` to see if there are any errors.
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
* [x] terminated
* [x] exited
* [ ] output

Capabilities:

* [x] variableReferences
* [ ] condition
* [ ] hit condition
* [ ] watch
* [ ] hover

## Name

> it's a debugger for the moon language. - @tjdevries

## Plugin architecture

Please refer to [ARCHITECTURE.md](ARCHITECTURE.md).

## Credits

* [mfussenegger/nvim-lua-debugger](https://github.com/mfussenegger/nvim-lua-debugger)
 
## Contribute

See [here](https://github.com/jbyuki/ntangle.nvim/wiki/How-to-use-ntangle.nvim).
