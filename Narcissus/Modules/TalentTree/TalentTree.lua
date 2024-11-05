local INPSECT_CONFIG_ID = -1;

local HIDE_INACTIVE_NODE = false;
local USE_CLASS_BACKGROUND = false;

local _, addon = ...

local LoadingBarUtil = addon.TalentTreeLoadingBarUtil;
local ClassTalentTooltipUtil = addon.ClassTalentTooltipUtil;
local DataProvider = addon.TalentTreeDataProvider;
local OnEnterDelay = addon.TalentTreeOnEnterDelay;
local TextButtonUtil = addon.TalentTreeTextButtonUtil;
local TextureUtil = addon.TalentTreeTextureUtil;
local UniversalFont = addon.UniversalFontUtil.Create();
local NodeUtil = addon.TalentTreeNodeUtil;
--local ActionBarUtil = addon.TalentTreeActionBarUtil;

local L = Narci.L;

do
    local playerNameFonts = {
        rm = "Interface\\AddOns\\Narcissus\\Font\\SourceSansPro-Semibold.ttf",
        cn = "Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf",
        ru = "Interface\\AddOns\\Narcissus\\Font\\NotoSans-Medium.ttf",
    };
    UniversalFont:SetFonts(playerNameFonts);
    UniversalFont:SetFontStyle("");
    UniversalFont:CheckFirstLetterOnly(false);
end

local NarciAPI = NarciAPI;
local C_Traits = C_Traits;
local C_ClassTalents = C_ClassTalents;
local C_SpecializationInfo = C_SpecializationInfo;
local C_PvP = C_PvP;

local CAN_USE_TALENT_UI = true;
local CanPlayerUseTalentSpecUI = C_SpecializationInfo.CanPlayerUseTalentSpecUI;

local GetSpecializationInfoByID = GetSpecializationInfoByID;
local GetInspectSpecialization = GetInspectSpecialization;
local UnitClass = UnitClass;
local UnitSex = UnitSex;
local UnitLevel = UnitLevel;
local IsSpecializationActivateSpell = IsSpecializationActivateSpell;

local sqrt = math.sqrt;
local atan2 = math.atan2;
local ipairs = ipairs;
local floor = math.floor;

local BUTTON_PIXEL_SIZE = 32;
local ICON_PIXEL_SIZE = 24;
local FONT_PIXEL_SIZE = 16;

do
    local function ChangePixelSize(sizeInfo)
        BUTTON_PIXEL_SIZE = sizeInfo.buttonSize;
        ICON_PIXEL_SIZE = sizeInfo.iconSize;
        FONT_PIXEL_SIZE = sizeInfo.fontHeight;
    end
    addon.TalentTreeTextureUtil:AddSizeChangedCallback(ChangePixelSize);
end

local DISTANCE_UNIT = 300;  --600    --neighboring node distance 600
local PADDING = 1;
local HEADER_SIZE;
local SECTOR_WIDTH = 11;    --the width of each tab (spec talent, class talent). unit is button wdith.

local BUTTON_SIZE = 32;
local BUTTON_SIZE_HALF = BUTTON_SIZE * 0.5;
local BRANCH_WEIGHT = 1;
local ICON_SIZE = 24;
local FONT_HEIGHT = 16;
local PIXEL = 1;

local MainFrame;
local Nodes = {};
local Branches = {};
local NodeIDxNode = {};
local NodeHighlights = {};

local EventCenter = CreateFrame("Frame");

local LoadoutUtil = {};
local LayoutUtil = {};
LayoutUtil.editboxes = {};

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
    local w = BUTTON_SIZE * 2 * SECTOR_WIDTH + pvpFrameWidth;
    local h = BUTTON_SIZE * (10 + 2*PADDING) + HEADER_SIZE;
    self.frameWidth = w;
    self.frameHeight = h;
    MainFrame:SetSize(w, h);
    self:UpdateArtworkTexCoord();
end

function LayoutUtil:UpdateArtworkTexCoord()
    local l, r, t, b = TextureUtil:CalculateTexCoord(self.frameWidth, self.frameHeight, "right");
    MainFrame.SpecArt:SetTexCoord(l, r, t, b);
    l, r, t, b = TextureUtil:CalculateTexCoord(216 * PIXEL, self.frameHeight, "left");
    MainFrame.SideTab.ClipFrame.SpecArt:SetTexCoord(l, r, t, b);
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
        y = -(node.iY - leftMinY) * tileSize + fromOffsetY;
        if node.isLeft then
            x = (node.iX - leftMinX) * tileSize + leftFromOffsetX;
            --y = -(node.iY - leftMinY) * tileSize + fromOffsetY;
            --node.Order:SetText(node.iX - leftMinX)
        else
            x = (node.iX - rightMinX) * tileSize + rightFromOffsetX;
            --y = -(node.iY - rightMinY) * tileSize + fromOffsetY;
            --node.Order:SetText(node.iX - rightMinX)
        end
        node:SetPoint("TOPLEFT", container, "TOPLEFT", x, y);
        node.x, node.y = x, y;
    end

    --print("Left Span", leftSpanX);
    --print("Right Span", rightSpanX);

    local middleOffsetX = (0.5*(leftMaxX + rightMinX) - leftMinX) * tileSize + leftFromOffsetX;

    return middleOffsetX, fromOffsetY
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

function LayoutUtil:UpdatePixel()
    local f = MainFrame;
    local px = NarciAPI.GetPixelForWidget(f, 1);

    PIXEL = px;
    BRANCH_WEIGHT = 2 * px;
    BUTTON_SIZE = px * BUTTON_PIXEL_SIZE;
    ICON_SIZE = px * ICON_PIXEL_SIZE;
    BUTTON_SIZE_HALF = BUTTON_SIZE * 0.5;
    FONT_HEIGHT = FONT_PIXEL_SIZE * px;
    HEADER_SIZE = FONT_HEIGHT + BUTTON_SIZE;

    UniversalFont:SetFontHeight(FONT_HEIGHT);
    LayoutUtil:UpdateFrameSize();
    TextButtonUtil:UpdatePixel(px, FONT_PIXEL_SIZE);
    ClassTalentTooltipUtil:UpdatePixel();

    f.PvPTalentFrame:UpdatePixel();
    f.SideTab:UpdatePixel(px);
    --f.MacroForge:UpdatePixel(px);

    f.Divider:ClearAllPoints();
    f.Divider:SetPoint("TOPLEFT", f, "TOPLEFT", SECTOR_WIDTH * BUTTON_SIZE, -BUTTON_SIZE/2 -HEADER_SIZE);
    f.Divider:SetPoint("BOTTOMLEFT", f, "BOTTOM", 0, BUTTON_SIZE/2);

    if f.LoadoutToggle then
        f.LoadoutToggle:ClearAllPoints();
        f.LoadoutToggle:SetPoint("TOP", f, "TOPLEFT", SECTOR_WIDTH * BUTTON_SIZE, -BUTTON_SIZE);
        f.SideTabToggle:ClearAllPoints();
        f.SideTabToggle:SetPoint("TOPLEFT", f, "TOPLEFT", BUTTON_SIZE, -BUTTON_SIZE);
        f.PvPTalentToggle:ClearAllPoints();
        f.PvPTalentToggle:SetPoint("TOPRIGHT", f, "TOPRIGHT", -BUTTON_SIZE, -BUTTON_SIZE);
        f.DisplayModeButton1:ClearAllPoints();
        f.DisplayModeButton1:SetPoint("TOPRIGHT", f, "TOP", 0, -BUTTON_SIZE);
        f.DisplayModeButton2:ClearAllPoints();
        f.DisplayModeButton2:SetPoint("TOPLEFT", f, "TOP", 8, -BUTTON_SIZE);
        f.SettingsButton:ClearAllPoints();
        f.SettingsButton:SetPoint("BOTTOMLEFT", f.SideTab, "BOTTOMLEFT", 20*px, 20*px);
        f.ShareToggle:ClearAllPoints();
        f.ShareToggle:SetPoint("BOTTOMLEFT", f.SideTab, "BOTTOMLEFT", 20*px, (20 + 16*4)*px);
        f.SaveButton:ClearAllPoints();
        f.SaveButton:SetPoint("TOP", f.SaveButton.anchor, "BOTTOM", 0, -16*px);
    end

    for _, node in ipairs(Nodes) do
        node.Icon:SetSize(ICON_SIZE, ICON_SIZE);
        node:SetSize(BUTTON_SIZE, BUTTON_SIZE);
    end

    local highlightSize = 2*px*BUTTON_PIXEL_SIZE;

    for _, hl in ipairs(NodeHighlights) do
        hl:SetSize(highlightSize, highlightSize);
    end
end

function LayoutUtil:ClearTemps()
    for nodeID, node in pairs(NodeIDxNode) do
        node.x = nil;
        node.y = nil;
    end
end


local function CalculateNormalizedPosition(posX, posY)
    --posX = posX - 1800;
    --posY = 1200 - posY;

    --debug
    posX = posX;
    posY = -posY
    
    posX = floor(posX/DISTANCE_UNIT + 0.5);
    posY = floor(posY/DISTANCE_UNIT + 0.5);

    posY = -posY;

    posX = posX * 0.5;
    posY = posY * 0.5;

    local isLeftSide;

    if posX >= 12.5 then
        posX = posX - 2;
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

