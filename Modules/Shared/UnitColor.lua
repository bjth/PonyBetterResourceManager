local ADDON_NAME, ns = ...;

-- Shared utility for unit color lookup (reaction colors)
-- This consolidates the unit color logic used by all frame types
-- Unit colors are based on the unit's reaction (hostile, neutral, friendly)

local UnitColor = {};

-- Get the appropriate unit color for a unit
-- Returns color table {r, g, b} or nil
-- unit: unit ID (e.g., "player", "target")
-- db: database profile (personalResource or targetResource)
function UnitColor:GetUnitColor(unit, db)
	if not unit then
		return nil;
	end
	
	-- Check if unit exists
	if not UnitExists(unit) then
		return nil;
	end
	
	-- Get unit reaction
	local reaction = UnitReaction(unit, "player");
	if not reaction then
		return nil;
	end
	
	-- Check global unit colors in profile
	local addon = ns.Addon;
	local profile = addon and addon.db and addon.db.profile;
	
	-- Check for unit color override in profile first (this allows overriding the blue color)
	-- This takes highest priority - if user sets a color for reaction 5 (Friendly), it overrides everything
	if profile and profile.unitColors and profile.unitColors[reaction] then
		return profile.unitColors[reaction];
	end
	
	-- Check if unit is a player or party member (friendly units that can have class colors)
	local isPlayer = UnitIsPlayer(unit);
	local isPartyMember = UnitInParty(unit);
	local isRaidMember = UnitInRaid(unit);
	local isFriendlyUnit = isPlayer or isPartyMember or isRaidMember;
	
	-- If unit is friendly and class color option is enabled, use class color instead of blue
	-- This only applies if no unit color override was set above
	if isFriendlyUnit and profile and profile.useClassColorForFriendly then
		local _, class = UnitClass(unit);
		if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
			local colorTable = RAID_CLASS_COLORS[class];
			return { r = colorTable.r, g = colorTable.g, b = colorTable.b };
		end
	end
	
	-- Fall back to Blizzard defaults using UnitSelectionColor
	-- UnitSelectionColor returns r, g, b for the unit's selection color (blue for friendly units)
	local r, g, b = UnitSelectionColor(unit);
	if r and g and b then
		return { r = r, g = g, b = b };
	end
	
	-- Fallback to reaction-based colors if UnitSelectionColor fails
	-- Reaction values: 1 = hated, 2 = hostile, 3 = unfriendly, 4 = neutral, 5 = friendly, 6 = honored, 7 = revered, 8 = exalted
	if FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction] then
		local color = FACTION_BAR_COLORS[reaction];
		return { r = color.r, g = color.g, b = color.b };
	end
	
	return nil;
end

-- Apply unit color to a status bar
-- statusBar: the status bar frame
-- unit: unit ID
-- db: database profile
function UnitColor:ApplyUnitColor(statusBar, unit, db)
	if not statusBar or not unit or not db then
		return;
	end
	
	-- Get unit color
	local color = self:GetUnitColor(unit, db);
	if color and color.r and color.g and color.b then
		statusBar:SetStatusBarColor(color.r, color.g, color.b);
	end
end

ns.UnitColor = UnitColor;

return UnitColor;

