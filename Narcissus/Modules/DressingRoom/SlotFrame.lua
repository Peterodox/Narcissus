local _, addon = ...

local DataProvider = addon.TransmogDataProvider;

local MAX_TRY_ON_HISTORY = 5;
local HIDDEN_ILLUSION = 5360;
local SLOT_BUTTON_SHOWN = true;

local After = C_Timer.After;

local TransmogUtil = TransmogUtil;
local MogAPI = C_TransmogCollection;
local GetSourceInfo = MogAPI.GetSourceInfo;
local GetAppearanceSourceDrops = MogAPI.GetAppearanceSourceDrops;
local IsAppearanceFavorite = MogAPI.GetIsAppearanceFavorite;
local IsHiddenVisual = MogAPI.IsAppearanceHiddenVisual;
local GetItemQualityColor = C_Item.GetItemQualityColor;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetSlotVisualID = NarciAPI.GetSlotVisualID;
local FadeFrame = NarciFadeUI.Fade;
local GetSlotIDByInvType = NarciAPI.GetSlotIDByInvType;

----------------------------------------------------
local SlotFrame, GearTextsClipborad, SlotToggle;
local slotButtons = {};

----------------------------------------------------
local emptyTextures = {
    HeadSlot = 133071,
    ShoulderSlot = 135040,
    BackSlot = 133762,
    ChestSlot = 132624,
    WristSlot = 132606,
    HandsSlot = 132958,
    WaistSlot = 132514,
    LegsSlot = 134589,
    FeetSlot = 132543,
    MainHandSlot = 135274,
    SecondaryHandSlot = 134952,
    ShirtSlot = 135030,
    TabardSlot = 255149,
};

local alternateSlotName = {
    [3] = {RIGHTSHOULDERSLOT, LEFTSHOULDERSLOT},
};

----------------------------------------------------
local function IsWeaponSlot(slotID)
    return (slotID == 16 or slotID == 17)
end

local ItemList = {};
ItemList.itemList = {};

local function WipeItemList()
    ItemList.itemList = {};
end

function ItemList:GetList()
    return self.itemList
end

function ItemList:AddItemID(slotID, itemID, bonusID)
    if not itemID then
        return
    end
    if not self.itemList[slotID] then
        self.itemList[slotID] = {};
    end
    self.itemList[slotID].itemID = itemID;
    self.itemList[slotID].itemBonusID = bonusID;
end

function ItemList:AddItemName(slotID, itemName)
    if not itemName then
        return
    end
    if not self.itemList[slotID] then
        self.itemList[slotID] = {};
    end
    self.itemList[slotID].name = itemName;
end

function ItemList:AddItemSourceID(slotID, sourceID)
    if not sourceID then
        return
    end
    if not self.itemList[slotID] then
        self.itemList[slotID] = {};
    end
    self.itemList[slotID].sourceID = sourceID;
end

function ItemList:AddItemSourceText(slotID, sourceText)
    if not self.itemList[slotID] then
        self.itemList[slotID] = {};
    end
    self.itemList[slotID].sourceText = sourceText;
end

function ItemList:AddItem(slotID, itemID, bonusID, itemName, sourceID, sourceText)
    self:AddItemID(slotID, itemID, bonusID);
    self:AddItemName(slotID, itemName);
    self:AddItemSourceID(slotID, sourceID);
    self:AddItemSourceText(slotID, sourceText);
end

function ItemList:SetSecondarySourceID(slotID, secondarySourceID)
    if not secondarySourceID then
        return
    end
    if not self.itemList[slotID] then
        self.itemList[slotID] = {};
    end
    self.itemList[slotID].secondarySourceID = secondarySourceID;
end

function ItemList:GetSecondarySourceID(slotID)
    if self.itemList[slotID] and self.itemList[slotID].secondarySourceID then
        return self.itemList[slotID].secondarySourceID
    end
end


function ItemList:SetSecondarySourceInfo(slotID, itemID, itemName, sourceText)
    if not itemName then
        return
    end
    if not self.itemList[slotID] then
        self.itemList[slotID] = {};
    end
    self.itemList[slotID].secondaryItemID = itemID;
    self.itemList[slotID].secondaryName = itemName;
    self.itemList[slotID].secondarySourceText = sourceText;
end

function ItemList:AddSourceToHistory(slotID, sourceID)
    if not self.tryOnHistory then
        self.tryOnHistory = {};
    end
    if not self.tryOnHistory[slotID] then
        self.tryOnHistory[slotID] = {};
    end
    local data = self.tryOnHistory[slotID];
    for i = 1, #data do
        if data[i] == sourceID then
            table.remove(data, i);
        end
    end
    table.insert(data, sourceID);
end

function ItemList:GetSlotHistory(slotID)
    if self.tryOnHistory and self.tryOnHistory[slotID] then
        return self.tryOnHistory[slotID];
    else
        return {}
    end
end

----------------------------------------------------

----------------------------------------------------
local DataCache = CreateFrame("Frame");
DataCache:Hide();
DataCache.queue = {};

