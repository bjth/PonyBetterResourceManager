local ADDON_NAME, ns = ...;

local addon = ns.Addon;
if not addon then
	return;
end

local PetResource = addon:NewModule("PetResource", "AceEvent-3.0");
ns.PetResource = PetResource;

local UnitFrameBase = ns.UnitFrameBase;

local function GetDB()
	return (addon.db and addon.db.profile and addon.db.profile.petResource) or nil;
end

local function IsModuleEnabled()
	local profile = addon.db and addon.db.profile;
	if not profile then
		return false;
	end
	return profile.petResource and profile.petResource.enabled == true;
end

-- Create the pet resource display frame
function PetResource:CreateFrame()
	if self.frame then
		return self.frame;
	end
	
	-- Use UnitFrameBase to create the frame
	local frame = UnitFrameBase:CreateUnitFrame({
		frameName = "PBRMPetResourceDisplayFrame",
		defaultSize = { width = 200, height = 20 },
		defaultPoint = { "CENTER", UIParent, "CENTER", 0, 0 }
	});
	
	local db = GetDB();
	
	-- Setup Edit Mode integration
	UnitFrameBase:SetupEditModeIntegration(frame, {
		systemName = "Pony Pet Frame",
		db = db,
		defaultHideSelection = false,
		hasUnitFunc = function() return UnitExists("pet"); end,
		onEditModeEnter = function(self)
			self:Show();
		end,
		onEditModeExit = function(self)
			if UnitExists("pet") then
				self:Show();
			end
		end
	});
	
	self.frame = frame;
	
	-- Make frame clickable to target and hoverable for spell casting
	UnitFrameBase:SetupFrameInteraction(frame, "pet");
	
	-- Initial styling and update
	local Style = ns.PetResourceStyle;
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
	end
	
	-- Update display if we have a pet or are in Edit Mode
	if UnitExists("pet") or (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()) then
		self:UpdatePetDisplay();
	end
	
	return frame;
end

function PetResource:OnInitialize()
	-- No-op for now
end

function PetResource:OnEnable()
	if not IsModuleEnabled() then
		return;
	end
	
	self:CreateFrame();
	
	-- Register for pet unit events
	self:RegisterEvent("PLAYER_PET_CHANGED", "PLAYER_PET_CHANGED");
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
					self:UpdatePetDisplay();
				end);
			end
		end);
		
		EventRegistry:RegisterCallback("EditMode.Exit", function()
			if self.frame then
				if self.frame.OnEditModeExit then
					self.frame:OnEditModeExit();
				end
				self:UpdatePetDisplay();
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
	
	-- Handle PetFrame visibility on initialization
	local db = GetDB();
	if db and UnitFrameBase then
		UnitFrameBase:SetupBlizzardFrameHiding("PetFrame", db, GetDB, "hidePetFrame", function() return UnitExists("pet"); end);
	end
	
	-- Update display (will show/hide based on pet and Edit Mode state)
	self:UpdatePetDisplay();
end

function PetResource:OnDisable()
	if self.frame then
		self.frame:Hide();
	end
	
	self:UnregisterEvent("PLAYER_PET_CHANGED");
	self:UnregisterEvent("UNIT_HEALTH");
	self:UnregisterEvent("UNIT_MAXHEALTH");
	self:UnregisterEvent("UNIT_POWER_UPDATE");
	self:UnregisterEvent("UNIT_MAXPOWER");
	self:UnregisterEvent("UNIT_DISPLAYPOWER");
	self:UnregisterEvent("UNIT_HEAL_PREDICTION");
	self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED");
end

function PetResource:PLAYER_PET_CHANGED()
	local db = GetDB();
	if db and UnitFrameBase then
		UnitFrameBase:SetupBlizzardFrameHiding("PetFrame", db, GetDB, "hidePetFrame", function() return UnitExists("pet"); end);
	end
	self:UpdatePetDisplay();
end

function PetResource:UNIT_HEALTH(event, unit)
	if unit == "pet" then
		self:UpdatePetHealth();
	end
end

function PetResource:UNIT_MAXHEALTH(event, unit)
	if unit == "pet" then
		self:UpdatePetHealth();
	end
end

function PetResource:UNIT_POWER_UPDATE(event, unit, powerType)
	if unit == "pet" then
		self:UpdatePetPower();
	end
end

function PetResource:UNIT_MAXPOWER(event, unit, powerType)
	if unit == "pet" then
		self:UpdatePetPower();
	end
end

function PetResource:UNIT_DISPLAYPOWER(event, unit)
	if unit == "pet" then
		self:UpdatePetPower();
	end
end

function PetResource:UNIT_HEAL_PREDICTION(event, unit)
	if unit == "pet" then
		self:UpdatePetHealth();
	end
end

function PetResource:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
	if unit == "pet" then
		self:UpdatePetHealth();
	end
end

function PetResource:UpdatePetDisplay()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.PetResourceStyle;
	
	-- Use UnitFrameBase to update display
	UnitFrameBase:UpdateUnitDisplay(frame, "pet", db, Style, function() return UnitExists("pet"); end);
end

function PetResource:UpdatePetHealth()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.PetResourceStyle;
	
	-- Use UnitFrameBase to update health
	UnitFrameBase:UpdateUnitHealth(frame, "pet", db, Style);
end

function PetResource:UpdatePetPower()
	local frame = self.frame;
	if not frame then
		return;
	end
	
	local db = GetDB();
	local Style = ns.PetResourceStyle;
	
	-- Use UnitFrameBase to update power
	UnitFrameBase:UpdateUnitPower(frame, "pet", db, Style);
end

function PetResource:RefreshFromConfig()
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
	
	-- Handle PetFrame visibility
	local db = GetDB();
	if db and UnitFrameBase then
		-- Re-setup Blizzard frame hiding in case option changed
		UnitFrameBase:SetupBlizzardFrameHiding("PetFrame", db, GetDB, "hidePetFrame", function() return UnitExists("pet"); end);
	end
	
	-- Apply scale if configured
	local FrameLayout = ns.FrameLayout;
	if FrameLayout then
		FrameLayout:ApplyScale(frame, db);
	end
	
	local Style = ns.PetResourceStyle;
	
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
	end
	
	-- Update display if pet exists
	if UnitExists("pet") then
		self:UpdatePetDisplay();
	end
end

