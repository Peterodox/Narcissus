local _, addon = ...

local GamePadButtonPool = addon.GamePadButtonPool;
local AttributeFrame = Narci_Attribute;

local ag = addon.CreateActionGroup("MythicPlus");
ag.repeatInterval = 0.25;

function ag:Init()
    self.frame = Narci_CompetitiveDisplay.MythicPlus;
    self.cardButtons = self.frame.Cards;
    self.tabButtons = self.frame.TabButtons;
    self.cardIndex = 1;
    self.maxCards = 10;
    self.mode = 1;  --#1 Card Overview  #2 Runs Histograme  #3 Map Detail

    hooksecurefunc(self.frame, "SelectTab", function(f, tabIndex)
        if tabIndex == 1 then
            self.mode = 1;
        else
            self.mode = 2;
        end
        self:Navigate(0, 0);
    end);

    hooksecurefunc(self.frame, "ToggleMapDetail", function(f, showMapDetail)
        if showMapDetail then
            self.mode = 3;
        else
            self.mode = 1;
        end
        self:Navigate(0, 0);
    end);
end

function ag:OnActiveCallback()
    self:Navigate(0, 0);
    addon.GamePadNavBar:SelectButtonByID(5);
end

function ag:Switch(x)
    if x < 0 then
        Narci_NavBar:SelectTab(3);
    end
end

function ag:Navigate(x, y)
    if self.mode == 1 then
        local hold, valid;
        if x > 0 then
            if self.cardIndex < self.maxCards then
                self.cardIndex = self.cardIndex + 1;
                valid = true;
                hold = true;
            end
        elseif x < 0 then
            if self.cardIndex > 1 then
                self.cardIndex = self.cardIndex - 1;
                valid = true;
                hold = true;
            end
        elseif y > 0 then
            if self.cardIndex - 2 >= 1 then
                self.cardIndex = self.cardIndex - 2;
                valid = true;
                hold = true;
            end
        elseif y < 0 then
            if self.cardIndex + 2 <= self.maxCards then
                self.cardIndex = self.cardIndex + 2;
                valid = true;
                hold = true;
            end
        else
            valid = true;
        end
        if valid then
            GamePadButtonPool:HideAllButtons();
            if self.cardButtons[self.cardIndex] then
                self:Enter(self.cardButtons[self.cardIndex]);
                local pad1 = addon.GamePadButtonPool:SetupButton("PAD1", "", AttributeFrame, "TOPLEFT", self.currentObj, "TOPLEFT", 0, 0);
                local pad4 = addon.GamePadButtonPool:SetupButton("PAD4", "", AttributeFrame, "CENTER", self.tabButtons[2], "TOP", 0, 5);    --Place PAD4 on "Runs"
                return hold
            else
                --frame is still being constructing
                self.cardIndex = 1;
            end
        end
    elseif self.mode == 2 then
        GamePadButtonPool:HideAllButtons();
        local pad4 = addon.GamePadButtonPool:SetupButton("PAD4", "", AttributeFrame, "CENTER", self.tabButtons[1], "TOP", 0, 5);    --Place PAD4 on "Season Best"
    elseif self.mode == 3 then
        GamePadButtonPool:HideAllButtons();
        if x > 0 or y < 0 then
            self.frame.MapDetail.RightArrow:Click();
        elseif x < 0 or y > 0 then
            self.frame.MapDetail.LeftArrow:Click();
        end
        local pad2 = addon.GamePadButtonPool:SetupButton("PAD2", "", AttributeFrame, "TOPRIGHT", self.frame, "BOTTOMRIGHT", -72, -2);    --Place PAD4 on "Season Best"
        return true
    end
end

function ag:KeyDown(key)
    if self.mode == 1 then
        if key == "PAD1" then
            if self.currentObj and self.currentObj:IsEnabled() then
                self:Click();
            end
        elseif key == "PAD4" then
            self.tabButtons[2]:Click();
        elseif key == "PAD2" then
            addon.SelectActionGroup("CharacterFrame", 4);
        end
    elseif self.mode == 2 then
        if key == "PAD2" or key == "PAD4" then
            self.tabButtons[1]:Click();
        end
    elseif self.mode == 3 then
        if key == "PAD2" then
            self.frame:ToggleMapDetail(false);
        end
    end
end