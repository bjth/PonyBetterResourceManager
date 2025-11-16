local ADDON_NAME, ns = ...;

local DataTokens = ns.DataTokens;
if not DataTokens then
	return;
end

-- Register {name} token - shows unit name
-- {name} - full name (uses context.unit or defaults to "player")
-- {name:unit} - name for specified unit (e.g., {name:target}, {name:pet})
-- {name:short} - shortened name (first word only)
-- {name:unit:short} - shortened name for specified unit
DataTokens:RegisterToken("name", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local name = UnitName(unit);
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

-- Register {targetname} token - shows target name (backward compatibility)
-- {targetname} - full name
-- {targetname:short} - shortened name (first word only)
DataTokens:RegisterToken("targetname", function(token, tokenLower, modifiers, context)
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
DataTokens:RegisterToken("targethealth", function(token, tokenLower, modifiers, context)
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
DataTokens:RegisterToken("targetlevel", function(token, tokenLower, modifiers, context)
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

-- Register {level} token - shows unit level
-- {level} - level (uses context.unit or defaults to "player")
-- {level:unit} - level for specified unit
DataTokens:RegisterToken("level", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local level = UnitLevel(unit);
	if level and level > 0 then
		return tostring(level);
	elseif level == -1 then
		-- Level too high to determine
		return "??";
	end
	return "";
end);

-- Register {smartlevel} token - shows level with elite indicator
-- {smartlevel} - level with + for elite/boss
-- {smartlevel:unit} - smart level for specified unit
DataTokens:RegisterToken("smartlevel", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local level = UnitLevel(unit);
	local classification = UnitClassification(unit);
	
	if level and level > 0 then
		local levelStr = tostring(level);
		if classification == "elite" or classification == "rareelite" then
			return levelStr .. "+";
		elseif classification == "worldboss" or classification == "rare" then
			return levelStr .. "+";
		end
		return levelStr;
	elseif level == -1 then
		return "??";
	end
	return "";
end);

-- Register {class} token - shows unit class
-- {class} - full class name (uses context.unit or defaults to "player")
-- {class:unit} - class for specified unit
-- {class:short} - class abbreviation (first 3-4 letters)
-- {class:unit:short} - class abbreviation for specified unit
DataTokens:RegisterToken("class", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or not UnitIsPlayer(unit) then
		return "";
	end
	
	local className, classFile = UnitClass(unit);
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

-- Register {race} token - shows unit race
-- {race} - race name (uses context.unit or defaults to "player")
-- {race:unit} - race for specified unit
DataTokens:RegisterToken("race", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or not UnitIsPlayer(unit) then
		return "";
	end
	
	local raceName, raceFile = UnitRace(unit);
	if not raceName then
		return "";
	end
	
	return raceName;
end);

-- Register {guild} token - shows unit guild name
-- {guild} - guild name (uses context.unit or defaults to "player")
-- {guild:unit} - guild name for specified unit
DataTokens:RegisterToken("guild", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or not UnitIsPlayer(unit) then
		return "";
	end
	
	local guildName = GetGuildInfo(unit);
	if not guildName then
		return "";
	end
	
	return guildName;
end);

-- Register {guildrank} token - shows unit guild rank
-- {guildrank} - guild rank (uses context.unit or defaults to "player")
-- {guildrank:unit} - guild rank for specified unit
DataTokens:RegisterToken("guildrank", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or not UnitIsPlayer(unit) then
		return "";
	end
	
	local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit);
	if not guildRankName then
		return "";
	end
	
	return guildRankName;
end);

-- Register {realm} token - shows unit realm name
-- {realm} - realm name (uses context.unit or defaults to "player")
-- {realm:unit} - realm name for specified unit
DataTokens:RegisterToken("realm", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local name, realm = UnitName(unit);
	if not realm or realm == "" then
		return "";
	end
	
	return realm;
end);

