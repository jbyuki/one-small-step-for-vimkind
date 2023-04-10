##lua-debug
@script_variables+=
local seq_id = 1

@declare+=
local make_response

@implement+=
function make_response(request, response)
  local msg = {
    type = "response",
    seq = seq_id,
    request_seq = request.seq,
    success = true,
    command = request.command
  }
  seq_id = seq_id + 1
  return vim.tbl_extend('error', msg, response)
end

@send_back_initialize_response+=
log(vim.inspect(msg))
M.sendDAP(make_response(msg, {
  body = {
		@support_capabilities
	}
}))

@declare+=
local make_event

@implement+=
function make_event(event)
  local msg = {
    type = "event",
    seq = seq_id,
    event = event,
  }
  seq_id = seq_id + 1
  return msg
end

@send_back_initialized_event+=
M.sendDAP(make_event('initialized'))
