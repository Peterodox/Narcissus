----Pre Dragonflight Before 10.1----

local _, addon = ...
if addon.GetTooltipInfoVersion() ~= 1 then
    return
end

local C_TooltipInfo = C_TooltipInfo;
local GetInfoByHyperlink = C_TooltipInfo.GetHyperlink;
local GetInfoByItemID = C_TooltipInfo.GetItemByID;
local GetInfoByBagItem = C_TooltipInfo.GetBagItem;
local GetInfoByInventoryItem = C_TooltipInfo.GetInventoryItem;

local strtrim = strtrim;
local strsub = string.sub;
local gsub = string.gsub;
local match = string.match;
local find = string.find;
local format = string.format;
local split = string.split;
local tonumber = tonumber;
local type = type;
local select = select;
local tinsert = table.insert;

local floor = math.floor;
local max = math.max;

local _G = _G;
local L = Narci.L;
local TEXT_LOCALE = GetLocale();

local GetItemInfoInstant = GetItemInfoInstant;
local GetItemGem = GetItemGem;
local GetItemStats = GetItemStats;
local GetInventoryItemLink = GetInventoryItemLink;

local function IsArtifactRelic(item)
    --an alternative to IsArtifactRelicItem()
    local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(item);
    return classID == 3 and subclassID == 11
end

--[[
    Enum.TooltipDataLineType

    GameTooltip Color Scheme
    1, 0.13, 0.13  --red
    0, 1, 0     --green
    1, 1, 1     --white
    1, 0.5, 1   --pink transmog
    0.5, 0.5, 0.5   --grey

    ITEM_SET_LEGACY_INACTIVE_BONUS
    ITEM_LEGACY_INACTIVE_EFFECTS
--]]

local function RoundColor(a)
    return tonumber(format("%.2f", floor(a*100+0.5)*0.01 ))
end

local function IsTextColorColor(colorVal, r, g, b)
    if not colorVal then return false end;
    return (RoundColor(colorVal.r) == r) and (RoundColor(colorVal.g) == g) and (RoundColor(colorVal.b) == b)
end

local function IsTextColorRed(colorVal)
    --1, 0.13, 0.13
    if not colorVal then return false end;
    local r, g, b = colorVal.r, colorVal.g, colorVal.b;
    return (r > 0.99) and (g > 0.12 and g < 0.14) and (b > 0.12 and b < 0.14)
end

local function IsTextColorYellow(colorVal)
    --1, 0.82, 0
    if not colorVal then return false end;
    local r, g, b = colorVal.r, colorVal.g, colorVal.b;
    return (r > 0.99) and (g > 0.83 and g < 0.81) and (b < 0.01)
end

local function IsTextColorWhite(colorVal)
    if not colorVal then return false end;
    local r, g, b = colorVal.r, colorVal.g, colorVal.b;
    return (r > 0.99) and (g > 0.99) and (b > 0.99)
end

local function IsTextColor50Grey(colorVal)
    --0.5, 0.5, 0.5
    if not colorVal then return false end;
    local r, g, b = colorVal.r, colorVal.g, colorVal.b;
    return (r > 0.49 and r < 0.51) and (g > 0.49 and g < 0.51) and (b > 0.49 and b < 0.51)
end


local function TrimColon(text)
    return strtrim(text, ":：");
end

local function TrimWhiteSpace(text)
    return gsub(text, "%%s", "");
end

local function Pattern_WrapBrace(text)
    return text and gsub(text, "([()（）])", "%%%1");
end

local function Pattern_WrapSpace(text)
    return text and gsub(text, "%%s", "%(%.%+%)");
end

local function Pattern_WrapNumber(text)
    if not text then return end
    text = gsub(text, "%%d", "%(%%d%)");
    text = gsub(text, "%%d%+", "%(%%d%+%)");
    return text
end

local LEFT_BRACE = "%(";
local RIGHT_BRACE = "%)";


local ON_USE = ITEM_SPELL_TRIGGER_ONUSE;
local ON_EQUIP = ITEM_SPELL_TRIGGER_ONEQUIP;
local ON_PROC = ITEM_SPELL_TRIGGER_ONPROC;
local ITEM_BONUS = L["Item Bonus"];   --Bonus: (used by Domination Shard)     --ITEM_SOCKET_BONUS
local NO_COMMA_ON_USE = TrimColon(ON_USE);
local NO_COMMA_ON_EQUIP = TrimColon(ON_EQUIP);
local NO_COMMA_ON_PROC = TrimColon(ON_PROC);
local NO_COMMA_SET_BONUS = TrimColon(ITEM_BONUS);
local GEM_MIN_LEVEL = SOCKETING_ITEM_MIN_LEVEL_I;   --Requires Item Level:
local GREY_FONT = "|cff959595";
local SOURCE_KNOWN = TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN;
local APPEARANCE_KNOWN = TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN;
local APPEARANCE_UNKNOWN = TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN;

local TEXT_SPELL_RANGE = TrimWhiteSpace(SPELL_RANGE or "%s yd range");
local TEXT_SPELL_RANGE_UNLIMITED = SPELL_RANGE_UNLIMITED or "Unlimited range";
local TEXT_SPELL_RANGE_MELEE = MELEE_RANGE or "Melee Range";
local TEXT_SPELL_CAST_TIME_INSTANT = SPELL_CAST_TIME_INSTANT or "Instant";
local TEXT_SPELL_CAST_TIME_SEC = gsub(SPELL_CAST_TIME_SEC or "%.2g sec cast", "%%.2g", "");
local TEXT_SPELL_CAST_CHANNELED = SPELL_CAST_CHANNELED or "Channeled";
local TEXT_SPELL_PASSIVE = SPELL_PASSIVE or "Passive";
local TEXT_SPELL_COOLDOWN = L["Find Cooldown"];
local TEXT_SPELL_RECHARGE = L["Find Recharge"];
local TEXT_REPLACES_SPELL = TrimWhiteSpace(REPLACES_SPELL or "Replaces %s");
local TEXT_COSMETIC = ITEM_COSMETIC or "Cosmetic";

local SET_BONUS = TrimWhiteSpace(ITEM_SET_BONUS);          --"Set: %s"     --SET_BONUS_GRAY
local SOCKET_BONUS = TrimWhiteSpace(ITEM_SOCKET_BONUS);    --Socket Bonus: %s

