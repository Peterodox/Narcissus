local NUM_TIERS = 7;

local After = C_Timer.After;
local GetAllSelectedTalentIDsAndIcons = NarciAPI.GetAllSelectedTalentIDsAndIcons;

-----------------------------------------------------------------------------------
NarciTalentFlatButtonMixin = CreateFromMixins(NarciShewedRectButtonMixin);

function NarciTalentFlatButtonMixin:OnLoad()
    self:SetHighlight(false);
end

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

function NarciTalentFlatButtonMixin:OnEnter()
    self:SetHighlight(true);
    
    local tooltip = NarciGameTooltip;
    tooltip:Hide();
    if self.talentID then
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2);
        tooltip:SetTalent(self.talentID);
        tooltip:Show();
    elseif self.unlockLevel then
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2);
        tooltip:SetText(TALENT, 1, 1, 1);
        tooltip:AddLine( string.format(PVP_TALENT_SLOT_LOCKED, self.unlockLevel), 1, 0.82, 0, true );
        tooltip:Show();
    end

    Narci_NavBar:PlayTimer(false);
end

function NarciTalentFlatButtonMixin:OnLeave()
    self:SetHighlight(false);

    local tooltip = NarciGameTooltip;
    tooltip:Hide();

    Narci_NavBar:PlayTimer(true);
end

------------------------------------------------------------------------
NarciTalentsMixin = {};

function NarciTalentsMixin:UpdateAllTalents()
    if not self.talentButtons then
        self.talentButtons = {};
    end
    local buttons = self.talentButtons;
    local button;
    
    local ignorePlayerLevel = true;
    local talentInfo = GetAllSelectedTalentIDsAndIcons(ignorePlayerLevel);
    
    for i = 1, NUM_TIERS do
        button = buttons[i];
        if button and talentInfo[i] then
            buttons[i]:SetTalent(unpack(talentInfo[i]));
        end
    end

    local specIndex = GetSpecialization() or 1;
	local _, _, _, specIcon = GetSpecializationInfo(specIndex);

    local NavBar = self:GetParent():GetParent();
    NavBar.specIcon = specIcon;
    if NavBar.cycledTabIndex == 0 then
        NavBar:SetPortraitTexture(specIcon, true);
    end

    self.needsUpdate = nil;
end

function NarciTalentsMixin:OnLoad()
    local staticEvents = {"PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_ENTERING_WORLD"};
    for _, event in pairs(staticEvents) do
        self:RegisterEvent(event);
    end
    self.needsUpdate = true;

    --Create talent buttons
    self.talentButtons = {};
    local button;
    for i = 1, NUM_TIERS do
        button = CreateFrame("Button", nil, self, "NarciTalentFlatButtonTemplate");
        self.talentButtons[i] = button;
        local gap = -2;
        local butonWidth = (320 - 48 - 6*gap) / 7;
        
        if i == 1 then
            button:UseFullMask(true, 1);
            button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0);
        elseif i == 7 then
            button:UseFullMask(false);
            button:SetPoint("BOTTOMLEFT", self.talentButtons[i - 1], "BOTTOMRIGHT", gap, 0);
        else
            button:UseFullMask(false);
            button:SetPoint("BOTTOMLEFT", self.talentButtons[i - 1], "BOTTOMRIGHT", gap, 0);
        end
        
        button:SetButtonSize(butonWidth, 24);
        --button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", (butonWidth + gap) * (i - 1), 0);
    end

    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);
end

function NarciTalentsMixin:RequestUpdate(forcedUpdate)
    if self:IsVisible() or forcedUpdate then
        if self.pauseUpdate then
            After(0, function()
                self.pauseUpdate = nil;
            end)
        else
            self.pauseUpdate = true;
            self:UpdateAllTalents();
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
    if event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        self:RequestUpdate();
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:RequestUpdate(true);
    end
end
