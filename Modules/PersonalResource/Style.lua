local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

local Style = {};
ns.PersonalResourceStyle = Style;

local BreakUpLargeNumbers = BreakUpLargeNumbers;
local AbbreviateLargeNumbers = AbbreviateLargeNumbers or BreakUpLargeNumbers;

local function GetStatusBarTexture(key)
	if not LSM then
		return nil;
	end

	if not key or key == "" then
		key = "Blizzard";
	end

	return LSM:Fetch("statusbar", key);
end

local function ApplyBarVisuals(statusBar, textureKey, colorConfig, overrideColor)
	if not statusBar then
		return;
	end

	local texture = GetStatusBarTexture(textureKey);
	if texture then
		statusBar:SetStatusBarTexture(texture);
	end

	-- For Midnight, match Blizzard's usage: only pass plain RGB(A) numbers when we actively override.
	if overrideColor and colorConfig then
		local r = colorConfig.r or 1;
		local g = colorConfig.g or 1;
		local b = colorConfig.b or 1;
		local a = colorConfig.a;

		if a ~= nil then
			statusBar:SetStatusBarColor(r, g, b, a);
		else
			statusBar:SetStatusBarColor(r, g, b);
		end
	end
end

local function ApplyBorderSettings(border, style, color, size)
	if not border then
		return;
	end

	if style == "None" then
		border:Hide();
		return;
	end

	border:Show();

	if color then
		border:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1);
		border:SetAlpha(color.a or 1);
	end

	if size and size > 0 then
		border:SetScale(size);
	end
end

function Style:ApplyHealthBarStyle(frame, db)
	if not frame or not db then
		return;
	end

	if not frame.HealthBarsContainer or not frame.healthbar then
		return;
	end

	-- Border alpha tweak.
	if frame.HealthBarsContainer.border then
		frame.HealthBarsContainer.border:SetAlpha(db.borderAlpha or 0.5);
	end

	-- Apply texture and optional override color.
	ApplyBarVisuals(frame.healthbar, db.healthTexture, db.healthColor, db.overrideHealthColor);

	-- If not overriding, restore Blizzard's default health color.
	if not db.overrideHealthColor then
		frame.healthbar:SetStatusBarColor(0.0, 0.8, 0.0);
	end

	-- Border styling for the health container.
	if frame.HealthBarsContainer.border then
		ApplyBorderSettings(frame.HealthBarsContainer.border, db.healthBorderStyle, db.healthBorderColor, db.healthBorderSize);
	end

	-- Cache original anchors once so we can safely override and restore.
	local container = frame.HealthBarsContainer;
	if not container._PBRMOriginalPoints then
		container._PBRMOriginalPoints = {};
		for i = 1, container:GetNumPoints() do
			local p, relTo, relPoint, x, y = container:GetPoint(i);
			table.insert(container._PBRMOriginalPoints, { p, relTo, relPoint, x, y });
		end
	end

	-- Optional explicit sizing on top of Blizzard's layout.
	-- To make width adjustable, we need to break the left/right anchors and anchor
	-- the container by TOP relative to the PRD frame while keeping Edit Mode's
	-- position on the parent frame.
	if db.healthWidth and db.healthWidth > 0 then
		container:ClearAllPoints();
		container:SetPoint("TOP", frame, "TOP", 0, 0);
		container:SetWidth(db.healthWidth);
		if db.healthHeight and db.healthHeight > 0 then
			container:SetHeight(db.healthHeight);
		end
	elseif db.healthHeight and db.healthHeight > 0 and container._PBRMOriginalPoints then
		-- Only height override: preserve original anchors, just change height.
		container:ClearAllPoints();
		for _, pt in ipairs(container._PBRMOriginalPoints) do
			container:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]);
		end
		container:SetHeight(db.healthHeight);
	elseif container._PBRMOriginalPoints then
		-- No overrides: restore Blizzard's original anchors and size.
		container:ClearAllPoints();
		for _, pt in ipairs(container._PBRMOriginalPoints) do
			container:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]);
		end
	end

	-- Respect user's preference to hide/show the health bar, layering on top of Blizzard rules.
	if db.showHealthBar == false then
		frame.HealthBarsContainer:Hide();
	else
		-- Only show if Blizzard isn't intentionally hiding health/power.
		if not frame.hideHealthAndPower then
			frame.HealthBarsContainer:Show();
		end
	end

	-- Ensure the health text is updated whenever we (re)style the bar.
	self:UpdateHealthText(frame, db);
