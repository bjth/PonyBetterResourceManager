local ADDON_NAME, ns = ...;

local addon = ns.Addon;

local PowerColorOptions = {};
ns.PowerColorOptions = PowerColorOptions;

local function GetDB()
	-- Power colors are now stored globally in the profile
	return addon.db and addon.db.profile;
end

local function Get(info)
	local db = GetDB();
	if not db then
		return;
	end
	
	local key = info[#info];
	
	-- Handle power color overrides (e.g., "powerColor_MANA", "powerColor_RAGE")
	local powerColorMatch = key:match("^powerColor_(.+)$");
	if powerColorMatch then
		local powerToken = powerColorMatch;
		if db.powerColors and db.powerColors[powerToken] then
			local color = db.powerColors[powerToken];
			return color.r, color.g, color.b, color.a or 1.0;
		end
		-- Return Blizzard default if not set
		if PowerBarColor and PowerBarColor[powerToken] then
			local color = PowerBarColor[powerToken];
			return color.r, color.g, color.b, color.a or 1.0;
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
	
	-- Handle power color overrides
	local powerColorMatch = key:match("^powerColor_(.+)$");
	if powerColorMatch then
		local powerToken = powerColorMatch;
		if not db.powerColors then
			db.powerColors = {};
		end
		if not db.powerColors[powerToken] then
			db.powerColors[powerToken] = {};
		end
		local r, g, b, a = ...;
		db.powerColors[powerToken].r = r;
		db.powerColors[powerToken].g = g;
		db.powerColors[powerToken].b = b;
		db.powerColors[powerToken].a = a or 1.0;
	else
		db[key] = ...;
	end
	
	if addon.NotifyConfigChanged then
		addon:NotifyConfigChanged();
	end
end

function PowerColorOptions:BuildOptions()
	local args = {
		description = {
			type = "description",
			name = "Configure colors for each power type. These colors apply to all resource displays (Personal, Target, etc.).",
			order = 1,
		},
	};
	
	-- Add power color options directly to args (not nested in a group)
	local powerTypes = {
		{ token = "MANA", name = "Mana" },
		{ token = "RAGE", name = "Rage" },
		{ token = "ENERGY", name = "Energy" },
		{ token = "FOCUS", name = "Focus" },
		{ token = "RUNIC_POWER", name = "Runic Power" },
		{ token = "SOUL_SHARDS", name = "Soul Shards" },
		{ token = "LUNAR_POWER", name = "Lunar Power" },
		{ token = "HOLY_POWER", name = "Holy Power" },
		{ token = "MAELSTROM", name = "Maelstrom" },
		{ token = "INSANITY", name = "Insanity" },
		{ token = "CHI", name = "Chi" },
		{ token = "ARCANE_CHARGES", name = "Arcane Charges" },
		{ token = "COMBO_POINTS", name = "Combo Points" },
		{ token = "FURY", name = "Fury" },
		{ token = "PAIN", name = "Pain" },
	};
	
	for i, powerType in ipairs(powerTypes) do
		args["powerColor_" .. powerType.token] = {
			type = "color",
			name = powerType.name,
			desc = "Color override for " .. powerType.name .. " resource type. Applies to all frames.",
			hasAlpha = true,
			order = 10 + i,
		};
	end
	
	return {
		type = "group",
		name = "Power Colors",
		get = Get,
		set = Set,
		args = args,
	};
end

-- Register this option group
if ns.Options then
	ns.Options:RegisterOptionGroup("powerColors", "Power Colors", 7, function() return PowerColorOptions:BuildOptions(); end);
end
