local _, addon = ...
local StatSheetController = addon.StatSheetController; ---@type StatSheetController

local Narci = Narci;
local FadeFrame = NarciFadeUI.Fade;

local NavigationBar;

local EquipmentSetManager = Narci_EquipmentSetManagerFrame;
local PowersFrame = Narci_PowersFrame;
local ChallengeUI = Narci_CompetitiveDisplay;


--Global
local V = NarciViewUtil;        --Declared in NarciAPI.lua

function V:ShowAttributes()
    if self.targetView == 1 then
        return
    else
        self.targetView = 1;
    end

    FadeFrame(EquipmentSetManager, 0.2, 0);
    FadeFrame(PowersFrame, 0.20, 0);
    FadeFrame(ChallengeUI, 0.20, 0);

    StatSheetController:ShowStatSheet();
    StatSheetController:SetRadarChartOffset(0);

    self.hideSetsCallBack();
end

function V:ShowSets()
    if self.targetView == 2 then
        return
    else
        self.targetView = 2;
    end

    FadeFrame(PowersFrame, 0.20, 0);
    FadeFrame(EquipmentSetManager, 0.15, 1);
    FadeFrame(ChallengeUI, 0.20, 0);

    StatSheetController:ShowRadarChartOnly();
    StatSheetController:SetRadarChartOffset(-74);

    self.showSetsCallBack();
end

function V:ShowChallenge()
    if self.targetView == 4 then
        return
    else
        self.targetView = 4;
    end

    FadeFrame(EquipmentSetManager, 0.20, 0);
    FadeFrame(PowersFrame, 0.20, 0);
    FadeFrame(ChallengeUI, 0.15, 1);

    StatSheetController:HideStatSheet();

    self.hideSetsCallBack();
end

function V:SetTab(index)
    if index == 2 then
        self:ShowSets();
    elseif index == 3 then
        self:ShowChallenge();
    else
        self:ShowAttributes();
    end
end

function V:IsViewingAttributes()
    return (not self.targetView) or self.targetView == 1;
end

----------------------------------------------------------------------------
local NavButtonController = {};
NavButtonController.navButtons = {};
NavButtonController.navButtonByKey = {};

function NavButtonController:CreateAndAcquireButton(container, buttonKey)
    local button = CreateFrame("Button", nil, container, "NarciNavBarTabButtonTemplate")
    tinsert(self.navButtons, button);

    if buttonKey and not self.navButtonByKey[buttonKey] then
        self.navButtonByKey[buttonKey] = button;
    end

    return button;
end

function NavButtonController:SelectButton(selectedButton)
    for k, button in pairs(self.navButtons) do
        button:SetSelect(button == selectedButton);
    end
end

function NavButtonController:SelectButtonByIndex(buttonIndex)
    for k, button in pairs(self.navButtons) do
        button:SetSelect(k == buttonIndex);
    end
end

function NavButtonController:SetHighlightColor(r, g, b)
    for k, button in pairs(self.navButtons) do
        button.Highlight:SetVertexColor(r, g, b);
    end
end

function NavButtonController:SetButtonVisibility(buttonKey, state)
    if buttonKey and self.navButtonByKey[buttonKey] then
        self.navButtonByKey[buttonKey]:SetShown(state);
        self:UpdateButtonPosition();
    end
end

function NavButtonController:UpdateButtonPosition()
    local totalWidth = 0;
    local container = NavigationBar.TabButtonContainer;

    for i, b in ipairs(self.navButtons) do
        if b:IsShown() then
            b:ClearAllPoints();
            b:SetPoint("TOPLEFT", container, "TOPLEFT", totalWidth, 0);
            totalWidth = totalWidth + b.buttonWidth;
        end
    end
end


NarciNavBarTabButtonMixin = {};

function NarciNavBarTabButtonMixin:OnEnter()
    if not self.isSelected then
        self.Label:SetTextColor(0.85, 0.85, 0.85);
    end
end

function NarciNavBarTabButtonMixin:OnLeave()
    if not self.isSelected then
        self.Label:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciNavBarTabButtonMixin:OnClick()
    self.tabFrame:SelectTab(self.tabIndex);
end

function NarciNavBarTabButtonMixin:OnMouseDown()
    if not self.isSelected then
        self.Label:SetPoint("CENTER", self, "CENTER", 0, -1);
    end
