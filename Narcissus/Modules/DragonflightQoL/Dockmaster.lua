do
    local _, addon = ...;

    local function CheckCampaignStatus()
        local campaignID = 165;
        local campaignState = C_CampaignInfo.GetState(campaignID);
        if (not campaignState) or campaignState == 1 then
            return
        end

        local isBlueFaction = UnitFactionGroup("player") == "Alliance";
        local keyQuestID, keyZoneText;
        if isBlueFaction then
            keyQuestID = 67700;
            keyZoneText = C_Map.GetAreaInfo(4411) or "Stormwind Harbor";
        else
            keyQuestID = 67700;
            keyZoneText = C_Map.GetAreaInfo(4411) or "Stormwind Harbor";
        end

        if C_QuestLog.IsQuestFlaggedCompleted(keyQuestID) then
            return
        end

        print("Watch Boat")
        local IsFlyableArea = IsFlyableArea;
        local GetMinimapZoneText = GetMinimapZoneText;


        local EventListener = CreateFrame("Frame");
        if campaignState == 0 then
            EventListener:RegisterEvent("PLAYER_LEVEL_UP");
        end

        local function GetShipETA()
            --requires to talk to Chrovo to get the buff "Waiting for the Rugged Dragonscale" during this game session   392634  C_UnitAuras.GetPlayerAuraBySpellID(392634)
            --the buff will be gone once you board the ship, but the API can still obtain correct data
            --there is also a range limit
            local info = C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo(4418);
            if info then
                --info.shownState 0/1
                return info.barValue, info.barMax
            end
        end

        local function UpdateCountdown()
            local eta, total = GetShipETA();
            if eta and total then
                if total <= 0 or eta == 0 then
                    print("The ship has arrived");
                else
                    print(string.format("The ship will arrive in %s seconds", eta));
                end
            else
                print("No Data")
            end
        end

        local function IsShipToDragonIsleArrived()
            local eta = GetShipETA();
            return eta and eta <= 15
        end

        local function IsPlayerOnShip()
            local mapID = C_Map.GetBestMapForUnit("player");
            local position, x, y;
            if mapID == 84 then
                position = C_Map.GetPlayerMapPosition(mapID, "player");
                x, y = position:GetXY();
                if x < 0.2260 and y < 0.5730 and x > 0.2090 and y > 0.5564 then
                    return true;
                end
            elseif mapID == 0 then
        
            end
        end

        local function OnRightShipBoarded()
            EventListener:UnregisterAllEvents();
            EventListener:SetScript("OnUpdate", nil);
            EventListener:SetScript("OnEvent", nil);
        end

        local function OnFlyableChanged_Callback(self, elapsed)
            self.t = self.t + elapsed;
            if self.t >= 0.5 then
                self:SetScript("OnUpdate", nil);
                self.t = nil;
                if IsPlayerOnShip() then
                    if IsShipToDragonIsleArrived() then
                        print("Right Boat");
                        OnRightShipBoarded();
                    else
                        print("Wrong Boat");
                    end
                else
                    print("Off Boat");
                end
            end
        end

        local function OnEnteringKeyQuestZone(state)
            if state == EventListener.inQuestZone then
                return
            else
                EventListener.inQuestZone = state;
            end
            if state then
                EventListener:RegisterEvent("ACTIONBAR_UPDATE_USABLE"); --assume mount is on the ActionBar
                EventListener:RegisterEvent("UPDATE_UI_WIDGET");
                EventListener:RegisterUnitEvent("UNIT_AURA", "player");
                UpdateCountdown();
                print("inQuestZone");
            else
                EventListener:UnregisterEvent("ACTIONBAR_UPDATE_USABLE");
                EventListener:UnregisterEvent("UPDATE_UI_WIDGET");
                EventListener:UnregisterEvent("UNIT_AURA");
                print("not inQuestZone");
            end
        end

        local function OnKeyQuestAccepted()
            EventListener:RegisterEvent("ZONE_CHANGED");
            OnEnteringKeyQuestZone(GetMinimapZoneText() == keyZoneText);
            print("Accepted")
        end

        if not C_QuestLog.IsOnQuest(keyQuestID) then
            EventListener:RegisterEvent("QUEST_ACCEPTED");
        else
            OnKeyQuestAccepted();
        end


        EventListener:SetScript("OnEvent", function(self, event, ...)
            print(event)
            if event == "PLAYER_LEVEL_UP" then
                local newLevel = ...
                if newLevel >= 58 then
                    self:UnregisterEvent(event);
                    self:RegisterEvent("QUEST_ACCEPTED");
                end
            elseif event == "QUEST_ACCEPTED" then
                local questID = ...
                if questID == keyQuestID then
                    self:UnregisterEvent(event);
                    OnKeyQuestAccepted();
                end
            elseif event == "ACTIONBAR_UPDATE_USABLE" then
                local flyable = IsFlyableArea();
                if flyable ~= self.flyable then
                    self.flyable = flyable;
                    if flyable then
                        self.t = 0;
                        self:SetScript("OnUpdate", OnFlyableChanged_Callback);
                    else
                        self:SetScript("OnUpdate", nil);
                    end
                end
            elseif event == "UPDATE_UI_WIDGET" then
                UpdateCountdown();
            elseif event == "ZONE_CHANGED" then
                local zoneText = GetMinimapZoneText();
                OnEnteringKeyQuestZone(zoneText == keyZoneText);
            elseif event == "UNIT_AURA" then
                local unitTarget, isFullUpdate, updatedAuras = ...
                UpdateCountdown();
            end

        end)
    end

    addon.AddInitializationCallback(CheckCampaignStatus);
end

if true then return end;

--DEVTOOLS_MAX_ENTRY_CUTOFF
--[[
    campaignID 165, chapterIDs = {1289}
    C_CampaignInfo.GetState(165);   0 invalid  1 complete  2 inProgress  3 Stalled

    widgetID 4556, 4418(Alliance, before arrival)
    widgetType 2
    widgetSetID 729

    /dump C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo(4418)
    -barMax 300(not arrived) 0(arrived)
    --barValue

    C_QuestLog.GetQuestObjectives(67700)

    IsFlyableArea();    --not flyable near the dock

    Alliance
    Docketmaster Kultiras Aron Kyleson 142641       arrival ~ 214s  leave ~ 154s
    Captain Ironbridge of the Rugged Dragonscale 184288 --seems to only yell when you haven't complete the first criteria


    local mapID = C_Map.GetBestMapForUnit("player");  --84
    local position = C_Map.GetPlayerMapPosition(84, "player");

    0.2247, 0.5636
--]]