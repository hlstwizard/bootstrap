local M = {}

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
	config.unix_domains = {
		{
			name = constants.DOMAIN_NAME,
		},
	}
	config.default_gui_startup_args = { "connect", constants.DOMAIN_NAME }
	config.leader = { key = "Space", mods = "ALT", timeout_milliseconds = 1000 }
end

return M
