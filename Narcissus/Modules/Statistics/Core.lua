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
local FormatTime = NarciAPI.FormatTime;


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

    --[[
    for id, data in pairs(self.List) do
        self.ListByName[data.name] = id;
    end
    --]]
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

--Temporary
--[[
function DataManager:GetDataByName(name)
    self:GetDataByID(self.ListByName[name]);
end

function DataManager:PrintList()
    print("|cFFFFD100Player Statistics|r")
    for i = 1, #self.List do
        print("#"..i .. ": "..self.List[i].name);
    end
end

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
--]]

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
--[[
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
--]]

--------------------------------------------------------------------------------
--Track how much time does player spend on reading quests
local function ReadQuest_CompressOldData()
    if NarciStatisticsDB.questReadingTime then
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
                NarciStatisticsDB.SLQuestReadingTime = {locale, numQuests, numWords, timeReading, speed};
                break
            end
        end
        NarciStatisticsDB.questReadingTime = nil;
    end
end

local function ReadQuest_GetStatistics()
    if NarciStatisticsDB.SLQuestReadingTime then
        return unpack(NarciStatisticsDB.SLQuestReadingTime)
    end
end

NarciAPI.GetQuestStatistics = ReadQuest_GetStatistics;

------------------------------------------------------------------------------------------------------------


do
    local _, addon = ...
    local function PlayerEnteringWorld_OneTime()
        DataManager:LoadData();
        ReadQuest_CompressOldData();
    end
    addon.AddInitializationCallback(PlayerEnteringWorld_OneTime);
end

--[[
hooksecurefunc("StaticPopup_Show", function(name)
    print(name)
end)


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
};

--]]