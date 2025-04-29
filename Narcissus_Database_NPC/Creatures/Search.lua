NarciCreatureInfo = {};
NarciCreatureInfo.isLanguageLoaded = {};

local L = Narci.L;
local sub = string.sub;
local gsub = string.gsub;
local lower = string.lower;
local upper = string.upper;
local format = string.format;
local strsplit = strsplit;
local tinsert = table.insert;
local After = C_Timer.After;

local UnitGUID = UnitGUID;
local UnitIsPlayer = UnitIsPlayer;
local UnitIsOtherPlayersPet = UnitIsOtherPlayersPet;
local InCombatLockdown = InCombatLockdown;
local IsKeyDown = IsKeyDown;
local IsShiftKeyDown = IsShiftKeyDown;

local CLIENT_TEXT_LOCALE = GetLocale();
if CLIENT_TEXT_LOCALE == "enGB" then
    CLIENT_TEXT_LOCALE = "enUS";
end

local function SplitBySpace(str)
    return strsplit(" ", str)
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
local NUM_MAX_RELATIVES = 10;
local OTHER_LAST_NAME_FORMAT = L["Other Last Name Format"] or ("Other "..NARCI_COLOR_GREY_70.."%s(s)|r:\n");
local TOO_MUCH_RESULTS = format(L["Too Many Matches Format"] or ("\nOver %s matches."), NUM_MAX_RELATIVES);
local PREFIX_YELLOW = "|cffffd200";
local PREFIX_GREY = "|cffcccccc";
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

local function SortFunc(a, b)
    if a[1] == b[1] then
        return a[2] < b[2]
    else
        return a[1] < b[1]
    end
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

local function HasValidLastName(fullName)
    local lastName = {SplitBySpace(fullName)};
    local namePos = #lastName;
    if namePos <= 1 then
        return false
    else
        return true
    end
end

local function SearchRelativesByName(fullName, useEnglish)
    if not fullName or fullName == "" or IsKeyDown("BACKSPACE") then return {}, 0 end

    local lastNames = {SplitBySpace(fullName)};
    local namePos = #lastNames;
    if namePos <= 1 then return {}, 0 end

    local lower = lower;
    local lastName = lower(lastNames[namePos])
    local initial = GetInitial(lastName);
    local SubTable;
    local GetCreatureNameByID = GetCreatureNameByID;
    local GetCreatureEnglishNameByID = GetCreatureEnglishNameByID;

    if CLIENT_TEXT_LOCALE == "enUS" then
        SubTable = SearchTable[initial];
    else
        SubTable = SearchTable_English[initial];
    end

    if not SubTable then
        return {}, 0
    end

    useEnglish = (CLIENT_TEXT_LOCALE == "enUS")

    local name, id;
    local nameTemp;
    local matchedNames = {};
    local matchedIDs = {};
    local numMatches = 0;
    local overFlow;

    local str1 = "^"..lastName;
    local str2 = "[·‧ ]"..lastName;

    local NUM_MAX_RELATIVES = NUM_MAX_RELATIVES - 1;
    for i = 1, #SubTable do
        if numMatches > NUM_MAX_RELATIVES then
            overFlow = true;
            break
        end

        id = SubTable[i];
        name = GetCreatureEnglishNameByID(id);
        if name then
            nameTemp = { strsplit(" ", name) };
            namePos = #nameTemp
            if namePos > 1 then
                nameTemp = nameTemp[namePos];
                if nameTemp and lower(nameTemp) == lastName and name ~= fullName then
                    if not matchedNames[name] then
                        matchedNames[name] = true;
                        if not useEnglish then
                            name = GetCreatureNameByID(id);
                        end
                        tinsert(matchedIDs, {name, id})
                        numMatches = numMatches + 1;
                    end
                end
            end
        end
    end
    matchedNames = nil;
    table.sort(matchedIDs, SortFunc);
    lastName = gsub(lastName, "^%l", upper);
    return matchedIDs, numMatches, overFlow, lastName
end

local function SearchRelativesByID(creatureID)
    return SearchRelativesByName( GetCreatureLocalizedNameByID(creatureID, "enUS"), "useEnglish")
end

NarciCreatureInfo.SearchNPCByName = SearchNPCByName;
NarciCreatureInfo.SearchRelativesByName = SearchRelativesByName;

-------------------------------------------------------------------
--Add localized name to nameplate
local NarcissusUnitFrames = {};
local NamePlateNameOffset = 0;
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit;

