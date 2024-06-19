local _, addon = ...

local DataProvider = {};
addon.TalentTreeDataProvider = DataProvider;

local GetSpellTexture = addon.TransitionAPI.GetSpellTexture;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local C_ClassTalents = C_ClassTalents;
local C_Traits = C_Traits;
local GetNodeInfo = C_Traits.GetNodeInfo;
local GetEntryInfo = C_Traits.GetEntryInfo;
local UnitClass = UnitClass;
local GetClassColor = GetClassColor;
local GetSpecialization = GetSpecialization;
local GetSpecializationInfo = GetSpecializationInfo;
local GetNumSpecializations = GetNumSpecializations;

local INPSECT_CONFIG_ID = -1;

-- Should use C_Traits.GetConditionInfo, conditionInfo.ranksGranted and conditionInfo.isMet to check if the talent is granted for free
-- But the API returns a table so I'd like to use this fast but less adaptive approach.

local AUTO_GRANTED_NODES = {
    --[specID] = {[nodeID] = true},
    --https://wowpedia.fandom.com/wiki/SpecializationID
    --/dump GetMouseFocus().nodeID

    [250] = {76071}, --Blood
    [251] = {76081}, --Frost
    [252] = {76072}, --Unholy

    [577] = {90942}, --Havoc
    [581] = {90946}, --Vengeance (Changed in 10.2.0)

    [102] = {82201, 82202}, --Balance
    [103] = {82199, 82222}, --Feral (Changed in 10.2.0)
    [104] = {82220, 82223}, --Guardian
    [105] = {82217, 82216}, --Restoration

    [1467] = {68681},    --Devastation
    [1468] = {68689},    --Preservation
    [1473] = {93305, 93304},    --Augmentation

    [253] = {79935}, --Beast Mastery
    [254] = {79834}, --Marksmanship
    [255] = {79839}, --Survival

    [62] = {62121},  --Arcane
    [63] = {62119},  --Fire
    [64] = {62117},  --Frost

    [268] = {80689}, --Brewmaster
    [270] = {80691, 80690}, --Mistweaver (Changed in 10.2.0)
    [269] = {80690}, --Windwalker

    [65] = {81597, 81599, 81600},  --Holy (Changed in 10.2.0)
    [66] = {81597, 81599},  --Protection
    [70] = {81510, 81600, 81601},  --Retribution (Changed in 10.0.7)

    [256] = {82717, 82713}, --Discipline
    [257] = {82717, 82718}, --Holy
    [258] = {82713, 82712}, --Shadow

    [259] = {90740}, --Assassination
    [260] = {90684}, --Outlaw
    [261] = {90697}, --Subtlety (Changed in 10.2.0)

    [262] = {81061, 81062}, --Elemental
    [263] = {81060, 81061}, --Enhancement
    [264] = {81062, 81063}, --Restoration

    [265] = {71933}, --Affliction   All The Same?
    [266] = {71933}, --Demonology
    [267] = {71933}, --Destruction

    [71] = {90327},  --Arms
    [72] = {90325},  --Fury
    [73] = {90261, 90330},  --Protection
};

do
    local total;

    for specID, grantedNodeIDs in pairs(AUTO_GRANTED_NODES) do
        total = #grantedNodeIDs;
        for i = 1, total do
            AUTO_GRANTED_NODES[specID][grantedNodeIDs[i]] = true;
            AUTO_GRANTED_NODES[specID][i] = nil;
        end
    end
end


function DataProvider:IsAutoGrantedTalent(nodeID)
    return self.autoGrantedNodes[nodeID]
end



function DataProvider:UpdateSpecInfo()
    local specIndex = GetSpecialization() or 1;
    local specID, specName = GetSpecializationInfo(specIndex);
    self.specID = specID;
    self.specName = specName;

    self.autoGrantedNodes = AUTO_GRANTED_NODES[specID] or {};
end

function DataProvider:GetCurrentSpecIndex()
    if not self.specIndex then
        self:UpdateSpecInfo();
    end
    return self.specIndex
end

function DataProvider:GetCurrentSpecID()
    if not self.specID then
        self:UpdateSpecInfo();
    end
    return self.specID
end

