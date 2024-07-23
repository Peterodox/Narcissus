local NUM_WIDGETS = 10;
local NUM_NPC_ID_MAX = 10;
local TOOLTIP_NAME_PREFIX = "CreatureNameRetriever";

local OutputFrame, OutputEditBox;

local function SortFunc(a, b)
    if a[1] == b[1] then
        return a[2] < b[2]
    else
        return a[1] < b[1]
    end
end

local function UpdateEditBoxScrollRange()
    local maxScroll = OutputEditBox.numLines * 9;
    OutputFrame.ScrollFrame.range = maxScroll
    OutputFrame.ScrollFrame.scrollBar:SetMinMaxValues(0, maxScroll);
end

local function ResetOutputEditBox()
    OutputEditBox:SetText("");
    OutputEditBox.numLines = 0;
end

local function OutPutText(str)
    OutputEditBox.numLines = OutputEditBox.numLines + 1;
    --OutputEditBox:SetText(OutputEditBox:GetText().."\n"..str)
    OutputEditBox:Insert(str.."\n");
    UpdateEditBoxScrollRange()
end

local NameTemp = {};

local WidgetContainer = {};

local function CreateVirtualTooltip(index)
    local name = TOOLTIP_NAME_PREFIX..index;
    local VirtualTooltip = CreateFrame("GameTooltip", name, UIParent, "GameTooltipTemplate");
    VirtualTooltip.lineName = _G[name.. "TextLeft1"];

    local function GetName(creatureID)
        VirtualTooltip:SetOwner(UIParent, "ANCHOR_NONE");
        VirtualTooltip:SetHyperlink(format("unit:Creature-0-0-0-0-%d", creatureID));
        return VirtualTooltip.lineName:GetText() or ""
    end
    
    C_TooltipInfo.GetHyperlink(format("unit:Creature-0-0-0-0-%d", 1748))
    VirtualTooltip.GetName = GetName;

    return VirtualTooltip
end

function GetExistNPC(_endIndex)
    ResetOutputEditBox();

    local IDs = {};
    local _start, _end = (_endIndex - 1)*1000 + 1, _endIndex*1000;
    local numLeft = _end - _start + 1;

    for i = 1, numLeft do
        IDs[i] = _start + i - 1;
    end

    local name, id;
    local numExist = 0;
    local output = {
        --[creatureID] = name;
    };

    local find = string.find;

    local function Recursion()
        for i = 1, NUM_WIDGETS do
            id = IDs[numLeft];
            name = WidgetContainer[i].Tooltip.GetName(id);
            if name and name~= "" then
                --if not find(name, "PH") then
                    tinsert(output, {id, name});
                    numExist = numExist + 1;
                --end
            end
            numLeft = numLeft - 1;
            if numLeft == 0 then
                break
            end
        end

        if numLeft > 0 then
            C_Timer.After(0.01, Recursion);
        else
            print("Done");
            print(_start.." to ".._end.." : "..numExist)
            table.sort(output, SortFunc);
            for _, v in pairs(output) do
                OutPutText("|cffffffff".. v[1] .."|r|cffa6a6a6,  --".. v[2].."|r")
            end
        end
    end

    Recursion();
    OutputFrame:Show();
    OutputFrame:SetAlpha(1);
end


local function CreateVirtualModel(index)
    local VirtualModel = CreateFrame("CinematicModel");
    VirtualModel:SetScript("OnModelLoaded", function(self)
        if not self.pauseUpdate then
            self.pauseUpdate = true;
            local creatureID = self.creatureID;
            local fileID = self:GetModelFileID();
            if fileID and fileID ~= 124642 and fileID ~= 124640 then
                local name = self.Tooltip.GetName(creatureID);
                if name and name ~= "" then
                    if not NameTemp[name] then
                        NameTemp[name] = {};
                    end
                    if not NameTemp[name][fileID] then
                        NameTemp[name][fileID] = true;
                        OutPutText("|cffffffff".. (creatureID or "|cffed1c24Error") .."|r  |cffcccccc"..fileID.."|r  |cffa6a6a6"..name)
                    else
                        OutPutText("|cffffffff".. (creatureID or "|cffed1c24Error") .."|r  |cffcccccc"..fileID.."|r  |cffa6a6a6"..name.." |cffffd200Duplicated")
                    end
                end
            end
            C_Timer.After(0, function()
                self.pauseUpdate = nil;
            end)
        end
    end)

    VirtualModel.Tooltip = CreateVirtualTooltip(index)
    return VirtualModel
end


for i = 1, NUM_WIDGETS do
    WidgetContainer[i] = CreateVirtualModel(i);
end

function FormatAndSave()
    local raw = OutputEditBox:GetText();
    local text = {};
    local func = string.gmatch(raw, "[^\n]+[\n]");
    local match = string.match;
    local trim = string.trim;


    local outputTable = NarciDevToolOutput;
    for line in func do
        line = trim(line);
        local id, name = match(line, "(%d+)%s+([%a%d]+)");
        id = tonumber(id);
        outputTable[id] = name;
    end
end

--Loading
local Utility = CreateFrame("Frame");
Utility:RegisterEvent("PLAYER_ENTERING_WORLD");
Utility:SetScript("OnEvent", function(self, event)
    NarciDevToolOutput = NarciDevToolOutput or {};

    self:UnregisterEvent(event);
    OutputFrame = CreateFrame("Frame", "Narci_OutPutFrame", nil, "Narci_OutPutFrameTemplate");
    OutputFrame:Hide();
    OutputEditBox = OutputFrame.ScrollFrame.EditBox;
    local editBoxHeight = OutputEditBox:GetHeight();
    --CreateSmoothScroll(OutputFrame.ScrollFrame, editBoxHeight, 1, 0.5);
    OutputFrame.ScrollFrame.scrollBar:SetScript("OnValueChanged", function(self, value)
        self:GetParent():SetVerticalScroll(value);
    end)
end)