function DataCache:Add(slotID, sourceID, enchantID, isSecondarySourceID)
    self.shouldUpdate = true;
    self.t = 0;
    self.queue[slotID] = {sourceID, enchantID, isSecondarySourceID};
    self:Show();
end


local function GenerateHyperlinkAndSource(slotID, sourceID, enchantID, isSecondarySourceID, runAgain)
    local sourceInfo = GetSourceInfo(sourceID);
    if not sourceInfo then return end;

    local itemID = sourceInfo.itemID;
    local itemQuality = sourceInfo.quality or 1;
    local sourceType = sourceInfo.sourceType;
    local itemModID = sourceInfo.itemModID;
    local hyperlink, unformatedHyperlink;
    local sourceTextColorized, sourcePlainText;
    local _, _, _, hex = GetItemQualityColor(itemQuality);
    local bonusID = 0;
    enchantID = enchantID or "";

    if sourceType == 1 then --TRANSMOG_SOURCE_BOSS_DROP
        local drops = GetAppearanceSourceDrops(sourceID);
        if drops and drops[1] then
            sourceTextColorized = ("|cffe0e0e0"..drops[1].encounter.."|r ".."|cffffD100"..drops[1].instance.."|r|CFFf8e694") or "";
            sourcePlainText = (drops[1].encounter.." "..drops[1].instance) or "";

            if itemModID == 0 then 
                sourceTextColorized = sourceTextColorized.." "..PLAYER_DIFFICULTY1;
                sourcePlainText = sourcePlainText.." "..PLAYER_DIFFICULTY1;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:356".."1"..":1476:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:356".."1"..":1476";
                bonusID = 3561;
            elseif itemModID == 1 then 
                sourceTextColorized = sourceTextColorized.." "..PLAYER_DIFFICULTY2;
                sourcePlainText = sourcePlainText.." "..PLAYER_DIFFICULTY2;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:356".."2"..":1476:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:356".."2"..":1476";
                bonusID = 3562;
            elseif itemModID == 3 then 
                sourceTextColorized = sourceTextColorized.." "..PLAYER_DIFFICULTY6;
                sourcePlainText = sourcePlainText.." "..PLAYER_DIFFICULTY6;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:356".."3"..":1476:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:356".."3"..":1476";
                bonusID = 3563;
            elseif itemModID == 4 then
                sourceTextColorized = sourceTextColorized.." "..PLAYER_DIFFICULTY3;
                sourcePlainText = sourcePlainText.." "..PLAYER_DIFFICULTY3;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:356".."4"..":1476:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:356".."4"..":1476";
                bonusID = 3564;
            end
        end
    else
        if sourceType == 2 then --quest
            sourceTextColorized = TRANSMOG_SOURCE_2;
            if itemModID == 3 then 
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:512".."6"..":1562:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:512".."6"..":1562";
                bonusID = 5126;
            elseif itemModID == 2 then 
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:512".."5"..":1562:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:512".."5"..":1562";
                bonusID = 5125;
            elseif itemModID == 1 then 
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:512".."4"..":1562:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:512".."4"..":1562";
                bonusID = 5124;
            end
        elseif sourceType == 3 then --vendor
            sourceTextColorized = TRANSMOG_SOURCE_3
            hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
            unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
        elseif sourceType == 4 then --world drop
            sourceTextColorized = TRANSMOG_SOURCE_4
            hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
            unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
        elseif sourceType == 5 then --achievement
            sourceTextColorized = TRANSMOG_SOURCE_5
            hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r"
            unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::"
        elseif sourceType == 6 then	--profession
            sourceTextColorized = TRANSMOG_SOURCE_6
            hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
            unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
        else
            if itemQuality == 6 then
                sourceTextColorized = ITEM_QUALITY6_DESC;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
				if slotID == 16 then
					bonusID = itemModID or 0;	--Artifact use itemModID "7V0" + modID - 1
				else
					bonusID = 0;
				end
            elseif itemQuality == 5 then
                sourceTextColorized = ITEM_QUALITY5_DESC;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
            end
        end
    end

    if not hyperlink then
        hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
        unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
    end

    if sourceInfo.name then
        if isSecondarySourceID then
            ItemList:SetSecondarySourceInfo(slotID, itemID, sourceInfo.name, sourceTextColorized);
        else
            ItemList:AddItem(slotID, itemID, bonusID, sourceInfo.name, sourceID, sourceTextColorized);
        end
    elseif not runAgain then
        --cache
        DataCache:Add(slotID, sourceID, enchantID, isSecondarySourceID);
    end

    return hyperlink, unformatedHyperlink, sourceTextColorized, (sourcePlainText or sourceTextColorized);
end

local function GetItemEquipLocation(item)
    local itemEquipLoc, _;
    if type(item) == "number" then
        --sourceID
        local sourceInfo = GetSourceInfo(item);
        if sourceInfo then
            _, _, _, itemEquipLoc = GetItemInfoInstant(sourceInfo.itemID);
        end
    else
        --itemLink
        _, _, _, itemEquipLoc = GetItemInfoInstant(item);
    end
    return GetSlotIDByInvType(itemEquipLoc);
