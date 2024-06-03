local _, addon = ...
local TimerunningUtil = {};
addon.TimerunningUtil = TimerunningUtil;

local SPELL_TIMERUNNERS_ADVANTAGE = 440393;
local PATTERN_STAT = "%+%d+%%? %C+";

local GetPlayerAuraBySpellID = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID;
local GetUnitBuffByAuraInstanceID = C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID;
local GetItemNumSockets = C_Item.GetItemNumSockets;
local GetItemGemID = C_Item.GetItemGemID;
local GetInventoryItemLink = GetInventoryItemLink;
local match = string.match;
local L = Narci.L;


local function IsTimerunningMode()
    return PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID() ~= nil
end
TimerunningUtil.IsTimerunningMode = IsTimerunningMode;


local SLOT_ORDER = {
    1, 2, 3, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14,
};

local function GetEquippedTraits()
    local itemLink, numSockets,gemID;
    for _, slotID in ipairs(SLOT_ORDER) do
        itemLink = GetInventoryItemLink("player", slotID);
        if itemLink then
            numSockets = GetItemNumSockets(itemLink);
            if numSockets > 0 then
                for index = 1, numSockets do
                    gemID = GetItemGemID(itemLink, index);
                    if gemID then
                        print(GetItemInfoInstant(gemID));
                    end
                end
            end
        end
    end
end
TimerunningUtil.GetEquippedTraits = GetEquippedTraits;


do
    local THREAD_CURRENCY = {
        --{currencyID, localeKey}
        {2853, "Primary Stat"},
        {2854, "Stamina"},
        {2855, "Crit"},
        {2856, "Haste"},
        {2858, "Mastery"},
        {2860, "Versatility"},
        {2857, "Leech"},
        {2859, "Speed"},
        {3001, "EXP"},
    };

    local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo;

    local function GetThreadRank()
        local info;
        local rank = 0;

        for _, data in ipairs(THREAD_CURRENCY) do
            info = GetCurrencyInfo(data[1]);
            if info then
                rank = rank + info.quantity;
            end
        end

        return rank
    end
    TimerunningUtil.GetThreadRank = GetThreadRank;


    local function GetStatsBonusFromTooltip()
        local aura = GetPlayerAuraBySpellID(SPELL_TIMERUNNERS_ADVANTAGE);
        if aura and aura.points and #aura.points > 1 then
            --for some reason the size of this table doesn't match the number of stat types
            local info = GetUnitBuffByAuraInstanceID("player", aura.auraInstanceID);
    
            local line = info and info.lines and info.lines[2];
            if line and line.leftText then
                local n = 0;
                local value, stats;
    
                for statText in string.gmatch(line.leftText, PATTERN_STAT) do
                    value = match(statText, "%+(%d+)");
                    value = value and tonumber(value) or 0;
                    if value > 0 then
                        if not stats then
                            stats = {};
                        end
                        n = n + 1;
                        stats[n] = statText;
                    end
                end

                return stats
            end
        end
    end

    local function GetStatsBonusFromCurrency()
        local info, statName, stats;
        local n = 0;

        for _, data in ipairs(THREAD_CURRENCY) do
            info = GetCurrencyInfo(data[1]);
            if info and info.quantity > 0 then
                if not stats then
                    stats = {};
                end
                n = n + 1;

                statName = data[2];

                if L["Format Stat "..statName] then
                    stats[n] = string.format(L["Format Stat "..statName], info.quantity);
                else
                    stats[n] = string.format("+%d "..L[statName], info.quantity);
                end
            end
        end

        return stats
    end

    TimerunningUtil.GetStatsBonus = GetStatsBonusFromCurrency;
end


--[[
    /dump C_Item.GetItemNumSockets(GetInventoryItemLink("player", 5))

    Tinker: Passive
    Meta: Epic Spell
    Cog: Rare Spell (Mobility)

    Ability:
    Meta Gem 439052
    Cogwheel Gem 439053

    /dump C_SpellBook.GetOverrideSpell(439052)
    /dump C_SpellBook.GetOverrideSpell(439053)
    
    Lifestorm 437011


    1 Meta: Head
    1 Feet: Cogwheel
    Tinker: Shoulder, Wrist, Hands, Waist
    
    Neck, Chest, Legs, Ring, Trinket

    2 Trinket: Timerunner's Beacon & Timerunner's Idol : 3 Prism
    2 Ring: TImerunner's Ring & Timerunner's Seal: 3 Prism
    1 Neck: Timerunner's Amulet: 3 Prism

    Total
    Prism:  21 = 7*3
    Tinker: 12 = 4*3
]]