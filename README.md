# one-small-step-for-vimkind


`one-small-step-for-vimkind` a.k.a. `osv` is an **adapter** for the Neovim lua language. See the [DAP protocol](https://microsoft.github.io/debug-adapter-protocol/overview) to know more about adapters. It allows you to debug any lua code running in a Neovim instance.

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
  }
}

dap.adapters.nlua = function(callback, config)
  callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
end
```

Set keybindings to interact with the nvim-dap client.

```lua
vim.keymap.set('n', '<leader>db', require"dap".toggle_breakpoint, { noremap = true })
vim.keymap.set('n', '<leader>dc', require"dap".continue, { noremap = true })
vim.keymap.set('n', '<leader>do', require"dap".step_over, { noremap = true })
vim.keymap.set('n', '<leader>di', require"dap".step_into, { noremap = true })

vim.keymap.set('n', '<leader>dl', function() 
  require"osv".launch({port = 8086}) 
end, { noremap = true })

vim.keymap.set('n', '<leader>dw', function()
  local widgets = require"dap.ui.widgets"
  widgets.hover()
end)

vim.keymap.set('n', '<leader>df', function()
  local widgets = require"dap.ui.widgets"
  widgets.centered_float(widgets.frames)
end)
```

## Quickstart

* Launch the server in the debuggee using `<leader>dl`
* Open another Neovim instance with the source file
* Place breakpoint with `<leader>db`
* Connect using the DAP client with `<leader>dc`
* Run your script/plugin in the debuggee

Alternaltively you can:

* Open a lua file
* Place breakpoint
* Invoke `require"osv".run_this()`

See [osv.txt](https://github.com/jbyuki/lua-debug.nvim/blob/main/doc/osv.txt) for more detailed instructions.

## Debug configuration files

It is now possible to debug configuration files (ex. `init.lua`).
See the corresponding section in [osv.txt](https://github.com/jbyuki/lua-debug.nvim/blob/main/doc/osv.txt#L198).

## Troubleshoot

### `flatten.nvim`

Set `nest_if_no_args` to true. See [this issue](https://github.com/willothy/flatten.nvim/issues/41) for more informations.

### `fzf-lua`

Under special circumstances, the headless instance can fail. See [this issue](https://github.com/jbyuki/one-small-step-for-vimkind/issues/45#issuecomment-2125749906) for more details.

### Debugging plugins

Breakpoints are path-sensitive so they should always be set in the executed file
even though they might be multiple copies on the system.

This is the case for [packer.nvim](https://github.com/wbthomason/packer.nvim) when developing
local plugins. packer.nvim will create a symlink to the plugins files in the `nvim-data` directory (
it can be located using `:echo stdpath('data')`). Make sure to set the breakpoints inside 
the source files in the `nvim-data` directory and not the local copy. The plugin directory
can be found in `nvim-data/site/pack/packer/start/YOUR_PLUGIN`.

See [osv.txt](https://github.com/jbyuki/lua-debug.nvim/blob/main/doc/osv.txt) for more detailed instructions.

### Dropbox

If you're using a service like Dropbox to share your plugin file, there might be some issue arising with osv. The reason is that the path executed within Neovim and the path opened in dap doesn't match. Consequently, osv has no way to know if the current running script is the same file as the file opened inside the dap client. Try falling back to a local folder to see if this is the cause.

### `Neovim is waiting for input at startup. Aborting`

This appears when the osv's spawned headless neovim instance has an error at startup. Vim will usually wait for an user input but in case of osv, the instance is simply blocked. Resolve any errors that you see at startup. If there are none, the error might be due to the "headlessness". Start using `nvim --headless` to see if there are any errors.

### Breakpoint is not hit

**Important** : Make sure osv is not running.

1. Start tracing with `:lua require"osv".start_trace()`
2. Perform the action that should be debugged (for ex. calling a function in your plugin)
3. Stop tracing and display the results with `:lua =require"osv".stop_trace()` , the `=` will pretty print the resulting lua table.

Make sure that the path is correct and the breakpoint is set to a line which effectively gets executed.

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
* [x] setVariable
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

* [x] supportsConditionalBreakpoints
* [x] supportsHitConditionalBreakpoints
* [x] supportsSetVariable
* [x] supportTerminateDebuggee

## Name

> it's a debugger for the moon language. - @tjdevries

## Plugin architecture

Please refer to [ARCHITECTURE.md](ARCHITECTURE.md).

## Credits

* [mfussenegger/nvim-lua-debugger](https://github.com/mfussenegger/nvim-lua-debugger)

## Alternatives

* For an adapter limited to expression evaluation, see [mfussenegger/nluarepl](https://github.com/mfussenegger/nluarepl).
 
## Contribute

See [here](https://github.com/jbyuki/ntangle.nvim/wiki/How-to-use-ntangle.nvim).