end

local function IsItemOffHandBow(sourceID)
    local sourceInfo = GetSourceInfo(sourceID);
    if sourceInfo then
        local _, _, _, itemEquipLoc = GetItemInfoInstant(sourceInfo.itemID);
        if itemEquipLoc == "INVTYPE_RANGED" then
            return true
        end
    end
end

----------------------------------------------------
local MotionHandler = {};

function MotionHandler:Init()
    local fadeDelay = 2;
    local f = CreateFrame("Frame");
    f:Hide();
    f.t = 0;
    f:SetScript("OnUpdate", function(f, elapsed)
        f.t = f.t + elapsed;
        if f.t >= fadeDelay then
            f.t = 0;
            if SlotFrame:IsFocusLost() then
                f:Hide();
            end
        end
    end);
    self.executeFrame = f;
end

function MotionHandler:Start()
    self.executeFrame.t = 0;
    self.executeFrame:Show();
end

function MotionHandler:Stop()
    self.executeFrame:Hide();
end

----------------------------------------------------
--[[
NarciDressingRoomItemButtonMixin = {};
--]]

local function SecondaryButton_OnEnter(itemButton)
    GameTooltip:SetOwner(itemButton, "ANCHOR_NONE");
    GameTooltip:SetPoint("BOTTOMLEFT", itemButton, "TOPLEFT", 0, 8);
    if (itemButton.name) then
        GameTooltip:SetText(itemButton.name);
        local sourceText = DataProvider:GetIllusionSourceText(itemButton.sourceID);
		if sourceText then
			GameTooltip:AddLine(sourceText, 1, 1, 1, 1);
		end
        GameTooltip:Show();
    elseif (itemButton.hyperlink) then
        GameTooltip:SetHyperlink(itemButton.hyperlink);
        GameTooltip:Show();
    else
        GameTooltip:Hide();
    end
end

local function HideGameTooltip()
    GameTooltip:Hide();
end


NarciDressingRoomItemButtonMixin = {};

function NarciDressingRoomItemButtonMixin:OnLoad()
    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;

    self:RegisterForClicks("RightButtonUp");
    self:RegisterForDrag("LeftButton");
    self:SetFlattensRenderLayers(true);
end

function NarciDressingRoomItemButtonMixin:Init(slotName)
    local slotID, textureName = GetInventorySlotInfo(slotName);
    self.slotID = slotID;
    self.emptyTexture = emptyTextures[slotName] or textureName;
    self.localizedName = _G[string.upper(slotName)];
    slotButtons[slotID] = self;

    if DataProvider:CanHaveSecondaryAppearanceForSlotID(slotID) then
        self.secondarySourceID = 0;
        self.isValidForSecondarySource = true;
        self.SecondaryButton:SetScript("OnEnter", SecondaryButton_OnEnter);
        self.SecondaryButton:SetScript("OnLeave", HideGameTooltip);
    end

    self.isWeaponSlot = IsWeaponSlot(slotID);

    return slotID
end

function NarciDressingRoomItemButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE");
    GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 2, 4);
    if (self.hyperlink) then
        GameTooltip:SetHyperlink(self.hyperlink);
        GameTooltip:Show();
    elseif self.localizedName then
        GameTooltip:SetText(self.localizedName);
        GameTooltip:Show();
    else
        GameTooltip:Hide();
    end

    if self:HasItem() then
        FadeFrame(self.InnerHighlight, 0.12, 1);
    end
end

function NarciDressingRoomItemButtonMixin:OnLeave()
    HideGameTooltip();
    if self:HasItem() then
        FadeFrame(self.InnerHighlight, 0.2, 0);
    end
end

function NarciDressingRoomItemButtonMixin:OnClick(button)
    if button == "RightButton" then
        if not self.visualID then return end

        local state;
        if IsAppearanceFavorite(self.visualID) then
            --Remove from favorite
            state = false;
        else
            state = true;
            PlaySound(39672, "SFX");
        end

        C_TransmogCollection.SetIsAppearanceFavorite(self.visualID, state);
    end
end

function NarciDressingRoomItemButtonMixin:OnDragStart()

end

function NarciDressingRoomItemButtonMixin:OnDragStop()

end

function NarciDressingRoomItemButtonMixin:IsSameSouce(newSouceID, newSecondarySourceID)
    if self.isSlotHidden then
        return false
    else
        if self.isValidForSecondarySource then
            return (newSouceID == self.sourceID) and (newSecondarySourceID == self.secondarySourceID);
        else
            return (newSouceID == self.sourceID)
        end
    end
end