local PATTERN_COOLDOWN_TIME = "%((%d.+) Cooldown%)$";
local PATTERN_UPGRADE_LEVEL = gsub(ITEM_UPGRADE_TOOLTIP_FORMAT, "%%d+", "(%%d+)");
local PATTERN_ITEM_SET_NAME = "(.+) %((%d+)/(%d+)%)";   --Pattern_WrapNumber( Pattern_WrapSpace( Pattern_WrapBrace( ITEM_SET_NAME) ) );
local PATTERN_CLASS_REQUIREMENT = Pattern_WrapSpace(ITEM_CLASSES_ALLOWED);
local PATTERN_AMMO_DPS = gsub(AMMO_DAMAGE_TEMPLATE, "%%s", "([%%d.]+)");
local PATTERN_PROFESSION_QUALITY = Pattern_WrapSpace(PROFESSIONS_CRAFTING_QUALITY or "Quality: %s");
local PATTERN_ITEM_LEVEL = ITEM_LEVEL or "Item Level";

local SOCKET_TYPE_TEXTURE =	{
    Yellow = "Yellow",
    Red = "Red",
    Blue = "Blue",
    Hydraulic = "HYDRAULIC",
    Cogwheel = "COGWHEEL",
    Meta = "meta",
    Prismatic = "prismatic",
    PunchcardRed = "PunchcardRed",
    PunchcardYellow = "PunchcardYellow",
    PunchcardBlue = "PunchcardBlue",
    Domination = "Domination",
    Cypher = "META",
    Tinker = "PunchcardRed",
};

do
    if TEXT_LOCALE == "zhCN" then
        LEFT_BRACE = "（";
        RIGHT_BRACE = "）";
        PATTERN_ITEM_SET_NAME = "(.+)（(%d+)/(%d+)）"  --"%s（%d/%d）";
    elseif TEXT_LOCALE == "zhTW" then
        PATTERN_ITEM_SET_NAME = "(.+)%((%d+)/(%d+)%)";   --%s(%d/%d)
    elseif TEXT_LOCALE == "deDE" then
        PATTERN_ITEM_SET_NAME = "(.+) %((%d+)/(%d+)%)";     --"%1$s (%2$d/%3$d)"??
    end
end

local function RemoveColorString(str)
    if str then
        return gsub(str, "|[cC][fF][fF][%w%s][%w%s][%w%s][%w%s][%w%s][%w%s](.*)|[rR]", "%1")
    end
end

NarciAPI.RemoveColorString = RemoveColorString;

local function FormatItemLink(link)
    return match(link, "(item:[%-?%d:]+)");
end

local function FormatString(text, removedText, keepFormat)
    if not keepFormat then
        text = strtrim(text, removedText);
        text = TrimColon(text);
        text = strtrim(text);                               --remove space
        text = gsub(text, LEFT_BRACE, "\n\n"..GREY_FONT)
        text = gsub(text, RIGHT_BRACE, "|r")
    end
    return text;
end

local function TrimCooldownText(text)
    text = TrimColon(text);
    local cooldownText = match(text, PATTERN_COOLDOWN_TIME);
    text = gsub(text, LEFT_BRACE..".+"..RIGHT_BRACE.."$", "");
    text = strtrim(text);
    return text, cooldownText;
end

local function ReplacePureGreenText(text)
    return gsub(text, "cFF.0FF.0", "cFF00E700");
end


local function GetLineText(lines, index)
    if lines[index] and lines[index].args then
        return lines[index].args[2].stringVal;
    end
end

local function GetLineRightText(lines, index)
    if lines[index] and lines[index].args and lines[index].args[4] then
        return lines[index].args[4].stringVal;
    end
end

local function GetCraftingQualityFromText(text)
    --escape sequence: "|A:Professions-Icon-Quality-Tier1-Small:26:26:0:-1|a"
    local quality = match(text, "[Pp]rofessions%-[Ii]con%-[Qq]uality%-[Tt]ier(%d)", 1);
    if quality then
        return tonumber(quality)
    end
end

local function ReformatCraftingQualityText(text, addTierTextToRight)
    local quality = match(text, "[Qq]uality%-[Tt]ier(%d)", 1);     --10.0.7: Changed to Professions-(Chat)Icon-Quality-Tier
    if quality then
        local tempText = gsub(text, "%s?|A[^|]+|a", "");
        if tempText then
            local color;
            quality = tonumber(quality);
            if quality == 1 then
                color = "|cffd8b093";
            elseif quality == 2 then
                color = "|cffbbbbbb";
            elseif quality == 3 then
                color = "|cffdeb630";
            elseif quality == 4 then
                color = "|cff50c7a6";
            elseif quality == 5 then
                color = "|cffffa04c";
            else
                color = "|cffffffff";
            end

            if addTierTextToRight then
                return tempText .."  "..color.."T"..quality.."|r", true
            else
                return color.."T"..quality.."|r  "..tempText, true
            end
        end
    end
    return text, quality ~= nil
end

local function CompleteColorString(str)
    --Fixes some unclosured color string (no |r at the end)
    --Not robust
    if str then
        if strsub(str, 1, 1) == "|" and strsub(str, -2, -2) ~= "|" then
            str = str .. "|r"
        end
    end

    return str
end

---- Advanced Tooltip Parser with callback ----
local TooltipUpdateFrame;
local IS_ITEM_CACHED = {};
local ON_TEXT_CHANGED_CALLBACK;
local PINNED_LINES, LAST_ITEM, LAST_TEXT;

local function OnTextChanged(object, text)
    print(object.lineIndex);
    print(text);
end

local function GetPinnedLineText()
    if PINNED_LINES and LAST_ITEM then
        local tooltipData;
        if type(LAST_ITEM) == "number" then
            tooltipData = GetInfoByItemID(LAST_ITEM);
        else
            tooltipData = GetInfoByHyperlink(LAST_ITEM);
        end
        if not tooltipData then return end;
    
        local lines = tooltipData.lines;
        local numLines = #lines;
        local lineText;
        local output;

        for i = 1, #PINNED_LINES do
            if PINNED_LINES[i] <= numLines then
                lineText = GetLineText(lines, PINNED_LINES[i]);
                if lineText and lineText ~= "" then
                    if output then
                        output = output.."\n"..lineText;
                    else
                        output = lineText;
                    end
                end
            end
        end
        if output ~= LAST_TEXT then
            LAST_TEXT = output;
            if ON_TEXT_CHANGED_CALLBACK then
                ON_TEXT_CHANGED_CALLBACK(output);
            end
            return true
        end
    end
end

local function TooltipUpdateFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.25 then
        self.t = 0;
        self.iteration = self.iteration + 1;
        if self.iteration >= 3 then
            self:SetScript("OnUpdate", nil);
        end
        GetPinnedLineText();
    end
end

