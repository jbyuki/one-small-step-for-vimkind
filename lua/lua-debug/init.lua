-- Generated from attach.lua.tl, breakpoint_hit.lua.tl, continue.lua.tl, disconnect.lua.tl, evaluate.lua.tl, init.lua.tl, initialize.lua.tl, launch.lua.tl, log_remote.lua.tl, message_loop.lua.tl, next.lua.tl, pause.lua.tl, receive.lua.tl, scopes.lua.tl, send.lua.tl, server.lua.tl, set_breakpoints.lua.tl, stack_trace.lua.tl, step_in.lua.tl, step_out.lua.tl, threads.lua.tl, variables.lua.tl using ntangle.nvim
local limit = 0

local running = true

local seq_id = 1

local nvim_server

local stack_level = 0
local next = false
local monitor_stack = false

local pause = false

local vars_id = 1
local vars_ref = {}

-- for now, only accepts a single
-- connection
local client

local debug_hook_conn 

local frame_id = 1
local frames = {}

local step_in

local step_out = false

local make_response

local make_event

local log

local sendProxyDAP

local M = {}
function make_response(request, response)
  local msg = {
    type = "response",
    seq = seq_id,
    request_seq = request.seq,
    success = true,
    command = request.command
  }
  seq_id = seq_id + 1
  return vim.tbl_extend('error', msg, response)
end

function make_event(event)
  local msg = {
    type = "event",
    seq = seq_id,
    event = event,
  }
  seq_id = seq_id + 1
  return msg
end

function M.launch(opts)
  vim.validate {
    opts = {opts, 't', true}
  }
  
  if opts then
    vim.validate {
      ["opts.host"] = {opts.host, "s", true},
      ["opts.port"] = {opts.port, "n", true},
    }
  end

  nvim_server = vim.fn.jobstart({'nvim', '--embed', '--headless'}, {rpc = true})
  
  local hook_address = vim.fn.serverstart()
  vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[debug_hook_conn_address = ...]], {hook_address})
  
  local host = (opts and opts.host) or "127.0.0.1"
  local port = (opts and opts.port) or 0
  local server = vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[return require"lua-debug".start_server(...)]], {host, port})
  
  log("Server started on port " .. server.port)
  vim.defer_fn(M.wait_attach, 0)
  return server
end

