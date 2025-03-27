##lua-debug
@start_reading+=
sock:read_start(vim.schedule_wrap(function(err, chunk)
  if chunk then
    @read_tcp
  else
    @send_disconnect
    sock:shutdown()
    sock:close()
  end
end))

@create_reading_coroutine+=
local dap_read = coroutine.create(function()
  @read_dap_protocol_message
  @send_back_initialize_response
  @send_back_initialized_event

  while true do
    @read_dap_protocol_message
    @add_message_to_hook_instance
  end
end)

@socket_variables+=
local tcp_data = ""

@create_reading_coroutine-=
local function read_header()
  while true do
    local content_length, rest = tcp_data:match("^Content%-Length: (%d+).-\r\n\r\n(.*)")
    if content_length then
      tcp_data = rest
      return { content_length = tonumber(content_length) }
    end

    coroutine.yield()
  end
end

@create_reading_coroutine-=
---@param length integer
local function read_body(length)
  while #tcp_data < length do
    coroutine.yield()
  end

  @decode_json_body
  @remove_body_from_tcp_data

  return decoded
end

@read_content_length+=
local content_length = tcp_data:match("^Content%-Length: (%d+)")

@remove_header_from_tcp_data+=
local _, sep = tcp_data:find("\r\n\r\n")
tcp_data = tcp_data:sub(sep + 1)

@decode_json_body+=
local body = tcp_data:sub(1, length)
-- TODO: Handle error?
local succ, decoded = pcall(json_decode, body)

@remove_body_from_tcp_data+=
tcp_data = tcp_data:sub(length + 1)

@read_tcp+=
tcp_data = tcp_data .. chunk
coroutine.resume(dap_read)

@read_dap_protocol_message+=
local msg
do
  local len = read_header()
  msg = read_body(len.content_length)
end