local function SetBranchColorGrey(branch, isActive)
    if isActive then
        branch:SetVertexColor(0.67, 0.67, 0.67);
    else
        branch:SetVertexColor(0.200, 0.200, 0.200);
    end
end

local SetBranchColor = SetBranchColorYellow;

local function ShouldHideBackground()
    return IsPlayerMoving() or IsMouselooking()
end

local InspectDisplayModeUtil = {};
InspectDisplayModeUtil.buttons = {};

InspectDisplayModeUtil.onEnter = function(f)
    if not f.selected then
        f:SetAlpha(1)
    end
end

InspectDisplayModeUtil.onLeave = function(f)
    if not f.selected then
        f:SetAlpha(0.5);
    end
end

InspectDisplayModeUtil.onClick = function(f)
    if not f.selected then
        MainFrame:SetInspectDisplayMode(f.id);
    end
end


function InspectDisplayModeUtil:SetupButton(button, id)
    button:SetScript("OnEnter", self.onEnter);
    button:SetScript("OnLeave", self.onLeave);
    button:SetScript("OnClick", self.onClick);
    button.iconPosition = "left";
    button.id = id;
    if id == 1 then
        button.ButtonText:SetText("THEY");
        button.Icon:SetVertexColor(0, 0.84, 1);
        button.ButtonText:SetTextColor(0, 0.84, 1);
    else
        button.ButtonText:SetText("DIFF");
        button.Icon:SetVertexColor(1, 0.82, 0);
        button.ButtonText:SetTextColor(1, 0.82, 0);
    end
    if not self.buttons[id] then
        self.buttons[id] = button;
    end
end

function InspectDisplayModeUtil:SelectButton(id)
    if not self.highlight then
        self.highlight = MainFrame:CreateTexture(nil, "ARTWORK");
        self.highlight:SetSize(64, 32);
        self.highlight:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\TextButtonHighlight");
        self.highlight:SetBlendMode("ADD");
        self.highlight:Hide();
    end
    if self.buttons[id] then
        for i, b in ipairs(self.buttons) do
            if b.id == id then
                b.selected = true;
                b:SetAlpha(1);
                self.highlight:ClearAllPoints();
                self.highlight:SetPoint("CENTER", b, "CENTER", -4, 0);
                self.highlight:Show();
            else
                b.selected = nil;
                b:SetAlpha(0.5);
            end
        end
    end
end

function InspectDisplayModeUtil:SetButtonVisibility(state)
    for i, b in ipairs(self.buttons) do
        b:SetShown(state);
    end
    if self.highlight then
        self.highlight:SetShown(state);
    end
    MainFrame.LoadoutToggle:SetShown(not state);
end


NarciMiniTalentTreeMixin = {};

function NarciMiniTalentTreeMixin:OnLoad()
    MainFrame = self;
    ClassTalentTooltipUtil:AssignMainFrame(self);

    LayoutUtil:UpdatePixel();

    self.HeaderLight:ClearAllPoints();
    self.HeaderLight:SetPoint("TOP", self, "TOPLEFT", SECTOR_WIDTH * BUTTON_SIZE, 0);
    self.HeaderLight:SetSize(SECTOR_WIDTH * BUTTON_SIZE * 2 , SECTOR_WIDTH * BUTTON_SIZE * 0.5, 0);

    self.Divider:ClearAllPoints();
    self.Divider:SetPoint("TOPLEFT", self, "TOPLEFT", SECTOR_WIDTH * BUTTON_SIZE, -BUTTON_SIZE/2 -HEADER_SIZE);
    self.Divider:SetPoint("BOTTOMLEFT", self, "BOTTOM", 0, BUTTON_SIZE/2);


    local frameLevel = self:GetFrameLevel();

    self.LoadoutToggle = TextButtonUtil:CreateButton(self, "right", "center", "vertical", 96, "arrowDown");
    self.LoadoutToggle:SetFrameLevel(frameLevel + 18);
    self.LoadoutToggle.ButtonText:SetText(L["Loadout"]);
    self.LoadoutToggle:SetScript("OnClick", function()
        LoadoutUtil:ToggleList();
    end);

    self.SideTabToggle = TextButtonUtil:CreateButton(self, "left", "left", "horizontal", nil, "arrowRight");
    self.SideTabToggle:SetFrameLevel(frameLevel + 20);
    self.SideTabToggle.ButtonText:SetText(SPECIALIZATION or "Specialization");
    self.SideTabToggle:SetScript("OnClick", function(f)
        self.SideTab:ShowFrame();
    end);
    self.MotionBlocker:SetFrameLevel(frameLevel + 19);

    self.PvPTalentToggle = TextButtonUtil:CreateButton(self, "right", "right", "horizontal", nil, "arrowRight");
    self.PvPTalentToggle:SetFrameLevel(frameLevel + 14);
    self.PvPTalentToggle.ButtonText:SetText(L["PvP"]);
    self.PvPTalentToggle:SetScript("OnClick", function(f)
        self.PvPTalentFrame:Toggle();
    end);

    self.DisplayModeButton1 = TextButtonUtil:CreateButton(self, "left", "left", "vertical", 40, "inspectNode");
    self.DisplayModeButton1:SetFrameLevel(frameLevel + 14);
    self.DisplayModeButton1:Hide();
    InspectDisplayModeUtil:SetupButton(self.DisplayModeButton1, 1);
    self.DisplayModeButton2 = TextButtonUtil:CreateButton(self, "left", "left", "vertical", 40, "diffNode");
    self.DisplayModeButton2:SetFrameLevel(frameLevel + 14);
    self.DisplayModeButton2:Hide();
    InspectDisplayModeUtil:SetupButton(self.DisplayModeButton2, 2);
    InspectDisplayModeUtil:SelectButton(1);

    self.SettingsButton = TextButtonUtil:CreateButton(self.SideTab, "left", "left", "horizontal", nil, "cog");
    self.SettingsButton.ButtonText:SetText(SETTINGS or "Settings");
    self.SettingsButton:SetPoint("BOTTOMLEFT", self.SideTab, "BOTTOMLEFT", 16, 16);
    self.SettingsButton:SetScript("OnClick", function()
        if not NarciSettingsFrame:IsShown() then
            NarciSettingsFrame:ShowUI("talentTree", true, "talents");
        end
    end);

    self.ShareToggle = TextButtonUtil:CreateButton(self.SideTab, "left", "left", "horizontal", nil, "share");
    self.ShareToggle.ButtonText:SetText(L["Share"]);
    self.ShareToggle:SetPoint("BOTTOMLEFT", self.SideTab, "BOTTOMLEFT", 16, 48);
    self.ShareToggle:SetScript("OnClick", function(f)
        f:Hide();
        self.SideTab:TakeClipboard(true);
    end);

    local SaveButton = TextButtonUtil:CreateButton(self.SideTab, "left", "center", "horizontal", nil, "plus");
    SaveButton.anchor = self.SideTab.InspectTab.LoadoutNameEditBox;
    self.SaveButton = SaveButton;
    self.SideTab.InspectTab.LoadoutNameEditBox.SaveButton = SaveButton;
    SaveButton.ButtonText:SetText(L["Save"]);
    SaveButton:SetPoint("TOP", SaveButton.anchor, "BOTTOM", 0, -8);
    SaveButton:Hide();

    function SaveButton:CaseValid()
        self:Enable();
        self.ButtonText:SetText(L["Save"]);
        TextButtonUtil:SetButtonIcon(self, "plus");
        TextButtonUtil:SetButtonColor(self, 0.5, 0.5, 0.5);
    end

    function SaveButton:CaseDuplicate()
        self:Disable();
        self.ButtonText:SetText("Duplicate Name");
        TextButtonUtil:SetButtonIcon(self, "cross");
        TextButtonUtil:SetButtonColor(self, 1, 0.31, 0.31);
    end

    function SaveButton:CaseSaved()
        self:Disable();
        self.ButtonText:SetText("Saved");
        TextButtonUtil:SetButtonIcon(self, "check");
        TextButtonUtil:SetButtonColor(self, 0.4862, 0.7725, 0.4627);
    end

    SaveButton:SetScript("OnClick", function(f)
        local loadoutName = SaveButton.anchor:GetText();
        local result, errorString = DataProvider:SaveInpsectLoadout(loadoutName);
        if result then
            f:CaseSaved();
        else
            f:Disable();
            f.ButtonText:SetText(errorString);
        end
    end);

    self.AnimationFrame.ShockwaveMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Full", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST");
    self.AnimationFrame:Hide();
    self.AnimationFrame:SetScript("OnUpdate", function(f, elapsed)
        f.t = f.t + elapsed;
        if f.t > 2 then
            f:Hide();
            f.t = nil;
        end
    end);
end

function NarciMiniTalentTreeMixin:Init()
    if self.PvPTalentFrame:IsWarModeActive() then
        self.PvPTalentFrame:Toggle();
    end
    self.Init = nil;
