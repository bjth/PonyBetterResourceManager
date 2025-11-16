local ADDON_NAME, ns = ...;

local addon = ns.Addon;
if not addon then
	return;
end

local TargetResource = addon:NewModule("TargetResource", "AceEvent-3.0");
ns.TargetResource = TargetResource;

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
	
	-- Create main frame
	local frame = CreateFrame("Frame", "PBRMTargetResourceDisplayFrame", UIParent);
	frame:SetSize(200, 50);
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
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
	healthContainer:SetSize(200, 20);
	healthContainer:SetPoint("TOP", frame, "TOP", 0, 0);
	frame.HealthBarsContainer = healthContainer;
	
	-- Create border for health container (similar to Blizzard's Personal Resource Display)
	-- We'll use a simple texture-based border that can be styled
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
	healthBar:SetSize(200, 20);
	healthBar:SetPoint("CENTER", healthContainer, "CENTER", 0, 0);
	frame.healthbar = healthBar;
	
	-- Create overheal bar as a status bar (can handle secret values)
	-- Will be anchored to the right edge of the health bar in UpdateTargetHealth
	local overhealBar = CreateFrame("StatusBar", nil, healthContainer);
	overhealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	overhealBar:SetStatusBarColor(0.0, 0.659, 0.608);
	overhealBar:SetFrameLevel(healthBar:GetFrameLevel() + 1);
	-- Hide the background by making it transparent
	-- Status bars don't have a direct background property, but we can hide the empty portion
	-- by ensuring the bar only shows when there's a value
	overhealBar:Hide();
	frame.overhealBar = overhealBar;
	
	-- Create absorb bar as a status bar (can handle secret values)
	-- Will be anchored to the right edge of the health bar and fill leftward
	local absorbBar = CreateFrame("StatusBar", nil, healthContainer);
	absorbBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill");
	absorbBar:SetStatusBarColor(0.0, 0.8, 1.0);
	absorbBar:SetFrameLevel(healthBar:GetFrameLevel() + 2);
	-- Set reverse fill so it grows from right to left
	if absorbBar.SetReverseFill then
		absorbBar:SetReverseFill(true);
	end
	-- Hide the status bar's built-in background (the unfilled portion) so it doesn't cover the health bar
	-- Status bars have a Background property that shows the unfilled portion
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
	powerBar:SetSize(200, 12);
	powerBar:SetPoint("TOP", healthBar, "BOTTOM", 0, -2);
	frame.PowerBar = powerBar;
	
	-- Setup Edit Mode integration using our shared helper
	-- Scale is now handled entirely by Blizzard's Edit Mode UI
	local EditModeHelper = ns.EditModeHelper;
	local db = GetDB();
	if EditModeHelper then
		EditModeHelper:SetupEditModeIntegration({
			frame = frame,
			systemName = "Pony Target Frame",
			db = db,
			defaultHideSelection = false,
			-- Callback when entering Edit Mode
			onEditModeEnter = function(self)
				-- Explicitly show the frame
				self:Show();
			end,
			-- Callback when exiting Edit Mode
			onEditModeExit = function(self)
				-- Ensure frame is shown if we have a target
				if UnitExists("target") then
					self:Show();
				end
			end
		});
	end
	
	-- Initially hidden until target exists or Edit Mode is active
	local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive();
	if not inEditMode and not UnitExists("target") then
		frame:Hide();
	end
	
	self.frame = frame;
	
	-- Make frame clickable to target and hoverable for spell casting
	self:SetupFrameInteraction(frame);
	
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

function TargetResource:SetupFrameInteraction(frame)
	if not frame then
		return;
	end
	
	-- Check if we've already set this up
	if frame._PBRSecureButton then
		return;
	end
	
	-- Use secure unit button template for clicking and spell casting
	-- This allows clicking to target and hovering to cast spells on target
	-- Use "togglemenu" instead of "menu" - togglemenu is a secure action that automatically
	-- determines the correct menu type based on the unit, and calls UnitPopup_OpenMenu
	-- from secure code, allowing menu items to call protected functions
	local secureButton = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate");
	secureButton:SetAllPoints(frame);
	secureButton:SetAttribute("unit", "target");
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
	if db then
		local function setupTargetFrameHook()
			local targetFrame = _G.TargetFrame;
			if targetFrame then
				-- Hook Show method to prevent TargetFrame from showing when option is enabled
				if not targetFrame._PBRMShowHookSet then
					targetFrame._PBRMShowHookSet = true;
					hooksecurefunc(targetFrame, "Show", function(self)
						local db = GetDB();
						if db and db.hideTargetFrame then
							-- Immediately hide if option is enabled
							self:Hide();
						end
					end);
				end
				
				if db.hideTargetFrame then
					targetFrame:Hide();
				else
					-- Only show TargetFrame if there's actually a target
					-- Blizzard will handle the rest of the visibility logic
					if UnitExists("target") then
						targetFrame:Show();
					else
						targetFrame:Hide();
					end
				end
			end
		end
		
		-- Try immediately
		setupTargetFrameHook();
		
		-- Also try after a delay in case TargetFrame isn't created yet
		C_Timer.After(0.5, setupTargetFrameHook);
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
	
	-- Determine visibility based on Edit Mode and target existence
	local inEditMode = false;
	if EditModeManagerFrame then
		inEditMode = EditModeManagerFrame:IsEditModeActive();
	end
	local hasTarget = UnitExists("target");
	
	-- Show frame if:
	-- 1. We're in Edit Mode (even without target), OR
	-- 2. We have a target (outside Edit Mode)
	if inEditMode or hasTarget then
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
		-- Hide only if we're not in Edit Mode and have no target
		frame:Hide();
		return;
	end
	
	-- Update health and power (only if target exists)
	-- Only show placeholder values if we're in Edit Mode AND have no target
	if UnitExists("target") then
		self:UpdateTargetHealth();
		self:UpdateTargetPower();
	elseif inEditMode then
		-- In Edit Mode with no target, show placeholder values
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
	local Style = ns.TargetResourceStyle;
	local db = GetDB();
	if Style and Style.ApplyAll and db then
		Style:ApplyAll(frame, db);
		-- Re-apply health bar color after styling to ensure it's correct
		-- This is important because ApplyAbsorbBarStyle might have been called
		local BarStyling = ns.BarStyling;
		if BarStyling and frame.healthbar then
			BarStyling:ApplyBarVisuals(frame.healthbar, db.healthTexture, db.healthColor, db.overrideHealthColor);
			-- If not overriding, restore Blizzard's default health color
			if not db.overrideHealthColor then
				frame.healthbar:SetStatusBarColor(0.0, 0.8, 0.0);
			end
		end
	end
end

function TargetResource:UpdateTargetHealth()
	local frame = self.frame;
	if not frame or not frame.healthbar then
		return;
	end
	
	if not UnitExists("target") then
		return;
	end
	
	-- Update health bar value (using secret values - can't do math)
	local health = UnitHealth("target");
	local maxHealth = UnitHealthMax("target");
	
	-- Set min/max and value (these work with secret values)
	frame.healthbar:SetMinMaxValues(0, maxHealth);
	frame.healthbar:SetValue(health);
	
	-- Update overheal and absorb bars using status bars
	-- Status bars can handle secret values in SetValue and SetMinMaxValues
	-- They will automatically calculate the fill width based on value/max
	local db = GetDB();
	local _, totalMax = frame.healthbar:GetMinMaxValues();
	local healthBar = frame.healthbar;
	local container = frame.HealthBarsContainer;
	local barWidth = container and container:GetWidth() or 200;
	local barHeight = container and container:GetHeight() or 20;
	
	-- Update overheal bar
	-- Overheal extends to the right of the health bar, showing incoming heals beyond max health
	-- Use same min/max as health bar, set value to incomingHeal
	-- The bar will automatically size based on incomingHeal/totalMax
	if frame.overhealBar and db and db.showOverheal ~= false then
		local incomingHeal = UnitGetIncomingHeals("target");
		if incomingHeal ~= nil and totalMax ~= nil and healthBar then
			-- Use same scale as health bar so the bar sizes correctly
			frame.overhealBar:SetMinMaxValues(0, totalMax);
			frame.overhealBar:SetValue(incomingHeal);
			-- Position to the right of the health bar frame
			frame.overhealBar:ClearAllPoints();
			frame.overhealBar:SetPoint("TOPLEFT", healthBar, "TOPRIGHT", 0, 0);
			frame.overhealBar:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMRIGHT", 0, 0);
			-- Set width to match container so the bar fills proportionally
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
	-- Absorb overlays the health bar, anchored to the right edge and growing leftward
	-- Use same min/max as health bar, set value to totalAbsorb
	-- The bar will automatically size based on totalAbsorb/totalMax
	if frame.absorbBar and db and db.showAbsorb ~= false then
		local totalAbsorb = UnitGetTotalAbsorbs("target");
		if totalAbsorb ~= nil and totalMax ~= nil and healthBar then
			-- Use same scale as health bar so the bar sizes correctly
			frame.absorbBar:SetMinMaxValues(0, totalMax);
			frame.absorbBar:SetValue(totalAbsorb);
			-- Anchor the right edge of absorb bar to the right edge of health bar
			-- With reverse fill, it will grow leftward from the right edge
			frame.absorbBar:ClearAllPoints();
			frame.absorbBar:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0);
			frame.absorbBar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0);
			-- Set width to match health bar so it can overlay properly
			frame.absorbBar:SetWidth(barWidth);
			frame.absorbBar:SetHeight(barHeight);
			-- Ensure the background is hidden (in case it was shown again)
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
	
	-- Re-apply health bar color after updating absorb bar to ensure it's not covered
	-- This ensures the health bar color is correct even when absorb bar overlays it
	local BarStyling = ns.BarStyling;
	if BarStyling and db then
		-- Only re-apply the color, not the full style (to avoid recursion)
		BarStyling:ApplyBarVisuals(healthBar, db.healthTexture, db.healthColor, db.overrideHealthColor);
		-- If not overriding, restore Blizzard's default health color
		if not db.overrideHealthColor then
			healthBar:SetStatusBarColor(0.0, 0.8, 0.0);
		end
	end
	
	-- Update text if enabled
	if Style and Style.UpdateHealthText and db then
		Style:UpdateHealthText(frame, db);
	end
