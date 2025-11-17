local ADDON_NAME, ns = ...;

-- UnitFrameBase: Shared utilities for unit frame modules
-- Provides common functionality for creating and managing unit frames

local UnitFrameBase = {};
ns.UnitFrameBase = UnitFrameBase;

-- Get shared utilities
local FrameLayout = ns.FrameLayout;
local EditModeHelper = ns.EditModeHelper;
local BarStyling = ns.BarStyling;
local PowerColor = ns.PowerColor;

-- Create a complete unit frame structure
-- config: {
--   frameName: string (e.g., "PBRMTargetResourceDisplayFrame")
--   defaultSize: { width, height }
--   defaultPoint: { point, relativeTo, relativePoint, x, y }
-- }
function UnitFrameBase:CreateUnitFrame(config)
	if not config or not config.frameName then
		error("UnitFrameBase:CreateUnitFrame requires config.frameName");
	end
	
	-- Create main frame
	local frame = CreateFrame("Frame", config.frameName, UIParent);
	frame:SetSize(config.defaultSize.width or 200, config.defaultSize.height or 50);
	
	local defaultPoint = config.defaultPoint or { "CENTER", UIParent, "CENTER", 0, 0 };
	frame:SetPoint(defaultPoint[1], defaultPoint[2], defaultPoint[3], defaultPoint[4] or 0, defaultPoint[5] or 0);
	
	frame:SetMovable(true);
	frame:SetUserPlaced(true);
	frame:EnableMouse(true);
	frame:RegisterForDrag("LeftButton");
	
	-- Ensure frame is always on top and visible
	frame:SetFrameStrata("MEDIUM");
	frame:SetFrameLevel(100);
	frame:SetAlpha(1.0);
	
	-- Create health bar container
	local healthContainer = CreateFrame("Frame", nil, frame);
	healthContainer:SetSize(config.defaultSize.width or 200, config.defaultSize.height or 20);
	healthContainer:SetPoint("TOP", frame, "TOP", 0, 0);
	frame.HealthBarsContainer = healthContainer;
	
	-- Create border for health container
	local border = healthContainer:CreateTexture(nil, "OVERLAY");
	border:SetAllPoints(healthContainer);
	border:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill");
	border:SetTexCoord(0, 1, 0, 1);
	border:SetVertexColor(0, 0, 0, 0.5);
	healthContainer.border = border;
	
	-- Create health bar
	local healthBar = CreateFrame("StatusBar", nil, healthContainer);
	healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	healthBar:SetMinMaxValues(0, 100);
	healthBar:SetValue(100);
	healthBar:SetStatusBarColor(0.0, 0.8, 0.0);
	healthBar:SetSize(config.defaultSize.width or 200, config.defaultSize.height or 20);
	healthBar:SetPoint("CENTER", healthContainer, "CENTER", 0, 0);
	frame.healthbar = healthBar;
	
	-- Create overheal bar
	local overhealBar = CreateFrame("StatusBar", nil, healthContainer);
	overhealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	overhealBar:SetStatusBarColor(0.0, 0.659, 0.608);
	overhealBar:SetFrameLevel(healthBar:GetFrameLevel() + 1);
	overhealBar:Hide();
	frame.overhealBar = overhealBar;
	
	-- Create absorb bar
	local absorbBar = CreateFrame("StatusBar", nil, healthContainer);
	absorbBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill");
	absorbBar:SetStatusBarColor(0.0, 0.8, 1.0);
	absorbBar:SetFrameLevel(healthBar:GetFrameLevel() + 2);
	if absorbBar.SetReverseFill then
		absorbBar:SetReverseFill(true);
	end
	if absorbBar.Background then
		absorbBar.Background:Hide();
	end
	absorbBar:Hide();
	frame.absorbBar = absorbBar;
	
	-- Create power bar
	local powerBar = CreateFrame("StatusBar", nil, frame);
	powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	powerBar:SetMinMaxValues(0, 100);
	powerBar:SetValue(100);
	powerBar:SetStatusBarColor(0.0, 0.4, 1.0);
	powerBar:SetSize(config.defaultSize.width or 200, 12);
	powerBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -2);
	frame.PowerBar = powerBar;
	
	return frame;
end

-- Setup secure unit button for frame interaction
function UnitFrameBase:SetupFrameInteraction(frame, unit)
	if not frame or not unit then
		return;
	end
	
	-- Check if we've already set this up
	if frame._PBRSecureButton then
		return;
	end
	
	-- Use secure unit button template for clicking and spell casting
	local secureButton = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate");
	secureButton:SetAllPoints(frame);
	secureButton:SetAttribute("unit", unit);
	secureButton:SetAttribute("*type1", "target");      -- Left click targets
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

