local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

local Style = {};
ns.TargetOfTargetResourceStyle = Style;

-- Get shared utilities
local PowerColor = ns.PowerColor;
local BarStyling = ns.BarStyling;
local UnitFrameStyle = ns.UnitFrameStyle;

-- Helper function to get status bar texture
local function GetStatusBarTexture(key)
	if not LSM then
		return nil;
	end
	
	if not key or key == "" then
		key = "Blizzard";
	end
	
	return LSM:Fetch("statusbar", key);
end

function Style:ApplyHealthBarStyle(frame, db)
	if not frame or not db then
		return;
	end

	if not frame.HealthBarsContainer or not frame.healthbar then
		return;
	end

	-- Use shared bar styling module
	if BarStyling then
		BarStyling:ApplyHealthBarStyle(frame, frame.healthbar, frame.HealthBarsContainer, db, "targettarget");
		
		local healthBar = frame.healthbar;
		if healthBar then
			if db.healthWidth and db.healthWidth > 0 then
				healthBar:SetWidth(db.healthWidth);
			end
			if db.healthHeight and db.healthHeight > 0 then
				healthBar:SetHeight(db.healthHeight);
			end
		end
	end

	-- Apply overheal bar styling
	if frame.overhealBar then
		self:ApplyOverhealBarStyle(frame, db);
	end
	
	-- Apply absorb bar styling
	if frame.absorbBar then
		self:ApplyAbsorbBarStyle(frame, db);
	end

	-- Ensure the health text is updated
	self:UpdateHealthText(frame, db);
end

function Style:UpdateHealthText(frame, db)
	local bar = frame.healthbar;
	if not bar then
		return;
	end
	
	if not UnitExists("targettarget") then
		return;
	end
	
	if UnitFrameStyle then
		UnitFrameStyle:UpdateTextForBar(
			frame, 
			db, 
			bar, 
			"HEALTH",
			"targettarget",
			"TARGETOFTARGET",
			function(template, current, max) return UnitFrameStyle:FormatHealth("targettarget", template, current, max); end,
			function() return UnitHealth("targettarget"); end,
			function() return UnitHealthMax("targettarget"); end
		);
	end
end

function Style:UpdatePowerText(frame, db)
	local bar = frame.PowerBar;
	if not bar then
		return;
	end
	
	if not UnitExists("targettarget") then
		return;
	end
	
	local powerType = UnitPowerType("targettarget");
	if UnitFrameStyle then
		UnitFrameStyle:UpdateTextForBar(
			frame, 
			db, 
			bar, 
			"POWER",
			"targettarget",
			"TARGETOFTARGET",
			function(template, current, max) return UnitFrameStyle:FormatPower("targettarget", template, current, max); end,
			function() return UnitPower("targettarget", powerType); end,
			function() return UnitPowerMax("targettarget", powerType); end
		);
	end
end

function Style:ApplyPowerBarStyle(frame, db)
	if not frame or not db then
		return;
	end

	if not frame.PowerBar then
		return;
	end

	if BarStyling then
		BarStyling:ApplyPowerBarStyle(frame, frame.PowerBar, db, "targettarget");
	end

	self:UpdatePowerText(frame, db);
end

function Style:ApplyOverhealBarStyle(frame, db)
	if not frame or not db or not frame.overhealBar then
		return;
	end
	
	local overhealBar = frame.overhealBar;
	
	local textureKey = db.overhealTexture;
	if textureKey and textureKey ~= "" then
		local texture = GetStatusBarTexture(textureKey);
		if texture then
			overhealBar:SetStatusBarTexture(texture);
		end
	else
		if frame.healthbar then
			local defaultTexture = frame.healthbar:GetStatusBarTexture();
			if defaultTexture then
				overhealBar:SetStatusBarTexture(defaultTexture);
			else
				overhealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
			end
		end
	end
	
	local color = db.overhealColor;
	if color then
		local r = color.r or 0.0;
		local g = color.g or 0.659;
		local b = color.b or 0.608;
		local a = color.a or 1.0;
		overhealBar:SetStatusBarColor(r, g, b, a);
	end
end

function Style:ApplyAbsorbBarStyle(frame, db)
	if not frame or not db or not frame.absorbBar then
		return;
	end
	
	local absorbBar = frame.absorbBar;
	
	local textureKey = db.absorbTexture;
	if textureKey and textureKey ~= "" then
		local texture = GetStatusBarTexture(textureKey);
		if texture then
			absorbBar:SetStatusBarTexture(texture);
		end
	else
		absorbBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill");
	end
	
	if absorbBar.Background then
		absorbBar.Background:Hide();
	end
	
	local color = db.absorbColor;
	if color then
		local r = color.r or 0.0;
		local g = color.g or 0.8;
		local b = color.b or 1.0;
		local a = color.a or 1.0;
		absorbBar:SetStatusBarColor(r, g, b, a);
	end
end

function Style:ApplyAll(frame, db)
	self:ApplyHealthBarStyle(frame, db);
	self:ApplyPowerBarStyle(frame, db);
	
	frame._PBRMTextsUsed = {};
	
	self:UpdateHealthText(frame, db);
	self:UpdatePowerText(frame, db);
	
	if frame._PBRMTexts then
		for fsKey, fs in pairs(frame._PBRMTexts) do
			if not frame._PBRMTextsUsed[fsKey] then
				fs:SetText("");
				fs:Hide();
			end
		end
	end
end

