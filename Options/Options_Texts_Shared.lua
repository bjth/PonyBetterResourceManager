local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

-- Shared text options utilities
local TextOptionsShared = {};
ns.TextOptionsShared = TextOptionsShared;

-- Get sensible defaults for a new text entry based on resource type and target
function TextOptionsShared:GetTextDefaults(resourceType, target)
	local defaults = {
		enabled = true,
		resourceType = resourceType,
		target = target,
		anchor = "CENTER",
		x = 0,
		y = 0,
		format = "",
	};
	
	-- Set format based on target type
	if target == "HEALTH" then
		defaults.format = "{hp:short} / {hpmax:short}";
		-- Position health text on the left side
		defaults.anchor = "LEFT";
		defaults.x = 5;
		defaults.y = 0;
	elseif target == "POWER" then
		defaults.format = "{power:short} / {powermax:short}";
		-- Position power text on the right side
		defaults.anchor = "RIGHT";
		defaults.x = -5;
		defaults.y = 0;
	elseif target == "ALT_POWER" then
		defaults.format = "{power:short} / {powermax:short}";
		defaults.anchor = "CENTER";
		defaults.x = 0;
		defaults.y = 0;
	elseif target == "CLASS" then
		defaults.format = "{power:short}";
		defaults.anchor = "CENTER";
		defaults.x = 0;
		defaults.y = 0;
	else
		-- Fallback for unknown targets
		defaults.format = "{hp:short}";
		defaults.anchor = "CENTER";
		defaults.x = 0;
		defaults.y = 0;
	end
	
	-- Resource type specific adjustments
	if resourceType == "PERSONAL" then
		-- Personal resource might want percentage instead
		if target == "HEALTH" then
			defaults.format = "{hp:%}";
			defaults.anchor = "CENTER";
			defaults.x = 0;
			defaults.y = 0;
		elseif target == "POWER" then
			defaults.format = "{power:%}";
			defaults.anchor = "CENTER";
			defaults.x = 0;
			defaults.y = 0;
		end
	elseif resourceType == "TARGET" or resourceType == "FOCUS" or resourceType == "TARGETOFTARGET" then
		-- For target frames, show name on health bar
		if target == "HEALTH" then
			defaults.format = "{name}";
			defaults.anchor = "LEFT";
			defaults.x = 5;
			defaults.y = 0;
		end
	end
	
	return defaults;
end

-- Get font list for dropdowns
function TextOptionsShared:GetFontList()
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

-- Parse text index from info path
function TextOptionsShared:ParseTextIndex(info)
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

-- Build target values map from available targets
function TextOptionsShared:BuildTargetValues(availableTargets)
	local targetValues = {};
	for _, target in ipairs(availableTargets or {"HEALTH", "POWER"}) do
		if target == "HEALTH" then
			targetValues.HEALTH = "Health";
		elseif target == "POWER" then
			targetValues.POWER = "Power/Mana";
		elseif target == "ALT_POWER" then
			targetValues.ALT_POWER = "Alternate Power";
		elseif target == "CLASS" then
			targetValues.CLASS = "Class Resource";
		else
			targetValues[target] = target; -- Use target name as-is
		end
	end
	return targetValues;
end

