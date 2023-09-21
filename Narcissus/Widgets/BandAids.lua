-- Various game bug fixes and QoL improvements

local _, addon = ...


do
    --10.1.5.50199
    --Auto-select "Reporting for duty"
    --(Fixed by BLZ in 10.1.7) Fix: Soridormi Reputation/Friendship Bar (uiMapID: 2199, 2025)

    local f = CreateFrame("Frame");
    local UnitName = UnitName;
    local SORIDORMI;
    local ENABLE_AUTO_REPORT = true;

    f:SetScript("OnEvent", function(self, event, ...)
        if ENABLE_AUTO_REPORT and UnitName("npc") == SORIDORMI then    --or use
            if GossipFrame and GossipFrame:IsShown() then
                --Auto Report-in
                local options = C_GossipInfo.GetOptions();
                if options and options[1] and options[1].gossipOptionID == 109275 then
                    C_GossipInfo.SelectOption(109275);  --Maybe we don't need to check if the option is availible at all
                    return
                end

                --GossipFrame.FriendshipStatusBar:Update(2553);
            end
        end
    end);

    local module = addon.CreateZoneTriggeredModule();
    module:SetValidZones(2025, 2199);

    local function OnEnabledCallback()
        if not SORIDORMI then
            SORIDORMI = NarciAPI.GetCreatureName(204450) or "Soridormi";
        end
        f:RegisterEvent("GOSSIP_SHOW");
    end

    local function OnDisabledCallback()
        f:UnregisterEvent("GOSSIP_SHOW");
    end

    module:SetOnEnabledCallback(OnEnabledCallback);
    module:SetOnDisabledCallback(OnDisabledCallback);

    addon.AddLoadingCompleteCallback(
        function ()
            NarciAPI.GetCreatureName(204450);
        end
    );
end


--[[
do
    local WidgetContainer;

    local function GetTimeRiftBeginCountdown()
        local widgetID = 4924;
        local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(widgetID);
        if info and info.hasTimer and info.text and info.text ~= "" then
            return NarciAPI.GetTimeFromAbbreviatedDurationText(info.text, true);
        else
            return 0
        end
    end

    local function FormatNumber(n)
        if n == 0 then
            n = "00";
        elseif n < 10 then
            n = "0"..n;
        end

        return n
    end

    local function SetupWidget()
        if not WidgetContainer then
            WidgetContainer = CreateFrame("Frame", nil, UIParent);
            WidgetContainer:SetSize(12, 12);
            WidgetContainer:SetPoint("TOP", UIParent, "TOP", 0, -12);
            WidgetContainer.Text = WidgetContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal");
            WidgetContainer.Text:SetJustifyH("CENTER");
            WidgetContainer.Text:SetPoint("CENTER", WidgetContainer, "CENTER", 0, 0);
            WidgetContainer.Text:SetTextColor(1, 1, 1, 0.5);
            WidgetContainer.t = 0;
            WidgetContainer.syncCounter = 0;
            WidgetContainer.secondsLeft = 0;
            WidgetContainer:SetScript("OnUpdate", function(self, elapsed)
                self.t = self.t + elapsed;
                if self.t >= 1 then
                    self.t = self.t - 1;
                else
                    return
                end

                self.syncCounter = self.syncCounter + 1;

                if self.syncCounter > 10 then
                    self.syncCounter = 0;
                    self.secondsLeft = GetTimeRiftBeginCountdown();
                else
                    self.secondsLeft = self.secondsLeft - 1;
                end

                if self.secondsLeft > 0 then
                    local minutes = math.floor(self.secondsLeft / 60);
                    local seconds = self.secondsLeft - 60*minutes;
    
                    minutes = FormatNumber(minutes);
                    seconds = FormatNumber(seconds);
    
                    self.Text:SetText(minutes..":"..seconds);
                else
                    self:Hide();
                end
            end);
        end
    end

    function ShowTimeRiftCountdown()
        SetupWidget();
        WidgetContainer.Text:SetText("");
        WidgetContainer.t = 1;
        local seconds = GetTimeRiftBeginCountdown();
        WidgetContainer.secondsLeft = seconds + 1;
        WidgetContainer:Show();
    end
end
--]]

--[[
do
    --10.1.7 (since 10.0.5?)
    --Moonkin Form with Glyph of Stars - white model in Paperdoll
    --Implemented as a standalone addon
    local _, _, classID = UnitClass("player");
    if classID ~= 11 then return end;

    local SPELL_MOONKIN_FORM = 24858;
    local SPELL_GLYPH = 114301;

    local HasAttachedGlyph = HasAttachedGlyph;
    local modelScene = CharacterModelScene;

    local function UpdatePlayerModel()
        local form = GetShapeshiftFormID();
        if not (form == 31 and HasAttachedGlyph(SPELL_MOONKIN_FORM)) then
            return
        end

        modelScene:ReleaseAllActors();
        modelScene:TransitionToModelSceneID(595, 1, 2, true);   --CHARACTER_SHEET_MODEL_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN
        local actor = modelScene:GetPlayerActor();
        if actor then
            local hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
            local sheatheWeapon = GetSheathState() == 1;
            local autodress = true;
            local hideWeapon = false;
            local useNativeForm = not inAlternateForm;
            actor:SetModelByUnit("player", sheatheWeapon, autodress, hideWeapon, useNativeForm);
            actor:SetAnimationBlendOperation(0);
            actor:SetSpellVisualKit(23368, false);
            actor:SetSpellVisualKit(27440, false);
        end
    end

    if PaperDollFrame_SetPlayer and modelScene then
        hooksecurefunc("PaperDollFrame_SetPlayer", UpdatePlayerModel);
    end

    
    --Avoid overwriting, possible taint?

    local ANIMAL_FORMS = ANIMAL_FORMS or {};

    if true then return end;

    function PaperDollFrame_SetPlayer()
        CharacterModelScene:ReleaseAllActors();
        CharacterModelScene:TransitionToModelSceneID(595, 1, 2, true);   --CHARACTER_SHEET_MODEL_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN

        local form = GetShapeshiftFormID();
        local isStarry;

        if form and not UnitOnTaxi("player") then
            if form == 31 and HasAttachedGlyph(SPELL_MOONKIN_FORM) then
                isStarry = true;
            else
                local actorTag = ANIMAL_FORMS[form] and ANIMAL_FORMS[form].actorTag or nil;
                if actorTag then
                    local actor = CharacterModelScene:GetPlayerActor(actorTag);
                    local creatureDisplayID = C_PlayerInfo.GetDisplayID();
                    if actor and creatureDisplayID then
                        actor:SetModelByCreatureDisplayID(creatureDisplayID);
                        actor:SetAnimationBlendOperation(MODEL_BLEND_OPERATION);
                        return
                    end
                end
            end
        end

        local actor = CharacterModelScene:GetPlayerActor();
        if actor then
            local hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
            local sheatheWeapon = GetSheathState() == 1;
            local autodress = true;
            local hideWeapon = false;
            local useNativeForm = not inAlternateForm;
            actor:SetModelByUnit("player", sheatheWeapon, autodress, hideWeapon, useNativeForm);
            actor:SetAnimationBlendOperation(MODEL_BLEND_OPERATION);

            if isStarry then
                actor:SetSpellVisualKit(23368, false);
                actor:SetSpellVisualKit(27440, false);
            end
        end
    end
end
--]]