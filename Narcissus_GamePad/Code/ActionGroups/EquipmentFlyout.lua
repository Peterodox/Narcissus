local _, addon = ...


local ag = addon.CreateActionGroup("SwapItem");
ag.repeatInterval = 0.25;

local BUTTONS_PER_ROW = 5;
local SlotBorder = NarciGamePadOverlay.SlotBorder;

function ag:Init()
    self.frame = Narci_EquipmentFlyoutFrame;
    self.buttons = self.frame.buttons;
    self.row = 1;
    self.col = 1;
    self.maxIndex = 1;
    self.index = 0;
end

function ag:OnActiveCallback(slotChanged)
    self.maxIndex = self.frame.numDisplayedItems or 0;
    if slotChanged then
        self.index = 0;
        self.currentObj = nil;
    else
        if self.index > self.maxIndex then
            self.index = self.maxIndex;
        end
        self:Enter(self.buttons[self.index]);
    end
    addon.GamePadNavBar:SelectButtonByID(1);
end

function ag:Navigate(x, y)
    local hold, valid;

    if self.index == 0 then
        --select the first item on any press
        self.index = 1;
        valid = true;
    else
        if x > 0 then
            if self.index < self.maxIndex then
                self.index = self.index + 1;
                hold = true;
                valid = true;
            end
        elseif x < 0 then
            if self.index > 1 then
                self.index = self.index - 1;
                hold = true;
                valid = true;
            end
        elseif y > 0 then
            if self.index > 1 then
                if self.index - BUTTONS_PER_ROW >= 1 then
                    self.index = self.index - BUTTONS_PER_ROW;
                    hold = true;
                else
                    self.index = 1;
                end
                valid = true;
            end
        elseif y < 0 then
            if self.index < self.maxIndex then
                if self.index + BUTTONS_PER_ROW  <= self.maxIndex then
                    self.index = self.index + BUTTONS_PER_ROW;
                    hold = true;
                else
                    self.index = self.maxIndex;
                end
                valid = true;
            end
        end
    end

    if valid then
        self:Enter(self.buttons[self.index]);
    end
    return hold
end

function ag:Enter(currentObj)
    self:Leave();
    if currentObj and currentObj.OnEnter then
        SlotBorder:AnchorToSlotButton(currentObj);
        currentObj:OnEnter(nil, true);
    end
    self.currentObj = currentObj;
end

function ag:KeyDown(key)
    if key == "PAD1" then
        if self.currentObj then
            self.currentObj:Click();
        end
    elseif key == "PAD2" then
        self.frame:Hide();
    end
end