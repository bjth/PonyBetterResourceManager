local ADDON_NAME, ns = ...;

local addon = ns.Addon;

local Options = {};
ns.Options = Options;

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

	local personalGroup = ns.PersonalResourceOptions and ns.PersonalResourceOptions:BuildOptions() or nil;
	local targetGroup = ns.TargetResourceOptions and ns.TargetResourceOptions:BuildOptions() or nil;
	local textGroupBuilder = ns.PersonalResourceTextOptions and ns.PersonalResourceTextOptions:BuildOptions() or nil;
	local powerColorGroup = ns.PowerColorOptions and ns.PowerColorOptions:BuildOptions() or nil;

	-- Build options table as a function so it rebuilds dynamically when text entries change
	local function BuildOptionsTable()
		-- textGroupBuilder may be a function (for dynamic options) or a table (for static options)
		local textGroup = type(textGroupBuilder) == "function" and textGroupBuilder() or textGroupBuilder;

		return {
			type = "group",
			name = "Pony Better Resource Manager",
			childGroups = "tab",
			args = {
				personalResource = personalGroup and {
					type = "group",
					name = "Personal Resource",
					order = 1,
					args = personalGroup.args,
					get = personalGroup.get,
					set = personalGroup.set,
				} or nil,
				targetResource = targetGroup and {
					type = "group",
					name = "Target Resource",
					order = 2,
					args = targetGroup.args,
					get = targetGroup.get,
					set = targetGroup.set,
				} or nil,
				texts = textGroup and {
					type = "group",
					name = "Data Texts",
					order = 3,
					args = textGroup.args,
					get = textGroup.get,
					set = textGroup.set,
				} or nil,
				powerColors = powerColorGroup and {
					type = "group",
					name = "Power Colors",
					order = 4,
					args = powerColorGroup.args,
					get = powerColorGroup.get,
					set = powerColorGroup.set,
				} or nil,
			},
		};
	end

	AceConfig:RegisterOptionsTable("PonyBetterResourceManager", BuildOptionsTable);
	AceConfigDialog:AddToBlizOptions("PonyBetterResourceManager", "Pony Better Resource Manager");

	-- Profiles
	local profiles = AceDBOptions:GetOptionsTable(addon.db);
	AceConfig:RegisterOptionsTable("PonyBetterResourceManager_Profiles", profiles);
	AceConfigDialog:AddToBlizOptions("PonyBetterResourceManager_Profiles", "Profiles", "Pony Better Resource Manager");
end


