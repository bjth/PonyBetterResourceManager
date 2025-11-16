local ADDON_NAME, ns = ...;

local TextTokens = ns.PersonalResourceTextTokens;
if not TextTokens then
	return;
end

-- Register {mark} token - shows raid target marker icon
-- {mark} - shows marker on player
-- {mark:target} - shows marker on target
TextTokens:RegisterToken("mark", function(token, tokenLower, modifiers, context)
	-- Determine which unit to check based on modifiers
	local unit = "player"; -- Default to player
	if modifiers and modifiers ~= "" then
		local modifiersLower = string.lower(modifiers);
		if modifiersLower == "target" then
			unit = "target";
		end
		-- Could add more units later: focus, pet, etc.
	end
	
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

-- Register {combat} token - shows combat icon if player is in combat
TextTokens:RegisterToken("combat", function(token, tokenLower, modifiers, context)
	if UnitAffectingCombat("player") then
		-- Use combat icon texture (swords icon)
		return "|TInterface\\Icons\\Ability_DualWield:16:16|t";
	end
	return "";
end);

-- Register {resting} token - shows resting icon if player is resting
TextTokens:RegisterToken("resting", function(token, tokenLower, modifiers, context)
	if IsResting() then
		-- Use resting icon (Zzz icon)
		return "|TInterface\\CharacterFrame\\UI-StateIcon:16:16:0:0:64:64:0:32:0:32|t";
	end
	return "";
end);

-- Register {dead} token - shows dead icon if player is dead
TextTokens:RegisterToken("dead", function(token, tokenLower, modifiers, context)
	if UnitIsDead("player") then
		-- Use skull icon for dead
		return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16:16|t";
	end
	return "";
end);

-- Register {ghost} token - shows ghost icon if player is a ghost
TextTokens:RegisterToken("ghost", function(token, tokenLower, modifiers, context)
	if UnitIsGhost("player") then
		-- Use ghost icon
		return "|TInterface\\CharacterFrame\\UI-StateIcon:16:16:0:0:64:64:32:64:0:32|t";
	end
	return "";
end);

