local _, addon = ...
local DataProvider = addon.PerksProgramDataProvider;
local TransitionAPI = addon.TransitionAPI;

local MainFrame, PreviewModel;
local FrameToggle;
local FocusedButton;
local ProductButtons;

local FadeFrame = NarciFadeUI.Fade;
local NarciAPI = NarciAPI;

local C_Item = C_Item;
local GetItemIconByID = C_Item.GetItemIconByID;
local ResetCursor = ResetCursor;
local GetItemInfo = GetItemInfo;
local GetItemInfoInstant = GetItemInfoInstant;

local CURRENCY_AMOUNT = 0;

local CHECK_MARK = "|TInterface\\AddOns\\Narcissus\\Art\\BasicShapes\\CheckMark:12:12:0:0:32:32:0:32:0:32:124:197:118|t";
local PREVIEW_MODEL_WIDTH, PREVIEW_MODEL_HEIGHT = 78*2, 104*2;

local function RemoveEnsembleLabel(itemName)
    if itemName then
        return string.gsub(itemName, "^Ensemble: ", "");
    end
end

local function SetupEncounterJournal()
    if FrameToggle then return end;

    local f = EncounterJournal and EncounterJournal.MonthlyActivitiesFrame;
    if not f then return end;

    FrameToggle = NarciPerksProgramEncounterJournalButton;
    FrameToggle:ClearAllPoints();
    FrameToggle:SetParent(f);
    --FrameToggle:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -6);
    FrameToggle:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -16, -2);
    FrameToggle:Show();
    FrameToggle:RegisterEvent("PERKS_PROGRAM_CURRENCY_REFRESH");
end

local function EncounterJournal_TabChanged(_, _, id)

end

do
    if DataProvider:DoesPerksProgramExist() or true then
        if EncounterJournal_LoadUI then
            hooksecurefunc("EncounterJournal_LoadUI", SetupEncounterJournal);
            --EventRegistry:RegisterCallback("EncounterJournal.TabSet", EncounterJournal_TabChanged, MainFrame);
        end
    end
end


NarciPerksProgramEncounterJournalButtonMixin = {};

function NarciPerksProgramEncounterJournalButtonMixin:OnEnter()
    local tooltipText;

    if self:IsEnabled() then
        if not MainFrame:IsShown() then
            tooltipText = Narci.L["Perks Program See Wares"];
        end
    else
        tooltipText = Narci.L["Perks Program No Cache Alert"];
    end

    if tooltipText then
        local tooltip = GameTooltip;
        tooltip:Hide();
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("LEFT", self, "RIGHT", 16, 0);
        tooltip:SetText(tooltipText, 1, 1, 1, 1, true);
        tooltip:Show();
    end

    self.focused = true;
    self:UpdateVisual();
end

function NarciPerksProgramEncounterJournalButtonMixin:OnLeave()
    self.focused = nil;
    self:UpdateVisual();
    GameTooltip:Hide();
end

function NarciPerksProgramEncounterJournalButtonMixin:OnClick()
    local state = not MainFrame:IsShown();

    if state then
        MainFrame:SetParent(self);
        MainFrame:ClearAllPoints();
        NarciAPI.SetFramePointPixelPerfect(MainFrame, "TOPLEFT", EncounterJournal, "TOPRIGHT", 8, -4);
        --MainFrame:SetPoint("TOPLEFT", EncounterJournal, "TOPRIGHT", 8, -4);
        MainFrame:Show();
    else
        MainFrame:Hide();
    end

    self:UpdateVisual();
end

function NarciPerksProgramEncounterJournalButtonMixin:OnMouseDown()
    if self:IsEnabled() then
        self.down = true;
        GameTooltip:Hide();
    end
    self:UpdateVisual();
end

function NarciPerksProgramEncounterJournalButtonMixin:OnMouseUp()
    self.down = false;
    self:UpdateVisual();
end

