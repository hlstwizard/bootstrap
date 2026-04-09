local wezterm = require("wezterm")
local mux = wezterm.mux

local config = wezterm.config_builder()
local act = wezterm.action

local constants = require("modules.constants")
local events = require("modules.events")
local keys = require("modules.keys")
local options = require("modules.options")
local presets = require("modules.presets")
local window = require("modules.window")

events.register(wezterm, mux, window.fit_window_to_active_screen)
presets.register(wezterm, act, constants.EVENTS)

options.apply(config, wezterm, constants)
config.keys = keys.build(wezterm, act, constants)

return config
