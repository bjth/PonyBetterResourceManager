local ADDON_NAME, ns = ...;

local EditModeHelper = {};
ns.EditModeHelper = EditModeHelper;

-- Configuration options for Edit Mode integration
-- {
--   frame = frame,                    -- The frame to integrate
--   systemName = "Frame Name",        -- Name to display in Edit Mode
--   db = dbTable,                     -- Database table to save position to (required for position saving)
--   defaultHideSelection = false,     -- Whether to hide selection by default
--   onPositionChange = function(frame) -- Optional callback when position changes (defaults to saving to db)
--   onEditModeEnter = function(frame) -- Optional callback when entering Edit Mode
--   onEditModeExit = function(frame)  -- Optional callback when exiting Edit Mode
--   setupSnappingOverrides = function(frame) -- Optional function for custom snapping overrides (rarely needed)
-- }
function EditModeHelper:SetupEditModeIntegration(config)
	if not config or not config.frame or not config.systemName then
		error("EditModeHelper:SetupEditModeIntegration requires frame and systemName");
	end
	
	local frame = config.frame;
	local systemName = config.systemName;
	local db = config.db;
	local defaultHideSelection = config.defaultHideSelection or false;
	local onPositionChange = config.onPositionChange;
	local onEditModeEnter = config.onEditModeEnter;
	local onEditModeExit = config.onEditModeExit;
	local setupSnappingOverrides = config.setupSnappingOverrides;
	
	-- Apply Blizzard's EditModeSystemMixin to our frame
	-- This gives us all the standard Edit Mode functionality
	Mixin(frame, EditModeSystemMixin);
	
	-- Initialize Edit Mode state (matching Blizzard's OnSystemLoad)
	-- Use a custom system enum value to avoid clashes: 9097 = "Pony", 001 = first frame
	-- This allows us to register with EditModeManagerFrame and use all Blizzard functionality
	frame.system = 9097001; -- Custom system enum for PonyBetterResourceManager Target Frame
	frame.systemName = systemName;
	frame.defaultHideSelection = defaultHideSelection;
	frame.snappedFrames = {};
	frame.downKeys = {};
	
	-- Store original position when entering Edit Mode (for revert functionality)
	frame._originalEditModePosition = nil;
	
	-- Create selection frame as a child frame (matching Blizzard's XML structure)
	-- The Selection frame is created in XML for Blizzard frames, but we create it programmatically
	local selectionFrame = CreateFrame("Frame", nil, frame, "EditModeSystemSelectionTemplate");
	selectionFrame:SetAllPoints(frame);
	
	-- Ensure selection frame has proper mouse interaction (matching XML attributes)
	selectionFrame:EnableMouse(true);
	selectionFrame:RegisterForDrag("LeftButton");
	selectionFrame:SetFrameStrata("MEDIUM");
	selectionFrame:SetFrameLevel(1000);
	selectionFrame:SetToplevel(true);
	
	-- Ensure parent reference is set (used by OnMouseDown)
	selectionFrame.parent = frame;
	
	selectionFrame:Hide();
	frame.Selection = selectionFrame;
	
	-- Set the system on the selection frame (matching Blizzard's OnSystemLoad line 29)
	selectionFrame:SetSystem(frame);
	
	-- Override GetSystemName to return our custom name
	frame.GetSystemName = function(self)
		return systemName;
	end;
	
	-- Use Blizzard's OnSystemLoad directly - we now have a system enum!
	-- No need to override it anymore since we have a valid system value
	-- The mixin's OnSystemLoad will handle everything including registration
	
	-- No need to override SetPointOverride - we have a valid system enum now
	-- Blizzard's implementation will work correctly
	
	-- Hook into EditModeManagerFrame to forward keyboard events to our selected frame
	-- This allows arrow key movement when our custom frame is selected
	-- Blizzard's system forwards keyboard through the settings dialog, but we skip that
	-- So we need to hook into the manager frame's keyboard handling
	if EditModeManagerFrame and not EditModeManagerFrame._PBRMKeyboardHooked then
		EditModeManagerFrame._PBRMKeyboardHooked = true;
		
		-- Enable keyboard on EditModeManagerFrame so it can receive keyboard events
		EditModeManagerFrame:EnableKeyboard(true);
		
		-- Store reference to our custom frames for keyboard forwarding
		EditModeManagerFrame._PBRMCustomFrames = {};
		
		-- Hook OnKeyDown to forward to selected custom system frames
		local originalOnKeyDown = EditModeManagerFrame:GetScript("OnKeyDown");
		EditModeManagerFrame:SetScript("OnKeyDown", function(self, key)
			-- Call original handler first
			if originalOnKeyDown then
				originalOnKeyDown(self, key);
			end
			
			-- Forward to any selected custom frame
			if self._PBRMCustomFrames then
				for customFrame in pairs(self._PBRMCustomFrames) do
					if customFrame.isSelected and customFrame.OnKeyDown then
						customFrame:OnKeyDown(key);
						break; -- Only one frame should be selected at a time
					end
				end
			end
		end);
		
		-- Hook OnKeyUp similarly
		local originalOnKeyUp = EditModeManagerFrame:GetScript("OnKeyUp");
		EditModeManagerFrame:SetScript("OnKeyUp", function(self, key)
			-- Call original handler first
			if originalOnKeyUp then
				originalOnKeyUp(self, key);
			end
			
			-- Forward to any selected custom frame
			if self._PBRMCustomFrames then
				for customFrame in pairs(self._PBRMCustomFrames) do
					if customFrame.isSelected and customFrame.OnKeyUp then
						customFrame:OnKeyUp(key);
						break; -- Only one frame should be selected at a time
					end
				end
			end
		end);
	end
	
	-- Register this frame for keyboard forwarding
	if EditModeManagerFrame and EditModeManagerFrame._PBRMCustomFrames then
		EditModeManagerFrame._PBRMCustomFrames[frame] = true;
	end
	
	-- No need to override SelectSystem - we have a valid system enum now
	-- Blizzard's implementation will work correctly, but we can skip the settings dialog
	-- since we don't have settings defined for our custom system
	local originalSelectSystem = frame.SelectSystem;
	frame.SelectSystem = function(self)
		if not self.isSelected then
			self:SetMovable(true);
			if self.Selection then
				self.Selection:ShowSelected();
			end
			-- Skip EditModeSystemSettingsDialog:AttachToSystemFrame since we don't have settings
			-- The dialog expects systemInfo which we don't have for custom systems
			-- However, we still need keyboard input, so we enable it on the frame directly
			-- if EditModeSystemSettingsDialog and EditModeSystemSettingsDialog.AttachToSystemFrame then
			-- 	EditModeSystemSettingsDialog:AttachToSystemFrame(self);
			-- end
			self.isSelected = true;
			self:UpdateMagnetismRegistration();
		end
	end;
	
	-- Override OnSystemPositionChange to track changes but NOT save to database yet
	-- Position will only be saved when user clicks Save button (via PrepareForSave)
	local originalOnSystemPositionChange = frame.OnSystemPositionChange;
	frame.OnSystemPositionChange = function(self)
		self:SetHasActiveChanges(true);
		
		-- Call Blizzard's implementation first
		if originalOnSystemPositionChange then
			originalOnSystemPositionChange(self);
		end
		
		-- Don't save to database here - just track that position changed
		-- The position will be saved when PrepareForSave is called (on Save button click)
	end;
	
	-- No need to override OnDragStop - Blizzard's implementation calls OnSystemPositionChange
	-- which will track changes but not save to database
	
	-- Override OnEditModeEnter to store original position for revert functionality
	local originalOnEditModeEnter = frame.OnEditModeEnter;
	frame.OnEditModeEnter = function(self)
		-- Store original position when entering Edit Mode
		-- Get current position and convert to scale-adjusted offsets (at 1.0 scale) for storage
		local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1);
		if point then
			-- Convert offsets to 1.0 scale (matching how we save)
			local frameScale = self:GetScale();
			local scaleAdjustedX = (xOfs or 0) * frameScale;
			local scaleAdjustedY = (yOfs or 0) * frameScale;
			
			self._originalEditModePosition = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
				relativePoint = relativePoint or point,
				x = scaleAdjustedX,
				y = scaleAdjustedY
			};
		end
		
		-- Call Blizzard's implementation
		if originalOnEditModeEnter then
			originalOnEditModeEnter(self);
		end
		
		-- Call custom callback if provided
		if onEditModeEnter then
			onEditModeEnter(self);
		end
	end;
	
	-- Override OnEditModeExit to skip settings dialog and restore position appropriately
	local originalOnEditModeExit = frame.OnEditModeExit;
	frame.OnEditModeExit = function(self)
		self:ClearHighlight();
		self:StopMovingOrSizing();
		
		-- If there were active changes but user didn't save, restore original position
		-- (This handles the case where user exits Edit Mode without clicking Save)
		if self.hasActiveChanges and self._originalEditModePosition then
			local relativeTo = self._originalEditModePosition.relativeTo and _G[self._originalEditModePosition.relativeTo] or UIParent;
			
			-- Convert scale-adjusted offsets (at 1.0 scale) back to current scale offsets
			local frameScale = self:GetScale();
			local xOfs = self._originalEditModePosition.x / frameScale;
			local yOfs = self._originalEditModePosition.y / frameScale;
			
			self:ClearAllPoints();
			self:SetPoint(
				self._originalEditModePosition.point,
				relativeTo,
				self._originalEditModePosition.relativePoint or self._originalEditModePosition.point,
				xOfs,
				yOfs
			);
		elseif not self.hasActiveChanges and db and db.editModePoint then
			-- User saved changes - restore the saved position from database
			-- This ensures the frame appears at the correct position after Edit Mode
			local point = db.editModePoint;
			local relativeTo = db.editModeRelativeTo and _G[db.editModeRelativeTo] or UIParent;
			local relativePoint = db.editModeRelativePoint or point;
			local savedX = db.editModeX or 0;
			local savedY = db.editModeY or 0;
			
			-- Convert saved offsets (at 1.0 scale) to current scale offsets
			local frameScale = self:GetScale();
			local xOfs = savedX / frameScale;
			local yOfs = savedY / frameScale;
			
			self:ClearAllPoints();
			self:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs);
		end
		
		-- Clear original position storage
		self._originalEditModePosition = nil;
		
		-- Skip EditModeSystemSettingsDialog:Hide since we don't use the settings dialog
		-- if EditModeSystemSettingsDialog and EditModeSystemSettingsDialog.Hide then
		-- 	EditModeSystemSettingsDialog:Hide();
		-- end
		
		-- Call custom callback if provided (after position restoration)
		if onEditModeExit then
			onEditModeExit(self);
		end
	end;
	
	-- Default position saving function (used if no custom callback provided)
	-- This follows Blizzard's UpdateSystemAnchorInfo approach from EditModeManager.lua
	local function savePositionToDB(frame)
		if not db then
			return;
		end
		
		-- Get the current anchor point (using GetPoint which is the override)
		-- This matches Blizzard's UpdateSystemAnchorInfo line 299
		local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint(1);
		
		if not point then
			-- No anchor point found, can't save
			return;
		end
		
		-- Handle nil relativeTo (matches Blizzard's UpdateSystemAnchorInfo lines 301-312)
		if not relativeTo then
			relativeTo = UIParent;
			
			-- When setting relativeTo to UIParent, the y position can change slightly
			-- Account for this by tracking the change in top and adjusting
			local originalSystemFrameTop = frame:GetTop();
			frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
			
			offsetY = offsetY + (originalSystemFrameTop - (frame:GetTop() or originalSystemFrameTop));
			frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
		end
		
		-- Undo offset changes due to scale so we're always working as if we're at 1.0 scale
		-- This matches Blizzard's UpdateSystemAnchorInfo lines 314-317
		local frameScale = frame:GetScale();
		offsetX = offsetX * frameScale;
		offsetY = offsetY * frameScale;
		
		-- Ensure we have valid numbers (not nil)
		offsetX = offsetX or 0;
		offsetY = offsetY or 0;
		
		-- Save to database (storing scale-adjusted offsets)
		db.editModePoint = point;
		db.editModeRelativeTo = relativeTo and relativeTo:GetName() or "UIParent";
		db.editModeRelativePoint = relativePoint or point;
		db.editModeX = offsetX;
		db.editModeY = offsetY;
	end;
	
	-- Use custom callback if provided, otherwise use default position saving
	local positionChangeCallback = onPositionChange or savePositionToDB;
	
	-- Override PrepareForSave to actually save position to database when Save button is clicked
	-- This is called when the user clicks Save, after all dragging has stopped
	local originalPrepareForSave = frame.PrepareForSave;
	frame.PrepareForSave = function(self)
		-- Call Blizzard's implementation first (this may modify the frame position)
		if originalPrepareForSave then
			originalPrepareForSave(self);
		end
		
		-- Now save the current position to database
		-- Position should be finalized at this point since dragging has stopped
		if positionChangeCallback and self:IsShown() then
			positionChangeCallback(self);
		end
		
		-- Immediately restore the saved position to ensure it's correct
		-- This prevents the frame from appearing at 0,0 after save
		if db and db.editModePoint then
			local point = db.editModePoint;
			local relativeTo = db.editModeRelativeTo and _G[db.editModeRelativeTo] or UIParent;
			local relativePoint = db.editModeRelativePoint or point;
			local savedX = db.editModeX or 0;
			local savedY = db.editModeY or 0;
			
			-- Convert saved offsets (at 1.0 scale) to current scale offsets
			local frameScale = self:GetScale();
			local xOfs = savedX / frameScale;
			local yOfs = savedY / frameScale;
			
			self:ClearAllPoints();
			self:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs);
		end
	end;
	
	-- Override UpdateSystem to handle revert (restore original position)
	-- This is called when RevertAllChanges is clicked
	local originalUpdateSystem = frame.UpdateSystem;
	frame.UpdateSystem = function(self, systemInfo)
		-- If we have an original position stored, restore it
		if self._originalEditModePosition then
			local relativeTo = self._originalEditModePosition.relativeTo and _G[self._originalEditModePosition.relativeTo] or UIParent;
			
			-- Convert scale-adjusted offsets (at 1.0 scale) back to current scale offsets
			local frameScale = self:GetScale();
			local xOfs = self._originalEditModePosition.x / frameScale;
			local yOfs = self._originalEditModePosition.y / frameScale;
			
			self:ClearAllPoints();
			self:SetPoint(
				self._originalEditModePosition.point,
				relativeTo,
				self._originalEditModePosition.relativePoint or self._originalEditModePosition.point,
				xOfs,
				yOfs
			);
		end
		
		-- Call Blizzard's implementation
		if originalUpdateSystem then
			originalUpdateSystem(self, systemInfo);
		end
	end;
	
	-- No need to override OnMouseDown - we're registered now, so EditModeManagerFrame:SelectSystem will work
	-- The mixin's OnMouseDown calls EditModeManagerFrame:SelectSystem(self.parent) which will work correctly
	
	-- Call OnSystemLoad to initialize the mixin
	-- This must be called before restoring position so SetPoint override is active
	frame:OnSystemLoad();
	
	-- Restore saved position if available (after OnSystemLoad so SetPoint override works)
	-- Note: Saved offsets are at 1.0 scale, so we need to divide by current scale when restoring
	-- This matches Blizzard's ApplySystemAnchor approach (EditModeSystemTemplates.lua line 375)
	if db and db.editModePoint then
		local point = db.editModePoint;
		local relativeTo = db.editModeRelativeTo and _G[db.editModeRelativeTo] or UIParent;
		local relativePoint = db.editModeRelativePoint or point;
		local savedX = db.editModeX or 0;
		local savedY = db.editModeY or 0;
		
		-- Convert saved offsets (at 1.0 scale) to current scale offsets
		local frameScale = frame:GetScale();
		local xOfs = savedX / frameScale;
		local yOfs = savedY / frameScale;
		
		-- Use ClearAllPointsBase to avoid triggering Edit Mode logic during initial setup
		frame:ClearAllPointsBase();
		-- Use SetPointBase to set initial position without triggering Edit Mode logic
		frame:SetPointBase(point, relativeTo, relativePoint, xOfs, yOfs);
	end
	
	-- Set up custom snapping overrides if provided
	-- This allows for frame-specific overrides if needed
	if setupSnappingOverrides then
		setupSnappingOverrides(frame);
	end
end

return EditModeHelper;
