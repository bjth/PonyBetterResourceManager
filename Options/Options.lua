local ADDON_NAME, ns = ...;

local addon = ns.Addon;

local Options = {};
ns.Options = Options;

-- Initialize ResourceTypeRegistry early so other Options files can register
if not ns.ResourceTypeRegistry then
	ns.ResourceTypeRegistry = {};
end

-- Registry for option groups
local optionRegistry = {};

-- Register an option group
-- key: unique identifier (e.g., "personalResource", "targetResource")
-- name: display name (e.g., "Personal Resource", "Target Resource")
-- order: display order (lower numbers appear first)
-- builder: function or table that returns the option group
function Options:RegisterOptionGroup(key, name, order, builder)
	optionRegistry[key] = {
		name = name,
		order = order,
		builder = builder,
	};
end

function Options:Initialize()
	if not addon or not addon.db then
		return;
	end

	local AceConfig = LibStub("AceConfig-3.0", true);
	local AceConfigDialog = LibStub("AceConfigDialog-3.0", true);
	local AceDBOptions = LibStub("AceDBOptions-3.0", true);

	if not (AceConfig and AceConfigDialog and AceDBOptions) then
		if addon and addon.Print then
			addon:Print("AceConfig-3.0 / AceConfigDialog-3.0 / AceDBOptions-3.0 missing. Options UI disabled.");
		end
		return;
	end

	-- Build options table as a function so it rebuilds dynamically when text entries change
	local function BuildOptionsTable()
		local args = {};
		
		-- Unit frame resource keys (to be grouped under "Unit Configuration")
		local unitFrameKeys = {
			"personalResource",
			"targetResource",
			"focusResource",
			"petResource",
			"targetOfTargetResource",
		};
		
		-- Sort registered options by order
		local sortedKeys = {};
		for key, _ in pairs(optionRegistry) do
			table.insert(sortedKeys, key);
		end
		table.sort(sortedKeys, function(a, b)
			local orderA = optionRegistry[a].order or 999;
			local orderB = optionRegistry[b].order or 999;
			return orderA < orderB;
		end);
		
		-- Build Unit Configuration group
		local unitConfigArgs = {};
		local unitConfigOrder = 1;
		
		-- Build args from registry
		for _, key in ipairs(sortedKeys) do
			local entry = optionRegistry[key];
			local builder = entry.builder;
			
			-- builder may be a function (for dynamic options) or a table (for static options)
			local group = type(builder) == "function" and builder() or builder;
			
			-- Some builders (like TextOptions) return a function that needs to be called again
			if type(group) == "function" then
				group = group();
			end
			
			if group and type(group) == "table" then
				-- Check if this is a unit frame resource
				local isUnitFrame = false;
				for _, unitKey in ipairs(unitFrameKeys) do
					if key == unitKey then
						isUnitFrame = true;
						break;
					end
				end
				
				if isUnitFrame then
					-- Add to Unit Configuration group
					unitConfigArgs[key] = {
						type = "group",
						name = entry.name,
						order = unitConfigOrder,
						args = group.args,
						get = group.get,
						set = group.set,
						childGroups = group.childGroups, -- Preserve childGroups (e.g., "tab" for tabs)
					};
					unitConfigOrder = unitConfigOrder + 1;
				else
					-- Add to root args
					args[key] = {
						type = "group",
						name = entry.name,
						order = entry.order,
						args = group.args,
						get = group.get,
						set = group.set,
						childGroups = group.childGroups, -- Preserve childGroups (e.g., "tab" for tabs)
					};
				end
			end
		end
		
		-- Add Unit Configuration group to root args
		if next(unitConfigArgs) then
			args.unitConfiguration = {
				type = "group",
				name = "Unit Configuration",
				order = 1,
				childGroups = "tree",
				args = unitConfigArgs,
			};
		end

		return {
			type = "group",
			name = "Pony Better Resource Manager",
			childGroups = "tree",
			args = args,
		};
	end

	AceConfig:RegisterOptionsTable("PonyBetterResourceManager", BuildOptionsTable);
	AceConfigDialog:AddToBlizOptions("PonyBetterResourceManager", "Pony Better Resource Manager");

	-- Profiles
	local profiles = AceDBOptions:GetOptionsTable(addon.db);
	AceConfig:RegisterOptionsTable("PonyBetterResourceManager_Profiles", profiles);
	AceConfigDialog:AddToBlizOptions("PonyBetterResourceManager_Profiles", "Profiles", "Pony Better Resource Manager");
end


