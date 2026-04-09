local M = {}

function M.register(wezterm, act, events)
	wezterm.on(events.PRESET_DEV_1, function(window, pane)
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

		window:perform_action(act.ActivatePaneDirection("Up"), right_bottom)
	end)

	wezterm.on(events.PROMPT_TAB_TITLE, function(window, pane)
		window:perform_action(
			act.PromptInputLine({
				description = "Enter new tab title",
				action = wezterm.action_callback(function(win, _, line)
					if line then
						win:active_tab():set_title(line)
					end
				end),
			}),
			pane
		)
	end)
end

return M
