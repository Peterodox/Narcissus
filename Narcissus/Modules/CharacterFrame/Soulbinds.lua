local _, addon = ...

local strmatch = string.match;
local gmatch = string.gmatch;
local After = C_Timer.After;
local unpack = unpack;

local FadeFrame = NarciFadeUI.Fade;
local outQuart = addon.EasingFunctions.outQuart;
local MAX_ROW = NarciConstants.Soulbinds.MaxRow or 8;   --12
local FILE_PATH = "Interface\\AddOns\\Narcissus\\Art\\Modules\\CharacterFrame\\Soulbinds\\";
local CONDUIT_OFFSET = 60;
local CONDUIT_MAX_RANK = 14;

--[[
local QUALITY_COLORS = {
    [0] = {0.5, 0.5, 0.5},
    [1] = {0.8, 0.8, 0.8},
    [2] = {0.57, 0.79, 0.40},
    [3] = {0.17, 0.52, 0.87},
    [4] = {0.64, 0.21, 0.93},
    [5] = {0.5, 0.5, 0.5},
};
--]]


local QUALITY_COLORS = NarciAPI.GetItemQualityColorTable();
QUALITY_COLORS[1] = {0.8, 0.8, 0.8};

local C_Item = C_Item;
local C_Soulbinds = C_Soulbinds;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local GetSpellTexture = addon.TransitionAPI.GetSpellTexture;

local MainFrame, NodesContainer, CollectionFrame, ConduitTooltip;

local function GetConduitItemQualityByRank(rank)
    if rank == 0 then
        return 1
    elseif rank == 1 then
        return 2
    elseif rank <= 3 then
        return 3
    else
        return 4
    end
end

local function SetTextColorByQuality(text, quality, darker)
    local r, g, b = unpack(QUALITY_COLORS[quality]);

    if not r then
        r, g, b = 0.8, 0.8, 0.8;
    end

    if darker then
        text:SetTextColor(r, g, b);
    else
        text:SetTextColor(r*0.66, g*0.66, b*0.66);
    end
end

local function SetConduitItemQualityColorByItemLevel(widget, itemLevel, isCurrentSpec)
    local i;
    if itemLevel < 158 then
        i = 0;
    elseif itemLevel <= 171 then
        i = 1;
    else
        i = 2;
    end
    widget.Border:SetTexCoord(0.25 * i, 0.25 * (i + 1), 0, 1);
    if isCurrentSpec then
        widget.Border:SetVertexColor(1, 1, 1);
        widget.Icon:SetVertexColor(1, 1, 1);
        SetTextColorByQuality(widget.Name, i+2);
    else
        widget.Border:SetVertexColor(0.66, 0.66, 0.66);
        widget.Icon:SetVertexColor(0.66, 0.66, 0.66);
        SetTextColorByQuality(widget.Name, i+2, true);
    end
end


-----------------------------------------------------------------------------------
local QueueFrame = NarciAPI.CreateProcessor();

local ReferenceTooltip = CreateFrame("GameTooltip", "NarciSoulbindsConduitReferenceTooltip", UIParent, "GameTooltipTemplate");
if ReferenceTooltip:HasScript("OnTooltipAddMoney") then --dragonflight
    ReferenceTooltip:SetScript("OnTooltipAddMoney", nil);
end
if ReferenceTooltip:HasScript("OnTooltipCleared") then
    ReferenceTooltip:SetScript("OnTooltipCleared", nil);
end

local DataProvider = {};
DataProvider.conduitItemIDs = {};
DataProvider.conduitNames = {};

function DataProvider:GetConduitItemLevel(rank)
    if not rank or rank == 0 then
        return 0;
    else
        return 135 + rank * 13;
    end
end

function DataProvider:GetActiveCovenantID()
    if not self.activeCovenantID then
        self.activeCovenantID = C_Covenants.GetActiveCovenantID();
    end
    return self.activeCovenantID
end

function DataProvider:UpdateCovenantData()
    self.activeCovenantID = C_Covenants.GetActiveCovenantID();
    wipe(self.conduitItemIDs);
    for conduitType = 0, 2 do
        local data = C_Soulbinds.GetConduitCollection(conduitType);
        if data then
            local itemID, conduitID;
            for i = 1, #data do
                itemID = data[i].conduitItemID;
                conduitID = data[i].conduitID;
                if itemID then
                    self.conduitItemIDs[itemID] = conduitID;
                end
            end
        end
    end
end

function DataProvider:GetConduitName(conduitID, conduitItemID)
    if not conduitID then return "" end;

    if self.conduitNames[conduitID] then
        return self.conduitNames[conduitID]
    else
        if not conduitItemID then
            local collectionData = C_Soulbinds.GetConduitCollectionData(conduitID);
            if collectionData then
                conduitItemID = collectionData.conduitItemID;
            end
        end
        if conduitItemID then
            local name = C_Item.GetItemNameByID(conduitItemID);
            if name and name ~= "" then
                self.conduitNames[conduitID] = name;
                return name
            end
        end
        return ""
    end
end

--/dump strmatch("|cFFFFFFFF10% sec|r. in to |cFFFFFFFF20% sec|r.", "|c%w%w%w%w%w%w%w%w([^|]+)")
--/dump string.gsub("|cFFFFFFFF10% sec|r. in to |cFFFFFFFF20% sec|r.", "|c%w%w%w%w%w%w%w%w([^|]+)", print)

function DataProvider:CacheConduitTooltip(conduitID, rank)
    ReferenceTooltip:SetOwner(UIParent, "ANCHOR_NONE");
    ReferenceTooltip:SetConduit(conduitID, rank);
end

function DataProvider:GetConduitDescription(conduitID, rank, numberOnly)
    ReferenceTooltip:SetOwner(UIParent, "ANCHOR_NONE");
    ReferenceTooltip:SetConduit(conduitID, rank);
    if not self.referenceLine then
        self.referenceLine = _G["NarciSoulbindsConduitReferenceTooltip".. "TextLeft5"];
    end
    if self.referenceLine then
        local text = self.referenceLine:GetText();
        if numberOnly and text then
            local str = gmatch(text, "|c%w%w%w%w%w%w%w%w([^|]+)");
            local effect1, effect2 = str(), str();
            return effect1, effect2;
        else
            return text;
        end
    end
end

function DataProvider:GetConduitIDFromItemID(itemID)
    if itemID then
        return self.conduitItemIDs[tonumber(itemID)];
    end
end

function DataProvider:GetKnownConduitItemLevel(itemID)
    local conduitID = self:GetConduitIDFromItemID(itemID);
    if conduitID then
        local data = C_Soulbinds.GetConduitCollectionData(conduitID);
        if data then
            local rank = data.conduitRank;
            local itemLevel = DataProvider:GetConduitItemLevel(rank);
            local description = self:GetConduitDescription(conduitID, rank);
            return true, itemLevel, description;
        else
            return true
        end
    end
end

function DataProvider:GetDefaultSoulbindID(covenantID)
    --Blizzard_SoulbindsUtil.lua
    local SOULBINDS_COVENANT_KYRIAN = 1;
    local SOULBINDS_COVENANT_VENTHYR = 2;
    local SOULBINDS_COVENANT_NIGHT_FAE = 3;
    local SOULBINDS_COVENANT_NECROLORD = 4;
    local soulbindDefaultIDs = {
        [SOULBINDS_COVENANT_KYRIAN] = 7,
        [SOULBINDS_COVENANT_VENTHYR] = 8,
        [SOULBINDS_COVENANT_NIGHT_FAE] = 1,
        [SOULBINDS_COVENANT_NECROLORD] = 4,
    };
    return soulbindDefaultIDs[covenantID]
