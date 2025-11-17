local ADDON_NAME, ns = ...;

local addon = ns.Addon;

local UnitColorOptions = {};
ns.UnitColorOptions = UnitColorOptions;

local function GetDB()
	-- Unit colors are stored globally in the profile
	return addon.db and addon.db.profile;
end

local function Get(info)
	local db = GetDB();
	if not db then
		return;
	end
	
	local key = info[#info];
	
	-- Handle unit color overrides (e.g., "unitColor_1", "unitColor_2")
	local unitColorMatch = key:match("^unitColor_(.+)$");
	if unitColorMatch then
		local reaction = tonumber(unitColorMatch);
		if reaction and db.unitColors and db.unitColors[reaction] then
			local color = db.unitColors[reaction];
			return color.r, color.g, color.b, color.a or 1.0;
		end
		-- Return Blizzard default if not set
		if FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction] then
			local color = FACTION_BAR_COLORS[reaction];
			return color.r, color.g, color.b, color.a or 1.0;
		end
		-- Fallback to UnitSelectionColor if available
		if UnitSelectionColor then
			-- We can't call this without a unit, so just return default
			return 1.0, 1.0, 1.0, 1.0;
		end
		return 1.0, 1.0, 1.0, 1.0;
	end
	
	return db[key];
end

local function Set(info, ...)
	local db = GetDB();
	if not db then
		return;
	end
	
	local key = info[#info];
	
	-- Handle unit color overrides
	local unitColorMatch = key:match("^unitColor_(.+)$");
	if unitColorMatch then
		local reaction = tonumber(unitColorMatch);
		if reaction then
			if not db.unitColors then
				db.unitColors = {};
			end
			if not db.unitColors[reaction] then
				db.unitColors[reaction] = {};
			end
			local r, g, b, a = ...;
			db.unitColors[reaction].r = r;
			db.unitColors[reaction].g = g;
			db.unitColors[reaction].b = b;
			db.unitColors[reaction].a = a or 1.0;
		end
	else
		db[key] = ...;
	end
	
	if addon.NotifyConfigChanged then
		addon:NotifyConfigChanged();
	end
end

function UnitColorOptions:BuildOptions()
	local args = {
		description = {
			type = "description",
			name = "Configure colors for each unit reaction type. These colors apply to health bars when 'Use Unit Color' is enabled. Reaction values: 1=Hated, 2=Hostile, 3=Unfriendly, 4=Neutral, 5=Friendly, 6=Honored, 7=Revered, 8=Exalted.",
			order = 1,
		},
		useClassColorForFriendly = {
			type = "toggle",
			name = "Use Class Color for Friendly Units",
			desc = "When enabled, friendly units (players, party members) will use their class color instead of the blue selection color. This applies when 'Use Unit Color' is enabled on health bars.",
			order = 2,
		},
	};
	
	-- Add unit color options for each reaction level
	local reactionTypes = {
		{ reaction = 1, name = "Hated" },
		{ reaction = 2, name = "Hostile" },
		{ reaction = 3, name = "Unfriendly" },
		{ reaction = 4, name = "Neutral" },
		{ reaction = 5, name = "Friendly" },
		{ reaction = 6, name = "Honored" },
		{ reaction = 7, name = "Revered" },
		{ reaction = 8, name = "Exalted" },
	};
	
	for i, reactionType in ipairs(reactionTypes) do
		args["unitColor_" .. reactionType.reaction] = {
			type = "color",
			name = reactionType.name,
			desc = "Color override for " .. reactionType.name .. " units (reaction " .. reactionType.reaction .. "). Applies to health bars when 'Use Unit Color' is enabled. Overrides class colors if 'Use Class Color for Friendly Units' is enabled.",
			hasAlpha = true,
			order = 10 + i,
		};
	end
	
	return {
		type = "group",
		name = "Unit Colours",
		get = Get,
		set = Set,
		args = args,
	};
end

-- Register this option group
if ns.Options then
	ns.Options:RegisterOptionGroup("unitColors", "Unit Colours", 8, function() return UnitColorOptions:BuildOptions(); end);
end

