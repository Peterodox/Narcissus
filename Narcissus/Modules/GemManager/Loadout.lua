local _, addon = ...
local Gemma = addon.Gemma;
local AtlasUtil = Gemma.AtlasUtil;
local ItemCache = Gemma.ItemCache;
local AcquireActionButton = Gemma.AcquireActionButton;
local L = Narci.L;
local GetItemIcon = C_Item.GetItemIconByID;
local FadeFrame = NarciFadeUI.Fade;
local GetItemBagPosition = NarciAPI.GetItemBagPosition;
local CopyTable = addon.CopyTable;

local GetItemGemID = C_Item.GetItemGemID;
local GetItemNumSockets = C_Item.GetItemNumSockets;
local GetInventoryItemLink = GetInventoryItemLink;
local GetItemCount = C_Item.GetItemCount;

local pairs = pairs;
local ipairs = ipairs;
local min = math.min;
local tsort = table.sort;

local CreateFrame = CreateFrame;
local Mixin = Mixin;
local strtrim = strtrim;

local MAX_SAVES = 10;
local LOADOUT_BUTTON_HEIGHT_COLLAPSED = 28;
local LOADOUT_BUTTON_HEIGHT_EXPANDED = 56;
local LOADOUT_BUTTON_WIDTH = 322;


local DataProvider;
local MainFrame, LoadoutFrame, MouseOverFrame, EquipButton, EditButton, ListRightIcon, SimpleTooltip;
local EditWindow, Planner;


local SOCKETABLE_SLOTS = {
    1, 2, 3, 5, 9,
    10, 6, 7, 8,
    11, 12, 13, 14,
};

local STAT1_SLOTS = {
    5,  --Chest
    7,  --Legs
};

local STAT2_SLOTS = {
    13,  --Trinket1
    14,  --Trinket2
};

local STAT3_SLOTS = {
    2,  --Neck
    11, --Ring1
    12, --Ring2
};

local Automation = CreateFrame("Frame");


local function CreateReturnButton(parent)
    local f = Gemma.CreateIconButton(parent);
    AtlasUtil:SetAtlas(f.Icon, "gemlist-return");
    f:SetSize(60, 32);
    f:SetPoint("LEFT", parent, "TOPLEFT", 0, -22);
    f.tooltipText = L["Return"];
    return f
end


