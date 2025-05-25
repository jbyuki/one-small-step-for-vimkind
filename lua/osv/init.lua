-- Generated using ntangle.nvim
local running = true

local builtin_debug_traceback
local break_on_exception

local exception_error_msg = nil

local exception_stacktrace

local limit = 0

local stack_level = 0
local next = false
local monitor_stack = false

local pause = false

local vars_id = 1
local vars_ref = {}

local frame_id = 1
local frames = {}

local step_in

local step_out = false

local seq_id = 1

local nvim_server

local hook_address

local log_filename

local lock_debug_loop = false

local skip_monitor = false
local skip_monitor_same_depth = false

local head_start_depth = -1

local redir_nvim_output = false
local nvim_exec2_opts = {}

local exit_autocmd

local auto_nvim

-- for now, only accepts a single
-- connection
local client

local debug_hook_conn 

local is_attached = false

local cache = {}

local start_profiler
local stop_profiler
local get_profiler_result
local start_time = {}
local profiler_result = {}
local profiler_max = {}
local disable_profiler = false

local sendProxyDAP

local make_response

local make_event

local log

local M = {}
function M.print_profiler()
  if not disable_profiler then
    disable_profiler = true
    for section, results in pairs(profiler_result) do
      local msg_chunks = {}
      local sorted = vim.deepcopy(results, true)
      table.sort(sorted)
      local top = math.min(5, #sorted)
      local threshold = sorted[#sorted-(top-1)]

      table.insert(msg_chunks, {("[%s]: "):format(section), "Normal"})

      for _, result in ipairs(results) do
        if result >= threshold then
          table.insert(msg_chunks, {("%.2f "):format(result), "WarningMsg"})
        else
          table.insert(msg_chunks, {("%.2f "):format(result), "Normal"})
        end
      end
      vim.api.nvim_echo(msg_chunks, false, {})
    end
    disable_profiler = false
  else
    vim.api.nvim_echo({{"Profiler was not enabled.", "WarningMsg"}}, false, {})
  end
end

function start_profiler(section)
  if not disable_profiler  then
    start_time[section] = vim.uv.hrtime()
  end
end

function stop_profiler(section)
  if not disable_profiler and start_time[section] then 
    local elapsed = vim.uv.hrtime() - start_time[section] 
    profiler_result[section] = profiler_result[section] or {}
    local results = profiler_result[section]
    table.insert(results, elapsed/1e6)
    while #results > 200 do
      table.remove(results, 1)
    end
  end
end

M.stop_freeze = false

function M.unfreeze()
  if not running then
    M.stop_freeze = true
  end
end

function sendProxyDAP(data)
  vim.fn.rpcnotify(nvim_server, 'nvim_exec_lua', [[require"osv".sendDAP(...)]], {data})
end

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
  vim.validate("opts", opts, 'table', true)

  if opts then
    vim.validate("opts.host", opts.host, 'string', true)
    vim.validate("opts.port", opts.port, 'number', true)
    vim.validate("opts.config_file", opts.config_file, 'string', true)
    vim.validate("opts.output", opts.output, 'boolean', true)
    vim.validate("opts.profiler", opts.profiler, 'boolean', true)


    vim.validate("opts.break_on_exception", opts.break_on_exception, 'boolean', true)

    if opts.output ~= nil then redir_nvim_output = opts.output end
  end
  if opts and opts.profiler then
    disable_profiler = false
  else
    disable_profiler = true
  end

  break_on_exception = opts and opts.break_on_exception
  if break_on_exception == nil then
    break_on_exception = true
  end


  if M.is_running() then
  	vim.api.nvim_echo({{"Server is already running.", "ErrorMsg"}}, true, {})
    return
  end



  if opts and opts.log then
    log_filename = vim.fn.stdpath("data") .. "/osv.log"
  end

  if M.on["start_server"] then
    nvim_server = M.on["start_server"](args, env)
    assert(nvim_server)


  else
    local clean_args = { vim.v.progpath, '-u', 'NONE', '-i', 'NONE', '-n', '--embed', '--headless' }
    nvim_server = vim.fn.jobstart(clean_args, {rpc = true})
    vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', 'vim.o.runtimepath = ...', { vim.o.runtimepath })
    vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', 'vim.o.packpath = ...', { vim.o.packpath })
  end

  local mode = vim.fn.rpcrequest(nvim_server, "nvim_get_mode")
  if mode.blocking then
  	vim.api.nvim_echo({{"Neovim is waiting for input at startup. Aborting.", "ErrorMsg"}}, true, {})
  	if nvim_server then
  		vim.fn.jobstop(nvim_server)
  		log("SERVER TERMINATED")
  	  nvim_server = nil
  	end

  	return
  end

  if not hook_address then
    hook_address = vim.fn.serverstart()
  end

  vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[debug_hook_conn_address = ...]], {hook_address})

  M.server_messages = {}

  local host = (opts and opts.host) or "127.0.0.1"
  local port = (opts and opts.port) or 0
  local server = vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', [[return require"osv".start_server(...)]], {host, port, opts and opts.log})
  if server == vim.NIL then
  	vim.api.nvim_echo({{("Server failed to launch on port %d"):format(port), "ErrorMsg"}}, true, {})
  	if nvim_server then
  		vim.fn.jobstop(nvim_server)
  		log("SERVER TERMINATED")
  	  nvim_server = nil
  	end

  	return
  end

  print("Server started on port " .. server.port)
  M.stop_freeze = false
	exit_autocmd = vim.api.nvim_create_autocmd({"VimLeavePre"}, {
		callback = function(...)
			M.stop()
		end
	})

  if not opts or not opts.blocking then
    vim.schedule(function() M.prepare_attach(false) end)
  else
    M.prepare_attach(true)
  end

  return server
