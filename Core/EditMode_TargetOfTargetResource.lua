local ADDON_NAME, ns = ...;

local addon = ns.Addon;

local EditModeTargetOftargetOfTargetResource = {};
ns.EditModeTargetOftargetOfTargetResource = EditModeTargetOftargetOfTargetResource;

local initialized;

function EditModeTargetOftargetOfTargetResource:Init()
	if initialized then
		return;
	end
	
	-- Wait for Edit Mode to be fully loaded
	if not EditModeManagerFrame or not EditModeManagerFrame.AccountSettings then
		-- Try again after a short delay
		C_Timer.After(0.1, function()
			EditModeTargetOftargetOfTargetResource:Init();
		end);
		return;
	end
	
	initialized = true;
	
	-- Hook into Edit Mode AccountSettings to add our section
	self:SetupPonyFramesSection();
end

function EditModeTargetOftargetOfTargetResource:SetupPonyFramesSection()
	local accountSettings = EditModeManagerFrame.AccountSettings;
	if not accountSettings then
		return;
	end
	
	local advancedContainer = accountSettings.SettingsContainer and accountSettings.SettingsContainer.ScrollChild and accountSettings.SettingsContainer.ScrollChild.AdvancedOptionsContainer;
	if not advancedContainer then
		return;
	end
	
	-- Create Pony Frames title
	local ponyTitle = CreateFrame("Frame", nil, advancedContainer);
	ponyTitle:SetSize(225, 32);
	local titleText = ponyTitle:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	titleText:SetPoint("LEFT", ponyTitle, "LEFT", 5, 0);
	titleText:SetText("Pony Frames");
	ponyTitle.Title = titleText;
	advancedContainer.PonyFramesTitle = ponyTitle;
	
	-- Create Pony Frames container (using GridLayoutFrame like other containers)
	local ponyContainer = CreateFrame("Frame", nil, advancedContainer);
	ponyContainer:SetSize(225, 1);
	-- Set up as a grid layout container
	ponyContainer.childXPadding = 0;
	ponyContainer.childYPadding = 0;
	ponyContainer.isHorizontal = true;
	ponyContainer.stride = 2;
	ponyContainer.layoutFramesGoingRight = true;
	ponyContainer.layoutFramesGoingUp = false;
	ponyContainer.alwaysUpdateLayout = true;
	advancedContainer.PonyFramesContainer = ponyContainer;
	
	-- Create checkbox for Target of Target Resource Frame using the template
	-- We'll create it manually but match the template structure
	local TargetOftargetOfTargetResourceCheck = CreateFrame("Frame", nil, accountSettings.SettingsContainer);
	TargetOftargetOfTargetResourceCheck:SetSize(225, 32);
	TargetOftargetOfTargetResourceCheck.fixedWidth = 225;
	TargetOftargetOfTargetResourceCheck.fixedHeight = 32;
	
	-- Create checkbox button
	local checkButton = CreateFrame("CheckButton", nil, TargetOftargetOfTargetResourceCheck);
	checkButton:SetSize(32, 32);
	checkButton:SetPoint("LEFT");
	checkButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
	checkButton:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
	checkButton:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD");
	checkButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
	checkButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
	TargetOftargetOfTargetResourceCheck.Button = checkButton;
	
	-- Create label
	local label = TargetOftargetOfTargetResourceCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium");
	label:SetPoint("LEFT", checkButton, "RIGHT", 5, 0);
	label:SetText("Target of Target Resource Frame");
	TargetOftargetOfTargetResourceCheck.Label = label;
	
	-- Set up checkbox behavior
	local function OnCheck(self, checked, isUserInput)
		local addon = ns.Addon;
		if addon and addon.db and addon.db.profile and addon.db.profile.TargetOftargetOfTargetResource then
			addon.db.profile.TargetOftargetOfTargetResource.enabled = checked;
			if addon.NotifyConfigChanged then
				addon:NotifyConfigChanged();
			end
		end
	end
	
	local function OnMouseOver(self)
		-- Show tooltip or highlight frame
		local targetModule = addon and addon:GetModule("TargetOftargetOfTargetResource", true);
		if targetModule and targetModule.frame then
			targetModule.frame:HighlightSystem();
		end
	end
	
	local function OnMouseLeave(self)
		-- Clear highlight if not selected
		local targetModule = addon and addon:GetModule("TargetOftargetOfTargetResource", true);
		if targetModule and targetModule.frame then
			if not targetModule.frame.isSelected then
				targetModule.frame:ClearHighlight();
			end
		end
	end
	
	checkButton:SetScript("OnClick", function(self)
		local checked = self:GetChecked();
		OnCheck(TargetOftargetOfTargetResourceCheck, checked, true);
	end);
	
	TargetOftargetOfTargetResourceCheck:SetScript("OnEnter", OnMouseOver);
	TargetOftargetOfTargetResourceCheck:SetScript("OnLeave", OnMouseLeave);
	
	TargetOftargetOfTargetResourceCheck.SetControlChecked = function(self, checked)
		if self.Button then
			self.Button:SetChecked(checked);
		end
	end;
	
	TargetOftargetOfTargetResourceCheck.IsControlChecked = function(self)
		if self.Button then
			return self.Button:GetChecked();
		end
		return false;
	end;
	
	TargetOftargetOfTargetResourceCheck.SetCallback = function(self, callback)
		self._callback = callback;
	end;
	
	TargetOftargetOfTargetResourceCheck.SetMouseOverCallback = function(self, callback)
		self._mouseOverCallback = callback;
	end;
	
	-- Set category to a custom value (we'll handle it in LayoutSettings hook)
	TargetOftargetOfTargetResourceCheck.category = 4; -- Custom category for Pony Frames
	TargetOftargetOfTargetResourceCheck.advancedLayoutIndex = 1;
	TargetOftargetOfTargetResourceCheck.isBasicOption = false;
	TargetOftargetOfTargetResourceCheck.shouldHide = false;
	
	-- Store reference
	accountSettings.SettingsContainer.TargetOftargetOfTargetResourceFrame = TargetOftargetOfTargetResourceCheck;
	
	-- Hook LayoutSettings to add our section
	hooksecurefunc(accountSettings, "LayoutSettings", function(self)
		EditModeTargetOftargetOfTargetResource:LayoutPonyFramesSection(self);
	end);
	
	-- Hook PrepareSettingsCheckButtonVisibility to include our checkbox
	hooksecurefunc(accountSettings, "PrepareSettingsCheckButtonVisibility", function(self)
		if not self.settingsCheckButtons then
			self.settingsCheckButtons = {};
		end
		if accountSettings.SettingsContainer.TargetOftargetOfTargetResourceFrame then
			self.settingsCheckButtons.TargetOftargetOfTargetResourceFrame = accountSettings.SettingsContainer.TargetOftargetOfTargetResourceFrame;
		end
	end);
end

function EditModeTargetOftargetOfTargetResource:LayoutPonyFramesSection(accountSettings)
	if not accountSettings then
		return;
	end
	
	local showAdvancedOptions = EditModeManagerFrame:AreAdvancedOptionsEnabled();
	if not showAdvancedOptions then
		return;
	end
	
	local advancedContainer = accountSettings.SettingsContainer and accountSettings.SettingsContainer.ScrollChild and accountSettings.SettingsContainer.ScrollChild.AdvancedOptionsContainer;
	if not advancedContainer then
		return;
	end
	
	local ponyTitle = advancedContainer.PonyFramesTitle;
	local ponyContainer = advancedContainer.PonyFramesContainer;
	local TargetOftargetOfTargetResourceCheck = accountSettings.SettingsContainer.TargetOftargetOfTargetResourceFrame;
	
	if not (ponyTitle and ponyContainer and TargetOftargetOfTargetResourceCheck) then
		return;
	end
	
	-- Position Pony Frames section after Misc section
	-- Find the last layout index from Misc
	local lastLayoutIndex = 6; -- MiscContainer is layoutIndex 6
	ponyTitle.layoutIndex = lastLayoutIndex + 1;
	ponyContainer.layoutIndex = lastLayoutIndex + 2;
	
	-- Set parent and show
	ponyTitle:SetParent(advancedContainer);
	ponyTitle:Show();
	
	ponyContainer:SetParent(advancedContainer);
	ponyContainer:Show();
	
	-- Add checkbox to container
	TargetOftargetOfTargetResourceCheck:SetParent(ponyContainer);
	TargetOftargetOfTargetResourceCheck.layoutIndex = 1;
	TargetOftargetOfTargetResourceCheck:Show();
	
	-- Update checkbox state from config
	local addon = ns.Addon;
	if addon and addon.db and addon.db.profile and addon.db.profile.TargetOftargetOfTargetResource then
		TargetOftargetOfTargetResourceCheck:SetControlChecked(addon.db.profile.TargetOftargetOfTargetResource.enabled or false);
	end
	
	-- Trigger layout update
	if advancedContainer and advancedContainer.GetLayoutIndex then
		-- Force layout refresh
		if EditModeManagerFrame and EditModeManagerFrame.Layout then
			EditModeManagerFrame:Layout();
		end
	end
end

