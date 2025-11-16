local ADDON_NAME, ns = ...;

local TextTokens = ns.PersonalResourceTextTokens;
if not TextTokens then
	return;
end

-- Register {zone} token - shows current zone name
TextTokens:RegisterToken("zone", function(token, tokenLower, modifiers, context)
	local zoneName = GetZoneText();
	if zoneName and zoneName ~= "" then
		return zoneName;
	end
	return "";
end);

-- Register {fps} token - shows current FPS
TextTokens:RegisterToken("fps", function(token, tokenLower, modifiers, context)
	local fps = GetFramerate();
	if fps then
		-- Round to nearest integer
		local ok, rounded = pcall(function()
			return string.format("%.0f", fps);
		end);
		if ok and rounded then
			return rounded;
		end
		return tostring(fps);
	end
	return "";
end);

-- Register {latency} token - shows network latency
-- {latency} or {latency:local} - home latency (whole number, e.g., "45ms")
-- {latency:world} - world latency (whole number)
-- {latency:1f} or {latency:local:1f} - home latency with 1 decimal place (e.g., "45.2ms")
-- {latency:world:1f} - world latency with 1 decimal place
-- {latency:2f} - home latency with 2 decimal places
TextTokens:RegisterToken("latency", function(token, tokenLower, modifiers, context)
	local _, latencyHome, latencyWorld = GetNetStats();
	
	-- Determine which latency to use and format specifier
	local useWorld = false;
	local formatSpec = nil;
	local decimals = 0;
	
	if modifiers and modifiers ~= "" then
		local modifiersLower = string.lower(modifiers);
		
		-- Check for :world or :local
		if string.find(modifiersLower, "world") then
			useWorld = true;
		end
		-- :local is default, so no need to check for it explicitly
		
		-- Check for format specifier like :1f, :2f, etc.
		-- Can be combined: :world:1f or :1f:world or just :1f
		local formatMatch = string.match(modifiers, "(%d+)f");
		if formatMatch then
			decimals = tonumber(formatMatch);
			if decimals and decimals >= 0 and decimals <= 10 then
				formatSpec = "%." .. decimals .. "f";
			end
		end
	end
	
	-- Get the appropriate latency value
	local latency = nil;
	if useWorld then
		latency = latencyWorld;
	else
		latency = latencyHome;
	end
	
	-- Fallback to the other if the requested one is not available
	if not latency or latency == 0 then
		latency = latencyHome or latencyWorld or 0;
	end
	
	if latency then
		-- Format with decimal places if specified
		if formatSpec then
			local ok, formatted = pcall(function()
				return string.format(formatSpec, latency);
			end);
			if ok and formatted then
				return formatted .. "ms";
			end
		end
		-- Default: whole number
		return tostring(latency) .. "ms";
	end
	return "";
end);

-- Register {time} token - shows current game time
-- {time} - 24-hour format (HH:MM)
-- {time:12} - 12-hour format (HH:MM AM/PM)
TextTokens:RegisterToken("time", function(token, tokenLower, modifiers, context)
	local hour, minute = GetGameTime();
	if hour and minute then
		-- Check for :12 modifier for 12-hour format
		if modifiers and modifiers ~= "" then
			local modifiersLower = string.lower(modifiers);
			if modifiersLower == "12" then
				local ampm = "AM";
				local displayHour = hour;
				if hour == 0 then
					displayHour = 12;
				elseif hour == 12 then
					ampm = "PM";
				elseif hour > 12 then
					displayHour = hour - 12;
					ampm = "PM";
				end
				return string.format("%d:%02d %s", displayHour, minute, ampm);
			end
		end
		-- Default: 24-hour format
		return string.format("%02d:%02d", hour, minute);
	end
	return "";
end);

