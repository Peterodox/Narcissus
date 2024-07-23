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

