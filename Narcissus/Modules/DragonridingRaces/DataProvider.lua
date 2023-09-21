local _, addon = ...

local DataProvider = {};
addon.DragonridingRaceDataProvider = DataProvider;

local time = time;

--Bronze Timekeeper vignetteID 5104

local TourPOI = {
    --auto-generated
	[7494] = {--Fel Flyover
		["mapID"] = 77,
		["cy"] = 0.2245392054319382,
		["cx"] = 0.510776698589325,
		["id"] = 7494,
		["continent"] = 12,
	},
	[7495] = {--Winter Wander
		["mapID"] = 83,
		["cy"] = 0.2570351362228394,
		["cx"] = 0.6057320833206177,
		["id"] = 7495,
		["continent"] = 12,
	},
	[7496] = {--Nordrassil Spiral
		["mapID"] = 198,
		["cy"] = 0.2814698219299316,
		["cx"] = 0.5544447898864746,
		["id"] = 7496,
		["continent"] = 12,
	},
	[7497] = {--Hyjal Hotfoot
		["mapID"] = 198,
		["cy"] = 0.3118551373481751,
		["cx"] = 0.5143584609031677,
		["id"] = 7497,
		["continent"] = 12,
	},
	[7498] = {--Rocketway Ride
		["mapID"] = 76,
		["cy"] = 0.3216145634651184,
		["cx"] = 0.6561214923858643,
		["id"] = 7498,
		["continent"] = 12,
	},
	[7499] = {--Ashenvale Ambit
		["mapID"] = 63,
		["cy"] = 0.3591360449790955,
		["cx"] = 0.4756047129631043,
		["id"] = 7499,
		["continent"] = 12,
	},
	[7500] = {--Durotar Tour
		["mapID"] = 1,
		["cy"] = 0.5183326601982117,
		["cx"] = 0.5988578796386719,
		["id"] = 7500,
		["continent"] = 12,
	},
	[7501] = {--Webwinder Weave
		["mapID"] = 65,
		["cy"] = 0.5021476745605469,
		["cx"] = 0.4647814035415649,
		["id"] = 7501,
		["continent"] = 12,
	},
	[7502] = {--Desolate Drift
		["mapID"] = 66,
		["cy"] = 0.5606335997581482,
		["cx"] = 0.3830517530441284,
		["id"] = 7502,
		["continent"] = 12,
	},
	[7503] = {--Barrens Divier Dive
		["mapID"] = 199,
		["cy"] = 0.5196206569671631,
		["cx"] = 0.5103986859321594,
		["id"] = 7503,
		["continent"] = 12,
	},
	[7504] = {--Razorfen Roundabout
		["mapID"] = 199,
		["cy"] = 0.6808913946151733,
		["cx"] = 0.5131373405456543,
		["id"] = 7504,
		["continent"] = 12,
	},
	[7505] = {--Thousand Needles Thread
		["mapID"] = 64,
		["cy"] = 0.6841453909873962,
		["cx"] = 0.4871701896190643,
		["id"] = 7505,
		["continent"] = 12,
	},
	[7506] = {--Ferlas Ruins Ramble
		["mapID"] = 69,
		["cy"] = 0.7008814811706543,
		["cx"] = 0.4369997978210449,
		["id"] = 7506,
		["continent"] = 12,
	},
	[7507] = {--Ahn'Qiraj Circuit
		["mapID"] = 81,
		["cy"] = 0.8339823484420776,
		["cx"] = 0.4262949824333191,
		["id"] = 7507,
		["continent"] = 12,
	},
	[7508] = {--Uldum Tour  --Zidormi (mapID 1527 is wrong timeline)
		["mapID"] = 249,
		["cy"] = 0.9000136852264404,
		["cx"] = 0.4912934303283691,
		["id"] = 7508,
		["continent"] = 12,
	},

	[7509] = {--Un'Goro Crater Circuit
		["mapID"] = 78,
		["cy"] = 0.8385398387908936,
		["cx"] = 0.5029329061508179,
		["id"] = 7509,
		["continent"] = 12,
	},
};