local function GetFontByLanguage(language)
    if language == "zhCN" or language == "zhTW" or language == "koKR" then
        return "Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf"
    else
        return "Interface\\AddOns\\Narcissus\\Font\\NotoSans-Medium.ttf"
    end
end

local function SetNamePlateNameOffset(offset)
    NamePlateNameOffset = offset or NarcissusDB.NamePlateNameOffset or 0;
    local point, relativeTo, relativePoint, fontString;
    for _, frame in pairs(NarcissusUnitFrames) do
        fontString = frame.TranslatedName;
        fontString:SetPoint("BOTTOM", fontString.relativeTo, "TOP", 0, 2 + NamePlateNameOffset);
    end
end

NarciCreatureInfo.SetNamePlateNameOffset = SetNamePlateNameOffset;

local function AcquireTranslationFrame(nameplate, language)
    if not nameplate.NarcissusUnitFrame then
        local NarcissusUnitFrame = CreateFrame("Frame", nil, nameplate);
        tinsert(NarcissusUnitFrames, NarcissusUnitFrame);
        nameplate.NarcissusUnitFrame = NarcissusUnitFrame;
        local fontString = NarcissusUnitFrame:CreateFontString(nil, "BACKGROUND");
        NarcissusUnitFrame.TranslatedName = fontString;

        --Style
        NarcissusUnitFrame:SetSize(2, 2);
        NarcissusUnitFrame:SetPoint("TOP", nameplate.UnitFrame, "TOP", 0, 0);
        fontString.relativeTo = nameplate.UnitFrame.name;
        fontString:SetPoint("BOTTOM", fontString.relativeTo, "TOP", 0, 2 + NamePlateNameOffset);
        fontString:SetFont( GetFontByLanguage( language ), 8);
        fontString:SetTextColor(0.9, 0.9, 0.9);
        fontString:SetShadowColor(0, 0, 0);
        fontString:SetShadowOffset(1, -1);

        return fontString
    end

    return nameplate.NarcissusUnitFrame.TranslatedName
end

local function SetNamePlateName(unit, language)
    --Translate Name
    local creatureID = { strsplit("-", UnitGUID(unit) ) };
    creatureID = tonumber(creatureID[6]);
    --local name = UnitName(unit);
    local localizedName = GetCreatureLocalizedNameByID(creatureID, language);
    local NamePlate = GetNamePlateForUnit(unit);
    local fontString = AcquireTranslationFrame(NamePlate, language);
    fontString:SetText(localizedName);
    fontString:Show();
end

local function HideNamePlateName(unit)
    local UnitFrame = GetNamePlateForUnit(unit).NarcissusUnitFrame;
    if UnitFrame then
        local fontString = UnitFrame.TranslatedName;
        if fontString then
            fontString:Hide();
        end
    end
end

local NamePlateListener = CreateFrame("Frame");

local function ShowTranslationOnNameplate(state)
    local language = NarcissusDB.NamePlateLanguage;

    if state and language then
        NamePlateListener:RegisterEvent("NAME_PLATE_UNIT_ADDED");
        NamePlateListener:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
        NamePlateListener.language = language;
        local font = GetFontByLanguage(language);
        for _, frame in pairs(NarcissusUnitFrames) do
            frame.TranslatedName:SetFont(font, 8);
            frame:Show();
        end
        SetNamePlateNameOffset();
    else
        NamePlateListener:UnregisterEvent("NAME_PLATE_UNIT_ADDED");
        NamePlateListener:UnregisterEvent("NAME_PLATE_UNIT_REMOVED");

        for _, frame in pairs(NarcissusUnitFrames) do
            frame:Hide();
        end
    end
end
NarciCreatureInfo.ShowTranslationOnNameplate = ShowTranslationOnNameplate;
 
NamePlateListener:SetScript("OnEvent", function(self,event,...)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        if unit and not ( UnitIsPlayer(unit) or UnitIsOtherPlayersPet(unit) ) then
            SetNamePlateName(unit, self.language);
        end
    end
    
    if event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        if unit then
            HideNamePlateName(unit);
        end
    end
end);

-------------------------------------------------------------------
--Extra Info on Tooltip: Translate Names/Find relatives

