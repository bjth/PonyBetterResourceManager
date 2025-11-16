local ADDON_NAME, ns = ...;

local addon = ns.Addon;
if not addon then
	return;
end

local TargetOfTargetResource = addon:NewModule("TargetOfTargetResource", "AceEvent-3.0");
ns.TargetOfTargetResource = TargetOfTargetResource;

local UnitFrameBase = ns.UnitFrameBase;

local function GetDB()
	return (addon.db and addon.db.profile and addon.db.profile.targetOfTargetResource) or nil;
end

local function IsModuleEnabled()
	local profile = addon.db and addon.db.profile;
	if not profile then
		return false;
	end
	return profile.targetOfTargetResource and profile.targetOfTargetResource.enabled == true;
end

-- Create the target of target resource display frame
function TargetOfTargetResource:CreateFrame()
	if self.frame then
		return self.frame;
	end
	
	-- Use UnitFrameBase to create the frame
	local frame = UnitFrameBase:CreateUnitFrame({
		frameName = "PBRMTargetOfTargetResourceDisplayFrame",
		defaultSize = { width = 200, height = 20 },
		defaultPoint = { "CENTER", UIParent, "CENTER", 0, 0 }
	});
	
	local db = GetDB();
	
	-- Setup Edit Mode integration
	UnitFrameBase:SetupEditModeIntegration(frame, {
		systemName = "Pony Target of Target Frame",
		db = db,
		defaultHideSelection = false,
		hasUnitFunc = function() return UnitExists("target") and UnitExists("targettarget"); end,
		onEditModeEnter = function(self)
			self:Show();
		end,
		onEditModeExit = function(self)
			if UnitExists("target") and UnitExists("targettarget") then
				self:Show();
			end
		end
	});
	
	self.frame = frame;
	
	-- Make frame clickable to target and hoverable for spell casting
	UnitFrameBase:SetupFrameInteraction(frame, "targettarget");
	
	-- Initial styling and update
	local Style = ns.TargetOfTargetResourceStyle;
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
	end
	
	-- Update display if we have a target's target or are in Edit Mode
	if (UnitExists("target") and UnitExists("targettarget")) or (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()) then
		self:UpdateTargetOfTargetDisplay();
	end
	
	return frame;
end

function TargetOfTargetResource:OnInitialize()
	-- No-op for now
end

