local _, addon = ...
local TransmogUIManager = {};
addon.TransmogUIManager = TransmogUIManager;
TransmogUIManager.modules = {};


local GetAppearanceSources = C_TransmogCollection.GetAppearanceSources;
local GetAppearanceInfoBySource = C_TransmogCollection.GetAppearanceInfoBySource;


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

function TransmogUIManager:SetPendingFromTransmogInfoList(transmogInfoList)
    local GetTransmogOutfitSlotFromInventorySlot = C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot;
    local IsAppearanceHiddenVisual = C_TransmogCollection.IsAppearanceHiddenVisual;
    local SetPendingTransmog = C_TransmogOutfitInfo.SetPendingTransmog;
    local Enum = Enum;

    local mainHandSlot = 16;
    local offsetHandSlot = 17;
    local shoulderSlot = 3;


    local function ApplyTransmog(invSlotID, slot, transmogID, illusionID)
        local option = Enum.TransmogOutfitSlotOption.None;

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
                transmogID = self:GetHiddenSourceIDForSlot(invSlotID) or transmogID;
            end
        end

        if slot and transmogID then
            SetPendingTransmog(slot, transmogType, option, transmogID, displayType);
        else
            --print(string.format("Missing Slot %s, AppearanceID: %s", invSlotID, transmogID));
        end
    end


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

function TransmogUIManager:IsTransmogInfoListCollected(transmogInfoList, showMissingSlots)
    local isCollected = true;
    local missingSlots;

	for invSlotID, transmogInfo in ipairs(transmogInfoList) do
		local appearanceInfo = GetAppearanceInfoBySource(transmogInfo.appearanceID);
		if appearanceInfo and not appearanceInfo.appearanceIsCollected then
			isCollected = false;
			if showMissingSlots then
                if not missingSlots then
                    missingSlots = {};
                end
                table.insert(missingSlots, invSlotID);
            else
                break
            end
		end
	end
    return isCollected, missingSlots
end

function TransmogUIManager:IsCustomSetCollected(customSetID, showMissingSlots)
	local transmogInfoList = C_TransmogCollection.GetCustomSetItemTransmogInfoList(customSetID);
	return self:IsTransmogInfoListCollected(transmogInfoList, showMissingSlots)
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