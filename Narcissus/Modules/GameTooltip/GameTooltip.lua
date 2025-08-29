local _, addon = ...

local TOOLTIP_NAME = "NarciGameTooltip";

local floor = math.floor;
local gsub = string.gsub;
local format = string.format;
local match = string.match;
local strtrim = strtrim;
local unpack = unpack;

local _G = _G;
local NarciAPI = NarciAPI;
local FadeFrame = NarciFadeUI.Fade;
local C_Item = C_Item;
local GetItemStats = C_Item.GetItemStats;
local GetItemSpell = C_Item.GetItemSpell;
local GetItemInfo = C_Item.GetItemInfo;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo;
local GetInventoryItemLink = GetInventoryItemLink;
local GetInventoryItemDurability = GetInventoryItemDurability;
local Model_ApplyUICamera = Model_ApplyUICamera;
local C_TransmogCollection = C_TransmogCollection;
local GetSlotVisualInfo = C_Transmog.GetSlotVisualInfo;
local EJ_SetSearch = EJ_SetSearch;

local GetItemQualityColor = NarciAPI.GetItemQualityColor;

local SharedTooltipDelay = addon.SharedTooltipDelay;
local TransmogDataProvider = addon.TransmogDataProvider;
local SetModelByUnit = addon.TransitionAPI.SetModelByUnit;
local ItemCacheUtil = addon.ItemCacheUtil;
local SetupSpecialItemTooltip = addon.SetupSpecialItemTooltip;

local PT_EQUIPMENT_SETS = gsub(EQUIPMENT_SETS, ".cFF.+", "");
local PT_ITEM_SOULBOUND = ITEM_SOULBOUND;
local PT_DURABILITY = "|TInterface\\AddOns\\Narcissus\\Art\\GameTooltip\\ExclamationMark:14:14:2:-2:32:32:0:32:0:32:255:109:15|t   "..(DURABILITY_TEMPLATE or "Durability %d / % d");
local PT_DPS_TEMPLATE = gsub(DPS_TEMPLATE, "%%s", "%%.1f");
local ENCHANTED_TOOLTIP_LINE = ENCHANTED_TOOLTIP_LINE or "Enchanted: %s";

local GenericTooltip, EquipmentTooltip;

local function IsColorRelevant(r, g, b)
    return not (r == 1 and g == 0.5 and b == 1)
end

local function IsTextRelevant(text)
    return not (strtrim(text) == "" or match(text, "<", 1) or match(text, PT_EQUIPMENT_SETS, 1) or match(text, PT_ITEM_SOULBOUND, 1) )
end

--[[
    1, 0.13, 0.13  --red
    0, 1, 0     --green
    1, 1, 1     --white
    1, 0.5, 1   --pink transmog

    GetSpellBaseCooldown
    GetItemSpell
    
    C_TradeSkillUI.GetItemCraftedQualityByItemInfo(itemLink)
--]]
local function Round(a)
    return tonumber(format("%.2f", floor(a*100+0.5)*0.01 ))
end

local function RoundColor(r, g, b)
    return Round(r), Round(g), Round(b)
end

local function VoidFunc(self)
end

local function AppendItemIDToGameTooltip(self)
    if not TooltipUtil.GetDisplayedItem then return end;

    local name, itemLink = TooltipUtil.GetDisplayedItem(self);
    if itemLink then
        local itemID = match(itemLink, "item:(%d+)");
        local spellID;
        name, spellID = GetItemSpell(itemLink);
        if spellID then
            self:AddDoubleLine(format("|cff545454ItemID|r |cff808080%s|r", itemID), format("|cff545454SpellID|r |cff808080%s|r", spellID));
        else
            self:AddLine(format("|cff545454ID|r |cff808080%s|r", itemID));
        end
    end
end

local GENERIC_SETUP_FUNC = VoidFunc;
local GameTooltip_ClearMoney = GameTooltip_ClearMoney or VoidFunc;

if addon.IsDragonflight() and TooltipDataHandlerMixin then
    NarciGameTooltipMixin = CreateFromMixins(TooltipDataHandlerMixin);
else
    NarciGameTooltipMixin = {};
end


function NarciGameTooltipMixin:OnLoad()
    GenericTooltip = self;
    NarciAPI.NineSliceUtil.SetUpBackdrop(self, "phantom", 0, 20/255, 24/255, 28/255);
    NarciAPI.NineSliceUtil.SetUpBorder(self, "shadowHugeR0", 0);
    local p = 8;
    self:SetPadding(p, p, p, p);
    self.leftTexts = {};
    self.rightTexts = {};

    self:SetFrameStrata("TOOLTIP");
    self:SetFixedFrameStrata(true);
end

function NarciGameTooltipMixin:OnShow()

end

function NarciGameTooltipMixin:OnHide()
    SharedTooltipDelay:Kill();
    self:SetScript("OnUpdate", nil);
end

function NarciGameTooltipMixin:OnTooltipCleared()
    GameTooltip_ClearMoney(self);
    SharedTooltip_ClearInsertedFrames(self);
end

function NarciGameTooltipMixin:OnSizeChanged(w, h)

end

function NarciGameTooltipMixin:UpdateTextColor()
    local r, g, b;
    local text, count;
    local numLines = self:NumLines();
    for i = 1, numLines do
        if not self.leftTexts[i] then
            self.leftTexts[i] = _G[TOOLTIP_NAME.."TextLeft"..i];
        end
        if self.leftTexts[i] then
            r, g, b = RoundColor(self.leftTexts[i]:GetTextColor());
            if r == 1 and g == 1 and b == 1 then
                self.leftTexts[i]:SetTextColor(0.8863, 0.8863, 0.8863);
            elseif r == 0 and g == 1 and b == 0 then    --green
                self.leftTexts[i]:SetTextColor(0.4353, 0.8039, 0.4784);
            elseif r == 1 and g == 0.13 and b == 0.13 then
                self.leftTexts[i]:SetTextColor(119/255, 119/255, 119/255);
            elseif r == 1 and g == 0.82 and b == 0 then  --yellow
                self.leftTexts[i]:SetTextColor(222/255, 179/255, 0/255);
                text = self.leftTexts[i]:GetText();
                if text then
                    text, count = gsub(text, "|cffffffff", "|cffe2e2e2");
                    text, count = gsub(text, "|cFFFFFFFF", "|cffe2e2e2");
                    --if count > 0 then
                        self.leftTexts[i]:SetText(text);
                    --end
                end
            end
        end
        if not self.rightTexts[i] then
            self.rightTexts[i] = _G[TOOLTIP_NAME.."TextRight"..i];
        end
        if self.rightTexts[i] then
            r, g, b = RoundColor(self.rightTexts[i]:GetTextColor());
            if r == 1 and g == 1 and b == 1 then
                self.rightTexts[i]:SetTextColor(0.8863, 0.8863, 0.8863);
            end
        end
    end
