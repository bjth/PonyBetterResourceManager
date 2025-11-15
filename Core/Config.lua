local ADDON_NAME, ns = ...;

ns.Defaults = {
	profile = {
		general = {
			enabled = true,
		},
		personalResource = {
			enabled = true,

			-- Visuals
			healthTexture = "Blizzard",
			powerTexture = "Blizzard",
			alternatePowerTexture = "Blizzard",
			borderAlpha = 0.5,

			-- Border styling
			healthBorderStyle = "Default",
			healthBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			healthBorderSize = 1.0,
			powerBorderStyle = "Default",
			powerBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			powerBorderSize = 1.0,

			-- Colors (nil means use Blizzard's defaults / class colors)
			overrideHealthColor = false,
			healthColor = { r = 0.0, g = 0.8, b = 0.0, a = 1.0 },

			overridePowerColor = false,
			powerColor = { r = 0.0, g = 0.4, b = 1.0, a = 1.0 },

			-- Layout
			scale = 1.0,

			-- Size controls (applied on top of Blizzard's layout)
			healthWidth = 120,
			healthHeight = 12,
			powerWidth = 120,
			powerHeight = 8,

			-- Per-bar offsets
			healthOffsetX = 0,
			healthOffsetY = 0,
			powerOffsetX = 0,
			powerOffsetY = 0,
			classOffsetX = 0,
			classOffsetY = 0,

			-- Visibility toggles
			showHealthBar = true,
			showPowerBar = true,
			showAlternatePowerBar = true,
			showClassResourceBar = true,

			-- Texts
			-- Master toggle for all personal resource texts.
			healthTextEnabled = false,
			-- Legacy single-text format (used as a fallback when no custom texts exist).
			healthTextFormat = "CURRENT",
			-- Global defaults for dynamically defined texts.
			textDefaultFont = "FRIZQT", -- See Style.lua for mapping to real font paths.
			textDefaultSize = 18,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			-- Dynamic text definitions. Each entry can target different bars.
			-- Empty by default; users can add entries via the UI.
			texts = {},
		},
	},
};


