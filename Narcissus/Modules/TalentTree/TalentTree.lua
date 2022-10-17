local SHOW_NAME = false;
local HIDE_INACTIVE_NODE = false;

local _, addon = ...

local LoadingBarUtil = addon.TalentTreeLoadingBarUtil;
local ClassTalentTooltipUtil = addon.ClassTalentTooltipUtil;

local After = C_Timer.After;
local C_Traits = C_Traits;
local C_ClassTalents = C_ClassTalents;
local C_SpecializationInfo = C_SpecializationInfo;
local GetNodeInfo = C_Traits.GetNodeInfo;
local GetEntryInfo = C_Traits.GetEntryInfo;

local GetSpecializationRoleByID = GetSpecializationRoleByID;
local GetSpecializationInfoByID = GetSpecializationInfoByID;
local GetSpecializationInfo = GetSpecializationInfo;
local GetSpecialization = GetSpecialization;
local GetInspectSpecialization = GetInspectSpecialization;
local UnitClass = UnitClass;
local UnitSex = UnitSex;
--local INSPECT_TRAIT_CONFIG_ID = -1;

local sqrt = math.sqrt;
local atan2 = math.atan2;
local ipairs = ipairs;
local floor = math.floor;

local BUTTON_PIXEL_SIZE = 32;
local ICON_PIXEL_SIZE = 24;
local DISTANCE_UNIT = 300;  --600    --neighboring node distance 600
local PADDING = 1;
local PADDING_Y = 2;
local HEADER_SIZE;
local SECTOR_WIDTH = 11;    --the width of each tab (spec talent, class talent). unit is button wdith.

if not SHOW_NAME then
    PADDING_Y = 0;
end

local ABC;  --ACTIVE_BRANCH_COLOR
if BUTTON_PIXEL_SIZE >= 30 then
    ABC = 0.67;
else
    ABC = 0.4
end

local BUTTON_SIZE = 32;
local BUTTON_SIZE_HALF = BUTTON_SIZE * 0.5;
local BRANCH_WEIGHT = 1;
local DISTANCE_RATIO = 0.05;
local ICON_SIZE = 28;
local FONT_HEIGHT = 16;
local PIXEL = 1;

local MainFrame;
local Nodes = {};
local Branches = {};

local EntryInfoCache = {};
local NodeInfoCache = {};
local NodeIDxNode = {};

local LoadoutUtil = {};
local LayoutUtil = {};

function LayoutUtil:Reset()
    self.leftMinX = 69;
    self.leftMaxX = 0;
    self.leftMinY = 69;
    self.rightMinX = 69;
    self.rightMaxX = 1;
    self.rightMinY = 69;
end

function LayoutUtil:UpdateFrameSize()
    local pvpFrameWidth = (MainFrame.PvPTalentFrame:IsShown() and 3*BUTTON_SIZE) or 0;
    MainFrame:SetSize(BUTTON_SIZE * 2 * SECTOR_WIDTH + pvpFrameWidth, BUTTON_SIZE * (10 + 2*PADDING + PADDING_Y) + HEADER_SIZE);
end

function LayoutUtil:UpdateNodePosition()
    local tileSize = BUTTON_SIZE;
    local container = MainFrame;

    local leftMinY = self.leftMinY;
    local leftMinX = self.leftMinX;
    local leftMaxX = self.leftMaxX;
    local leftSpanX = leftMaxX - leftMinX + 1;

    local rightMinY = self.rightMinY;
    local rightMinX = self.rightMinX;
    local rightMaxX = self.rightMaxX;
    local rightSpanX = rightMaxX - rightMinX + 1;

    local leftFromOffsetX = (SECTOR_WIDTH - leftSpanX)*0.5*tileSize;
    local rightFromOffsetX = ((SECTOR_WIDTH - rightSpanX)*0.5 + SECTOR_WIDTH) *tileSize;

    local fromOffsetY = - HEADER_SIZE - tileSize;
    local node, x, y;

    for i = 1, MainFrame.numAcitveNodes do
        node = Nodes[i];
        node:ClearAllPoints();
        if node.isLeft then
            x = (node.iX - leftMinX) * tileSize + leftFromOffsetX;
            y = -(node.iY - leftMinY) * tileSize + fromOffsetY;
            --node.Order:SetText(node.iX - leftMinX)
        else
            x = (node.iX - rightMinX) * tileSize + rightFromOffsetX;
            y = -(node.iY - rightMinY) * tileSize + fromOffsetY;
            node:SetPoint("TOPLEFT", container, "TOPLEFT", x, y);
            --node.Order:SetText(node.iX - rightMinX)
        end
        node:SetPoint("TOPLEFT", container, "TOPLEFT", x, y);
        node.x, node.y = x, y;
    end
end

function LayoutUtil:SetNodeTileIndex(node, isLeft, iX, iY)
    node.iX = iX;
    node.iY = iY;
    node.isLeft = isLeft or nil;

    if isLeft then
        if iX > self.leftMaxX then
            self.leftMaxX = iX;
        end
        if iX < self.leftMinX then
            self.leftMinX = iX;
        end
        if iY < self.leftMinY then
            self.leftMinY = iY;
        end
    else
        if iX > self.rightMaxX then
            self.rightMaxX = iX;
        end
        if iX < self.rightMinX then
            self.rightMinX = iX;
        end
        if iY < self.rightMinY then
            self.rightMinY = iY;
        end
    end
end


local function CalculateNormalizedPosition(posX, posY)
    posX = posX - 1800;
    posY = 1200 - posY;
    
    posX = floor(posX/DISTANCE_UNIT + 0.5);
    posY = floor(posY/DISTANCE_UNIT + 0.5);

    posY = -posY;

    posX = posX * 0.5;
    posY = posY * 0.5;

    local isLeftSide;

    if posX >= 12.5 then
        posX = posX - 2
    else
        isLeftSide = true
    end

    return posX, posY, isLeftSide
end