function TargetOfTargetResource:OnEnable()
	if not IsModuleEnabled() then
		return;
	end
	
	self:CreateFrame();
	
	-- Register for target of target unit events
	-- Note: targettarget changes when target changes, so we listen to PLAYER_TARGET_CHANGED
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "PLAYER_TARGET_CHANGED");
	self:RegisterEvent("UNIT_HEALTH", "UNIT_HEALTH");
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_MAXHEALTH");
	self:RegisterEvent("UNIT_POWER_UPDATE", "UNIT_POWER_UPDATE");
	self:RegisterEvent("UNIT_MAXPOWER", "UNIT_MAXPOWER");
	self:RegisterEvent("UNIT_DISPLAYPOWER", "UNIT_DISPLAYPOWER");
	self:RegisterEvent("UNIT_HEAL_PREDICTION", "UNIT_HEAL_PREDICTION");
	self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_ABSORB_AMOUNT_CHANGED");
	
	-- Listen for Edit Mode events via EventRegistry
	if EventRegistry then
		EventRegistry:RegisterCallback("EditMode.Enter", function()
			if self.frame then
				self.frame:Show();
				if self.frame.OnEditModeEnter then
					self.frame:OnEditModeEnter();
				end
				
				C_Timer.After(0.1, function()
					self:UpdateTargetOfTargetDisplay();
				end);
			end
		end);
		
		EventRegistry:RegisterCallback("EditMode.Exit", function()
			if self.frame then
				if self.frame.OnEditModeExit then
					self.frame:OnEditModeExit();
				end
				self:UpdateTargetOfTargetDisplay();
			end
		end);
	end
	
	-- Initial update - check if we should show the frame
	local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive();
	if inEditMode and self.frame then
		if self.frame.OnEditModeEnter then
			self.frame:OnEditModeEnter();
		end
	end
	
	-- Handle TargetFrameToT visibility on initialization
	local db = GetDB();
	if db and UnitFrameBase then
		UnitFrameBase:SetupBlizzardFrameHiding("TargetFrameToT", db, GetDB, "hideTargetOfTargetFrame", function() return UnitExists("target") and UnitExists("targettarget"); end);
	end
	
	-- Update display (will show/hide based on target's target and Edit Mode state)
	self:UpdateTargetOfTargetDisplay();
end

function TargetOfTargetResource:OnDisable()
	if self.frame then
		self.frame:Hide();
	end
	
	self:UnregisterEvent("PLAYER_TARGET_CHANGED");
	self:UnregisterEvent("UNIT_HEALTH");
	self:UnregisterEvent("UNIT_MAXHEALTH");
	self:UnregisterEvent("UNIT_POWER_UPDATE");
	self:UnregisterEvent("UNIT_MAXPOWER");
	self:UnregisterEvent("UNIT_DISPLAYPOWER");
	self:UnregisterEvent("UNIT_HEAL_PREDICTION");
	self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED");
end

function TargetOfTargetResource:PLAYER_TARGET_CHANGED()
	local db = GetDB();
	if db and UnitFrameBase then
		UnitFrameBase:SetupBlizzardFrameHiding("TargetFrameToT", db, GetDB, "hideTargetOfTargetFrame", function() return UnitExists("target") and UnitExists("targettarget"); end);
	end
	self:UpdateTargetOfTargetDisplay();
end

function TargetOfTargetResource:UNIT_HEALTH(event, unit)
	if unit == "targettarget" then
		self:UpdateTargetOfTargetHealth();
	end
end

function TargetOfTargetResource:UNIT_MAXHEALTH(event, unit)
	if unit == "targettarget" then
		self:UpdateTargetOfTargetHealth();
	end
end

function TargetOfTargetResource:UNIT_POWER_UPDATE(event, unit, powerType)
	if unit == "targettarget" then
		self:UpdateTargetOfTargetPower();
	end
end

function TargetOfTargetResource:UNIT_MAXPOWER(event, unit, powerType)
	if unit == "targettarget" then
		self:UpdateTargetOfTargetPower();
	end
end

function TargetOfTargetResource:UNIT_DISPLAYPOWER(event, unit)
	if unit == "targettarget" then
		self:UpdateTargetOfTargetPower();
	end
end

function TargetOfTargetResource:UNIT_HEAL_PREDICTION(event, unit)
	if unit == "targettarget" then
		self:UpdateTargetOfTargetHealth();
	end
end

function TargetOfTargetResource:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
	if unit == "targettarget" then
		self:UpdateTargetOfTargetHealth();
	end
end

function TargetOfTargetResource:UpdateTargetOfTargetDisplay()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.TargetOfTargetResourceStyle;
	
	-- Use UnitFrameBase to update display
	UnitFrameBase:UpdateUnitDisplay(frame, "targettarget", db, Style, function() return UnitExists("target") and UnitExists("targettarget"); end);
end

function TargetOfTargetResource:UpdateTargetOfTargetHealth()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.TargetOfTargetResourceStyle;
	
	-- Use UnitFrameBase to update health
	UnitFrameBase:UpdateUnitHealth(frame, "targettarget", db, Style);
end

function TargetOfTargetResource:UpdateTargetOfTargetPower()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.TargetOfTargetResourceStyle;
	
	-- Use UnitFrameBase to update power
	UnitFrameBase:UpdateUnitPower(frame, "targettarget", db, Style);
end

function TargetOfTargetResource:RefreshFromConfig()
	if not IsModuleEnabled() then
		if self.frame then
			self.frame:Hide();
		end
		return;
	end
	
	local frame = self.frame;
	if not frame then
		return;
	end
	
	-- Handle TargetFrameToT visibility
	local db = GetDB();
	if db and UnitFrameBase then
		-- Re-setup Blizzard frame hiding in case option changed
		UnitFrameBase:SetupBlizzardFrameHiding("TargetFrameToT", db, GetDB, "hideTargetOfTargetFrame", function() return UnitExists("target") and UnitExists("targettarget"); end);
	end
	
	-- Apply scale if configured
	local FrameLayout = ns.FrameLayout;
	if FrameLayout then
		FrameLayout:ApplyScale(frame, db);
	end
	
	local Style = ns.TargetOfTargetResourceStyle;
	
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
	end
	
	-- Update display if target's target exists
	if UnitExists("target") and UnitExists("targettarget") then
		self:UpdateTargetOfTargetDisplay();
	end
end