function DataProvider:GetCurrentSpecName()
    if not self.specName then
        self:UpdateSpecInfo();
    end
    return self.specName
end

function DataProvider:SetInspectSpecID(inspectSpecID)
    self.inspectSpecID = inspectSpecID;
end

function DataProvider:GetInspectSpecID()
    return self.inspectSpecID;
end

function DataProvider:IsInpsectSameSpec()
    if self.inspectSpecID and self.inspectSpecID == self.specID then
        return true
    end
end

function DataProvider:SetInspectMode(state)
    self.inspectMode = state;
    if state then
        self.GetEntryInfo = self.GetComparisonEntryInfo;
        self.GetNodeInfo = self.GetComparisonNodeInfo;
    else
        self.GetEntryInfo = self.GetPlayerEntryInfo;
        self.GetNodeInfo = self.GetPlayerNodeInfo;
    end
end


function DataProvider:GetActiveLoadoutName()
    local name;
    local specID = self:GetCurrentSpecID();

    if specID then
        local configs = C_ClassTalents.GetConfigIDsBySpecID(specID);
        local total = #configs;

        if total > 0 then
            local selectedID = C_ClassTalents.GetLastSelectedSavedConfigID(specID);

            if selectedID then
                local info = C_Traits.GetConfigInfo(selectedID);
                name = info and info.name;
            end
        end
    end

    return name or TALENT_FRAME_DROP_DOWN_DEFAULT or "Default Loadout"
end

function DataProvider:RefreshConfigIDs()
    self.configNames = {};
    self.configIDs = C_ClassTalents.GetConfigIDsBySpecID(self:GetCurrentSpecID());
end

function DataProvider:GetConfigIDs()
    if not self.configIDs then
        self:RefreshConfigIDs();
    end
    return self.configIDs
end

function DataProvider:GetConfigName(configID)
    if not self.configNames[configID] then
        local info = C_Traits.GetConfigInfo(configID);
        self.configNames[configID] = (info and info.name) or "Unnamed Loadout";
    end
    return self.configNames[configID]
end

function DataProvider:IsConfigIDValidForCurrentSpec(configID)
    if not self.configIDs then
        self:RefreshConfigIDs();
    end
    if self.configIDs then
        for i = 1, #self.configIDs do
            if configID == self.configIDs[i] then
                return true
            end
        end
    end
    return false
end

function DataProvider:GetSelecetdConfigID()
    local specID = self:GetCurrentSpecID();
    if not specID then return end;

    local selectedID = C_ClassTalents.GetLastSelectedSavedConfigID(specID);

    if self:IsConfigIDValidForCurrentSpec(selectedID) then
        return selectedID
    else
        return C_ClassTalents.GetActiveConfigID();
    end
end

function DataProvider:IsConfigIDValid(configID)
    if not self.validConfigIDs then
        if not self.specIDs then
            self.specIDs = {};
            local numSpec = GetNumSpecializations();
            local specID;
            local n = 0;
            for i = 1, numSpec do
                specID = GetSpecializationInfo(i);
                if specID then
                    n = n + 1;
                    self.specIDs[n] = specID;
                end
            end
        end

        self.validConfigIDs = {};
        local configIDs;
        for i = 1, #self.specIDs do
            configIDs = C_ClassTalents.GetConfigIDsBySpecID(self.specIDs[i]);
            if configIDs then
                for j = 1, #configIDs do
                    self.validConfigIDs[configIDs[j]] = true;
                end
            end
        end
    end

    return self.validConfigIDs[configID]
end

function DataProvider:MarkConfigIDValid(configID, isValid)
    if self.validConfigIDs and configID then
        self.validConfigIDs[configID] = isValid;
    end
end


local NodeInfoCache = {};
local EntryInfoCache = {};
local ComparisonNodeInfoCache = {};
local ComparisonEntryInfoCache = {};
local EndOfLineTraits;
local PLAYER_ACTIVE_CONFIG_ID;

function DataProvider:SetPlayerActiveConfigID(configID)
    if not configID then
        configID = self:GetSelecetdConfigID();
    end

    if configID ~= PLAYER_ACTIVE_CONFIG_ID then
        PLAYER_ACTIVE_CONFIG_ID = configID;
        self:ClearPlayerCache();
    end
