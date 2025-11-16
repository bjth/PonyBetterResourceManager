local ADDON_NAME, ns = ...;

-- Shared bar styling utilities
-- This module provides common bar styling logic used by all frame types
-- Each frame type can have its own database values, but the styling logic is shared

local BarStyling = {};
ns.BarStyling = BarStyling;

local LSM = ns.Media and ns.Media.LSM;
local PowerColor = ns.PowerColor;

-- Get status bar texture from LibSharedMedia
local function GetStatusBarTexture(key)
	if not LSM then
		return nil;
	end

	if not key or key == "" then
		key = "Blizzard";
	end

	return LSM:Fetch("statusbar", key);
end

-- Apply visual styling to a status bar (texture and optional color override)
function BarStyling:ApplyBarVisuals(statusBar, textureKey, colorConfig, overrideColor)
	if not statusBar then
		return;
	end

	local texture = GetStatusBarTexture(textureKey);
	if texture then
		statusBar:SetStatusBarTexture(texture);
	end

	-- For Midnight, match Blizzard's usage: only pass plain RGB(A) numbers when we actively override.
	if overrideColor and colorConfig then
		local r = colorConfig.r or 1;
		local g = colorConfig.g or 1;
		local b = colorConfig.b or 1;
		local a = colorConfig.a;

		if a ~= nil then
			statusBar:SetStatusBarColor(r, g, b, a);
		else
			statusBar:SetStatusBarColor(r, g, b);
		end
	end
end

-- Round to nearest pixel for pixel-perfect alignment
local function RoundToPixel(value)
	return math.floor(value + 0.5);
end

-- Get pixel-perfect position accounting for frame scale and actual position
-- This ensures borders align to integer pixel boundaries even when frames are scaled or at non-integer positions
local function GetPixelPerfectPosition(frame, offset)
	if not frame then
		return RoundToPixel(offset);
	end
	
	local scale = frame:GetEffectiveScale();
	if scale and scale > 0 then
		-- Get the frame's actual screen position to account for non-integer frame positions
		local left, bottom = frame:GetLeft(), frame:GetBottom();
		if left and bottom then
			-- Convert frame position and offset to screen pixels
			local screenLeft = left * scale;
			local screenBottom = bottom * scale;
			local screenOffset = offset * scale;
			
			-- Round the combined position to nearest pixel
			local roundedScreenPos = RoundToPixel(screenLeft + screenOffset);
			
			-- Convert back to frame-relative coordinates
			return (roundedScreenPos - screenLeft) / scale;
		else
			-- Fallback: just round the offset
			local screenPixels = offset * scale;
			local roundedPixels = RoundToPixel(screenPixels);
			return roundedPixels / scale;
		end
	end
	
	return RoundToPixel(offset);
end

-- Apply border settings to a border frame
local function ApplyBorderSettings(border, style, color, size)
	if not border then
		return;
	end

	if style == "None" then
		border:Hide();
		return;
	end

	border:Show();

	if color then
		border:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1);
		border:SetAlpha(color.a or 1);
	end

	if size and size > 0 then
		-- Round scale to nearest 0.05 for pixel-perfect alignment
		-- This ensures borders align to pixel boundaries
		local roundedScale = math.floor((size * 20) + 0.5) / 20;
		border:SetScale(roundedScale);
	end
end

-- Cache original anchor points for a frame
-- This allows us to restore Blizzard's original positioning when needed
function BarStyling:CacheOriginalPoints(frame)
	if not frame then
		return;
	end
	
	if not frame._PBRMOriginalPoints then
		frame._PBRMOriginalPoints = {};
		for i = 1, frame:GetNumPoints() do
			local p, relTo, relPoint, x, y = frame:GetPoint(i);
			table.insert(frame._PBRMOriginalPoints, { p, relTo, relPoint, x, y });
		end
	end
end

-- Restore original anchor points
function BarStyling:RestoreOriginalPoints(frame)
	if not frame or not frame._PBRMOriginalPoints then
		return;
	end
	
	frame:ClearAllPoints();
	for _, pt in ipairs(frame._PBRMOriginalPoints) do
		frame:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]);
	end
end

