local ADDON_NAME, ns = ...;

-- DataTokens: Modular token replacement system for format strings
-- This allows easy extension of format string tokens without modifying core formatting logic

local DataTokens = {};
ns.DataTokens = DataTokens;

-- Token registry: maps token names (lowercase) to handler functions
-- Handler signature: handler(token, tokenLower, modifiers, context)
-- context contains: hp, maxHp, power, maxPower, pct, hpFull, hpShort, maxFull, maxShort, powerFull, powerShort
-- context.unit: default unit for this frame (e.g., "player", "target", "pet")
local tokenHandlers = {};

-- Helper function to extract unit from modifiers
-- Supports patterns like: {name:target}, {hp:pet:short}, etc.
function DataTokens.ExtractUnitFromModifiers(modifiers)
	if not modifiers or modifiers == "" then
		return nil;
	end
	
	-- Check for common unit identifiers
	local unitMap = {
		player = "player",
		target = "target",
		pet = "pet",
		focus = "focus",
		targettarget = "targettarget",
		tot = "targettarget",
	};
	
	-- Check for party/raid units
	local partyMatch = string.match(modifiers, "^party(%d+)$");
	if partyMatch then
		return "party" .. partyMatch;
	end
	
	local raidMatch = string.match(modifiers, "^raid(%d+)$");
	if raidMatch then
		return "raid" .. raidMatch;
	end
	
	-- Check direct unit name
	local modifiersLower = string.lower(modifiers);
	if unitMap[modifiersLower] then
		return unitMap[modifiersLower];
	end
	
	-- Check if modifier starts with a unit name followed by colon (e.g., "target:short")
	for unitName, unitId in pairs(unitMap) do
		if string.find(modifiersLower, "^" .. unitName .. ":") then
			return unitId;
		end
	end
	
	return nil;
end

-- Register a token handler
-- name: token name (e.g., "hp", "mark", "combat")
-- handler: function(token, tokenLower, modifiers, context) -> string
function DataTokens:RegisterToken(name, handler)
	if not name or not handler then
		return;
	end
	tokenHandlers[string.lower(name)] = handler;
end

-- Process a format string template and replace tokens
-- template: format string (e.g., "{hp} / {hpmax}")
-- context: table with values like hp, maxHp, power, maxPower, pct, etc.
function DataTokens:ProcessTemplate(template, context)
	if not template or template == "" then
		return "";
	end
	
	context = context or {};
	
	-- Manually parse and replace tokens - can't use gsub with secret values
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
		
		-- Check if token has modifiers (e.g., {hp:short} or {name:target:short})
		local baseToken = tokenLower;
		local modifiers = "";
		local colonPos = string.find(tokenLower, ":");
		if colonPos then
			baseToken = string.sub(tokenLower, 1, colonPos - 1);
			modifiers = string.sub(token, colonPos + 1); -- Keep original case for format specifiers
		end
		
		-- Extract unit from modifiers if present (e.g., {name:target} or {hp:pet:short})
		local unitFromModifier = DataTokens.ExtractUnitFromModifiers(modifiers);
		local actualUnit = unitFromModifier or (context and context.unit) or "player";
		
		-- Remove unit from modifiers if it was extracted (e.g., "target:short" -> "short")
		if unitFromModifier then
			local unitPattern = "^" .. string.lower(unitFromModifier) .. ":";
			if string.find(string.lower(modifiers), unitPattern) then
				modifiers = string.sub(modifiers, #unitFromModifier + 2);
			elseif string.lower(modifiers) == string.lower(unitFromModifier) then
				modifiers = "";
			end
		end
		
		-- Add unit to context for handler
		if not context then
			context = {};
		end
		context.actualUnit = actualUnit;
		
		-- Look up handler
		local handler = tokenHandlers[baseToken];
		if handler then
			local replacement = handler(token, tokenLower, modifiers, context);
			if replacement then
				result = result .. replacement;
			end
		end
		-- If no handler found, token is ignored (nothing added to result)
		
		pos = endPos + 1;
	end
	
	return result;
end

-- Helper function to get unit from context
-- This is used by all token handlers to determine which unit to query
function DataTokens:GetUnit(context)
	return (context and context.actualUnit) or (context and context.unit) or "player";
end

-- Export ExtractUnitFromModifiers as a module function
DataTokens.ExtractUnitFromModifiers = ExtractUnitFromModifiers;

-- Initialize default tokens
function DataTokens:Initialize()
	-- Health tokens will be registered in HealthTokens.lua
	-- Power tokens will be registered in PowerTokens.lua
	-- Icon tokens will be registered in IconTokens.lua
end

return DataTokens;

