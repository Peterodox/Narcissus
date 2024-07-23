local _, addon = ...

local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo;
local GemDataProvider = addon.GemDataProvider;

local PADDING = 24;
local ICON_SIZE = 16;
local ICON_NAME_GAP = 8;
local TEXT_OFFSET = 24;
local TEXT_WIDTH = 320 - 2 * PADDING - ICON_SIZE - ICON_NAME_GAP;

NarciEquipmentTooltipGemFrameMixin = {};

function NarciEquipmentTooltipGemFrameMixin:SetFrameWidth(width)
    TEXT_WIDTH = width - TEXT_OFFSET - PADDING;
    if self.texts then
        for i = 1, #self.texts do
            self.texts[i]:SetWidth(TEXT_WIDTH);
        end
    end
    self:SetWidth(width);
end

function NarciEquipmentTooltipGemFrameMixin:SetSocketInfo(socketInfo)
    self:Clear();
    if socketInfo then
        local numGems = #socketInfo;
        self.numGems = numGems;
        local maxWidth = 0;
        local width;
        for i = 1, numGems do
            width = self:SetGemEffect(i, unpack(socketInfo[i]));
            if width > maxWidth then
                maxWidth = width;
            end
        end
        self:Show();
        local frameHeight = self:GetTop() - self.texts[numGems]:GetBottom();
        self:SetHeight(frameHeight);
        maxWidth = maxWidth + TEXT_OFFSET;
        return true, frameHeight, maxWidth
    end
end

function NarciEquipmentTooltipGemFrameMixin:Clear()
    if self.numGems and self.numGems > 0 then
        if self.icons then
            for i = 1, #self.icons do
                self.icons[i]:Hide();
                self.texts[i]:Hide();
                self.borders[i]:Hide();
            end
        end
        self:Hide();
    end
    self.numGems = 0;
end

function NarciEquipmentTooltipGemFrameMixin:SetGemEffect(n, texture, gemName, gemLink, gemEffect)
    if not self.icons then
        self.icons = {};
        self.texts = {};
        self.borders = {};
    end
    if not self.icons[n] then
        self.texts[n] = self:CreateFontString(nil, "ARTWORK", self:GetParent().textFont);
        self.texts[n]:SetSpacing(2);
        self.texts[n]:SetWidth(TEXT_WIDTH);
        self.texts[n]:SetJustifyH("LEFT");
        self.icons[n] = self:CreateTexture(nil, "ARTWORK");
        self.icons[n]:SetSize(ICON_SIZE, ICON_SIZE);
        self.icons[n]:SetPoint("RIGHT", self.texts[n], "TOPLEFT", -7, -5);
        self.borders[n] = self:CreateTexture(nil,"OVERLAY");
        self.borders[n]:SetSize(22, 22);
        self.borders[n]:SetPoint("CENTER", self.icons[n], "CENTER", 0, 0);
        self.borders[n]:SetTexture("Interface\\AddOns\\Narcissus\\Art\\GameTooltip\\GemBorderSqaure");
    end
    if n == 1 then
        self.texts[n]:SetPoint("TOPLEFT", self, "TOPLEFT", TEXT_OFFSET, -2);
    else
        self.texts[n]:SetPoint("TOPLEFT", self.texts[n - 1], "BOTTOMLEFT", 0, -12);
    end

    self.icons[n]:SetTexture(texture);
    --print(gemEffect .." "..texture)
    if gemLink then
        --local itemID, itemType, itemSubType, itemEquipLoc, icon = GetItemInfoInstant(gemLink);
        self.texts[n]:SetTextColor(0.8863, 0.8863, 0.8863);
        self.icons[n]:Show();
        self.borders[n]:Show();
        self.texts[n]:Show();

        local itemID = GetItemInfoInstant(gemLink);
        if GemDataProvider:IsItemPrimordialStone(itemID) then
            local itemLevel = GetDetailedItemLevelInfo(gemLink);
            if itemLevel and gemEffect then
                gemEffect = string.gsub(gemEffect, "\n", "\n".."|CFFFFD100"..itemLevel.."|r  ", 1);
            end
        end
    else
        self.texts[n]:SetTextColor(0.5, 0.5, 0.5);
        self.icons[n]:Show();
        self.borders[n]:Hide();
        self.texts[n]:Show();
    end

    self.texts[n]:SetText(gemEffect);

    if not gemEffect then
        self:GetParent():QueryData();
    end

    return self.texts[n]:GetWrappedWidth() or 0
end

function NarciEquipmentTooltipGemFrameMixin:UpdateAnchor()
    local p = self:GetParent();
end