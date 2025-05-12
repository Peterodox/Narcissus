local AFK_MSG = string.format(MARKED_AFK_MESSAGE, DEFAULT_AFK_MESSAGE);

local AFK = CreateFrame("Frame");

local UnitIsAFK = UnitIsAFK;

do
    local _, addon = ...
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.UseAFKScreen(state, db)
        if state == nil then
            state = db["AFKScreen"];
        end
        if state then
            AFK:RegisterEvent("CHAT_MSG_SYSTEM");
        else
            AFK:UnregisterEvent("CHAT_MSG_SYSTEM");
        end
    end
end


local function CanShowAFKScreen()
    if Narci and Narci.isActive then
        return false
    end

    local canShow = not(C_PvP.IsActiveBattlefield() or CinematicFrame:IsShown() or MovieFrame:IsShown() or InCombatLockdown() or (BarberShopFrame and BarberShopFrame:IsShown()));
    if C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType then
        canShow = canShow and C_PlayerInteractionManager.IsInteractingWithNpcOfType(0);
        --IsInteractingWithNpcOfType(0) == true means player is not interacting with an NPC
        --There is a chance IsInteractingWithNpcOfType stuck at false until player interacts then stops interacting with an NPC
    end

    return canShow
end

local function ShowAFKScreen()
    if not Narci.isActive then
        --securecall("CloseAllWindows");    --cause taint?
        CloseWindows();
        Narci_MinimapButton:Click();
        Narci.isAFK = true;
    end
end


local AFKCountdownFrame;


local function CreateAFKCountdown()
    AFKCountdownFrame = CreateFrame("Frame", nil, UIParent, "NarciAFKCoundownFrame");
    local f = AFKCountdownFrame;
    f:SetFrameStrata("FULLSCREEN");

    local fontPath = NarciFontMedium12Outline:GetFont();

    local headerText = MARKED_AFK or "You are now Away";
    headerText = string.gsub(headerText, "[。%.]", "");

    local header = f.Header;
    header:SetText(headerText);
    header:SetTextColor(1, 0.82, 0);
    header:SetShadowColor(0, 0, 0);
    header:SetShadowOffset(1, -1);

    f.Text:SetText("Narcissus will be activated in");
    f.Text:SetPoint("BOTTOM", f, "BOTTOM", 0, 0);
    f.Text:SetTextColor(0.72, 0.72, 0.72);
    f.Text:SetShadowColor(0, 0, 0);
    f.Text:SetShadowOffset(1, -1);

    local countdown = f.CountdownNumber;
    countdown:SetFont(fontPath, 24, "OUTLINE");
    countdown:SetShadowColor(0, 0, 0);
    countdown:SetShadowOffset(2, -2);

    local function Countdown_OnPlay(self)
        countdown:SetText(f.counter);
    end

    local function Countdown_OnFinished(self)
        if not UnitIsAFK("player") then --Jumping doesn't trigger Moving
            f:Hide();
            return
        end
        f.counter = f.counter - 1;
        if f.counter <= 0 then
            f:Hide();
            if CanShowAFKScreen() then
                ShowAFKScreen();
            end
        else
            self:Play();
        end
    end

    local function StartCountdownDelay_OnUpdate(self, elapsed)
        f.delay = f.delay + elapsed;
        if f.delay > 0 then
            f:SetScript("OnUpdate", nil);
            countdown.AnimBlip:Play();
        end
    end

    local function FadeIn_OnFinished(self)
        f.delay = -0.5;
        f:SetScript("OnUpdate", StartCountdownDelay_OnUpdate);
    end

    countdown.AnimBlip:SetScript("OnPlay", Countdown_OnPlay);
    countdown.AnimBlip:SetScript("OnFinished", Countdown_OnFinished);
    f.FadeIn:SetScript("OnFinished", FadeIn_OnFinished);

    f:SetScript("OnHide", function(self)
        f:Hide();
        f:StopAnimating();
        f:SetScript("OnUpdate", nil);
        f:UnregisterEvent("PLAYER_STARTED_MOVING");
    end);

    f:SetScript("OnEvent", function(self)
        f:Hide();
    end);

    function f:ResetCountdown()
        self:StopAnimating();
        self.counter = 5;
        countdown:SetText("");
        self.FadeIn:Play();
        self:RegisterEvent("PLAYER_STARTED_MOVING");
        self:Show();
    end
end



AFK:SetScript("OnEvent", function(self, event, ...)
    if not NarcissusDB or not NarcissusDB.AFKScreen then return; end

    local name = ...
    if name == AFK_MSG and CanShowAFKScreen() then
        if NarcissusDB and NarcissusDB.AKFScreenDelay then
            if not AFKCountdownFrame then
                CreateAFKCountdown();
            end
            AFKCountdownFrame:ResetCountdown();
        else
            ShowAFKScreen();
        end
        --[[
        C_Timer.After(0.6, function()
            if IsResting() then
                DoEmote("Read", "none");
            end
        end)
        --]]
    end
end)