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
  while not string.find(tcp_data, "\r\n\r\n") do
    coroutine.yield()
  end
  @read_content_length
  @remove_header_from_tcp_data

  return {
    content_length = tonumber(content_length),
  }
end

@create_reading_coroutine-=
local function read_body(length)
  while string.len(tcp_data) < length do
    coroutine.yield()
  end

  @decode_json_body
  @remove_body_from_tcp_data

  return decoded
end

@read_content_length+=
local content_length = string.match(tcp_data, "^Content%-Length: (%d+)")

@remove_header_from_tcp_data+=
local _, sep = string.find(tcp_data, "\r\n\r\n")
tcp_data = string.sub(tcp_data, sep+1)

@decode_json_body+=
local body = string.sub(tcp_data, 1, length)
local succ, decoded = pcall(vim.fn.json_decode, body)

@remove_body_from_tcp_data+=
tcp_data = string.sub(tcp_data, length+1)

@read_tcp+=
tcp_data = tcp_data .. chunk
coroutine.resume(dap_read)

@read_dap_protocol_message+=
local msg
do
  local len = read_header()
  msg = read_body(len.content_length)
end