end

function NarciGameTooltipMixin:AnchorToSlotButton(slotButton, offsetX, offsetY)
    self:ClearAllPoints();
    self:SetOwner(slotButton, "ANCHOR_NONE");
    offsetX = offsetX or 0;
    offsetY = offsetY or 0;
    if slotButton.isRight then
        self:SetPoint("TOPRIGHT", slotButton, "TOPLEFT", -offsetX, offsetY);
    else
        self:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", offsetX, offsetY);
    end
end

function NarciGameTooltipMixin:SetFromSlotButton(slotButton, offsetX, offsetY, delay)
    if delay then
        SharedTooltipDelay:Setup(slotButton, delay, self.SetFromSlotButton, self, slotButton, offsetX, offsetY);
    else
        self:AnchorToSlotButton(slotButton, offsetX, offsetY);
        self:SetInventoryItem("player", slotButton.slotID, nil, true);
        GENERIC_SETUP_FUNC(self);
        self:Show();
        self:FadeIn();
    end
end

function NarciGameTooltipMixin:SetTransmogFromSlotButton(slotButton, offsetX, offsetY)
    self:AnchorToSlotButton(slotButton, offsetX, offsetY);
    if slotButton.hyperlink then
        self:SetHyperlink(slotButton.hyperlink);
        self:Show();
        self:FadeIn();
    end
end

function NarciGameTooltipMixin:SetItemLinkAndAnchor(itemLink, anchorTo, offsetX, offsetY)
    if itemLink and anchorTo then
        self:AnchorToSlotButton(anchorTo, offsetX, offsetY);
        self:SetHyperlink(itemLink);
        GENERIC_SETUP_FUNC(self);
        self:Show();
        self:FadeIn();
    end
end

function NarciGameTooltipMixin:HideTooltip()
    self:Hide();
    SharedTooltipDelay:Kill();
end

function NarciGameTooltipMixin:FadeIn()
    self:StopFading();
    self.AnimIn:Play();
end

local function TooltipFadeOut_OnUpdate(self, elapsed)
    self.alpha = self.alpha - 4 * elapsed;
    if self.alpha <= 0 then
        self:StopFading();
        self:Hide();
    else
        self:SetAlpha(self.alpha);
    end
end

function NarciGameTooltipMixin:FadeOut()
    if self:IsVisible() then
        self.AnimIn:Stop();
        self.alpha = 1;
        self:SetScript("OnUpdate", TooltipFadeOut_OnUpdate);
    end
end

function NarciGameTooltipMixin:StopFading()
    self.AnimIn:Stop();
    self:SetScript("OnUpdate", nil);
    self.alpha = nil;
end

---- Equipment Tooltip (for displaying gears/mogs in character frame) ----

local function OnModelLoaded(self)
    if self.cameraID then
        Model_ApplyUICamera(self, self.cameraID);
    end
end

local STATS_COLOR = {
    [0] = {0.5, 0.5, 0.5},
    [1] = {0.8863, 0.8863, 0.8863},     --white
    [2] = {0.4353, 0.8039, 0.4784},     --green
    [3] = {1, 0.82, 0},                 --bliz yellow
    [4] = {0.9412, 0.3490, 0.3490},     --red
    [5] = {0.8275, 0.7804, 0.5529},     --flavor text
    [6] = {1, 0.4275, 0.0588},          --Low durability
    [7] = {0.8610, 0.8610, 0.4549},     --Light Yellow: For equipped set items   1, 1, 0.6
};

local TOOLTIP_PADDING = 24;
local MIN_TEXT_WIDTH = 240 - 2 * TOOLTIP_PADDING;
local SEG_INSETS = 12;
local DIVIDER_HEIGHT = 0;
local MODEL_SIZE_RATIO = 0.7647;

local function GetColorByIndex(index)
    return unpack(STATS_COLOR[index]);
end

local function CompareWidth(fontString, lastMax)
    local width = fontString:GetWrappedWidth();
    return ((width > lastMax) and width) or lastMax
end

local STATS_ORDER = {
    {"RESISTANCE0_NAME", "%d ", 1},     --Armor
    {"ITEM_MOD_BLOCK_RATING_SHORT", "%d ", 1},   --Block not in the itemstats payload but will be inserted later

    {"ITEM_MOD_AGILITY_SHORT", "+%d ", 1},
    {"ITEM_MOD_STRENGTH_SHORT", "+%d ", 1},
    {"ITEM_MOD_INTELLECT_SHORT", "+%d ", 1},
    {"ITEM_MOD_STAMINA_SHORT", "+%d ", 1},

    {"ITEM_MOD_CRIT_RATING_SHORT", "+%d ", 2, "crit"},
    {"ITEM_MOD_HASTE_RATING_SHORT", "+%d ", 2, "haste"},
    {"ITEM_MOD_MASTERY_RATING_SHORT", "+%d ", 2, "mastery"},
    {"ITEM_MOD_VERSATILITY", "+%d ", 2, "versatility"},

    {"ITEM_MOD_CR_STURDINESS_SHORT", "", 2},
    {"ITEM_MOD_CR_SPEED_SHORT", "+%d ", 2},
    {"ITEM_MOD_CR_LIFESTEAL_SHORT", "+%d ", 2},
    {"ITEM_MOD_CR_AVOIDANCE_SHORT", "+%d ", 2},
};

local function AppendItemID(tooltip)
    local spellID = tooltip:GetItemSpellID();
    if spellID then
        tooltip:AddDoubleLine(format("|cff545454ItemID|r |cff808080%s|r", tooltip.itemID), format("|cff545454SpellID|r |cff808080%s|r", spellID), 1, 1, 1, (tooltip.numLines > 0 and - SEG_INSETS));
    else
        tooltip:AddLine(format("|cff545454ItemID|r |cff808080%s|r", tooltip.itemID), 1, 1, 1, (tooltip.numLines > 0 and - SEG_INSETS));
    end
end

local ADDTIONAL_SETUP_FUNC = VoidFunc;


local ItemDropLocation = {};

function ItemDropLocation:SetDropLocation(itemID, locationText)
    if not self.items then
        self.items = {};
    end
    self.items[itemID] = locationText or "";
end

function ItemDropLocation:GetItemDropLocation(itemID)
    if itemID and self.items then
        return self.items[itemID];
    end
end

function ItemDropLocation:IsItemCached(itemID)
    return itemID and self.items and self.items[itemID];
end

function ItemDropLocation:DoesItemHaveDropLocation(itemID)
    return self:IsItemCached(itemID) and self.items[itemID] ~= ""
end


local ItemLoader = CreateFrame("Frame");

local function ItemLoader_OnUpdate(self, elapased)
    self.t = self.t + elapased;
    if self.t >= 0 then
        self:SetScript("OnUpdate", nil);
        self.t = nil;
        EquipmentTooltip:OnDataLoaded();
    end