local function GetCachedItemTooltipTextByLine(item, line, callbackFunc)
    if not TooltipUpdateFrame then
        TooltipUpdateFrame = CreateFrame("Frame");
    end

    ON_TEXT_CHANGED_CALLBACK = callbackFunc;

    local isCached;
    if IS_ITEM_CACHED[item] then
        isCached = true
    else
        IS_ITEM_CACHED[item] = true;
        isCached = false
    end

    local tooltipData;
    if type(item) == "number" then
        tooltipData = GetInfoByItemID(item);
    else
        tooltipData = GetInfoByHyperlink(item);
    end
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local lineText;

    if item ~= LAST_ITEM then
        LAST_ITEM = item;
        LAST_TEXT = nil;
        TooltipUpdateFrame.t = 0;
        TooltipUpdateFrame.iteration = 0;
        TooltipUpdateFrame:SetScript("OnUpdate", TooltipUpdateFrame_OnUpdate);
    end

    if isCached then
        if PINNED_LINES then
            PINNED_LINES = nil;
        end
    end


    if type(line) == "table" then
        local output;
        local _l;
        for i = 1, #line do
            _l = line[i];
            if _l <= numLines then
                lineText = GetLineText(lines, _l);
                if lineText and lineText ~= "" then
                    lineText = CompleteColorString(lineText);
                    if output then
                        output = output.."\n"..lineText;
                    else
                        output = lineText;
                    end
                end
            end
        end

        if not isCached then
            PINNED_LINES = line;
            LAST_TEXT = output;
        end

        return output, isCached or (output ~= nil);
    else
        if line <= numLines then
            lineText = RemoveColorString( GetLineText(lines, line) );
        end

        if not isCached then
            PINNED_LINES = {line};
            LAST_TEXT = lineText;
        end

        return lineText, isCached or (lineText ~= nil);
    end
end

NarciAPI.GetCachedItemTooltipTextByLine = GetCachedItemTooltipTextByLine;
-------------------------------------------------------------------



local function GetItemRankText(itemLink, statName)
    --Items that can get upgraded
    if not itemLink then return; end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local dataText = GetLineText(tooltipData.lines, 2);
    if not dataText then return end;

    local rank = match(dataText, "%d+", -2) or "";
    if not rank then return end;

    if statName then
        local stats = GetItemStats(itemLink) or {};
        return "|cff00ccff"..rank.."|r", stats[statName] or 0
    else
        return "|cff00ccff"..rank.."|r"
    end
end

NarciAPI.GetItemRankText = GetItemRankText;


local function GetItemTooltipTextByLine(item, lineIndex, keepColor)
    --It's possible that item description hasn't been cached yet
    --See TooltipParser.lua for more advanced functionalities
    local tooltipData;
    if type(item) == "number" then
        tooltipData = GetInfoByItemID(item);
    else
        tooltipData = GetInfoByHyperlink(item);
    end

    if tooltipData and tooltipData.lines then
        if keepColor then
            return GetLineText(tooltipData.lines, lineIndex)
        else
            return RemoveColorString( GetLineText(tooltipData.lines, lineIndex) );
        end
    end
end

NarciAPI.GetItemTooltipTextByLine = GetItemTooltipTextByLine;


local ITEM_ENCHANT_FORMAT = gsub(ENCHANTED_TOOLTIP_LINE, "%%s", "(.+)");

local function GetItemEnchantText(itemLink, colorized)
    if not itemLink then return; end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;

    if numLines < 5 then return end;

    local lineText;
    local enchantText;
    local enchantFormat = ITEM_ENCHANT_FORMAT;

    for i = 5, numLines do
        if lines[i][4] and lines[i][4].field == "enchantID" then
            lineText = GetLineText(lines, i);
            if lineText then
                enchantText = match(lineText, enchantFormat);
                if enchantText then
                    enchantText = strtrim(enchantText);
                    if enchantText ~= "" then
                        if colorized then
                            enchantText = "|cff5fbd6b"..enchantText.."|r";
                        end
                        enchantText = ReformatCraftingQualityText(enchantText);
                        return enchantText
                    end
                end
            end
            return
        else
            return
        end
    end
end

local function GetEnchantTextByEnchantID(enchantID)
    if enchantID then
        --local itemLink = "item:2092:"..enchantID;
        --return GetItemEnchantText(itemLink, false);
        local tooltipData = GetInfoByHyperlink("item:2092:"..enchantID);
        if not tooltipData then return nil, true end;

        local enchantText = GetLineText(tooltipData.lines, 8);  --DF:Moved to line #8
        if enchantText and enchantText ~= "" then
            --remove "Enchanted:"
            local effect = match(enchantText, ITEM_ENCHANT_FORMAT);
            if not effect then
                effect = enchantText;
            end

            effect = ReformatCraftingQualityText(effect);
            return effect, true
        else
            return nil, true
        end
    end
end

NarciAPI.GetItemEnchantText = GetItemEnchantText;
NarciAPI.GetEnchantTextByEnchantID = GetEnchantTextByEnchantID;


local function GetEnchantTextByItemLink(itemLink, colorized, isRight)
    if not itemLink then return end;

    local enchantID = match(itemLink, "item:%d+:(%d+):");

    if enchantID and enchantID ~= "" then
        local tooltipData = GetInfoByHyperlink("item:2092:"..enchantID);
        if not tooltipData then return nil, true end;

        local enchantText = GetLineText(tooltipData.lines, 8);
        if enchantText and enchantText ~= "" then
            --remove "Enchanted:"
            local effect = match(enchantText, ITEM_ENCHANT_FORMAT);
            if not effect then
                effect = enchantText;
            end
            if colorized then
                effect = "|cff5fbd6b"..effect.."|r";
            end
            effect = ReformatCraftingQualityText(effect, isRight);
            return effect, true
        else
            return nil, true
        end
    end
end

NarciAPI.GetEnchantTextByItemLink = GetEnchantTextByItemLink;


local TEMP_ENCHANT_FORMAT = "([^+].+) %((%d+%D+)%)";
local FORMAT_COLON = ":";
if TEXT_LOCALE == "zhCN" then
    FORMAT_COLON = "：";
    TEMP_ENCHANT_FORMAT = "([^+].+)（(%d+%D+)%）";
elseif TEXT_LOCALE == "zhTW" then
    FORMAT_COLON = "：";
    TEMP_ENCHANT_FORMAT = "([^+].+)%((%d+%D+)%)";
end

local function GetTemporaryItemBuff(location1, location2)
    if not location1 then return; end

    local tooltipData;
    if location2 then
        tooltipData = GetInfoByBagItem(location1, location2);
    else
        tooltipData = GetInfoByInventoryItem("player", location1, true);
    end
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local lineText;
    local buffText, durationText;
    for i = 5, numLines do
        lineText = GetLineText(lines, i);
        if lineText then
            if not match(lineText, FORMAT_COLON) then
                buffText, durationText = match(lineText, TEMP_ENCHANT_FORMAT);
                if buffText and durationText then
                    break
                end
            end
        end
    end

    --durationText: hours, hour, min, sec
    --/dump string.match("Reinforced (15 sec)", ".+ %((%d+) sec%)")
    return buffText, durationText