function NarciDressingRoomItemButtonMixin:SetItemSource(sourceID, secondarySourceID)
    --secondarySourceID can be (ItemTransmogInfoMixin).secondaryAppearanceID or .illusionID
    if sourceID == 0 and self.isSlotHidden then
        return
    end

    local isKnown;
    sourceID, isKnown = DataProvider:FindKnownSource(sourceID);

    self.sourceID = sourceID;
    self:HideSlot(false);
    self:SetSecondarySource(secondarySourceID);

    if not(sourceID and sourceID > 0) then
        self.hyperlink = nil;
        self.visualID = nil;
        self.ItemIcon:SetTexture(self.emptyTexture);
        self:Desaturate(true);
        self:SetBottomMark();
        return
    end

    self.visualID = DataProvider:GetVisualIDBySourceID(sourceID);
    local isFavorite = IsAppearanceFavorite(self.visualID);
    self.ItemIcon:SetTexture( MogAPI.GetSourceIcon(sourceID) );
    self:Desaturate(false);
    self:SetBottomMark(isKnown, isFavorite);
    if self.isWeaponSlot then
        self.hyperlink = GenerateHyperlinkAndSource(self.slotID, sourceID, secondarySourceID);
    else
        self.hyperlink = GenerateHyperlinkAndSource(self.slotID, sourceID);
    end
end

function NarciDressingRoomItemButtonMixin:SetBottomMark(isKnown, isFavorite)
    if isFavorite then
        self.GreenTick:Hide();
        self.YellowStar:Show();
    elseif isKnown then
        self.GreenTick:Show();
        self.YellowStar:Hide();
    else
        self.GreenTick:Hide();
        self.YellowStar:Hide();
    end
end

function NarciDressingRoomItemButtonMixin:UpdateBottomMark()
    local sourceID, isKnown = DataProvider:FindKnownSource(self.sourceID);
    local isFavorite = DataProvider:IsSourceFavorite(sourceID);
    self:SetBottomMark(isKnown, isFavorite);
end

function NarciDressingRoomItemButtonMixin:SetSecondarySource(secondarySourceID)
    if self.isValidForSecondarySource then
        local hasSecondaryAppearance;
        if secondarySourceID and secondarySourceID > 0 and secondarySourceID ~= HIDDEN_ILLUSION then
            local isKnown, icon, visualID;
            if self.isWeaponSlot then
                local illusionID = secondarySourceID;
                visualID, self.SecondaryButton.name, icon, isKnown = DataProvider:GetIllusionInfo(illusionID);
                if icon then
                    hasSecondaryAppearance = true;
                end
                ItemList:SetSecondarySourceID(self.slotID, illusionID);
            else
                secondarySourceID, isKnown = DataProvider:FindKnownSource(secondarySourceID);
                local isSecondarySourceID = true;
                self.SecondaryButton.hyperlink = GenerateHyperlinkAndSource(self.slotID, secondarySourceID, nil, isSecondarySourceID);
                icon = MogAPI.GetSourceIcon(secondarySourceID);
                ItemList:SetSecondarySourceID(self.slotID, secondarySourceID);
                if icon then
                    hasSecondaryAppearance = true;
                end
            end
            self.SecondaryItemIcon:SetTexture(icon);  --MogAPI.GetSourceIcon(sourceID)
            self.SecondaryButton.GreenTick:SetShown(isKnown);
        else
            hasSecondaryAppearance = false;
            ItemList:SetSecondarySourceID(self.slotID, 0);
        end
        if hasSecondaryAppearance then
            self.Border:SetTexCoord(0.5, 1, 0, 1);
            self.SecondaryButton:Show();
            self.SecondaryButton.sourceID = secondarySourceID;
            self.SecondaryItemIcon:Show();
        else
            self.Border:SetTexCoord(0, 0.5, 0, 1);
            self.SecondaryButton:Hide();
            self.SecondaryButton.name = nil;
            self.SecondaryButton.hyperlink = nil;
            self.SecondaryItemIcon:Hide();
        end
        self.secondarySourceID = secondarySourceID;
    end
end

function NarciDressingRoomItemButtonMixin:HasItem()
    return (self.sourceID and self.sourceID > 0)
end

function NarciDressingRoomItemButtonMixin:DressSlot(state)
	local playerActor = DressUpFrame.ModelScene:GetPlayerActor();
	if (not playerActor) then
		return false;
	end

    if state then
        if playerActor.SetItemTransmogInfo then
            local transmogInfo = CreateFromMixins(ItemTransmogInfoMixin);
            if self.slotID == 16 or self.slotID == 17 then
                transmogInfo:Init(self.sourceID, nil, self.secondarySourceID);  --this secondarySourceID is in fact illusionID
            else
                transmogInfo:Init(self.sourceID, self.secondarySourceID);
            end
            playerActor:SetItemTransmogInfo(transmogInfo, self.slotID);
        else
            if self.slotID == 16 then
                playerActor:TryOn(self.sourceID, "MAINHANDSLOT", self.secondarySourceID);
            elseif self.slotID == 17 then
                playerActor:TryOn(self.sourceID, "SECONDARYHANDSLOT", self.secondarySourceID);
            else
                playerActor:TryOn(self.sourceID, self.slotID);
            end
        end
    else
        playerActor:UndressSlot(self.slotID);
    end
