local MAX_WIDTH = 180;
local MIN_WIDTH = 0;
local EXTRA_HEIGHT = 0;
local ICON_SIZE = 20;
local TOOLTIP_PADDING = 6;


local UIParent = UIParent;
local GetCursorPosition = GetCursorPosition;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetTransmogItemAppearanceID = C_TransmogCollection.GetItemInfo;
local GetItemAppearanceID;
local FadeFrame = NarciFadeUI.Fade;

local DataProvider = {};

function DataProvider:GetInventoryName(itemEquipLoc)
    if not self.invTypes then
        self.invTypes = {};
    end
    if itemEquipLoc then
        if not self.invTypes[itemEquipLoc] then
            self.invTypes[itemEquipLoc] = _G[itemEquipLoc];
        end
        return self.invTypes[itemEquipLoc] or "Invalid Loc"
    end
end


NarciWeaponTooltipMixin = {};

function NarciWeaponTooltipMixin:OnLoad()
    local a = 12;

    NarciAPI.NineSliceUtil.SetUpBackdrop(self, "blizzardTooltipBorder", 0, 0.27, 0.27, 0.27);

    local p = self.Pointer;
    p:ClearAllPoints();
    p:SetSize(a, a);
    p:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Tooltip\\Tooltip-Grey27-Pointer");
    p:SetPoint("RIGHT", self, "LEFT", 1, 0);

    self.ItemIcon:ClearAllPoints();
    self.ItemIcon:SetPoint("TOPLEFT", self, "TOPLEFT", TOOLTIP_PADDING, -TOOLTIP_PADDING);

    self.uiScale = UIParent:GetEffectiveScale();
    self:SetAlpha(0);

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;

    self:ToggleExtraInfo(false);
end

function NarciWeaponTooltipMixin:FadeOut()
    FadeFrame(self, 0.12, 0);
end

function NarciWeaponTooltipMixin:OnHide()
    self:Hide();
    self:SetAlpha(0);
end

function NarciWeaponTooltipMixin:SetNameID(name, itemID, boundaryFrame)
    if name and itemID then
        self.itemID = itemID;
        local _, itemType, itemSubType, itemEquipLoc, icon = GetItemInfoInstant(itemID);
        self.ItemIcon:SetTexture(icon);
        self.IDText:SetText(DataProvider:GetInventoryName(itemEquipLoc).."  "..itemID);
        --local fileID = boundaryFrame.Model:GetModelFileID();
        --fileID = self.ItemIcon:GetTextureFileID();
        --self.IDText:SetText(itemID);
        
        self.Name:SetSize(0, 0);
        self.Name:SetText(name);
        local textWidth = self.Name:GetWrappedWidth();
        if textWidth > MAX_WIDTH then
            textWidth = MAX_WIDTH;
            self.Name:SetWidth(textWidth + 0.5);
        end
        
        textWidth = math.max(self.Name:GetWrappedWidth(), self.IDText:GetWrappedWidth());

        local textHeight = self.Name:GetHeight() + self.IDText:GetHeight() + 2;
        if self.showExtraInfo then
            self:SetExtraInfo(itemID, boundaryFrame.itemModID, boundaryFrame.sourceID);
            if textWidth < MIN_WIDTH then
                textWidth = MIN_WIDTH;
            end
            self.ExtraInfoFrame.shadow:SetWidth(textWidth);
            self.ExtraInfoFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -textHeight - 14);
        else
            
        end
        self:SetSize( textWidth + ICON_SIZE + 2*TOOLTIP_PADDING + 4, math.max(textHeight, ICON_SIZE) + 2*TOOLTIP_PADDING);

        if boundaryFrame then
            self.xMin = boundaryFrame:GetRight() - 24;
        else
            self.xMin = 0;
        end

        FadeFrame(self, 0.2, 1);
        self:OnUpdate();

        --[[
        if GetTransmogItemAppearanceID(itemID) then
            self.Name:SetTextColor(0.66, 0.66, 0.66);
        else
            self.Name:SetTextColor(1, 0.3137, 0.3137);
        end
        --]]
    else
        self:Hide();
    end
end

