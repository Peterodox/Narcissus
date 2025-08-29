local HIDE_MYTHIC_TAB_ON_LOW_LEVELS = true;


local _, addon = ...

local L = Narci.L;
local After = C_Timer.After;
local C_MythicPlus = C_MythicPlus;
local C_ChallengeMode = C_ChallengeMode;
local NarciAPI = NarciAPI;
local WrapNameWithClassColor = NarciAPI.WrapNameWithClassColor;
local ConvertHexColorToRGB = NarciAPI.ConvertHexColorToRGB;
local SmartSetName = NarciAPI.SmartSetName;
local RemoveTextBeforeColon = NarciAPI.RemoveTextBeforeColon;
local UpdateTabButtonVisual = addon.UpdateTabButtonVisual;

local MAP_FILE_PREFIX = "Interface\\AddOns\\Narcissus\\Art\\Modules\\Competitive\\MythicPlus\\Maps\\";
local CARD_FULL_HEIGHT = 315;   --13 * 24

local AFFIX_TYRANNICAL;     --9
local AFFIX_FORTIFIED;      --10

local MainFrame, OwnedKeystoneFrame;

local MAP_UI_INFO = {
    --[] = {name = '', barColor = ''},

    [375] = {name = 'mists-of-tirna-scithe', barColor ='6273f4'},
    [376] = {name = 'the-necrotic-wake', barColor = '63c29a'},
    [377] = {name = 'de-other-side', barColor = '8240e8'},
    [378] = {name = 'halls-of-atonement', barColor = 'd80075'},
    [379] = {name = 'plaguefall', barColor = '6fd54f'},
    [380] = {name = 'sanguine-depths', barColor = 'f73b39'},
    [381] = {name = 'spires-of-ascension', barColor = '85c5ff'},
    [382] = {name = 'theater-of-pain', barColor = '83c855'},
    [391] = {name = 'tazavesh-the-veiled-market', barColor = '5f8afa'},     --Street
    [392] = {name = 'tazavesh-the-veiled-market', barColor = '5f8afa'},     --Gambit

    [369] = {name = 'operation-mechagon', barColor = '4ebbc9'},    --Junkyard
    [370] = {name = 'operation-mechagon', barColor = '4ebbc9'},    --Workshop
    [227] = {name = 'return-to-karazhan', barColor = '68abe0'},    --Lower
    [234] = {name = 'return-to-karazhan', barColor = '68abe0'},    --Upper
    [166] = {name = 'grimrail-depot', barColor = 'b79266'},
    [169] = {name = 'iron-docks', barColor = 'b79266'},

    [165] = {name = 'shadowmoon-burial-grounds', },
    [399] = {name = 'ruby-life-pools', },
    [400] = {name = 'the-nokhud-offensive', },
    [401] = {name = 'the-azure-vault', },
    [200] = {name = 'halls-of-valor', },
    [210] = {name = 'court-of-stars', },
    [402] = {name = 'algethar-academy', },
    [2] = {name = 'temple-of-the-jade-serpent', },

    [438] = {name = 'the-vortex-pinnacle', },
    [403] = {name = 'uldaman-legacy-of-tyr', },
    [404] = {name = 'neltharus', },
    [406] = {name = 'halls-of-infusion', },
    [251] = {name = 'the-underrot', },
    [245] = {name = 'freehold', },
    [206] = {name = 'neltharions-lair', },
    [405] = {name = 'brackenhide-hollow', },

    [244] = {name = 'ataldazar', },
    [199] = {name = 'black-rook-hold', },
    [198] = {name = 'darkheart-thicket', },
    [168] = {name = 'the-everbloom', },
    [456] = {name = 'throne-of-the-tides', },
    [248] = {name = 'waycrest-manor', },
    [463] = {name = 'dawn-of-the-infinite', },  --Galakrond
    [464] = {name = 'dawn-of-the-infinite', },  --Murozond

    [501] = {name = 'the-stonevault'},
    [503] = {name = 'arakara-city-of-echoes'},
    [507] = {name = 'grim-batol'},
    [505] = {name = 'the-dawnbreaker'},
    [353] = {name = 'siege-of-boralus'},
    [502] = {name = 'city-of-threads'},

    [500] = {name = 'the-rookery'},
    [504] = {name = 'darkflame-cleft'},
    [499] = {name = 'priory-of-the-sacred-flame'},
    [506] = {name = 'cinderbrew-meadery'},
    [525] = {name = 'operation-floodgate'},
    [247] = {name = 'the-motherlode'},

    [542] = {name = 'ecodome-aldani'},
};

local SEASON_MAPS = {542, 525, 505, 503, 499, 392, 391, 378};
local IS_MAP_THIS_SEASON = {};