end

function NarciNavBarTabButtonMixin:OnMouseUp()
    self.Label:SetPoint("CENTER", self, "CENTER", 0, 0);
end

function NarciNavBarTabButtonMixin:SetSelect(state)
    if state then
        self.Highlight:Show();
        self.isSelected = true;
        self.Label:SetTextColor(0.92, 0.92, 0.92);
    else
        self.Highlight:Hide();
        self.isSelected = nil;
        self.Label:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciNavBarTabButtonMixin:SetUp(labelText, tabIndex)
    self.Label:SetWidth(0);
    self.Label:SetText(labelText);
    local textWidth = self.Label:GetWidth();
    local MAX_WIDTH = self.maxWidth or 60;
    if textWidth < 30 then
        textWidth = 30;
        self.Label:SetWidth(textWidth);
    elseif textWidth > MAX_WIDTH then
        textWidth = MAX_WIDTH;
        self.Label:SetWidth(textWidth);
    end
    self.buttonWidth = textWidth + 20;
    self:SetWidth(self.buttonWidth);
    self.tabIndex = tabIndex;
end

function NarciNavBarTabButtonMixin:SetSelected(state)
    self:SetSelect(state);
end

function NarciNavBarTabButtonMixin:SetText(text)
    self:SetUp(text);
    self:SetScript("OnClick", function()
        self:SelectTab();
    end);
end


NarciNavBarMixin = {};

function NarciNavBarMixin:OnLoad()
    NavigationBar = self;
    self.cycledTabIndex = 0;
    self.soulbindID = 0;

    --Create tab buttons
    local GAP = 0;

    local tabInfo = {
        --{LocalizedName, buttonKey}
        {PRIMARY, "primary"},
        {WARDROBE_SETS, "equipmentsets"},
        {Narci.L["Mythic Plus Abbrev"], "mythicplus"},
    };

    local navButton;
    local container = self.TabButtonContainer;
    for i = 1, #tabInfo do
        navButton = NavButtonController:CreateAndAcquireButton(container, tabInfo[i][2]);
        navButton:SetPoint("TOPLEFT", container, "TOPLEFT", GAP, 0);
        if i == 1 then
            navButton:SetSelect(true);
        end
        navButton:SetUp(tabInfo[i][1], i);
        navButton.tabFrame = self;
    end

    NavButtonController:UpdateButtonPosition();
end

function NarciNavBarMixin:IsCurrentTabSoulbind()
    return (self.cycledTabIndex == 1)
end

function NarciNavBarMixin:SetThemeColor(colorTable)
    if not colorTable then
        colorTable = {0.8, 0.8, 0.8};
    end
    NavButtonController:SetHighlightColor(unpack(colorTable));
end

function NarciNavBarMixin:SetPortraitTexture(tex, useOffset, darken)
    if tex == self.portraitTexture then
        return;
    else
        local portrait = self.OverlayFrame.Portrait;
        if tex then
            self.portraitTexture = tex;
            portrait.ActivateAnim:Stop();
            portrait:SetTexture(tex, nil, nil, "LINEAR");
            portrait.ActivateAnim:Play();
            if useOffset then
                portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92);
                portrait:SetVertexColor(0.80, 0.80, 0.80);
            else
                portrait:SetTexCoord(0, 1, 0, 1);
                portrait:SetVertexColor(1, 1, 1);
            end
            if darken then
                portrait:SetDesaturation(0.2);
            else
                portrait:SetDesaturation(0);
            end
        else
            portrait:SetColorTexture(0.1, 0.1, 0.1);
        end
    end
end

function NarciNavBarMixin:SelectTab(tabIndex)
    if tabIndex ~= self.tabIndex then
        self.tabIndex = tabIndex;
    else
        return
    end
    NavButtonController:SelectButtonByIndex(tabIndex);
    V:SetTab(tabIndex);

    self:ProcessUpdate();

    self.PrimaryFrame:SetShown(tabIndex == 1);
    self.SetsFrame:SetShown(tabIndex == 2);
    --self.SoulbindsFrame:SetShown(tabIndex == 3);
    self.ChallengeFrame:SetShown(tabIndex == 3);

    if tabIndex == 1 then
        self:ShowPrimary();
    elseif tabIndex == 2 then
        self:ShowSets();
    elseif tabIndex == 3 then
        self:ShowChallenge();
    elseif tabIndex == 4 then
        --self:ShowChallenge();
    end