end

function NarciDressingRoomItemButtonMixin:Desaturate(state)
    self.ItemIcon:SetDesaturated(state);
    if state then
        self.ItemIcon:SetVertexColor(0.47, 0.4, 0.3);
        self.Border:SetVertexColor(0.5, 0.5, 0.5);
        self.ItemIcon:SetSize(18, 18);
        self.Border:SetSize(60, 60);
    else
        self.ItemIcon:SetVertexColor(1, 1, 1);
        self.Border:SetVertexColor(1, 1, 1);
        self.ItemIcon:SetSize(22, 22);
        self.Border:SetSize(68, 68);
    end
end

function NarciDressingRoomItemButtonMixin:HideSlot(state)
    if state then
        self.ItemIcon:SetVertexColor(0.6, 0.6, 0.6);
        if self.isValidForSecondarySource then
            self.SecondaryItemIcon:SetVertexColor(0.6, 0.6, 0.6);
        end
    else
        self.ItemIcon:SetVertexColor(1, 1, 1);
        if self.isValidForSecondarySource then
            self.SecondaryItemIcon:SetVertexColor(1, 1, 1);
        end
    end
    self.RedEye:SetShown(state);
    self.isSlotHidden = state;
end

function NarciDressingRoomItemButtonMixin:Shine()
    self.BorderShine.Shine:Stop();
    self.BorderShine:Show();
    self.BorderShine.Shine:Play();
end


----------------------------------------------------
local function SlotFrame_Enable(state)
    SLOT_BUTTON_SHOWN = state;
    if state then
        if SlotToggle then
            SlotToggle.Icon:SetTexCoord(0.75, 0.875, 0.25, 0);
        end
    else
        if SlotToggle then
            SlotToggle.Icon:SetTexCoord(0.75, 0.875, 0, 0.25);
        end
    end
    SlotFrame:UpdateVisibility();
end


local SlotToggleMixin = {};
do
    function SlotToggleMixin:Init()
        self.Init = nil;

        self:SetSize(20, 20);

        self.Background = self:CreateTexture(nil, "BACKGROUND");
        self.Background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DressingRoom\\OptionButton", nil, nil, "TRILINEAR");
        self.Background:SetTexCoord(0.5, 0.75, 0, 0.5);
        self.Background:SetPoint("CENTER", self, "CENTER", 0, 0);
        self.Background:SetSize(24, 24);

        self.Icon = self:CreateTexture(nil, "OVERLAY");
        self.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\DressingRoom\\OptionButton");
        self.Icon:SetTexCoord(0.75, 0.875, 0, 0.25);
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0);
        self.Icon:SetSize(12, 12);
        self:SetHighlighted(false);

        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnClick", self.OnClick);
    end

    function SlotToggleMixin:SetHighlighted(state)
        if state then
            self.Icon:SetVertexColor(1, 1, 1);
        else
            self.Icon:SetVertexColor(0.6, 0.6, 0.6);
        end
    end

    function SlotToggleMixin:OnEnter()
        self:SetHighlighted(true);
        local tooltip = GameTooltip;
        tooltip:SetOwner(self, "ANCHOR_RIGHT");
        tooltip:SetText(Narci.L["Toggle Equipment Slots"], 1, 1, 1, true);
        tooltip:Show();
    end

    function SlotToggleMixin:OnLeave()
        self:SetHighlighted(false);
        HideGameTooltip();
    end

    function SlotToggleMixin:OnClick()
        SlotFrame_Enable(not SLOT_BUTTON_SHOWN);
        NarcissusDB.DressingRoomShowSlot = SLOT_BUTTON_SHOWN;
        HideGameTooltip();
    end
end


NarciDressingRoomSlotFrameMixin = {};

function NarciDressingRoomSlotFrameMixin:OnLoad()
    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);

    SlotFrame = self;
    GearTextsClipborad = NarciDressingRoomGearTextsClipborad;
    MotionHandler:Init();

    --Highlight slot when changing item
    hooksecurefunc("DressUpVisual", function(item)
        if item then
            local slotID = GetItemEquipLocation(item);
            if slotID then
                self:ShineSlot(slotID);
                self:FadeIn();
                self:SetManuallyChanged(true);
            end
        end
        --print("DressUpVisual")
    end);

    hooksecurefunc("DressUpItemTransmogInfo", function(itemTransmogInfo)
        if itemTransmogInfo and itemTransmogInfo.appearanceID then
            local slotID = GetItemEquipLocation(itemTransmogInfo.appearanceID);
            if slotID then
                self:ShineSlot(slotID);
                self:FadeIn();
                self:SetManuallyChanged(true);
            end
        end
        --print("DressUpItemTransmogInfo")
    end);

    --OutfitDropDown
    if DressUpItemTransmogInfoList then
        hooksecurefunc("DressUpItemTransmogInfoList", function(itemTransmogInfoList)
            self:FadeIn();
            self:SetManuallyChanged(true);
            --print("DressUpItemTransmogInfoList")
        end)
    end

    --Ctrl+Click Wardrobe Items
    if DressUpCollectionAppearance then
        hooksecurefunc("DressUpCollectionAppearance", function(sourceID, transmogLocation, categoryID)
            local slotID = transmogLocation.slotID;
            if slotID then
                self:ShineSlot(slotID);
                self:FadeIn();
                self:SetManuallyChanged(true);
            end
            --print("DressUpCollectionAppearance")
        end);
    end

    self:SetAlpha(0.25);


    --Create a toggle to show/hide Slots
    SlotToggle = CreateFrame("Button", nil, self);
    Mixin(SlotToggle, SlotToggleMixin);
    SlotToggle:Init();
    SlotToggle:SetIgnoreParentAlpha(true);
    self.SlotToggle = SlotToggle;


    SlotFrame_Enable(addon.GetDBValue("DressingRoomShowSlot"));