local GTP = GameTooltip;
local GTPTitle = _G["GameTooltip".. "TextLeft1"];
local ETP, ETP2;                      --Extra Tooltips. Create this frame after every other addons have been loaded
local ETPName = "Narci_NPCTooltip";
local ETP2Name = "Narci_RelatedNPCTooltip";
local FORMAT_FIND_RELATIVES_HOTKEY = L["Find Relatives Hotkey Format"];
local CREATURE_TOOLTIP_ENABLED, FIND_RELATIVES, TRANSLATE_NAME_TOOLTIP;     --Load it later
local NPCModel;
local UnitData = {};
local LAST_UNIT_NAME = "";
local CACHED_NPC = {};
local EnabledLanguages = {};
local NUM_ENABLED_LOCALES = 0;

local function UpdateEnabledLanguages()
    wipe(EnabledLanguages);
    NUM_ENABLED_LOCALES = 0;
    ETP:Hide();

    if NarcissusDB.TranslateName then
        if NarcissusDB.NameTranslationPosition == 2 then
            --print("Show translated name on name plate");
            ShowTranslationOnNameplate(true);
        else
            --print("Show translated name on tooltip");
            local Languages = NarcissusDB.TooltipLanguages;
            if Languages then
                for language, isEnabled in pairs(Languages) do
                    if isEnabled and language ~= CLIENT_TEXT_LOCALE then
                        tinsert(EnabledLanguages, language);
                        NUM_ENABLED_LOCALES = NUM_ENABLED_LOCALES + 1;
                    end
                end
            end

            table.sort(EnabledLanguages, function(a, b) return a < b end);
            GameTooltip_AddBlankLinesToTooltip(ETP, NUM_ENABLED_LOCALES + 3);
            ShowTranslationOnNameplate(false);
        end
    else
        ShowTranslationOnNameplate(false);
    end
end

local function EnableLanguage(language, state)
    NarcissusDB.TooltipLanguages = NarcissusDB.TooltipLanguages or {};
    NarcissusDB.TooltipLanguages[language] = state;
    UpdateEnabledLanguages();
end

local TooltipSetUnitCallback;     --function Create Later (Pre 10.0.2)

local function SetIsCreatureTooltipEnabled()
    FIND_RELATIVES = NarcissusDB.SearchRelatives;
    TRANSLATE_NAME_TOOLTIP = NarcissusDB.TranslateName and NarcissusDB.NameTranslationPosition == 1;
    CREATURE_TOOLTIP_ENABLED = FIND_RELATIVES or TRANSLATE_NAME_TOOLTIP;

    if CREATURE_TOOLTIP_ENABLED and (not ETP.hasHooked) then
        ETP.hasHooked = true;
        GTP:HookScript("OnHide", function()
            LAST_UNIT_NAME = "";
        end);

        if GTP:HasScript("OnTooltipSetUnit") then
            GTP:HookScript("OnTooltipSetUnit", TooltipSetUnitCallback);
        elseif TooltipDataProcessor and GTP.SetUnit then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, TooltipSetUnitCallback);
        end
    else
        ETP:Hide();
    end
end

local function DisableTranslator()
    wipe(EnabledLanguages);
    NUM_ENABLED_LOCALES = 0;
    NarcissusDB.TranslateName = false;
    SetIsCreatureTooltipEnabled();
end

local function UpdateNPCSettings()
    SetIsCreatureTooltipEnabled();
    ShowTranslationOnNameplate(NarcissusDB.TranslateName and NarcissusDB.NameTranslationPosition == 2);
end

NarciCreatureInfo.UpdateEnabledLanguages = UpdateEnabledLanguages;
NarciCreatureInfo.EnableLanguage = EnableLanguage;
NarciCreatureInfo.DisableTranslator = DisableTranslator;
NarciCreatureInfo.UpdateNPCSettings = UpdateNPCSettings;

local function RequestNPCInfo(id)
    ETP2:SetHyperlink(format("unit:Creature-0-0-0-0-%d", id));
    CACHED_NPC[id] = true;
end

local function RemoveLevel(fontString)
    --Remove "Level ??"
    local title = fontString:GetText() or "";
    title = gsub(title, NARCI_NPC_BROWSER_TITLE_LEVEL, "");
    if title and title ~= "" then
        fontString:SetText(title);
    end
end

