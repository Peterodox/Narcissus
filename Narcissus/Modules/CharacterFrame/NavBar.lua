local _, addon = ...
local StatSheetController = addon.StatSheetController; ---@type StatSheetController

local Narci = Narci;
local FadeFrame = NarciFadeUI.Fade;

local EquipmentSetManager = Narci_EquipmentSetManagerFrame;
local ChallengeUI = Narci_CompetitiveDisplay;


--Global
local V = NarciViewUtil;        --Declared in NarciAPI.lua

function V:ShowPrimary()
    Narci_NavBar:SelectTabByKey("Primary");
end

function V:ShowSets()
    Narci_NavBar:SelectTabByKey("EquipmentSet");
end

function V:ShowChallenge()
    Narci_NavBar:SelectTabByKey("MythicPlus");
end

function V:SetTab(index)
    if index == 2 then
        self:ShowSets();
    elseif index == 3 then
        self:ShowChallenge();
    else
        self:ShowPrimary();
    end
end

function V:IsViewingAttributes()
    local tabKey = Narci_NavBar:GetSelectedTabKey();
    return (not tabKey) or tabKey == "Primary";
end


---@class CharacterUINavBar : TabSystem
NarciNavBarMixin = {};

function NarciNavBarMixin:OnLoad()
    local enableBackground = true;
    local enableDivider = true;
    addon.CreateTabSystem(self, enableBackground, enableDivider);

    local tabInfo = {
        --{tabKey, tabName}
        {"Primary", PRIMARY, self.PrimaryFrame},
        {"EquipmentSet", WARDROBE_SETS, self.SetsFrame},
        {"MythicPlus", Narci.L["Mythic Plus Abbrev"], self.ChallengeFrame},
    };

    for _, v in ipairs(tabInfo) do
        self:AddTab(v[1], v[2], v[3]);
    end
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

function NarciNavBarMixin:OnTabSelected(tabKey)
    if tabKey == "EquipmentSet" then
        self:ShowSets();
    elseif tabKey == "MythicPlus" then
        self:ShowChallenge();
    else
        self:ShowPrimary();
    end

    if tabKey == "EquipmentSet" then
        NarciViewUtil.showSetsCallBack();
    else
        NarciViewUtil.hideSetsCallBack();
    end
end

function NarciNavBarMixin:ShowPrimary()
    self:SetPortraitTexture(self.specIcon, true);

    FadeFrame(EquipmentSetManager, 0.2, 0);
    FadeFrame(ChallengeUI, 0.20, 0);

    StatSheetController:ShowStatSheet();
    StatSheetController:SetRadarChartOffset(0);
end

function NarciNavBarMixin:ShowSets()
    self:SetPortraitTexture(133139, true);

    FadeFrame(EquipmentSetManager, 0.15, 1);
    FadeFrame(ChallengeUI, 0.20, 0);

    StatSheetController:ShowRadarChartOnly();
    StatSheetController:SetRadarChartOffset(-74);
end

function NarciNavBarMixin:ShowChallenge()
    if self.keystoneIcon then
        self:SetPortraitTexture(self.keystoneIcon, false, true);
    else
        self:SetPortraitTexture("Interface\\AddOns\\Narcissus\\Art\\NavBar\\Hourglass");
    end

    FadeFrame(EquipmentSetManager, 0.20, 0);
    FadeFrame(ChallengeUI, 0.15, 1);

    StatSheetController:HideStatSheet();
end

function NarciNavBarMixin:OnShow()
    self:SetScript("OnShow", nil);

    local playerLevel = UnitLevel("player");
    if canaccessvalue(playerLevel) and playerLevel ~= GetMaxLevelForPlayerExpansion() then
        self:DisableTab("MythicPlus");
    end

    self:Init();
end

function NarciNavBarMixin:OnHide()
    -- Reset tab to "Primary"
    self:SelectTabByKey("Primary");
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
    self:LayoutTabButtons();
    self.OverlayFrame.PortraitShadow:SetShown(state);
    self.OverlayFrame.Portrait:SetShown(state);
    self.PrimaryFrame.TalentContainer:RequestUpdate();
end

--For GamePad
function NarciNavBarMixin:GetTabButtons()
    local visibleTabs = {};
    local numButtons = 0;
    return visibleTabs, numButtons;
end
