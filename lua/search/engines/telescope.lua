-- lua/search/engines/telescope.lua
local M = {}
local builtin = require("telescope.builtin")

-- 打开 telescope 窗口
M.open = function(func_or_name, opts)
	-- 获取实际函数
	local func = M.get_function(func_or_name)

	-- 调用 telescope 函数
	return func(opts)
end

-- 获取窗口 ID
M.get_window_id = function()
	return vim.api.nvim_get_current_win()
end

-- 从字符串或函数获取实际的 telescope 函数
M.get_function = function(func_or_name)
	-- telescope 函数映射表
	local function_map = {
		["find_files"] = builtin.find_files,
		["git_files"] = builtin.git_files,
		["live_grep"] = builtin.live_grep,
		["git_commits"] = builtin.git_commits,
		["git_branches"] = builtin.git_branches,
		["git_status"] = builtin.git_status,
		-- 添加更多映射...
	}

	if type(func_or_name) == "string" then
		return function_map[func_or_name]
	elseif type(func_or_name) == "function" then
		return func_or_name
	end
end

-- 获取当前命令行内容
M.get_prompt = function()
	local current_prompt = vim.api.nvim_get_current_line()
	local prefix_len = #require("telescope.config").values.prompt_prefix or "> "
	return string.sub(current_prompt, prefix_len + 1)
end

-- 设置窗口关闭回调
M.on_close = function(window_id, callback)
	local buffer_id = vim.api.nvim_win_get_buf(window_id)
	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = buffer_id,
		nested = true,
		once = true,
		callback = callback,
	})
end

-- 设置 telescope 的按键映射

return M
