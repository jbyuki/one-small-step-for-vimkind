##../lua-debug
@implement_handlers+=
function handlers.evaluate(request)
  local args = request.arguments
  if args.context == "repl" then
		local frame = frames[args.frameId]
    @retrieve_locals_in_frame
		@retrieve_upvalues_in_frame
		@retrieve_globals
		local expr = args.expression
    @set_frame_environment_for_execution
    @evaluate_expression
    @make_evaluate_reponse
    @send_repl_evaluate_response
	elseif args.context == "hover" then
		local frame = frames[args.frameId]
    @retrieve_locals_in_frame
		@retrieve_upvalues_in_frame
		@retrieve_globals
		local expr = args.expression
    @set_frame_environment_for_execution
    @evaluate_expression
    @make_evaluate_reponse
    @send_hover_evaluate_response
  else
    log("evaluate context " .. args.context .. " not supported!")
  end
end

@retrieve_locals_in_frame+=
local a = 1
local prev
local cur = {}
local first = cur

while true do
  local succ, ln, lv = pcall(debug.getlocal, frame+1, a)
  if not succ then
    break
  end

  if not ln then
		break
  else
    -- Avoid shadowing of the globals if a local variable is nil
    cur[ln] = lv or vim.NIL
    a = a + 1
  end
end



@set_frame_environment_for_execution+=
local succ, f = pcall(loadstring, "return " .. expr)
if succ and f then
  setfenv(f, first)
end

@evaluate_expression+=
local result_repl
if succ then
  succ, result_repl = pcall(f)
else
  result_repl = f
end

if result_repl == vim.NIL then
  result_repl = nil 
end

@send_repl_evaluate_response+=
sendProxyDAP(make_response(request, {
  body = v
}))

@send_hover_evaluate_response+=
sendProxyDAP(make_response(request, {
  body = v
}))

@retrieve_upvalues_in_frame+=
prev = cur

cur = {}
setmetatable(prev, {
	__index = cur
})

a = 1

local succ, info = pcall(debug.getinfo, frame+1)
if succ and info and info.func then
	local func = info.func
	local a = 1
	while true do
		local succ, ln, lv = pcall(debug.getupvalue, func, a)
		if not succ then
			break
		end

		if not ln then
			break
		else
      -- Avoid shadowing of the globals if a local variable is nil
			cur[ln] = lv or vim.NIL
			a = a + 1
		end
	end
end

@retrieve_globals+=
local succ, info = pcall(debug.getinfo, frame+1)
if succ and info and info.func then
	setmetatable(cur, {
		__index = getfenv(info.func)
	})
end

@make_evaluate_reponse+=
local v = {}
v.result = tostring(result_repl)
if type(result_repl) == "table" then
  local lv = result_repl
  @make_variable_reference_for_table
else
  v.variablesReference = 0
end

