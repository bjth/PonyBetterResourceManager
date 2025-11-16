local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

local Style = {};
ns.TargetResourceStyle = Style;

local BreakUpLargeNumbers = BreakUpLargeNumbers;
local AbbreviateLargeNumbers = AbbreviateLargeNumbers or BreakUpLargeNumbers;

-- Get the DataTokens system
local DataTokens = ns.DataTokens;

-- Get shared utilities
local PowerColor = ns.PowerColor;
local BarStyling = ns.BarStyling;

-- Helper function to get status bar texture (similar to BarStyling)
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
		BarStyling:ApplyHealthBarStyle(frame, frame.healthbar, frame.HealthBarsContainer, db, "target");
		
		-- TargetResource also needs to set healthbar size directly to match container
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

	-- Ensure the health text is updated whenever we (re)style the bar.
	self:UpdateHealthText(frame, db);
end

local function AbbreviatePlainNumber(n)
	-- Use Blizzard's built-in function - it handles secret values properly!
	if AbbreviateLargeNumbers then
		return AbbreviateLargeNumbers(n);
	end
	return tostring(n);
end

local function ResolveFontPath(key)
	-- First try LibSharedMedia if available
	if LSM then
		local font = LSM:Fetch("font", key);
		if font then
			return font;
		end
	end
	
	-- Fallback to hardcoded Blizzard fonts
	if key == "ARIALN" then
		return "Fonts\\ARIALN.TTF";
	elseif key == "MORPHEUS" then
		return "Fonts\\MORPHEUS.TTF";
	else
		return "Fonts\\FRIZQT__.TTF";
	end
end

local function FormatHealthCustom(template, hp, maxHp)
	if not template or template == "" then
		return "";
	end

	-- Health values are SECRET VALUES - use Blizzard functions only
	local pct = nil;
	if UnitHealthPercent then
		pct = UnitHealthPercent("target", true, true);
	end
	
	local hpFull = nil;
	local hpShort = nil;
	local maxFull = nil;
	local maxShort = nil;
	
	local ok1, hpFullStr = pcall(function() return tostring(hp or ""); end);
	local ok2, maxFullStr = pcall(function() return tostring(maxHp or ""); end);
	if ok1 and hpFullStr then
		hpFull = hpFullStr;
	else
		hpFull = "";
	end
	if ok2 and maxFullStr then
		maxFull = maxFullStr;
	else
		maxFull = "";
	end
	
	if AbbreviateLargeNumbers then
		hpShort = AbbreviateLargeNumbers(hp);
		maxShort = AbbreviateLargeNumbers(maxHp);
	end
	
	if not hpShort then hpShort = hpFull; end
	if not maxShort then maxShort = maxFull; end
	
	local pctFormatted = nil;
	if pct then
		local ok, formatted = pcall(function()
			return string.format("%.0f", pct);
		end);
		if ok and formatted then
			pctFormatted = formatted;
		else
			pctFormatted = AbbreviatePlainNumber(pct);
		end
	end

	if DataTokens and DataTokens.ProcessTemplate then
		local context = {
			hp = hp,
			maxHp = maxHp,
			hpFull = hpFull,
			hpShort = hpShort,
			maxFull = maxFull,
			maxShort = maxShort,
			pct = pct,
			pctFormatted = pctFormatted,
			unit = "target", -- Default unit for Target Resource
		};
		return DataTokens:ProcessTemplate(template, context);
	else
		return "";
	end
end

local function FormatPowerCustom(template, power, maxPower)
	if not template or template == "" then
		return "";
	end

	local pct = nil;
	if UnitPowerPercent then
		local powerType = UnitPowerType("target");
		pct = UnitPowerPercent("target", powerType, true, true);
	end
	
	local powerFull = nil;
	local powerShort = nil;
	local maxFull = nil;
	local maxShort = nil;
	
	local ok1, powerFullStr = pcall(function() return tostring(power or ""); end);
	local ok2, maxFullStr = pcall(function() return tostring(maxPower or ""); end);
	if ok1 and powerFullStr then
		powerFull = powerFullStr;
	else
		powerFull = "";
	end
	if ok2 and maxFullStr then
		maxFull = maxFullStr;
	else
		maxFull = "";
	end
	
	if AbbreviateLargeNumbers then
		powerShort = AbbreviateLargeNumbers(power);
		maxShort = AbbreviateLargeNumbers(maxPower);
	end
	
	if not powerShort then powerShort = powerFull; end
	if not maxShort then maxShort = maxFull; end
	
	local pctFormatted = nil;
	if pct then
		local ok, formatted = pcall(function()
			return string.format("%.0f", pct);
		end);
		if ok and formatted then
			pctFormatted = formatted;
		else
			pctFormatted = AbbreviatePlainNumber(pct);
		end
	end

	if DataTokens and DataTokens.ProcessTemplate then
		local context = {
			power = power,
			maxPower = maxPower,
			powerFull = powerFull,
			powerShort = powerShort,
			maxFull = maxFull,
			maxShort = maxShort,
			pct = pct,
			pctFormatted = pctFormatted,
			unit = "target", -- Default unit for Target Resource
		};
		return DataTokens:ProcessTemplate(template, context);
	else
		return "";
	end
