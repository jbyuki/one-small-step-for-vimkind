##../lua-debug
@implement+=
function M.start_trace()
	@line_hook
	@clear_cache
	@attach_line_hook
end

@implement+=
function M.stop_trace()
	@deattach_line_hook
	@list_executed_modules
end

@line_hook+=
function line_hook(event, line)
	local surface = 0
	@get_surface_stack_frame

	local info = debug.getinfo(surface, "S")
	local source_path = info.source
	@add_to_cache
end

@script_variables+=
local cache = {}

@clear_cache+=
cache = {}

@add_to_cache+=
cache[source_path] = cache[source_path] or {}
table.insert(cache[source_path], line)

@attach_line_hook+=
debug.sethook(line_hook, "l")

@deattach_line_hook+=
debug.sethook()

@list_executed_modules+=
@uniquify_lines_number
return cache

@uniquify_lines_number+=
local sources = vim.tbl_keys(cache)
for _, source in ipairs(sources) do
	local line_set = {}

	for _, linenr in ipairs(cache[source]) do
		line_set[linenr] = true
	end

	line_set = vim.tbl_keys(line_set)
	table.sort(line_set)
	cache[source] = line_set
end
