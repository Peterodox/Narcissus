local _, addon = ...
local TransmogUIManager = {};
addon.TransmogUIManager = TransmogUIManager;
TransmogUIManager.modules = {};


local CallbackRegistry = addon.CallbackRegistry;
local TransmogDataProvider = addon.TransmogDataProvider;
local GetSourceInfo = C_TransmogCollection.GetSourceInfo;
local GetAppearanceInfoBySource = C_TransmogCollection.GetAppearanceInfoBySource;
local GetTransmogOutfitSlotFromInventorySlot = C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot;
local IsAppearanceHiddenVisual = C_TransmogCollection.IsAppearanceHiddenVisual;
local SetPendingTransmog =  C_TransmogOutfitInfo and C_TransmogOutfitInfo.SetPendingTransmog;
local ipairs = ipairs;
local Enum = Enum;


local SharedModuleMixin = {};
do
    function SharedModuleMixin:OnLoad()

    end

    function SharedModuleMixin:AddNewObject(obj)
        if not self.newObjects then
            self.newObjects = {};
        end
        table.insert(self.newObjects, obj);
    end

    function SharedModuleMixin:Disable()
        if self.newObjects then
            for _, obj in ipairs(self.newObjects) do
                obj:Hide();
            end
        end

        if self.OnDisable then
            self:OnDisable();
        end
    end
end


function TransmogUIManager:CreateModule(key)
    local module = {};
    Mixin(module, SharedModuleMixin);
    module.moduleKey = key;
    table.insert(self.modules, module);
    return module
end

function TransmogUIManager:LoadModules()
    if not NarciTransmogUIDB then
        NarciTransmogUIDB = {};
    end

    if not NarciTransmogUIDB.SharedSets then
        NarciTransmogUIDB.SharedSets = {};
    end

    for _, module in ipairs(self.modules) do
        module:OnLoad();
    end
end

local function ConverInvSlotToTransmogSlot(invSlotID)
    return GetTransmogOutfitSlotFromInventorySlot(invSlotID - 1)
end


local IgnoredInvSlots = {
    [2]  = true,
    [11] = true,
    [12] = true,
    [13] = true,
    [14] = true,
    [18] = true,    --Ranged Slot
};

local TransmogInvSlots = {
    1, 3, 15, 5, 4, 19, 9,
    10, 6, 7, 8,
    16, 17,
};


local function ApplyTransmog(invSlotID, slot, transmogID, illusionID)
    local transmogType, option, displayType;

    --if invSlotID == 16 or invSlotID == 17 then
    --    option = C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot(slot);
    --    SetPendingTransmog(slot, Enum.TransmogType.Appearance, option, 0, Enum.TransmogOutfitDisplayType.Unassigned);
    --end

    if not option then
        option = Enum.TransmogOutfitSlotOption.None;
    end

    if illusionID then
        transmogType = Enum.TransmogType.Illusion;
        local typeKey;
        if illusionID == 0 then
            typeKey = "Unassigned";
        else
            typeKey = "Assigned";
        end
        displayType = Enum.TransmogOutfitDisplayType[typeKey] or 1;
        SetPendingTransmog(slot, transmogType, option, illusionID, displayType);
    end

    transmogType = Enum.TransmogType.Appearance;

    local isHiddenVisual;
    if IsAppearanceHiddenVisual(transmogID) or transmogID == 0 then
        displayType = Enum.TransmogOutfitDisplayType.Hidden;
        isHiddenVisual = true;
    else
        displayType = Enum.TransmogOutfitDisplayType.Assigned;
    end

    if isHiddenVisual then
        if transmogID == 0 then
            transmogID = TransmogDataProvider.GetHiddenSourceIDForSlot(invSlotID) or transmogID;
        end
    end

    if slot and transmogID then
        SetPendingTransmog(slot, transmogType, option, transmogID, displayType);
    else
        --print(string.format("Missing Slot %s, AppearanceID: %s", invSlotID, transmogID));
    end
end