-- Apply size overrides and update anchors for a container frame
-- frame: the container frame to modify
-- parentFrame: the parent frame to anchor to (usually the PRD frame)
-- width: override width (0 or nil = no override)
-- height: override height (0 or nil = no override)
-- This handles width/height overrides by breaking left/right anchors and anchoring by TOP
-- when width is set, while preserving original anchors for height-only overrides
function BarStyling:ApplySizeAndAnchors(frame, parentFrame, width, height)
	if not frame then
		return;
	end
	
	-- Ensure original points are cached
	if not frame._PBRMOriginalPoints then
		self:CacheOriginalPoints(frame);
	end
	
	-- Optional explicit sizing on top of Blizzard's layout.
	-- To make width adjustable, we need to break the left/right anchors and anchor
	-- the container by TOP relative to the parent frame while keeping Edit Mode's
	-- position on the parent frame.
	if width and width > 0 then
		frame:ClearAllPoints();
		-- Anchor by TOP only, then set explicit width
		-- This breaks the LEFT/RIGHT stretch anchors but allows explicit width control
		-- The frame will be positioned at the top center of the parent by default
		frame:SetPoint("TOP", parentFrame or frame:GetParent(), "TOP", 0, 0);
		-- Set width first, then verify it was applied
		frame:SetWidth(width);
		-- Force a layout update to ensure width is applied
		frame:SetSize(width, frame:GetHeight() or (height or 0));
		if height and height > 0 then
			frame:SetHeight(height);
		end
	elseif height and height > 0 and frame._PBRMOriginalPoints then
		-- Only height override: preserve original anchors, just change height.
		frame:ClearAllPoints();
		for _, pt in ipairs(frame._PBRMOriginalPoints) do
			frame:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]);
		end
		frame:SetHeight(height);
	elseif frame._PBRMOriginalPoints then
		-- No overrides: restore Blizzard's original anchors and size.
		frame:ClearAllPoints();
		for _, pt in ipairs(frame._PBRMOriginalPoints) do
			frame:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]);
		end
	end
end

-- Apply offset to a frame
-- offsetX: horizontal offset (can be 0)
-- offsetY: vertical offset (can be 0)
-- originalPoints: cached original anchor points
function BarStyling:ApplyOffset(frame, offsetX, offsetY, originalPoints)
	if not frame then
		return;
	end
	
	-- Always apply offset, even if it's 0, to ensure frame is positioned correctly
	-- Use 0 as default if nil
	offsetX = offsetX or 0;
	offsetY = offsetY or 0;
	
	-- Cache original points if not already cached
	if originalPoints and not frame._PBRMOriginalPoints then
		frame._PBRMOriginalPoints = originalPoints;
	end
	
	if frame._PBRMOriginalPoints then
		frame:ClearAllPoints();
		local ox = offsetX or 0;
		local oy = offsetY or 0;
		for _, pt in ipairs(frame._PBRMOriginalPoints) do
			local p, relTo, relPoint, x, y = pt[1], pt[2], pt[3], pt[4] or 0, pt[5] or 0;
			frame:SetPoint(p, relTo, relPoint, x + ox, y + oy);
		end
	end
end