end

function NarciMiniTalentTreeMixin:ShowActiveBuild()
    local configID = DataProvider:GetSelecetdConfigID();
    DataProvider:SetPlayerActiveConfigID(configID);
    self:ShowConfig(configID);
end

local function IsValidEntryType(entryType)
    return entryType == nil or entryType == 0 or entryType == 1 or entryType == 2
end

local function IsValidNodeInfo(nodeInfo)
    return (nodeInfo) and (nodeInfo.type ~= 3) and (nodeInfo.isVisible) and (nodeInfo.posY >= 0) and (not nodeInfo.subTreeID)
end

local function IsSubTreeNode(nodeInfo, activeSubTreeID)
    if nodeInfo and nodeInfo.isVisible and nodeInfo.subTreeID then
        if activeSubTreeID then
            return nodeInfo.subTreeID == activeSubTreeID
        else
            return true
        end
    end
end

local function SortFunc_SubTreeNode(a, b)
    if a.posY ~= b.posY then
        return a.posY > b.posY
    end

    return a.posX < b.posX
end

function NarciMiniTalentTreeMixin:ShowConfig(configID, isPreviewing)
    if not configID then return end;

    if not( (self.isDirty) or (configID ~= self.configID) ) then
        return
    end
    self.configID = configID;
    self.isDirty = nil;

    local isInspecting = self:IsInspecting() and (configID == INPSECT_CONFIG_ID);
    local canShowComparison = isInspecting and DataProvider:IsInpsectSameSpec();
    local comparisonMode = self.showTalentDifferences and canShowComparison;   --if the inspected unit and player have the same spec

    InspectDisplayModeUtil:SetButtonVisibility(canShowComparison);

    self:ReleaseAllNodes();

    local specID = DataProvider:GetCurrentSpecID();
    local configInfo = C_Traits.GetConfigInfo(configID);

    if not configInfo then
        return
    end

    local treeID = configInfo.treeIDs[1]
	local nodeIDs = C_Traits.GetTreeNodes(treeID);
    self.treeID = treeID;

    local activeSubTreeID;

    local node, nodeInfo, activeEntryID, entryInfo, entryType, iX, iY, isLeftSide;
    local GetNodeInfo, GetEntryInfo;
    local borderColor;

    if isInspecting then
        borderColor = 2;
        GetNodeInfo = DataProvider.GetComparisonNodeInfo;
        GetEntryInfo = DataProvider.GetComparisonEntryInfo;
        activeSubTreeID = DataProvider:GetInspectActiveSubTreeID();
    else
        borderColor = 1;
        DataProvider:SetPlayerActiveConfigID(configID);
        GetNodeInfo = DataProvider.GetPlayerNodeInfo;
        GetEntryInfo = DataProvider.GetPlayerEntryInfo;
        activeSubTreeID = DataProvider:GetPlayerActiveSubTreeID();
    end


    if not comparisonMode then
        for i, nodeID in ipairs(nodeIDs) do
            nodeInfo = GetNodeInfo(nodeID);

            if IsValidNodeInfo(nodeInfo) then   ----Dracthyr has a Button that is out-of-bound for some reason
                activeEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID or nil;
                entryInfo = (activeEntryID ~= nil) and GetEntryInfo(activeEntryID) or nil;
                entryType = (entryInfo ~= nil) and entryInfo.type or nil;

                if IsValidEntryType(entryType) then
                    node = self:AcquireNode();
                    node:SetBorderColor(borderColor);
                
                    iX, iY, isLeftSide = CalculateNormalizedPosition(nodeInfo.posX, nodeInfo.posY);
                
                    if (nodeInfo.ranksPurchased > 0) or (nodeInfo.activeRank > 0) or (DataProvider:IsAutoGrantedTalent(nodeID)) then
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
                            node.Icon:SetTexture(nil);
                        end
                    else
                        node.entryIDs = nil;
                        if entryType == 0 then
                            --*Warrior Why do some passive traits use this type?
                            node:SetNodeType(1, 0);
                        elseif entryType == 1 then --square
                            node:SetNodeType(0, 1);
                        elseif entryType == 2 then --circle
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
                            --print(entryType, "Unknown type")
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
            end
        end

        self:CreateBranches(nodeIDs);

    else
        local playerNodeInfo, playerEntryInfo, playerEntryID;
        local GetPlayerNodeInfo = DataProvider.GetPlayerNodeInfo;
        local GetPlayerEntryInfo = DataProvider.GetPlayerEntryInfo;
        local playerRank, targetRank;
        local playerChoice, targetChoice;
        local nodeTypeID;   --custom value

        for i, nodeID in ipairs(nodeIDs) do
            nodeInfo = GetNodeInfo(nodeID);
            playerNodeInfo = GetPlayerNodeInfo(nodeID);

            if IsValidNodeInfo(nodeInfo) then   ----Dracthyr has a Button that is out-of-bound for some reason
                activeEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID or nil;
                entryInfo = (activeEntryID ~= nil) and GetEntryInfo(activeEntryID) or nil;
                entryType = (entryInfo ~= nil) and entryInfo.type or nil;
            
                if IsValidEntryType(entryType) then
                    playerEntryID = playerNodeInfo.activeEntry and playerNodeInfo.activeEntry.entryID or nil;
                    playerEntryInfo = (playerEntryID ~= nil) and GetPlayerEntryInfo(playerEntryID) or nil;

                    node = self:AcquireNode();
                    iX, iY, isLeftSide = CalculateNormalizedPosition(nodeInfo.posX, nodeInfo.posY);
                
                    targetRank = nodeInfo.ranksPurchased or 0;
                    playerRank = playerNodeInfo.ranksPurchased or 0;

                    if DataProvider:IsAutoGrantedTalent(nodeID) then
                        targetRank = 1;
                        playerRank = 1;
                    end

                    if targetRank == playerRank then
                        node.active = nil;
                        node.currentRank = targetRank;
                    else
                        if nodeInfo.ranksPurchased == 0 then
                            node.currentRank = 1;
                        else
                            node.currentRank = nodeInfo.ranksPurchased;
                        end
                        node.active = (targetRank > 0) or (playerRank > 0);
                    end
                    node:SetBorderColor(3);

                    node.maxRanks = nodeInfo.maxRanks;
                
                    LayoutUtil:SetNodeTileIndex(node, isLeftSide, iX, iY);
                
                    NodeIDxNode[nodeID] = node;
                
                    if nodeInfo.type == 2 then
                        node.entryIDs = nodeInfo.entryIDs;
                        if activeEntryID == nodeInfo.entryIDs[1] then
                            targetChoice = 1;
                        elseif activeEntryID == nodeInfo.entryIDs[2] then
                            targetChoice = 2;
                        else
                            targetChoice = 0;
                        end

                        if playerEntryID == playerNodeInfo.entryIDs[1] then
                            playerChoice = 1;
                        elseif playerEntryID == playerNodeInfo.entryIDs[2] then
                            playerChoice = 2;
                        else
                            playerChoice = 0;
                        end

                        if targetChoice ~= playerChoice and targetChoice ~= 0 then
                            node.active = true;
                        end

                        node:SetComparison(2, targetChoice, playerChoice);
                        if targetChoice == 0 and playerChoice ~= 0 and playerEntryInfo then
                            node:SetDefinitionID(playerEntryInfo.definitionID);
                        end
                    else
                        node.entryIDs = nil;
                        if entryType == 0 then
                            nodeTypeID = 1;
                        elseif entryType == 1 then --square
                            nodeTypeID = 0;
                        elseif entryType == 2 then --circle
                            nodeTypeID = 1;
                        else
                            nodeTypeID = 2;
                            --nil is unselected octagon
                            node.Symbol:SetVertexColor(1, 0, 0);
                            --print(entryType, "Unknown type")
                        end

                        node:SetComparison(nodeTypeID, targetRank, playerRank);
                    end

                    if node.active then
                        node.Symbol:SetVertexColor(0.67, 0.67, 0.67);
                        node.IconBorder:SetDesaturated(false);
                        node.IconBorder:SetVertexColor(1, 1, 1);
                        node.Icon:SetDesaturation(0.5);
                        node.Icon:SetVertexColor(0.67, 0.67, 0.67);
                        node.isActive = nil;
                    else
                        node.Symbol:SetVertexColor(0.160, 0.160, 0.160);
                        node:SetActive(false);
                    end

                    if entryInfo then
                        node:SetDefinitionID(entryInfo.definitionID);
                    end
                
                    node.nodeID = nodeID;
                    node.entryID = activeEntryID;
                    node.rank = targetRank;
                    
                    if playerRank == 0 and targetRank == 0 then
                        node.Icon:SetTexture(nil);
                    end
                end
            end
        end

        self:RemoveBranches();
    end

    local middleX, middleY = LayoutUtil:UpdateNodePosition();


    --Subtree
    local subTreeNodes;

    for i, nodeID in ipairs(nodeIDs) do
        nodeInfo = GetNodeInfo(nodeID);
        if IsSubTreeNode(nodeInfo, activeSubTreeID) then
        --Only Show Choice Node
            if nodeInfo.type == 2 then
                activeEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID;
                if activeEntryID then
                    entryInfo = GetEntryInfo(activeEntryID);
                    if entryInfo and entryInfo.definitionID then
                        if not subTreeNodes then
                            subTreeNodes = {};
                        end

                        table.insert(subTreeNodes, {
                            nodeID = nodeID,
                            entryID = activeEntryID;
                            entryIDs = nodeInfo.entryIDs,
                            definitionID = entryInfo.definitionID,
                            selectLeft = activeEntryID == nodeInfo.entryIDs[1],
                            posX = nodeInfo.posX,
                            posY = nodeInfo.posY,
                        });
                    end
                end
            end
        end
    end

    if subTreeNodes then
        table.sort(subTreeNodes, SortFunc_SubTreeNode);

        local tileSize = BUTTON_SIZE;

        for i, nodeData in ipairs(subTreeNodes) do
            --print(i, DataProvider:GetTraitNameByDefinitionID(nodeData.definitionID));
            node = self:AcquireNode();
            node:SetBorderColor(borderColor);
            node:SetPoint("TOP", self, "TOPLEFT", middleX, middleY + (1- i)*tileSize);

            if nodeData.selectLeft then
                node:SetNodeType(2, 1);
            else
                node:SetNodeType(2, 2);
            end

            node.nodeID = nodeData.nodeID;
            node.entryID = nodeData.entryID;
            node.entryIDs = nodeData.entryIDs;
            node.rank = 1;
            node.currentRank = 1;
            node.maxRanks = 1;
            node:SetDefinitionID(nodeData.definitionID);
            node:SetActive(true);
        end

        self.Divider:Hide();
    else
        self.Divider:Show();
    end

    if not isPreviewing and not isInspecting then
        UniversalFont:SetText(self.LoadoutToggle.ButtonText, DataProvider:GetActiveLoadoutName());
        self.SideTab:SetSelectedSpec(specID);
        LoadoutUtil:SetSelectedConfigID(DataProvider:GetSelecetdConfigID());
        LoadingBarUtil:HideBar();
        self:SetSpecBackground(specID);
    end