local LoadoutUtil = {};
do
    --Save Format:
    --[[
        save = {
            name = text,
            timeCreated = time,
            timeApplied = time,
            gemInfo = table,    --See DataProvider:GetEquippedLoadoutGemInfo() for gemInfo structure
        },
    --]]

    local REF_TIME = 1717403000;
    local NO_GEM_ID = 0;
    local time = time;

    local tinsert = table.insert;
    local tremove = table.remove;

    local function GetRelativeTime()
        return time() - REF_TIME
    end

    function LoadoutUtil:LoadSaves()
        if not NarcissusDB.PandariaRemixLoadout then
            NarcissusDB.PandariaRemixLoadout = {};
        end

        local _, _, classID = UnitClass("player");
        if not NarcissusDB.PandariaRemixLoadout[classID] then
            NarcissusDB.PandariaRemixLoadout[classID] = {};
        end

        self.Saves = NarcissusDB.PandariaRemixLoadout[classID];

        self:CreateOverviews();
    end

    function LoadoutUtil:GetCurrentGemInfo()
        if not self.currentGemInfo then
            self.currentGemInfo = DataProvider:GetEquippedLoadoutGemInfo();
        end
        return self.currentGemInfo
    end

    function LoadoutUtil:CreateNewLoadout(name, gemInfo)
        local isDupe, dupeName = self:DoesGemLoadoutExist(gemInfo);
        if isDupe then
            return
        end

        tsort(gemInfo.tinker);

        local data = {};
        data.name = name;
        data.gemInfo = gemInfo;
        data.timeCreated = GetRelativeTime();

        table.insert(self.Saves, data);
        self:CreateOverviews();

        LoadoutFrame.loadoutListChanged = true;
        LoadoutFrame:RequestUpdate();

        return true
    end

    function LoadoutUtil:OverwriteLoadout(loadoutIndex, name, gemInfo)
        if loadoutIndex and self.Saves[loadoutIndex] then
            local data = {};
            data.name = name;
            data.gemInfo = CopyTable(gemInfo);
            data.timeCreated = GetRelativeTime();
            self.Saves[loadoutIndex] = data;

            self:CreateOverviews();
            LoadoutFrame.loadoutListChanged = true;
            LoadoutFrame.equipmentChanged = true;
            LoadoutFrame:RequestUpdate();

            return true
        end
    end

    function LoadoutUtil:SaveCurrentItemsAsNewLoadout()
        local name = "Loadout #"..(self:GetNumSaves() + 1);
        local gemInfo = self:GetCurrentGemInfo();
        self:CreateNewLoadout(name, gemInfo);
    end

    function LoadoutUtil:GetLoadoutName(loadoutIndex)
        return self:GetLoadoutData(loadoutIndex).name
    end

    function LoadoutUtil:GetLoadoutGemInfo(loadoutIndex)
        return self:GetLoadoutData(loadoutIndex).gemInfo
    end

    function LoadoutUtil:CopyLoadoutGemInfo(loadoutIndex)
        return CopyTable(self:GetLoadoutGemInfo(loadoutIndex))
    end

    function LoadoutUtil:FormatStatText(stats)
        --stats: { [statType] = amount }

        local numStats = 7;
        local valueText, statText;
        local amount;

        for i = 1, numStats do
            amount = stats[i] or 0;

            if amount == 0 then
                valueText = amount;
            else
                valueText = "|cffffffff"..amount.."|r";
            end

            if statText then
                statText = statText .. "-" .. valueText;
            else
                statText = valueText;
            end
        end

        return statText
    end

    function LoadoutUtil:GetLoadoutStatText(gemInfo)
        local numStats = 7;
        local count = {};
        local n;

        for i = 1, numStats do
            count[i] = 0;
        end

        for i = 1, 3 do
            local stats = gemInfo["stats"..i];
            if stats then
                for j = 1, numStats do
                    n = stats[j];
                    if n then
                        count[j] = count[j] + n;
                    end
                end
            end
        end

        return self:FormatStatText(count)
    end

    function LoadoutUtil:CreateOverviews()
        self.Overviews = {};

        for i = 1, MAX_SAVES do
            if self.Saves[i] then
                local itemID;
                local gemInfo = self:GetLoadoutGemInfo(i);
                local n = 0;
                local info = {};
                info.icons = {};

                for j = 1, 6 do
                    if j == 1 then
                        itemID = gemInfo.head;
                    elseif j == 2 then
                        itemID = gemInfo.feet;
                    else
                        itemID = gemInfo.tinker and gemInfo.tinker[j - 2];
                    end

                    if itemID then
                        n = n + 1;
                        info.icons[n] = GetItemIcon(itemID);
                    end
                end

                info.statText = self:GetLoadoutStatText(gemInfo);

                self.Overviews[i] = info;
            else
                break
            end
        end
    end

    function LoadoutUtil:GetLoadoutData(loadoutIndex)
        return self.Saves[loadoutIndex]
    end

    function LoadoutUtil:GetLoadoutOverview(loadoutIndex)
        return self.Overviews[loadoutIndex]
    end

    function LoadoutUtil:GetNumSaves()
        return min(#self.Saves, MAX_SAVES);
    end

    function LoadoutUtil:DeleteLoadout(loadoutIndex)
        local data = table.remove(self.Saves, loadoutIndex);
        table.remove(self.Overviews, loadoutIndex);

        if LoadoutFrame:IsDataSelectedByIndex(loadoutIndex) then
            LoadoutFrame:ClearSelection();
            LoadoutFrame:SetExpandedButton(nil);
        end

        self.equippedLoadoutIndex = nil;

        LoadoutFrame.loadoutListChanged = true;
        LoadoutFrame:RequestUpdate();
    end

    function LoadoutUtil:GetGemsForLoadout(loadoutIndex)
        local data = self:GetLoadoutData(loadoutIndex);
        --debug
    end

    function LoadoutUtil:AreGemInfoSame(gemInfo1, gemInfo2)
        if gemInfo1 and gemInfo2 then
            if not (gemInfo1.head == gemInfo2.head) then
                return false
            end

            if not (gemInfo1.feet == gemInfo2.feet) then
                return false
            end

            local v1, v2;

            for statType, amount in pairs(gemInfo2.stats1) do
                v1 = amount or 0;
                v2 = gemInfo1.stats1[statType] or 0;
                if v1 ~= v2 then
                    return false
                end
            end

            for statType, amount in pairs(gemInfo2.stats2) do
                v1 = amount or 0;
                v2 = gemInfo1.stats2[statType] or 0;
                if v1 ~= v2 then
                    return false
                end
            end

            for statType, amount in pairs(gemInfo2.stats3) do
                v1 = amount or 0;
                v2 = gemInfo1.stats3[statType] or 0;
                if v1 ~= v2 then
                    return false
                end
            end

            if #gemInfo1.tinker == #gemInfo2.tinker then
                local tinker1 = {};
                for _, itemID in ipairs(gemInfo1.tinker) do
                    tinker1[itemID] = true;
                end

                local allSame = true;
                for _, itemID in ipairs(gemInfo2.tinker) do
                    allSame = allSame and tinker1[itemID];
                end

                if allSame then
                    return true
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    end

    function LoadoutUtil:IsLoadoutEquipped(loadoutIndex)
        local gemInfo1 = self:GetCurrentGemInfo();
        local gemInfo2 = self:GetLoadoutData(loadoutIndex).gemInfo;

        return self:AreGemInfoSame(gemInfo1, gemInfo2)
    end

    function LoadoutUtil:IsLoadoutFullyEquipped(loadoutIndex)
        --Include using best stats gems in bags
        if self:IsLoadoutEquipped(loadoutIndex) then
            local searchStatsOnly = true;
            local slotActions, errors, requiredBagSpace = self:GetSlotActionsForLoadout(loadoutIndex, searchStatsOnly);
            return (#slotActions.insert + #slotActions.remove) == 0
        else
            return false
        end
    end

    function LoadoutUtil:GetEquippedLoadoutIndex()
        --0:   None
        --nil: uncached
        if not self.equippedLoadoutIndex then
            for i = 1, self:GetNumSaves() do
                if self:IsLoadoutFullyEquipped(i) then
                    self.equippedLoadoutIndex = i;
                    break
                end
            end

            if self.equippedLoadoutIndex then
                self:UpdateAppliedTime(self.equippedLoadoutIndex);
            end
        end

        return self.equippedLoadoutIndex
    end

    function LoadoutUtil:DoesLoadoutNameExist(name, loadoutIndex)
        for i = 1, self:GetNumSaves() do
            if name == self:GetLoadoutName(i) and i ~= loadoutIndex then
                return true
            end
        end
    end

    function LoadoutUtil:DoesGemLoadoutExist(gemInfo)
        for i = 1, self:GetNumSaves() do
            if self:AreGemInfoSame(gemInfo, self:GetLoadoutGemInfo(i)) then
                return true, self:GetLoadoutName(i);
            end
        end

        return false
    end

    function LoadoutUtil:UpdateAppliedTime(loadoutIndex)
        local data = self:GetLoadoutData(loadoutIndex);
        data.timeApplied = GetRelativeTime();
    end

    function LoadoutUtil:GetLastAppliedLoadoutIndex()
        local index;
        local maxValue = 0;
        local timeApplied;

        for i = 1, self:GetNumSaves() do
            timeApplied = self:GetLoadoutData(i).timeApplied;
            if timeApplied then
                if timeApplied > maxValue then
                    maxValue = timeApplied;
                    index = i;
                end
            end
        end

        return index
    end




    local TINKER_SLOT = {
        3, 9, 10, 6
    };

    function LoadoutUtil:GetCurrentItems()
        if self.currentSlotGems then
            return self.currentSlotGems
        end

        local slotGems = {};

        local itemLink, numSockets, gemItemID;

        for _, slotID in ipairs(SOCKETABLE_SLOTS) do
            itemLink = GetInventoryItemLink("player", slotID);
            if itemLink then
                numSockets = GetItemNumSockets(itemLink);
                for socketIndex = 1, numSockets do
                    gemItemID = GetItemGemID(itemLink, socketIndex) or NO_GEM_ID;
                    if not slotGems[slotID] then
                        slotGems[slotID] = {};
                    end
                    slotGems[slotID][socketIndex] = gemItemID;
                end
            end
        end

        self.currentSlotGems = slotGems;

        return slotGems
    end

    function LoadoutUtil:GetErrorMessage(errors)
        local errorType, message;
        local str;

        for i, error in ipairs(errors) do
            errorType = error[1];
            if errorType == 1 then   --Gem Uncollected
                message = "Uncollected: "..error[2];
            elseif errorType == 2 then  --Not enough sockets

            end
        end
    end

    local function DoesPlayerHaveSparedItem(itemID)
        local onPlayer = GetItemCount(itemID);
        return onPlayer > 0
    end

    local function PopulateRequiredStatsTable(gemInfoStats, totalRequiredStats, slotRequiredStats)
        for statType, amount in pairs(gemInfoStats) do
            if not totalRequiredStats[statType] then
                totalRequiredStats[statType] = 0;
            end
            totalRequiredStats[statType] = totalRequiredStats[statType] + amount;
            slotRequiredStats[statType] = amount;
        end
    end

    local function GetBestStatGemFromList(statGemCount, minusCount, bestIndex)
        --bestIndex: best, 2nd best, 3rd best...
        --statGemCount structure:
        --{ {itemID = , inBagCount = , spareCount = } , {} }    --items are from highest tier - lower

        local n = 0;

        for i, data in ipairs(statGemCount) do
            n = n + data.inBagCount;

            if n >= bestIndex then
                if minusCount then
                    data.inBagCount = data.inBagCount - 1;
                end
                return data.itemID, true
            end

            n = n + data.spareCount;

            if n >= bestIndex then
                if minusCount then
                    data.spareCount = data.spareCount - 1;
                end
                return data.itemID, false
            end
        end
    end

    local function AddStatGemToList(statGemCount, gemItemID, isInBagItem)
        for i, data in ipairs(statGemCount) do
            if gemItemID == data.itemID then
                if isInBagItem then
                    data.inBagCount = data.inBagCount + 1;
                else
                    data.spareCount = data.spareCount + 1;
                end
                break
            end
        end
    end

    local function SortFunc_StatSlot(slotInfo1, slotInfo2)
        --Sort by stat type and tier
        if slotInfo1.isEmpty ~= slotInfo2.isEmpty then
            return slotInfo1.isEmpty
        elseif slotInfo1.isEmpty then   --both empty
            if slotInfo1[1] ~= slotInfo2[1] then    --SlotID
                return slotInfo1[1] < slotInfo2[1]
            else    --SocketIndex
                return slotInfo1[2] < slotInfo2[2]
            end
        end

        if slotInfo1.isRequired ~= slotInfo2.isRequired then
            return not slotInfo1.isRequired;
        end

        if slotInfo1.statType ~= slotInfo2.statType then
            return slotInfo1.statType < slotInfo2.statType
        end

        --Sort Low Tier to the top
        return DataProvider:IsLeftStatGemBetter(slotInfo1[3], slotInfo2[3])
    end

    --[[
    local function MergeStatSlot(currentSlotGems, slotID, statSlot, requiredStats, equippedStats)
        if currentSlotGems[slotID] then
            for socketIndex, gemItemID in ipairs(currentSlotGems[slotID]) do
                local tbl = {slotID, socketIndex, gemItemID};
                if gemItemID == NO_GEM_ID then
                    tbl.isEmpty = true;
                    tbl.isRequired = false;
                else
                    local statType = DataProvider:GetStatType(gemItemID);
                    tbl.statType = statType;

                    if requiredStats[statType] then
                        tbl.isRequired = true;
                        if not equippedStats[statType] then
                            equippedStats[statType] = 0;
                        end
                        equippedStats[statType] = equippedStats[statType] + 1;

                        if equippedStats[statType] > requiredStats[statType] then
                            tbl.isRequired = false;
                        end
                    else
                        tbl.isRequired = false;
                    end
                end
                tinsert(statSlot, tbl);
            end

            tsort(statSlot, SortFunc_StatSlot);
        end
    end
    --]]

    local function MergeStatSlot(currentSlotGems, slotID, statSlot)
        if currentSlotGems[slotID] then
            for socketIndex, gemItemID in ipairs(currentSlotGems[slotID]) do
                local tbl = {slotID, socketIndex, gemItemID};
                tinsert(statSlot, tbl);
            end
        end
    end

    local function SortStatSlot(statSlot, requiredStats, equippedStats)
        local gemItemID, statType;

        for _, slotInfo in ipairs(statSlot) do
            gemItemID = slotInfo[3];
            if gemItemID == NO_GEM_ID then
                slotInfo.isEmpty = true;
                slotInfo.isRequired = false;
            else
                statType = DataProvider:GetStatType(gemItemID);
                slotInfo.statType = statType;

                if requiredStats[statType] then
                    slotInfo.isRequired = true;
                else
                    slotInfo.isRequired = false;
                end
            end
        end
        tsort(statSlot, SortFunc_StatSlot);

        for _, slotInfo in ipairs(statSlot) do
            if slotInfo.isRequired then
                statType = slotInfo.statType;
                if not equippedStats[statType] then
                    equippedStats[statType] = 0;
                end
                equippedStats[statType] = equippedStats[statType] + 1;

                if equippedStats[statType] > requiredStats[statType] then
                    slotInfo.isRequired = false;
                end
            end
        end
        tsort(statSlot, SortFunc_StatSlot);
    end

    local function ProcessStatSlots(requiredStats, statSlots, allStatGemCount, slotActions)
        for statType, amount in pairs(requiredStats) do
            local searchIndexOffset = 0;

            for i = 1, amount do
                local bestGemID, inBagItem = GetBestStatGemFromList(allStatGemCount[statType], false, i + searchIndexOffset);
                local found;

                if bestGemID then
                    local itemID;
                    for _, slotInfo in ipairs(statSlots) do
                        --slotInfo = {slotID, socketIndex, gemItemID}
                        itemID = slotInfo[3];
                        if (not slotInfo.used) and (not slotInfo.isEmpty) then
                            if not slotInfo.counted then
                                if itemID == bestGemID or DataProvider:IsLeftStatGemBetter(itemID, bestGemID) then
                                    slotInfo.counted = true;
                                    found = true;
                                    searchIndexOffset = searchIndexOffset - 1;
                                    break
                                end
                            end
                        end
                    end
                    --print("Search", bestGemID, ItemCache:GetItemName(bestGemID), "Found:", found)
                else
                    --print(i + searchIndexOffset, "No Best Gem for Stat", statType, amount)
                end

                if bestGemID and (not found) then
                    bestGemID, inBagItem = GetBestStatGemFromList(allStatGemCount[statType], true, 1);
                    local bestSlotInfo;

                    if not bestSlotInfo then
                        for _, slotInfo in ipairs(statSlots) do
                            if (not slotInfo.used) and slotInfo.isEmpty then
                                slotInfo.used = true;
                                bestSlotInfo = slotInfo;
                                break
                            end
                        end
                    end

                    if not bestSlotInfo then
                        for _, slotInfo in ipairs(statSlots) do
                            if (not slotInfo.used) and not slotInfo.isRequired then
                                slotInfo.used = true;
                                bestSlotInfo = slotInfo;
                                local itemID = slotInfo[3];
                                local statType = slotInfo.statType;
                                if allStatGemCount[statType] then
                                    AddStatGemToList(allStatGemCount[statType], itemID, false);
                                end
                                break
                            end
                        end
                    end

                    if not bestSlotInfo then
                        for _, slotInfo in ipairs(statSlots) do
                            if (not slotInfo.used) and slotInfo.isRequired then
                                local itemID = slotInfo[3];
                                if DataProvider:IsLeftStatGemBetter(bestGemID, itemID) then
                                    slotInfo.used = true;
                                    bestSlotInfo = slotInfo;
                                    local statType = slotInfo.statType;
                                    if allStatGemCount[statType] then
                                        AddStatGemToList(allStatGemCount[statType], itemID, false);
                                    end
                                    break
                                end
                            end
                        end
                    end

                    if bestSlotInfo then
                        local slotID, socketIndex, gemItemID = bestSlotInfo[1], bestSlotInfo[2], bestSlotInfo[3];
                        if not bestSlotInfo.isEmpty then
                            tinsert(slotActions.remove, {slotID, socketIndex, gemItemID});
                            --print("Add", bestGemID, ItemCache:GetItemName(bestGemID), "to replace", slotID, socketIndex, gemItemID, ItemCache:GetItemName(gemItemID))
                        else
                            --print("Add", bestGemID, ItemCache:GetItemName(bestGemID), "to slot", slotID, socketIndex)
                        end
                        tinsert(slotActions.insert, {slotID, socketIndex, bestGemID});
                        if inBagItem then
                            tinsert(slotActions.remove, {bestGemID});
                        end
                        searchIndexOffset = searchIndexOffset - 1;
                    end
                end
            end
        end
    end

    function LoadoutUtil:GetSlotActionsForLoadout(loadoutIndex, searchStatsOnly)
        --May ask the user to equip when switching a gem from low stat budget slot to a higher one
        local gemInfo = self:GetLoadoutGemInfo(loadoutIndex);
        local currentSlotGems = self:GetCurrentItems();

        local slotActions = {
            insert = {},    --{slotID, socketIndex, gemItemID}
            remove = {},    --{slotID, socketIndex, (itemID)} or {itemID}
        };

        local errors = {};
        local removeBagItem = {};
        local equippedGemID, requiredGemID;
        local slotID, socketIndex;


        if not searchStatsOnly then
            --Meta
            slotID = 1;
            socketIndex = 1;
            if currentSlotGems[slotID] then
                equippedGemID = currentSlotGems[slotID][socketIndex];
                requiredGemID = gemInfo.head;

                if requiredGemID and (equippedGemID and equippedGemID ~= requiredGemID) then
                    if DataProvider:IsGemCollected(requiredGemID) then
                        if equippedGemID ~= NO_GEM_ID then
                            tinsert(slotActions.remove,
                                {slotID, socketIndex, equippedGemID}
                            );
                        end
                        tinsert(slotActions.insert, {slotID, socketIndex, requiredGemID});

                        if not DoesPlayerHaveSparedItem(requiredGemID) then
                            tinsert(removeBagItem, requiredGemID);
                        end
                    else
                        tinsert(errors, {1, requiredGemID});

                        if equippedGemID == NO_GEM_ID then
                            local gemItemID = DataProvider:GetFallbackMeta();
                            tinsert(slotActions.insert, {slotID, socketIndex, gemItemID});
                            if not DoesPlayerHaveSparedItem(gemItemID) then
                                tinsert(removeBagItem, gemItemID);
                            end
                        end
                    end
                end
            end

            --Cogwheel
            slotID = 8;
            socketIndex = 1;
            if currentSlotGems[slotID] then
                equippedGemID = currentSlotGems[slotID][socketIndex];
                requiredGemID = gemInfo.feet;
                if requiredGemID and (equippedGemID and equippedGemID ~= requiredGemID) then
                    if DataProvider:IsGemCollected(requiredGemID) then
                        if equippedGemID ~= NO_GEM_ID then
                            tinsert(slotActions.remove,
                                {slotID, socketIndex, equippedGemID}
                            );
                        end
                        tinsert(slotActions.insert, {slotID, socketIndex, requiredGemID});

                        if not DoesPlayerHaveSparedItem(requiredGemID) then
                            tinsert(removeBagItem, requiredGemID);
                        end
                    else
                        tinsert(errors, {1, requiredGemID});

                        if equippedGemID == NO_GEM_ID then
                            local gemItemID = DataProvider:GetFallbackCogwheel();
                            tinsert(slotActions.insert, {slotID, socketIndex, gemItemID});
                            if not DoesPlayerHaveSparedItem(gemItemID) then
                                tinsert(removeBagItem, gemItemID);
                            end
                        end
                    end
                end
            end


            --Tinker
            local requiredTinker = {};
            local numEmptyTinkerSockets = 0;

            for _, gemItemID in ipairs(gemInfo.tinker) do
                if DataProvider:IsGemCollected(gemItemID) then
                    requiredTinker[gemItemID] = true;
                else
                    tinsert(errors, {1, gemItemID});
                end
            end

            local equippedTinker = {};
            local removalCandidate = {};  --Empty this socket if it has a gem not included in the loadout

            for _, slotID in ipairs(TINKER_SLOT) do
                local equippedGems = currentSlotGems[slotID];
                if equippedGems then
                    for socketIndex, gemItemID in ipairs(equippedGems) do
                        if not requiredTinker[gemItemID] then
                            local candidate = {slotID, socketIndex};
                            if gemItemID == NO_GEM_ID then
                                candidate.isEmpty = true;
                                numEmptyTinkerSockets = numEmptyTinkerSockets + 1;
                            else
                                candidate[3] = gemItemID;
                            end
                            tinsert(removalCandidate, candidate);
                        end

                        if gemItemID ~= NO_GEM_ID then
                            equippedTinker[gemItemID] = true;
                        end
                    end
                end
            end

            for gemItemID in pairs(requiredTinker) do
                if not equippedTinker[gemItemID] then
                    local candidate = tremove(removalCandidate);
                    if candidate then
                        if candidate.isEmpty then
                            numEmptyTinkerSockets = numEmptyTinkerSockets - 1;
                        else
                            tinsert(slotActions.remove, candidate);
                        end
                        slotID = candidate[1];
                        socketIndex = candidate[2];
                        tinsert(slotActions.insert, {slotID, socketIndex, gemItemID});

                        if not DoesPlayerHaveSparedItem(gemItemID) then
                            tinsert(removeBagItem, gemItemID);
                        end
                    else
                        --Not enough slot to equip
                        break
                    end
                end
            end

            --Fill up empty sockets if players don't the items saved in their loadout
            if numEmptyTinkerSockets > 0 then
                local fallbackGems = DataProvider:GetFallbackTinkers(numEmptyTinkerSockets, requiredTinker);
                local index = 0;
                for _, candidate in ipairs(removalCandidate) do
                    if candidate.isEmpty then
                        index = index + 1;
                        local gemItemID = fallbackGems[index];
                        if gemItemID then
                            slotID = candidate[1];
                            socketIndex = candidate[2];
                            tinsert(slotActions.insert, {slotID, socketIndex, gemItemID});

                            if not DoesPlayerHaveSparedItem(gemItemID) then
                                tinsert(removeBagItem, gemItemID);
                            end

                            --print("Use Fallback Tinker", gemItemID, ItemCache:GetItemName(gemItemID))
                        else
                            break
                        end
                    end
                end
            end
        end


        --Stats
        local requiredStats = {};
        local requiredStats1 = {};
        local requiredStats2 = {};
        local requiredStats3 = {};

        if gemInfo.stats1 then
            PopulateRequiredStatsTable(gemInfo.stats1, requiredStats, requiredStats1);
        end

        if gemInfo.stats2 then
            PopulateRequiredStatsTable(gemInfo.stats2, requiredStats, requiredStats2);
        end

        if gemInfo.stats3 then
            PopulateRequiredStatsTable(gemInfo.stats3, requiredStats, requiredStats3);
        end


        local allStatGemCount = {};
        for statType in pairs(requiredStats) do
            allStatGemCount[statType] = DataProvider:GetAvailableGemListForStat(statType);
        end


        --Chest, Legs
        local equippedStats1 = {};
        local stat1Slots = {};
        if gemInfo.stats1 then
            for _, slotID in ipairs(STAT1_SLOTS) do
                MergeStatSlot(currentSlotGems, slotID, stat1Slots);
            end
            SortStatSlot(stat1Slots, requiredStats1, equippedStats1);
            ProcessStatSlots(requiredStats1, stat1Slots, allStatGemCount, slotActions);
        end

        --Trinkets
        local equippedStats2 = {};
        local stat2Slots = {};
        if gemInfo.stats2 then
            for _, slotID in ipairs(STAT2_SLOTS) do
                MergeStatSlot(currentSlotGems, slotID, stat2Slots);
            end
            SortStatSlot(stat2Slots, requiredStats2, equippedStats2);
            ProcessStatSlots(requiredStats2, stat2Slots, allStatGemCount, slotActions);
        end

        --Neck, Rings
        local equippedStats3 = {};
        local stat3Slots = {};
        if gemInfo.stats3 then
            for _, slotID in ipairs(STAT3_SLOTS) do
                MergeStatSlot(currentSlotGems, slotID, stat3Slots);
            end
            SortStatSlot(stat3Slots, requiredStats3, equippedStats3);
            ProcessStatSlots(requiredStats3, stat3Slots, allStatGemCount, slotActions);
        end


        for _, itemID in ipairs(removeBagItem) do
            tinsert(slotActions.remove, {itemID});
        end

        local uniqueGems = {};
        local itemID;
        local requiredBagSpace = 1;     --We required an extra bag slot in case something went wrong

        for _, info in ipairs(slotActions.remove) do
            itemID = info[3] or info[1];
            if (itemID and not uniqueGems[itemID]) then
                uniqueGems[itemID] = true;
                if not DoesPlayerHaveSparedItem(itemID) then
                    requiredBagSpace = requiredBagSpace + 1;
                end
            end
        end

        return slotActions, errors, requiredBagSpace
    end
end




local LoadoutButtonMixin = {};
local CreateLoadoutButton;

do
    function LoadoutButtonMixin:OnEnter()
        if not self.isEquipped then
            self.Name:SetTextColor(1, 1, 1);
        end

        LoadoutFrame:SetExpandedButton(self);

        if not LoadoutFrame:IsAnyDataSelected() then
            MouseOverFrame:SetLoadout(self.index);
        end
    end

    function LoadoutButtonMixin:OnLeave()
        if self:IsVisible() and self:IsMouseOver() then
            return
        end

        if self.isEquipped then
            
        else
            self.Name:SetTextColor(0.67, 0.67, 0.67);
        end
        
        LoadoutFrame:SetExpandedButton(nil);
    end

    function LoadoutButtonMixin:OnClick()
        if LoadoutFrame:IsDataSelectedByIndex(self.index) then
            LoadoutFrame:ClearSelection();
        else
            LoadoutFrame:SelectLoadoutByIndex(self.index);
        end
    end

    function LoadoutButtonMixin:OnDoubleClick()
        --Consume this action since we're using a gesture different from equipment set to equip gem loadout
    end

    function LoadoutButtonMixin:SetData(data, isEquipped)
        self.Name:SetText(data.name);
        self.isEquipped = isEquipped;
        if isEquipped then
            self.Name:SetTextColor(1, 0.82, 0);
        else
            self.Name:SetTextColor(0.67, 0.67, 0.67);
        end
    end

    function LoadoutButtonMixin:SetExpanded(isExpanded)
        if isExpanded and (not self.isExpanded) then
            self.isExpanded = true;
            self:SetHeight(LOADOUT_BUTTON_HEIGHT_EXPANDED);
            self:SetAlpha(0);
        elseif (not isExpanded) and self.isExpanded then
            self.isExpanded = false;
            self:SetHeight(LOADOUT_BUTTON_HEIGHT_COLLAPSED);
            self:SetAlpha(1);
        end
    end


    function CreateLoadoutButton(parent, index)
        local f = CreateFrame("Button", nil, parent);
        Mixin(f, LoadoutButtonMixin);
        f:SetSize(LOADOUT_BUTTON_WIDTH, LOADOUT_BUTTON_HEIGHT_COLLAPSED);
        f.index = index;

        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnClick", f.OnClick);
        f:SetScript("OnDoubleClick", f.OnDoubleClick);

        f.Name = f:CreateFontString(nil, "OVERLAY", "NarciGemmaFontLarge");
        f.Name:SetJustifyH("LEFT");
        f.Name:SetPoint("LEFT", f, "LEFT", 32, 0);

        return f
    end
end




local RightIconMixin = {};
do
    function RightIconMixin:Init()
        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnHide", self.OnHide);
    end

    function RightIconMixin:SetEquipped()
        AtlasUtil:SetAtlas(self.Icon, "remix-loadout-checkmark");
        self.description = L["Loadout Equipped"];
    end

    function RightIconMixin:SetLastApplied()
        AtlasUtil:SetAtlas(self.Icon, "remix-loadout-bluestar");
        self.description = L["Last Used Loadout"];
    end

    function RightIconMixin:OnEnter()
        SimpleTooltip:ShowTooltip(self, self.description);
    end

    function RightIconMixin:OnLeave()
        SimpleTooltip:FadeOut();

        if self.parentButton and self.parentButton:IsShown() then
            self.parentButton:OnLeave();
        end
    end

    function RightIconMixin:OnHide()
        self:OnLeave();
    end
    
    function RightIconMixin:SetSmall(state)
        if state then
            self.Icon:SetSize(18, 18);
            self:EnableMouse(false);
        else
            self.Icon:SetSize(24, 24);
            self:EnableMouse(true);
        end
    end

    function RightIconMixin:AnchorToLoadoutButton(loadoutButton)
        self.parentButton = loadoutButton;
        self:ClearAllPoints();
        if loadoutButton.isExpanded then
            ListRightIcon:SetPoint("RIGHT", loadoutButton, "RIGHT", -12, 0);
            ListRightIcon:SetSmall(false);
        else
            ListRightIcon:SetPoint("RIGHT", loadoutButton, "RIGHT", -26, 0);
            ListRightIcon:SetSmall(true);
        end
        self:SetFrameLevel(loadoutButton:GetFrameLevel() + 2);
        self:Show();
    end
end




local NewButtonMixin = {};
do
    function NewButtonMixin:Init()
        AtlasUtil:SetAtlas(self.Icon, "remix-loadout-plus");
        self.Text:SetText(L["New Loadout"]);
        self:SetHighlighed(false);

        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnClick", self.OnClick);
        self:SetScript("OnMouseDown", self.OnMouseDown);
        self:SetScript("OnMouseUp", self.OnMouseUp);
    end

    function NewButtonMixin:SetExpanded(isExpanded)
        if isExpanded and (not self.isExpanded) then
            self.isExpanded = true;
            self:SetHeight(LOADOUT_BUTTON_HEIGHT_EXPANDED);
        elseif (not isExpanded) and self.isExpanded then
            self.isExpanded = false;
            self:SetHeight(LOADOUT_BUTTON_HEIGHT_COLLAPSED);
        end
    end

    function NewButtonMixin:SetHighlighed(state)
        if state then
            self.Text:SetTextColor(0.098, 1.000, 0.098);    --0.098, 1.000, 0.098  1, 1, 1
            self.Icon:SetVertexColor(0.098, 1.000, 0.098);
        else
            self.Text:SetTextColor(0.67, 0.67, 0.67);
            self.Icon:SetVertexColor(0.67, 0.67, 0.67);
        end
    end

    function NewButtonMixin:OnEnter()
        self:SetHighlighed(true);
        LoadoutFrame:SetExpandedButton(self);
        if LoadoutFrame:IsAnyDataSelected() then
            self:SetExpanded(false);
        else
            self:SetExpanded(true);
        end
    end

    function NewButtonMixin:OnLeave()
        self:SetHighlighed(false);
        LoadoutFrame:SetExpandedButton(nil);
        self:SetExpanded(false);
    end

    function NewButtonMixin:OnClick()
        LoadoutFrame:OpenEditWindow();
    end

    function NewButtonMixin:OnMouseDown(button)
        if button == "LeftButton" then
            self.Icon:SetPoint("LEFT", self, "LEFT", 30, -1);
        end
    end

    function NewButtonMixin:OnMouseUp()
        self.Icon:SetPoint("LEFT", self, "LEFT", 30, 0);
    end
end




local FOOTER_BUTTON_HEIGHT = 40;
local FOOTER_BUTTON_OFFSET = 16;
local FOOTER_BUTTON_WIDTH = 338 - 2*FOOTER_BUTTON_OFFSET - FOOTER_BUTTON_HEIGHT - 8;

local function SetupThreeSliceButton(self)
    self:SetSize(FOOTER_BUTTON_WIDTH, FOOTER_BUTTON_HEIGHT);

    if not self.ButtonText then
        self.ButtonText = self:CreateFontString(nil, "OVERLAY", "NarciGemmaFontLarge");
    end
    self.ButtonText:SetJustifyH("CENTER");
    self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, 0);
    self.ButtonText:SetWidth(FOOTER_BUTTON_WIDTH - 64);

    self.Left = self:CreateTexture(nil, "BACKGROUND");
    self.Center = self:CreateTexture(nil, "BACKGROUND");
    self.Right = self:CreateTexture(nil, "BACKGROUND");

    self.Left:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0);
    self.Right:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
    self.Center:SetPoint("TOPLEFT", self.Left, "TOPRIGHT", 0, 0);
    self.Center:SetPoint("BOTTOMRIGHT", self.Right, "BOTTOMLEFT", 0, 0);


    AtlasUtil:SetAtlas(self.Left, "remix-loadout-equip-left");
    AtlasUtil:SetAtlas(self.Right, "remix-loadout-equip-right");
    AtlasUtil:SetAtlas(self.Center, "remix-loadout-equip-center");
    --self.Center:SetHorizTile(true);   --Doesn't work?
