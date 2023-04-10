##../lua-debug
@check_if_breakpoint_hit+=
local bps = breakpoints[line]
if event == "line" and bps then
  @get_source_path
  @if_source_path_match_break

@get_source_path+=
local info = debug.getinfo(2, "S")
local source_path = info.source

@script_variables+=
local running = true

@if_source_path_match_break+=
if source_path:sub(1, 1) == "@" or step_in then
  local path = source_path:sub(2)
  local succ, path = pcall(vim.fn.fnamemodify, path, ":p")
  if succ then
		path = vim.fn.resolve(path)
    path = vim.uri_from_fname(path:lower())
		local bp = bps[path]
    if bp then
			log(vim.inspect(bp))
			local hit = false
			if type(bp) == "boolean" then
				hit = true
			elseif type(bp) == "number" then
				@check_breakpoint_hit_condition
			elseif type(bp) == "string" then
				@check_breakpoint_condition
			elseif type(bp) == "table" then
				@check_breakpoint_both
			end

			if hit then
				log("breakpoint hit")
				@send_stopped_event_breakpoint
				@freeze_neovim_instance
			end
    end
  end
end

@freeze_neovim_instance+=
running = false
while not running do
  @check_disconnected
  @handle_new_messages
  @clear_messages
  vim.wait(50)
end

@send_stopped_event_breakpoint+=
local msg = make_event("stopped")
msg.body = {
  reason = "breakpoint",
  threadId = 1
}
sendProxyDAP(msg)

@check_breakpoint_hit_condition+=
if bp == 0 then
	hit = true
	bps[path] = breakpoints_count[line][path]
else
	bps[path] = bps[path] - 1
end

