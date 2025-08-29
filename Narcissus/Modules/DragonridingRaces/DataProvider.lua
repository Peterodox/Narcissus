local _, addon = ...

local DataProvider = {};
addon.DragonridingRaceDataProvider = DataProvider;

local time = time;

--Bronze Timekeeper vignetteID 5104

local CalendarTexture = {
    [5213737] = "Kalimdor",
    [5213738] = "Kalimdor",
    [5225883] = "Eastern Kingdoms",
    [5225884] = "Eastern Kingdoms",
    [5225881] = "Outland",
    [5225882] = "Outland",
};

local TourLabelXContitentMapID = {
    ["Kalimdor"] = 12,
    ["Eastern Kingdoms"] = 13;
    ["Outland"] = 101,
};

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


	[7571] = {--Gilneas Gambit
		["mapID"] = 217,
		["cy"] = 0.4402732253074646,
		["cx"] = 0.4068848490715027,
		["id"] = 7571,
		["continent"] = 13,
	},
	[7572] = {--Loch Modan Loop
		["mapID"] = 48,
		["cy"] = 0.5863564014434814,
		["cx"] = 0.5267385244369507,
		["id"] = 7572,
		["continent"] = 13,
	},
	[7573] = {--Searing Slalom
		["mapID"] = 32,
		["cy"] = 0.6595594882965088,
		["cx"] = 0.4940609931945801,
		["id"] = 7573,
		["continent"] = 13,
	},
	[7574] = {--Twilight Terror
		["mapID"] = 241,
		["cy"] = 0.5918666124343872,
		["cx"] = 0.5508695840835571,
		["id"] = 7574,
		["continent"] = 13,
	},
	[7575] = {--Deadwind Derby
		["mapID"] = 42,
		["cy"] = 0.8194032907485962,
		["cx"] = 0.4948469400405884,
		["id"] = 7575,
		["continent"] = 13,
	},
	[7576] = {--Elwynn Forest Flash
		["mapID"] = 37,
		["cy"] = 0.7455446720123291,
		["cx"] = 0.463355302810669,
		["id"] = 7576,
		["continent"] = 13,
	},
	[7577] = {--Gurubashi Gala
		["mapID"] = 50,
		["cy"] = 0.8441623449325562,
		["cx"] = 0.4737812876701355,
		["id"] = 7577,
		["continent"] = 13,
	},
	[7578] = {--Ironforge Interceptor
		["mapID"] = 27,
		["cy"] = 0.5976994633674622,
		["cx"] = 0.48268061876297,
		["id"] = 7578,
		["continent"] = 13,
	},
	[7579] = {--Blasted Lands Bolt
		["mapID"] = 17,
		["cy"] = 0.8249945640563965,
		["cx"] = 0.5316610336303711,
		["id"] = 7579,
		["continent"] = 13,
	},
	[7580] = {--Plaguelands Plunge
		["mapID"] = 23,
		["cy"] = 0.3127650022506714,
		["cx"] = 0.5365713238716125,
		["id"] = 7580,
		["continent"] = 13,
	},
	[7581] = {--Booty Bay Blast
		["mapID"] = 210,
		["cy"] = 0.9481046199798584,
		["cx"] = 0.433427095413208,
		["id"] = 7581,
		["continent"] = 13,
	},
	[7582] = {--Fuselight Night Flight
		["mapID"] = 15,
		["cy"] = 0.654969334602356,
		["cx"] = 0.5433018207550049,
		["id"] = 7582,
		["continent"] = 13,
	},
	[7583] = {--Krazzworks Klash
		["mapID"] = 241,
		["cy"] = 0.5271182060241699,
		["cx"] = 0.6001608371734619,
		["id"] = 7583,
		["continent"] = 13,
	},
	[7584] = {--Redridge Rally
		["mapID"] = 49,
		["cy"] = 0.7410318851470947,
		["cx"] = 0.5080758333206177,
		["id"] = 7584,
		["continent"] = 13,
	},


	[7589] = {--Hellfire Hustle
		["mapID"] = 100,
		["cy"] = 0.5036680698394775,
		["cx"] = 0.6502492427825928,
		["id"] = 7589,
		["continent"] = 101,
	},
	[7590] = {--Coilfang Caper
		["mapID"] = 102,
		["cy"] = 0.4408425688743591,
		["cx"] = 0.3078436851501465,
		["id"] = 7590,
		["continent"] = 101,
	},
	[7591] = {--Blade's Edge Brawl
		["mapID"] = 105,
		["cy"] = 0.2070049643516541,
		["cx"] = 0.4271526038646698,
		["id"] = 7591,
		["continent"] = 101,
	},
	[7592] = {--Telaar Tear
		["mapID"] = 107,
		["cy"] = 0.7368491888046265,
		["cx"] = 0.3388928771018982,
		["id"] = 7592,
		["continent"] = 101,
	},
	[7593] = {--Razorthorn Rise Rush
		["mapID"] = 108,
		["cy"] = 0.6006608009338379,
		["cx"] = 0.5234887599945068,
		["id"] = 7593,
		["continent"] = 101,
	},
	[7594] = {--Auchindoun Coaster
		["mapID"] = 108,
		["cy"] = 0.7958080768585205,
		["cx"] = 0.4691863059997559,
		["id"] = 7594,
		["continent"] = 101,
	},
	[7595] = {--Tempest Keep Sweep
		["mapID"] = 109,
		["cy"] = 0.1837196350097656,
		["cx"] = 0.6500643491744995,
		["id"] = 7595,
		["continent"] = 101,
	},
	[7596] = {--Shattrath City Sashay
		["mapID"] = 108,
		["cy"] = 0.6794252991676331,
		["cx"] = 0.4461385011672974,
		["id"] = 7596,
		["continent"] = 101,
	},
	[7597] = {--Shadowmoon Slam
		["mapID"] = 104,
		["cy"] = 0.8197986483573914,
		["cx"] = 0.6966030597686768,
		["id"] = 7597,
		["continent"] = 101,
	},
	[7598] = {--Eco-Dome Excursion
		["mapID"] = 109,
		["cy"] = 0.1652154326438904,
		["cx"] = 0.5935842990875244,
		["id"] = 7598,
		["continent"] = 101,
	},
	[7599] = {--Warmaul Wingding
		["mapID"] = 107,
		["cy"] = 0.5756202340126038,
		["cx"] = 0.2478588819503784,
		["id"] = 7599,
		["continent"] = 101,
	},
	[7600] = {--Skettis Scramble
		["mapID"] = 108,
		["cy"] = 0.7895718812942505,
		["cx"] = 0.5464901328086853,
		["id"] = 7600,
		["continent"] = 101,
	},
	[7601] = {--Fel Pit Fracas
		["mapID"] = 104,
		["cy"] = 0.7935017347335815,
		["cx"] = 0.662832498550415,
		["id"] = 7601,
		["continent"] = 101,
	},
};