local function SetBranchColorYellow(branch, isActive)
    if isActive then
        branch:SetVertexColor(0.72, 0.6, 0);
    else
        branch:SetVertexColor(0.200, 0.200, 0.200);
    end
end

local function SetBranchColorCyan(branch, isActive)
    if isActive then
        branch:SetVertexColor(0, 0.53, 0.65);
    else
        branch:SetVertexColor(0.200, 0.200, 0.200);
    end
end

local SetBranchColor = SetBranchColorYellow;


local DataProvider = {};

function DataProvider:UpdateSpecInfo()
    local specIndex = GetSpecialization() or 1;
    local specID, specName = GetSpecializationInfo(specIndex);
    self.specID = specID;
    self.specName = specName;
end

function DataProvider:GetCurrentSpecID()
    if not self.specID then
        self:UpdateSpecInfo();
    end
    return self.specID
end

function DataProvider:GetActiveLoadoutName()
    local specID = self:GetCurrentSpecID();
    local configs = C_ClassTalents.GetConfigIDsBySpecID(specID);
    local total = #configs;

    if total == 0 then
        return self.specName
    else
        local selectedID = C_ClassTalents.GetLastSelectedSavedConfigID(specID);
        local name;
        if selectedID then
            local info = C_Traits.GetConfigInfo(selectedID);
            name = info and info.name;
        end
        return name or self.specName
    end
end

function DataProvider:GetSelecetdConfigID()
    local specID = self:GetCurrentSpecID();
    local selectedID = C_ClassTalents.GetLastSelectedSavedConfigID(specID);
    return selectedID
end

function DataProvider:WipeNodeCache()
    EntryInfoCache = {};
    NodeInfoCache = {};
end


NarciMiniTalentTreeMixin = {};