end

NarciAPI.GetTemporaryItemBuff = GetTemporaryItemBuff;


local function GetWeaponDamageAndSpeed(itemLink)
    if not itemLink then return; end
    local _, _, _, itemEquipLoc, _, classID, subclassID = GetItemInfoInstant(itemLink);
    if classID ~= 2 then
        return
    end
    itemEquipLoc = _G[itemEquipLoc];

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local lineText, leftText, rightText;

    for i = 3, numLines do
        lineText = GetLineText(lines, i);
        if lineText then
            if lineText == itemEquipLoc then
                local n = i + 1;
                leftText = GetLineText(lines, n);
                rightText = GetLineRightText(lines, n);
                return leftText, rightText
            end
        else
            return
        end
    end
end

NarciAPI.GetWeaponDamageAndSpeed = GetWeaponDamageAndSpeed;


local function GetItemFlavorText(itemLink)
    if not itemLink then return; end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local lineText, text;

    for i = numLines, numLines - 1, -1 do
        lineText = GetLineText(lines, i);
        if lineText then
            if match(lineText, "^[\"“]") then
                return text
            end
        else
            return
        end
    end
end

NarciAPI.GetItemFlavorText = GetItemFlavorText;



local function IsAppearanceKnown(itemLink)
    --Need to correspond with C_TransmogCollection.PlayerHasTransmog
    if not itemLink then return; end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local lineText;

    for i = numLines, numLines - 2, -1 do
        lineText = GetLineText(lines, i);
        if not lineText then
            return false;
        end
        if lineText == SOURCE_KNOWN or lineText == APPEARANCE_KNOWN then
            return true;
        elseif lineText == APPEARANCE_UNKNOWN then
            return false;
        end
    end

    return false;
end

NarciAPI.IsAppearanceKnown = IsAppearanceKnown;


local function GetItemExtraEffect(itemLink, checkBonus, keepFormat)
    if not itemLink then return; end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local fromLine = max(numLines - 6, 3);
    local output = "";
    local category, lineText;

    for i = fromLine, numLines, 1 do
        lineText = GetLineText(lines, i);
        if not lineText then
            break;
        end

        if find(lineText, ON_USE) then
            lineText = FormatString(lineText, NO_COMMA_ON_USE, keepFormat);
            if not category then    category = NO_COMMA_ON_USE; end
            output = output..lineText.."\n";
        elseif find(lineText, ON_EQUIP) then
            lineText = FormatString(lineText, NO_COMMA_ON_EQUIP, keepFormat);
            if not category then    category = NO_COMMA_ON_EQUIP; end
            output = output..lineText.."\n";
        elseif find(lineText, ON_PROC) then
            lineText = FormatString(lineText, NO_COMMA_ON_PROC, keepFormat);
            if not category then    category = NO_COMMA_ON_PROC; end
            output = output..lineText.."\n";
        elseif checkBonus then
            if find(lineText, ITEM_BONUS) then
                lineText = FormatString(lineText, NO_COMMA_SET_BONUS, keepFormat);
                if not category then    category = NO_COMMA_SET_BONUS; end
                output = output..lineText.."\n";
                break
            end
        end
    end

    return category, output;
end

NarciAPI.GetItemExtraEffect = GetItemExtraEffect;


local SpecialGemData = {
    --1 Movement Speed
    --2 Health Regen
    [173125] = 2,       --Revitalizing Jewel Doublet
    [173126] = 1,       --Straddling Jewel Doublet
    [25893] = 3,        --Meta Chance to Increase Spell Cast Speed
    [32410] = 4,        --Meta Chance to Increase Melee/Ranged Attack Speed
};

local GEM_BONUS_CACHE = {};

local function GetGemBonusFromGem(gem)
    --gem: Gem's itemID or hyperlink
    if not gem then return; end

    if GEM_BONUS_CACHE[gem] then
        return GEM_BONUS_CACHE[gem][1], GEM_BONUS_CACHE[gem][2]
    end

    local tooltipData;
    local itemID;
    if type(gem) == "number" then
        tooltipData = GetInfoByItemID(gem);
        itemID = gem;
    else
        tooltipData = GetInfoByHyperlink(gem);
        itemID = GetItemInfoInstant(gem);
    end

    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local bonusText;
    local lineText;
    local requiredItemLevel = 0;

    local bonusID = SpecialGemData[itemID];
    if bonusID then
        if bonusID == 1 then
            bonusText = STAT_MOVEMENT_SPEED;
        elseif bonusID == 2 then
            bonusText = ITEM_MOD_HEALTH_REGENERATION_SHORT;
        elseif bonusID == 3 then
            bonusText = GetSpellInfo(32837);
        elseif bonusID == 4 then
            bonusText = STAT_ATTACK_SPEED;
        end
    end

    for i = 2, numLines do
        lineText = GetLineText(lines, i);
        if not lineText then
            return;
        end

        if not bonusText then
            if strsub(lineText, 1, 1) == "+" then
                bonusText = lineText;
            elseif find(lineText, ON_EQUIP) then
                bonusText = FormatString(lineText, NO_COMMA_ON_EQUIP);
            end
        end

        if find(lineText, GEM_MIN_LEVEL) then
            requiredItemLevel = FormatString(lineText, GEM_MIN_LEVEL);
        end

        if requiredItemLevel and bonusText then break end;
    end

    requiredItemLevel = tonumber(requiredItemLevel);

    if bonusText then
        bonusText = ReformatCraftingQualityText(bonusText);
        GEM_BONUS_CACHE[gem] = {bonusText, requiredItemLevel};
    end

    return bonusText, requiredItemLevel;
end

NarciAPI.GetGemBonus = GetGemBonusFromGem;


local function GetItemEquipEffect(itemLink)
    if not itemLink then return; end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local fromLine = max(numLines - 4, 0);
    local lineText;
    local effects, effectType, effectText, cooldownText;
    local numEffects;

    for i = fromLine, numLines do
        lineText = GetLineText(lines, i);
        if not lineText then
            break;
        end
        effectType = nil;
        effectText = nil;
        cooldownText = nil;
        if find(lineText, ON_USE) then
            effectText, cooldownText = TrimCooldownText( strtrim(lineText, NO_COMMA_ON_USE) );
            effectType = "use";
        elseif find(lineText, ON_EQUIP) then
            effectText = RemoveColorString(lineText);
            effectType = "equip";
        elseif find(lineText, ON_PROC) then
            effectText = lineText;
            effectType = "proc";
        elseif find(lineText, ITEM_BONUS) then
            effectText = lineText;
            effectType = "set";
        end
        if effectType then
            if not effects then
                effects = {};
                numEffects = 0;
            end
            numEffects = numEffects + 1;
            effects[numEffects] = {effectType, effectText, cooldownText};
        end
    end
    return effects, numEffects;