end




local EquipButtonMixin = {};
do
    local HIGHLIGHT_MIN_ALPHA = 0.2;

    local function HighlightFrame_OnUpdate(self, elapsed)
        if self.isFocused then
            if self.targetAlpha then
                self.breathAlpha = self.breathAlpha + 6*elapsed;
                if self.breathAlpha >= 1 then
                    self.breathAlpha = 1;
                    self.targetAlpha = nil;
                end
                self.BreathLight:SetAlpha(self.breathAlpha);
            end
        else
            self.breathAlpha = self.breathAlpha + self.breathDelta * elapsed;
            if self.breathAlpha >= 1 then
                self.breathDelta = -0.5;
                self.breathAlpha = 1;
            elseif self.breathAlpha <= HIGHLIGHT_MIN_ALPHA then
                self.breathDelta = 1;
                self.breathAlpha = HIGHLIGHT_MIN_ALPHA;
            end
            self.BreathLight:SetAlpha(self.breathAlpha);
        end
    end

    function EquipButtonMixin:Init()
        self.Init = nil;

        SetupThreeSliceButton(self);

        self:ClearAllPoints();
        self:SetPoint("LEFT", LoadoutFrame, "BOTTOMLEFT", FOOTER_BUTTON_OFFSET, 34);

        AtlasUtil:SetAtlas(self.HighlightFrame.BreathLight, "remix-loadout-equip-breathlight");
        AtlasUtil:SetAtlas(self.HighlightFrame.LineLight, "remix-loadout-equip-linelight");

        self.HighlightFrame:SetScript("OnUpdate", HighlightFrame_OnUpdate);

        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnEnable", self.OnEnable);
        self:SetScript("OnDisable", self.OnDisable);
        self:SetScript("OnMouseDown", self.OnMouseDown);
        self:SetScript("OnMouseUp", self.OnMouseUp);
        self:SetScript("OnClick", self.OnClick);

        self:OnClearSelection();
    end

    function EquipButtonMixin:OnClearSelection()
        self.action = nil;
        self.actionType = nil;
        self.ButtonText:SetText(L["Select A Loadout"]);
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
        self:Disable();
    end

    function EquipButtonMixin:SetClickTimes(n, itemMissing)
        if n == 0 then
            self:Disable();
            if itemMissing then
                self.ButtonText:SetText(L["Loadout Equipped Partially"]);
            else
                self.ButtonText:SetText(L["Loadout Equipped"]);
            end
            self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
        elseif n == 1 then
            self:Enable();
            self.ButtonText:SetText(string.format(L["Format Click Times To Equip Singular"], n));
            self.ButtonText:SetTextColor(1, 1, 1);
        else
            self:Enable();
            self.ButtonText:SetText(string.format(L["Format Click Times To Equip Plural"], n));
            self.ButtonText:SetTextColor(1, 1, 1);
        end
    end

    function EquipButtonMixin:SetRequiredBagSpace(amount)
        self:Disable();
        self.ButtonText:SetText(L["Format Free Up Bag Slot"]:format(amount));
        self.ButtonText:SetTextColor(1, 0.282, 0);
    end

    function EquipButtonMixin:OnLoadoutSelected()
        self:Update();
        self:PlaySelectionFeedback();
    end

    function EquipButtonMixin:Update()
        if Automation:IsProcessing() then
            self:Disable();
            local text = Automation:GetProcessText();
            if not text then
                text = L["Equipping Gems"];
            end
            self.ButtonText:SetText(text);
            self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
            return
        end

        local loadoutIndex = LoadoutFrame:GetSelectedLoadoutIndex();
        Gemma.HideActionButton();

        if loadoutIndex then
            local numClicks;
            local action;

            local searchStatsOnly = LoadoutUtil:IsLoadoutEquipped(loadoutIndex);

            local slotActions, errors, requiredBagSpace = LoadoutUtil:GetSlotActionsForLoadout(loadoutIndex, searchStatsOnly);
            if not Gemma:DoesBagHaveEnoughSpace(requiredBagSpace) then
                self:SetRequiredBagSpace(requiredBagSpace);
                return
            end

            local itemMissing = #errors > 0

            local numRemoval = #slotActions.remove;
            local numInsert = #slotActions.insert;
            numClicks = numRemoval;

            if numRemoval == 0 and numInsert == 0 then
                numClicks = 0;
            else
                if numInsert > 0 then
                    numClicks = numClicks + 1;
                end
            end

            if numRemoval == 0 then
                action = slotActions.insert;
                self.actionType = 2;
            else
                action = slotActions.remove[1];
                self.actionType = 1;
            end

            self:SetClickTimes(numClicks, itemMissing);
            self.action = action;

            if numClicks == 0 then
                LoadoutUtil:UpdateAppliedTime(loadoutIndex);
            end

            if self:IsMouseOver() then
                self:OnEnter();
            end
        else
            self:OnClearSelection();
        end
    end

    function EquipButtonMixin:PlaySelectionFeedback()
        --self.AnimSelect:Stop();
        --self.AnimSelect:Play();
        self.HighlightFrame.breathDelta = 8;
    end

    local function RegisterBagEvent_OnUpdate(self, elapsed)
        self.processDelay = self.processDelay + elapsed;
        if self.processDelay >= 0 then
            self.processDelay = -1;
            if LoadoutFrame:IsVisible() then
                if LoadoutFrame:IsMouseOver() then

                else
                    self:SetScript("OnUpdate", nil);
                    LoadoutFrame:RegisterEvent("BAG_UPDATE");
                end
            else
                self:SetScript("OnUpdate", nil);
            end
        end
    end

    function EquipButtonMixin:PauseBagEvent(pause)
        --We update our frame x sec after "BAG_UPDATE" which affects EquipButton Action

        self.processDelay = -1

        if pause then
            LoadoutFrame:UnregisterEvent("BAG_UPDATE");
            self:SetScript("OnUpdate", RegisterBagEvent_OnUpdate);
        else
            LoadoutFrame:RegisterEvent("BAG_UPDATE");
            self:SetScript("OnUpdate", nil);
        end
    end

    function EquipButtonMixin:OnEnter(motion, fromActionButton)
        if not self:IsEnabled() then return end;

        FadeFrame(self.HighlightFrame.LineLight, 0.15, 1);
        FadeFrame(self.HighlightFrame, 0.15, 1);
        self.HighlightFrame.isFocused = true;
        self.HighlightFrame.targetAlpha = true;

        if fromActionButton then return end;

        if self.action then
            if self.actionType == 1 then --Remove
                local ActionButton = AcquireActionButton(self);
                if ActionButton then
                    local arg1, arg2 = self.action[1], self.action[2];
                    if arg2 then
                        self:PauseBagEvent(true);
                        ActionButton:SetAction_RemovePandariaGemOnPlayer(arg1, arg2);
                    else
                        self:PauseBagEvent(false);
                        ActionButton:SetAction_RemovePandariaGemInBag(arg1);
                    end
                end
            else --Insert

            end
        end
    end

    function EquipButtonMixin:OnLeave(motion, fromActionButton)
        FadeFrame(self.HighlightFrame.LineLight, 0.15, 0);
        self.HighlightFrame.isFocused = false;
        self.HighlightFrame.targetAlpha = true;
    end

    function EquipButtonMixin:ShowHighlight()
        self.HighlightFrame.breathAlpha = 0;
        self.HighlightFrame.breathDelta = 1;
        self.HighlightFrame:Show();
    end

    function EquipButtonMixin:SetBackgroundAlpha(alpha)
        self.Left:SetAlpha(alpha);
        self.Center:SetAlpha(alpha);
        self.Right:SetAlpha(alpha);
    end

    function EquipButtonMixin:OnEnable()
        self:SetBackgroundAlpha(1);
        self:ShowHighlight();
    end

    function EquipButtonMixin:OnDisable()
        self:SetBackgroundAlpha(0.5);
        self:OnLeave(true);
        self.HighlightFrame:Hide();
        self:OnMouseUp();
    end

    function EquipButtonMixin:OnMouseDown(button)
        if self:IsEnabled() and button == "LeftButton" then
            --self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, -2);
            self.AnimPushed:Stop();
            self.AnimPushed:Play();
        end

        LoadoutFrame:HideEditWindow();
    end

    function EquipButtonMixin:OnMouseUp()
        --self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, 0);
    end

    function EquipButtonMixin:OnClick(button)
        if button ~= "LeftButton" then return end;

        --MainFrame:ShowActionBlocker();
        if self.action and self.actionType == 2 then
            Automation:EquipGems(self.action);
        end
    end
