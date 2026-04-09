local M = {}

local function is_vim(pane)
	-- this is set by smart-splits.nvim and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local function split_nav(wezterm, directions, resize_or_move, key)
	local mods = resize_or_move == "resize" and "META" or "CTRL"

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

local function nav_bindings(wezterm, constants, mode)
	local bindings = {}
	for _, key in ipairs(constants.NAV_KEYS) do
		table.insert(bindings, split_nav(wezterm, constants.NAV_DIRECTIONS, mode, key))
	end

	return bindings
end

function M.build(wezterm, act, constants)
	local keys = {
		{ mods = "LEADER", key = "p", action = act.PaneSelect },
		{ key = "f", mods = "LEADER", action = act.QuickSelect },
		{ key = "x", mods = "LEADER", action = act.ActivateCopyMode },
		{ key = "r", mods = "LEADER", action = act.EmitEvent(constants.EVENTS.PROMPT_TAB_TITLE) },
		{ key = "1", mods = "LEADER", action = act.EmitEvent(constants.EVENTS.PRESET_DEV_1) },
		{ key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = false }) },
	}

	for _, binding in ipairs(nav_bindings(wezterm, constants, "move")) do
		table.insert(keys, binding)
	end

	for _, binding in ipairs(nav_bindings(wezterm, constants, "resize")) do
		table.insert(keys, binding)
	end

	return keys
end

return M