local function ShowNewDungeons()
    --Use this to get season map
    local maps = C_ChallengeMode.GetMapTable();
    print(string.format("This season has %d dungeons.", #maps));

    local n = 0;

    for i, mapChallengeModeID in ipairs(maps) do
        local mapName = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID);
        local text = "#"..i;
        if not MAP_UI_INFO[mapChallengeModeID] then
            text = "|cffffd100Missing|r "..text;
        end
        print(string.format("%s  %d  %s", text, mapChallengeModeID, mapName));
    end
end

NarciAPI.ShowNewMythicPlusDungeons = ShowNewDungeons;
--/run NarciAPI.ShowNewMythicPlusDungeons() --debug



local function FormatDuration(seconds)
    seconds = (seconds and tonumber(seconds)) or 0;
    local minutes = math.floor(seconds / 60);
    local restSeconds = seconds - minutes * 60;
    if restSeconds < 10 then
        restSeconds = "0"..restSeconds;
    end
    if minutes < 10 then
        minutes = "0"..minutes;
    end
    return string.format("%s:%s", minutes, restSeconds);
end

local function SharedOnMouseDown(self, button)
    if button == "RightButton" then
        MainFrame:ToggleMapDetail(false);
    end
end


local DataProvider = {};

function DataProvider:Init()
    self.mapRecords = {};
    self.mapNames = {};
    self.mapTimers = {};
    self.mapIDs = {};   --Map with record
    self.mapIcons = {};

    self.Init = nil;
end

function DataProvider:GetSeasonBestForMap(mapID)
    if not self.mapRecords[mapID] then
        self.mapRecords[mapID] = {};
    end
    local data = self.mapRecords[mapID];
    if data.isCached then
        return data.intimeInfo, data.overtimeInfo, true
    else
        local intimeInfo, overtimeInfo =  C_MythicPlus.GetSeasonBestForMap(mapID);
        if intimeInfo or overtimeInfo then
            data.intimeInfo = intimeInfo;
            data.overtimeInfo = overtimeInfo;
            local memberInfoReady = false;
            if intimeInfo then
                if intimeInfo.members and #intimeInfo.members >= 5 then
                    memberInfoReady = true;
                end
            end
            if overtimeInfo then
                if overtimeInfo.members and #overtimeInfo.members >= 5 then
                    memberInfoReady = memberInfoReady and true;
                else
                    memberInfoReady = false;
                end
            end
            if memberInfoReady then
                data.isCached = true;
            end
        end
        return intimeInfo, overtimeInfo, data.isCached
    end
end

function DataProvider:GetSesaonBestScoreLevelTime(mapID)
    local intimeInfo, overtimeInfo = self:GetSeasonBestForMap(mapID);
    local info, isOvertime;

    if intimeInfo and overtimeInfo then
        if intimeInfo.dungeonScore > overtimeInfo.dungeonScore then
            info = intimeInfo;
            isOvertime = false;
        else
            info = overtimeInfo;
            isOvertime = true;
        end
    else
        isOvertime = overtimeInfo ~= nil;
        info = (isOvertime and overtimeInfo) or intimeInfo;
    end

    if info then
        local dungeonScore = info.dungeonScore;
        local level = info.level
        local durationSec = info.durationSec;
        return dungeonScore, level, durationSec, isOvertime
    end
end

function DataProvider:CacheMapUIInfo(mapID)
    local name, id, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID);
    if name then
        if not self.mapNames[mapID] then
            self.mapNames[mapID] = RemoveTextBeforeColon(name);
        end
    end
    if timeLimit then
        if not self.mapTimers[mapID] then
            self.mapTimers[mapID] = timeLimit;
        end
    end
    if texture then
        if not self.mapIcons[mapID] then
            self.mapIcons[mapID] = texture;
        end
    end
end

function DataProvider:GetMapName(mapID)
    if self.mapNames[mapID] then
        return self.mapNames[mapID];
    end

    self:CacheMapUIInfo(mapID);
    return self.mapNames[mapID];
end

function DataProvider:GetMapTimer(mapID)
    if self.mapTimers[mapID] then
        return self.mapTimers[mapID];
    end

    self:CacheMapUIInfo(mapID);
    return self.mapTimers[mapID];
end

function DataProvider:GetMapIcon(mapID)
    if self.mapIcons[mapID] then
        return self.mapIcons[mapID];
    end

    self:CacheMapUIInfo(mapID);
    return self.mapIcons[mapID];
end

function DataProvider:GetMapTexture(mapID)
    if mapID and MAP_UI_INFO[mapID] then
        return MAP_FILE_PREFIX.. MAP_UI_INFO[mapID].name
    end
end

function DataProvider:GetPageByMapID(mapID)
    for page, id in pairs(self.mapIDs) do
        if id == mapID then
            return page
        end
    end
    return 0
end

function DataProvider:GetMapIDByOrder(page)
    return self.mapIDs[page];
end

function DataProvider:SetMapComplete(mapID)
    table.insert(self.mapIDs, mapID);
    self.numCompleteMaps = #self.mapIDs;
end

function DataProvider:GetWeeklyAffixesForLevel(keystoneLevel)
    local weeklyAffixes = C_MythicPlus.GetCurrentAffixes();
    local affixes = {};
    if weeklyAffixes then
        local total;
        if keystoneLevel then
            total = 4;
        else
            if keystoneLevel >= 10 then
                total = 4;
            elseif keystoneLevel >= 7 then
                total = 3;
            elseif keystoneLevel >= 4 then
                total = 2;
            elseif keystoneLevel >= 2 then
                total = 1;
            else
                total = 0;
            end
        end
        for i = 1, total do
            if weeklyAffixes[i] then
                table.insert(affixes, weeklyAffixes[i].id);
            else
                break;
            end
        end
    end
    return affixes;
end

function DataProvider:ClearRecords()
    self.mapRecords = {};
end

NarciMythicPlusAffixFrameMixin = {};