function NarciMiniTalentTreeMixin:OnLoad()
    MainFrame = self;

    local px = NarciAPI.GetPixelForWidget(self, 1);
    PIXEL = px;
    BRANCH_WEIGHT = NarciAPI.GetPixelForWidget(self, 2);
    BUTTON_SIZE = NarciAPI.GetPixelForWidget(self, BUTTON_PIXEL_SIZE);
    ICON_SIZE = NarciAPI.GetPixelForWidget(self, ICON_PIXEL_SIZE);
    DISTANCE_RATIO = BUTTON_SIZE / 600;
    BUTTON_SIZE_HALF = BUTTON_SIZE * 0.5;
    FONT_HEIGHT = 16 * px;
    HEADER_SIZE = FONT_HEIGHT + BUTTON_SIZE;

    LayoutUtil.fromOffsetX = -3 * 600*DISTANCE_RATIO;
    LayoutUtil.fromOffsetY = 2 * 600*DISTANCE_RATIO;

    LayoutUtil:UpdateFrameSize();

    self.ClassName:ClearAllPoints();
    self.ClassName:SetPoint("TOP", self, "TOPLEFT", (4.5 + PADDING) * BUTTON_SIZE, -PADDING*BUTTON_SIZE);

    self.SpecName:ClearAllPoints();
    self.SpecName:SetPoint("TOP", self, "TOPLEFT", (15.5 + PADDING) * BUTTON_SIZE, -PADDING*BUTTON_SIZE);

    local font, height, flag = self.LoadoutToggle.ButtonText:GetFont();
    self.ClassName:SetFont(font, BUTTON_SIZE, flag);
    self.SpecName:SetFont(font, BUTTON_SIZE, flag);


    local hitrectCompensation = (16*px - 16)/2;
    if hitrectCompensation > 0 then
        hitrectCompensation = 0;
    end


    local function LoadoutToggle_OnEnter(f)
        f.ButtonText:SetTextColor(0.92, 0.92, 0.92);
        f.Arrow:SetVertexColor(0.92, 0.92, 0.92);
    end

    local function LoadoutToggle_OnLeave(f)
        f.ButtonText:SetTextColor(0.67, 0.67, 0.67);
        f.Arrow:SetVertexColor(0.67, 0.67, 0.67);
    end

    self.LoadoutToggle.ButtonText:SetFont(font, FONT_HEIGHT, "");
    self.LoadoutToggle:ClearAllPoints();
    self.LoadoutToggle:SetPoint("TOP", self, "TOPLEFT", SECTOR_WIDTH * BUTTON_SIZE, -BUTTON_SIZE);
    self.LoadoutToggle:SetHeight(FONT_HEIGHT);
    self.LoadoutToggle:SetHitRectInsets(0, 0, hitrectCompensation, hitrectCompensation);
    self.LoadoutToggle.Arrow:SetSize(FONT_HEIGHT, FONT_HEIGHT);
    self.LoadoutToggle:SetScript("OnClick", function()
        LoadoutUtil:ToggleList();
    end);
    self.LoadoutToggle:SetScript("OnEnter", LoadoutToggle_OnEnter);
    self.LoadoutToggle:SetScript("OnLeave", LoadoutToggle_OnLeave);

    self.HeaderLight:ClearAllPoints();
    self.HeaderLight:SetPoint("TOP", self, "TOPLEFT", SECTOR_WIDTH * BUTTON_SIZE, 0);
    self.HeaderLight:SetSize(SECTOR_WIDTH * BUTTON_SIZE * 2 , SECTOR_WIDTH * BUTTON_SIZE * 0.5, 0);

    self.SpecTabToggle:SetHeight(FONT_HEIGHT);
    self.SpecTabToggle:SetHitRectInsets(-4, 0, hitrectCompensation, hitrectCompensation);
    self.SpecTabToggle:SetPoint("TOPLEFT", self, "TOPLEFT", BUTTON_SIZE, -BUTTON_SIZE);
    self.SpecTabToggle.ButtonText:SetFont(font, FONT_HEIGHT, "");
    self.SpecTabToggle.ButtonText:SetPoint("LEFT", 12*px, 0);
    self.SpecTabToggle.Arrow:SetSize(FONT_HEIGHT, FONT_HEIGHT);
    self.SpecTabToggle.Arrow:SetPoint("LEFT", 0, -px);


    local function SpecTabToggle_OnEnter(f)
        f.ButtonText:SetTextColor(0.8, 0.8, 0.8);
        f.Arrow:SetVertexColor(0.8, 0.8, 0.8);
    end

    local function SpecTabToggle_OnLeave(f)
        f.ButtonText:SetTextColor(0.5, 0.5, 0.5);
        f.Arrow:SetVertexColor(0.5, 0.5, 0.5);
    end

    local function SpecTabToggle_OnClick(f)
        MainFrame.SpecSelect:ShowFrame();
    end
   
    self.SpecTabToggle:SetScript("OnEnter", SpecTabToggle_OnEnter);
    self.SpecTabToggle:SetScript("OnLeave", SpecTabToggle_OnLeave);
    self.SpecTabToggle:SetScript("OnClick", SpecTabToggle_OnClick);

    self.PvPTalentToggle:SetHeight(FONT_HEIGHT);
    self.PvPTalentToggle:SetHitRectInsets(0, -8, hitrectCompensation, hitrectCompensation);
    self.PvPTalentToggle:SetPoint("TOPRIGHT", self, "TOPRIGHT", -BUTTON_SIZE, -BUTTON_SIZE);
    self.PvPTalentToggle.ButtonText:SetFont(font, FONT_HEIGHT, "");
    self.PvPTalentToggle.ButtonText:SetPoint("RIGHT", -12*px, 0);
    self.PvPTalentToggle.Arrow:SetSize(FONT_HEIGHT/2, FONT_HEIGHT);
    self.PvPTalentToggle.Arrow:SetPoint("RIGHT", 0, -px);
    self.PvPTalentToggle:SetScript("OnEnter", SpecTabToggle_OnEnter);
    self.PvPTalentToggle:SetScript("OnLeave", SpecTabToggle_OnLeave);
    self.PvPTalentToggle:SetScript("OnClick", function(f)
        if MainFrame.PvPTalentFrame:IsShown() then
            MainFrame.PvPTalentFrame:Hide();
            f.Arrow:SetTexCoord(0, 0.25, 0.5, 1);
        else
            MainFrame.PvPTalentFrame:Show();
            f.Arrow:SetTexCoord(0.25, 0, 0.5, 1);
        end
        LayoutUtil:UpdateFrameSize();
    end);

    if not SHOW_NAME then
        self.ClassName:Hide();
        self.SpecName:Hide();
    end

    self.Divider:ClearAllPoints();
    self.Divider:SetPoint("TOPLEFT", self, "TOPLEFT", SECTOR_WIDTH * BUTTON_SIZE, -BUTTON_SIZE/2 -HEADER_SIZE);
    self.Divider:SetPoint("BOTTOMLEFT", self, "BOTTOM", 0, BUTTON_SIZE/2);

    --Share
    local fontHeight;
    if BUTTON_PIXEL_SIZE < 30 then
        fontHeight = BUTTON_SIZE;
    else
        fontHeight = BUTTON_SIZE/2;
    end
    self.SharedString:SetFont(font, fontHeight, flag);
    self.SharedString:ClearAllPoints();
    self.SharedString:SetPoint("TOPLEFT", self.SpecIcon, "TOPRIGHT", 4, 0);
    self.SharedString:SetPoint("RIGHT", self, "RIGHT", -BUTTON_SIZE, 0);
    self.SharedString:SetTextColor(0.8, 0.8, 0.8);
    self.SharedString:SetSpacing(0);

    local pixel = NarciAPI.GetPixelForWidget(self, 1);
    self.SpecIconBorder:SetVertexColor(0.67, 0.67, 0.67);
    self.SpecIconBorderMask:SetPoint("TOPLEFT", self.SpecIconBorder, "TOPLEFT", pixel, -pixel);
    self.SpecIconBorderMask:SetPoint("BOTTOMRIGHT", self.SpecIconBorder, "BOTTOMRIGHT", -pixel, pixel);

    local corpRatio = 1.5;  --w:h = 3:2
    local coordY =  (1 - (corpRatio - 1))/2
    local corp = 4 / 64;
    self.SpecIcon:SetTexCoord(corp, 1-corp, corp * coordY, (1-corp) * (1-coordY));
    self.SpecIcon:SetSize(BUTTON_SIZE*corpRatio, BUTTON_SIZE);

    self.Footer:SetPoint("BOTTOM", self.SharedString, "BOTTOM", 0, -BUTTON_SIZE);

    local str = "BYQAPz/q+n/tulJx+Kl/V/d+cDAAAAAAkSpkkSSSaJHgkCSakEAAAAAAAKRCUSiSKARKJSaQShE4AA";
    local seg = 8;
    local str2;

    for i = 1, #str, seg do
        if str2 then
            str2 = str2.."  "..string.sub(str, i, i + seg - 1);
        else
            str2 = string.sub(str, i, i + seg - 1);
        end
    end

    self.SharedString:SetText(str2);
end

function NarciMiniTalentTreeMixin:ShowActiveBuild()
    local configID = C_ClassTalents.GetActiveConfigID();
    self:ShowConfig(configID);
end

function NarciMiniTalentTreeMixin:ShowConfig(configID, isPreviewing)
    if configID ~= self.configID then
        DataProvider:WipeNodeCache();
    end

    self:ReleaseAllNodes();

    local configInfo = C_Traits.GetConfigInfo(configID);
    local treeID = configInfo.treeIDs[1]
	local nodeIDs = C_Traits.GetTreeNodes(treeID);

    self.configID = configID;
    self.treeID = treeID;
    self.nodeIDs = nodeIDs;

    local isInspecting = self:IsInspecting();

    for i, nodeID in ipairs(nodeIDs) do
		self:InstantiateTalentButton(nodeID, nil, isInspecting);
	end

    LayoutUtil:UpdateNodePosition();

    --After(0, function()
        self:CreateBranches()
    --end)

    if not isPreviewing and not isInspecting then
        self.LoadoutToggle.ButtonText:SetText(DataProvider:GetActiveLoadoutName());
        self.SpecSelect:SetSelectedSpec(DataProvider:GetCurrentSpecID());
        LoadoutUtil:SetActiveConfigID(DataProvider:GetSelecetdConfigID());
        LoadingBarUtil:HideBar();
    end
