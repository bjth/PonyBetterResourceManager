local ADDON_NAME, ns = ...;

local addon = ns.Addon;
if not addon then
	return;
end

local FocusResource = addon:NewModule("FocusResource", "AceEvent-3.0");
ns.FocusResource = FocusResource;

local UnitFrameBase = ns.UnitFrameBase;

local function GetDB()
	return (addon.db and addon.db.profile and addon.db.profile.focusResource) or nil;
end

local function IsModuleEnabled()
	local profile = addon.db and addon.db.profile;
	if not profile then
		return false;
	end
	return profile.focusResource and profile.focusResource.enabled == true;
end

-- Create the focus resource display frame
function FocusResource:CreateFrame()
	if self.frame then
		return self.frame;
	end
	
	-- Use UnitFrameBase to create the frame
	local frame = UnitFrameBase:CreateUnitFrame({
		frameName = "PBRMFocusResourceDisplayFrame",
		defaultSize = { width = 200, height = 20 },
		defaultPoint = { "CENTER", UIParent, "CENTER", 0, 0 }
	});
	
	local db = GetDB();
	
	-- Setup Edit Mode integration
	UnitFrameBase:SetupEditModeIntegration(frame, {
		systemName = "Pony Focus Frame",
		db = db,
		defaultHideSelection = false,
		hasUnitFunc = function() return UnitExists("focus"); end,
		onEditModeEnter = function(self)
			self:Show();
		end,
		onEditModeExit = function(self)
			if UnitExists("focus") then
				self:Show();
			end
		end
	});
	
	self.frame = frame;
	
	-- Make frame clickable to target and hoverable for spell casting
	UnitFrameBase:SetupFrameInteraction(frame, "focus");
	
	-- Initial styling and update
	local Style = ns.FocusResourceStyle;
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
	end
	
	-- Update display if we have a focus or are in Edit Mode
	if UnitExists("focus") or (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()) then
		self:UpdateFocusDisplay();
	end
	
	return frame;
end

function FocusResource:OnInitialize()
	-- No-op for now
end

function FocusResource:OnEnable()
	if not IsModuleEnabled() then
		return;
	end
	
	self:CreateFrame();
	
	-- Register for focus unit events
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", "PLAYER_FOCUS_CHANGED");
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
					self:UpdateFocusDisplay();
				end);
			end
		end);
		
		EventRegistry:RegisterCallback("EditMode.Exit", function()
			if self.frame then
				if self.frame.OnEditModeExit then
					self.frame:OnEditModeExit();
				end
				self:UpdateFocusDisplay();
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
	
	-- Handle FocusFrame visibility on initialization
	local db = GetDB();
	if db and UnitFrameBase then
		UnitFrameBase:SetupBlizzardFrameHiding("FocusFrame", db, GetDB, "hideFocusFrame", function() return UnitExists("focus"); end);
	end
	
	-- Update display (will show/hide based on focus and Edit Mode state)
	self:UpdateFocusDisplay();
end

function FocusResource:OnDisable()
	if self.frame then
		self.frame:Hide();
	end
	
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED");
	self:UnregisterEvent("UNIT_HEALTH");
	self:UnregisterEvent("UNIT_MAXHEALTH");
	self:UnregisterEvent("UNIT_POWER_UPDATE");
	self:UnregisterEvent("UNIT_MAXPOWER");
	self:UnregisterEvent("UNIT_DISPLAYPOWER");
	self:UnregisterEvent("UNIT_HEAL_PREDICTION");
	self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED");
end

function FocusResource:PLAYER_FOCUS_CHANGED()
	local db = GetDB();
	if db and UnitFrameBase then
		UnitFrameBase:SetupBlizzardFrameHiding("FocusFrame", db, GetDB, "hideFocusFrame", function() return UnitExists("focus"); end);
	end
	self:UpdateFocusDisplay();
end

function FocusResource:UNIT_HEALTH(event, unit)
	if unit == "focus" then
		self:UpdateFocusHealth();
	end
end

function FocusResource:UNIT_MAXHEALTH(event, unit)
	if unit == "focus" then
		self:UpdateFocusHealth();
	end
end

function FocusResource:UNIT_POWER_UPDATE(event, unit, powerType)
	if unit == "focus" then
		self:UpdateFocusPower();
	end
end

function FocusResource:UNIT_MAXPOWER(event, unit, powerType)
	if unit == "focus" then
		self:UpdateFocusPower();
	end
end

function FocusResource:UNIT_DISPLAYPOWER(event, unit)
	if unit == "focus" then
		self:UpdateFocusPower();
	end
end

function FocusResource:UNIT_HEAL_PREDICTION(event, unit)
	if unit == "focus" then
		self:UpdateFocusHealth();
	end
end

function FocusResource:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
	if unit == "focus" then
		self:UpdateFocusHealth();
	end
end

function FocusResource:UpdateFocusDisplay()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.FocusResourceStyle;
	
	-- Use UnitFrameBase to update display
	UnitFrameBase:UpdateUnitDisplay(frame, "focus", db, Style, function() return UnitExists("focus"); end);
end

function FocusResource:UpdateFocusHealth()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.FocusResourceStyle;
	
	-- Use UnitFrameBase to update health
	UnitFrameBase:UpdateUnitHealth(frame, "focus", db, Style);
end

function FocusResource:UpdateFocusPower()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.FocusResourceStyle;
	
	-- Use UnitFrameBase to update power
	UnitFrameBase:UpdateUnitPower(frame, "focus", db, Style);
end

function FocusResource:RefreshFromConfig()
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
	
	-- Handle FocusFrame visibility
	local db = GetDB();
	if db and UnitFrameBase then
		-- Re-setup Blizzard frame hiding in case option changed
		UnitFrameBase:SetupBlizzardFrameHiding("FocusFrame", db, GetDB, "hideFocusFrame", function() return UnitExists("focus"); end);
	end
	
	-- Apply scale if configured
	local FrameLayout = ns.FrameLayout;
	if FrameLayout then
		FrameLayout:ApplyScale(frame, db);
	end
	
	local Style = ns.FocusResourceStyle;
	
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
	end
	
	-- Update display if focus exists
	if UnitExists("focus") then
		self:UpdateFocusDisplay();
	end
end

