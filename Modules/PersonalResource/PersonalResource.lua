local ADDON_NAME, ns = ...;

local addon = ns.Addon;
if not addon then
	return;
end

local PersonalResource = addon:NewModule("PersonalResource", "AceEvent-3.0");
ns.PersonalResource = PersonalResource;

local function GetDB()
	return (addon.db and addon.db.profile and addon.db.profile.personalResource) or nil;
end

local function IsModuleEnabled()
	local profile = addon.db and addon.db.profile;
	if not profile then
		return false;
	end

	-- Personal resource styling is always enabled as long as the profile exists;
	-- per-bar visibility is controlled by the individual show* toggles.
	return profile.personalResource ~= nil;
end

local hooked;

local function EnsureHooks()
	if hooked then
		return;
	end
	hooked = true;

	if type(PersonalResourceDisplayMixin) == "table" then
		local Style = ns.PersonalResourceStyle;

		if Style and Style.ApplyHealthBarStyle then
			hooksecurefunc(PersonalResourceDisplayMixin, "SetupHealthBar", function(frame)
				if IsModuleEnabled() then
					Style:ApplyHealthBarStyle(frame, GetDB());
				end
			end);
		end

		if Style and Style.ApplyPowerBarStyle then
			hooksecurefunc(PersonalResourceDisplayMixin, "SetupPowerBar", function(frame)
				if IsModuleEnabled() then
					Style:ApplyPowerBarStyle(frame, GetDB());
				end
			end);
		end

		if Style and Style.ApplyAlternatePowerStyle then
			hooksecurefunc(PersonalResourceDisplayMixin, "SetupAlternatePowerBar", function(frame)
				if IsModuleEnabled() then
					Style:ApplyAlternatePowerStyle(frame, GetDB());
				end
			end);
		end

		if Style and Style.ApplyClassResourceStyle and PersonalResourceDisplayMixin.SetupClassBar then
			hooksecurefunc(PersonalResourceDisplayMixin, "SetupClassBar", function(frame)
				if IsModuleEnabled() then
					Style:ApplyClassResourceStyle(frame, GetDB());
				end
			end);
		end

		if Style and Style.UpdateHealthText then
			hooksecurefunc(PersonalResourceDisplayMixin, "UpdateHealth", function(frame)
				if IsModuleEnabled() then
					Style:UpdateHealthText(frame, GetDB());
				end
			end);
		end
	end
end

function PersonalResource:OnInitialize()
	-- No-op for now; we rely on OnEnable for runtime hooks.
end

function PersonalResource:OnEnable()
	if not IsModuleEnabled() then
		return;
	end

	self:InitializeFrame();
	
	-- Register for UNIT_HEALTH events to ensure text updates when health changes
	-- Pass the method names explicitly to avoid lookup issues
	self:RegisterEvent("UNIT_HEALTH", "UNIT_HEALTH");
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_MAXHEALTH");
	-- Register for UNIT_POWER events to ensure text updates when power changes
	self:RegisterEvent("UNIT_POWER_UPDATE", "UNIT_POWER_UPDATE");
	self:RegisterEvent("UNIT_MAXPOWER", "UNIT_MAXPOWER");
	-- Register for target and raid target changes to update {mark} token
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "PLAYER_TARGET_CHANGED");
	self:RegisterEvent("RAID_TARGET_UPDATE", "RAID_TARGET_UPDATE");
end

function PersonalResource:OnDisable()
	-- We don't call Blizzard's setup methods directly here, as doing so can
	-- attempt to do math on secret values in Midnight. Instead we simply stop
	-- applying our styling by honoring IsModuleEnabled() in hooks.
	
	-- Unregister health and power events
	self:UnregisterEvent("UNIT_HEALTH");
	self:UnregisterEvent("UNIT_MAXHEALTH");
	self:UnregisterEvent("UNIT_POWER_UPDATE");
	self:UnregisterEvent("UNIT_MAXPOWER");
	-- Unregister target and raid target events
	self:UnregisterEvent("PLAYER_TARGET_CHANGED");
	self:UnregisterEvent("RAID_TARGET_UPDATE");
end

function PersonalResource:InitializeFrame()
	local frame = _G.PersonalResourceDisplayFrame;
	if not frame then
		self:RegisterEvent("ADDON_LOADED");
		return;
	end

	self.frame = frame;
	EnsureHooks();

	-- Do not call Blizzard's setup methods directly (they may touch secret values),
	-- but do apply our styling/layout once so that reload/login immediately reflects
	-- current settings even if Setup* already ran before our hooks were installed.
	local Style = ns.PersonalResourceStyle;
	if Style and Style.ApplyAll then
		Style:ApplyAll(frame, GetDB());
	end

	local Layout = ns.PersonalResourceLayout;
	if Layout and Layout.ApplyLayout then
		Layout:ApplyLayout(frame, GetDB());
	end
