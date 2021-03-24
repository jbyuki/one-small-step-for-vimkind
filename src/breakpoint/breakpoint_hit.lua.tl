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
log(source_path)

@if_source_path_match_break+=
if source_path:sub(1, 1) == "@" then
  local path = source_path:sub(2)
  path = vim.fn.fnamemodify(path, ":p")
  if bps[path] then
    log("Break!")
  end
end
