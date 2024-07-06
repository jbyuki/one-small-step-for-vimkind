##../lua-debug
@check_if_breakpoint_hit+=
local bps = breakpoints[line]
if event == "line" and bps then
  @get_source_path
  @if_source_path_match_break

@get_source_path+=
local surface = 0
@get_surface_stack_frame

local info = debug.getinfo(surface, "S")
local source_path = info.source

@script_variables+=
local running = true

@if_source_path_match_break+=
if source_path:sub(1, 1) == "@" then
	local path
	if #source_path >= 4 and source_path:sub(1, 4) == "@vim" then
		@resolve_vim_runtime_directory
	else
		path = source_path:sub(2)
	end
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
				local expr = bp
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

@check_breakpoint_condition+=
local frame = 2
@retrieve_locals_in_frame
@retrieve_upvalues_in_frame
@retrieve_globals
@set_frame_environment_for_execution
@evaluate_expression
hit = result_repl == true

@check_breakpoint_both+=
local expr = bp[1]
@check_breakpoint_condition
if bp[2] == 0 then
	hit = hit and true
	bp[2] = breakpoints_count[line][path]
else
	bp[2] = bp[2] - 1
	hit = false
end

@resolve_vim_runtime_directory+=
path = os.getenv("VIMRUNTIME") .. "/lua/" .. source_path:sub(2) 

@get_surface_stack_frame+=
local off = 0
while true do
  local info = debug.getinfo(off, "S")
  if not info then
    break
  end

  local inside_osv = false
  @check_if_inside_osv

  if inside_osv then
    surface = off + 1
  end
  off = off + 1
end
