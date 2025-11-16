local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

local TextOptions = {};
ns.PersonalResourceTextOptions = TextOptions;

-- Migration: Ensure all existing texts have resourceType set to PERSONAL
function TextOptions:MigrateTexts()
	local db = addon.db and addon.db.profile and addon.db.profile.personalResource;
	if not db or not db.texts then
		return;
	end
	
	local migrated = false;
	for _, entry in ipairs(db.texts) do
		if not entry.resourceType then
			entry.resourceType = "PERSONAL";
			migrated = true;
		end
	end
	
	if migrated then
		-- Notify that we've migrated
		if addon.NotifyConfigChanged then
			addon:NotifyConfigChanged();
		end
	end
end

local function GetFontList()
	local fonts = {
		FRIZQT = "Friz Quadrata",
		ARIALN = "Arial Narrow",
		MORPHEUS = "Morpheus",
	};
	
	-- Add fonts from LibSharedMedia if available
	if LSM then
		local lsmFonts = LSM:HashTable("font");
		if lsmFonts then
			for key, _ in pairs(lsmFonts) do
				fonts[key] = key; -- Use key as display name, or could fetch better name
			end
		end
	end
	
	return fonts;
end

local function GetDB()
	return addon.db and addon.db.profile and addon.db.profile.personalResource;
end

local function ParseTextIndex(info)
	-- info can look like:
	-- { "texts", "personal", "text1", "enabled" } - nested in resource group
	-- { "texts", "text1", "enabled" } - direct field (legacy)
	-- { "texts", "text1", "basicGroup", "delete" } - nested in a group
	-- We need to find the "textN" key in the path
	for i = #info, 1, -1 do
		local key = info[i];
		if type(key) == "string" then
			local index = key:match("^text(%d+)$");
			if index then
				return tonumber(index);
			end
		end
	end
	return nil;
end

local function GetResourceTypeFromInfo(info)
	-- Check if we're in a personal or target sub-group
	for i = 1, #info do
		local key = info[i];
		if key == "personal" then
			return "PERSONAL";
		elseif key == "target" then
			return "TARGET";
		end
	end
	-- Default to PERSONAL for backward compatibility
	return "PERSONAL";
end