-- Update health display for a unit
function UnitFrameBase:UpdateUnitHealth(frame, unit, db, Style)
	if not frame or not frame.healthbar or not unit or not db then
		return;
	end
	
	if not UnitExists(unit) then
		return;
	end
	
	-- Update health bar value (using secret values - can't do math)
	local health = UnitHealth(unit);
	local maxHealth = UnitHealthMax(unit);
	
	-- Set min/max and value (these work with secret values)
	frame.healthbar:SetMinMaxValues(0, maxHealth);
	frame.healthbar:SetValue(health);
	
	-- Update overheal and absorb bars using status bars
	local _, totalMax = frame.healthbar:GetMinMaxValues();
	local healthBar = frame.healthbar;
	local container = frame.HealthBarsContainer;
	local barWidth = container and container:GetWidth() or 200;
	local barHeight = container and container:GetHeight() or 20;
	
	-- Update overheal bar
	if frame.overhealBar and db.showOverheal ~= false then
		local incomingHeal = UnitGetIncomingHeals(unit);
		if incomingHeal ~= nil and totalMax ~= nil and healthBar then
			frame.overhealBar:SetMinMaxValues(0, totalMax);
			frame.overhealBar:SetValue(incomingHeal);
			frame.overhealBar:ClearAllPoints();
			frame.overhealBar:SetPoint("TOPLEFT", healthBar, "TOPRIGHT", 0, 0);
			frame.overhealBar:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMRIGHT", 0, 0);
			frame.overhealBar:SetWidth(barWidth);
			frame.overhealBar:SetHeight(barHeight);
			frame.overhealBar:Show();
		else
			frame.overhealBar:Hide();
		end
	elseif frame.overhealBar then
		frame.overhealBar:Hide();
	end
	
	-- Update absorb bar
	if frame.absorbBar and db.showAbsorb ~= false then
		local totalAbsorb = UnitGetTotalAbsorbs(unit);
		if totalAbsorb ~= nil and totalMax ~= nil and healthBar then
			frame.absorbBar:SetMinMaxValues(0, totalMax);
			frame.absorbBar:SetValue(totalAbsorb);
			frame.absorbBar:ClearAllPoints();
			frame.absorbBar:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0);
			frame.absorbBar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0);
			frame.absorbBar:SetWidth(barWidth);
			frame.absorbBar:SetHeight(barHeight);
			if frame.absorbBar.Background then
				frame.absorbBar.Background:Hide();
			end
			frame.absorbBar:Show();
		else
			frame.absorbBar:Hide();
		end
	elseif frame.absorbBar then
		frame.absorbBar:Hide();
	end
	
	-- Re-apply health bar color after updating absorb bar
	-- Use ApplyHealthBarStyle to ensure unit colors are properly applied
	if BarStyling and db and frame.HealthBarsContainer then
		BarStyling:ApplyHealthBarStyle(frame, healthBar, frame.HealthBarsContainer, db, unit);
	end
	
	-- Update text if enabled
	if Style and Style.UpdateHealthText and db then
		Style:UpdateHealthText(frame, db);
	end
end

-- Update power display for a unit
function UnitFrameBase:UpdateUnitPower(frame, unit, db, Style)
	if not frame or not frame.PowerBar or not unit or not db then
		return;
	end
	
	if not UnitExists(unit) then
		return;
	end
	
	-- Get power type
	local powerType = UnitPowerType(unit);
	local power = UnitPower(unit, powerType);
	local maxPower = UnitPowerMax(unit, powerType);
	
	-- Set min/max and value
	frame.PowerBar:SetMinMaxValues(0, maxPower);
	frame.PowerBar:SetValue(power);
	
	-- Update power color using shared utility
	if PowerColor and db then
		PowerColor:ApplyPowerColor(frame.PowerBar, unit, db, false);
	else
		-- Fallback to default colors
		local r, g, b = PowerBarColor[powerType].r, PowerBarColor[powerType].g, PowerBarColor[powerType].b;
		frame.PowerBar:SetStatusBarColor(r, g, b);
	end
	
	-- Update text if enabled
	if Style and Style.UpdatePowerText and db then
		Style:UpdatePowerText(frame, db);
	end
end