end




local EditButtonMixin = {};
do
    function EditButtonMixin:Init()
        self:SetSize(FOOTER_BUTTON_HEIGHT, FOOTER_BUTTON_HEIGHT);
        self:ClearAllPoints();
        self:SetPoint("RIGHT", self:GetParent(), "BOTTOMRIGHT", -FOOTER_BUTTON_OFFSET, 34);

        self.Background = self:CreateTexture(nil, "BACKGROUND");
        self.Background:SetAllPoints(true);
        AtlasUtil:SetAtlas(self.Background, "remix-loadout-edit-bg");

        self.Icon = self:CreateTexture(nil, "OVERLAY");
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0);
        AtlasUtil:SetAtlas(self.Icon, "remix-loadout-edit-setting");

        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnEnable", self.OnEnable);
        self:SetScript("OnDisable", self.OnDisable);
        self:SetScript("OnMouseDown", self.OnMouseDown);
        self:SetScript("OnMouseUp", self.OnMouseUp);
        self:SetScript("OnClick", self.OnClick);

        self:Disable();

        self:RegisterForClicks("LeftButtonUp");
        self.tooltipText = L["Edit Loadout"];
    end

    function EditButtonMixin:OnLoadoutSelected()
        self:Enable();
    end

    function EditButtonMixin:OnClearSelection()
        self:Disable();
    end

    function EditButtonMixin:OnEnter()
        self.Icon:SetVertexColor(1, 1, 1);
        AtlasUtil:SetAtlas(self.Background, "remix-loadout-edit-highlight");
        SimpleTooltip:ShowTooltip(self, self.tooltipText);
    end

    function EditButtonMixin:OnLeave()
        self.Icon:SetVertexColor(0.67, 0.67, 0.67);
        AtlasUtil:SetAtlas(self.Background, "remix-loadout-edit-bg");
        SimpleTooltip:FadeOut();
    end

    function EditButtonMixin:OnEnable()
        self:SetAlpha(1);
    end

    function EditButtonMixin:OnDisable()
        self:SetAlpha(0.5);
        self:OnLeave();
        self:OnMouseUp();
    end

    function EditButtonMixin:OnMouseDown()
        if not self:IsEnabled() then return end;
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, -1);
    end

    function EditButtonMixin:OnMouseUp()
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0);
    end

    function EditButtonMixin:OnClick(button)
        if EditWindow and EditWindow:IsShown() then
            LoadoutFrame:HideEditWindow();
            return
        end

        local index = LoadoutFrame.selectedIndex;
        if not index then return end;

        LoadoutFrame:OpenEditWindow(index);
    end
