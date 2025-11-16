local ADDON_NAME, ns = ...;

local TextTokens = ns.PersonalResourceTextTokens;
if not TextTokens then
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

TextTokens:RegisterToken("power", HandlePower);
TextTokens:RegisterToken("mana", HandlePower);

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

TextTokens:RegisterToken("powermax", HandleMaxPower);
TextTokens:RegisterToken("manamax", HandleMaxPower);
TextTokens:RegisterToken("maxpower", HandleMaxPower);
TextTokens:RegisterToken("maxmana", HandleMaxPower);

-- Register {power%} and {mana%} tokens
local function HandlePowerPercent(token, tokenLower, modifiers, context)
	local pctFormatted = context.pctFormatted;
	if pctFormatted then
		return pctFormatted .. "%";
	end
	return "";
end

TextTokens:RegisterToken("power%", HandlePowerPercent);
TextTokens:RegisterToken("mana%", HandlePowerPercent);

