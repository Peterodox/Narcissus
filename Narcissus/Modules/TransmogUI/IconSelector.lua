local _, addon = ...

if addon.IsTOCVersionEqualOrNewerThan(120001) then
	--Icon Selector will include transmog icons natively
	return
end

local TransmogUIManager = addon.TransmogUIManager;


local Module = TransmogUIManager:CreateModule("IconSelector");

local Def = {
	IconSize = 36,
	IconGap = 6,
	ButtonsPerRow = 8,
	FramePadding = 18,
};

local SuggestionFrame;


local IconButton_PostCreate;
do
	local IconButtonMixin = {};

	function IconButtonMixin:OnEnter()
		local name;
		if self.slotInfo.name then
			name = self.slotInfo.name;
		elseif self.slotInfo.isIllusion then
			name = C_TransmogCollection.GetIllusionStrings(self.slotInfo.transmogID);
		else
			local sourceInfo = C_TransmogCollection.GetSourceInfo(self.slotInfo.transmogID);
			name = sourceInfo and sourceInfo.name;
		end

		if not name then return end;

		local tooltip = GameTooltip;
		tooltip:SetOwner(self, "ANCHOR_RIGHT");
		tooltip:SetText(name, 1, 1, 1, 1, true);
		tooltip:Show();
	end

	function IconButtonMixin:OnLeave()
		GameTooltip:Hide();
	end

	function IconButtonMixin:OnClick()
		Module.SetIconTexture(self.slotInfo.texture);
		SuggestionFrame:UpdateSelection();
	end

	function IconButtonMixin:SetSlotInfo(slotInfo)
		self.Icon:SetTexture(slotInfo.texture);
		self.slotInfo = slotInfo;
	end


	function IconButton_PostCreate(self)
		Mixin(self, IconButtonMixin);
		self:SetScript("OnEnter", self.OnEnter);
		self:SetScript("OnLeave", self.OnLeave);
		self:SetScript("OnClick", self.OnClick);
	end
end


local SuggestionFrameMixin = {};
do
	function SuggestionFrameMixin:OnShow()
		local shouldShow;

		if self.SelectorPopup.outfitData and self.SelectorPopup.mode == IconSelectorPopupFrameModes.Edit then
			if C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID() == self.SelectorPopup.outfitData.outfitID then
				shouldShow = true;
			end
		end

		if shouldShow then
			self:TryShowOptions();
		else
			self.WidgetContainer:Hide();
		end
	end

	function SuggestionFrameMixin:OnHide()

	end

	function SuggestionFrameMixin:TryShowOptions()
		self.IconButtons:ReleaseAll();

		if not self.specIcons then
			self.specIcons = {};
			local _, _, classID = UnitClass("player");
			for index = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classID) do
				local _, name, _, icon = C_SpecializationInfo.GetSpecializationInfo(index);
				if name then
					table.insert(self.specIcons, {
						texture = icon,
						name = name,
					});
				end
			end
		end

		local info = TransmogUIManager:GetViewedOutfitInfo();
		local numButtons = #info;

		if numButtons > 0 then
			numButtons = numButtons + #self.specIcons;
			local layoutSize = Def.IconSize + Def.IconGap;
			local fromX = (math.min(Def.ButtonsPerRow, numButtons) * layoutSize - Def.IconGap) * 0.5;
			local x = -fromX;
			local y = Def.FramePadding;
			local button;

			for _, specInfo in ipairs(self.specIcons) do
				table.insert(info, specInfo);
			end

			for k, slotInfo in ipairs(info) do
				button = self.IconButtons:Acquire();
				button:SetPoint("TOPLEFT", self.WidgetContainer, "TOP", x, -y);
				button:SetSlotInfo(slotInfo);
				button.SelectedTexture:Hide();
				button:Show();
				if k % Def.ButtonsPerRow == 0 then
					x = -fromX;
					y = y + layoutSize;
				else
					x = x + layoutSize;
				end
			end

			local frameWidth = Def.ButtonsPerRow * layoutSize - Def.IconGap + 2*Def.FramePadding;
			local frameHeight = math.ceil(numButtons / Def.ButtonsPerRow) * layoutSize - Def.IconGap + 2*Def.FramePadding;

			self.WidgetContainer:SetSize(frameWidth, frameHeight);
			self.WidgetContainer:Show();

			C_Timer.After(0, function()
				self:UpdateSelection();
			end);
		else
			self.WidgetContainer:Hide();
		end
	end

	function SuggestionFrameMixin:UpdateSelection()
		local texture = Module.GetIconTexture();
		for button in self.IconButtons:EnumerateActive() do
			button.SelectedTexture:SetShown(button.slotInfo.texture == texture);
		end
	end


	function SuggestionFrameMixin:OnLoad()
		self.OnLoad = nil;

		self:SetScript("OnShow", self.OnShow);
		self:SetScript("OnHide", self.OnHide);

		local WidgetContainer = CreateFrame("Frame", nil, self);
		self.WidgetContainer = WidgetContainer;
		WidgetContainer:SetPoint("TOPLEFT", self.SelectorPopup, "TOPRIGHT", 4, 0);
		WidgetContainer:SetSize(256, 64);

		local bg = CreateFrame("Frame", nil, WidgetContainer, "DialogBorderDarkTemplate");
		WidgetContainer.BackgroundFrame = bg;
		bg:SetUsingParentLevel(true);

		self.IconButtons = CreateFramePool("Button", WidgetContainer, "NarciSelectorIconButtonTemplate", nil, nil, IconButton_PostCreate);
	end
end


function Module:OnLoad()
    local SelectorPopup = TransmogFrame.OutfitPopup;	--Taint?
	local parent = TransmogFrame;

	SuggestionFrame = CreateFrame("Frame", nil, parent);
	SuggestionFrame:Hide();
	Mixin(SuggestionFrame, SuggestionFrameMixin);
	SuggestionFrame.SelectorPopup = SelectorPopup;
	SuggestionFrame:OnLoad();
	SuggestionFrame:SetFrameStrata("HIGH");

	SelectorPopup:HookScript("OnShow", function()
		SuggestionFrame:Show();
	end);

	SelectorPopup:HookScript("OnHide", function()
		SuggestionFrame:Hide();
	end);

	local function SetIconTexture(texture)
		SelectorPopup.IconSelector:SetSelectedIndex(SelectorPopup:GetIndexOfIcon(texture));
		SelectorPopup.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(texture);
	end
	self.SetIconTexture = SetIconTexture;

	local function GetIconTexture()
		return SelectorPopup.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture();
	end
	self.GetIconTexture = GetIconTexture;
end