local RecordData = {
    --Record is Currency
    --Currency Naming Rule: Dragon Racing - Personal Best Record - E Kingdoms 07 ← This number is the same as its achievement criteria order

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

    --E Kingdoms
    [7571] = {--01
        goldTime = {78, 74, 74},
        recordCurrency = {2536, 2552, 2568},
    },

    [7572] = {--02
        goldTime = {63, 61, 63},
        recordCurrency = {2537, 2553, 2569},
    },

    [7573] = {--03
        goldTime = {52, 46, 43},
        recordCurrency = {2538, 2554, 2570},
    },

    [7574] = {--04
        goldTime = {73, 68, 66},
        recordCurrency = {2539, 2555, 2571},
    },

    [7575] = {--05
        goldTime = {60, 59, 59},
        recordCurrency = {2540, 2556, 2572},
    },

    [7576] = {--06
        goldTime = {73, 66, 63},
        recordCurrency = {2541, 2557, 2573},
    },

    [7577] = {--07
        goldTime = {56, 49, 50},
        recordCurrency = {2542, 2558, 2574},
    },

    [7578] = {--08
        goldTime = {70, 64, 60},
        recordCurrency = {2543, 2559, 2575},
    },

    [7579] = {--09
        goldTime = {69, 62, 64},
        recordCurrency = {2544, 2560, 2576},
    },

    [7580] = {--10
        goldTime = {63, 53, 58},
        recordCurrency = {2545, 2561, 2577},
    },

    [7581] = {--11
        goldTime = {63, 57, 56},
        recordCurrency = {2546, 2562, 2578},
    },

    [7582] = {--12
        goldTime = {64, 58, 58},
        recordCurrency = {2547, 2563, 2579},
    },

    [7583] = {--13
        goldTime = {71, 64, 62},
        recordCurrency = {2548, 2564, 2580},
    },

    [7584] = {--14
        goldTime = {57, 52, 52},
        recordCurrency = {2549, 2565, 2581},
    },

    --Outland
    [7589] = {--1
        goldTime = {75, 73, 72},
        recordCurrency = {2600, 2615, 2630},
    },

    [7590] = {--2
        goldTime = {75, 70, 70},
        recordCurrency = {2601, 2616, 2631},
    },

    [7591] = {--3
        goldTime = {75, 72, 75},
        recordCurrency = {2602, 2617, 2632},
    },

    [7592] = {--4
        goldTime = {64, 57, 58},
        recordCurrency = {2603, 2618, 2633},
    },

    [7593] = {--5
        goldTime = {67, 54, 54},
        recordCurrency = {2604, 2619, 2634},
    },

    [7594] = {--6
        goldTime = {73, 70, 70},
        recordCurrency = {2605, 2620, 2635},
    },

    [7595] = {--7
        goldTime = {100, 87, 88},
        recordCurrency = {2606, 2621, 2636},
    },

    [7596] = {--8
        goldTime = {75, 65, 66},
        recordCurrency = {2607, 2622, 2637},
    },

    [7597] = {--9
        goldTime = {70, 63, 63},
        recordCurrency = {2608, 2623, 2638},
    },

    [7598] = {--10
        goldTime = {115, 109, 110},
        recordCurrency = {2609, 2624, 2639},
    },

    [7599] = {--11
        goldTime = {80, 72, 73},
        recordCurrency = {2610, 2625, 2640},
    },

    [7600] = {--12
        goldTime = {70, 63, 63},
        recordCurrency = {2611, 2626, 2641},
    },

    [7601] = {--13
        goldTime = {77, 73, 76},
        recordCurrency = {2612, 2627, 2642},
    },
};