end

function NarciMiniTalentTreeMixin:SetSpecBackground(specID)
    if not USE_CLASS_BACKGROUND then return end;
    if specID ~= self.bgID then
        self.bgID = specID;
        self.HeaderLight:Hide();
        local bgFile, blurFile = TextureUtil:GetSpecBackground(specID);
        self.SpecArt:SetTexture(bgFile);
        self.SideTab.ClipFrame.SpecArt:SetTexture(blurFile);
    end
end

function NarciMiniTalentTreeMixin:ShowInspecting(inspectUnit)
    self.inspectUnit = inspectUnit;
    self:SetInspectMode(true);
    DataProvider:ClearComparisonCache();
    DataProvider:SetPlayerActiveConfigID();
    self.configID = nil;
    self:ShowConfig(INPSECT_CONFIG_ID);
end

function NarciMiniTalentTreeMixin:SetInspectDisplayMode(id)
    if id ~= 1 and id ~= 2 then
        id = 1;
    end
    InspectDisplayModeUtil:SelectButton(id);

    --id:  1.Show Target Talents Only  2.Show Difference
    local showDiff = (id == 2) or nil;
    if showDiff ~= self.showTalentDifferences then
        self.showTalentDifferences = showDiff;
        if self:IsInspecting() then
            self:ShowInspecting( self:GetInspectUnit() );
        end
    end
end

function NarciMiniTalentTreeMixin:SetInspectMode(state)
    if state then
        DataProvider:SetInspectMode(true);
        self.SideTabToggle:Hide();
        self.LoadoutToggle:Disable();
        self.LoadoutToggle.Icon:Hide();
        LoadingBarUtil:HideBar();
        if self.SideTab:IsShown() then
            self.SideTab:CloseFrame(true);
        end
        
        if self.PvPTalentFrame:IsShown() then
            self.PvPTalentFrame:Update();
        end

        local loadoutName;
        local unit = self:GetInspectUnit();
        local playerName = UnitName(unit);
        local specID = GetInspectSpecialization(unit);
		local classDisplayName, class = UnitClass(unit);
        playerName = playerName or "Unknown Player";

		if specID then
            local sex = UnitSex(unit);
			local _, specName = GetSpecializationInfoByID(specID, sex);
            --loadoutName = specName.." "..classDisplayName.." - "..playerName;
            loadoutName = classDisplayName.." - "..playerName;
            self.SideTabToggle:Show();
            self.SideTabToggle.ButtonText:SetText(specName);
            self:SetSpecBackground(specID);
        else
            loadoutName = playerName;   --TALENTS_INSPECT_FORMAT
		end
        UniversalFont:SetText(self.LoadoutToggle.ButtonText, loadoutName);
        SetBranchColor = SetBranchColorCyan;
        DataProvider:SetInspectSpecID(specID);
        self.SideTab:SetMode("inspect", DataProvider:IsInpsectSameSpec());
        self.ShareToggle:Hide();
        TextButtonUtil:SetButtonIcon(self.SideTabToggle, "share");

    elseif self:IsInspecting() then
        DataProvider:SetInspectMode(false);
        self.inspectUnit = nil;
        self.SideTabToggle:Show();
        self.LoadoutToggle:Enable();
        self.LoadoutToggle.Icon:Show();
        UniversalFont:SetText(self.LoadoutToggle.ButtonText, DataProvider:GetActiveLoadoutName());
        self.SideTabToggle.ButtonText:SetText(DataProvider:GetCurrentSpecName());
        if self.PvPTalentFrame:IsShown() then
            self.PvPTalentFrame:Update();
        end
        SetBranchColor = SetBranchColorYellow;
        self.SideTab:SetMode("class");
        self.ShareToggle:Show();
        TextButtonUtil:SetButtonIcon(self.SideTabToggle, "arrowRight");
    end

    --self.MacroForge:HideFrame();
end

function NarciMiniTalentTreeMixin:ReleaseAllNodes()
    for i = 1, #Nodes do
        Nodes[i]:Hide();
        Nodes[i]:ClearAllPoints();
    end
    self.numAcitveNodes = 0;

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

--[[
local BranchUpdater = CreateFrame("Frame");

local MAX_PROCESS_PER_FRAME = 400;

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

--]]

local function PlayActivationAnimationAfterDelay(self, elapsed)
    self.animT = self.animT + elapsed;
    if self.activationAnimDelay then
        if self.animT >= self.activationAnimDelay then
            self:SetScript("OnUpdate", nil);
            self.activationAnimDelay = nil;
            self.animT = nil;
            MainFrame:PlayActivationAnimation();
        end
    else
        self:SetScript("OnUpdate", nil);
    end

end

local function BranchUpdater_OnUpdate_OneFrame(self, elapsed)
    self:SetScript("OnUpdate", self.nextOnUpdateFunc);
    for i = 1, #Branches do
        Branches[i]:Hide();
        Branches[i]:ClearAllPoints();
    end

    local nodeIDs = self.nodeIDs;

    local numBranches = 0;
    local fromIndex = 1;
    local numNodes = #nodeIDs;
    local nodeID, nodeInfo;
    local fromNode, targetNode;
    local x1, y1, x2, y2, d, rd, b;
    local bchs = Branches;
    local SZH = BUTTON_SIZE_HALF;
    local container = MainFrame;

    local GetNodeInfo = DataProvider.GetNodeInfo;
    local sqrt = sqrt;
    local atan2 = atan2;
    local SetBranchColor = SetBranchColor;

    while fromIndex <= numNodes do
        nodeID = nodeIDs[fromIndex];
        nodeInfo = GetNodeInfo(nodeID);

        if nodeInfo then
            fromNode = NodeIDxNode[nodeID];
            if fromNode then
                for j, edgeVisualInfo in ipairs(nodeInfo.visibleEdges) do
                    targetNode = NodeIDxNode[edgeVisualInfo.targetNode];
                    if targetNode then
                        numBranches = numBranches + 1;
                        b = bchs[numBranches];
                        if not b then
                            b = container:CreateTexture(nil, "OVERLAY");
                            bchs[numBranches] = b;
                            b:SetHeight(BRANCH_WEIGHT);
                            b:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\Branch");
                        end
                        x1, y1 = fromNode.x + SZH, fromNode.y - SZH;
                        x2, y2 = targetNode.x + SZH, targetNode.y - SZH;
                        d = sqrt( (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) );
                        rd = atan2(y2 - y1, x2 - x1);
                        b:SetWidth(d);
                        b:ClearAllPoints();
                        b:SetPoint("CENTER", container, "TOPLEFT", (x1+x2)*0.5, (y1+y2)*0.5);
                        b:SetRotation(rd);
                        b:Show();
                        SetBranchColor(b, fromNode.active and targetNode.active);
                    end
                end
            end
        end

        fromIndex = fromIndex + 1;
    end

    self.nodeIDs = nil;
    LayoutUtil:ClearTemps();
end