-- Apply health bar styling
-- frame: the frame containing the health bar
-- healthBar: the actual health bar status bar
-- container: the container frame (if different from healthBar)
-- db: database profile (can be personalResource, targetResource, etc.)
-- unit: unit ID (e.g., "player", "target")
function BarStyling:ApplyHealthBarStyle(frame, healthBar, container, db, unit)
	if not frame or not healthBar or not db then
		return;
	end
	
	container = container or healthBar;
	unit = unit or "player";
	
	-- Cache original points
	self:CacheOriginalPoints(container);
	
	-- Border alpha is now handled per-border via border color alpha
	
	-- Apply texture and optional override color
	self:ApplyBarVisuals(healthBar, db.healthTexture, db.healthColor, db.overrideHealthColor);
	
	-- If not overriding, restore Blizzard's default health color
	if not db.overrideHealthColor then
		healthBar:SetStatusBarColor(0.0, 0.8, 0.0);
	end
	
	-- Border styling for the health container
	if container.border then
		-- For health container borders, we need to create custom border textures
		-- similar to power bars for better pixel control
		if db.healthBorderStyle == "None" then
			container.border:Hide();
			if container._PBRMBorderTop then
				container._PBRMBorderTop:Hide();
				container._PBRMBorderBottom:Hide();
				container._PBRMBorderLeft:Hide();
				container._PBRMBorderRight:Hide();
			end
		else
			container.border:Hide();
			
			local color = db.healthBorderColor or { r = 0, g = 0, b = 0, a = 1.0 };
			-- Ensure alpha is set (use from color if present, otherwise default to 1.0)
			if not color.a then
				color.a = 1.0;
			end
			-- Calculate thickness accounting for frame scale for pixel-perfect alignment
			local baseThickness = (db.healthBorderSize or 1) * 2;
			local scale = container:GetEffectiveScale() or 1;
			-- Convert to screen pixels, round to nearest integer, then convert back
			local screenPixels = baseThickness * scale;
			local roundedPixels = RoundToPixel(screenPixels);
			local thickness = roundedPixels / scale;
			-- Ensure minimum thickness
			if thickness < 0.5 then
				thickness = 0.5;
			end
			
			if not container._PBRMBorderTop then
				container._PBRMBorderTop = container:CreateTexture(nil, "OVERLAY");
				container._PBRMBorderBottom = container:CreateTexture(nil, "OVERLAY");
				container._PBRMBorderLeft = container:CreateTexture(nil, "OVERLAY");
				container._PBRMBorderRight = container:CreateTexture(nil, "OVERLAY");
			end
			
			-- Top edge - use pixel-perfect offsets
			container._PBRMBorderTop:ClearAllPoints();
			local topLeftX = GetPixelPerfectPosition(container, 0);
			local topLeftY = GetPixelPerfectPosition(container, 0);
			local topRightX = GetPixelPerfectPosition(container, 0);
			local topRightY = GetPixelPerfectPosition(container, 0);
			container._PBRMBorderTop:SetPoint("BOTTOMLEFT", container, "TOPLEFT", topLeftX, topLeftY);
			container._PBRMBorderTop:SetPoint("BOTTOMRIGHT", container, "TOPRIGHT", topRightX, topRightY);
			container._PBRMBorderTop:SetHeight(thickness);
			
			-- Bottom edge - use pixel-perfect offsets
			container._PBRMBorderBottom:ClearAllPoints();
			local bottomLeftX = GetPixelPerfectPosition(container, 0);
			local bottomLeftY = GetPixelPerfectPosition(container, 0);
			local bottomRightX = GetPixelPerfectPosition(container, 0);
			local bottomRightY = GetPixelPerfectPosition(container, 0);
			container._PBRMBorderBottom:SetPoint("TOPLEFT", container, "BOTTOMLEFT", bottomLeftX, bottomLeftY);
			container._PBRMBorderBottom:SetPoint("TOPRIGHT", container, "BOTTOMRIGHT", bottomRightX, bottomRightY);
			container._PBRMBorderBottom:SetHeight(thickness);
			
			-- Left edge - use pixel-perfect offsets
			container._PBRMBorderLeft:ClearAllPoints();
			local leftTopX = GetPixelPerfectPosition(container._PBRMBorderTop, 0);
			local leftTopY = GetPixelPerfectPosition(container._PBRMBorderTop, 0);
			local leftBottomX = GetPixelPerfectPosition(container._PBRMBorderBottom, 0);
			local leftBottomY = GetPixelPerfectPosition(container._PBRMBorderBottom, 0);
			container._PBRMBorderLeft:SetPoint("TOPRIGHT", container._PBRMBorderTop, "TOPLEFT", leftTopX, leftTopY);
			container._PBRMBorderLeft:SetPoint("BOTTOMRIGHT", container._PBRMBorderBottom, "BOTTOMLEFT", leftBottomX, leftBottomY);
			container._PBRMBorderLeft:SetWidth(thickness);
			
			-- Right edge - use pixel-perfect offsets
			container._PBRMBorderRight:ClearAllPoints();
			local rightTopX = GetPixelPerfectPosition(container._PBRMBorderTop, 0);
			local rightTopY = GetPixelPerfectPosition(container._PBRMBorderTop, 0);
			local rightBottomX = GetPixelPerfectPosition(container._PBRMBorderBottom, 0);
			local rightBottomY = GetPixelPerfectPosition(container._PBRMBorderBottom, 0);
			container._PBRMBorderRight:SetPoint("TOPLEFT", container._PBRMBorderTop, "TOPRIGHT", rightTopX, rightTopY);
			container._PBRMBorderRight:SetPoint("BOTTOMLEFT", container._PBRMBorderBottom, "BOTTOMRIGHT", rightBottomX, rightBottomY);
			container._PBRMBorderRight:SetWidth(thickness);
			
			local r = color.r or 0;
			local g = color.g or 0;
			local b = color.b or 0;
			local a = color.a or 1;
			
			container._PBRMBorderTop:SetColorTexture(r, g, b, a);
			container._PBRMBorderBottom:SetColorTexture(r, g, b, a);
			container._PBRMBorderLeft:SetColorTexture(r, g, b, a);
			container._PBRMBorderRight:SetColorTexture(r, g, b, a);
			
			container._PBRMBorderTop:Show();
			container._PBRMBorderBottom:Show();
			container._PBRMBorderLeft:Show();
			container._PBRMBorderRight:Show();
		end
	end
	
	-- Apply background
	if db.healthBarBackground and db.healthBarBackground.enabled then
		if not healthBar._PBRMBackground then
			healthBar._PBRMBackground = healthBar:CreateTexture(nil, "BACKGROUND");
			healthBar._PBRMBackground:SetAllPoints(healthBar);
		end
		
		local bgTexture = GetStatusBarTexture(db.healthBarBackground.texture);
		if bgTexture then
			healthBar._PBRMBackground:SetTexture(bgTexture);
		end
		
		local bgColor = db.healthBarBackground.color;
		if bgColor then
			healthBar._PBRMBackground:SetVertexColor(bgColor.r or 0, bgColor.g or 0, bgColor.b or 0, bgColor.a or 0.5);
		end
		
		healthBar._PBRMBackground:Show();
	else
		if healthBar._PBRMBackground then
			healthBar._PBRMBackground:Hide();
		end
	end
	
	-- Apply size overrides and update anchors
	local hasWidthOverride = db.healthWidth and db.healthWidth > 0;
	self:ApplySizeAndAnchors(container, frame, db.healthWidth, db.healthHeight);
	
	-- Apply offsets
	-- Offsets should produce the same visual distance regardless of frame scale
	-- So we store them at 1.0 scale and convert to current frame scale
	-- This ensures -3 on a 0.5 scale frame matches -1 on a 1.0 scale frame visually
	-- IMPORTANT: Only apply offsets if we haven't overridden width, as width override
	-- breaks the original anchors that ApplyOffset relies on
	if not hasWidthOverride then
		local frameScale = container:GetEffectiveScale() or 1;
		local baseScale = 1.0;
		-- Convert offset from base scale (1.0) to current frame scale
		-- If frame is at 0.5 scale, multiply offset by 0.5 to get same visual distance
		local offsetX = (db.healthOffsetX or 0) * (frameScale / baseScale);
		local offsetY = (db.healthOffsetY or 0) * (frameScale / baseScale);
		self:ApplyOffset(container, offsetX, offsetY, container._PBRMOriginalPoints);
	else
		-- When width is overridden, apply offsets directly to the TOP anchor
		local frameScale = container:GetEffectiveScale() or 1;
		local baseScale = 1.0;
		local offsetX = (db.healthOffsetX or 0) * (frameScale / baseScale);
		local offsetY = (db.healthOffsetY or 0) * (frameScale / baseScale);
		-- Get current TOP anchor and apply offsets
		local point, relativeTo, relativePoint, xOfs, yOfs = container:GetPoint(1);
		if point then
			container:SetPoint(point, relativeTo or frame, relativePoint or point, (xOfs or 0) + offsetX, (yOfs or 0) + offsetY);
		end
	end
	
	-- Ensure healthbar fills the container after resizing and offsets
	-- This is critical for Personal Resource where the healthbar is anchored with TOPLEFT/BOTTOMRIGHT
	-- in Blizzard's XML, but we need to ensure it fills the container after we resize it
	-- Do this AFTER offsets so the healthbar fills the final container position
	-- Always re-anchor to ensure it fills the container, especially after width changes
	if healthBar and container ~= healthBar then
		healthBar:ClearAllPoints();
		healthBar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0);
		healthBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0);
	end
	
	-- Show/hide logic
	if db.showHealthBar == false then
		container:Hide();
	else
		-- Only show if Blizzard isn't intentionally hiding health/power
		if not frame.hideHealthAndPower then
			container:Show();
		end
	end
