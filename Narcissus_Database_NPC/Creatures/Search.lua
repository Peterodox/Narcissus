NarciCreatureInfo = {};
NarciCreatureInfo.isLanguageLoaded = {};

local L = Narci.L;
local sub = string.sub;
local gsub = string.gsub;
local lower = string.lower;
local format = string.format;
local strsplit = strsplit;
local tinsert = table.insert;
local After = C_Timer.After;

local IsKeyDown = IsKeyDown;

local CLIENT_TEXT_LOCALE = GetLocale();
if CLIENT_TEXT_LOCALE == "enGB" then
    CLIENT_TEXT_LOCALE = "enUS";
end

local function GetCreatureNameByID(id)
    return NarciCreatureInfo.Names[id]
end

local function GetCreatureLocalizedNameByID(id, language)
    if NarciCreatureInfo[language] and id then
        return NarciCreatureInfo[language][id]
    end
end

local GetCreatureEnglishNameByID = GetCreatureNameByID;
if CLIENT_TEXT_LOCALE ~= "enUS" then
    function GetCreatureEnglishNameByID(id)
        if NarciCreatureInfo["enUS"] and id then
            return NarciCreatureInfo["enUS"][id]
        else
            --print("Not loaded")
        end
    end
end

local numNPC = 0;

local function GetNumCreatures()
    return numNPC
end


local function IgnoreDatabase(databaseLanguage)
    if databaseLanguage == "enUS" then
        return false
    end

    if CLIENT_TEXT_LOCALE == databaseLanguage then
        return false
    else
        local Settings = NarcissusDB;
        if not Settings.TranslateName then
            return true
        end
        local ignoreThis;
        if Settings["NameTranslationPosition"] == 1 then
            if not Settings["TooltipLanguages"][databaseLanguage] then
                ignoreThis = true;
            end
        elseif Settings["NamePlateLanguage"] ~= databaseLanguage then
            ignoreThis = true;
        end

        return ignoreThis
    end
end

NarciCreatureInfo.GetCreatureNameByID = GetCreatureNameByID;
NarciCreatureInfo.GetCreatureLocalizedNameByID = GetCreatureLocalizedNameByID;
NarciCreatureInfo.GetNumCreatures = GetNumCreatures;
NarciCreatureInfo.IgnoreDatabase = IgnoreDatabase;

-------------------------------------------------------------------
local NUM_MAX_MATCHES = 80;
local OMISSIONS = {"%[", "%(", "%:", "%s%-", "Credit", "Proxy", "Controller", "Bunny", "Generic", "to%s", "PH", "Test%s", "*", "zzOLD", "Quest Tracker", "Speak%s", "Meet%s"};
local OMISSIONS_LOCALE = {
    --["enUS"] = {"the", "of"},
    ["deDE"] = {"das", "der", "die", "von", "aus", "im", "den"},
    ["frFR"] = {"et", "de", "des", "le", "la", "du", "en"},
    ["ruRU"] = {"и", "а", "с", "в", "о", "но", "или", "за", "из", "на", "як"},
    ["esES"] = {"de", "del", "en", "el", "la", "lo", "las", "los", "elfo", "sin"},
    ["esMX"] = {"de", "del", "en", "el", "la", "lo", "las", "los", "elfo", "sin"},
    ["ptBR"] = {"o", "O", "ou", "os", "de", "da", "do", "dos", "das"},
    ["itIT"] = {"i", "O", "un", "di", "del", "dei", "della", "la", "lo", "il"},
}

local SearchTable = {};
local SearchTable_English;
SearchTable_English = {};


local OMISSIONS_EXTRA = OMISSIONS_LOCALE[CLIENT_TEXT_LOCALE];

local GetInitial;
if CLIENT_TEXT_LOCALE == "zhCN" or CLIENT_TEXT_LOCALE == "zhTW" or CLIENT_TEXT_LOCALE == "koKR" then
    function GetInitial(str)
        return lower(sub(str, 1, 3))
    end
elseif CLIENT_TEXT_LOCALE == "ruRU" then
    function GetInitial(str)
        return lower(sub(str, 1, 2))
    end
else
    function GetInitial(str)
        return lower(sub(str, 1, 2))
    end 
end

