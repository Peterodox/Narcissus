local _, addon = ...

local SCREENSHOT_ALERT_CHANGED = false;
local DEFAULT_MSG = UI_HIDDEN or "";    --UI_HIDDEN isn't used in Retail

local function ScreenshotAlert_CheckRequirements()
    if ActionStatus and ActionStatus.Text and ActionStatusMixin and ActionStatusMixin.OnUpdate and ActionStatusMixin.DisplayMessage then
        return true
    else
        return false
    end
end

local function ScreenshotAlert_Override()
    if not SCREENSHOT_ALERT_CHANGED then
        SCREENSHOT_ALERT_CHANGED = true;
    else
        return
    end

    --if _G["UI_HIDDEN"] then
    --    UI_HIDDEN = "";
    --end

    if ScreenshotAlert_CheckRequirements() then
        local function OnUpdate(self, elapsed)
            self.t = self.t + elapsed;

            if self.t >= 0.5 then
                local alpha = self:GetAlpha() - 5*elapsed;
                if alpha <= 0 then
                    alpha = 0;
                    self:Hide();
                end
                self:SetAlpha(alpha);
            end
        end

        local function DisplayMessage(self, text)
            self:SetAlpha(1.0);
            self.Text:SetText(text);
            self.t = 0;
            self:Show();
        end

        ActionStatus:SetScript("OnUpdate", OnUpdate);
        ActionStatus.DisplayMessage = DisplayMessage;
        ActionStatus:Hide();
    end
end

local function ScreenshotAlert_Restore()
    if SCREENSHOT_ALERT_CHANGED then
        SCREENSHOT_ALERT_CHANGED = false;
    else
        return
    end

    --UI_HIDDEN = DEFAULT_MSG;

    if ScreenshotAlert_CheckRequirements() then
        ActionStatus:SetScript("OnUpdate", ActionStatusMixin.OnUpdate);
        ActionStatus.DisplayMessage = ActionStatusMixin.DisplayMessage;
        ActionStatus:Hide();
    end
end


do
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.SpeedyScreenshotAlert(state, db)
        if state == nil then
            state = db["SpeedyScreenshotAlert"];
        end

        if state then
            ScreenshotAlert_Override();
        else
            ScreenshotAlert_Restore();
        end
    end
end