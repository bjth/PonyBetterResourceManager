local ADDON_NAME, ns = ...;

local DataTokens = ns.DataTokens;
if not DataTokens then
	return;
end

-- Register {status} token - shows status text (Dead, Ghost, Offline, etc.)
-- {status} - status text (uses context.unit or defaults to "player")
-- {status:unit} - status text for specified unit
DataTokens:RegisterToken("status", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsDead(unit) then
		return "Dead";
	elseif UnitIsGhost(unit) then
		return "Ghost";
	elseif UnitIsAFK(unit) then
		return "AFK";
	elseif UnitIsDND(unit) then
		return "DND";
	elseif not UnitIsConnected(unit) then
		return "Offline";
	end
	
	return "";
end);

-- Register {incombat} token - shows text when in combat
-- {incombat} - combat status (uses context.unit or defaults to "player")
-- {incombat:unit} - combat status for specified unit
DataTokens:RegisterToken("incombat", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitAffectingCombat(unit) then
		return "Combat";
	end
	return "";
end);

-- Register {combat} token - shows combat status (text alternative to icon)
-- {combat} - combat status (uses context.unit or defaults to "player")
-- {combat:unit} - combat status for specified unit
DataTokens:RegisterToken("combat", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitAffectingCombat(unit) then
		return "Combat";
	end
	return "";
end);

-- Register {resting} token - shows resting status (text alternative to icon)
-- {resting} - resting status (uses context.unit or defaults to "player")
-- {resting:unit} - resting status for specified unit
DataTokens:RegisterToken("resting", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or unit ~= "player" then
		-- Resting only applies to player
		return "";
	end
	
	if IsResting() then
		return "Resting";
	end
	return "";
end);

-- Register {afk} token - shows AFK status
-- {afk} - AFK status (uses context.unit or defaults to "player")
-- {afk:unit} - AFK status for specified unit
DataTokens:RegisterToken("afk", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsAFK(unit) then
		return "AFK";
	end
	return "";
end);

-- Register {dnd} token - shows Do Not Disturb status
-- {dnd} - DND status (uses context.unit or defaults to "player")
-- {dnd:unit} - DND status for specified unit
DataTokens:RegisterToken("dnd", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsDND(unit) then
		return "DND";
	end
	return "";
end);

-- Register {leader} token - shows group leader indicator
-- {leader} - leader indicator (uses context.unit or defaults to "player")
-- {leader:unit} - leader indicator for specified unit
DataTokens:RegisterToken("leader", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsGroupLeader(unit) then
		return "Leader";
	end
	return "";
end);

-- Register {masterlooter} token - shows master looter indicator
-- {masterlooter} - master looter indicator (uses context.unit or defaults to "player")
-- {masterlooter:unit} - master looter indicator for specified unit
DataTokens:RegisterToken("masterlooter", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsGroupAssistant(unit) and GetLootMethod() == "master" then
		local masterLooter = GetMasterLootCandidate();
		if masterLooter and UnitIsUnit(unit, masterLooter) then
			return "ML";
		end
	end
	return "";
end);

-- Register {pvp} token - shows PvP status
-- {pvp} - PvP status (uses context.unit or defaults to "player")
-- {pvp:unit} - PvP status for specified unit
DataTokens:RegisterToken("pvp", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsPVP(unit) then
		return "PvP";
	end
	return "";
end);

-- Register {pvpicon} token - shows PvP icon texture
-- {pvpicon} - PvP icon (uses context.unit or defaults to "player")
-- {pvpicon:unit} - PvP icon for specified unit
DataTokens:RegisterToken("pvpicon", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsPVP(unit) then
		local factionGroup = UnitFactionGroup(unit);
		if factionGroup == "Horde" then
			return "|TInterface\\TargetingFrame\\UI-PVP-Horde:16:16|t";
		elseif factionGroup == "Alliance" then
			return "|TInterface\\TargetingFrame\\UI-PVP-Alliance:16:16|t";
		end
	end
	return "";
end);

-- Register {rested} token - shows rested XP indicator
-- {rested} - rested status (uses context.unit or defaults to "player")
-- {rested:unit} - rested status for specified unit
DataTokens:RegisterToken("rested", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) or unit ~= "player" then
		-- Rested only applies to player
		return "";
	end
	
	local restedXP = GetXPExhaustion();
	if restedXP and restedXP > 0 then
		return "Rested";
	end
	return "";
end);

-- Register {threat} token - shows threat percentage
-- {threat} - threat % (uses context.unit or defaults to "player")
-- {threat:unit} - threat % for specified unit
DataTokens:RegisterToken("threat", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	-- Threat only works for target/focus
	if unit ~= "target" and unit ~= "focus" then
		return "";
	end
	
	local status = UnitThreatSituation("player", unit);
	if status and status > 0 then
		-- status is 0-3 (0 = no threat, 1-3 = increasing threat)
		-- Get threat percentage if available
		local isTanking, status, threatPercent = UnitDetailedThreatSituation("player", unit);
		if threatPercent then
			local ok, formatted = pcall(function()
				return string.format("%.0f", threatPercent);
			end);
			if ok and formatted then
				return formatted .. "%";
			end
		end
	end
	return "";
end);

