local _, addon = ...
local TransmogDataProvider = addon.TransmogDataProvider;
local DressingRoomSystem = addon.DressingRoomSystem;
local Mixin = Mixin;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;

local _G = _G;
local DressUpFrame = DressUpFrame;
local C_Item = C_Item;
local RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID;
local PlayerHasTransmog = C_TransmogCollection.PlayerHasTransmog;
local GetSourceItemID = C_TransmogCollection.GetSourceItemID;
local GetAppearanceInfoBySource = C_TransmogCollection.GetAppearanceInfoBySource;


local FRAME_WIDTH_BASE = 320;
local FRAME_WIDTH = 320;
local MAX_LABEL_WIDTH = 24;
local ITEMBUTTON_HEIGHT = 24;
local ITEMLIST_PADDING_Y = 12;
local SIZE_SCALE = 0.5;
local COLOR_1 = 0.80;
local COLOR_2 = 0.67;
local FILE = "Interface/AddOns/Narcissus/Art/Modules/DressingRoom/TransmogSetFrame.tga";


local TransmogSetFrame = CreateFrame("Frame", nil, UIParent);
TransmogSetFrame:SetSize(FRAME_WIDTH, 460);
TransmogSetFrame:Hide();
TransmogSetFrame.itemButtons = {};
DressingRoomSystem.TransmogSetFrame = TransmogSetFrame;

function TransmogSetFrame:Init()
    self.Init = nil;

    DressUpFrame.ModelScene:HookScript("OnDressModel", function(_, itemModifiedAppearanceID, invSlot, removed)
        self:OnDressModel(itemModifiedAppearanceID, invSlot, removed);
    end);

    NarciAPI.NineSliceUtil.CreateNineSlice(self);

    local slices = self.backdropTextures;
    for i = 1, 9 do
        slices[i]:SetTexture(FILE);
    end

    local sizeScale = SIZE_SCALE;
    local sizeUnit = 16 * sizeScale;

    slices[1]:SetTexCoord(0/1024, 32/1024, 0/1024, 32/1024);
    slices[1]:SetSize(2*sizeUnit, 2*sizeUnit);
    slices[1]:SetPoint("TOPLEFT", self, "TOPLEFT", -sizeUnit, sizeUnit);

    slices[2]:SetTexCoord(32/1024, 480/1024, 0/1024, 32/1024);

    slices[3]:SetTexCoord(480/1024, 512/1024, 0/1024, 32/1024);
    slices[3]:SetSize(2*sizeUnit, 2*sizeUnit);
    slices[3]:SetPoint("TOPRIGHT", self, "TOPRIGHT", sizeUnit, sizeUnit);

    slices[4]:SetTexCoord(0/1024, 32/1024, 32/1024, 160/1024);
    slices[5]:SetTexCoord(32/1024, 480/1024, 32/1024, 160/1024);
    slices[6]:SetTexCoord(480/1024, 512/1024, 32/1024, 160/1024);

    slices[7]:SetTexCoord(0/1024, 32/1024, 160/1024, 256/1024);
    slices[7]:SetSize(2*sizeUnit, 6*sizeUnit);
    slices[7]:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -sizeUnit, -sizeUnit);

    slices[8]:SetTexCoord(32/1024, 480/1024, 160/1024, 256/1024);

    slices[9]:SetTexCoord(480/1024, 512/1024, 160/1024, 256/1024);
    slices[9]:SetSize(2*sizeUnit, 6*sizeUnit);
    slices[9]:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", sizeUnit, -sizeUnit);

    self.maxWidth_Armor, self.maxWidth_Weapon = TransmogDataProvider:GetLongestLabelWidth(self, "GameFontNormalSmall2");
    MAX_LABEL_WIDTH = self.maxWidth_Armor;
    FRAME_WIDTH = FRAME_WIDTH_BASE + MAX_LABEL_WIDTH - 24;
    self:SetWidth(FRAME_WIDTH);

    --Footer
    self.Footer = CreateFrame("Frame", nil, self);
    self.Footer:SetHeight(78 * sizeScale);
    self.Footer:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0);
    self.Footer:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);

    self:CreateFooterCheckbox(Narci.L["Hide Player Items"], "ToggleRemovePlayerItems", "DressingRoomAutoRemoveNonSetItem", Narci.L["Hide Player Items Tooltip"]);


    --Header
    local headerHeight = 60;
    local titleOffsetY = 16;
    self.itemlistFromY = -headerHeight -ITEMLIST_PADDING_Y;

    self.Title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2");
    self.Title:SetJustifyH("CENTER");
    self.Title:SetWidth(FRAME_WIDTH - 32);
    self.Title:SetPoint("TOP", self, "TOP", 0, -titleOffsetY);
    self.Title:SetTextColor(COLOR_1, COLOR_1, COLOR_1);
    self.Title:SetMaxLines(1);

    self.Subtitle = self:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    self.Subtitle:SetJustifyH("CENTER");
    self.Subtitle:SetPoint("BOTTOM", self, "TOP", 0, -headerHeight + titleOffsetY - 4);
    self.Subtitle:SetTextColor(COLOR_2, COLOR_2, COLOR_2);

    self.Divider = self:CreateTexture(nil, "ARTWORK");
    self.Divider:SetHeight(64 * SIZE_SCALE);
    self.Divider:SetPoint("LEFT", self, "TOPLEFT", 0, -headerHeight);
    self.Divider:SetPoint("RIGHT", self, "TOPRIGHT", 0, -headerHeight);
    self.Divider:SetTexture(FILE);
    self.Divider:SetTexCoord(0, 0.5, 256/1024, 320/1024);


    self.ButtonHighlight = self:CreateTexture(nil, "ARTWORK");
    self.ButtonHighlight:Hide();
    self.ButtonHighlight:SetTexture(FILE);
    self.ButtonHighlight:SetTexCoord(0, 512/1024, 320/1024, 384/1024);
    self.ButtonHighlight:SetSize(FRAME_WIDTH, 64 * SIZE_SCALE);
    NarciAPI.DisableSharpening(self.ButtonHighlight);

    self:SetScript("OnShow", self.OnShow);
    self:SetScript("OnHide", self.OnHide);
    self:SetScript("OnEvent", self.OnEvent);
