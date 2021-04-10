##../lua-debug
@implement_handlers+=
function handlers.scopes(request)
  local args = request.arguments
  local frame = frames[args.frameId]
  if not frame then 
    log("Frame not found!")
    return 
  end


  local scopes = {}

  @put_local_scope

  sendProxyDAP(make_response(request,{
    body = {
      scopes = scopes,
    };
  }))
end

@script_variables+=
local vars_id = 1
local vars_ref = {}

@put_local_scope+=
local a = 1
local local_scope = {}
local_scope.name = "Locals"
local_scope.presentationHint = "locals"
local_scope.variablesReference = vars_id
local_scope.expensive = false

vars_ref[vars_id] = frame
vars_id = vars_id + 1

table.insert(scopes, local_scope)
