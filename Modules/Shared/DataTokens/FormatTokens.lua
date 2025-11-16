local ADDON_NAME, ns = ...;

local DataTokens = ns.DataTokens;
if not DataTokens then
	return;
end

-- Register {color:xxxxxx} token - inserts color code
-- {color:ff0000} - red color
-- {color:00ff00} - green color
-- {color:0000ff} - blue color
-- Supports 6-digit hex codes (RRGGBB)
DataTokens:RegisterToken("color", function(token, tokenLower, modifiers, context)
	if not modifiers or modifiers == "" then
		return "";
	end
	
	-- Extract hex color code (should be 6 digits)
	local hexColor = string.match(modifiers, "^([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])");
	if hexColor then
		return "|cff" .. hexColor;
	end
	
	return "";
end);

-- Register {colorreset} token - resets color to default
-- {colorreset} - reset color
DataTokens:RegisterToken("colorreset", function(token, tokenLower, modifiers, context)
	return "|r";
end);

-- Register {n} token - newline
-- {n} - newline character
DataTokens:RegisterToken("n", function(token, tokenLower, modifiers, context)
	return "\n";
end);

-- Register {space} token - space character
-- {space} - single space
-- {space:N} - N spaces (e.g., {space:5} = 5 spaces)
DataTokens:RegisterToken("space", function(token, tokenLower, modifiers, context)
	if not modifiers or modifiers == "" then
		return " ";
	end
	
	-- Try to parse number of spaces
	local numSpaces = tonumber(modifiers);
	if numSpaces and numSpaces > 0 and numSpaces <= 100 then
		return string.rep(" ", numSpaces);
	end
	
	return " ";
end);

-- Register {tab} token - tab character
-- {tab} - single tab
-- {tab:N} - N tabs (e.g., {tab:2} = 2 tabs)
DataTokens:RegisterToken("tab", function(token, tokenLower, modifiers, context)
	if not modifiers or modifiers == "" then
		return "\t";
	end
	
	-- Try to parse number of tabs
	local numTabs = tonumber(modifiers);
	if numTabs and numTabs > 0 and numTabs <= 10 then
		return string.rep("\t", numTabs);
	end
	
	return "\t";
end);

