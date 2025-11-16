local ADDON_NAME, ns = ...;

local addon = ns.Addon;
if not addon then
	return;
end

local TargetResource = addon:NewModule("TargetResource", "AceEvent-3.0");
ns.TargetResource = TargetResource;

local UnitFrameBase = ns.UnitFrameBase;

local function GetDB()
	return (addon.db and addon.db.profile and addon.db.profile.targetResource) or nil;
end

local function IsModuleEnabled()
	local profile = addon.db and addon.db.profile;
	if not profile then
		return false;
	end
	return profile.targetResource and profile.targetResource.enabled == true;
end

-- Create the target resource display frame
function TargetResource:CreateFrame()
	if self.frame then
		return self.frame;
	end
	
	-- Use UnitFrameBase to create the frame
	local frame = UnitFrameBase:CreateUnitFrame({
		frameName = "PBRMTargetResourceDisplayFrame",
		defaultSize = { width = 200, height = 20 },
		defaultPoint = { "CENTER", UIParent, "CENTER", 0, 0 }
	});
	
	local db = GetDB();
	
	-- Setup Edit Mode integration
	UnitFrameBase:SetupEditModeIntegration(frame, {
		systemName = "Pony Target Frame",
		db = db,
		defaultHideSelection = false,
		hasUnitFunc = function() return UnitExists("target"); end,
		onEditModeEnter = function(self)
			self:Show();
		end,
		onEditModeExit = function(self)
			if UnitExists("target") then
				self:Show();
			end
		end
	});
	
	self.frame = frame;
	
	-- Make frame clickable to target and hoverable for spell casting
	UnitFrameBase:SetupFrameInteraction(frame, "target");
	
	-- Initial styling and update - ensure the frame is properly styled and updated
	-- This is important because CreateFrame might be called before OnEnable
	local Style = ns.TargetResourceStyle;
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
	end
	
	-- Update display if we have a target or are in Edit Mode
	if UnitExists("target") or (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()) then
		self:UpdateTargetDisplay();
	end
	
	return frame;
end

function TargetResource:OnInitialize()
	-- No-op for now
end

function TargetResource:OnEnable()
	if not IsModuleEnabled() then
		return;
	end
	
	self:CreateFrame();
	
	-- Register for target unit events
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
				-- Explicitly show the frame first
				self.frame:Show();
				if self.frame.OnEditModeEnter then
					self.frame:OnEditModeEnter();
				end
				
				-- Use a small delay to ensure Edit Mode state is fully updated
				C_Timer.After(0.1, function()
					-- Ensure frame is visible in Edit Mode and update display
					self:UpdateTargetDisplay();
				end);
			end
		end);
		
		EventRegistry:RegisterCallback("EditMode.Exit", function()
			if self.frame then
				if self.frame.OnEditModeExit then
					self.frame:OnEditModeExit();
				end
				-- Update visibility after Edit Mode - this will show if target exists
				self:UpdateTargetDisplay();
			end
		end);
	end
	
	-- Initial update - check if we should show the frame
	-- If Edit Mode is already active when the module loads, show the frame
	local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive();
	if inEditMode and self.frame then
		if self.frame.OnEditModeEnter then
			self.frame:OnEditModeEnter();
		end
	end
	
	-- Handle TargetFrame visibility on initialization
	local db = GetDB();
	if db and UnitFrameBase then
		UnitFrameBase:SetupBlizzardFrameHiding("TargetFrame", db, GetDB, "hideTargetFrame", function() return UnitExists("target"); end);
	end
	
	-- Update display (will show/hide based on target and Edit Mode state)
	self:UpdateTargetDisplay();
end

function TargetResource:OnDisable()
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

function TargetResource:PLAYER_TARGET_CHANGED()
	-- Update TargetFrame visibility when target changes
	local db = GetDB();
	if db then
		local targetFrame = _G.TargetFrame;
		if targetFrame and not db.hideTargetFrame then
			-- Only show TargetFrame if there's actually a target
			if UnitExists("target") then
				targetFrame:Show();
			else
				targetFrame:Hide();
			end
		end
	end
	
	self:UpdateTargetDisplay();
end

function TargetResource:UNIT_HEALTH(event, unit)
	if unit == "target" then
		self:UpdateTargetHealth();
	end
end

function TargetResource:UNIT_MAXHEALTH(event, unit)
	if unit == "target" then
		self:UpdateTargetHealth();
	end
end

function TargetResource:UNIT_POWER_UPDATE(event, unit, powerType)
	if unit == "target" then
		self:UpdateTargetPower();
	end
end

function TargetResource:UNIT_MAXPOWER(event, unit, powerType)
	if unit == "target" then
		self:UpdateTargetPower();
	end
end

function TargetResource:UNIT_DISPLAYPOWER(event, unit)
	if unit == "target" then
		self:UpdateTargetPower();
	end
end

function TargetResource:UNIT_HEAL_PREDICTION(event, unit)
	if unit == "target" then
		self:UpdateTargetHealth();
	end
end

function TargetResource:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
	if unit == "target" then
		self:UpdateTargetHealth();
	end
end

function TargetResource:UpdateTargetDisplay()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.TargetResourceStyle;
	
	-- Use UnitFrameBase to update display
	UnitFrameBase:UpdateUnitDisplay(frame, "target", db, Style, function() return UnitExists("target"); end);
end

function TargetResource:UpdateTargetHealth()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.TargetResourceStyle;
	
	-- Use UnitFrameBase to update health
	UnitFrameBase:UpdateUnitHealth(frame, "target", db, Style);
end

function TargetResource:UpdateTargetPower()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.TargetResourceStyle;
	
	-- Use UnitFrameBase to update power
	UnitFrameBase:UpdateUnitPower(frame, "target", db, Style);
end

function TargetResource:RefreshFromConfig()
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
	
	-- Handle TargetFrame visibility
	local db = GetDB();
	if db and UnitFrameBase then
		-- Re-setup Blizzard frame hiding in case option changed
		UnitFrameBase:SetupBlizzardFrameHiding("TargetFrame", db, GetDB, "hideTargetFrame", function() return UnitExists("target"); end);
	end
	
	-- Apply scale if configured
	local FrameLayout = ns.FrameLayout;
	if FrameLayout then
		FrameLayout:ApplyScale(frame, db);
	end
	
	local Style = ns.TargetResourceStyle;
	
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
	end
	
	-- Update display if target exists
	if UnitExists("target") then
		self:UpdateTargetDisplay();
	end
end

