-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux

local config = wezterm.config_builder()

local function fit_window_to_active_screen(window)
	local gui_window = window:gui_window()
	if not gui_window then
		return
	end

	local screens = wezterm.gui and wezterm.gui.screens() or nil
	if screens and screens.active then
		gui_window:restore()
		gui_window:set_position(screens.active.x, screens.active.y)
	end

	gui_window:maximize()
end

wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	fit_window_to_active_screen(window)
end)

wezterm.on("gui-attached", function()
	local workspace = mux.get_active_workspace()
	for _, window in ipairs(mux.all_windows()) do
		if window:get_workspace() == workspace then
			fit_window_to_active_screen(window)
		end
	end
end)

config.font_size = 14.0

config.unix_domains = {
	{
		name = "unix",
	},
}

config.default_gui_startup_args = { "connect", "unix" }

config.leader = { key = "Space", mods = "ALT", timeout_milliseconds = 1000 }

-- Basic: split window like iTerm (Cmd+d)
config.keys = {
	{ mods = "LEADER", key = "p", action = wezterm.action.PaneSelect },
	{ key = "f", mods = "LEADER", action = wezterm.action.QuickSelect },
	{ key = "x", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	{ key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration },
	{
		key = "d",
		mods = "CMD",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "d",
		mods = "CMD|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "CMD",
		action = wezterm.action.CloseCurrentPane({ confirm = false }),
	},
}

return config
