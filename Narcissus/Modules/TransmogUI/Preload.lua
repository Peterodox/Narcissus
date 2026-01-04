local _, addon = ...
local TransmogUIManager = {};
addon.TransmogUIManager = TransmogUIManager;
TransmogUIManager.modules = {};


local TransmogDataProvider = addon.TransmogDataProvider;
local GetSourceInfo = C_TransmogCollection.GetSourceInfo;
local GetAppearanceSources = C_TransmogCollection.GetAppearanceSources;
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

    for _, module in ipairs(self.modules) do
        module:OnLoad();
    end
end


local HiddenVisuals = {
    --[slotID] = visualID (appearanceID) --sourceID (modifiedAppearanceID)
    [1] = 29124,    --77344
    [3] = 24531,    --77343
    [5] = 40282,    --104602
    [4] = 33155,    --83202
    [19]= 33156,    --83203
    [9] = 40284,    --104604
    [10]= 37207,    --94331
    [6] = 33252,    --84233
    [7] = 42568,    --198608
    [8] = 40283,    --104603
};

local IgnoredInvSlots = {
    [2]  = true,
    [11] = true,
    [12] = true,
    [13] = true,
    [14] = true,
    [18] = true,    --Ranged Slot
};


function TransmogUIManager:GetHiddenSourceIDForSlot(invSlotID)
    local appearanceID = HiddenVisuals[invSlotID]
    local sources = appearanceID and GetAppearanceSources(appearanceID);
    if sources and sources[1] then
        return sources[1].sourceID
    end
end

local function ApplyTransmog(invSlotID, slot, transmogID, illusionID)
    local transmogType;
    if illusionID and illusionID ~= 0 then
        transmogType = Enum.TransmogType.Illusion;
    else
        transmogType = Enum.TransmogType.Appearance;
    end

    local isHiddenVisual;
    local displayType;
    if IsAppearanceHiddenVisual(transmogID) or transmogID == 0 then
        displayType = Enum.TransmogOutfitDisplayType.Hidden;
        isHiddenVisual = true;
    else
        displayType = Enum.TransmogOutfitDisplayType.Assigned;
    end

    if isHiddenVisual then
        if transmogID == 0 then
            transmogID = TransmogUIManager:GetHiddenSourceIDForSlot(invSlotID) or transmogID;
        end
    end

    if slot and transmogID then
        local option;
        if invSlotID == 16 or invSlotID == 17 then
            --option = Enum.TransmogOutfitSlotOption.OneHandedWeapon;
            option = C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot(slot);
            if not option then
                option = Enum.TransmogOutfitSlotOption.None;
            end
        else
            option = Enum.TransmogOutfitSlotOption.None;
        end
        SetPendingTransmog(slot, transmogType, option, transmogID, displayType);
    else
        --print(string.format("Missing Slot %s, AppearanceID: %s", invSlotID, transmogID));
    end
end

function TransmogUIManager:SetPendingFromTransmogInfoList(transmogInfoList)
    --WoW uses C_TransmogOutfitInfo.SetOutfitToCustomSet(customSetID) to directly apply the sets
    --But we need to do it by slot

    local mainHandSlot = 16;
    local offsetHandSlot = 17;
    local shoulderSlot = 3;

    for invSlotID, transmogInfo in ipairs(transmogInfoList) do
        if not IgnoredInvSlots[invSlotID] then
            local transmogID = transmogInfo.appearanceID;
            local secondaryAppearanceID = transmogInfo.secondaryAppearanceID;
            local illusionID = transmogInfo.illusionID;

            if illusionID == 0 then
                illusionID = nil;
            end

            if invSlotID == shoulderSlot then
                ApplyTransmog(invSlotID, Enum.TransmogOutfitSlot.ShoulderRight, transmogID, illusionID);
                if secondaryAppearanceID == 0 then
                    secondaryAppearanceID = transmogID;
                end
                ApplyTransmog(invSlotID, Enum.TransmogOutfitSlot.ShoulderLeft, secondaryAppearanceID, illusionID);
            else
                local slot = GetTransmogOutfitSlotFromInventorySlot(invSlotID - 1);
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


do  --Shared Custom Sets
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

        self.colorizedName = WrapNameWithClassColor(self.name, self.classID);
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