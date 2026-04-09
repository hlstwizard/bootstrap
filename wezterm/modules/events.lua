local M = {}

function M.register(wezterm, mux, fit_window_to_active_screen)
	wezterm.on("gui-startup", function(cmd)
		local _, _, window = mux.spawn_window(cmd or {})
		fit_window_to_active_screen(wezterm, window)
	end)

	wezterm.on("gui-attached", function()
		local workspace = mux.get_active_workspace()
		for _, window in ipairs(mux.all_windows()) do
			if window:get_workspace() == workspace then
				fit_window_to_active_screen(wezterm, window)
			end
		end
	end)
end

return M