end

NarciAPI.GetItemEquipEffect = GetItemEquipEffect;


local function GetItemUpgradeLevel(itemLink)
    if not itemLink then return; end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;
    local lineText;
    local currentLevel, maxLevel;
    for i = 2, 3 do
        lineText = GetLineText(lines, i);
        if lineText then
            currentLevel, maxLevel = match(lineText, PATTERN_UPGRADE_LEVEL);
            if maxLevel then
                return currentLevel, maxLevel
            end
        else
            break
        end
    end
end

NarciAPI.GetItemUpgradeLevel = GetItemUpgradeLevel;


local function GetCompleteItemData(tooltipData, itemLink)
    --return a table of data obtained by scanning tooltip
    --upgrade level (current/max), equipmentEffects(onEquip, onUse, onProc, bonus), socket info(socket1, socket2, socket3), enchant
    --reset socket textures
    if not (tooltipData and itemLink) then return end;

    itemLink = FormatItemLink(itemLink);

    local _, _, _, itemEquipLoc, _, classID, subclassID = GetItemInfoInstant(itemLink);
    local matchWeapon;
    if classID == 2 then
        --Find Weapon damage and attack speed by matching the texts below equip location
        itemEquipLoc = _G[itemEquipLoc];
        matchWeapon = true;
    end

    local processed = {};   --process each line once
    local lines = tooltipData.lines;
    local numLines = #lines;
    local lineText;
    local match1, match2;
    local enchantText;
    local effectText, effectType, numEffects, isActive, cooldownText;
    local data, anyMatch;
    local socketOrderID = 0;
    local qualityFound;
    local requestSubData;

    for i = 2, numLines do
        if not processed[i] then
            lineText = GetLineText(lines, i);
            if lineText then
                anyMatch = nil;
                if i == 2 then
                    --the second line is usually item level
                    --or a special item category: difficuty, Cypher Equipment
                    if not match(lineText, "%d$") then
                        if not data then
                            data = {};
                        end
                        data.context = ReplacePureGreenText(lineText);
                        anyMatch = true;
                    end
                else
                    if i < 5 and not match2 then
                        --upgrade level
                        match1, match2 = match(lineText, PATTERN_UPGRADE_LEVEL);
                        if match2 then
                            if not data then
                                data = {};
                            end
                            data.upgradeLevel = {match1, match2};
                            anyMatch = true;
                        end
                    end
                end

                if i >= 4 and not anyMatch then
                    --effects
                    if find(lineText, ON_USE) then
                        effectText, cooldownText = TrimCooldownText( strtrim(lineText, NO_COMMA_ON_USE) );
                        effectType = "use";
                    elseif find(lineText, ON_EQUIP) then
                        effectText = RemoveColorString(lineText);
                        effectType = "equip";
                    elseif find(lineText, ON_PROC) then
                        effectText = lineText;
                        effectType = "proc";
                    elseif find(lineText, ITEM_BONUS) or find(lineText, SOCKET_BONUS) then
                        effectText = lineText;
                        effectType = "set";
                    elseif matchWeapon then
                        if lineText == itemEquipLoc then
                            matchWeapon = nil;
                            local leftText;
                            local rightText = GetLineRightText(lines, i);
                            if rightText then
                                if not data then
                                    data = {};
                                end
                                data.itemType = rightText;
                            end
                            local n = i + 1;
                            
                            leftText = GetLineText(lines, n);
                            rightText = GetLineRightText(lines, n);
                            if leftText and rightText then
                                if not data then
                                    data = {};
                                end
                                data.weaponInfo = {leftText, rightText};
                                anyMatch = true;
                            end
                        end
                    else
                        --enchant
                        if not enchantText then
                            enchantText = match(lineText, ITEM_ENCHANT_FORMAT);
                            if enchantText then
                                enchantText = strtrim(enchantText);
                                if enchantText ~= "" then
                                    if not data then
                                        data = {};
                                    end
                                    enchantText = ReformatCraftingQualityText(enchantText, true);
                                    data.enchant = enchantText;
                                    anyMatch = true;
                                end
                            end
                        end
                    end

                    if effectType then
                        if not data then
                            data = {};
                        end
                        if not data.effects then
                            data.effects = {};
                            numEffects = 0;
                        end
                        isActive = not (IsTextColorRed(lines[i].args[3].colorVal) or IsTextColor50Grey(lines[i].args[3].colorVal));
                        numEffects = numEffects + 1;
                        data.effects[numEffects] = {effectType, effectText, isActive, cooldownText};
                        effectType = nil;
                        effectText = nil;
                        cooldownText = nil;
                        isActive = nil;
                        anyMatch = true;
                    end

                    if not anyMatch then
                        --socket
                        if lines[i].args[4] and (lines[i].args[4].field == "socketType" or lines[i].args[4].field == "gemIcon") then
                            if not data then
                                data = {};
                            end
                            if not data.socketInfo then
                                data.socketInfo = {};
                            end
                            local socketType = lines[i].args[4].stringVal;
                            local icon, gemName, gemLink, gemEffect;
                            if lines[i].args[4].field == "gemIcon" then
                                icon = lines[i].args[4].intVal;
                            end
                            socketOrderID = socketOrderID + 1;
                            gemName, gemLink = GetItemGem(itemLink, socketOrderID);
                            if gemLink then --has a gem
                                if not icon then
                                    icon = select(5, GetItemInfoInstant(gemLink));
                                end

                                local isCraftedItem;

                                gemEffect = lines[i].args[2].stringVal;
                                gemEffect = RemoveColorString(gemEffect);
                                gemEffect, isCraftedItem = ReformatCraftingQualityText(gemEffect, true);

                                if not isCraftedItem then
                                    local bonusTextFromItem = GetGemBonusFromGem(gemLink);
                                    if bonusTextFromItem and gemEffect then
                                        if bonusTextFromItem ~= gemEffect then
                                            gemEffect = CompleteColorString(gemEffect)
                                            gemEffect = gemEffect.."\n"..bonusTextFromItem;
                                        end
                                    end
                                end

                                if not requestSubData then
                                    if (not gemName or gemName == "") or (not gemEffect and gemEffect == "") then
                                        requestSubData = true;
                                    end
                                end
                            else
                                local textureKit = SOCKET_TYPE_TEXTURE[socketType] or "Prismatic";
                                icon = "Interface\\ItemSocketingFrame\\UI-EmptySocket-"..textureKit;
                                gemName = lines[i].args[2].stringVal;   --Empty X Socket
                                gemEffect = gemName;
                            end
                            data.socketInfo[socketOrderID] = {icon, gemName, gemLink, gemEffect};
                        end
                    end
                end
                if i >= numLines - 2 and not anyMatch then
                    --flavor texts, class restrictions
                    match1 = match(lineText, PATTERN_CLASS_REQUIREMENT);
                    if match1 then
                        isActive = IsTextColorWhite(lines[i].args[3].colorVal);
                        if not data then
                            data = {};
                        end
                        data.classesAllowed = {match1, isActive};
                        anyMatch = true;
                    elseif match(lineText, "^[\"“]") then
                        if not data then
                            data = {};
                        end
                        data.flavorText = lineText;
                        anyMatch = true;
                    end
                end
                --print(i.." "..tostring(anyMatch).." "..lineText)
                if i > 8 and not anyMatch then
                    if not qualityFound then
                        match1 = match(lineText, PATTERN_PROFESSION_QUALITY);
                        if match1 then
                            PP = match1
                            qualityFound = true;
                            anyMatch = true;
                            if not data then
                                data = {};
                            end
                            data.craftingQuality = GetCraftingQualityFromText(match1);
                        end
                    end

                    --match item sets
                    if not anyMatch then
                        match1, match2, _ = match(lineText, PATTERN_ITEM_SET_NAME);    --string.match("Test Set (1/9)", PATTERN_ITEM_SET_NAME)
                        if match1 and match2 and _ then
                            --found setName, numOwned, total
                            if not data then
                                data = {};
                            end
                            if not data.itemSet then
                                data.itemSet = {};
                                data.itemSet.itemNames = {};
                                data.itemSet.bonuses = {};
                            end
                            anyMatch = true;
                            local total = tonumber(_);
                            data.itemSet.rawName = lineText;
                            data.itemSet.name = match1;
                            data.itemSet.numOwned = tonumber(match2);
                            data.itemSet.total = total;

                            for j = 1 + i, total + i do
                                lineText = GetLineText(lines, j);
                                if lineText then
                                    isActive = not IsTextColor50Grey(lines[j].args[3].colorVal);
                                    --print(fontString:GetTextColor());
                                    tinsert(data.itemSet.itemNames, {lineText, isActive});
                                    processed[j] = true;
                                else
                                    break
                                end
                            end
                            for j = i + total + 2, numLines do
                                lineText = GetLineText(lines, j);
                                if lineText then
                                    if find(lineText, SET_BONUS, 1) then
                                        --found set bonus
                                        isActive = not IsTextColor50Grey(lines[j].args[3].colorVal);
                                        tinsert(data.itemSet.bonuses, {lineText, isActive});
                                        processed[j] = true;
                                    end
                                else
                                    break
                                end
                            end
                        end
                    end
                end
            else
                break
            end
        end
    end

    return data, requestSubData