local function SetRelatedNPCTooltip(id)
    ETP2:ClearAllPoints();
    ETP2:SetOwner(ETP, "ANCHOR_NONE");
    if ETP.isLeft then
        ETP2:SetPoint("BOTTOMRIGHT", ETP, "BOTTOMLEFT", -2, 0);
    else
        ETP2:SetPoint("BOTTOMLEFT", ETP, "BOTTOMRIGHT", 2, 0);
    end
    ETP2:SetHyperlink(format("unit:Creature-0-0-0-0-%d", id));

    RemoveLevel(ETP2.line2);
    RemoveLevel(ETP2.line3);

    --Update Width
    ETP2:SetMinimumWidth(200);
    ETP2:SetPadding(0,0);

    --Model
    After(0, function()
        NPCModel:SetCreature(id);
        NPCModel:SetViewTranslation(NPCModel:GetWidth() * 0.5, 0);
        NPCModel:Show();
    end)
end

local SCREEN_COORD_X_MAX, SCREEN_COORD_Y_MAX = UIParent:GetSize();
local function SetTooltipOrientation()
    ETP:ClearAllPoints();
    ETP:SetOwner(GTP, "ANCHOR_NONE");
    local posRight = GTP:GetRight();
    if posRight and posRight + 450 > SCREEN_COORD_X_MAX then
        ETP.isLeft = true;
        ETP:SetPoint("TOPRIGHT", GTP, "TOPLEFT", -2, 0);
    else
        ETP.isLeft = nil;
        ETP:SetPoint("TOPLEFT", GTP, "TOPRIGHT", 2, 0);
    end
end

local function InitializeExtraTooltip(name)
    SetTooltipOrientation();
    ETP:SetClampedToScreen(true);
    ETP:SetText(name, GTPTitle:GetTextColor());
end

local function UpdateNPCTooltip(name, unit, showRelatives)
    if not ( UnitIsPlayer(unit) or UnitIsOtherPlayersPet(unit) ) then
        ETP:ClearLines();
        --Translate Name
        local creatureID = { strsplit("-", UnitGUID(unit) ) };
        creatureID = tonumber(creatureID[6]);
        if not creatureID then return end

        if TRANSLATE_NAME_TOOLTIP and NUM_ENABLED_LOCALES > 0 then
            InitializeExtraTooltip(name);

            if NUM_ENABLED_LOCALES > 1 then
                for _, language in pairs(EnabledLanguages) do
                    local localizedName = GetCreatureLocalizedNameByID(creatureID, language);
                    if localizedName then
                        localizedName = gsub(localizedName, "‧", "·");
                        ETP:AddDoubleLine(localizedName, language, 1, 1, 1, 0.5, 0.5, 0.5);
                    end
                end
            else
                local localizedName = GetCreatureLocalizedNameByID(creatureID, EnabledLanguages[1]);
                if localizedName then
                    localizedName = gsub(localizedName, "‧", "·");
                    ETP:AddLine(localizedName, 1, 1, 1);
                end
            end
        end

        --Find Relatives
        if FIND_RELATIVES then
            local englishName = GetCreatureEnglishNameByID(creatureID);
            if not englishName then return end

            if showRelatives or UnitData[name] then
                local numMacthes, relatives, overFlow, lastName;
                local data = UnitData[name];
                if not data then
                    UnitData[name] = {};
                    data = UnitData[name];
                    data.relatives, data.numMacthes, data.overFlow, data.lastName = SearchRelativesByName(englishName, "enUS");
                end
                relatives, numMacthes, overFlow, lastName = data.relatives, data.numMacthes, data.overFlow, data.lastName;

                if numMacthes > 0 then
                    if NUM_ENABLED_LOCALES > 0 then
                        ETP:AddLine(" ");
                    else
                        InitializeExtraTooltip(name);
                    end
                    ETP:AddLine(format(OTHER_LAST_NAME_FORMAT, lastName), 0.5, 0.5, 0.5);

                    local line = 0;
                    local delayTooltip;
                    local id;
                    for _, v in pairs(relatives) do
                        name = v[1];
                        id = v[2];
                        line = line + 1;
                        if not CACHED_NPC[id] then
                            delayTooltip = true;
                            RequestNPCInfo(id);
                        end

                        if line == ETP.creatureIndex then
                            name = WARDROBE_TOOLTIP_CYCLE_ARROW_ICON.. name;

                            if not delayTooltip then
                                SetRelatedNPCTooltip(id);
                            else
                                After(0.25, function()
                                    SetRelatedNPCTooltip(id, true);
                                end);
                            end
                        else
                            name = WARDROBE_TOOLTIP_CYCLE_SPACER_ICON.. name
                        end

                        ETP:AddDoubleLine(name, id, nil, nil, nil, 0.5, 0.5, 0.5);
                    end

                    if numMacthes > 1 then
                        ETP.tooltipCycle = numMacthes;
                        if overFlow then
                            ETP:AddLine(TOO_MUCH_RESULTS, 0.5, 0.5, 0.5, true);
                        end
                    else
                        ETP.tooltipCycle = nil;
                    end
                else
                    ETP.tooltipCycle = nil;

                    if NUM_ENABLED_LOCALES == 0 then
                        InitializeExtraTooltip(NARCI_COLOR_RED_MILD.. "No Result");
                    end
                end
            else
                if HasValidLastName(englishName) then
                    local tooltip;
                    if NUM_ENABLED_LOCALES > 0 then
                        tooltip = ETP;
                        ETP:SetClampedToScreen(true);
                    else
                        ETP:SetOwner(GTP, "ANCHOR_NONE");
                        ETP:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 10, -10);
                        ETP:SetText("Hello");
                        ETP:SetClampedToScreen(false);
                        tooltip = GTP;
                    end
                    tooltip:AddLine(" ");
                    tooltip:AddLine(format(FORMAT_FIND_RELATIVES_HOTKEY, ("Tab" or NOT_BOUND) ) , 0.5, 0.5, 0.5);
                end
            end
        end

        ETP:Show();
    end