end

local function UpdateTextForBar(frame, db, bar, targetType, formatFunc, getCurrentValue, getMaxValue)
	if not frame or not db or not bar then
		return;
	end

	if db.healthTextEnabled == false then
		if frame._PBRMTexts then
			for _, fs in pairs(frame._PBRMTexts) do
				fs:SetText("");
				fs:Hide();
			end
		end
		return;
	end

	frame._PBRMTexts = frame._PBRMTexts or {};
	frame._PBRMTextsUsed = frame._PBRMTextsUsed or {};
	-- Get texts from personalResource (unified storage)
	local personalDb = addon.db and addon.db.profile and addon.db.profile.personalResource;
	local texts = personalDb and personalDb.texts;
	
	if not UnitExists("target") then
		return;
	end
	
	if type(texts) ~= "table" or #texts == 0 then
		return;
	else
		for index, entry in ipairs(texts) do
			-- Filter by resourceType: only show TARGET texts
			local entryResourceType = entry.resourceType;
			if entryResourceType == "TARGET" then
				local entryTarget = entry.target;
				if targetType == "HEALTH" and entryTarget == nil then
					entryTarget = "HEALTH";
				end
				if entry and entry.enabled ~= false and entryTarget == targetType then
				local fsKey = index .. "_" .. targetType;
				local fs = frame._PBRMTexts[fsKey];
				if not fs then
					fs = bar:CreateFontString(nil, "OVERLAY");
					frame._PBRMTexts[fsKey] = fs;
				end

				fs:ClearAllPoints();
				local point = entry.anchor or "CENTER";
				local x = entry.x or 0;
				local y = entry.y or 0;
				fs:SetPoint(point, bar, point, x, y);

				-- Use personalResource defaults if targetResource doesn't have them
				local defaultFont = db.textDefaultFont or (personalDb and personalDb.textDefaultFont) or "FRIZQT";
				local defaultSize = db.textDefaultSize or (personalDb and personalDb.textDefaultSize) or 18;
				local fontKey = entry.font or defaultFont;
				local fontPath = ResolveFontPath(fontKey);
				local size = entry.size or defaultSize;
				local outlineStyle = entry.outline or "OUTLINE";
				if outlineStyle == "NONE" then
					outlineStyle = "";
				end
				
				local current = getCurrentValue();
				local max = getMaxValue();
				local formatString = entry.format or "";
				local text = formatFunc(formatString, current, max);
				local textStr = tostring(text or "");
				
				fs:SetFont(fontPath, size, outlineStyle);

				local defaultColor = db.textDefaultColor or (personalDb and personalDb.textDefaultColor) or { r = 1, g = 1, b = 1, a = 1 };
				local color = entry.color or defaultColor;
				local r = (type(color.r) == "number" and color.r >= 0 and color.r <= 1) and color.r or 1;
				local g = (type(color.g) == "number" and color.g >= 0 and color.g <= 1) and color.g or 1;
				local b = (type(color.b) == "number" and color.b >= 0 and color.b <= 1) and color.b or 1;
				local a = (type(color.a) == "number" and color.a >= 0 and color.a <= 1) and color.a or 1;
				fs:SetTextColor(r, g, b, a);

				local shadowEnabled = entry.shadowEnabled;
				if shadowEnabled == nil then
					shadowEnabled = true;
				end
				if shadowEnabled then
					local shadowOffsetX = entry.shadowOffsetX or 1;
					local shadowOffsetY = entry.shadowOffsetY or -1;
					local shadowColor = entry.shadowColor or { r = 0, g = 0, b = 0, a = 1 };
					local sr = (type(shadowColor.r) == "number" and shadowColor.r >= 0 and shadowColor.r <= 1) and shadowColor.r or 0;
					local sg = (type(shadowColor.g) == "number" and shadowColor.g >= 0 and shadowColor.g <= 1) and shadowColor.g or 0;
					local sb = (type(shadowColor.b) == "number" and shadowColor.b >= 0 and shadowColor.b <= 1) and shadowColor.b or 0;
					local sa = (type(shadowColor.a) == "number" and shadowColor.a >= 0 and shadowColor.a <= 1) and shadowColor.a or 1;
					fs:SetShadowColor(sr, sg, sb, sa);
					fs:SetShadowOffset(shadowOffsetX, shadowOffsetY);
				else
					fs:SetShadowColor(0, 0, 0, 0);
					fs:SetShadowOffset(0, 0);
				end

				fs:SetDrawLayer("OVERLAY", 7);
				fs:SetJustifyH("CENTER");
				fs:SetJustifyV("MIDDLE");
				
				fs:SetText(textStr);
				fs:Hide();
				fs:Show();

				frame._PBRMTextsUsed[fsKey] = true;
				end
			end
		end
	end
