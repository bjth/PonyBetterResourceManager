local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

local PersonalOptions = {};
ns.PersonalResourceOptions = PersonalOptions;

local function GetDB()
	return addon.db and addon.db.profile and addon.db.profile.personalResource;
end

local function Get(info)
	local db = GetDB();
	if not db then
		return;
	end

	local key = info[#info];
	if key == "healthColor" or key == "powerColor" or key == "healthBorderColor" or key == "powerBorderColor" then
		local color = db[key];
		return color.r, color.g, color.b, color.a;
	end

	return db[key];
end

local function Set(info, ...)
	local db = GetDB();
	if not db then
		return;
	end

	local key = info[#info];
	if key == "healthColor" or key == "powerColor" or key == "healthBorderColor" or key == "powerBorderColor" then
		local r, g, b, a = ...;
		db[key].r, db[key].g, db[key].b, db[key].a = r, g, b, a;
	else
		db[key] = ...;
	end

	if addon.NotifyConfigChanged then
		addon:NotifyConfigChanged();
	end
end

local function BuildStatusBarValues()
	local values = {};
	if LSM then
		for _, name in ipairs(LSM:List("statusbar")) do
			values[name] = name;
		end
	end
	return values;
end

function PersonalOptions:BuildOptions()
	return {
		type = "group",
		name = "Personal Resource",
		get = Get,
		set = Set,
		args = {
			divider1 = {
				type = "header",
				name = "Health Bar",
				order = 10,
			},
			showHealthBar = {
				type = "toggle",
				name = "Show Health Bar",
				desc = "If disabled, hides the health bar even when Blizzard would normally show it.",
				order = 11,
			},
			healthSizeGroup = {
				type = "group",
				inline = true,
				name = "",
				order = 12,
				args = {
					healthWidth = {
						type = "range",
						name = "Health Width",
						desc = "Override width of the health bar.",
						min = 0,
						max = 1000,
						step = 1,
						order = 1,
					},
					healthHeight = {
						type = "range",
						name = "Health Height",
						desc = "Override height of the health bar.",
						min = 0,
						max = 200,
						step = 1,
						order = 2,
					},
				},
			},
			healthBorderGroup = {
				type = "group",
				inline = true,
				name = "",
				order = 13,
				args = {
					healthBorderStyle = {
						type = "select",
						name = "Border Style",
						desc = "Style for the health bar border.",
						values = {
							Default = "Default",
							None = "None",
						},
						order = 0,
					},
					healthBorderSize = {
						type = "range",
						name = "Border Size",
						desc = "Scale of the health bar border.",
						min = 0.5,
						max = 3.0,
						step = 0.05,
						order = 0.5,
					},
					healthBorderColor = {
						type = "color",
						name = "Border Color",
						desc = "Color of the health bar border.",
						hasAlpha = true,
						order = 1,
					},
				},
			},
			healthTextureGroup = {
				type = "group",
				inline = true,
				name = "",
				order = 14,
				args = {
					healthTexture = {
						type = "select",
						name = "Health Texture",
						desc = "Status bar texture for the health bar.",
						values = BuildStatusBarValues,
						order = 1,
					},
					overrideHealthColor = {
						type = "toggle",
						name = "Override Health Color",
						desc = "Use a custom health bar color instead of Blizzard defaults.",
						order = 2,
					},
					healthColor = {
						type = "color",
						name = "Health Color",
						desc = "Custom color for the health bar.",
						hasAlpha = true,
						order = 3,
						disabled = function()
							local db = GetDB();
							return not (db and db.overrideHealthColor);
						end,
					},
					healthClassColorButton = {
						type = "execute",
						name = "Set to Class Color",
						desc = "Set the health bar color to your class color and enable override.",
						order = 4,
						func = function()
							local db = GetDB();
							if not db then
								return;
							end

							local _, class = UnitClass("player");
							local colorTable = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class];
							if colorTable then
								db.overrideHealthColor = true;
								db.healthColor.r = colorTable.r;
								db.healthColor.g = colorTable.g;
								db.healthColor.b = colorTable.b;
								db.healthColor.a = 1.0;

								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
					},
				},
			},
			divider2 = {
				type = "header",
				name = "Power Bar",
				order = 20,
			},
			showPowerBar = {
				type = "toggle",
				name = "Show Power Bar",
				desc = "If disabled, hides the power bar even when Blizzard would normally show it.",
				order = 21,
			},
			powerSizeGroup = {
				type = "group",
				inline = true,
				name = "",
				order = 22,
				args = {
					powerWidth = {
						type = "range",
						name = "Power Width",
						desc = "Override width of the power bar.",
						min = 0,
						max = 1000,
						step = 1,
						order = 1,
					},
					powerHeight = {
						type = "range",
						name = "Power Height",
						desc = "Override height of the power bar.",
						min = 0,
						max = 200,
						step = 1,
						order = 2,
					},
				},
			},
			powerOffsetGroup = {
				type = "group",
				inline = true,
				name = "",
				order = 23,
				args = {
					powerOffsetX = {
						type = "range",
						name = "Power X Offset",
						desc = "Horizontal offset for the power bar.",
						min = -500,
						max = 500,
						step = 1,
						order = 1,
					},
					powerOffsetY = {
						type = "range",
						name = "Power Y Offset",
						desc = "Vertical offset for the power bar.",
						min = -500,
						max = 500,
						step = 1,
						order = 2,
					},
				},
			},
			powerBorderGroup = {
				type = "group",
				inline = true,
				name = "",
				order = 24,
				args = {
					powerBorderStyle = {
						type = "select",
						name = "Border Style",
						desc = "Style for the power bar border.",
						values = {
							Default = "Default",
							None = "None",
						},
						order = 0,
					},
					powerBorderSize = {
						type = "range",
						name = "Border Size",
						desc = "Scale of the power bar border.",
						min = 0.5,
						max = 3.0,
						step = 0.05,
						order = 0.5,
					},
					powerBorderColor = {
						type = "color",
						name = "Border Color",
						desc = "Color of the power bar border.",
						hasAlpha = true,
						order = 1,
					},
				},
			},
			powerTextureGroup = {
				type = "group",
				inline = true,
				name = "",
				order = 25,
				args = {
					powerTexture = {
						type = "select",
						name = "Power Texture",
						desc = "Status bar texture for the power bar.",
						values = BuildStatusBarValues,
						order = 1,
					},
					overridePowerColor = {
						type = "toggle",
						name = "Override Power Color",
						desc = "Use a custom power bar color instead of Blizzard defaults.",
						order = 2,
					},
					powerColor = {
						type = "color",
						name = "Power Color",
						desc = "Custom color for the power bar.",
						hasAlpha = true,
						order = 3,
						disabled = function()
							local db = GetDB();
							return not (db and db.overridePowerColor);
						end,
					},
				},
			},
			divider3 = {
				type = "header",
				name = "Layout",
				order = 30,
			},
			scale = {
				type = "range",
				name = "Scale",
				desc = "Additional scale applied on top of Edit Mode configuration.",
				min = 0.5,
				max = 5.0,
				step = 0.01,
				isPercent = false,
				order = 31,
			},
			borderAlpha = {
				type = "range",
				name = "Border Alpha",
				desc = "Controls the transparency of health and power bar borders.",
				min = 0.0,
				max = 1.0,
				step = 0.05,
				order = 32,
			},

			alternateHeader = {
				type = "header",
				name = "Alternate Power Bar",
				order = 40,
			},
			showAlternatePowerBar = {
				type = "toggle",
				name = "Show Alternate Power Bar",
				desc = "If disabled, hides the alternate power bar (where applicable).",
				order = 41,
			},

			classHeader = {
				type = "header",
				name = "Class Resource Bar",
				order = 50,
			},
			showClassResourceBar = {
				type = "toggle",
				name = "Show Class Resource Bar",
				desc = "If disabled, hides the class resource bar (e.g. Holy Power, combo points).",
				order = 51,
			},
			classOffsetX = {
				type = "range",
				name = "Class Resource X Offset",
				desc = "Horizontal offset for the class resource bar container.",
				min = -500,
				max = 500,
				step = 1,
				order = 52,
			},
			classOffsetY = {
				type = "range",
				name = "Class Resource Y Offset",
				desc = "Vertical offset for the class resource bar container.",
				min = -500,
				max = 500,
				step = 1,
				order = 53,
			},
		},
	};
end


