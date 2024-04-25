local L = Narci.L;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;
local GetGemBonus = NarciAPI.GetGemBonus; --(Gem's itemID or hyperlink)
local GetShardBonus = NarciAPI.GetDominationShardBonus;
local max = math.max;
local FadeFrame = NarciFadeUI.Fade;

local GemIDList = {};
local DominationShardIDs = {};
local GetItemIcon = C_Item.GetItemIconByID;
local GetItemCount = C_Item.GetItemCount;
local GetItemInfo = C_Item.GetItemInfo;
local NUM_EXAMPLE_GEMS = 3;

for gemID, info in pairs(Narci.GemData) do
    tinsert(GemIDList, gemID);
end

if Narci.DominationShards then
    local typeName = {
        [1] = "Frost",
        [2] = "Unholy",
        [3] = "Blood",
    }
    for gemID, info in pairs(Narci.DominationShards) do
        tinsert(DominationShardIDs, gemID);
    end
end

local function SortedByID(a, b) return a > b; end
table.sort(GemIDList, SortedByID);
table.sort(DominationShardIDs, SortedByID);

local GemCountList = {};

local function GetMatchCount(referenceList, outputList)
    wipe(outputList);
    local count = 0;
    local i = 1;
    local exampleGems = {};
    for k, itemID in pairs(referenceList) do
        count = GetItemCount(itemID);
        if count ~= 0 then
            outputList[i] = {itemID, count};
            if i <= NUM_EXAMPLE_GEMS then
                tinsert(exampleGems, itemID);
            end
            i = i + 1;
        end
    end

    return (i - 1), exampleGems
end


NarciGemSlotMixin = {};

function NarciGemSlotMixin:CountGems()
    local numGems, exampleGems;
    local list;
    if self.isDomiationSocket then
        list = DominationShardIDs;
    else
        list = GemIDList;
    end
    numGems, exampleGems = GetMatchCount(list, GemCountList);
    self.numGems = numGems;
    return numGems, exampleGems;
end

function NarciGemSlotMixin:OnEnter()
    local tooltip = Narci_GearEnhancement_Tooltip;
    local offsetX, extraWidth;
    tooltip:ClearAllPoints();
    tooltip.TailMask:ClearAllPoints();
    if self:GetParent().isRight then
		tooltip:SetPoint("RIGHT", self, "LEFT", 4, 0);
        tooltip.TailMask:SetPoint("LEFT", tooltip, "LEFT", 0, 0);
        tooltip.TailMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Linear-ShowRight");
        offsetX = 64;
        extraWidth = 36;
	else
		tooltip:SetPoint("LEFT", self, "RIGHT", -4, 0);
        tooltip.TailMask:SetPoint("RIGHT", tooltip, "RIGHT", 0, 0);
        tooltip.TailMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Linear-ShowLeft");
        offsetX = 16;
        extraWidth = 80;
	end

    local link = self:GetParent().gemLink;
    --Show optional gem types in your inventory
    local numGems, exampleGems = self:CountGems();

    local text;     --Show how many types of gems in bags
    local sgf = tooltip.SpareGemFrame;
    if numGems > 0 then
        text = L["In Bags"];
        sgf.Text:SetText(text);
        if not sgf.Icons then
            sgf.Icons = {};
        end
        local icons = sgf.Icons;
        for i = 1, #icons do
            icons[i]:Hide();
        end
        local texObject;
        for i = 1, #exampleGems do
            texObject = icons[i];
            if not texObject then
                texObject = sgf:CreateTexture(nil, "OVERLAY");
                texObject:SetSize(12, 12);
                texObject:SetPoint("LEFT", sgf.Text, "RIGHT", 8 + 14*(i - 1), 0);
                texObject:SetTexCoord(0.05, 0.95, 0.05, 0.95);
                icons[i] = texObject;
            end
            texObject:SetTexture( GetItemIcon(exampleGems[i]) );
            texObject:Show();
        end
        local numExceed = numGems - NUM_EXAMPLE_GEMS;
        if numExceed > 0 then
            sgf.More:SetText("+"..numExceed);
            sgf.More:Show();
            sgf.ColorBlock:Show();
            sgf.ColorBlock:ClearAllPoints();
            sgf.ColorBlock:SetPoint("LEFT", texObject, "RIGHT", 2, 0);
            sgf.ColorBlock:SetWidth(sgf.More:GetWidth() + 4);
        else
            sgf.More:Hide();
            sgf.ColorBlock:Hide();
        end
        sgf:Show();
        tooltip.WhiteStrip:Show();
    else
        sgf.Text:SetText("");
        sgf:Hide();
        tooltip.WhiteStrip:Hide();
    end

    local ItemName = tooltip.ItemName;
    local Bonus = tooltip.Bonus;
    ItemName:ClearAllPoints();
    Bonus:ClearAllPoints();
    local _, bonusText, name, quality, icon;

    if self.isDomiationSocket and self.sockedGemItemID then
        link = "item:"..self.sockedGemItemID..":::::::::::::::::";
    end
    local height;
    if link then
        if self.isDomiationSocket then
            bonusText = GetShardBonus(self.sockedGemItemID);
        else
            if NarciAPI.GetCrystallicSpell(self.sockedGemItemID) then
                bonusText = NarciAPI.GetCrystallicEffect(self.sockedGemItemID);
            else
                bonusText = GetGemBonus(link);
            end
        end
        name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(link);
        Bonus:SetPoint("BOTTOMLEFT", tooltip, "LEFT", offsetX, 1);
        ItemName:SetPoint("TOPLEFT", tooltip, "LEFT", offsetX, -3);
        tooltip.Icon:SetSize(60, 48);
        height = 48;
    else
        if self.isDomiationSocket then
            name = EMPTY_SOCKET_DOMINATION;  --EMPTY;
            icon = 4095404;
        else
            name = EMPTY_SOCKET_PRISMATIC;
            icon = 458977;
        end
        quality = 1;
        ItemName:SetPoint("LEFT", tooltip, "LEFT", offsetX, 0);
        tooltip.Icon:SetSize(50, 40);
        height = 40;
    end
    sgf:SetPoint("LEFT", tooltip.WhiteStrip, "LEFT", offsetX, 0);
    tooltip:SetHeight(height);

	local r, g, b = GetItemQualityColor(quality);

	tooltip.Icon:SetTexture(icon);
    tooltip.Icon:SetVertexColor(0.25, 0.25, 0.25);
	ItemName:SetText(name);
	ItemName:SetTextColor(r, g, b);
	Bonus:SetText(bonusText);
    tooltip:SetWidth(max(Bonus:GetWrappedWidth(),ItemName:GetWrappedWidth(), sgf.Text:GetWrappedWidth()) + extraWidth + offsetX);
	tooltip:SetParent(self);
	tooltip:SetFrameStrata("TOOLTIP");

    tooltip:SetMouseMotionEnabled(false);
	FadeFrame(tooltip, 0.15, 1, 0);
end


function NarciGemSlotMixin:OnLeave()
    Narci_GearEnhancement_Tooltip:Hide();
end

function NarciGemSlotMixin:LoadGemList()
    self:CountGems();
    SOCKETED_ITEM_LEVEL = self.ItemLevel;
    --if self.numGems == 0 and not self.isDomiationSocket then return; end;
    Narci_EquipmentOption:SetGemListFromSlotButton(self:GetParent());
    FadeFrame(Narci_GearEnhancement_Tooltip, 0.15, 0);
end

function NarciGemSlotMixin:OnClick()
    local frame = Narci_EquipmentOption;

    if frame:IsShown() then
        frame:CloseUI();
    else
        self:LoadGemList();
    end
    Narci:HideButtonTooltip();
end

function NarciGemSlotMixin:FadeIn()
    self:StopAnimating();
    self.animIn:Play();
    self:Show();
end

function NarciGemSlotMixin:FadeOut()
    self:StopAnimating();
    if self:IsVisible() then
        self.animOut:Play();
    else
        self:Hide();
    end
end

function NarciGemSlotMixin:ShowSlot()
    self:StopAnimating();
    self:Show();
    self:SetAlpha(1);
end

function NarciGemSlotMixin:HideSlot()
    self:StopAnimating();
    self:Hide();
    self:SetAlpha(0);
end