end

function TransmogSetFrame:SetItemSet(setName, items, setItemLink)
    if self.Init then
        self:Init();
    end

    self:Show();
    self:ReleaseItemButtons();

    if setName then
        self.Title:SetText(setName);
        self.setItemID = nil;
    else
        --Some sets aren't covered by C_TransmogSets.GetSetInfo
        self.Title:SetText("");
        local setItemID = C_Item.GetItemInfoInstant(setItemLink);
        self.setItemID = setItemID;
        self:RegisterEvent("ITEM_DATA_LOAD_RESULT");
        RequestLoadItemDataByID(setItemID);
    end


    --Remove duplicate items
    local usedAppearance = {};

    local appearanceInfo;
    local tbl = {};
    local addItem, appearanceID;
    local n = 0;
    local numKnown = 0;

    for _, transmogSetItemInfo in ipairs(items) do
        addItem = false;
        appearanceInfo = GetAppearanceInfoBySource(transmogSetItemInfo.itemModifiedAppearanceID);

        if appearanceInfo then
            appearanceID = appearanceInfo.appearanceID;
            if not usedAppearance[appearanceID] then
                usedAppearance[appearanceID] = true;
                addItem = true;
                if appearanceInfo.appearanceIsCollected or appearanceInfo.sourceIsCollected then
                    numKnown = numKnown + 1;
                end
            end
        else
            addItem = true;
        end

        if addItem then
            n = n + 1;
            tbl[n] = transmogSetItemInfo;
        end
    end

    items = tbl;
    TransmogDataProvider:SortSetItems(items);


    local itemButton;
    local numItems = #items;
    local anyWeapon = false;

    for i, setItem in ipairs(items) do
        itemButton = self:AcquireItemButton();
        itemButton:SetPoint("TOP", self, "TOP", 0, self.itemlistFromY + (1 - i) * ITEMBUTTON_HEIGHT);
        itemButton:SetItem(setItem.itemID, setItem.itemModifiedAppearanceID, setItem.invType);
        if itemButton.slotID == 16 or itemButton.slotID == 17 then
            anyWeapon = true;
        end
    end

    MAX_LABEL_WIDTH = anyWeapon and self.maxWidth_Weapon or self.maxWidth_Armor;
    FRAME_WIDTH = FRAME_WIDTH_BASE + MAX_LABEL_WIDTH - 24;

    self.Subtitle:SetText(string.format("%s:  |cffcccccc%d / %d|r", TRANSMOG_COLLECTED or "Collected", numKnown, numItems));
    self:UpdateLabels(true);

    local height = math.max(numItems, 4) * ITEMBUTTON_HEIGHT - self.itemlistFromY + 80 * SIZE_SCALE + ITEMLIST_PADDING_Y;
    self:SetSize(FRAME_WIDTH, height);