end

function DataProvider:GetPlayerActiveConfigID()
    if not PLAYER_ACTIVE_CONFIG_ID then
        self:SetPlayerActiveConfigID();
    end
    return PLAYER_ACTIVE_CONFIG_ID;
end

function DataProvider.GetPlayerNodeInfo(nodeID)
    if not NodeInfoCache[nodeID] then
        NodeInfoCache[nodeID] = GetNodeInfo(PLAYER_ACTIVE_CONFIG_ID, nodeID);
    end
    return NodeInfoCache[nodeID]
end

function DataProvider.GetPlayerEntryInfo(entryID)
    if not EntryInfoCache[entryID] then
        EntryInfoCache[entryID] = GetEntryInfo(PLAYER_ACTIVE_CONFIG_ID, entryID);
    end
    return EntryInfoCache[entryID];
end

function DataProvider:ClearPlayerCache()
    NodeInfoCache = {};
    EntryInfoCache = {};
    EndOfLineTraits = nil;
end

function DataProvider:ClearComparisonCache()
    ComparisonNodeInfoCache = {};
    ComparisonEntryInfoCache = {};
end

function DataProvider:ClearAllCache()
    self:ClearPlayerCache();
    self:ClearComparisonCache();
end

function DataProvider.GetComparisonNodeInfo(nodeID)
    if not ComparisonNodeInfoCache[nodeID] then
        ComparisonNodeInfoCache[nodeID] = GetNodeInfo(INPSECT_CONFIG_ID, nodeID);
    end
    return ComparisonNodeInfoCache[nodeID]
end

function DataProvider.GetComparisonEntryInfo(entryID)
    if not ComparisonEntryInfoCache[entryID] then
        ComparisonEntryInfoCache[entryID] = GetEntryInfo(INPSECT_CONFIG_ID, entryID);
    end
    return ComparisonEntryInfoCache[entryID]
end



DataProvider:SetInspectMode(false);


local CountdownFrame;

function DataProvider:StartCacheWipingCountdown()
    if not CountdownFrame then
        CountdownFrame = CreateFrame("Frame");
        CountdownFrame:Hide();
        CountdownFrame:SetScript("OnUpdate", function(f, elapsed)
            f.t = f.t + elapsed;
            if f.t >= 2 then
                f:Hide();
                self:ClearAllCache();
            end
        end);
    end
    CountdownFrame.t = 0;
    CountdownFrame:Show();
end

function DataProvider:StopCacheWipingCountdown()
    if CountdownFrame then
        CountdownFrame:Hide();
    end
end

function DataProvider:CanCreateNewConfig()
    return C_ClassTalents.CanCreateNewConfig()
end

function DataProvider:IsLoadoutNameValid(newLoadoutName)
    --capped at 30 characters
    if not newLoadoutName then return end;
    newLoadoutName = strtrim(newLoadoutName);
    if newLoadoutName == "" then return end;

    local configIDs = self:GetConfigIDs();
    local name;
    for i, configID in ipairs(configIDs) do
        name = self:GetConfigName(configID);
        if name == newLoadoutName then
            return
        end
    end
    
    return true
end

function DataProvider:SaveInpsectLoadout(newLoadoutName)
    --/run DP:SaveInpsectLoadout()
    if not self:IsInpsectSameSpec() then return false, "Wrong Spec" end;

    if not self:CanCreateNewConfig() then
        return false, "No Save Slot"
    end

    if not self:IsLoadoutNameValid(newLoadoutName) then
        return false, "Invalid Name"
    end

    local configID = INPSECT_CONFIG_ID;
    local configInfo = C_Traits.GetConfigInfo(configID);
    local treeID = configInfo.treeIDs[1]
	local nodeIDs = C_Traits.GetTreeNodes(treeID);

    local nodeInfo;
	local loadoutEntryInfo = {};
    local count = 1;

    local GetComparisonNodeInfo = self.GetComparisonNodeInfo;

    for i, nodeID in ipairs(nodeIDs) do
        nodeInfo = GetComparisonNodeInfo(nodeID);
        if nodeInfo.ranksPurchased > 0 then
            local result = {};
            result.nodeID = nodeInfo.ID;
            result.ranksPurchased = nodeInfo.ranksPurchased;
            result.selectionEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID or nil;
            loadoutEntryInfo[count] = result;
            count = count + 1;
        end
    end

    --local requestResult = C_ClassTalents.RequestNewConfig(newLoadoutName);
    configID = C_ClassTalents.GetActiveConfigID();
    local success, errorString = C_ClassTalents.ImportLoadout(configID, loadoutEntryInfo, newLoadoutName);
    return success, errorString
