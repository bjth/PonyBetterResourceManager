local ADDON_NAME, ns = ...;

-- PUF Defaults Configuration
-- This module provides default settings that mirror ShadowedUnitFrames (SUF) appearance
local PUFDefaults = {};
ns.PUFDefaults = PUFDefaults;

-- Deep copy helper function
local function DeepCopy(orig)
	local orig_type = type(orig);
	local copy;
	if orig_type == "table" then
		copy = {};
		for orig_key, orig_value in next, orig, nil do
			copy[DeepCopy(orig_key)] = DeepCopy(orig_value);
		end
		setmetatable(copy, DeepCopy(getmetatable(orig)));
	else
		copy = orig;
	end
	return copy;
end

-- Get SUF-like default profile configuration
function PUFDefaults:GetSUFDefaults()
	-- Use Blizzard's smooth texture (Raid-Bar-Hp-Fill) for SUF-like appearance
	-- This is registered as "PBRM Smooth" in Media.lua
	local smoothTexture = "PBRM Smooth";
	
	return {
		general = {
			enabled = true,
		},
		-- Global power type color overrides (matching SUF defaults from LoadUnitDefaults and CheckUpgrade)
		-- Note: SUF revision 62 added ESSENCE power color
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
			ESSENCE = { r = 0.40, g = 0.80, b = 1.00 }, -- Added in SUF revision 62 for Evoker
		},
		personalResource = {
			enabled = true,
			
			-- Hide Blizzard PlayerFrame when our frame is enabled (SUF default behavior)
			hidePlayerFrame = true,
			
			-- Visuals - Use smooth texture for SUF-like appearance
			healthTexture = smoothTexture,
			powerTexture = smoothTexture,
			alternatePowerTexture = smoothTexture,
			
			-- Border styling
			healthBorderStyle = "Default",
			healthBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			healthBorderSize = 1.0,
			powerBorderStyle = "Default",
			powerBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			powerBorderSize = 1.0,
			
			-- Colors - Class-colored health, power-type colored power (SUF default)
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
			
			-- Background support (typically disabled in SUF)
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
			healthWidth = 120,
			healthHeight = 12,
			powerWidth = 120,
			powerHeight = 8,
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
			
			-- Texts - Clean minimal style: Name - Level on health left, health value on health right, power value - percentage on power left
			healthTextEnabled = true,
			healthTextFormat = "CURRENT", -- Legacy format (used as fallback when no custom texts exist)
			textDefaultFont = "FRIZQT",
			textDefaultSize = 12,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {
				-- Text 1: Name - Level on health bar, left side
				{
					name = "Name",
					enabled = true,
					resourceType = "PERSONAL",
					target = "HEALTH",
					anchor = "LEFT",
					x = 3,
					y = 0,
					format = "{name} - {level}",
					size = 12,
				},
				-- Text 2: Health value (short format) on health bar, right side
				{
					name = "Health Value",
					enabled = true,
					resourceType = "PERSONAL",
					target = "HEALTH",
					anchor = "RIGHT",
					x = -3,
					y = 0,
					format = "{hp:short}",
					size = 11,
				},
				-- Text 3: Power value - percentage on power bar, left side
				{
					name = "Power Value",
					enabled = true,
					resourceType = "PERSONAL",
					target = "POWER",
					anchor = "LEFT",
					x = 3,
					y = 0,
					format = "{power:short} - {power:percent}",
					size = 11,
				},
			},
		},
		targetResource = {
			enabled = true, -- SUF enables target by default
			
			-- Hide Blizzard TargetFrame when our frame is enabled (SUF default behavior)
			hideTargetFrame = true,
			
			-- Visuals
			healthTexture = smoothTexture,
			powerTexture = smoothTexture,
			
			-- Border styling
			healthBorderStyle = "Default",
			healthBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			healthBorderSize = 1.0,
			powerBorderStyle = "Default",
			powerBorderColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 },
			powerBorderSize = 1.0,
			
			-- Colors - Class-colored health, power-type colored power
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
			
			-- Layout - Typical SUF target frame size
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
			
			-- Texts - Clean minimal style: Name - Level Elite above health bar, health value - percentage on health bar
			healthTextEnabled = true,
			healthTextFormat = "CURRENT", -- Legacy format (used as fallback when no custom texts exist)
			textDefaultFont = "FRIZQT",
			textDefaultSize = 12,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {
				-- Text 1: Name - Level Elite above health bar (using TOP anchor with positive y offset)
				{
					name = "Name",
					enabled = true,
					resourceType = "TARGET",
					target = "HEALTH",
					anchor = "TOP",
					x = 0,
					y = 2,
					format = "{name} - {smartlevel}",
					size = 12,
				},
				-- Text 2: Health value - percentage on health bar, centered
				{
					name = "Health Value",
					enabled = true,
					resourceType = "TARGET",
					target = "HEALTH",
					anchor = "CENTER",
					x = 0,
					y = 0,
					format = "{hp:short} - {hp:percent}",
					size = 11,
				},
			},
		},
		focusResource = {
			enabled = true, -- SUF enables focus by default
			
			-- Hide Blizzard FocusFrame when our frame is enabled (SUF default behavior)
			hideFocusFrame = true,
			
			-- Visuals
			healthTexture = smoothTexture,
			powerTexture = smoothTexture,
			
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
			
			-- Texts - Clean minimal style: Name - Level above health bar, health value - percentage on health bar
			healthTextEnabled = true,
			healthTextFormat = "CURRENT", -- Legacy format (used as fallback when no custom texts exist)
			textDefaultFont = "FRIZQT",
			textDefaultSize = 12,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {
				-- Text 1: Name - Level above health bar
				{
					name = "Name",
					enabled = true,
					resourceType = "FOCUS",
					target = "HEALTH",
					anchor = "TOP",
					x = 0,
					y = 2,
					format = "{name} - {smartlevel}",
					size = 12,
				},
				-- Text 2: Health value - percentage on health bar, centered
				{
					name = "Health Value",
					enabled = true,
					resourceType = "FOCUS",
					target = "HEALTH",
					anchor = "CENTER",
					x = 0,
					y = 0,
					format = "{hp:short} - {hp:percent}",
					size = 11,
				},
			},
		},
		petResource = {
			enabled = true, -- SUF enables pet by default
			
			-- Hide Blizzard PetFrame when our frame is enabled (SUF default behavior)
			hidePetFrame = true,
			
			-- Visuals
			healthTexture = smoothTexture,
			powerTexture = smoothTexture,
			
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
			
			-- Texts - Clean minimal style: Name above health bar, health value - percentage on health bar
			healthTextEnabled = true,
			healthTextFormat = "CURRENT", -- Legacy format (used as fallback when no custom texts exist)
			textDefaultFont = "FRIZQT",
			textDefaultSize = 12,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {
				-- Text 1: Name above health bar
				{
					name = "Name",
					enabled = true,
					resourceType = "PET",
					target = "HEALTH",
					anchor = "TOP",
					x = 0,
					y = 2,
					format = "{name}",
					size = 12,
				},
				-- Text 2: Health value - percentage on health bar, centered
				{
					name = "Health Value",
					enabled = true,
					resourceType = "PET",
					target = "HEALTH",
					anchor = "CENTER",
					x = 0,
					y = 0,
					format = "{hp:short} - {hp:percent}",
					size = 11,
				},
			},
		},
		targetOfTargetResource = {
			enabled = true, -- SUF enables target of target by default
			
			-- Hide Blizzard TargetFrameToT when our frame is enabled (SUF default behavior)
			hideTargetOfTargetFrame = true,
			
			-- Visuals
			healthTexture = smoothTexture,
			powerTexture = smoothTexture,
			
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
			
			-- Texts - Clean minimal style: Name above health bar, health value - percentage on health bar
			healthTextEnabled = true,
			healthTextFormat = "CURRENT", -- Legacy format (used as fallback when no custom texts exist)
			textDefaultFont = "FRIZQT",
			textDefaultSize = 12,
			textDefaultColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
			texts = {
				-- Text 1: Name above health bar
				{
					name = "Name",
					enabled = true,
					resourceType = "TARGETOFTARGET",
					target = "HEALTH",
					anchor = "TOP",
					x = 0,
					y = 2,
					format = "{name}",
					size = 12,
				},
				-- Text 2: Health value - percentage on health bar, centered
				{
					name = "Health Value",
					enabled = true,
					resourceType = "TARGETOFTARGET",
					target = "HEALTH",
					anchor = "CENTER",
					x = 0,
					y = 0,
					format = "{hp:short} - {hp:percent}",
					size = 11,
				},
			},
		},
	};
end

-- Export deep copy function for use in Core.lua
PUFDefaults.DeepCopy = DeepCopy;