end




local MouseOverFrameMixin = {};
do
    local PADDING_H = 20;
    local PADDING_V = 8;

    function MouseOverFrameMixin:Init()
        self.Init = nil;
        self.icons = {};
  
        local iconSize = 16;
        local iconGap = 2;
        local numIcons = 6;

        for i = 1, numIcons do
            local icon = self:CreateTexture(nil, "OVERLAY");
            self.icons[i] = icon;
            icon:SetSize(iconSize, iconSize);
            icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
            icon:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", PADDING_H + (i - 1) * (iconSize + iconGap), PADDING_V);
            icon:SetAlpha(1 - 0.15*(i - 1));
        end

        local iconFrameWidth = numIcons * (iconSize + iconGap) - iconGap;

        self.StatText:ClearAllPoints();
        self.StatText:SetPoint("LEFT", self, "BOTTOMLEFT", PADDING_H + iconFrameWidth + PADDING_H, PADDING_V + 0.5*iconSize);
        self.Name:SetPoint("TOPLEFT", self, "TOPLEFT", PADDING_H, -PADDING_V);
    end

    function MouseOverFrameMixin:SetLoadout(index)
        if self.Init then
            self:Init();
        end

        self.loadoutIndex = index;

        local data = LoadoutUtil:GetLoadoutData(index);
        if not data then return end;

        local overview = LoadoutUtil:GetLoadoutOverview(index);
        self.Name:SetText(data.name);
        self.StatText:SetText(overview.statText);
    
        for i = 1, 6 do
            self.icons[i]:SetTexture(overview.icons[i]);
        end
    end

    function MouseOverFrameMixin:SetSelected(isSelected)
        self.isSelected = isSelected;
        self:UpdateBackground();
    end

    function MouseOverFrameMixin:UpdateBackground()
        if self.isSelected then
            local isEquipped = self.loadoutIndex and self.loadoutIndex == LoadoutUtil:GetEquippedLoadoutIndex();
            if isEquipped then
                AtlasUtil:SetAtlas(MouseOverFrame.Background, "remix-loadout-detail-selection-equipped");
            else
                AtlasUtil:SetAtlas(MouseOverFrame.Background, "remix-loadout-detail-selection-regular");
            end
        else
            AtlasUtil:SetAtlas(MouseOverFrame.Background, "remix-loadout-detail-bg");
        end
    end

    function MouseOverFrameMixin:UpdateLoadout()
        if self.loadoutIndex then
            self:SetLoadout(self.loadoutIndex);
        end
    end
end




local LoadoutFrameMixin = {};
Gemma.LoadoutFrameMixin = LoadoutFrameMixin;
do
    function LoadoutFrameMixin:OnLoad()
        SimpleTooltip = Gemma.CreateSimpleTooltip(self);

        MainFrame = Gemma.MainFrame;
        LoadoutFrame = self;

        EquipButton = self.EquipButton;
        Mixin(EquipButton, EquipButtonMixin);

        EditButton = self.EditButton;
        Mixin(EditButton, EditButtonMixin);

        MouseOverFrame = self.MouseOverFrame;
        MouseOverFrame:SetSize(322, LOADOUT_BUTTON_HEIGHT_EXPANDED);
        AtlasUtil:SetAtlas(MouseOverFrame.Background, "remix-loadout-detail-bg");
        Mixin(MouseOverFrame, MouseOverFrameMixin);

        ListRightIcon = self.LoadoutList.RightIcon;
        

        self.loadoutButtons = {};
        self.Title:SetTextColor(0.88, 0.88, 0.88);
        self:SetTitle(L["Loadout"].."  |cff80808010/10|r");

        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnHide", self.OnHide);

        AtlasUtil:SetAtlas(self.Divider, "remix-ui-divider");
        --AtlasUtil:SetAtlas(EquipButton.Background, "remix-loadout-detail-bg");


        AtlasUtil:SetAtlas(self.ButtonHighlight.Texture, "remix-listbutton-highlight");
        self.ButtonHighlight.Texture:SetBlendMode("ADD");
    end

    function LoadoutFrameMixin:InitFrame()
        self.InitFrame = nil;

        LoadoutUtil:LoadSaves();
        DataProvider = Gemma:GetDataProviderByName("Pandaria");
        EditButton:Init();
        EquipButton:Init();

        Mixin(self.LoadoutList.NewButton, NewButtonMixin);
        self.LoadoutList.NewButton:Init();

        Mixin(ListRightIcon, RightIconMixin);
        ListRightIcon:Init();

        self.equipmentChanged = true;
        self.loadoutListChanged = true;
        self:RequestUpdate();

        self.defaultSelecetdLoadoutIndex = LoadoutUtil:GetLastAppliedLoadoutIndex();
    end

    function LoadoutFrameMixin:OnShow()
        if self.InitFrame then
            self:InitFrame();
        end

        self:SetScript("OnEvent", self.OnEvent);
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
        self:RegisterEvent("BAG_UPDATE");
    end

    function LoadoutFrameMixin:OnHide()
        --self:UnregisterEvent("BAG_UPDATE");
    end

    function LoadoutFrameMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;

        if self.t >= 0 then
            self.t = 0;
        else
            return
        end

        local anyAction;

        if self.equipmentChanged then
            anyAction = true;
            self:PostEquipmentChanged();
        end

        if self.loadoutListChanged then
            anyAction = true;
            self:PostLoadoutListChanged();
        end

        if not anyAction then
            self:SetScript("OnUpdate", nil);
            self.t = nil;
        end
    end

    function LoadoutFrameMixin:RequestUpdate(delay)
        delay = delay and -delay or 0;
        self.t = delay;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function LoadoutFrameMixin:OnEvent(event, ...)
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" then
            self.equipmentChanged = true;
            self.loadoutListChanged = true;

            if event == "BAG_UPDATE" then
                self:RequestUpdate(0.0);    --Longer?
            else
                self:RequestUpdate();
            end

            if not self:IsVisible() then
                self:UnregisterEvent(event);
                return
            end
        end

        --print(GetTime(), event);
    end

    function LoadoutFrameMixin:PostEquipmentChanged()
        self.equipmentChanged = false;
        LoadoutUtil.currentGemInfo = nil;
        LoadoutUtil.currentSlotGems = nil;
        LoadoutUtil.equippedLoadoutIndex = nil;

        EquipButton:Update();
    end

    function LoadoutFrameMixin:PostLoadoutListChanged()
        self.loadoutListChanged = nil;
        self:UpdateLoadoutList();
    end

    function LoadoutFrameMixin:UpdateRightIcon()
        for i, button in ipairs(self.loadoutButtons) do
            if button:IsShown() then
                if i == self.equippedIndex then
                    ListRightIcon:SetEquipped();
                    ListRightIcon:AnchorToLoadoutButton(button);
                    return
                elseif i == self.lastAppliedIndex then
                    ListRightIcon:SetLastApplied();
                    ListRightIcon:AnchorToLoadoutButton(button);
                    return
                end
            else
                break
            end
        end

        ListRightIcon:Hide();
    end

    function LoadoutFrameMixin:UpdateLoadoutList()
        local numSaves = LoadoutUtil:GetNumSaves();
        local newButtonIndex = numSaves + 1;   -- +New Loadout Button
        local button;
        local data;

        local NewButton = self.LoadoutList.NewButton;
        NewButton:Hide();

        local equippedIndex = LoadoutUtil:GetEquippedLoadoutIndex();
        local lastAppliedIndex;
        if not equippedIndex then
            lastAppliedIndex = LoadoutUtil:GetLastAppliedLoadoutIndex();
        end

        self.equippedIndex = equippedIndex;
        self.lastAppliedIndex = lastAppliedIndex;



        for i = 1, MAX_SAVES do
            data = LoadoutUtil:GetLoadoutData(i);
            button = self.loadoutButtons[i];
            if data then
                if not button then
                    button = CreateLoadoutButton(self.LoadoutList, i);
                    self.loadoutButtons[i] = button;
                    if i == 1 then
                        button:SetPoint("TOP", self.LoadoutList, "TOP", 0, 0);
                    else
                        button:SetPoint("TOP", self.loadoutButtons[i - 1], "BOTTOM", 0, 0);
                    end
                end
                button:SetData(data, i == equippedIndex);
                button:Show();
            else
                if button then
                    button:Hide();
                end

                if i == newButtonIndex then
                    NewButton:ClearAllPoints();
                    NewButton:Show();
                    if i == 1 then
                        NewButton:SetPoint("TOP", self.LoadoutList, "TOP", 0, 0);
                    else
                        NewButton:SetPoint("TOP", self.loadoutButtons[i - 1], "BOTTOM", 0, 0);
                    end
                end
            end
        end

        self:SetTitle(L["Loadout"].."  |cff808080"..numSaves.."/"..MAX_SAVES.."|r");

        self:UpdateRightIcon();


        MouseOverFrame:UpdateBackground();
        MouseOverFrame:UpdateLoadout();

        if self.defaultSelecetdLoadoutIndex then
            local loadoutIndex = self.defaultSelecetdLoadoutIndex;
            self.defaultSelecetdLoadoutIndex = nil;
            C_Timer.After(0.0, function()
                self:SelectLoadoutByIndex(loadoutIndex);
            end);
        end
    end

    function LoadoutFrameMixin:SetTitle(title)
        self.Title:SetText(title);
    end

    function LoadoutFrameMixin:SetExpandedButton(loadoutButton)
        local hl = self.ButtonHighlight;
        hl:ClearAllPoints();
        if loadoutButton then
            hl:SetParent(loadoutButton);
            hl:SetPoint("TOPLEFT", loadoutButton, "TOPLEFT", 0, 0);
            hl:SetPoint("BOTTOMRIGHT", loadoutButton, "BOTTOMRIGHT", 0, 0);
            hl:Show();
        else
            hl:Hide();
        end

        if self:IsAnyDataSelected() then
            return
        end

        for i, button in ipairs(self.loadoutButtons) do
            if button == loadoutButton then
                button:SetExpanded(true);
            else
                button:SetExpanded(false);
            end
        end

        MouseOverFrame:ClearAllPoints();

        if loadoutButton and loadoutButton.index then
            MouseOverFrame:SetPoint("CENTER", loadoutButton, "CENTER", 0, 0);
            MouseOverFrame.Name:SetText(loadoutButton.Name:GetText());
            MouseOverFrame:Show();
        else
            MouseOverFrame:Hide();
        end

        self:UpdateRightIcon();
    end

    function LoadoutFrameMixin:GetSelectedLoadoutIndex()
        return self.selectedIndex
    end

    function LoadoutFrameMixin:IsAnyDataSelected()
        return self.selectedIndex ~= nil
    end

    function LoadoutFrameMixin:IsDataSelectedByIndex(index)
        return index and index == self.selectedIndex
    end

    function LoadoutFrameMixin:SelectLoadoutByIndex(index)
        self.selectedIndex = nil;
        local button = self.loadoutButtons[index];
        self:SetExpandedButton(button);

        local data = LoadoutUtil:GetLoadoutData(index);
        self.selectedData = data;
        self.selectedIndex = index;

        if data then
            MouseOverFrame:SetLoadout(index);
            MouseOverFrame:SetSelected(true);
            EquipButton:OnLoadoutSelected(index);
            EditButton:OnLoadoutSelected(index);

            if self:IsEditWindowShown() then
                if index ~= EditWindow.loadoutIndex then
                    EditWindow:SetLoadout(index);
                end
            end
        else
            self:ClearSelection();
        end
    end

    function LoadoutFrameMixin:ClearSelection()
        self.selectedData = nil;
        self.selectedIndex = nil;
        MouseOverFrame:SetSelected(false);
        EquipButton:OnClearSelection();
        EditButton:OnClearSelection();
    end