end

local function AbbreviatePlainNumber(n)
	-- Use Blizzard's built-in function - it handles secret values properly!
	if AbbreviateLargeNumbers then
		return AbbreviateLargeNumbers(n);
	end
	-- Fallback if function doesn't exist (shouldn't happen)
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
		-- Default: Friz Quadrata.
		return "Fonts\\FRIZQT__.TTF";
	end
end

local function FormatHealthPreset(formatKey, hp, maxHp)
	-- Convert to strings for non-SHORT formats
	local hpStr = tostring(hp or "");
	local maxStr = tostring(maxHp or "");

	if formatKey == "CURRENT" then
		return hpStr;
	elseif formatKey == "CURRENT_MAX" then
		return hpStr .. " / " .. maxStr;
	elseif formatKey == "SHORT" then
		-- Use Blizzard's AbbreviateLargeNumbers - it handles secret values properly
		-- Pass hp directly (can be number or secret value)
		return AbbreviatePlainNumber(hp);
	elseif formatKey == "SHORT_CURRENT_MAX" then
		-- Use Blizzard's AbbreviateLargeNumbers for both values
		-- It handles secret values properly, so we can pass them directly
		local hpAbbrev = AbbreviatePlainNumber(hp);
		local maxAbbrev = AbbreviatePlainNumber(maxHp);
		return hpAbbrev .. " / " .. maxAbbrev;
	end

	return "";
end