end

local function ClearTooltipTexture()
    local tex;
    for i = 1, 3 do
        tex = _G["NarciVirtualTooltipTexture"..i];
        if tex then
            tex = tex:SetTexture(nil);
        else
            break
        end
    end
end

local function GetCompleteItemDataFromSlot(slotID, itemLink)
    local tooltipData = GetInfoByInventoryItem("player", slotID, true);
    if not itemLink then
        itemLink = GetInventoryItemLink("player", slotID);
    end
    return GetCompleteItemData(tooltipData, itemLink);
end

local function GetCompleteItemDataByItemLink(itemLink)
    if not itemLink then return end
    local tooltipData = GetInfoByHyperlink(itemLink);
    return GetCompleteItemData(tooltipData, itemLink);
end

local function GetCompleteItemDataFromGameTooltip()
    --for debug
    return
end

NarciAPI.GetCompleteItemDataFromSlot = GetCompleteItemDataFromSlot;
NarciAPI.GetCompleteItemDataByItemLink = GetCompleteItemDataByItemLink;
NarciAPI.GetCompleteItemDataFromGameTooltip = GetCompleteItemDataFromGameTooltip;


--[[
EMPTY_SOCKET_BLUE = "Blue Socket"; 136256
EMPTY_SOCKET_COGWHEEL = "Cogwheel Socket"; 407324
EMPTY_SOCKET_CYPHER = "Crystallic Socket"; ???
EMPTY_SOCKET_DOMINATION = "Domination Socket"; 4095404
EMPTY_SOCKET_HYDRAULIC = "Sha-Touched"; 407325
EMPTY_SOCKET_META = "Meta Socket"; 136257
EMPTY_SOCKET_NO_COLOR = "Prismatic Socket"; 458977
EMPTY_SOCKET_PRISMATIC = "Prismatic Socket"; 458977
EMPTY_SOCKET_PUNCHCARDBLUE = "Blue Punchcard Socket"; 2958629
EMPTY_SOCKET_PUNCHCARDRED = "Red Punchcard Socket"; 2958630
EMPTY_SOCKET_PUNCHCARDYELLOW = "Yellow Punchcard Socket"; 2958631
EMPTY_SOCKET_RED = "Red Socket"; 136258
EMPTY_SOCKET_YELLOW = "Yellow Socket"; 136259
EMPTY_SOCKET_CYPHER = "Crystallic Socket"

RELIC_TOOLTIP_TYPE
--]]

--[[
local SocketTypes = {
    --tooltip emtpy socket texture fileID
    [136256] = "BLUE",
    [136258] = "RED",
    [136259] = "YELLOW",
    [407324] = "COGWHEEL",
    [4095404] = "DOMINATION",
    [407325] = "HYDRAULIC",
    [136257] = "CYPHER",    --was META
    [458977] = "PRISMATIC",
    [2958629] = "PUNCHCARDBLUE",
    [2958630] = "PUNCHCARDRED",
    [2958631] = "PUNCHCARDYELLOW",
};
--]]

local IsSupportedSocket = {};

do
    local postfixes = {
        "BLUE", "COGWHEEL", "HYDRAULIC", "META", "PRISMATIC", "PUNCHCARDBLUE", "PUNCHCARDRED", "PUNCHCARDYELLOW",
        "RED", "TINKER", "YELLOW", "PRIMORDIAL",
    };

    for _, name in pairs(postfixes) do
        IsSupportedSocket[name] = true;
    end
end


