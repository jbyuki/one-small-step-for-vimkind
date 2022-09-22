##../lua-debug
@declare+=
local log

@implement+=
function log(str)
  if log_filename then
    @write_to_logfile
  end

  -- required for regression testing
  if debug_output then
    table.insert(debug_output, tostring(str))
  else
    -- print(str)
  end
end

@script_variables+=
local log_filename

@init_logger+=
if opts and opts.log then
  log_filename = vim.fn.stdpath("data") .. "/osv.log"
end

@write_to_logfile+=
local f = io.open(log_filename, "a")
if f then
  f:write(str .. "\n")
  f:close()
end