end

function ItemLoader:QueryData(itemLink, itemID)
    self.t = -0.2;
    self.pendingItemID = itemID;
    self:SetScript("OnUpdate", ItemLoader_OnUpdate);
    C_Item.RequestLoadItemDataByID(itemLink);
end

function ItemLoader:LoadItemData(link, itemID, forceUpdateItemData)
    if forceUpdateItemData or (not ItemCacheUtil:IsItemDataCached(itemID)) then
        if C_Item.DoesItemExistByID(link) then
            self:QueryData(link, itemID);
        end
    else
        if self.pendingItemID then
            self.pendingItemID = nil;
            self:SetScript("OnUpdate", nil);
        end
    end
end


NarciEquipmentTooltipMixin = {};

function NarciEquipmentTooltipMixin:OnLoad()
    EquipmentTooltip = self;
    local FRAME_WIDTH = 320;
    local padding = TOOLTIP_PADDING;

    local textWidth = FRAME_WIDTH - 2 * padding;
    self.textWidthDefault = textWidth;
    self.textWidthNoModel = FRAME_WIDTH - 40 - 2 * padding;
    self.textWidth = self.textWidthNoModel;
    self:SetEmbededFrameWidth(self.textWidth);

    self.SpellFrame.isActive = true;
    self.SpellFrame.InactiveAlert:SetTextColor(GetColorByIndex(4));
    self.SpellFrame:SetCooldownTextColor(GetColorByIndex(1));

    NarciAPI.NineSliceUtil.SetUpBorder(self, "shadowHugeR0", 0);
    NarciAPI.NineSliceUtil.SetUpBackdrop(self, "phantom", 0, 20/255, 24/255, 28/255);

    self.leftTexts = {};
    self.rightTexts = {};
    self:ClearLines();

    self.transmogLocation = CreateFromMixins(TransmogLocationMixin);

    self.padding = padding;
    self.headerPadding = padding + SEG_INSETS;
    self.HeaderFrame.ItemName:ClearAllPoints();
    self.HeaderFrame.ItemLevel:ClearAllPoints();
    self.HeaderFrame.ItemType:ClearAllPoints();
    self.HeaderFrame.LevelSubText:ClearAllPoints();
    self.HeaderFrame.ItemName:SetPoint("TOPLEFT", self.HeaderFrame, "TOPLEFT", padding, -padding);
    self.HeaderFrame.ItemLevel:SetPoint("TOPLEFT", self.HeaderFrame.ItemName, "BOTTOMLEFT", 0, -2);
    self.HeaderFrame.ItemType:SetPoint("TOPLEFT", self.HeaderFrame.ItemLevel, "BOTTOMLEFT", 0, -2);
    self.HeaderFrame.ItemType:SetTextColor(GetColorByIndex(1));
    self.HeaderFrame.LevelSubText:SetPoint("TOPLEFT", self.HeaderFrame.ItemLevel, "TOPRIGHT", 3, -2);
    self.HeaderFrame.LevelSubText:SetTextColor(GetColorByIndex(1));
    self.HeaderFrame.ItemName:SetWidth(self.textWidthDefault - 78);
    self.HeaderFrame.ItemName:SetShadowOffset(2, -2);
    self.HeaderFrame.ItemLevel:SetShadowOffset(4, -4);

    self.AttributeFrame:SetPoint("TOPLEFT", self.HeaderFrame, "BOTTOMLEFT", padding, -SEG_INSETS - DIVIDER_HEIGHT);
    self.AttributeFrame:SetPoint("TOPRIGHT", self.HeaderFrame, "BOTTOMRIGHT", -padding, -SEG_INSETS - DIVIDER_HEIGHT);

    self.ItemModel:SetUseTransmogSkin(true);  --not self.usePlayerSkin
    self.ItemModel:SetAutoDress(false);
    self.ItemModel:SetKeepModelOnHide(true);
    self.ItemModel:SetDoBlend(false);
    self.ItemModel:Undress();
    self.ItemModel:FreezeAnimation(0, 0, 0);
    self.ItemModel:SetUseTransmogChoices(true);
    self.ItemModel:SetObeyHideInTransmogFlag(true);
    self.ItemModel:SetScript("OnModelLoaded", OnModelLoaded);
    self.ItemModel:SetModelDrawLayer("BACKGROUND", 1);

    self:SetFrameStrata("TOOLTIP");
    self:SetFixedFrameStrata(true);

    local alwaysShown = true;
    self.HotkeyFrame = CreateFrame("Frame", nil, self, "NarciHotkeyNotificationTemplate");
    self.HotkeyFrame:SetPoint("BOTTOM", self, "TOP", 0, 8);
    self.HotkeyFrame:SetKey(NARCI_MODIFIER_ALT, "LeftButton", Narci.L["Swap items"], alwaysShown);
    self.HotkeyFrame:SetIgnoreParentScale(true);
    self.HotkeyFrame:Show();

    addon.ModuleManager:AddGamePadCallbackWidget(self);

    NarciAPI.InitializeModelLight(self.ItemModel);
end

function NarciEquipmentTooltipMixin:OnShow()
    self:RegisterEvent("TOOLTIP_DATA_UPDATE");
end

function NarciEquipmentTooltipMixin:OnHide()
    SharedTooltipDelay:Kill();
    self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
    self.dataInstanceID = nil;
end

function NarciEquipmentTooltipMixin:OnEvent(event, ...)
    if event == "TOOLTIP_DATA_UPDATE" then
        local dataInstanceID = ...
        if dataInstanceID == self.dataInstanceID then
            self:OnDataLoaded();
        end
    end
end

function NarciEquipmentTooltipMixin:EvaluateMaxWidth(width)
    if width > self.maxWidth then
        self.maxWidth = width;
    end
end

function NarciEquipmentTooltipMixin:SetEmbededFrameWidth(width)
    self.SpellFrame:SetFrameWidth(width);
    self.GemFrame:SetFrameWidth(width);
end

function NarciEquipmentTooltipMixin:AddLine(text, r, g, b, offsetY)
    if not text then return end
    local n = self.numLines + 1;
    self.numLines = n;
    offsetY = offsetY or -4;
    if not self.leftTexts[n] then
        self.leftTexts[n] = self.AttributeFrame:CreateFontString(nil, "ARTWORK", self.textFont);
        self.leftTexts[n]:SetSpacing(2);
        self.leftTexts[n]:SetJustifyH("LEFT");
    end
    self.leftTexts[n]:ClearAllPoints();
    if self.bottomObject then
        self.leftTexts[n]:SetPoint("TOPLEFT", self.bottomObject, "BOTTOMLEFT", 0, offsetY);
    else
        self.leftTexts[n]:SetPoint("TOPLEFT", self.AttributeFrame, "TOPLEFT", 0, offsetY);
    end
    self.leftTexts[n]:SetWidth(self.textWidth);
    self.leftTexts[n]:SetText(text);
    self.leftTexts[n]:SetTextColor(r or 0.8863, g or 0.8863, b or 0.8863, 1);
    self.leftTexts[n]:Show();
    self.maxWidth = CompareWidth(self.leftTexts[n], self.maxWidth);
    self.bottomObject = self.leftTexts[n];