end

function NarciMiniTalentTreeMixin:ShowInspecting(inspectUnit)
    self.inspectUnit = inspectUnit;
    self:SetInspectionMode(true);
    self:ShowConfig(-1);
end


function NarciMiniTalentTreeMixin:SetInspectionMode(state)
    if state then
        self.SpecTabToggle:Hide();
        self.LoadoutToggle:Disable();
        self.LoadoutToggle.Arrow:Hide();
        --self.LoadoutToggle.ButtonText:SetText(TALENTS_INSPECT_FORMAT:format(UnitName(self.inspectUnit)));
        LoadingBarUtil:HideBar();
        if self.SpecSelect:IsShown() then
            self.SpecSelect:CloseFrame(true);
        end
        
        if self.PvPTalentFrame:IsShown() then
            self.PvPTalentFrame:Update();
        end

        local loadoutName;
        local unit = self:GetInspectUnit();
        local playerName = UnitName(unit);
        local specID = GetInspectSpecialization(unit);
		local classDisplayName, class = UnitClass(unit);
		if specID then
            local sex = UnitSex(unit);
			local _, specName = GetSpecializationInfoByID(specID, sex);
            loadoutName = specName.." "..classDisplayName.." - "..playerName;
        else
            loadoutName = TALENTS_INSPECT_FORMAT:format(playerName);
		end
        self.LoadoutToggle.ButtonText:SetText(loadoutName);
        SetBranchColor = SetBranchColorCyan;

    elseif self:IsInspecting() then
        self.inspectUnit = nil;
        self.SpecTabToggle:Show();
        self.LoadoutToggle:Enable();
        self.LoadoutToggle.Arrow:Show();
        self.LoadoutToggle.ButtonText:SetText(DataProvider:GetActiveLoadoutName());
        if self.PvPTalentFrame:IsShown() then
            self.PvPTalentFrame:Update();
        end
        SetBranchColor = SetBranchColorYellow;
    end
end

local PRINTED_INDEX = {
    [118] = true,
    [119] = true,
    [103] = true,
    [112] = true,
    [102] = true,
}

local function SetNodePosition(node, relativeTo, x, y)
    y = y - HEADER_SIZE;
    --node:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", x, y);
    node.x = x;
    node.y = y;
end

function NarciMiniTalentTreeMixin:InstantiateTalentButton(nodeID, nodeInfo, isInspecting)
    nodeInfo = nodeInfo or self:GetAndCacheNodeInfo(nodeID);

    if not nodeInfo.isVisible then
		return nil;
	end

    local activeEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID or nil;
	local entryInfo = (activeEntryID ~= nil) and self:GetAndCacheEntryInfo(activeEntryID) or nil;
	local talentType = (entryInfo ~= nil) and entryInfo.type or nil;

    if nodeInfo.posY < 0 then
        --Button #1 is out-of-bound for some reason
        return
    end

    local node = self:AcquireNode();
    node:SetBorderColor(isInspecting);

    local iX, iY, isLeftSide = CalculateNormalizedPosition(nodeInfo.posX, nodeInfo.posY);

    local isAutoGranted;
    if iY == 1 and nodeInfo.ranksPurchased == 0 then
        --only check the first row for auto-granted talent
        local conditionID = nodeInfo.conditionIDs[1];
        if conditionID then
            local conditionInfo = C_Traits.GetConditionInfo(self.configID, conditionID);
            isAutoGranted = conditionInfo.isMet and conditionInfo.ranksGranted and conditionInfo.ranksGranted > 0;
        end
    end

    if nodeInfo.ranksPurchased > 0 or nodeInfo.activeRank > 0 or isAutoGranted then
        --ranksPurchased is 0 for freely-granted talent (some talent in the first row)
        node.active = true;
        if nodeInfo.ranksPurchased == 0 then
            node.currentRank = 1;
        else
            node.currentRank = nodeInfo.ranksPurchased;
        end
    else
        if HIDE_INACTIVE_NODE then
            node:Hide();
        end
        node.active = nil;
        node.currentRank = 0;
    end
    node.maxRanks = nodeInfo.maxRanks;

    LayoutUtil:SetNodeTileIndex(node, isLeftSide, iX, iY);

    NodeIDxNode[nodeID] = node;

    if nodeInfo.type == 2 then
        node.entryIDs = nodeInfo.entryIDs;
        if activeEntryID == nodeInfo.entryIDs[1] then
            node:SetNodeType(2, 1);
        elseif activeEntryID == nodeInfo.entryIDs[2] then
            node:SetNodeType(2, 2);
        else
            node:SetNodeType(2, 0);
        end
        --[[
        if nodeInfo and (nodeInfo.type == Enum.TraitNodeType.Selection) then
			if FlagsUtil.IsSet(nodeInfo.flags, Enum.TraitNodeFlag.ShowMultipleIcons) then
				return "ClassTalentButtonChoiceTemplate";
			end
		end
        --]]
    else
        node.entryIDs = nil;
        if talentType == 0 then
            --*Warrior Why do some passive traits use this type?
            node:SetNodeType(1, 0);
        elseif talentType == 1 then --square
            node:SetNodeType(0);
        elseif talentType == 2 then --circle
            if nodeInfo.type == 0 then
                if nodeInfo.maxRanks == 1 then  --1/1
                    node:SetNodeType(1, 0);
                elseif nodeInfo.maxRanks == 2 then
                    if nodeInfo.ranksPurchased == 1 then    --1/2
                        node:SetNodeType(1, 1);
                    else    --2/2
                        node:SetNodeType(1, 0);
                    end
                elseif nodeInfo.maxRanks == 3 then
                    if nodeInfo.ranksPurchased == 1 then    --1/3
                        node:SetNodeType(1, 1);
                    elseif nodeInfo.ranksPurchased == 2 then    --2/3
                        node:SetNodeType(1, 2);
                    else    --3/3
                        node:SetNodeType(1, 0);
                    end
                else
                    --0/4?
                    node.Symbol:SetVertexColor(1, 0, 0);
                    node:SetNodeType(1, 0);
                end
            else
                node:Hide();
            end
        else
            --nil is unselected octagon
            node.Symbol:SetVertexColor(1, 0, 0);
            print(talentType, "Unknown type")
        end
    end


    if node.active then
        node.Symbol:SetVertexColor(0.67, 0.67, 0.67);
        node:SetActive(true);
    else
        node.Symbol:SetVertexColor(0.160, 0.160, 0.160);
        node:SetActive(false);
    end

    if entryInfo then
        node:SetDefinitionID(entryInfo.definitionID);
    end

    node.nodeID = nodeID;
    node.entryID = activeEntryID;
    node.rank = nodeInfo.ranksPurchased;