local function IsItemSocketable(itemLink, socketID)
    if not itemLink then return; end

    local gemName, gemLink = GetItemGem(itemLink, socketID or 1)
    if gemLink then
        if not IsArtifactRelic(gemLink) then
            return gemName or "...", gemLink;
        end
        return
    end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local lines = tooltipData.lines;
    local numLines = #lines;

    for i = 4, numLines do     --max 10
        if lines[i].args and lines[i].args[4] and lines[i].args[4].field == "socketType" then
            return lines[i].args[4].field, nil
        end
    end

    return nil, nil;
end
NarciAPI.IsItemSocketable = IsItemSocketable;



--[[
    --Interface / SharedXML / Tooltip / TooltipDataRules.lua

    function TooltipDataRules.GemSocket(tooltip, lineData)
		local asset;
		local gemIcon = lineData.gemIcon;
		if gemIcon then
			asset = gemIcon;
		else
			local socketType = lineData.socketType;
			if socketType then
				asset = string.format("Interface\\ItemSocketingFrame\\UI-EmptySocket-%s", socketType);
			end
		end
		if asset then
			tooltip:AddTexture(asset);
		end
	end
--]]

local function GetItemSocketInfo(itemLink)
    --gemData = { {socketType, icon, gemLink(nillable) } }

    if not itemLink then return end

    local tooltipData = GetInfoByHyperlink(itemLink);
    if not tooltipData then return end;

    local icon;
    local gemName, gemLink, socketType, socketName;
    local socektInfo;
    local gemOrderID = 0;

    for i = 1, 3 do
        gemName, gemLink = GetItemGem(itemLink, i);
        if gemLink then
            if not socektInfo then
                socektInfo = {};
            end
            gemOrderID = i;
            icon = select(5, GetItemInfoInstant(gemLink));
            socektInfo[gemOrderID] = {gemName, icon, gemLink};
        end
    end

    local lines = tooltipData.lines;
    local numLines = #lines;
    local field;

    gemOrderID = 0;

    for i = 4, numLines do     --max 10
        if lines[i].args and lines[i].args[4] then
            field = lines[i].args[4].field;
            if field and field == "socketType" or field == "gemIcon" then
                gemOrderID = gemOrderID + 1;
                if not socektInfo then
                    socektInfo = {};
                end
                socketType = lines[i].args[4].stringVal;
                if not socektInfo[gemOrderID] then
                    socketName = lines[i].args[2].stringVal;
                    socektInfo[gemOrderID] = {socketName, "Interface\\ItemSocketingFrame\\UI-EmptySocket-"..socketType, nil, socketType};
                else
                    socektInfo[gemOrderID][4] = socketType;
                end
            end
        end
    end

    return socektInfo
end

NarciAPI.GetItemSocketInfo = GetItemSocketInfo;


local function DoesItemHaveSockets(itemLink)
    --determine if item really have sockets instead of relics
    --can't determine socket order so:
    --If the item have two or more types of socket, use ItemSocketingFrame-GetSocketTypes to get socket order

    if not itemLink then return end

    local stats = GetItemStats(itemLink);

    if stats then
        local numSocket = 0;
        local subType, lastType;
        local socketIsDiverse;

        for name, count in pairs(stats) do
            subType = match(name, "^EMPTY_SOCKET_(%a+)");
            if IsSupportedSocket[subType] then
                numSocket = numSocket + count;
                if lastType then
                    socketIsDiverse = socketIsDiverse or (subType ~= lastType);
                else
                    lastType = subType;
                end
            end
        end

        if numSocket > 0 then
            return numSocket, socketIsDiverse, lastType
        end
    end
end

NarciAPI.DoesItemHaveSockets = DoesItemHaveSockets;

--[[
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    local _, itemLink = self:GetItem();
    DoesItemHaveSockets(itemLink);
end);
--]]

local function GetAmmoDps(itemID)
    if not itemID then return end;
    return 0
end

NarciAPI.GetAmmoDps = GetAmmoDps;



local function FormatSpellData(tooltipData, fromLine)
    local lines = tooltipData.lines;
    local numLines = #lines;
    local leftText, rightText;
    local anyMatch;
    local data = {};
    local rangeText, castText, cdText, costText, replaceSpell;
    local isPassive;
    fromLine = fromLine or 1;
    local first2Lines = fromLine + 1;

    --castText: instant, x sec cast, channel
    --cdText: cooldown or recharge time
    for i = fromLine, numLines do
        anyMatch = false;
        leftText = GetLineText(lines, i);
        rightText = GetLineRightText(lines, i);

        if i <= first2Lines then
            if leftText then
                if not rangeText then
                    if find(leftText, TEXT_SPELL_RANGE) or find(leftText, TEXT_SPELL_RANGE_MELEE) or find(leftText, TEXT_SPELL_RANGE_UNLIMITED) then
                        anyMatch = true;
                        rangeText = leftText;
                        data.rangeText = rangeText;
                    end
                end

                if not anyMatch and not castText then
                    if find(leftText, TEXT_SPELL_PASSIVE) then
                        isPassive = true;
                        anyMatch = true;
                        castText = leftText;
                        data.castText = castText;
                    elseif find(leftText, TEXT_SPELL_CAST_TIME_INSTANT) or find(leftText, TEXT_SPELL_CAST_TIME_SEC) or find(leftText, TEXT_SPELL_CAST_CHANNELED) then
                        anyMatch = true;
                        castText = leftText;
                        data.castText = castText;
                    end
                end

                if not anyMatch and not isPassive and not cdText then
                    if find(leftText, TEXT_SPELL_COOLDOWN) or find(leftText, TEXT_SPELL_RECHARGE) then
                        anyMatch = true;
                        cdText = leftText;
                        data.cdText = cdText;
                    end
                end

                if not anyMatch and find(leftText, "%d") then
                    anyMatch = true;
                    costText = gsub(leftText, "\n", " ");   --!Druid: Energy + ComboPoint
                    data.costText = costText;
                end

                if not anyMatch and find(leftText, TEXT_REPLACES_SPELL) then
                    anyMatch = true;
                    replaceSpell = leftText;
                    data.replaceSpell = replaceSpell;
                end
            end

            if rightText and not anyMatch then
                if not rangeText then
                    if find(rightText, TEXT_SPELL_RANGE) or find(rightText, TEXT_SPELL_RANGE_MELEE) or find(rightText, TEXT_SPELL_RANGE_UNLIMITED) then
                        anyMatch = true;
                        rangeText = rightText;
                        data.rangeText = rangeText;
                    end
                end

                if not anyMatch and not castText then
                    if find(rightText, TEXT_SPELL_PASSIVE) then
                        isPassive = true;
                        anyMatch = true;
                        castText = rightText;
                        data.castText = castText;
                    elseif find(rightText, TEXT_SPELL_CAST_TIME_INSTANT) or find(rightText, TEXT_SPELL_CAST_TIME_SEC) or find(rightText, TEXT_SPELL_CAST_CHANNELED) then
                        anyMatch = true;
                        castText = rightText;
                        data.castText = castText;
                    end
                end

                if not anyMatch and not isPassive and not cdText then
                    if find(rightText, TEXT_SPELL_COOLDOWN) or find(rightText, TEXT_SPELL_RECHARGE) then
                        anyMatch = true;
                        cdText = rightText;
                        data.cdText = cdText;
                    end
                end
            end
        end

        if not anyMatch then
            if leftText then
                leftText = strtrim(leftText);
                if leftText ~= "" then
                    if not data.descriptions then
                        data.descriptions = {};
                    end
                    tinsert(data.descriptions, leftText);
                end
            end
        end
    end

    return data
