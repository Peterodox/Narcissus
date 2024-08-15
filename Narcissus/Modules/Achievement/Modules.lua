local _, addon = ...
local AchievementAlertUtil = addon.AchievementAlertUtil;

local GetAchievementInfo = GetAchievementInfo;
local GetParentAchievementID = NarciAPI.GetParentAchievementID;

local strsub = strsub;
local strsplit = strsplit;

local IS_TOOLTIP_HOOKED = false;
local ENABLE_TOOLTIP = false;
local tooltipButtons = {};

local function InsertTooltipButton(tooltipFrame, buttonIndex, achievementID, completed, topLine)
    --Called after adding new line
    local line;
    if topLine then
        line = 1;
    else
        line = tooltipFrame:NumLines();
    end
    if not tooltipButtons[buttonIndex] then
        tooltipButtons[buttonIndex] = CreateFrame("Button", nil, nil, "NarciAchievementTooltipButtonTemplate");
    end
    local button = tooltipButtons[buttonIndex];
    button:ClearAllPoints();
    button:SetParent(tooltipFrame);
    button.achievementID = achievementID;
    button:SetPoint("TOPLEFT", tooltipFrame:GetName().."TextLeft"..line, "TOPLEFT", 0, 2);
    if topLine then
        button:SetPoint("BOTTOMLEFT", tooltipFrame:GetName().."TextLeft"..line, "BOTTOMLEFT", 0, -2);
        button:SetWidth(tooltipFrame:GetWidth() - 16);
        button.closeFrame = true;
    else
        button:SetPoint("BOTTOMRIGHT", tooltipFrame:GetName().."TextLeft"..line, "BOTTOMRIGHT", 0, -2);
        button.closeFrame = false;
    end
    if completed then
        button.Highlight:SetVertexColor(0.251, 0.753, 0.251);
    else
        button.Highlight:SetVertexColor(1, 0.82, 0);
    end
    button:Show();
    if not tooltipFrame.insertedFrames then
        tooltipFrame.insertedFrames = {};
    end
    tinsert(tooltipFrame.insertedFrames, button);
end

local function HookAchievementTooltip()
    if IS_TOOLTIP_HOOKED then return end;
    IS_TOOLTIP_HOOKED = true;
    
    hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(self, link)
        if not ENABLE_TOOLTIP then return end;

        if strsub(link, 1, 11) == "achievement" then
            local _, achievementID = strsplit(":", link);
            achievementID = tonumber(achievementID);
            local id, name, _, completed = GetAchievementInfo(achievementID);
            InsertTooltipButton(self, 1, achievementID, completed, true)
            local parentAchievementID1, parentAchievementID2 = GetParentAchievementID(achievementID, true);
            if parentAchievementID1 then
                self:AddLine(" ");
                local id, name, _, completed = GetAchievementInfo(parentAchievementID1);
                local colorString;
                if completed then
                    colorString = "|cff40c040";
                else
                    colorString = "|cFFFFD100";
                end
                --self:AddDoubleLine("|cFF808080> |r"..colorString..name.."|r", id, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, true);
                self:AddLine("|cFF808080> |r"..colorString..name.."|r", 0.5, 0.5, 0.5, true);
                InsertTooltipButton(self, 2, parentAchievementID1, completed);
                if parentAchievementID2 then
                    id, name, _, completed = GetAchievementInfo(parentAchievementID2);
                    if completed then
                        colorString = "|cff40c040";
                    else
                        colorString = "|cFFFFD100";
                    end
                    --self:AddDoubleLine("|cFF808080>> |r"..colorString..name.."|r", id, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, true);
                    self:AddLine("|cFF808080>> |r"..colorString..name.."|r", 0.5, 0.5, 0.5, true);
                    InsertTooltipButton(self, 3, parentAchievementID2, completed);
                end
                self:Show();
            end
        end
    end);
end


local function AttemptToOpenAchievement(achievementID, clickAgainToClose)
    if Narci_AchievementFrame then
        Narci_AchievementFrame:LocateAchievement(achievementID, clickAgainToClose);
    else
        Narci.LoadAchievementPanel(achievementID, clickAgainToClose);
    end
end


NarciAchievementExtraTooltipMixin = {};

function NarciAchievementExtraTooltipMixin:OnLoad()
    self:RegisterForDrag("LeftButton");
end

function NarciAchievementExtraTooltipMixin:OnDragStart()
    local parent = self:GetParent();
    if parent and parent.OnDragStart then
        parent:OnDragStart();
    end
end

function NarciAchievementExtraTooltipMixin:OnDragStop()
    local parent = self:GetParent();
    if parent and parent.OnDragStop then
        parent:OnDragStop();
    end
end

function NarciAchievementExtraTooltipMixin:OnClick(button)
    if self.achievementID then
        AttemptToOpenAchievement(self.achievementID);
        if button == "RightButton" or self.closeFrame then
            self:GetParent():Hide();
        end
    end
end

-------------------------------------------------------------------------------------
--Redirect Blizzard Achievement to Narcissus Achievement Frame
--Temporarily disabled due to taint in Dragonflight