end

function DataProvider:GetLoadoutExportString()
    --/run DP:GetLoadoutExportString()
    local exportStream = ExportUtil.MakeExportDataStream();
    local configID, specID;
    if self.inspectMode then
        configID = INPSECT_CONFIG_ID;
        specID = self:GetInspectSpecID();
    else
        configID = self:GetSelecetdConfigID();
        specID = self:GetCurrentSpecID();
    end

    local configInfo = C_Traits.GetConfigInfo(configID);
    local treeID = configInfo.treeIDs[1];
    local treeInfo = C_Traits.GetTreeInfo(configID, treeID);
    local treeHash = C_Traits.GetTreeHash(treeInfo.ID);
    local serializationVersion = (C_Traits.GetLoadoutSerializationVersion ~= nil and C_Traits.GetLoadoutSerializationVersion()) or 1;

    --print("SpecID: ", specID, "ConfigID: ", configID, "treeID: ", treeID);

    if ClassTalentImportExportMixin then
        ClassTalentImportExportMixin:WriteLoadoutHeader(exportStream, serializationVersion, specID, treeHash);
        ClassTalentImportExportMixin:WriteLoadoutContent(exportStream, configID, treeInfo.ID);
    else
        --copy past from Blizzard_ClassTalentImportExport.lua
        local function GetActiveEntryIndex(treeNode)
            for i, entryID in ipairs(treeNode.entryIDs) do
                if(entryID == treeNode.activeEntry.entryID) then
                    return i;
                end
            end
            return 0;
        end

        local bitWidthHeaderVersion = 8;
        local bitWidthSpecID = 16;
        local bitWidthRanksPurchased = 6;

        --ClassTalentImportExportMixin.WriteLoadoutHeader
        exportStream:AddValue(bitWidthHeaderVersion, serializationVersion);
        exportStream:AddValue(bitWidthSpecID, specID);
        for i, hashVal in ipairs(treeHash) do
            exportStream:AddValue(8, hashVal);
        end

        --WriteLoadoutContent(exportStream, configID, treeID)
        local treeNodes = C_Traits.GetTreeNodes(treeID);
        local typeSelection = Enum.TraitNodeType.Selection;
        for i, nodeID in ipairs(treeNodes) do
            local treeNode = C_Traits.GetNodeInfo(configID, nodeID);
            local isNodeSelected = treeNode.ranksPurchased > 0;
            local isPartiallyRanked = treeNode.ranksPurchased ~= treeNode.maxRanks;
            local isChoiceNode = treeNode.type == typeSelection;
            exportStream:AddValue(1, isNodeSelected and 1 or 0);
            if(isNodeSelected) then
                exportStream:AddValue(1, isPartiallyRanked and 1 or 0);
                if(isPartiallyRanked) then
                    exportStream:AddValue(bitWidthRanksPurchased, treeNode.ranksPurchased);
                end
                exportStream:AddValue(1, isChoiceNode and 1 or 0);
                if(isChoiceNode) then
                    local entryIndex = GetActiveEntryIndex(treeNode);
                    exportStream:AddValue(2, entryIndex - 1);
                end
            end
        end
    end

    local exportString = exportStream:GetExportString();
    return exportString or "ERROR";
end

local function SortTraitByPosition(a, b)
    --left to right, then bottom to top
    if a[1] == b[1] then
        return a[2] > b[2]
    else
        return a[1] < b[1]
    end
end

