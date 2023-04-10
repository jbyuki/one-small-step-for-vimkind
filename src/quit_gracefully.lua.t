##lua-debug
@script_variables+=
local exit_autocmd

@unregister_exit_autocmd+=
if exit_autocmd then
	vim.api.nvim_del_autocmd(exit_autocmd)
	exit_autocmd = nil
end

@create_autocommand_when_exit+=
exit_autocmd = vim.api.nvim_create_autocmd({"VimLeavePre"}, {
	callback = function(...)
		M.stop()
	end
})