function NarciPerksProgramEncounterJournalButtonMixin:UpdateVisual()
    if self:IsEnabled() then
        self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturated(false);
        if self.down or MainFrame:IsShown() then
            if self.focused then
                self.Icon:SetTexCoord(0.5, 1, 0, 0.5);
            else
                self.Icon:SetTexCoord(0.5, 1, 0.5, 1);
            end
        else
            if self.focused then
                self.Icon:SetTexCoord(0, 0.5, 0, 0.5);
            else
                self.Icon:SetTexCoord(0, 0.5, 0.5, 1);
            end
        end
    else
        self.Icon:SetVertexColor(0.67, 0.67, 0.67);
        self.Icon:SetDesaturated(true);
        self.Icon:SetTexCoord(0, 0.5, 0.5, 1);
    end
end

function NarciPerksProgramEncounterJournalButtonMixin:UpdateCurrencyAmount()
    CURRENCY_AMOUNT = C_PerksProgram.GetCurrencyAmount();
	self.Text:SetText(CURRENCY_AMOUNT);
    if CURRENCY_AMOUNT > 0 then
        self.Text:SetTextColor(1, 1, 1);
    else
        self.Text:SetTextColor(0.5, 0.5, 0.5);
    end
    MainFrame:RequestUpdate();
end

function NarciPerksProgramEncounterJournalButtonMixin:OnShow()
    self:UpdateCurrencyAmount();

    local vendorItemIDs = DataProvider:GetCurrentMonthItems();
    if vendorItemIDs and #vendorItemIDs > 0 then
        self:Enable();
    else
        self:Disable();
    end
end

function NarciPerksProgramEncounterJournalButtonMixin:OnEvent(event, ...)
    --PERKS_PROGRAM_CURRENCY_REFRESH
    self:UpdateCurrencyAmount();
end

NarciPerksProgramProductListMixin = {};

function NarciPerksProgramProductListMixin:OnLoad()
    MainFrame = self;
    self.requireUpdate = true;
end

function NarciPerksProgramProductListMixin:Init()
    NarciAPI.NineSliceUtil.SetUpBorder(self.BackgroundFrame, "genericChamferedBorder", nil, 0.25, 0.25, 0.25, 1, 7);
    NarciAPI.NineSliceUtil.SetUpBackdrop(self.BackgroundFrame, "genericChamferedBackground", nil, 0, 0, 0, 0.9, -8);
    self.Init = nil;
end

function NarciPerksProgramProductListMixin:OnShow()
    if self.Init then
        self:Init();
    end

    if self.requireUpdate then
        self:UpdateList();
    end

    self:RegisterEvent("MODIFIER_STATE_CHANGED");

    if FrameToggle then
        FrameToggle:UpdateVisual();
    end
end

function NarciPerksProgramProductListMixin:OnHide()
    self:Hide();
    self:UnregisterEvent("MODIFIER_STATE_CHANGED");
    FocusedButton = nil;
    ResetCursor();

    if FrameToggle then
        FrameToggle:UpdateVisual();
    end
end


function NarciPerksProgramProductListMixin:OnEvent(event, ...)
    if event == "MODIFIER_STATE_CHANGED" then
        self.controlDown = IsModifiedClick("DRESSUP");
        ResetCursor();
        if FocusedButton then
            if self.controlDown then
                ShowInspectCursor();
            end
        end
    end
end

function NarciPerksProgramProductListMixin:ShowInfoButton()
    if not self.InfoButton then
        local b = CreateFrame("Frame", nil, self, "NarciGenericInfoButtonTemplate");
        self.InfoButton = b;
        b:SetFrameLevel(self:GetFrameLevel() + 6);
        b:SetPoint("CENTER", self, "TOPRIGHT", -18, -18);
        b:SetSize(20, 20);
        b:SetHitRectInsets(0, 0, 0, 0);
        b.tooltipOffsetX = 12;
        b.tooltipName = "GameTooltip";
        b.tooltipText = Narci.L["Perks Program Using Cache Alert"];
    end
end

function NarciPerksProgramProductListMixin:HideInfoButton()
    if self.InfoButton then
        self.InfoButton:Hide();
    end
end

