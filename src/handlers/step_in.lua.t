##../lua-debug
@implement_handlers+=
function handlers.stepIn(request)
  @set_step_in
  @continue_running

  @acknowledge_step_in
end

@continue_running+=
running = true

@script_variables+=
local step_in

@set_step_in+=
step_in = true

@disable_step_in+=
step_in = false

@acknowledge_step_in+=
sendProxyDAP(make_response(request,{}))

@check_if_step_into+=
elseif event == "line" and step_in then
	local valid = false
	@make_sure_location_is_valid
	if valid then
		@send_stopped_event_step
		@disable_step_in

		@freeze_neovim_instance
	end

@send_stopped_event_step+=
local msg = make_event("stopped")
msg.body = {
  reason = "step",
  threadId = 1
}
sendProxyDAP(msg)

@make_sure_location_is_valid+=
local surface = 0
@get_surface_stack_frame

local info = debug.getinfo(surface)

if info and info.currentline and info.currentline ~= 0 then
	valid = true
end