function TransmogUIManager:SetPendingFromTransmogInfoList(transmogInfoList)
    --WoW uses C_TransmogOutfitInfo.SetOutfitToCustomSet(customSetID) to directly apply the sets
    --But we need to do it by slot

    for invSlotID, transmogInfo in ipairs(transmogInfoList) do
        if not IgnoredInvSlots[invSlotID] then
            local transmogID = transmogInfo.appearanceID;
            local secondaryAppearanceID = transmogInfo.secondaryAppearanceID;
            local illusionID = transmogInfo.illusionID;

            if invSlotID ~= 16 and invSlotID ~= 17 then
                illusionID = nil;
            end

            if invSlotID == 3 then
                ApplyTransmog(invSlotID, Enum.TransmogOutfitSlot.ShoulderRight, transmogID);
                if secondaryAppearanceID == 0 then
                    secondaryAppearanceID = transmogID;
                end
                ApplyTransmog(invSlotID, Enum.TransmogOutfitSlot.ShoulderLeft, secondaryAppearanceID);
            else
                local slot = ConverInvSlotToTransmogSlot(invSlotID);
                ApplyTransmog(invSlotID, slot, transmogID, illusionID);
            end
        end
    end
end

local UsableItemModifiedAppearances = {};

function TransmogUIManager:IsAppearanceUsable(appearanceID)
    --Race/Class errors

    if UsableItemModifiedAppearances[appearanceID] == nil then
        if not IsAppearanceHiddenVisual(appearanceID) then
            local sourceInfo = GetSourceInfo(appearanceID);
            if sourceInfo then
                UsableItemModifiedAppearances[appearanceID] = sourceInfo.useError == nil;
            end
        end
    end

    return UsableItemModifiedAppearances[appearanceID]
end

function TransmogUIManager:IsTransmogInfoListCollected(transmogInfoList, showMissingSlots)
    local allCollected = true;
    local allMissing = showMissingSlots and true or nil;
    local missingSlots;

	for invSlotID, transmogInfo in ipairs(transmogInfoList) do
        if (not IgnoredInvSlots[invSlotID]) and transmogInfo.appearanceID ~= 0 then
            local appearanceInfo = GetAppearanceInfoBySource(transmogInfo.appearanceID);
            local valid = true;

            if appearanceInfo then
                if not appearanceInfo.appearanceIsCollected then
                    valid = false;
                end
            elseif not IsAppearanceHiddenVisual(transmogInfo.appearanceID) then
                valid = false;
            end

            if valid then
                allMissing = false;
            else
                allCollected = false;
            end

            if showMissingSlots then
                if not valid then
                    if not missingSlots then
                        missingSlots = {};
                    end
                    table.insert(missingSlots, invSlotID);
                end
            elseif not allCollected then
                break
            end
        end
	end

    return allCollected, missingSlots, allMissing
end

function TransmogUIManager:IsTransmogInfoListUsable(transmogInfoList)
    local total = 0;
    local numNotHidden = 0;
    local numHidden = 0;

    for invSlotID, transmogInfo in ipairs(transmogInfoList) do
        if (not IgnoredInvSlots[invSlotID]) and transmogInfo.appearanceID ~= 0 then
            total = total + 1;
            if IsAppearanceHiddenVisual(transmogInfo.appearanceID) then
                numHidden = numHidden + 1;
            elseif TransmogUIManager:IsAppearanceUsable(transmogInfo.appearanceID) then
                numNotHidden = numNotHidden + 1;
            end
        end
    end

    if total > 0 then
        --If all items are hidden visual, consider it usable
        if numHidden == total then
            return true
        end

        if numNotHidden > 0 then
            return true
        end
    end

    return false
end

function TransmogUIManager:IsCustomSetCollected(customSetID, showMissingSlots)
	local transmogInfoList = C_TransmogCollection.GetCustomSetItemTransmogInfoList(customSetID);
	return self:IsTransmogInfoListCollected(transmogInfoList, showMissingSlots)
end

function TransmogUIManager:Tooltip_AddGreyLine(tooltip, text)
    --Disabled Text: The default Grey (0.5, 0.5, 0.5) might not be legible enough
    tooltip:AddLine(text, 0.6, 0.6, 0.6, true);
