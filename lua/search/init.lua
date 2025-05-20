local M = {}

local util = require("search.util")
local settings = require("search.settings")
local tab_bar = require("search.tab_bar")
local tabs = require("search.tabs")

--- opens the tab window and anchors it to the telescope window
--- @param win_id number the id of the telescope window
--- @return nil
local tab_window = function(win_id)
	local row = settings.prompt_position == "top" and -2 or vim.fn.winheight(win_id) + 1

	-- if the telescope window is closed, we exit early
	-- this can happen when the user holds down the tab key
	if prompt_width == -1 then
		return
	end

	-- create the tab bar window, anchoring it to the prompt window
	local tab_bar_win = tab_bar.create({
		relative = "win",
		win = win_id,
		width = vim.fn.winwidth(win_id),
		col = 0,
		row = row,
	})

	-- make this window disappear when the prompt window is closed
	local prompt_bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = prompt_bufnr,
		nested = true,
		once = true,
		callback = function()
			vim.api.nvim_win_close(tab_bar_win, true)
		end,
	})
end

--- opens the telescope window and sets the prompt to the one that was used before
local open_prompt = function(prompt, opts)
	M.busy = true
	local tab = tabs.current()

	-- since some telescope functions are linked to lsp, we need to make sure that we are in the correct buffer
	-- this would become an issue if we are coming from another tab
	if vim.api.nvim_get_current_win() ~= M.opened_on_win then
		vim.api.nvim_set_current_win(M.opened_on_win)
	end
	tab:start_waiting()

	-- Pass along any telescope options. Set the title to the tab name.
	local tele_opts = tab.tele_opts or {}
	tele_opts.prompt_title = tab.name

	-- Merge telescope options passed from different places.
	-- Merge telescope_opts and tab.tele_opts
	for k, v in pairs(opts or {}) do
		tele_opts[k] = v
	end

	local success = pcall(tab.tele_func, tele_opts)

	-- this (only) happens, if the telescope function actually errors out.
	-- if the telescope window does not open without error, this is not handled here
	if not success then
		M.busy = false
		tab:fail()
		M.continue_tab(false)
		return
	end

	-- find a better way to do this
	-- we might need to wait for the telescope window to open
	util.do_when(
		function()
			-- wait for the window change
			return M.opened_on_win ~= vim.api.nvim_get_current_win()
		end,
		function()
			tab:stop_waiting()
			local current_win_id = vim.api.nvim_get_current_win()
			util.set_keymap(vim.api.nvim_get_current_buf(), settings.keys)
			vim.api.nvim_input(prompt)
			tab_window(current_win_id)
			M.busy = false
		end,
		2000, -- wait for 2 second at most
		function()
			M.busy = false
			tab:fail()
			M.continue_tab(false)
		end
	)
end

M.direction = "next"

M.busy = false

M.continue_tab = function(remember)
	if M.direction == "next" then
		M.next_tab(remember)
	else
		M.previous_tab(remember)
	end
end

--- switches to the next tab, preserving the prompt
--- only switches to tabs that are available
M.next_tab = function(remember)
	remember = remember == nil and true or remember
	M.direction = "next"

	if M.busy then
		return
	end
	util.next_available()

	local prompt = ""
	if remember then
		prompt = util.get_prompt(vim.api.nvim_get_current_line())
	end

	open_prompt(prompt)
end

--- switches to the previous tab, preserving the prompt
M.previous_tab = function(remember)
	remember = remember == nil and true or remember
	M.direction = "previous"

	if M.busy then
		return
	end
	util.previous_available()

	local prompt = ""
	if remember then
		prompt = util.get_prompt(vim.api.nvim_get_current_line())
	end

	open_prompt(prompt)
end

--- remembers the prompt that was used before
--- resets the state of the search module
M.reset = function(opts)
	opts = opts or {}

	tabs.current_collection_id = "default"
	if opts.collection then
		tabs.current_collection_id = opts.collection
	end

	if opts.tab_id then
		tabs.set_by_id(opts.tab_id)
	elseif opts.tab_name then
		tabs.set_by_name(opts.tab_name)
	else
		tabs.initial_tab()
	end

	M.current_prompt = ""
	M.opened_on_win = -1
end

M.opened_on_win = -1

--- opens the telescope window with the current prompt
--- this is the function that should be called from the outside
M.open = function(opts)
	-- TODO: find a better way to do this
	-- this is just a workaround to make sure that the settings are initialized
	-- if the user did not call setup() themselves
	if not settings.initialized then
		settings.setup()
	end

	M.reset(opts)
	M.opened_on_win = vim.api.nvim_get_current_win()
	M.busy = true

	-- Pass along tele_opts to telescope
	local tele_func_opts = {}
	if opts ~= nil then
		tele_func_opts = opts.tele_opts or {}
		if tele_func_opts.default_text == nil then
			tele_func_opts.default_text = opts.default_text or ""
		end
	end
	open_prompt("", tele_func_opts)
end

-- configuration
M.setup = function(opts)
	settings.setup(opts)
end

return M
