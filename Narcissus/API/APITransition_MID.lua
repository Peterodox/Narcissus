local _, addon = ...

local TransitionAPI = addon.TransitionAPI;

local select = select;


do  --Secret General
    local issecretvalue = issecretvalue or function(_) return false end;
    TransitionAPI.Secret_IsSecret = issecretvalue;

    local canaccessvalue = canaccessvalue or function(_) return true end;

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


    local function Secret_CanAccess(v)
        if canaccessvalue(v) then
            return v ~= nil
        end
        return false
    end
    TransitionAPI.Secret_CanAccess = Secret_CanAccess;
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


do  --Transmog
    local GetSlotVisualInfo = C_Transmog.GetSlotVisualInfo;

    function TransitionAPI.SetTransmogLocationData(transmogLocation, slotID, transmogType, modification)
        local slot = C_TransmogOutfitInfo.GetTransmogOutfitSlotFromInventorySlot(slotID - 1);
        local locationData = {
            slotID = slotID,
            slot = slot,
            transmogType = transmogType or 0,
            isSecondary = modification and modification == 1 or false,
        }
        transmogLocation:Set(locationData);
    end

    function TransitionAPI.GetSlotVisualInfo(transmogLocation)
        local slotVisualInfo = transmogLocation and GetSlotVisualInfo(transmogLocation:GetData());
        if slotVisualInfo then
            return slotVisualInfo.baseSourceID, slotVisualInfo.baseVisualID, slotVisualInfo.appliedSourceID, slotVisualInfo.appliedVisualID
        end
    end

    function TransitionAPI.GetTransmogSourceName(sourceType)
        --sourceType matches the TRANSMOG_SOURCE_# index (same on Standard and Forever)
        return sourceType and _G["TRANSMOG_SOURCE_".. sourceType]
    end
end
