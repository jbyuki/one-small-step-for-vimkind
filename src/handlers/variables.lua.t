##../lua-debug
@implement_handlers+=
function handlers.variables(request)
  local args = request.arguments

  local ref = vars_ref[args.variablesReference]
  local variables = {}
  if type(ref) == "number" then
    @inspect_local_variables
    @inspect_up_values
  elseif type(ref) == "table" then
    @inspect_table_elements
  end

  sendProxyDAP(make_response(request, {
    body = {
      variables = variables,
    }
  }))
end

@inspect_local_variables+=
local a = 1
local frame = ref
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
if vim.startswith(ln, "(") then

@fill_variable_struct+=
v.name = tostring(ln)
v.variablesReference = 0
if type(lv) == "table" then
  @make_variable_reference_for_table
end
v.value = tostring(lv) 

@make_variable_reference_for_table+=
vars_ref[vars_id] = lv
v.variablesReference = vars_id
vars_id = vars_id + 1

@inspect_table_elements+=
for ln, lv in pairs(ref) do
    local v = {}
    @fill_variable_struct
    table.insert(variables, v)
end

@inspect_up_values+=
local func = debug.getinfo(frame).func
local a = 1
while true do
  local ln,lv = debug.getupvalue(func, a)
  if not ln then break end

  @omit_temporary_values
  else
    local v = {}
    @fill_variable_struct
    table.insert(variables, v)
  end
  a = a + 1
end