function NarciMythicPlusAffixFrameMixin:OnEnter()
    self.Icon:SetVertexColor(1, 1, 1);

    local name, description, icon = C_ChallengeMode.GetAffixInfo(self.affixID);
    local tp = NarciGameTooltip;
    tp:Hide();
    tp:SetOwner(self, "ANCHOR_NONE");
    tp:SetText(name);
    tp:AddLine(description, 1, 1, 1, true);
    tp:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 0);
    tp:Show();
end

function NarciMythicPlusAffixFrameMixin:OnLeave()
    self.Icon:SetVertexColor(0.8, 0.8, 0.8);
    NarciGameTooltip:Hide();
end

function NarciMythicPlusAffixFrameMixin:OnMouseDown(button)
    SharedOnMouseDown(nil, button);
end

function NarciMythicPlusAffixFrameMixin:SetByID(affixID)
    self.affixID = affixID;
    if affixID then
        local name, description, icon = C_ChallengeMode.GetAffixInfo(affixID);
        self.Icon:SetTexture(icon);
        if self:IsMouseOver() then
            self:OnEnter();
        else
            self:OnLeave();
        end
        self:Show();
    else
        self:Hide();
    end
end


NarciMythicPlusRatingCardMixin = {};

function NarciMythicPlusRatingCardMixin:LoadMap(mapID)
    if mapID ~= self.mapID and MAP_UI_INFO[mapID] then
        self.MapTexture:SetTexture( DataProvider:GetMapTexture(mapID) );
    end
end

function NarciMythicPlusRatingCardMixin:SetMapName(name)
    self.MapName:SetText(name);
    if self.MapName:IsTruncated() then
        self.MapName:SetFontObject("NarciFontNormal9");
    end
end

function NarciMythicPlusRatingCardMixin:SetUpByMapID(mapID)
    self.mapID = mapID;
    local mapName = DataProvider:GetMapName(mapID);
    self:SetMapName(mapName);
    local score, level, duration, isOvertime = DataProvider:GetSesaonBestScoreLevelTime(mapID);

    if score and level and duration then
        local v = isOvertime and 0.6 or 0.92;
        self.Level1:SetText(level);
        self.Level1:SetTextColor(v, v, v, 0.9);
        self.Level1:Show();
        self.Duration1:SetText(FormatDuration(duration));
        self.Duration1:SetTextColor(v, v, v, 1);
        self.Duration1:Show();

        local scoreColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(score);
        if (not scoreColor) then
            scoreColor = HIGHLIGHT_FONT_COLOR;
        end
        self.Score:SetText(score);
        self.Score:SetTextColor(scoreColor.r, scoreColor.g, scoreColor.b);
        self.Score:Show();
        self.ScoreBound:Show();
        self.MapTexture:SetDesaturation(0);
        self.MapTexture:SetVertexColor(1, 1, 1);
        self.Header:SetDesaturation(0);
        self.GreyBackground:Hide();
        self.NoRecordLabel:Hide();
        self:Enable();
        DataProvider:SetMapComplete(mapID);
    else
        self:SetEmpty();
    end
end

function NarciMythicPlusRatingCardMixin:SetEmpty()
    self.Score:Hide();
    self.ScoreBound:Hide();
    self.Level1:Hide();
    self.Duration1:Hide();
    self.Level2:Hide();
    self.Duration2:Hide();

    if not HIDE_MYTHIC_TAB_ON_LOW_LEVELS then
        DataProvider:SetMapComplete(self.mapID);
        return
    end

    self.MapTexture:SetDesaturation(1);
    self.MapTexture:SetVertexColor(0.6, 0.6, 0.6);
    self.Header:SetDesaturation(1);
    self.GreyBackground:Show();
    self.NoRecordLabel:Show();
    self:Disable();
end

function NarciMythicPlusRatingCardMixin:SetRecord(mapScore, level, duration, overTime)
    local v;
    if overTime then
        v = 0.5;
    else
        v = 0.92;
    end
    self.Level1:SetText(level);
    self.Level1:SetTextColor(v, v, v, 0.9);
    self.Level1:Show();
    self.Duration1:SetText( FormatDuration(duration) );
    self.Duration1:SetTextColor(v, v, v);
    self.Duration1:Show();

    local scoreColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(mapScore);
    if (not scoreColor) then
        scoreColor = HIGHLIGHT_FONT_COLOR;
    end
    self.Score:SetText(mapScore);
    self.Score:SetTextColor(scoreColor.r, scoreColor.g, scoreColor.b);
    self.Score:Show();

    self.ScoreBound:Show();
    self.MapTexture:SetDesaturation(0);
    self.MapTexture:SetVertexColor(1, 1, 1);
    self.Header:SetDesaturation(0);
    self.Level2:Hide();
    self.Duration2:Hide();
    self.GreyBackground:Hide();
    self.NoRecordLabel:Hide();
    self:Enable();
end

function NarciMythicPlusRatingCardMixin:OnEnter()
    self.BlackOverlay:Hide();
end

function NarciMythicPlusRatingCardMixin:OnLeave()
    self.BlackOverlay:Show();
end

function NarciMythicPlusRatingCardMixin:OnClick()
    MainFrame:SetMapDetail(self.mapID);
    MainFrame:ToggleMapDetail(true);
end


