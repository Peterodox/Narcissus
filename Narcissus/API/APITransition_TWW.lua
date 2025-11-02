local _, addon = ...

local TransitionAPI = addon.TransitionAPI;

local ipairs = ipairs;
local pairs = pairs;
local unpack = unpack;


do  --Spell
    local C_Spell = C_Spell;
    local GetSpellInfo_Table = C_Spell.GetSpellInfo;
    local SPELL_INFO_KEYS = {"name", "rank", "iconID", "castTime", "minRange", "maxRange", "spellID", "originalIconID"};

    local function GetSpellInfo_Flat(spellID)
        local info = spellID and GetSpellInfo_Table(spellID);
        if info then
            local tbl = {};
            local n = 0;
            for _, key in ipairs(SPELL_INFO_KEYS) do
                n = n + 1;
                tbl[n] = info[key];
            end
            return unpack(tbl)
        end
    end
    TransitionAPI.GetSpellInfo = GetSpellInfo_Flat;

    TransitionAPI.GetSpellDescription = C_Spell.GetSpellDescription;
    TransitionAPI.IsSpellPassive = C_Spell.IsSpellPassive;
    TransitionAPI.GetSpellTexture = C_Spell.GetSpellTexture;
end


do  --Item
    TransitionAPI.GetItemQualityColor = C_Item.GetItemQualityColor;
end


do  --System
    local GetMouseFoci = GetMouseFoci;

    local function GetMouseFocus()
        local objects = GetMouseFoci();
        return objects and objects[1]
    end
    TransitionAPI.GetMouseFocus = GetMouseFocus;
end


do  --Container
    local EquipmentManager_GetLocationData = EquipmentManager_GetLocationData;
    function TransitionAPI.EquipmentManager_UnpackLocation(packedLocation)
        local locationData = EquipmentManager_GetLocationData(packedLocation);
        local voidStorage, tab, voidSlot = false, nil, nil;
        return locationData.isPlayer or false, locationData.isBank or false, locationData.isBags or false, voidStorage, locationData.slot, locationData.bag, tab, voidSlot;
    end
end