end

function M.prepare_attach(blocking)
  local handlers = {}
  local breakpoints = {}

  local breakpoints_count = {}

  function handlers.attach(request)
    sendProxyDAP(make_response(request, {}))
  end


  function handlers.configurationDone(request)
    sendProxyDAP(make_response(request, {}))
  end

  function handlers.continue(request)
    running = true

    sendProxyDAP(make_response(request,{}))
  end

  function handlers.disconnect(request)
    debug.sethook()

    sendProxyDAP(make_response(request, {}))

  	if request.terminateDebuggee == true then
  		M.stop()
  	end

    skip_monitor = false
    skip_monitor_same_depth = false

    running = true

    limit = 0

    stack_level = 0
    next = false
    monitor_stack = false

    pause = false

    vars_id = 1
    vars_ref = {}

    frame_id = 1
    frames = {}

    step_out = false

    seq_id = 1

    M.stop_freeze = false

    is_attached = false

  	if not request.terminateDebuggee then
  		vim.schedule(function() M.prepare_attach(false) end)
  	end
  end

  function handlers.evaluate(request)
    local args = request.arguments
    if args.context == "repl" then
  		local frame = args.frameId and frames[args.frameId]
      local a = 1
      local prev
      local cur = {}
      local first = cur

      while true do
      	if not frame then break end
        local succ, ln, lv = pcall(debug.getlocal, frame+1, a)
        if not succ then
          break
        end

        if not ln then
      		break
        else
          -- Avoid shadowing of the globals if a local variable is nil
          cur[ln] = lv or vim.NIL
          a = a + 1
        end
      end



  		prev = cur

  		cur = {}
  		setmetatable(prev, {
  			__index = cur
  		})

  		a = 1

  		if frame then
  			local succ, info = pcall(debug.getinfo, frame+1)
  			if succ and info and info.func then
  				local func = info.func
  				local a = 1
  				while true do
  					local succ, ln, lv = pcall(debug.getupvalue, func, a)
  					if not succ then
  						break
  					end

  					if not ln then
  						break
  					else
  						-- Avoid shadowing of the globals if a local variable is nil
  						cur[ln] = lv or vim.NIL
  						a = a + 1
  					end
  				end
  			end
  		end

  		if frame then
  			local succ, info = pcall(debug.getinfo, frame+1)
  			if succ and info and info.func then
  				setmetatable(cur, {
  					__index = getfenv(info.func)
  				})
  			end
  		else
  			local frame = 0

  			while true do 
  				local succ, info = pcall(debug.getinfo, frame+1)
  				if not succ or not info or not info.func then
  					break
  				end
  				frame = frame + 1
  			end

  			local succ, info = pcall(debug.getinfo, frame)
  			if succ and info then
  				setmetatable(cur, {
  					__index = getfenv(info.func)
  				})
  			end
  		end

  		local expr = args.expression
      local succ, f = pcall(loadstring, "return " .. expr)
      if succ and f then
        setfenv(f, first)
      end

      local result_repl
      if succ then
        succ, result_repl = pcall(f)
      else
        result_repl = f
      end

      if result_repl == vim.NIL then
        result_repl = nil 
      end

      local v = {}
      v.result = tostring(result_repl)
      if type(result_repl) == "table" then
        local lv = result_repl
        vars_ref[vars_id] = lv
        v.variablesReference = vars_id
        vars_id = vars_id + 1

      else
        v.variablesReference = 0
      end


      sendProxyDAP(make_response(request, {
        body = v
      }))

  	elseif args.context == "hover" then
  		local frame = args.frameId and frames[args.frameId]
      local a = 1
      local prev
      local cur = {}
      local first = cur

      while true do
      	if not frame then break end
        local succ, ln, lv = pcall(debug.getlocal, frame+1, a)
        if not succ then
          break
        end

        if not ln then
      		break
        else
          -- Avoid shadowing of the globals if a local variable is nil
          cur[ln] = lv or vim.NIL
          a = a + 1
        end
      end



  		prev = cur

  		cur = {}
  		setmetatable(prev, {
  			__index = cur
  		})

  		a = 1

  		if frame then
  			local succ, info = pcall(debug.getinfo, frame+1)
  			if succ and info and info.func then
  				local func = info.func
  				local a = 1
  				while true do
  					local succ, ln, lv = pcall(debug.getupvalue, func, a)
  					if not succ then
  						break
  					end

  					if not ln then
  						break
  					else
  						-- Avoid shadowing of the globals if a local variable is nil
  						cur[ln] = lv or vim.NIL
  						a = a + 1
  					end
  				end
  			end
  		end

  		if frame then
  			local succ, info = pcall(debug.getinfo, frame+1)
  			if succ and info and info.func then
  				setmetatable(cur, {
  					__index = getfenv(info.func)
  				})
  			end
  		else
  			local frame = 0

  			while true do 
  				local succ, info = pcall(debug.getinfo, frame+1)
  				if not succ or not info or not info.func then
  					break
  				end
  				frame = frame + 1
  			end

  			local succ, info = pcall(debug.getinfo, frame)
  			if succ and info then
  				setmetatable(cur, {
  					__index = getfenv(info.func)
  				})
  			end
  		end

  		local expr = args.expression
      local succ, f = pcall(loadstring, "return " .. expr)
      if succ and f then
        setfenv(f, first)
      end

      local result_repl
      if succ then
        succ, result_repl = pcall(f)
      else
        result_repl = f
      end

      if result_repl == vim.NIL then
        result_repl = nil 
      end

      local v = {}
      v.result = tostring(result_repl)
      if type(result_repl) == "table" then
        local lv = result_repl
        vars_ref[vars_id] = lv
        v.variablesReference = vars_id
        vars_id = vars_id + 1

      else
        v.variablesReference = 0
      end


      sendProxyDAP(make_response(request, {
        body = v
      }))

    else
      log("evaluate context " .. args.context .. " not supported!")
    end
  end

  function handlers.exceptionInfo(request)
    sendProxyDAP(make_response(request,{
      body = {
        exceptionId = "",
        breakMode = "always",
        description = exception_error_msg,
        details = {
          message = exception_error_msg,
          stackTrace = exception_stacktrace,
        }
      }
    }))
  end

  function handlers.next(request)
    local depth = 0
    local surface = 0
    local off = 0
    while true do
      local info = debug.getinfo(off, "S")
      if not info then
        break
      end

      local inside_osv = false
      if info.source:sub(1, 1) == '@' and #info.source > 8 and info.source:sub(#info.source-8+1,#info.source) == "init.lua" then
        local source = info.source:sub(2)
        -- local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
        local parent = vim.fs.dirname(source)
        if parent and vim.fs.basename(parent) == "osv" then
          inside_osv = true
        end
      end

      if inside_osv then
        surface = off
      end
      off = off + 1
    end
    head_start_depth = off - 1

    depth = (off - 1) - surface
    stack_level = depth

    next = true
    monitor_stack = true

    skip_monitor = false
    skip_monitor_same_depth = false

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
      line_bps[vim.uri_from_fname(args.source.path:lower())] = nil
    end

    for line, line_bps_count in pairs(breakpoints_count) do
    	line_bps_count[vim.uri_from_fname(args.source.path:lower())] = nil
    end
    local results_bps = {}

    for _, bp in ipairs(args.breakpoints) do
      breakpoints[bp.line] = breakpoints[bp.line] or {}
      local line_bps = breakpoints[bp.line]
    	if bp.condition and bp.hitCondition then
    		breakpoints_count[bp.line] = breakpoints_count[bp.line] or {}
    		local line_bps_count = breakpoints_count[bp.line]
    		line_bps_count[vim.uri_from_fname(args.source.path:lower())] = tonumber(bp.hitCondition)

    		line_bps[vim.uri_from_fname(args.source.path:lower())] = {bp.condition, tonumber(bp.hitCondition)}
    	elseif bp.condition then
    		line_bps[vim.uri_from_fname(args.source.path:lower())] = bp.condition
    	elseif bp.hitCondition then
    		breakpoints_count[bp.line] = breakpoints_count[bp.line] or {}
    		local line_bps_count = breakpoints_count[bp.line]
    		line_bps_count[vim.uri_from_fname(args.source.path:lower())] = tonumber(bp.hitCondition)

    		line_bps[vim.uri_from_fname(args.source.path:lower())] = tonumber(bp.hitCondition)
    	else
    		line_bps[vim.uri_from_fname(args.source.path:lower())] = true
    	end

      table.insert(results_bps, { verified = true })
      -- log("Set breakpoint at line " .. bp.line .. " in " .. args.source.path)
    end

    sendProxyDAP(make_response(request, {
      body = {
        breakpoints = results_bps
      }
    }))


  end

  function handlers.setExceptionBreakpoints(request)
    local args = request.arguments

    -- For now just send back an empty 
    -- answer
    sendProxyDAP(make_response(request, {
      body = {
        breakpoints = {}
      }
    }))
  end
  function handlers.setVariable(request)
  	local args = request.arguments
    local ref = vars_ref[args.variablesReference]

  	local body = {}


    if type(ref) == "number" then
  		local a = 1
  		local frame = ref
  		while true do
  		  local ln, lv = debug.getlocal(frame, a)
  		  if not ln then
  		    break
  		  end

  			if ln == args.name then
  				local succ, f = pcall(loadstring, "return " .. args.value)
  				if succ and f then
  					local val = f()
  					body.value = tostring(val)
  					body.type = type(val)
  					if type(val) == "table" then
  						vars_ref[vars_id] = val
  						body.variablesReference = vars_id
  						vars_id = vars_id + 1
  					else
  						body.variablesReference = 0
  					end

  					debug.setlocal(frame, a, val)

  				end
  		  end
  		  a = a + 1
  		end

  	elseif type(ref) == "table" then
  		local succ, val = pcall(loadstring, "return " .. args.value)
  		if succ and f then
  			local val = f()
  			body.value = tostring(val)
  			body.type = type(val)
  			if type(val) == "table" then
  				vars_ref[vars_id] = val
  				body.variablesReference = vars_id
  				vars_id = vars_id + 1
  			else
  				body.variablesReference = 0
  			end

  			ref[args.name] = f
  		end

  	end
  	
  	sendProxyDAP(make_response(request, {
  		body = body
  	}))
  end

  function handlers.stackTrace(request)
    local args = request.arguments
    local start_frame = args.startFrame or 0
    local max_levels = args.levels or -1


    local stack_frames = {}
    local levels = 1
    local skip = 0

    local off = 0
    while true do
      local info = debug.getinfo(off+levels+start_frame)
      if not info then
        break
      end

      local inside_osv = false
      if info.source:sub(1, 1) == '@' and #info.source > 8 and info.source:sub(#info.source-8+1,#info.source) == "init.lua" then
        local source = info.source:sub(2)
        -- local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
        local parent = vim.fs.dirname(source)
        if parent and vim.fs.basename(parent) == "osv" then
          inside_osv = true
        end
      end


      if inside_osv then
        skip = off + 1
      end

      off = off + 1
    end


    -- @log_whole_stack_trace

    while levels <= max_levels or max_levels == -1 do
      local info = debug.getinfo(skip+levels+start_frame)
      if not info then
        break
      end

      local stack_frame = {}
      stack_frame.id = frame_id
      stack_frame.name = info.name or info.what
      if info.source:sub(1, 1) == '@' then
      	local source = info.source:sub(2)
      	if #info.source >= 4 and info.source:sub(1,4) == "@vim" then
      		source = os.getenv("VIMRUNTIME") .. "/lua/" .. info.source:sub(2) 
      	end


        stack_frame.source = {
          name = info.source,
      		path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p")),
        }
        stack_frame.line = info.currentline 
        stack_frame.column = 0
      else
      	-- Should be ignored by the client
        stack_frame.line = 0
        stack_frame.column = 0
      end

      table.insert(stack_frames, stack_frame)
      frames[frame_id] = skip+levels+start_frame
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

    skip_monitor = false
    skip_monitor_same_depth = false

    local depth = 0
    local surface = 0
    local off = 0
    while true do
      local info = debug.getinfo(off, "S")
      if not info then
        break
      end

      local inside_osv = false
      if info.source:sub(1, 1) == '@' and #info.source > 8 and info.source:sub(#info.source-8+1,#info.source) == "init.lua" then
        local source = info.source:sub(2)
        -- local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
        local parent = vim.fs.dirname(source)
        if parent and vim.fs.basename(parent) == "osv" then
          inside_osv = true
        end
      end

      if inside_osv then
        surface = off
      end
      off = off + 1
    end
    head_start_depth = off - 1

    depth = (off - 1) - surface
    stack_level = depth

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

      local info = debug.getinfo(frame)
      if not info then
        -- Handle invalid level
        return
      end

      while true do
        local ln, lv = debug.getlocal(frame, a)
        if not ln then
          break
        end

        if vim.startswith(ln, "(") then

        else
          local v = {}
          v.name = tostring(ln)
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

      local func = debug.getinfo(frame).func
      local a = 1
      while true do
        local ln,lv = debug.getupvalue(func, a)
        if not ln then break end

        if vim.startswith(ln, "(") then

        else
          local v = {}
          v.name = tostring(ln)
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
          v.name = tostring(ln)
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

  local attach_now = function()
      if break_on_exception then
        if not builtin_debug_traceback then
          builtin_debug_traceback = debug.traceback
        end

        debug.traceback = function(...)
          log("debug.traceback " .. vim.inspect({...}))
          if not M.is_running() then
            if builtin_debug_traceback then
              debug.traceback = builtin_debug_traceback
              return debug.traceback(...)
            end
            log("debug.traceback handle lost")
            return "one-small-step-for-vimkind lost the debug.traceback handle :("
          end

          local off = 0
          local called_explicit = false
          local called_explicit_level = nil
          local sources = {}
          while true do
            local succ, info = pcall(debug.getinfo, off)
            if not succ or not info then
              break
            end

            log("STACK " .. (info.name or "[NO NAME]") .. " " .. (info.source or "[NO SOURCE]") .. " " .. info.currentline .. " " .. tostring(info.func == debug.traceback))
            sources[off] = info.source

            if info.func == debug.traceback and info.name == "traceback" then
              called_explicit = true
              called_explicit_level = off
            end
            off = off + 1
          end

          log("called explicit " .. vim.inspect(called_explicit))
          if called_explicit and sources[called_explicit_level+1] ~= "=[C]" then
            log("called explicit source " .. vim.inspect(sources[called_explicit_level+1]))
            return builtin_debug_traceback(...)
          end

          local traceback_args = { ... }
          exception_error_msg = nil
          log(vim.inspect({...}))
          if #traceback_args > 0 then
            exception_error_msg = traceback_args[1]
          end

          local start_frame = 0
          local levels = 1
          local skip = 0

          local off = 0
          while true do
            local info = debug.getinfo(off+levels+start_frame)
            if not info then
              break
            end

            local inside_osv = false
            if info.source:sub(1, 1) == '@' and #info.source > 8 and info.source:sub(#info.source-8+1,#info.source) == "init.lua" then
              local source = info.source:sub(2)
              -- local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
              local parent = vim.fs.dirname(source)
              if parent and vim.fs.basename(parent) == "osv" then
                inside_osv = true
              end
            end


            if inside_osv then
              skip = off + 1
            end

            off = off + 1
          end


          exception_stacktrace = {}
          while true do
            local info = debug.getinfo(skip+levels+start_frame)
            if not info then
              break
            end
            local stack_desc = ""
            stack_desc = (info.short_src or "") .. ":" .. (info.currentline or "")
            if info.name then
              stack_desc = stack_desc .. " in function " .. info.name
            elseif info.what then
              stack_desc = stack_desc .. " in " .. info.what .. " chunk"
            end
            table.insert(exception_stacktrace, stack_desc)
            levels = levels + 1
          end

          exception_stacktrace = table.concat(exception_stacktrace, "\n")
          local msg = make_event("stopped")
          msg.body = {
            reason = "exception",
            threadId = 1,
            text = exception_error_msg 
          }
          sendProxyDAP(msg)

          running = false
          while not running do
            if M.stop_freeze then
              M.stop_freeze = false
              break
            end
            local i = 1
            while i <= #M.server_messages do
              local msg = M.server_messages[i]
              local f = handlers[msg.command]
              log(vim.inspect(msg))
              if f then
                f(msg)
              else
                log("Could not handle " .. msg.command)
              end
              i = i + 1
            end

            M.server_messages = {}

            vim.wait(0)
          end

          return builtin_debug_traceback(...)
        end
      end

      is_attached = true

      debug.sethook(function(event, line)
        if lock_debug_loop then return end

        local i = 1
        while i <= #M.server_messages do
          local msg = M.server_messages[i]
          local f = handlers[msg.command]
          log(vim.inspect(msg))
          if f then
            f(msg)
          else
            log("Could not handle " .. msg.command)
          end
          i = i + 1
        end

        M.server_messages = {}

        if redir_nvim_output and not vim.in_fast_event() then
          start_profiler("output")

          -- Sets `g:_osv_nvim_output` with messages observed since last `:redir`.
          pcall(vim.api.nvim_exec2, 'silent redir END', nvim_exec2_opts)

          local ok, msgs = pcall(vim.api.nvim_get_var, '_osv_nvim_output')
          if ok then
            if type(msgs) ~= 'string' then
              error('expected g:_osv_nvim_output to be a string but got: ' .. msgs)
            elseif #msgs > 0 then
              local event = make_event 'output'
              event.body = { category = 'stdout', output = msgs }
              sendProxyDAP(event)
            end
          end

          -- Sets `g:_osv_nvim_output` as redir target for nvim messages, creates the
          -- variable if it doesn't already exist, and clears it. Messages are still
          -- displayed on-screen in debuggee as usual. This should also work when nvim
          -- is headless.
          pcall(vim.api.nvim_exec2, 'silent redir => g:_osv_nvim_output', nvim_exec2_opts)
          stop_profiler("output")
        end


        local depth = -1
        if (event == "call" or event == "return") and monitor_stack and next then
        	skip_monitor_same_depth = true
        	skip_monitor = false
        end

        if monitor_stack and not skip_monitor then
          local surface = 0
          local off = 0
          while true do
            local info = debug.getinfo(off, "S")
            if not info then
              break
            end

            local inside_osv = false
            if info.source:sub(1, 1) == '@' and #info.source > 8 and info.source:sub(#info.source-8+1,#info.source) == "init.lua" then
              local source = info.source:sub(2)
              -- local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
              local parent = vim.fs.dirname(source)
              if parent and vim.fs.basename(parent) == "osv" then
                inside_osv = true
              end
            end

            if inside_osv then
              surface = off
            end
            off = off + 1
          end
          head_start_depth = off - 1

          depth = (off - 1) - surface
          if next and event == "line" and skip_monitor_same_depth then
          	skip_monitor = true
          end

        end

        local bps = breakpoints[line]
        if event == "line" and bps then
          local surface = 0
          local off = 0
          while true do
            local info = debug.getinfo(off, "S")
            if not info then
              break
            end

            local inside_osv = false
            if info.source:sub(1, 1) == '@' and #info.source > 8 and info.source:sub(#info.source-8+1,#info.source) == "init.lua" then
              local source = info.source:sub(2)
              -- local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
              local parent = vim.fs.dirname(source)
              if parent and vim.fs.basename(parent) == "osv" then
                inside_osv = true
              end
            end


            if inside_osv then
              surface = off + 1
            end
            off = off + 1
          end


          local info = debug.getinfo(surface, "S")
          local source_path = info.source

          if source_path:sub(1, 1) == "@" then
          	local path
          	if #source_path >= 4 and source_path:sub(1, 4) == "@vim" then
          		path = os.getenv("VIMRUNTIME") .. "/lua/" .. source_path:sub(2) 

          	else
          		path = source_path:sub(2)
          	end
          	start_profiler("resolve_path")

            local succ, path = pcall(vim.fn.fnamemodify, path, ":p")
            if succ then
          		path = vim.fn.resolve(path)
              path = vim.uri_from_fname(path:lower())
          		stop_profiler("resolve_path")
          		local bp = bps[path]
              if bp then
          			log(vim.inspect(bp))
          			local hit = false
          			if type(bp) == "boolean" then
          				hit = true
          			elseif type(bp) == "number" then
          				if bp == 0 then
          					hit = true
          					bps[path] = breakpoints_count[line][path]
          				else
          					bps[path] = bps[path] - 1
          				end

          			elseif type(bp) == "string" then
          				local expr = bp
          				local frame = 2
          				local a = 1
          				local prev
          				local cur = {}
          				local first = cur

          				while true do
          					if not frame then break end
          				  local succ, ln, lv = pcall(debug.getlocal, frame+1, a)
          				  if not succ then
          				    break
          				  end

          				  if not ln then
          						break
          				  else
          				    -- Avoid shadowing of the globals if a local variable is nil
          				    cur[ln] = lv or vim.NIL
          				    a = a + 1
          				  end
          				end



          				prev = cur

          				cur = {}
          				setmetatable(prev, {
          					__index = cur
          				})

          				a = 1

          				if frame then
          					local succ, info = pcall(debug.getinfo, frame+1)
          					if succ and info and info.func then
          						local func = info.func
          						local a = 1
          						while true do
          							local succ, ln, lv = pcall(debug.getupvalue, func, a)
          							if not succ then
          								break
          							end

          							if not ln then
          								break
          							else
          								-- Avoid shadowing of the globals if a local variable is nil
          								cur[ln] = lv or vim.NIL
          								a = a + 1
          							end
          						end
          					end
          				end

          				if frame then
          					local succ, info = pcall(debug.getinfo, frame+1)
          					if succ and info and info.func then
          						setmetatable(cur, {
          							__index = getfenv(info.func)
          						})
          					end
          				else
          					local frame = 0

          					while true do 
          						local succ, info = pcall(debug.getinfo, frame+1)
          						if not succ or not info or not info.func then
          							break
          						end
          						frame = frame + 1
          					end

          					local succ, info = pcall(debug.getinfo, frame)
          					if succ and info then
          						setmetatable(cur, {
          							__index = getfenv(info.func)
          						})
          					end
          				end

          				local succ, f = pcall(loadstring, "return " .. expr)
          				if succ and f then
          				  setfenv(f, first)
          				end

          				local result_repl
          				if succ then
          				  succ, result_repl = pcall(f)
          				else
          				  result_repl = f
          				end

          				if result_repl == vim.NIL then
          				  result_repl = nil 
          				end

          				hit = result_repl == true

          			elseif type(bp) == "table" then
          				local expr = bp[1]
          				local frame = 2
          				local a = 1
          				local prev
          				local cur = {}
          				local first = cur

          				while true do
          					if not frame then break end
          				  local succ, ln, lv = pcall(debug.getlocal, frame+1, a)
          				  if not succ then
          				    break
          				  end

          				  if not ln then
          						break
          				  else
          				    -- Avoid shadowing of the globals if a local variable is nil
          				    cur[ln] = lv or vim.NIL
          				    a = a + 1
          				  end
          				end



          				prev = cur

          				cur = {}
          				setmetatable(prev, {
          					__index = cur
          				})

          				a = 1

          				if frame then
          					local succ, info = pcall(debug.getinfo, frame+1)
          					if succ and info and info.func then
          						local func = info.func
          						local a = 1
          						while true do
          							local succ, ln, lv = pcall(debug.getupvalue, func, a)
          							if not succ then
          								break
          							end

          							if not ln then
          								break
          							else
          								-- Avoid shadowing of the globals if a local variable is nil
          								cur[ln] = lv or vim.NIL
          								a = a + 1
          							end
          						end
          					end
          				end

          				if frame then
          					local succ, info = pcall(debug.getinfo, frame+1)
          					if succ and info and info.func then
          						setmetatable(cur, {
          							__index = getfenv(info.func)
          						})
          					end
          				else
          					local frame = 0

          					while true do 
          						local succ, info = pcall(debug.getinfo, frame+1)
          						if not succ or not info or not info.func then
          							break
          						end
          						frame = frame + 1
          					end

          					local succ, info = pcall(debug.getinfo, frame)
          					if succ and info then
          						setmetatable(cur, {
          							__index = getfenv(info.func)
          						})
          					end
          				end

          				local succ, f = pcall(loadstring, "return " .. expr)
          				if succ and f then
          				  setfenv(f, first)
          				end

          				local result_repl
          				if succ then
          				  succ, result_repl = pcall(f)
          				else
          				  result_repl = f
          				end

          				if result_repl == vim.NIL then
          				  result_repl = nil 
          				end

          				hit = result_repl == true

          				if bp[2] == 0 then
          					hit = hit and true
          					bp[2] = breakpoints_count[line][path]
          				else
          					bp[2] = bp[2] - 1
          					hit = false
          				end

          			end

          			if hit then
          				log("breakpoint hit")
          				local msg = make_event("stopped")
          				msg.body = {
          				  reason = "breakpoint",
          				  threadId = 1
          				}
          				sendProxyDAP(msg)

          				running = false
          				while not running do
          				  if M.stop_freeze then
          				    M.stop_freeze = false
          				    break
          				  end
          				  local i = 1
          				  while i <= #M.server_messages do
          				    local msg = M.server_messages[i]
          				    local f = handlers[msg.command]
          				    log(vim.inspect(msg))
          				    if f then
          				      f(msg)
          				    else
          				      log("Could not handle " .. msg.command)
          				    end
          				    i = i + 1
          				  end

          				  M.server_messages = {}

          				  vim.wait(0)
          				end

          			end
              end
            end
          end


        elseif event == "line" and step_in then
        	local valid = false
        	local surface = 0
        	local off = 0
        	while true do
        	  local info = debug.getinfo(off, "S")
        	  if not info then
        	    break
        	  end

        	  local inside_osv = false
        	  if info.source:sub(1, 1) == '@' and #info.source > 8 and info.source:sub(#info.source-8+1,#info.source) == "init.lua" then
        	    local source = info.source:sub(2)
        	    -- local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
        	    local parent = vim.fs.dirname(source)
        	    if parent and vim.fs.basename(parent) == "osv" then
        	      inside_osv = true
        	    end
        	  end


        	  if inside_osv then
        	    surface = off + 1
        	  end
        	  off = off + 1
        	end


        	local info = debug.getinfo(surface)

        	if info and info.currentline and info.currentline ~= 0 then
        		valid = true
        	end
        	if valid then
        		local msg = make_event("stopped")
        		msg.body = {
        		  reason = "step",
        		  threadId = 1
        		}
        		sendProxyDAP(msg)

        		step_in = false


        		running = false
        		while not running do
        		  if M.stop_freeze then
        		    M.stop_freeze = false
        		    break
        		  end
        		  local i = 1
        		  while i <= #M.server_messages do
        		    local msg = M.server_messages[i]
        		    local f = handlers[msg.command]
        		    log(vim.inspect(msg))
        		    if f then
        		      f(msg)
        		    else
        		      log("Could not handle " .. msg.command)
        		    end
        		    i = i + 1
        		  end

        		  M.server_messages = {}

        		  vim.wait(0)
        		end

        	end

        elseif event == "line" and next and depth >= 0 and depth <= stack_level then
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
            if M.stop_freeze then
              M.stop_freeze = false
              break
            end
            local i = 1
            while i <= #M.server_messages do
              local msg = M.server_messages[i]
              local f = handlers[msg.command]
              log(vim.inspect(msg))
              if f then
                f(msg)
              else
                log("Could not handle " .. msg.command)
              end
              i = i + 1
            end

            M.server_messages = {}

            vim.wait(0)
          end


        elseif event == "line" and step_out and depth >= 0 and stack_level-1 == depth then
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
            if M.stop_freeze then
              M.stop_freeze = false
              break
            end
            local i = 1
            while i <= #M.server_messages do
              local msg = M.server_messages[i]
              local f = handlers[msg.command]
              log(vim.inspect(msg))
              if f then
                f(msg)
              else
                log("Could not handle " .. msg.command)
              end
              i = i + 1
            end

            M.server_messages = {}

            vim.wait(0)
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
            if M.stop_freeze then
              M.stop_freeze = false
              break
            end
            local i = 1
            while i <= #M.server_messages do
              local msg = M.server_messages[i]
              local f = handlers[msg.command]
              log(vim.inspect(msg))
              if f then
                f(msg)
              else
                log("Could not handle " .. msg.command)
              end
              i = i + 1
            end

            M.server_messages = {}

            vim.wait(0)
          end


        end
      end, "clr")

  end
  if blocking then
    local has_done_configuration = false
    local has_attach_message = false
    while true do
      local j = 1
      while j <= #M.server_messages do
        local msg = M.server_messages[j]
        local f = handlers[msg.command]

        if f then
          if msg.command == "setBreakpoints" then
            log(vim.inspect(msg))
            f(msg)
            table.remove(M.server_messages, j)
          elseif msg.command == "configurationDone" then
            has_done_configuration = true
            log(vim.inspect(msg))
            f(msg)
            table.remove(M.server_messages, j)
          elseif msg.command == "attach" then
            has_attach_message = true
            j = j + 1
          else
            j = j + 1
          end
        else
          j = j + 1
        end
      end
      if has_done_configuration and has_attach_message then break end
      vim.wait(50)
    end

    attach_now()
  else
    local timer = vim.loop.new_timer()
    local has_done_configuration = false
    local has_attach_message = false
    timer:start(0, 50, vim.schedule_wrap(function()
      local j = 1
      while j <= #M.server_messages do
        local msg = M.server_messages[j]
        local f = handlers[msg.command]

        if f then
          if msg.command == "setBreakpoints" then
            log(vim.inspect(msg))
            f(msg)
            table.remove(M.server_messages, j)
          elseif msg.command == "configurationDone" then
            has_done_configuration = true
            log(vim.inspect(msg))
            f(msg)
            table.remove(M.server_messages, j)
          elseif msg.command == "attach" then
            has_attach_message = true
            j = j + 1
          else
            j = j + 1
          end
        else
          j = j + 1
        end
      end
      if not has_done_configuration or not has_attach_message then return end
      timer:close()
      attach_now()
    end))

  end
