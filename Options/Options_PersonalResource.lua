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
	if key == "healthColor" or key == "powerColor" or key == "healthBorderColor" or key == "powerBorderColor" or key == "overhealColor" or key == "absorbColor" then
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
	if key == "healthColor" or key == "powerColor" or key == "healthBorderColor" or key == "powerBorderColor" or key == "overhealColor" or key == "absorbColor" then
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
			generalHeader = {
				type = "header",
				name = "General",
				order = 1,
			},
			hidePlayerFrame = {
				type = "toggle",
				name = "Hide Player Frame",
				desc = "Hide the built-in Player Profile frame (PlayerFrame) since we are replacing it with the Personal Resource Display.",
				order = 2,
			},
			enablePersonalResourceDisplay = {
				type = "execute",
				name = "Enable Personal Resource Display",
				desc = "Enable Blizzard's Personal Resource Display setting. This matches the 'Display Personal Resource' option in Interface > Display settings.",
				order = 3,
				func = function()
					-- Try to enable Personal Resource Display via CVar
					-- The CVar name may vary, so we'll try common ones
					local cvarNames = {
						"displayPersonalResource",
						"showPersonalResource",
						"personalResourceDisplay",
						"nameplateShowSelf", -- This is for nameplates, but might be related
					};
					
					local success = false;
					for _, cvarName in ipairs(cvarNames) do
						local currentValue = GetCVar(cvarName);
						if currentValue ~= nil then
							-- CVar exists, try to set it to 1 (enabled)
							local ok, err = pcall(function()
								SetCVar(cvarName, "1");
							end);
							if ok then
								success = true;
								break;
							end
						end
					end
					
					-- Also try to enable through Interface Options if available
					if Settings and Settings.OpenToCategory then
						-- Open Interface options to Display category
						Settings.OpenToCategory("display");
					elseif InterfaceOptionsFrame_OpenToCategory then
						-- Fallback for older method
						InterfaceOptionsFrame_OpenToCategory("Display");
					end
					
					if success then
						print("|cFF00FF00PonyBetterResourceManager:|r Personal Resource Display enabled. You may need to reload your UI for changes to take effect.");
					else
						print("|cFFFF0000PonyBetterResourceManager:|r Could not automatically enable Personal Resource Display. Please enable it manually in Interface > Display > Display Personal Resource.");
					end
				end,
			},
			personalResourceStatus = {
				type = "description",
				name = function()
					-- Check current status of Personal Resource Display
					local cvarNames = {
						"displayPersonalResource",
						"showPersonalResource",
						"personalResourceDisplay",
					};
					
					for _, cvarName in ipairs(cvarNames) do
						local value = GetCVar(cvarName);
						if value ~= nil then
							local enabled = value == "1" or value == "true";
							return "Status: " .. (enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r");
						end
					end
					
					-- Check if PersonalResourceDisplayFrame exists and is shown
					local frame = _G.PersonalResourceDisplayFrame;
					if frame then
						return "Status: " .. (frame:IsShown() and "|cFF00FF00Visible|r" or "|cFFFF0000Hidden|r");
					end
					
					return "Status: |cFFFFAA00Unknown|r";
				end,
				order = 4,
			},
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
				get = Get,
				set = Set,
				args = {
					healthWidth = {
						type = "range",
						name = "Health Width",
						desc = "Override width of the health bar.",
						min = 0,
						max = 1000,
						step = 1,
						get = Get,
						set = Set,
						order = 1,
					},
					healthHeight = {
						type = "range",
						name = "Health Height",
						desc = "Override height of the health bar.",
						min = 0,
						max = 200,
						step = 1,
						get = Get,
						set = Set,
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
					healthBackgroundEnabled = {
						type = "toggle",
						name = "Background Enable",
						desc = "Show background behind health bar.",
						order = 5,
						get = function()
							local db = GetDB();
							return db and db.healthBarBackground and db.healthBarBackground.enabled;
						end,
						set = function(info, value)
							local db = GetDB();
							if db and db.healthBarBackground then
								db.healthBarBackground.enabled = value;
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
					},
					healthBackgroundTexture = {
						type = "select",
						name = "Background Texture",
						desc = "Background texture for health bar.",
						values = BuildStatusBarValues,
						order = 6,
						get = function()
							local db = GetDB();
							return db and db.healthBarBackground and db.healthBarBackground.texture or "";
						end,
						set = function(info, value)
							local db = GetDB();
							if db and db.healthBarBackground then
								db.healthBarBackground.texture = value;
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
						disabled = function()
							local db = GetDB();
							return not (db and db.healthBarBackground and db.healthBarBackground.enabled);
						end,
					},
					healthBackgroundColor = {
						type = "color",
						name = "Background Color",
						desc = "Background color for health bar.",
						hasAlpha = true,
						order = 7,
						get = function()
							local db = GetDB();
							if db and db.healthBarBackground and db.healthBarBackground.color then
								local c = db.healthBarBackground.color;
								return c.r, c.g, c.b, c.a;
							end
							return 0, 0, 0, 0.5;
						end,
						set = function(info, r, g, b, a)
							local db = GetDB();
							if db and db.healthBarBackground and db.healthBarBackground.color then
								db.healthBarBackground.color.r = r;
								db.healthBarBackground.color.g = g;
								db.healthBarBackground.color.b = b;
								db.healthBarBackground.color.a = a;
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
						disabled = function()
							local db = GetDB();
							return not (db and db.healthBarBackground and db.healthBarBackground.enabled);
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
				get = Get,
				set = Set,
				args = {
					powerWidth = {
						type = "range",
						name = "Power Width",
						desc = "Override width of the power bar.",
						min = 0,
						max = 1000,
						step = 1,
						get = Get,
						set = Set,
						order = 1,
					},
					powerHeight = {
						type = "range",
						name = "Power Height",
						desc = "Override height of the power bar.",
						min = 0,
						max = 200,
						step = 1,
						get = Get,
						set = Set,
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
					powerBackgroundEnabled = {
						type = "toggle",
						name = "Background Enable",
						desc = "Show background behind power bar.",
						order = 4,
						get = function()
							local db = GetDB();
							return db and db.powerBarBackground and db.powerBarBackground.enabled;
						end,
						set = function(info, value)
							local db = GetDB();
							if db and db.powerBarBackground then
								db.powerBarBackground.enabled = value;
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
					},
					powerBackgroundTexture = {
						type = "select",
						name = "Background Texture",
						desc = "Background texture for power bar.",
						values = BuildStatusBarValues,
						order = 5,
						get = function()
							local db = GetDB();
							return db and db.powerBarBackground and db.powerBarBackground.texture or "";
						end,
						set = function(info, value)
							local db = GetDB();
							if db and db.powerBarBackground then
								db.powerBarBackground.texture = value;
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
						disabled = function()
							local db = GetDB();
							return not (db and db.powerBarBackground and db.powerBarBackground.enabled);
						end,
					},
					powerBackgroundColor = {
						type = "color",
						name = "Background Color",
						desc = "Background color for power bar.",
						hasAlpha = true,
						order = 6,
						get = function()
							local db = GetDB();
							if db and db.powerBarBackground and db.powerBarBackground.color then
								local c = db.powerBarBackground.color;
								return c.r, c.g, c.b, c.a;
							end
							return 0, 0, 0, 0.5;
						end,
						set = function(info, r, g, b, a)
							local db = GetDB();
							if db and db.powerBarBackground and db.powerBarBackground.color then
								db.powerBarBackground.color.r = r;
								db.powerBarBackground.color.g = g;
								db.powerBarBackground.color.b = b;
								db.powerBarBackground.color.a = a;
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
						disabled = function()
							local db = GetDB();
							return not (db and db.powerBarBackground and db.powerBarBackground.enabled);
						end,
					},
				},
			},
			overhealAbsorbHeader = {
				type = "header",
				name = "Overheal & Absorb",
				order = 28,
			},
			overhealAbsorbGroup = {
				type = "group",
				inline = true,
				name = "",
				order = 29,
				args = {
					showOverheal = {
						type = "toggle",
						name = "Show Overheal",
						desc = "Display overheal prediction on health bars.",
						order = 1,
					},
					overhealColor = {
						type = "color",
						name = "Overheal Color",
						desc = "Color for overheal prediction.",
						hasAlpha = true,
						order = 2,
					},
					overhealTexture = {
						type = "select",
						name = "Overheal Texture",
						desc = "Texture for overheal prediction (empty = default).",
						values = function()
							local values = { [""] = "Default" };
							if LSM then
								for _, name in ipairs(LSM:List("statusbar")) do
									values[name] = name;
								end
							end
							return values;
						end,
						get = function()
							local db = GetDB();
							return db and (db.overhealTexture or "") or "";
						end,
						set = function(info, value)
							local db = GetDB();
							if db then
								db.overhealTexture = (value == "" and nil or value);
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
						order = 3,
					},
					showAbsorb = {
						type = "toggle",
						name = "Show Absorb",
						desc = "Display absorb shields on health bars.",
						order = 4,
					},
					absorbColor = {
						type = "color",
						name = "Absorb Color",
						desc = "Color for absorb shields.",
						hasAlpha = true,
						order = 5,
					},
					absorbTexture = {
						type = "select",
						name = "Absorb Texture",
						desc = "Texture for absorb shields (empty = default).",
						values = function()
							local values = { [""] = "Default" };
							if LSM then
								for _, name in ipairs(LSM:List("statusbar")) do
									values[name] = name;
								end
							end
							return values;
						end,
						get = function()
							local db = GetDB();
							return db and (db.absorbTexture or "") or "";
						end,
						set = function(info, value)
							local db = GetDB();
							if db then
								db.absorbTexture = (value == "" and nil or value);
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
						order = 6,
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
				desc = "Scale of the Personal Resource Display frame.",
				min = 0.05,
				max = 5.00,
				step = 0.05,
				order = 31,
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