end

-- Apply power bar styling
-- frame: the frame containing the power bar
-- powerBar: the actual power bar status bar
-- db: database profile (can be personalResource, targetResource, etc.)
-- unit: unit ID (e.g., "player", "target")
function BarStyling:ApplyPowerBarStyle(frame, powerBar, db, unit)
	if not frame or not powerBar or not db then
		return;
	end
	
	unit = unit or "player";
	
	-- Cache original points
	self:CacheOriginalPoints(powerBar);
	
	-- Apply texture (no color override - power type colors are handled separately)
	self:ApplyBarVisuals(powerBar, db.powerTexture, nil, false);
	
	-- Apply power color using shared utility (always use power type colors)
	-- This ensures power color is applied whenever the bar style is updated
	if PowerColor then
		PowerColor:ApplyPowerColor(powerBar, unit, db, false);
	end
	
	-- Apply background
	if db.powerBarBackground and db.powerBarBackground.enabled then
		if not powerBar._PBRMBackground then
			powerBar._PBRMBackground = powerBar:CreateTexture(nil, "BACKGROUND");
			powerBar._PBRMBackground:SetAllPoints(powerBar);
		end
		
		local bgTexture = GetStatusBarTexture(db.powerBarBackground.texture);
		if bgTexture then
			powerBar._PBRMBackground:SetTexture(bgTexture);
		end
		
		local bgColor = db.powerBarBackground.color;
		if bgColor then
			powerBar._PBRMBackground:SetVertexColor(bgColor.r or 0, bgColor.g or 0, bgColor.b or 0, bgColor.a or 0.5);
		end
		
		powerBar._PBRMBackground:Show();
	else
		if powerBar._PBRMBackground then
			powerBar._PBRMBackground:Hide();
		end
	end
	
	-- Border styling for the power bar
	if powerBar.Border then
		-- Blizzard's border atlas isn't reliably tintable in Midnight. Hide it and draw a simple
		-- rectangular border that we fully control.
		if db.powerBorderStyle == "None" then
			powerBar.Border:Hide();
			if powerBar._PBRMBorderTop then
				powerBar._PBRMBorderTop:Hide();
				powerBar._PBRMBorderBottom:Hide();
				powerBar._PBRMBorderLeft:Hide();
				powerBar._PBRMBorderRight:Hide();
			end
		else
			powerBar.Border:Hide();

			local color = db.powerBorderColor or { r = 0, g = 0, b = 0, a = 1.0 };
			-- Ensure alpha is set (use from color if present, otherwise default to 1.0)
			if not color.a then
				color.a = 1.0;
			end
			-- Calculate thickness accounting for frame scale for pixel-perfect alignment
			local baseThickness = (db.powerBorderSize or 1) * 2;
			local scale = powerBar:GetEffectiveScale() or 1;
			-- Convert to screen pixels, round to nearest integer, then convert back
			local screenPixels = baseThickness * scale;
			local roundedPixels = RoundToPixel(screenPixels);
			local thickness = roundedPixels / scale;
			-- Ensure minimum thickness
			if thickness < 0.5 then
				thickness = 0.5;
			end

			if not powerBar._PBRMBorderTop then
				powerBar._PBRMBorderTop = powerBar:CreateTexture(nil, "OVERLAY");
				powerBar._PBRMBorderBottom = powerBar:CreateTexture(nil, "OVERLAY");
				powerBar._PBRMBorderLeft = powerBar:CreateTexture(nil, "OVERLAY");
				powerBar._PBRMBorderRight = powerBar:CreateTexture(nil, "OVERLAY");
			end

			-- Top edge: sits just above the bar - use pixel-perfect offsets
			powerBar._PBRMBorderTop:ClearAllPoints();
			local topLeftX = GetPixelPerfectPosition(powerBar, 0);
			local topLeftY = GetPixelPerfectPosition(powerBar, 0);
			local topRightX = GetPixelPerfectPosition(powerBar, 0);
			local topRightY = GetPixelPerfectPosition(powerBar, 0);
			powerBar._PBRMBorderTop:SetPoint("BOTTOMLEFT", powerBar, "TOPLEFT", topLeftX, topLeftY);
			powerBar._PBRMBorderTop:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT", topRightX, topRightY);
			powerBar._PBRMBorderTop:SetHeight(thickness);

			-- Bottom edge: sits just below the bar - use pixel-perfect offsets
			powerBar._PBRMBorderBottom:ClearAllPoints();
			local bottomLeftX = GetPixelPerfectPosition(powerBar, 0);
			local bottomLeftY = GetPixelPerfectPosition(powerBar, 0);
			local bottomRightX = GetPixelPerfectPosition(powerBar, 0);
			local bottomRightY = GetPixelPerfectPosition(powerBar, 0);
			powerBar._PBRMBorderBottom:SetPoint("TOPLEFT", powerBar, "BOTTOMLEFT", bottomLeftX, bottomLeftY);
			powerBar._PBRMBorderBottom:SetPoint("TOPRIGHT", powerBar, "BOTTOMRIGHT", bottomRightX, bottomRightY);
			powerBar._PBRMBorderBottom:SetHeight(thickness);

			-- Left edge: spans exactly between top and bottom borders so corners meet - use pixel-perfect offsets
			powerBar._PBRMBorderLeft:ClearAllPoints();
			local leftTopX = GetPixelPerfectPosition(powerBar._PBRMBorderTop, 0);
			local leftTopY = GetPixelPerfectPosition(powerBar._PBRMBorderTop, 0);
			local leftBottomX = GetPixelPerfectPosition(powerBar._PBRMBorderBottom, 0);
			local leftBottomY = GetPixelPerfectPosition(powerBar._PBRMBorderBottom, 0);
			powerBar._PBRMBorderLeft:SetPoint("TOPRIGHT", powerBar._PBRMBorderTop, "TOPLEFT", leftTopX, leftTopY);
			powerBar._PBRMBorderLeft:SetPoint("BOTTOMRIGHT", powerBar._PBRMBorderBottom, "BOTTOMLEFT", leftBottomX, leftBottomY);
			powerBar._PBRMBorderLeft:SetWidth(thickness);

			-- Right edge: spans exactly between top and bottom borders so corners meet - use pixel-perfect offsets
			powerBar._PBRMBorderRight:ClearAllPoints();
			local rightTopX = GetPixelPerfectPosition(powerBar._PBRMBorderTop, 0);
			local rightTopY = GetPixelPerfectPosition(powerBar._PBRMBorderTop, 0);
			local rightBottomX = GetPixelPerfectPosition(powerBar._PBRMBorderBottom, 0);
			local rightBottomY = GetPixelPerfectPosition(powerBar._PBRMBorderBottom, 0);
			powerBar._PBRMBorderRight:SetPoint("TOPLEFT", powerBar._PBRMBorderTop, "TOPRIGHT", rightTopX, rightTopY);
			powerBar._PBRMBorderRight:SetPoint("BOTTOMLEFT", powerBar._PBRMBorderBottom, "BOTTOMRIGHT", rightBottomX, rightBottomY);
			powerBar._PBRMBorderRight:SetWidth(thickness);

			local r = color.r or 0;
			local g = color.g or 0;
			local b = color.b or 0;
			local a = color.a or 1;

			powerBar._PBRMBorderTop:SetColorTexture(r, g, b, a);
			powerBar._PBRMBorderBottom:SetColorTexture(r, g, b, a);
			powerBar._PBRMBorderLeft:SetColorTexture(r, g, b, a);
			powerBar._PBRMBorderRight:SetColorTexture(r, g, b, a);

			powerBar._PBRMBorderTop:Show();
			powerBar._PBRMBorderBottom:Show();
			powerBar._PBRMBorderLeft:Show();
			powerBar._PBRMBorderRight:Show();
		end
	end
	
	-- Apply size overrides and update anchors
	-- This handles width/height overrides and restores original anchors when no overrides are set
	self:ApplySizeAndAnchors(powerBar, frame, db.powerWidth, db.powerHeight);
	
	-- Apply offsets if explicitly set (including 0)
	-- Check if offsets are explicitly set (including 0) vs nil/not set
	local hasOffset = (db.powerOffsetX ~= nil) or (db.powerOffsetY ~= nil);
	if hasOffset then
		-- Offsets should produce the same visual distance regardless of frame scale
		-- So we store them at 1.0 scale and convert to current frame scale
		-- This ensures -3 on a 0.5 scale frame matches -1 on a 1.0 scale frame visually
		local frameScale = powerBar:GetEffectiveScale() or 1;
		local baseScale = 1.0;
		-- Convert offset from base scale (1.0) to current frame scale
		-- If frame is at 0.5 scale, multiply offset by 0.5 to get same visual distance
		local offsetX = (db.powerOffsetX or 0) * (frameScale / baseScale);
		local offsetY = (db.powerOffsetY or 0) * (frameScale / baseScale);
		-- Use 0 as default if offset is nil, so 0 offset is explicitly applied
		self:ApplyOffset(powerBar, offsetX, offsetY, powerBar._PBRMOriginalPoints);
	end
	
	-- Show/hide logic
	if db.showPowerBar == false then
		powerBar:Hide();
	else
		if not frame.hideHealthAndPower then
			powerBar:Show();
		end
	end
end

return BarStyling;