end

function NarciDressingRoomSlotFrameMixin:IsFocusLost()
    if not self:IsMouseOver() then
        self:EnableMotion(true);
        if self:IsShown() then
            FadeFrame(self, 2, 0.25);
        end
        return true
    end
end

function NarciDressingRoomSlotFrameMixin:EnableMotion(state)
    self:EnableMouse(state)
    self:SetMouseMotionEnabled(state)
    self:SetMouseClickEnabled(state)
end

function NarciDressingRoomSlotFrameMixin:OnEnter()
    MotionHandler:Start();
    self:EnableMotion(false);
    FadeFrame(self, 0.2, 1);
end

function NarciDressingRoomSlotFrameMixin:OnLeave()

end

function NarciDressingRoomSlotFrameMixin:OnHide()
    self:StopAnimating();
    self.Notification:SetAlpha(0);
    self:SetManuallyChanged(false);
end

function NarciDressingRoomSlotFrameMixin:FadeIn()
    if self.isInvisible or self.isDisabled then return end;

    MotionHandler:Start();
    if not self.isFading then
        self.isFading = true;
        FadeFrame(self, 0.2, 1);
        After(0, function()
            self.isFading = nil;
        end);
    end
end

function NarciDressingRoomSlotFrameMixin:FadeOut()
    if self.isInvisible or self.isDisabled then return end;

    FadeFrame(self, 0.2, 0.25);
end

function NarciDressingRoomSlotFrameMixin:ShineSlot(slotID)
    if slotButtons[slotID] then
        slotButtons[slotID]:Shine();
    end
end

function NarciDressingRoomSlotFrameMixin:Disable()
    --Disable our SlotFrame entirely when detecting some incompatible addon
    self.isDisabled = true;
    MotionHandler:Stop();
    self:Hide();
end


function NarciDressingRoomSlotFrameMixin:ShowPlayerTransmog()
    local sourceID, visualID, hasSecondaryAppearance;
    for slotID, button in pairs(slotButtons) do
        sourceID, visualID, hasSecondaryAppearance = GetSlotVisualID(slotID);
        button:SetItemSource(sourceID);
    end
    self:FadeIn();
end


local function DressUpSources(sources, mainHandEnchant, offHandEnchant)
    if ( not sources ) then
		return true;
    end

	local playerActor = DressUpFrame.ModelScene:GetPlayerActor();
	if (not playerActor) then
		return false;
	end
    playerActor:Undress();
    if playerActor.SetItemTransmogInfo then
        local sourceID, secondarySourceID;
        local currentInfo;
        for slotID, transmogInfo in pairs(sources) do
            sourceID, secondarySourceID = DataProvider:GetSourceIDFromTransmogInfo(transmogInfo);
            --if transmogInfo and transmogInfo.appearanceID == 0 then
            --    playerActor:UndressSlot(slotID);
            --end
            if slotButtons[slotID] then
                slotButtons[slotID]:SetItemSource(sourceID, secondarySourceID);
            end
            if slotID == 16 or slotID == 17 then
                currentInfo = playerActor:GetItemTransmogInfo(slotID);
                if not transmogInfo:IsEqual(currentInfo) then
                    playerActor:TryOn(transmogInfo.appearanceID, (slotID == 16 and "MAINHANDSLOT") or "SECONDARYHANDSLOT", transmogInfo.illusionID);    --ME FIXED?
                end
            else
                playerActor:SetItemTransmogInfo(transmogInfo);
            end
        end
    else
        local currentID;
        for slotID, sourceID in pairs(sources) do
            if slotButtons[slotID] then
                if slotID == 16 then
                    slotButtons[slotID]:SetItemSource(sourceID, mainHandEnchant);
                    if not IsItemOffHandBow(sourceID) then
                        currentID = playerActor:GetSlotTransmogSources(slotID);
                        if sourceID ~= currentID then
                            playerActor:TryOn(sourceID, "MAINHANDSLOT", mainHandEnchant);
                        end
                    end
                elseif slotID == 17 then
                    currentID = playerActor:GetSlotTransmogSources(slotID);
                    if sourceID ~= currentID then
                        playerActor:TryOn(sourceID, "SECONDARYHANDSLOT", offHandEnchant);
                    end
                    slotButtons[slotID]:SetItemSource(sourceID, offHandEnchant);
                else
                    playerActor:TryOn(sourceID);
                    slotButtons[slotID]:SetItemSource(sourceID);
                end
            end
        end
    end

    --Hold Bow
    local sheathed = playerActor:GetSheathed();
    playerActor:SetSheathed(not sheathed);
    playerActor:SetSheathed(sheathed);
