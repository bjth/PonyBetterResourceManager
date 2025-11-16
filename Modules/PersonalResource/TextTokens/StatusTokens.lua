local ADDON_NAME, ns = ...;

local TextTokens = ns.PersonalResourceTextTokens;
if not TextTokens then
	return;
end

-- Register {incombat} token - shows text when in combat (alternative to {combat} icon)
TextTokens:RegisterToken("incombat", function(token, tokenLower, modifiers, context)
	if UnitAffectingCombat("player") then
		return "Combat";
	end
	return "";
end);

-- Register {group} token - shows group/raid size
TextTokens:RegisterToken("group", function(token, tokenLower, modifiers, context)
	if IsInRaid() then
		local numMembers = GetNumGroupMembers();
		return tostring(numMembers);
	elseif IsInGroup() then
		local numMembers = GetNumGroupMembers();
		return tostring(numMembers);
	end
	return "";
end);

-- Register {role} token - shows current role (Tank/Healer/DPS)
TextTokens:RegisterToken("role", function(token, tokenLower, modifiers, context)
	local role = UnitGroupRolesAssigned("player");
	if role == "TANK" then
		return "T";
	elseif role == "HEALER" then
		return "H";
	elseif role == "DAMAGER" then
		return "D";
	end
	return "";
end);

-- Register {pvp} token - shows PvP status
TextTokens:RegisterToken("pvp", function(token, tokenLower, modifiers, context)
	if UnitIsPVP("player") then
		return "PvP";
	end
	return "";
end);