local function MapDetail_OnMouseWheel(self, delta)
    if not DataProvider.numCompleteMaps then return end;

    if delta > 0 then
        if self.page > 1 then
            self.page = self.page - 1;
        else
            return
        end
    elseif delta < 0 then
        if self.page < DataProvider.numCompleteMaps then
            self.page = self.page + 1;
        else
            return
        end
    end
    self.LeftArrow:SetShown(self.page ~= 1);
    self.RightArrow:SetShown(self.page ~= DataProvider.numCompleteMaps);
    local mapID = DataProvider:GetMapIDByOrder(self.page);
    if mapID then
        MainFrame:SetMapDetail(mapID);
    end
end

local dyamicEvents = {"CHALLENGE_MODE_MAPS_UPDATE", "CHALLENGE_MODE_MEMBER_INFO_UPDATED", "CHALLENGE_MODE_LEADERS_UPDATE"};

NarciMythicPlusDisplayMixin = {};

function NarciMythicPlusDisplayMixin:OnLoad()
    MainFrame = self;
    self.t = 0;
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED");
    self.requireUpdate = true;
    self.requireNewHistory = true;
    self.MapDetail.Header:SetVertexColor(0.5, 0.5, 0.5);

    local height = CARD_FULL_HEIGHT + 24;
    self:SetHeight(height);
    self.MapDetail:SetHeight(height);
    self:GetParent():SetHeight(height);

    self.Cards = {};
end

function NarciMythicPlusDisplayMixin:OnEvent(event)
    if event == "CHALLENGE_MODE_COMPLETED" then
        self.requireUpdate = true;
        self.requireNewHistory = true;
    elseif event == "CHALLENGE_MODE_LEADERS_UPDATE" then
        if not self.pauseUpdate then
            self.pauseUpdate = true;
            After(0.5, function()
                self:PostUpdate();
                self.pauseUpdate = nil;
            end);
        end
    elseif event == "CHALLENGE_MODE_MEMBER_INFO_UPDATED" then
        self.memberInfoReady = true;
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        if UnitLevel("player") ~= GetMaxLevelForPlayerExpansion() and HIDE_MYTHIC_TAB_ON_LOW_LEVELS then
            Narci_NavBar:HideMythicPlusButton();
        end
    end
end

function NarciMythicPlusDisplayMixin:OnShow()
    for _, event in pairs(dyamicEvents) do
        self:RegisterEvent(event);
    end
    if self.requireUpdate then
        self:RequestUpdate();
    end
end

function NarciMythicPlusDisplayMixin:OnHide()
    for _, event in pairs(dyamicEvents) do
        self:UnregisterEvent(event);
    end
    self:SetScript("OnUpdate", nil);
end