end

function NarciEquipmentTooltipMixin:AddColoredText(text, colorIndex, offsetY)
    local r, g, b = GetColorByIndex(colorIndex);
    self:AddLine(text, r, g, b, offsetY);
end

function NarciEquipmentTooltipMixin:IsBottomObjectFontString()
    return self.bottomObject and self.bottomObject:IsObjectType("FontString")
end

function NarciEquipmentTooltipMixin:AddDoubleLine(text1, text2, r, g, b, offsetY)
    if not text1 then return end
    local n = self.numLines + 1;
    local p = self.numRightLines + 1;
    self.numLines = n;
    self.numRightLines = p;
    offsetY = offsetY or -4;
    if not self.leftTexts[n] then
        self.leftTexts[n] = self.AttributeFrame:CreateFontString(nil, "ARTWORK", self.textFont);
        self.leftTexts[n]:SetSpacing(2);
        self.leftTexts[n]:SetJustifyH("LEFT");
    end
    self.leftTexts[n]:ClearAllPoints();
    if self.bottomObject then
        self.leftTexts[n]:SetPoint("TOPLEFT", self.bottomObject, "BOTTOMLEFT", 0, offsetY);
    else
        self.leftTexts[n]:SetPoint("TOPLEFT", self.AttributeFrame, "TOPLEFT", 0, offsetY);
    end
    self.leftTexts[n]:SetWidth(self.textWidth);
    self.leftTexts[n]:SetText(text1);
    self.leftTexts[n]:SetTextColor(r or 0.8863, g or 0.8863, b or 0.8863);
    self.leftTexts[n]:Show();
    self.bottomObject = self.leftTexts[n];

    if not self.rightTexts[p] then
        self.rightTexts[p] = self.AttributeFrame:CreateFontString(nil, "ARTWORK", self.textFont);
        self.rightTexts[p]:SetSpacing(2);
        self.rightTexts[p]:SetJustifyH("RIGHT");
    end
    self.rightTexts[p]:ClearAllPoints();
    self.rightTexts[p]:SetWidth(self.textWidth);
    self.rightTexts[p]:SetPoint("RIGHT", self.AttributeFrame, "RIGHT", 0, 0);
    self.rightTexts[p]:SetPoint("TOP", self.leftTexts[n], "TOP", 0, 0);
    self.rightTexts[p]:SetText(text2);
    self.rightTexts[p]:SetTextColor(r or 0.8863, g or 0.8863, b or 0.8863);
    self.rightTexts[p]:Show();

    local width = self.leftTexts[n]:GetWrappedWidth() + self.rightTexts[p]:GetWrappedWidth() + 20;
    if width > self.maxWidth then
        self.maxWidth = width
    end
end

function NarciEquipmentTooltipMixin:ClearLines()
    self.numLines = 0;
    self.numRightLines = 0;
    self.maxWidth = 0;
    self.bottomObject = nil;
    self.baseSourceID = nil;
    self.baseVisualID = nil;
    self.itemID = nil;
    self.itemIcon = nil;
    self.itemName = nil;
    self.itemLink = nil;

    for i = 1, #self.leftTexts do
        self.leftTexts[i]:Hide();
        self.leftTexts[i]:SetText(nil);
    end
    for i = 1, #self.rightTexts do
        self.rightTexts[i]:Hide();
        self.rightTexts[i]:SetText(nil);
    end

    self.HeaderFrame.ItemLevel:SetText(nil);
    self.HeaderFrame.LevelSubText:SetText(nil);
    self.HeaderFrame.CraftingQualityIcon:Hide();

    self.GemFrame:Clear();
    self.SpellFrame:Clear();
end

function NarciEquipmentTooltipMixin:InsertFrame(embededFrame)
    embededFrame:ClearAllPoints();
    if self.bottomObject then
        embededFrame:SetPoint("TOPLEFT", self.bottomObject, "BOTTOMLEFT", 0, -SEG_INSETS);
    else
        embededFrame:SetPoint("TOPLEFT", self.AttributeFrame, "TOPLEFT", 0, 0);
    end
    self.bottomObject = embededFrame;
end

function NarciEquipmentTooltipMixin:AddBlankLine()
    self:AddLine(" ");
end

function NarciEquipmentTooltipMixin:AddRows(rows, colorIndex, prefix, padFirstLine)
    colorIndex = colorIndex or 1;
    local r, g, b;
    if prefix then
        for i = 1, #rows do
            r, g, b = GetColorByIndex( (rows[i][2] and colorIndex) or 0 );
            if i == 1 then
                self:AddLine(prefix.. rows[i][1], r, g, b, (padFirstLine and -SEG_INSETS));
            else
                self:AddLine(prefix.. rows[i][1], r, g, b);
            end
        end
    else
        for i = 1, #rows do
            r, g, b = GetColorByIndex( (rows[i][2] and colorIndex) or 0 );
            if i == 1 then
                self:AddLine(rows[i][1], r, g, b, (padFirstLine and -SEG_INSETS));
            else
                self:AddLine(rows[i][1], r, g, b);
            end
        end
    end
end


function NarciEquipmentTooltipMixin:SetInventoryItem(slotID)
    self.transmogLocation:Set(slotID, 0, 0);
    self.slotID = slotID;
    self:ClearLines();
    self:SetUseTransmogLayout(false);

    local link = GetInventoryItemLink("player", slotID);
    if link then
        local itemData, requestEmbededData = NarciAPI.GetCompleteItemDataFromSlot(slotID);
        self:DisplayItemData(link, itemData, slotID, nil, nil, requestEmbededData);
        itemData = nil;
    else
        self:Hide();
    end
end

