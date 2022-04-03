local _, addon = ...

local ag = addon.CreateActionGroup("Soulbind");
ag.repeatInterval = 0.25;

function ag:Init()
    self.characters = Narci_SoulbindsFrame.buttons;
    self.activateButton = Narci_SoulbindsFrame.ActivateButton;
    self.maxIndex = 3;
    self.index = 0;
end

function ag:OnActiveCallback()
    self.index = 1;
    for i = 1, #self.characters do
        if self.characters[i].isSelected then
            self.index = i;
            break
        end
    end
    self:Navigate(0, 0);
    addon.GamePadNavBar:SelectButtonByID(4);
end

function ag:Navigate(x, y)
    local hold, valid;
    if y > 0 or x < 0 then
        if self.index > 1 then
            self.index = self.index - 1;
            hold = true;
            valid = true;
        else
            return
        end
    elseif y < 0 or x > 0 then
        if self.index <self.maxIndex then
            self.index = self.index + 1;
            hold = true;
            valid = true;
        else
            return
        end
    elseif x == 0 then
        valid = true;
    end
    if valid then
        self:Enter(self.characters[self.index], true);
        self:Click();
        local pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "", Narci_Attribute, "RIGHT", self.currentObj, "LEFT", -4, 0);
        if self.activateButton.isVisible then
            self.pad3 = addon.GamePadButtonPool:SetupButton("PAD3", "", Narci_Attribute, "CENTER", self.activateButton, "LEFT", 4, 0);
        elseif self.pad3 then
            self.pad3:Hide();
        end
    end
end

function ag:KeyDown(key)
    if key == "PAD1" then
        self:Click();
    elseif key == "PAD2" then
        addon.SelectActionGroup("CharacterFrame", 3);
    elseif key == "PAD3" then
        if self.activateButton:IsEnabled() then
            self.activateButton:Click();
            if self.pad3 then
                self.pad3:Hide();
            end
        end
    end
end

function ag:Switch(x)
    if x < 0 then
        Narci_NavBar:SelectTab(2);
    elseif x > 0 then
        Narci_NavBar:SelectTab(4);
    end
end

function ag:ResetNavigation()
    self.pad3 = nil;
end