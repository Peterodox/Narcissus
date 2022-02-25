local function SetSmallFont(object)
    local path, height = GameFontBlackTiny:GetFont();
    object:SetFont(path, 9);
end

local function AchievementAlertFrame_SetUp(frame, achievementID, alreadyEarned)
    local _, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuildAch, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementID);
    frame.id = achievementID;

    if ( points < 100 ) then
        frame.points:SetFontObject(GameFontNormal);
    else
        frame.points:SetFontObject(GameFontNormalSmall);
    end
    frame.points:SetText(points);

    if ( points == 0 ) then
        frame.points:Hide();
        frame.shield:SetTexture([[Interface\AchievementFrame\UI-Achievement-Shields-NoPoints]]);
    else
        frame.points:Show();
        frame.shield:SetTexture([[Interface\AchievementFrame\UI-Achievement-Shields]]);
    end

    frame.name:SetText(name);
    frame.nameLong:SetText(name);
    local isLongName = frame.name:IsTruncated();
    frame.name:SetShown(not isLongName);
    frame.nameLong:SetShown(isLongName);

    frame.icon:SetTexture(icon);

    local offsetY;
    
    if isGuildAch then
        if not frame.guildDisplay then
            frame.guildDisplay = true;
            frame:SetHeight(98);
            frame.background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameGuildBackground");
            frame.background:SetTexCoord(0, 1, 0.1875, 0.8125);
            frame.mask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameGuildMask");
            frame.mask:SetHeight(156);
            frame.unlockedText:SetText( string.upper(GUILD_ACHIEVEMENT_UNLOCKED) );
            frame.points:SetVertexColor(0, 1, 0);
            frame.shield:SetTexCoord(0, 0.5, 0.5, 1);
            frame.shield:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 14);
            frame.guildName:Show();
            frame.GuildBorder:Show();
            frame.GuildBanner:Show();
            frame.icon:SetSize(45, 45);
            frame.glow:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameGuildGlow");
            frame.shine:SetSize(98, 98);
            frame.shine:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameGuildShine");
            frame.shineMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameGuildShineMask");
            offsetY = 3;
        end
        frame.guildName:SetText( GetGuildInfo("player") );
        SetSmallGuildTabardTextures("player", nil, frame.GuildBanner, frame.GuildBorder);
        frame.points:SetPoint("CENTER", frame.shield, "CENTER", -1, 3);
    else
        if frame.guildDisplay then
            frame.guildDisplay = nil;
            frame:SetHeight(78);
            frame.background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameBackground");
            frame.mask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameMask");
            frame.mask:SetHeight(78);
            --frame.unlockedText:SetText( string.upper(ACHIEVEMENT_UNLOCKED) );
            frame.points:SetVertexColor(1, 0.82, 0);
            frame.shield:SetTexCoord(0, 0.5, 0, 0.45);
            frame.shield:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14);
            frame.guildName:Hide();
            frame.GuildBorder:Hide();
            frame.GuildBanner:Hide();
            frame.icon:SetSize(52, 52);
            frame.glow:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameGlow");
            frame.shine:SetSize(78, 78);
            frame.shine:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameShine");
            frame.shineMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Achievement\\Classic\\AlertFrameShineMask");
            offsetY = 0;
        end
        if flags == 131072 then
            frame.background:SetTexCoord(0, 1, 0.5, 1);
        else
            frame.background:SetTexCoord(0, 1, 0, 0.5);
        end
        frame.unlockedText:SetText( string.upper(ACHIEVEMENT_UNLOCKED) );
        frame.points:SetPoint("CENTER", frame.shield, "CENTER", -1, 0);
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



local EventListener = CreateFrame("Frame");

EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "ACHIEVEMENT_EARNED" then
        NarciAchievementAlertSystem:AddAlert(...);
    elseif event == "CRITERIA_EARNED" then
        NarciCriteriaAlertSystem:AddAlert(...);
    end
end)


------------------------------------------------------------------------------------------------------
--Public:
--/run NarciAchievementAlertSystem:AddAlert(13994, true)
NarciCriteriaAlertSystem = AlertFrame:AddQueuedAlertFrameSubSystem("NarciCriteriaAlertFrameTemplate", CriteriaAlertFrame_SetUp, 2, 0);
NarciAchievementAlertSystem = AlertFrame:AddQueuedAlertFrameSubSystem("NarciAchievementAlertFrameTemplate", AchievementAlertFrame_SetUp, 2, 6);

function NarciAchievementAlertSystem:Enable()
    EventListener:RegisterEvent("ACHIEVEMENT_EARNED");
    EventListener:RegisterEvent("CRITERIA_EARNED");
    if AlertFrame then
        AlertFrame:UnregisterEvent("ACHIEVEMENT_EARNED");
        AlertFrame:UnregisterEvent("CRITERIA_EARNED");
    end
end

function NarciAchievementAlertSystem:Disable()
    EventListener:UnregisterEvent("ACHIEVEMENT_EARNED");
    EventListener:UnregisterEvent("CRITERIA_EARNED");
    if AlertFrame then
        AlertFrame:RegisterEvent("ACHIEVEMENT_EARNED");
        AlertFrame:RegisterEvent("CRITERIA_EARNED");
    end
end


function NarciAchievementAlertFrame_OnClick(self, button, down)
    if( AlertFrame_OnClick(self, button, down) ) then
        return;
    end
    local id = self.id;
    if ( not id ) then
        return;
    end

    if Narci_AchievementFrame then
        Narci_AchievementFrame:LocateAchievement(id);
    else
        Narci.LoadAchievementPanel(id);
    end
end

------------------------------------------------------------------------------------------------------
--/run NarciAchievementAlertSystem:AddAlert(13699)
--/run NarciAchievementAlertSystem:AddAlert(5159)

------------------------------------------------------------------------------------------------------