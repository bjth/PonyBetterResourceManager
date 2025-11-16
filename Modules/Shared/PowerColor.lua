local ADDON_NAME, ns = ...;

-- Shared utility for power color lookup
-- This consolidates the power color logic used by all frame types

local PowerColor = {};

-- Get the appropriate power color for a unit
-- Returns color table {r, g, b} or nil
-- unit: unit ID (e.g., "player", "target")
-- db: database profile (personalResource or targetResource)
function PowerColor:GetPowerColor(unit, db)
	if not unit or not db then
		return nil;
	end
	
	local powerType, powerToken, altR, altG, altB = UnitPowerType(unit);
	if not powerToken then
		return nil;
	end
	
	-- Check global power colors in profile
	local addon = ns.Addon;
	if addon and addon.db and addon.db.profile then
		if addon.db.profile.powerColors and addon.db.profile.powerColors[powerToken] then
			return addon.db.profile.powerColors[powerToken];
		end
	end
	
	-- Fallback: check in provided db (for backward compatibility)
	if db.powerColors and db.powerColors[powerToken] then
		return db.powerColors[powerToken];
	end
	
	-- Fall back to Blizzard defaults
	if MANA_BAR_COLOR and MANA_BAR_COLOR[powerToken] then
		return MANA_BAR_COLOR[powerToken];
	elseif PowerBarColor and PowerBarColor[powerToken] then
		return PowerBarColor[powerToken];
	elseif altR then
		return { r = altR, g = altG, b = altB };
	elseif PowerBarColor and PowerBarColor[powerType] then
		return PowerBarColor[powerType];
	end
	
	return nil;
end

-- Apply power color to a status bar
-- statusBar: the status bar frame
-- unit: unit ID
-- db: database profile
-- overrideColor: if true, uses db.powerColor instead
function PowerColor:ApplyPowerColor(statusBar, unit, db, overrideColor)
	if not statusBar or not unit or not db then
		return;
	end
	
	-- If overriding, use the override color
	if overrideColor and db.powerColor then
		local r = db.powerColor.r or 1;
		local g = db.powerColor.g or 1;
		local b = db.powerColor.b or 1;
		local a = db.powerColor.a;
		if a ~= nil then
			statusBar:SetStatusBarColor(r, g, b, a);
		else
			statusBar:SetStatusBarColor(r, g, b);
		end
		return;
	end
	
	-- Otherwise, use power type color
	local color = self:GetPowerColor(unit, db);
	if color and color.r and color.g and color.b then
		statusBar:SetStatusBarColor(color.r, color.g, color.b);
	end
end

ns.PowerColor = PowerColor;

return PowerColor;