function NarciMiniTalentTreeMixin:CreateBranches(nodeIDs)
    self.nodeIDs = nodeIDs;

    if self.activationAnimDelay then
        self.animT = 0;
        self.nextOnUpdateFunc = PlayActivationAnimationAfterDelay;
    else
        self.nextOnUpdateFunc = nil;
    end

    self:SetScript("OnUpdate", BranchUpdater_OnUpdate_OneFrame);
end

function NarciMiniTalentTreeMixin:RemoveBranches()
    self:SetScript("OnUpdate", nil);
    self.nodeIDs = nil;
    for i = 1, #Branches do
        Branches[i]:Hide();
        Branches[i]:ClearAllPoints();
    end
end

function NarciMiniTalentTreeMixin:RequestUpdate()
    self.isDirty = true;
    if not self:IsInspecting() then
        if self:IsVisible() then
            self:ShowActiveBuild();
        else
            local configID = DataProvider:GetSelecetdConfigID();
            DataProvider:SetPlayerActiveConfigID(configID);
        end
    end
    --ActionBarUtil:RequestUpdate();
end

function NarciMiniTalentTreeMixin:OnShow()
    if self.Init then
        self:Init();
    end
    DataProvider:StopCacheWipingCountdown();
    --EventCenter:RegisterEvent("CURSOR_CHANGED");
    EventCenter:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");

    self:RegisterEvent("PLAYER_STARTED_MOVING");
    self:RegisterEvent("PLAYER_STOPPED_MOVING");
    self:RegisterEvent("PLAYER_STARTED_LOOKING");
    self:RegisterEvent("PLAYER_STOPPED_LOOKING");
    self:RegisterEvent("PLAYER_STARTED_TURNING");
    self:RegisterEvent("PLAYER_STOPPED_TURNING");
    
    if ShouldHideBackground() then
        self:SetBackgroundAlpha(0);
        self:EnableMouse(false);
    else
        self:SetBackgroundAlpha(1);
        self:EnableMouse(true);
    end
end

function NarciMiniTalentTreeMixin:OnHide()
    self.activationAnimDelay = nil;
    DataProvider:StartCacheWipingCountdown();
    --EventCenter:UnregisterEvent("CURSOR_CHANGED");
    EventCenter:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");

    self:UnregisterEvent("PLAYER_STARTED_MOVING");
    self:UnregisterEvent("PLAYER_STOPPED_MOVING");
    self:RegisterEvent("PLAYER_STARTED_LOOKING");
    self:RegisterEvent("PLAYER_STOPPED_LOOKING");
    self:RegisterEvent("PLAYER_STARTED_TURNING");
    self:RegisterEvent("PLAYER_STOPPED_TURNING");
    self:SetFading(false);
end

function NarciMiniTalentTreeMixin:IsInspecting()
    return self.inspectUnit ~= nil
end

function NarciMiniTalentTreeMixin:GetInspectUnit()
    return self.inspectUnit;
end


local function SetPixelPerfectPosition(frame, relativeTo)
    if relativeTo then
        frame:ClearAllPoints();
        local position = frame.position;
        if position == "bottom" then
            local offsetV = 32;
            local bottom0 = relativeTo:GetBottom();
            local bottom1 = floor( (bottom0 - offsetV) * PIXEL) / PIXEL;
            frame:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, bottom1 - bottom0);
        else
            local offsetH;
            if frame.offsetH then
                offsetH = frame.offsetH * UIParent:GetEffectiveScale();
            else
                offsetH = 4;
            end
            local right0 = relativeTo:GetRight();
            local right1 = floor( (right0 + offsetH) * PIXEL + 0.5) / PIXEL;
            local top0 = relativeTo:GetTop();
            local top1 = floor( (top0 + 0) * PIXEL) / PIXEL;
            frame:SetPoint("TOPLEFT", relativeTo, "TOPRIGHT", right1 - right0, top1 - top0);
        end
    end
end

function NarciMiniTalentTreeMixin:AnchorToInspectFrame()
    self.anchor = "inspectframe";
    local f = InspectFrame;
    if f and f:IsShown() and f.unit then
        SetPixelPerfectPosition(self, f);
        self:Show();
        self:ShowInspecting(f.unit);
        self:SetFrameStrata("HIGH");
        self:SetToplevel(false);
    else
        self:Hide();
    end
end

function NarciMiniTalentTreeMixin:AnchorToPaperDoll()
    self.anchor = "paperdoll";
    self:SetFrameStrata("MEDIUM");
    self:SetToplevel(false);
    local f = PaperDollFrame;
    if f and f:IsShown() then
        SetPixelPerfectPosition(self, f);
    else
        self:Hide();
    end
end

function NarciMiniTalentTreeMixin:SetUseClassBackground(state)
    if state ~= USE_CLASS_BACKGROUND then
        USE_CLASS_BACKGROUND = state;

        if state then
            local specID = DataProvider:GetCurrentSpecID();
            self.HeaderLight:Hide();
            local bgFile, blurFile = TextureUtil:GetSpecBackground(specID);
            self.SpecArt:SetTexture(bgFile);
            self.SideTab.ClipFrame.SpecArt:SetTexture(blurFile);
            self.SideTab.FullFrameOverlay:SetColorTexture(0, 0, 0, 0.5);
            self.SideTab.Shadow:SetColorTexture(0, 0, 0);
            self.LoadoutDropdown.FullFrameOverlay:SetColorTexture(0, 0, 0, 0.5);
            self.LoadoutDropdown.Background:SetVertexColor(0, 0, 0);
            if self.LoadoutToggle then
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.LoadoutToggle, 0.8, 1);
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.SideTabToggle, 0.8, 1);
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.PvPTalentToggle, 0.8, 1);
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.SettingsButton, 0.67, 0.92);
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.ShareToggle, 0.67, 0.92);
            end
        else
            self.HeaderLight:Show();
            self.SpecArt:SetTexture(nil);
            self.SideTab.ClipFrame.SpecArt:SetTexture(nil);
            self.SideTab.FullFrameOverlay:SetColorTexture(0.1, 0.1, 0.1, 0.5);
            self.SideTab.Shadow:SetColorTexture(0.08, 0.08, 0.08);
            self.LoadoutDropdown.FullFrameOverlay:SetColorTexture(0.1, 0.1, 0.1, 0.5);
            self.LoadoutDropdown.Background:SetVertexColor(0.1, 0.1, 0.1);
            if self.LoadoutToggle then
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.LoadoutToggle, 0.67, 0.92);
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.SideTabToggle, 0.5, 0.92);
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.PvPTalentToggle, 0.5, 0.92);
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.SettingsButton, 0.5, 0.92);
                TextButtonUtil:SetButtonNormalAndHiglightColor(self.ShareToggle, 0.5, 0.92);
            end
        end

        ClassTalentTooltipUtil:SetUseClassBackground(state);
    end

    self.Background:SetShown(not state);
end

function NarciMiniTalentTreeMixin:RaiseActiveNodesFrameLevel(state)
    if not state then state = nil end;
    if state == self.isNodeRaised then
        return
    else
        self.isNodeRaised  = state
    end

    local baseLevel = self:GetFrameLevel() + 1;
    local activeLevel;

    if state then
        --activeLevel = self.MacroForge.MotionBlocker:GetFrameLevel() + 1;
        NodeUtil:SetModePickIcon();
    else
        activeLevel = baseLevel;
        NodeUtil:SetModeNormal();
    end

    for i, node in ipairs(Nodes) do
        if node.isActive then
            node:SetFrameLevel(activeLevel);
        else
            node:SetFrameLevel(baseLevel);
        end
    end
end

function NarciMiniTalentTreeMixin:SetFramePosition(position)
    if position == "bottom" then
        self.position = "bottom";
    else
        self.position = "right";
    end

    if self:IsShown() then
        if self.anchor == "inspectframe" then
            self:AnchorToInspectFrame();
        elseif self.anchor == "paperdoll" then
            self:AnchorToPaperDoll();
        end
    end
end

function NarciMiniTalentTreeMixin:PlayActivationAnimation()
    self.AnimationFrame:StopAnimating();
    if not self:IsVisible() then
        self.AnimationFrame:Hide();
        return
    end
    self.AnimationFrame.t = 0;
    self.AnimationFrame:Show();

    local sqrt = sqrt;
    local node, highlight;
    local n = 0;
    for i = 1, self.numAcitveNodes do
        node = Nodes[i];
        if node.isActive and node.iX and node.iY then
            n = n + 1;
            highlight = NodeHighlights[n];
            if not highlight then
                highlight = self.AnimationFrame:CreateTexture(nil, "OVERLAY", "NarciTalentTreeNodeHighlightTemplate");
                highlight:SetSize(2*BUTTON_SIZE, 2*BUTTON_SIZE);
                NodeHighlights[n] = highlight;
            end
            if node.typeID == 0 then
                highlight:SetTexCoord(0.5, 1, 0, 0.5); --square
            elseif node.typeID == 2 then
                highlight:SetTexCoord(0, 0.5, 0.5, 1); --octagon
            else
                highlight:SetTexCoord(0, 0.5, 0, 0.5); --circle
            end
            highlight:ClearAllPoints();
            highlight:SetPoint("CENTER", node, "CENTER", 0, 0);
            highlight.Glow.AnimDelay:SetStartDelay(sqrt( (node.iX - 9)*(node.iX - 9) + (node.iY - 5)*(node.iY - 5)) * 0.05);
            highlight.Glow:Play();
            highlight:Show();
        end
    end
    self.AnimationFrame.ActivationShockwave.AnimIn:Play();
    self.AnimationFrame.ActivationShockwave:Show();

    for i = n + 1, #NodeHighlights do
        NodeHighlights[i]:Hide();
    end