end



local EDIT_OPTIONS = {
    "head",
    "feet",
    "tinker",
    "stats1",
    "stats2",
    "stats3",
};

local OPTION_BUTTON_HEIGHT = 32;
local CreateEditOption;
local CreateNameEditButton;

do  --Edit Options
    local PADDING_H = 20;
    local ARROW_SIZE = 16;

    local OptionButtonMixin = {};

    local function GetChoiceText_ItemID(self, itemID)
        local anySelection = itemID ~= nil;
        local fullySelected = anySelection;
        local text;

        if anySelection then
            text = ItemCache:GetItemName(itemID, self);
        end

        return text, anySelection, fullySelected
    end

    local function GetChoiceText_ItemList(self, list)
        local points = list and #list or 0;
        local anySelection = points > 0;
        local fullySelected = (not self.pointsRequired) or (points >= self.pointsRequired);
        local text;

        if anySelection then
            text = L["Format Number Items Selected"]:format(points);
        end

        return text, anySelection, fullySelected
    end

    local function GetChoiceText_Stats(self, stats)
        local points = 0;

        if stats then
            for _, amount in pairs(stats) do
                points = points + amount;
            end
        end

        local fullySelected = (not self.pointsRequired) or (points >= self.pointsRequired);
        local anySelection = fullySelected;
        local text;

        if fullySelected then
            text = LoadoutUtil:FormatStatText(stats);
        end

        return text, anySelection, fullySelected
    end

    function OptionButtonMixin:OnItemLoaded(itemID)
        self:OnSelectionChanged();
    end

    function OptionButtonMixin:SetCategory_head()
        self.Category:SetText(META_GEM);
        self.pointsRequired = 1;
        self.GetChoiceText = GetChoiceText_ItemID;
    end

    function OptionButtonMixin:SetCategory_feet()
        self.Category:SetText(COGWHEEL_GEM);
        self.pointsRequired = 1;
        self.GetChoiceText = GetChoiceText_ItemID;
    end

    function OptionButtonMixin:SetCategory_tinker()
        self.Category:SetText(L["Pandamonium Gem Category 2"]);
        self.pointsRequired = 12;
        self.GetChoiceText = GetChoiceText_ItemList;
    end

    function OptionButtonMixin:SetCategory_stats1()
        self.Category:SetText(L["Pandamonium Slot Category 1"]);
        self.pointsRequired = 6;
        self.isStat = true;
        self.GetChoiceText = GetChoiceText_Stats;
    end

    function OptionButtonMixin:SetCategory_stats2()
        self.Category:SetText(L["Pandamonium Slot Category 2"]);
        self.pointsRequired = 6;
        self.isStat = true;
        self.GetChoiceText = GetChoiceText_Stats;
    end

    function OptionButtonMixin:SetCategory_stats3()
        self.Category:SetText(L["Pandamonium Slot Category 3"]);
        self.pointsRequired = 9;
        self.isStat = true;
        self.GetChoiceText = GetChoiceText_Stats;
    end

    function OptionButtonMixin:UpdateChoiceText()
        local text, anySelection, fullySelected = self:GetChoiceText(self.choice);
        if fullySelected then
            self.ChoiceText:SetText(text);
            if self.isStat then
                self.ChoiceText:SetTextColor(0.5, 0.5, 0.5);
            else
                self.ChoiceText:SetTextColor(0.88, 0.88, 0.88);
            end
            self.Category:SetTextColor(0.67, 0.67, 0.67);
            self.Arrow:SetVertexColor(0.88, 0.88, 0.88);
        else
            if text then
                self.ChoiceText:SetText(text);
            else
                self.ChoiceText:SetText(L["Select Gems"]);
            end
            self.ChoiceText:SetTextColor(1, 0.82, 0); --0.37, 0.74, 0.42
            self.Category:SetTextColor(0.67, 0.67, 0.67);
            self.Arrow:SetVertexColor(1, 0.82, 0);
        end
        self.fullySelected = fullySelected;
    end

    function OptionButtonMixin:SetChoice(choice)
        self.choice = choice;
        self:UpdateChoiceText();
        return self.fullySelected
    end

    function OptionButtonMixin:SetCategory(key)
        self.key = key;
        self["SetCategory_"..key](self);
        local textWidth = self.Category:GetWrappedWidth();
        self.ChoiceText:SetWidth(math.floor(LOADOUT_BUTTON_WIDTH - (textWidth - ARROW_SIZE - OPTION_BUTTON_HEIGHT)));
    end

    function OptionButtonMixin:OnEnter()
        self.Category:SetTextColor(1, 1, 1);
        EditWindow:HighlightButton(self);
    end

    function OptionButtonMixin:OnLeave()
        self.Category:SetTextColor(0.67, 0.67, 0.67);
        EditWindow:HighlightButton(nil);
    end

    function OptionButtonMixin:OnClick()
        EditWindow:ShowPlanner(self.key);
    end

    function CreateEditOption(parent)
        local f = CreateFrame("Button", nil, parent);
        f:SetSize(LOADOUT_BUTTON_WIDTH, OPTION_BUTTON_HEIGHT);

        f.Category = f:CreateFontString(nil, "OVERLAY", "NarciGemmaFontLarge");
        f.Category:SetJustifyH("LEFT");
        f.Category:SetPoint("LEFT", f, "LEFT", PADDING_H, 0);
        f.Category:SetTextColor(0.67, 0.67, 0.67);

        f.ChoiceText = f:CreateFontString(nil, "OVERLAY", "NarciGemmaFontMedium");
        f.ChoiceText:SetJustifyH("RIGHT");
        f.ChoiceText:SetPoint("RIGHT", f, "RIGHT", -PADDING_H - ARROW_SIZE, 0);
        f.ChoiceText:SetMaxLines(1);

        f.Arrow = f:CreateTexture(nil, "OVERLAY");
        f.Arrow:SetPoint("RIGHT", f, "RIGHT", -PADDING_H, 0);
        AtlasUtil:SetAtlas(f.Arrow, "gemlist-next");

        Mixin(f, OptionButtonMixin);

        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnClick", f.OnClick);

        return f
    end


    local NameButtonMixin = {};
    NameButtonMixin.OnEnter = OptionButtonMixin.OnEnter;
    NameButtonMixin.OnLeave = OptionButtonMixin.OnLeave;

    function NameButtonMixin:OnClick()
        self.EditBox:SetFocus();
    end

    function NameButtonMixin:SetLoadoutName(name)
        self.EditBox:SetText(name or "");
        self.EditBox:SetHighlighed(false);
    end

    function NameButtonMixin:GetText()
        local text = strtrim(self.EditBox:GetText());
        if text ~= "" then
            return text
        end
    end

    local EditBoxMixin = {};

    function EditBoxMixin:SetHighlighed(state)
        if state then
            self.Border:SetVertexColor(1, 1, 1);
        else
            if self:IsTextValid() then
                self.Border:SetVertexColor(0.5, 0.5, 0.5);
            else
                self.Border:SetVertexColor(1, 0.82, 0.0);
            end
        end
    end

    function EditBoxMixin:OnEnter()
        OptionButtonMixin.OnEnter(self:GetParent());
    end

    function EditBoxMixin:OnLeave()
        OptionButtonMixin.OnLeave(self:GetParent());
    end

    function EditBoxMixin:OnEditFocusGained()
        self:SetHighlighed(true);
    end

    function EditBoxMixin:OnEditFocusLost()
        self:ClearHighlightText();

        local text = strtrim(self:GetText() or "");

        if text == "" and self.defaultText then
            text = self.defaultText;
        end

        self:SetText(text);
        self:SetHighlighed(false);

        EditWindow:UpdateEditWindow();
    end

    function EditBoxMixin:OnEscapePressed()
        self:ClearFocus();
    end

    function EditBoxMixin:OnEnterPressed()
        self:ClearFocus();
    end

    function EditBoxMixin:IsTextValid()
        return strtrim(self:GetText() or "") ~= ""
    end

    function CreateNameEditButton(parent)
        local f = CreateFrame("Button", nil, parent);
        f:SetSize(LOADOUT_BUTTON_WIDTH, OPTION_BUTTON_HEIGHT);

        f.Category = f:CreateFontString(nil, "OVERLAY", "NarciGemmaFontLarge");
        f.Category:SetJustifyH("LEFT");
        f.Category:SetPoint("LEFT", f, "LEFT", PADDING_H, 0);
        f.Category:SetTextColor(0.67, 0.67, 0.67);
        f.Category:SetText(NAME);

        local eb = CreateFrame("EditBox", nil, f);
        f.EditBox = eb;
        eb:SetFontObject("NarciGemmaFontMedium");
        eb:SetTextColor(0.88, 0.88, 0.88);
        eb:SetMaxLetters(16);
        eb:SetTextInsets(8, 8, 0, 0);
        eb:SetJustifyH("CENTER");
        eb:SetAutoFocus(false);
        eb:SetSize(24*7, 24);
        eb:SetPoint("RIGHT", f, "RIGHT", -PADDING_H -2, 0);
        eb.Border = eb:CreateTexture(nil, "BACKGROUND");
        eb.Border:SetAllPoints(true);
        AtlasUtil:SetAtlas(eb.Border, "remix-loadout-editbox-bg");
        --eb.Background:GetTextureSliceMode(0);
        --TextureSlice is kinda broken since 10.2.7

        Mixin(f, NameButtonMixin);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnClick", f.OnClick);

        Mixin(eb, EditBoxMixin);
        eb:SetScript("OnEnter", eb.OnEnter);
        eb:SetScript("OnLeave", eb.OnLeave);
        eb:SetScript("OnEditFocusGained", eb.OnEditFocusGained);
        eb:SetScript("OnEditFocusLost", eb.OnEditFocusLost);
        eb:SetScript("OnEscapePressed", eb.OnEscapePressed);
        eb:SetScript("OnEnterPressed", eb.OnEnterPressed);

        return f
    end
