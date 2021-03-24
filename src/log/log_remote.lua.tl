##../lua-debug
@declare+=
local log

@implement+=
function log(str)
  if debug_output then
    table.insert(debug_output, tostring(str))
  else
    print(str)
  end
end
