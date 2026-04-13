local M = {}

function M.fit_window_to_active_screen(window)
	local gui_window = window:gui_window()
	if not gui_window then
		return
	end

	gui_window:restore()
	gui_window:maximize()
end

return M
