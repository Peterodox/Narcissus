----Pre Dragonflight----

local _, addon = ...
if addon.GetTooltipInfoVersion() ~= 0 then
    return
end

local strtrim = strtrim;
local gsub = string.gsub;
local match = string.match;
local find = string.find;
local format = string.format;
local split = string.split;

local tinsert = table.insert;

local floor = math.floor;
local max = math.max;

local _G = _G;
local L = Narci.L;
local TEXT_LOCALE = GetLocale();

local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetItemGem = C_Item.GetItemGem;
local GetItemStats = C_Item.GetItemStats;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;

local function IsArtifactRelic(item)
    --an alternative to IsArtifactRelicItem()
    local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(item);
    return classID == 3 and subclassID == 11
end

--[[
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

local function IsTextColorColor(fontstring, r, g, b)
    local textR, textG, textB = fontstring:GetTextColor();
    return (RoundColor(textR) == r) and (RoundColor(textG) == g) and (RoundColor(textB) == b)
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
local ITEM_BONUS = Narci.L["Item Bonus"];   --Bonus: (used by Domination Shard)     --ITEM_SOCKET_BONUS
local NO_COMMA_ON_USE = TrimColon(ON_USE);
local NO_COMMA_ON_EQUIP = TrimColon(ON_EQUIP);
local NO_COMMA_ON_PROC = TrimColon(ON_PROC);
local NO_COMMA_SET_BONUS = TrimColon(ITEM_BONUS);
local GEM_MIN_LEVEL = SOCKETING_ITEM_MIN_LEVEL_I;
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

local SET_BONUS = TrimWhiteSpace(ITEM_SET_BONUS);          --"Set: %s"     --SET_BONUS_GRAY
local SOCKET_BONUS = TrimWhiteSpace(ITEM_SOCKET_BONUS);    --Socket Bonus: %s

local PATTERN_COOLDOWN_TIME = "%((%d.+) Cooldown%)$";
local PATTERN_UPGRADE_LEVEL = gsub(ITEM_UPGRADE_TOOLTIP_FORMAT, "%%d+", "(%%d+)");
local PATTERN_ITEM_SET_NAME = "(.+) %((%d+)/(%d+)%)";   --Pattern_WrapNumber( Pattern_WrapSpace( Pattern_WrapBrace( ITEM_SET_NAME) ) );
local PATTERN_CLASS_REQUIREMENT = Pattern_WrapSpace(ITEM_CLASSES_ALLOWED);
local PATTERN_AMMO_DPS = gsub(AMMO_DAMAGE_TEMPLATE, "%%s", "([%%d.]+)");

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
        return gsub(str, "|[cC][fF][fF]%w%w%w%w%w%w(.*)|[rR]", "%1")
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

---- Advanced UtilityTooltip Parser with callback ----
local UtilityTooltip;
local UTIL_TOOLTIP_NAME = "NarciUtilityTooltip";
local IS_ITEM_CACHED = {};
local IS_LINE_HOOKED = {};

local pinnedObjects, lastItem, lastText, onTextChangedCallback;

local function OnTextChanged(object, text)
    print(object.lineIndex);
    print(text);
end

local function SetTooltipItem(item)
    if not item then return end;

    if type(item) == "number" then
        UtilityTooltip:SetItemByID(item);
    else
        UtilityTooltip:SetHyperlink(item);
    end

    if IS_ITEM_CACHED[item] then
        return true
    else
        IS_ITEM_CACHED[item] = true;
        return false
    end
end

local function GetPinnedLineText()
    if pinnedObjects then
        local output;
        local text;
        for i = 1, #pinnedObjects do
            text = pinnedObjects[i]:GetText() or "";
            text = strtrim(text);
            if text and text ~= "" then
                if output then
                    output = output.."\n"..text;
                else
                    output = text;
                end
            end
        end
        if output ~= lastText then
            lastText = output;
            if onTextChangedCallback then
                onTextChangedCallback(output);
            end
            return true
        end
    end
end

local function Tooltip_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.25 then
        self.t = 0;
        self.iteration = self.iteration + 1;
        if self.iteration > 3 then
            self:SetScript("OnUpdate", nil);
        end
        SetTooltipItem(lastItem);
        GetPinnedLineText()
    end
end

local function GetCachedItemTooltipTextByLine(item, line, callbackFunc)
    if not UtilityTooltip then
        UtilityTooltip = CreateFrame("GameTooltip", UTIL_TOOLTIP_NAME, nil, "GameTooltipTemplate");
        UtilityTooltip:SetOwner(UIParent, "ANCHOR_NONE");
        UtilityTooltip:SetScript("OnTooltipAddMoney", nil);
        UtilityTooltip:SetScript("OnTooltipCleared", nil);
    end

    onTextChangedCallback = callbackFunc;
    local isCached = SetTooltipItem(item);

    if item ~= lastItem then
        lastItem = item;
        lastText = nil;
        UtilityTooltip.t = 0;
        UtilityTooltip.iteration = 0;
        UtilityTooltip:SetScript("OnUpdate", Tooltip_OnUpdate);
    end

    local object;
    local text;

    if pinnedObjects then
        wipe(pinnedObjects);
    else
        pinnedObjects = {};
    end
    if type(line) == "table" then
        local output;
        local _l;
        for i = 1, #line do
            _l = line[i];
            object = _G[UTIL_TOOLTIP_NAME.."TextLeft".._l];
            if object then
                tinsert(pinnedObjects, object);
                if not IS_LINE_HOOKED[_l] then
                    IS_LINE_HOOKED[_l] = true;
                    object.lineIndex = _l;
                end
                text = object:GetText() or "";
                text = strtrim(text);
                if text and text ~= "" then
                    if output then
                        output = output.."\n"..text;
                    else
                        output = text;
                    end
                end
            end
        end
        return output, isCached
    else
        object = _G[UTIL_TOOLTIP_NAME.."TextLeft"..line];
        pinnedObjects = {object};
        if object then
            if not IS_LINE_HOOKED[line] then
                IS_LINE_HOOKED[line] = true;
                object.lineIndex = line;
            end
            text = object:GetText();
        end
        return text, isCached
    end
end

NarciAPI.GetCachedItemTooltipTextByLine = GetCachedItemTooltipTextByLine;
-------------------------------------------------------------------



----Generic UtilityTooltip Scan----

local TP = CreateFrame("GameTooltip", "NarciVirtualTooltip", nil, "GameTooltipTemplate");
TP:SetOwner(UIParent, 'ANCHOR_NONE');
TP:SetScript("OnTooltipAddMoney", nil);
TP:SetScript("OnTooltipCleared", nil);

--TP:SetPoint("TOP", UIParent, "TOP", 0, 0)
local LEFT_FONT_STRINGS = {
    TP.TextLeft1, TP.TextLeft2
};


local function GetItemRankText(itemLink, statName)
    --Items that can get upgraded
    if not itemLink then return; end

    TP:SetHyperlink(itemLink);
    local fontstring = _G["NarciVirtualTooltip".."TextLeft"..2];
    fontstring = fontstring:GetText() or "";
    fontstring = strtrim(fontstring, "|r");
    local rank = match(fontstring, "%d+", -2) or "";

    if statName then
        local stats = GetItemStats(itemLink) or {};
        return "|cff00ccff"..rank.."|r", stats[statName] or 0
    else
        return "|cff00ccff"..rank.."|r"
    end
end

NarciAPI.GetItemRankText = GetItemRankText;


local function GetItemTooltipTextByLine(item, line, keepColor)
    --It's possible that item description hasn't been cached yet
    --See TooltipParser.lua for more advanced functionalities
    if type(item) == "number" then
        TP:SetItemByID(item);
    else
        TP:SetHyperlink(item);
    end
    local object = _G["NarciVirtualTooltipTextLeft"..line];
    if object then
        if keepColor then
            return object:GetText();
        else
            return RemoveColorString(object:GetText());
        end
    end
end

NarciAPI.GetItemTooltipTextByLine = GetItemTooltipTextByLine;


local ITEM_ENCHANT_FORMAT = gsub(ENCHANTED_TOOLTIP_LINE, "%%s", "(.+)");

local function GetItemEnchantText(itemLink, colorized)
    if not itemLink then return; end

    TP:SetHyperlink(itemLink);
    local numLines = TP:NumLines();
    local str;
    local enchantText;
    local enchantFormat = ITEM_ENCHANT_FORMAT;
    for i = 5, numLines do
        str = _G["NarciVirtualTooltip".."TextLeft"..i];
        if str then
            str = str:GetText();
            enchantText = match(str, enchantFormat);
            if enchantText then
                enchantText = strtrim(enchantText);
                if enchantText ~= "" then
                    --print(enchantText)
                    if colorized then
                        enchantText = "|cff5fbd6b"..enchantText.."|r";
                    end
                    return enchantText
                end
            end
        else
            return
        end
    end
end

local function GetEnchantTextByEnchantID(enchantID)
    if enchantID then
        local itemLink = "item:2092:"..enchantID;
        return GetItemEnchantText(itemLink, false);
    end
end

NarciAPI.GetItemEnchantText = GetItemEnchantText;
NarciAPI.GetEnchantTextByEnchantID = GetEnchantTextByEnchantID;


local function GetEnchantTextByItemLink(itemLink, colorized)
    if not itemLink then return end;

    local _, _, _, linkType, linkID, enchantID = split(":|H", itemLink);

    if enchantID then
        TP:SetHyperlink("item:2092:"..enchantID);

        if not LEFT_FONT_STRINGS[7] then
            LEFT_FONT_STRINGS[7] = _G["NarciVirtualTooltipTextLeft7"];
        end

        if LEFT_FONT_STRINGS[7] then
            local enchantText = LEFT_FONT_STRINGS[7]:GetText();

            if enchantText and enchantText ~= "" then
                --remove "Enchanted:"
                local effect = match(enchantText, ITEM_ENCHANT_FORMAT);
                if not effect then
                    effect = enchantText;
                end
                if colorized then
                    effect = "|cff5fbd6b"..effect.."|r";
                end
                return effect
            end
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
    if location2 then
        TP:SetBagItem(location1, location2);
    else
        TP:SetInventoryItem("player", location1, nil, true);
    end
    local numLines = TP:NumLines();
    local str;
    local r, g, b;
    local buffText, durationText;
    for i = 5, numLines do
        str = _G["NarciVirtualTooltip".."TextLeft"..i];
        if str then
            str = str:GetText();
            if not match(str, FORMAT_COLON) then
                buffText, durationText = match(str, TEMP_ENCHANT_FORMAT);
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

    TP:SetHyperlink(itemLink);
    local numLines = TP:NumLines();
    local fontString, leftText, rightText;

    for i = 3, numLines do
        fontString = _G["NarciVirtualTooltip".."TextLeft"..i];
        if fontString then
            leftText = fontString:GetText();
            if leftText == itemEquipLoc then
                local n = i + 1;
                fontString = _G["NarciVirtualTooltip".."TextLeft"..n];
                if fontString then
                    leftText = fontString:GetText();
                end
                fontString = _G["NarciVirtualTooltip".."TextRight"..n];
                if fontString then
                    rightText = fontString:GetText();
                end
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
    TP:SetHyperlink(itemLink);
    local numLines = TP:NumLines();
    local fontString, text;

    for i = numLines, numLines - 1, -1 do
        fontString = _G["NarciVirtualTooltip".."TextLeft"..i];
        if fontString then
            text = fontString:GetText();
            if match(text, "^[\"“]") then
                return text
            end
        else
            return
        end
    end
end

NarciAPI.GetItemFlavorText = GetItemFlavorText;


local function NarciAPI_IsAppearanceKnown(itemLink)
    --Need to correspond with C_TransmogCollection.PlayerHasTransmog
    if not itemLink then    return; end
    TP:SetHyperlink(itemLink);
    local str;
    local num = TP:NumLines();
    for i = num, num - 2, -1 do
        str = nil;
        str = _G["NarciVirtualTooltip".."TextLeft"..i]
        if not str then
            return false;
        else
            str = str:GetText();
        end
        if str == SOURCE_KNOWN or str == APPEARANCE_KNOWN then
            return true;
        elseif str == APPEARANCE_UNKNOWN then
            return false;
        end
    end
    return false;
end

NarciAPI.IsAppearanceKnown = NarciAPI_IsAppearanceKnown;


local function GetItemExtraEffect(itemLink, checkBonus, keepFormat)
    if not itemLink then return; end

    TP:SetHyperlink(itemLink);
    local num = TP:NumLines();
    local begin = max(num - 6, 3);
    local output = "";
    local category, str;

    for i = begin, num, 1 do
        str = nil;
        str = _G["NarciVirtualTooltip".."TextLeft"..i];
        if not str then
            break;
        else
            str = str:GetText();
        end

        if find(str, ON_USE) then
            str = FormatString(str, NO_COMMA_ON_USE, keepFormat);
            if not category then    category = NO_COMMA_ON_USE; end
            output = output..str.."\n"
        elseif find(str, ON_EQUIP) then
            str = FormatString(str, NO_COMMA_ON_EQUIP, keepFormat);
            if not category then    category = NO_COMMA_ON_EQUIP; end
            output = output..str.."\n"
        elseif find(str, ON_PROC) then
            str = FormatString(str, NO_COMMA_ON_PROC, keepFormat);
            if not category then    category = NO_COMMA_ON_PROC; end
            output = output..str.."\n"
        elseif checkBonus then
            if find(str, ITEM_BONUS) then
                str = FormatString(str, NO_COMMA_SET_BONUS, keepFormat);
                if not category then    category = NO_COMMA_SET_BONUS; end
                output = output..str.."\n"
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

local function NarciAPI_GetGemBonus(item)
    --item: Gem's Item ID or hyperlink
    if not item then return; end
    local itemID;
    if type(item) == "number" then
        TP:SetItemByID(item);
        itemID = item;
    else
        TP:SetHyperlink(item);
        itemID = GetItemInfoInstant(item);
    end
    local num = TP:NumLines();
    local bonusText;
    local str;
    local level = 0;

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

    for i = 1, num do
        str = _G["NarciVirtualTooltip".."TextLeft"..i]
        if not str then
            return;
        else
            str = str:GetText();
            if not str then
                return;
            end
        end

        if not bonusText and string.sub(str, 1, 1) == "+" then
            bonusText = str;
        end

        if find(str, GEM_MIN_LEVEL) then
            level = FormatString(str, GEM_MIN_LEVEL);
        end

        if level and bonusText then return bonusText, tonumber(level); end
    end
    return bonusText, tonumber(level);
end

NarciAPI.GetGemBonus = NarciAPI_GetGemBonus;


local function GetItemEquipEffect(itemLink)
    if not itemLink then return; end

    TP:SetHyperlink(itemLink);
    local total = TP:NumLines();
    local begin = max(total - 4, 0);
    local fontString, text;
    local effects, effectType, effectText, cooldownText;
    local numEffects;

    for i = begin, total do
        fontString = _G["NarciVirtualTooltip".."TextLeft"..i];
        if not fontString then
            break;
        else
            text = fontString:GetText();
        end
        effectType = nil;
        effectText = nil;
        cooldownText = nil;
        if find(text, ON_USE) then
            effectText, cooldownText = TrimCooldownText( strtrim(text, NO_COMMA_ON_USE) );
            effectType = "use";
        elseif find(text, ON_EQUIP) then
            effectText = RemoveColorString(text);
            effectType = "equip";
        elseif find(text, ON_PROC) then
            effectText = text;
            effectType = "proc";
        elseif find(text, ITEM_BONUS) then
            effectText = text;
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

    TP:SetHyperlink(itemLink);
    local fontString, text;
    local currentLevel, maxLevel;
    for i = 2, 3 do
        fontString = _G["NarciVirtualTooltip".."TextLeft"..i];
        if fontString then
            text = fontString:GetText();
            currentLevel, maxLevel = match(text, PATTERN_UPGRADE_LEVEL);
            if maxLevel then
                return currentLevel, maxLevel
            end
        else
            break
        end
    end
end

NarciAPI.GetItemUpgradeLevel = GetItemUpgradeLevel;


local function GetCompleteItemData(itemLink)
    --return a table of data obtained by scanning tooltip
    --upgrade level (current/max), equipmentEffects(onEquip, onUse, onProc, bonus), socket info(socket1, socket2, socket3), enchant
    --reset socket textures
    local _;
    if not itemLink then
        _, itemLink = TP:GetItem();
        itemLink = FormatItemLink(itemLink);
        if not itemLink then
            return
        end
    end

    local _, _, _, itemEquipLoc, _, classID, subclassID = GetItemInfoInstant(itemLink);
    local matchWeapon;
    if classID == 2 then
        --Find Weapon damage and attack speed by matching the texts below equip location
        itemEquipLoc = _G[itemEquipLoc];
        matchWeapon = true;
    end

    local processed = {};   --process each line once

    local numLines = TP:NumLines();
    local fontString, text;
    local match1, match2;
    local enchantText;
    local effectText, effectType, numEffects, isActive, cooldownText;
    local data, anyMatch;
    local tex, texID;
    local gemName, gemLink, gemEffect, lineIndex;
    local requestSubData;

    for i = 1, 3 do
        tex = _G["NarciVirtualTooltipTexture"..i];
        texID = tex and tex:GetTexture();
        if texID then
            gemName, gemLink = GetItemGem(itemLink, i);
            _, fontString = tex:GetPoint();
            if fontString then
                gemEffect = fontString:GetText();
                gemEffect = RemoveColorString(gemEffect);
                lineIndex = tonumber(match(fontString:GetName(), "Left(%d+)$"));
                processed[lineIndex] = true;
                if lineIndex and not LEFT_FONT_STRINGS[lineIndex] then
                    LEFT_FONT_STRINGS[lineIndex] = fontString;
                end
            else
                gemEffect = nil;
            end
            if not data then
                data = {};
            end
            if not data.socketInfo then
                data.socketInfo = {};
            end
            data.socketInfo[i] = {texID, gemName, gemLink, gemEffect};
            if gemLink and not requestSubData then
                if gemEffect and gemEffect == "" then
                    requestSubData = true;
                end
            end
        end
    end

    for i = 2, numLines do
        if not processed[i] then
            if not LEFT_FONT_STRINGS[i] then
                LEFT_FONT_STRINGS[i] = _G["NarciVirtualTooltipTextLeft"..i];
            end
            fontString = LEFT_FONT_STRINGS[i];
            if fontString then
                text = fontString:GetText();
                anyMatch = nil;
                if i == 2 then
                    --the second line is usually item level
                    --or a special item category: difficuty, Cypher Equipment
                    if not match(text, "%d$") then
                        if not data then
                            data = {};
                        end
                        data.context = ReplacePureGreenText(text);
                        anyMatch = true;
                    end
                else
                    if i < 5 and not match2 then
                        --upgrade level
                        match1, match2 = match(text, PATTERN_UPGRADE_LEVEL);
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
                    if find(text, ON_USE) then
                        effectText, cooldownText = TrimCooldownText( strtrim(text, NO_COMMA_ON_USE) );
                        effectType = "use";
                    elseif find(text, ON_EQUIP) then
                        effectText = RemoveColorString(text);
                        effectType = "equip";
                    elseif find(text, ON_PROC) then
                        effectText = text;
                        effectType = "proc";
                    elseif find(text, ITEM_BONUS) or find(text, SOCKET_BONUS) then
                        effectText = text;
                        effectType = "set";
                    elseif matchWeapon then
                        if text == itemEquipLoc then
                            matchWeapon = nil;
                            local leftText, rightText;
                            fontString = _G["NarciVirtualTooltipTextRight"..i];
                            if fontString then
                                rightText = fontString:GetText();   --weapon type singular
                                if rightText then
                                    if not data then
                                        data = {};
                                    end
                                    data.itemType = rightText;
                                end
                            end
                            local n = i + 1;
                            if not LEFT_FONT_STRINGS[n] then
                                LEFT_FONT_STRINGS[n] = _G["NarciVirtualTooltipTextLeft"..n]
                            end
                            fontString = LEFT_FONT_STRINGS[n];
                            if fontString then
                                leftText = fontString:GetText();        --damage (x - y Damage)
                            end
                            fontString = _G["NarciVirtualTooltipTextRight"..n];
                            if fontString then
                                rightText = fontString:GetText();       --speed 0.00
                            end
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
                            enchantText = match(text, ITEM_ENCHANT_FORMAT);
                            if enchantText then
                                enchantText = strtrim(enchantText);
                                if enchantText ~= "" then
                                    if not data then
                                        data = {};
                                    end
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
                        isActive = not (IsTextColorColor(fontString, 1, 0.13, 0.13) or IsTextColorColor(fontString, 0.5, 0.5, 0.5));
                        numEffects = numEffects + 1;
                        data.effects[numEffects] = {effectType, effectText, isActive, cooldownText};
                        effectType = nil;
                        effectText = nil;
                        cooldownText = nil;
                        isActive = nil;
                        anyMatch = true;
                    end
                end
                if i >= numLines - 2 and not anyMatch then
                    --flavor texts, class restrictions
                    match1 = match(text, PATTERN_CLASS_REQUIREMENT);
                    if match1 then
                        isActive = IsTextColorColor(fontString, 1, 1, 1);
                        if not data then
                            data = {};
                        end
                        data.classesAllowed = {match1, isActive};
                        anyMatch = true;
                    elseif match(text, "^[\"“]") then
                        if not data then
                            data = {};
                        end
                        data.flavorText = text;
                        anyMatch = true;
                    end
                end
                --print(i.." "..tostring(anyMatch).." "..text)
                if i > 8 and not anyMatch then
                    --match item sets
                    match1, match2, _ = match(text, PATTERN_ITEM_SET_NAME);    --string.match("Test Set (1/9)", PATTERN_ITEM_SET_NAME)
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
                        data.itemSet.rawName = text;
                        data.itemSet.name = match1;
                        data.itemSet.numOwned = tonumber(match2);
                        data.itemSet.total = total;

                        for j = 1 + i, total + i do
                            if not LEFT_FONT_STRINGS[j] then
                                LEFT_FONT_STRINGS[j] = _G["NarciVirtualTooltipTextLeft"..j]
                            end
                            fontString = LEFT_FONT_STRINGS[j];
                            if fontString then
                                text = fontString:GetText();
                                isActive = not IsTextColorColor(fontString, 0.5, 0.5, 0.5);
                                --print(fontString:GetTextColor());
                                tinsert(data.itemSet.itemNames, {text, isActive});
                                processed[j] = true;
                            else
                                break
                            end
                        end
                        for j = i + total + 2, numLines do
                            if not LEFT_FONT_STRINGS[j] then
                                LEFT_FONT_STRINGS[j] = _G["NarciVirtualTooltipTextLeft"..j]
                            end
                            fontString = LEFT_FONT_STRINGS[j];
                            if fontString then
                                text = fontString:GetText();
                                if find(text, SET_BONUS, 1) then
                                    --found set bonus
                                    isActive = not IsTextColorColor(fontString, 0.5, 0.5, 0.5);
                                    tinsert(data.itemSet.bonuses, {text, isActive});
                                    processed[j] = true;
                                end
                            else
                                break
                            end
                        end
                    end
                end
            else
                --No FontString
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
    for i = 1, #LEFT_FONT_STRINGS do
        LEFT_FONT_STRINGS[i]:SetText(nil);
        LEFT_FONT_STRINGS[i]:SetTextColor(1, 1, 1); --this should fix some coloring issue caused by using escape sequence: |cff
    end
end

local function GetCompleteItemDataFromSlot(slotID)
    ClearTooltipTexture();
    TP:SetInventoryItem("player", slotID, false, true);
    return GetCompleteItemData();
end

local function GetCompleteItemDataByItemLink(itemLink)
    if not itemLink then return end
    ClearTooltipTexture();
    TP:SetHyperlink(itemLink);
    return GetCompleteItemData(itemLink);
end

local function GetCompleteItemDataFromGameTooltip()
    --for debug
    local name, itemLink = GameTooltip:GetItem();
    if itemLink then
        ClearTooltipTexture();
        TP:SetHyperlink(itemLink);
        return GetCompleteItemData(itemLink);
    end
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

do
    local version, build, date, tocversion = GetBuildInfo()
    if tocversion and tocversion < 90000 then
        SocketTypes[136257] = "META";
    end
end

local IsSupportedSocket = {};

for _, name in pairs(SocketTypes) do
    IsSupportedSocket[name] = true;
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

    local tex, texID;
    for i = 1, 3 do
        tex = _G["NarciVirtualTooltipTexture"..i];
        if tex then
            tex = tex:SetTexture(nil);
        end
    end

    TP:SetHyperlink(itemLink);

    for i = 1, 3 do     --max 10
        tex = _G["NarciVirtualTooltipTexture"..i]
        texID = tex and tex:GetTexture();
        --print(texID)
        if SocketTypes[texID] then     --458977: Regular empty socket texture  --Doesn't include domination socket
            return "Empty", nil;
        end
    end
    return nil, nil;
end
NarciAPI.IsItemSocketable = IsItemSocketable;

local function GetItemSocketInfo(itemLink)
    --gemData = { {socketType, icon, gemLink(nillable) } }

    if not itemLink then return end
    ClearTooltipTexture();
    TP:SetHyperlink(itemLink);

    local tex, texID;
    local gemName, gemLink;
    local socektInfo;
    local numSocket = 0;
    for i = 1, 3 do
        gemName, gemLink = GetItemGem(itemLink, i);
        if gemLink then
            if not socektInfo then
                socektInfo = {};
            end
            texID = select(5, GetItemInfoInstant(gemLink));
            numSocket = numSocket + 1;
            socektInfo[numSocket] = {gemName, texID, gemLink};
        else
            tex = _G["NarciVirtualTooltipTexture"..i];
            texID = tex and tex:GetTexture();
            if SocketTypes[texID] then
                if not socektInfo then
                    socektInfo = {};
                end
                numSocket = numSocket + 1;
                socektInfo[numSocket] = {SocketTypes[texID], texID, };
            end
        end
    end

    --socektInfo = { {SocketTypes[458977], 458977}, {SocketTypes[4095404], 4095404}, {SocketTypes[136257], 136257} };   --debug SL
    --socektInfo = { {SocketTypes[136257], 136257}, {SocketTypes[136259], 136259}, {SocketTypes[136256], 136256} };   --debug TBC
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

    TP:SetItemByID(itemID);
    if not LEFT_FONT_STRINGS[3] then
        LEFT_FONT_STRINGS[3] = _G["NarciVirtualTooltipTextLeft3"];
    end
    if LEFT_FONT_STRINGS[3] then
        return tonumber(match(LEFT_FONT_STRINGS[3]:GetText(), PATTERN_AMMO_DPS) or 0);
    end
end

NarciAPI.GetAmmoDps = GetAmmoDps;


local function FormatSpellData(fromLine)
    local leftText, rightText;
    local anyMatch;
    local data = {};
    local rangeText, castText, cdText, costText, replaceSpell;
    local isPassive;
    fromLine = fromLine or 1;
    local first2Lines = fromLine + 1;

    --castText: instant, x sec cast, channel
    --cdText: cooldown or recharge time

    local numLines = TP:NumLines();
    local fontString;

    for i = fromLine, numLines do
        anyMatch = false;
        if not LEFT_FONT_STRINGS[i] then
            LEFT_FONT_STRINGS[i] = _G["NarciVirtualTooltipTextLeft"..i];
        end
        fontString = LEFT_FONT_STRINGS[i];
        if fontString then
            leftText = fontString:GetText();
        else
            leftText = nil;
        end
        fontString = _G["NarciVirtualTooltipTextRight"..i];
        if fontString then
            rightText = fontString:GetText();
        else
            rightText = nil;
        end

        if i <= first2Lines then
            if rightText then
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

                if not anyMatch and match(leftText, "^%d", 1) then
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

    TP:ClearLines();
    TP:AddTraitEntry(entryID, rank);

    return FormatSpellData()
end

NarciAPI.GetTraitEntryTooltip = GetTraitEntryTooltip;


local function GetPvpTalentTooltip(talentID, isInspecting, specGroupIndex, slotIndex)
    if not (talentID and specGroupIndex and slotIndex) then return end;

    TP:SetPvpTalent(talentID, isInspecting, specGroupIndex, slotIndex);
    return FormatSpellData(2);
end

NarciAPI.GetPvpTalentTooltip = GetPvpTalentTooltip;


local function VoidFunc()
end

NarciAPI.GetBagItemSubText = VoidFunc;
NarciAPI.GetBagItemSubText = VoidFunc;


local function GetDominationShardEffect(item)
    if not item then return end;

    if type(item) == "number" then
        TP:SetItemByID(item);
    else
        TP:SetHyperlink(item);
    end

    local line = _G["NarciVirtualTooltipTextLeft5"];
    if line then
        return line:GetText();
    end
end

NarciAPI.GetDominationShardEffect = GetDominationShardEffect;


--[[
itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, (setID), isCraftingReagent
= GetItemInfo

GetItemSetInfo(setID)
GetItemSpecInfo

ITEM_SET_BONUS = "Set: %s";
ITEM_SET_BONUS_GRAY = "(%d) Set: %s";
ITEM_SET_BONUS_NO_VALID_SPEC = "Bonus effects vary based on the player's specialization.";
ITEM_SET_LEGACY_INACTIVE_BONUS = "Legacy Set: Bonus is inactive";
ITEM_SET_NAME = "%s (%d/%d)";
--]]

--[[
local function TestItemLinkAffix(from, to)
    local TP = TP;
    local max = max;
    local total = 0;
    local s = from  --6500;
    local e = to    --6600;
    local output;
    local itemLink;
    local function GetExtraInfo()
        itemLink = "\124cffa335ee\124Hitem:174954::::::::120::::2:1477:".. s ..":\124h[]\124h\124r";
        TP:SetHyperlink(itemLink);
        local num = TP:NumLines();
        local begin = max(num - 3, 0);
        local str;
    
        for i = begin, num, 1 do
            str = nil;
            str = _G["NarciVirtualTooltip".."TextLeft"..i]
            if not str then
                break;
            else
                str = str:GetText();
            end
            
            if find(str, ON_EQUIP) then
                print("|cFFFFD100"..s.."|r "..str);
                break
            end
        end

        s = s + 1;
        total = total + 1;
        if s < e and total < 1000 then
            After(0, GetExtraInfo);
        else
            print("Search Complete")
        end
    end

    print("Search from "..s.." to "..e);
    for i = s, e do
        --Cache
        itemLink = "\124cffa335ee\124Hitem:174954::::::::120::::2:1477:".. i ..":\124h[]\124h\124r";
        TP:SetHyperlink(itemLink);
    end
    After(1, GetExtraInfo);
end

--]]