end

function DataProvider:UpdateSpec()
    self.specSetIDs = {};
    local specIndex = GetSpecialization() or 1;
	self.currentSpecID = GetSpecializationInfo(specIndex);
end

function DataProvider:IsCurrentSpec(specSetID)
    if specSetID then
        if self.specSetIDs[specSetID] == nil then
            self.specSetIDs[specSetID] = C_SpecializationInfo.MatchesCurrentSpecSet(specSetID);
        end
        return self.specSetIDs[specSetID];
    else
        return false;
    end
end

-----------------------------------------------------------------------------------

local ConduitNodeUtil = {};
ConduitNodeUtil.activeNodeFrames = {};
ConduitNodeUtil.nodePool = {};
ConduitNodeUtil.activeNodeIndexes = {};

function ConduitNodeUtil:ReleaseActiveNodes()
    QueueFrame:Stop();
    wipe(self.activeNodeIndexes);
    for row, frame in pairs(self.activeNodeFrames) do
        frame:Hide();
    end
end

function ConduitNodeUtil:AcquireNodeFrame(row)
    local frame = self.activeNodeFrames[row];
    if not frame then
        frame = CreateFrame("Frame", nil, MainFrame.AcitveNodesList, "NarciActiveConduitFrameTemplate");
        self.activeNodeFrames[row] = frame;
    end
    frame:ClearAllPoints();
    frame:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", 0, -12 -24 * row);
    frame:Show();
    return frame;
end

function ConduitNodeUtil:SetUpActiveNodeFrame(conduitID, rank, spellID, conduitType, row)
    local frame = self:AcquireNodeFrame(row);
    frame:SetUp(conduitID, rank, spellID, conduitType, row);
end

function ConduitNodeUtil:SetUpEmptyNodeFrame(row, unlockLevel)
    local frame = self:AcquireNodeFrame(row);
    frame:SetFailureReason(row, unlockLevel);
end


function ConduitNodeUtil:BuildNodes(fullNodesData, isTreeActive)
    self:ReleaseActiveNodes();
    local IS_ROW_PROCESSED = {};
    local numNodes;
    if fullNodesData then
        numNodes = #fullNodesData;
        local node;
        local nodeData;
        for i = 1, numNodes do
            node = self.nodePool[i];
            nodeData = fullNodesData[i];
            local row = nodeData.row;
            if row + 1 <= MAX_ROW then
                if not node then
                    node = CreateFrame("Button", nil, NodesContainer, "NarciConduitNodeButtonTemplate");
                    self.nodePool[i] = node;
                end
                if node:SetUp(nodeData, isTreeActive) then
                    tinsert(self.activeNodeIndexes, i);
                end
                node:Show();
                if nodeData.state == 0 then   --Unavailable
                    if not IS_ROW_PROCESSED[row] then
                        IS_ROW_PROCESSED[row] = true;
                        local unlockLevel = nodeData.failureRenownRequirement;
                        if unlockLevel then
                            self:SetUpEmptyNodeFrame(row, unlockLevel);
                        end
                    end
                elseif nodeData.state == 3 then         
    
                end
            end
        end
    else
        numNodes = 1;
    end

    for i = numNodes + 1, #self.nodePool do
        self.nodePool[i]:Hide();
    end
end

function ConduitNodeUtil:PlayShine()
    for i = 1, #self.activeNodeIndexes do
        self.nodePool[ self.activeNodeIndexes[i] ]:Shine();
    end
end

function ConduitNodeUtil:HighlightConduitByType(conduitType)
    local node;
    for i = 1, #self.activeNodeIndexes do
        node = self.nodePool[ self.activeNodeIndexes[i] ];
        if node.conduitType == conduitType then
            node:Shine();
        end
    end
end

local ConduitCollectionUtil = {};
ConduitCollectionUtil.categoryButtons = {};
ConduitCollectionUtil.conduitButtons = {};

local function ConduitSortFunc(a, b)
    if a.conduitSpecSetID == b.conduitSpecSetID then
        if a.conduitRank ~= b.conduitRank then
            return a.conduitRank > b.conduitRank;
        end
        return DataProvider:GetConduitName(a.conduitID) < DataProvider:GetConduitName(b.conduitID)
    else
        if DataProvider:IsCurrentSpec(a.conduitSpecSetID) then
            if DataProvider:IsCurrentSpec(b.conduitSpecSetID) then
                return a.conduitSpecSetID > b.conduitSpecSetID
            else
                return true
            end
        else
            if DataProvider:IsCurrentSpec(b.conduitSpecSetID) then
                return false
            else
                return a.conduitSpecSetID > b.conduitSpecSetID
            end
        end
    end
end

function ConduitCollectionUtil:UpdateScrollRange()
    local frame = MainFrame.ConduitCollection;

    if self.numConduits == 0 then
        frame:SetScrollRange(0);
        return
    end
    
    local cb = self.categoryButtons;
    if not cb or #cb < 3 then
        return
    end
    local yTop = cb[1]:GetTop() or 0;
    local M1 = yTop - (cb[2]:GetTop() or 0);
    local M2 = yTop - (cb[3]:GetTop() or 0);

    frame.scrollBar.onValueChangedFunc = function(endValue, delta, scrollBar, isTop, isBottom)
        if endValue > M2 + 8 then
            cb[1].Button:ResetAnchor();
            cb[2].Button:ResetAnchor();
            cb[3].Button:AnchorToTop();
        elseif endValue > (M2 - 16) then
            cb[1].Button:ResetAnchor();
            cb[2].Button:AnchorToDrawer();
            cb[3].Button:ResetAnchor();
        elseif endValue > (M1 + 8) then
            cb[1].Button:ResetAnchor();
            cb[2].Button:AnchorToTop();
            cb[3].Button:ResetAnchor();
        elseif endValue > (M1 - 16) then
            cb[1].Button:AnchorToDrawer();
            cb[2].Button:ResetAnchor();
            cb[3].Button:ResetAnchor();
        elseif endValue > 8 then
            cb[1].Button:AnchorToTop();
            cb[2].Button:ResetAnchor();
            cb[3].Button:ResetAnchor();
        else
            cb[1].Button:ResetAnchor();
            cb[2].Button:ResetAnchor();
            cb[3].Button:ResetAnchor();
        end
    end

    local bottomButton;
    if cb[3].Drawer:IsShown() then
        bottomButton = self.bottomButton;
    else
        bottomButton = cb[3];
    end
    frame:SetScrollRange(yTop - bottomButton:GetBottom() - 192);
end

