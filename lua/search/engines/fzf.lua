local M = {}
local fzf = require("fzf-lua")

-- 打开 fzf 窗口
M.open = function(func_name, opts)
	-- 转换选项格式以适应 fzf-lua
	local fzf_opts = M.convert_opts(opts)

	-- 映射 telescope 函数名到 fzf-lua 函数
	local func = M.get_function(func_name)

	-- 调用对应的 fzf-lua 函数
	return func(fzf_opts)
end

-- 获取窗口 ID
M.get_window_id = function()
	-- fzf-lua 识别当前窗口的逻辑
	return vim.api.nvim_get_current_win()
end

-- 从 telescope 函数映射到 fzf-lua 函数
M.get_function = function(func_or_name)
	-- fzf-lua 函数映射表
	local function_map = {
		["find_files"] = fzf.files,
		["git_files"] = fzf.git_files,
		["live_grep"] = fzf.grep_project,
		-- 添加更多映射...
	}

	if type(func_or_name) == "string" then
		return function_map[func_or_name]
	elseif type(func_or_name) == "function" then
		-- 自定义函数需要特殊处理
		return func_or_name
	end
end

-- 转换选项格式
M.convert_opts = function(telescope_opts)
	local fzf_opts = {}

	-- 从 telescope 选项转换为 fzf-lua 选项
	if telescope_opts.prompt_title then
		fzf_opts.prompt = telescope_opts.prompt_title
	end

	if telescope_opts.default_text then
		fzf_opts.query = telescope_opts.default_text
	end

	-- 添加更多选项转换...

	return fzf_opts
end

-- 获取命令行内容
M.get_prompt = function()
	return ""
end

return M
