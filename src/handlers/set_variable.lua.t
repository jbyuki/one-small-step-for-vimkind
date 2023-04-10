##../lua-debug
@support_capabilities+=
supportsSetVariable = true,

@implement_handlers+=
function handlers.setVariable(request)
	local args = request.arguments
  local ref = vars_ref[args.variablesReference]

	@set_variable_variables

  if type(ref) == "number" then
		@set_variable_in_frame
	elseif type(ref) == "table" then
		@set_variable_in_table
	end
	
	sendProxyDAP(make_response(request, {
		body = body
	}))
end

@set_variable_in_frame+=
local a = 1
local frame = ref
while true do
  local ln, lv = debug.getlocal(frame, a)
  if not ln then
    break
  end

	if ln == args.name then
		local succ, f = pcall(loadstring, "return " .. args.value)
		if succ and f then
			local val = f()
			@fill_set_variable_response_body
			@set_local_variable_value
		end
  end
  a = a + 1
end

@set_variable_variables+=
local body = {}

@fill_set_variable_response_body+=
body.value = tostring(val)
body.type = type(val)
if type(val) == "table" then
	vars_ref[vars_id] = val
	body.variablesReference = vars_id
	vars_id = vars_id + 1
else
	body.variablesReference = 0
end

@set_local_variable_value+=
debug.setlocal(frame, a, val)

@set_variable_in_table+=
local succ, val = pcall(loadstring, "return " .. args.value)
if succ and f then
	local val = f()
	@fill_set_variable_response_body
	ref[args.name] = f
end

