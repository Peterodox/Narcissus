local After = C_Timer.After;
local db;
local GetItemModelFileID = NarciItemDatabase.GetItemModelFileID;

------Acquire ModelFileID------
local NUM_WIDGETS = 50;

local container = CreateFrame("Frame");
local numTotal = 0;
local numLeft;

local models = {};

local flatIDs = {};

local function FetchItemID()
    local itemID = flatIDs[numLeft];
    local index = numLeft;
    flatIDs[numLeft] = nil;
    if numLeft == 0 then
        return
    else
        numLeft = numLeft - 1;
    end
    return index, itemID
end

local function FetchAndSetItem(model)
    local index, itemID = FetchItemID();
    model.t = 0;
    if itemID then
        model.dataIndex = index;
        After(0, function()
            model.itemID = itemID;
            model:SetItem(itemID);
        end)
    else
        model.dataIndex = nil;
    end
end

local function CheckComplete()
    local isComplete = true;
    local numPending = 0;
    for i = 1, NUM_WIDGETS do
        if models[i].dataIndex then
            isComplete = false;
            numPending = numPending + 1;

            --Dead Widget
            if models[i].t > 2 then
                NarciItemDatabaseFailure[ models[i].itemID ] = true;
                FetchAndSetItem(models[i]);
            end
        end
    end

    if isComplete then
        print("COMPLETE!")
    else
        --print("Pending: "..numPending)
    end

    return isComplete
end

local checker = CreateFrame("Frame");
checker:Hide();
checker.t = 0;
checker:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 3 then
        self.t = 0;
        print(numLeft.."/"..numTotal);
        if CheckComplete() then
            self:Hide();
            self.t = 0;
        end
    end
end);

local function OnModelLoaded(model)
    local fileID = model:GetModelFileID();
    --print(fileID)

    db[ model.itemID ] = fileID;
    model.dataIndex = nil;
    FetchAndSetItem(model)
end

local function OnPausing(model, elapsed)
    if model.dataIndex then
        model.t = model.t + elapsed;
    end
end

for i = 1, NUM_WIDGETS do
    models[i] = CreateFrame("PlayerModel", nil, container);
    models[i].t = 0;
    models[i]:SetScript("OnModelLoaded", OnModelLoaded);
    models[i]:SetScript("OnUpdate", OnPausing);
end

function ProcessWeapons()
    --Get Model FileID
    flatIDs = NarciItemDatabase.HoldableItems;
    local unprocessed = {};
    local itemID, fileID;
    for i = 1, #flatIDs do
        itemID = flatIDs[i][3];
        fileID = GetItemModelFileID(itemID);
        if not fileID then
            tinsert(unprocessed, itemID);
            print(itemID)
        end
    end
    flatIDs = unprocessed;
    numTotal = #flatIDs;
    numLeft = numTotal;
    if not NarciItemDatabaseOutput then
        NarciItemDatabaseOutput = {};
    end
    db = NarciItemDatabaseOutput;

    for i = 1, NUM_WIDGETS do
        FetchAndSetItem(models[i]);
    end

    checker:Show();
end


function GetItemsWithNoModel()
    local validItems = NarciItemDatabase.GetFlatList();
    local IS_VALID = {};
    for i = 1, #validItems do
        IS_VALID[ validItems[i] ] = true;
    end
    local allItems, numAll = NarciItemDatabase.GetFlatListFromItemNameDatabase();
    local itemID;
    NarciItemDatabaseFailure = {};
    local DB = NarciItemDatabaseFailure;
    for i = 1, numAll do
        itemID = allItems[i];
        if not IS_VALID[itemID] then
            DB[itemID] = true;
        end
    end
    print("Complete")
end

------Sort Item------


