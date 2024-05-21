##../lua-debug
@attach_variables+=
local breakpoints = {}

@implement_handlers+=
function handlers.setBreakpoints(request)
  local args = request.arguments
  @clear_breakpoints_in_source
  @save_breakpoints_informations
  @send_back_breakpoint_verification
end

@save_breakpoints_informations+=
local results_bps = {}

for _, bp in ipairs(args.breakpoints) do
  breakpoints[bp.line] = breakpoints[bp.line] or {}
  local line_bps = breakpoints[bp.line]
	@save_breakpoint
  table.insert(results_bps, { verified = true })
  -- log("Set breakpoint at line " .. bp.line .. " in " .. args.source.path)
end

@declare+=
local sendProxyDAP

@implement+=
function sendProxyDAP(data)
  vim.fn.rpcnotify(nvim_server, 'nvim_exec_lua', [[require"osv".sendDAP(...)]], {data})
end

@send_back_breakpoint_verification+=
sendProxyDAP(make_response(request, {
  body = {
    breakpoints = results_bps
  }
}))


@clear_breakpoints_in_source+=
for line, line_bps in pairs(breakpoints) do
  line_bps[vim.uri_from_fname(args.source.path:lower())] = nil
end

@support_capabilities+=
supportsHitConditionalBreakpoints = true,
supportsConditionalBreakpoints = true,


@save_breakpoint+=
if bp.condition and bp.hitCondition then
	@set_breakpoint_hit_condition_in_table
	line_bps[vim.uri_from_fname(args.source.path:lower())] = {bp.condition, tonumber(bp.hitCondition)}
elseif bp.condition then
	line_bps[vim.uri_from_fname(args.source.path:lower())] = bp.condition
elseif bp.hitCondition then
	@set_breakpoint_hit_condition_in_table
	line_bps[vim.uri_from_fname(args.source.path:lower())] = tonumber(bp.hitCondition)
else
	line_bps[vim.uri_from_fname(args.source.path:lower())] = true
end

@attach_variables+=
local breakpoints_count = {}

@set_breakpoint_hit_condition_in_table+=
breakpoints_count[bp.line] = breakpoints_count[bp.line] or {}
local line_bps_count = breakpoints_count[bp.line]
line_bps_count[vim.uri_from_fname(args.source.path:lower())] = tonumber(bp.hitCondition)

@clear_breakpoints_in_source+=
for line, line_bps_count in pairs(breakpoints_count) do
	line_bps_count[vim.uri_from_fname(args.source.path:lower())] = nil
end