end

function TransmogSetFrame:ToggleRemovePlayerItems(state)
    local userInput = true;
    NarciDressingRoomAPI.EnableAutoRemoveNonSetItems(state, userInput);
end

function TransmogSetFrame:OnEvent(event, ...)
    if event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        if itemID and success then
            if self.itemOwners[itemID] and itemID == self.itemOwners[itemID].itemID then
                self.itemOwners[itemID]:OnItemLoaded(itemID);
            elseif itemID == self.setItemID then
                self.setItemID = nil;
                self.Title:SetText(C_Item.GetItemNameByID(itemID));
            end
        end
    end
end

function TransmogSetFrame:LoadItem(itemID, itemButton)
    self.itemOwners[itemID] = itemButton;
    self:RegisterEvent("ITEM_DATA_LOAD_RESULT");
    RequestLoadItemDataByID(itemID);
end

function TransmogSetFrame:OnShow()
    self.visible = true;
end

function TransmogSetFrame:OnHide()
    self.visible = false;
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT");
    self:HighlightButton(nil);
    self:Hide();
    self:ReleaseItemButtons();
    if self.refreshItemTimer then
        self.refreshItemTimer = nil;
        self:SetScript("OnUpdate", nil);
    end
end

function TransmogSetFrame:HighlightButton(itemButton)
    self.ButtonHighlight:Hide();
    self.ButtonHighlight:ClearAllPoints();
    if itemButton then
        self.ButtonHighlight:SetWidth(FRAME_WIDTH);
        self.ButtonHighlight:SetPoint("CENTER", itemButton, "CENTER", 0, 0);
        self.ButtonHighlight:Show();
    end
end

function TransmogSetFrame:OnDressModel(itemModifiedAppearanceID, invSlot, removed)
    if self.visible then
        self.refreshItemTimer = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end
end

function TransmogSetFrame:UpdateEquippedItems()
    local playerActor = DressUpFrame.ModelScene:GetPlayerActor();
	if playerActor then
		local transmogInfoList = playerActor:GetItemTransmogInfoList();
        if transmogInfoList then
            for i = 1, self.numButtons do
                self.itemButtons[i]:SetEquipped(false);
            end
            local transmogID, itemID, itemButton;
            for slotID, info in pairs(transmogInfoList) do
                transmogID = info.appearanceID;
                if transmogID and transmogID ~= 0 then
                    itemID = GetSourceItemID(transmogID);
                    itemButton = itemID and self.itemOwners[itemID];
                    if itemButton then
                        itemButton:SetEquipped(itemID == itemButton.itemID);
                    end
                end
            end
        end
	end
    self:UpdateLabels();
