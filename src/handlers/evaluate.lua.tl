##../lua-debug
@implement_handlers+=
function handlers.evaluate(request)
  local args = request.arguments
  if args.context == "repl" then
    @retrieve_locals_in_frame
    @set_frame_environment_for_execution
    @evaluate_expression
    @send_repl_evaluate_response
  else
    log("evaluate context " .. args.context .. " not supported!")
  end
end

@retrieve_locals_in_frame+=
local frame = frames[args.frameId]
-- what is this abomination...
--              a former c++ programmer
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
    prev = cur

    cur = {}
    setmetatable(prev, {
      __index = cur
    })

    frame = frame + 1
    a = 1
  else
    cur[ln] = lv
    a = a + 1
  end
end

setmetatable(cur, {
  __index = _G
})

@set_frame_environment_for_execution+=
local succ, f = pcall(loadstring, "return " .. args.expression)
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

@send_repl_evaluate_response+=
sendProxyDAP(make_response(request, {
  body = {
    result = vim.inspect(result_repl),
    variablesReference = 0,
  }
}))
