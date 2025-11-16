local ADDON_NAME, ns = ...;

local Layout = {};
ns.PetResourceLayout = Layout;

-- Layout module is now a no-op - scale is handled by Blizzard's Edit Mode UI
function Layout:ApplyLayout(frame, db)
	-- No-op - scale is handled by Blizzard's Edit Mode
end

function Layout:OnEditModeExit(frame, db)
	-- No-op - scale is handled by Blizzard's Edit Mode
end