function NarciMythicPlusDisplayMixin:Init()
    DataProvider:Init();

    local OFFSET_Y= -24;

    if not self.maps then
        --Check if the current season maps match the data since last update
        local mapsThisSeason = C_ChallengeMode.GetMapTable();
        local isNewSeason;

        if mapsThisSeason and #mapsThisSeason > 0 then
            local presetMaps = {};

            for _, mapID in ipairs(SEASON_MAPS) do
                presetMaps[mapID] = true;
            end

            for _, mapID in ipairs(mapsThisSeason) do
                if not presetMaps[mapID] then
                    isNewSeason = true;
                    break
                end
            end

            presetMaps = nil;
        end

        if isNewSeason then
            self.maps = mapsThisSeason;
        else
            self.maps = SEASON_MAPS;
        end

        for _, mapID in ipairs(self.maps) do
            IS_MAP_THIS_SEASON[mapID] = true;
        end
    end

    local numRows = math.ceil(#self.maps * 0.5);

    self.Map2Cards = {};

    local numMaps = #self.maps;
    local card;
    local row, col = 0, 0;
    local container = self.CardContainer;
    local footerHeight = 0; --24
    local cardHeight = (CARD_FULL_HEIGHT - footerHeight) / numRows;
    for i = 1, numMaps do
        card = self.Cards[i];
        if not card then
            card = CreateFrame("Button", nil, container, "NarciMythicPlusCompactRatingCardTemplate");
            self.Cards[i] = card;
            card:SetPoint("TOPLEFT", container, "TOPLEFT", col * 160, -row * cardHeight + OFFSET_Y);
            card:SetHeight(cardHeight);
            col = col + 1;
            if col >= 2 then
                row = row + 1;
                col = 0;
            end
        end
        card:LoadMap(self.maps[i]);
        self.Map2Cards[self.maps[i]] = card;
    end

    if numMaps == 0 then
        numMaps = 1;
    end


    --Map Detail Frame
    self.MapDetail:SetScript("OnMouseDown", SharedOnMouseDown);
    self.MapDetail:SetScript("OnMouseWheel", MapDetail_OnMouseWheel);
    self.MapDetail:SetHitRectInsets(0, 0, 0, -20);

    for i = 3, 0, -1 do
        local f = CreateFrame("Frame", nil, self.MapDetail, "NarciMythicPlusAffixFrameTemplate");
        f:SetPoint("TOPRIGHT", self.MapDetail.ContentBackdrop, "TOPRIGHT", -24 - i * 32, -74);
    end
    self.MapDetail.Pointer:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Competitive\\MythicPlus\\TimerlinePointer", nil, nil, "TRILINEAR");

    --Create Primary Tab Buttons
    local tabNames = {
        MYTHIC_PLUS_SEASON_BEST, L["Runs"],
    };
    self.TabButtons = {};
    for i = 1, #tabNames do
        local button = CreateFrame("Button", nil, self, "NarciNavBarTabButtonTemplate");
        self.TabButtons[i] = button;
        if i == 1 then
            button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
            button:SetSelect(true);
        else
        button:SetPoint("LEFT", self.TabButtons[i - 1], "RIGHT", 0, 0);
        end
        button.maxWidth = 100;
        button.Highlight:SetVertexColor(0.5, 0.5, 0.5);
        button:SetUp(tabNames[i], i);
        button.tabFrame = self;
    end

    local grey80 =  "|TInterface\\AddOns\\Narcissus\\Art\\Modules\\Competitive\\MythicPlus\\BarBlock32:10:10:-4:0:32:32:0:32:0:32:204:204:204|t";
    local grey50 =  "|TInterface\\AddOns\\Narcissus\\Art\\Modules\\Competitive\\MythicPlus\\BarBlock32:10:10:-4:0:32:32:0:32:0:32:128:128:128|t";
    self.HistoryFrame.GraphDescription:SetText(grey80..L["Complete In Time"].."    "..grey50..L["Complete Over Time"]);

    self.Init = nil;
end

function NarciMythicPlusDisplayMixin:SelectTab(tabIndex)
    if tabIndex ~= self.tabIndex then
        self.tabIndex = tabIndex;
    else
        return
    end
    for i, button in pairs(self.TabButtons) do
        button:SetSelect(tabIndex == i);
    end
    if tabIndex == 1 then
        self.CardContainer:Show();
        self.MapDetail:Hide();
        self.HistoryFrame:Hide();
    else
        self:ToggleHistory(true);
    end
end

function NarciMythicPlusDisplayMixin:RequestUpdate()
    if self.Init then
        self:Init();
    end

    self:GetParent():ShowLoading();

    local numMaps = #self.maps;
    local mapID;

    for i = 1, numMaps do
        mapID = self.maps[i];
        C_ChallengeMode.RequestLeaders(mapID);
    end

    DataProvider.mapIDs = {};
    DataProvider:ClearRecords();
    C_MythicPlus.RequestMapInfo();
    C_MythicPlus.RequestCurrentAffixes();
end

function NarciMythicPlusDisplayMixin:PostUpdate()
    local card;
    for i = 1, #self.maps do
        card = self.Cards[i];
        card:SetUpByMapID(self.maps[i]);
    end
    self.requireUpdate = false;

    local seasonID = (C_MythicPlus.GetCurrentSeason() or 6) - 4;
    --self.SeasonText:SetText(string.format(SL_SEASON_NUMBER, seasonID));
    --self.CardContainer.GraphDescription:SetText(string.format("%s    %s    %s", PVP_RATING_HEADER or "Rating", AFFIX_TYRANNICAL, AFFIX_FORTIFIED));  --MYTHIC_PLUS_SEASON_BEST

    local overallScore = C_ChallengeMode.GetOverallDungeonScore();
	local color = C_ChallengeMode.GetDungeonScoreRarityColor(overallScore);
	if (color) then
        overallScore = color:WrapTextInColorCode(overallScore);
    end
    local text = overallScore;
    local currentSeasonOnly = true;
    local runHistory = C_MythicPlus.GetRunHistory(true, true, currentSeasonOnly);
    if runHistory then
        local total = 0;

        for i, info in ipairs(runHistory) do
            if info.mapChallengeModeID and IS_MAP_THIS_SEASON[info.mapChallengeModeID] then
                --Only count the ones that are in the current map pool
                total = total + 1;
            end
        end

        if total > 0 then
            text = text.."     ".. Narci.L["Total Runs"] .."|cffffffff"..total.."|r";
        end
    end


    local nav = Narci_NavBar;
    nav.ChallengeFrame.DataText:SetText(string.format(DUNGEON_SCORE_LEADER, text));
    local ownedMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID();
    local mapIcon;
    OwnedKeystoneFrame.mapID = ownedMapID;
    if ownedMapID then
        --known issue: talking with keystone trader doesn't trigger updates.
        mapIcon = DataProvider:GetMapIcon(ownedMapID);
        local level = C_MythicPlus.GetOwnedKeystoneLevel();
        OwnedKeystoneFrame:Show();
        if level then
            OwnedKeystoneFrame:SetLevel(level);
        end
    else
        OwnedKeystoneFrame:Hide();
    end
    nav.keystoneIcon = mapIcon;
    if mapIcon then
        nav:SetPortraitTexture(mapIcon, false, true);
    end

    self:GetParent():HideLoading();
end

function NarciMythicPlusDisplayMixin:SetUnit(unit)
    unit = unit or "target";
    if not UnitExists(unit) then return end;

    if self.Init then
        self:Init();
    end
    local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit);
    local card;
    local mapID, mapName;
    local mapHasData = {};
    if summary and type(summary) == "table" then
        local runs = summary.runs;
        local currentSeasonScore = summary.currentSeasonScore;
        local mapData = {};
        if runs and #runs > 0 then
            local level, duration, mapScore, overTime;
            for _, run in pairs(runs) do
                mapID = run.challengeModeID;
                mapScore = run.mapScore;
                level = run.bestRunLevel;
                duration = math.ceil(run.bestRunDurationMS / 1000);
                overTime = not run.finishedSuccess;
                mapHasData[mapID] = true;
                card = self.Map2Cards[mapID];
                if card then
                    card:SetRecord(mapScore, level, duration, overTime);
                    mapName = DataProvider:GetMapName(mapID);
                    card:SetMapName(mapName);
                end
            end
        end
        for i = 1, #self.maps do
            mapID = self.maps[i];
            if not mapHasData[mapID] then
                card = self.Map2Cards[mapID];
                if card then
                    card:SetEmpty();
                    mapName = DataProvider:GetMapName(mapID);
                    card:SetMapName(mapName);
                end
            end
        end
    end