end

local function HasDynamicTokens(formatStr)
	if not formatStr then
		return false;
	end
	local lower = string.lower(formatStr);
	return string.find(lower, "{fps}") ~= nil or 
	       string.find(lower, "{latency}") ~= nil or 
	       string.find(lower, "{time}") ~= nil;
end

function Style:UpdateHealthText(frame, db)
	local bar = frame.healthbar;
	if not bar then
		return;
	end
	
	if not UnitExists("target") then
		return;
	end
	
	UpdateTextForBar(
		frame, 
		db, 
		bar, 
		"HEALTH",
		FormatHealthCustom,
		function() return UnitHealth("target"); end,
		function() return UnitHealthMax("target"); end
	);
end

function Style:UpdatePowerText(frame, db)
	local bar = frame.PowerBar;
	if not bar then
		return;
	end
	
	if not UnitExists("target") then
		return;
	end
	
	local powerType = UnitPowerType("target");
	UpdateTextForBar(
		frame, 
		db, 
		bar, 
		"POWER",
		FormatPowerCustom,
		function() return UnitPower("target", powerType); end,
		function() return UnitPowerMax("target", powerType); end
	);
end

function Style:ApplyPowerBarStyle(frame, db)
	if not frame or not db then
		return;
	end

	if not frame.PowerBar then
		return;
	end

	-- Use shared bar styling module
	if BarStyling then
		BarStyling:ApplyPowerBarStyle(frame, frame.PowerBar, db, "target");
	end

	self:UpdatePowerText(frame, db);
end

function Style:ApplyOverhealBarStyle(frame, db)
	if not frame or not db or not frame.overhealBar then
		return;
	end
	
	local overhealBar = frame.overhealBar;
	
	-- Apply texture (overhealBar is a status bar, so use SetStatusBarTexture)
	local textureKey = db.overhealTexture;
	if textureKey and textureKey ~= "" then
		local texture = GetStatusBarTexture(textureKey);
		if texture then
			overhealBar:SetStatusBarTexture(texture);
		end
	else
		-- Use default texture (same as health bar)
		if frame.healthbar then
			local defaultTexture = frame.healthbar:GetStatusBarTexture();
			if defaultTexture then
				overhealBar:SetStatusBarTexture(defaultTexture);
			else
				overhealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
			end
		end
	end
	
	-- Apply color (use SetStatusBarColor for status bars)
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
	
	-- Apply texture (absorbBar is a status bar, so use SetStatusBarTexture)
	local textureKey = db.absorbTexture;
	if textureKey and textureKey ~= "" then
		local texture = GetStatusBarTexture(textureKey);
		if texture then
			absorbBar:SetStatusBarTexture(texture);
		end
	else
		-- Use default texture (Blizzard's shield texture)
		absorbBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill");
	end
	
	-- Hide the status bar's built-in background (the unfilled portion) so it doesn't cover the health bar
	-- Status bars have a Background property that shows the unfilled portion
	if absorbBar.Background then
		absorbBar.Background:Hide();
	end
	
	-- Apply color (use SetStatusBarColor for status bars)
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

