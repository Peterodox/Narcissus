local _, addon = ...
local API = addon.API;


local _, _, CLASS_ID = UnitClass and UnitClass("player");


function API.IsPlayerDruid()
    return CLASS_ID == 11
end