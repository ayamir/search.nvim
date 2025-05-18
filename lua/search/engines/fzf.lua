local M = {}
local fzf = require("fzf-lua")

M.open = function(func_name, opts)
	local fzf_opts = M.convert_opts(opts)

	local func = M.get_function(func_name)

	return func(fzf_opts)
end

-- 从 telescope 函数映射到 fzf-lua 函数
M.get_function = function(func_or_name)
	local function_map = {
		["find_files"] = fzf.files,
		["git_files"] = fzf.git_files,
		["live_grep"] = fzf.grep_project,
	}

	if type(func_or_name) == "string" then
		return function_map[func_or_name]
	elseif type(func_or_name) == "function" then
		return func_or_name
	end
end

-- 转换选项格式
M.convert_opts = function(telescope_opts)
	local fzf_opts = {}

	if telescope_opts.prompt_title then
		fzf_opts.prompt = telescope_opts.prompt_title
	end

	if telescope_opts.default_text then
		fzf_opts.query = telescope_opts.default_text
	end

	return fzf_opts
end

-- 获取命令行内容
M.get_prompt = function()
	local line = vim.api.nvim_get_current_line()
	line = line:gsub("^%s*[^%w%.%-_/]*", "")

	local parts = {}
	for word in line:gmatch("%S+") do
		table.insert(parts, word)
	end
	if #parts < 3 then
		return ""
	end

	local path = parts[#parts - 2]

	if path:sub(-1) == "/" then
		return ""
	end

	local name = path:match("([^/]+)$")
	return vim.trim(name)
end

return M