--[[
local function SortFunc_Category(id1, id2)
    local info1 = DataProvider:GetAndCacheVendorItemInfo(id1);
    local info2 = DataProvider:GetAndCacheVendorItemInfo(id2);

    if info1.perksVendorCategoryID ~= info2.perksVendorCategoryID then
        return info1.perksVendorCategoryID < info2.perksVendorCategoryID
    end

    if info1.purchased then
        if info2.purchased then
            return info1.name < info2.name
        else
            return false
        end
    else
        if info2.purchased then
            return true
        else
            if info1.price ~= info2.price then
                return info1.price > info2.price
            else
                return info1.name < info2.name
            end
        end
    end
end
--]]

local function SortFunc_Category(id1, id2)
    local c1 = DataProvider:GetVendorItemCategory(id1);
    local c2 = DataProvider:GetVendorItemCategory(id2);

    if c1 ~= c2 then
        return c1 < c2
    end

    local o1 = DataProvider:IsVendorItemPurchased(id1);
    local o2 = DataProvider:IsVendorItemPurchased(id2);

    if o1 then
        if o2 then
            return DataProvider:GetVendorItemName(id1) < DataProvider:GetVendorItemName(id2)
        else
            return false
        end
    else
        if o2 then
            return true
        else
            local p1 = DataProvider:GetVendorItemPrice(id1);
            local p2 = DataProvider:GetVendorItemPrice(id2);
            if p1 ~= p2 then
                return p1 > p2
            else
                return DataProvider:GetVendorItemName(id1) < DataProvider:GetVendorItemName(id2)
            end
        end
    end
end

function NarciPerksProgramProductListMixin:AcquireButton(index)
    if not ProductButtons[index] then
        ProductButtons[index] = CreateFrame("Button", nil, self, "NarciPerksProgramProductListButtonTemplate");
    end
    return ProductButtons[index]
end

function NarciPerksProgramProductListMixin:UpdateList()
    CURRENCY_AMOUNT = DataProvider:GetCurrencyAmount();

    local vendorItemIDs = DataProvider:GetCurrentMonthItems();
    local numItems = (vendorItemIDs and #vendorItemIDs) or 0;

    if numItems > 0 then
        local sortedList = {};
        for i = 1, numItems do
            sortedList[i] = vendorItemIDs[i];
        end

        table.sort(sortedList, SortFunc_Category);
        self.vendorItemIDs = sortedList;

        if not ProductButtons then
            ProductButtons = {};
        end

        local paddingTop = 6;
        local paddingBottom = 8;
        local buttonHeight = 24;

        local fullHeight;
        local lastCategory;
        local categoryID;
        local vendorItemID;
        local button;

        local numButtons = 0;
        for i = 1, numItems do
            vendorItemID = sortedList[i];
            categoryID = DataProvider:GetVendorItemCategory(vendorItemID);
            if categoryID ~= lastCategory then
                lastCategory = categoryID;
                numButtons = numButtons + 1;
                button = self:AcquireButton(numButtons);
                button:ClearAllPoints();
                button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -paddingTop + (1 - numButtons)*buttonHeight);
                button:SetCategoryID(categoryID);
            end
            
            numButtons = numButtons + 1;
            button = self:AcquireButton(numButtons);
            button:ClearAllPoints();
            button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -paddingTop + (1 - numButtons)*buttonHeight);
            button:SetVendorItemID(sortedList[i]);
        end

        self:SetHeight(paddingTop + paddingBottom + buttonHeight*numButtons);
        self.AlertText:Hide();
        self:ShowInfoButton();
    else
        self.AlertText:SetText(Narci.L["Perks Program No Cache Alert"]);
        self.AlertText:Show();
        self:SetHeight( math.floor(self.AlertText:GetHeight() + 24.5) );
        self:HideInfoButton();
    end

    self.requireUpdate = nil;
end

local function ShowPreviewModel_OnUpdate(self, elapsed)
    self.updateDelay = self.updateDelay + elapsed;
    if self.updateDelay >= 0 then
        self:SetScript("OnUpdate", nil);
        if FocusedButton then
            MainFrame:DisplayItem(FocusedButton.itemID, FocusedButton.vendorItemID);
        end
    end
