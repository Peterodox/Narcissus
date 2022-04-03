local _, addon = ...

local ag = addon.CreateActionGroup("EnhancementList");
ag.repeatInterval = 0.125;

function ag:Init()
    self.frame = Narci_EquipmentOption.ItemList;
    self.itemButtons = self.frame:GetItemButtons();
    self.filter = self.frame.FilterToggle;
    self.index = 1;
    self.GemActionButton = self.frame.GemActionButton;
    self.EnchantActionButton = NarciEquipmentEnchantActionButton;

    hooksecurefunc(self.GemActionButton, "MarkActive", function(f, isActive)
        self.gemActionActive = isActive;
        if not isActive then
            if self.pad3 then
                self.pad3:Hide();
                self.pad3 = nil;
            end
            addon.ClickProxy:Remove();
        end
    end);

    hooksecurefunc(self.EnchantActionButton, "MarkActive", function(f, isActive)
        self.enchantActionActive = isActive;
        if isActive then
            addon.ClickProxy:SetRunMacro( self.EnchantActionButton:GetMacroText() );
        else
            if self.pad3 then
                self.pad3:Hide();
                self.pad3 = nil;
            end
            addon.ClickProxy:Remove();
        end
    end);
end

function ag:PlaceButtonNote()
    if self.currentObj and self.currentObj:IsShown() then
        self.pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "", self.currentObj, "RIGHT", self.currentObj, "RIGHT", -8, 0);
    elseif self.pad1 then
        self.pad1:Hide();
    end
end

function ag:Navigate(x, y)
    if self.gemActionActive then
        self.frame:ClearActionButtons();
        return
    elseif self.enchantActionActive then
        self.frame:ClearActionButtons();
        return
    end

    if self.currentObj and self.currentObj.i then
        self.index = self.currentObj.i;
    end
    local hold, propagate;
    local scroll = 0;
    if y > 0 then
        self.index = self.index - 1;
        if self.index <= 1 then
            scroll = 1;
        end
        hold = true;
    elseif y < 0 then
        self.index = self.index + 1;
        if self.index >= 6 then
            scroll = -1
        end
        hold = true;
    end
    if self.index < 1 then
        self.index = 1;
    elseif self.index > 6 then
        self.index = 6;
    end
    local obj = self.itemButtons[self.index];
    if obj:IsShown() then
        self:Enter(obj);
        self:PlaceButtonNote();
        self.frame:ScrollByOneButton(scroll);
        return hold, propagate
    end
end

function ag:KeyDown(key)
    if self.gemActionActive then
        if key == "PAD3" then
            self.GemActionButton:Click("LeftButton");
        else
            self.frame:ClearActionButtons();
            self:PlaceButtonNote();
        end
        return
    elseif self.enchantActionActive then
        local hold, propagate;
        if key == "PAD3" then
            if self.EnchantActionButton.isActive then
                propagate = true;   --click enchant action button
                self.EnchantActionButton:PostClick("LeftButton");
                ClearCursor();  --failed when using gamepad why??
                --SetGamePadCursorControl(false);   --this failed too
            end
        else
            self.frame:ClearActionButtons();
            self:PlaceButtonNote();
        end
        return hold, propagate
    end

    if key == "PAD1" then
        if self.currentObj then
            if self.currentObj:IsEnabled() then
                self.currentObj:Click();
                self.pad3 = addon.GamePadButtonPool:SetupButton("PAD3", "Confirm", Narci_Character, "CENTER", self.currentObj, "LEFT", 0, 0, 1);    --execute
                self.pad3:PlayEntrance();
            end
        end
    elseif key == "PAD2" then
        self.frame:GetParent():ShowMenu();
    elseif key == "PAD4" then
        self.filter:Click();
        self:OnActiveCallback();
    end
end

function ag:OnActiveCallback()
    self.index = 2;
    C_Timer.After(0, function()
        self:Enter(self.itemButtons[self.index]);
        self:PlaceButtonNote();
    end)
    local pad4 = addon.GamePadButtonPool:SetupButton("PAD4", "", self.frame, "LEFT", self.filter, "RIGHT", 6, 0);
end

function ag:ResetNavigation()
    self.index = 1;
    self.gemActionActive = nil;
    self.enchantActionActive = nil;
end