local _, addon = ...

local GetRaidRosterInfo = GetRaidRosterInfo;
local GetNumGroupMembers = GetNumGroupMembers;
local NotifyInspect = NotifyInspect;
local UnitGUID = UnitGUID;
local UnitExists = UnitExists;
local ClearInspectPlayer = ClearInspectPlayer;
local UnitIsPlayer = UnitIsPlayer;
local CanInspect = CanInspect;
local GetInventoryItemTexture = GetInventoryItemTexture;
local GetInventoryItemLink = GetInventoryItemLink;
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo;
local GetItemInfoInstant = GetItemInfoInstant;
local CreateFrame = CreateFrame;
local gsub = string.gsub;

local IsItemProgenitorSet = NarciAPI.IsItemProgenitorSet;
local GetInspectEncounterCount = addon.GetInspectEncounterCount;


local MainFrame, MouseOverFrame, Tooltip;

local TAB_HEIGHT = 32;
local ITEM_SIZE = 24;
local ITEM_PADDING = 4;
local PIXEL = NarciAPI.GetScreenPixelSize();

local GUID_CACHE = {};

local EQUIPMENT_ORDER = {
    1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17
};

local function ShortenPlayerGUID(guid)
    if guid then
        guid = string.match(guid, "Player%-%d+%-(.+)");
        return guid --tonumber(guid, 16);
    end
end

local function RemoveServerName(playerName)
    return playerName and gsub(playerName, "-.+", "");
end

local function Delay_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        self:SetScript("OnUpdate", nil);
        if self.delayCallback then
            self:delayCallback();
        end
    end
end

local function Shared_OnDragStart()
    MainFrame:StartMoving();
    Tooltip:Hide();
end

local function Shared_OnDragStop()
    MainFrame:StopMovingOrSizing();
end

local function SetUpFrameForDrag(f)
    f:RegisterForDrag("LeftButton");
    f:SetScript("OnDragStart", Shared_OnDragStart);
    f:SetScript("OnDragStop", Shared_OnDragStop);
end


local ItemOutlinePool = {};

function ItemOutlinePool:Acquire()
    if not self.frames then
        self.frames = {};
        self.liveFrames = {};
        self.deadFrames = {};
        self.total = 0;
        self.numLive = 0;
        self.numDead = 0;
    end
    local f;
    if self.numDead > 0 then
        f = self.deadFrames[self.numDead];
        self.deadFrames[self.numDead] = nil;
        self.numDead = self.numDead - 1;
    else
        self.total = self.total + 1;
        self.frames[self.total] = CreateFrame("Frame", nil, MainFrame, "NarciRaidCheckItemOutlineTemplate");
        f = self.frames[self.total];
    end
    self.numLive = self.numLive + 1;
    f:ClearAllPoints();
    f:Show();
    return f
end

function ItemOutlinePool:KillFrame(frame)
    frame:Hide();
    frame:ClearAllPoints();
    self.numLive = self.numLive - 1;
    self.numDead = self.numDead + 1;
    self.deadFrames[self.numDead] = frame;
end

function ItemOutlinePool:GetTotalFrames()
    return self.total
end



local DataProvider = {};

function DataProvider:Wipe()
    self.dataByGUID = {};
    self.displayedOrder = {};
end

function DataProvider:CreatePlayerData(guid)
    if not self.dataByGUID[guid] then
        self.dataByGUID[guid] = {
            ["items"] = {},
        };
    end
end

function DataProvider:SetPlayerItemData(guid, slotID, itemLink)
    self:CreatePlayerData(guid);
    if not (self.dataByGUID[guid]["items"][slotID] and self.dataByGUID[guid]["items"][slotID].itemLink) then
        self.dataByGUID[guid]["items"][slotID] = {
            itemLink = itemLink,
            itemID = itemLink and GetItemInfoInstant(itemLink),
            level = itemLink and GetDetailedItemLevelInfo(itemLink),
        };
    end
end

function DataProvider:GetPlayerItemData(guid, slotID)
    if self.dataByGUID[guid] then
        return self.dataByGUID[guid]["items"][slotID]
    end
end

function DataProvider:GetPlayerItemLink(guid, slotID)
    if self.dataByGUID[guid] then
        return self.dataByGUID[guid]["items"][slotID] and self.dataByGUID[guid]["items"][slotID].itemLink
    end
end

function DataProvider:GetPlayerItemID(guid, slotID)
    if self.dataByGUID[guid] then
        return self.dataByGUID[guid]["items"][slotID] and self.dataByGUID[guid]["items"][slotID].itemID
    end
end