function ConduitCollectionUtil:BuildList()
    local frame = MainFrame.ConduitCollection;
    local buttons = self.conduitButtons;
    local parentButtons = self.categoryButtons;
    local button, parentButton;

    local numConduits = 0;
    local drawer;
    local buttonHeight = 32;
    local types = {2, 0, 1} --{1, 0, 2};

    local categoryFrameLevel = frame.ScrollChild:GetFrameLevel() + 4;
    for index = 1, 3 do
        local conduitType = types[index];
        local data = C_Soulbinds.GetConduitCollection(conduitType);
        if data then
            local numData = #data;
            if numData > 0 then
                table.sort(data, ConduitSortFunc);
                
                parentButton = parentButtons[index];
                if not parentButton then
                    parentButton = CreateFrame("Frame", nil, frame, "NarciConduitCollectionCategoryButtonTemplate");
                    parentButtons[index] = parentButton;
                end
                parentButton:ClearAllPoints();
                parentButton.Button:SetFrameLevel(categoryFrameLevel);
                if index == 1 then
                    parentButton:SetPoint("TOP", frame.ScrollChild, "TOP", -6, -6);
                else
                    parentButton:SetPoint("TOP", drawer, "BOTTOM", 0, 0);
                end
                parentButton.Button:SetConduitType(conduitType);
                parentButton.Button:SetDrawerHeight(numData * buttonHeight + 36);
                drawer = parentButton.Drawer;
                
                local d;
                for i = 1, numData do
                    numConduits = numConduits + 1;
                    d = data[i];
                    button = buttons[numConduits];
                    if button then
                        button:SetParent(drawer);
                    else
                        button = CreateFrame("Button", nil, drawer, "NarciConduitCollectionConduitButtonTemplate");
                        buttons[numConduits] = button;
                    end
                    button:ClearAllPoints();
                    button:SetPoint("TOP", drawer, "TOP", 0, -buttonHeight * (i - 1) -26);
                    button:SetConduitFromData(d);

                    --DataProvider:CacheConduitTooltip(d.conduitID, d.conduitRank);
                end
            end
        end
    end

    self.bottomButton = button;

    self:UpdateScrollRange();
end
-----------------------------------------------------------------------------------
NarciConduitNodeButtonMixin = {};
--/script for i = 1, 15 do if NODES[i].row == 6 then print(NODES[i].conduitType) end end

function NarciConduitNodeButtonMixin:OnLoad()
    self.ConduitBorder:SetTexture(FILE_PATH.."IconBorder", nil, nil, "LINEAR");

    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);
end

function NarciConduitNodeButtonMixin:SetUp(nodeData, isTreeActive)
    if nodeData then
        self.nodeID = nodeData.ID;
        local conduitType = nodeData.conduitType;   --Fixed Node: conduitType = nil
        self.conduitType = conduitType;
        
        local row, column = nodeData.row, nodeData.column;
        if not row and column then return end;

        self:ClearAllPoints();
        self:SetPoint("CENTER", MainFrame, "TOPLEFT", CONDUIT_OFFSET + 24*(column - 1), -24 -24 * row);

        local spellID = nodeData.spellID;
        local conduitID = nodeData.conduitID;
        local conduitRank = nodeData.conduitRank;
        self.conduitID = conduitID;
        self.conduitRank = conduitRank;
        self.isEnhanced = nodeData.socketEnhanced;

        if conduitID ~= 0 and (conduitRank and conduitRank ~= 0) then
            spellID = C_Soulbinds.GetConduitSpellID(conduitID, conduitRank);
            self.Icon:SetTexture(GetSpellTexture(spellID));
            if self.isEnhanced then
                self.ConduitBorder:SetTexCoord(0.75, 1, 0, 1);
            else
                self.ConduitBorder:SetTexCoord(0.25, 0.5, 0, 1);
            end
            self.Highlight:SetTexCoord(0.5, 1, 0, 1);
            self.Mask:SetTexture(FILE_PATH.."MaskOctagon");
        elseif spellID ~= 0 then
            self.Icon:SetTexture(nodeData.icon); --nodeData.icon
            self.Mask:SetTexture(FILE_PATH.."MaskCircle");
            self.ConduitBorder:SetTexCoord(0, 0.25, 0, 1);
            self.Highlight:SetTexCoord(0, 0.5, 0, 1);
        else
            self.Icon:SetTexture(nil);
            self.ConduitBorder:SetTexCoord(0.5, 0.75, 0, 1);
            self.Highlight:SetTexCoord(0, 0, 0, 0);
        end

        self.spellID = spellID;
        self.state = nodeData.state;
        
        --Glow Animation
        local Highlight = self.Highlight;
        Highlight.Glow:Stop();

        --If this node is active
        if self.state == 3 then
            self:SetParent(NodesContainer.ActiveNodesFrame);
            self:UpdateVisual(true, isTreeActive);
            Highlight.Glow.Delay:SetDuration(0.06 * row);

            ConduitNodeUtil:SetUpActiveNodeFrame(conduitID, conduitRank, spellID, conduitType, row);

            return true;
        else
            self:SetParent(NodesContainer.InactiveNodesFrame);
            self:UpdateVisual(false, isTreeActive);
            return false;
        end
    end
end

function NarciConduitNodeButtonMixin:UpdateVisual(isNodeSelected, isTreeActive)
    if isNodeSelected then
        self.Icon:SetDesaturation(0);
        self.ConduitBorder:SetDesaturation(0);
    else
        self.Icon:SetDesaturation(1);
        self.ConduitBorder:SetDesaturation(1);
    end
    if isTreeActive then
        self.Icon:SetVertexColor(1, 1, 1);
        self.ConduitBorder:SetVertexColor(1, 1, 1);
    else
        self.Icon:SetVertexColor(0.66, 0.66, 0.66);
        self.ConduitBorder:SetVertexColor(0.66, 0.66, 0.66);

    end
end

function NarciConduitNodeButtonMixin:Shine()
    self.Highlight:Show();
    self.Highlight.Glow:Play();
end

function NarciConduitNodeButtonMixin:ShowTooltip()
    local tooltip = NarciGameTooltip;
    tooltip:Hide();
    if self.conduitID or self.spellID then
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, 0);
        if self.conduitType then
            if self.isEnhanced then
                tooltip:SetEnhancedConduit(self.conduitID, self.conduitRank or 1);
            else
                tooltip:SetConduit(self.conduitID, self.conduitRank or 1);
            end
        elseif self.spellID then
            tooltip:SetSpellByID(self.spellID);
        end
        tooltip:Show();
    end
end

function NarciConduitNodeButtonMixin:HideTooltip()
    local tooltip = NarciGameTooltip;
    tooltip:Hide();
end

function NarciConduitNodeButtonMixin:OnEnter()
    self:ShowTooltip();
end

function NarciConduitNodeButtonMixin:OnLeave()
    self:HideTooltip();
end

function NarciConduitNodeButtonMixin:OnClick()
    C_Soulbinds.SelectNode(self.nodeID);
end


NarciSoulbindsConduitFrameMixin = {};

function NarciSoulbindsConduitFrameMixin:SetNameAndIcon()
    local name, _, icon = GetSpellInfo(self.spellID);
    local hasName;
    if name and name ~= "" then
        self.Name:SetText(name);
        hasName = true;
    else
        QueueFrame:Add(self, self.SetNameAndIcon);
    end
    return hasName;
end


function NarciSoulbindsConduitFrameMixin:SetUp(conduitID, rank, spellID, conduitType)
    local quality = GetConduitItemQualityByRank(rank);  --C_Soulbinds.GetConduitQuality(traitID, rank)
    rank = DataProvider:GetConduitItemLevel(rank);
    if not conduitType then
        conduitType = 3;
    end
    self.ConduitTypeIcon:SetTexCoord(conduitType*0.25, conduitType*0.25 + 0.25, 0, 1); 
    local hasName;
    if not spellID or spellID == 0 then
        self.Name:SetText(EMPTY);
        quality = 0;
        hasName = true;
    else
        self.spellID = spellID;
        self:SetNameAndIcon();
    end

    SetTextColorByQuality(self.Name, quality);
    
    if not rank or rank == 0 then
        rank = "";
    end
    self.ItemLevel:SetText(rank);

    return hasName