end

function NarciMiniTalentTreeMixin:ReleaseAllNodes()
    for i = 1, #Nodes do
        Nodes[i]:Hide();
        Nodes[i]:ClearAllPoints();
    end
    self.numAcitveNodes = 0;

    for i = 1, #Branches do
        Branches[i]:Hide();
        Branches[i]:ClearAllPoints();
    end
    self.numBranches = 0;

    LayoutUtil:Reset();
end

function NarciMiniTalentTreeMixin:AcquireNode()
    self.numAcitveNodes = self.numAcitveNodes + 1;
    if not Nodes[self.numAcitveNodes] then
        Nodes[self.numAcitveNodes] = CreateFrame("Frame", nil, self, "NarciTalentTreeNodeTemplate");
        Nodes[self.numAcitveNodes].Symbol:SetVertexColor(0.67, 0.67, 0.67);
        Nodes[self.numAcitveNodes].Icon:SetSize(ICON_SIZE, ICON_SIZE);
        Nodes[self.numAcitveNodes]:SetSize(BUTTON_SIZE, BUTTON_SIZE);
    end
    Nodes[self.numAcitveNodes]:Show();
    return Nodes[self.numAcitveNodes];
end

function NarciMiniTalentTreeMixin:GetAndCacheEntryInfo(entryID)
    if not EntryInfoCache[entryID] then
        EntryInfoCache[entryID] = GetEntryInfo(self.configID, entryID);
    end
    return EntryInfoCache[entryID];
end

function NarciMiniTalentTreeMixin:GetAndCacheNodeInfo(nodeID)
    if not NodeInfoCache[nodeID] then
        NodeInfoCache[nodeID] = GetNodeInfo(self.configID, nodeID);
    end
    return NodeInfoCache[nodeID];
end


local BranchUpdater = CreateFrame("Frame");

local MAX_PROCESS_PER_FRAME = 400;    --20

local function BranchUpdater_OnUpdate(self, elapsed)
    local processedThisFrame = 0;

    local nodeID;
    local nodeInfo;
    local fromNode, targetNode;
    local b;
    local x1, y1, x2, y2, d, rd;
    local bchs = Branches;
    local SZH = BUTTON_SIZE_HALF;
    local notFound = true;
    local main = MainFrame;

    while self.fromNodeIndex <= self.numNodes do
        if self.lastEdgeID and self.lastNodeInfo then
            fromNode = self.lastFromNode;
            for j = self.lastEdgeID, #self.lastNodeInfo.visibleEdges do
                targetNode = NodeIDxNode[self.lastNodeInfo.visibleEdges[j].targetNode];
                if targetNode then
                    processedThisFrame = processedThisFrame + 1;
                    if processedThisFrame > MAX_PROCESS_PER_FRAME then
                        self.lastEdgeID = j;
                        self.lastNodeInfo = nodeInfo;
                        return
                    end
                    self.numBranches = self.numBranches + 1;
                    b = bchs[self.numBranches];
                    if not b then
                        b = MainFrame:CreateTexture(nil, "OVERLAY");
                        bchs[self.numBranches] = b;
                        b:SetHeight(BRANCH_WEIGHT);
                        b:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\Branch");
                    end
                    x1, y1 = fromNode.x + SZH, fromNode.y - SZH;
                    x2, y2 = targetNode.x + SZH, targetNode.y - SZH;
                    d = sqrt( (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) );
                    rd = atan2(y2 - y1, x2 - x1);
                    b:SetWidth(d);
                    b:ClearAllPoints();
                    if fromNode.isLeft then
                        b:SetPoint("CENTER", main, "TOPLEFT", (x1+x2)*0.5, (y1+y2)*0.5);
                    else
                        b:SetPoint("CENTER", main, "TOPLEFT", (x1+x2)*0.5, (y1+y2)*0.5);
                    end
                    
                    b:SetRotation(rd);
                    b:Show();

                    SetBranchColor(b, fromNode.active and targetNode.active);
                end
            end

            self.fromNodeIndex = self.fromNodeIndex + 1;
            self.lastEdgeID = nil;
            self.lastNodeInfo = nil;
            self.lastFromNode = nil;

            if self.fromNodeIndex > self.numNodes then
                break
            end
        end

        nodeID = MainFrame.nodeIDs[self.fromNodeIndex];
        nodeInfo = MainFrame:GetAndCacheNodeInfo(nodeID);

        if nodeInfo then
            fromNode = NodeIDxNode[nodeID];
            if fromNode then
                --print(nodeID)
                --notFound = false;
                for j, edgeVisualInfo in ipairs(nodeInfo.visibleEdges) do
                    targetNode = NodeIDxNode[edgeVisualInfo.targetNode];
                    if targetNode then
                        notFound = false;
                        processedThisFrame = processedThisFrame + 1;
                        if processedThisFrame > MAX_PROCESS_PER_FRAME then
                            self.lastEdgeID = j;
                            self.lastNodeInfo = nodeInfo;
                            self.lastFromNode = fromNode;
                            return
                        end
                        self.numBranches = self.numBranches + 1;
                        b = bchs[self.numBranches];
                        if not b then
                            b = MainFrame:CreateTexture(nil, "OVERLAY");
                            bchs[self.numBranches] = b;
                            b:SetHeight(BRANCH_WEIGHT);
                            b:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\Branch");
                        end
                        x1, y1 = fromNode.x + SZH, fromNode.y - SZH;
                        x2, y2 = targetNode.x + SZH, targetNode.y - SZH;
                        d = sqrt( (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) );
                        rd = atan2(y2 - y1, x2 - x1);
                        b:SetWidth(d);
                        b:ClearAllPoints();
                        if fromNode.isLeft then
                            b:SetPoint("CENTER", main, "TOPLEFT", (x1+x2)*0.5, (y1+y2)*0.5);
                        else
                            b:SetPoint("CENTER", main, "TOPLEFT", (x1+x2)*0.5, (y1+y2)*0.5);
                        end
                        b:SetRotation(rd);
                        b:Show();

                        SetBranchColor(b, fromNode.active and targetNode.active);
                    end
                end
            end
        end

        self.fromNodeIndex = self.fromNodeIndex + 1;
    end

    if notFound then
        self:SetScript("OnUpdate", nil);
        --print("Branches: "..self.numBranches);
    end