local function Get(info)
	local db = GetDB();
	if not db then
		return;
	end

	local key = info[#info];
	local index = ParseTextIndex(info);

	-- Per-text fields.
	if index then
		local texts = db.texts;
		local entry = texts and texts[index];
		
		-- For all fields, entry must exist
		if not entry then
			return;
		end
		
		-- Ensure resourceType exists (migration safety)
		if not entry.resourceType then
			entry.resourceType = "PERSONAL";
		end
		
		if key == "font" then
			return entry.font or db.textDefaultFont or "FRIZQT";
		elseif key == "size" then
			return entry.size or db.textDefaultSize or 18;
		elseif key == "outline" then
			return entry.outline or "OUTLINE";
		elseif key == "shadowEnabled" then
			if entry.shadowEnabled == nil then
				return true; -- Default to enabled
			end
			return entry.shadowEnabled;
		elseif key == "shadowOffsetX" then
			return entry.shadowOffsetX or 1;
		elseif key == "shadowOffsetY" then
			return entry.shadowOffsetY or -1;
		elseif key == "shadowColor" then
			local shadowColor = entry.shadowColor;
			if not shadowColor or type(shadowColor) ~= "table" then
				shadowColor = { r = 0, g = 0, b = 0, a = 1 };
			end
			local r = (type(shadowColor.r) == "number" and shadowColor.r >= 0 and shadowColor.r <= 1) and shadowColor.r or 0;
			local g = (type(shadowColor.g) == "number" and shadowColor.g >= 0 and shadowColor.g <= 1) and shadowColor.g or 0;
			local b = (type(shadowColor.b) == "number" and shadowColor.b >= 0 and shadowColor.b <= 1) and shadowColor.b or 0;
			local a = (type(shadowColor.a) == "number" and shadowColor.a >= 0 and shadowColor.a <= 1) and shadowColor.a or 1;
			return r, g, b, a;
		elseif key == "color" then
			-- Return color with validation
			local color = entry.color;
			if not color or type(color) ~= "table" then
				color = db.textDefaultColor or { r = 1, g = 1, b = 1, a = 1 };
			end
			-- Ensure all color components are valid numbers in range 0-1
			local r = (type(color.r) == "number" and color.r >= 0 and color.r <= 1) and color.r or 1;
			local g = (type(color.g) == "number" and color.g >= 0 and color.g <= 1) and color.g or 1;
			local b = (type(color.b) == "number" and color.b >= 0 and color.b <= 1) and color.b or 1;
			local a = (type(color.a) == "number" and color.a >= 0 and color.a <= 1) and color.a or 1;
			return r, g, b, a;
		else
			-- Return the value from the entry, or nil if not set
			return entry[key];
		end
	end

	-- Global text settings.
	if key == "textDefaultColor" then
		local color = db.textDefaultColor;
		-- If textDefaultColor doesn't exist or is not a proper table, use default
		if not color or type(color) ~= "table" then
			color = { r = 1, g = 1, b = 1, a = 1 };
		end
		-- Ensure all color components are valid numbers in range 0-1
		local r = (type(color.r) == "number" and color.r >= 0 and color.r <= 1) and color.r or 1;
		local g = (type(color.g) == "number" and color.g >= 0 and color.g <= 1) and color.g or 1;
		local b = (type(color.b) == "number" and color.b >= 0 and color.b <= 1) and color.b or 1;
		local a = (type(color.a) == "number" and color.a >= 0 and color.a <= 1) and color.a or 1;
		-- Final safety check - ensure no nil values
		return (r or 1), (g or 1), (b or 1), (a or 1);
	end

	return db[key];
end

local function Set(info, ...)
	local db = GetDB();
	if not db then
		return;
	end

	local key = info[#info];
	local index = ParseTextIndex(info);

	if index then
		db.texts = db.texts or {};
		db.texts[index] = db.texts[index] or {};
		local entry = db.texts[index];
		
		-- Ensure resourceType exists
		if not entry.resourceType then
			entry.resourceType = "PERSONAL";
		end

		if key == "font" then
			local fontKey = ...;
			entry.font = fontKey;
		elseif key == "size" then
			local size = ...;
			entry.size = size;
		elseif key == "outline" then
			local outline = ...;
			entry.outline = outline;
		elseif key == "shadowEnabled" then
			local enabled = ...;
			entry.shadowEnabled = enabled;
		elseif key == "shadowOffsetX" then
			local offsetX = ...;
			entry.shadowOffsetX = (type(offsetX) == "number") and offsetX or 1;
		elseif key == "shadowOffsetY" then
			local offsetY = ...;
			entry.shadowOffsetY = (type(offsetY) == "number") and offsetY or -1;
		elseif key == "shadowColor" then
			local r, g, b, a = ...;
			entry.shadowColor = entry.shadowColor or {};
			entry.shadowColor.r = (type(r) == "number") and r or 0;
			entry.shadowColor.g = (type(g) == "number") and g or 0;
			entry.shadowColor.b = (type(b) == "number") and b or 0;
			entry.shadowColor.a = (type(a) == "number") and a or 1;
		elseif key == "color" then
			local r, g, b, a = ...;
			entry.color = entry.color or {};
			-- Ensure all values are valid numbers
			entry.color.r = (type(r) == "number") and r or 1;
			entry.color.g = (type(g) == "number") and g or 1;
			entry.color.b = (type(b) == "number") and b or 1;
			entry.color.a = (type(a) == "number") and a or 1;
		else
			-- Save the value to the entry
			local value = ...;
			entry[key] = value;
		end
		
		-- If name, enabled, target, format, or resourceType changed, notify AceConfig to refresh the tree/list
		if key == "name" or key == "enabled" or key == "target" or key == "format" or key == "resourceType" then
			-- Force a refresh of the options table to update the tree view
			local AceConfig = LibStub("AceConfigRegistry-3.0", true);
			if AceConfig then
				-- Notify change and force a rebuild
				AceConfig:NotifyChange("PonyBetterResourceManager");
			end
		end
		
		-- If font, size, color, outline, or shadow settings changed, update the text immediately
		if key == "font" or key == "size" or key == "color" or key == "outline" or 
		   key == "shadowEnabled" or key == "shadowOffsetX" or key == "shadowOffsetY" or key == "shadowColor" then
			-- Just notify config changed to update the display
			if addon.NotifyConfigChanged then
				addon:NotifyConfigChanged();
			end
		end
	else
		if key == "textDefaultColor" then
			local r, g, b, a = ...;
			db.textDefaultColor = db.textDefaultColor or {};
			-- Ensure all values are valid numbers
			db.textDefaultColor.r = (type(r) == "number") and r or 1;
			db.textDefaultColor.g = (type(g) == "number") and g or 1;
			db.textDefaultColor.b = (type(b) == "number") and b or 1;
			db.textDefaultColor.a = (type(a) == "number") and a or 1;
		else
			db[key] = ...;
		end
	end

	if addon.NotifyConfigChanged then
		addon:NotifyConfigChanged();
	end
end

-- Build text entry args filtered by resourceType
local function BuildTextEntryArgs(resourceType)
	local db = GetDB();
	local args = {};

	if not db or type(db.texts) ~= "table" then
		return args;
	end

	for index, entry in ipairs(db.texts) do
		-- Ensure resourceType exists
		if not entry.resourceType then
			entry.resourceType = "PERSONAL";
		end
		
		-- Only include entries matching the requested resourceType
		if entry.resourceType == resourceType then
			local key = "text" .. index;
			-- Capture index in a local variable to avoid closure issues
			local entryIndex = index;
			args[key] = {
			type = "group",
			inline = false,
			name = function()
				local dbLocal = GetDB();
				local entryLocal = dbLocal and dbLocal.texts and dbLocal.texts[entryIndex];
				if entryLocal then
					local name = entryLocal.name or "";
					local target = entryLocal.target or "HEALTH";
					local enabled = entryLocal.enabled ~= false and "✓" or "✗";
					if name and name ~= "" then
						return string.format("%s %s", enabled, name);
					else
						return string.format("%s Text %d: %s", enabled, entryIndex, target);
					end
				end
				return string.format("Text %d", entryIndex);
			end,
			order = 20 + entryIndex,
			args = {
				basicGroup = {
					type = "group",
					inline = true,
					name = "Basic Settings",
					order = 1,
					args = {
						name = {
							type = "input",
							name = "Name",
							desc = "Optional name for this text entry (shown in the list).",
							order = 1,
							width = "full",
						},
						enabled = {
							type = "toggle",
							name = "Enabled",
							order = 2,
						},
						target = {
							type = "select",
							name = "Target Bar",
							desc = "Which bar this text should be attached to.",
							values = {
								HEALTH = "Health",
								POWER = "Power/Mana",
								-- ALT_POWER and CLASS can be used later.
							},
							order = 3,
						},
						moveToOther = {
							type = "execute",
							name = function()
								local dbLocal = GetDB();
								local entryLocal = dbLocal and dbLocal.texts and dbLocal.texts[entryIndex];
								if entryLocal and entryLocal.resourceType == "TARGET" then
									return "Move to Personal";
								else
									return "Move to Target";
								end
							end,
							desc = "Move this text entry to the other resource group.",
							order = 4,
							func = function(info)
								local moveIndex = ParseTextIndex(info);
								if not moveIndex then
									return;
								end
								local dbLocal = GetDB();
								if not dbLocal or type(dbLocal.texts) ~= "table" then
									return;
								end
								local entryLocal = dbLocal.texts[moveIndex];
								if not entryLocal then
									return;
								end
								-- Toggle resourceType
								if entryLocal.resourceType == "TARGET" then
									entryLocal.resourceType = "PERSONAL";
								else
									entryLocal.resourceType = "TARGET";
								end
								-- Notify AceConfig that the options table has changed.
								local AceConfig = LibStub("AceConfigRegistry-3.0", true);
								if AceConfig then
									AceConfig:NotifyChange("PonyBetterResourceManager");
								end
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end,
						},
						delete = {
							type = "execute",
							name = "Delete",
							confirm = true,
							confirmText = "Delete this text entry?",
							order = 5,
							func = function(info)
								-- Extract the index from the info path
								local deleteIndex = ParseTextIndex(info);
								if not deleteIndex then
									return;
								end
								local dbLocal = GetDB();
								if not dbLocal or type(dbLocal.texts) ~= "table" then
									return;
								end
								-- Validate index is within bounds
								if deleteIndex < 1 or deleteIndex > #dbLocal.texts then
									return;
								end
								-- Remove the entry at the correct index
								table.remove(dbLocal.texts, deleteIndex);
								-- Notify AceConfig that the options table has changed.
								local AceConfig = LibStub("AceConfigRegistry-3.0", true);
								if AceConfig then
									AceConfig:NotifyChange("PonyBetterResourceManager");
								end
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end,
						},
					},
				},
				positionGroup = {
					type = "group",
					inline = true,
					name = "Position",
					order = 2,
					args = {
						anchor = {
							type = "select",
							name = "Anchor Point",
							desc = "Where on the bar to anchor the text.",
							values = {
								CENTER = "Center",
								TOPLEFT = "Top Left",
								TOP = "Top",
								TOPRIGHT = "Top Right",
								LEFT = "Left",
								RIGHT = "Right",
								BOTTOMLEFT = "Bottom Left",
								BOTTOM = "Bottom",
								BOTTOMRIGHT = "Bottom Right",
							},
							order = 1,
						},
						x = {
							type = "range",
							name = "X Offset",
							min = -500,
							max = 500,
							step = 1,
							order = 2,
						},
						y = {
							type = "range",
							name = "Y Offset",
							min = -500,
							max = 500,
							step = 1,
							order = 3,
						},
					},
				},
				formatGroup = {
					type = "group",
					inline = true,
					name = "Format",
					order = 3,
					args = {
						format = {
							type = "input",
							name = "Format String",
							desc = "Format strings:\n" ..
								"Health: {hp}, {hp:short}, {hp:%}, {hp:%.0f}, {hp:bln}, {hpmax}, {hpmax:short}\n" ..
								"Power: {power} or {mana}, {power:short}, {power:%}, {power:bln}, {powermax}, {powermax:short}\n" ..
								"Icons: {mark}, {mark:target}, {combat}, {resting}, {dead}, {ghost}\n" ..
								"Status: {incombat}, {group}, {role}, {pvp}\n" ..
								"Unit: {targetname}, {targetname:short}, {targethealth}, {targetlevel}, {level}, {class}, {class:short}\n" ..
								"Info: {zone}, {fps}, {latency}, {latency:local}, {latency:world}, {latency:1f}, {latency:world:1f}, {time}, {time:12}\n" ..
								"{hp:bln} uses BreakUpLargeNumbers\n" ..
								"You can add arbitrary text, e.g.: '({hp})' or 'MP: {power} / {powermax}'",
							order = 1,
							width = "double",
						},
					},
				},
				appearanceGroup = {
					type = "group",
					inline = true,
					name = "Appearance",
					order = 4,
					args = {
						font = {
							type = "select",
							name = "Font",
							desc = "Font for this text (blank uses the global default).",
							values = GetFontList,
							order = 1,
						},
						size = {
							type = "range",
							name = "Font Size",
							desc = "Font size for this text (0 uses the global default).",
							min = 6,
							max = 72,
							step = 1,
							order = 2,
						},
						color = {
							type = "color",
							name = "Text Color",
							desc = "Color for this text (uses global default if not set).",
							hasAlpha = true,
							order = 3,
						},
						outline = {
							type = "select",
							name = "Font Outline",
							desc = "Font outline style.",
							values = {
								NONE = "None",
								OUTLINE = "Outline",
								THICKOUTLINE = "Thick Outline",
								MONOCHROME = "Monochrome",
							},
							order = 4,
						},
						shadowHeader = {
							type = "header",
							name = "Drop Shadow",
							order = 5,
						},
						shadowEnabled = {
							type = "toggle",
							name = "Enable Shadow",
							desc = "Enable drop shadow for this text.",
							order = 6,
						},
						shadowOffsetX = {
							type = "range",
							name = "Shadow Offset X",
							desc = "Horizontal offset for drop shadow.",
							min = -5,
							max = 5,
							step = 1,
							order = 7,
							disabled = function()
								local dbLocal = GetDB();
								local entryLocal = dbLocal and dbLocal.texts and dbLocal.texts[entryIndex];
								return not (entryLocal and entryLocal.shadowEnabled ~= false);
							end,
						},
						shadowOffsetY = {
							type = "range",
							name = "Shadow Offset Y",
							desc = "Vertical offset for drop shadow.",
							min = -5,
							max = 5,
							step = 1,
							order = 8,
							disabled = function()
								local dbLocal = GetDB();
								local entryLocal = dbLocal and dbLocal.texts and dbLocal.texts[entryIndex];
								return not (entryLocal and entryLocal.shadowEnabled ~= false);
							end,
						},
						shadowColor = {
							type = "color",
							name = "Shadow Color",
							desc = "Color for the drop shadow.",
							hasAlpha = true,
							order = 9,
							disabled = function()
								local dbLocal = GetDB();
								local entryLocal = dbLocal and dbLocal.texts and dbLocal.texts[entryIndex];
								return not (entryLocal and entryLocal.shadowEnabled ~= false);
							end,
						},
					},
				},
			},
		};
		end
	end

	return args;
end

function TextOptions:BuildOptions()
	-- Return a function that dynamically builds the options table each time it's accessed.
	-- This ensures the UI refreshes when entries are added or deleted.
	return function()
		local args = {
			defaultsHeader = {
				type = "header",
				name = "Global Defaults",
				order = 1,
			},
			textDefaultFont = {
				type = "select",
				name = "Default Font",
				desc = "Font used when a text does not specify its own.",
				order = 2,
				values = GetFontList,
			},
			textDefaultSize = {
				type = "range",
				name = "Default Font Size",
				min = 6,
				max = 72,
				step = 1,
				order = 3,
			},
			textDefaultColor = {
				type = "color",
				name = "Default Color",
				hasAlpha = true,
				order = 4,
			},
			personalHeader = {
				type = "header",
				name = "Personal Resource",
				order = 10,
			},
			personalEnabled = {
				type = "toggle",
				name = "Enable Personal Texts",
				desc = "Master toggle for all custom texts on the personal resource.",
				get = function()
					local db = GetDB();
					return db and db.healthTextEnabled ~= false;
				end,
				set = function(info, value)
					local db = GetDB();
					if db then
						db.healthTextEnabled = value;
						if addon.NotifyConfigChanged then
							addon:NotifyConfigChanged();
						end
					end
				end,
				order = 11,
			},
			personal = {
				type = "group",
				inline = false,
				name = "Personal",
				order = 12,
				args = {},
			},
			targetHeader = {
				type = "header",
				name = "Target Resource",
				order = 20,
			},
			targetEnabled = {
				type = "toggle",
				name = "Enable Target Texts",
				desc = "Master toggle for all custom texts on the target resource.",
				get = function()
					local targetDb = addon.db and addon.db.profile and addon.db.profile.targetResource;
					return targetDb and targetDb.healthTextEnabled ~= false;
				end,
				set = function(info, value)
					local targetDb = addon.db and addon.db.profile and addon.db.profile.targetResource;
					if targetDb then
						targetDb.healthTextEnabled = value;
						if addon.NotifyConfigChanged then
							addon:NotifyConfigChanged();
						end
					end
				end,
				order = 21,
			},
			target = {
				type = "group",
				inline = false,
				name = "Target",
				order = 22,
				args = {},
			},
		};

		-- Build Personal text entries
		local personalArgs = BuildTextEntryArgs("PERSONAL");
		personalArgs.addText = {
			type = "execute",
			name = "Add Text",
			order = 1,
			func = function()
				local db = GetDB();
				if not db then
					return;
				end
				db.texts = db.texts or {};
				table.insert(db.texts, {
					name = "",
					enabled = true,
					resourceType = "PERSONAL",
					target = "HEALTH",
					anchor = "CENTER",
					x = 0,
					y = 0,
					format = "{hp}",
				});
				-- Notify AceConfig that the options table has changed.
				local AceConfig = LibStub("AceConfigRegistry-3.0", true);
				if AceConfig then
					AceConfig:NotifyChange("PonyBetterResourceManager");
				end
				if addon.NotifyConfigChanged then
					addon:NotifyConfigChanged();
				end
			end,
		};
		for k, v in pairs(personalArgs) do
			args.personal.args[k] = v;
		end

		-- Build Target text entries
		local targetArgs = BuildTextEntryArgs("TARGET");
		targetArgs.addText = {
			type = "execute",
			name = "Add Text",
			order = 1,
			func = function()
				local db = GetDB();
				if not db then
					return;
				end
				db.texts = db.texts or {};
				table.insert(db.texts, {
					name = "",
					enabled = true,
					resourceType = "TARGET",
					target = "HEALTH",
					anchor = "CENTER",
					x = 0,
					y = 0,
					format = "{hp}",
				});
				-- Notify AceConfig that the options table has changed.
				local AceConfig = LibStub("AceConfigRegistry-3.0", true);
				if AceConfig then
					AceConfig:NotifyChange("PonyBetterResourceManager");
				end
				if addon.NotifyConfigChanged then
					addon:NotifyConfigChanged();
				end
			end,
		};
		for k, v in pairs(targetArgs) do
			args.target.args[k] = v;
		end

		return {
			type = "group",
			name = "Data Texts",
			get = Get,
			set = Set,
			args = args,
		};
	end;
end
