##lua-debug
@script_variables+=
local redir_nvim_output = true
local nvim_exec2_opts = {}

@handle_nvim_output+=
if redir_nvim_output and not vim.in_fast_event() then
  -- Sets `g:_osv_nvim_output` with messages observed since last `:redir`.
  pcall(vim.api.nvim_exec2, 'silent redir END', nvim_exec2_opts)

  local ok, msgs = pcall(vim.api.nvim_get_var, '_osv_nvim_output')
  if ok then
    if type(msgs) ~= 'string' then
      error('expected g:_osv_nvim_output to be a string but got: ' .. msgs)
    elseif #msgs > 0 then
      local event = make_event 'output'
      event.body = { category = 'stdout', output = msgs }
      sendProxyDAP(event)
    end
  end

  -- Sets `g:_osv_nvim_output` as redir target for nvim messages, creates the
  -- variable if it doesn't already exist, and clears it. Messages are still
  -- displayed on-screen in debuggee as usual. This should also work when nvim
  -- is headless.
  pcall(vim.api.nvim_exec2, 'silent redir => g:_osv_nvim_output', nvim_exec2_opts)
end