local RecordData = {
    [7494] = {
        goldTime = {70, 63, 62},
        recordCurrency = {2312, 2342, 2372},
    },

    [7495] = {
        goldTime = {76, 73, 70},
        recordCurrency = {2313, 2343, 2373},
    },

    [7496] = {
        goldTime = {45, 41, 41},
        recordCurrency = {2314, 2344, 2374},
    },

    [7497] = {
        goldTime = {70, 69, 67},
        recordCurrency = {2315, 2345, 2375},
    },

    [7498] = {
        goldTime = {100, 94, 94},
        recordCurrency = {2316, 2346, 2376},
    },

    [7499] = {
        goldTime = {64, 59, 59},
        recordCurrency = {2317, 2347, 2377},
    },

    [7500] = {
        goldTime = {80, 73, 73},
        recordCurrency = {2318, 2348, 2378},
    },

    [7501] = {
        goldTime = {80, 70, 70},
        recordCurrency = {2319, 2349, 2379},
    },

    [7502] = {
        goldTime = {75, 70, 70},
        recordCurrency = {2320, 2350, 2380},
    },

    [7503] = {
        goldTime = {48, 43, 44},
        recordCurrency = {2321, 2351, 2381},
    },

    [7504] = {
        goldTime = {53, 47, 47},
        recordCurrency = {2322, 2352, 2382},
    },

    [7505] = {
        goldTime = {83, 76, 76},
        recordCurrency = {2323, 2353, 2383},
    },

    [7506] = {
        goldTime = {89, 83, 83},
        recordCurrency = {2324, 2354, 2384},
    },

    [7507] = {
        goldTime = {75, 66, 69},
        recordCurrency = {2325, 2355, 2385},
    },

    [7508] = {
        goldTime = {84, 76, 76},
        recordCurrency = {2326, 2356, 2386},
    },

    [7509] = {
        goldTime = {100, 87, 91},
        recordCurrency = {2327, 2357, 2387},
    },
};

DataProvider.TourPOI = TourPOI;

local WidgetVisibleMaps = {};
do
    for poiID, info in pairs(TourPOI) do
        WidgetVisibleMaps[ info.mapID ] = true;
        WidgetVisibleMaps[ info.continent ] = true;
    end
end

function DataProvider:ShouldShowWorldMapWidget(uiMapID)
    return (uiMapID and WidgetVisibleMaps[uiMapID])
end

function DataProvider:GetPOIContinentPosition(poiID)
    return TourPOI[poiID].cx, TourPOI[poiID].cy
end

function DataProvider:GetPOIMapPosition(poiID)
    if not TourPOI[poiID].mx then
        local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(TourPOI[poiID].mapID, poiID);
        if poiInfo then
            TourPOI[poiID].mx, TourPOI[poiID].my = poiInfo.position:GetXY();
        end
    end

    return TourPOI[poiID].mx, TourPOI[poiID].my
end

function DataProvider:GetPOIWaypoint(poiID)
    local point = {};
    local mapID = TourPOI[poiID].mapID;
    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID);

    if poiInfo then
        point.uiMapID = mapID;
        point.position = poiInfo.position:Clone();
    end

    return point
end

function DataProvider:GetPOIName(poiID)
    if not self.poiNames then
        self.poiNames = {};
    end

    if not self.poiNames[poiID] then
        local uiMapID = TourPOI[poiID]["mapID"];
        local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, poiID);  --Local DBC
        if poiInfo then
            self.poiNames[poiID] = poiInfo.name;
        end
    end

    return self.poiNames[poiID]
end

function DataProvider:GetMapName(uiMapID)
    if not self.mapNames then
        self.mapNames = {};
    end

    if not self.mapNames[uiMapID] then
        local info = C_Map.GetMapInfo(uiMapID);
        if info then
            self.mapNames[uiMapID] = info.name;
        end
    end

    return self.mapNames[uiMapID]
end

function DataProvider:GetPOIsForContinent(continentMapID)
    if not self.continentPOIs then
        self.continentPOIs = {};
    end

    if not self.continentPOIs[continentMapID] then
        local tbl = {};
        for poiID, info in pairs(TourPOI) do
            if info["continent"] == continentMapID then
                table.insert(tbl, poiID);
            end
        end

        table.sort(tbl);
        self.continentPOIs[continentMapID] = tbl;
    end

    return self.continentPOIs[continentMapID]
end

function DataProvider:UpdateRecordTime(poiID)
    if not RecordData[poiID].recordTime then
        RecordData[poiID].recordTime = {};
    end

    local info, recordTime;
    local isGold = true;

    for i, currencyID in ipairs(RecordData[poiID].recordCurrency) do
        info = C_CurrencyInfo.GetCurrencyInfo(currencyID);
        if info and info.quantity then
            recordTime = info.quantity * 0.001;
            RecordData[poiID].recordTime[i] = recordTime;

            if recordTime == 0 then
                isGold = false;
            end

            if isGold then
                isGold = recordTime <= RecordData[poiID].goldTime[i];
            end
        end
    end

    RecordData[poiID].isGold = isGold;
end

function DataProvider:UpdateAllRecords()
    for poiID in pairs(RecordData) do
        self:UpdateRecordTime(poiID);
    end
end

function DataProvider:GetAndCacheRecord(poiID, courseTypeID)
    if RecordData[poiID] then
        if not RecordData[poiID].recordTime then
            self:UpdateRecordTime(poiID);
        end

        return RecordData[poiID].recordTime[courseTypeID], RecordData[poiID].goldTime[courseTypeID]
    end
end

function DataProvider:IsCourseGold(poiID)
    if not RecordData[poiID].recordTime then
        self:UpdateRecordTime(poiID);
    end

    if RecordData[poiID] then
        return RecordData[poiID].isGold
    end
end

function DataProvider:GetNumBadges()
    --2588 Riders of Azeroth Badge
    --Icon: 4638724
    local info = C_CurrencyInfo.GetCurrencyInfo(2588);
    return (info and info.quantity) or 0
