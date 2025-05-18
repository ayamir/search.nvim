-- lua/search/engines/telescope.lua
local M = {}
local builtin = require("telescope.builtin")

M.open = function(func_or_name, opts)
	local func = M.get_function(func_or_name)
	return func(opts)
end

M.get_function = function(func_or_name)
	-- telescope 函数映射表
	local function_map = {
		["find_files"] = builtin.find_files,
		["git_files"] = builtin.git_files,
		["live_grep"] = builtin.live_grep,
		["git_commits"] = builtin.git_commits,
		["git_branches"] = builtin.git_branches,
		["git_status"] = builtin.git_status,
	}

	if type(func_or_name) == "string" then
		return function_map[func_or_name]
	elseif type(func_or_name) == "function" then
		return func_or_name
	end
end

M.get_prompt = function()
	local current_prompt = vim.api.nvim_get_current_line()
	local prefix_len = #require("telescope.config").values.prompt_prefix or "> "
	return string.sub(current_prompt, prefix_len + 1)
end

return M
