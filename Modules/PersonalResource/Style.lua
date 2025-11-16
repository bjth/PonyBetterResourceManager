local ADDON_NAME, ns = ...;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;

local Style = {};
ns.PersonalResourceStyle = Style;

local BreakUpLargeNumbers = BreakUpLargeNumbers;
local AbbreviateLargeNumbers = AbbreviateLargeNumbers or BreakUpLargeNumbers;

-- Get the DataTokens system
local DataTokens = ns.DataTokens;

-- Get shared utilities
local PowerColor = ns.PowerColor;
local BarStyling = ns.BarStyling;

function Style:ApplyHealthBarStyle(frame, db)
	if not frame or not db then
		return;
	end

	if not frame.HealthBarsContainer or not frame.healthbar then
		return;
	end

	-- Use shared bar styling module
	if BarStyling then
		BarStyling:ApplyHealthBarStyle(frame, frame.healthbar, frame.HealthBarsContainer, db, "player");
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

	-- Use the modular token system to process the template
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
			unit = "player", -- Default unit for Personal Resource
		};
		return DataTokens:ProcessTemplate(template, context);
	else
		-- Fallback: return empty string if token system not available
		return "";
	end
end

local function FormatPowerCustom(template, power, maxPower, unit)
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

	-- Use the modular token system to process the template
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
			unit = unit or "player", -- Use provided unit or default to "player"
		};
		return DataTokens:ProcessTemplate(template, context);
	else
		-- Fallback: return empty string if token system not available
		return "";
	end
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
			-- Filter by resourceType: only show PERSONAL texts (or nil for backward compatibility)
			local entryResourceType = entry.resourceType;
			if not entryResourceType or entryResourceType == "PERSONAL" then
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
	end
	
	-- Clean up font strings that are no longer used (after both UpdateHealthText and UpdatePowerText have run)
	-- We'll do this cleanup in ApplyAll after both have been called
end

-- Helper function to check if format string contains dynamic tokens
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

	-- Use shared bar styling module
	if BarStyling then
		BarStyling:ApplyPowerBarStyle(frame, frame.PowerBar, db, "player");
	end
end

function Style:ApplyAlternatePowerStyle(frame, db)
	if not frame or not db then
		return;
	end

	if not frame.AlternatePowerBar then
		return;
	end

	-- Border alpha is now handled per-border via border color alpha
	if frame.AlternatePowerBar.Border then
		frame.AlternatePowerBar.Border:SetAlpha(0.5);
	end

	if BarStyling then
		BarStyling:ApplyBarVisuals(frame.AlternatePowerBar, db.alternatePowerTexture, nil, false);
	end

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
	
	-- Set up periodic updates for dynamic tokens (fps, latency, time)
	self:SetupDynamicTokenUpdates(frame, db);
end

function Style:SetupDynamicTokenUpdates(frame, db)
	if not frame or not db then
		return;
	end
	
	-- Check if any text entries use dynamic tokens
	local hasDynamicTokens = false;
	local texts = db.texts;
	if type(texts) == "table" then
		for _, entry in ipairs(texts) do
			if entry and entry.enabled ~= false and entry.format then
				if HasDynamicTokens(entry.format) then
					hasDynamicTokens = true;
					break;
				end
			end
		end
	end
	
	-- Set up separate update frame for dynamic tokens to avoid interfering with Blizzard's OnUpdate
	if hasDynamicTokens then
		if not frame._PBRMDynamicUpdateFrame then
			-- Create a separate frame for our updates
			local updateFrame = CreateFrame("Frame");
			frame._PBRMDynamicUpdateFrame = updateFrame;
			updateFrame._PBRMLastUpdate = 0;
			updateFrame._PBRMTargetFrame = frame;
			
			updateFrame:SetScript("OnUpdate", function(self, elapsed)
				-- Update every 0.5 seconds for dynamic tokens
				self._PBRMLastUpdate = (self._PBRMLastUpdate or 0) + elapsed;
				if self._PBRMLastUpdate >= 0.5 then
					self._PBRMLastUpdate = 0;
					
					local targetFrame = self._PBRMTargetFrame;
					if not targetFrame then
						return;
					end
					
					-- Only update text strings directly, don't trigger full updates
					-- This avoids triggering Blizzard's update methods that do arithmetic on secret values
					local addon = ns.Addon;
					local dbLocal = addon and addon.db and addon.db.profile and addon.db.profile.personalResource;
					if dbLocal and dbLocal.healthTextEnabled ~= false and targetFrame._PBRMTexts then
						local texts = dbLocal.texts;
						if type(texts) == "table" then
							for index, entry in ipairs(texts) do
								-- Filter by resourceType: only show PERSONAL texts (or nil for backward compatibility)
								local entryResourceType = entry.resourceType;
								if (not entryResourceType or entryResourceType == "PERSONAL") and 
								   entry and entry.enabled ~= false and entry.format and HasDynamicTokens(entry.format) then
									local entryTarget = entry.target;
									if entryTarget == nil then
										entryTarget = "HEALTH"; -- Default to health for backward compatibility
									end
									
									-- Find the font string for this entry
									local fsKey = index .. "_" .. entryTarget;
									local fs = targetFrame._PBRMTexts[fsKey];
									if fs and fs:IsShown() then
										-- Get the appropriate bar and format function
										local bar = nil;
										local formatFunc = nil;
										local getCurrentValue = nil;
										local getMaxValue = nil;
										
										if entryTarget == "HEALTH" then
											bar = targetFrame.healthbar;
											formatFunc = FormatHealthCustom;
											getCurrentValue = function() return UnitHealth("player"); end;
											getMaxValue = function() return UnitHealthMax("player"); end;
										elseif entryTarget == "POWER" then
											bar = targetFrame.PowerBar;
											formatFunc = FormatPowerCustom;
											getCurrentValue = function() return UnitPower("player"); end;
											getMaxValue = function() return UnitPowerMax("player"); end;
										end
										
										if bar and formatFunc and getCurrentValue and getMaxValue then
											-- Only update the text, don't trigger full refresh
											local current = getCurrentValue();
											local max = getMaxValue();
											local formatString = entry.format or "";
											local text = formatFunc(formatString, current, max);
											local textStr = tostring(text or "");
											fs:SetText(textStr);
										end
									end
								end
							end
						end
					end
				end
			end);
		end
	else
		-- Clean up update frame if no dynamic tokens
		if frame._PBRMDynamicUpdateFrame then
			frame._PBRMDynamicUpdateFrame:SetScript("OnUpdate", nil);
			frame._PBRMDynamicUpdateFrame = nil;
		end
	end
end