end

function NarciDressingRoomSlotFrameMixin:SetSources(sources, mainHandEnchant, offHandEnchant)
    WipeItemList();
    DressUpSources(sources, mainHandEnchant, offHandEnchant);
end

function NarciDressingRoomSlotFrameMixin:UpdateVisibility()
    --Hide when minimized
    self.isInvisible = not SLOT_BUTTON_SHOWN;
    if SLOT_BUTTON_SHOWN then
        if not self.isDisabled then
            self.SlotContainer:Show();
            MotionHandler:Start();
        end
    else
        MotionHandler:Stop();
        self.SlotContainer:Hide();
    end

    if self.shouldShowSlot and (not self.isDisabled) then
        SlotToggle:Show();
        self:Show();
    else
        SlotToggle:Hide();
        self:Hide();
    end
end

function NarciDressingRoomSlotFrameMixin:SetShouldShowSlot(state)
    --Show slot when DressUpFrame is maximized
    --Doesn't affect SlotToggle
    self.shouldShowSlot = state;
    self:UpdateVisibility();
end

function NarciDressingRoomSlotFrameMixin:SetManuallyChanged(state)
    self.manuallyChanged = (state and true) or nil;
end

function NarciDressingRoomSlotFrameMixin:IsManuallyChanged()
    return self.manuallyChanged == true
end


local ITEM_SOURCE_FORMAT_UNKNOWN_SOURCE_NO_ID = "|cffffD100%s:|r |cffb8b8b8%s|r";
local ITEM_SOURCE_FORMAT_UNKNOWN_SOURCE_WITH_ID = "|cffffD100%s:|r |cffb8b8b8%s|r |cff808080%s|r";
local ITEM_SOURCE_FORMAT_NO_ID = "|cffffD100%s:|r |cffb8b8b8%s|r |cff808080(|r%s|cff808080)|r";
local ITEM_SOURCE_FORMAT_WITH_ID = "|cffffD100%s:|r |cffb8b8b8%s|r |cff808080%s|r |cff808080(|r%s|cff808080)|r";
local ITEM_SOURCE_ILLUSION = "|cffff80ff".. (TRANSMOGRIFIED_ENCHANT or "Illusion: %s") .. "|r";

local includeItemID;