local function FormatHealthCustom(template, hp, maxHp)
	if not template or template == "" then
		return "";
	end

	-- In Midnight, health values are SECRET VALUES - we CANNOT use them in gsub at all
	-- We can ONLY use Blizzard's formatting functions: AbbreviateLargeNumbers
	-- We must manually parse the template and build the result without using gsub with secret values
	
	-- Get percentage using UnitHealthPercent (returns secret value, but already 0-100)
	local pct = nil;
	if UnitHealthPercent then
		pct = UnitHealthPercent("player", true, true); -- usePredicted=true, scaleTo100=true
	end
	
	-- Format all values using Blizzard functions (these return secret values)
	-- Full values show raw numbers, short values are abbreviated
	-- BreakUpLargeNumbers is only used when :bln modifier is specified
	local hpFull = nil;
	local hpShort = nil;
	local maxFull = nil;
	local maxShort = nil;
	
	-- Full: try tostring for raw value (works for display even with secret values)
	-- Wrap in pcall in case tostring fails on secret values
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
	
	-- Short: use AbbreviateLargeNumbers
	if AbbreviateLargeNumbers then
		hpShort = AbbreviateLargeNumbers(hp);
		maxShort = AbbreviateLargeNumbers(maxHp);
	end
	
	-- Fallback for short if function doesn't exist
	if not hpShort then hpShort = hpFull; end
	if not maxShort then maxShort = maxFull; end
	-- For percentage, we want whole numbers only (no decimals like "60.3%")
	-- Since pct is already 0-100 from UnitHealthPercent, try to format it as integer
	-- We can't do arithmetic on secret values, so try string.format directly
	local pctFormatted = nil;
	if pct then
		-- Try to format as whole number using string.format - this might work with secret values
		-- If it fails, we'll fall back to AbbreviatePlainNumber
		local ok, formatted = pcall(function()
			return string.format("%.0f", pct);
		end);
		if ok and formatted then
			pctFormatted = formatted;
		else
			-- Fallback to AbbreviatePlainNumber (might have decimals)
			pctFormatted = AbbreviatePlainNumber(pct);
		end
	end

	-- Manually parse and replace tokens - can't use gsub or table.concat with secret values
	-- Use string concatenation (..) which works with secret values
	local result = "";
	local pos = 1;
	
	while pos <= #template do
		local startPos = string.find(template, "{", pos);
		if not startPos then
			-- No more tokens, add rest of string
			result = result .. string.sub(template, pos);
			break;
		end
		
		-- Add text before token
		if startPos > pos then
			result = result .. string.sub(template, pos, startPos - 1);
		end
		
		-- Find end of token
		local endPos = string.find(template, "}", startPos);
		if not endPos then
			-- No closing brace, add rest and break
			result = result .. string.sub(template, startPos);
			break;
		end
		
		-- Extract token
		local token = string.sub(template, startPos + 1, endPos - 1);
		local tokenLower = string.lower(token);
		
		-- Handle token - use string concatenation (..) which works with secret values
		if tokenLower == "hp" then
			-- {hp} shows full number (not abbreviated)
			result = result .. hpFull;
		elseif tokenLower == "hpmax" or tokenLower == "maxhp" then
			-- {hpmax} shows full number (not abbreviated)
			result = result .. maxFull;
		elseif tokenLower == "hp%" then
			if pctFormatted then
				result = result .. pctFormatted .. "%";
			end
		elseif string.match(tokenLower, "^hp:") then
			-- Token with modifiers
			local baseToken = string.match(tokenLower, "^([^:]+)");
			local modifiers = string.sub(token, #baseToken + 2); -- Use original token (not lowercased) for format specifiers
			local modifiersLower = string.lower(modifiers);
			
			if baseToken == "hp" then
				local parts = {};
				local partsOriginal = {}; -- Keep original case for format specifiers
				for part in string.gmatch(modifiers, "([^%-]+)") do
					table.insert(partsOriginal, part);
					table.insert(parts, string.lower(part));
				end
				
				local hasShort = false;
				local hasPercent = false;
				local formatSpec = nil;
				local useBLN = false; -- Use BreakUpLargeNumbers
				
				for i, part in ipairs(parts) do
					if part == "short" then
						hasShort = true;
					elseif part == "%" then
						hasPercent = true;
					elseif string.match(part, "^%%") then
						-- Format specifier like "%.0f", "%.1f", etc. - use original case!
						formatSpec = partsOriginal[i];
						hasPercent = true; -- Format spec implies percentage
					elseif part == "bln" then
						-- Use BreakUpLargeNumbers
						useBLN = true;
					end
				end
				
				if hasPercent and pct then
					-- Format percentage with custom format specifier if provided
					local pctStr = nil;
					if formatSpec then
						-- Try to use the format specifier (e.g., "%.0f" for whole numbers)
						local ok, formatted = pcall(function()
							return string.format(formatSpec, pct);
						end);
						if ok and formatted then
							pctStr = formatted;
						else
							-- Fallback to default formatting
							pctStr = pctFormatted;
						end
					else
						-- Use default formatted percentage
						pctStr = pctFormatted;
					end
					
					if pctStr then
						pctStr = pctStr .. "%";
						if hasShort then
							result = result .. hpShort .. " (" .. pctStr .. ")";
						else
							result = result .. pctStr;
						end
					end
				else
					-- No percentage modifier, show health value
					if useBLN then
						-- Use BreakUpLargeNumbers
						local blnValue = nil;
						if BreakUpLargeNumbers then
							blnValue = BreakUpLargeNumbers(hp);
						end
						if blnValue then
							result = result .. blnValue;
						else
							result = result .. hpFull;
						end
					elseif hasShort then
						result = result .. hpShort;
					else
						result = result .. hpFull;
					end
				end
			end
		elseif string.match(tokenLower, "^hpmax:") or string.match(tokenLower, "^maxhp:") then
			-- Check for modifiers
			local baseToken = string.match(tokenLower, "^([^:]+)");
			local modifiers = string.sub(token, #baseToken + 2); -- Use original token
			local modifiersLower = string.lower(modifiers);
			
			local hasShort = false;
			local useBLN = false;
			
			-- Parse modifiers
			local parts = {};
			local partsOriginal = {};
			for part in string.gmatch(modifiers, "([^%-]+)") do
				table.insert(partsOriginal, part);
				table.insert(parts, string.lower(part));
			end
			
			for i, part in ipairs(parts) do
				if part == "short" then
					hasShort = true;
				elseif part == "bln" then
					useBLN = true;
				end
			end
			
			if useBLN then
				-- Use BreakUpLargeNumbers
				local blnValue = nil;
				if BreakUpLargeNumbers then
					blnValue = BreakUpLargeNumbers(maxHp);
				end
				if blnValue then
					result = result .. blnValue;
				else
					result = result .. maxFull;
				end
			elseif hasShort then
				result = result .. maxShort;
			else
				result = result .. maxFull;
			end
		end
		-- Unsupported tokens (deficit, missing) get empty replacement (nothing added)
		
		pos = endPos + 1;
	end
	
	return result;
end

local function FormatPowerCustom(template, power, maxPower)
	if not template or template == "" then
		return "";
	end

	-- Power values are also SECRET VALUES in Midnight - same approach as health
	-- Get percentage - check if UnitPowerPercent exists, otherwise calculate from bar
	local pct = nil;
	if UnitPowerPercent then
		pct = UnitPowerPercent("player", nil, true, true); -- unit, powerType, usePredicted, scaleTo100
	else
		-- Fallback: try to get from bar value if available
		-- But we can't do arithmetic, so this might not work
	end
	
	-- Format all values using Blizzard functions (these return secret values)
	-- Full values show raw numbers, short values are abbreviated
	-- BreakUpLargeNumbers is only used when :bln modifier is specified
	local powerFull = nil;
	local powerShort = nil;
	local maxFull = nil;
	local maxShort = nil;
	
	-- Full: try tostring for raw value (works for display even with secret values)
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
	
	-- Short: use AbbreviateLargeNumbers
	if AbbreviateLargeNumbers then
		powerShort = AbbreviateLargeNumbers(power);
		maxShort = AbbreviateLargeNumbers(maxPower);
	end
	
	-- Fallback for short if function doesn't exist
	if not powerShort then powerShort = powerFull; end
	if not maxShort then maxShort = maxFull; end
	
	-- Format percentage if available
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

	-- Manually parse and replace tokens - same approach as health
	local result = "";
	local pos = 1;
	
	while pos <= #template do
		local startPos = string.find(template, "{", pos);
		if not startPos then
			result = result .. string.sub(template, pos);
			break;
		end
		
		if startPos > pos then
			result = result .. string.sub(template, pos, startPos - 1);
		end
		
		local endPos = string.find(template, "}", startPos);
		if not endPos then
			result = result .. string.sub(template, startPos);
			break;
		end
		
		local token = string.sub(template, startPos + 1, endPos - 1);
		local tokenLower = string.lower(token);
		
		-- Handle power tokens
		if tokenLower == "power" or tokenLower == "mana" then
			result = result .. powerFull;
		elseif tokenLower == "powermax" or tokenLower == "manamax" or tokenLower == "maxpower" or tokenLower == "maxmana" then
			result = result .. maxFull;
		elseif tokenLower == "power%" or tokenLower == "mana%" then
			if pctFormatted then
				result = result .. pctFormatted .. "%";
			end
		elseif string.match(tokenLower, "^power:") or string.match(tokenLower, "^mana:") then
			local baseToken = string.match(tokenLower, "^([^:]+)");
			local modifiers = string.sub(token, #baseToken + 2);
			local modifiersLower = string.lower(modifiers);
			
			if baseToken == "power" or baseToken == "mana" then
				local parts = {};
				local partsOriginal = {};
				for part in string.gmatch(modifiers, "([^%-]+)") do
					table.insert(partsOriginal, part);
					table.insert(parts, string.lower(part));
				end
				
				local hasShort = false;
				local hasPercent = false;
				local formatSpec = nil;
				local useBLN = false;
				
				for i, part in ipairs(parts) do
					if part == "short" then
						hasShort = true;
					elseif part == "%" then
						hasPercent = true;
					elseif string.match(part, "^%%") then
						formatSpec = partsOriginal[i];
						hasPercent = true;
					elseif part == "bln" then
						useBLN = true;
					end
				end
				
				if hasPercent and pct then
					local pctStr = nil;
					if formatSpec then
						local ok, formatted = pcall(function()
							return string.format(formatSpec, pct);
						end);
						if ok and formatted then
							pctStr = formatted;
						else
							pctStr = pctFormatted;
						end
					else
						pctStr = pctFormatted;
					end
					
					if pctStr then
						pctStr = pctStr .. "%";
						if hasShort then
							result = result .. powerShort .. " (" .. pctStr .. ")";
						else
							result = result .. pctStr;
						end
					end
				else
					if useBLN then
						local blnValue = nil;
						if BreakUpLargeNumbers then
							blnValue = BreakUpLargeNumbers(power);
						end
						if blnValue then
							result = result .. blnValue;
						else
							result = result .. powerFull;
						end
					elseif hasShort then
						result = result .. powerShort;
					else
						result = result .. powerFull;
					end
				end
			end
		elseif string.match(tokenLower, "^powermax:") or string.match(tokenLower, "^manamax:") or string.match(tokenLower, "^maxpower:") or string.match(tokenLower, "^maxmana:") then
			local baseToken = string.match(tokenLower, "^([^:]+)");
			local modifiers = string.sub(token, #baseToken + 2);
			
			local hasShort = false;
			local useBLN = false;
			
			local parts = {};
			local partsOriginal = {};
			for part in string.gmatch(modifiers, "([^%-]+)") do
				table.insert(partsOriginal, part);
				table.insert(parts, string.lower(part));
			end
			
			for i, part in ipairs(parts) do
				if part == "short" then
					hasShort = true;
				elseif part == "bln" then
					useBLN = true;
				end
			end
			
			if useBLN then
				local blnValue = nil;
				if BreakUpLargeNumbers then
					blnValue = BreakUpLargeNumbers(maxPower);
				end
				if blnValue then
					result = result .. blnValue;
				else
					result = result .. maxFull;
				end
			elseif hasShort then
				result = result .. maxShort;
			else
				result = result .. maxFull;
			end
		end
		
		pos = endPos + 1;
	end
	
	return result;
end

local function UpdateTextForBar(frame, db, bar, targetType, formatFunc, getCurrentValue, getMaxValue)
	if not frame or not db or not bar then
		return;
	end

	-- Master toggle: if disabled, hide all texts.
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
	frame._PBRMTextsUsed = frame._PBRMTextsUsed or {}; -- Track which entries are used across all target types
	local texts = db.texts;
	
	-- Set up OnValueChanged hook on the bar to update text when value changes
	if not bar._PBRMTextUpdateRegistered then
		bar._PBRMTextUpdateRegistered = true;
		bar._PBRMFrameRef = frame;
		bar._PBRMTargetType = targetType;
		
		local existingOnValueChanged = bar:GetScript("OnValueChanged");
		
		bar:SetScript("OnValueChanged", function(self, value)
			if existingOnValueChanged then
				existingOnValueChanged(self, value);
			end
			
			local frameRef = self._PBRMFrameRef;
			local storedTargetType = self._PBRMTargetType;
			if frameRef then
				local addon = ns.Addon;
				local db = addon and addon.db and addon.db.profile and addon.db.profile.personalResource;
				if db and db.healthTextEnabled ~= false then
					local Style = ns.PersonalResourceStyle;
					if storedTargetType == "HEALTH" and Style and Style.UpdateHealthText then
						Style:UpdateHealthText(frameRef, db);
					elseif storedTargetType == "POWER" and Style and Style.UpdatePowerText then
						Style:UpdatePowerText(frameRef, db);
					end
				end
			end
		end);
	end

	if type(texts) ~= "table" or #texts == 0 then
		-- Only hide if this is the last target type being processed
		-- For now, just mark as unused - we'll clean up at the end
		return;
	else
		for index, entry in ipairs(texts) do
			-- For backward compatibility, nil target defaults to HEALTH
			local entryTarget = entry.target;
			if targetType == "HEALTH" and entryTarget == nil then
				entryTarget = "HEALTH";
			end
			if entry and entry.enabled ~= false and entryTarget == targetType then
				-- Use a composite key: index + target type to avoid conflicts
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

				-- Always update font and size (in case they changed)
				local fontKey = entry.font or db.textDefaultFont or "FRIZQT";
				-- Re-fetch font path in case LibSharedMedia font changed
				local fontPath = ResolveFontPath(fontKey);
				local size = entry.size or db.textDefaultSize or 18;
				-- Get font outline style (NONE, OUTLINE, THICKOUTLINE, MONOCHROME)
				local outlineStyle = entry.outline or "OUTLINE";
				if outlineStyle == "NONE" then
					outlineStyle = "";
				end
				
				-- Get current values and format text first (before setting font/shadow)
				local current = getCurrentValue();
				local max = getMaxValue();
				local formatString = entry.format or "";
				local text = formatFunc(formatString, current, max);
				local textStr = tostring(text or "");
				
				-- Set font - this will update even if the same font is used
				fs:SetFont(fontPath, size, outlineStyle);

				-- Always update color (in case it changed)
				local color = entry.color or db.textDefaultColor or { r = 1, g = 1, b = 1, a = 1 };
				-- Validate color values
				local r = (type(color.r) == "number" and color.r >= 0 and color.r <= 1) and color.r or 1;
				local g = (type(color.g) == "number" and color.g >= 0 and color.g <= 1) and color.g or 1;
				local b = (type(color.b) == "number" and color.b >= 0 and color.b <= 1) and color.b or 1;
				local a = (type(color.a) == "number" and color.a >= 0 and color.a <= 1) and color.a or 1;
				fs:SetTextColor(r, g, b, a);

				-- Apply drop shadow if enabled
				local shadowEnabled = entry.shadowEnabled;
				if shadowEnabled == nil then
					shadowEnabled = true; -- Default to enabled
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
				
				-- Set text after font/shadow to force a refresh
				fs:SetText(textStr);
				-- Force hide/show to ensure font and shadow changes are applied
				fs:Hide();
				fs:Show();

				frame._PBRMTextsUsed[fsKey] = true;
			end
		end
	end
	
	-- Clean up font strings that are no longer used (after both UpdateHealthText and UpdatePowerText have run)
	-- We'll do this cleanup in ApplyAll after both have been called
end

function Style:UpdateHealthText(frame, db)
	local bar = frame.healthbar;
	if not bar then
		return;
	end
	
	UpdateTextForBar(
		frame, 
		db, 
		bar, 
		"HEALTH",
		FormatHealthCustom,
		function() return UnitHealth("player"); end,
		function() return UnitHealthMax("player"); end
	);
end

function Style:UpdatePowerText(frame, db)
	local bar = frame.PowerBar;
	if not bar then
		return;
	end
	
	UpdateTextForBar(
		frame, 
		db, 
		bar, 
		"POWER",
		FormatPowerCustom,
		function() return UnitPower("player"); end,
		function() return UnitPowerMax("player"); end
	);
end

function Style:ApplyPowerBarStyle(frame, db)
	if not frame or not db then
		return;
	end

	if not frame.PowerBar then
		return;
	end

	-- Cache original anchors once for relative offsets.
	local bar = frame.PowerBar;
	if not bar._PBRMOriginalPoints then
		bar._PBRMOriginalPoints = {};
		for i = 1, bar:GetNumPoints() do
			local p, relTo, relPoint, x, y = bar:GetPoint(i);
			table.insert(bar._PBRMOriginalPoints, { p, relTo, relPoint, x, y });
		end
	end

	-- Apply texture and optional override color.
	ApplyBarVisuals(bar, db.powerTexture, db.powerColor, db.overridePowerColor);

	-- If not overriding, restore Blizzard's default power color logic.
	if not db.overridePowerColor then
		local powerType, powerToken, altR, altG, altB = UnitPowerType("player");
		local info;
		if powerToken then
			if MANA_BAR_COLOR and MANA_BAR_COLOR[powerToken] then
				info = MANA_BAR_COLOR[powerToken];
			elseif PowerBarColor and PowerBarColor[powerToken] then
				info = PowerBarColor[powerToken];
			elseif altR then
				info = { r = altR, g = altG, b = altB };
			elseif PowerBarColor and PowerBarColor[powerType] then
				info = PowerBarColor[powerType];
			end
		end

		if info and info.r and info.g and info.b then
			bar:SetStatusBarColor(info.r, info.g, info.b);
		end
	end

	-- Border styling for the power bar.
	if bar.Border then
		-- Blizzard's border atlas isn't reliably tintable in Midnight. Hide it and draw a simple
		-- rectangular border that we fully control.
		if db.powerBorderStyle == "None" then
			bar.Border:Hide();
			if bar._PBRMBorderTop then
				bar._PBRMBorderTop:Hide();
				bar._PBRMBorderBottom:Hide();
				bar._PBRMBorderLeft:Hide();
				bar._PBRMBorderRight:Hide();
			end
		else
			bar.Border:Hide();

			local color = db.powerBorderColor or { r = 0, g = 0, b = 0, a = db.borderAlpha or 0.5 };
			local thickness = (db.powerBorderSize or 1) * 2;

			if not bar._PBRMBorderTop then
				bar._PBRMBorderTop = bar:CreateTexture(nil, "OVERLAY");
				bar._PBRMBorderBottom = bar:CreateTexture(nil, "OVERLAY");
				bar._PBRMBorderLeft = bar:CreateTexture(nil, "OVERLAY");
				bar._PBRMBorderRight = bar:CreateTexture(nil, "OVERLAY");
			end

			-- Top edge: sits just above the bar.
			bar._PBRMBorderTop:ClearAllPoints();
			bar._PBRMBorderTop:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 0);
			bar._PBRMBorderTop:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 0);
			bar._PBRMBorderTop:SetHeight(thickness);

			-- Bottom edge: sits just below the bar.
			bar._PBRMBorderBottom:ClearAllPoints();
			bar._PBRMBorderBottom:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0);
			bar._PBRMBorderBottom:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0);
			bar._PBRMBorderBottom:SetHeight(thickness);

			-- Left edge: spans exactly between top and bottom borders so corners meet.
			bar._PBRMBorderLeft:ClearAllPoints();
			bar._PBRMBorderLeft:SetPoint("TOPRIGHT", bar._PBRMBorderTop, "TOPLEFT", 0, 0);
			bar._PBRMBorderLeft:SetPoint("BOTTOMRIGHT", bar._PBRMBorderBottom, "BOTTOMLEFT", 0, 0);
			bar._PBRMBorderLeft:SetWidth(thickness);

			-- Right edge: spans exactly between top and bottom borders so corners meet.
			bar._PBRMBorderRight:ClearAllPoints();
			bar._PBRMBorderRight:SetPoint("TOPLEFT", bar._PBRMBorderTop, "TOPRIGHT", 0, 0);
			bar._PBRMBorderRight:SetPoint("BOTTOMLEFT", bar._PBRMBorderBottom, "BOTTOMRIGHT", 0, 0);
			bar._PBRMBorderRight:SetWidth(thickness);

			local r = color.r or 0;
			local g = color.g or 0;
			local b = color.b or 0;
			local a = color.a or 1;

			bar._PBRMBorderTop:SetColorTexture(r, g, b, a);
			bar._PBRMBorderBottom:SetColorTexture(r, g, b, a);
			bar._PBRMBorderLeft:SetColorTexture(r, g, b, a);
			bar._PBRMBorderRight:SetColorTexture(r, g, b, a);

			bar._PBRMBorderTop:Show();
			bar._PBRMBorderBottom:Show();
			bar._PBRMBorderLeft:Show();
			bar._PBRMBorderRight:Show();
		end
	end

	-- Optional explicit sizing and offsets relative to original anchors.
	local hasSizeOverride = (db.powerWidth and db.powerWidth > 0) or (db.powerHeight and db.powerHeight > 0);
	local hasOffset = (db.powerOffsetX and db.powerOffsetX ~= 0) or (db.powerOffsetY and db.powerOffsetY ~= 0);

	if (hasSizeOverride or hasOffset) and bar._PBRMOriginalPoints then
		bar:ClearAllPoints();
		local ox = db.powerOffsetX or 0;
		local oy = db.powerOffsetY or 0;
		for _, pt in ipairs(bar._PBRMOriginalPoints) do
			local p, relTo, relPoint, x, y = pt[1], pt[2], pt[3], pt[4] or 0, pt[5] or 0;
			bar:SetPoint(p, relTo, relPoint, x + ox, y + oy);
		end

		if db.powerWidth and db.powerWidth > 0 then
			bar:SetWidth(db.powerWidth);
		end
		if db.powerHeight and db.powerHeight > 0 then
			bar:SetHeight(db.powerHeight);
		end
	elseif bar._PBRMOriginalPoints then
		bar:ClearAllPoints();
		for _, pt in ipairs(bar._PBRMOriginalPoints) do
			bar:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]);
		end
	end

	-- Respect user's preference to hide/show the power bar, layering on top of Blizzard rules.
	if db.showPowerBar == false then
		frame.PowerBar:Hide();
	else
		if not frame.hideHealthAndPower then
			frame.PowerBar:Show();
		end
	end
