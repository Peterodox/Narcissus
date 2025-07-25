local _, addon = ...

local Math = {};
addon.Math = Math;

local floor = math.floor;

local function Round(number)
    return floor(number + 0.5);
end
Math.Round = Round;
NarciAPI.Round = Round;

local function RoundToDigit(number, digit)
    digit = digit or 0;
    local a = 10 ^ digit;
    return Round(number * a)/a
end
Math.RoundToDigit = RoundToDigit;


local function Clamp(value, min, max)
    if value > max then
        return max
    elseif value < min then
        return min
    end
    return value
end
NarciAPI.Clamp = Clamp;

local function Lerp(startValue, endValue, amount)
    return (1 - amount) * startValue + amount * endValue;
end
NarciAPI.Lerp = Lerp;

local function Saturate(value)
    return Clamp(value, 0.0, 1.0);
end

local function DeltaLerp(startValue, endValue, amount, timeSec)
    return Lerp(startValue, endValue, Saturate(amount * timeSec * 60.0));
end
NarciAPI.DeltaLerp = DeltaLerp;