end

function TransmogUIManager:PostTransmogInChat(transmogInfoList)
    local hyperlink = C_TransmogCollection.GetCustomSetHyperlinkFromItemTransmogInfoList(transmogInfoList);
    if hyperlink then
        if not ChatFrameUtil.InsertLink(hyperlink) then
            ChatFrameUtil.OpenChat(hyperlink);
        end
        return true
    end
end

function TransmogUIManager:ShowTransmogClipboard(transmogInfoList)
    local cmd = TransmogUtil.CreateCustomSetSlashCommand(transmogInfoList);
    addon.ShowClipboard(cmd);
end

local function AreAppearancesEqualOrHidden(id1, id2)
    if id1 ~= id2 then
        if not( (id1 == 0 or IsAppearanceHiddenVisual(id1)) and (id2 == 0 or IsAppearanceHiddenVisual(id2)) ) then
            return false
        end
    end
    return true
end

local function AreShoulderAppearancesEqual(lInfo, rInfo)
    if lInfo.appearanceID ~= rInfo.appearanceID then
        return false
    end

    if lInfo.secondaryAppearanceID ~= 0 and rInfo.secondaryAppearanceID ~= 0 then
        return false
    end

    return true
end

function TransmogUIManager:IsCustomSetDressed(currentItemTransmogInfoList, customSetItemTransmogInfoList)
    local rInfo;
    for slotID, lInfo in ipairs(currentItemTransmogInfoList) do
        rInfo = customSetItemTransmogInfoList[slotID];

        --[[    --Blizzard Method
        if not lInfo:IsEqual(rInfo) then
            if lInfo.appearanceID ~= 0 then
                return false
            end
        end
        --]]

        if not AreAppearancesEqualOrHidden(lInfo.appearanceID, rInfo.appearanceID) then
            return false
        end

        if not AreAppearancesEqualOrHidden(lInfo.illusionID, rInfo.illusionID) then
            return false
        end

        if rInfo.secondaryAppearanceID ~= 0 then
            if not AreAppearancesEqualOrHidden(lInfo.secondaryAppearanceID, rInfo.secondaryAppearanceID) then
                return false
            end
        end
    end
    return true
end

function TransmogUIManager:GetDefaultCustomSetsCount()
    local current = #(C_TransmogCollection.GetCustomSets() or {});
    local max = C_TransmogCollection.GetNumMaxCustomSets() or 0;
    return current, max
end

function TransmogUIManager:CanSaveMoreCustomSet()
    local current, max = self:GetDefaultCustomSetsCount();
    return current < max
end

do  --For jumping to recently saved set
    function TransmogUIManager:SetRecentlySavedSharedSetFlag(timeCreated)
        self.recentlySavedSharedSetFlag = timeCreated;
        C_Timer.After(0.5, function()
            self.recentlySavedSharedSetFlag = nil;
        end);
    end

    function TransmogUIManager:SetRecentlySavedCustomSetFlag(name)
        self.recentlySavedCustomSetFlag = name;
        C_Timer.After(0.5, function()
            self.recentlySavedCustomSetFlag = nil;
        end);
    end
end

