local container = CreateFrame("Frame");
local MD = CreateFrame("DressUpModel", "NarciSourceModel", container);
MD:SetSize(512, 512);
MD:SetPoint("CENTER", UIParent, "CENTER", 100, 0);

function MD:Init()
    self:SetUnit("player");
    self:SetFacing(-PI/6)
    self:SetSheathed(false);
    self:SetLight(true, false, cos(PI/4)*sin(-PI/4) ,  cos(PI/4)*cos(-PI/4) , -cos(PI/4), 1, 204/255, 204/255, 204/255, 1, 0.8, 0.8, 0.8);
end

local visualIDToBestItem = {};

local IS_VALID_INV = {
    [13] = true,
    [14] = true,
    [15] = true,
    [17] = true,
    [21] = true,
    [22] = true,
    [23] = true,
    [25] = true,
    [26] = true,

    [27] = true,
    [28] = true,
}

function MD:TestAllSource()
    local a = 1;
    local range = 10000;
    local e = 180000;
    local result;
    local format = string.format;
    local GetSourceInfo = C_TransmogCollection.GetSourceInfo;
    local sourceInfo;
    local invType, categoryID, itemID;
    local name;

    local DB = NarciItemDatabaseOutput;

    print("------------------------------------")
    local numValid = 0
    for sourceID = a, e do
        --result = self:TryOn(format("item:%d", itemID));
        if not DB[sourceID] then
            result = self:TryOn(sourceID);
            if result and (result == 0 or result == 1) then
                DB[sourceID] = true;
                numValid = numValid + 1
                --[[
                sourceInfo = GetSourceInfo(sourceID);
                if sourceInfo then
                    invType = sourceInfo.invType;
                    categoryID = sourceInfo.categoryID;
                    itemID = sourceInfo.itemID
                    if itemID and categoryID and categoryID == 18 then    --IS_VALID_INV[invType]   categoryID >= 12
                        name = sourceInfo.name or "";
                        numValid = numValid + 1
                        --print(format("sourceID:%d  result:%s  name:%s", sourceID, result, name));
                        DB[sourceID] = {itemID, name};
                    end
                end
                --]]
            end
        end
    end

    print(numValid.."  Saved!");
end

function MD:FindAllWeapons(index)
    local DB = NarciItemDatabaseOutput;
    local format = string.format;
    local completeSourceIDs = NarciItemDatabase.GetExistSourceID();
    local numSources = #completeSourceIDs;
    local sourceID;
    local foundID;
    local result;
    local numValid = 0;
    local slice = 400;
    local numSlices = math.ceil(numSources/slice);
    local a1, a2 = index*slice + 1, (index + 1)*slice;
    local isComplete = false;
    for i = a1, a2 do
        sourceID = completeSourceIDs[i];
        if not sourceID then
            isComplete = true;
            break
        end

        if not DB[sourceID] then
            self:Undress(16);
            self:Undress(17);
            result = self:TryOn(sourceID);
            if result then
                foundID = self:GetSlotTransmogSources(16);
                if not foundID or foundID == 0 then
                    foundID = self:GetSlotTransmogSources(17);
                end
                if foundID == sourceID and foundID ~= 0 then
                    DB[sourceID] = true;
                    numValid = numValid + 1;
                end
            end
        end
    end

    print(a1.."-"..a2.." of "..numSources.."  Slice: "..index.."/"..numSlices.."  "..numValid.."  Saved!");
    return isComplete
end

local AllWeaponsInCategory;
--[[
function MD:FindValidForDressUpModel(index)
    if not AllWeaponsInCategory then
        AllWeaponsInCategory = NarciItemDatabase.GetFlatList();
    end
    local DB = NarciItemDatabaseOutput;
    local numSources = #AllWeaponsInCategory;
    local itemID, weaponID, itemString;
    local result1, result2;
    local numValid = 0;
    local slice = 400;
    local numSlices = math.ceil(numSources/slice);
    local a1, a2 = index*slice + 1, (index + 1)*slice;
    local isComplete = false;
    for i = a1, a2 do
        if not AllWeaponsInCategory[i] then
            isComplete = true;
            break
        end

        if type(AllWeaponsInCategory[i]) == "table" then
            itemID = AllWeaponsInCategory[i][1];
            weaponID = AllWeaponsInCategory[i][3];  --sourceID
        else
            itemID = AllWeaponsInCategory[i];
        end

        if not DB[itemID] then
            self:Undress(16);
            self:Undress(17);
            itemString = "item:" .. itemID;
            result1 = self:TryOn(itemString);
            if result1 and (result1 == 0 or result1 == 1) then
                --success or wrong race
                numValid = numValid + 1;
                DB[itemID] = true;
            end
        end
    end

    print(a1.."-"..a2.." of "..numSources.."  Slice: "..index.."/"..numSlices.."  "..numValid.."  Saved!");
    return isComplete
end
--]]

