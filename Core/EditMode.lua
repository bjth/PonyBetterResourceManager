local ADDON_NAME, ns = ...;

local addon = ns.Addon;

local EditMode = {};
ns.EditMode = EditMode;

local initialized;

function EditMode:InitPersonalResourceSystem()
	if initialized then
		return;
	end
	initialized = true;

	-- Hook the Edit Mode system mixin so we can respond when the user exits Edit Mode.
	if type(EditModePersonalResourceDisplaySystemMixin) == "table" then
		hooksecurefunc(EditModePersonalResourceDisplaySystemMixin, "OnEditModeExit", function(systemFrame)
			local mod = addon and addon.GetModule and addon:GetModule("PersonalResource", true);
			if mod and mod.OnEditModeExit then
				mod:OnEditModeExit(systemFrame);
			end
		end);
	end
end


