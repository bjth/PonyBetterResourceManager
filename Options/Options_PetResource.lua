local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;
local SharedOptions = ns.SharedResourceOptions;

local PetOptions = {};
ns.petResourceOptions = PetOptions;

local function GetDB()
	return addon.db and addon.db.profile and addon.db.profile.petResource;
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

function PetOptions:BuildOptions()
	-- Organize options into tabs like SUF: General, Health Bar, Power Bar, Overheal & Absorb, Layout, Texts
	local args = {
		general = {
			type = "group",
			name = "General",
			order = 1,
			get = Get,
			set = Set,
			args = {
				enabled = {
					type = "toggle",
					name = "Enable Pet Display",
					desc = "Show a resource display for your Pet (similar to the personal resource display).",
					order = 1,
				},
				hidePetFrame = {
					type = "toggle",
					name = "Hide Pet Frame",
					desc = "Hide the built-in Pet frame (PetFrame) since we are replacing it with the Pet Display.",
					order = 2,
				},
			},
		},
		healthBar = {
			type = "group",
			name = "Health Bar",
			order = 2,
			get = Get,
			set = Set,
			args = {
				showHealthBar = {
					type = "toggle",
					name = "Show Health Bar",
					desc = "If disabled, hides the health bar.",
					order = 1,
				},
				healthSizeGroup = {
					type = "group",
					inline = true,
					name = "Size",
					order = 2,
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
				healthOffsetGroup = {
					type = "group",
					inline = true,
					name = "Offset",
					order = 3,
					args = {
						healthOffsetX = {
							type = "range",
							name = "Health X Offset",
							desc = "Horizontal offset for the health bar.",
							min = -500,
							max = 500,
							step = 1,
							order = 1,
						},
						healthOffsetY = {
							type = "range",
							name = "Health Y Offset",
							desc = "Vertical offset for the health bar.",
							min = -500,
							max = 500,
							step = 1,
							order = 2,
						},
					},
				},
				healthBorderGroup = SharedOptions and SharedOptions:BuildHealthBorderGroup(
					function(info) return GetDB(); end,
					function(info, ...) Set(info, ...); end,
					4
				) or nil,
				healthTextureGroup = {
					type = "group",
					inline = true,
					name = "Texture & Color",
					order = 5,
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
							desc = "Use a custom health bar color instead of default green.",
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
						healthBackgroundEnabled = {
							type = "toggle",
							name = "Background Enable",
							desc = "Show background behind health bar.",
							order = 4,
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
							order = 5,
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
							order = 6,
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
			},
		},
		powerBar = {
			type = "group",
			name = "Power Bar",
			order = 3,
			get = Get,
			set = Set,
			args = {
				showPowerBar = {
					type = "toggle",
					name = "Show Power Bar",
					desc = "If disabled, hides the power bar.",
					order = 1,
				},
				powerSizeGroup = {
					type = "group",
					inline = true,
					name = "Size",
					order = 2,
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
					name = "Offset",
					order = 3,
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
				powerBorderGroup = SharedOptions and SharedOptions:BuildPowerBorderGroup(
					function(info) return GetDB(); end,
					function(info, ...) Set(info, ...); end,
					4
				) or nil,
				powerTextureGroup = {
					type = "group",
					inline = true,
					name = "Texture & Background",
					order = 5,
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
			},
		},
		overhealAbsorb = {
			type = "group",
			name = "Overheal & Absorb",
			order = 4,
			get = Get,
			set = Set,
			args = {
				overhealAbsorbGroup = {
					type = "group",
					inline = true,
					name = "",
					order = 1,
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
			},
		},
		layout = {
			type = "group",
			name = "Layout",
			order = 5,
			get = Get,
			set = Set,
			args = {
				scale = {
					type = "range",
					name = "Scale",
					desc = "Scale of the Pet Display frame.",
					min = 0.05,
					max = 5.00,
					step = 0.05,
					order = 1,
				},
			},
		},
	};
	
	-- Add Texts section using shared utilities
	local TextOptionsShared = ns.TextOptionsShared;
	if TextOptionsShared then
		local function GetTextsDB()
			-- Texts are stored in each resource's own database
			return addon.db and addon.db.profile and addon.db.profile.petResource;
		end
		local function GetPetDB()
			return addon.db and addon.db.profile and addon.db.profile.petResource;
		end
		local textsArgs = {};
		TextOptionsShared:AddTextSectionToOptions(
			textsArgs,
			"Pet",
			"Pet",
			{"HEALTH", "POWER"},
			GetTextsDB,
			GetPetDB,
			1
		);
		if next(textsArgs) then
			args.texts = {
				type = "group",
				name = "Data",
				order = 6,
				args = textsArgs,
			};
		end
	end
	
	return {
		type = "group",
		name = "Pet",
		childGroups = "tab",
		get = Get,
		set = Set,
		args = args,
	};
end

-- Register this option group
if ns.Options then
	ns.Options:RegisterOptionGroup("petResource", "Pet", 4, function() return PetOptions:BuildOptions(); end);
end

-- Register with Data Texts system
if ns.PersonalResourceTextOptions then
	ns.PersonalResourceTextOptions:RegisterResourceType("Pet", "Pet", {"HEALTH", "POWER"}, 3);
end