function MD:FindValidForDressUpModel(index)
    if not AllWeaponsInCategory then
        AllWeaponsInCategory = NarciItemDatabase.HoldableItems;
    end
    local DB = NarciItemDatabaseOutput;
    local numSources = #AllWeaponsInCategory;
    local itemID, weaponID, itemString;
    local result1, result2;
    local numValid = 0;
    local slice = 400;
    local numSlices = math.ceil(numSources/slice);
    local a1, a2 = index*slice + 1, (index + 1)*slice;
    local isComplete = false;
    for i = a1, a2 do
        if not AllWeaponsInCategory[i] then
            isComplete = true;
            break
        end

        itemID = AllWeaponsInCategory[i][3];

        if not DB[itemID] then
            self:Undress(16);
            self:Undress(17);
            itemString = "item:" .. itemID;
            result1 = self:TryOn(itemString);
            if result1 and (result1 == 0 or result1 == 1) then
                --success or wrong race
                numValid = numValid + 1;
                DB[itemID] = true;
            end
        end
    end

    print(a1.."-"..a2.." of "..numSources.."  Slice: "..index.."/"..numSlices.."  "..numValid.."  Saved!");
    return isComplete
end

local autoRun = CreateFrame("Frame");
autoRun:Hide();

autoRun:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.1 then
        self.t = 0;
        local isComplete = MD:FindValidForDressUpModel(self.index);   --FindItemInfo, FindAllWeapons, FindItemSourceInfo, FindItemVisualInfo, FindBestItemForEachVisual, FindValidForDressUpModel
        if isComplete then
            self:Reset();
            return
        end
        self.loopTime = self.loopTime + 1;
        if self.loopTime >= 3 then
            self.loopTime = 0;
            self.index = self.index + 1;
        end
    end
end);

function autoRun:Reset()
    self:Hide();
    self.t = 2;
    self.index = 0;
    self.loopTime = 0;
end

function ProcessWeaponSourceID()
    MD:Init();
    C_Timer.After(0.5, function()
        autoRun:Reset();
        autoRun:Show();
    end)
end

local IsWeaponProcessed = {};

function MD:FindItemInfo(index)
    local DB = NarciItemDatabaseOutput;
    local GetSourceInfo = C_TransmogCollection.GetSourceInfo;
    local completeSourceIDs = NarciItemDatabase.GetValidSourceID();
    local numSources = #completeSourceIDs;
    local sourceID;
    local sourceInfo;
    local numValid = 0;
    local name, itemID, itemModID;

    local slice = 200;
    local numSlices = math.ceil(numSources/slice);
    local a1, a2 = index*slice + 1, (index + 1)*slice;
    local isComplete = false;

    for i = a1, a2 do
        sourceID = completeSourceIDs[i];
        if not sourceID then
            isComplete = true;
            break;
        end
        if not DB[sourceID] then
            sourceInfo = GetSourceInfo(sourceID);
            if sourceInfo and sourceInfo.name then
                name = sourceInfo.name;
                itemID = sourceInfo.itemID;
                itemModID = sourceInfo.itemModID;
                DB[sourceID] = {name, itemID, itemModID};
                numValid = numValid + 1;
            end
        end
    end

    print(a1.."-"..a2.." of "..numSources.."  Slice: "..index.."/"..numSlices.."  "..numValid.."  Saved!");
    return isComplete
end