function M.wait_attach()
  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    local has_attach = false
    for _,msg in ipairs(M.server_messages) do
      if msg.command == "attach" then
        has_attach = true
      end
    end
    
    if not has_attach then return end
    timer:close()

    local handlers = {}
    local breakpoints = {}
    
    function handlers.attach(request)
      sendProxyDAP(make_response(request, {}))
    end
    
    
    function handlers.continue(request)
      running = true
      
      sendProxyDAP(make_response(request,{}))
    end
    
    function handlers.disconnect(request)
      debug.sethook()
      
      sendProxyDAP(make_response(request, {}))
      
      vim.wait(1000)
      if nvim_server then
        vim.fn.jobstop(nvim_server)
        nvim_server = nil
      end
    end
    
    function handlers.evaluate(request)
      local args = request.arguments
      if args.context == "repl" then
        local frame = frames[args.frameId]
        -- what is this abomination...
        --              a former c++ programmer
        local a = 1
        local prev
        local cur = {}
        local first = cur
        
        while true do
          local succ, ln, lv = pcall(debug.getlocal, frame+1, a)
          if not succ then
            break
          end
        
          if not ln then
            prev = cur
        
            cur = {}
            setmetatable(prev, {
              __index = cur
            })
        
            frame = frame + 1
            a = 1
          else
            cur[ln] = lv
            a = a + 1
          end
        end
        
        setmetatable(cur, {
          __index = _G
        })
        
        local succ, f = pcall(loadstring, "return " .. args.expression)
        if succ and f then
          setfenv(f, first)
        end
        
        local result_repl
        if succ then
          succ, result_repl = pcall(f)
        else
          result_repl = f
        end
        
        sendProxyDAP(make_response(request, {
          body = {
            result = vim.inspect(result_repl),
            variablesReference = 0,
          }
        }))
      else
        log("evaluate context " .. args.context .. " not supported!")
      end
    end
    
    function handlers.next(request)
      local depth = 0
      while true do
        local info = debug.getinfo(depth+3, "S")
        if not info then
          break
        end
        depth = depth + 1
      end
      stack_level = depth-1
      
      next = true
      monitor_stack = true
      
      running = true
      
      sendProxyDAP(make_response(request, {}))
    end
    
    function handlers.pause(request)
      pause = true
      
    end
    
    function handlers.scopes(request)
      local args = request.arguments
      local frame = frames[args.frameId]
      if not frame then 
        log("Frame not found!")
        return 
      end
    
    
      local scopes = {}
    
      local a = 1
      local local_scope = {}
      local_scope.name = "Locals"
      local_scope.presentationHint = "locals"
      local_scope.variablesReference = vars_id
      local_scope.expensive = false
      
      vars_ref[vars_id] = frame
      vars_id = vars_id + 1
      
      table.insert(scopes, local_scope)
    
      sendProxyDAP(make_response(request,{
        body = {
          scopes = scopes,
        };
      }))
    end
    
    function handlers.setBreakpoints(request)
      local args = request.arguments
      for line, line_bps in pairs(breakpoints) do
        line_bps[args.source.path:lower()] = nil
      end
      local results_bps = {}
      
      for _, bp in ipairs(args.breakpoints) do
        breakpoints[bp.line] = breakpoints[bp.line] or {}
        local line_bps = breakpoints[bp.line]
        line_bps[args.source.path:lower()] = true
        table.insert(results_bps, { verified = true })
        -- log("Set breakpoint at line " .. bp.line .. " in " .. args.source.path)
      end
      
      sendProxyDAP(make_response(request, {
        body = {
          breakpoints = results_bps
        }
      }))
      
      
    end
    
    function handlers.stackTrace(request)
      local args = request.arguments
      local start_frame = args.startFrame or 0
      local max_levels = args.levels or -1
      
    
      local stack_frames = {}
      local levels = 1
      while levels <= max_levels or max_levels == -1 do
        local info = debug.getinfo(2+levels+start_frame)
        if not info then
          break
        end
      
        local stack_frame = {}
        stack_frame.id = frame_id
        stack_frame.name = info.name or info.what
        if info.source:sub(1, 1) == '@' then
          stack_frame.source = {
            name = info.source,
            path = vim.fn.fnamemodify(info.source:sub(2), ":p"),
          }
          stack_frame.line = info.currentline 
          stack_frame.column = 0
        end
        table.insert(stack_frames, stack_frame)
        frames[frame_id] = 2+levels+start_frame
        frame_id = frame_id + 1
      
        levels = levels + 1
      end
      
    
      sendProxyDAP(make_response(request,{
        body = {
          stackFrames = stack_frames,
          totalFrames = #stack_frames,
        };
      }))
    end
    
    function handlers.stepIn(request)
      step_in = true
      
      running = true
      
    
      sendProxyDAP(make_response(request,{}))
      
    end
    
    function handlers.stepOut(request)
      step_out = true
      monitor_stack = true
      
      local depth = 0
      while true do
        local info = debug.getinfo(depth+3, "S")
        if not info then
          break
        end
        depth = depth + 1
      end
      stack_level = depth-1
      
      running = true
      
    
      sendProxyDAP(make_response(request, {}))
      
    end
    
    function handlers.threads(request)
      sendProxyDAP(make_response(request, {
        body = {
          threads = {
            {
              id = 1,
              name = "main"
            }
          }
        }
      }))
    end
    function handlers.variables(request)
      local args = request.arguments
    
      local ref = vars_ref[args.variablesReference]
      local variables = {}
      if type(ref) == "number" then
        local a = 1
        local frame = ref
        while true do
          local ln, lv = debug.getlocal(frame, a)
          if not ln then
            break
          end
        
          if vim.startswith(ln, "(*") then
          
          else
            local v = {}
            v.name = ln
            v.variablesReference = 0
            if type(lv) == "table" then
              vars_ref[vars_id] = lv
              v.variablesReference = vars_id
              vars_id = vars_id + 1
              
            end
            v.value = tostring(lv) 
            
            table.insert(variables, v)
          end
          a = a + 1
        end
        
      elseif type(ref) == "table" then
        for ln, lv in pairs(ref) do
            local v = {}
            v.name = ln
            v.variablesReference = 0
            if type(lv) == "table" then
              vars_ref[vars_id] = lv
              v.variablesReference = vars_id
              vars_id = vars_id + 1
              
            end
            v.value = tostring(lv) 
            
            table.insert(variables, v)
        end
      end
    
      sendProxyDAP(make_response(request, {
        body = {
          variables = variables,
        }
      }))
    end
    
    debug.sethook(function(event, line)
      local i = 1
      while i <= #M.server_messages do
        local msg = M.server_messages[i]
        local f = handlers[msg.command]
        if f then
          f(msg)
        else
          log("Could not handle " .. msg.command)
        end
        i = i + 1
      end
      
      M.server_messages = {}
      
    
      local depth = 0
      if monitor_stack then
        while true do
          local info = debug.getinfo(depth+3, "S")
          if not info then
            break
          end
          depth = depth + 1
        end
      end
    
      local bps = breakpoints[line]
      if event == "line" and bps then
        local info = debug.getinfo(2, "S")
        local source_path = info.source
        
        if source_path:sub(1, 1) == "@" or step_in then
          local path = source_path:sub(2)
          path = vim.fn.fnamemodify(path, ":p"):lower()
          if bps[path] then
            local msg = make_event("stopped")
            msg.body = {
              reason = "breakpoint",
              threadId = 1
            }
            sendProxyDAP(msg)
            running = false
            while not running do
              local i = 1
              while i <= #M.server_messages do
                local msg = M.server_messages[i]
                local f = handlers[msg.command]
                if f then
                  f(msg)
                else
                  log("Could not handle " .. msg.command)
                end
                i = i + 1
              end
              
              M.server_messages = {}
              
              vim.wait(50)
            end
            
          end
        end
        
      
      elseif event == "line" and step_in then
        local msg = make_event("stopped")
        msg.body = {
          reason = "step",
          threadId = 1
        }
        sendProxyDAP(msg)
        step_in = false
        
      
        running = false
        while not running do
          local i = 1
          while i <= #M.server_messages do
            local msg = M.server_messages[i]
            local f = handlers[msg.command]
            if f then
              f(msg)
            else
              log("Could not handle " .. msg.command)
            end
            i = i + 1
          end
          
          M.server_messages = {}
          
          vim.wait(50)
        end
        
      
      elseif event == "line" and next and depth == stack_level then
        local msg = make_event("stopped")
        msg.body = {
          reason = "step",
          threadId = 1
        }
        sendProxyDAP(msg)
        next = false
        monitor_stack = false
        
      
        running = false
        while not running do
          local i = 1
          while i <= #M.server_messages do
            local msg = M.server_messages[i]
            local f = handlers[msg.command]
            if f then
              f(msg)
            else
              log("Could not handle " .. msg.command)
            end
            i = i + 1
          end
          
          M.server_messages = {}
          
          vim.wait(50)
        end
        
      
      elseif event == "line" and step_out and stack_level-1 == depth then
        local msg = make_event("stopped")
        msg.body = {
          reason = "step",
          threadId = 1
        }
        sendProxyDAP(msg)
        step_out = false
        monitor_stack = false
        
      
        running = false
        while not running do
          local i = 1
          while i <= #M.server_messages do
            local msg = M.server_messages[i]
            local f = handlers[msg.command]
            if f then
              f(msg)
            else
              log("Could not handle " .. msg.command)
            end
            i = i + 1
          end
          
          M.server_messages = {}
          
          vim.wait(50)
        end
        
      elseif event == "line" and pause then
        pause = false
        
        local msg = make_event("stopped")
        msg.body = {
          reason = "pause",
          threadId = 1
        }
        sendProxyDAP(msg)
        running = false
        while not running do
          local i = 1
          while i <= #M.server_messages do
            local msg = M.server_messages[i]
            local f = handlers[msg.command]
            if f then
              f(msg)
            else
              log("Could not handle " .. msg.command)
            end
            i = i + 1
          end
          
          M.server_messages = {}
          
          vim.wait(50)
        end
        
      
      end
    end, "clr")
    
  end))
