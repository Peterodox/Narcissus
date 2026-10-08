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
    self:PropagateMethod("SetIntroAnimationDelay", secondsPerRow * 10);
end

function StatSheetController:PlayIntroAnimation()
    self:PropagateMethod("PlayIntroAnimation");
end
