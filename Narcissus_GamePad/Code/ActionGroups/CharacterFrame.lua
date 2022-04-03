local _, addon = ...

local ag = addon.CreateActionGroup("CharacterFrame");

ag:SetButtonDescription("A", "Select");
ag:SetButtonDescription("B", "Cancel");
ag:SetButtonDescription("X", "Use");

local NavBar = Narci_NavBar;
local AttributeFrame = Narci_Attribute;

function ag:Init()
    self.frames = {
        [1] = Narci_TitleManager_Switch,
    };
    self.col = 1;   --Left: CharacterFrame, Right: Title, NavBar
    self.row = 0;
    self.maxRow = 1;
end

function ag:KeyDown(key)
    if key == "PAD1" then
        if self.currentObj and self.currentObj.OnClick then
            self.currentObj:OnClick("LeftButton");
        end
    end
end

function ag:PlaceButtonNote()
    if self.currentObj then
        if self.row == 1 then
            self.pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "", AttributeFrame, "RIGHT", self.currentObj, "LEFT", -4, 0);
        else
            self.pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "", AttributeFrame, "CENTER", self.currentObj, "TOP", 0, 5);
        end
    end
end

function ag:Navigate(x, y)
    if self.col == 1 then
        if x < 0 or y < 0 then
            addon.SelectActionGroup("EquipmentSlot", 1);    --topleft
        elseif x > 0 then
            addon.SelectActionGroup("EquipmentSlot", 2);    --topright
        elseif y > 0 then
            addon.SelectActionGroup("EquipmentSlot", 3);    --bottomleft
        end
    elseif self.col == 2 then
        local hold, valid;
        if y > 0 or x < 0 then
            self.row = self.row - 1;
            if self.row < 1 then
                self.row = 1;
            else
                valid = true;
                hold = true;
            end
        elseif y < 0 or x > 0 then
            self.row = self.row + 1;
            if self.row > self.maxRow then
                self.row = self.maxRow;
            else
                hold = true;
                valid = true;
            end
        end
        if valid then
            self:Enter(self.frames[self.row]);
            self:PlaceButtonNote();
        end
        return hold
    end
end

function ag:Switch(x)
    --x > 0 PADRSHOULDER, x < 0 PADLSHOULDER
    if x < 0 then
        if self.row > 1 then
            self.row = self.row - 1;
            self.col = 2;
            self:Enter(self.frames[self.row]);
            self:PlaceButtonNote();
            if self.row > 1 then
                self:Click();
            end
        else
            self.col = 1;
            addon.SelectActionGroup("EquipmentSlot", 4);
        end
    elseif x > 0 then
        self.col = 2;
        self:Navigate(1, 0);
        if self.row > 1 then
            self:Click();
        end
    end
end

function ag:OnActiveCallback(mode)
    local tabs, numTabs = NavBar:GetTabButtons();
    for i = 2, 2 + numTabs do
        self.frames[i] = tabs[i - 1];
    end
    self.maxRow = 1 + numTabs;
    tabs = nil;

    if mode then
        if mode == 0 then
            --Activate from equipment slot
            self.col = 2;
            if self.row == 0 then
                self.row = 1;
            end
        else
            --Activate by clicking NavBar
            self.col = 2;
            self.row = mode + 1;
            if self.row > self.maxRow then
                self.row = self.maxRow;
            end
        end
    end
    if self.row > 0 then
        self:Enter(self.frames[self.row]);
        self:PlaceButtonNote();
    end
end

function ag:ResetNavigation()
    self.col = 1;
    self.row = 0;
    self.pad1 = nil;
end