end

function PersonalResource:ADDON_LOADED(_, name)
	if name == "Blizzard_PersonalResourceDisplay" then
		self:UnregisterEvent("ADDON_LOADED");
		self:InitializeFrame();
	end
end

function PersonalResource:RefreshFromConfig()
	if not IsModuleEnabled() then
		return;
	end

	local frame = _G.PersonalResourceDisplayFrame;
	if not frame then
		return;
	end

	local Style = ns.PersonalResourceStyle;
	local Layout = ns.PersonalResourceLayout;

	if Style and Style.ApplyAll then
		Style:ApplyAll(frame, GetDB());
	else
		if Style and Style.ApplyHealthBarStyle then
			Style:ApplyHealthBarStyle(frame, GetDB());
		end
		if Style and Style.ApplyPowerBarStyle then
			Style:ApplyPowerBarStyle(frame, GetDB());
		end
		if Style and Style.ApplyAlternatePowerStyle then
			Style:ApplyAlternatePowerStyle(frame, GetDB());
		end
	end

	if Layout and Layout.ApplyLayout then
		Layout:ApplyLayout(frame, GetDB());
	end
end

function PersonalResource:UNIT_HEALTH(event, unit)
	if unit == "player" then
		local frame = _G.PersonalResourceDisplayFrame;
		if frame and frame.healthbar then
			local Style = ns.PersonalResourceStyle;
			if Style and Style.UpdateHealthText then
				Style:UpdateHealthText(frame, GetDB());
			end
		end
	end
end

function PersonalResource:UNIT_MAXHEALTH(event, unit)
	if unit == "player" then
		local frame = _G.PersonalResourceDisplayFrame;
		if frame and frame.healthbar then
			local Style = ns.PersonalResourceStyle;
			if Style and Style.UpdateHealthText then
				Style:UpdateHealthText(frame, GetDB());
			end
		end
	end
end

function PersonalResource:UNIT_POWER_UPDATE(event, unit, powerType)
	if unit == "player" and (not powerType or powerType == "MANA" or powerType == "ENERGY" or powerType == "RAGE" or powerType == "FOCUS" or powerType == "RUNIC_POWER") then
		local frame = _G.PersonalResourceDisplayFrame;
		if frame and frame.PowerBar then
			local Style = ns.PersonalResourceStyle;
			if Style and Style.UpdatePowerText then
				Style:UpdatePowerText(frame, GetDB());
			end
		end
	end
end

function PersonalResource:UNIT_MAXPOWER(event, unit, powerType)
	if unit == "player" and (not powerType or powerType == "MANA" or powerType == "ENERGY" or powerType == "RAGE" or powerType == "FOCUS" or powerType == "RUNIC_POWER") then
		local frame = _G.PersonalResourceDisplayFrame;
		if frame and frame.PowerBar then
			local Style = ns.PersonalResourceStyle;
			if Style and Style.UpdatePowerText then
				Style:UpdatePowerText(frame, GetDB());
			end
		end
	end
end

function PersonalResource:PLAYER_TARGET_CHANGED(event)
	-- Update all text displays when target changes (for {mark} token)
	local frame = _G.PersonalResourceDisplayFrame;
	if frame then
		local Style = ns.PersonalResourceStyle;
		if Style then
			if Style.UpdateHealthText then
				Style:UpdateHealthText(frame, GetDB());
			end
			if Style.UpdatePowerText then
				Style:UpdatePowerText(frame, GetDB());
			end
		end
	end
end

function PersonalResource:RAID_TARGET_UPDATE(event)
	-- Update all text displays when raid target markers change (for {mark} token)
	local frame = _G.PersonalResourceDisplayFrame;
	if frame then
		local Style = ns.PersonalResourceStyle;
		if Style then
			if Style.UpdateHealthText then
				Style:UpdateHealthText(frame, GetDB());
			end
			if Style.UpdatePowerText then
				Style:UpdatePowerText(frame, GetDB());
			end
		end
	end
end

function PersonalResource:OnEditModeExit(systemFrame)
	-- The system frame here is the same PersonalResourceDisplayFrame instance.
	local Layout = ns.PersonalResourceLayout;
	if Layout and Layout.OnEditModeExit then
		Layout:OnEditModeExit(systemFrame, GetDB());
	end
end


