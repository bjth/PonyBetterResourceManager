local ADDON_NAME, ns = ...;

ns.Defaults = {
	profile = {
		general = {
			enabled = true,
		},
		-- Global power type color overrides (applies to all frames)
		powerColors = {
			MANA = { r = 0.1, g = 0.25, b = 1.0 },
			RAGE = { r = 1.0, g = 0.0, b = 0.0 },
			ENERGY = { r = 1.0, g = 0.96, b = 0.41 },
			FOCUS = { r = 1.0, g = 0.5, b = 0.25 },
			RUNIC_POWER = { r = 0.0, g = 0.82, b = 1.0 },
			SOUL_SHARDS = { r = 0.58, g = 0.51, b = 0.79 },
			LUNAR_POWER = { r = 0.3, g = 0.52, b = 0.9 },
			HOLY_POWER = { r = 0.95, g = 0.9, b = 0.6 },
			MAELSTROM = { r = 0.0, g = 0.78, b = 0.92 },
			INSANITY = { r = 0.4, g = 0.0, b = 0.8 },
			CHI = { r = 0.71, g = 0.92, b = 0.98 },
			ARCANE_CHARGES = { r = 0.1, g = 0.5, b = 1.0 },
			COMBO_POINTS = { r = 1.0, g = 0.96, b = 0.41 },
			FURY = { r = 0.78, g = 0.26, b = 0.22 },
			PAIN = { r = 0.9, g = 0.0, b = 0.0 },
		},
		personalResource = {
			enabled = true,

			-- Visuals
			healthTexture = "Blizzard",
			powerTexture = "Blizzard",
			alternatePowerTexture = "Blizzard",

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
			
			-- Overheal and absorb styling
			overhealColor = { r = 0.0, g = 0.659, b = 0.608 },
			overhealTexture = nil, -- nil = use default
			absorbColor = { r = 0.0, g = 0.8, b = 1.0 },
			absorbTexture = nil, -- nil = use default
			showOverheal = true,
			showAbsorb = true,
			
			-- Background support
			healthBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			powerBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},

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
		targetResource = {
			enabled = false,
			
			-- Visuals (reuse same structure as personalResource)
			healthTexture = "Blizzard",
			powerTexture = "Blizzard",
			
			-- Border styling
			healthBorderStyle = "Default",
			healthBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			healthBorderSize = 1.0,
			powerBorderStyle = "Default",
			powerBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			powerBorderSize = 1.0,
			
			-- Colors
			overrideHealthColor = false,
			healthColor = { r = 0.0, g = 0.8, b = 0.0, a = 1.0 },
			overridePowerColor = false,
			powerColor = { r = 0.0, g = 0.4, b = 1.0, a = 1.0 },
			
			-- Overheal and absorb styling
			overhealColor = { r = 0.0, g = 0.659, b = 0.608 },
			overhealTexture = nil, -- nil = use default
			absorbColor = { r = 0.0, g = 0.8, b = 1.0 },
			absorbTexture = nil, -- nil = use default
			showOverheal = true,
			showAbsorb = true,
			
			-- Background support
			healthBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			powerBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			
			-- Layout
			scale = 1.0,
			healthWidth = 200,
			healthHeight = 20,
			powerWidth = 200,
			powerHeight = 12,
			healthOffsetX = 0,
			healthOffsetY = 0,
			powerOffsetX = 0,
			powerOffsetY = 0,
			
			-- Visibility
			showHealthBar = true,
			showPowerBar = true,
			
			-- Texts (same structure as personalResource)
			healthTextEnabled = false,
			textDefaultFont = "FRIZQT",
			textDefaultSize = 18,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {},
		},
		focusResource = {
			enabled = false,
			
			-- Visuals (reuse same structure as targetResource)
			healthTexture = "Blizzard",
			powerTexture = "Blizzard",
			
			-- Border styling
			healthBorderStyle = "Default",
			healthBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			healthBorderSize = 1.0,
			powerBorderStyle = "Default",
			powerBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			powerBorderSize = 1.0,
			
			-- Colors
			overrideHealthColor = false,
			healthColor = { r = 0.0, g = 0.8, b = 0.0, a = 1.0 },
			overridePowerColor = false,
			powerColor = { r = 0.0, g = 0.4, b = 1.0, a = 1.0 },
			
			-- Overheal and absorb styling
			overhealColor = { r = 0.0, g = 0.659, b = 0.608 },
			overhealTexture = nil,
			absorbColor = { r = 0.0, g = 0.8, b = 1.0 },
			absorbTexture = nil,
			showOverheal = true,
			showAbsorb = true,
			
			-- Background support
			healthBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			powerBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			
			-- Layout
			scale = 1.0,
			healthWidth = 200,
			healthHeight = 20,
			powerWidth = 200,
			powerHeight = 12,
			healthOffsetX = 0,
			healthOffsetY = 0,
			powerOffsetX = 0,
			powerOffsetY = 0,
			
			-- Visibility
			showHealthBar = true,
			showPowerBar = true,
			hideFocusFrame = false,
			
			-- Texts
			healthTextEnabled = false,
			textDefaultFont = "FRIZQT",
			textDefaultSize = 18,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {},
		},
		petResource = {
			enabled = false,
			
			-- Visuals (reuse same structure as targetResource)
			healthTexture = "Blizzard",
			powerTexture = "Blizzard",
			
			-- Border styling
			healthBorderStyle = "Default",
			healthBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			healthBorderSize = 1.0,
			powerBorderStyle = "Default",
			powerBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			powerBorderSize = 1.0,
			
			-- Colors
			overrideHealthColor = false,
			healthColor = { r = 0.0, g = 0.8, b = 0.0, a = 1.0 },
			overridePowerColor = false,
			powerColor = { r = 0.0, g = 0.4, b = 1.0, a = 1.0 },
			
			-- Overheal and absorb styling
			overhealColor = { r = 0.0, g = 0.659, b = 0.608 },
			overhealTexture = nil,
			absorbColor = { r = 0.0, g = 0.8, b = 1.0 },
			absorbTexture = nil,
			showOverheal = true,
			showAbsorb = true,
			
			-- Background support
			healthBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			powerBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			
			-- Layout
			scale = 1.0,
			healthWidth = 200,
			healthHeight = 20,
			powerWidth = 200,
			powerHeight = 12,
			healthOffsetX = 0,
			healthOffsetY = 0,
			powerOffsetX = 0,
			powerOffsetY = 0,
			
			-- Visibility
			showHealthBar = true,
			showPowerBar = true,
			hidePetFrame = false,
			
			-- Texts
			healthTextEnabled = false,
			textDefaultFont = "FRIZQT",
			textDefaultSize = 18,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {},
		},
		targetOfTargetResource = {
			enabled = false,
			
			-- Visuals (reuse same structure as targetResource)
			healthTexture = "Blizzard",
			powerTexture = "Blizzard",
			
			-- Border styling
			healthBorderStyle = "Default",
			healthBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			healthBorderSize = 1.0,
			powerBorderStyle = "Default",
			powerBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			powerBorderSize = 1.0,
			
			-- Colors
			overrideHealthColor = false,
			healthColor = { r = 0.0, g = 0.8, b = 0.0, a = 1.0 },
			overridePowerColor = false,
			powerColor = { r = 0.0, g = 0.4, b = 1.0, a = 1.0 },
			
			-- Overheal and absorb styling
			overhealColor = { r = 0.0, g = 0.659, b = 0.608 },
			overhealTexture = nil,
			absorbColor = { r = 0.0, g = 0.8, b = 1.0 },
			absorbTexture = nil,
			showOverheal = true,
			showAbsorb = true,
			
			-- Background support
			healthBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			powerBarBackground = {
				enabled = false,
				texture = "Interface\\TargetingFrame\\UI-StatusBar",
				color = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			},
			
			-- Layout
			scale = 1.0,
			healthWidth = 200,
			healthHeight = 20,
			powerWidth = 200,
			powerHeight = 12,
			healthOffsetX = 0,
			healthOffsetY = 0,
			powerOffsetX = 0,
			powerOffsetY = 0,
			
			-- Visibility
			showHealthBar = true,
			showPowerBar = true,
			hideTargetOfTargetFrame = false,
			
			-- Texts
			healthTextEnabled = false,
			textDefaultFont = "FRIZQT",
			textDefaultSize = 18,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {},
		},
	},
};