function NarciEquipmentTooltipMixin:DisplayItemData(link, itemData, slotID, visualID, sourceID, forceUpdateItemData)
    --link: the itemlink,  itemData: data obatined by scanning tooltip, slotID: if the item is an inventory item (equipped)
    link = string.match(link, "(item:[%-?%d:]+)");
    local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(link);
    ItemLoader:LoadItemData(link, itemID, forceUpdateItemData);
    local quality = link and C_Item.GetItemQualityByID(link);
    if quality then
        self.HeaderFrame.ItemName:SetTextColor( GetItemQualityColor(quality) );
    end
    local itemName = GetItemInfo(link);
    local itemLevel = GetDetailedItemLevelInfo(link);
    self.HeaderFrame.ItemName:SetText(itemName);
    self.HeaderFrame.ItemLevel:SetText(itemLevel);
    self.HeaderFrame.ItemIcon:SetTexture(icon);
    self.HeaderFrame.ItemIcon:SetVertexColor(0.6, 0.6, 0.6);
    self.itemID = itemID;
    self.itemName = itemName;
    self.itemIcon = icon;
    self.isWeapon = classID == 2;
    self.quality = quality;
    local validForTransmog = visualID or NarciAPI.IsSlotValidForTransmog(slotID);
    if validForTransmog ~= self.showItemModel then
        if validForTransmog then
            self.textWidth = self.textWidthDefault;
        else
            self.textWidth = self.textWidthNoModel;
        end
        self.showItemModel = validForTransmog
        self:SetEmbededFrameWidth(self.textWidth);
    end
    if itemData and itemData.itemType then
        itemSubType = itemData.itemType;        --the original itemSubType is plural, so use the item type displayed on the GameTooltip instead
    end
    if itemEquipLoc then
        if classID == 4 and subclassID == 0 then
            --Neck, rings, etc.
            self.HeaderFrame.ItemType:SetText(_G[itemEquipLoc]);
        else
            self.HeaderFrame.ItemType:SetText(_G[itemEquipLoc] .." · ".. itemSubType);
        end
    else
        self.HeaderFrame.ItemType:SetText(itemSubType);
    end
    if itemData then
        local levelSubtext;

        if itemData.context then
            levelSubtext = itemData.context;
        end

        if itemData.upgradeString then
            levelSubtext = itemData.upgradeString;
        elseif itemData.upgradeLevel then
            levelSubtext = format("%s/%s", itemData.upgradeLevel[1], itemData.upgradeLevel[2]);
        end

        if levelSubtext and itemData.fullyUpgradedItemLevel then
            local level1, level2 = match(levelSubtext, "(%d)/(%d)");
            if level1 and level2 and level1 ~= level2 then
                levelSubtext = levelSubtext.." |cff808080("..itemData.fullyUpgradedItemLevel..")|r";
            end
        end

        if levelSubtext then
            local temp = levelSubtext;
            local _, numNewLines = gsub(temp, "|n", " ");
            if numNewLines and numNewLines > 1 then
                --Remove one line break (10.2.0, old season item has very long subtext. e.g. "Raid Finder Dragonflight Season 2 Upgrade Level Veteran 8/8")
                levelSubtext = gsub(levelSubtext, "|n", " ", 1);
            end
        end
        self.HeaderFrame.LevelSubText:SetText(levelSubtext);

        if itemData.craftingQuality then
            local qualityTexture = self.HeaderFrame.CraftingQualityIcon;
            local craftingQuality = itemData.craftingQuality;
            local qualityAtlas = format("Professions-Icon-Quality-Tier%d-Small", craftingQuality);
            qualityTexture:ClearAllPoints();

            local offsetY;
            if craftingQuality == 2 then
                qualityTexture:SetSize(18, 18);
                offsetY = 2;
            elseif craftingQuality == 3 then
                qualityTexture:SetSize(16, 16);
                offsetY = -1;
            else
                qualityTexture:SetSize(12, 12);
                offsetY = -1;
            end

            qualityTexture:SetAtlas(qualityAtlas, false);
            qualityTexture:Show();

            if levelSubtext ~= nil and levelSubtext ~= "" then
                qualityTexture:SetPoint("LEFT", self.HeaderFrame.LevelSubText, "RIGHT", 4, 0);
            else
                qualityTexture:SetPoint("TOPLEFT", self.HeaderFrame.ItemLevel, "TOPRIGHT", 4, offsetY);
            end
        else
            self.HeaderFrame.CraftingQualityIcon:Hide();
        end

        if itemData.weaponInfo then
            self:AddDoubleLine(itemData.weaponInfo[1], itemData.weaponInfo[2], GetColorByIndex(1));
        end
    end

    local statsTable = GetItemStats(link);
    if statsTable then
        if self.isWeapon then
            local dps = statsTable["ITEM_MOD_DAMAGE_PER_SECOND_SHORT"]; --this value might be different for artifact
            if dps then
                self:AddLine(format(PT_DPS_TEMPLATE, dps), GetColorByIndex(1));    --DPS_TEMPLATE
                statsTable["ITEM_MOD_DAMAGE_PER_SECOND_SHORT"] = nil;
            end
        elseif classID == 4 and subclassID == 6 then
            local block = GetShieldBlock();
            if block and block > 0 then
                statsTable["ITEM_MOD_BLOCK_RATING_SHORT"] = block;
            end
        end

        if not (itemData and itemData.isLegionRemix) then
            local key;
            local statText;
            for i = 1, #STATS_ORDER do
                key = STATS_ORDER[i][1];
                if statsTable[key] then
                    statText = format(STATS_ORDER[i][2], statsTable[key]) .. _G[key];
                    if STATS_ORDER[i][4] then
                        statText = statText .. "|cff729a7c" .. NarciAPI.ConvertRatingToPercentage(STATS_ORDER[i][4], statsTable[key]) .. "|r";
                    end
                    self:AddLine(statText, GetColorByIndex(STATS_ORDER[i][3]));
                    statsTable[key] = nil;
                end
            end
            for k, v in pairs(statsTable) do
                if _G[k] and not match(k, "^EMPTY_SOCKET") then
                    statText = format("+%d %s", v, _G[k]);
                    self:AddLine(statText, GetColorByIndex(2));
                    --print(k)  --special stats
                end
            end
        end
    end


    if itemData.extraLines then --for Legion Remix
        for _, lineData in ipairs(itemData.extraLines) do
            if lineData[2] then --White
                self:AddLine(lineData[1], 1, 1, 1);
            else
                self:AddLine(lineData[1], 0.4353, 0.8039, 0.4784);
            end
        end
    end

    if itemData then
        if itemData.enchant then
            local r, g, b = GetColorByIndex(2);
            self:AddLine(format(ENCHANTED_TOOLTIP_LINE, itemData.enchant), r, g, b, -SEG_INSETS);
        end

        local anySocket, frameHeight, lineWidth = self.GemFrame:SetSocketInfo(itemData.socketInfo);
        if anySocket then
            self:InsertFrame(self.GemFrame);
            self:EvaluateMaxWidth(lineWidth);
        end

        if itemData.effects then
            local splitLines, lineText;
            for i = 1, #itemData.effects do
                if itemData.effects[i][1] == "use" then
                    self.SpellFrame:SetSpellEffect(link, itemData.effects[i][2], itemData.effects[i][3], itemData.effects[i][4]);
                    --self:InsertFrame(self.SpellFrame);
                else
                    local r, g, b = GetColorByIndex((itemData.effects[i][3] and 2) or 4);
                    --C_Item.GetFirstTriggeredSpellForItem(itemID, quality)
                    splitLines = {string.split("\n", itemData.effects[i][2])};  --adjust multiline spacing
                    for j = 1, #splitLines do
                        lineText = strtrim(splitLines[j]);
                        if lineText ~= "" then
                            self:AddLine(lineText, r, g, b, (self.bottomObject) and -SEG_INSETS);
                        end
                    end
                    --print(itemData.effects[i][2])
                end
            end
        end

        if itemData.itemSet then
            local r, g, b = GetColorByIndex(3);
            self:AddLine(itemData.itemSet.rawName, r, g, b, -SEG_INSETS);
            self:AddRows(itemData.itemSet.itemNames, 7, "   ");
            --self:AddBlankLine();
            self:AddRows(itemData.itemSet.bonuses, 2, nil, true);
        end

        if itemData.classesAllowed then
            local r, g, b = GetColorByIndex( (itemData.classesAllowed[2] and 1) or 4);
            self:AddLine(itemData.classesAllowed[1], r, g, b, -SEG_INSETS);
        end

        if itemData.flavorText then
            local r, g, b = GetColorByIndex(5);
            self:AddLine(itemData.flavorText, r, g, b, -SEG_INSETS);
        end
    end

    --Show durability under certain threshhold <50%
    if slotID then
        local currentDura, maxDura = GetInventoryItemDurability(slotID);
        if currentDura and maxDura and maxDura > 0 then
            if currentDura / maxDura <= 0.5 then
                self:AddLine(format(PT_DURABILITY, currentDura, maxDura), 1, 0.4275, 0.0588, -SEG_INSETS);
            end
        end
    end
    if validForTransmog and not visualID then
        self.baseSourceID, self.baseVisualID = GetSlotVisualInfo(self.transmogLocation);
    else
        self.baseSourceID, self.baseVisualID = sourceID, visualID;
    end
    self:SearchDropLocation(itemName, itemID, self.baseSourceID);

    self:SetAdditionalInfo(itemID, slotID);

    self:UpdateSize();
    self:SetItemModel();
    self:Show();
