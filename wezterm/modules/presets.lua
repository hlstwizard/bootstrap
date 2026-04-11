local M = {}
local platform = require("modules.platform")

local function shell_command(wezterm, command)
	if platform.is_windows(wezterm) then
		return { "pwsh", "-NoLogo", "-NoExit", "-Command", command }
	end

	local shell = os.getenv("SHELL") or "/bin/zsh"
	return { shell, "-lic", "exec " .. command }
end

local function resolve_pane_cwd(pane)
	local cwd_uri = pane:get_current_working_dir()
	if cwd_uri and cwd_uri.file_path then
		return cwd_uri.file_path
	end

	return os.getenv("HOME")
end

function M.register(wezterm, act, events)
	wezterm.on(events.PRESET_DEV_1, function(window, pane)
		local cwd = resolve_pane_cwd(pane)

		pane:split({
			direction = "Left",
			size = 0.5,
			cwd = cwd,
			args = shell_command(wezterm, "gitui"),
		})

		local right_bottom = pane:split({
			direction = "Bottom",
			size = 0.5,
			cwd = cwd,
			args = shell_command(wezterm, "opencode"),
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
