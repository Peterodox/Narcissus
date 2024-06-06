local MAX_DISPLAYED_TALENTS = 9;

local _, addon = ...;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local After = C_Timer.After;


NarciTalentFlatButtonMixin = CreateFromMixins(NarciShewedRectButtonMixin);

function NarciTalentFlatButtonMixin:OnLoad()
    self:SetHighlight(false);
end

--[[    --Pre 10.0
function NarciTalentFlatButtonMixin:SetTalent(talentID, texture, unlockLevel)
    self.talentID = talentID;
    self.unlockLevel = unlockLevel;
    if texture then
        self:SetIcon(texture);
        self.UnlockLevel:Hide();
    else
        self:SetColorTexture(0.1, 0.1, 0.1);
        self.UnlockLevel:SetText(unlockLevel);
        self.UnlockLevel:Show();
    end
end
--]]

function NarciTalentFlatButtonMixin:SetTalent(entryID, rank, spellID, icon)
    --Post 10.0
    self.entryID = entryID;
    self.rank = rank;
    self.spellID = spellID;

    if icon then
        self:SetIcon(icon);
        self.UnlockLevel:Hide();
    else
        self:SetColorTexture(0.1, 0.1, 0.1);
        self.UnlockLevel:SetText("");
        self.UnlockLevel:Show();
    end
end

function NarciTalentFlatButtonMixin:OnEnter()
    local tooltip = NarciGameTooltip;
    tooltip:Hide();

    if self.entryID then
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2);
        --tooltip:SetTalent(self.talentID);

        if self.spellID then
            local name = GetSpellInfo(self.spellID);
            if name and name ~= "" then
                tooltip:SetText(name, 1, 1, 1, true);
            end
        end

        local tooltipInfo = CreateBaseTooltipInfo("GetTraitEntry", self.entryID, self.rank or 1);
        tooltipInfo.append = true;
        tooltip:ProcessInfo(tooltipInfo);
        tooltip:Show();
    elseif self.unlockLevel then
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2);
        tooltip:SetText(TALENT, 1, 1, 1);
        tooltip:AddLine( string.format(PVP_TALENT_SLOT_LOCKED, self.unlockLevel), 1, 0.82, 0, true );
        tooltip:Show();
    else
        return
    end

    self:SetHighlight(true);

    Narci_NavBar:PauseTimer(true);
end

function NarciTalentFlatButtonMixin:OnLeave()
    self:SetHighlight(false);
    NarciGameTooltip:Hide();
    Narci_NavBar:PauseTimer(false);
end

------------------------------------------------------------------------
NarciTalentsMixin = {};

function NarciTalentsMixin:UpdateAllTalents()
    if not self.talentButtons then
        self.talentButtons = {};
    end

    local buttons = self.talentButtons;
    local button;

    local talentInfo = NarciAPI.GetEndOfLineTraitInfo();
    local numTalents = #talentInfo;

    if numTalents < 4 then
        numTalents = 4;
    elseif numTalents > MAX_DISPLAYED_TALENTS then
        numTalents = MAX_DISPLAYED_TALENTS;     --cut-off
    end

    for i = 1, #buttons do
        buttons[i]:Hide();
        buttons[i]:ClearAllPoints();
    end

    local navBar = self:GetParent():GetParent();
    local trayWidth = navBar:GetTrayWidth();

    local gap = -2;     --negative value
    local buttonWidth = (trayWidth - (numTalents - 1)*gap) / numTalents;

    for i = 1, numTalents do
        button = buttons[i];
        if not button then
            button = CreateFrame("Button", nil, self, "NarciTalentFlatButtonTemplate");
            buttons[i] = button;
        end

        if i == 1 then
            button:UseFullMask(true, 1);
            button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0);
        elseif i == numTalents then
            button:UseFullMask(true, 2);
            button:SetPoint("BOTTOMLEFT", self.talentButtons[i - 1], "BOTTOMRIGHT", gap, 0);
        else
            button:UseFullMask(false);
            button:SetPoint("BOTTOMLEFT", self.talentButtons[i - 1], "BOTTOMRIGHT", gap, 0);
        end
        if talentInfo[i] then
            button:SetTalent(unpack(talentInfo[i]));
        else
            button:SetTalent();
        end
        button:SetButtonSize(buttonWidth, 24);
        button:Show();
    end

    local specIndex = GetSpecialization() or 1;
	local _, _, _, specIcon = GetSpecializationInfo(specIndex);

    navBar.specIcon = specIcon;
    if navBar.cycledTabIndex == 0 then
        navBar:SetPortraitTexture(specIcon, true);
    end

    self.needsUpdate = nil;
end

function NarciTalentsMixin:OnLoad()
    local staticEvents;
    if addon.IsDragonflight() then
        staticEvents = {"TRAIT_CONFIG_UPDATED", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_ENTERING_WORLD"};
    else
        staticEvents = {"PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_ENTERING_WORLD"};
    end

    for _, event in pairs(staticEvents) do
        self:RegisterEvent(event);
    end
    self.needsUpdate = true;
    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);
end

function NarciTalentsMixin:RequestUpdate(forcedUpdate)
    if self:IsVisible() or forcedUpdate then
        if not self.pauseUpdate then
            self.pauseUpdate = true;
            After(0, function()
                self.pauseUpdate = nil;
                self:UpdateAllTalents();    --After our Talent Cache got updated
            end)
        end
    else
        self.needsUpdate = true;
    end
end

function NarciTalentsMixin:OnShow()
    if self.needsUpdate then
        self:UpdateAllTalents();
    end
end

function NarciTalentsMixin:OnHide()

end

function NarciTalentsMixin:OnEvent(event, ...)
    if event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        self:RequestUpdate();
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:RequestUpdate(true);
        self:UnregisterEvent(event);
    end
end