end

function TransmogSetFrame:UpdateLabels(updateLayout)
    --Hide duplicated SlotName
    local slotID, itemButton, lastLabel, label, anyEqupped;

    for i = 1, self.numButtons do
        itemButton = self.itemButtons[i];

        if i == 1 then
            lastLabel = itemButton.SlotName;
        end

        if slotID ~= itemButton.slotID then
            slotID = itemButton.slotID;
            itemButton.SlotName:Show();
            lastLabel = itemButton.SlotName;
            anyEqupped = itemButton.isEquipped;
        else
            itemButton.SlotName:Hide();
            anyEqupped = anyEqupped or itemButton.isEquipped;
        end

        label = lastLabel or itemButton.SlotName;

        if anyEqupped then
            label:SetTextColor(COLOR_2, COLOR_2, COLOR_2);
        else
            label:SetTextColor(0.40, 0.40, 0.40);
        end

        if updateLayout then
            itemButton:Layout();
        end
    end
end

function TransmogSetFrame:OnUpdate(elapsed)
    self.refreshItemTimer = self.refreshItemTimer + elapsed;
    if self.refreshItemTimer > 0.03 then
        self.refreshItemTimer = nil;
        self:SetScript("OnUpdate", nil);
        self:UpdateEquippedItems();
    end
end

do  --Checkbox
    local BOX_SIZE = 24;
    local BOX_TEXT_GAP = 4;
    local WIDGET_HEIGHT = 32;
    local CheckboxMixin = {};

    function CheckboxMixin:OnLoad()
        self.OnLoad = nil;
        self:SetSize(BOX_SIZE, WIDGET_HEIGHT);

        self.Box = self:CreateTexture(nil, "ARTWORK");
        self.Box:SetPoint("LEFT", self, "LEFT", 0, 0);
        self.Box:SetTexture(FILE);
        self.Box:SetTexCoord(512/1024, 544/1024, 0, 32/1024);
        self.Box:SetSize(BOX_SIZE, BOX_SIZE);

        self.Check = self:CreateTexture(nil, "OVERLAY");
        self.Check:SetPoint("CENTER", self.Box, "CENTER", 0, 0);
        self.Check:SetTexture(FILE);
        self.Check:SetTexCoord(544/1024, 576/1024, 0, 32/1024);
        self.Check:SetSize(BOX_SIZE, BOX_SIZE);

        self.Highlight = self:CreateTexture(nil, "BACKGROUND");
        self.Highlight:SetPoint("CENTER", self.Box, "CENTER", 0, 1);
        self.Highlight:SetTexture(FILE);
        self.Highlight:SetAlpha(0.8);
        self.Highlight:SetTexCoord(576/1024, 640/1024, 0, 64/1024);
        self.Highlight:SetSize(2*BOX_SIZE, 2*BOX_SIZE);
        self.Highlight:Hide();

        self.Label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        self.Label:SetJustifyH("LEFT");
        self.Label:SetPoint("LEFT", self.Box, "RIGHT", BOX_TEXT_GAP, 0);

        self:SetChecked(false);
        self:SetScript("OnClick", self.OnClick);
        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnShow", self.OnShow);
    end

    function CheckboxMixin:SetLabel(label)
        self.Label:SetText(label);
        self:SetWidth(math.ceil(BOX_SIZE + BOX_TEXT_GAP + self.Label:GetWrappedWidth()));
    end

    function CheckboxMixin:SetChecked(state)
        self.isChecked = state;
        self.Check:SetShown(state);
    end

    function CheckboxMixin:OnClick()
        self.isChecked = not self.isChecked;
        self:SetChecked(self.isChecked);
        GameTooltip:Hide();
        if self.onClickMethod then
            TransmogSetFrame[self.onClickMethod](TransmogSetFrame, self.isChecked);
        end
        if self.isChecked then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
        end
    end

    function CheckboxMixin:OnEnter()
        self.Highlight:Show();
        if self.tooltipText then
            local tooltip = GameTooltip;
            tooltip:SetOwner(self.Box, "ANCHOR_RIGHT");
            tooltip:SetText(self.Label:GetText(), 1, 0.82, 0);
            tooltip:AddLine(self.tooltipText, 1, 1, 1, true);
            tooltip:Show();
        end
    end

    function CheckboxMixin:OnLeave()
        self.Highlight:Hide();
        GameTooltip:Hide();
    end

    function CheckboxMixin:OnShow()
        if self.dbKey then
            self:SetChecked(NarcissusDB and NarcissusDB[self.dbKey] == true);
        end
    end

    function TransmogSetFrame:CreateFooterCheckbox(label, onClickMethod, dbKey, tooltipText)
        if not self.checkboxes then
            self.checkboxes = {};
        end

        local f = CreateFrame("Button", nil, self.Footer);
        table.insert(self.checkboxes, f);
        Mixin(f, CheckboxMixin);
        f:OnLoad();
        f:SetLabel(label);
        f.onClickMethod = onClickMethod;
        f.dbKey = dbKey;
        f.tooltipText = tooltipText;
        self:LayoutFooter();
        return f
    end

    function TransmogSetFrame:LayoutFooter()
        if self.checkboxes then
            local numWidgets = #self.checkboxes;
            if numWidgets > 1 then
                local gap = 32 * SIZE_SCALE;
                local fullWidth = 0;
                for _, checkbox in ipairs(self.checkboxes) do
                    fullWidth = fullWidth + checkbox:GetWidth() + gap;
                end
                fullWidth = fullWidth - gap;
                for i, checkbox in ipairs(self.checkboxes) do
                    checkbox:ClearAllPoints();
                    if i == 1 then
                        checkbox:SetPoint("LEFT", self.Footer, "LEFT", 0.5 * (self:GetWidth() - fullWidth), 0);
                    else
                        checkbox:SetPoint("LEFT", self.checkboxes[i - 1], "RIGHT", gap, 0);
                    end
                end
            else
                self.checkboxes[1]:ClearAllPoints();
                self.checkboxes[1]:SetPoint("CENTER", self.Footer, "CENTER", 0, 0);
            end
        end
    end
