local _, addon = ...

local LinearScrollUpdater = addon.LinearScrollUpdater;

local ag = addon.CreateActionGroup("TitleManager");
ag.repeatInterval = 0.125;

ag:SetButtonDescription("A", "Use");
ag:SetButtonDescription("B", "Return");
ag:SetButtonDescription("Y", "Sort");

function ag:Init()
    local manager = Narci_TitleFrame;
    self.frame = manager;
    self.switch = Narci_TitleManager_Switch;
    self.filter = manager.TitleList.FilterButton;
    self.scrollFrame = manager.TitleList.ScrollFrame;
    self.buttons = manager.TitleList.ScrollFrame.buttons;
    self.maxIndex = #self.buttons;
    self.tooltip = manager.TooltipFrame;
end

function ag:OnActiveCallback(mode)
    self.i = 0;
    C_Timer.After(0, function()
        local pad1, width = addon.GamePadButtonPool:SetupButton("PAD1", "Use", self.frame, "TOPLEFT", self.frame, "BOTTOMLEFT", 20, 8);
        if pad1 and width then
            local pad2 = addon.GamePadButtonPool:SetupButton("PAD2", "Back", self.frame, "TOPLEFT", self.frame, "BOTTOMLEFT", 48 + width, 8);
            local pad4 = addon.GamePadButtonPool:SetupButton("PAD4", "Sort", self.frame, "LEFT", self.filter, "RIGHT", -7, 5);
        end
    end);
    addon.GamePadNavBar:SelectButtonByID(2);
end

function ag:Click()
    if self.currentObj then
        self.currentObj:Click("LeftButton");
        return true
    end
end

function ag:KeyDown(key)
    if key == "PAD1" then
        self:Click();
    elseif key == "PAD2" then
        self.switch:Close();
        self.currentObj = nil;
    elseif key == "PAD4" then
        self.filter:Click();
    end
end

function ag:KeyUp(key)
    if LinearScrollUpdater:Stop() or key == "PAD4" then
        self.tooltip:OnScrollStopped();
    end
end

function ag:Navigate(x, y)
    --↑↓←→
    -- x > 0 PADDRIGHT, x < 0 PADDLEFT
    -- y > 0 PADDUP, x < 0 PADDDOWN
    if y > 0 then
        if self.i < 2 then
            LinearScrollUpdater:Start(self.scrollFrame, -240, true);
            self.tooltip:PauseAndHide();
        end
        if self.i > 0 then
            self.i = self.i - 1;
        end
    elseif y  < 0 then
        if self.i > 15 then
            LinearScrollUpdater:Start(self.scrollFrame, 240, true);
            self.tooltip:PauseAndHide();
        end
        if self.i < self.maxIndex then
            self.i = self.i + 1;
        end
    end
    self:Enter(self.buttons[self.i]);
    return true
end