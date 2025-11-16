local ADDON_NAME, ns = ...;

local TextTokens = ns.PersonalResourceTextTokens;
if not TextTokens then
	return;
end

-- Register {targetname} token - shows target name
-- {targetname} - full name
-- {targetname:short} - shortened name (first word only)
TextTokens:RegisterToken("targetname", function(token, tokenLower, modifiers, context)
	if not UnitExists("target") then
		return "";
	end
	
	local name = UnitName("target");
	if not name then
		return "";
	end
	
	-- Check for :short modifier
	if modifiers and modifiers ~= "" then
		local modifiersLower = string.lower(modifiers);
		if modifiersLower == "short" then
			-- Return first word only
			local firstWord = string.match(name, "^([^%s]+)");
			return firstWord or name;
		end
	end
	
	return name;
end);

-- Register {targethealth} token - shows target health percentage
TextTokens:RegisterToken("targethealth", function(token, tokenLower, modifiers, context)
	if not UnitExists("target") then
		return "";
	end
	
	-- Use UnitHealthPercent if available (returns secret value)
	local pct = nil;
	if UnitHealthPercent then
		pct = UnitHealthPercent("target", true, true); -- usePredicted=true, scaleTo100=true
	end
	
	if pct then
		-- Try to format as whole number
		local ok, formatted = pcall(function()
			return string.format("%.0f", pct);
		end);
		if ok and formatted then
			return formatted .. "%";
		end
	end
	
	return "";
end);

-- Register {targetlevel} token - shows target level (or "??" if too high)
TextTokens:RegisterToken("targetlevel", function(token, tokenLower, modifiers, context)
	if not UnitExists("target") then
		return "";
	end
	
	local level = UnitLevel("target");
	if level and level > 0 then
		return tostring(level);
	elseif level == -1 then
		-- Level too high to determine
		return "??";
	end
	
	return "";
end);

-- Register {level} token - shows player level
TextTokens:RegisterToken("level", function(token, tokenLower, modifiers, context)
	local level = UnitLevel("player");
	if level then
		return tostring(level);
	end
	return "";
end);

-- Register {class} token - shows player class
-- {class} - full class name
-- {class:short} - class abbreviation (first 3-4 letters)
TextTokens:RegisterToken("class", function(token, tokenLower, modifiers, context)
	local className, classFile = UnitClass("player");
	if not className then
		return "";
	end
	
	-- Check for :short modifier
	if modifiers and modifiers ~= "" then
		local modifiersLower = string.lower(modifiers);
		if modifiersLower == "short" then
			-- Return first 3-4 letters
			return string.sub(className, 1, 4);
		end
	end
	
	return className;
end);