end


do  --ItemButton
    local PADDING_H = 16;
    local ICON_SIZE = 20;
    local ICON_TEXT_GAP = 6;
    local ItemButtonMixin = {};

    function ItemButtonMixin:OnLoad()
        self.OnLoad = nil;
        self:SetSize(FRAME_WIDTH, ITEMBUTTON_HEIGHT);

        self.Icon = self:CreateTexture(nil, "OVERLAY");
        self.Icon:SetTexCoord(0/64, 64/64, 0/64, 64/64);
        self.Icon:SetSize(ICON_SIZE, ICON_SIZE);
        self:Layout();

        self.ItemName = self:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        self.ItemName:SetJustifyH("LEFT");
        self.ItemName:SetPoint("LEFT", self.Icon, "RIGHT", ICON_TEXT_GAP, 0);
        self.ItemName:SetPoint("RIGHT", self, "RIGHT", -PADDING_H, 0);
        self.ItemName:SetMaxLines(1);

        self.SlotName = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall2");
        self.SlotName:SetJustifyH("LEFT");
        self.SlotName:SetPoint("LEFT", self, "LEFT", PADDING_H, 0);
        self.SlotName:SetTextColor(COLOR_2, COLOR_2, COLOR_2);

        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnClick", self.OnClick);
    end

    function ItemButtonMixin:OnEnter()
        if self.itemID then
            TransmogSetFrame:HighlightButton(self);
            local tooltip = GameTooltip;
            tooltip:Hide();
            tooltip:SetOwner(self, "ANCHOR_RIGHT");
            tooltip:SetItemByID(self.itemID);
        end
    end

    function ItemButtonMixin:OnLeave()
        TransmogSetFrame:HighlightButton(nil);
        GameTooltip:Hide();
    end

    function ItemButtonMixin:OnClick()
        if not self.itemID then return end;

        self:SetEquipped(not self.isEquipped, true);
    end

    function ItemButtonMixin:SetItem(itemID, itemModifiedAppearanceID, invType)
        self.itemID = itemID;
        self.itemModifiedAppearanceID = itemModifiedAppearanceID;
        self.invType = invType;
        self.slotID = TransmogDataProvider:GetSlotIDBySetInvType(invType);
        self.SlotName:SetText(_G[invType]);
        self.isLoaded = false;
        TransmogSetFrame:LoadItem(itemID, self);
    end

    function ItemButtonMixin:OnItemLoaded(itemID)
        if self.isLoaded then return end;

        local itemIcon = C_Item.GetItemIconByID(itemID);
        local name = C_Item.GetItemNameByID(itemID);
        local quality = C_Item.GetItemQualityByID(itemID);
        local r, g, b = GetItemQualityColor(quality);
        self.Icon:SetTexture(itemIcon);
        self.ItemName:SetText(name);
        self.ItemName:SetTextColor(r, g, b);
    end

    function ItemButtonMixin:SetEquipped(state, userInput)
        self.isEquipped = state;

        if state then
            self.Icon:SetVertexColor(1, 1, 1);
            self.ItemName:SetAlpha(1);
        else
            self.Icon:SetVertexColor(0.5, 0.5, 0.5);
            self.ItemName:SetAlpha(0.5);
        end

        if userInput then
            local playerActor = DressUpFrame.ModelScene:GetPlayerActor();
            if playerActor then
                local isTwoHandWeapon = self.invType == "INVTYPE_2HWEAPON";
                local isOffHandWeapon = self.invType == "INVTYPE_WEAPONOFFHAND" or self.invType == "INVTYPE_RANGED";
                local isMainHandWeapon = self.invType == "INVTYPE_MAINHAND" or self.invType == "INVTYPE_RANGEDRIGHT";
                if self.isEquipped then
                    if isTwoHandWeapon or isOffHandWeapon or isMainHandWeapon then
                        playerActor:TryOn(self.itemModifiedAppearanceID, isOffHandWeapon and "SECONDARYHANDSLOT" or "MAINHANDSLOT");
                    else
                        playerActor:TryOn(self.itemModifiedAppearanceID);
                    end
                else
                    playerActor:UndressSlot(TransmogDataProvider:GetSlotIDBySetInvType(self.invType));
                end
            end
        end
    end

    function ItemButtonMixin:Layout()
        self.Icon:SetPoint("LEFT", self, "LEFT", PADDING_H + MAX_LABEL_WIDTH + ICON_SIZE, 0);
        self:SetWidth(FRAME_WIDTH);
    end

    function ItemButtonMixin:ClearItem()
        if self.itemID then
            self.itemID = nil;
            self.itemModifiedAppearanceID = nil;
            self.invType = nil;
            self.slotID = nil;
            self.isLoaded = nil;
            self.Icon:SetTexture(nil);
            self.ItemName:SetText(nil);
            self.SlotName:SetText(nil);
        end
    end

    function TransmogSetFrame:ReleaseItemButtons()
        self:HighlightButton(nil);
        self.itemOwners = {};
        self.numButtons = 0;
        for _, f in ipairs(self.itemButtons) do
            f:Hide();
            f:ClearAllPoints();
            f:ClearItem();
        end
    end

    function TransmogSetFrame:AcquireItemButton()
        local i = self.numButtons + 1;
        self.numButtons = i;
        if not self.itemButtons[i] then
            local f = CreateFrame("Button", nil, self);
            self.itemButtons[i] = f;
            Mixin(f, ItemButtonMixin);
            f:OnLoad();
        end
        self.itemButtons[i]:Show();
        return self.itemButtons[i]
    end
end