end

local function GetTraitEntryTooltip(entryID, rank)
    if not (entryID and rank) then return end;

    local tooltipData = C_TooltipInfo.GetTraitEntry(entryID, rank);
    if not tooltipData then return end;

    return FormatSpellData(tooltipData)
end

NarciAPI.GetTraitEntryTooltip = GetTraitEntryTooltip;


local function GetPvpTalentTooltip(talentID, isInspecting, specGroupIndex, slotIndex)
    if not (talentID and specGroupIndex and slotIndex) then return end;

    local tooltipData = C_TooltipInfo.GetPvpTalent(talentID, isInspecting, specGroupIndex, slotIndex);
    if not tooltipData then return end;

    return FormatSpellData(tooltipData, 2)
end

NarciAPI.GetPvpTalentTooltip = GetPvpTalentTooltip;


local function GetBagItemSubText(bag, slot)
    if not (bag and slot) then return end;

    local tooltipData = GetInfoByBagItem(bag, slot);
    if tooltipData then
        return GetLineText(tooltipData.lines, 2) or ""
    end
end

NarciAPI.GetBagItemSubText = GetBagItemSubText;


local function GetCreatureName(creatureID)
    if not creatureID then return end;
    local tooltipData = GetInfoByHyperlink("unit:Creature-0-0-0-0-"..creatureID);
    if tooltipData then
        return GetLineText(tooltipData.lines, 1);
    end
end

NarciAPI.GetCreatureName = GetCreatureName;

local function GetDominationShardEffect(item)
    if not item then return end;

    local tooltipData;
    if type(item) == "number" then
        tooltipData = GetInfoByItemID(item);
    else
        tooltipData = GetInfoByHyperlink(item);
    end

    if tooltipData then
        return GetLineText(tooltipData.lines, 5);
    end
end

NarciAPI.GetDominationShardEffect = GetDominationShardEffect;

local function SurfaceItemArgs(item)
    if not item then return end;

    local tooltipData;
    if type(item) == "number" then
        tooltipData = GetInfoByItemID(item);
    else
        tooltipData = GetInfoByHyperlink(item);
    end

    if not tooltipData then return end;

    local surfaceArgs = {};

    for i, lineData in ipairs(tooltipData.lines) do
        surfaceArgs[i] = {};
        for j, arg in ipairs(lineData.args) do
		    surfaceArgs[i][arg.field] = arg.stringVal or arg.intVal or arg.floatVal or arg.boolVal or arg.colorVal or arg.guidVal;
        end
	end

    return surfaceArgs
end

local ITEM_REQUIREMENT_INCLUDE_LINES = {
    [21] = true,    --Enum.TooltipDataLineType.RestrictedRaceClass
    [22] = true,    --Enum.TooltipDataLineType.RestrictedFaction
    [23] = true,    --Enum.TooltipDataLineType.RestrictedSkill
    [24] = true,    --Enum.TooltipDataLineType.RestrictedPvPMedal
    [25] = true,    --Enum.TooltipDataLineType.RestrictedReputation
    --[26] = true,      --Enum.TooltipDataLineType.RestrictedSpellKnown Already Known
    [27] = true,    --Enum.TooltipDataLineType.RestrictedLevel
    [28] = true,    --Enum.TooltipDataLineType.EquipSlot
};


local function GetItemRequirement(item)
    local surfaceArgs = SurfaceItemArgs(item);

    if surfaceArgs then
        local data = {};
        local index = 0;
        local leftText, rightText;
        local lineTypeEquipSlot = 28;   --Enum.TooltipDataLineType.EquipSlot

        for i, arg in ipairs(surfaceArgs) do
            if ITEM_REQUIREMENT_INCLUDE_LINES[arg.type] then
                leftText = arg.leftText;
                if leftText then
                    --print(arg.type, leftText)
                    rightText = arg.rightText;
                    if arg.type == lineTypeEquipSlot and ( not (arg.isValidInvSlot and arg.isValidItemType) ) and rightText then
                        leftText = "|cffff2121"..leftText.."|r";
                        rightText = "|cffff2121"..rightText.."|r";
                    else
                        if arg.leftColor then
                            leftText = arg.leftColor:WrapTextInColorCode(leftText);
                        end

                        if rightText and arg.rightColor then
                            rightText = arg.leftColor:WrapTextInColorCode(rightText);
                        end
                    end

                    if rightText then
                        leftText = leftText .. " " .. rightText;
                    end

                    index = index + 1;
                    data[index] = leftText;
                end
            end
        end

        return data
    end
end

NarciAPI.GetItemRequirement = GetItemRequirement;



local PrimordialStoneNames = {};

local function GetColorizedPrimordialStoneName(itemID)
    --From PTR: color format |C0040C040Storm Infused Stone  --|C00?  No closure |r?
    if PrimordialStoneNames[itemID] then
        return PrimordialStoneNames[itemID]
    end

    local name = GetItemTooltipTextByLine(itemID, 6, true);

    if name and name ~= "" then
        PrimordialStoneNames[itemID] = name;
    else
        name = GetItemInfo(itemID);
    end

    return name
end

NarciAPI.GetColorizedPrimordialStoneName = GetColorizedPrimordialStoneName;

--[[
function Professions.GetIconForQuality(quality, small)
    if small then
        return ("Professions-Icon-Quality-Tier%d-Small"):format(quality);
    end
    return ("Professions-Icon-Quality-Tier%d"):format(quality);
end

function TestSetProfessionQuality(quality, small)
    if not TT then
        local f = CreateFrame("Frame");
        TT = f:CreateTexture();
        TT:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    end

    local atlas;
    if small then
        atlas = ("Professions-Icon-Quality-Tier%d-Small"):format(quality);
    else
        atlas = ("Professions-Icon-Quality-Tier%d"):format(quality);
    end
    
    TT:SetAtlas(atlas, true);
end
--]]