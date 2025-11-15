local ADDON_NAME, ns = ...;

local Layout = {};
ns.PersonalResourceLayout = Layout;

local function GetScale(db)
	if not db or not db.scale or db.scale <= 0 then
		return 1.0;
	end
	return db.scale;
end

-- Apply a safe scale modifier on top of Blizzard's Edit Mode configuration.
function Layout:ApplyLayout(frame, db)
	if not frame then
		return;
	end

	if not frame._PBRMBaseScale then
		frame._PBRMBaseScale = frame:GetScale() or 1.0;
	end

	local scale = GetScale(db);
	frame:SetScale(frame._PBRMBaseScale * scale);
end

-- When leaving Edit Mode, capture whatever scale Blizzard applied so we can
-- treat that as the new base scale and re-apply our modifier.
function Layout:OnEditModeExit(frame, db)
	if not frame then
		return;
	end

	local currentScale = frame:GetScale() or 1.0;
	local modifier = GetScale(db);

	if modifier <= 0 then
		modifier = 1.0;
	end

	frame._PBRMBaseScale = currentScale / modifier;
	self:ApplyLayout(frame, db);
end


