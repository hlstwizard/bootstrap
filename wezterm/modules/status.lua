local M = {}
local platform = require("modules.platform")

local function decode_uri_component(text)
	if not text or text == "" then
		return ""
	end

	return text:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
end

local function normalize_path(path, is_windows)
	if not path or path == "" then
		return "~"
	end

	path = decode_uri_component(path)

	if is_windows then
		path = path:gsub("^/([A-Za-z]:)", "%1")
		path = path:gsub("/", "\\")
		return path
	end

	path = path:gsub("\\", "/")
	return path
end

local function get_hostname_and_cwd(wezterm, pane)
	local is_windows = platform.is_windows(wezterm)
	local cwd_uri = pane:get_current_working_dir()
	if not cwd_uri then
		return wezterm.hostname(), "~"
	end

	local cwd = ""
	local hostname = ""

	if type(cwd_uri) == "userdata" then
		cwd = cwd_uri.file_path or ""
		hostname = cwd_uri.host or wezterm.hostname()
	else
		local raw = cwd_uri:gsub("^file://", "")
		local parsed_host, parsed_path = raw:match("^([^/]*)(/.*)$")
		hostname = parsed_host or ""
		cwd = parsed_path or raw
	end

	local dot = hostname:find("[.]")
	if dot then
		hostname = hostname:sub(1, dot - 1)
	end
	if hostname == "" then
		hostname = wezterm.hostname()
	end

	return hostname, normalize_path(cwd, is_windows)
end

function M.register(wezterm)
	wezterm.on("update-right-status", function(window, pane)
		-- Each element holds the text for a cell in a compact style.
		local cells = {}

		local hostname, dir = get_hostname_and_cwd(wezterm, pane)
		table.insert(cells, string.format(" %s %s ", utf8.char(0xf07c), dir))
		table.insert(cells, string.format(" %s %s ", utf8.char(0xf109), hostname))

		local date = wezterm.strftime(" %a %b %-d %H:%M ")
		table.insert(cells, date)

		for _, b in ipairs(wezterm.battery_info()) do
			table.insert(cells, string.format(" %s %.0f%% ", utf8.char(0xf240), b.state_of_charge * 100))
		end

		local palette = {
			bg = "#1f2528",
			cell = "#2a3135",
			sep = "#465057",
			text = "#d9e0d8",
		}

		local elements = {}
		table.insert(elements, { Background = { Color = palette.bg } })

		for i, cell in ipairs(cells) do
			table.insert(elements, { Foreground = { Color = palette.text } })
			table.insert(elements, { Background = { Color = palette.cell } })
			table.insert(elements, { Text = cell })

			if i < #cells then
				table.insert(elements, { Foreground = { Color = palette.sep } })
				table.insert(elements, { Background = { Color = palette.bg } })
				table.insert(elements, { Text = utf8.char(0xe0b3) })
			end
		end

		window:set_right_status(wezterm.format(elements))
	end)
end

return M