function DataProvider:CalculatePlayerAverageItemLevel(guid)
    if self.dataByGUID[guid] then
        if not self.dataByGUID[guid].averageLevel then
            local sum = 0;
            local numItems = 0;
            local items = self.dataByGUID[guid]["items"];
            for slot, data in pairs(items) do
                sum = sum + (data.level or 0);
                numItems = numItems + 1;
            end
            self.dataByGUID[guid].averageLevel = (numItems > 0 and math.floor(sum/numItems * 1000 + 0.5)/1000) or 0;
        end
        return self.dataByGUID[guid].averageLevel
    end
end


NarciRaidCheckFrameMixin = {};

function NarciRaidCheckFrameMixin:OnLoad()
    MainFrame = self;
    MouseOverFrame = self.MouseOverFrame;
    Tooltip = self.Tooltip;
    --Tooltip:SetClampRectInsets(2, 2, 2, 2);

    SetUpFrameForDrag(self);
    SetUpFrameForDrag(self.MouseOverFrame);

    DataProvider:Wipe();
end

function NarciRaidCheckFrameMixin:OnHide()

end

function NarciRaidCheckFrameMixin:OnMouseUp(button)
    if button == "RightButton" then
        self:Hide();
    end
end

function NarciRaidCheckFrameMixin:AcquireFrame()
    if not self.frames then
        self.frames = {};
        self.numActive = 0;
    end
    local i = self.numActive + 1;
    self.numActive = i;
    if not self.frames[i] then
        self.frames[i] = CreateFrame("Frame", nil, self, "NarciRaidCheckMemberFrameTemplate");
        self.frames[i]:SetPoint("TOPLEFT", self, "TOPLEFT", 0, TAB_HEIGHT * PIXEL * (1 - i));
        self.frames[i]:SetFrameID(i);
    end
    self.frames[i]:Show();
    return self.frames[i];
end

function NarciRaidCheckFrameMixin:GetFrameByIndex(i)
    return self.frames[i];
end

function NarciRaidCheckFrameMixin:ReleaseFrames()
    if self.frames then
        for i = 1, #self.frames do
            self.frames[i]:Hide();
        end
    end
    self.numActive = 0;
end

function NarciRaidCheckFrameMixin:UpdateRoster()
    self:ReleaseFrames();
    local numPeople = GetNumGroupMembers();
    local f;
    local name, rank, subgroup, level, class, fileName, zone, online;
    for i = 1, numPeople do
        name, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo(i);
        if name then
            f = self:AcquireFrame();
            f.PlayerName:SetText(RemoveServerName(name));
        end
    end
    self:SetHeight(16 * math.max(self.numActive, 1));
    self.memberIndex = 0;
    self:CheckNextMember();
end

local function UnitIsValid(unit)
    return UnitExists(unit) and CanInspect(unit)
end

function NarciRaidCheckFrameMixin:CheckNextMember()
    local i, unit;
    while self.memberIndex <= self.numActive do
        i = self.memberIndex + 1;
        self.memberIndex = i;
        unit = "raid"..i;
        if UnitIsValid(unit) then
            break
        end
    end
    if i <= self.numActive and UnitIsValid(unit) then
        self.targetGUID = UnitGUID(unit);
        self.targetUnit = unit;
        self:RegisterEvent("INSPECT_READY");
        NotifyInspect(unit);
    else
        self:StopChecking();
    end
end

function NarciRaidCheckFrameMixin:StopChecking()
    self:UnregisterEvent("INSPECT_READY");
end

function NarciRaidCheckFrameMixin:OnEvent(event, ...)
    if event == "INSPECT_READY" then
        self:OnInspectionReady(...);
    end
    if event =="INSPECT_ACHIEVEMENT_READY" then
        self:OnAchievementReady(...);
    end
    if event == "PLAYER_TARGET_CHANGED" then
        self:OnTargetChanged();
    end
end

function NarciRaidCheckFrameMixin:OnInspectionReady(guid)
    if guid == self.targetGUID then
        self.t = -0.1;
        self.delayCallback = self.ProcessInspectedPlayer;
        self:SetScript("OnUpdate", Delay_OnUpdate);
    end
end

function NarciRaidCheckFrameMixin:OnAchievementReady(guid)
    if guid == self.targetGUID then
        local f = self:GetFrameByIndex(self.memberIndex);
        f.BossCount:SetText(GetInspectEncounterCount());
    end
end

function NarciRaidCheckFrameMixin:ProcessInspectedPlayer()
    self:UnregisterEvent("INSPECT_READY");
    local unit = self.targetUnit;
    local guid = self.targetGUID;

    local f = self:GetFrameByIndex(self.memberIndex);
    f.guid = guid;

    local slotID, link;
    local complete = true;
    for i = 1, #EQUIPMENT_ORDER do
        slotID = EQUIPMENT_ORDER[i];
        link = GetInventoryItemLink(unit, slotID);
        if link then
            link =  string.match(link, "(item:[%-?%d:]+)");
        end
        DataProvider:SetPlayerItemData(guid, slotID, link);
        complete = (f:SetMemberItem(i, slotID, GetInventoryItemTexture(unit, slotID), link)) and complete;
        if not complete then
            break
        end
    end

    if complete then
        f:OnItemLoadingComplete();
        ClearInspectPlayer();
        self.delayCallback = nil;
    else
        self.t = -0.15;
        self.delayCallback = self.ProcessInspectedPlayer;
    end
    self:SetScript("OnUpdate", Delay_OnUpdate);
