local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

local TextOptions = {};
ns.PersonalResourceTextOptions = TextOptions;

-- Registry for resource modules that support text (stored in ns so it's accessible from other files)
if not ns.ResourceTypeRegistry then
	ns.ResourceTypeRegistry = {};
end
local resourceTypeRegistry = ns.ResourceTypeRegistry;

-- Register a resource type for Data Texts
-- resourceType: unique identifier (e.g., "PERSONAL", "TARGET", "FOCUS", "PET", "TARGETOFTARGET")
-- displayName: display name (e.g., "Personal", "Target", "Focus", "Pet", "Target of Target")
-- availableTargets: array of available bar targets (e.g., {"HEALTH", "POWER"})
-- order: display order (lower numbers appear first)
function TextOptions:RegisterResourceType(resourceType, displayName, availableTargets, order)
	resourceTypeRegistry[resourceType] = {
		displayName = displayName,
		availableTargets = availableTargets or {"HEALTH", "POWER"},
		order = order or 999,
	};
end


-- Format help window
local formatHelpWindow = nil;

local function ShowFormatHelpWindow()
	local AceGUI = LibStub("AceGUI-3.0", true);
	local AceConfigDialog = LibStub("AceConfigDialog-3.0", true);
	if not AceGUI then
		return;
	end
	
	-- Close existing window if open
	if formatHelpWindow then
		formatHelpWindow:Hide();
		formatHelpWindow = nil;
	end
	
	-- Get the parent options dialog frame
	local parentFrame = nil;
	if AceConfigDialog and AceConfigDialog.OpenFrames then
		parentFrame = AceConfigDialog.OpenFrames["PonyBetterResourceManager"];
	end
	
	if not parentFrame or not parentFrame.frame then
		-- Fallback: create as standalone window if no parent
		formatHelpWindow = AceGUI:Create("Window");
		formatHelpWindow:SetTitle("Format String Help");
		formatHelpWindow:SetWidth(600);
		formatHelpWindow:SetHeight(500);
		formatHelpWindow:SetLayout("Fill");
		formatHelpWindow.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	else
		-- Create as a simple frame attached to the options window
		formatHelpWindow = AceGUI:Create("Frame");
		formatHelpWindow:SetTitle("Format String Help");
		formatHelpWindow:SetWidth(600);
		formatHelpWindow:SetHeight(500);
		formatHelpWindow:SetLayout("Fill");
		
		-- Parent and position relative to options dialog
		formatHelpWindow.frame:SetParent(parentFrame.frame);
		formatHelpWindow.frame:SetFrameStrata("FULLSCREEN_DIALOG");
		-- Set frame level much higher to ensure it's on top
		local parentLevel = parentFrame.frame:GetFrameLevel();
		formatHelpWindow.frame:SetFrameLevel(parentLevel + 50);
		-- Attach left border to right border of options panel
		formatHelpWindow.frame:ClearAllPoints();
		formatHelpWindow.frame:SetPoint("LEFT", parentFrame.frame, "RIGHT", 0, 0);
	end
	
	formatHelpWindow:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget);
		formatHelpWindow = nil;
	end);
	
	-- Create scrollable frame for content
	local scrollFrame = AceGUI:Create("ScrollFrame");
	scrollFrame:SetLayout("List");
	formatHelpWindow:AddChild(scrollFrame);
	
	-- Helper function to add a section
	local function AddSection(title, content)
		local heading = AceGUI:Create("Heading");
		heading:SetText(title);
		heading:SetFullWidth(true);
		scrollFrame:AddChild(heading);
		
		local label = AceGUI:Create("Label");
		label:SetText(content);
		label:SetFullWidth(true);
		scrollFrame:AddChild(label);
		
		-- Add spacing
		local spacer = AceGUI:Create("Label");
		spacer:SetText("");
		spacer:SetFullWidth(true);
		scrollFrame:AddChild(spacer);
	end
	
	-- Add sections with better formatting
	AddSection("Health Tokens", 
		"{hp} - Current health\n" ..
		"{hp:short} - Short format (e.g., 1.2K, 5.3M)\n" ..
		"{hp:%} - Health percentage\n" ..
		"{hp:%.0f} - Health percentage with 0 decimals\n" ..
		"{hp:bln} - Uses BreakUpLargeNumbers\n" ..
		"{hpmax} - Maximum health\n" ..
		"{hpmax:short} - Maximum health (short format)");
	
	AddSection("Power Tokens", 
		"{power} or {mana} - Current power/mana\n" ..
		"{power:short} - Short format (e.g., 1.2K, 5.3M)\n" ..
		"{power:%} - Power percentage\n" ..
		"{power:bln} - Uses BreakUpLargeNumbers\n" ..
		"{powermax} - Maximum power\n" ..
		"{powermax:short} - Maximum power (short format)");
	
	AddSection("Icon Tokens", 
		"{mark} - Raid target marker (uses current unit)\n" ..
		"{mark:target} - Raid target marker for target\n" ..
		"{combat} - Combat icon\n" ..
		"{resting} - Resting icon (player only)\n" ..
		"{dead} - Dead icon\n" ..
		"{ghost} - Ghost icon\n" ..
		"{classicon} - Class icon\n" ..
		"{specicon} - Specialization icon");
	
	AddSection("Status Tokens", 
		"{incombat} - In combat status\n" ..
		"{group} - Group status\n" ..
		"{role} - Role (Tank, Healer, DPS)\n" ..
		"{pvp} - PvP status");
	
	AddSection("Unit Tokens", 
		"{targetname} - Target name\n" ..
		"{targetname:short} - Target name (short)\n" ..
		"{targethealth} - Target health\n" ..
		"{targetlevel} - Target level\n" ..
		"{level} - Player level\n" ..
		"{class} - Class name\n" ..
		"{class:short} - Class name (short)");
	
	AddSection("Info Tokens", 
		"{zone} - Current zone\n" ..
		"{fps} - Frames per second\n" ..
		"{latency} - Latency\n" ..
		"{latency:local} - Local latency\n" ..
		"{latency:world} - World latency\n" ..
		"{latency:1f} - Latency with 1 decimal\n" ..
		"{latency:world:1f} - World latency with 1 decimal\n" ..
		"{time} - Current time\n" ..
		"{time:12} - Current time (12-hour format)");
	
	AddSection("Examples", 
		"You can combine tokens with arbitrary text:\n" ..
		"  ({hp}) - Shows health in parentheses\n" ..
		"  MP: {power} / {powermax} - Shows power with label\n" ..
		"  {hp:short} / {hpmax:short} - Shows health range\n" ..
		"  {combat} {hp:%}% - Shows combat icon and health %");
	
	formatHelpWindow:Show();
end

-- Method wrapper for ShowFormatHelpWindow
function TextOptions:ShowFormatHelp()
	ShowFormatHelpWindow();
end

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

local function Get(info)
	local db = GetDB();
	if not db then
		return;
	end

	local key = info[#info];

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

	if addon.NotifyConfigChanged then
		addon:NotifyConfigChanged();
	end
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
			formatHelpHeader = {
				type = "header",
				name = "Format Help",
				order = 10,
			},
			formatHelp = {
				type = "execute",
				name = "Show Format Help",
				desc = "Show help window with available format tokens.",
				order = 11,
				func = function()
					TextOptions:ShowFormatHelp();
				end,
			},
		};

		return {
			type = "group",
			name = "Data Texts",
			get = Get,
			set = Set,
			args = args,
		};
	end;
end

-- Register this option group
-- Note: TextOptions:BuildOptions() returns a function that builds the options table dynamically
if ns.Options then
	ns.Options:RegisterOptionGroup("texts", "Data Texts", 6, function() return TextOptions:BuildOptions(); end);
end