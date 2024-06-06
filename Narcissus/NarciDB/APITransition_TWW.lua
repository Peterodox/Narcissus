local _, addon = ...

local TransitionAPI = addon.TransitionAPI;
local IS_TWW = TransitionAPI.IsTWW();

local ipairs = ipairs;
local pairs = pairs;
local unpack = unpack;


do  --Spell
    local C_Spell = C_Spell;

    if not IS_TWW then
        TransitionAPI.GetSpellInfo = GetSpellInfo;
        TransitionAPI.GetSpellDescription = GetSpellDescription;
        TransitionAPI.IsSpellPassive = IsPassiveSpell;
    else
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
    end
end


do  --Item
    if not IS_TWW then
        TransitionAPI.GetItemQualityColor = GetItemQualityColor;
    else
        TransitionAPI.GetItemQualityColor = C_Item.GetItemQualityColor;
        local function GetItemQualityColor_Flat(quality)
            local color = GetItemQualityColor(quality);
            if color then
                return color.r, color.g, color.b
            end
        end
    end
end


do  --System
    if not IS_TWW then
        TransitionAPI.GetMouseFocus = GetMouseFocus;
    else
        local GetMouseFoci = GetMouseFoci;

        local function GetMouseFocus()
            local object = GetMouseFoci();
            return object and object[1]
        end
        TransitionAPI.GetMouseFocus = GetMouseFocus;
    end
end