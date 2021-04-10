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
  line_bps[args.source.path:lower()] = true
  table.insert(results_bps, { verified = true })
  -- log("Set breakpoint at line " .. bp.line .. " in " .. args.source.path)
end

@declare+=
local sendProxyDAP

@implement+=
function sendProxyDAP(data)
  vim.fn.rpcnotify(nvim_server, 'nvim_exec_lua', [[require"step-for-vimkind".sendDAP(...)]], {data})
end

@send_back_breakpoint_verification+=
sendProxyDAP(make_response(request, {
  body = {
    breakpoints = results_bps
  }
}))


@clear_breakpoints_in_source+=
for line, line_bps in pairs(breakpoints) do
  line_bps[args.source.path:lower()] = nil
end