end

function NarciPerksProgramProductListMixin:FocusOnButton(button)
    self.ButtonHighlight:ClearAllPoints();
    self:HidePreview();
    if button then
        self.ButtonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 2, 0);
        self.ButtonHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0);
        self.ButtonHighlight:Show();
        if self.controlDown then
            ShowInspectCursor();
        end
        
        --show model after x second
        self.BackgroundFrame.updateDelay = -0.5;
        self.BackgroundFrame:SetScript("OnUpdate", ShowPreviewModel_OnUpdate);
    else
        self.ButtonHighlight:Hide();
        ResetCursor();
    end
    FocusedButton = button;
end

local function UpdateList_NextFrame(self, elapsed)
    self.updateDelay =  self.updateDelay + elapsed;
    if self.updateDelay >= 0 then
        self:SetScript("OnUpdate", nil);
        self:UpdateList();
    end
end

function NarciPerksProgramProductListMixin:RequestUpdate(useDelay)
    self.requireUpdate = true;
    self:SetScript("OnUpdate", nil);

    if self:IsVisible() then
        if useDelay then
            self.updateDelay = -0.5;
            self:SetScript("OnUpdate", UpdateList_NextFrame);
        else
            self:UpdateList();
        end
    end
end

local PI2 = math.floor(1000*math.pi*2)/1000;

local function PreviewModel_Turntable_OnUpdate(self, elapsed)
    self.yaw = self.yaw + elapsed*PI2*0.1;
    if self.yaw > PI2 then
        self.yaw = self.yaw - PI2;
    end
    self:SetFacing(self.yaw);
end

local function PreviewModel_Init()
    PreviewModel = MainFrame.PreviewFrame.Model;
    PreviewModel:SetViewInsets(4, 4, 4, -8);
    PreviewModel:SetKeepModelOnHide(true);
    PreviewModel:SetModelDrawLayer("BACKGROUND");
    PreviewModel:SetAutoDress(false);
    PreviewModel:SetDoBlend(false);
    TransitionAPI.SetModelLight(PreviewModel, true, false, -1, 1, -1, 0.8, 1, 1, 1, 0.5, 1, 1, 1);

    MainFrame.PreviewFrame:SetSize(PREVIEW_MODEL_WIDTH, PREVIEW_MODEL_HEIGHT);
    PreviewModel:SetSize(PREVIEW_MODEL_WIDTH, PREVIEW_MODEL_HEIGHT);
    NarciAPI.NineSliceUtil.SetUpBorder(MainFrame.PreviewFrame.BackgroundFrame, "genericChamferedBorder", nil, 0.25, 0.25, 0.25, 1, 7);
    NarciAPI.NineSliceUtil.SetUpBackdrop(MainFrame.PreviewFrame.BackgroundFrame, "genericChamferedBackground", nil, 0, 0, 0, 0.9, -8);

    local function PreviewModel_OnModelLoaded(f)
        if f.cameraID then
            Model_ApplyUICamera(f, f.cameraID);
        end
    end
    PreviewModel:SetScript("OnModelLoaded", PreviewModel_OnModelLoaded);
end