end

function NarciEquipmentTooltipMixin:SetTransmogSource(appliedSourceID)
    self:ClearLines();
    self:SetUseTransmogLayout(true);

    if appliedSourceID and appliedSourceID > 0 then
        local sourceInfo = C_TransmogCollection.GetSourceInfo(appliedSourceID);
        local itemName = sourceInfo and sourceInfo.name;
        if not itemName or itemName == "" then
            return
        end
        local appliedVisualID = sourceInfo.visualID;
        local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(sourceInfo.itemID);
        local quality = sourceInfo.quality;
        if quality then
            self.HeaderFrame.ItemName:SetTextColor( GetItemQualityColor(quality) );
        end
        self.HeaderFrame.ItemName:SetText(itemName);
        self.HeaderFrame.ItemIcon:SetTexture(icon);
        self.HeaderFrame.ItemIcon:SetVertexColor(0.6, 0.6, 0.6);
        self.isWeapon = classID == 2;
        self.quality = quality;
        if not self.showItemModel then
            self.showItemModel = true;
            self.textWidth = self.textWidthDefault;
            self:SetEmbededFrameWidth(self.textWidth);
        end
        if itemEquipLoc then
            if classID == 4 and subclassID == 0 then
                --Neck, rings, etc.
                self.HeaderFrame.ItemType:SetText(_G[itemEquipLoc]);
            else
                self.HeaderFrame.ItemType:SetText(_G[itemEquipLoc] .." · ".. itemSubType);
            end
        else
            self.HeaderFrame.ItemType:SetText(itemSubType);
        end

        local sourceText;

        if sourceInfo.sourceType == 1 then  --TRANSMOG_SOURCE_BOSS_DROP
            local location;
            local drops = C_TransmogCollection.GetAppearanceSourceDrops(appliedSourceID);
            if drops and drops[1] then
                local drop = drops[1];
                location = format(WARDROBE_TOOLTIP_ENCOUNTER_SOURCE, drop.encounter, drop.instance);
                local difficulty = drop.difficulties and drop.difficulties[1];
                if difficulty then
                    sourceText = format(WARDROBE_TOOLTIP_BOSS_DROP_FORMAT_WITH_DIFFICULTIES, location, difficulty)
                else
                    sourceText = format(WARDROBE_TOOLTIP_BOSS_DROP_FORMAT, location);
                end
            else
                sourceText = _G["TRANSMOG_SOURCE_1"];
            end
        else
            if sourceInfo.sourceType then
                sourceText = _G["TRANSMOG_SOURCE_".. sourceInfo.sourceType];
            end
        end

        if sourceText then
            self:AddLine(sourceText, GetColorByIndex(1));
        end

        local specialSourceText = TransmogDataProvider:GetSpecialItemSourceText(appliedSourceID, sourceInfo.itemID, sourceInfo.itemModID);

        if specialSourceText then
            if TransmogDataProvider:IsLegionArtifactBySourceID(appliedSourceID) then
                specialSourceText = (ARTIFACTS_APPEARANCE_TAB_TITLE or "Artifact Appearance") .. ":  "..specialSourceText;
            end
            self:AddLine(specialSourceText, GetColorByIndex(1));
        end

        --Model
        self.ItemModel.FadeIn:Stop();
        local cameraID = C_TransmogCollection.GetAppearanceCameraIDBySource(appliedSourceID);
        self.ItemModel.cameraID = cameraID;
        self.ItemModel:RefreshCamera();
        Model_ApplyUICamera(self.ItemModel, cameraID);
        --self.ItemModel.FadeIn.Hold:SetDuration(1);
        --self.ItemModel.FadeIn:Play();
        if not self.isWeapon then
            if appliedSourceID ~= self.ItemModel.id then
                self.ItemModel.id = appliedSourceID;
                SetModelByUnit(self.ItemModel, "player");
                self.ItemModel:TryOn(appliedSourceID);
            end
        else
            if appliedVisualID ~= self.ItemModel.id then
                self.ItemModel.id = appliedVisualID;
                self.ItemModel:SetItemAppearance(appliedVisualID);
            end
        end
        self.ItemModel:Show();
        self.HeaderFrame.ItemIcon:Hide();
        self.HeaderFrame.ItemIconMask:Hide();

        self:UpdateSize();
        self:Show();
    else
        self:Hide();
    end
end


local function Search_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.5 then
        self.t = 0;
        if EJ_IsSearchFinished() then
            self:SetScript("OnUpdate", nil);
            self:InsertDropLocation();
        end
    end
end

local function PauseSearching_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        if self.searchName then
            EJ_SetSearch(self.searchName);
            self:SetScript("OnUpdate", Search_OnUpdate);
            self.searchName = nil;
        else
            self.t = nil;
            self:SetScript("OnUpdate", nil);
        end
    end
end