end

function NarciMythicPlusDisplayMixin:ToggleMapDetail(state)
    self.MapDetail:SetShown(state);
    self.CardContainer:SetShown(not state);
    self.HistoryFrame:Hide();
    if state then
        if not self.MapDetail.MouseButton then
            --Create a note that informs user you can right click to go back to the main frame.
            local f = CreateFrame("Frame", nil, self.MapDetail, "NarciHotkeyNotificationTemplate");
            self.MapDetail.MouseButton = f;
            f:SetKey(nil, "RightButton", L["Return"], true);
            f:SetPoint("TOPRIGHT", self.MapDetail, "BOTTOMRIGHT", -6, -4);
            f:SetIgnoreParentScale(true);
        end
    end
end

function NarciMythicPlusDisplayMixin:ToggleHistory(state)
    local f = self.HistoryFrame;
    f:SetShown(state);
    self.CardContainer:SetShown(not state);
    self.MapDetail:Hide();
    if self.requireNewHistory then
        self.requireNewHistory = false;
    else
        return
    end
    if state then
        local currentSeasonOnly = true;
        local runHistory = C_MythicPlus.GetRunHistory(true, true, currentSeasonOnly);
        local numRuns = #runHistory;
        if numRuns > 0 then
            if not f.bars then
                f.bars = {};
                local frameHeight = f:GetHeight() - 36;
                local numMaps = #self.maps;
                local offsetY = frameHeight / numMaps;
                local bar;
                for i = 1, #self.maps do
                    bar = CreateFrame("Frame", nil, f, "NarciMythicPlusHistogrameTemplate");
                    bar:SetPoint("TOP", f, "TOP", 0, -12 + (1 - i) * offsetY);
                    f.bars[i] = bar;
                end
            end
            local mapID;
            local mapData = {};
            for i = 1, #self.maps do
                mapID = self.maps[i];
                mapData[mapID] = {intime = 0, overtime = 0};
            end
            
            for i = 1, numRuns do
                mapID = runHistory[i].mapChallengeModeID;
                if mapData[mapID] then
                    if runHistory[i].completed then
                        mapData[mapID].intime = mapData[mapID].intime + 1;
                    else
                        mapData[mapID].overtime = mapData[mapID].overtime + 1;
                    end
                end
            end
            local maxRun = 0;
            local sum;
            for _, data in pairs(mapData) do
                sum = data.intime + data.overtime;
                if sum > maxRun then
                    maxRun = sum;
                end
            end
            local normalizedRun;
            if numRuns > 100 then
                normalizedRun = maxRun;
            elseif numRuns < 20 then
                normalizedRun = maxRun / 0.5;
            else
                normalizedRun = maxRun / (0.5 + (numRuns - 20)/160);
            end
            for i = 1, #self.maps do
                mapID = self.maps[i];
                f.bars[i]:SetData(mapID, mapData[mapID].intime, mapData[mapID].overtime, normalizedRun);
            end
            f.NoRecordLabel:Hide();
            f.GraphDescription:Show();
        else
            f.NoRecordLabel:Show();
            f.GraphDescription:Hide();
        end
    end
end

local function UpdateTimelinePointer(timeLimit, yourTime)
    local p = MainFrame.MapDetail.Pointer;
    local centeralTime = timeLimit * 0.8;
    local offsetXPerSec = 64 / (timeLimit * 0.2);
    --local maxOffset = 260;
    local offsetX = math.floor((yourTime - centeralTime) * offsetXPerSec);
    if offsetX > 130 then
        offsetX = 130
    elseif offsetX < -130 then
        offsetX = -130;
    end
    p:ClearAllPoints();
    p:SetPoint("TOP", MainFrame.MapDetail.Timeline, "BOTTOM", offsetX, 0);
    if timeLimit < yourTime then
        p:SetVertexColor(NarciAPI.GetColorPresetRGB("red"));
    else
        p:SetVertexColor(NarciAPI.GetColorPresetRGB("green"));
    end
end

local function MemberInfoCallBack_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.5 then
        self:SetScript("OnUpdate", nil);
        self:UpdateMemberInfo();
    end
end

function NarciMythicPlusDisplayMixin:RequestMemberInfo()
    self.t = 0;
    self:SetScript("OnUpdate", MemberInfoCallBack_OnUpdate);
end

function NarciMythicPlusDisplayMixin:UpdateMemberInfo()
    if self.activeMapID then
        local intimeInfo, overtimeInfo, isCached = DataProvider:GetSeasonBestForMap(self.activeMapID);
        local data = intimeInfo;
        if not data then
            return
        end
        local memberString = "";
        for j = 1, #data.members do
            memberString = memberString..WrapNameWithClassColor(data.members[j].name, data.members[j].classID, data.members[j].specID, true, -7).."   ";
        end
        SmartSetName(self.MapDetail.MemberText, memberString);
    end
end