function NarciWeaponTooltipMixin:OnUpdate(elapsed)
    self.x, self.y = GetCursorPosition();
    self.x = self.x + 12;
    if (self.x - self.xMin) < -180 or (self.x - self.xMin) > 80 then
        self:Hide();
    end
    if self.x < self.xMin then
        self.x = 0.1*(self.x - self.xMin) + self.xMin;
    end
    self:SetPoint("LEFT", UIParent, "BOTTOMLEFT", self.x, self.y);
end


function NarciWeaponTooltipMixin:ToggleExtraInfo(state)
    if self.ExtraInfoFram then
        if state then
            if self.Load then
                self:Load();
            end
            EXTRA_HEIGHT = 24;
            self.ExtraInfoFrame:Show();
        else
            EXTRA_HEIGHT = 0;
            self.ExtraInfoFrame:Hide();
        end
    end;
    
    self.showExtraInfo = state;
end

function NarciWeaponTooltipMixin:Load()
    --Create Data Blocks
    local frame = CreateFrame("Frame", nil, self);
    self.ExtraInfoFrame = frame;
    frame:SetPoint("TOPLEFT", self, "TOPLEFT", 10, 0);

    frame.headers = {};
    frame.data = {};

    local headerNames = {
        "itemID", "modID", "sourceID", "visualID",
    }
    local testIDs = {
        182574, 34, 116654, 132498,
    }

    local totalWidth = 0;
    local blockWidth;
    
    for i = 1, 4 do
        frame.headers[i] = frame:CreateFontString(nil, "OVERLAY", "NarciIndicatorDigitTiny");
        frame.headers[i]:SetText(headerNames[i]);
        if i == 2 then
            blockWidth = 28;
        else
            blockWidth = 40;
        end
        frame.headers[i]:SetSize(blockWidth, 10);
        if i <= 2 then
            frame.headers[i]:SetPoint("TOPLEFT", frame, "TOPLEFT", totalWidth, -3);
        else
            frame.headers[i]:SetPoint("TOPLEFT", frame.headers[i - 1], "TOPRIGHT", 0, 0);
        end
        frame.headers[i]:SetTextColor(0.5, 0.5, 0.5);
        frame.data[i] = frame:CreateFontString(nil, "OVERLAY", "NarciIndicatorDigitTiny");
        frame.data[i]:SetText(testIDs[i]);
        frame.data[i]:SetWidth(blockWidth);
        frame.data[i]:SetPoint("TOP", frame.headers[i], "TOP", 0, -10);
        frame.data[i]:SetTextColor(1, 0.82, 0);
        totalWidth = totalWidth + blockWidth;
    end

    frame:SetSize(totalWidth, 40);
    MIN_WIDTH = totalWidth;

    --Inner Shadow
    local shadow = frame:CreateTexture(nil, "OVERLAY");
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    shadow:SetSize(totalWidth, 4);
    shadow:SetColorTexture(0, 0, 0, 0.5);
    frame.shadow = shadow;

    self.Load = nil;
end

function NarciWeaponTooltipMixin:SetExtraInfo(itemID, itemModID, sourceID)
    if not GetItemAppearanceID then
        GetItemAppearanceID = NarciItemDatabase.GetItemAppearanceID;
    end
    local frame = self.ExtraInfoFrame;

    if not sourceID then
        sourceID = NarciItemDatabase.GetSourceID(itemID);
    end
    frame.data[1]:SetText(itemID);
    frame.data[2]:SetText(itemModID);
    frame.data[3]:SetText(sourceID or "|cff545454--|r");
    if itemModID then
        frame.headers[2]:SetWidth(28);
        frame.headers[2]:Show();
        MIN_WIDTH = 148;
        local visualID = GetTransmogItemAppearanceID(itemID, itemModID);
        frame.data[4]:SetText(visualID or "|cff545454--|r");
        frame.data[1]:SetTextColor(0.87, 0.45, 0.15);
        frame.data[2]:SetTextColor(0.87, 0.45, 0.15);
    else
        frame.headers[2]:SetWidth(0.1);
        frame.headers[2]:Hide();
        if GetItemAppearanceID then
            local visualID = GetItemAppearanceID(itemID);
            frame.data[4]:SetText(visualID or "|cff545454--|r");
        end
        frame.data[1]:SetTextColor(1, 0.82, 0);
        MIN_WIDTH = 120;
    end
end