--[[
local Original_OnBlockHeaderClick = ACHIEVEMENT_TRACKER_MODULE.OnBlockHeaderClick;
local Original_OpenAchievementFrameToAchievement = OpenAchievementFrameToAchievement;
local Original_AchievementAlertFrame_OnClick = AchievementAlertFrame_OnClick;

local function New_OnBlockHeaderClick(_, block, mouseButton)
    if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
        local achievementLink = GetAchievementLink(block.id);
        if ( achievementLink ) then
            ChatEdit_InsertLink(achievementLink);
        end
    elseif ( mouseButton ~= "RightButton" ) then
        if ( IsModifiedClick("QUESTWATCHTOGGLE") ) then
            RemoveTrackedAchievement(block.id);
        else
            local clickAgainToClose = true;
            AttemptToOpenAchievement(block.id, clickAgainToClose);
        end
    else
        ObjectiveTracker_ToggleDropDown(block, AchievementObjectiveTracker_OnOpenDropDown);
    end
end

local RedirectFrame = {};
RedirectFrame.hasOverwritten = false;

function RedirectFrame:RestoreFunctions()
    if self.hasOverwritten then
        self.hasOverwritten = false;
        OpenAchievementFrameToAchievement = Original_OpenAchievementFrameToAchievement;
        AchievementAlertFrame_OnClick = Original_AchievementAlertFrame_OnClick;
        ACHIEVEMENT_TRACKER_MODULE.OnBlockHeaderClick = Original_OnBlockHeaderClick;
    end
end

function RedirectFrame:OverrideFunctions()
    if not self.hasOverwritten then
        self.hasOverwritten = true;
        function OpenAchievementFrameToAchievement(achievementID)
            AttemptToOpenAchievement(achievementID);
        end
        ACHIEVEMENT_TRACKER_MODULE.OnBlockHeaderClick = New_OnBlockHeaderClick;
    end
end


--]]



local REDIRECT_TO_NARCISSUS = false;
local FUNCTIONS_HOOKED = false;

local function CloseDefaultWindow()
    local f = AchievementFrame;
    if f and f:IsShown() then
        if InCombatLockdown() then
            --f:Hide();
            --"Hide" doesn't seem to cause Interface Failure, but UIPanel still considers it opened
            --which affects frame anchors and cause Esc unable to clear targets or open Game Menu
        else
            HideUIPanel(f);
        end
    end
end

local function New_OnBlockHeaderClick(_, block, mouseButton)
    if not REDIRECT_TO_NARCISSUS then return end;
    if mouseButton == "LeftButton" and not(IsModifiedClick("CHATLINK") or IsModifiedClick("QUESTWATCHTOGGLE")) then
        local clickAgainToClose = true;
        AttemptToOpenAchievement(block.id, clickAgainToClose);
        CloseDefaultWindow();
    end
end

local function New_AchievementAlertFrame_OnClick(self, button, down)
    --Debug /run AchievementAlertSystem:AddAlert(5159)
    if not REDIRECT_TO_NARCISSUS then return end;
    if button == "LeftButton" then
        local id = self.id;
        if id then
            AttemptToOpenAchievement(id);
            CloseDefaultWindow();
        end
    end
end

local function HookAchievementTrackerModule()
    --Attemp to use Hooks instead of overwriting exsisting functions to reduce Taint?
    --Default AchievementFrame will be opened then closed by us, so there might be some stuttering

    if FUNCTIONS_HOOKED then return end;
    FUNCTIONS_HOOKED = true;

    local m = AchievementObjectiveTracker;
    if m and m.OnBlockHeaderClick then
        hooksecurefunc(m, "OnBlockHeaderClick", New_OnBlockHeaderClick);
    end

    if AchievementAlertFrame_OnClick then
        hooksecurefunc("AchievementAlertFrame_OnClick", New_AchievementAlertFrame_OnClick);
    end
end

HookAchievementTrackerModule();



local function UpdateAchievementSettings()
    local db = NarciAchievementOptions;
    if not db then return end;

    if db.UseAsDefault then
        ENABLE_TOOLTIP = true;
        HookAchievementTooltip()

        REDIRECT_TO_NARCISSUS = true;
        HookAchievementTrackerModule();
    else
        ENABLE_TOOLTIP = false;
        REDIRECT_TO_NARCISSUS = false;
    end
end
Narci.UpdateAchievementSettings = UpdateAchievementSettings;



local MODULE_NAME = "Narcissus_Achievements";

local Loader = CreateFrame("Frame");
Loader:RegisterEvent("PLAYER_ENTERING_WORLD");

Loader:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == MODULE_NAME then
            self:UnregisterEvent(event);
            self:OnAddOnLoaded();
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        UpdateAchievementSettings();
    end
end)

function Loader:LoadAchievementPanel()
    Loader:RegisterEvent("ADDON_LOADED");
    C_AddOns.EnableAddOn(MODULE_NAME);    --Forced Enable
    local loaded, reason = C_AddOns.LoadAddOn(MODULE_NAME);
end

function Loader:OnAddOnLoaded()
    local frame = Narci_AchievementFrame;
    if frame then
        frame:Init();
        if self.pendingAchievementID then
            C_Timer.After(0.5, function()
                frame:LocateAchievement(self.pendingAchievementID, self.clickAgainToClose);
                self.pendingAchievementID = nil;
            end)
        end
    end
end

Narci.LoadAchievementPanel = function(achievementID, clickAgainToClose)
    Loader.pendingAchievementID = achievementID;    --Load panel then go to this achievement
    Loader.clickAgainToClose = clickAgainToClose;
    Loader:LoadAchievementPanel();
end