end

function NarciRaidCheckFrameMixin:CheckTarget()
    local unit = "target";
    if UnitIsValid(unit) then
        self:ReleaseFrames();
        local f = self:AcquireFrame();
        local _, classFilename = UnitClass(unit);
        f.PlayerName:SetText( RemoveServerName( UnitName(unit) ));
        f.PlayerName:SetTextColor( GetClassColor(classFilename) )
        self.memberIndex = 1;
        self.targetGUID = UnitGUID(unit);
        self.targetUnit = unit;
        self:RegisterEvent("INSPECT_READY");
        NotifyInspect(unit);
    end
end

function NarciRaidCheckFrameMixin:InspectUnitAchievements(unit)
    ClearAchievementComparisonUnit();
    self:RegisterEvent("INSPECT_ACHIEVEMENT_READY");
    SetAchievementComparisonUnit(unit);
end

function NarciRaidCheckFrameMixin:CheckNewTarget()
    local unit = "target";
    if UnitIsValid(unit) then
        if not self.memberIndex then
            self.memberIndex = 0;
        end
        local f = self:AcquireFrame();
        local _, classFilename = UnitClass(unit);
        local guid = UnitGUID(unit);
        f.guid = guid;
        f.PlayerName:SetText( RemoveServerName( UnitName(unit) ));
        f.PlayerName:SetTextColor( GetClassColor(classFilename) );
        self.memberIndex = self.memberIndex + 1;
        self.targetGUID = guid;
        self.targetUnit = unit;
        self:RegisterEvent("INSPECT_READY");
        NotifyInspect(unit);
        self:InspectUnitAchievements(unit);
    end
end

function NarciRaidCheckFrameMixin:OnTargetChanged()
    local unit = "target";
    if UnitIsValid(unit) then
        local guid = UnitGUID(unit);
        guid = ShortenPlayerGUID(guid);
        if not GUID_CACHE[guid] then
            GUID_CACHE[guid] = true;
            self:CheckNewTarget();
        end
    end
end

function NarciRaidCheckFrameMixin:SetManualCheck(state)
    if state then
        self:Show();
        self:RegisterEvent("PLAYER_TARGET_CHANGED");
    else
        self:UnregisterEvent("PLAYER_TARGET_CHANGED");
    end
end

local function Tooltip_ShowItem(anchor, itemLink)
    Tooltip:Hide();
    if itemLink then
        Tooltip:SetOwner(anchor, "ANCHOR_NONE");
        Tooltip:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2);
        Tooltip:SetHyperlink(itemLink);
        Tooltip:SetFrameStrata("DIALOG");
        Tooltip:Show();
    end
end

function Tooltip_ShowUnit(unit)
    if unit and UnitExists(unit) then
        Tooltip:SetHyperlink(string.format("unit:%s", UnitGUID(unit)));
        Tooltip:Show();
    else
        Tooltip:Hide();
    end
end

local function MemberFrame_OnEnter(self)
    MouseOverFrame:ClearAllPoints();
    MouseOverFrame:SetParent(self);
    MouseOverFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
    MouseOverFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
    MouseOverFrame:Show();
end

local function MemberFrame_OnLeave(self)
    if not self:IsMouseOver() then
        MouseOverFrame:Hide();
    end
end

local function MemberFrame_OnMouseUp(self)
    MainFrame:Hide();
end

local function ItemButton_OnEnter(self)
    self.Icon:SetVertexColor(1, 1, 1);
    Tooltip_ShowItem(self, DataProvider:GetPlayerItemLink(self:GetParent().guid, self.slotID));
    MemberFrame_OnEnter(self:GetParent());
end

local function ItemButton_Leave(self)
    if self.isLoaded then
        self.Icon:SetVertexColor(0.67, 0.67, 0.67);
    else
        self.Icon:SetVertexColor(0.67, 0.25, 0.25);
    end
    Tooltip:Hide();
    MemberFrame_OnLeave(self:GetParent());
end



NarciRaidCheckMemberFrameMixin = {};