function NarciEquipmentTooltipMixin:SearchDropLocation(itemName, itemID, baseSourceID)
    if ItemDropLocation:IsItemCached(itemID) then
        self:InsertDropLocation(itemID);
        self:SetScript("OnUpdate", nil);
        self.t = nil;
    else
        if not itemName then return end
        if baseSourceID then
            --for transmogable items
            self:SetScript("OnUpdate", nil);
            self.t = nil;
            local sourceText;
            local sourceInfo = C_TransmogCollection.GetSourceInfo(baseSourceID);
            if sourceInfo.sourceType == 1 then  --TRANSMOG_SOURCE_BOSS_DROP
                local location;
                local drops = C_TransmogCollection.GetAppearanceSourceDrops(baseSourceID);
                if drops and drops[1] then
                    local drop = drops[1];
                    sourceText = drop.instance;
                    if sourceText then
                        sourceText = sourceText.." > "..drop.encounter;
                    else
                        sourceText = drop.encounter;
                    end
                end
                if not sourceText then
                    sourceText = _G["TRANSMOG_SOURCE_1"];
                end
            else
                --Only displays the boss-dropped
                --[[
                if sourceInfo.sourceType then
                    sourceText = _G["TRANSMOG_SOURCE_"..sourceInfo.sourceType];
                end
                --]]
            end
            ItemDropLocation:SetDropLocation(itemID, sourceText);
            self:InsertDropLocation(itemID);
        else
            --for trinket/ring/necklace
            self.searchName = itemName;
            self.t = -0.2;   --start searching after the delay to minimize stuttering
            self:SetScript("OnUpdate", PauseSearching_OnUpdate);
        end
    end
end

function NarciEquipmentTooltipMixin:InsertDropLocation(itemID, locationText)
    if itemID then
        if locationText then
            self:AddLine(locationText, 0.5, 0.5, 0.5, -SEG_INSETS);
        elseif ItemDropLocation:DoesItemHaveDropLocation(itemID) then
            locationText = ItemDropLocation:GetItemDropLocation(itemID);
            self:AddLine(locationText, 0.5, 0.5, 0.5, -SEG_INSETS);
        end
        return
    end

    local numResults = EJ_GetNumSearchResults();
    if numResults > 0 then
        local id, stype, difficultyID, instanceID, encounterID, itemLink = EJ_GetSearchResult(1);
        if stype == 0 then  --loot
            local creatureName, _;
            local instanceName = instanceID and EJ_GetInstanceInfo(instanceID);
            if encounterID then
                local resultItemID = itemLink and tonumber( match(itemLink, "item:(%d+)") or "" ) or 0;
                if resultItemID == self.itemID then
                    creatureName, _, _, _, _, _, _, instanceID = EJ_GetEncounterInfo(encounterID);
                    if creatureName and instanceName then
                        local locationText = instanceName.." > "..creatureName;
                        self:AddLine(locationText, 0.5, 0.5, 0.5, -SEG_INSETS);
                        local fontString = self.bottomObject;
                        if fontString then
                            FadeFrame(fontString, 0.25, 1, 0);
                        end
                        self:UpdateSize();
                        ItemDropLocation:SetDropLocation(self.itemID, locationText)
                        return
                    end
                end
            end
        end
    end
    ItemDropLocation:SetDropLocation(self.itemID, nil);
end

function NarciEquipmentTooltipMixin:CalculateHeightAbove()
    if self.numLines > 0 then
        return self.HeaderFrame:GetBottom() - self.leftTexts[self.numLines]:GetBottom();
    else
        return 0
    end
end

function NarciEquipmentTooltipMixin:GetItemSpellID()
    local spellID1 = self.itemID and self.quality and C_Item.GetFirstTriggeredSpellForItem(self.itemID, self.quality);
    local spellID2 = self.SpellFrame.spellID;

    if spellID1 and spellID2 and spellID1 ~= spellID2 then
        return spellID1..", "..spellID2
    else
        return spellID1 or spellID2
    end
end

function NarciEquipmentTooltipMixin:SetItemModel()
    self.ItemModel.FadeIn:Stop();

    if not self.showItemModel then
        self.HeaderFrame.ItemIcon:Show();
        self.HeaderFrame.ItemIconMask:Show();
        self.ItemModel:Hide();
        return
    end

    if self.baseSourceID and self.baseVisualID then
        self.ItemModel:Show();
        self.ItemModel:SetUseTransmogSkin(true);
        --local baseSourceID, baseVisualID = GetSlotVisualInfo(self.transmogLocation);
        --local sourceID = transmogInfo.appearanceID;
        local cameraID = C_TransmogCollection.GetAppearanceCameraIDBySource(self.baseSourceID);
        if cameraID == 0 then
            cameraID = 238; --Use the Sword camera if the weapon is not transmoggable
        end
        self.ItemModel.cameraID = cameraID;
        self.ItemModel:RefreshCamera();
        Model_ApplyUICamera(self.ItemModel, cameraID);
        --self.ItemModel.FadeIn.Hold:SetDuration(1);
        --self.ItemModel.FadeIn:Play();
        if self.isWeapon then
            if self.ItemModel.id ~= self.baseVisualID then
                self.ItemModel.id = self.baseVisualID;
                self.ItemModel:SetItemAppearance(self.baseVisualID);
            end
        else
            if self.ItemModel.id ~= self.baseSourceID then
                self.ItemModel.id = self.baseSourceID;
                SetModelByUnit(self.ItemModel, "player");
                self.ItemModel:TryOn(self.baseSourceID);
            end
        end
        self.HeaderFrame.ItemIcon:Hide();
        self.HeaderFrame.ItemIconMask:Hide();
    else
        self.HeaderFrame.ItemIcon:Show();
        self.HeaderFrame.ItemIconMask:Show();
        self.ItemModel:Hide();
    end
end

function NarciEquipmentTooltipMixin:SetUseTransmogLayout(state)
    if state ~= self.transmogLayout then
        self.transmogLayout = state;
        self.HeaderFrame.ItemName:ClearAllPoints();
        self.HeaderFrame.ItemType:ClearAllPoints();
        if state then
            --hide item level, upgrade level
            self.HeaderFrame.ItemName:SetPoint("TOPLEFT", self.HeaderFrame, "TOPLEFT", TOOLTIP_PADDING, -36);
            self.HeaderFrame.ItemType:SetPoint("TOPLEFT", self.HeaderFrame.ItemName, "BOTTOMLEFT", 0, -4);
            self.headerPadding = 48 + SEG_INSETS;
            self.HeaderFrame.CraftingQualityIcon:Hide();
        else
            self.HeaderFrame.ItemName:SetPoint("TOPLEFT", self.HeaderFrame, "TOPLEFT", TOOLTIP_PADDING, -TOOLTIP_PADDING);
            self.HeaderFrame.ItemType:SetPoint("TOPLEFT", self.HeaderFrame.ItemLevel, "BOTTOMLEFT", 0, -2);
            self.headerPadding = TOOLTIP_PADDING + SEG_INSETS + 2;
        end
        self:ShowHotkey(not state);
    end
