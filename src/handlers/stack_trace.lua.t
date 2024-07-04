##../lua-debug
@implement_handlers+=
function handlers.stackTrace(request)
  local args = request.arguments
  @read_stacktrace_arguments

  local stack_frames = {}
  @parse_debug_traces

  sendProxyDAP(make_response(request,{
    body = {
      stackFrames = stack_frames,
      totalFrames = #stack_frames,
    };
  }))
end

@read_stacktrace_arguments+=
local start_frame = args.startFrame or 0
local max_levels = args.levels or -1

@script_variables+=
local frame_id = 1
local frames = {}

@parse_debug_traces+=
local levels = 1
local skip_firsts = true
while levels <= max_levels or max_levels == -1 do
  local info = debug.getinfo(levels+start_frame)
  if not info then
    break
  end

  local inside_osv = false
  if skip_firsts then
    @check_if_stack_frame_is_inside_osv
  end

  if not skip_firsts or not inside_osv then
    @fill_stack_frame_with_info
    table.insert(stack_frames, stack_frame)
    frames[frame_id] = levels+start_frame
    frame_id = frame_id + 1
    skip_firsts = false 
  end

  levels = levels + 1
end

@fill_stack_frame_with_info+=
local stack_frame = {}
stack_frame.id = frame_id
stack_frame.name = info.name or info.what
if info.source:sub(1, 1) == '@' then
	local source = info.source:sub(2)
	@handle_source_in_vim_runtime
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

@handle_source_in_vim_runtime+=
if #info.source >= 4 and info.source:sub(1,4) == "@vim" then
	source = os.getenv("VIMRUNTIME") .. "/lua/" .. info.source:sub(2) 
end


@check_if_stack_frame_is_inside_osv+=
if info.source:sub(1, 1) == '@' then
  local source = info.source:sub(2)
  local path = vim.fn.resolve(vim.fn.fnamemodify(source, ":p"))
  if vim.fs.basename(path) == 'init.lua' then
    local parent = vim.fs.dirname(path)
    if parent and vim.fs.basename(parent) == "osv" then
      inside_osv = true
    end
  end
end
