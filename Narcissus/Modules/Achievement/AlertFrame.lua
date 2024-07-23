-- Not being used due to potential taint

local _, addon = ...

local function SetSmallFont(object)
    local path, height = GameFontBlackTiny:GetFont();
    object:SetFont(path, 9);
end

local function AchievementAlertFrame_SetUp(frame, achievementID, alreadyEarned)
    local _, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementID);
    frame.id = achievementID;

    if ( points < 100 ) then
        frame.points:SetFontObject(GameFontNormal);
    else
        frame.points:SetFontObject(GameFontNormalSmall);
    end
    frame.points:SetText(points);

    if ( points == 0 ) then
        frame.points:Hide();
        frame.Shield:SetTexture([[Interface\AchievementFrame\UI-Achievement-Shields-NoPoints]]);
    else
        frame.points:Show();
        frame.Shield:SetTexture([[Interface\AchievementFrame\UI-Achievement-Shields]]);
    end

    frame.icon:SetTexture(icon);

    frame.PlayerAchievementBackground:SetShown(not isGuild);
    frame.GuildAchievementBackground:SetShown(isGuild);

    if isGuild then
        frame:SetWidth(312);
        frame.Name:SetWidth(170);
        frame.Name:SetText(name);
        frame.NameLong:SetWidth(170);
        frame.NameLong:SetText(name);
        frame.NameLong:SetPoint("CENTER", frame.Name, "CENTER", 0, 0);
        local isLongName = frame.Name:IsTruncated();
        frame.Name:SetShown(not isLongName);
        frame.NameLong:SetShown(isLongName);
        frame.shine = frame.GuildAchievementBackground.Shine;
        frame.glow = frame.GuildAchievementBackground.Glow;
        if not frame.guildDisplay then
            frame.guildDisplay = true;
            frame:SetHeight(98);
            frame.unlockedText:SetText( string.upper(GUILD_ACHIEVEMENT_UNLOCKED) );
            frame.points:SetVertexColor(0, 1, 0);
            frame.Shield:SetTexCoord(0, 0.5, 0.5, 1);
            frame.Shield:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 14);
            frame.guildName:Show();
            frame.GuildBorder:Show();
            frame.GuildBanner:Show();
            frame.icon:SetSize(45, 45);
            frame.decor:Hide();
        end
        frame.guildName:SetText( GetGuildInfo("player") );
        SetSmallGuildTabardTextures("player", nil, frame.GuildBanner, frame.GuildBorder);
        frame.points:SetPoint("CENTER", frame.Shield, "CENTER", -1, 3);
    else
        frame.Name:SetWidth(0);
        frame.Name:SetText(name);
        frame.NameLong:SetText(name);
        frame.Name:Show();
        frame.NameLong:Hide();
        frame.shine = frame.PlayerAchievementBackground.ShineMask;
        frame.glow = frame.PlayerAchievementBackground.Glow;
        frame.PlayerAchievementBackground.Ribbon:SetHeight(24);
        frame.PlayerAchievementBackground.Ribbon:SetPoint("BOTTOM", 0, 21);
        local frameWidth;
        local textWidth = frame.Name:GetWidth();
        local extra = textWidth - 170;
        if extra > 0 then
            if extra > 64 then
                extra = 64;
                frame.Name:Hide();
                frame.NameLong:Show();
                frame.NameLong:SetWidth(170 + extra);
                frame.NameLong:SetPoint("CENTER", frame.Name, "CENTER", 0, -2);
                frame.PlayerAchievementBackground.Ribbon:SetHeight(32);
                frame.PlayerAchievementBackground.Ribbon:SetPoint("BOTTOM", 0, 16);
            end
            frameWidth = 312 + extra;
        else
            frameWidth = 312;
        end
        frame.PlayerAchievementBackground:SetWidth(frameWidth);
        frame.PlayerAchievementBackground.ShineMask.animIn.Translation:SetOffset(frameWidth + 78, 0);
        frame:SetWidth(frameWidth);

        if frame.guildDisplay then
            frame.guildDisplay = nil;
            frame:SetHeight(78);
            --frame.unlockedText:SetText( string.upper(ACHIEVEMENT_UNLOCKED) );
            frame.points:SetVertexColor(1, 0.82, 0);
            frame.Shield:SetTexCoord(0, 0.5, 0, 0.45);
            frame.Shield:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14);
            frame.guildName:Hide();
            frame.GuildBorder:Hide();
            frame.GuildBanner:Hide();
            frame.icon:SetSize(52, 52);
            frame.decor:Show();
        end

        local texY;
        if flags == 131072 then
            texY = 0.5;
        else
            texY = 0;
        end
        frame.PlayerAchievementBackground.Ribbon:SetTexCoord(0, 1, texY, texY + 0.3125);

        frame.unlockedText:SetText( string.upper(ACHIEVEMENT_UNLOCKED) );
        frame.points:SetPoint("CENTER", frame.Shield, "CENTER", 0, 0);
    end

    SetSmallFont(frame.unlockedText);

    return true
