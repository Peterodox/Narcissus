local _, addon = ...

local AttributeFrame = Narci_Attribute;
local ESM = Narci_EquipmentSetManager;
local GamePadButtonPool = addon.GamePadButtonPool;

local ag = addon.CreateActionGroup("SetManager");
ag.repeatInterval = 0.25;

function ag:Init()
    self.setButtons = ESM:GetSetButtons();
    self.setIndex = 1;

    self.scrollFrame = Narci_EquipmentSetManagerFrame.ListScrollFrame;
    self.scrollScript = self.scrollFrame:GetScript("OnMouseWheel");

    hooksecurefunc(ESM, "OnNumSetsChanged", function(f, numSets)
        if self.scrollFrame:IsShown() then
            self.numSets = numSets;
            if self.setIndex > numSets then
                self.setIndex = numSets;
            end
            self:Navigate(0, 0);
        end
    end);
end

function ag:OnActiveCallback()
    self.numSets = ESM:GetNumSetButtons();
    self.setIndex = 0;
    self.editMode = nil;

    self:Navigate(0, -1);
    addon.GamePadNavBar:SelectButtonByID(3);
end

function ag:ResetNavigation()

end

function ag:Navigate(x, y)
    local hold;
    if self.editMode then

    else
        --Browsing saved sets
        local moveDirection;
        if x > 0 or y < 0 then
            if self.setIndex < self.numSets then
                self.setIndex = self.setIndex + 1;
                hold = true;
                moveDirection = -1;
            else
                return
            end
        elseif x < 0 or y > 0 then
            if self.setIndex > 1 then
                self.setIndex = self.setIndex - 1;
                hold = true;
                moveDirection = 1;
            else
                return
            end
        end
        GamePadButtonPool:HideAllButtons();
        self:Enter(self.setButtons[self.setIndex]);
        if self.currentObj then
            if self.currentObj.setID then
                local pad1 = GamePadButtonPool:SetupButton("PAD3", "Equip", AttributeFrame, "TOPRIGHT", self.currentObj, "TOPLEFT", -4, 0, -1);
                local pad3 = GamePadButtonPool:SetupButton("PAD1", "Edit", AttributeFrame, "BOTTOMRIGHT", self.currentObj, "BOTTOMLEFT", -4, 0, -1);
            else
                --"New Set" button
                local pad3 = GamePadButtonPool:SetupButton("PAD1", "", AttributeFrame, "RIGHT", self.currentObj, "LEFT", -4, 0, -1);
            end

            if moveDirection then
                if moveDirection > 0 then
                    if self.currentObj:GetTop() > self.scrollFrame:GetTop() + 4 then
                        self.scrollScript(self.scrollFrame, 1);
                    end
                else
                    if self.currentObj:GetBottom() < self.scrollFrame:GetBottom() - 4 then
                        self.scrollScript(self.scrollFrame, -1);
                    end
                end
            end
        end
    end

    return hold
end

function ag:Switch(x)
    if x < 0 then
        Narci_NavBar:SelectTab(1);
    elseif x > 0 then
        Narci_NavBar:SelectTab(3);
    end
end

function ag:KeyDown(key)
    if self.editMode then
        if key =="PAD2" then
            if self.currentObj then
                self.currentObj.CancelButton:Click();
            end
            self.editMode = nil;
            self:Navigate(0, 0);
        elseif key == "PAD3" then
            if self.currentObj then
                self.currentObj.ConfirmButton:Click();
            end
            self.editMode = nil;
            self:Navigate(0, 0);
        end
    else
        if key == "PAD1" then
            self:Click("RightButton");
            self.editMode = true;
            GamePadButtonPool:HideAllButtons();
            if self.currentObj then
                local pad3 = GamePadButtonPool:SetupButton("PAD3", "", AttributeFrame, "BOTTOM", self.currentObj.ConfirmButton, "TOP", 0, 0);
                local pad2 = GamePadButtonPool:SetupButton("PAD2", "", AttributeFrame, "BOTTOM", self.currentObj.CancelButton, "TOP", 0, 0);
            end
        elseif key == "PAD3" then
            if self.currentObj and self.currentObj.setID then
                self.currentObj:OnDoubleClick("LeftButton");
            end
        elseif key == "PAD2" then
            addon.SelectActionGroup("CharacterFrame", 2);
        end
    end
end