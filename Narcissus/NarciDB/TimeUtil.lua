local match = string.match;
local floor = math.floor;
local mod = math.fmod;
local tonumber = tonumber;

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