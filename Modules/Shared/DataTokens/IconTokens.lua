local ADDON_NAME, ns = ...;

local DataTokens = ns.DataTokens;
if not DataTokens then
	return;
end

-- Register {mark} token - shows raid target marker icon
-- {mark} - shows marker (uses context.unit or defaults to "player")
-- {mark:unit} - shows marker on specified unit
DataTokens:RegisterToken("mark", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	-- Check if unit exists (for target, focus, etc.)
	if unit ~= "player" and not UnitExists(unit) then
		return "";
	end
	
	-- GetRaidTargetIndex returns a SECRET VALUE in Midnight - use it directly in string concatenation
	local markIndex = GetRaidTargetIndex(unit);
	
	-- Use the secret value directly in string concatenation (this works with secret values)
	if markIndex then
		local texturePath = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. markIndex;
		-- Return texture format - size 16x16 (will scale with font)
		return "|T" .. texturePath .. ":16:16|t";
	end
	
	return "";
end);

-- Register {combat} token - shows combat icon
-- {combat} - combat icon (uses context.unit or defaults to "player")
-- {combat:unit} - combat icon for specified unit
DataTokens:RegisterToken("combat", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitAffectingCombat(unit) then
		-- Use combat icon texture (swords icon)
		return "|TInterface\\Icons\\Ability_DualWield:16:16|t";
	end
	return "";
end);

-- Register {resting} token - shows resting icon
-- {resting} - resting icon (uses context.unit or defaults to "player")
-- {resting:unit} - resting icon for specified unit (only works for player)
DataTokens:RegisterToken("resting", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or unit ~= "player" then
		-- Resting only applies to player
		return "";
	end
	
	if IsResting() then
		-- Use resting icon (Zzz icon)
		return "|TInterface\\CharacterFrame\\UI-StateIcon:16:16:0:0:64:64:0:32:0:32|t";
	end
	return "";
end);

-- Register {dead} token - shows dead icon
-- {dead} - dead icon (uses context.unit or defaults to "player")
-- {dead:unit} - dead icon for specified unit
DataTokens:RegisterToken("dead", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsDead(unit) then
		-- Use skull icon for dead
		return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t";
	end
	return "";
end);

-- Register {ghost} token - shows ghost icon
-- {ghost} - ghost icon (uses context.unit or defaults to "player")
-- {ghost:unit} - ghost icon for specified unit
DataTokens:RegisterToken("ghost", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsGhost(unit) then
		-- Use ghost icon
		return "|TInterface\\CharacterFrame\\UI-StateIcon:16:16:0:0:64:64:32:64:0:32|t";
	end
	return "";
end);

-- Register {offline} token - shows offline icon
-- {offline} - offline icon (uses context.unit or defaults to "player")
-- {offline:unit} - offline icon for specified unit
DataTokens:RegisterToken("offline", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if not UnitIsConnected(unit) then
		-- Use offline icon (red X or similar)
		return "|TInterface\\CharacterFrame\\DisconnectIcon:16:16|t";
	end
	return "";
end);

-- Register {classicon} token - shows class icon
-- {classicon} - class icon (uses context.unit or defaults to "player")
-- {classicon:unit} - class icon for specified unit
DataTokens:RegisterToken("classicon", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or not UnitIsPlayer(unit) then
		return "";
	end
	
	local className, classFile = UnitClass(unit);
	if not classFile then
		return "";
	end
	
	-- Use class icon texture
	local texturePath = "Interface\\TargetingFrame\\ClassIcon-" .. classFile;
	return "|T" .. texturePath .. ":16:16|t";
end);

-- Register {specicon} token - shows specialization icon
-- {specicon} - spec icon (uses context.unit or defaults to "player")
-- {specicon:unit} - spec icon for specified unit
DataTokens:RegisterToken("specicon", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or not UnitIsPlayer(unit) then
		return "";
	end
	
	-- Get specialization icon
	local specID = GetSpecializationInfo(GetSpecialization());
	if specID then
		local _, _, _, icon = GetSpecializationInfoByID(specID);
		if icon then
			return "|T" .. icon .. ":16:16|t";
		end
	end
	
	return "";
end);

