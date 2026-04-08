-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux

local config = wezterm.config_builder()

local function supports_hardware_acceleration()
	if not wezterm.gui or not wezterm.gui.enumerate_gpus then
		return false
	end

	local ok, gpus = pcall(wezterm.gui.enumerate_gpus)
	return ok and type(gpus) == "table" and #gpus > 0
end

if supports_hardware_acceleration() then
	config.front_end = "WebGpu"
else
	config.front_end = "Software"
end

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

local function is_vim(pane)
	-- this is set by smart-splits.nvim and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	local mods = resize_or_move == "resize" and "META" or "CTRL"

	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
			elseif resize_or_move == "resize" then
				win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
			else
				win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
			end
		end),
	}
end

wezterm.on("preset-dev-1", function(window, pane)
	local cwd = pane:get_current_working_dir()

	pane:split({
		direction = "Left",
		size = 0.5,
		cwd = cwd,
		command = { args = { "gitui" } },
	})

	local right_bottom = pane:split({
		direction = "Bottom",
		size = 0.5,
		cwd = cwd,
		command = { args = { "opencode" } },
	})

	window:perform_action(wezterm.action.ActivatePaneDirection("Up"), right_bottom)
end)

-- Basic: split window like iTerm (Cmd+d)
config.keys = {
	{ mods = "LEADER", key = "p", action = wezterm.action.PaneSelect },
	{ key = "f", mods = "LEADER", action = wezterm.action.QuickSelect },
	{ key = "x", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	{ key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration },
	{ key = "1", mods = "LEADER", action = wezterm.action.EmitEvent("preset-dev-1") },
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

	-- smart-splits integration (Neovim + WezTerm)
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
}

return config
