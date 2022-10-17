local match = string.match;
local floor = math.floor;

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