do  --Alt Character Custom Sets
    local CharacterProfile = addon.ProfileAPI;

    local ArmorTypeXPlayerClass = {
        --1:Cloth, 2:Leather, 3:Mail, 4:Plate
        [1] = {5, 8, 9},
        [2] = {4, 10, 11, 12},
        [3] = {3, 7, 13},
        [4] = {1, 2, 6},
    };

    function TransmogUIManager:GetCharacterList()
        local _, _, classID = UnitClass("player");
        local classesWidthSameArmorType;

        for _armorType, classes in pairs(ArmorTypeXPlayerClass) do
            for _, _classID in ipairs(classes) do
                if classID == _classID then
                    classesWidthSameArmorType = classes;
                    break
                end
            end

            if classesWidthSameArmorType then
                break
            end
        end

        local function filterFunc(data)
            if data.outfits and #data.outfits > 0 then
                return true
            end
        end

        local sortMethod = "name";
        local uids = CharacterProfile:GetRoster(filterFunc, sortMethod) or {};

        return uids
    end

    local WrapNameWithClassColor = NarciAPI.WrapNameWithClassColor;

    local function CharacterInfo_LoadData(self)
        if self.loaded then return end;
        self.loaded = true;

        local colorizedName = WrapNameWithClassColor(self.name, self.classID);
        local realmName = CharacterProfile:GetRealmName(self.serverID);

        --if not realmName then realmName = "Culte de la Rive noire" end; --Debug, Longest Name

        if realmName then
            self.realmName = realmName;
            if self.fromOtherServer then
                colorizedName = colorizedName.."|cff808080 - "..realmName.."|r";
            end
        end

        self.colorizedName = colorizedName;

        local outfits = CharacterProfile:GetOutfits(self.uid);
        local sets = {};
        for i, v in ipairs(outfits) do
            sets[i] = TransmogDataProvider:DecodeSavedOutfit(v); --setsInfo = {name = string, transmogInfoList = table}
        end
        self.sets = sets;
        self.numSets = #sets;
    end

    function TransmogUIManager:GetAllCharacterCustomSets()
        if self.allCharacterCustomSets then
            return self.allCharacterCustomSets
        end

        local playerUID = CharacterProfile:GetCurrentPlayerUID();
        local uids = self:GetCharacterList();
        local n = 0;
        local tbl = {};

        for _, uid in ipairs(uids) do
            if uid ~= playerUID then
                local outfits = CharacterProfile:GetOutfits(uid);
                if outfits then
                    local characterInfo = CharacterProfile:CopyBasicInfo(uid);
                    characterInfo.LoadData = CharacterInfo_LoadData;
                    if true then
                        n = n + 1;
                        tbl[n] = characterInfo;
                    end
                end
            end
        end

        self.allCharacterCustomSets = tbl;
        return tbl
    end

    CallbackRegistry:Register("TransmogUI.CharacterInfoDeleted", function(uid)
        if TransmogUIManager.allCharacterCustomSets then
            for i, characterInfo in ipairs(TransmogUIManager.allCharacterCustomSets) do
                if characterInfo.uid == uid then
                    table.remove(TransmogUIManager.allCharacterCustomSets, i);
                    break
                end
            end
        end
    end);
end