function DataProvider:GetEndOfLineTraits()
    --1. Traits with zero targetNode e.g. Last row
    --2. Traits with targetNodes but none of them is activated

    if EndOfLineTraits then
        return EndOfLineTraits
    end

    local configID = DataProvider:GetSelecetdConfigID();
    if not configID then return {} end;

    local configInfo = C_Traits.GetConfigInfo(configID);
    local treeID = configInfo and configInfo.treeIDs and configInfo.treeIDs[1];

    if not treeID then
        return {}
    end

	local nodeIDs = C_Traits.GetTreeNodes(treeID);
    local nodeInfo, entryInfo, definitionInfo;
    local definitionID, committedEntryID;
    local spellID, icon, originalIcon;
    local traitName;
    local _;

    local isNodeActive = {};

    for i, nodeID in ipairs(nodeIDs) do
        nodeInfo = GetNodeInfo(configID, nodeID);
        if nodeInfo.isVisible then
            committedEntryID = nodeInfo.entryIDsWithCommittedRanks and nodeInfo.entryIDsWithCommittedRanks[1];
            if committedEntryID then
                isNodeActive[nodeID] = true;
            end
        end
    end

    local numEdges, targetNodeID, valid;
    local tempData = {};

    for i, nodeID in ipairs(nodeIDs) do
        nodeInfo = GetNodeInfo(configID, nodeID);
        if nodeInfo.isVisible then
            committedEntryID = nodeInfo.entryIDsWithCommittedRanks and nodeInfo.entryIDsWithCommittedRanks[1];
            if committedEntryID then
                numEdges = nodeInfo.visibleEdges and #nodeInfo.visibleEdges;
                valid = true;
                if numEdges then
                    for j = 1, numEdges do
                        targetNodeID = nodeInfo.visibleEdges[j].targetNode;
                        if targetNodeID and isNodeActive[targetNodeID] then
                            valid = false;
                            break
                        end
                    end
                end

                if valid then
                    entryInfo = GetEntryInfo(configID, committedEntryID);
                    definitionID = entryInfo and entryInfo.definitionID;
                    if definitionID then
                        definitionInfo = C_Traits.GetDefinitionInfo(definitionID);
                        if definitionInfo then
                            spellID = definitionInfo.spellID or definitionInfo.overriddenSpellID;
                            icon = definitionInfo.overrideIcon;
                            if spellID then
                                if not icon then
                                    icon = GetSpellTexture(spellID);
                                end
                                table.insert(tempData, {nodeInfo.posX or 0, nodeInfo.posY or 0, committedEntryID, nodeInfo.currentRank or 1, spellID, icon});
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(tempData, SortTraitByPosition);
    EndOfLineTraits = {};

    for i, data in ipairs(tempData) do
        EndOfLineTraits[i] = {data[3], data[4], data[5], data[6]};   --EntryID, Rank, SpellID, Icon
    end

    return EndOfLineTraits
end

NarciAPI.GetEndOfLineTraitInfo = DataProvider.GetEndOfLineTraits;


function DataProvider:GetTraitNameByDefinitionID(definitionID)
    local definitionInfo = C_Traits.GetDefinitionInfo(definitionID);
    local spellID = definitionInfo and (definitionInfo.spellID or definitionInfo.overriddenSpellID);
    local spellName = GetSpellInfo(spellID);
    return spellName
end