-- Build a single text entry's options
-- This is the shared logic for configuring an individual text entry
function TextOptionsShared:BuildTextEntryOptions(entryIndex, availableTargets, getDBFunc, getFunc, setFunc)
	local targetValues = self:BuildTargetValues(availableTargets);
	
	return {
		type = "group",
		inline = false,
		name = function()
			local dbLocal = getDBFunc();
			local entryLocal = dbLocal and dbLocal.texts and dbLocal.texts[entryIndex];
			if entryLocal then
				local name = entryLocal.name or "";
				local target = entryLocal.target or "HEALTH";
				local enabled = entryLocal.enabled ~= false and "[ON]" or "[OFF]";
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
						get = getFunc,
						set = setFunc,
					},
					enabled = {
						type = "toggle",
						name = "Enabled",
						order = 2,
						get = getFunc,
						set = setFunc,
					},
					target = {
						type = "select",
						name = "Target Bar",
						desc = "Which bar this text should be attached to.",
						values = targetValues,
						order = 3,
						get = getFunc,
						set = setFunc,
					},
					delete = {
						type = "execute",
						name = "Delete",
						desc = "Delete this text entry.",
						order = 4,
						confirm = true,
						confirmText = "Are you sure you want to delete this text entry?",
						func = function(info)
							local index = self:ParseTextIndex(info);
							if index then
								local db = getDBFunc();
								if db and db.texts then
									table.remove(db.texts, index);
									-- Notify AceConfig that the options table has changed.
									local AceConfig = LibStub("AceConfigRegistry-3.0", true);
									if AceConfig then
										AceConfig:NotifyChange("PonyBetterResourceManager");
									end
									if addon.NotifyConfigChanged then
										addon:NotifyConfigChanged();
									end
								end
							end
						end,
					},
				},
			},
			formatGroup = {
				type = "group",
				inline = true,
				name = "Format",
				order = 2,
				args = {
					format = {
						type = "input",
						name = "Format String",
						desc = "Format string using tokens. Click 'Format Help' for available tokens.",
						order = 1,
						width = "full",
						get = getFunc,
						set = setFunc,
					},
					formatHelp = {
						type = "execute",
						name = "Format Help",
						desc = "Show help window with available format tokens.",
						order = 2,
						func = function()
							if ns.PersonalResourceTextOptions and ns.PersonalResourceTextOptions.ShowFormatHelp then
								ns.PersonalResourceTextOptions:ShowFormatHelp();
							end
						end,
					},
				},
			},
			positionGroup = {
				type = "group",
				inline = true,
				name = "Position",
				order = 3,
				args = {
					anchor = {
						type = "select",
						name = "Anchor Point",
						desc = "Where to anchor the text on the bar.",
						values = {
							LEFT = "Left",
							CENTER = "Center",
							RIGHT = "Right",
							TOP = "Top",
							BOTTOM = "Bottom",
							TOPLEFT = "Top Left",
							TOPRIGHT = "Top Right",
							BOTTOMLEFT = "Bottom Left",
							BOTTOMRIGHT = "Bottom Right",
						},
						order = 1,
						get = getFunc,
						set = setFunc,
					},
					x = {
						type = "range",
						name = "X Offset",
						desc = "Horizontal offset from anchor point.",
						min = -500,
						max = 500,
						step = 1,
						order = 2,
						get = getFunc,
						set = setFunc,
					},
					y = {
						type = "range",
						name = "Y Offset",
						desc = "Vertical offset from anchor point.",
						min = -500,
						max = 500,
						step = 1,
						order = 3,
						get = getFunc,
						set = setFunc,
					},
				},
			},
			fontGroup = {
				type = "group",
				inline = true,
				name = "Font",
				order = 4,
				args = {
					font = {
						type = "select",
						name = "Font",
						desc = "Font to use for this text (empty = use default).",
						values = function() return self:GetFontList(); end,
						get = function(info)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] then
								return db.texts[index].font or "";
							end
							return "";
						end,
						set = function(info, value)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] then
								db.texts[index].font = (value == "" and nil or value);
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
						order = 1,
					},
					size = {
						type = "range",
						name = "Font Size",
						desc = "Font size for this text (0 = use default).",
						min = 0,
						max = 72,
						step = 1,
						order = 2,
						get = getFunc,
						set = setFunc,
					},
					outline = {
						type = "select",
						name = "Outline",
						desc = "Font outline style.",
						values = {
							NONE = "None",
							OUTLINE = "Outline",
							THICKOUTLINE = "Thick Outline",
							MONOCHROME = "Monochrome",
						},
						order = 3,
						get = getFunc,
						set = setFunc,
					},
					color = {
						type = "color",
						name = "Color",
						desc = "Text color (empty = use default).",
						hasAlpha = true,
						order = 4,
						get = function(info)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] and db.texts[index].color then
								local c = db.texts[index].color;
								return c.r, c.g, c.b, c.a;
							end
							return 1, 1, 1, 1;
						end,
						set = function(info, r, g, b, a)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] then
								db.texts[index].color = { r = r, g = g, b = b, a = a };
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
					},
				},
			},
			shadowGroup = {
				type = "group",
				inline = true,
				name = "Shadow",
				order = 5,
				args = {
					shadowEnabled = {
						type = "toggle",
						name = "Enable Shadow",
						order = 1,
						get = getFunc,
						set = setFunc,
					},
					shadowOffsetX = {
						type = "range",
						name = "Shadow X Offset",
						min = -10,
						max = 10,
						step = 1,
						order = 2,
						get = getFunc,
						set = setFunc,
						disabled = function(info)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] then
								return db.texts[index].shadowEnabled == false;
							end
							return false;
						end,
					},
					shadowOffsetY = {
						type = "range",
						name = "Shadow Y Offset",
						min = -10,
						max = 10,
						step = 1,
						order = 3,
						get = getFunc,
						set = setFunc,
						disabled = function(info)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] then
								return db.texts[index].shadowEnabled == false;
							end
							return false;
						end,
					},
					shadowColor = {
						type = "color",
						name = "Shadow Color",
						hasAlpha = true,
						order = 4,
						get = function(info)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] and db.texts[index].shadowColor then
								local c = db.texts[index].shadowColor;
								return c.r, c.g, c.b, c.a;
							end
							return 0, 0, 0, 1;
						end,
						set = function(info, r, g, b, a)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] then
								db.texts[index].shadowColor = { r = r, g = g, b = b, a = a };
								if addon.NotifyConfigChanged then
									addon:NotifyConfigChanged();
								end
							end
						end,
						disabled = function(info)
							local db = getDBFunc();
							local index = self:ParseTextIndex(info);
							if db and db.texts and index and db.texts[index] then
								return db.texts[index].shadowEnabled == false;
							end
							return false;
						end,
					},
				},
			},
		},
	};