do  --Shared Custom Sets
    local MAX_SHARED_SETS = 90; --10 Pages

    function TransmogUIManager:GetNumMaxSharedSets()
        return MAX_SHARED_SETS
    end

    local function SortFunc_ByDate(a, b)
        if a.anyUsable ~= b.anyUsable then
            return a.anyUsable
        end

        if a.collected ~= b.collected then
            return a.collected
        end

        if a.timeCreated ~= b.timeCreated then
            return a.timeCreated > b.timeCreated
        end

        if a.name ~= b.name then
            return a.name < b.name
        end

        return a.dataIndex < b.dataIndex
    end

    function TransmogUIManager:GetSharedSetsDataList()
        if self.sharedSetsDataList then
            return self.sharedSetsDataList
        end

        local n = 1;
        local _, _, classID = UnitClass("player");
        local ParseCustomSetSlashCommand = TransmogUtil.ParseCustomSetSlashCommand;
        local sets = NarciTransmogUIDB.SharedSets;
        local total = #sets;
        local setInfo = sets[1];
        local dataList = {};

        while n <= total and setInfo do
            setInfo.dataIndex = n;
            local transmogInfoList = ParseCustomSetSlashCommand(setInfo.cmd);
            if transmogInfoList then
                dataList[n] = {
                    name = setInfo.name,
                    transmogInfoList = transmogInfoList,
                    timeCreated = setInfo.timeCreated,
                    classID = setInfo.classID,
                    collected = self:IsTransmogInfoListCollected(transmogInfoList),
                    dataIndex = setInfo.dataIndex,
                };
                if classID == setInfo.classID then
                    dataList[n].anyUsable = true;
                else
                    dataList[n].anyUsable = self:IsTransmogInfoListUsable(transmogInfoList);
                end
                n = n + 1;
            else
                table.remove(sets, n);
                print("Narcissus Invalid Shared Sets Removed:", setInfo.name);
            end
            setInfo = sets[n];
        end

        table.sort(dataList, SortFunc_ByDate);
        self.sharedSetsDataList = dataList;

        return dataList
    end

    function TransmogUIManager:GetNumSharedSets()
        return NarciTransmogUIDB and NarciTransmogUIDB.SharedSets and #NarciTransmogUIDB.SharedSets or 0
    end

    function TransmogUIManager:CanSaveMoreSharedSet()
        return self:GetNumSharedSets() < MAX_SHARED_SETS;
    end

    function TransmogUIManager:TrySaveSharedSet(name, transmogInfoList)
        if not self:CanSaveMoreSharedSet() then return end;

        --Use Blizzard encoding so it's easier to salvage saves from SavedVariables

        local cmd = TransmogUtil.CreateCustomSetSlashCommand(transmogInfoList);
        cmd = string.gsub(cmd, "/customset%s+", "", 1);

        local _, _, classID = UnitClass("player");
        local dataIndex = #NarciTransmogUIDB.SharedSets + 1;
        local timestamp = time();

        table.insert(NarciTransmogUIDB.SharedSets, {
            name = name,
            cmd = cmd,
            timeCreated = timestamp,
            timeModified = timestamp,
            classID = classID,
            dataIndex = dataIndex,
        });

        self.sharedSetsDataList = nil;

        self:SetRecentlySavedSharedSetFlag(timestamp);

        return true
    end

    function TransmogUIManager:TryRenameSharedSet(dataIndex, name)
        local success;

        if name and strtrim(name) ~= "" then
            for i, setInfo in ipairs(NarciTransmogUIDB.SharedSets) do
                if setInfo.dataIndex == dataIndex then
                    setInfo.name = name;
                    setInfo.timeModified = time();
                    success = true;
                    break
                end
            end

            if self.sharedSetsDataList then
                for i, setInfo in ipairs(self.sharedSetsDataList) do
                    if setInfo.dataIndex == dataIndex then
                        setInfo.name = name;
                        break
                    end
                end
            end
        end

        if success then
            CallbackRegistry:Trigger("StaticPopup.CloseAll");
            CallbackRegistry:Trigger("TransmogUI.SharedSetRenamed");
        end
    end

    function TransmogUIManager:TryOverwriteSharedSet(dataIndex, transmogInfoList)
        local success;

        local cmd = TransmogUtil.CreateCustomSetSlashCommand(transmogInfoList);
        cmd = string.gsub(cmd, "/customset%s+", "", 1);

        local _, _, classID = UnitClass("player");

        for i, setInfo in ipairs(NarciTransmogUIDB.SharedSets) do
            if setInfo.dataIndex == dataIndex then
                setInfo.cmd = cmd;
                setInfo.timeModified = time();
                setInfo.classID = classID;
                success = true;
                break
            end
        end

        if success then
            self.sharedSetsDataList = nil;
            CallbackRegistry:Trigger("StaticPopup.CloseAll");
            CallbackRegistry:Trigger("TransmogUI.LoadSharedSets", true);
        end
    end

    function TransmogUIManager:DeleteSharedSet(dataIndex)
        local success;

        for i, setInfo in ipairs(NarciTransmogUIDB.SharedSets) do
            if setInfo.dataIndex == dataIndex then
                table.remove(NarciTransmogUIDB.SharedSets, i);
                success = true;
                break
            end
        end

        if success then
            self.sharedSetsDataList = nil;
            CallbackRegistry:Trigger("StaticPopup.CloseAll");
            CallbackRegistry:Trigger("TransmogUI.LoadSharedSets", true);
        end
    end

    function TransmogUIManager:IsCustomSetShared(transmogInfoList)
        local info;
        local dataIndex, name;

        for _, data in ipairs(self:GetSharedSetsDataList()) do
            dataIndex = data.index;
            name = data.name;
            for slotID, _info in ipairs(data.transmogInfoList) do
                info = transmogInfoList[slotID];
                if not (info and info:IsEqual(_info)) then
                    if slotID == 3 then
                        if not AreShoulderAppearancesEqual(info, _info) then
                            name = nil;
                            break
                        end
                    else
                        name = nil;
                        break
                    end
                end
            end

            if name then
                break
            end
        end

        return name
    end