end

function NarciSoulbindsConduitFrameMixin:SetFailureReason(row, requiredRenownLevel)
    self.ConduitTypeIcon:SetTexCoord(0.75, 1, 0, 1);
    self.ItemLevel:SetText("");
    if row and requiredRenownLevel then
        self.Name:SetText( string.format(COVENANT_SANCTUM_LEVEL, requiredRenownLevel) );  --COVENANT_SANCTUM_RENOWN_REWARD_DESC
        self.Name:SetTextColor(0.5, 0.2, 0.2);
    end
end

function NarciSoulbindsConduitFrameMixin:OnEnter()

end

function NarciSoulbindsConduitFrameMixin:OnLeave()

end

function NarciSoulbindsConduitFrameMixin:OnLoad()

end

------------------------------------------------------------------
NarciSoulbindsCharacterButtonMixin = {};
--Selcet a Soulbind
function NarciSoulbindsCharacterButtonMixin:SetSelected(state)
    self:UnlockHighlight();
    if state then
        self.Texture:SetTexCoord(0.5, 1, 0, 0.5);
        self.Highlight:SetTexCoord(0.5, 1, 0.5, 1);
        self.isSelected = true;
    else
        self.Texture:SetTexCoord(0, 0.5, 0, 0.5);
        self.Highlight:SetTexCoord(0, 0.5, 0.5, 1);
        self.isSelected = nil;
    end
end

function NarciSoulbindsCharacterButtonMixin:OnClick()
    if self.soulbindID and self.soulbindID ~= MainFrame.soulbindID then
        MainFrame:SelectTree(self.soulbindID);
        self:LockHighlight();
    end
end

function NarciSoulbindsCharacterButtonMixin:OnEnter(motion, isGamepad)
    local tooltip = NarciGameTooltip;
    tooltip:Hide();
    if self.soulbindName then
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("LEFT", self, "RIGHT", 8, 0);
        tooltip:SetText(self.soulbindName, 1, 1, 1);
        if isGamepad then
            tooltip:FadeIn();
            MainFrame:DisplayInactiveNodes(true);
        else
            tooltip:Show();
        end
        MainFrame:AutoHideTooltip(isGamepad);
    end
end

function NarciSoulbindsCharacterButtonMixin:OnLeave()
    NarciGameTooltip:Hide();
end

function NarciSoulbindsCharacterButtonMixin:OnMouseDown()
    --self.Texture:SetSize(30, 30);
    --self.Highlight:SetSize(30, 30);
    self.Texture:SetPoint("CENTER", 1, 0);
    self.Highlight:SetPoint("CENTER", 1, 0);
end

function NarciSoulbindsCharacterButtonMixin:OnMouseUp()
    --self.Texture:SetSize(32, 32);
    --self.Highlight:SetSize(32, 32);
    self.Texture:SetPoint("CENTER", 0, 0);
    self.Highlight:SetPoint("CENTER", 0, 0);
end

----------------------------------------------------------------------------
NarciConduitFlatButtonMixin = CreateFromMixins(NarciShewedRectButtonMixin);

function NarciConduitFlatButtonMixin:OnLoad()
    self:SetHighlight(false);
end

function NarciConduitFlatButtonMixin:OnEnter()
    self:SetHighlight(true);
    
    local tooltip = NarciGameTooltip;
    tooltip:Hide();
    if self.conduitID or (self.spellID and self.spellID ~= 0) then
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2);
        if self.conduitID then
            tooltip:SetConduit(self.conduitID, self.conduitRank or 1)
        elseif self.spellID then
            tooltip:SetSpellByID(self.spellID);
        end
        tooltip:Show();
    else
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2);
        tooltip:SetText(EMPTY, 1, 0.82, 0);
        tooltip:Show();
    end

    Narci_NavBar:PauseTimer(true);
end

function NarciConduitFlatButtonMixin:OnLeave()
    self:SetHighlight(false);
    local tooltip = NarciGameTooltip;
    tooltip:Hide();

    Narci_NavBar:PauseTimer(false);
end

function NarciConduitFlatButtonMixin:SetConduit(nodeData)
    if not (nodeData and nodeData.conduitRank) then
        self:SetEmptyConduit();
        return
    end

    local rank = nodeData.conduitRank;
    local spellID;
    if rank == 0 then
        spellID = nodeData.spellID;
        self.conduitID = nil;
        self.conduitRank = nil;
    else
        local conduitID = nodeData.conduitID;
        spellID = C_Soulbinds.GetConduitSpellID(conduitID, rank);
        self.conduitID = conduitID;
        self.conduitRank = rank;
    end
    self.spellID = spellID;

    if not spellID or spellID == 0 then
        self:SetEmptyConduit();
        return
    else
        self:Show();
    end

    local conduitType = nodeData.conduitType;
    conduitType = conduitType or 3;
    self.ConduitTypeIcon:Show();
    self.ConduitTypeIcon:SetTexCoord(conduitType*0.25, conduitType*0.25 + 0.25, 0, 1);
    self.UnlockLevel:Hide();

    self:SetNameAndIcon();
end

function NarciConduitFlatButtonMixin:SetNameAndIcon()
    local name, _, icon = GetSpellInfo(self.spellID);
    local hasName;
    if name and name ~= "" then
        --self.Icon:SetTexture(icon);
        self:SetIcon(icon);
        hasName = true;
    else
        QueueFrame:Add(self, self.SetNameAndIcon);
    end
    return hasName;
end

function NarciConduitFlatButtonMixin:SetUnlockLevel(unlockLevel)
    self:SetColorTexture(0.1, 0.1, 0.1);
    self.ConduitTypeIcon:Hide();
    self.UnlockLevel:SetText(unlockLevel);
    self.UnlockLevel:Show();
    self:Show();
end

function NarciConduitFlatButtonMixin:SetEmptyConduit()
    self:ShowAlert();
    self.ConduitTypeIcon:Hide();
    self.UnlockLevel:Hide();
    self:Show();
end

local function CreateTabs(frame)
    local d = 0.08;
    frame.Background:SetAlpha(0.9);
    frame.Background:SetVertexColor(d, d, d);
end


NarciSoulbindsMixin = {};

local dynamicEvents = {"SOULBIND_ACTIVATED", "SOULBIND_NODE_UPDATED", "SOULBIND_PATH_CHANGED", "SOULBIND_NODE_LEARNED",
    "ACTIVE_TALENT_GROUP_CHANGED",
    };