-- Register {aggro} token - shows aggro indicator
-- {aggro} - aggro indicator (uses context.unit or defaults to "player")
-- {aggro:unit} - aggro indicator for specified unit
DataTokens:RegisterToken("aggro", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	-- Aggro only works for target/focus
	if unit ~= "target" and unit ~= "focus" then
		return "";
	end
	
	local status = UnitThreatSituation("player", unit);
	if status and status >= 3 then
		return "Aggro";
	elseif status and status >= 2 then
		return "High";
	elseif status and status >= 1 then
		return "Gaining";
	end
	return "";
end);

-- Register {range} token - shows range indicator
-- {range} - range indicator (uses context.unit or defaults to "player")
-- {range:unit} - range indicator for specified unit
DataTokens:RegisterToken("range", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	-- Check if unit is in range (within 40 yards for most spells)
	local inRange = CheckInteractDistance(unit, 4); -- 4 = 40 yards
	if inRange then
		return "In Range";
	end
	return "";
end);

-- Register {distance} token - shows distance to unit
-- {distance} - distance (uses context.unit or defaults to "player")
-- {distance:unit} - distance to specified unit
DataTokens:RegisterToken("distance", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	-- Try to get distance using CheckInteractDistance
	-- This is approximate but works for most cases
	local distance = nil;
	if CheckInteractDistance(unit, 1) then -- 1 = 3.2 yards
		distance = "3";
	elseif CheckInteractDistance(unit, 2) then -- 2 = 11.11 yards
		distance = "11";
	elseif CheckInteractDistance(unit, 3) then -- 3 = 29.9 yards
		distance = "30";
	elseif CheckInteractDistance(unit, 4) then -- 4 = 40 yards
		distance = "40";
	else
		distance = "40+";
	end
	
	return distance .. "y";
end);

-- Register {group} token - shows group/raid size or unit's group number
-- {group} - group size (uses context.unit or defaults to "player")
-- {group:unit} - group number for specified unit in raid
DataTokens:RegisterToken("group", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	-- If unit is player, show group size
	if unit == "player" then
		if IsInRaid() then
			local numMembers = GetNumGroupMembers();
			return tostring(numMembers);
		elseif IsInGroup() then
			local numMembers = GetNumGroupMembers();
			return tostring(numMembers);
		end
		return "";
	end
	
	-- For other units, show their group number in raid
	if IsInRaid() and UnitInRaid(unit) then
		local name = UnitName(unit);
		if name then
			for i = 1, GetNumGroupMembers() do
				local raidName = GetRaidRosterInfo(i);
				if raidName == name then
					local _, _, subgroup = GetRaidRosterInfo(i);
					if subgroup then
						return tostring(subgroup);
					end
				end
			end
		end
	end
	
	return "";
end);

-- Register {subgroup} token - shows subgroup number
-- {subgroup} - subgroup number (uses context.unit or defaults to "player")
-- {subgroup:unit} - subgroup number for specified unit
DataTokens:RegisterToken("subgroup", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if IsInRaid() and UnitInRaid(unit) then
		local name = UnitName(unit);
		if name then
			for i = 1, GetNumGroupMembers() do
				local raidName = GetRaidRosterInfo(i);
				if raidName == name then
					local _, _, subgroup = GetRaidRosterInfo(i);
					if subgroup then
						return tostring(subgroup);
					end
				end
			end
		end
	end
	
	return "";
end);

-- Register {role} token - shows current role (Tank/Healer/DPS)
-- {role} - role (uses context.unit or defaults to "player")
-- {role:unit} - role for specified unit
DataTokens:RegisterToken("role", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local role = UnitGroupRolesAssigned(unit);
	if role == "TANK" then
		return "T";
	elseif role == "HEALER" then
		return "H";
	elseif role == "DAMAGER" then
		return "D";
	end
	return "";
end);

-- Register {roleicon} token - shows role icon texture
-- {roleicon} - role icon (uses context.unit or defaults to "player")
-- {roleicon:unit} - role icon for specified unit
DataTokens:RegisterToken("roleicon", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local role = UnitGroupRolesAssigned(unit);
	if role == "TANK" then
		return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t";
	elseif role == "HEALER" then
		return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t";
	elseif role == "DAMAGER" then
		return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t";
	end
	return "";
end);

-- Register {readycheck} token - shows ready check status
-- {readycheck} - ready check status (uses context.unit or defaults to "player")
-- {readycheck:unit} - ready check status for specified unit
DataTokens:RegisterToken("readycheck", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	local readyCheckStatus = GetReadyCheckStatus(unit);
	if readyCheckStatus == "ready" then
		return "Ready";
	elseif readyCheckStatus == "notready" then
		return "Not Ready";
	elseif readyCheckStatus == "waiting" then
		return "Waiting";
	end
	return "";
end);

-- Register {tapped} token - shows if unit is tapped by other player
-- {tapped} - tapped status (uses context.unit or defaults to "player")
-- {tapped:unit} - tapped status for specified unit
DataTokens:RegisterToken("tapped", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		return "Tapped";
	end
	return "";
end);

-- Register {tappedbyme} token - shows if unit is tapped by me
-- {tappedbyme} - tapped by me status (uses context.unit or defaults to "player")
-- {tappedbyme:unit} - tapped by me status for specified unit
DataTokens:RegisterToken("tappedbyme", function(token, tokenLower, modifiers, context)
	local unit = DataTokens:GetUnit(context);
	
	if not UnitExists(unit) then
		return "";
	end
	
	if UnitIsTappedByPlayer(unit) then
		return "Tapped";
	end
	return "";
end);