end

M.on = {}

function log(str)
  if log_filename then
    local f = io.open(log_filename, "a")
    if f then
      f:write(str .. "\n")
      f:close()
    end
  end

  -- required for regression testing
  if debug_output then
    table.insert(debug_output, tostring(str))
  else
    -- print(str)
  end
end

function M.add_message(msg)
  lock_debug_loop = true
  table.insert(M.server_messages, msg)
  lock_debug_loop = false
end

M.server_messages = {}
function M.run_this(opts)
  local dap = require"dap"
  assert(dap, "nvim-dap not found. Please make sure it's installed.")

  if auto_nvim then
    vim.fn.jobstop(auto_nvim)
    auto_nvim = nil
  end

  local clean_args = { vim.v.progpath, '-u', 'NONE', '-i', 'NONE', '-n', '--embed', '--headless' }
  nvim_server = vim.fn.jobstart(clean_args, {rpc = true})
  vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', 'vim.o.runtimepath = ...', { vim.o.runtimepath })
  vim.fn.rpcrequest(nvim_server, 'nvim_exec_lua', 'vim.o.packpath = ...', { vim.o.packpath })
  auto_nvim = nvim_server

  assert(auto_nvim, "Could not create neovim instance with jobstart!")


  local mode = vim.fn.rpcrequest(auto_nvim, "nvim_get_mode")
  assert(not mode.blocking, "Neovim is waiting for input at startup. Aborting.")

  local server = vim.fn.rpcrequest(auto_nvim, "nvim_exec_lua", [[return require"osv".launch(...)]], { opts })
  vim.wait(100)

  assert(dap.adapters.nlua, "nvim-dap adapter configuration for nlua not found. Please refer to the README.md or :help osv.txt")

  local osv_config = {
    type = "nlua",
    request = "attach",
    name = "Debug current file",
    host = server.host,
    port = server.port,
  }
  dap.run(osv_config)

  dap.listeners.after['setBreakpoints']['osv'] = function(session, body)
    vim.schedule(function()
      vim.fn.rpcnotify(auto_nvim, "nvim_command", "luafile " .. vim.fn.expand("%:p"))

    end)
  end