local function PrintItemList()
    if not GearTextsClipborad:IsVisible() then return end;

    if includeItemID == nil then
        includeItemID = NarcissusDB.DressingRoomIncludeItemID;
    end

    local itemList = ItemList:GetList();
    local data;
    local itemText = "";
    local slotName, itemName, localizedSlotName;
    local isFirstLine = true;
    local formatedItemList = {};
    local canHaveSecondaryVisual;
    for slotID = 1, 19 do
        data = itemList[slotID];
        if data and not slotButtons[slotID].isSlotHidden then
            itemName = data.name;
            if itemName then
                if isFirstLine then
                    isFirstLine = false;
                else
                    itemText = itemText .. "\n";
                end
                slotName = TransmogUtil.GetSlotName(slotID);
                if slotName then
                    localizedSlotName = _G[slotName];
                end
                if slotID == 3 then
                    local secondarySourceID = ItemList:GetSecondarySourceID(slotID);
                    if secondarySourceID and secondarySourceID ~= 0 then
                        localizedSlotName = alternateSlotName[3][1] or localizedSlotName;
                    end
                end
                itemName = data.name;
                if itemName and localizedSlotName then
                    if data.sourceText then
                        if includeItemID then
                            itemText = itemText .. string.format(ITEM_SOURCE_FORMAT_WITH_ID, localizedSlotName, itemName, data.itemID, data.sourceText);
                        else
                            itemText = itemText .. string.format(ITEM_SOURCE_FORMAT_NO_ID, localizedSlotName, itemName, data.sourceText);
                        end
                    else
                        if includeItemID then
                            itemText = itemText .. string.format(ITEM_SOURCE_FORMAT_UNKNOWN_SOURCE_WITH_ID, localizedSlotName, itemName, data.itemID);
                        else
                            itemText = itemText .. string.format(ITEM_SOURCE_FORMAT_UNKNOWN_SOURCE_NO_ID, localizedSlotName, itemName);
                        end
                    end

                    if DataProvider:CanHaveSecondaryAppearanceForSlotID(slotID) then
                        local secondarySourceID = ItemList:GetSecondarySourceID(slotID);
                        if secondarySourceID and secondarySourceID ~= 0 then
                            if IsWeaponSlot(slotID) then
                                local sourceName = DataProvider:GetIllusionName(secondarySourceID);
                                if sourceName then
                                    itemText = itemText.." "..string.format(ITEM_SOURCE_ILLUSION, sourceName);
                                end
                            else
                                itemName = data.secondaryName;
                                localizedSlotName = alternateSlotName[3][2] or "Left Shoulder";
                                if itemName then
                                    itemText = itemText.."\n";
                                    if data.secondarySourceText then
                                        if includeItemID then
                                            itemText = itemText .. string.format(ITEM_SOURCE_FORMAT_WITH_ID, localizedSlotName, itemName, data.secondaryItemID, data.secondarySourceText);
                                        else
                                            itemText = itemText .. string.format(ITEM_SOURCE_FORMAT_NO_ID, localizedSlotName, itemName, data.secondarySourceText);
                                        end
                                    else
                                        if includeItemID then
                                            itemText = itemText .. string.format(ITEM_SOURCE_FORMAT_UNKNOWN_SOURCE_WITH_ID, localizedSlotName, itemName, data.secondaryItemID);
                                        else
                                            itemText = itemText .. string.format(ITEM_SOURCE_FORMAT_UNKNOWN_SOURCE_NO_ID, localizedSlotName, itemName);
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                formatedItemList[slotID] = {data.itemID, data.itemBonusID};
            end
        end
    end

    local popup = NarciDressingRoomSharedPopup;
    popup.GearTextContainer:SetText(itemText);
    popup.GearTextContainer.Header:SetText(Narci.L["Item List"]);

    popup.ExternalLink:SetText( NarciAPI.EncodeItemlist(formatedItemList) );
    popup.ExternalLink:SetDefaultCursorPosition(0);

    popup.SlashCommand:SetText( NarciAPI.GetOutfitSlashCommand() );
    popup.SlashCommand:SetDefaultCursorPosition(0);
    popup.SlashCommand.Header:SetText(Narci.L["InGame Command"])
end

NarciDressingRoomAPI.PrintItemList = PrintItemList;
NarciDressingRoomAPI.WipeItemList = WipeItemList;

DataCache:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.25 then
        if self.shouldUpdate then
            self.shouldUpdate = nil;
            for slotID, data in pairs(self.queue) do
                GenerateHyperlinkAndSource(slotID, data[1], data[2], data[3], true);
            end
        end
        if self.t > 0.5 then
            wipe(self.queue);
            self:Hide();
            PrintItemList();
        end
    end
end)


function NarciDressingRoomItemButtonMixin:OnMouseDown(mouseButton)
    if mouseButton == "LeftButton" then
        if self:HasItem() then
            self:HideSlot(not self.isSlotHidden);
            self:DressSlot(not self.isSlotHidden);
        else
            self:DressSlot(false);
        end
        PrintItemList();
    end
end


NarciDressingRoomItemIDToggleMixin = {};

function NarciDressingRoomItemIDToggleMixin:OnShow()
    local state = NarcissusDB.DressingRoomIncludeItemID;
    self.Tick:SetShown(state);
    self:SetScript("OnShow", nil);
    self.OnShow = nil;
end

function NarciDressingRoomItemIDToggleMixin:OnClick()
    local state = not NarcissusDB.DressingRoomIncludeItemID;
    NarcissusDB.DressingRoomIncludeItemID = state;
    self.Tick:SetShown(state);
    includeItemID = state;

    PrintItemList();
end

local PrintOrders = {
    1, 3, 15, 5, 4, 19, 9, 10, 6, 7, 8, 16, 17,
};

local function GetItemNames()
    local slotID;
    local data, itemName, itemText;
    local itemList = ItemList:GetList();
    for i = 1, #PrintOrders do
        slotID = PrintOrders[i];
        data = itemList[slotID];
        if data then
            itemName = data.name;
            if itemName then
                if data.sourceID and IsHiddenVisual(data.sourceID) then
                    itemName = "|cff808080"..itemName.."|r";
                end
                if itemText then
                    itemText = itemText .. "\n" .. itemName;
                else
                    itemText = itemName;
                end
                if DataProvider:CanHaveSecondaryAppearanceForSlotID(slotID) then
                    local secondarySourceID = ItemList:GetSecondarySourceID(slotID);
                    if secondarySourceID and secondarySourceID ~= 0 then
                        if IsWeaponSlot(slotID) then
                            local sourceName = DataProvider:GetIllusionName(secondarySourceID);
                            if sourceName then
                                itemText = itemText.." "..sourceName;
                            end
                        else
                            itemName = data.secondaryName;
                            if itemName then
                                itemText = itemText.."\n"..itemName;
                            end
                        end
                    end
                end
            end
        end
    end
    return itemText
end

NarciDressingRoomAPI.GetItemNames = GetItemNames;
