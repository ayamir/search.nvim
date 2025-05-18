local M = {}

M.load = function(engine_name)
	if engine_name == "telescope" then
		return require("search.engines.telescope")
	elseif engine_name == "fzf" then
		return require("search.engines.fzf")
	else
		error("Unknown search engine: " .. engine_name)
	end
end

return M