end

function Style:ApplyAlternatePowerStyle(frame, db)
	if not frame or not db then
		return;
	end

	if not frame.AlternatePowerBar then
		return;
	end

	if frame.AlternatePowerBar.Border then
		frame.AlternatePowerBar.Border:SetAlpha(db.borderAlpha or 0.5);
	end

	ApplyBarVisuals(frame.AlternatePowerBar, db.alternatePowerTexture, nil, false);

	if db.showAlternatePowerBar == false then
		frame.AlternatePowerBar:Hide();
	else
		if not frame.hideHealthAndPower and frame.AlternatePowerBar.alternatePowerRequirementsMet ~= false then
			frame.AlternatePowerBar:Show();
		end
	end
end

function Style:ApplyClassResourceStyle(frame, db)
	if not frame or not db then
		return;
	end

	-- Class resource widgets (e.g. Holy Power) live under ClassFrameContainer / prdClassFrame.
	local container = frame.ClassFrameContainer;

	if db.showClassResourceBar == false then
		if container then
			container:Hide();
		end
		if _G.prdClassFrame then
			_G.prdClassFrame:Hide();
		end
		return;
	end

	-- Re-show if Blizzard created them and conditions are met.
	if container and _G.prdClassFrame then
		-- Cache original anchors once for relative offsets.
		if not container._PBRMOriginalPoints then
			container._PBRMOriginalPoints = {};
			for i = 1, container:GetNumPoints() do
				local p, relTo, relPoint, x, y = container:GetPoint(i);
				table.insert(container._PBRMOriginalPoints, { p, relTo, relPoint, x, y });
			end
		end

		local hasOffset = (db.classOffsetX and db.classOffsetX ~= 0) or (db.classOffsetY and db.classOffsetY ~= 0);
		if hasOffset and container._PBRMOriginalPoints then
			container:ClearAllPoints();
			local ox = db.classOffsetX or 0;
			local oy = db.classOffsetY or 0;
			for _, pt in ipairs(container._PBRMOriginalPoints) do
				local p, relTo, relPoint, x, y = pt[1], pt[2], pt[3], pt[4] or 0, pt[5] or 0;
				container:SetPoint(p, relTo, relPoint, x + ox, y + oy);
			end
		elseif container._PBRMOriginalPoints then
			container:ClearAllPoints();
			for _, pt in ipairs(container._PBRMOriginalPoints) do
				container:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]);
			end
		end

		container:Show();
		_G.prdClassFrame:Show();
	end
end

function Style:ApplyAll(frame, db)
	self:ApplyHealthBarStyle(frame, db);
	self:ApplyPowerBarStyle(frame, db);
	self:ApplyAlternatePowerStyle(frame, db);
	self:ApplyClassResourceStyle(frame, db);
	
	-- Initialize used tracking
	frame._PBRMTextsUsed = {};
	
	-- Update text displays
	self:UpdateHealthText(frame, db);
	self:UpdatePowerText(frame, db);
	
	-- Clean up font strings that are no longer used
	if frame._PBRMTexts then
		for fsKey, fs in pairs(frame._PBRMTexts) do
			if not frame._PBRMTextsUsed[fsKey] then
				fs:SetText("");
				fs:Hide();
			end
		end
	end
end


