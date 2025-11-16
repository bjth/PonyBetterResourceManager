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

-- Register {hp} token
DataTokens:RegisterToken("hp", function(token, tokenLower, modifiers, context)
	local hp = context.hp;
	local hpFull = context.hpFull or "";
	local hpShort = context.hpShort or "";
	local pct = context.pct;
	local pctFormatted = context.pctFormatted;
	
	if modifiers == "" then
		-- {hp} shows full number (not abbreviated)
		return hpFull;
	else
		-- {hp:modifiers}
		local hasShort, hasPercent, formatSpec, useBLN = ParseModifiers(modifiers);
		
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
					return hpShort .. " (" .. pctStr .. ")";
				else
					return pctStr;
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
					return blnValue;
				else
					return hpFull;
				end
			elseif hasShort then
				return hpShort;
			else
				return hpFull;
			end
		end
	end
end);

-- Register {hpmax} and {maxhp} tokens
local function HandleMaxHp(token, tokenLower, modifiers, context)
	local maxHp = context.maxHp;
	local maxFull = context.maxFull or "";
	local maxShort = context.maxShort or "";
	
	if modifiers == "" then
		-- {hpmax} shows full number (not abbreviated)
		return maxFull;
	else
		-- {hpmax:modifiers}
		local hasShort, _, _, useBLN = ParseModifiers(modifiers);
		
		if useBLN then
			-- Use BreakUpLargeNumbers
			local blnValue = nil;
			if BreakUpLargeNumbers then
				blnValue = BreakUpLargeNumbers(maxHp);
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

DataTokens:RegisterToken("hpmax", HandleMaxHp);
DataTokens:RegisterToken("maxhp", HandleMaxHp);

-- Register {hp%} token
DataTokens:RegisterToken("hp%", function(token, tokenLower, modifiers, context)
	local pctFormatted = context.pctFormatted;
	if pctFormatted then
		return pctFormatted .. "%";
	end
	return "";
end);

-- Helper function to get health values for a unit
local function GetUnitHealth(unit)
	if not UnitExists(unit) then
		return nil, nil, nil;
	end
	
	local hp = UnitHealth(unit);
	local maxHp = UnitHealthMax(unit);
	local pct = nil;
	if UnitHealthPercent then
		pct = UnitHealthPercent(unit, true, true);
	end
	
	return hp, maxHp, pct;
end

-- Register {missinghp} token - shows missing health
-- {missinghp} - missing health (uses context.unit or defaults to "player")
-- {missinghp:unit} - missing health for specified unit
DataTokens:RegisterToken("missinghp", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	local hp, maxHp = GetUnitHealth(unit);
	
	if not hp or not maxHp then
		return "";
	end
	
	local missing = maxHp - hp;
	if missing <= 0 then
		return "";
	end
	
	-- Format missing health
	local ok, formatted = pcall(function()
		return tostring(missing);
	end);
	if ok and formatted then
		return formatted;
	end
	return "";
end);

-- Register {missinghp%} token - shows missing health percentage
-- {missinghp%} - missing health % (uses context.unit or defaults to "player")
-- {missinghp%:unit} - missing health % for specified unit
DataTokens:RegisterToken("missinghp%", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	local hp, maxHp, pct = GetUnitHealth(unit);
	
	if not hp or not maxHp or maxHp <= 0 then
		return "";
	end
	
	local missing = maxHp - hp;
	if missing <= 0 then
		return "";
	end
	
	local missingPct = (missing / maxHp) * 100;
	local ok, formatted = pcall(function()
		return string.format("%.0f", missingPct);
	end);
	if ok and formatted then
		return formatted .. "%";
	end
	return "";
end);

-- Register {deficit} token - shows health deficit (negative of missing)
-- {deficit} - health deficit (uses context.unit or defaults to "player")
-- {deficit:unit} - health deficit for specified unit
DataTokens:RegisterToken("deficit", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	local hp, maxHp = GetUnitHealth(unit);
	
	if not hp or not maxHp then
		return "";
	end
	
	local missing = maxHp - hp;
	if missing <= 0 then
		return "";
	end
	
	-- Return as negative number
	local ok, formatted = pcall(function()
		return "-" .. tostring(missing);
	end);
	if ok and formatted then
		return formatted;
	end
	return "";
end);

-- Register {incomingheal} token - shows incoming heal amount
-- {incomingheal} - incoming heal (uses context.unit or defaults to "player")
-- {incomingheal:unit} - incoming heal for specified unit
DataTokens:RegisterToken("incomingheal", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local incomingHeal = UnitGetIncomingHeals(unit) or 0;
	if incomingHeal <= 0 then
		return "";
	end
	
	local ok, formatted = pcall(function()
		return tostring(incomingHeal);
	end);
	if ok and formatted then
		return formatted;
	end
	return "";
end);

-- Register {healcomm} token - shows HealComm incoming heal (if addon present)
-- {healcomm} - HealComm incoming heal (uses context.unit or defaults to "player")
-- {healcomm:unit} - HealComm incoming heal for specified unit
DataTokens:RegisterToken("healcomm", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	-- Check if HealComm is available
	if HealComm and HealComm.GetHealAmount then
		local healAmount = HealComm:GetHealAmount(unit);
		if healAmount and healAmount > 0 then
			local ok, formatted = pcall(function()
				return tostring(healAmount);
			end);
			if ok and formatted then
				return formatted;
			end
		end
	end
	
	return "";
end);

-- Register {absorbs} token - shows total absorb shields
-- {absorbs} - total absorbs (uses context.unit or defaults to "player")
-- {absorbs:unit} - total absorbs for specified unit
DataTokens:RegisterToken("absorbs", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local totalAbsorb = UnitGetTotalAbsorbs(unit) or 0;
	if totalAbsorb <= 0 then
		return "";
	end
	
	local ok, formatted = pcall(function()
		return tostring(totalAbsorb);
	end);
	if ok and formatted then
		return formatted;
	end
	return "";
end);

-- Register {overabsorbs} token - shows over-absorb amount
-- {overabsorbs} - over-absorb amount (uses context.unit or defaults to "player")
-- {overabsorbs:unit} - over-absorb amount for specified unit
-- NOTE: This token is disabled because calculating over-absorb requires arithmetic on secret values
-- Blizzard provides UnitGetTotalAbsorbs() but no direct function for over-absorbs.
-- To calculate over-absorb, you would need: (hp + totalAbsorb) - maxHp
-- However, hp and maxHp are secret values in Midnight, and arithmetic on secret values is not allowed.
-- Blizzard calculates this internally in their own code, but addons cannot do the same calculation.
-- Users should use {absorbs} token instead to see total absorb amount.
DataTokens:RegisterToken("overabsorbs", function(token, tokenLower, modifiers, context)
	return "";
end);

