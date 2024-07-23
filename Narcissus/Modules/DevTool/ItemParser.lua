----Analyze itemLinks----

local _, addon = ...

local TOOLTIP_NAME = "NarciDevToolItemParserTooltip";

local PIXEL;
local MainFrame, ItemTooltip, ItemCards, EditBox;

local RECEPTOR_SIZE = 24;

local ITEM_STRING_FORMAT = {
    "itemID", "enchant", "gem1", "gem2", "gem3", "gem4", "suffix", "uniqueID", "playerLevel", "specID", "modifiersMask", "itemContext",
    "numBonusIDs",
};

--[[
    Results:
    Runecarved Lego:    #14 Runecarving Power
    First bonusID ~ Upgrade Level?
    3rd bonusID ~ Item level?

    ItemBonusListGroupID 228 ~ Upgrade Level 1/12 7773(ItemBonusListID), 12/12 7784
    The last bonusID control item level and difficuty (also item name suffix?)
--]]

local function ItemReceptor_OnEnter(self)
    if self.hasItem then
        self.Border:SetColorTexture(1, 1, 1);
    else
        local infoType, itemID, itemLink = GetCursorInfo();
        if not (infoType and infoType == "item") then
            self.Border:SetColorTexture(1, 0.13, 0.13);
        else
            self.Border:SetColorTexture(1, 1, 1);
        end
    end
end

local function ItemReceptor_OnLeave(self)
    self.Border:SetColorTexture(self.r, self.g, self.b);
end


local function ItemReceptor_SetColor(self, r, g, b)
    self.Border:SetColorTexture(r, g, b);
    self.r, self.g, self.b = r, g, b;
end

local function ItemReceptor_OnDropCursor(self)
    local infoType, itemID, itemLink = GetCursorInfo();
    if not (infoType and infoType == "item") then return end

    self:GetParent():SetItemLink(itemLink);
    ClearCursor();
end

local function AcquireCard()
    if not ItemCards then
        ItemCards = {};
    end
    local numCards = #ItemCards;
    for i = 1, numCards do
        if not ItemCards[i]:IsShown() then
            return ItemCards[i];
        end
    end

    numCards = numCards + 1;
    ItemCards[numCards] = CreateFrame("Frame", nil, MainFrame, "NarciDevToolItemParserItemCardTemplate");
    ItemCards[numCards].id = numCards;

    local OFFSET = 6;

    ItemCards[numCards]:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", OFFSET, -OFFSET + (1 - numCards) * 32);
    return ItemCards[numCards]
end

local function ShowHyperLinkOnTooltip(tooltip, hyperLink)
    if hyperLink then
        tooltip:SetOwner(MainFrame, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 10, -72);
        tooltip:SetHyperlink(hyperLink);
        --tooltip:SetMinimumWidth(254 / 0.8);
        local newHeight;
        local f = _G[TOOLTIP_NAME.."MoneyFrame1"];
        if f then
            f:Hide();
            f:ClearAllPoints();
            local i = tooltip:NumLines();
            local fontString = _G[TOOLTIP_NAME .."TextLeft".. i];
            local bottom = fontString:GetBottom();
            local top = tooltip:GetTop();
            newHeight = top - bottom;
        end
        tooltip:Show();
        if newHeight then
            tooltip:SetHeight(newHeight);
        end
    end
end

local function UpdateCustomItemLink(cardID)
    local link = "|Hitem";
    cardID = cardID or 1;
    local card = ItemCards[cardID];
    for i = 1, #card.ValueBoxes do
        link = link..( card.ValueBoxes[i]:GetLinkText() );
    end
    link = link .. "|h";
    card:SetItemLink(link);
end

local function ShowBoxLabel(valueBox)
    MainFrame.BoxLabel:ClearAllPoints();
    if valueBox then
        if valueBox.segmentLabel then
            MainFrame.BoxLabel:SetText("#"..valueBox.id.." "..valueBox.segmentLabel);
        else
            MainFrame.BoxLabel:SetText("#"..valueBox.id);
        end
        MainFrame.BoxLabel:SetPoint("BOTTOM", valueBox, "TOP", 0, 2);
        MainFrame.BoxLabel:Show();
    else
        MainFrame.BoxLabel:Hide();
    end
