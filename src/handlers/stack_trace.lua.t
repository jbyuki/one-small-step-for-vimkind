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
local skip = 0

@skip_internal_frames

-- @log_whole_stack_trace

while levels <= max_levels or max_levels == -1 do
  local info = debug.getinfo(skip + levels + start_frame)
  if not info then
    break
  end

  @fill_stack_frame_with_info
  table.insert(stack_frames, stack_frame)
  frames[frame_id] = skip + levels + start_frame
  frame_id = frame_id + 1

  levels = levels + 1
end

@fill_stack_frame_with_info+=
local stack_frame = {}
stack_frame.id = frame_id
stack_frame.name = info.name or info.what
if info.source:find "^@" then
  local source = info.source:sub(2)
  @handle_source_in_vim_runtime
  stack_frame.source = {
    name = info.source,
    path = uv.fs_realpath(source),
  }
  stack_frame.line = info.currentline
  stack_frame.column = 0
else
  -- Should be ignored by the client
  stack_frame.line = 0
  stack_frame.column = 0
end

@handle_source_in_vim_runtime+=
if info.source:find "^@vim" then
  source = os.getenv("VIMRUNTIME") .. "/lua/" .. info.source:sub(2)
end


@skip_internal_frames+=
for off = 0, math.huge do
  local info = debug.getinfo(off + levels + start_frame)
  if not info then
    break
  end

  local inside_osv = false
  @check_if_inside_osv

  if inside_osv then
    skip = off + 1
  end
end

@check_if_inside_osv+=
inside_osv = info.source:find [[^@.*[\/]osv[\/]init%.lua$]] ~= nil

@log_whole_stack_trace+=
for off = 0, math.huge do
  local info = debug.getinfo(off + levels + start_frame)
  if not info then
    break
  end
  log("STACK " .. (info.name or "[NO NAME]") .. " " .. (info.source or "[NO SOURCE]") .. " " .. info.currentline)
end
