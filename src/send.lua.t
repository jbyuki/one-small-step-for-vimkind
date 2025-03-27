##lua-debug
@implement+=
function M.sendDAP(msg)
  @encode_json
  @log_send_dap
  if succ then
    @append_content_length
    @send_dap_to_client
  else
    log(encoded)
  end
end

@encode_json+=
local succ, encoded = pcall(json_encode, msg)

@append_content_length+=
local bin_msg = "Content-Length: " .. #encoded .. "\r\n\r\n" .. encoded

@send_dap_to_client+=
client:write(bin_msg)

@log_send_dap+=
log(vim.inspect(msg))