end




local SaveButtonMixin = {};
do  --Save Button
    function SaveButtonMixin:Init()
        self.Init = nil;

        SetupThreeSliceButton(self);

        self.ButtonText:SetText(SAVE);
        self.ButtonText:SetTextColor(1, 0.82, 0);

        self:ClearAllPoints();
        self:SetPoint("LEFT", self:GetParent(), "BOTTOMLEFT", FOOTER_BUTTON_OFFSET, 34);
        self:SetHighlighed(false);

        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnMouseDown", self.OnMouseDown);
        self:SetScript("OnMouseUp", self.OnMouseUp);
        self:SetScript("OnEnable", self.OnEnable);
        self:SetScript("OnDisable", self.OnDisable);
        self:SetScript("OnClick", self.OnClick);

        self:SetMotionScriptsWhileDisabled(true);
    end

    function SaveButtonMixin:OnEnable()
        if self:IsMouseOver() then
            self:SetHighlighed(true);
        else
            self:SetHighlighed(false);
        end
    end

    function SaveButtonMixin:OnDisable()
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end

    function SaveButtonMixin:SetHighlighed(state)
        if state then
            AtlasUtil:SetAtlas(self.Left, "remix-loadout-equip-hl-left");
            AtlasUtil:SetAtlas(self.Right, "remix-loadout-equip-hl-right");
            AtlasUtil:SetAtlas(self.Center, "remix-loadout-equip-hl-center");
            self.ButtonText:SetTextColor(1, 1, 1);
        else
            AtlasUtil:SetAtlas(self.Left, "remix-loadout-equip-left");
            AtlasUtil:SetAtlas(self.Right, "remix-loadout-equip-right");
            AtlasUtil:SetAtlas(self.Center, "remix-loadout-equip-center");
            if self:IsEnabled() then
                self.ButtonText:SetTextColor(1, 0.82, 0);
            else
                self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
            end
        end
    end

    function SaveButtonMixin:OnEnter()
        if self:IsEnabled() then
            self:SetHighlighed(true);
        end

        SimpleTooltip:ShowTooltip(self, self.failureReason);
    end

    function SaveButtonMixin:OnLeave()
        if self:IsEnabled() then
            self:SetHighlighed(false);
        end

        SimpleTooltip:FadeOut();
    end

    function SaveButtonMixin:OnMouseDown(button)
        if self:IsEnabled() and button == "LeftButton" then
            self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, -1);
        end
    end

    function SaveButtonMixin:OnMouseUp()
        self.ButtonText:SetPoint("CENTER", self, "CENTER", 0, 0);
    end

    function SaveButtonMixin:OnClick()
        if self:IsEnabled() then
            EditWindow:SaveChanges();
        end
    end
end

local DeleteButtonMixin = {};
do
    function DeleteButtonMixin:Init()
        self.Init = nil;

        EditButtonMixin.Init(self);
        self.deleteDuration = 1.0;
        AtlasUtil:SetAtlas(self.Icon, "remix-loadout-edit-delete");
        self:Enable();

        local bar = self:CreateTexture(nil, "OVERLAY");
        self.CounterBar = bar;
        self.barWidth = FOOTER_BUTTON_HEIGHT;
        bar:Hide();
        bar:SetColorTexture(1.000, 0.125, 0.125);
        bar:SetWidth(1);
        bar:SetHeight(4);
        bar:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4);

        self:OnLeave();
    end

    function DeleteButtonMixin:OnEnter()
        EditButtonMixin.OnEnter(self);
    end

    function DeleteButtonMixin:OnLeave()
        EditButtonMixin.OnLeave(self);
    end

    function DeleteButtonMixin:OnMouseDown(button)
        EditButtonMixin.OnMouseDown(self);
        if self:IsEnabled() and button == "LeftButton" then
            if self.useLongClick then
                self:ShowCounter();
            end
        end
    end

    function DeleteButtonMixin:OnMouseUp()
        EditButtonMixin.OnMouseUp(self);
        self:HideCounter();
    end

    function DeleteButtonMixin:OnClick()
        if self.useLongClick then
            
        else
            self:DeleteSelectedLoadout();
        end
    end

    function DeleteButtonMixin:SetLongClickMode(useLongClick)
        self.useLongClick = useLongClick;
        if useLongClick then
            self.tooltipText = L["Delete Loadout Long Click"];
        else
            self.tooltipText = L["Delete Loadout One Click"];
        end
    end

    function DeleteButtonMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        local a;
        if self.t >= self.deleteDuration then
            a = 1;
            self:HideCounter();
            self:DeleteSelectedLoadout();
        else
            a = self.t / self.deleteDuration;
        end
        self.CounterBar:SetWidth(a * self.barWidth);
    end

    function DeleteButtonMixin:DeleteSelectedLoadout()
        local loadoutIndex = EditWindow and EditWindow.loadoutIndex;
        if loadoutIndex then
            LoadoutUtil:DeleteLoadout(loadoutIndex);
        elseif EditWindow and EditWindow:IsCreatingNewLoadout() then
            EditWindow:DeleteDraft();
        end
        LoadoutFrame:HideEditWindow();
    end

    function DeleteButtonMixin:ShowCounter()
        self.CounterBar:Show();
        self.CounterBar:SetWidth(0.1);
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end

    function DeleteButtonMixin:HideCounter()
        self.CounterBar:Hide();
        self.t = nil;
        self:SetScript("OnUpdate", nil);
        EditButtonMixin.OnMouseUp(self);
    end

    function DeleteButtonMixin:OnHide()
        self:HideCounter();
    end
end




local WINDOW_GAP = 8;