function NarciSoulbindsMixin:OnLoad()
    MainFrame = self;
    local numRow = MAX_ROW;
    local frameHeight = (numRow + 1) * 24;
    self:SetHeight(frameHeight);
    self.AcitveNodesList:SetHeight(frameHeight);

    NodesContainer = self.ConduitNodesFrame;
    self.ConduitNodesFrame:SetHeight(frameHeight);
    self.ConduitNodesFrame:SetScript("OnEnter", function(frame)
        self:DisplayInactiveNodes(true);
    end);
    self.ConduitNodesFrame:SetScript("OnLeave", function(frame)
        if not frame:IsMouseOver() then
            self:DisplayInactiveNodes(false);
        end
    end);
    self.buttons = {};
    -------------------------------------------
    --Collection ScrollFrame
    CollectionFrame = self.ConduitCollection;

    local deltaRatio = 1;
    local speedRatio = 0.2;
    local positionFunc;
    local buttonHeight = 60;
    local range = 120;

    NarciAPI_ApplySmoothScrollToScrollFrame(CollectionFrame, deltaRatio, speedRatio, positionFunc, buttonHeight, range);


    ConduitTooltip = self.ConduitTooltip;

    -------------------------------------------
    self:RegisterForDrag("LeftButton");

    --Static Events
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("COVENANT_CHOSEN");

    for i = 1, #dynamicEvents do
        self:RegisterEvent(dynamicEvents[i]);
    end

    CreateTabs(self.TabHolder);
    CreateTabs = nil;

    --Update Subtrate Height

    if MAX_ROW and MAX_ROW > 8 then
        self.Stone:SetTexture(FILE_PATH.."StoneLong");
        self.StoneMask:SetTexture(FILE_PATH.."StoneMaskLong");
        self.Stone:SetSize(136, 272 * 2);
    end

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciSoulbindsMixin:OnShow()
    if self.soulbindID ~= C_Soulbinds.GetActiveSoulbindID() then
        self.needsUpdate = true;
    end
    if self.needsUpdate then
        self:SelectTree();
    end
end

function NarciSoulbindsMixin:OnHide()
    --[[
    for i = 1, #dynamicEvents do
        self:UnregisterEvent(dynamicEvents[i]);
    end
    --]]
    self:AutoHideTooltip(false);
end

function NarciSoulbindsMixin:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        DataProvider:UpdateSpec();
        self:UpdateCovenantData();
        self:SelectTree();
        After(1, function()
            self:RequestUpdate();
            Narci_NavBar:RequestUpdate("all");
        end)
    elseif event == "COVENANT_CHOSEN" then
        local newCovenantID = ...;
        self:UpdateCovenantData(newCovenantID);
        Narci_NavBar:RequestUpdate("soulbinds");
    elseif event == "SOULBIND_ACTIVATED" then
        self:RequestUpdate();
        self:PlayShine();
        Narci_NavBar:RequestUpdate("soulbinds");
    elseif event == "SOULBIND_PATH_CHANGED" or event == "SOULBIND_NODE_UPDATED" then
        self:RequestUpdate();
        Narci_NavBar:RequestUpdate("soulbinds");
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        DataProvider:UpdateSpec();
    end
    --print(event);
end

function NarciSoulbindsMixin:GetActiveConduit()
    --DEBUG
    local soulbindID = C_Soulbinds.GetActiveSoulbindID();
    local data = C_Soulbinds.GetSoulbindData(soulbindID);
    if not data or not data.tree then return end;
    local nodes = data.tree.nodes;
    local conduitType, conduitState;

    for i = 1, #nodes do
        conduitState = nodes[i].state;
        if conduitState and conduitState == 3 then
            conduitType = nodes[i].conduitType;
            if conduitType then
                print(C_Soulbinds.GetConduitSpellID(nodes[i].conduitID, nodes[i].conduitRank))
            else
                print(nodes[i].spellID);
            end
        end
    end
end

function NarciSoulbindsMixin:UpdateCovenantData(newCovenantID)
    local covenantID = newCovenantID or C_Covenants.GetActiveCovenantID();
    if not covenantID or covenantID == 0 then
        --Covenant Unselected
        return
    end
    
    local data = C_Covenants.GetCovenantData(covenantID);
    self.defaultSoulbindID = DataProvider:GetDefaultSoulbindID(covenantID);
    if data then
        self.covenantData = data;
        self:CreateChoiceButtons(data.soulbindIDs);
    end

    DataProvider.activeCovenantID = covenantID;
    DataProvider:UpdateCovenantData();
end

function NarciSoulbindsMixin:CreateChoiceButtons(soulbindIDs)
    if not self.buttons then
        self.buttons = {};
    end
    local numChoices = #soulbindIDs;
    local gap = 4;
    local button;
    for i = 1, numChoices do
        button = self.buttons[i];
        if not button then
            button = CreateFrame("Button", nil, self, "NarciSoulbindsCharacterButton");
            button:SetFrameLevel(self:GetFrameLevel() + 3);
            button:SetPoint("CENTER", self, "LEFT", 0, (16 + gap)*(numChoices - 1)/2 - (16 + gap)*(i - 1));
            self.buttons[i] = button;
        end
        button.soulbindID = soulbindIDs[i];

        local soulbindData = C_Soulbinds.GetSoulbindData(soulbindIDs[i]);
        if soulbindData and soulbindData.name then
            button.soulbindName = soulbindData.name;
        end
        soulbindData = nil;

        if i == 1 then
            button:SetSelected(true);
        else
            button:SetSelected(false);
        end
    end
end

function NarciSoulbindsMixin:GetPipe(index, row, col, effectiveCol)
    if not self.pipePool then
        self.pipePool = {};
    end
    local pipe = self.pipePool[index];
    if not pipe then
        pipe = self:CreateTexture(nil, "OVERLAY", "NarciSoulbindsPipeTextureTemplate");
        self.pipePool[index] = pipe;
    end
    pipe:ClearAllPoints();
    pipe:Show();
    local offsetY = 0;
    if col == 2 and effectiveCol and effectiveCol ~= 2 then
        --Flip Texture
        offsetY = -24;
        col = effectiveCol;
    end
    pipe:SetPoint("TOP", self, "TOPLEFT", 60 + 24*(col - 2), 24*(1 - row) + offsetY);
    return pipe
end

function NarciSoulbindsMixin:UpdatePipeline(structure)
    if self.pipePool then
        for _, pipe in pairs(self.pipePool) do
            pipe:Hide();
        end
    end

    local numTex = 0;
    local numRow = #structure;
    local numCol = 3;
    local numNodesPerRow = {};
    for row = 1, numRow do
        local numNodes = 0;
        for col = 1, numCol do
            if structure[row][col] ~= 0 then
                numNodes = numNodes + 1;
            end
        end
        numNodesPerRow[row] = numNodes;
    end

    for row = 1, numRow - 1 do
        local numNodes = numNodesPerRow[row];
        for col = 1, numCol do
            local nodeState = structure[row][col];
            if nodeState ~= 0 then
                local texOffsetY, nextNodeState;
                local nextRowData = structure[row + 1];
                if false and numNodes == 3 then
                    numTex = numTex + 1;
                    nextNodeState = nextRowData[col];
                    if nodeState == 2 and nextNodeState == 2 then
                        texOffsetY = 0.5;
                    else
                        texOffsetY = 0;
                    end
                    local pipe = self:GetPipe(numTex, row, col, col);
                    pipe:SetTexCoord(0.265625, 0.515625, texOffsetY, texOffsetY + 0.5);
                else
                    if nextRowData[col] and nextRowData[col] ~= 0 then
                        numTex = numTex + 1;
                        nextNodeState = nextRowData[col];
                        if nodeState == 2 and nextNodeState == 2 then
                            texOffsetY = 0.5;
                        else
                            texOffsetY = 0;
                        end
                        local pipe = self:GetPipe(numTex, row, col, col);
                        pipe:SetTexCoord(0.265625, 0.515625, texOffsetY, texOffsetY + 0.5);
                    end
                    if numNodes == 1 or numNodesPerRow[row + 1] ~= 3 then
                        if nextRowData[col - 1] and nextRowData[col - 1] ~= 0 then
                            numTex = numTex + 1;
                            nextNodeState = nextRowData[col - 1];
                            if nodeState == 2 and nextNodeState == 2 then
                                texOffsetY = 0.5;
                            else
                                texOffsetY = 0;
                            end
                            local pipe = self:GetPipe(numTex, row, col - 1, 3);
                            if col == 2 then
                                pipe:SetTexCoord(0, 0.25, texOffsetY, texOffsetY + 0.5);
                            else
                                pipe:SetTexCoord(0.53125, 0.78125, texOffsetY + 0.5, texOffsetY);
                            end
                        end
                        if nextRowData[col + 1] and nextRowData[col + 1] ~= 0 then
                            numTex = numTex + 1;
                            nextNodeState = nextRowData[col + 1];
                            if nodeState == 2 and nextNodeState == 2 then
                                texOffsetY = 0.5;
                            else
                                texOffsetY = 0;
                            end
                            local pipe = self:GetPipe(numTex, row, col + 1, 1);
                            if col == 2 then
                                pipe:SetTexCoord(0.53125, 0.78125, texOffsetY, texOffsetY + 0.5);
                            else
                                pipe:SetTexCoord(0, 0.25, texOffsetY + 0.5, texOffsetY);
                            end
                        end
                    end
                end
            end
        end
    end

    --[[
    for i = 1, #structure do
        print(unpack(structure[i]))
    end
    --]]
