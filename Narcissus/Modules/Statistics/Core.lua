--[[
    Confirmation Dialogue Name: CONFIRM_PLAYER_CHOICE   Are you sure you wish to join this Covenant?
    Quest: Choose Your Purpose  57878 Speak to the Covenants: Preview covenant abilities, descriptions
    C_QuestLog.IsQuestFlaggedCompleted(57878)
    Events: COVENANT_CHOSEN
    Blizzard_CovenantChoiceToast.lua

    local covenantData = C_Covenants.GetCovenantData(C_Covenants.GetActiveCovenantID())
    C_Covenants.GetCovenantData(covenantID) --  .name: 1.Kyrian 2.Venthyr 3.Night Fae 4.Necrolord


    C_GossipInfo.GetText()
    strlenutf8()    --Count letters
--]]

--[[
local List = {
    {
        name = "CovenantWalkthrough",
        type = "Duration",
        flagType = "Quest",
        flagArg = 57878,
        startEvent = "Quest",
        startArg = 57878,
        startEvent = "ADDON_LOADED",
        stopArg = "Blizzard_PlayerChoiceUI",
    },

    {
        name = "CovenantDecision",
        type = "Duration",
        flagType = "Quest",
        flagArg = 57878,
        startEvent = "ADDON_LOADED",
        startArg = "Blizzard_PlayerChoiceUI",
        stopEvent = "COVENANT_CHOSEN",
    },

    {
        name = "LevelingTime",
        type = "ExactTime",
        flagType = "Function",
        flagArg = function() return UnitLevel("player") == GetMaxLevelForExpansionLevel( GetExpansionLevel() ) end,
        isRepeated = true,
        startEvent = "PLAYER_LEVEL_UP",
    },
};
--]]
local FormatTime = NarciAPI_FormatTime;


--Private
local EventListener = CreateFrame("Frame");

local DataManager = {};

DataManager.ListByName = {};

function DataManager:LoadData()
    if not NarciStatisticsDB then
        NarciStatisticsDB = {};
    end
    if not NarciStatisticsDB_PC then
        NarciStatisticsDB_PC = {};
    end

    ---------------------
    -----Statistics------
    ---------------------
    --"InstalledDate" (added in 1.1.2)
    --"TimeSpentInNarcissus"
    --"ScreenshotsTakenInNarcissus"
    if not NarciStatisticsDB.InstalledDate then
        NarciStatisticsDB.InstalledDate = time();
    end

    for id, data in pairs(self.List) do
        self.ListByName[data.name] = id;
    end
end

function DataManager:SaveAccountData(field, value)
    NarciStatisticsDB[field] = value;
end

function DataManager:SaveCharacterData(field, value)
    NarciStatisticsDB_PC[field] = value;
end

function DataManager:GetDataByID(id)
    if id and self.List[id] then
        if self.List[id].printFunc then
            self.List[id].printFunc();
        else
            local fields = self.List[id].fields;
            local dataSource;
            local isTime = self.List[id].isTime;
            if self.List[id].isAccountWide then
                dataSource = NarciStatisticsDB;
            else
                dataSource = NarciStatisticsDB_PC;
            end
            for i = 1, #fields do
                local value = dataSource[fields[i].name];
                if value then
                    if isTime then
                        value = FormatTime( tonumber(value) );
                    end
                    print( string.format(fields[i].format, value) );
                end
            end
        end
        return true
    else
        print("Invalid Field");
        return false
    end
end

function DataManager:GetDataByName(name)
    self:GetDataByID(self.ListByName[name]);
end

function DataManager:PrintList()
    print("|cFFFFD100Player Statistics|r")
    for i = 1, #self.List do
        print("#"..i .. ": "..self.List[i].name);
    end
end


--Temporary
SLASH_PLAYERSTATS1 = "/playerstats";
SlashCmdList["PLAYERSTATS"] = function(msg)
    msg = strlower(msg);
    if msg == "" then
        DataManager:PrintList()
    else
        local id = tonumber(msg);
        if id then
            DataManager:GetDataByID(id);
        else
            DataManager:GetDataByName(id)
        end
    end
end

-------------------------------------------------------------------
local SharedTrackerMixin = {};

