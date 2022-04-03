local _, addon = ...

local GetComparisonStatistic = GetComparisonStatistic;

local ENCOUNTERS = {
    --[instanceID], stats = { {LGF, N, H, M}, bossAchiementIcon }
    --https://wow.tools/dbc/?dbc=journalinstance&build=9.2.0.42423#page=1
    [1195] = {  --Sepulcher of the First Ones
        art = nil,
        stats = {
            {{15424, 15425, 15426, 15427}, 4254081},    --Vigilant Guardian
            {{15428, 15429, 15430, 15431}, 4254082},    --Skolex
            {{15432, 15433, 15434, 15435}, 4254076},    --Artificer Xy'mox2
            {{15436, 15437, 15438, 15439}, 4254078},    --Dausegne
            {{15440, 15441, 15442, 15443}, 4254087},    --Prototype Pantheon
            {{15444, 15445, 15446, 15447}, 4254089},    --Lihuvim
            {{15448, 15449, 15450, 15451}, 4254083},    --Halondrus
            {{15452, 15453, 15454, 15455}, 4254075},    --Anduin
            {{15456, 15457, 15458, 15459}, 4254079},    --Lords of Dread
            {{15460, 15461, 15462, 15463}, 4254077},    --Rygelon
            {{15464, 15465, 15466, 15467}, 4254080},    --The Jailer
        },
    },
};

local function GetStatAchievements(difficulty)
    local data = ENCOUNTERS[1195].stats;
    local tbl = {};
    for i = 1, #data do
        tbl[i] = data[i][1][difficulty];
    end
    return tbl
end

local function IsValueNonZero(value)
    return value and not(value == "--" or value == 0)
end

local TEST = GetStatAchievements(2);

local function GetInspectEncounterCount(unit)
    local achievementID, value;
    local total = #TEST;
    local downed = 0;
    for i = 1, total do
        achievementID = TEST[i];
        value = GetComparisonStatistic(achievementID);
        print(value)
        if IsValueNonZero(value) then
            downed = downed + 1;
        end
    end
    return string.format("%d/%d", downed, total);
end

addon.GetInspectEncounterCount = GetInspectEncounterCount;