
local ADDON = "AzeriteUI"

if not CogWheel then return end;
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local ActionBarsParent;
local Test_ToggleAzeriteUI = function(forced)
    local CogWheel = _G.CogWheel
    if CogWheel then 
        local LibFader = CogWheel("LibFader", true)
        if LibFader then 
            LibFader:SetObjectFadeOverride(forced)
        end 
        local LibModule = CogWheel("LibModule", true)
        if LibModule then 
            local AzeriteUI = LibModule:GetModule("AzeriteUI", true)
            if AzeriteUI then 
                local ActionBars = AzeriteUI:GetModule("ActionBarMain", true)
                if (ActionBars) then 
                    ActionBars:SetForcedVisibility(forced)
                end 
            end 
        end 
    end 
end 


local ButtonName = "AzeriteUIActionButton";
local DefaultParent, DefaultScale;

local function TakeFramesOut(frame, state)
    if not frame then
        return;
    end

    if state then
        frame:SetParent(Narci_SharedAnimatedParent);
        frame:SetScale(DefaultScale);
        
    else
        frame:SetParent(DefaultParent);
        frame:SetScale(1);
    end
end

function Bridge_AzeriteUI_ShowActionBars(state)
    if not (DefaultParent and DefaultParent) then
        return;
    end

    for i=1, 24 do
        --print(i..": "..tostring(_G[ButtonName..i]:IsEnabled()))
        TakeFramesOut(_G[ButtonName..i], state)
    end;
end

local Bridge = CreateFrame("Frame", "AddonBridge-AzeriteUI");
Bridge:RegisterEvent("VARIABLES_LOADED");
Bridge:SetScript("OnEvent",function(self,event,...)
    local ReferenceButton = _G[ButtonName.."1"];
    DefaultParent = ReferenceButton:GetParent();
    DefaultScale = ReferenceButton:GetEffectiveScale();
    --print("Scale is "..DefaultScale)
end)