end

function NarciSoulbindsMixin:PlayShine()
    if self:IsVisible() then
        ConduitNodeUtil:PlayShine();
    end
end

local function GetNullStructure()
    local structure = {};
    local numRow, numCol = MAX_ROW, 3;
    for row = 1, numRow do
        structure[row] = {};
        for col = 1, numCol do
            structure[row][col] = 0;
        end
    end
    return structure
end

local atlasInfo = {
    [1] = { --"Kyrian"
        texture = "Interface\\Soulbinds\\SoulbindsShotsKyrian",
        [13] = {603, 558, 0.00048828125, 0.294921875, 0.0009765625, 0.5458984375},  --Kleia
		[18] = {578, 558, 0.2958984375, 0.578125, 0.0009765625, 0.5458984375},  --Mikanikos
		[7] = {578, 558, 0.5791015625, 0.861328125, 0.0009765625, 0.5458984375}, --Pelagos
    },

    [2] = { --"Venthyr"
        texture = "Interface\\Soulbinds\\SoulbindsShotsVenthyr",
		[3] = {603, 558, 0.6064453125, 0.90087890625, 0.0009765625, 0.5458984375},   --Draven
		[8] = {629, 558, 0.00048828125, 0.3076171875, 0.0009765625, 0.5458984375},   --Nadjia
		[9] = {608, 558, 0.30859375, 0.60546875, 0.0009765625, 0.5458984375},   --Theotar
    },

    [3]={   --Night Fae
        texture = "Interface\\Soulbinds\\SoulbindsShotsFey",
        [1]={578, 558, 0.591309, 0.873535, 0.000976562, 0.545898},    --Niya
        [2]={603, 558, 0.000488281, 0.294922, 0.000976562, 0.545898},  --Dreamweaver
        [6]={603, 558, 0.295898, 0.590332, 0.000976562, 0.545898},     --Korayn
    },

    [4]={   --Necrolord
        texture = "Interface\\Soulbinds\\SoulbindsShotsNecrolords",
		[5] = {629, 558, 0.00048828125, 0.3076171875, 0.0009765625, 0.5458984375}, --Emeni
		[4] = {572, 558, 0.5888671875, 0.8681640625, 0.0009765625, 0.5458984375},   --Marileth
		[10] = {572, 558, 0.30859375, 0.587890625, 0.0009765625, 0.5458984375},   --Heirmir
    },
}

function NarciSoulbindsMixin:SetPortrait(index, desaturated)
    local covenantID = DataProvider:GetActiveCovenantID();
    if not atlasInfo[covenantID] then return end;
    self.Portrait:SetDesaturated(desaturated);
    if index == atlasInfo.lastIndex then
        return;
    else
        atlasInfo.lastIndex = index;
    end

    local data = atlasInfo[covenantID][index];
    if data then
        local width, height, left, right, top, bottom = unpack(data);
        local ratio = 0.8;
        local effectiveWidth = (self:GetHeight())*width/height * ratio;
        self.Portrait:SetWidth(effectiveWidth);
        self.Portrait:SetTexture(atlasInfo[covenantID].texture);
        self.Portrait:SetTexCoord(left, left + (right - left)*ratio, top, bottom);
        self.Portrait.ActivateAnim:Play();
    end
end


function NarciSoulbindsMixin:SelectTree(soulbindID)
    local data;
    local activeSoulbindID = C_Soulbinds.GetActiveSoulbindID();
    if not activeSoulbindID or activeSoulbindID == 0 then
        --Thread of Fate Alt
        Narci_NavBar:SetSkipCovenant(true);
        return
    end
    soulbindID = soulbindID or activeSoulbindID;
    if soulbindID == 0 then
        soulbindID = self.defaultSoulbindID;
    end
    data = C_Soulbinds.GetSoulbindData(soulbindID);

    if not data or not data.tree then
        return
    end

    local nodes = data.tree.nodes;
    if not nodes then return end;
    self.needsUpdate = nil;
    
    local node, conduitType, conduitState, spellID, conduitRank, traitID;
    local isTreeActive = soulbindID == activeSoulbindID;
    local structure = GetNullStructure();

    Narci_NavBar:SetSoulbindName(data.name, isTreeActive);

    for i = 1, #nodes do
        node = nodes[i];
        if structure[node.row + 1] then
            conduitState = node.state;
            if conduitState then
                if conduitState == 3 then   --Selected
                    structure[node.row + 1][node.column + 1] = 2;
                else
                    structure[node.row + 1][node.column + 1] = 1;
                end
            end
        end
    end

    --Node Links
    self:UpdatePipeline(structure);

    --Soulbinds Character Button
    if self.buttons then
        for i = 1, #self.buttons do
            self.buttons[i]:SetSelected(self.buttons[i].soulbindID == activeSoulbindID);
        end
    end

    if isTreeActive then
        self.Stone:SetVertexColor(1, 1, 1);
    else
        self.Stone:SetVertexColor(0.66, 0.66, 0.66);
    end
    self:SetPortrait(soulbindID, soulbindID ~= activeSoulbindID);

    self.ActivateButton:Update(not isTreeActive, soulbindID);
    self.soulbindID = soulbindID;

    ConduitNodeUtil:BuildNodes(nodes, isTreeActive);
end

function NarciSoulbindsMixin:RequestUpdate()
    if self:IsVisible() then
        self:SelectTree();
    else
        self.needsUpdate = true;
    end
end

function NarciSoulbindsMixin:SelectTab(tabIndex)
    if tabIndex == 2 then
        self.AcitveNodesList:Hide();
        self.ConduitCollection:Show();
        ConduitCollectionUtil:BuildList();
    else
        self.AcitveNodesList:Show();
        self.ConduitCollection:Hide();
    end
end

local function AutoHideTooltip_OnUpdate(self, elapsed)
    self.countdown = self.countdown + elapsed;
    if self.countdown > 1 then
        self:AutoHideTooltip(false);
        NarciGameTooltip:FadeOut();
    end
end

