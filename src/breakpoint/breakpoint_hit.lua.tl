##../lua-debug
@check_if_breakpoint_hit+=
local bps = breakpoints[line]
if bps then
  @get_source_path
  @if_source_path_match_break
end

@get_source_path+=
local info = debug.getinfo(2, "S")
local source_path = info.source

@script_variables+=
local running = false

@if_source_path_match_break+=
if source_path:sub(1, 1) == "@" then
  local path = source_path:sub(2)
  path = vim.fn.fnamemodify(path, ":p")
  if bps[path] then
    @send_stopped_event

    while not running do
      @handle_new_messages
      @clear_messages
      vim.wait(50)
    end
  end
end

@send_stopped_event+=
local msg = make_event("stopped")
msg.body = {
  reason = "breakpoint",
  threadId = 1
}
sendProxyDAP(msg)
