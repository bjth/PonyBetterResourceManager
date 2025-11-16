local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

local SharedOptions = {};
ns.SharedResourceOptions = SharedOptions;

-- Build status bar texture values from LibSharedMedia
local function BuildStatusBarValues()
	local values = {};
	if LSM then
		for _, name in ipairs(LSM:List("statusbar")) do
			values[name] = name;
		end
	end
	return values;
end

-- Get function for color values
local function GetColorValue(db, key)
	if not db then
		return 0, 0, 0, 1;
	end
	local color = db[key];
	if color then
		return color.r, color.g, color.b, color.a;
	end
	return 0, 0, 0, 1;
end

-- Set function for color values
local function SetColorValue(db, key, r, g, b, a)
	if not db then
		return;
	end
	if not db[key] then
		db[key] = {};
	end
	db[key].r, db[key].g, db[key].b, db[key].a = r, g, b, a;
end

-- Build health bar border options group
-- getFunc: function(info) that returns the db table
-- setFunc: function(info, value) that sets values and notifies
-- order: order number for the group
function SharedOptions:BuildHealthBorderGroup(getFunc, setFunc, order)
	return {
		type = "group",
		inline = true,
		name = "",
		order = order or 13,
		args = {
			healthBorderStyle = {
				type = "select",
				name = "Border Style",
				desc = "Style for the health bar border.",
				values = {
					Default = "Default",
					None = "None",
				},
				get = function(info)
					local db = getFunc(info);
					return db and db.healthBorderStyle or "Default";
				end,
				set = setFunc,
				order = 0,
			},
			healthBorderSize = {
				type = "range",
				name = "Border Size",
				desc = "Scale of the health bar border.",
				min = 0.5,
				max = 3.0,
				step = 0.05,
				get = function(info)
					local db = getFunc(info);
					return db and db.healthBorderSize or 1.0;
				end,
				set = setFunc,
				order = 0.5,
			},
			healthBorderColor = {
				type = "color",
				name = "Border Color",
				desc = "Color of the health bar border.",
				hasAlpha = true,
				get = function(info)
					local db = getFunc(info);
					return GetColorValue(db, "healthBorderColor");
				end,
				set = function(info, r, g, b, a)
					local db = getFunc(info);
					if db then
						SetColorValue(db, "healthBorderColor", r, g, b, a);
						setFunc(info, r, g, b, a);
					end
				end,
				order = 1,
			},
		},
	};
end

-- Build power bar border options group
-- getFunc: function(info) that returns the db table
-- setFunc: function(info, value) that sets values and notifies
-- order: order number for the group
function SharedOptions:BuildPowerBorderGroup(getFunc, setFunc, order)
	return {
		type = "group",
		inline = true,
		name = "",
		order = order or 24,
		args = {
			powerBorderStyle = {
				type = "select",
				name = "Border Style",
				desc = "Style for the power bar border.",
				values = {
					Default = "Default",
					None = "None",
				},
				get = function(info)
					local db = getFunc(info);
					return db and db.powerBorderStyle or "Default";
				end,
				set = setFunc,
				order = 0,
			},
			powerBorderSize = {
				type = "range",
				name = "Border Size",
				desc = "Scale of the power bar border.",
				min = 0.5,
				max = 3.0,
				step = 0.05,
				get = function(info)
					local db = getFunc(info);
					return db and db.powerBorderSize or 1.0;
				end,
				set = setFunc,
				order = 0.5,
			},
			powerBorderColor = {
				type = "color",
				name = "Border Color",
				desc = "Color of the power bar border.",
				hasAlpha = true,
				get = function(info)
					local db = getFunc(info);
					return GetColorValue(db, "powerBorderColor");
				end,
				set = function(info, r, g, b, a)
					local db = getFunc(info);
					if db then
						SetColorValue(db, "powerBorderColor", r, g, b, a);
						setFunc(info, r, g, b, a);
					end
				end,
				order = 1,
			},
		},
	};
end

-- Build border alpha option
function SharedOptions:BuildBorderAlphaOption(getFunc, setFunc, order)
	return {
		type = "range",
		name = "Border Alpha",
		desc = "Controls the transparency of health and power bar borders.",
		min = 0.0,
		max = 1.0,
		step = 0.05,
		get = getFunc,
		set = setFunc,
		order = order or 31,
	};
end

return SharedOptions;