local function SortByModelFileID(a, b)
    local itemID1, itemID2;
    local itemModID1, itemModID2;
    if type(a) == "table" then
        itemID1 = a[1];
        itemModID1 = a[2];
    else
        itemID1 = a;
    end
    if type(b) == "table" then
        itemID2 = b[1];
        itemModID2 = b[2];
    else
        itemID2 = b;
    end
    local f1, f2 = GetItemModelFileID(itemID1), GetItemModelFileID(itemID2);
    if f1 and f2 then
        if f1 ~= f2 then
            return f1 > f2
        else
            if (itemID1) and (itemID2) and (itemID1 == itemID2) and itemModID1 and itemModID2 then
                return itemModID1 < itemModID2
            end
        end
    else
        return itemID1 > itemID2
    end
end

local SPECIAL_ITEM_SUBCLASS_OVERRIDE = {
    --itemID
    [108736] = 14,  --NaShara Mining Pick
    [13289] = 3,    --Egan's Blaster
    [33604] = 3,    --Plague Shooter
    [42764] = 4,    --Krolmir
    [140345] = 6,   --Hall of Valor 1H Spear
    [160435] = 6,   --Kultiras Harpoon
    [127346] = 6,   --Yakmen Polearm
    [132179] = 4,   --Hammer of Khaz'goroth
    [182161] = 4,   --Ceremonial Javelin
    [177265] = 6,   --Maldraxxus Polearm
    [177264] = 6,   --Maldraxxus Polearm
    [177263] = 6,   --Maldraxxus Polearm
    [177262] = 6,   --Maldraxxus Polearm
    [177260] = 6,   --Maldraxxus Polearm
    [176845] = 6,   --Archon's Staff
    [164000] = 6,   --Draenor Crafted Polearm
};

local IGNORED_ITEM = {
    [180051] = true,    --Maw Crossbow Hammer
}

function SortWeaponBySubclass()
    local type = type;
    local tinsert = table.insert;
    local visualItems = NarciItemDatabase.VisualItems;
    local GetItemInfoInstant = GetItemInfoInstant;
    local GetItemModelFileID = NarciItemDatabase.GetItemModelFileID;
    local function GetSubclassID(id)
        local _, _, _, _, _, itemClassID, itemSubClassID = GetItemInfoInstant(id);
        if itemClassID == 4 and itemSubClassID == 6 then --shield
            itemSubClassID = 69;
        elseif itemClassID ~= 2 then    --weapon
            itemSubClassID = 1208;     --Unknown    class 4 subclass 0 LE_ITEM_ARMOR_GENERIC
        end

        if itemClassID == 2 and itemSubClassID == 17 then
            itemSubClassID = 6;    --Redirect Spears to Polearm
        end
        return itemSubClassID
    end

    local fileID;
    local itemID, subclassID;
    local list = {};
    
    for visualID, itemInfo in pairs(visualItems) do
        if type(itemInfo) == "table" then
            itemID = itemInfo[1];
        else
            itemID = itemInfo;
        end
        fileID = GetItemModelFileID(itemID);
        if fileID and not IGNORED_ITEM[itemID] then
            if SPECIAL_ITEM_SUBCLASS_OVERRIDE[itemID] then
                subclassID = SPECIAL_ITEM_SUBCLASS_OVERRIDE[itemID];
            else
                subclassID = GetSubclassID(itemID);
            end
            if not list[subclassID] then
                list[subclassID] = {};
            end
            tinsert(list[subclassID], itemInfo);
        end
    end

    for _, data in pairs(list) do
        table.sort(data, SortByModelFileID);
    end

    NarciItemDatabaseOutput = list;

    print("Sorting Complete")

    --Count Item
    NarciItemDatabaseCount = {};
    for subclassID, data in pairs(list) do
        NarciItemDatabaseCount[subclassID] = #data;
    end
end

function GetItemIDxSourceID()
    local holdables = NarciItemDatabase.HoldableItems;
    local itemIDxSourceID = {};
    local sourceID, itemID, itemModID;
    for index, data in pairs(holdables) do
        sourceID = data[1];
        itemID = data[3];
        itemModID = data[4];
        if not itemIDxSourceID[itemID] then
            itemIDxSourceID[itemID] = sourceID;
        else
            if itemModID == 0 or itemModID == 153 then
                itemIDxSourceID[itemID] = sourceID;
            end
        end
    end
    NarciItemDatabaseOutput = itemIDxSourceID
end

