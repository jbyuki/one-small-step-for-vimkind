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
while levels <= max_levels or max_levels == -1 do
  local info = debug.getinfo(2+levels+start_frame)
  if not info then
    break
  end

  @fill_stack_frame_with_info
  table.insert(stack_frames, stack_frame)
  frames[frame_id] = 2+levels+start_frame
  frame_id = frame_id + 1

  levels = levels + 1
end

@fill_stack_frame_with_info+=
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
