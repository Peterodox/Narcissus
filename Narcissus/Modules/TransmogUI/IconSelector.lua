local _, addon = ...
local TransmogUIManager = addon.TransmogUIManager;


local Module = TransmogUIManager:CreateModule("IconSelector");
Module.Defs = {};


local SuggestionFrame;
local SuggestionFrameMixin = {};
do
	function SuggestionFrameMixin:OnShow()
		if self.parent.outfitData and self.parent.mode == IconSelectorPopupFrameModes.Edit then
			self.WidgetContainer:Show();
		else
			self.WidgetContainer:Hide();
		end
	end

	function SuggestionFrameMixin:OnHide()

	end

	function SuggestionFrameMixin:OnLoad()
		self.OnLoad = nil;

		self:SetScript("OnShow", self.OnShow);
		self:SetScript("OnHide", self.OnHide);

		local WidgetContainer = CreateFrame("Frame", nil, self);
		self.WidgetContainer = WidgetContainer;
		WidgetContainer:SetPoint("TOPLEFT", self.parent, "TOPRIGHT", 4, 0);
		WidgetContainer:SetSize(256, 64);

		WidgetContainer.Background = WidgetContainer:CreateTexture(nil, "BACKGROUND");
		WidgetContainer.Background:SetAllPoints(true);
		WidgetContainer.Background:SetColorTexture(0, 0, 0, 0.95);
	end
end


function Module:OnLoad()
    local parent = TransmogFrame.OutfitPopup;

	SuggestionFrame = CreateFrame("Frame", nil, parent);
	Mixin(SuggestionFrame, SuggestionFrameMixin);
	SuggestionFrame.parent = parent;
	SuggestionFrame:OnLoad();
end