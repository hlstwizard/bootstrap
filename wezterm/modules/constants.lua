local M = {}

M.DOMAIN_NAME = "unix"

M.NAV_DIRECTIONS = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

M.NAV_KEYS = { "h", "j", "k", "l" }

M.EVENTS = {
	PRESET_DEV_1 = "preset-dev-1",
	PROMPT_TAB_TITLE = "trigger-tab-title",
}

return M