-- Main display update - handles visibility and calls health/power updates
function UnitFrameBase:UpdateUnitDisplay(frame, unit, db, Style, hasUnitFunc)
	if not frame or not unit or not db then
		return;
	end
	
	-- Determine visibility based on Edit Mode and unit existence
	local inEditMode = false;
	if EditModeManagerFrame then
		inEditMode = EditModeManagerFrame:IsEditModeActive();
	end
	
	local hasUnit = hasUnitFunc and hasUnitFunc() or UnitExists(unit);
	
	-- Show frame if:
	-- 1. We're in Edit Mode (even without unit), OR
	-- 2. We have a unit (outside Edit Mode)
	if inEditMode or hasUnit then
		-- Force all visibility properties to ensure frame is actually visible
		frame:SetAlpha(1.0);
		frame:SetFrameStrata("MEDIUM");
		frame:SetFrameLevel(100);
		frame:Show();
		
		-- Verify it's actually shown and visible
		C_Timer.After(0.05, function()
			local actuallyShown = frame:IsShown();
			local parent = frame:GetParent();
			local parentShown = parent and parent:IsShown();
			local alpha = frame:GetAlpha();
			
			if not actuallyShown or not parentShown or alpha < 0.01 then
				frame:SetAlpha(1.0);
				frame:SetFrameStrata("MEDIUM");
				frame:SetFrameLevel(100);
				frame:Show();
			end
		end);
	else
		-- Hide only if we're not in Edit Mode and have no unit
		frame:Hide();
		return;
	end
	
	-- Update health and power (only if unit exists)
	-- Only show placeholder values if we're in Edit Mode AND have no unit
	if hasUnit then
		self:UpdateUnitHealth(frame, unit, db, Style);
		self:UpdateUnitPower(frame, unit, db, Style);
	elseif inEditMode then
		-- In Edit Mode with no unit, show placeholder values
		if frame.healthbar then
			frame.healthbar:SetMinMaxValues(0, 100);
			frame.healthbar:SetValue(100);
		end
		if frame.PowerBar then
			frame.PowerBar:SetMinMaxValues(0, 100);
			frame.PowerBar:SetValue(100);
		end
	end
	
	-- Apply styling
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
		-- Re-apply health bar color after styling to ensure it's correct
		-- Use ApplyHealthBarStyle to ensure unit colors are properly applied
		if BarStyling and frame.healthbar and frame.HealthBarsContainer then
			BarStyling:ApplyHealthBarStyle(frame, frame.healthbar, frame.HealthBarsContainer, db, unit);
		end
	end
end

-- Setup Blizzard frame hiding
function UnitFrameBase:SetupBlizzardFrameHiding(blizzardFrameName, db, getDBFunc, hideOptionName, unitExistsFunc)
	if not blizzardFrameName or not getDBFunc then
		return;
	end
	
	local function setupBlizzardFrameHook()
		local blizzardFrame = _G[blizzardFrameName];
		if blizzardFrame then
			-- Hook Show method to prevent Blizzard frame from showing when option is enabled
			if not blizzardFrame._PBRMShowHookSet then
				blizzardFrame._PBRMShowHookSet = true;
				hooksecurefunc(blizzardFrame, "Show", function(self)
					local db = getDBFunc();
					if db and hideOptionName and db[hideOptionName] then
						-- Immediately hide if option is enabled
						self:Hide();
					end
				end);
			end
			
			local db = getDBFunc();
			if db and hideOptionName and db[hideOptionName] then
				blizzardFrame:Hide();
			else
				-- Only show Blizzard frame if unit exists
				if unitExistsFunc and unitExistsFunc() then
					blizzardFrame:Show();
				else
					blizzardFrame:Hide();
				end
			end
		end
	end
	
	-- Try immediately
	setupBlizzardFrameHook();
	
	-- Also try after a delay in case Blizzard frame isn't created yet
	C_Timer.After(0.5, setupBlizzardFrameHook);
end

-- Setup Edit Mode integration
function UnitFrameBase:SetupEditModeIntegration(frame, config)
	if not frame or not config then
		return;
	end
	
	-- Apply scale if configured (before Edit Mode setup)
	local db = config.db;
	if FrameLayout and db then
		FrameLayout:ApplyScale(frame, db);
	end
	
	-- Setup Edit Mode integration using our shared helper
	if EditModeHelper then
		EditModeHelper:SetupEditModeIntegration({
			frame = frame,
			systemName = config.systemName or "Pony Unit Frame",
			db = db,
			defaultHideSelection = config.defaultHideSelection or false,
			onEditModeEnter = config.onEditModeEnter or function(self)
				self:Show();
			end,
			onEditModeExit = config.onEditModeExit or function(self)
				-- Default: show if unit exists
				if config.hasUnitFunc and config.hasUnitFunc() then
					self:Show();
				end
			end
		});
	end
	
	-- Initially hidden until unit exists or Edit Mode is active
	local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive();
	if not inEditMode then
		local hasUnit = config.hasUnitFunc and config.hasUnitFunc() or false;
		if not hasUnit then
			frame:Hide();
		end
	end
end

return UnitFrameBase;