function NarciPerksProgramProductListMixin:DisplayItem(item, vendorItemID)
    if not PreviewModel then
        PreviewModel_Init();
    end

    self.PreviewFrame.FadeIn:Stop();

    local itemID, itemLink;
    if type(item) == "number" then
        itemID = item;
        local _;
        _, itemLink = GetItemInfo(item);
    else
        itemLink = item;
    end

    local backupFlavorText;

    if C_Item.IsDressableItemByID(item) then
        local appearanceID, sourceID = C_TransmogCollection.GetItemInfo(itemLink);
        local isArmor;
        if appearanceID then
            --One Item
            local cameraID = C_TransmogCollection.GetAppearanceCameraIDBySource(sourceID);
            PreviewModel.cameraID = cameraID;
            PreviewModel:SetScript("OnUpdate", nil);

            if NarciAPI.IsHoldableItem(itemLink) then
                PreviewModel:SetItemAppearance(appearanceID);
            else
                isArmor = true;
            end
        else
            --Ensemble
            isArmor = true;
            local detailsCameraID, vendorCameraID = C_TransmogSets.GetCameraIDs()
            PreviewModel.cameraID = vendorCameraID;
            PreviewModel.yaw = -0.78;
            PreviewModel:SetScript("OnUpdate", PreviewModel_Turntable_OnUpdate);
        end

        if isArmor then
            PreviewModel:Undress();
            --PreviewModel:SetUseTransmogSkin(false);
            TransitionAPI.SetModelByUnit(PreviewModel, "player");
            PreviewModel:FreezeAnimation(0, 0, 0);
            PreviewModel:TryOn(itemLink);
        end
    else
        itemID = itemID or GetItemInfoInstant(itemID);
        local mountID = C_MountJournal.GetMountFromItem(itemID);
        local displayID;
        if mountID then
            PreviewModel:ClearModel();
            local creatureDisplayID, description, _, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID);
            displayID = creatureDisplayID;
            backupFlavorText = description;
            if isSelfMount then
                PreviewModel:SetAnimation(618);
            else
                PreviewModel:SetAnimation(0);
            end
        else
            local _, _, _, creatureID, _, description, _, _, _, _, _, creatureDisplayID, speciesID = C_PetJournal.GetPetInfoByItemID(itemID);
            backupFlavorText = description;
            displayID = creatureDisplayID;
            PreviewModel:SetAnimation(0);
        end

        if displayID then
            PreviewModel.cameraID = nil;
            PreviewModel:SetPosition(0, 0, 0);
            PreviewModel:SetPitch(0);
            PreviewModel:SetRoll(0);
            PreviewModel:SetDisplayInfo(displayID);
            PreviewModel.yaw = -0.78;
            PreviewModel:SetScript("OnUpdate", PreviewModel_Turntable_OnUpdate);
        else
            PreviewModel:SetScript("OnUpdate", nil);
            self.PreviewFrame:Hide();
            return
        end
    end

    self.PreviewFrame:ClearAllPoints();

    local anchorToButton;
    if FocusedButton then
        local y0 = self:GetTop();
        local _, y1 = FocusedButton:GetCenter();
        if y0 - y1 > PREVIEW_MODEL_HEIGHT*0.5 then
            anchorToButton = true;
        end
    end

    if anchorToButton then
        self.PreviewFrame:SetPoint("LEFT", FocusedButton, "RIGHT", 8, 0);
    else
        self.PreviewFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", 8, 0);
    end


    local itemTooltipText = NarciAPI.GetItemRequirement(itemID);
    local itemName = DataProvider:GetVendorItemName(vendorItemID);
    local itemDesc;

    if itemTooltipText then
        for i, text in ipairs(itemTooltipText) do
            if itemDesc then
                itemDesc = itemDesc.."\n"..text;
            else
                itemDesc = text;
            end
        end
    end

    local flavorText = vendorItemID and DataProvider:GetVendorItemDescription(vendorItemID);
    if flavorText == "" then
        flavorText = backupFlavorText;
    end
    if flavorText and flavorText ~= "" then
        flavorText = "|cffffd100\""..flavorText.."\"|r";
        if itemDesc then
            itemDesc = itemDesc.."\n"..flavorText;
        else
            itemDesc = flavorText;
        end
    end

    local quality = C_Item.GetItemQualityByID(itemID);
    local r, g, b = NarciAPI.GetItemQualityColor(quality);

    self.PreviewFrame.ItemName:SetText(itemName);
    self.PreviewFrame.ItemName:SetTextColor(r, g, b);
    self.PreviewFrame.ItemDescription:SetText(itemDesc);

    local textHeight = self.PreviewFrame.ItemName:GetTop() - self.PreviewFrame.ItemDescription:GetBottom();
    local textWidth = math.max(self.PreviewFrame.ItemName:GetWrappedWidth(), self.PreviewFrame.ItemDescription:GetWrappedWidth());

    self.PreviewFrame.ItemName:ClearAllPoints();
    local offsetY = math.floor((PREVIEW_MODEL_HEIGHT - textHeight)*0.5 + 0.5);
    self.PreviewFrame.ItemName:SetPoint("TOPLEFT", PreviewModel, "TOPRIGHT", 12, -offsetY);
    self.PreviewFrame:SetWidth(PREVIEW_MODEL_WIDTH + math.floor(textWidth + 0.5) + 24);


    self.PreviewFrame.FadeIn:Play();
    self.PreviewFrame:Show();

    --Item Tooltip
    --[[
    local tooltip = GameTooltip;
    tooltip:Hide();
    tooltip:SetOwner(self, "ANCHOR_NONE");
    tooltip:SetPoint("TOPLEFT", self.PreviewFrame, "TOPRIGHT", 4, 0);
    tooltip:SetItemByID(itemID);
    tooltip:Show();
    FadeFrame(tooltip, 0.25, 1, 0);
    --]]
