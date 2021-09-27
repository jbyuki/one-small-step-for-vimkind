Software architecture of `osv`
==============================

This document was created to still give a "easy" to
understand explanation because the plugin's inner workings
are probably hard to understand only by reading code.

This should give "something" to work with if you plan to
make modifications to the code, make your own debugger or
 any other purpose involving `osv`.

Terminology:

  *  debbugee (i.e. the process which will be debugged )
  *  debugger client (i.e. the process where the debugger is running)                                   

Launching
---------

```
                      DEBUGGEE              
                ┌────────────────────┐
                │                    │             
    launch()    │   ┌───────────┐    │            DAP SERVER
   ────────────────►│spawn nvim │────────────► ┌──────────────────┐
                │   └─────┬─────┘    │         │                  │
                │         │          │         │                  │
                │         ▼          │         │                  │
                │┌──────────────────┐│         │                  │
                ││serverstart()     ││         │                  │
                ││                  ││ pass    │                  │
                ││generate server   ├───────────►┌──────────────┐ │
                ││address           ││ address │ │set address   │ │
                │└──────────────────┘│         │ │    in        │ │
                │         │          │        debug_hook_conn_address
                │         │          │         │ │              │ │
                │         │          │         │ │              │ │
                │         │          │         │ └──────────────┘ │
                │         │          │         │                  │
                │         ▼          │         │                  │
                │┌──────────────────┐│         │                  │ 
                ││start server in   ├───────────►┌──────────────┐ │
                ││   dap server     ││         │ │    start     │ │
                │└──────────────────┘│         │ │ TCP server   │ │
                │                    │         │ └──────┬───────┘ │
                │                    │         │        │         │
                │                    │         │        ▼         │
                │                    │         │ ┌──────────────┐ │
                │                    │         │ │ sockconnect  │ │
                │                    │◄══════════│    back      │ │
                │                    │         │ │ to debuggee  │ │
                │                    │         │ │    with      │ │
                │                    │        debug_hook_conn_address
                │                    │         │ └──────────────┘ │
                │                    │         │                  │
                └────────────────────┘         └──────────────────┘
```

* The diagrams were drawn using [venn.nvim](https://github.com/jbyuki/venn.nvim).

Message handling
----------------

Notes:

  * [debug.sethook](https://www.lua.org/pil/23.2.html) allows to register a callback which will be called whenever a new lua line is executed, a call or a return is made.

```
                   DEBUGGEE                     DAP server
               ┌──────────────────┐           ┌────────────────┐
               │┌───────────────┐ │           │                │ incoming
               ││debug.sethook  │ │           │ ┌───────────┐ ◄───────────
               ││sents an event │ │           │ │ message   │  │ DAP message
               ││(line, call,   │ │           │ │ read by   │  │
               ││ return)       │ │           │ │ TCP server│  │
               │└───────────────┘ │           │ └───────────┘  │
               │  │               │           │       │        │
               │  ▼               │           │       │        │
               │┌─────────────┐   │           │       │        │
               ││check        │   │           │       │        │
               ││messages in  │   │           │       │        │
               ││M.server_messages│           │       │        │
               │└─┬──┬────────┘   │           │       ▼        │
               │NO│  │YES         │           │┌──────────────┐│
               │  │  └─► handle it│           ││insert message││
               │  │      │        │◄═══════════╡ into debuggee││
               │  │      │if      │           ││using RPC     ││
               │  │      │breakpoint          ││ socket in    ││
               │  │      ▼        │           ││M.server_messages
               │  ▼  ┌──────────┐ │           │└──────────────┘│
               │     │ frozen   │ │           │                │
               │     │  state   │ │           │                │
               │     └──────────┘ │           │                │
               └──────────────────┘           └────────────────┘

```

Frozen
------

* neovim is single-threaded.  By going into a loop
it stops any execution. Even when calling `vim.wait`,
neovim won't execute other any other lua code in the
idle time. Note: This is not entierly true since code
inside _fast-api_ calls can still be executed.

```

                   DEBUGGEE                      DAP server
               ┌──────────────────┐           ┌────────────────┐
               │                  │           │                │ incoming
               │    message loop  │           │ ┌───────────┐ ◄───────────
               │  ┌─────────────┐ │           │ │ message   │  │ DAP message
               │  ▼             │ │           │ │  read by  │  │
               │┌─────────────┐ │ │           │ │TCP server │  │
               ││check        │ │ │           │ └───────────┘  │
               ││messages in  │   │           │       │        │
               ││M.server_messages│           │       │        │
               │└─┬──┬────────┘   │           │       ▼        │
               │NO│  │YES         │           │┌──────────────┐│
               │  │  └─► handle it│           ││insert message││
               │  │               │◄═══════════╡ into debuggee││
               │  │   if     │  │ │           ││using RPC     ││
               │  │   continue  │ │           ││ socket in    ││
               │  │   msg    │  │ │           ││M.server_messages
               │  ▼          │  │ │           │└──────────────┘│
               │┌──────────┐ │  │ │           │                │
               ││vim.wait  │─│──┘ │           │                │
               │└──────────┘ │    │           │                │
               │             │    │           │                │
               │  ┌──────────┘    │           │                │
               │  │ break out     │           │                │
               │  ▼ of loop       │           │                │
               │                  │           │                │
               └──────────────────┘           └────────────────┘
```

Source code
-----------

For more detailed informations please refer to the source
code available in [src/](https://github.com/jbyuki/one-small-step-for-vimkind/tree/main/src). All the sources are written using [ntangle.nvim](https://github.com/jbyuki/ntangle.nvim). Please look at the plugin's documentation for the syntax and how sources are organised.