function NarciRaidCheckMemberFrameMixin:OnLoad()
    self:SetHeight(TAB_HEIGHT * PIXEL);
    self.SpecIcon:SetSize(ITEM_SIZE * PIXEL, ITEM_SIZE * PIXEL);
    self.SpecIcon:SetPoint("LEFT", self, "LEFT", ITEM_PADDING * PIXEL, 0);
    self.PlayerName:SetPoint("LEFT", self, "LEFT", (ITEM_SIZE + 2 * ITEM_PADDING) * PIXEL, 0);
    local width = (ITEM_SIZE + 2 * ITEM_PADDING) * PIXEL + 120;
    self.leftWidth = width;
    self:SetWidth(width + (ITEM_SIZE + ITEM_PADDING) * PIXEL * 16);

    self:SetScript("OnEnter", MemberFrame_OnEnter);
    self:SetScript("OnLeave", MemberFrame_OnLeave);
    self:SetScript("OnMouseUp", MemberFrame_OnMouseUp);

    SetUpFrameForDrag(self);
end

function NarciRaidCheckMemberFrameMixin:SetFrameID(id)
    self.id = id;
    if id % 2 == 1 then
        self.Background:SetColorTexture(0.1, 0.1, 0.1);
    else
        self.Background:SetColorTexture(0.13, 0.13, 0.13);
    end
end

function NarciRaidCheckMemberFrameMixin:SetMemberItem(id, slotID, texture, itemLink)
    if not self.itemButtons then
        self.itemButtons = {};
    end
    if not self.itemButtons[id] then
        self.itemButtons[id] = CreateFrame("Button", nil, self);
        local f = self.itemButtons[id];
        local a = ITEM_SIZE*PIXEL;
        f.id = id;
        f.slotID = slotID;
        SetUpFrameForDrag(f);
        f:SetScript("OnEnter", ItemButton_OnEnter);
        f:SetScript("OnLeave", ItemButton_Leave);
        f:SetSize(a, a);
        f:SetPoint("LEFT", self, "LEFT", self.leftWidth + ( (ITEM_SIZE + ITEM_PADDING) * PIXEL * (id - 1)), 0);
        f.Icon = f:CreateTexture(nil, "OVERLAY");
        f.Icon:SetSize(a, a);
        f.Icon:SetPoint("CENTER", f, "CENTER", 0, 0);
        f.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);
    end
    self.itemButtons[id].Icon:SetTexture(texture);
    --self.itemButtons[id].itemLink = itemLink;
    local isLoaded = itemLink ~= nil;
    if isLoaded then
        self.itemButtons[id].Icon:SetVertexColor(0.67, 0.67, 0.67);
    else
        self.itemButtons[id].Icon:SetVertexColor(0.67, 0.25, 0.25);
    end
    self.itemButtons[id].isLoaded = isLoaded;
    return (not texture) or (texture and isLoaded)
end

function NarciRaidCheckMemberFrameMixin:OnItemLoadingComplete()
    --Release item outlines
    if self.outlines then
        for i = 1, #self.outlines do
            ItemOutlinePool:KillFrame(self.outlines[i]);
        end
    end
    self.outlines = {};
    local itemID;
    local numOwned = 0;
    local guid = self.guid;
    local outline, slotID;
    for i = 1, #EQUIPMENT_ORDER do
        if self.itemButtons[i] and self.itemButtons[i].isLoaded then
            slotID = EQUIPMENT_ORDER[i];
            itemID = DataProvider:GetPlayerItemID(guid, slotID);
            if IsItemProgenitorSet(itemID) then
                numOwned = numOwned + 1;
                outline = ItemOutlinePool:Acquire();
                outline:SetParent(self.itemButtons[i]);
                outline:SetPoint("CENTER", self.itemButtons[i], "CENTER", 0, 0);
                outline.Exclusion:SetSize(ITEM_SIZE*PIXEL, ITEM_SIZE*PIXEL);
                outline.Selection:SetSize((ITEM_SIZE + 2)*PIXEL, (ITEM_SIZE + 2)*PIXEL);
                self.outlines[numOwned] = outline;
            end
        end
    end
    self.ItemCount:SetText(math.floor( DataProvider:CalculatePlayerAverageItemLevel(guid) + 0.25 ));  --average item level

    local unit = MainFrame.targetUnit;
    local specID = GetInspectSpecialization(unit);
	local _, specName, specIcon;
	if specID then
		_, specName, _, specIcon = GetSpecializationInfoByID(specID, UnitSex(unit));
	end
    self.SpecIcon:SetTexture(specIcon);
end

--[[
    /run NarciRaidCheckFrame:UpdateRoster()
    /run NarciRaidCheckFrame:CheckTarget()
    /run NarciRaidCheckFrame:SetManualCheck(true)
    /run NarciRaidCheckTooltip:SetHyperlink(format("unit:%s", UnitGUID("target")));
    name, rank, subgroup, level, class, fileName, 
  zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex);
GROUP_ROSTER_UPDATE
--]]