end


function NarciMiniTalentTreeMixin:SetUseBiggerUI(larger)
    TextureUtil:UpdateWidgetSize(larger);
    LayoutUtil:UpdatePixel();
    if self:IsVisible() then
        self:RequestUpdate();
    else
        self.isDirty = true;
    end
end

function NarciMiniTalentTreeMixin:OnEvent(event, ...)
    if event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STARTED_LOOKING" or event == "PLAYER_STARTED_TURNING" then
        self:SetFading(-4);
    elseif event == "PLAYER_STOPPED_MOVING" or event == "PLAYER_STOPPED_LOOKING" or event == "PLAYER_STOPPED_TURNING" then
        if not ShouldHideBackground() then
            self:SetFading(4);
        end
    end
end

local FadingFrame = CreateFrame("Frame");
FadingFrame:Hide();
FadingFrame:SetScript("OnUpdate", function(self, elapsed)
    self.alpha = self.alpha + self.delta * elapsed;
    if self.alpha >= 1 then
        self.alpha = 1;
        self:Hide();
    elseif self.alpha <= 0 then
        self.alpha = 0;
        self:Hide();
    end
    MainFrame:SetBackgroundAlpha(self.alpha);
end);

function NarciMiniTalentTreeMixin:SetFading(delta)
    if delta then
        if delta > 0 then
            FadingFrame.delta = 4;
            self:EnableMouse(true);
        elseif delta < 0 then
            FadingFrame.delta = -4;
            self:EnableMouse(false);
        else
            return
        end
        FadingFrame.alpha = self.Background:GetAlpha();
        FadingFrame:Show();
    else
        FadingFrame:Hide();
        self:SetBackgroundAlpha(1);
        self:EnableMouse(true);
    end
end

function NarciMiniTalentTreeMixin:SetBackgroundAlpha(alpha)
    self.Background:SetAlpha(alpha);
    self.SpecArt:SetAlpha(alpha);
end

function NarciMiniTalentTreeMixin:OnSwitchLoadoutFailed(reason)
    self:RequestUpdate();
end

NarciTalentTreeLoadoutButtonMixin = {};

function NarciTalentTreeLoadoutButtonMixin:OnEnter()
    if not self.selected then
        self.ButtonText:SetTextColor(1, 1, 1);
    end

    if self.configID then
        OnEnterDelay:WatchButton(self);
    end
end

function NarciTalentTreeLoadoutButtonMixin:OnEnterCallback()
    if self.configID then
        MainFrame:ShowConfig(self.configID, true);
    end
end

function NarciTalentTreeLoadoutButtonMixin:OnLeave()
    if not self.selected then
        self.ButtonText:SetTextColor(0.67, 0.67, 0.67);
    end
    OnEnterDelay:ClearWatch();
end


local function AttemptToApplyConfig(configIDToLoad)
    if not configIDToLoad then return end;
    MainFrame.lastConfigID = DataProvider:GetSelecetdConfigID();

    if not ClassTalentFrame then
		ClassTalentFrame_LoadUI();
	end

    if ClassTalentFrame then
        ClassTalentFrame.TalentsTab:LoadConfigByPredicate(function(_, configID)
            return configID == configIDToLoad;
        end);
    else
        MainFrame.lastConfigID = DataProvider:GetSelecetdConfigID();
        local autoApply = true;
        local result = C_ClassTalents.LoadConfig(configIDToLoad, autoApply);
        if result ~= 0 then
            local currentSpecID = DataProvider:GetCurrentSpecID();
            C_ClassTalents.UpdateLastSelectedSavedConfigID(currentSpecID, configIDToLoad);
        end
        return result
    end
end

Narci.AC = AttemptToApplyConfig;    --Name Shorten to be used in macro 


function NarciTalentTreeLoadoutButtonMixin:OnClick()
    if self.selected then

    else
        if self.configID and (ClassTalentHelper and ClassTalentHelper.SwitchToLoadoutByIndex) then
            MainFrame.lastConfigID = DataProvider:GetSelecetdConfigID();
            if ClassTalentHelper and ClassTalentHelper.SwitchToLoadoutByIndex then
                ClassTalentHelper.SwitchToLoadoutByIndex(self.index);
            end
            --Talent swap may not succeed due to abilities in cooldown, but "ClassTalentHelper" itself doesn't return anything
            --We check if loading start after 1s
            LoadingBarUtil:SetFromLoadoutToggle(MainFrame.LoadoutToggle);
        end
    end
    LoadoutUtil:HideList();
end

function NarciTalentTreeLoadoutButtonMixin:SetConfigID(configID)
    self.configID = configID;

    local name = DataProvider:GetConfigName(configID);
    if name then
        self.ButtonText:SetText(name);
        self.Underline:SetWidth(self.ButtonText:GetWrappedWidth());
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

    local configs = DataProvider:GetConfigIDs();
    local button;

    for i = 1, #configs do
        button = self.buttons[i];
        if not button then
            button = CreateFrame("Button", nil, self.container, "NarciTalentTreeLoadoutButtonTemplate");
            self.buttons[i] = button;
            button.index = i;
            button.ButtonText:SetFont(self.font, FONT_HEIGHT, "");
            button:SetPoint("TOP", MainFrame.LoadoutToggle, "TOP", 0, self.buttonHeight*( - i));
            button:SetHeight(self.buttonHeight);
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

        local selectedConfigID = DataProvider:GetSelecetdConfigID();
        if selectedConfigID then
            self:SetSelectedConfigID(selectedConfigID);
        end

        return true
    else
        self.container:SetHeight(64);

        return false
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
    if LoadingBarUtil:IsBarVisible() then
        return
    end

    if self.Init then
        self:Init();
    end

    local anyLoadout = self:UpdateList();

    if self.activeButton then
        self.activeButton.Underline.AnimIn:Stop();
        self.activeButton.Underline.AnimIn:Play();
    end

    self.container:Show();
    self.container.alpha = 0;
    self.container:SetScript("OnUpdate", self.ShowFrame_OnUpdate);

    if anyLoadout then
        MainFrame.LoadoutToggle.ButtonText:SetText(L["Loadout"]);
    else
        MainFrame.LoadoutToggle.ButtonText:SetText(L["No Loadout"]);
    end
    MainFrame.LoadoutToggle.Icon:SetTexCoord(0.25, 0.5, 0.25, 0);
end

function LoadoutUtil:HideList()
    self.container:Hide();
    MainFrame.LoadoutToggle.Icon:SetTexCoord(0.25, 0.5, 0, 0.25);

    if not LoadingBarUtil:IsBarVisible() then
        UniversalFont:SetText(MainFrame.LoadoutToggle.ButtonText, DataProvider:GetActiveLoadoutName());
        MainFrame:ShowActiveBuild();
    end
end

function LoadoutUtil:ToggleList()
    if self.container and self.container:IsShown() then
        self:HideList();
    else
        self:ShowList();
    end
end

function LoadoutUtil:SetSelectedConfigID(configID)
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
    if self.isDirty then
        self:Update();
    end
end

function NarciTalentTreePvPFrameMixin:RequestUpdate()
    if self:IsShown() then
        self:Update();
    else
        self.isDirty = true;
    end
end

function NarciTalentTreePvPFrameMixin:IsWarModeActive()
    return C_PvP.IsWarModeDesired() or C_PvP.IsWarModeActive()
end

function NarciTalentTreePvPFrameMixin:Update()
    self:Init();

    self.isDirty = nil;

    local talentID, talentInfo;

    if MainFrame:IsInspecting() then
        local unit = MainFrame:GetInspectUnit();
        for i = 1, 3 do
            talentID = C_SpecializationInfo.GetInspectSelectedPvpTalent(unit, i);
            self.slots[i]:SetPvPTalent(talentID, unit);
            self.slots[i]:Show();
            self.slots[i].isInspecting = true;
            self.slots[i]:SetBorderColor(2);
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
            self.slots[i]:SetBorderColor(1);
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
            slot.isPvp = true;

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

function NarciTalentTreePvPFrameMixin:Toggle()
    if self:IsShown() then
        self:Hide();
        MainFrame.PvPTalentToggle.Icon:SetTexCoord(0, 0.125, 0, 0.25);
    else
        self:Show();
        MainFrame.PvPTalentToggle.Icon:SetTexCoord(0.125, 0.25, 0, 0.25);
    end
    LayoutUtil:UpdateFrameSize();
end

