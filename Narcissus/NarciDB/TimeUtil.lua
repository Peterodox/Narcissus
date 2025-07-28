local match = string.match;
local floor = math.floor;
local mod = math.fmod;
local tonumber = tonumber;
local date = date;
local time = time;


local RemoveNumberBracket;

if GetLocale() == "zhCN" then
    function RemoveNumberBracket(text)
        return string.gsub(text, "[%s%d%(%)（）]", "")
    end
else
    function RemoveNumberBracket(text)
        return string.gsub(text, "[%s%d%(%)]", "")
    end
end


local TIME_LEFT_HOUR, TIME_LEFT_HOURS = string.match(ITEM_ENCHANT_TIME_LEFT_HOURS, "|4(%S+):(%S+);");
if not TIME_LEFT_HOUR then
    TIME_LEFT_HOUR = RemoveNumberBracket(string.format(ITEM_ENCHANT_TIME_LEFT_HOURS, " ", 1));
end
if not TIME_LEFT_HOURS then
    TIME_LEFT_HOURS = RemoveNumberBracket(string.format(ITEM_ENCHANT_TIME_LEFT_HOURS, " ", 2));
end
local TIME_LEFT_MIN = RemoveNumberBracket(string.format(ITEM_ENCHANT_TIME_LEFT_MIN, " ", 2));
local TIME_LEFT_SEC = RemoveNumberBracket(string.format(ITEM_ENCHANT_TIME_LEFT_SEC, " ", 2));


local function ConvertTextToSeconds(durationText)
    --e.g. can convert "24 min" but not "24 min 12 sec"
    local number = tonumber(match(durationText, "(%d+)"));
    if match(durationText, TIME_LEFT_HOURS) or match(durationText, TIME_LEFT_HOUR) then
        return number * 3600
    elseif match(durationText, TIME_LEFT_MIN) then
        return number * 60
    elseif match(durationText, TIME_LEFT_SEC) then
        return number
    else
        return 0
    end
end

NarciAPI.ConvertTextToSeconds = ConvertTextToSeconds;


local function SecondsToCooldownAbbrev(seconds)
    --e.g. 90 seconds - 1.5 min
    if seconds == nil then
        return ""
    end

    if seconds >= 86400 then
        local hour = floor(10 * seconds/86400 + 0.5)*0.1
        return hour.." hr"
    elseif seconds >= 60 then
        local miniute = floor(10 * seconds/60 + 0.5)*0.1
        return miniute.." min"
    else
        seconds = floor(10 * seconds + 0.5)*0.1
        return seconds.." sec"
    end
end

NarciAPI.SecondsToCooldownAbbrev = SecondsToCooldownAbbrev;


--[[
print(TIME_LEFT_HOURS);
print(TIME_LEFT_HOUR);
print(TIME_LEFT_MIN);
print(TIME_LEFT_SEC);
--]]


local function WrapNumber(text)
    return string.gsub(text, "%%d", "(%%d+)");
end

local PATTERN_MINUTE = WrapNumber(MINUTES_ABBR or "%d |4Min:Min;");
local PATTERN_SECOND = WrapNumber(SECONDS_ABBR or "%d |4Sec:Sec;");

local function GetTimeFromAbbreviatedDurationText(durationText, toSeconds)
    local minutes = match(durationText, PATTERN_MINUTE);
    local seconds = match(durationText, PATTERN_SECOND);

    if minutes then
        minutes = tonumber(minutes);
    else
        minutes = 0;
    end

    if seconds then
        seconds = tonumber(seconds);
    else
        seconds = 0;
    end

    if toSeconds then
        return 60*minutes + seconds
    else
        return minutes, seconds
    end
end

NarciAPI.GetTimeFromAbbreviatedDurationText = GetTimeFromAbbreviatedDurationText;


local function FormatTime(seconds)
    seconds = seconds or 0;

    local hour = floor(seconds / 3600);
    local minute = floor((seconds - 3600 * hour) / 60);
    local second = mod(seconds, 60);
    if hour > 0 then
        return hour.."h "..minute.."m "..second.."s";
    elseif minute > 0 then
        return minute.."m "..second.."s";
    else
        return second.."s";
    end
end

NarciAPI.FormatTime = FormatTime;




local MonthDays = {
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
};

local function IsLeapYear(year)
    return year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)
end

local function GetFebruaryDays(year)
    if IsLeapYear(year) then
        return 29
    else
        return 28
    end
end

local function GetNumDaysToDate(year, month, day)
    local numDays = day;

    for yr = 1, (year -1) do
        if IsLeapYear(yr) then
            numDays = numDays + 366;
        else
            numDays = numDays + 365;
        end
    end

    for m = 1, (month - 1) do
        if m == 2 then
            numDays = numDays + GetFebruaryDays(year);
        else
            numDays = numDays + MonthDays[m];
        end
    end

    return numDays
end

local function GetNumSecondsToDate(year, month, day, hour, minute, second)
    hour = hour or 0;
    minute = minute or 0;
    second = second or 0;
    local numDays = GetNumDaysToDate(year, month, day);
    local numSeconds = second;
    numSeconds = numSeconds + numDays * 86400;
    numSeconds = numSeconds + hour * 3600 + minute * 60;
    return numSeconds
end

local function ConvertCalendarTime(calendarTime)
    --WoW's CalendarTime See https://warcraft.wiki.gg/wiki/API_C_DateAndTime.GetCurrentCalendarTime
    local year = calendarTime.year;
    local month = calendarTime.month;
    local day = calendarTime.monthDay;
    local hour = calendarTime.hour;
    local minute = calendarTime.minute;
    local second = calendarTime.second or 0;    --the original calendarTime does not contain second

    return {year, month, day, hour, minute, second}
end

local function GetCalendarTimeDifference(lhsCalendarTime, rhsCalendarTime)
    --time = {year, month, day, hour, minute, second}
    local time1 = ConvertCalendarTime(lhsCalendarTime);
    local time2 = ConvertCalendarTime(rhsCalendarTime);
    local second1 = GetNumSecondsToDate(unpack(time1));
    local second2 = GetNumSecondsToDate(unpack(time2));
    return second2 - second1
end
NarciAPI.GetCalendarTimeDifference = GetCalendarTimeDifference;


local function EpochToDate(second)
    local timeString = date("%d %m %y", second)
    local day, month, year = string.split(" ", timeString);
    local calendarTime = {};
    calendarTime.year = tonumber(year or 0);
    calendarTime.month = tonumber(month or 0);
    calendarTime.day = tonumber(day or 0);
    return calendarTime
end
NarciAPI.EpochToDate = EpochToDate;


local function GetRelativeTime()
    return time() - 1753700000
end
NarciAPI.GetRelativeTime = GetRelativeTime;