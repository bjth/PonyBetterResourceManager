local ADDON_NAME, ns = ...;

-- TextTokens: Modular token replacement system for format strings
-- This allows easy extension of format string tokens without modifying core formatting logic

local TextTokens = {};
ns.PersonalResourceTextTokens = TextTokens;

-- Token registry: maps token names (lowercase) to handler functions
-- Handler signature: handler(token, tokenLower, modifiers, context)
-- context contains: hp, maxHp, power, maxPower, pct, hpFull, hpShort, maxFull, maxShort, powerFull, powerShort
local tokenHandlers = {};

-- Register a token handler
-- name: token name (e.g., "hp", "mark", "combat")
-- handler: function(token, tokenLower, modifiers, context) -> string
function TextTokens:RegisterToken(name, handler)
	if not name or not handler then
		return;
	end
	tokenHandlers[string.lower(name)] = handler;
end

-- Process a format string template and replace tokens
-- template: format string (e.g., "{hp} / {hpmax}")
-- context: table with values like hp, maxHp, power, maxPower, pct, etc.
function TextTokens:ProcessTemplate(template, context)
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
		
		-- Check if token has modifiers (e.g., {hp:short})
		local baseToken = tokenLower;
		local modifiers = "";
		local colonPos = string.find(tokenLower, ":");
		if colonPos then
			baseToken = string.sub(tokenLower, 1, colonPos - 1);
			modifiers = string.sub(token, colonPos + 1); -- Keep original case for format specifiers
		end
		
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

-- Initialize default tokens
function TextTokens:Initialize()
	-- Health tokens will be registered in HealthTokens.lua
	-- Power tokens will be registered in PowerTokens.lua
	-- Icon tokens will be registered in IconTokens.lua
end

return TextTokens;