end

-- Build a complete text section for a resource type
-- This is the main function modules should call to build their text options
function TextOptionsShared:BuildResourceTextSection(resourceType, displayName, availableTargets, getDBFunc, getResourceDBFunc)
	local args = {};
	
	-- Get texts from the resource's own database
	local db = getDBFunc();
	if not db or type(db.texts) ~= "table" then
		-- Return empty section with just Add Text button
		args.addText = {
			type = "execute",
			name = "Add Text",
			order = 1,
			func = function()
				local dbLocal = getDBFunc();
				if not dbLocal then
					return;
				end
				dbLocal.texts = dbLocal.texts or {};
				local defaultTarget = availableTargets[1] or "HEALTH";
				local defaults = self:GetTextDefaults(resourceType, defaultTarget);
				table.insert(dbLocal.texts, {
					name = "",
					enabled = defaults.enabled,
					resourceType = defaults.resourceType,
					target = defaults.target,
					anchor = defaults.anchor,
					x = defaults.x,
					y = defaults.y,
					format = defaults.format,
				});
				local AceConfig = LibStub("AceConfigRegistry-3.0", true);
				if AceConfig then
					AceConfig:NotifyChange("PonyBetterResourceManager");
				end
				if addon.NotifyConfigChanged then
					addon:NotifyConfigChanged();
				end
			end,
		};
		return args;
	end
	
	-- Build Get/Set functions for this resource type
	local function Get(info)
		local dbLocal = getDBFunc();
		if not dbLocal then
			return;
		end
		
		local key = info[#info];
		local index = self:ParseTextIndex(info);
		
		if index then
			local texts = dbLocal.texts;
			local entry = texts and texts[index];
			
			if not entry or entry.resourceType ~= resourceType then
				return;
			end
			
			-- Get resource-specific DB for defaults
			local resourceDb = getResourceDBFunc and getResourceDBFunc() or dbLocal;
			
			if key == "font" then
				return entry.font or (resourceDb and resourceDb.textDefaultFont) or "FRIZQT";
			elseif key == "size" then
				return entry.size or (resourceDb and resourceDb.textDefaultSize) or 18;
			elseif key == "outline" then
				return entry.outline or "OUTLINE";
			elseif key == "shadowEnabled" then
				return entry.shadowEnabled ~= false;
			elseif key == "shadowOffsetX" then
				return entry.shadowOffsetX or 1;
			elseif key == "shadowOffsetY" then
				return entry.shadowOffsetY or -1;
			elseif key == "shadowColor" then
				local shadowColor = entry.shadowColor or { r = 0, g = 0, b = 0, a = 1 };
				return shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a;
			elseif key == "color" then
				local color = entry.color or (resourceDb and resourceDb.textDefaultColor) or { r = 1, g = 1, b = 1, a = 1 };
				return color.r, color.g, color.b, color.a;
			else
				return entry[key];
			end
		end
		
		return nil;
	end
	
	local function Set(info, ...)
		local dbLocal = getDBFunc();
		if not dbLocal then
			return;
		end
		
		local key = info[#info];
		local index = self:ParseTextIndex(info);
		
		if index then
			dbLocal.texts = dbLocal.texts or {};
			dbLocal.texts[index] = dbLocal.texts[index] or {};
			local entry = dbLocal.texts[index];
			
			-- Set resourceType if not set (for new entries)
			if not entry.resourceType then
				entry.resourceType = resourceType;
			end
			
			-- Only allow editing entries that match this resourceType
			if entry.resourceType ~= resourceType then
				return;
			end
			
			if key == "font" then
				entry.font = ...;
			elseif key == "size" then
				entry.size = ...;
			elseif key == "outline" then
				entry.outline = ...;
			elseif key == "shadowEnabled" then
				entry.shadowEnabled = ...;
			elseif key == "shadowOffsetX" then
				entry.shadowOffsetX = ...;
			elseif key == "shadowOffsetY" then
				entry.shadowOffsetY = ...;
			elseif key == "shadowColor" then
				local r, g, b, a = ...;
				entry.shadowColor = { r = r, g = g, b = b, a = a };
			elseif key == "color" then
				local r, g, b, a = ...;
				entry.color = { r = r, g = g, b = b, a = a };
			else
				entry[key] = ...;
			end
			
			-- Notify changes
			if key == "name" or key == "enabled" or key == "target" or key == "format" then
				local AceConfig = LibStub("AceConfigRegistry-3.0", true);
				if AceConfig then
					AceConfig:NotifyChange("PonyBetterResourceManager");
				end
			end
			
			if addon.NotifyConfigChanged then
				addon:NotifyConfigChanged();
			end
		end
	end
	
	-- Build text entries for this resource type
	for index, entry in ipairs(db.texts) do
		if entry.resourceType == resourceType then
			local entryOptions = self:BuildTextEntryOptions(index, availableTargets, getDBFunc, Get, Set);
			local key = "text" .. index;
			args[key] = entryOptions;
		end
	end
	
	-- Add "Add Text" button
	args.addText = {
		type = "execute",
		name = "Add Text",
		order = 1,
		func = function()
			local dbLocal = getDBFunc();
			if not dbLocal then
				return;
			end
			dbLocal.texts = dbLocal.texts or {};
			local defaultTarget = availableTargets[1] or "HEALTH";
			local defaults = self:GetTextDefaults(resourceType, defaultTarget);
			table.insert(dbLocal.texts, {
				name = "",
				enabled = defaults.enabled,
				resourceType = defaults.resourceType,
				target = defaults.target,
				anchor = defaults.anchor,
				x = defaults.x,
				y = defaults.y,
				format = defaults.format,
			});
			local AceConfig = LibStub("AceConfigRegistry-3.0", true);
			if AceConfig then
				AceConfig:NotifyChange("PonyBetterResourceManager");
			end
			if addon.NotifyConfigChanged then
				addon:NotifyConfigChanged();
			end
		end,
	};
	
	return args;
end

-- Add a "Texts" section to a module's options args
-- This is a convenience function that modules can call to add text options to their own options
function TextOptionsShared:AddTextSectionToOptions(args, resourceType, displayName, availableTargets, getDBFunc, getResourceDBFunc, order)
	order = order or 1000; -- Default to end of options
	
	-- Add header
	args.textsHeader = {
		type = "header",
		name = "Data",
		order = order,
	};
	
	-- Add enabled toggle
	args.textsEnabled = {
		type = "toggle",
		name = "Enable " .. displayName .. " Texts",
		desc = "Master toggle for all custom texts on the " .. string.lower(displayName) .. " resource.",
		order = order + 1,
		get = function()
			local resourceDb = getResourceDBFunc and getResourceDBFunc();
			return resourceDb and resourceDb.healthTextEnabled ~= false;
		end,
		set = function(info, value)
			local resourceDb = getResourceDBFunc and getResourceDBFunc();
			if resourceDb then
				resourceDb.healthTextEnabled = value;
				if addon.NotifyConfigChanged then
					addon:NotifyConfigChanged();
				end
			end
		end,
	};
	
	-- Add texts group
	args.texts = {
		type = "group",
		inline = false,
		name = displayName .. " Texts",
		order = order + 2,
		args = self:BuildResourceTextSection(resourceType, displayName, availableTargets, getDBFunc, getResourceDBFunc),
	};
end

return TextOptionsShared;