end

function DataProvider:GetClosestTourPOIID()
    local mapID;

    if not self.mapPOIs then
        self.mapPOIs = {};

        for poiID, info in pairs(TourPOI) do
            mapID = info.mapID;
            if not self.mapPOIs[mapID] then
                self.mapPOIs[mapID] = {};
            end

            table.insert(self.mapPOIs[mapID], poiID);
        end
    end

    mapID = C_Map.GetBestMapForUnit("player");
    if mapID and self.mapPOIs[mapID] then
        local position;
        local bestID;
        local x, y, d, minD;
        local mx, my;
        for _, poiID in ipairs(self.mapPOIs[mapID]) do
            position = C_Map.GetPlayerMapPosition(mapID, "player");
            if position then
                x, y = position:GetXY();
                mx, my = self:GetPOIMapPosition(poiID);
                if mx and my then
                    d = (x - mx)^2 + (y - my)^2;
                    if (minD and d < minD) or (not minD) then
                        minD = d;
                        bestID = poiID;
                    end
                end
            end
        end
        return bestID
    end
end

local CalendarTexture = {
    [5213737] = "Kalimdor",
    [5213738] = "Kalimdor",
};

function DataProvider:GetActiveTournamentInfo()
    local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();
    local presentDay = currentCalendarTime.monthDay;

    local monthOffset = 0;
    local holidayInfo;
    local tourLabel, tourName;
    local durationText, remainingSeconds;

    local eventEndTime;

    for i = 1, C_Calendar.GetNumDayEvents(monthOffset, presentDay) do   --Need to request data first with C_Calendar.OpenCalendar()
        holidayInfo = C_Calendar.GetHolidayInfo(monthOffset, presentDay, i);
        if holidayInfo and holidayInfo.texture and CalendarTexture[holidayInfo.texture] then
            tourLabel = CalendarTexture[holidayInfo.texture];
            tourName = holidayInfo.name;
            if holidayInfo.startTime and holidayInfo.endTime then
                --durationText = FormatShortDate(holidayInfo.endTime.monthDay, holidayInfo.endTime.month) .." "..  GameTime_GetFormattedTime(holidayInfo.endTime.hour, holidayInfo.endTime.minute, true);
                eventEndTime = holidayInfo.endTime;
            end
            break
        end
    end

    if eventEndTime then
        local dayOffset, minuteOffset = NarciAPI.GetCalendarTimeDifferenceInDays(currentCalendarTime, eventEndTime);
        local presentTime = time();
        remainingSeconds = minuteOffset * 60;
        self.endTime = presentTime + remainingSeconds;
    end

    return tourName, remainingSeconds
end

function DataProvider:GetTournamentRemainingSeconds()
    if self.endTime then
        local presentTime = time();
        return self.endTime - presentTime
    else
        return 0
    end
end

---- Dev Tool ----
local function ConvertMapPositionToContinentPosition(uiMapID, x, y, poiID)
    local info = C_Map.GetMapInfo(uiMapID);
    if not info then return end;

    local continentMapID;
    local parentMapID = info.parentMapID;

    while info do
        if info.mapType == Enum.UIMapType.Continent then
            continentMapID = info.mapID;
            break
        elseif info.parentMapID then
            info = C_Map.GetMapInfo(info.parentMapID);
        else
            return
        end
    end

    if not continentMapID then
        print(string.format("Map %s doesn't belong to any continent.", uiMapID));
    end

    local point = {
        uiMapID = uiMapID,
        position = CreateVector2D(x, y);
    };

    C_Map.SetUserWaypoint(point);

    C_Timer.After(0, function()
        local posVector = C_Map.GetUserWaypointPositionForMap(continentMapID);
        if posVector then
            x, y = posVector:GetXY();
            print(continentMapID, x, y);
            
            if not NarciDevToolOutput then
                NarciDevToolOutput = {};
            end

            if poiID then
                NarciDevToolOutput[poiID] = {
                    id = poiID,
                    mapID = uiMapID,
                    continent = continentMapID,
                    cx = x,
                    cy = y,
                };
            end
        else
            print("No user waypoint found.")
        end
    end);
end

local function GetPOIContinentPosition(poiID)
    local mapID = TourPOI[poiID].mapID;
    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID);
    if poiInfo then
        local x, y = poiInfo.position:GetXY();
        ConvertMapPositionToContinentPosition(mapID, x, y, poiID);
    end
end

local function ProcessAllPOI()
    local f = CreateFrame("Frame");
    f.t = 0;

    local pois = {};
    local i = 0;

    for k, v in pairs(TourPOI) do
        table.insert(pois, k);
    end

    f:SetScript("OnUpdate", function(self, elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.25 then
            self.t = 0;

            i = i + 1;
            if pois[i] then
                GetPOIContinentPosition( pois[i] );
            else
                self:SetScript("OnUpdate", nil);
            end
        end
    end);
end