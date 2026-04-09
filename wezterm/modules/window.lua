local M = {}

local function active_screen_origin(wezterm)
	local screens = wezterm.gui and wezterm.gui.screens() or nil
	if screens and screens.active then
		return screens.active.x, screens.active.y
	end

	return nil, nil
end

function M.fit_window_to_active_screen(wezterm, window)
	local gui_window = window:gui_window()
	if not gui_window then
		return
	end

	local x, y = active_screen_origin(wezterm)
	if x and y then
		gui_window:restore()
		gui_window:set_position(x, y)
	end

	gui_window:maximize()
end

return M
