local ADDON_NAME, ns = ...;

local AceAddon = LibStub and LibStub("AceAddon-3.0", true);
local AceConsole = LibStub and LibStub("AceConsole-3.0", true);
local AceEvent = LibStub and LibStub("AceEvent-3.0", true);

if not (AceAddon and AceConsole and AceEvent) then
	-- Hard abort if Ace3 isn't available; this keeps errors obvious during development.
	return;
end

local addon = AceAddon:NewAddon("PonyBetterResourceManager", "AceConsole-3.0", "AceEvent-3.0");
ns.Addon = addon;

addon.modules = addon.modules or {};

local function SafeCall(func, ...)
	if type(func) == "function" then
		return func(...);
	end
end

function addon:OnInitialize()
	local AceDB = LibStub("AceDB-3.0", true);
	if not AceDB then
		self:Print("AceDB-3.0 not found. PonyBetterResourceManager will not save settings.");
		return;
	end

	local defaults = ns.Defaults or {};
	self.db = AceDB:New("PonyBetterResourceManagerDB", defaults, true);

	-- Migrate existing texts to have resourceType field
	if ns.PersonalResourceTextOptions and ns.PersonalResourceTextOptions.MigrateTexts then
		ns.PersonalResourceTextOptions:MigrateTexts();
	end

	-- Set up options UI once the DB exists.
	if ns.Options and ns.Options.Initialize then
		ns.Options:Initialize();
	end

	self:RegisterChatCommand("pbrm", "OpenConfig");
	self:RegisterChatCommand("ponyresource", "OpenConfig");
end

function addon:OnEnable()
	-- Hook Edit Mode systems.
	if ns.EditMode and ns.EditMode.InitPersonalResourceSystem then
		ns.EditMode:InitPersonalResourceSystem();
	end
	
	-- Initialize Edit Mode integration for Target Resource
	if ns.EditModeTargetResource and ns.EditModeTargetResource.Init then
		ns.EditModeTargetResource:Init();
	end
	
	-- Initialize Edit Mode integration for Focus Resource
	if ns.EditModeFocusResource and ns.EditModeFocusResource.Init then
		ns.EditModeFocusResource:Init();
	end
	
	-- Initialize Edit Mode integration for Pet Resource
	if ns.EditModePetResource and ns.EditModePetResource.Init then
		ns.EditModePetResource:Init();
	end
	
	-- Initialize Edit Mode integration for Target of Target Resource
	if ns.EditModeTargetOfTargetResource and ns.EditModeTargetOfTargetResource.Init then
		ns.EditModeTargetOfTargetResource:Init();
	end
end

function addon:OpenConfig()
	local AceConfigDialog = LibStub("AceConfigDialog-3.0", true);
	if not AceConfigDialog then
		self:Print("AceConfigDialog-3.0 not found. Cannot open options.");
		return;
	end

	AceConfigDialog:Open("PonyBetterResourceManager");
end

function addon:NotifyConfigChanged()
	-- Notify interested modules that configuration has changed.
	local personalModule = self:GetModule("PersonalResource", true);
	if personalModule and personalModule.RefreshFromConfig then
		SafeCall(personalModule.RefreshFromConfig, personalModule);
	end
	
	local function HandleModuleRefresh(moduleName, profileKey)
		local module = self:GetModule(moduleName, true);
		if module then
			local profile = self.db and self.db.profile;
			local shouldBeEnabled = profile and profile[profileKey] and profile[profileKey].enabled == true;
			
			if shouldBeEnabled and not module:IsEnabled() then
				module:Enable();
			elseif not shouldBeEnabled and module:IsEnabled() then
				module:Disable();
			elseif module.RefreshFromConfig then
				SafeCall(module.RefreshFromConfig, module);
			end
		end
	end
	
	HandleModuleRefresh("TargetResource", "targetResource");
	HandleModuleRefresh("FocusResource", "focusResource");
	HandleModuleRefresh("PetResource", "petResource");
	HandleModuleRefresh("TargetOfTargetResource", "targetOfTargetResource");
end


