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

function StatSheetController:LazyRefresh()
    for  _, statFrame in ipairs(self.frames) do
        statFrame:LazyRefresh();
    end
end

function StatSheetController:InstantRefresh()
    for _, statFrame in ipairs(self.frames) do
        statFrame:RequestFullUpdate();
    end
end