end

function NarciNavBarMixin:UpdateSets(numSets, numMissing)
    local SetsFrame = self.SetsFrame;
    local maxSets = 10; --MAX_EQUIPMENT_SETS_PER_PLAYER
    local saved = "|cffcccccc".. Narci.L["NavBar Saved Sets"] .."  |r";
    local incomplet = "|cffffd100".. Narci.L["NavBar Incomplete Sets"] .."  ";
    if numMissing and numMissing > 0 then
        SetsFrame.DataText:SetText(saved..numSets.."/"..maxSets.. "     "..incomplet..numMissing.."|r");
    else
        SetsFrame.DataText:SetText(saved..numSets.."/"..maxSets);
    end
end

function NarciNavBarMixin:ShowPrimary()
    if self:IsCurrentTabSoulbind() then
        self:SetPortraitTexture("Interface\\AddOns\\Narcissus\\Art\\NavBar\\Soulbinds\\".. self.soulbindID);
    else
        self:SetPortraitTexture(self.specIcon, true);
    end
end

function NarciNavBarMixin:SetSkipCovenant(state)
    if state == self.skipCovenant then
        return
    end
    self.skipCovenant = state;
    NavButtonController:SetButtonVisibility("covenant", not state);
end

function NarciNavBarMixin:HideMythicPlusButton()
    NavButtonController:SetButtonVisibility("mythicplus", false);
end


function NarciNavBarMixin:ShowCovenant()
    if not self.covenantID then
        self.covenantID = C_Covenants.GetActiveCovenantID() or 0;
    end
    self:SetPortraitTexture("Interface\\AddOns\\Narcissus\\Art\\NavBar\\Covenants\\".. self.covenantID);
end

function NarciNavBarMixin:ShowSets()
    self:SetPortraitTexture(133139, true);
end

function NarciNavBarMixin:SetSoulbindName(soulbindName, isActive)
    local dataText = self.SoulbindsFrame.DataText;
    dataText:SetText(soulbindName);
    if isActive then
        --dataText:SetTextColor(0.47, 0.72, 0.84);
        dataText:SetTextColor(0.71, 0.89, 0.91);
    else
        dataText:SetTextColor(0.43, 0.64, 0.71);
        --dataText:SetTextColor(0.84, 0.33, 0.19);
    end

    self:SetSkipCovenant(false);
end

function NarciNavBarMixin:ShowChallenge()
    if self.keystoneIcon then
        self:SetPortraitTexture(self.keystoneIcon, false, true);
    else
        self:SetPortraitTexture("Interface\\AddOns\\Narcissus\\Art\\NavBar\\Hourglass");
    end
end

function NarciNavBarMixin:ToggleBar(state)
    if state then
        self:SetHeight(48);
        self.OverlayFrame:Show();
    else
        self:SetHeight(24);
        self.OverlayFrame:Hide();
    end
end

function NarciNavBarMixin:OnHide()
    -- Reset tab to "Primary"
    self:SelectTab(1);
end

function NarciNavBarMixin:GetTrayWidth()
    if self.maximizedMode then
        return (320 - 48);
    else
        return 240;
    end
end

function NarciNavBarMixin:SetMaximizedMode(state)
    if state == nil then
        state = NarcissusDB.DetailedIlvlInfo or true;
    end
    self.maximizedMode = state;

    local barWidth;

    if state then
        barWidth = 320;
    else
        barWidth = 240;
    end

    self:SetWidth(barWidth);
    self.OverlayFrame.PortraitShadow:SetShown(state);
    self.OverlayFrame.Portrait:SetShown(state);
    self.PrimaryFrame.TalentContainer:RequestUpdate();
end

--For GamePad
function NarciNavBarMixin:GetTabButtons()
    local visibleTabs = {};
    local numButtons = 0;
    for i = 1, #NavButtonController.navButtons do
        if NavButtonController.navButtons[i]:IsShown() then
            numButtons = numButtons + 1;
            visibleTabs[numButtons] = NavButtonController.navButtons[i];
        end
    end
    return visibleTabs, numButtons;
end