end

do  --Viewd Outfit Info
    --/dump C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(0, 0, 0)
    function TransmogUIManager:GetViewedOutfitInfo()
        if not self.weaponOptions then
            self.weaponOptions = {};
            local option = Enum.TransmogOutfitSlotOption;
            self.weaponOptions = {
                option.OneHandedWeapon,
                option.TwoHandedWeapon,
                option.RangedWeapon,
                option.OffHand,
                option.Shield,
                option.FuryTwoHandedWeapon,
            };
        end

        local GetViewedOutfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo;
        local usedTextures = {};
        local tbl = {};
        local n = 0;

        local function AddSlotInfo(invSlotID, slot, appearanceType, weaponOption)
            local slotInfo = GetViewedOutfitSlotInfo(slot, appearanceType, weaponOption);
            if slotInfo and slotInfo.error == 0 then
                if slotInfo.texture and not usedTextures[slotInfo.texture] then
                    usedTextures[slotInfo.texture] = true;
                    n = n + 1;
                    tbl[n] = {
                        texture = slotInfo.texture,
                        transmogID = slotInfo.transmogID,
                        invSlotID = invSlotID,
                        isIllusion = appearanceType == 1,
                    };
                end
            end
        end

        for _, invSlotID in ipairs(TransmogInvSlots) do
            local slot = ConverInvSlotToTransmogSlot(invSlotID);
            if invSlotID == 16 or invSlotID == 17 then
                for _, weaponOption in ipairs(self.weaponOptions) do
                    AddSlotInfo(invSlotID, slot, Enum.TransmogType.Appearance, weaponOption);
                end
                for _, weaponOption in ipairs(self.weaponOptions) do
                    AddSlotInfo(invSlotID, slot, Enum.TransmogType.Illusion, weaponOption);
                end
            elseif invSlotID == 3 then
                AddSlotInfo(invSlotID, slot, Enum.TransmogType.Appearance, Enum.TransmogOutfitSlotOption.None);
                AddSlotInfo(invSlotID, Enum.TransmogOutfitSlot.ShoulderRight, Enum.TransmogType.Appearance, Enum.TransmogOutfitSlotOption.None);
                AddSlotInfo(invSlotID, Enum.TransmogOutfitSlot.ShoulderLeft, Enum.TransmogType.Appearance, Enum.TransmogOutfitSlotOption.None);
            else
                AddSlotInfo(invSlotID, slot, Enum.TransmogType.Appearance, Enum.TransmogOutfitSlotOption.None);
            end
        end

        return tbl
    end

    --[[
    function Narci_YeetViewdSlots()
        local tbl = TransmogUIManager:GetViewedOutfitInfo();
        for _, v in ipairs(tbl) do
            local sourceInfo = GetSourceInfo(v.transmogID);
            local name = sourceInfo and sourceInfo.name or "";
            print(string.format("|T%s:16:16|t %s", v.texture, name));
        end
    end
    --]]
end


--[[
function Narci_SetPendingTransmogByCustomSet(setID)
    local list = C_TransmogCollection.GetCustomSetItemTransmogInfoList(setID);
    if list then
        TransmogUIManager:SetPendingFromTransmogInfoList(list)
    end

    --/run Narci_SetPendingTransmogByCustomSet(12)
    --/dump GetMouseFoci()[1].elementData.customSetID
end
--]]


--[[
hooksecurefunc(C_TransmogOutfitInfo, "SetPendingTransmog", function(slot, type, option, transmogID, displayType)
    print(slot, type, option, transmogID, displayType)
end)
--]]
