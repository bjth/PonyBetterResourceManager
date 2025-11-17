local ADDON_NAME, ns = ...;

local addon = ns.Addon;

local ProfileOptions = {};
ns.ProfileOptions = ProfileOptions;

-- Cache for current profile name (for dynamic description)
local currentProfileCache = nil;

-- Helper function to update current profile cache
local function UpdateCurrentProfileCache()
	if addon.db then
		currentProfileCache = addon.db:GetCurrentProfile();
	end
end

-- Register for profile change events (Options files load after Core, so db should be ready)
-- But we'll register in BuildOptions to be safe
local callbackRegistered = false;

-- Helper functions
local function GetDB()
	return addon.db and addon.db.profile;
end

local function Get()
	local info = GetDB();
	if not info then return nil; end
	return info[info.arg];
end

local function Set(info, value)
	local db = GetDB();
	if db then
		db[info.arg] = value;
		if addon.NotifyConfigChanged then
			addon:NotifyConfigChanged();
		end
	end
end

function ProfileOptions:BuildOptions()
	-- Register callback if not already registered and db is ready
	if not callbackRegistered and addon and addon.db then
		addon.db.RegisterCallback(ProfileOptions, "OnProfileChanged", function(db, profileName)
			UpdateCurrentProfileCache();
			-- Refresh the UI
			if addon.NotifyConfigChanged then
				addon:NotifyConfigChanged();
			end
		end);
		UpdateCurrentProfileCache();
		callbackRegistered = true;
	end
	
	local args = {
		loadPUFProfile = {
			type = "execute",
			name = "Load PUF Profile",
			desc = "Switch to the PUF (Pony Unit Frames) profile, which mirrors the default Shadowed Unit Frames appearance.",
			func = function()
				if not addon.db then
					addon:Print("Database not initialized. Cannot load PUF profile.");
					return;
				end
				
				-- Check if PUF profile exists
				local profiles = addon.db:GetProfiles();
				local pufExists = false;
				for _, profileName in ipairs(profiles) do
					if profileName == "PUF" then
						pufExists = true;
						break;
					end
				end
				
				if not pufExists then
					-- Create PUF profile if it doesn't exist
					if ns.PUFDefaults and ns.PUFDefaults.GetSUFDefaults then
						-- Get SUF defaults
						local sufDefaults = ns.PUFDefaults:GetSUFDefaults();
						
						-- Create PUF profile by switching to it
						addon.db:SetProfile("PUF");
						
						-- Reset the profile first to clear any default values (suppress callbacks during reset)
						addon.db:ResetProfile(nil, true);
						
						-- Deep copy SUF defaults into the PUF profile (overwrites any defaults from ResetProfile)
						local DeepCopy = ns.PUFDefaults.DeepCopy;
						if DeepCopy then
							-- Copy each top-level key from SUF defaults to current profile
							for key, value in pairs(sufDefaults) do
								if type(value) == "table" then
									addon.db.profile[key] = DeepCopy(value);
								else
									addon.db.profile[key] = value;
								end
							end
						end
						
						-- Update cache
						UpdateCurrentProfileCache();
						
						-- Notify config changed (callbacks were suppressed during reset)
						if addon.NotifyConfigChanged then
							addon:NotifyConfigChanged();
						end
						
						addon:Print("PUF profile created and loaded successfully!");
					else
						addon:Print("PUF defaults not available. Cannot create PUF profile.");
					end
				else
					-- Switch to existing PUF profile and reset it to apply fresh defaults
					local currentProfile = addon.db:GetCurrentProfile();
					if currentProfile ~= "PUF" then
						addon.db:SetProfile("PUF");
					end
					
					-- Reset and reapply defaults to ensure they're correct
					if ns.PUFDefaults and ns.PUFDefaults.GetSUFDefaults then
						local sufDefaults = ns.PUFDefaults:GetSUFDefaults();
						
						-- Reset profile (suppress callbacks during reset)
						addon.db:ResetProfile(nil, true);
						
						-- Deep copy SUF defaults into the PUF profile (overwrites any defaults from ResetProfile)
						local DeepCopy = ns.PUFDefaults.DeepCopy;
						if DeepCopy then
							-- Copy each top-level key from SUF defaults to current profile
							for key, value in pairs(sufDefaults) do
								if type(value) == "table" then
									addon.db.profile[key] = DeepCopy(value);
								else
									addon.db.profile[key] = value;
								end
							end
						end
					end
					
					-- Update cache
					UpdateCurrentProfileCache();
					
					-- Notify config changed (callbacks were suppressed during reset)
					if addon.NotifyConfigChanged then
						addon:NotifyConfigChanged();
					end
					
					addon:Print("PUF profile loaded and defaults applied.");
				end
			end,
			order = 1,
		},
		currentProfile = {
			type = "description",
			name = function()
				UpdateCurrentProfileCache();
				local profile = currentProfileCache or (addon.db and addon.db:GetCurrentProfile()) or "Unknown";
				return "Current Profile: |cff00ff00" .. profile .. "|r";
			end,
			order = 2,
		},
		spacer = {
			type = "description",
			name = " ",
			order = 3,
		},
		note = {
			type = "description",
			name = "Note: Use the 'Profiles' panel in the Blizzard Interface Options to manage profiles (create, copy, delete, rename).",
			fontSize = "medium",
			order = 4,
		},
	};
	
	return {
		type = "group",
		name = "Profiles",
		get = Get,
		set = Set,
		args = args,
	};
end

-- Register this option group
if ns.Options then
	ns.Options:RegisterOptionGroup("profiles", "Profiles", 0, function() return ProfileOptions:BuildOptions(); end);
end

