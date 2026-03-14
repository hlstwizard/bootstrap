-- Pull in the wezterm API
local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.leader = { key = "\\", mods = "CTRL", timeout_milliseconds = 1000 }

-- Basic: split window like iTerm (Cmd+d)
config.keys = {
	{ mods = "LEADER", key = "p", action = wezterm.action.PaneSelect },
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