do  --Hero Talents
    function DataProvider:GetActiveHeroTalentTreeInfo(configID, specID)
        if configID ~= INPSECT_CONFIG_ID then
            self.activeSubTreeID = nil;
        end

        local subTreeIDs, requiredPlayerLevel = C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, specID);
        if not subTreeIDs then return end;

        for _, subTreeID in ipairs(subTreeIDs) do
            local subTreeInfo = C_Traits.GetSubTreeInfo(configID, subTreeID);   --TWW Cache This
            if subTreeInfo and subTreeInfo.isActive then
                if configID ~= INPSECT_CONFIG_ID then
                    self.activeSubTreeID = subTreeID;
                end

                return subTreeInfo
            end
        end
    end

    function DataProvider:GetPlayerActiveHeroTalentTreeInfo()
        --local configID = C_ClassTalents.GetActiveConfigID()
        --local specID = self:GetCurrentSpecID();
        --return self:GetActiveHeroTalentTreeInfo(configID, specID)

        local configID = C_ClassTalents.GetActiveConfigID()
        local subTreeID = self:GetPlayerActiveSubTreeID();

        if subTreeID then
            return C_Traits.GetSubTreeInfo(configID, subTreeID)
        end
    end

    function DataProvider:GetInspectActiveHeroTalentTreeInfo()
        local configID = INPSECT_CONFIG_ID;
        local specID = self:GetInspectSpecID();
        return self:GetActiveHeroTalentTreeInfo(configID, specID)
    end

    function DataProvider:GetActiveSubTreeID(configID, specID)
        local subTreeIDs, requiredPlayerLevel = C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, specID);
        if not subTreeIDs then return end;

        for _, subTreeID in ipairs(subTreeIDs) do
            local subTreeInfo = C_Traits.GetSubTreeInfo(configID, subTreeID);
            if subTreeInfo and subTreeInfo.isActive then
                return subTreeID
            end
        end
    end

    function DataProvider:GetPlayerActiveSubTreeID()
        --local configID = C_ClassTalents.GetActiveConfigID()
        --local specID = self:GetCurrentSpecID();
        --return self:GetActiveSubTreeID(configID, specID)
        return C_ClassTalents.GetActiveHeroTalentSpec();
    end

    function DataProvider:GetInspectActiveSubTreeID()
        local configID = INPSECT_CONFIG_ID;
        local specID = self:GetInspectSpecID();
        return self:GetActiveSubTreeID(configID, specID)
    end

    do
        if addon.TransitionAPI.IsTWW() then
            function DataProvider:GetPlayerHeroSpecName()
                local subTreeInfo = self:GetPlayerActiveHeroTalentTreeInfo();
                if subTreeInfo then
                    return subTreeInfo.name;
                end
            end
        else
            function DataProvider:GetPlayerHeroSpecName()
                return nil
            end

            function DataProvider:GetActiveSubTreeID(configID, specID)
                return nil
            end

            function DataProvider:GetPlayerActiveSubTreeID()
                return nil
            end
        end
    end
end

function DataProvider:GetPlayerSpecClassName(colorized)
    --e.g. Subtlety Rogue, Subtlety Deathstalker (if hero talents selected)

    local className, englishClass = UnitClass("player");
	local currentSpec = GetSpecialization();
    local _, currentSpecName = GetSpecializationInfo(currentSpec);
    local keyName;

	if currentSpec then
        keyName = self:GetPlayerHeroSpecName();
	end

    if not keyName then
        keyName = className;
    end

    if not currentSpecName then
        currentSpecName = "";
    end

    if colorized then
        local _, _, _, rgbHex = GetClassColor(englishClass);
        return "|c"..rgbHex..currentSpecName.." "..keyName.."|r"
    else
        return currentSpecName.." "..keyName
    end
end