end

function BranchUpdater:StartUpdating()
    self.numBranches = 0;
    self.fromNodeIndex = 1;
    self.numNodes = #MainFrame.nodeIDs;
    self:SetScript("OnUpdate", BranchUpdater_OnUpdate);
end

function NarciMiniTalentTreeMixin:CreateBranches()
    if true then
        BranchUpdater:StartUpdating();
        return
    end

	local nodeIDs = self.nodeIDs or C_Traits.GetTreeNodes(self.treeID);
    local configID = self.configID;
    local nodeInfo;

    local fromNode, targetNode;

    local total = 0;
    local bchs = Branches;
    local x1, y1, x2, y2, d, rd;
    local b;
    local sqrt = sqrt;
    local atan2 = atan2;
    local SZH = BUTTON_SIZE_HALF;

    for i, nodeID in ipairs(nodeIDs) do
		nodeInfo = self:GetAndCacheNodeInfo(nodeID);
        if nodeInfo then
            fromNode = NodeIDxNode[nodeID];
            if fromNode then
                for j, edgeVisualInfo in ipairs(nodeInfo.visibleEdges) do
                    targetNode = NodeIDxNode[edgeVisualInfo.targetNode];
                    if targetNode then
                        --self:LinkNode(fromNode, targetNode);
                        total = total + 1;
                        b = bchs[total];
                        if not b then
                            b = self:CreateTexture(nil, "OVERLAY");
                            bchs[total] = b;
                            b:SetHeight(BRANCH_WEIGHT);
                            b:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\Branch")
                        end
                        x1, y1 = fromNode.x + SZH, fromNode.y - SZH;
                        x2, y2 = targetNode.x + SZH, targetNode.y - SZH;
                        d = sqrt( (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) );
                        rd = atan2(y2 - y1, x2 - x1);
                        b:SetWidth(d);
                        b:SetPoint("CENTER", self, "TOPLEFT", (x1+x2)*0.5, (y1+y2)*0.5);
                        b:SetRotation(rd);
                        b:Show();

                        if fromNode.active and targetNode.active then
                            b:SetVertexColor(0.4, 0.4, 0.4);
                        else
                            b:SetVertexColor(0.160, 0.160, 0.160);
                        end
                    end
                end
            end
		end
	end
end

local Events = {
    "TRAIT_TREE_CHANGED", "TRAIT_NODE_CHANGED", "TRAIT_NODE_CHANGED_PARTIAL", "TRAIT_NODE_ENTRY_UPDATED", "TRAIT_CONFIG_UPDATED", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",

    --TRAIT_NODE_CHANGED: Fires multiple times when cancel switching talent
    --TRAIT_TREE_CHANGED: After clicking a loadout
    --TRAIT_CONFIG_UPDATED: After successfully changing loadout
    --ACTIVE_PLAYER_SPECIALIZATION_CHANGED: followed by TRAIT_CONFIG_UPDATED
}

function NarciMiniTalentTreeMixin:OnShow()
    for i, event in ipairs(Events) do
        self:RegisterEvent(event);
    end
end


function NarciMiniTalentTreeMixin:OnEvent(event, ...)
    if event == "TRAIT_TREE_CHANGED" then
        
    elseif event == "TRAIT_NODE_CHANGED" then

    elseif event == "TRAIT_NODE_CHANGED_PARTIAL" then

    elseif event == "TRAIT_NODE_ENTRY_UPDATED" then

    elseif event == "TRAIT_CONFIG_UPDATED" then
        After(0, function()
            self:ShowActiveBuild();

            --if ClassTalentFrame then
            --    ClassTalentFrame:OnEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED");
            --end
        end)
    elseif event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
        if self.SpecSelect:IsShown() then
            self.SpecSelect:CloseFrame();
        end
        DataProvider:UpdateSpecInfo();
        self:ShowActiveBuild();
    end
end

function NarciMiniTalentTreeMixin:IsInspecting()
    return self.inspectUnit ~= nil
end

function NarciMiniTalentTreeMixin:GetInspectUnit()
    return self.inspectUnit;
end

function NarciMiniTalentTreeMixin:AnchorToInspectFrame()
    self.anchor = "inspectframe";
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", InspectFrame, "TOPRIGHT", 4, 0);
end

