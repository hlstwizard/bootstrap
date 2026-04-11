local M = {}
local platform = require("modules.platform")

local function is_vim(pane)
	-- this is set by smart-splits.nvim and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local function split_nav(wezterm, directions, resize_or_move, key, move_mods, resize_mods)
	local mods = resize_or_move == "resize" and resize_mods or move_mods

	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
			elseif resize_or_move == "resize" then
				win:perform_action({ AdjustPaneSize = { directions[key], 3 } }, pane)
			else
				win:perform_action({ ActivatePaneDirection = directions[key] }, pane)
			end
		end),
	}
end

local function nav_bindings(wezterm, constants, mode, move_mods, resize_mods)
	local bindings = {}
	for _, key in ipairs(constants.NAV_KEYS) do
		table.insert(bindings, split_nav(wezterm, constants.NAV_DIRECTIONS, mode, key, move_mods, resize_mods))
	end

	return bindings
end

function M.build(wezterm, act, constants)
	local keys = {
		{ mods = "LEADER", key = "p", action = act.PaneSelect },
		{ key = "f", mods = "LEADER", action = act.QuickSelect },
		{ key = "x", mods = "LEADER", action = act.ActivateCopyMode },
		{ key = "Enter", mods = "LEADER", action = act.TogglePaneZoomState },
		{ key = "r", mods = "LEADER", action = act.EmitEvent(constants.EVENTS.PROMPT_TAB_TITLE) },
		{ key = "1", mods = "LEADER", action = act.EmitEvent(constants.EVENTS.PRESET_DEV_1) },
	}

	if platform.is_windows(wezterm) then
		table.insert(keys, { key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) })
		table.insert(keys, { key = "d", mods = "CTRL|ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) })
		table.insert(keys, { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) })
		table.insert(keys, {
			key = "l",
			mods = "CTRL|SHIFT",
			action = act.Multiple({
				act.ClearScrollback("ScrollbackAndViewport"),
				act.SendKey({ key = "l", mods = "CTRL" }),
			}),
		})

		for _, binding in ipairs(nav_bindings(wezterm, constants, "move", "CTRL", "ALT")) do
			table.insert(keys, binding)
		end

		for _, binding in ipairs(nav_bindings(wezterm, constants, "resize", "CTRL", "ALT")) do
			table.insert(keys, binding)
		end
	elseif platform.is_macos(wezterm) then
		table.insert(keys, { key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) })
		table.insert(keys, { key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) })
		table.insert(keys, { key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = false }) })
		table.insert(keys, {
			key = "l",
			mods = "CMD",
			action = act.Multiple({
				act.ClearScrollback("ScrollbackAndViewport"),
				act.SendKey({ key = "l", mods = "CTRL" }),
			}),
		})

		for _, binding in ipairs(nav_bindings(wezterm, constants, "move", "CTRL", "META")) do
			table.insert(keys, binding)
		end

		for _, binding in ipairs(nav_bindings(wezterm, constants, "resize", "CTRL", "META")) do
			table.insert(keys, binding)
		end
	else
		return keys
	end

	return keys
end

return M