function NarciMythicPlusDisplayMixin:SetMapDetail(mapID, useIntimeOrOvertime)
    if not mapID then return end;
    self.activeMapID = mapID;

    local f = self.MapDetail;
    f.page = DataProvider:GetPageByMapID(mapID);

    f.LeftArrow:SetShown(f.page ~= 1);
    f.RightArrow:SetShown(f.page ~= DataProvider.numCompleteMaps);

    f.Header:SetTexture(DataProvider:GetMapTexture(mapID, true));
    f.MapName:SetText( DataProvider:GetMapName(mapID) );

    local intimeInfo, overtimeInfo, isCached = DataProvider:GetSeasonBestForMap(mapID);
    local data;

    --If time isn't specified, find the one that has data starting from intime data
    local fromI, toI;
    if useIntimeOrOvertime == nil then
        fromI = 1;
        toI = 2;
    else
        if useIntimeOrOvertime then
            fromI = 1;
            toI = 1;
        else
            fromI = 2;
            toI = 2;
        end
    end

    local hasData = false;
    for i = fromI, toI do
        if i == 1 then
            data = intimeInfo;
        else
            data = overtimeInfo;
        end
        if data then
            hasData = true;
            UpdateTabButtonVisual(i);
            local durationSec = data.durationSec;
            f.Duration:SetText( FormatDuration(durationSec) );
            f.Duration:SetTextColor(1, 1, 1);
            f.Level:SetText( data.level );
            f.Level:SetTextColor(1, 1, 1);
            f.Date:SetText( FormatShortDate(data.completionDate.day, (data.completionDate.month or 0) + 1, data.completionDate.year) ); --month starts from zero why?
            f.Score:SetText( data.dungeonScore );
            local color = C_ChallengeMode.GetSpecificDungeonScoreRarityColor(data.dungeonScore);
            if (not color) then
                color = HIGHLIGHT_FONT_COLOR;
            end
            f.Score:SetTextColor(color.r, color.g, color.b);

            --Time
            local timeLimit = DataProvider:GetMapTimer(mapID);
            if timeLimit then
                local plus3 = timeLimit * 0.6;
                local plus2 = timeLimit * 0.8;
                if durationSec < plus3 then
                    f.Area3:SetTextColor(1, 1, 1);
                    f.Area2:SetTextColor(0.5, 0.5, 0.5);
                    f.Area1:SetTextColor(0.5, 0.5, 0.5);
                    f.Area0:SetTextColor(0.5, 0.5, 0.5);
                elseif durationSec < plus2 then
                    f.Area2:SetTextColor(1, 1, 1);
                    f.Area3:SetTextColor(0.5, 0.5, 0.5);
                    f.Area1:SetTextColor(0.5, 0.5, 0.5);
                    f.Area0:SetTextColor(0.5, 0.5, 0.5);
                elseif durationSec < timeLimit then
                    f.Area1:SetTextColor(1, 1, 1);
                    f.Area2:SetTextColor(0.5, 0.5, 0.5);
                    f.Area3:SetTextColor(0.5, 0.5, 0.5);
                    f.Area0:SetTextColor(0.5, 0.5, 0.5);
                else
                    f.Area0:SetTextColor(1, 1, 1);
                    f.Area2:SetTextColor(0.5, 0.5, 0.5);
                    f.Area1:SetTextColor(0.5, 0.5, 0.5);
                    f.Area3:SetTextColor(0.5, 0.5, 0.5);
                end

                f.Timer1:SetText( FormatDuration(timeLimit) );
                f.Timer2:SetText( FormatDuration(plus2) );
                f.Timer3:SetText( FormatDuration(plus3) );

                --Timeline Pointer
                UpdateTimelinePointer(timeLimit, durationSec);
                f.Pointer:Show();
            else
                f.Pointer:Hide();
            end

            --Affix Frames
            for j = 1, 4 do
               f.AffixFrames[j]:SetByID(data.affixIDs[j]);
            end

            --Members
            local memberString = "";
            for j = 1, #data.members do
                memberString = memberString..WrapNameWithClassColor(data.members[j].name, data.members[j].classID, data.members[j].specID, true, -7).."   ";
            end
            SmartSetName(f.MemberText, memberString);
            if not isCached then
                self:RequestMemberInfo();
            end
            break;
        end
    end

    if not hasData then
        f.Score:SetText("--");
        f.Score:SetTextColor(0.5, 0.5, 0.5);
        f.Date:SetText("No Date");
        f.Duration:SetText("00:00");
        f.Duration:SetTextColor(0.5, 0.5, 0.5);
        f.Level:SetText("--");
        f.Level:SetTextColor(0.5, 0.5, 0.5);
        for j = 1, 4 do
            f.AffixFrames[j]:SetByID(nil);
        end
        f.MemberText:SetText("");
        f.Timer1:SetText("");
        f.Timer2:SetText("");
        f.Timer3:SetText("");
        f.Area0:SetTextColor(0.5, 0.5, 0.5);
        f.Area2:SetTextColor(0.5, 0.5, 0.5);
        f.Area1:SetTextColor(0.5, 0.5, 0.5);
        f.Area3:SetTextColor(0.5, 0.5, 0.5);
        f.Pointer:Hide();
    end
end

function NarciMythicPlusDisplayMixin:SetMapDetailInfoType(useIntimeOrOvertime)
    self:SetMapDetail(self.activeMapID, useIntimeOrOvertime);