function MD:FindItemSourceInfo(index)
    local DB = NarciItemDatabaseOutput;
    local GetSourceID = NarciItemDatabase.GetSourceID;
    local GetSourceInfo = C_TransmogCollection.GetSourceInfo;
    if not self.completeItems then
        self.completeItems = NarciItemDatabase.GetFlatList();
    end
    local completeItems = self.completeItems;
    local numSources = #completeItems;
    local sourceID;
    local sourceInfo;
    local numValid = 0;
    local name, itemID, itemModID, categoryID, visualID;

    local slice = 200;
    local numSlices = math.ceil(numSources/slice);
    local a1, a2 = index*slice + 1, (index + 1)*slice;
    local isComplete = false;

    for i = a1, a2 do
        itemID = completeItems[i];
        sourceID = GetSourceID(itemID);
        if i > numSources then
            isComplete = true;
            break;
        end
        if not DB[itemID] then
            sourceInfo = GetSourceInfo(sourceID);
            if sourceInfo and sourceInfo.categoryID then
                categoryID = sourceInfo.categoryID;
                itemModID = sourceInfo.itemModID;
                DB[itemID] = categoryID;
                numValid = numValid + 1;
            end
        end
    end

    print(a1.."-"..a2.." of "..numSources.."  Slice: "..index.."/"..numSlices.."  "..numValid.."  Saved!");
    return isComplete
end

function MD:FindItemVisualInfo(index)
    local DB = NarciItemDatabaseOutput;
    local GetSourceID = NarciItemDatabase.GetSourceID;
    local GetSourceInfo = C_TransmogCollection.GetSourceInfo;
    if not self.completeItems then
        self.completeItems = NarciItemDatabase.GetFlatList();
    end
    local completeItems = self.completeItems;
    local numSources = #completeItems;
    local sourceID;
    local sourceInfo;
    local numValid = 0;
    local name, itemID, itemModID, categoryID, visualID;

    local slice = 200;
    local numSlices = math.ceil(numSources/slice);
    local a1, a2 = index*slice + 1, (index + 1)*slice;
    local isComplete = false;
    local visualItem = {};
    for i = a1, a2 do
        itemID = completeItems[i];
        sourceID = GetSourceID(itemID);
        if i > numSources then
            isComplete = true;
            break;
        end
        if sourceID ~= 0 and not DB[itemID] then
            sourceInfo = GetSourceInfo(sourceID);
            if sourceInfo and sourceInfo.visualID then
                visualID = sourceInfo.visualID;
                DB[itemID] = visualID;
                numValid = numValid + 1;
            end
        end
    end
    
    print(a1.."-"..a2.." of "..numSources.."  Slice: "..index.."/"..numSlices.."  "..numValid.."  Saved!");
    return isComplete
end

function MD:FindBestItemForEachVisual(index)
    local GetItemInfo = GetItemInfo;
    local GetTransmogItemInfo = C_TransmogCollection.GetItemInfo;
    local holdables = NarciItemDatabase.HoldableItems;
    local numSources = #holdables;
    local numValid = 0;
    local name, itemID, itemModID, categoryID, visualID, sourceID;

    local slice = 100;
    local numSlices = math.ceil(numSources/slice);
    local a1, a2 = index*slice + 1, (index + 1)*slice;
    local isComplete = false;
    local DB = NarciItemDatabaseOutput;
    for i = a1, a2 do
        if i > numSources then
            isComplete = true;
            break;
        end

        sourceID = holdables[i][1]
        visualID = holdables[i][2];
        itemID = holdables[i][3];
        itemModID = holdables[i][4];
        
        if visualID > 0 then
            if DB[visualID] then
                if GetTransmogItemInfo(itemID, itemModID) then
                    if itemModID == 0 or itemModID == 153 then
                        DB[visualID] = itemID;
                    else
                        DB[visualID] = {itemID, itemModID, sourceID};
                    end
                    numValid = numValid + 1;
                end
            else
                --self.visualItem[visualID] = itemID;
                if itemModID == 0 or itemModID == 153 then
                    DB[visualID] = itemID;
                else
                    DB[visualID] = {itemID, itemModID, sourceID};
                end
                numValid = numValid + 1;
            end
        end
    end
    print(a1.."-"..a2.." of "..numSources.."  Slice: "..index.."/"..numSlices.."  "..numValid.."  Saved!");
    return isComplete
end

function IsItemLogged(itemID)
   local list = NarciItemDatabase.GetFlatList();
   for i = 1, #list do
       if list[i] == itemID then
        print("Found: "..itemID)   
        return
       end
   end
   print("Failed: "..itemID)
end

