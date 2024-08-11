##../lua-debug
@script_variables+=
local skip_monitor = false
local skip_monitor_same_depth = false

@reset_internal_states+=
skip_monitor = false
skip_monitor_same_depth = false

@set_next_variable+=
skip_monitor = false
skip_monitor_same_depth = false

@set_step_out+=
skip_monitor = false
skip_monitor_same_depth = false

@speedup_stack_monitor+=
if (event == "call" or event == "return") and monitor_stack and next then
	skip_monitor_same_depth = true
	skip_monitor = false
end

@disable_monitor_for_speedup+=
if next and event == "line" and skip_monitor_same_depth then
	skip_monitor = true
end

@script_variables+=
local head_start_depth = -1

@save_for_next_head_start+=
head_start_depth = off - 1

@head_start_for_monitoring+=
if head_start_depth >= 0 then
  local info = debug.getinfo(head_start_depth, "S")
  if info then
		local inside_osv = false
		@check_if_inside_osv
		if inside_osv then
			off = head_start_depth+1
		end
  end
end