end

function M.sendDAP(msg)
  local succ, encoded = pcall(vim.fn.json_encode, msg)

  log(vim.inspect(msg))
  if succ then
    local bin_msg = "Content-Length: " .. string.len(encoded) .. "\r\n\r\n" .. encoded

    client:write(bin_msg)

  else
    log(encoded)
  end
end

function M.start_server(host, port, do_log)
  if do_log then
    log_filename = vim.fn.stdpath("data") .. "/osv.log"
  end

  local server = vim.loop.new_tcp()

  server:bind(host, port)

  server:listen(128, function(err)
    M.stop_freeze = false

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

      log(vim.inspect(msg))
      M.sendDAP(make_response(msg, {
        body = {
      		supportsConfigurationDoneRequest = true,

      		supportTerminateDebuggee = true,

      		supportsExceptionInfoRequest = true,

      		supportsHitConditionalBreakpoints = true,
      		supportsConditionalBreakpoints = true,


      		supportsSetVariable = true,

      	}
      }))

      M.sendDAP(make_event('initialized'))

      while true do
        local msg
        do
          local len = read_header()
          msg = read_body(len.content_length)
        end

        if debug_hook_conn then
          vim.fn.rpcnotify(debug_hook_conn, "nvim_exec_lua", [[require"osv".add_message(...)]], {msg})
        end

      end
    end)

    sock:read_start(vim.schedule_wrap(function(err, chunk)
      if chunk then
        tcp_data = tcp_data .. chunk
        coroutine.resume(dap_read)

      else
        vim.fn.rpcrequest(debug_hook_conn, "nvim_exec_lua", [[require"osv".unfreeze()]], {})

        sock:shutdown()
        sock:close()
      end
    end))

  end)

  if not server:getsockname() then
  	return nil
  end

  print("Server started on " .. server:getsockname().port)

  if debug_hook_conn_address then
    debug_hook_conn = vim.fn.sockconnect("pipe", debug_hook_conn_address, {rpc = true})
  end


  return {
    host = host,
    port = server:getsockname().port
  }
