##lua-debug
@wait_for_attach_message+=
local has_attach = false
for _,msg in ipairs(server_messages) do
  if msg.command == "attach" then
    has_attach = true
  end
end