end


NarciDevToolNumberContainerMixin = {};

function NarciDevToolNumberContainerMixin:SetValue(value)
    value = tonumber(value) or 0;
    self.value = value;
    self.ValueText:SetText(value);
    if value ~= 0 then
        self.ValueText:SetTextColor(0.8, 0.8, 0.8);
    else
        self.ValueText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciDevToolNumberContainerMixin:GetValue()
    return self.value
end

function NarciDevToolNumberContainerMixin:GetLinkText()
    if self.value and self.value > 0 then
        return ":"..self.value
    else
        return ":"
    end
end

function NarciDevToolNumberContainerMixin:ShowHighlight(state)
    if state then
        self.Background:SetColorTexture(0.33, 0.33, 0.33);
    else
        self.Background:SetColorTexture(0, 0, 0);
    end
end

function NarciDevToolNumberContainerMixin:LockHighlight(state)
    self.highlightLocked = state;
    if state then
        self:ShowHighlight(true);
    else
        if not self:IsMouseOver() then
            self:ShowHighlight(false);
        end
    end
end

function NarciDevToolNumberContainerMixin:OnEnter()
    self:ShowHighlight(true);
    ShowBoxLabel(self);
end

function NarciDevToolNumberContainerMixin:OnLeave()
    if not self.highlightLocked then
        self:ShowHighlight(false);
    end
    ShowBoxLabel();
end

function NarciDevToolNumberContainerMixin:OnMouseDown()
    EditBox:AnchorToBox(self);
end


NarciDevToolItemParserItemCardMixin = {};

function NarciDevToolItemParserItemCardMixin:OnLoad()
    local f = self.Receptor;
    f:SetScript("OnEnter", ItemReceptor_OnEnter);
    f:SetScript("OnLeave", ItemReceptor_OnLeave);
    f:SetScript("OnClick", ItemReceptor_OnDropCursor);
    f:SetScript("OnReceiveDrag", ItemReceptor_OnDropCursor);
    f:SetSize(RECEPTOR_SIZE, RECEPTOR_SIZE);
    f.Exclusion:SetSize(RECEPTOR_SIZE - 2*PIXEL, RECEPTOR_SIZE - 2*PIXEL);
    ItemReceptor_SetColor(f, 0.5, 0.5, 0.5);

    self.ItemName:SetText("< Drop an item here");
end

function NarciDevToolItemParserItemCardMixin:SetItemLink(itemLink)
    if not C_Item.DoesItemExistByID(itemLink) then return end;

    self.itemLink = itemLink;
    local itemName, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc, itemIcon = GetItemInfo(itemLink);
    local itemString = string.match(itemLink, "item:([%-?%d:]+)");
    --local enchantID = GetItemEnchantID(itemLink);
    local r, g, b = GetItemQualityColor(itemQuality);   --GetCustomQualityColor
    self.Receptor.ItemIcon:SetTexture(itemIcon);
    ItemReceptor_SetColor(self.Receptor, r, g, b);

    self.ItemName:SetText(itemName);
    self.ItemName:SetTextColor(r, g, b);
    --self.ItemString:SetText(itemString);
    self.Receptor.hasItem = true;
    ShowHyperLinkOnTooltip(ItemTooltip, itemLink);


    if not self.ValueBoxes then
        self.ValueBoxes = {};
    end
    local values = {string.split(":", itemString)};
    for i = 1, #values do
        if not self.ValueBoxes[i] then
            self.ValueBoxes[i] = CreateFrame("Frame", nil, self, "NarciDevToolNumberContainerTemplate");
            self.ValueBoxes[i]:SetPoint("LEFT", self, "LEFT", 178 + 33 * (i - 1), 0);
            self.ValueBoxes[i].id = i;
            self.ValueBoxes[i].segmentLabel = ITEM_STRING_FORMAT[i];
        end
        self.ValueBoxes[i]:SetValue(values[i]);
    end