function SharedTrackerMixin:RegisterEvent(event)
    if not self.isEventRegistered then
        self.isEventRegistered = {};
    end
    EventListener:RegisterEvent(event);
    self.isEventRegistered[event] = true;
    --print("RegisterEvent: "..event)
end

function SharedTrackerMixin:UnregisterEvent(event)
    if not self.isEventRegistered then
        self.isEventRegistered = {};
    end
    self.isEventRegistered[event] = false;
    --print("Unregistered: "..event);
end

function SharedTrackerMixin:IsEventRegistered(event)
    return self.isEventRegistered[event]
end

function SharedTrackerMixin:OnEvent(event, ...)
    if self:IsEventRegistered(event) then
        local killEvent = self:HandleEvent(event, ...);
        if killEvent then
            self:UnregisterEvent(event);
        end
    end
end

function SharedTrackerMixin:HandleEvent(event, ...)
end

function SharedTrackerMixin:Load()
end

-------------------------------------------------------------------

local CovenantChoice = CreateFromMixins(SharedTrackerMixin);

function CovenantChoice:Load()
    self.name = "Covenant";
    if not C_QuestLog.IsQuestFlaggedCompleted(57878) then
        --Quest: Choose Your Purpose (choose covenant)
        if UnitLevel("player") == 60 then
            self:RegisterEvent("QUEST_ACCEPTED");
            self.timeQuestAccepted = time();
        else
            self:RegisterEvent("PLAYER_LEVEL_CHANGED");
        end
        --print("Tracking: ".."Covenant Choice")
        EventListener:HookScript("OnEvent", function(frame, event, ...)
            self:OnEvent(event, ...);
        end)
    end
end

function CovenantChoice:HandleEvent(event, ...)
    --Assume player accept the quest and complete it without logout or reload
    local killEvent;
    if event == "PLAYER_LEVEL_CHANGED" then
        local oldLevel, newLevel = ...;
        if newLevel == 60 then
            killEvent = true;
            self:RegisterEvent("QUEST_ACCEPTED");
        end
    elseif event == "QUEST_ACCEPTED" then
        local questID = ...;
        if questID == 57878 then
            self.timeQuestAccepted = time();
            killEvent = true;
            --print("Timer Start: "..self.timeQuestAccepted)

            --Start Tracking Second Objective:
            if IsAddOnLoaded("Blizzard_PlayerChoiceUI") then
                if PlayerChoiceFrame then
                    PlayerChoiceFrame:HookScript("OnShow", function()
                        if not self.timeChoiceOpened then
                            self.timeChoiceOpened = time();
                            self:RegisterEvent("COVENANT_CHOSEN");
                            if self.timeQuestAccepted then
                                --print("Session1: "..(self.timeChoiceOpened - self.timeQuestAccepted) .." seconds" );
                                DataManager:SaveCharacterData("CovenantWalkthrough", (self.timeChoiceOpened - self.timeQuestAccepted));
                            end
                        end
                    end);
                end
            else
                self:RegisterEvent("ADDON_LOADED");
            end
        end
    elseif event == "ADDON_LOADED" then
        local name = ...;
        --print(name)
        if name == "Blizzard_PlayerChoiceUI" then
            killEvent = true;
            self.timeChoiceOpened = time();
            self:RegisterEvent("COVENANT_CHOSEN");
            if self.timeQuestAccepted then
                --print("Session1: "..(self.timeChoiceOpened - self.timeQuestAccepted) .." seconds" );
                DataManager:SaveCharacterData("CovenantWalkthrough", (self.timeChoiceOpened - self.timeQuestAccepted));
            end
        end
    elseif event == "COVENANT_CHOSEN" then
        killEvent = true;
        self.timeChoiceMade = time();
        if self.timeChoiceOpened then
            --print("Session2: "..(self.timeChoiceMade - self.timeChoiceOpened) .." seconds" );
            DataManager:SaveCharacterData("CovenantDecision", (self.timeChoiceMade - self.timeChoiceOpened));
        end
    end
    return killEvent
end