function FindConflict()
    local GetItemInfo = C_TransmogCollection.GetItemInfo;
    local DB = NarciItemDatabase.weaponSources;
    local appearanceID, itemID, modID;
    local output = {};
    local temp = {};
    local total = 0;
    for sourceID, info in pairs(DB) do
        itemID = info[2];
        modID = info[3] or 0;

        appearanceID = GetItemInfo(itemID, modID);
        if not appearanceID then
            --print(info[1])
            total = total + 1;
            temp[total] = sourceID;
        end

        --[[
        total = total + 1;
        temp[total] = sourceID;
        --]]
    end
    table.sort(temp, function(a, b) return a > b end)
    local sourceID;
    for i = 1, total do
        sourceID = temp[i];
        output[i] = {sourceID, unpack(DB[sourceID])};
    end
    NarciItemDatabaseOutput = output;
    print("numConflict: "..total)
end

function SortDB()
    local output = {};
    local numItem = 0;
    for itemID, _ in pairs(NarciItemDatabaseOutput) do
        numItem = numItem + 1;
        output[numItem] = itemID;
    end
    table.sort(output, function(a, b) return a < b end)
    NarciItemDatabaseOutput = output;
end

function GetOneItemIDForEachAppearanceID()
    local visualItem = NarciItemDatabase.appearanceItems
    local numItems = 0;
    local list = {};
    for visualID, itemID in pairs(visualItem) do
        numItems = numItems + 1;
        list[numItems] = itemID;
    end
    NarciItemDatabaseOutput = list;
    print("Complete! NumItems: "..numItems);
end

function GetItemsWithModID()
    local loggedItems = NarciItemDatabase.appearanceItems
    local allVisuals = NarciItemDatabase.appearanceIDxItemMod
    local IS_VISUAL_LOGGED = {};
    local list = {};
    
    for visualID, itemID in pairs(loggedItems) do
        IS_VISUAL_LOGGED[visualID] = true;
    end
    
    local numUnlogged = 0;
    for visualID, data in pairs(allVisuals) do
        if not IS_VISUAL_LOGGED[visualID] then
            IS_VISUAL_LOGGED[visualID] = true;
            numUnlogged = numUnlogged + 1;
            list[numUnlogged] = data;
        end
    end

    print("Complete! NumUnloggedItems: "..numUnlogged);
    NarciItemDatabaseOutput = list;
end

function InsertModifiedItemIntoCategory()
    local orignalList = NarciItemDatabase.subclassItems;
    local extraList = NarciItemDatabase.itemVariations;
    local itemID, modID, sourceID;
    local itemMods = {};
    local data;
    for i = 1, #extraList do
        data = extraList[i];
        itemID = data[1];
        modID = data[2];
        sourceID = data[3];
        if not itemMods[itemID] then
            itemMods[itemID] = {};
        end
        tinsert(itemMods[itemID], {modID, sourceID});
    end

    local mods = {};
    local dataSize = 0;
    for subclassID, data in pairs(orignalList) do
        dataSize = #data;
        for i = 1, dataSize do
            itemID = data[i];
            mods = itemMods[itemID];
            if mods then
                table.sort(mods, function(a, b) return a[1] > b[1] end)
                local spot = i + 1;
                for j = 1, #mods do
                    table.insert(orignalList[subclassID], spot, {itemID, unpack(mods[j]) } );
                    i = i + 1;
                    dataSize = dataSize + 1;
                end
            end
        end
    end

    NarciItemDatabaseOutput = orignalList;
end

function BuildItemIDToVariation()
    local list = NarciItemDatabase.itemVariations;
    local newList = {};
    local itemID;
    for i = 1, #list do
        itemID = list[i][1];
        if not newList[itemID] then
            newList[itemID] = {};
        end

        tinsert(newList[itemID], {list[i][2], list[i][3]});
    end
    for itemID, data in pairs(newList) do
        table.sort(data, function(a, b)
            return a[1] < b[1];
        end);
    end
    NarciItemDatabaseOutput = newList;
end

--[[
    /run NarciSourceModel:Init();
    /run NarciSourceModel:TestSource();
    /run NarciSourceModel:FindAllWeapons()
    /dump NarciSourceModel:GetSlotTransmogSources(17)
ItemTryOnReason = {
		Success = 0,
		WrongRace = 1,
		NotEquippable = 2,
		DataPending = 3,
	},
--]]

