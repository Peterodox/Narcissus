local _, addon = ...


---@class StatSheetController
local StatSheetController = {};
addon.StatSheetController = StatSheetController;


---@type [StatSheetFrame]
StatSheetController.frames = {};


---@param statFrame StatSheetFrame
function StatSheetController:AddStatFrame(statFrame)
    table.insert(self.frames, statFrame);
end

function StatSheetController:PropagateMethod(method, ...)
    for  _, statFrame in ipairs(self.frames) do
        statFrame[method](statFrame, ...);
    end
end

function StatSheetController:LazyRefresh()
    self:PropagateMethod("LazyRefresh");
end

function StatSheetController:InstantRefresh()
    self:PropagateMethod("RequestFullUpdate");
end

function StatSheetController:SetIntroAnimationDelay(secondsPerRow)
    self:PropagateMethod("SetIntroAnimationDelay", secondsPerRow);
end

function StatSheetController:PlayIntroAnimation()
    self:PropagateMethod("PlayIntroAnimation");
end

---Assign the RadarChartFrame for private access
---RadarChart only exists on Retail
function StatSheetController:AssignRadarChart(radarChart)
    self.radarChart = radarChart;
end

function StatSheetController:SetRadarChartShown(state)
    if self.radarChart then
        self.radarChart:SetShown(state);
    end
end

function StatSheetController:ShowDetailedStats(state)
    if Narci_Attribute and Narci_Attribute:IsVisible() then
        for  _, statFrame in ipairs(self.frames) do
            statFrame:SetShown((statFrame.isDetailed and state) or (not statFrame.isDetailed and not state));
        end
        self:InstantRefresh();
    else
        for  _, statFrame in ipairs(self.frames) do
            statFrame:SetShown((statFrame.isDetailed and state) or (not statFrame.isDetailed and not state));
        end
    end
    self:SetRadarChartShown(state);
end

function StatSheetController:ShowStatSheet()
    StatSheetController:ShowDetailedStats(NarcissusDB and NarcissusDB.DetailedIlvlInfo);
end

---When switching to "ShowChallenge" from NavBar, hide all sheets include RadarChartFrame
function StatSheetController:HideStatSheet()
    for  _, statFrame in ipairs(self.frames) do
        statFrame:Hide();
    end
    self:SetRadarChartShown(false);
end

--When switching to "ShowSets" (Equipment Set Manager), show RadarChartFrame and hide other frames
function StatSheetController:ShowRadarChartOnly()
    for  _, statFrame in ipairs(self.frames) do
        statFrame:Hide();
    end
    self:SetRadarChartShown(true);
end