--------------------------------------------------------------------------------
local GetQuestExpansion = GetQuestExpansion;
local IsQuestTask = C_QuestLog.IsQuestTask; --World Quest / Bonus Objectives
local GetQuestID = GetQuestID;
local GetQuestText = GetQuestText;
local GetObjectiveText = GetObjectiveText;
local gsub = string.gsub;
local strlenutf8 = strlenutf8;

--Track how much time does player spend on reading quests

local ReadQuest = CreateFromMixins(SharedTrackerMixin);

local function CountWords(text)
    text = gsub(text, "%s+", " ");
    local numWords = strlenutf8(text);
    text = gsub(text, "%s+", "");
    numWords = numWords - strlenutf8(text) + 1;
    return numWords or 0
end

function ReadQuest:Load()
    self.name = "ReadQuest";
    EventListener:HookScript("OnEvent", function(frame, event, ...)
        self:OnEvent(event, ...);
    end);

    local events = {"QUEST_ACCEPTED", "QUEST_TURNED_IN",
    "QUEST_DETAIL", "QUEST_COMPLETE",
    }
    for i = 1, #events do
        self:RegisterEvent(events[i]);
    end

    local textLocale = GetLocale();
    if textLocale == "zhCN" or textLocale == "zhTW" or textLocale == "koKR" then
        function CountWords(text)
            text = gsub(text, "%s+", "");
            local numWords = strlenutf8(text);
            return numWords;
        end
    end

    if not NarciStatisticsDB.questReadingTime then
        NarciStatisticsDB.questReadingTime = {};
    end
    if not NarciStatisticsDB.questReadingTime[textLocale] then
        NarciStatisticsDB.questReadingTime[textLocale] = {};
    end
    self.db = NarciStatisticsDB.questReadingTime[textLocale];
end

function ReadQuest:HandleEvent(event, ...)
    --print(event);
    if event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN" then
        local questID = ...;
        local isRelevant = self:IsQuestRelevant(questID);
        --print("QuestID: "..questID);
        --print("isRelevant: "..tostring(isRelevant));
        if isRelevant and questID == self.activeQuestID then
            self:SaveReadingTime(questID, event == "QUEST_TURNED_IN");
        end
    elseif event == "QUEST_DETAIL" then
        self:UpdateActiveQuestData();
    elseif event == "QUEST_COMPLETE" then
        local questID = GetQuestID();
        local isRelevant = self:IsQuestRelevant(questID);
        if isRelevant then
            self:UpdateActiveQuestData(true);
        end
    end
end

function ReadQuest:IsQuestRelevant(questID)
    if questID then
        return (GetQuestExpansion(questID) == 8) and (not IsQuestTask(questID)) --Shadowlands
    else
        return false
    end
end

function ReadQuest:UpdateActiveQuestData(questComplete)
    self.questlineLength = self:GetQuestlineLength(questComplete);
    self.timeStartReading = time();
    self.activeQuestID = GetQuestID();
    self.cache = nil;
end

function ReadQuest:SaveReadingTime(questID, questComplete)
    local timeReading = self.timeStartReading;
    local questlineLength = self.questlineLength;
    if questID and timeReading and questlineLength then
        timeReading = time() - timeReading;
    else
        return
    end
    --print("Quest: "..questID);
    --print("Reading Time: "..timeReading);

    if self.db[questID] then
        if questComplete and not self.db[questID][3] then
            local v1 = self.db[questID][1] or 0;
            local v2 = self.db[questID][2] or 0;
            self.db[questID] = {v1 + questlineLength, v2 + timeReading, true};
        end
    else
        self.db[questID] = {questlineLength, timeReading, questComplete};
    end
end

function ReadQuest:GetQuestlineLength(questComplete)
    local numWords = 0;
    local tempText;
    if questComplete then
        tempText = GetRewardText();
    else
        tempText = GetQuestText();
    end
    
    if not tempText or tempText == "" then
        return numWords
    end

    --tempText = gsub(tempText, "[\r\n]", " ");
    local numWords = CountWords(tempText);
    
    if not questComplete then
        tempText = GetObjectiveText();
        if not tempText or tempText == "" then
            return numWords
        end
        numWords = numWords + CountWords(tempText);
    end
    --print(numWords);
    return numWords
end