function NarciMiniTalentTreeMixin:AnchorToPaperDoll()
    self.anchor = "paperdoll";
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", PaperDollFrame, "TOPRIGHT", 4, 0);
end


--[[
    
function ClassTalentTalentsTabMixin:GetSpecID()
	if self:IsInspecting() then
		return GetInspectSpecialization(self:GetInspectUnit());
	end

	return PlayerUtil.GetCurrentSpecID();
end

]]

NarciTalentTreeLoadoutButtonMixin = {};

function NarciTalentTreeLoadoutButtonMixin:OnEnter()
    if not self.selected then
        self.ButtonText:SetTextColor(0.92, 0.92, 0.92);
    end

    if self.configID then
        MainFrame:ShowConfig(self.configID, true);
    end
end

function NarciTalentTreeLoadoutButtonMixin:OnLeave()
    if not self.selected then
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciTalentTreeLoadoutButtonMixin:OnClick()
    if self.selected then

    else
        if self.configID then
            LoadingBarUtil:SetFromLoadoutToggle(MainFrame.LoadoutToggle);

            local autoApply = true;
            local result = C_ClassTalents.LoadConfig(self.configID, autoApply);
            if result ~= 0 then
                local currentSpecID = DataProvider:GetCurrentSpecID();
                if currentSpecID then
                    C_ClassTalents.UpdateLastSelectedSavedConfigID(currentSpecID, self.configID);
                end
            end
        end
    end
    LoadoutUtil:HideList();
end

function NarciTalentTreeLoadoutButtonMixin:SetConfigID(configID)
    self.configID = configID;

    local info = C_Traits.GetConfigInfo(configID);
    if info and info.name then
        self.ButtonText:SetText(info.name);
        self.Underline:SetWidth(self.ButtonText:GetWrappedWidth());
    else

    end
end

function LoadoutUtil:IsFocused()
    if MainFrame.LoadoutToggle:IsMouseOver(12, -12, 0, 0) then
        return true
    end

    for i = 1, #self.buttons do
        if self.buttons[i]:IsShown() then
            if self.buttons[i]:IsMouseOver() then
                return true
            end
        else
            return
        end
    end
end

function LoadoutUtil:Init()
    self.buttons = {};

    local function LoadoutDropdown_OnShow(f)
        f:RegisterEvent("GLOBAL_MOUSE_DOWN");
    end

    local function LoadoutDropdown_OnEvent(f, event, ...)
        if not self:IsFocused() then
            f:UnregisterEvent("GLOBAL_MOUSE_DOWN");
            self:HideList();
        end
    end

    self.container = MainFrame.LoadoutDropdown;

    self.container:SetScript("OnShow", LoadoutDropdown_OnShow);
    self.container:SetScript("OnEvent", LoadoutDropdown_OnEvent);

    self.font = MainFrame.LoadoutToggle.ButtonText:GetFont();
    self.buttonHeight = 32*PIXEL;

    self.Init = nil;
end

function LoadoutUtil:UpdateList()
    for i = 1, #self.buttons do
        self.buttons[i]:Hide();
    end

    local specID = DataProvider:GetCurrentSpecID();
    local configs = C_ClassTalents.GetConfigIDsBySpecID(specID);
    local button;

    for i = 1, #configs do
        button = self.buttons[i];
        if not button then
            button = CreateFrame("Button", nil, self.container, "NarciTalentTreeLoadoutButtonTemplate");
            self.buttons[i] = button;
            button.ButtonText:SetFont(self.font, FONT_HEIGHT, "");
            button:SetPoint("TOP", MainFrame.LoadoutToggle, "TOP", 0, self.buttonHeight*( - i));
            button.Underline:SetHeight(2*PIXEL);
            button.Underline:SetPoint("TOPLEFT", button.ButtonText, "BOTTOMLEFT", 0, -2*PIXEL);
        end
        button:SetConfigID(configs[i]);
        button:Show();
    end

    if button then
        local top = self.container:GetTop();
        local bottom = button:GetBottom();
        self.container:SetHeight(top - bottom + 8);

        if self.activeConfigID then
            self:SetActiveConfigID(self.activeConfigID);
        end
    else
        self.container:SetHeight(64);
    end
end

function LoadoutUtil.ShowFrame_OnUpdate(f, elapsed)
    f.alpha = f.alpha + elapsed * 4;
    if f.alpha > 1 then
        f.alpha = 1;
        f:SetScript("OnUpdate", nil);
    end
    f:SetAlpha(f.alpha);
end

function LoadoutUtil:ShowList()
    if self.Init then
        self:Init();
    end

    self:UpdateList();

    if self.activeButton then
        self.activeButton.Underline.AnimIn:Stop();
        self.activeButton.Underline.AnimIn:Play();
    end

    self.container:Show();
    self.container.alpha = 0;
    self.container:SetScript("OnUpdate", self.ShowFrame_OnUpdate);

    MainFrame.LoadoutToggle.ButtonText:SetText("Loadout");
    MainFrame.LoadoutToggle.Arrow:SetRotation(math.pi);
end

function LoadoutUtil:HideList()
    self.container:Hide();
    MainFrame.LoadoutToggle.Arrow:SetRotation(0);

    if not LoadingBarUtil:IsBarVisible() then
        MainFrame.LoadoutToggle.ButtonText:SetText(DataProvider:GetActiveLoadoutName());
    end
end

function LoadoutUtil:ToggleList()
    if self.container and self.container:IsShown() then
        self:HideList();
    else
        self:ShowList();
    end
end

function LoadoutUtil:SetActiveConfigID(configID)
    self.activeButton = nil;
    self.activeConfigID = configID;
    if self.buttons then
        for i, b in ipairs(self.buttons) do
            if b.configID == configID then
                b.Underline:Show();
                b.selected = true;
                b.ButtonText:SetTextColor(1, 0.82, 0);
                self.activeButton = b;
            else
                b.Underline:Hide();
                b.selected = false;
                b:OnLeave();
            end
        end
    end