DataProvider.TourPOI = TourPOI;

local WidgetVisibleMaps = {};

function DataProvider:InitMapPool(tourLabel)
    local uiMapID = tourLabel and TourLabelXContitentMapID[tourLabel]
    if uiMapID then
        WidgetVisibleMaps[uiMapID] = true;
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
    else
        --The API seems to return nil when tournament is not active
        --Use our own data as a fallback 
        point.uiMapID = TourPOI[poiID]["continent"];
        point.position = {
            x = TourPOI[poiID]["cx"],
            y = TourPOI[poiID]["cy"],
        }
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
    if not continentMapID then
        return {}
    end

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


function DataProvider:SetCurrentContinent(continentMapID)
    self.currentContinent = continentMapID;
end

function DataProvider:GetPOIsForCurrentContinent()
    return self:GetPOIsForContinent( self.currentContinent )
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
    if not RecordData[poiID] then
        return false
    end

    if not RecordData[poiID].recordTime then
        self:UpdateRecordTime(poiID);
    end

    return RecordData[poiID].isGold
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


function DataProvider:GetActiveTournamentInfo()
    local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();
    local presentDay = currentCalendarTime.monthDay;

    local monthOffset = 0;
    local holidayInfo;
    local tourLabel, tourName;
    local durationText, remainingSeconds;

    local eventEndTime;

    --debug
    --monthOffset = -1;
    --presentDay = 27;

    for i = 1, C_Calendar.GetNumDayEvents(monthOffset, presentDay) do   --Need to request data first with C_Calendar.OpenCalendar()
        holidayInfo = C_Calendar.GetHolidayInfo(monthOffset, presentDay, i);
        --print(holidayInfo.name, holidayInfo.texture)
        if holidayInfo and holidayInfo.texture and CalendarTexture[holidayInfo.texture] then
            tourLabel = CalendarTexture[holidayInfo.texture];
            DataProvider:InitMapPool(tourLabel);
            tourName = holidayInfo.name;
            if holidayInfo.startTime and holidayInfo.endTime then
                --durationText = FormatShortDate(holidayInfo.endTime.monthDay, holidayInfo.endTime.month) .." "..  GameTime_GetFormattedTime(holidayInfo.endTime.hour, holidayInfo.endTime.minute, true);
                eventEndTime = holidayInfo.endTime;
            end
            break
        end
    end

    if eventEndTime then
        remainingSeconds = NarciAPI.GetCalendarTimeDifference(currentCalendarTime, eventEndTime);
        local presentTime = time();
        self.endTime = presentTime + remainingSeconds;
    end

    return tourName, remainingSeconds, tourLabel
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
    else
        print(poiID, "NO POI")
    end