function ReadQuest:GetStatistics()
    --use cache
    if not self.cache then
        self.cache = {};
        for locale, questData in pairs(NarciStatisticsDB.questReadingTime) do
            local numQuests = 0;
            local numWords = 0;
            local timeReading = 0;
            for questID, data in pairs(questData) do
                numQuests = numQuests + 1;
                numWords = numWords + (data[1] or 0);
                timeReading = timeReading + (data[2] or 0);
            end
            if numQuests > 0 then
                local speed = 0;
                if timeReading > 0 then
                    speed = math.floor(numWords / timeReading * 60 + 0.5);
                    timeReading = FormatTime(timeReading);
                end
                self.cache = {locale, numQuests, numWords, timeReading, speed};
                --just get one locale for now
                break
            end
        end
    end
    return unpack(self.cache)
end

NarciAPI.GetQuestStatistics = function()
    return ReadQuest:GetStatistics()
end

function ReadQuest:PrintResult()
    print(" ");
    local Y = "|CFFFFD100";

    for locale, questData in pairs(NarciStatisticsDB.questReadingTime) do
        local numQuests = 0;
        local numWords = 0;
        local timeReading = 0;
        for questID, data in pairs(questData) do
            numQuests = numQuests + 1;
            numWords = numWords + (data[1] or 0);
            timeReading = timeReading + (data[2] or 0);
        end
        if timeReading > 0 then
            local wpm = math.floor(numWords / timeReading * 60 + 0.5);
            print(Y.."Language:|r "..locale);
            print(Y.."Quest:|r "..numQuests);
            print(Y.."Words:|r "..numWords);
            print(Y.."Duration:|r "..FormatTime(timeReading));
            print(Y.."Speed:|r "..wpm.." wpm")
            print(" ");
        end
    end
end

local function PrintReadingSpeed()
    ReadQuest:PrintResult();
end

local function PrintAddOnUsage()
    local timeSpent = NarciStatisticsDB.TimeSpentInNarcissus or 0;
    local installedDate = NarciStatisticsDB.InstalledDate;
    if timeSpent and installedDate then
        local installedDateString = date("%d %m %y", installedDate);
        local day, month, year = string.split(" ", installedDateString);
        if day and month and year then
            day = tonumber(day);
            month = tonumber(month);
            year = tonumber(year);
            local dateString = FormatShortDate(day, month, year);
            timeSpent = SecondsToTime(timeSpent);
            print(string.format("|cFFFFD100Total time spent in Narcissus:|r %s", timeSpent));
            print(string.format("|cFFFFD100Installed On:|r %s", dateString));
        end
    end
end

local function PrintScreenshotsTaken()
    local numTaken = NarciStatisticsDB.ScreenshotsTakenInNarcissus or 0;
    print(string.format("|cFFFFD100Screenshots Taken In Narcissus:|r %s", numTaken));
end

------------------------------------------------------------------------------------------------------------
DataManager.List ={
    [1] = {
        name = "TimeSpentInNarcissus",
        printFunc = PrintAddOnUsage,
    },

    [2] = {
        name = "ScreenshotsTakenInNarcissus",
        printFunc = PrintScreenshotsTaken,
    },

    [3] = {
        name = "CovenantChoice",
        isAccountWide = false,
        isTime = true,
        fields = {
            {name = "CovenantWalkthrough", format = "|cFFFFD100Spoke to the Covenants:|r %s"},
            {name = "CovenantDecision", format = "|cFFFFD100Made the final decision:|r %s"},
        },
    },

    [4] = {
        name = "ReadingSpeed",
        printFunc = PrintReadingSpeed,
    },
};

--local events = {"GOSSIP_SHOW", "GOSSIP_CLOSED", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "ADDON_LOADED", "PLAYER_CHOICE_UPDATE", "PLAYER_CHOICE_CLOSE"}
EventListener:RegisterEvent("PLAYER_ENTERING_WORLD");


EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        DataManager:LoadData();
        CovenantChoice:Load();
        ReadQuest:Load();
    end
    --print(event);
    --print(...)
end)

--[[
hooksecurefunc("StaticPopup_Show", function(name)
    print(name)
end)
--]]