function NarciTalentTreePvPFrameMixin:UpdatePixel()
    if self.slots then
        for i, slot in ipairs(self.slots) do
            slot.Icon:SetSize(ICON_SIZE, ICON_SIZE);
            slot:SetSize(BUTTON_SIZE, BUTTON_SIZE);
            if i <= 3 then
                slot:SetPoint("TOP", self, "TOP", 0, -HEADER_SIZE -(i + 1) * BUTTON_SIZE);
            else
                slot:SetPoint("TOP", self, "TOP", 0, -HEADER_SIZE -(i + 3) * BUTTON_SIZE);
            end
        end
    end
    self:SetWidth(BUTTON_SIZE * 3);
    self.Divider:ClearAllPoints();
    self.Divider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -BUTTON_SIZE/2 -HEADER_SIZE);
    self.Divider:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, BUTTON_SIZE/2);
end



local CreateKeyChordStringUsingMetaKeyState = CreateKeyChordStringUsingMetaKeyState;

local function Clipboard_OnKeyDown(self, key)
    local keys = CreateKeyChordStringUsingMetaKeyState(key);
    if keys == "CTRL-C" or key == "COMMAND-C" then
        self:SetScript("OnKeyDown", nil);
        C_Timer.After(0, function()
            self.Label:SetText(L["String Copied"]);
            self.Label:StopAnimating();
            self.Label.FadeOut:Play();
            self:ClearFocus();
        end);
    end
end

local function LoadoutEditBox_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 1 then
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        self:ShowLoadingIndicator(false);
        self.SaveButton:Show();
        local text = self:GetText();
        if DataProvider:IsLoadoutNameValid(text) then
            self.SaveButton:CaseValid();
        else
            self.SaveButton:CaseDuplicate();
        end
    end
end

local function LoadoutEditBox_OnTextChanged(self, isUserInput)
    if isUserInput then
        if not self.t then
            self.t = 0;
            self.SaveButton:Hide();
            self:SetScript("OnUpdate", LoadoutEditBox_OnUpdate);
            self:ShowLoadingIndicator(true);
        end
        self.t = 0
    end
end

local function LoadoutEditBox_OnHide(self)
    self:SetScript("OnUpdate", nil);
    self.t = nil;
    self.SaveButton:Hide();
end

NarciTalentTreeSharedEditBoxMixin = {};


function NarciTalentTreeSharedEditBoxMixin:OnLoad()
    table.insert(LayoutUtil.editboxes, self);
    self.Exclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");

    if self.widgetType == "clipboard" then
        self.isClipboard = true;
        self:SetScript("OnTextChanged", NarciTalentTreeSharedEditBoxMixin.OnTextChanged_Forbidden);
        self:SetScript("OnCursorChanged", NarciTalentTreeSharedEditBoxMixin.OnCursorChanged_Forbidden);
        self:SetPropagateKeyboardInput(false);

        local function LabelFadingComplete()
            self.Label:SetText("Copy As Text");
            self.Label.FadeIn:Play();
        end
        self.Label.FadeOut:SetScript("OnFinished", LabelFadingComplete);

    elseif self.widgetType == "inputbox" then
        self.LoadingIndicator:ClearAllPoints();
        self.LoadingIndicator:SetPoint("LEFT", self, "LEFT", 4, 0);
        self:SetMaxLetters(30);
        self:SetScript("OnTextChanged", LoadoutEditBox_OnTextChanged);
        self:SetScript("OnHide", LoadoutEditBox_OnHide);
    end

    if self.unfocusedLabel then
        self:SetLabelText(self.unfocusedLabel);
    end
    if self.defaultTextKey and L[self.defaultTextKey] then
        self.DefaultText:SetText(L[self.defaultTextKey]);
        self.defaultTextKey = nil;
    end
    self.hitOffset = 0;
end

function NarciTalentTreeSharedEditBoxMixin:OnEnter()
    if not self:HasFocus() then
        self:SetStrokeGrayscale(0.4);
        self.Label:SetTextColor(0.67, 0.67, 0.67);
    end
end

function NarciTalentTreeSharedEditBoxMixin:OnLeave()
    if not self:HasFocus() then
        self:SetStrokeGrayscale(0.25);
        self.Label:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciTalentTreeSharedEditBoxMixin:SetStrokeColor(r, g, b)
    self.Border:SetColorTexture(r, g, b);
end

function NarciTalentTreeSharedEditBoxMixin:SetStrokeGrayscale(a)
    self.Border:SetColorTexture(a, a, a);
end

function NarciTalentTreeSharedEditBoxMixin:OnEscapePressed()
    self:ClearFocus();
end

function NarciTalentTreeSharedEditBoxMixin:OnEnterPressed()
    if self.ConfirmChange then
        self.ConfirmChange(self:GetText());
    end
    self:ClearFocus();
end

function NarciTalentTreeSharedEditBoxMixin:OnEditFocusGained()
    self:HighlightText();
    self:SetTextColor(0.92, 0.92, 0.92);
    self:SetStrokeColor(0.05, 0.41, 0.85);
    self.DefaultText:Hide();
    if self.isClipboard then
        self:SetScript("OnKeyDown", Clipboard_OnKeyDown);
        self.Label:StopAnimating();
        self.Label:SetText(L["Press To Copy"]);
    end
end

function NarciTalentTreeSharedEditBoxMixin:OnEditFocusLost()
    self:HighlightText(0, 0);
    self:SetTextColor(0.5, 0.5, 0.5);

    if self.isClipboard then
        if self.copiedText then
            self:SetText(self.copiedText);
        else
            self.DefaultText:Show();
        end
        if not self.Label.FadeOut:IsPlaying() then
            self.Label:SetText("Copy As Text");
        end
    else
        if not string.find(self:GetText(), "%S") then
            self.DefaultText:Show();
        end
    end

    if self:IsMouseOver(self.hitOffset, 0, 0, 0) then
        self:OnEnter();
    else
        self:OnLeave();
    end

    self:SetScript("OnKeyDown", nil);
end

function NarciTalentTreeSharedEditBoxMixin.OnTextChanged_Forbidden(self, isUserInput)
    if isUserInput then
        self:ClearFocus();
    end
end

function NarciTalentTreeSharedEditBoxMixin.OnCursorChanged_Forbidden(self)
    if self:HasFocus() then
        self:HighlightText();
    end
end

function NarciTalentTreeSharedEditBoxMixin:SetLabelText(text, r, g, b)
    self.Label:SetText(text);
    if self.Label:IsTruncated() then
        self.labelPixelHeight = 14;
        local font = self.Label:GetFont();
        local height = PIXEL * self.labelPixelHeight;
        self.Label:SetFont(font, height, "");
    end
    if r and g and b then
        self.Label:SetTextColor(r, g, b);
    end
end

function NarciTalentTreeSharedEditBoxMixin:SetLabelText(text, r, g, b)
    self.Label:SetText(text);
    if r and g and b then
        self.Label:SetTextColor(r, g, b);
    end
end

function NarciTalentTreeSharedEditBoxMixin:UpdatePixel(px)
    self:SetWidth(176*px);
    self:SetHeight(24*px);
    local font = self.Label:GetFont();
    self.Label:SetFont(font, (self.labelPixelHeight or 16)*px, "");
    self:SetFont(font, 16*px, "");
    self.DefaultText:SetFont(font, 16*px, "");
    self.Label:SetPoint("BOTTOM", self, "TOP", 0, 4);
    self.Label:SetWidth(168*px);
    self.Exclusion:SetPoint("TOPLEFT", px, -px);
    self.Exclusion:SetPoint("BOTTOMRIGHT", -px, px);

    if self.LoadingIndicator then
        self.LoadingIndicator:SetSize(16*px, 16*px);
        if self.widgetType == "inputbox" then
            self.LoadingIndicator:SetPoint("LEFT", self, "LEFT", 4*px, 0);
        end
    end

    local effectiveHitHeight = 24;
    local verticalCompensation = (16*px - effectiveHitHeight);  --upwards
    if verticalCompensation > 0 then
        verticalCompensation = 0;
    end
    self:SetHitRectInsets(0, 0, verticalCompensation, 0);
    self.hitOffset = -verticalCompensation;
end

function NarciTalentTreeSharedEditBoxMixin:SetOnFocusGainedCallback(callback)
    self.OonFocusGainedCallback = callback;
end

function NarciTalentTreeSharedEditBoxMixin:ShowLoadingIndicator(state)
    if self.LoadingIndicator then
        if state then
            self.LoadingIndicator.AnimSpin:Play();
            self.LoadingIndicator:Show();
        else
            self.LoadingIndicator.AnimSpin:Stop();
            self.LoadingIndicator:Hide();
        end
    end
end

function NarciTalentTreeSharedEditBoxMixin:ResetState()
    self:SetText("");
    self.DefaultText:Show();
    if self.SaveButton then
        self.SaveButton:Hide();
    end
end


EventCenter:RegisterEvent("PLAYER_ENTERING_WORLD");
EventCenter:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");
EventCenter:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED");
EventCenter:RegisterEvent("TRAIT_CONFIG_UPDATED");
EventCenter:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED");
EventCenter:RegisterEvent("TRAIT_CONFIG_DELETED");
EventCenter:RegisterEvent("TRAIT_CONFIG_CREATED");
EventCenter:RegisterEvent("CONFIG_COMMIT_FAILED");
EventCenter:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED");