end

local function ProcessAllPOI()
    local f = CreateFrame("Frame");
    f.t = 0;

    local pois = {};
    local i = 0;

    for poiID in pairs(TourPOI) do
        table.insert(pois, poiID);
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



--[[
local RawAreaPOI = {
    {7571, -776.93701171875, 1595, 217},
    {7572, -4743.0498046875, -3287.9799804688, 48},
    {7573, -6730.490234375, -1956.6600341797, 32},
    {7574, -4892.6499023438, -4271.1098632812, 241},
    {7575, -11070.200195312, -1988.6800537109, 42},
    {7576, -9064.9599609375, -705.67102050781, 37},
    {7577, -11742.400390625, -1130.4399414062, 50},
    {7578, -5051.009765625, -1493.0100097656, 27},
    {7579, -11222, -3488.5300292969, 17},
    {7580, 2684.8701171875, -3688.580078125, 23},
    {7581, -14564.400390625, 513.63800048828, 210},
    {7582, -6605.8701171875, -3962.7900390625, 15},
    {7583, -3134.75, -6279.2900390625, 241},
    {7584, -8942.4404296875, -2527.6398925781, 49},
}

local POI_MAP_INFO = {};

for i, v in ipairs(RawAreaPOI) do
    local poiID = v[1];
    POI_MAP_INFO[poiID] = {
        x = v[2],
        y = v[3],
        mapID = v[4],
    };
end

local function GetPOIContinentPosition_Offline(poiID)
    local info = POI_MAP_INFO[poiID];
    local continentID = 0;
    local worldPosition = {
        x = info.x,
        y = info.y,
    }
    local uiMapID, mapPosition = C_Map.GetMapPosFromWorldPos(continentID, worldPosition, info.mapID);
    ConvertMapPositionToContinentPosition(info.mapID, mapPosition.x, mapPosition.y, poiID);
end

function ProcessAllRawPOI()
    local f = CreateFrame("Frame");
    f.t = 0;

    local pois = {};
    local i = 0;

    for k, v in pairs(POI_MAP_INFO) do
        table.insert(pois, k);
    end

    f:SetScript("OnUpdate", function(self, elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.25 then
            self.t = 0;

            i = i + 1;
            if pois[i] then
                GetPOIContinentPosition_Offline( pois[i] );
            else
                self:SetScript("OnUpdate", nil);
            end
        end
    end);
end
--]]