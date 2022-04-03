local _, addon = ...

local ag = addon.CreateActionGroup("EquipmentOption");
ag.repeatInterval = 0.125;

ag:SetButtonDescription("A", "Select");
ag:SetButtonDescription("B", "Return");

function ag:Init()
    self.frame = Narci_EquipmentOption;
    self.meunButtons = self.frame.meunButtons;
    self.menuIndex = 1;
end

function ag:PlaceButtonNote()
    if self.currentObj then
        self.pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "", self.currentObj, "RIGHT", self.currentObj, "RIGHT", -8, 0);
    end
end

function ag:Navigate(x, y)
    local hold, propagate;
    if y > 0 then
        if self.menuIndex > 1 then
            self.menuIndex = self.menuIndex - 1;
            hold = true;
        end
    elseif y < 0 then
        if self.menuIndex < self.menuMaxIndex then
            self.menuIndex = self.menuIndex + 1;
            hold = true;
        end
    end
    local obj = self.meunButtons[self.menuIndex];
    self:Enter(obj);
    self:PlaceButtonNote();

    return hold, propagate
end

function ag:KeyDown(key)
    if key == "PAD1" then
        if self.currentObj then
            self.currentObj:Click();
        end
    elseif key == "PAD2" then
        self.frame:CloseUI();
    end
end

function ag:OnActiveCallback(resetIndex)
    self.menuMaxIndex = self.frame:GetNumActiveButtons();
    if resetIndex then
        self.menuIndex = 1;
    else
        if self.menuIndex > self.menuMaxIndex then
            self.menuIndex = self.menuMaxIndex;
        end
    end
    self:Enter(self.meunButtons[self.menuIndex]);
    self:PlaceButtonNote();
    addon.GamePadNavBar:SelectButtonByID(1);
end

function ag:ResetNavigation()
    self.pad1 = nil;
end