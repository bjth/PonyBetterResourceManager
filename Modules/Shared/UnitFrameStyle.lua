local ADDON_NAME, ns = ...;

-- UnitFrameStyle: Shared styling utilities for unit frame modules
-- Provides common text formatting, font resolution, and text update logic

local UnitFrameStyle = {};
ns.UnitFrameStyle = UnitFrameStyle;

local addon = ns.Addon;
local LSM = ns.Media and ns.Media.LSM;
local DataTokens = ns.DataTokens;

local BreakUpLargeNumbers = BreakUpLargeNumbers;
local AbbreviateLargeNumbers = AbbreviateLargeNumbers or BreakUpLargeNumbers;

-- Helper function to abbreviate numbers
local function AbbreviatePlainNumber(n)
	if AbbreviateLargeNumbers then
		return AbbreviateLargeNumbers(n);
	end
	return tostring(n);
end

-- Resolve font path from key
function UnitFrameStyle:ResolveFontPath(key)
	if LSM then
		local font = LSM:Fetch("font", key);
		if font then
			return font;
		end
	end
	
	if key == "ARIALN" then
		return "Fonts\\ARIALN.TTF";
	elseif key == "MORPHEUS" then
		return "Fonts\\MORPHEUS.TTF";
	else
		return "Fonts\\FRIZQT__.TTF";
	end
end

-- Format health values using DataTokens
-- unit: unit ID (e.g., "target", "focus", "pet")
function UnitFrameStyle:FormatHealth(unit, template, hp, maxHp)
	if not template or template == "" then
		return "";
	end

	local pct = nil;
	if UnitHealthPercent then
		pct = UnitHealthPercent(unit, true, true);
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

	-- Get DataTokens at runtime (not at load time) in case it's not loaded yet
	local DataTokensRuntime = ns.DataTokens;
	
	if DataTokensRuntime and DataTokensRuntime.ProcessTemplate then
		local context = {
			hp = hp,
			maxHp = maxHp,
			hpFull = hpFull,
			hpShort = hpShort,
			maxFull = maxFull,
			maxShort = maxShort,
			pct = pct,
			pctFormatted = pctFormatted,
			unit = unit,
		};
		return DataTokensRuntime:ProcessTemplate(template, context);
	else
		return "";
	end
end

-- Format power values using DataTokens
-- unit: unit ID (e.g., "target", "focus", "pet")
function UnitFrameStyle:FormatPower(unit, template, power, maxPower)
	if not template or template == "" then
		return "";
	end

	local pct = nil;
	if UnitPowerPercent then
		local powerType = UnitPowerType(unit);
		pct = UnitPowerPercent(unit, powerType, true, true);
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

	-- Get DataTokens at runtime (not at load time) in case it's not loaded yet
	local DataTokensRuntime = ns.DataTokens;
	
	if DataTokensRuntime and DataTokensRuntime.ProcessTemplate then
		local context = {
			power = power,
			maxPower = maxPower,
			powerFull = powerFull,
			powerShort = powerShort,
			maxFull = maxFull,
			maxShort = maxShort,
			pct = pct,
			pctFormatted = pctFormatted,
			unit = unit,
		};
		return DataTokensRuntime:ProcessTemplate(template, context);
	else
		return "";
	end
end

-- Update text for a bar
-- frame: the unit frame
-- db: database config for this frame type
-- bar: the status bar to attach text to
-- targetType: "HEALTH" or "POWER"
-- unit: unit ID (e.g., "target", "focus", "pet")
-- resourceType: resource type string for filtering texts (e.g., "TARGET", "FOCUS", "PET", "TARGETOFTARGET")
-- formatFunc: function(template, current, max) -> formatted string
-- getCurrentValue: function() -> current value
-- getMaxValue: function() -> max value
function UnitFrameStyle:UpdateTextForBar(frame, db, bar, targetType, unit, resourceType, formatFunc, getCurrentValue, getMaxValue)
	if not frame or not db or not bar then
		return;
	end

	frame._PBRMTexts = frame._PBRMTexts or {};
	frame._PBRMTextsUsed = frame._PBRMTextsUsed or {};
	
	-- Texts are stored in each resource's own database (db.texts)
	-- Initialize if needed
	if not db.texts then
		db.texts = {};
	end
	local texts = db.texts;
	
	if not UnitExists(unit) then
		return;
	end
	
	if type(texts) ~= "table" then
		return;
	end
	
	-- Iterate through texts and display matching ones
	for index, entry in ipairs(texts) do
		if not entry then
			-- Skip nil entries
		else
			-- Filter by resourceType
			local entryResourceType = entry.resourceType;
			-- Must match exactly (no backward compatibility here - texts should have resourceType set)
			if entryResourceType == resourceType then
				local entryTarget = entry.target;
				-- For backward compatibility, nil target defaults to HEALTH for health bars
				if targetType == "HEALTH" and entryTarget == nil then
					entryTarget = "HEALTH";
				end
				if entry.enabled ~= false and entryTarget == targetType then
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

					-- Use default font/size from db (db is already the correct resource database)
					local defaultFont = db.textDefaultFont or "FRIZQT";
					local defaultSize = db.textDefaultSize or 18;
					local fontKey = entry.font or defaultFont;
					local fontPath = self:ResolveFontPath(fontKey);
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

					local defaultColor = db.textDefaultColor or { r = 1, g = 1, b = 1, a = 1 };
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
					
					-- Set justify based on anchor point for better text positioning
					local justifyH = "CENTER";
					local justifyV = "MIDDLE";
					if point == "LEFT" or point == "TOPLEFT" or point == "BOTTOMLEFT" then
						justifyH = "LEFT";
					elseif point == "RIGHT" or point == "TOPRIGHT" or point == "BOTTOMRIGHT" then
						justifyH = "RIGHT";
					end
					if point == "TOP" or point == "TOPLEFT" or point == "TOPRIGHT" then
						justifyV = "TOP";
					elseif point == "BOTTOM" or point == "BOTTOMLEFT" or point == "BOTTOMRIGHT" then
						justifyV = "BOTTOM";
					end
					fs:SetJustifyH(justifyH);
					fs:SetJustifyV(justifyV);
					
					fs:SetText(textStr);
					-- Force hide/show to ensure font and other changes are applied
					fs:Hide();
					fs:Show();

					frame._PBRMTextsUsed[fsKey] = true;
				end
			end
		end
	end
end

return UnitFrameStyle;