end

NarciDevToolItemParserMixin = {};

function NarciDevToolItemParserMixin:OnShow()
    if self.Init then
        self:Init();
    end
end

function NarciDevToolItemParserMixin:ShowFrame()
    self:Show();
end

function NarciDevToolItemParserMixin:Init()
    MainFrame = self;
    PIXEL = NarciAPI.GetPixelForWidget(self);

    self:RegisterForDrag("LeftButton");

    local locale = GetLocale();
    local version, build, date, tocversion = GetBuildInfo();
    local narciVersion = NarciAPI.GetAddOnVersionInfo(true);
    self.ClientInfo:SetText(locale.."  "..version.."."..build.."  "..narciVersion);

    ItemTooltip = CreateFrame("GameTooltip", TOOLTIP_NAME, self, "GameTooltipTemplate");
    local t = ItemTooltip;
    t:Hide();
    t:SetScale(1);

    t.textLeft1Font = "NarciFontUniversal9";
    t.textLeft2Font = "NarciFontUniversal8";
    t.textRight1Font = "NarciFontUniversal9";
    t.textRight2Font = "NarciFontUniversal8";
    t.NineSlice:Hide();

	t.TextLeft1:SetFontObject(t.textLeft1Font);
    t.TextLeft2:SetFontObject(t.textLeft2Font);
    t.TextRight1:SetFontObject(t.textRight1Font);
    t.TextRight2:SetFontObject(t.textRight2Font);

    local backdrop = t:CreateTexture(nil, "BACKGROUND");
    backdrop:SetPoint("TOPLEFT", t, "TOPLEFT", 0, 0);
    backdrop:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 0, 0);
    backdrop:SetColorTexture(0, 0, 0);

    local border = t:CreateTexture(nil, "BORDER");
    border:SetPoint("TOPLEFT", t, "TOPLEFT", 0, 0);
    border:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 0, 0);
    border:SetColorTexture(0.33, 0.33, 0.33);

    local mask = t:CreateMaskTexture(nil, "BORDER");
    mask:SetPoint("TOPLEFT", border, "TOPLEFT", PIXEL, -PIXEL);
    mask:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -PIXEL, PIXEL);
    mask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");
    border:AddMaskTexture(mask);

    AcquireCard();
    AcquireCard();

    NarciDevToolItemParserMixin.Init = nil;
    self.Init = nil;
end

function NarciDevToolItemParserMixin:OnDragStart()
    self:StartMoving();
end

function NarciDevToolItemParserMixin:OnDragStop()
    self:StopMovingOrSizing();
end


NarciDevToolItemParserEditBoxMixin = {};

function NarciDevToolItemParserEditBoxMixin:OnLoad()
    EditBox = self;
    self.Background:SetColorTexture(0, 122/255, 204/255);
    self:SetHighlightColor(0, 0, 0);
end

function NarciDevToolItemParserEditBoxMixin:OnEditFocusLost()
    self:Hide();
end

function NarciDevToolItemParserEditBoxMixin:OnEditFocusGained()
    self:HighlightText();
end

function NarciDevToolItemParserEditBoxMixin:QuitEdit()
    self:Hide();
end

function NarciDevToolItemParserEditBoxMixin:ConfirmEdit()
    local value = self:GetNumber() or 0;
    self.parentBox:SetValue(value);
    self:Hide();
    UpdateCustomItemLink(self.parentBox:GetParent().id);
end

function NarciDevToolItemParserEditBoxMixin:OnTextChanged(text, isUserInput)

end

function NarciDevToolItemParserEditBoxMixin:OnHide()
    self:Hide();
end

function NarciDevToolItemParserEditBoxMixin:AnchorToBox(valueBox)
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", valueBox, "TOPLEFT", 0, 0);
    self:SetPoint("BOTTOMRIGHT", valueBox, "BOTTOMRIGHT", 0, 0);
    self:SetText(valueBox:GetValue());
    self:SetFrameLevel(valueBox:GetFrameLevel() + 2);
    self:Show();
    self.parentBox = valueBox;
    self:SetFocus();
end