function SortWeaponByCategory()
    local ITEMS = NarciItemDatabase.UniqueItems;
    local ITEM_CATEGORY = NarciItemDatabase.itemIDCategoryID;
    local itemID, categoryID;
    local list = {};

    for i = 1, #ITEMS do
        itemID = ITEMS[i]
        categoryID = ITEM_CATEGORY[itemID];
        if not list[categoryID] then
            list[categoryID] = {};
        end
        tinsert(list[categoryID], itemID);
    end

    for cateID, data in pairs(list) do
        table.sort(data, SortByModelFileID);
    end

    NarciItemDatabaseOutput = list;
end

------Attempt to distinguish uncolletable items------
function GetInternalItems()
    local GetTransmogInfo = C_TransmogCollection.GetItemInfo;
    local numNoAppearanceID, numNoSourceItem = 0, 0;
    local aID, sID;
    local itemID;
    local DB = NarciItemDatabase.itemIDBySubclassID;
    local numTotal = 0;
    local ignoredItem = {};

    for subclassID, data in pairs(DB) do
        for i = 1, #data do
            numTotal = numTotal + 1;
            itemID = data[i];
            aID, sID = GetTransmogInfo(itemID);

            if aID then
                ignoredItem[itemID] = true;
            else
                numNoAppearanceID = numNoAppearanceID + 1;
            end

            if not sID then
                numNoSourceItem = numNoSourceItem + 1;
            end
        end
    end

    print("Complete")
    print("Total: "..numTotal);
    print("No Source: "..numNoAppearanceID);

    local output = {};
    local numSaved = 0;
    for subclassID, data in pairs(DB) do
        output[subclassID] = {};
        for i = 1, #data do
            itemID = data[i];
            if itemID and not ignoredItem[itemID] then
                numSaved = numSaved + 1
                tinsert( output[subclassID], itemID );
            end
        end
    end
    NarciItemDatabaseOutput = output;
    print("Saved: "..numSaved);
end


------Count Items------

function CountWeaponsByCategoryID()
    local DB1 = NarciItemDatabase.subclassItems;
    local DB2 = NarciItemDatabase.subclassItems;
    local output = {
        {}, {},
    };
    for id, data in pairs(DB1) do
        output[1][id] = #data;
    end
    for id, data in pairs(DB2) do
        output[2][id] = #data;
    end
    NarciItemDatabaseOutput = output;
    print("Complete");
end

------ModelFileID to ItemID------
function CompileModelFileID()
    local IDList = NarciItemDatabase.GetUniqueAppearanceList();
    local GetFileID = NarciItemDatabase.GetItemModelFileID;
    local output = {};
    local numModel = 0;
    local fileID;
    for _, itemID in pairs(IDList) do
        fileID = GetFileID(itemID);
        if fileID then
            if output[fileID] then
                tinsert(output[fileID], itemID);
            else
                numModel = numModel + 1;
                output[fileID] = {itemID};
            end
        end
    end

    NarciItemDatabaseOutput = output;
    print("Complete");
    print("Num Unique Model: "..numModel)
end

function GetItemVariations()
    local sourceList = NarciItemDatabase.appearanceIDxItemMod;   --[visualID] = {itemID, itemModID, sourceID}
    local loggedItem = {};
    local itemID, itemModID, sourceID;
    for visualID, data in pairs(sourceList) do
        itemID = data[1];
        itemModID = data[2];
        sourceID = data[3];
        if not loggedItem[itemID] then
            loggedItem[itemID] = {};
        end
        if itemModID ~= 0 and itemModID ~= 153 then --basic mod ID
            tinsert(loggedItem[itemID], {itemModID, sourceID});
        end
    end

    local output = {};
    local numVariant;
    local numTotal = 0;
    for itemID, data in pairs(loggedItem) do
        numVariant = #data;
        if numVariant > 1 then
            numTotal = numTotal + 1;
            output[itemID] = {};
            for i = 1, numVariant do
                output[itemID][i] = data[i];
            end
        end
    end
    NarciItemDatabaseOutput = output;
    print("Complete");
    print(numTotal.." items have color variations");
end