end

function log(str)
  if debug_output then
    table.insert(debug_output, tostring(str))
  else
    print(str)
  end
end
M.server_messages = {}
function M.sendDAP(msg)
  local succ, encoded = pcall(vim.fn.json_encode, msg)
  
  if succ then
    local bin_msg = "Content-Length: " .. string.len(encoded) .. "\r\n\r\n" .. encoded
    
    client:write(bin_msg)
  else
    log(encoded)
  end
end

function M.start_server(host, port)
  local server = vim.loop.new_tcp()
  
  server:bind(host, port)
  
  server:listen(128, function(err)
    local sock = vim.loop.new_tcp()
    server:accept(sock)
    
    local tcp_data = ""
    
  
    client = sock
  
    local function read_body(length)
      while string.len(tcp_data) < length do
        coroutine.yield()
      end
    
      local body = string.sub(tcp_data, 1, length)
      local succ, decoded = pcall(vim.fn.json_decode, body)
      
      tcp_data = string.sub(tcp_data, length+1)
      
    
      return decoded
    end
    
    local function read_header()
      while not string.find(tcp_data, "\r\n\r\n") do
        coroutine.yield()
      end
      local content_length = string.match(tcp_data, "^Content%-Length: (%d+)")
      
      local _, sep = string.find(tcp_data, "\r\n\r\n")
      tcp_data = string.sub(tcp_data, sep+1)
      
    
      return {
        content_length = tonumber(content_length),
      }
    end
    
    local dap_read = coroutine.create(function()
      local msg
      do
        local len = read_header()
        msg = read_body(len.content_length)
      end
      
      M.sendDAP(make_response(msg, {
        body = {}
      }))
      
      M.sendDAP(make_event('initialized'))
    
      while true do
        local msg
        do
          local len = read_header()
          msg = read_body(len.content_length)
        end
        
        if debug_hook_conn then
          vim.fn.rpcrequest(debug_hook_conn, "nvim_exec_lua", [[table.insert(require"lua-debug".server_messages, ...)]], {msg})
        end
        
      end
    end)
    
    sock:read_start(vim.schedule_wrap(function(err, chunk)
      if chunk then
        tcp_data = tcp_data .. chunk
        coroutine.resume(dap_read)
        
      else
        sock:shutdown()
        sock:close()
      end
    end))
    
  end)
  
  log("Server started on " .. server:getsockname().port)
  
  if debug_hook_conn_address then
    debug_hook_conn = vim.fn.sockconnect("pipe", debug_hook_conn_address, {rpc = true})
  end
  

  return {
    host = host,
    port = server:getsockname().port
  }
end

function sendProxyDAP(data)
  vim.fn.rpcnotify(nvim_server, 'nvim_exec_lua', [[require"lua-debug".sendDAP(...)]], {data})
end

return M