end

function TargetResource:UpdateTargetPower()
	local frame = self.frame;
	if not frame or not frame.PowerBar then
		return;
	end
	
	if not UnitExists("target") then
		return;
	end
	
	-- Get power type
	local powerType = UnitPowerType("target");
	local power = UnitPower("target", powerType);
	local maxPower = UnitPowerMax("target", powerType);
	
	-- Set min/max and value
	frame.PowerBar:SetMinMaxValues(0, maxPower);
	frame.PowerBar:SetValue(power);
	
	-- Update power color using shared utility (respects user's color settings)
	local PowerColor = ns.PowerColor;
	local db = GetDB();
	if PowerColor and db then
		PowerColor:ApplyPowerColor(frame.PowerBar, "target", db, false);
	else
		-- Fallback to default colors
		local r, g, b = PowerBarColor[powerType].r, PowerBarColor[powerType].g, PowerBarColor[powerType].b;
		frame.PowerBar:SetStatusBarColor(r, g, b);
	end
	
	-- Update text if enabled
	local Style = ns.TargetResourceStyle;
	if Style and Style.UpdatePowerText and db then
		Style:UpdatePowerText(frame, db);
	end
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
	if db then
		local targetFrame = _G.TargetFrame;
		if targetFrame then
			-- Ensure hook is set up (in case option was changed after initialization)
			if not targetFrame._PBRMShowHookSet then
				targetFrame._PBRMShowHookSet = true;
				hooksecurefunc(targetFrame, "Show", function(self)
					local db = GetDB();
					if db and db.hideTargetFrame then
						-- Immediately hide if option is enabled
						self:Hide();
					end
				end);
			end
			
			if db.hideTargetFrame then
				targetFrame:Hide();
			else
				-- Only show TargetFrame if there's actually a target
				-- Blizzard will handle the rest of the visibility logic
				if UnitExists("target") then
					targetFrame:Show();
				else
					targetFrame:Hide();
				end
			end
		end
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

