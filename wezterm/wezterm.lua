-- Pull in the wezterm API
local wezterm = require("wezterm")

local config = wezterm.config_builder()

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
