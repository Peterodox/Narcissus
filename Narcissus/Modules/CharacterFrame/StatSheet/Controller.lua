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
        --self.radarChart:SetShown(state);
        if state then
            self.radarChart:FadeIn();
            self.radarChart:Update();
        else
            self.radarChart:FadeOut();
        end
    end
end

function StatSheetController:ShowDetailedStats(state)
    if not NarciViewUtil:IsViewingAttributes() then return; end

    for  _, statFrame in ipairs(self.frames) do
        if statFrame.isDetailed then
            if state then
                statFrame:FadeIn();
            else
                statFrame:FadeOut();
            end
        else
            if state then
                statFrame:FadeOut();
            else
                statFrame:FadeIn();
            end
        end
    end
    self:SetRadarChartShown(state);
    if Narci_Attribute and Narci_Attribute:IsVisible() then
        self:InstantRefresh();
    end
end

function StatSheetController:ShowStatSheet()
    StatSheetController:ShowDetailedStats(NarcissusDB and NarcissusDB.DetailedIlvlInfo);
end

---When switching to "ShowChallenge" from NavBar, hide all sheets include RadarChartFrame
function StatSheetController:HideStatSheet()
    for  _, statFrame in ipairs(self.frames) do
        statFrame:FadeOut();
    end
    self:SetRadarChartShown(false);
end

--When switching to "ShowSets" (Equipment Set Manager), show RadarChartFrame and hide other frames
function StatSheetController:ShowRadarChartOnly()
    for  _, statFrame in ipairs(self.frames) do
        statFrame:FadeOut();
    end
    self:SetRadarChartShown(true);
end

do -- Fade In/Out Animation
    local FadeUpdatorMixin = {};

    FadeUpdatorMixin.fadeInMultiplier = 5;
    FadeUpdatorMixin.fadeOutMultiplier = 5;

    function FadeUpdatorMixin:SnapToResult()
        self:SetScript("OnUpdate", nil);
        if self.result == 0 then
            self.alpha = 0;
            self.owner:Hide();
            self.owner:SetAlpha(0);
        else
            self.alpha = 1;
            self.owner:Show();
            self.owner:SetAlpha(1);
        end
    end

    function FadeUpdatorMixin:FadeIn()
        self.result = 1;
        self.owner:Show();
        if self.owner:IsVisible() then
            self.alpha = self.owner:GetAlpha();
            if self.alpha < 1 then
                self:SetScript("OnUpdate", self.OnUpdate_FadeIn);
                return;
            end
        end
        self:SnapToResult();
    end

    function FadeUpdatorMixin:FadeOut()
        self.result = 0;
        if self.owner:IsVisible() then
            self.alpha = self.owner:GetAlpha();
            if self.alpha > 0 then
                self:SetScript("OnUpdate", self.OnUpdate_FadeOut);
                return;
            end
        end
        self:SnapToResult();
    end

    function FadeUpdatorMixin:OnUpdate_FadeIn(elapsed)
        self.alpha = self.alpha + elapsed * self.fadeInMultiplier;
        if self.alpha >= 1 then
            self.alpha = 1;
            self.result = 1;
            self:SnapToResult();
        else
            self.owner:SetAlpha(self.alpha);
        end
    end

    function FadeUpdatorMixin:OnUpdate_FadeOut(elapsed)
        self.alpha = self.alpha - elapsed * self.fadeOutMultiplier;
        if self.alpha <= 0 then
            self.alpha = 0;
            self.result = 0;
            self:SnapToResult();
        else
            self.owner:SetAlpha(self.alpha);
        end
    end


    function StatSheetController:MakeFrameFadable(frame)
        if frame.fadeUpdator or frame.FadeIn or frame.FadeOut then return; end

        local fadeUpdator = CreateFrame("Frame");
        Mixin(fadeUpdator, FadeUpdatorMixin);

        frame.fadeUpdator = fadeUpdator;
        fadeUpdator.owner = frame;

        function frame:FadeIn()
            fadeUpdator:FadeIn();
        end

        function frame:FadeOut()
            fadeUpdator:FadeOut();
        end

        function frame:SnapToFadeResult()
            fadeUpdator:SnapToResult();
        end
    end
end
