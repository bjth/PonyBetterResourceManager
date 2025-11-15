local ADDON_NAME, ns = ...;

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

ns.Media = {
	LSM = LSM,
};

if not LSM then
	-- LibSharedMedia is optional but strongly recommended; fail softly.
	return;
end

-- Register a couple of simple defaults that rely on Blizzard textures/fonts,
-- so we don't need to ship custom media to get started.
LSM:Register(LSM.MediaType.STATUSBAR, "PBRM Default", "Interface\\TargetingFrame\\UI-StatusBar");
LSM:Register(LSM.MediaType.STATUSBAR, "PBRM Smooth", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill");


