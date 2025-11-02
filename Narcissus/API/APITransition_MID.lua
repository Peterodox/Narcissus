local _, addon = ...

local TransitionAPI = addon.TransitionAPI;
local IS_MIDNIGHT = addon.IsTOCVersionEqualOrNewerThan(120000);

local ipairs = ipairs;
local pairs = pairs;
local unpack = unpack;
local select = select;
local issecretvalue = issecretvalue or function(_) return false end;
TransitionAPI.Secret_IsSecret = issecretvalue;


do  --Secret General
    local function Secret_Multiply(...)
        if select("#", ...) == 1 then
            return ...
        end

        local v, result;
        for i = 1, select("#", ...) do
            v = select(i, ...);
            if issecretvalue(v) then
                return
            else
                if i == 1 then
                    result = v;
                else
                    result = result * v;
                end
            end
        end

        return result
    end
    TransitionAPI.Secret_Multiply = Secret_Multiply;


    local function Secret_DoesStringExist(obj)
        if issecretvalue(obj) then return true end;
        return obj ~= nil
    end
    TransitionAPI.Secret_DoesStringExist = Secret_DoesStringExist;
end


do  --Unit
    local function UnitHasMana()
        local powerType = UnitPowerType("player");
        return powerType == 0
    end
    TransitionAPI.UnitHasMana = UnitHasMana;
end


do  --Chat
    if C_ChatInfo and C_ChatInfo.PerformEmote then
        TransitionAPI.DoEmote = C_ChatInfo.PerformEmote;
    else
        TransitionAPI.DoEmote = DoEmote;
    end
end