--[[
function DataProvider:EncodeActiveLoadout()
    local configID = C_ClassTalents.GetActiveConfigID();
    local configInfo = C_Traits.GetConfigInfo(configID);
    local treeID = configInfo.treeIDs[1]
	local nodeIDs = C_Traits.GetTreeNodes(treeID);
    local nodeInfo, activeEntryID, entryInfo, talentType, entryIDs;
    local n = 0;
    local state;
    local states = {};
    local numInvisible = 0;
    local nodeBits = {};
    local maxRanks
    local numBits = 0;
    local definitionIDs = {};

    table.sort(nodeIDs);
    --print("ConfigID: "..configID)
    for i, nodeID in ipairs(nodeIDs) do
        nodeInfo = GetNodeInfo(configID, nodeID);
        if nodeInfo.isVisible then
            n = n + 1;
            activeEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID or nil;
            entryInfo = (activeEntryID ~= nil) and GetEntryInfo(configID, activeEntryID) or nil;
            talentType = (entryInfo ~= nil) and entryInfo.type or nil;
            if entryInfo then
                definitionIDs[n] = entryInfo.definitionID;
                NI = nodeInfo
            else
                print(n.." Missing EntryInfo Node: "..nodeID)
            end

            maxRanks = nodeInfo.maxRanks or 1;
            if maxRanks > 1 or nodeInfo.type == 2 then
                numBits = 2;
            else
                numBits = 1;
            end

            if (nodeInfo.ranksPurchased > 0) then
                if nodeInfo.type == 2 then
                    if activeEntryID == nodeInfo.entryIDs[1] then
                        state = 1;
                    elseif activeEntryID == nodeInfo.entryIDs[2] then
                        state = 2;
                    else
                        state = 0;
                    end
                else
                    if talentType == 1 then --square
                        state = 1;
                    else
                        state = nodeInfo.ranksPurchased;
                    end
                end
            else
                state = 0;
            end
            states[n] = state;
            nodeBits[n] = numBits;
        else
            numInvisible = numInvisible + 1;
        end
    end

    local str1 = "";
    local str2 = "";

    local method = 3;
    if method == 1 then
        for i = 1, n do
            state = states[i];
            if state > 1 then
                state = state - 1;
                str1 = str1.."1";
                str2 = str2.."1";
            else
                str1 = str1..state;
                str2 = str2.."0";
            end
        end
        TestEditBox:SetText(str1.."/"..str2);

    elseif method == 2 then
        for i = 1, n do
            str1 = str1 .. states[i];
        end
        TestEditBox:SetText(str1);

    else
        local nodeID, defID;
        for i = 1, n do
            state = states[i];
            if nodeBits[i] > 1 then
                if state == 0 then
                    str1 = str1.."00";
                elseif state == 1 then
                    str1 = str1.."01";
                elseif state == 2 then
                    str1 = str1.."10";
                elseif state == 3 then
                    str1 = str1.."11";
                else
                    print(n, "Error", state)
                end
            else
                if state == 0 then
                    str1 = str1.."0";
                elseif state == 1 then
                    str1 = str1.."1";
                else
                    nodeID = nodeIDs[i];
                    defID = definitionIDs[i];
                    print(string.format("Error: #%d  NodeID: %d  DefID: %d  State: %d", i, nodeID, defID, state));
                end
            end
        end
        TestEditBox:SetText(str1);
    end

    print("Num Nodes: "..#nodeIDs);
    print("Visible: "..n);
    print("Invisible: "..numInvisible)
    print("Length: "..string.len(str1));

    --/run DP:EncodeActiveLoadout()
    -- WoW:       BYQAfcj78nJtvjmejSqe5Zhm9AAAAAAg0SpUSSJJhDkIJFAkkkDAAAAAAAlIBKJRJFgIlEJNQ0SCcAA
    -- A+B:       NUglRmSSDZxxJru,BqOmv4JxOqzPzgY
    -- Method3:   6OkckwLRJTeZtXuaYDe
    -- Base4:     pWLnmG8bWFZq6qT4rBwGNbKeZBLLYk
    -- Traverse:  2WMvI9gucZR,1Pk9JYiTVE
    --(49,31) (40, 30)
    --11554258485616
    --Tier Choices 25, 40
    --0000111101100010-1101001101011000-0011010000010100-1101011111000110-1100001110011101-1000000011111110-0000010111011000-00
    --000011110110001011010011010110000011010000010100110101111100011011000011100111011000000011111110000001011011100000
    --000011110110001011010011011010000011010000010100110101111100011011000011100111011000000011111110000001011011100000
    --BYGAGX1kx6Mci9Zl2t+S+sRoPCAAAAAAAAAAAAAAAAAAAoBkkkIJSSAQSSCIpkQSkDkGiEJJJtkSkEkAA
    --010000110111100111111110000000000011111110000000011011100011010010011100000101100110111011011011011100011000
    --sWg63isv9pnSt1xNwI
end

DP = DataProvider;


local TestEditBox = CreateFrame("EditBox", "TestEditBox");
TestEditBox:SetSize(120, 24);
TestEditBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
TestEditBox:SetFontObject("GameFontNormal");
TestEditBox:SetAutoFocus(false);
TestEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus();
end);
TestEditBox.Background = TestEditBox:CreateTexture(nil, "BACKGROUND");
TestEditBox.Background:SetAllPoints(true);
TestEditBox.Background:SetColorTexture(0, 0, 0, 0.5);

function CalculateCombo(m, n)
    local v = 1.0;
    local p;
    for i = 1.0, n, 1.0 do
        p = (m - i + 1.0) / i
        v = v * p ;
        print(i, v)
    end

    TestEditBox:SetText(v)
end
--]]