end

function NarciPerksProgramProductListMixin:HidePreview()
    self.PreviewFrame:Hide();
    self.BackgroundFrame:SetScript("OnUpdate", nil);
    GameTooltip:Hide();
end

NarciPerksProgramProductListButtonMixin = {};

function NarciPerksProgramProductListButtonMixin:OnEnter()
    self.Container.Name:SetTextColor(1, 1, 1);
    self.Container.Icon:SetVertexColor(1, 1, 1);
    MainFrame:FocusOnButton(self);

    --print(C_Item.IsDressableItemByID(self.itemID));
end

function NarciPerksProgramProductListButtonMixin:OnLeave()
    self.Container.Name:SetTextColor(1, 0.82, 0);
    self.Container.Icon:SetVertexColor(0.8, 0.8, 0.8);
    MainFrame:FocusOnButton();
end

function NarciPerksProgramProductListButtonMixin:OnMouseDown()
    if self:IsEnabled() then
        self.Container:SetPoint("TOPLEFT", 1, -1);
        self.Container:SetPoint("BOTTOMRIGHT", 1, -1);
    end
end

function NarciPerksProgramProductListButtonMixin:OnMouseUp()
    self.Container:SetPoint("TOPLEFT", 0, 0);
	self.Container:SetPoint("BOTTOMRIGHT", 0, 0);
end

function NarciPerksProgramProductListButtonMixin:OnClick()
    if not IsModifierKeyDown() then return end;

    if self.itemID then
        local _, itemLink = GetItemInfo(self.itemID);
        local result = HandleModifiedItemClick(itemLink);
    end
end



function NarciPerksProgramProductListButtonMixin:SetVendorItemID(vendorItemID)
    self:Enable();
    self.Container.Name:SetTextColor(1, 0.82, 0);
    local info = DataProvider:GetAndCacheVendorItemInfo(vendorItemID);
    if not (info and info.name and info.name ~= "") then
        MainFrame:RequestUpdate(true);
        return
    end
    local name = RemoveEnsembleLabel(info.name);
    self.Container.Name:SetText(name);
    self.Container.Name:SetPoint("LEFT", self.Container.Icon, "RIGHT", 6, 0);
    self.vendorItemID = vendorItemID;
    self.itemID = info.itemID;
    local iconTexture = GetItemIconByID(self.itemID);
    self.Container.Icon:SetTexture(iconTexture);

    local price = DataProvider:GetVendorItemPrice(vendorItemID);

    if DataProvider:IsVendorItemPurchased(vendorItemID) then
        self.Container.Price:SetText(CHECK_MARK);
    else
        if price and price ~= 0 then
            self.Container.Price:SetText(price);
            if price <= CURRENCY_AMOUNT then
                self.Container.Price:SetTextColor(0.8, 0.8, 0.8);
            else
                self.Container.Price:SetTextColor(0.5, 0.5, 0.5);   --1, 0.3137, 0.3137
            end
        else
            self.Container.Price:SetText("N/A");
            self.Container.Price:SetTextColor(0.5, 0.5, 0.5);
        end
    end
end