end


NarciTalentTreePvPFrameMixin = {};

function NarciTalentTreePvPFrameMixin:OnShow()
    self:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    self:Update();
end

function NarciTalentTreePvPFrameMixin:OnEvent()
    self:Update();
end

function NarciTalentTreePvPFrameMixin:Update()
    self:Init();

    local talentID, talentInfo;

    if MainFrame:IsInspecting() then
        local unit = MainFrame:GetInspectUnit();
        for i = 1, 3 do
            talentID = C_SpecializationInfo.GetInspectSelectedPvpTalent(unit, i);
            self.slots[i]:SetPvPTalent(talentID, unit);
            self.slots[i]:Show();
            self.slots[i].isInspecting = true;
            self.slots[i]:SetBorderColor(true);
        end

        for i = 4, 6 do
            talentInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(i - 3);
            self.slots[i]:SetPvPTalent((talentInfo ~= nil and talentInfo.selectedTalentID) or nil);
            self.slots[i]:Show();
            self.slots[i].isInspecting = false;
        end
    else
        for i = 4, 6 do
            self.slots[i]:Hide();
            self.slots[i].isInspecting = false;
        end

        for i = 1, 3 do
            talentInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(i);
            self.slots[i]:SetPvPTalent((talentInfo ~= nil and talentInfo.selectedTalentID) or nil);
            self.slots[i]:Show();
            self.slots[i].isInspecting = false;
            self.slots[i]:SetBorderColor(false);
        end
    end
end

function NarciTalentTreePvPFrameMixin:Init()
    if not self.slots then
        self.slots = {};

        local slot;

        for i = 1, 6 do -- 4,5,6 are for inspection (1-3 for the inspectee, 4-6 for me)
            slot = CreateFrame("Button", nil, self, "NarciTalentTreeNodeTemplate");
            self.slots[i] = slot;
            slot.Icon:SetSize(ICON_SIZE, ICON_SIZE);
            slot:SetSize(BUTTON_SIZE, BUTTON_SIZE);
            slot:SetNodeType(0, 1);
            slot.Icon:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375);
            slot.Symbol:SetVertexColor(0.160, 0.160, 0.160);
            slot:SetScript("OnEnter", ClassTalentTooltipUtil.SetFromPvPButton);

            if i <= 3 then
                slot:SetPoint("TOP", self, "TOP", 0, -HEADER_SIZE -(i + 1) * BUTTON_SIZE);
                slot.index = i;
            else
                slot:SetPoint("TOP", self, "TOP", 0, -HEADER_SIZE -(i + 3) * BUTTON_SIZE);
                slot.index = i - 3;
            end
        end

        self:SetWidth(BUTTON_SIZE * 3);
        self.Divider:ClearAllPoints();
        self.Divider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -BUTTON_SIZE/2 -HEADER_SIZE);
        self.Divider:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, BUTTON_SIZE/2);
    end
end



if not addon.IsDragonflight() then return end;

local ENABLE_INSPECT = false;
local ENABLE_PAPERDOLL = false;
local HookUtil = {};

function HookUtil:HookInpsectFrame()
    if self.inspectFrameHooked then return end;

    local InspectFrame = _G["InspectFrame"];

    if InspectFrame then
        self.inspectFrameHooked = true;
        InspectFrame:HookScript("OnShow", function()
            if ENABLE_INSPECT and InspectFrame.unit then
                MainFrame:AnchorToInspectFrame();
                MainFrame:Show();
                MainFrame:ShowInspecting(InspectFrame.unit);
            end
        end);

        InspectFrame:HookScript("OnHide", function()
            if ENABLE_INSPECT then
                MainFrame:Hide();
            end
        end);
    else
        if self.inspectFuncHooked then return end;
        self.inspectFuncHooked = true;
        hooksecurefunc("InspectUnit", function()
            if not self.inspectFrameHooked then
                self.inspectFrameHooked = true;
                InspectFrame = _G["InspectFrame"];
                if not InspectFrame then return end;

                InspectFrame:HookScript("OnShow", function()
                    if ENABLE_INSPECT and InspectFrame.unit then
                        MainFrame:AnchorToInspectFrame();
                        MainFrame:Show();
                        MainFrame:ShowInspecting(InspectFrame.unit);
                    end
                end);
    
                InspectFrame:HookScript("OnHide", function()
                    if ENABLE_INSPECT then
                        MainFrame:Hide();
                    end
                end);
            end
        end);
    end
end

function HookUtil:HookPaperDoll()
    if self.paperdollHooked then return end;
    self.paperdollHooked = true;

    local PaperDoll = _G["PaperDollFrame"];
    PaperDoll:HookScript("OnShow", function()
        if ENABLE_PAPERDOLL then
            MainFrame:AnchorToPaperDoll();
            MainFrame:SetInspectionMode(false);
            MainFrame:Show();
            MainFrame:ShowActiveBuild();
        end
    end);

    PaperDoll:HookScript("OnHide", function()
        if ENABLE_PAPERDOLL then
            MainFrame:Hide();
        end
    end);
end


do
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.ShowMiniTalentTreeForInspection(state, db)
        if state == nil then
            state = db["TalentTreeForInspection"];
        end
        if state then
            ENABLE_INSPECT = true;
            HookUtil:HookInpsectFrame();
        else
            ENABLE_INSPECT = false;
            if MainFrame.anchor == "inpsectframe" then
                MainFrame:Hide();
            end
        end
    end

    function SettingFunctions.ShowMiniTalentTreeForPaperDoll(state, db)
        if state == nil then
            state = db["TalentTreeForPaperDoll"];
        end
        if state then
            ENABLE_PAPERDOLL = true;
            HookUtil:HookPaperDoll();
        else
            ENABLE_PAPERDOLL = false;
            if MainFrame.anchor == "paperdoll" then
                MainFrame:Hide();
            end
        end
    end
end