end

function NarciEquipmentTooltipMixin:ShowHotkey(state)
    self.HotkeyFrame:SetShown(state and not self.isGamepad);
end

function NarciEquipmentTooltipMixin:OnGamePadActiveChanged(isActive)
    self.isGamepad = isActive;
    if isActive then
        self:ShowHotkey(false);
    else
        self:ShowHotkey(not self.transmogLayout);
    end
end

function NarciEquipmentTooltipMixin:IsTransmogLayout()
    return self.transmogLayout
end

function NarciEquipmentTooltipMixin:UpdateSize()
    local padding = self.padding;
    local headerTextHeight = self.HeaderFrame.ItemName:GetTop() - self.HeaderFrame.ItemType:GetBottom();
    local headerHeight = headerTextHeight + self.headerPadding;
    self.HeaderFrame:SetHeight(headerHeight);
    self.HeaderFrame.ItemIcon:SetSize(headerHeight, headerHeight);
    local modelHeight = headerHeight - 10;
    local modelWidth = MODEL_SIZE_RATIO * modelHeight;
    self.ItemModel:SetSize(modelWidth, modelHeight);
    local headerWidth = math.max(self.HeaderFrame.ItemName:GetWrappedWidth() + (self.showItemModel and 0 or 52), self.HeaderFrame.ItemType:GetWrappedWidth()) + ((self.showItemModel and (modelWidth + 16) or 0));
    local maxWidth = self.maxWidth;
    if headerWidth > maxWidth then
        maxWidth = headerWidth;
    end
    maxWidth = math.max(maxWidth, MIN_TEXT_WIDTH);
    if self:GetItemSpellID() then
        self.SpellFrame:SetFrameWidth(maxWidth);
    end
    local fullHeight;
    if self.bottomObject then
        self.AttributeFrame:Show();
        fullHeight = self.HeaderFrame:GetTop() - self.bottomObject:GetBottom() + padding;
        self.ItemModel:SetPoint("BOTTOMRIGHT", self.HeaderFrame, "BOTTOMRIGHT", -padding, 1);
    else
        if self.transmogLayout then
            headerHeight = headerTextHeight + 72;
        else
            headerHeight = headerTextHeight + 2* padding;
        end
        fullHeight = headerHeight;
        self.HeaderFrame:SetHeight(headerHeight);
        self.AttributeFrame:Hide();
        self.ItemModel:SetPoint("BOTTOMRIGHT", self.HeaderFrame, "BOTTOMRIGHT", -padding, SEG_INSETS - 2);
    end
    local fullWidth = maxWidth + 2 * padding;
    self:SetSize(fullWidth, fullHeight);
end

function NarciEquipmentTooltipMixin:AnchorToSlotButton(slotButton, offsetX, offsetY)
    self:ClearAllPoints();
    offsetX = offsetX or 0;
    offsetY = offsetY or 0;
    if slotButton.isRight then
        self:SetPoint("TOPRIGHT", slotButton, "TOPLEFT", -offsetX, offsetY);
    else
        self:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", offsetX, offsetY);
    end
    self.anchorTo = slotButton;
    self.offsetX, self.offsetY = offsetX, offsetY;
end

function NarciEquipmentTooltipMixin:SetFromSlotButton(slotButton, offsetX, offsetY, delay, noFadeIn)
    if delay then
        SharedTooltipDelay:Setup(slotButton, delay, self.SetFromSlotButton, self, slotButton, offsetX, offsetY);
    else
        self:AnchorToSlotButton(slotButton, offsetX, offsetY);
        self:SetInventoryItem(slotButton.slotID);
        if not noFadeIn then
            self:FadeIn();
        end
    end
end

function NarciEquipmentTooltipMixin:SetTransmogFromSlotButton(slotButton, offsetX, offsetY, noFadeIn)
    self:AnchorToSlotButton(slotButton, offsetX, offsetY);
    self:SetTransmogSource(slotButton.sourceID);
    if not noFadeIn then
        self:FadeIn();
    end
end

function NarciEquipmentTooltipMixin:SetItemLinkAndAnchor(link, anchorTo, offsetX, offsetY, noFadeIn)
    self:ClearLines();
    self.slotID = nil;
    self.itemLink = link;
    self:SetUseTransmogLayout(false);
    if link and anchorTo then
        self:AnchorToSlotButton(anchorTo, offsetX, offsetY);
        local itemData = NarciAPI.GetCompleteItemDataByItemLink(link);
        local visualID, sourceID = C_TransmogCollection.GetItemInfo(link);
        self:DisplayItemData(link, itemData, nil, visualID, sourceID);
        itemData = nil;
        if not noFadeIn then
            self:FadeIn();
        end
    else
        self:Hide();
    end
end

function NarciEquipmentTooltipMixin:OnDataLoaded()
    if self:IsShown() and self.anchorTo then
        if self.transmogLayout then
            self:SetTransmogFromSlotButton(self.anchorTo, self.offsetX, self.offsetY, true)
        else
            if self.slotID then
                self:SetFromSlotButton(self.anchorTo, self.offsetX, self.offsetY, nil, true);
            else
                self:SetItemLinkAndAnchor(self.itemLink, self.anchorTo, self.offsetX, self.offsetY, true);
            end
        end
    end
end

local function ItemDataLoadedResult_OnEvent(self, event, itemID, success)
    if itemID == self.pendingItemID then
        self:SetScript("OnEvent", nil);
        self:OnDataLoaded();
        self.pendingItemID = nil;
        self.t = -0.2;
        print(event, itemID);
    end
end


function NarciEquipmentTooltipMixin:HideTooltip()
    self:Hide();
    self:ClearAllPoints();
    self:ClearLines();
    self:SetScript("OnUpdate", nil);
    SharedTooltipDelay:Kill();
end

function NarciEquipmentTooltipMixin:OnPixelChanged(pixel)

end

function NarciEquipmentTooltipMixin:FadeIn()
    self.AnimIn:Stop();
    self.AnimIn:Play();
    self.ItemModel.FadeIn:Stop();
    self.ItemModel.FadeIn:Play();
end

function NarciEquipmentTooltipMixin:SetAdditionalInfo(itemID, slotID)
    SetupSpecialItemTooltip(self, itemID, slotID);
    ADDTIONAL_SETUP_FUNC(self);
end

do
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.ShowItemIDOnTooltip(state, db)
        if state == nil then
            state = db["ShowItemID"];
        end
        if state then
            ADDTIONAL_SETUP_FUNC = AppendItemID;
            GENERIC_SETUP_FUNC = AppendItemIDToGameTooltip;
        else
            ADDTIONAL_SETUP_FUNC = VoidFunc;
            GENERIC_SETUP_FUNC = VoidFunc;
        end
    end
end