local function GetCategoryText(categoryID)
	if categoryID == Enum.PerksVendorCategoryType.Transmog then
		return PERKS_VENDOR_CATEGORY_TRANSMOG;
	elseif categoryID == Enum.PerksVendorCategoryType.Mount then
		return PERKS_VENDOR_CATEGORY_MOUNT;
	elseif categoryID == Enum.PerksVendorCategoryType.Pet then
		return PERKS_VENDOR_CATEGORY_PET;
	elseif categoryID == Enum.PerksVendorCategoryType.Toy then
		return PERKS_VENDOR_CATEGORY_TOY;
	elseif categoryID == Enum.PerksVendorCategoryType.Illusion then
		return PERKS_VENDOR_CATEGORY_ILLUSION;
	elseif categoryID == Enum.PerksVendorCategoryType.Transmogset then
		return PERKS_VENDOR_CATEGORY_TRANSMOG_SET;
	end
	return "";
end

function NarciPerksProgramProductListButtonMixin:SetCategoryID(perksVendorCategoryID)
    self:Disable();
    local categoryName = GetCategoryText(perksVendorCategoryID);
    self.Container.Name:SetText(categoryName);
    self.Container.Name:SetTextColor(0.6, 0.6, 0.6);
    self.Container.Name:SetPoint("LEFT", self.Container, "LEFT", 10, 0);
    self.Container.Icon:SetTexture(nil);
    self.Container.Price:SetText("");
end


if true then return end;

do
    --Debug

    local function GetItemClassID(itemID)
        return select(6, GetItemInfoInstant(itemID));
    end

    local function SortFunc_ItemClass(id1, id2)
        local classID1 = GetItemClassID(id1);
        local classID2 = GetItemClassID(id2);
    
        if classID1 ~= classID2 then
            return classID1 < classID2
        end
    
        return id1 < id2
    end

    local DEBUG_ITEMS = {
        34529, 202692, 200180,  --Weapon
        15304, 192013, 133615, 140865,  --Armor
        191658, 199877, --Transmog Set
        201440, --Mount
        193834, --Pet
    };

    function NarciPerksProgramProductListMixin:UpdateList()
        local vendorItemIDs = DEBUG_ITEMS;
        local numItems = (vendorItemIDs and #vendorItemIDs) or 0;
        if numItems > 0 then
            local sortedList = {};
            for i = 1, numItems do
                sortedList[i] = vendorItemIDs[i];
            end
    
            table.sort(sortedList, SortFunc_ItemClass);
            self.vendorItemIDs = sortedList;
    
            if not ProductButtons then
                ProductButtons = {};
            end
    
            local paddingTop = 6;
            local paddingBottom = 8;
            local buttonHeight = 24;
    
            local fullHeight;

            local lastCategory;
            local categoryID;
            local vendorItemID;
            local button;
    
            local numButtons = 0;
            for i = 1, numItems do
                vendorItemID = sortedList[i];
                categoryID = GetItemClassID(vendorItemID);
                if categoryID ~= lastCategory then
                    if fullHeight then
                        fullHeight = fullHeight + buttonHeight * 1.25;
                    else
                        fullHeight = paddingTop;
                    end
                    lastCategory = categoryID;
                    numButtons = numButtons + 1;
                    button = self:AcquireButton(numButtons);
                    button:ClearAllPoints();
                    button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -fullHeight);
                    button:SetCategoryID(categoryID);
                end

                fullHeight = fullHeight + buttonHeight;
                numButtons = numButtons + 1;
                button = self:AcquireButton(numButtons);
                button:ClearAllPoints();
                button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -fullHeight);
                button:SetVendorItemID(sortedList[i]);
            end
    
            self:SetHeight(fullHeight + paddingBottom + buttonHeight);
            self.AlertText:Hide();
        else
            self.AlertText:SetText(Narci.L["Perks Program No Cache Alert"]);
            self.AlertText:Show();
            self:SetHeight( math.floor(self.AlertText:GetHeight() + 24.5) );
        end
    end

    function NarciPerksProgramProductListButtonMixin:SetCategoryID(itemClassID)
        self:Disable();
        local categoryName = GetItemClassInfo(itemClassID);
        self.Container.Name:SetText(categoryName);
        self.Container.Name:SetTextColor(0.6, 0.6, 0.6);
        self.Container.Name:SetPoint("LEFT", self.Container, "LEFT", 10, 0);
        self.Container.Icon:SetTexture(nil);
        self.Container.Price:SetText("");
    end

    local CURRENCY_AMOUNT = 500;

    function NarciPerksProgramProductListButtonMixin:SetVendorItemID(itemID)
        self:Enable();
        self.Container.Name:SetTextColor(1, 0.82, 0);
        local name = C_Item.GetItemNameByID(itemID);
        if name then
            name = RemoveEnsembleLabel(name);
            self.Container.Name:SetText(name);
            self.Container.Name:SetPoint("LEFT", self.Container.Icon, "RIGHT", 6, 0);
        else
            MainFrame:RequestUpdate(true);
        end
        self.vendorItemID = itemID;
        self.itemID = itemID;
        local iconTexture = GetItemIconByID(itemID);
        self.Container.Icon:SetTexture(iconTexture);
        self.Container.Icon:SetVertexColor(0.8, 0.8, 0.8);

        local price = 100*math.random(1, 10);
        local isCollected = price >= 700;

        if isCollected then
            self.Container.Price:SetText(CHECK_MARK);
        else
            self.Container.Price:SetText(price);
            if price <= CURRENCY_AMOUNT then
                self.Container.Price:SetTextColor(0.8, 0.8, 0.8);
            else
                self.Container.Price:SetTextColor(1, 0.3137, 0.3137);
            end
        end
    end
