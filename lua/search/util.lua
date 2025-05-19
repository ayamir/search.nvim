local M = {}

local tabs = require("search.tabs")

--- the amount of milliseconds to wait between checks
M.await_time = 10

--- runs a function when a condition is met
--- @param condition function a function that returns a boolean
--- @param callback function a function that is called when the condition is met
--- @param max_ms number the maximum amount of milliseconds to wait
--- @param fail_callback function a function that is called when the condition is not met in time
--- @return any the return value of the callback
M.do_when = function(condition, callback, max_ms, fail_callback)
	if max_ms == nil then
		max_ms = 1000
	end

	while max_ms > 0 do
		if condition() then
			return callback()
		end
		vim.wait(M.await_time)
		max_ms = max_ms - M.await_time
	end

	if fail_callback ~= nil then
		return fail_callback()
	end
end

M.set_keymap = function(buf_id, keys)
	local opts = { noremap = true, silent = true }
	local next_cmd = "<C-\\><C-n><cmd>lua require('search').next_tab()<CR>"
	local prev_cmd = "<C-\\><C-n><cmd>lua require('search').previous_tab()<CR>"

	local function set_mapping(keymap, cmd)
		if type(keymap) == "string" then
			-- set keymap for fzf
			vim.api.nvim_buf_set_keymap(buf_id, "t", keymap, cmd, opts)
			vim.api.nvim_buf_set_keymap(buf_id, "n", keymap, cmd, opts)
			vim.api.nvim_buf_set_keymap(buf_id, "i", keymap, cmd, opts)
		else
			for _, value in ipairs(keymap) do
				-- set keymap for fzf
				vim.api.nvim_buf_set_keymap(buf_id, "t", value[1], cmd, opts)
				vim.api.nvim_buf_set_keymap(buf_id, value[2], value[1], cmd, opts)
			end
		end
	end

	set_mapping(keys.next, next_cmd)
	set_mapping(keys.prev, prev_cmd)
end

M.get_prompt = function(line)
	line = vim.trim(line)
	local is_telescope_prompt = line:match("%d+/%d+ %(%d+%)$") == nil
	if is_telescope_prompt then
		local prefix_len = #require("telescope.config").values.prompt_prefix or "> "
		local prompt = vim.trim(string.sub(line, prefix_len))
		return prompt
	end

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

	local prompt = vim.trim(path:match("([^/]+)$"))
	prompt = vim.api.nvim_replace_termcodes(prompt, true, true, true)
	return prompt
end

--- switches to the next available tab
--- @return Tab # the next available tab
M.next_available = function()
	local start = tabs.current().id
	while true do
		local tab = tabs.next()
		if tab:is_available() then
			return tab
		end
		if tab.id == start then
			return tab
		end
	end
end

--- switches to the previous available tab
--- @return Tab # the previous available tab
M.previous_available = function()
	local start = tabs.current().id
	while true do
		local tab = tabs.previous()
		if tab:is_available() then
			return tab
		end
		if tab.id == start then
			return tab
		end
	end
end

return M
