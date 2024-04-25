##lua-debug
@implement+=
function M.stop()
  @disable_hooks

	if not nvim_server then
		log("Tried stopping osv when it is already.")
		return 
	end

  @send_terminated_event
  @send_exited_event
  @terminate_adapter_server_process
  @reset_internal_states
	@unregister_exit_autocmd
end

@send_terminated_event+=
sendProxyDAP(make_event("terminated"))

@send_exited_event+=
local msg = make_event("exited")
msg.body = {
  exitCode = 0,
}
sendProxyDAP(msg)

@reset_internal_states+=
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

@implement+=
function M.is_running()
	return nvim_server ~= nil
end