function NarciSoulbindsMixin:AutoHideTooltip(state)
    if state then
        self.countdown = 0;
        self:SetScript("OnUpdate", AutoHideTooltip_OnUpdate);
    else
        self.countdown = nil;
        self:SetScript("OnUpdate", nil);
    end
end

function NarciSoulbindsMixin:DisplayInactiveNodes(state)
    if state then
        FadeFrame(self.ConduitNodesFrame.InactiveNodesFrame, 0.15, 1);
    else
        FadeFrame(self.ConduitNodesFrame.InactiveNodesFrame, 0.5, 0);
    end
end

--------------------------------------------------------------------------------------------
NarciSoulbindsActivateButtonMixin = CreateFromMixins(NarciUIShimmerButtonMixin);

function NarciSoulbindsActivateButtonMixin:OnLoad()
    self:Preload();

    self:SetState(true);


    local animFly = NarciAPI_CreateAnimationFrame(0.35);
    animFly:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local offsetY = outQuart(frame.total, frame.fromY, frame.toY, frame.duration);
        if frame.total >= frame.duration then
            offsetY = frame.toY;
            frame:Hide();
        end
        self:SetPoint("CENTER", animFly.relativeTo, animFly.relativePoint, animFly.offsetX, offsetY);
    end);

    function self:PlayFlyAnimation(direction)
        if direction == animFly.direction then
            return
        else
            animFly.direction = direction;
        end

        animFly:Hide();
        local _, fromY, toY;
        _, animFly.relativeTo, animFly.relativePoint, animFly.offsetX, fromY = self:GetPoint();
        animFly.fromY = fromY;
        local baseY = 28;
        if direction > 0 then
            toY = -12;
        else
            toY = -36;
        end
        toY = toY + baseY;

        animFly.toY = toY;

        local duration = (toY - fromY)/24 * 0.35;
        if duration ~= 0 then
            if toY < fromY then
                duration = -duration;
            end
            animFly.duration = duration;

            animFly:Show();
        end
    end
end

function NarciSoulbindsActivateButtonMixin:OnEnter()
    local tooltip = NarciGameTooltip;
    tooltip:Hide();

    if self:IsEnabled() then
        self:HoldShimmer();
    elseif self.tooltipText then
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4);
        tooltip:SetText(self.tooltipText, 1, 0, 0);
        tooltip:Show();
    end
end

function NarciSoulbindsActivateButtonMixin:OnLeave()
    --self:StopShimmer();
    NarciGameTooltip:Hide();
    if self:IsEnabled() then
        self:PlayShimmer();
    end
end

function NarciSoulbindsActivateButtonMixin:SetState(isEnabled)
    if isEnabled then
        self.ButtonText:SetTextColor(0, 0, 0);
        self.ButtonText:SetShadowColor(1, 1, 1);
        self.Background:SetDesaturation(0);
        self.Background:SetVertexColor(1, 1, 1);
        self:Enable();
        self:PlayShimmer();
    else
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
        self.ButtonText:SetShadowColor(0, 0, 0);
        self.Background:SetDesaturation(1);
        self.Background:SetVertexColor(0.25, 0.25, 0.25);
        self:Disable();
        self:StopShimmer();
    end
end

function NarciSoulbindsActivateButtonMixin:Toggle(visible)
    if visible then
        FadeFrame(self, 0.15, 1);
        self:PlayFlyAnimation(1);
        self.ButtonText:Show();
        self.isVisible = visible;
    else
        FadeFrame(self, 0.15, 0);
        self:PlayFlyAnimation(-1);
        self.ButtonText:Hide();
        self:StopShimmer();
        self.isVisible = nil;
    end
end

function NarciSoulbindsActivateButtonMixin:Check()
    if not self.soulbindID then
        self:Toggle(false);
        return
    end

    local available, errorDescription = C_Soulbinds.CanActivateSoulbind(self.soulbindID);
    if available then
        self.tooltipText = nil;
    else
        self.tooltipText = errorDescription;
    end
    self:SetState(available);
end

function NarciSoulbindsActivateButtonMixin:Update(visible, soulbindID)
    self.soulbindID = soulbindID;
    self:Toggle(visible);
end

function NarciSoulbindsActivateButtonMixin:OnClick()
    local soulbindID = self.soulbindID;
    
    if soulbindID then
        local available, errorDescription = C_Soulbinds.CanActivateSoulbind(soulbindID);
        if available then
            C_Soulbinds.ActivateSoulbind(self.soulbindID);
            self:Toggle(false);
        else
            --print(errorDescription);
        end
    else
        
    end
end

function NarciSoulbindsActivateButtonMixin:OnShow()
    --UNIT_AREA_CHANGED     --new event in 9.0.2 function????
    self:Check();
    self:RegisterEvent("PLAYER_UPDATE_RESTING");
end

function NarciSoulbindsActivateButtonMixin:OnHide()
    self:UnregisterEvent("PLAYER_UPDATE_RESTING");
end

function NarciSoulbindsActivateButtonMixin:OnEvent(event, ...)
    self:Check();
end


----------------------------------------------
--Conduit Collection
local GetMouseFocus = addon.TransitionAPI.GetMouseFocus;
local delayExecute = NarciAPI_CreateAnimationFrame(0.65);
delayExecute:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
	if self.total >= self.duration then
		self:Hide();
        local widget = GetMouseFocus();
        if widget and widget == self.lastFocus then
            if widget.ShowBonusText then
                widget:ShowBonusText();
            end
        end
	end
end);

NarciConduitCollectionButtonMixin = {};

function NarciConduitCollectionButtonMixin:SetConduitFromData(conduitData)
    self.conduitID = conduitData.conduitID;
    self.conduitRank = conduitData.conduitRank;
    self.conduitItemID = conduitData.conduitItemID;
    self.ItemLevel:SetText(conduitData.conduitItemLevel);
    SetConduitItemQualityColorByItemLevel(self, conduitData.conduitItemLevel, DataProvider:IsCurrentSpec(conduitData.conduitSpecSetID));
    self:SetNameAndIcon();
end

function NarciConduitCollectionButtonMixin:SetNameAndIcon()
    if not self.conduitID then return end;

    local name = DataProvider:GetConduitName(self.conduitID, self.conduitItemID);
    local icon = C_Item.GetItemIconByID(self.conduitItemID);
    local hasName;
    if name and name ~= "" and icon then
        self.Name:SetText(name);
        self.Icon:SetTexture(icon);
        hasName = true;
    else
        QueueFrame:Add(self, self.SetNameAndIcon);
    end
    return hasName;
end

function NarciConduitCollectionButtonMixin:ShowTooltip()
    delayExecute:Hide();
    delayExecute.lastFocus = nil;

    if not (self.conduitID and self.conduitRank) then
        ConduitTooltip:Hide();
    end;

    ConduitTooltip:FadeInHighlight(self);
    delayExecute.lastFocus = self;
    delayExecute:Show();
end

