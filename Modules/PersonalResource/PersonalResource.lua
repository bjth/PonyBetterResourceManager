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
					-- Also apply power color immediately after setup
					local PowerColor = ns.PowerColor;
					local db = GetDB();
					if PowerColor and db and frame.PowerBar then
						PowerColor:ApplyPowerColor(frame.PowerBar, "player", db, false);
					end
					
					-- Hook SetStatusBarTexture on the power bar instance to catch texture resets
					local powerBar = frame.PowerBar;
					if powerBar and not powerBar._PBRMTextureHookSet then
						powerBar._PBRMTextureHookSet = true;
						hooksecurefunc(powerBar, "SetStatusBarTexture", function(self, texture)
							-- Reapply full styling immediately after texture is set
							if IsModuleEnabled() then
								Style:ApplyPowerBarStyle(frame, GetDB());
							end
						end);
					end
					
					-- Store frame reference for use in Style.lua's OnValueChanged hook
					-- Style.lua will extend its OnValueChanged hook to also reapply styling
					if powerBar then
						powerBar._PBRMStyleFrameRef = frame;
					end
				end
			end);
		end
		
		-- Note: We don't need to hook UpdatePower directly anymore since OnValueChanged
		-- fires immediately after the value is updated, which is after UpdatePower completes.
		-- This eliminates flicker by reapplying styling synchronously.

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
					local db = GetDB();
					Style:UpdateHealthText(frame, db);
					-- Also update overheal and absorb bars
					if Style.UpdateOverhealAbsorbBars then
						Style:UpdateOverhealAbsorbBars(frame, db);
					end
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

	-- Make frame clickable to target player and hoverable for spell casting
	self:SetupFrameInteraction(frame);

	-- Handle PlayerFrame visibility on initialization
	local db = GetDB();
	if db then
		local function setupPlayerFrameHook()
			local playerFrame = _G.PlayerFrame;
			if playerFrame then
				-- Hook Show method to prevent PlayerFrame from showing when option is enabled
				if not playerFrame._PBRMShowHookSet then
					playerFrame._PBRMShowHookSet = true;
					hooksecurefunc(playerFrame, "Show", function(self)
						local db = GetDB();
						if db and db.hidePlayerFrame then
							-- Immediately hide if option is enabled
							self:Hide();
						end
					end);
				end
				
				if db.hidePlayerFrame then
					playerFrame:Hide();
				else
					-- Show the PlayerFrame when option is disabled
					playerFrame:Show();
				end
			end
		end
		
		-- Try immediately
		setupPlayerFrameHook();
		
		-- Also try after a delay in case PlayerFrame isn't created yet
		C_Timer.After(0.5, setupPlayerFrameHook);
	end

	-- Do not call Blizzard's setup methods directly (they may touch secret values),
	-- but do apply our styling/layout once so that reload/login immediately reflects
	-- current settings even if Setup* already ran before our hooks were installed.
	local Style = ns.PersonalResourceStyle;
	if Style and Style.ApplyAll then
		Style:ApplyAll(frame, GetDB());
	end
	
	-- Ensure power color is applied on initial load
	-- This fixes the issue where power color doesn't show until an event fires
	local PowerColor = ns.PowerColor;
	if PowerColor and db and frame.PowerBar then
		-- Use a small delay to ensure power type is determined
		C_Timer.After(0.1, function()
			if frame and frame.PowerBar then
				PowerColor:ApplyPowerColor(frame.PowerBar, "player", db, false);
			end
		end);
	end
end

function PersonalResource:SetupFrameInteraction(frame)
	if not frame then
		return;
	end
	
	-- Check if we've already set this up
	if frame._PBRSecureButton then
		return;
	end
	
	-- Use secure unit button template for clicking and spell casting
	-- This allows clicking to target player and hovering to cast spells on player
	-- Use "togglemenu" instead of "menu" - togglemenu is a secure action that automatically
	-- determines the correct menu type based on the unit, and calls UnitPopup_OpenMenu
	-- from secure code, allowing menu items to call protected functions
	local secureButton = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate");
	secureButton:SetAllPoints(frame);
	secureButton:SetAttribute("unit", "player");
	secureButton:SetAttribute("*type1", "target");      -- Left click targets player
	secureButton:SetAttribute("*type2", "togglemenu");  -- Right click opens menu (secure action)
	secureButton:RegisterForClicks("AnyUp");
	secureButton:RegisterForDrag("LeftButton", "RightButton");
	
	-- Enable mouse on secure button for hover/click
	secureButton:EnableMouse(true);
	
	-- Make sure the frame itself allows mouse passthrough to the secure button
	frame:EnableMouse(false);  -- Disable on main frame, let secure button handle it
	
	-- Store reference
	frame._PBRSecureButton = secureButton;
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

	-- Handle PlayerFrame visibility
	local db = GetDB();
	if db then
		local playerFrame = _G.PlayerFrame;
		if playerFrame then
			-- Ensure hook is set up (in case option was changed after initialization)
			if not playerFrame._PBRMShowHookSet then
				playerFrame._PBRMShowHookSet = true;
				hooksecurefunc(playerFrame, "Show", function(self)
					local db = GetDB();
					if db and db.hidePlayerFrame then
						-- Immediately hide if option is enabled
						self:Hide();
					end
				end);
			end
			
			if db.hidePlayerFrame then
				playerFrame:Hide();
			else
				-- Show the PlayerFrame when option is disabled
				-- Blizzard will handle whether it should actually be visible based on conditions
				playerFrame:Show();
			end
		end
	end

	local Style = ns.PersonalResourceStyle;

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
			-- Note: Styling is reapplied via OnValueChanged hook, so no need to do it here
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
	-- Scale is now handled entirely by Blizzard's Edit Mode UI
end


