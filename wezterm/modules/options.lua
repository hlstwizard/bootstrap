local M = {}
local platform = require("modules.platform")

local function supports_hardware_acceleration(wezterm)
	if not wezterm.gui or not wezterm.gui.enumerate_gpus then
		return false
	end

	local ok, gpus = pcall(wezterm.gui.enumerate_gpus)
	return ok and type(gpus) == "table" and #gpus > 0
end

local function get_front_end(wezterm)
	if supports_hardware_acceleration(wezterm) then
		return "WebGpu"
	end

	return "Software"
end

function M.apply(config, wezterm, constants)
	config.front_end = get_front_end(wezterm)
	config.font_size = 14.0
	config.color_scheme = "Bamboo Multiplex"
	config.enable_tab_bar = true
	config.hide_tab_bar_if_only_one_tab = false
	config.show_tabs_in_tab_bar = true
	config.use_fancy_tab_bar = false
	config.status_update_interval = 1000
	if not platform.is_windows(wezterm) then
		config.unix_domains = {
			{
				name = constants.DOMAIN_NAME,
			},
		}
		config.default_gui_startup_args = { "connect", constants.DOMAIN_NAME }
	end
	if platform.is_windows(wezterm) then
		config.default_prog = { "pwsh.exe", "-NoLogo" }
		config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
	else
		config.leader = { key = "Space", mods = "ALT", timeout_milliseconds = 1000 }
	end
end

return M
