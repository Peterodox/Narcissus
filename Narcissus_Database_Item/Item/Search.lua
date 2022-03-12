local NUM_MAX_MATCHES = 200;

local sub = string.sub;
local gsub = string.gsub;
local find = string.find;
local lower = string.lower;
local format = string.format;
local After = C_Timer.After;
local strsplit = strsplit;
local strtrim = strtrim;
local strlen = strlen;
local tinsert = table.insert;
local GetItemName = NarciItemDatabase.GetItemName;
local GetItemModelFileID = NarciItemDatabase.GetItemModelFileID;
local GetItemVariations = NarciItemDatabase.GetItemVariations;

local function ProcessName(name)
    if name then
        name = gsub(name, "_", " ");        --My_Name - My Name
        name = gsub(name, "%u%l", " %1");   --MyName - My Name
        name = gsub(name, "%s+", " ");
        name = strtrim(name);
        return name
    end
end

local function split(str)
    return strsplit(" ", str)
end

local function trim(str)
    if not str or find(str, "^%d") or strlen(str) < 2 then
        --Ignore words begin with digits
        return
    end
    return strtrim(str, "-(),\t");
end

local function GetInitial(str)
    str = trim(str);
    if str then
        return lower(sub(str, 1, 2))
    end
end

local SearchTable = {};

local SearchUtil = {};

function SearchUtil:Load()
    if self.DivideListByInitials then
        self:DivideListByInitials();
        self.DivideListByInitials = nil;
    end
end

function SearchUtil:DivideListByInitials()
    local itemlist, numItems = NarciItemDatabase.GetFlatList();
    local itemID, itemName, initial, names;
    local TempTable = {};

    for i = 1, numItems do
        itemID = itemlist[i];
        itemName = GetItemName(itemID);
        if itemName then
            itemName = ProcessName(itemName);
            names = { split(itemName) };
            for j = 1, #names do
                initial = GetInitial(names[j]);
                if initial and initial ~= "" then
                    if not TempTable[initial] then
                        TempTable[initial] = { [itemID] = true };
                    else
                        TempTable[initial][itemID] = true;
                    end
                end
            end
        else
            --print(itemID)
        end
    end

    local n1, n2, m1, m2;
    local function SortFunc(a, b)
        n1 = GetItemName(a);
        n2 = GetItemName(b);
        m1 = GetItemModelFileID(a);
        m2 = GetItemModelFileID(b);

        if m1 == m2 then
            if n1 == n2 then
                return a > b
            else
                return n1 < n2
            end
        else
            if m1 and m2 then
                return m1 > m2
            end
        end
    end
    
    for initial, SubTable in pairs(TempTable) do
        SearchTable[initial] = {};
        for id, _ in pairs(SubTable) do
            tinsert(SearchTable[initial], id);
        end
        table.sort(SearchTable[initial], SortFunc);
    end

    TempTable = nil;
    itemlist = nil;

    --print("Complete")
end

SearchUtil:Load();

local function SearchItemByName(str)
    if not str or str == "" or IsKeyDown("BACKSPACE") then return {}, 0 end
    SearchUtil:Load();

    local initial = GetInitial(str);
    local SubTable = SearchTable[initial];

    if not SubTable then
        --print("Couldn't find any creature that begins with "..str);
        return {}, 0
    end

    local unpack = unpack;
    local find = string.find;
    local lower = lower;
    local name, id;
    local nameTemp;
    local matchedIDs = {};
    local numMatches = 0;
    local overFlow;
    local variations, numVar;

    str = lower(str);

    --print("Initial: "..initial.."  Total: "..#SubTable)

    for i = 1, #SubTable do
        if numMatches > NUM_MAX_MATCHES then
            numMatches = numMatches - 1;
            overFlow = true;
            break
        end

        id = SubTable[i];
        name = GetItemName(id);
        name = ProcessName(name);
        if name then
            nameTemp = lower(name);
            if find(nameTemp, str) then
                tinsert(matchedIDs, id);
                numMatches = numMatches + 1;
                variations = GetItemVariations(id);
                if variations then
                    numVar = #variations;
                    numMatches = numMatches + numVar;
                    for j = 1, numVar do
                        tinsert(matchedIDs, {id, unpack(variations[j])} );
                    end
                end
            end
        end
    end

    return matchedIDs, numMatches, overFlow
end

NarciItemDatabase.SearchItemByName = SearchItemByName;

--[[
function SplitItemName(itemID)
    local itemName = GetItemName(itemID);
    itemName = ProcessName(itemName)
    local names = { split(itemName) };
    local name;
    print(" ")
    for i = 1, #names do
        name = trim(names[i]);
        if name and name ~= "" then
            print(i..": "..name)
        end
    end
end
--]]
--/run SplitItemName(163598)