function NarciConduitCollectionButtonMixin:ShowBonusText()
    local id = self.conduitID;
    local rank = self.conduitRank;

    local effect = DataProvider:GetConduitDescription(id, rank, false);

    if effect then
        local textLeft, textRight;
        for r = rank + 1, math.min(rank + 3, CONDUIT_MAX_RANK) do
            local effect1, effect2 = DataProvider:GetConduitDescription(id, r, true);
            local itemLevel = DataProvider:GetConduitItemLevel(r);
            if effect1 and itemLevel then
                if effect2 then
                    effect1 = effect1.."  "..effect2;
                end
            end
            if textLeft then
                textLeft = textLeft .."\n"..itemLevel;
            else
                textLeft = itemLevel;
            end
            if textRight then
                textRight = textRight .."\n"..effect1;
            else
                textRight = effect1;
            end
        end
        ConduitTooltip:SetButtonTooltip(self, effect, textLeft, textRight);
        return true;
    else
        QueueFrame:Add(self, self.ShowBonusText);
    end
    return false
end

function NarciConduitCollectionButtonMixin:OnEnter()
    CollectionFrame:HighlightButton(self);
    self:ShowTooltip();
    SetCursor("Interface/CURSOR/Item.blp");
end

function NarciConduitCollectionButtonMixin:OnLeave()
    CollectionFrame:HighlightButton();
    NarciGameTooltip:Hide();
    ConduitTooltip:Hide();
    delayExecute:Hide();
    ResetCursor();
end

--Conduit Category
NarciConduitCollectionCategoryButtonMixin = {};

function NarciConduitCollectionCategoryButtonMixin:ResetAnchor()
    if not self.isDefaultAnchor then
        self.isAnchorDrawer = nil;
        self.isDefaultAnchor = true;
        self.isAnchorTop = nil;
        self:SetPoint("TOP", self:GetParent(), "TOP", 0, 0);
    end
end

function NarciConduitCollectionCategoryButtonMixin:AnchorToTop()
    if not self.isAnchorTop then
        self.isAnchorDrawer = nil;
        self.isAnchorTop = true;
        self.isDefaultAnchor = nil;
        self:SetPoint("TOP", CollectionFrame, "TOP", -6, 2);
    end
end

function NarciConduitCollectionCategoryButtonMixin:AnchorToDrawer()
    if not self.isAnchorDrawer then
        self.isAnchorDrawer = true;
        self.isAnchorTop = nil;
        self.isDefaultAnchor = nil;
        self:SetPoint("TOP", self:GetParent().Drawer, "BOTTOM", 0, 24);
    end
end

function NarciConduitCollectionCategoryButtonMixin:SetConduitType(conduitType)
    if not conduitType then
        conduitType = 3;
    end
    self.conduitType = conduitType;

    if conduitType == 0 then
        self.ButtonText:SetText(CONDUIT_FINESSE);
    elseif conduitType == 1 then
        self.ButtonText:SetText(CONDUIT_POTENCY);
    elseif conduitType == 2 then
        self.ButtonText:SetText(CONDUIT_ENDURANCE);
    elseif conduitType == 3 then
        self.ButtonText:SetText("Unknown Type");
    end
    
    self.ConduitTypeIcon:SetTexCoord(conduitType*0.25, conduitType*0.25 + 0.25, 0, 1); 
end

function NarciConduitCollectionCategoryButtonMixin:SetDrawerHeight(height)
    height = math.max(height, 24);
    self.expandedHeight = height;
    self:SetExpanded(true);
end

function NarciConduitCollectionCategoryButtonMixin:SetExpanded(state)
    self.isExpanded = state;
    local Drawer = self:GetParent().Drawer
    if state then
        Drawer:Show();
        Drawer:SetHeight(self.expandedHeight or 24);
        self.ExpandMark:SetTexCoord(0, 0.5, 0, 1);
    else
        Drawer:Hide();
        Drawer:SetHeight(24);
        self.ExpandMark:SetTexCoord(0.5, 1, 0, 1);
    end
end

function NarciConduitCollectionCategoryButtonMixin:OnMouseDown()
    self.Background:SetPoint("CENTER", 1, -1);
end

function NarciConduitCollectionCategoryButtonMixin:OnMouseUp()
    self.Background:SetPoint("CENTER", 0, 0);
end

function NarciConduitCollectionCategoryButtonMixin:OnClick()
    self:SetExpanded(not self.isExpanded);
    ConduitCollectionUtil:UpdateScrollRange();
end

function NarciConduitCollectionCategoryButtonMixin:OnEnter()
    
end

function NarciConduitCollectionCategoryButtonMixin:OnLeave()

end

----------------------------------------------
--Conduit Tooltip
local function AddComparisionByHyperlink(frame, link)
    if not link then return end;
    
    local itemID = strmatch(link, "item:(%d+):");
    local isConduit, knownLevel, description = DataProvider:GetKnownConduitItemLevel(itemID);
    if isConduit then
        frame:AddLine(" ");
        if knownLevel then
            frame:AddDoubleLine("Known", knownLevel, 1, 1, 1, 1, 1, 1);
            if description then
                frame:AddLine(description, nil, nil, nil, true);
            end
        else
            frame:AddLine("Unlearned", nil, nil, nil, true);
        end
        frame:Show();
    end
end

local TooltipHooks = {};
TooltipHooks.hookedFrames = {
    --[tooltip name] = hasHooked,
};

function TooltipHooks:Hook(tooltip)
    local name = tooltip:GetName();
    if self.hookedFrames[name] == nil then
        self.hookedFrames[name] = true;

        --Conduit Item
        --[[
        tooltip:HookScript("OnTooltipSetItem", function(frame)
            local _, link = frame:GetItem();
            AddComparisionByHyperlink(frame, link);
        end);
        --]]

        --Conduit Collection
        hooksecurefunc(tooltip, "SetConduit", function(frame, conduitID, currentRank)
            --print("Current Rank: "..currentRank)
            if not self.hookedFrames[name] then return end;

            local hasHeader = false;
            for rank = currentRank + 1, math.min(currentRank + 3, CONDUIT_MAX_RANK) do
                local effect1, effect2 = DataProvider:GetConduitDescription(conduitID, rank, true);
                local itemLevel = DataProvider:GetConduitItemLevel(rank);

                if effect1 and itemLevel then
                    if not hasHeader then
                        hasHeader = true;
                        frame:AddDoubleLine("Effect", "Item Level", 0.5, 0.5, 0.5, 0.5, 0.5, 0.5);
                    end
                    if effect2 then
                        frame:AddDoubleLine(effect1.."  "..effect2, itemLevel, 1, 1, 1, nil, nil, nil);
                    else
                        frame:AddDoubleLine(effect1, itemLevel, 1, 1, 1, nil, nil, nil);
                    end
                end
            end
        end)
    else
        self.hookedFrames[name] = true;
    end
end

function TooltipHooks:Unhook(tooltip)
    local name = tooltip:GetName();
    if self.hookedFrames[name] then
        self.hookedFrames[name] = false;
    end
end

--[[
hooksecurefunc(GameTooltip, "SetBagItem", function(frame, bag, slot)
    local _, link = frame:GetItem();
    AddComparisionByHyperlink(frame, link);
end)
--]]

TooltipHooks:Hook(NarciGameTooltip);

do
    function addon.SettingFunctions.EnableConduitTooltip(state, db)
        if state == nil then
            state = db["ConduitTooltip"];
        end
        if state then
            TooltipHooks:Hook(GameTooltip);
        else
            TooltipHooks:Unhook(GameTooltip);
        end
    end
end

--[[
    column 0, 1, 2
    row 0, 1, ..., 7
    Enum.SoulbindNodeState:
        0 Unavailable
        1 Unselected
        2 Selectable
        3 Selected

    Enum.SoulbindConduitType:
        0 Finesse
        1 Potency
        2 Endurance
        3 Flex 
--]]