end

function TooltipSetUnitCallback()
    if not CREATURE_TOOLTIP_ENABLED then return end;
    local name, unit = GTP:GetUnit();
    if unit then
        if name and (name ~= LAST_UNIT_NAME) then
            ETP:Hide();
            LAST_UNIT_NAME = name;
            ETP.tooltipCycle = nil;
            ETP.creatureIndex = 1;
            UpdateNPCTooltip(name, unit);
        end
    else
        ETP:Hide();
    end
end

local function Tooltip_OnKeyDown(self, key)
    if not InCombatLockdown() then
        if key == "TAB" then
            if self.tooltipCycle then
                if not IsShiftKeyDown() then
                    if self.creatureIndex < self.tooltipCycle then
                        self.creatureIndex = self.creatureIndex + 1;
                    else
                        self.creatureIndex = 1;
                    end
                else
                    if self.creatureIndex > 1 then
                        self.creatureIndex = self.creatureIndex - 1;
                    else
                        self.creatureIndex = self.tooltipCycle;
                    end
                end
            end

            local name, unit = GTP:GetUnit();
            if name and unit then
                UpdateNPCTooltip(name, unit, true);
                self:SetPropagateKeyboardInput(false);
            else
                self:SetPropagateKeyboardInput(true);
            end
        else
            self:SetPropagateKeyboardInput(true);
        end
    end
end

local function Tooltip_OnShow(self)
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
end

local function Tooltip_OnHide(self)
    self:Hide();
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
end

local function Tooltip_OnEvent(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:Hide();
    end
end

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

            ETP = CreateFrame("GameTooltip", ETPName, GTP, "GameTooltipTemplate");

            SetIsCreatureTooltipEnabled();

            ETP:SetScript("OnKeyDown", Tooltip_OnKeyDown);
            ETP:SetScript("OnEvent", Tooltip_OnEvent);
            ETP:SetScript("OnHide", Tooltip_OnHide);
            ETP:SetScript("OnShow", Tooltip_OnShow);

            ETP2 = CreateFrame("GameTooltip", ETP2Name, ETP, "GameTooltipTemplate");
            ETP2:SetClampedToScreen(false);
            ETP2:SetOwner(ETP, "ANCHOR_NONE");
            ETP2:SetText(" ");
            ETP2:AddDoubleLine(" ", " ");
            ETP2:AddDoubleLine(" ", " ");
            ETP2:AddDoubleLine(" ", " ");
            ETP2.line2 = _G[ETP2Name.."TextLeft2"];
            ETP2.line3 = _G[ETP2Name.."TextLeft3"];
            ETP2:Hide();

            NPCModel = CreateFrame("CinematicModel", nil, ETP2);
            NPCModel:SetPoint("BOTTOMLEFT", ETP2, "TOPLEFT", 0, 0);
            NPCModel:SetPoint("BOTTOMRIGHT", ETP2, "TOPRIGHT", 0, 0);
            NPCModel:SetHeight(200);
            NarciAPI.TransitionAPI.SetModelLight(NPCModel, true, false, - 0.44699833180028 ,  0.72403680806459 , -0.52532198881773, 0.8, 172/255, 172/255, 172/255, 1, 0.8, 0.8, 0.8);

            UpdateEnabledLanguages();

            After(0, function()
                collectgarbage("collect");
            end)
        end
    end
end)