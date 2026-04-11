local M = {}

local function target_triple(wezterm)
	return wezterm.target_triple or ""
end

function M.is_windows(wezterm)
	return target_triple(wezterm):find("windows", 1, true) ~= nil
end

function M.is_macos(wezterm)
	local triple = target_triple(wezterm)
	return triple:find("apple", 1, true) ~= nil or triple:find("darwin", 1, true) ~= nil
end

return M