end

function M.stop()
	if builtin_debug_traceback then
	  debug.traceback = builtin_debug_traceback
	end

  debug.sethook()


	if not nvim_server then
		log("Tried stopping osv when it is already.")
		return 
	end

  sendProxyDAP(make_event("terminated"))

  local msg = make_event("exited")
  msg.body = {
    exitCode = 0,
  }
  sendProxyDAP(msg)

  if nvim_server then
  	vim.fn.jobstop(nvim_server)
  	log("SERVER TERMINATED")
    nvim_server = nil
  end

  skip_monitor = false
  skip_monitor_same_depth = false

  running = true

  limit = 0

  stack_level = 0
  next = false
  monitor_stack = false

  pause = false

  vars_id = 1
  vars_ref = {}

  frame_id = 1
  frames = {}

  step_out = false

  seq_id = 1

  M.stop_freeze = false

  is_attached = false

	if exit_autocmd then
		vim.api.nvim_del_autocmd(exit_autocmd)
		exit_autocmd = nil
	end

end

function M.is_running()
	return nvim_server ~= nil
end

function M.is_attached()
	return is_attached
end
function M.start_trace()
	function line_hook(event, line)
		local surface = 0
		local off = 0
		while true do
		  local info = debug.getinfo(off, "S")
		  if not info then
		    break
		  end

		  local inside_osv = false
		  if info.source:sub(1, 1) == '@' and #info.source > 8 and info.source:sub(#info.source-8+1,#info.source) == "init.lua" then
		    local source = info.source:sub(2)
		    -- local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
		    local parent = vim.fs.dirname(source)
		    if parent and vim.fs.basename(parent) == "osv" then
		      inside_osv = true
		    end
		  end


		  if inside_osv then
		    surface = off + 1
		  end
		  off = off + 1
		end


		local info = debug.getinfo(surface, "S")
		local source_path = info.source
		cache[source_path] = cache[source_path] or {}
		table.insert(cache[source_path], line)

	end

	cache = {}

	debug.sethook(line_hook, "l")

end

function M.stop_trace()
	debug.sethook()

	local sources = vim.tbl_keys(cache)
	for _, source in ipairs(sources) do
		local line_set = {}

		for _, linenr in ipairs(cache[source]) do
			line_set[linenr] = true
		end

		line_set = vim.tbl_keys(line_set)
		table.sort(line_set)
		cache[source] = line_set
	end
	return cache

end

return M
