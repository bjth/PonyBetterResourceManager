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

-- Register {hp} token
TextTokens:RegisterToken("hp", function(token, tokenLower, modifiers, context)
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

TextTokens:RegisterToken("hpmax", HandleMaxHp);
TextTokens:RegisterToken("maxhp", HandleMaxHp);

-- Register {hp%} token
TextTokens:RegisterToken("hp%", function(token, tokenLower, modifiers, context)
	local pctFormatted = context.pctFormatted;
	if pctFormatted then
		return pctFormatted .. "%";
	end
	return "";
end);