local function DivideListByInitials(enableEnglish)
    --print("Constructing search table...")

    local gsub = gsub;
    local find = string.find;
    local strsplit = strsplit;
    
    local function split(str)
        return strsplit(" ", str)
    end

    local TargetTable;
    local NormalizeString;
    local GetCreatureNameByID = GetCreatureNameByID;

    if enableEnglish then
        TargetTable = SearchTable_English;
        GetCreatureNameByID = GetCreatureEnglishNameByID;
        function NormalizeString(str)
            return str;
        end 
    else
        TargetTable = SearchTable;
        if CLIENT_TEXT_LOCALE == "zhCN" then
            function NormalizeString(str)
                return gsub(str, "·", " ");
            end
        elseif CLIENT_TEXT_LOCALE == "zhTW" then
            function NormalizeString(str)
                return gsub(str, "‧", " ");
            end
        else
            function NormalizeString(str)
                return str;
            end 
        end
    end

    local fullName, dividedName, initial;
    local names = {};

    local IDs = NarciCreatureInfo.UniqueIDs;

    local numNPC = 0;
    local TempTable = {};

    --Ignore this entry if it contains specific words
    local omission = {};
    for i = 1, #OMISSIONS do
        tinsert(omission, OMISSIONS[i])
    end

    --Don't use these matched words to build search table
    local omissionExtra = {"of", "the"};

    if OMISSIONS_EXTRA then
        for i = 1, #OMISSIONS_EXTRA do
            tinsert(omissionExtra, OMISSIONS_EXTRA[i])
        end
    end

    local numOmission = #omission;
    local numOmissionExtra = #omissionExtra;

    local function ShouldSkip(str)
        --Skip if including following words
        if not str then return true end

        for i = 1, numOmission do
            if find(str, omission[i]) then
                return true
            end
        end

        return false
    end

    local IsMeaningfullWord;
    --local numIgnored = 0;

    if numOmissionExtra > 0 then
        function IsMeaningfullWord(str)
            --Skip if including following words
            if not str then return false end
        
            for i = 1, numOmissionExtra do
                if str == omissionExtra[i] then
                    --numIgnored = numIgnored + 1
                    return false
                end
            end
            
            return true
        end
    else
        function IsMeaningfullWord()
            return true
        end
    end

    for id, isUnique in pairs(IDs) do
        if isUnique then
            fullName = GetCreatureNameByID(id);
            if not ShouldSkip(fullName) then
                numNPC = numNPC + 1;

                fullName = NormalizeString(fullName)
                names = { split(fullName) };
                for i = 1, #names do
                    dividedName = names[i];

                    if IsMeaningfullWord(dividedName) then
                        --print(dividedName)
                        initial = GetInitial(dividedName);
                        if initial then
                            if not TempTable[initial] then
                                TempTable[initial] = { [id] = true };
                            else
                                TempTable[initial][id] = true;
                            end
                        end
                    end
                end
            end
        end
    end
    
    --print(numIgnored)
    --Flaten Search Table
    for initial, SubTable in pairs(TempTable) do
        TargetTable[initial] = {};
        for id, _ in pairs(SubTable) do
            tinsert(TargetTable[initial], id)
        end
    end

    --print("Complete! Unique Creatures: "..PREFIX_YELLOW..numNPC);
end

local function SearchNPCByName(str)
    if not str or str == "" or IsKeyDown("BACKSPACE") then return {}, 0 end
    --str = gsub(str, "(%p)", "%%%1");

    local initial = GetInitial(str);
    local SubTable = SearchTable[initial];

    if not SubTable then
        --print("Couldn't find any creature that begins with "..initial);
        return {}, 0
    end

    local find = string.find;
    local lower = lower;
    local name, id;
    local nameTemp;
    local matchedIDs = {};
    local numMatches = 0;
    local overFlow;

    str = lower(str);
    local str1 = "^"..str;
    local str2 = "[·‧ ]"..str;

    --print("I: "..initial.."  Total: "..#SubTable)

    for i = 1, #SubTable do
        if numMatches > NUM_MAX_MATCHES then
            overFlow = true;
            break
        end

        id = SubTable[i];
        name = GetCreatureNameByID(id);
        if name then
            nameTemp = lower(name);
            if find(nameTemp, str1) or find(nameTemp, str2) then
                --print(name.." "..id)
                tinsert(matchedIDs, {name, id} );
                numMatches = numMatches + 1;
            end
        end
    end

    return matchedIDs, numMatches, overFlow
end
NarciCreatureInfo.SearchNPCByName = SearchNPCByName;

-------------------------------------------------------------------
local Initialize = CreateFrame("Frame");
Initialize:RegisterEvent("ADDON_LOADED");
Initialize:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "Narcissus_Database_NPC" then
            self:UnregisterEvent(event);
            if not NarciCreatureInfo.Names then
                print(NARCI_COLOR_RED_MILD.. "Failed to load Narcissus creature name database.")
                return
            end

            DivideListByInitials();
            if CLIENT_TEXT_LOCALE ~= "enUS" then
                DivideListByInitials("enUS");
            end

            --[[
            numNPC = 0;
            local Names = NarciCreatureInfo.Names;
            for id, name in pairs(Names) do
                if name then
                    numNPC = numNPC + 1;
                end
            end
            
            print("|cffffd200"..numNPC.."|r creature names");
            --]]

            After(0, function()
                collectgarbage("collect");
            end)
        end
    end
end)