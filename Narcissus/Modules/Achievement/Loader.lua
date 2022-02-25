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
        self:EnableAchievementPanel();
    end
end)

function Loader:LoadAchievementPanel()
    Loader:RegisterEvent("ADDON_LOADED");
    EnableAddOn(MODULE_NAME);    --Forced Enable
    local loaded, reason = LoadAddOn(MODULE_NAME);
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

function Loader:EnableAchievementPanel()
    if NarciAchievementOptions.UseAsDefault then
        Narci.RedirectPrimaryAchievementFrame();
    end
end

Narci.LoadAchievementPanel = function(achievementID, clickAgainToClose)
    Loader.pendingAchievementID = achievementID;    --Load panel then go to this achievement
    Loader.clickAgainToClose = clickAgainToClose;
    Loader:LoadAchievementPanel();
end