end

local function CriteriaAlertFrame_SetUp(frame, achievementID, criteriaString)
    frame.id = achievementID;
    frame.name:SetText(criteriaString);
    frame.unlockedText:SetText( string.upper(ACHIEVEMENT_PROGRESSED) );
    SetSmallFont(frame.unlockedText);
end



---- Alert System ----
local AchievementAlertUtil = {};
addon.AchievementAlertUtil = AchievementAlertUtil;

function AchievementAlertUtil:Enable()
    if not AlertFrame then return end;

    if not self.achievementAlertSystem then
        self.achievementAlertSystem = AlertFrame:AddQueuedAlertFrameSubSystem("NarciAchievementAlertFrameTemplate", AchievementAlertFrame_SetUp, 2, 6);
    end
    if not self.criteriaAlertSystem then
        self.criteriaAlertSystem = AlertFrame:AddQueuedAlertFrameSubSystem("NarciCriteriaAlertFrameTemplate", CriteriaAlertFrame_SetUp, 2, 0);
    end

    if not self.listener then
        self.listener = CreateFrame("Frame");
        self.listener:SetScript("OnEvent", function(self, event, ...)
            if event == "ACHIEVEMENT_EARNED" then
                self.achievementAlertSystem:AddAlert(...);
            elseif event == "CRITERIA_EARNED" then
                self.criteriaAlertSystem:AddAlert(...);
            end
        end)
    end

    self.listener:RegisterEvent("ACHIEVEMENT_EARNED");
    self.listener:RegisterEvent("CRITERIA_EARNED");

    AlertFrame:UnregisterEvent("ACHIEVEMENT_EARNED");
    AlertFrame:UnregisterEvent("CRITERIA_EARNED");
end

function AchievementAlertUtil:Disable()
    if self.listener then
        self.listener:UnregisterEvent("ACHIEVEMENT_EARNED");
        self.listener:UnregisterEvent("CRITERIA_EARNED");
        AlertFrame:RegisterEvent("ACHIEVEMENT_EARNED");
        AlertFrame:RegisterEvent("CRITERIA_EARNED");
    end
end

function AchievementAlertUtil.AlertFrame_OnClick(self, button, down)
    if button == "RightButton" then
        self:StopAnimating();
        self:Hide();
        return
    end

    if not self.id then return end;

    if Narci_AchievementFrame then
        Narci_AchievementFrame:LocateAchievement(self.id);
    else
        Narci.LoadAchievementPanel(self.id);
    end
end

------------------------------------------------------------------------------------------------------
--/run NarciAchievementAlertSystem:AddAlert(13699)
--/run NarciAchievementAlertSystem:AddAlert(15407)
--/run NarciAchievementAlertSystem:AddAlert(5159)
--/run NarciAchievementAlertSystem:AddAlert(4958)
--/run NarciAchievementAlertSystem:AddAlert(11572)
------------------------------------------------------------------------------------------------------