do  --Edit Loadout
    local EditWindowMixin = {};

    function EditWindowMixin:SetLoadout(loadoutIndex)
        self.newLoadout = false;
        self.loadoutIndex = loadoutIndex;
        self.loadoutName = LoadoutUtil:GetLoadoutName(loadoutIndex);
        self.NameButton.EditBox.defaultText = self.loadoutName;
        self.gemInfo = LoadoutUtil:CopyLoadoutGemInfo(loadoutIndex);
        self.DeleteButton:SetLongClickMode(true);
        self.NameButton:SetLoadoutName(self.loadoutName);
        self:UpdateEditWindow();
        self:SetTitle(self.loadoutName or L["Edit Loadout"]);
        self:ShowNewLoadoutPrompt(false);

        if Planner then
            Planner:Hide();
        end
    end

    function EditWindowMixin:SetNewLoadout()
        self.newLoadout = true;
        self.loadoutIndex = nil;
        self.NameButton.EditBox.defaultText = nil;
        self.loadoutName = nil;

        if self.unsavedGemInfo then
            --Previously unsave loadout
            self.gemInfo = self.unsavedGemInfo;
            self:ShowNewLoadoutPrompt(false);
        else
            --self.gemInfo = {};
            --self.unsavedGemInfo = self.gemInfo;
            self:ShowNewLoadoutPrompt(true);
            return
        end

        self.DeleteButton:SetLongClickMode(false);
        self.NameButton:SetLoadoutName(self.loadoutName);
        self:UpdateEditWindow();

        self:SetTitle(L["New Loadout"]);
    end

    function EditWindowMixin:SetBlankLoadout()
        self.unsavedGemInfo = {};
        self:SetNewLoadout();
    end

    function EditWindowMixin:SetNewLoadoutFromEquipped()
        local gemInfo = LoadoutUtil:GetCurrentGemInfo();
        if gemInfo then
            self.unsavedGemInfo = CopyTable(gemInfo);
            self:SetNewLoadout();
        else
            self:SetBlankLoadout();
        end
    end

    function EditWindowMixin:IsCreatingNewLoadout()
        return self:IsShown() and self.newLoadout
    end

    function EditWindowMixin:DeleteDraft()
        self.unsavedGemInfo = nil;
    end

    function EditWindowMixin:UpdateEditWindow()
        local selected = true;
        local allSelected = true;

        for i, button in ipairs(self.optionButtons) do
            selected = button:SetChoice(self.gemInfo[EDIT_OPTIONS[i]]);
            allSelected = allSelected and selected;
        end


        local NameButton = self.NameButton;
        local SaveButton = self.SaveButton;

        local name = NameButton:GetText();
        self.loadoutName = name;

        local canSave;
        local showError;

        if allSelected then
            if name then
                if self:IsCreatingNewLoadout() then
                    if LoadoutUtil:DoesLoadoutNameExist(name) then
                        canSave = false;
                        SaveButton.failureReason = L["Loadout Save Failure Dupe Name Format"];
                        showError = true;
                    else
                        local isDupe, dupeName = LoadoutUtil:DoesGemLoadoutExist(self.gemInfo);
                        if isDupe then
                            canSave = false;
                            SaveButton.failureReason = L["Loadout Save Failure Dupe Loadout Format"]:format(dupeName);
                            showError = true;
                        else
                            canSave = true;
                        end
                    end
                else
                    if LoadoutUtil:DoesLoadoutNameExist(name, self.loadoutIndex) then
                        canSave = false;
                        SaveButton.failureReason = L["Loadout Save Failure Dupe Name Format"];
                        showError = true;
                    else
                        canSave = true;
                    end
                end
            else
                canSave = false;
                SaveButton.failureReason = L["Loadout Save Failure No Name"];
            end
        else
            canSave = false;
            SaveButton.failureReason = L["Loadout Save Failure Incomplete Choices"];
        end

        if canSave then
            SaveButton.failureReason = nil;
            SaveButton:Enable();
        else
            SaveButton:Disable();
        end

        if showError then
            SaveButton:OnEnter();
        else
            SimpleTooltip:FadeOut();
        end
    end

    function EditWindowMixin:ShowNewLoadoutPrompt(state)
        if state then
            self:SetTitle(L["New Loadout"]);
            if not self.PromptFrame then
                local f = CreateFrame("Frame", nil, self);
                self.PromptFrame = f;
                f:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -40);
                f:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);

                local function PromptButton_OnEnter(s)
                    s.Name:SetTextColor(1, 1, 1);
                    self:HighlightButton(s);
                end

                local function PromptButton_OnLeave(s)
                    s.Name:SetTextColor(0.67, 0.67, 0.67);
                    self:HighlightButton(nil);
                end

                local promptButtonHeight = 44;

                local function CreatePromptButton()
                    local bt = CreateFrame("Button", nil, f);
                    bt:SetSize(LOADOUT_BUTTON_WIDTH, promptButtonHeight);

                    bt:SetScript("OnEnter", f.OnEnter);
                    bt:SetScript("OnLeave", f.OnLeave);
                    bt:SetScript("OnClick", f.OnClick);

                    bt.Name = f:CreateFontString(nil, "OVERLAY", "NarciGemmaFontLarge");
                    bt.Name:SetJustifyH("LEFT");
                    bt.Name:SetPoint("LEFT", bt, "LEFT", 32, 0);
                    bt.Name:SetTextColor(0.67, 0.67, 0.67);

                    bt:SetScript("OnEnter", PromptButton_OnEnter);
                    bt:SetScript("OnLeave", PromptButton_OnLeave);

                    return bt
                end

                local numButtons = 2;
                --local fromY = -0.5*(self.PromptFrame:GetHeight() - numButtons * promptButtonHeight);
                local fromY = -0.5*promptButtonHeight;
                local bt1 = CreatePromptButton();
                bt1:SetPoint("TOP", f, "TOP", 0, fromY - 0*promptButtonHeight);
                bt1.Name:SetText(L["New Loadout Blank"]);
                bt1:SetScript("OnClick", function()
                    self:SetBlankLoadout();
                end);

                local bt2 = CreatePromptButton();
                bt2:SetPoint("TOP", f, "TOP", 0, fromY - 1*promptButtonHeight);
                bt2.Name:SetText(L["New Loadout From Equipped"]);
                bt2:SetScript("OnClick", function()
                    self:SetNewLoadoutFromEquipped();
                end);
            end
            self.PromptFrame:Show();
        else
            if self.PromptFrame then
                self.PromptFrame:Hide();
            end
        end

        state = not state;
        self.SaveButton:SetShown(state);
        self.DeleteButton:SetShown(state);
        self.OptionFrame:SetShown(state);
        self:ShowFooterDivider(state);
    end

    function EditWindowMixin:InitEditWindow()
        self.optionButtons = {};

        local button;
        local fromY = -46;

        self.OptionFrame = CreateFrame("Frame", nil, self);
        self.OptionFrame:SetAllPoints(true);

        for i, categoryKey in ipairs(EDIT_OPTIONS) do
            button = CreateEditOption(self.OptionFrame);
            self.optionButtons[i] = button;
            button:SetCategory(categoryKey);
            button:SetPoint("TOP", self, "TOP", 0, fromY + (1 - i) * OPTION_BUTTON_HEIGHT);
            button:UpdateChoiceText();
        end


        local DeleteButton = CreateFrame("Button", nil, self);
        self.DeleteButton = DeleteButton;
        Mixin(DeleteButton, DeleteButtonMixin);
        DeleteButton:Init();

        local SaveButton = CreateFrame("Button", nil, self);
        self.SaveButton = SaveButton;
        Mixin(SaveButton, SaveButtonMixin);
        SaveButton:Init();

        AtlasUtil:SetAtlas(self.ButtonHighlight.Texture, "remix-listbutton-highlight");
        self.ButtonHighlight.Texture:SetBlendMode("ADD");

        local CancelButton = CreateReturnButton(self);
        self.CancelButton = CancelButton;
        CancelButton:SetScript("OnClick", function()
            self:Hide();
        end);


        local NameButton = CreateNameEditButton(self.OptionFrame);
        self.NameButton = NameButton;
        NameButton:SetPoint("TOP", self, "TOP", 0, fromY + (1 - #EDIT_OPTIONS - 2) * OPTION_BUTTON_HEIGHT);
    end

    function EditWindowMixin:HighlightButton(optionButton)
        self.ButtonHighlight:Hide();
        self.ButtonHighlight:ClearAllPoints();
        if optionButton then
            self.ButtonHighlight:SetPoint("TOPLEFT", optionButton, "TOPLEFT", 0, 0);
            self.ButtonHighlight:SetPoint("BOTTOMRIGHT", optionButton, "BOTTOMRIGHT", 0, 0);
            self.ButtonHighlight:Show();
        end
    end

    function EditWindowMixin:ShowPlanner(categoryKey)
        if not Planner then
            Planner = Gemma.CreateLoadoutPlanner(self);
            Planner:SetFrameStrata("HIGH");
            Planner:SetClampedToScreen(true);
            Planner:ClearAllPoints();
            Planner:SetPoint("TOPLEFT", self, "TOPRIGHT", WINDOW_GAP, 0);

            local CancelButton = CreateReturnButton(Planner);
            Planner.CancelButton = CancelButton;
            CancelButton:SetScript("OnClick", function()
                Planner:Hide();
            end);


            local bt = Planner.AcceptButton;
            SetupThreeSliceButton(bt);
            bt:ClearAllPoints();
            bt:SetPoint("CENTER", Planner, "BOTTOM", 0, 34);
            bt.ButtonText:SetText(ACCEPT);
            bt.ButtonText:SetTextColor(1, 0.82, 0);

            bt.SetHighlighed = SaveButtonMixin.SetHighlighed;
            bt.OnEnter = SaveButtonMixin.OnEnter;
            bt.OnLeave = SaveButtonMixin.OnLeave;
            bt.OnMouseDown = SaveButtonMixin.OnMouseDown;
            bt.OnMouseUp = SaveButtonMixin.OnMouseUp;

            bt:SetScript("OnEnter", bt.OnEnter);
            bt:SetScript("OnLeave", bt.OnLeave);
            bt:SetScript("OnMouseDown", bt.OnMouseDown);
            bt:SetScript("OnMouseUp", bt.OnMouseUp);
        end

        Planner:ShowTab(categoryKey, self.gemInfo[categoryKey]);
        Planner:Show();
    end

    function EditWindowMixin:SetPendingChoice(categoryKey, newChoice)
        self.gemInfo[categoryKey] = newChoice;
        self:UpdateEditWindow();
    end

    function EditWindowMixin:SaveChanges()
        if self:IsCreatingNewLoadout() then
            LoadoutUtil:CreateNewLoadout(self.loadoutName, self.gemInfo);
            self:DeleteDraft();
        else
            LoadoutUtil:OverwriteLoadout(self.loadoutIndex, self.loadoutName, self.gemInfo);
        end
        self:Hide();
    end


    function LoadoutFrameMixin:OpenEditWindow(loadoutIndex)
        if not EditWindow then
            EditWindow = Gemma.CreateWindow(self);
            EditWindow:SetPoint("TOPLEFT", self, "TOPRIGHT", WINDOW_GAP, 0);
            Mixin(EditWindow, EditWindowMixin);
            --EditWindow:SetTitle(L["Edit Loadout"]);
            EditWindow:InitEditWindow();
        end

        if loadoutIndex then
            --Edit Existing Loadout
            EditWindow:SetLoadout(loadoutIndex);
        else
            --Create New Loadout
            if not EditWindow:IsCreatingNewLoadout() then
                EditWindow:SetNewLoadout();
            end
        end
        
        EditWindow:Show();
    end

    function LoadoutFrameMixin:HideEditWindow()
        if EditWindow then
            EditWindow:Hide();
        end
    end

    function LoadoutFrameMixin:IsEditWindowShown()
        return EditWindow and EditWindow:IsShown()
    end
end




do  --Auto Equip Gems
    local UIParent = UIParent;

    local IsSocketOccupied = Gemma.IsSocketOccupied;
    local ClearCursor = ClearCursor;
    local ClickSocketButton = ClickSocketButton;
    local AcceptSockets = AcceptSockets;
    local CloseSocketInfo = CloseSocketInfo;
    local PickupContainerItem = C_Container.PickupContainerItem;
    local SocketInventoryItem = SocketInventoryItem;


    function Automation:SuppressGameEvent(state)
        if state then
            UIParent:UnregisterEvent("SOCKET_INFO_UPDATE");
            if ItemSocketingFrame then
                ItemSocketingFrame:UnregisterEvent("SOCKET_INFO_UPDATE");
                ItemSocketingFrame:UnregisterEvent("SOCKET_INFO_ACCEPT");
            end
        else
            UIParent:RegisterEvent("SOCKET_INFO_UPDATE");
            if ItemSocketingFrame then
                ItemSocketingFrame:RegisterEvent("SOCKET_INFO_UPDATE");
                ItemSocketingFrame:RegisterEvent("SOCKET_INFO_ACCEPT");
            end
        end
    end

    function Automation:PlaceGemInSlot(gemItemID, slotID, socketIndex)
        ClearCursor();
        if not (gemItemID and slotID) then return; end

        local bagID, slotIndex = GetItemBagPosition(gemItemID);
        if not(bagID and slotIndex) then return; end

        PickupContainerItem(bagID, slotIndex);
        SocketInventoryItem(slotID);

        if IsSocketOccupied(socketIndex) then
            --Something went wrong. Socket isn't empty
            return
        else
            ClickSocketButton(socketIndex);
            ClearCursor();
            AcceptSockets();
        end

        return true
    end

    function Automation:EquipNext()
        MainFrame:ShowActionBlocker();
        self.isProcessing = true;
        self.actionIndex = self.actionIndex + 1;
        local action = self.actionList[self.actionIndex];
        local success;

        if action then
            local slotID = action[1];
            local socketIndex = action[2];
            local gemItemID = action[3];

            local itemLink = GetInventoryItemLink("player", slotID);

            if itemLink then
                local numSockets = GetItemNumSockets(itemLink);
                if numSockets > 0 and numSockets >= socketIndex then
                    CloseSocketInfo();
                    if self:PlaceGemInSlot(gemItemID, slotID, socketIndex) then
                        success = true;
                    end
                end
            end

            self:SetScript("OnUpdate", self.OnUpdate);

            EquipButton:Update();
        else
            self:OnFinishsed();
        end

        if not self.actionList[self.actionIndex + 1] then
            --So the EquipButton can update on the next PLAYER_EQUIPMENT_CHANGED
            self.isProcessing = false;
        end

        return success
    end

    function Automation:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t > 0 then
            self.socketInfoSuccess = false;
            self:SetScript("OnUpdate", nil);
            self:EquipNext();
        end
    end

    function Automation:StartEquipping()
        self.t = 0;
        self.actionIndex = 0;
        self.socketInfoSuccess = false;
        self.isProcessing = true;
        self:RegisterEvent("SOCKET_INFO_SUCCESS");
        self:RegisterEvent("SOCKET_INFO_ACCEPT");
        self:RegisterEvent("SOCKET_INFO_UPDATE");
        self:SuppressGameEvent(true);
        self:SetScript("OnEvent", self.OnEvent);
        self:SetScript("OnUpdate", self.OnUpdate);

        MainFrame:ShowActionBlocker();
    end

    function Automation:Stop()
        self.t = 0;
        self.isProcessing = false;
        self:SetScript("OnUpdate", nil);
        self:UnregisterEvent("SOCKET_INFO_SUCCESS");
        self:UnregisterEvent("SOCKET_INFO_ACCEPT");
        self:UnregisterEvent("SOCKET_INFO_UPDATE");
        self:SuppressGameEvent(false);
        CloseSocketInfo();
    end

    function Automation:OnFinishsed()
        self:Stop();
    end

    function Automation:OnEvent(event, ...)
        --Event Sequence:
        ---- ACCEPT - SUCCESS - 3 UPDATE at the same time
        --print(GetTime(), event)
        if event == "SOCKET_INFO_SUCCESS" or event == "SOCKET_INFO_ACCEPT" then
            self.socketInfoSuccess = true;
            self.t = -1;
        elseif event == "SOCKET_INFO_UPDATE" then
            if self.socketInfoSuccess then
                self.t = -0.0;
            end
        end
    end

    function Automation:EquipGems(actionList)
        --actionList: actions.insert
        --{ {slotID, socketIndex, gemItemID}, ... }
        self.actionList = actionList;
        self.numActions = #actionList;
        self:StartEquipping();
    end

    function Automation:IsProcessing()
        return self.isProcessing == true
    end

    function Automation:GetProcessText()
        return L["Format Equipping Progress"]:format(self.actionIndex, self.numActions)
    end

    function Automation:DebugMode()
        self:RegisterEvent("SOCKET_INFO_SUCCESS");
        self:RegisterEvent("SOCKET_INFO_ACCEPT");
        self:RegisterEvent("SOCKET_INFO_UPDATE");
        self:RegisterEvent("SOCKET_INFO_CLOSE");
        self:SetScript("OnEvent", Automation.OnEvent);
    end
end