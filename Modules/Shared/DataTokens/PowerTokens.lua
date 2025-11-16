local ADDON_NAME, ns = ...;

local DataTokens = ns.DataTokens;
if not DataTokens then
	return;
end

local BreakUpLargeNumbers = BreakUpLargeNumbers;
local AbbreviatePlainNumber = function(n)
	if AbbreviateLargeNumbers then
		return AbbreviateLargeNumbers(n);
	end
	return tostring(n);
end;

-- Helper to parse modifiers
local function ParseModifiers(modifiers)
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
			-- Format specifier like "%.0f", "%.1f", etc. - use original case!
			formatSpec = partsOriginal[i];
			hasPercent = true; -- Format spec implies percentage
		elseif part == "bln" then
			-- Use BreakUpLargeNumbers
			useBLN = true;
		end
	end
	
	return hasShort, hasPercent, formatSpec, useBLN;
end

-- Register {power} and {mana} tokens
local function HandlePower(token, tokenLower, modifiers, context)
	local power = context.power;
	local powerFull = context.powerFull or "";
	local powerShort = context.powerShort or "";
	local pct = context.pct;
	local pctFormatted = context.pctFormatted;
	
	if modifiers == "" then
		-- {power} shows full number (not abbreviated)
		return powerFull;
	else
		-- {power:modifiers}
		local hasShort, hasPercent, formatSpec, useBLN = ParseModifiers(modifiers);
		
		if hasPercent and pct then
			-- Format percentage with custom format specifier if provided
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
					return powerShort .. " (" .. pctStr .. ")";
				else
					return pctStr;
				end
			end
		else
			-- No percentage modifier, show power value
			if useBLN then
				local blnValue = nil;
				if BreakUpLargeNumbers then
					blnValue = BreakUpLargeNumbers(power);
				end
				if blnValue then
					return blnValue;
				else
					return powerFull;
				end
			elseif hasShort then
				return powerShort;
			else
				return powerFull;
			end
		end
	end
end

DataTokens:RegisterToken("power", HandlePower);
DataTokens:RegisterToken("mana", HandlePower);

-- Register {powermax}, {manamax}, {maxpower}, {maxmana} tokens
local function HandleMaxPower(token, tokenLower, modifiers, context)
	local maxPower = context.maxPower;
	local maxFull = context.maxFull or "";
	local maxShort = context.maxShort or "";
	
	if modifiers == "" then
		-- {powermax} shows full number (not abbreviated)
		return maxFull;
	else
		-- {powermax:modifiers}
		local hasShort, _, _, useBLN = ParseModifiers(modifiers);
		
		if useBLN then
			local blnValue = nil;
			if BreakUpLargeNumbers then
				blnValue = BreakUpLargeNumbers(maxPower);
			end
			if blnValue then
				return blnValue;
			else
				return maxFull;
			end
		elseif hasShort then
			return maxShort;
		else
			return maxFull;
		end
	end
end

DataTokens:RegisterToken("powermax", HandleMaxPower);
DataTokens:RegisterToken("manamax", HandleMaxPower);
DataTokens:RegisterToken("maxpower", HandleMaxPower);
DataTokens:RegisterToken("maxmana", HandleMaxPower);

-- Register {power%} and {mana%} tokens
local function HandlePowerPercent(token, tokenLower, modifiers, context)
	local pctFormatted = context.pctFormatted;
	if pctFormatted then
		return pctFormatted .. "%";
	end
	return "";
end

DataTokens:RegisterToken("power%", HandlePowerPercent);
DataTokens:RegisterToken("mana%", HandlePowerPercent);

-- Helper function to get power type name
local function GetPowerTypeName(powerToken)
	if not powerToken then
		return "";
	end
	
	local powerNames = {
		MANA = "Mana",
		RAGE = "Rage",
		ENERGY = "Energy",
		FOCUS = "Focus",
		RUNIC_POWER = "Runic Power",
		SOUL_SHARDS = "Soul Shards",
		LUNAR_POWER = "Lunar Power",
		HOLY_POWER = "Holy Power",
		MAELSTROM = "Maelstrom",
		INSANITY = "Insanity",
		CHI = "Chi",
		ARCANE_CHARGES = "Arcane Charges",
		COMBO_POINTS = "Combo Points",
		FURY = "Fury",
		PAIN = "Pain",
	};
	
	return powerNames[powerToken] or powerToken;
end

-- Helper function to get power color code
local function GetPowerColorCode(powerToken)
	if not powerToken then
		return "";
	end
	
	-- Use Blizzard's PowerBarColor if available
	if PowerBarColor and PowerBarColor[powerToken] then
		local color = PowerBarColor[powerToken];
		if color and color.r and color.g and color.b then
			-- Convert to hex color code
			local r = math.floor(color.r * 255);
			local g = math.floor(color.g * 255);
			local b = math.floor(color.b * 255);
			return string.format("|cff%02x%02x%02x", r, g, b);
		end
	end
	
	return "";
end

-- Helper function to get power values for a unit
local function GetUnitPower(unit, powerType)
	if not UnitExists(unit) then
		return nil, nil, nil, nil;
	end
	
	local power = UnitPower(unit, powerType);
	local maxPower = UnitPowerMax(unit, powerType);
	local pct = nil;
	if UnitPowerPercent then
		pct = UnitPowerPercent(unit, powerType, true, true);
	end
	
	-- Get power type token
	local actualPowerType, powerToken = UnitPowerType(unit);
	if powerType then
		actualPowerType = powerType;
		powerToken = nil; -- Will need to look up token from power type
	end
	
	return power, maxPower, pct, powerToken;
end

-- Register {powername} token - shows power type name
-- {powername} - power type name (uses context.unit or defaults to "player")
-- {powername:unit} - power type name for specified unit
DataTokens:RegisterToken("powername", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local powerType, powerToken = UnitPowerType(unit);
	if not powerToken then
		return "";
	end
	
	return GetPowerTypeName(powerToken);
end);

-- Register {powercolor} token - shows power color code
-- {powercolor} - power color code (uses context.unit or defaults to "player")
-- {powercolor:unit} - power color code for specified unit
DataTokens:RegisterToken("powercolor", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local powerType, powerToken = UnitPowerType(unit);
	if not powerToken then
		return "";
	end
	
	return GetPowerColorCode(powerToken);
end);

-- Register {missingpower} token - shows missing power
-- {missingpower} - missing power (uses context.unit or defaults to "player")
-- {missingpower:unit} - missing power for specified unit
DataTokens:RegisterToken("missingpower", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local powerType = UnitPowerType(unit);
	local power, maxPower = GetUnitPower(unit, powerType);
	
	if not power or not maxPower then
		return "";
	end
	
	local missing = maxPower - power;
	if missing <= 0 then
		return "";
	end
	
	local ok, formatted = pcall(function()
		return tostring(missing);
	end);
	if ok and formatted then
		return formatted;
	end
	return "";
end);

