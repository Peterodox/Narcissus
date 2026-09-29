local _, addon = ...


local DefaultTooltip = NarciGameTooltip; -- Created in Module\GameTooltip.lua


---@alias WidgetOrientation
---| "left"   on the left side
---| "right"  on the right side


local RuneSlotMixin = {};
do  -- An area on the hex border to display enchants
    addon.RuneSlotMixin = RuneSlotMixin;

    ---@param orientation WidgetOrientation
    function RuneSlotMixin:SetOrientation(orientation)
        self.isRight = orientation == "right";
        self.RuneLetter:ClearAllPoints();
        if self.isRight then
            self.RuneLetter:SetPoint("CENTER", self, "CENTER", 0, 0);
        else
            self.RuneLetter:SetPoint("CENTER", self, "CENTER", 3, 0);
        end
    end

    function RuneSlotMixin:OnEnter()
        if (self.isFlyoutButton or not self.spellID) then return; end

        DefaultTooltip:SetOwner(self, "ANCHOR_NONE");
        if self.isRight then
            DefaultTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", 8, 8);
        else
            DefaultTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 8);
        end
        DefaultTooltip:SetSpellByID(self.spellID);
        DefaultTooltip:Show();
        DefaultTooltip:FadeIn();
    end

    function RuneSlotMixin:OnLeave()
        if not self.isFlyoutButton then
            Narci:HideButtonTooltip();
        end
    end

    function RuneSlotMixin:OnLoad()
        self:SetOrientation(self.orientation);
    end

    -- enchantID will be obtained from the itemLink
    function RuneSlotMixin:SetEquipmentItemLink(itemLink)
        local enchantID = itemLink and NarciAPI.GetItemEnchantID(itemLink);
        if enchantID then
            self.spellID = addon.EnchantDataProvider:GetSpellIDByEnchantID(enchantID);
            self.RuneLetter:SetText(NarciAPI.GetVerticalRunicLetters("undefined"));
            self.RuneLetter:Show();
            self:Show();
        else
            self.spellID = nil;
            self.RuneLetter:Hide();
            self:Hide();
        end
    end
end
