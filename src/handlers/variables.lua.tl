##../lua-debug
@implement_handlers+=
function handlers.variables(request)
  local args = request.arguments

  local frame = vars_ref[args.variablesReference]
  if not frame then
    log("VariablesReference not found")
    return
  end

  local variables = {}
  @inspect_local_variables

  sendProxyDAP(make_response(request, {
    body = {
      variables = variables,
    }
  }))
end

@inspect_local_variables+=
local a = 1
while true do
  local ln, lv = debug.getlocal(frame, a)
  if not ln then
    break
  end

  @omit_temporary_values
  else
    local v = {}
    @fill_variable_struct
    table.insert(variables, v)
  end
  a = a + 1
end

@omit_temporary_values+=
if vim.startswith(ln, "(*") then

@fill_variable_struct+=
v.name = ln
v.value = vim.inspect(lv)