EventCenter.onUpdate = function(self, elapsed)
    self:SetScript("OnUpdate", nil);
    if self.onUpdateCallback then
        self.onUpdateCallback(MainFrame);
    end
end


--[[
function EventCenter:RegisterDynamicEvents(state)
    if state then
        for i, event in ipairs(self.dynamicEvents) do
            self:RegisterEvent(event);
        end
    else
        for i, event in ipairs(self.dynamicEvents) do
            self:UnregisterEvent(event);
        end
    end
end

EventCenter.dynamicEvents = {
    "TRAIT_TREE_CHANGED", "TRAIT_NODE_CHANGED", "TRAIT_NODE_CHANGED_PARTIAL", "TRAIT_NODE_ENTRY_UPDATED", "TRAIT_CONFIG_UPDATED", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "CONFIG_COMMIT_FAILED",

    --TRAIT_NODE_CHANGED: Fires multiple times when cancel switching talent
    --TRAIT_TREE_CHANGED: After clicking a loadout
    --TRAIT_CONFIG_UPDATED: After successfully changing loadout
    --ACTIVE_PLAYER_SPECIALIZATION_CHANGED: followed by TRAIT_CONFIG_UPDATED
};
--]]


EventCenter.onEvent = function(self, event, ...)
    if event == "TRAIT_CONFIG_UPDATED" or event == "TRAIT_CONFIG_LIST_UPDATED" or event == "TRAIT_CONFIG_DELETED" or event == "TRAIT_CONFIG_CREATED" then
        DataProvider:RefreshConfigIDs();
        self.onUpdateCallback = MainFrame.RequestUpdate;
        self:SetScript("OnUpdate", self.onUpdate);

        if event == "TRAIT_CONFIG_CREATED" then
            local configInfo = ...;
            if configInfo and configInfo.type == 1 then
                --Enum.TraitConfigType.Combat
                DataProvider:MarkConfigIDValid(configInfo.ID, true);
            end
        elseif event == "TRAIT_CONFIG_DELETED" then
            local configID = ...;
            DataProvider:MarkConfigIDValid(configID, false);
        end

    elseif event == "CONFIG_COMMIT_FAILED" then
        if MainFrame.lastConfigID then
            local currentSpecID = DataProvider:GetCurrentSpecID();
            local result = C_ClassTalents.LoadConfig( MainFrame.lastConfigID, true);
            C_ClassTalents.UpdateLastSelectedSavedConfigID(currentSpecID, MainFrame.lastConfigID);
            MainFrame.lastConfigID = nil;
        end
        self.onUpdateCallback = MainFrame.RequestUpdate;
        self:SetScript("OnUpdate", self.onUpdate);

    elseif event == "ACTIVE_COMBAT_CONFIG_CHANGED" then
        local configID = ...;

    elseif event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
        if MainFrame.SideTab:IsShown() then
            MainFrame.SideTab:CloseFrame();
        end
        DataProvider:UpdateSpecInfo();
        DataProvider:RefreshConfigIDs();
        MainFrame:RequestUpdate();
        MainFrame.PvPTalentFrame:RequestUpdate();
        MainFrame.SideTabToggle.ButtonText:SetText(DataProvider:GetCurrentSpecName());
        CAN_USE_TALENT_UI = CanPlayerUseTalentSpecUI();

    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        self:RegisterEvent("UI_SCALE_CHANGED");
        self.onEvent(self, "ACTIVE_PLAYER_SPECIALIZATION_CHANGED");
        LayoutUtil:UpdatePixel();

        --AddOn Compatibility
        if C_AddOns.IsAddOnLoaded("TinyInspect") or C_AddOns.IsAddOnLoaded("TinyInspect-Reforged") then
            MainFrame.offsetH = 328 + 2;
        end

    elseif event == "UI_SCALE_CHANGED" then
        LayoutUtil:UpdatePixel();

    elseif event == "PLAYER_PVP_TALENT_UPDATE" then
        MainFrame.PvPTalentFrame:RequestUpdate();

    elseif event == "CURSOR_CHANGED" then
        --MainFrame.MacroForge:OnCursorChanged(...);

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local spellID = select(3, ...);
        if spellID then
            if IsSpecializationActivateSpell(spellID) then
                MainFrame.activationAnimDelay = 0.4;    --use delay for spec change coz game freezes shortly
            elseif spellID == 384255 then
                MainFrame.activationAnimDelay = 0;
            end
        end
    end

    --[[
        if event == "TRAIT_TREE_CHANGED" then

        elseif event == "TRAIT_NODE_CHANGED" then

        elseif event == "TRAIT_NODE_CHANGED_PARTIAL" then

        elseif event == "TRAIT_NODE_ENTRY_UPDATED" then

        else

        end
    --]]
end

EventCenter:SetScript("OnEvent", EventCenter.onEvent);




if not addon.IsDragonflight() then return end;


local ENABLE_INSPECT = false;
local ENABLE_PAPERDOLL = false;
local ENABLE_EQUIPMENT_MANAGER = false;
local HookUtil = {};

function HookUtil:HookInpsectFrame()
    if self.inspectFrameHooked then return end;

    local InspectFrame = _G["InspectFrame"];

    if InspectFrame then
        self.inspectFrameHooked = true;
        InspectFrame:HookScript("OnShow", function()
            if ENABLE_INSPECT and InspectFrame.unit and UnitLevel(InspectFrame.unit) >= 10 then
                MainFrame:AnchorToInspectFrame();
                MainFrame:Show();
                MainFrame:ShowInspecting(InspectFrame.unit);
            end
        end);

        InspectFrame:HookScript("OnHide", function()
            MainFrame:Hide();
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
                    if ENABLE_INSPECT and InspectFrame.unit and UnitLevel(InspectFrame.unit) >= 10 then
                        MainFrame:AnchorToInspectFrame();
                    end
                end);
    
                InspectFrame:HookScript("OnHide", function()
                    MainFrame:Hide();
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
        if ENABLE_PAPERDOLL and CAN_USE_TALENT_UI then
            MainFrame:AnchorToPaperDoll();
            MainFrame:SetInspectMode(false);
            MainFrame:Show();
            MainFrame:ShowActiveBuild();
        end
    end);

    PaperDoll:HookScript("OnHide", function()
        if ENABLE_INSPECT then
            MainFrame:AnchorToInspectFrame();
        else
            MainFrame:Hide();
        end
    end);
end

function HookUtil:HookEquipmentManager()
    if self.equipmentManageHooked then return end;
    self.equipmentManageHooked = true;
    local f = PaperDollFrame and PaperDollFrame.EquipmentManagerPane;
    if not f then return end;

    f:HookScript("OnShow", function()
        if ENABLE_EQUIPMENT_MANAGER and CAN_USE_TALENT_UI then
            MainFrame:AnchorToPaperDoll();
            MainFrame:SetInspectMode(false);
            MainFrame:Show();
            MainFrame:ShowActiveBuild();
        end
    end);

    f:HookScript("OnHide", function()
        if ENABLE_PAPERDOLL and CAN_USE_TALENT_UI then
            MainFrame:AnchorToPaperDoll();
            MainFrame:SetInspectMode(false);
            MainFrame:Show();
            MainFrame:ShowActiveBuild();
        else
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

    function SettingFunctions.ShowMiniTalentTreeForEquipmentManager(state, db)
        if state == nil then
            state = db["TalentTreeForEquipmentManager"];
        end
        if state then
            ENABLE_EQUIPMENT_MANAGER = true;
            HookUtil:HookEquipmentManager();
        else
            ENABLE_EQUIPMENT_MANAGER = false;
            if MainFrame.anchor == "paperdoll" then
                MainFrame:Hide();
            end
        end
    end

    function SettingFunctions.SetUseClassBackground(state, db)
        if state == nil then
            state = db["TalentTreeUseClassBackground"];
        end
        MainFrame:SetUseClassBackground(state);
    end

    function SettingFunctions.SetUseBiggerUI(state, db)
        if state == nil then
            state = db["TalentTreeBiggerUI"];
        end
        MainFrame:SetUseBiggerUI(state);
    end

    function SettingFunctions.SetTalentTreePosition(id, db)
        if id == nil then
            id = db["TalentTreeAnchor"];
        end
        local anchor;
        if id == 2 then
            anchor = "bottom";
        else
            anchor = "right";
        end
        MainFrame:SetFramePosition(anchor);
    end
end

--[[
local gsub = string.gsub;
function TestEmojiEditBox_OnTextChanged(self, isUserInput)
    if isUserInput then
        local text = self:GetText();
        text = gsub(text, " 1", "|cffa05548 1|r");
        text = gsub(text, " 2", "|cffa6c7dd 2|r");
        text = gsub(text, " 3", "|cffffd655 3|r");
        text = gsub(text, " 4", "|cff33ffcc 4|r");
        text = gsub(text, " 5", "|cffff931e 5|r");
        self:SetText(text);
    end
end
--]]