end

NarciMythicPlusPageButtonMixin = {};

function NarciMythicPlusPageButtonMixin:OnLoad()
    self.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Competitive\\MythicPlus\\ArrowRight", nil, nil, "LINEAR");
    if self.increment == 1 then
        self.Icon:SetTexCoord(1, 0, 0, 1);
    end
    self:OnLeave();

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciMythicPlusPageButtonMixin:OnEnter()
    self:SetAlpha(1);
end

function NarciMythicPlusPageButtonMixin:OnLeave()
    self:SetAlpha(0.5);
end

function NarciMythicPlusPageButtonMixin:OnMouseDown()
    self.Icon:SetPoint("CENTER", 0, -1);
end

function NarciMythicPlusPageButtonMixin:OnMouseUp()
    self.Icon:SetPoint("CENTER", 0, 0);
end

function NarciMythicPlusPageButtonMixin:OnClick()
    MapDetail_OnMouseWheel(MainFrame.MapDetail, self.increment);
end




NarciMythicPlusHistogrameMixin = {};

function NarciMythicPlusHistogrameMixin:SetData(mapID, intimeRun, overtimeRun, normalizedRun)
    intimeRun = intimeRun or 0;
    overtimeRun = overtimeRun or 0;
    local sum = normalizedRun--(intimeRun + overtimeRun);
    self.MapName:SetText(DataProvider:GetMapName(mapID));
    local r, g, b;
    if MAP_UI_INFO[mapID] and MAP_UI_INFO[mapID].barColor then
        r, g, b = unpack(ConvertHexColorToRGB(MAP_UI_INFO[mapID].barColor));
    else
        r, g, b = 0.8, 0.8, 0.8;
    end
    self.MapName:SetTextColor(r, g, b);
    if intimeRun == 0 and overtimeRun == 0 then
        self.Bar1:Hide();
        self.Bar2:Hide();
        self.Count:Hide();
        self.MapName:SetTextColor(0.5, 0.5, 0.5);
        return
    end
    self.Count:Show();
    self.Count:SetText( (intimeRun + overtimeRun) );
    local maxWidth = 180 - 12;
    if intimeRun > 0 then
        local bar1Width = math.floor(maxWidth * intimeRun/sum + 0.5);
        self.Bar1:SetWidth(bar1Width);
        self.Bar1:Show();
        self.Bar1:SetVertexColor(0.8, 0.8, 0.8);
        self.Bar1:SetTexCoord(0, bar1Width/maxWidth, 0, 1);
        if overtimeRun > 0 then
            local bar2Width = math.floor(maxWidth * overtimeRun/sum + 0.5);
            self.Bar2:SetWidth(bar2Width);
            self.Bar2:Show();
            self.Bar2:SetVertexColor(0.5, 0.5, 0.5);
            self.Bar1:SetTexCoord(bar1Width/maxWidth, bar2Width/maxWidth, 0, 1);
        else
            self.Bar2:Hide();
            self.Bar2:SetWidth(0.1);
        end
        self.Text1:SetText(intimeRun);
        self.Text2:SetText((overtimeRun > 0 and overtimeRun) or "");
    else
        local bar1Width = math.floor(maxWidth * overtimeRun/sum + 0.5);
        self.Bar1:SetWidth(bar1Width);
        self.Bar1:Show();
        self.Bar1:SetVertexColor(0.5, 0.5, 0.5);
        self.Bar1:SetTexCoord(0, bar1Width/maxWidth, 0, 1);
        self.Bar2:Hide();
        self.Bar2:SetWidth(0.1);
        self.Text1:SetText(overtimeRun);
        self.Text2:SetText("");
    end
end

function NarciMythicPlusHistogrameMixin:OnEnter()
    self.Text1:Show();
    self.Text2:Show();
end

function NarciMythicPlusHistogrameMixin:OnLeave()
    self.Text1:Hide();
    self.Text2:Hide();
end


NarciOwnedKeystoneFrameMixin = {};

function NarciOwnedKeystoneFrameMixin:OnLoad()
    OwnedKeystoneFrame = self;
    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end
function NarciOwnedKeystoneFrameMixin:OnEnter()
    if self.level and self.mapID then
        local tooltip = NarciGameTooltip;
        tooltip:Hide();
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetText(DataProvider:GetMapName(self.mapID));
        local affixes = DataProvider:GetWeeklyAffixesForLevel(self.level);
        local name;
        for i = 1, #affixes do
            name = C_ChallengeMode.GetAffixInfo(affixes[i]);
            if name and name ~= "" then
                tooltip:AddLine(name, 1 ,1 ,1 ,true);
            else
                After(0.2, function ()
                    self:Retry();
                end)
                return
            end
        end
        tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -4, -2);
        tooltip:Show();
    end
end

function NarciOwnedKeystoneFrameMixin:OnLeave()
    NarciGameTooltip:Hide();
end

function NarciOwnedKeystoneFrameMixin:Retry()
    if self:IsVisible() and self:IsMouseOver() then
        self:OnEnter();
    end
end

function NarciOwnedKeystoneFrameMixin:SetLevel(level)
    self.level = level;
    self.Level:SetText("|cffffffff+"..level.."|r");
end


do  --Debug Override
    --[[
    function DataProvider:GetSesaonBestScoreLevelTime(mapID)
        return 300, 10, 1500, false
    end
    --]]
end