end
--[[
    /script for k, v in pairs(GetMouseFocus()) do print(k) end

    Right Frame: PerksProgramFrame.ProductsFrame.PerksProgramProductDetailsContainerFrame

    /run PerksProgramFrame.ProductsFrame.PerksProgramProductDetailsContainerFrame:Layout()
/dump PerksProgramFrame.ModelSceneContainerFrame.MainModelScene
/run A = PerksProgramFrame.ModelSceneContainerFrame.playerActor
/run A:PlayAnimationKit(0, false)
/dump A:SetAnimation(4)
/run P = PerksProgramFrame.ModelSceneContainerFrame.MainModelScene:GetActorByTag("pet")
1355687

C_PerksProgram.GetAvailableVendorItemIDs    --vendorItemIDs (NOT itemID)    --visit Trading Post for cache
/dump C_PerksProgram.GetVendorItemInfo(110)

/run NarciPlayerModelFrame2:SetItemAppearance(69893)
C_TransmogSets.GetAllSourceIDs

    Name = "PerksVendorItemInfo",
    Type = "Structure",
    Fields =
    {
        { Name = "name", Type = "string", Nilable = false },
        { Name = "perksVendorCategoryID", Type = "number", Nilable = false },
        { Name = "description", Type = "string", Nilable = false },
        { Name = "timeRemaining", Type = "number", Nilable = false },
        { Name = "purchased", Type = "bool", Nilable = false },
        { Name = "refundable", Type = "bool", Nilable = false },
        { Name = "price", Type = "number", Nilable = false },
        { Name = "perksVendorItemID", Type = "number", Nilable = false },
        { Name = "itemID", Type = "number", Nilable = false },
        { Name = "iconTexture", Type = "string", Nilable = false },
        { Name = "mountID", Type = "number", Nilable = false },
        { Name = "speciesID", Type = "number", Nilable = false },
        { Name = "transmogSetID", Type = "number", Nilable = false },
        { Name = "itemModifiedAppearanceID", Type = "number", Nilable = false },
    },


    sourceID 169092 (169090) Snowy Scarf
    Dashing Buccaneer's 190904, 190905, 190906, 190907

    Last 69478

    /run NarciPerksProgramProductList:Show();
--]]

--/script LoadAddOn("Blizzard_PerksProgram");ShowUIPanel(PerksProgramFrame);PerksProgramFrame:SetPropagateKeyboardInput(true);