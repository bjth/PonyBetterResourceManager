local ADDON_NAME, ns = ...;

-- Shared frame layout utilities
-- This module provides common frame layout logic used by all frame types
-- Functions here handle layout-related operations like scale, positioning, etc.

local FrameLayout = {};
ns.FrameLayout = FrameLayout;

-- Apply scale to a frame from database configuration
-- @param frame The frame to scale
-- @param db The database table containing the scale value (db.scale)
function FrameLayout:ApplyScale(frame, db)
	if not frame then
		return;
	end
	
	if db and db.scale then
		frame:SetScale(db.scale);
	end
end

return FrameLayout;

