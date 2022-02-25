local strtrim = strtrim;

local Tooltip;

local TOOLTIP_NAME = "NarciUtilityTooltip";
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
        Tooltip:SetItemByID(item);
    else
        Tooltip:SetHyperlink(item);
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
            text = pinnedObjects[i]:GetText();
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

local function GetItemTooltipTextByLine(item, line, callbackFunc)
    if not Tooltip then
        Tooltip = CreateFrame("GameTooltip", TOOLTIP_NAME, nil, "GameTooltipTemplate");
        Tooltip:SetOwner(UIParent, "ANCHOR_NONE");
    end

    onTextChangedCallback = callbackFunc;
    local isCached = SetTooltipItem(item);

    if item ~= lastItem then
        lastItem = item;
        lastText = nil;
        Tooltip.t = 0;
        Tooltip.iteration = 0;
        Tooltip:SetScript("OnUpdate", Tooltip_OnUpdate);
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
            object = _G[TOOLTIP_NAME.."TextLeft".._l];
            if object then
                tinsert(pinnedObjects, object);
                if not IS_LINE_HOOKED[_l] then
                    IS_LINE_HOOKED[_l] = true;
                    object.lineIndex = _l;
                end
                text = object:GetText();
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
        object = _G[TOOLTIP_NAME.."TextLeft"..line];
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

NarciAPI.GetCachedItemTooltipTextByLine = GetItemTooltipTextByLine;