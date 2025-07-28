NarciGuideMixin = {};

local TutorialDB;     --NarcissusDB
local L = Narci.L;
local After = C_Timer.After;
local FadeFrame = NarciFadeUI.Fade;
local FIXED_WIDTH = 270;
local TOOLTIP_PADDING = 12;
local TEXT_GAP = 8;
local CRITERIA_MET_MARK = "[OK]";

local DEBUG_ALWAYS_SHOW_GUIDE = false;


local function ShouldShowGuideForModule(key)
    if (key and TutorialDB[key]) or DEBUG_ALWAYS_SHOW_GUIDE then
        return true
    end
end

local function CloseGuide(self)
    self:GetParent():Hide();
end

local function EmptyFunc()
end

function NarciGuideMixin:OnShow()
    if TutorialDB[self.KeyValue] then
        TutorialDB[self.KeyValue] = false;
    end
    FadeFrame(self, 0.25, 1, 0);
    self:SetScale(NarcissusDB["GlobalScale"]);
    self:SetWidth(FIXED_WIDTH);
    local height = (self.Header:GetHeight() + self.Text:GetHeight() + TEXT_GAP + 2*TOOLTIP_PADDING);
    self:SetHeight(height);
    PlaySound(869, "SFX");
end

function NarciGuideMixin:OnHide()
    self:StopAnimating();
end

function NarciGuideMixin:NewText(title, description, anchorTo, offsetX, offsetY, nextButtonOnClickFunc, horizontal)
    self:Hide();
    self:ClearAllPoints();
    self.Header:SetText(title);
    self.Text:SetText(description);

    self.Pointer:ClearAllPoints();
    self.Pointer2:ClearAllPoints();

    if horizontal then
        self:SetPoint("RIGHT", anchorTo, "LEFT", offsetX or 0, offsetY or 0);
        self.Pointer:Hide();
        self.Pointer2:SetPoint("CENTER", anchorTo, "RIGHT", 0, 0);
        self.Pointer2:Show();
    else
        self:SetPoint("BOTTOM", anchorTo, "TOP", offsetX or 0, offsetY or 0);
        self.Pointer2:Hide();
        self.Pointer:SetPoint("CENTER", self, "BOTTOM", 0, 0);
        self.Pointer:Show();
    end
    self:Show();

    if nextButtonOnClickFunc and type(nextButtonOnClickFunc) == "function" then
        self.Next:SetScript("OnClick", nextButtonOnClickFunc);
        self.Next.IconClose:Hide();
        self.Next.IconNext:Show();
    else
        self.Next.IconClose:Show();
        self.Next.IconNext:Hide();
        self.Next:SetScript("OnClick", CloseGuide);
    end
    self.Next:Show();
end

---------------------------------------------------------------------------------------

-------------------------
--Spell Visual Browser---
-------------------------
local BrowserGuide;
local LeftClickUsed, RightClickUsed = false, false;

local function MoveToEditBox()
    BrowserGuide:NewText(L["Guide Input Headline"], L["Guide Input Line1"], Narci_SpellVisualBrowser.ExpandableFrames.EditBox, 0, -4, "END");
end

local function MoveToReApplyButton()
    BrowserGuide:NewText(L["Refresh Model"], L["Guide Refresh Line1"], Narci_SpellVisualBrowser.ExpandableFrames.ResetButton, 0, -4, MoveToEditBox);
end

local function MoveToHistoryTab()
    BrowserGuide:Hide();
    After(1, function()
        BrowserGuide:NewText(L["Guide History Headline"], L["Guide History Line1"], Narci_SpellVisualBrowser.ExpandableFrames.HistoryFrame, 0, -6, MoveToReApplyButton);
    end);
end

local function SpellVisualBrowser_OnTabChanged(self, value)
    After(2, function()
        BrowserGuide:NewText(L["Guide Spell Headline"], L["Guide Spell Line1"].."\n"..L["Guide Spell Criteria1"].."\n"..L["Guide Spell Criteria2"], Narci_SpellVisualBrowser.ExpandableFrames.ListFrame, 0, 0, MoveToHistoryTab);

        hooksecurefunc(NarciPlayerModelFrame1, "ApplySpellVisualKit", function(self, visualID, oneshot)
            if LeftClickUsed and RightClickUsed then
                return;
            end
            if BrowserGuide:IsVisible() then
                if oneshot then
                    if not LeftClickUsed then
                        LeftClickUsed = true;
                        if not RightClickUsed then
                            BrowserGuide.Text:SetText(L["Guide Spell Line1"].."\n".."|cff007236"..CRITERIA_MET_MARK..L["Guide Spell Criteria1"].."|r\n"..L["Guide Spell Criteria2"]);
                        else
                            BrowserGuide.Text:SetText(L["Guide Spell Line1"].."\n".."|cff007236"..CRITERIA_MET_MARK..L["Guide Spell Criteria1"].."\n"..CRITERIA_MET_MARK..L["Guide Spell Criteria2"]);
                            MoveToHistoryTab()
                        end
                    end
                else
                    if not RightClickUsed then
                        RightClickUsed = true;
                        if not LeftClickUsed then
                            BrowserGuide.Text:SetText(L["Guide Spell Line1"].."\n"..L["Guide Spell Criteria1"].."\n|cff007236"..CRITERIA_MET_MARK.. L["Guide Spell Criteria2"]);
                        else
                            BrowserGuide.Text:SetText(L["Guide Spell Line1"].."\n".."|cff007236"..CRITERIA_MET_MARK..L["Guide Spell Criteria1"].."\n"..CRITERIA_MET_MARK..L["Guide Spell Criteria2"]);
                            MoveToHistoryTab()
                        end
                    end
                end
            end
        end);

    end)
end

local function BuildSpellVisualBrowserGuide()
    local Browser = Narci_SpellVisualBrowser;
    Browser.ShowGuide = true;
    BrowserGuide = CreateFrame("Frame", nil, Browser, "NarciGenericGuideTemplate");
    local TabListener = CreateFrame("SLIDER", nil, BrowserGuide);
    TabListener:SetMinMaxValues(-1, 5);     --Necessary!
    TabListener:SetScript("OnValueChanged", SpellVisualBrowser_OnTabChanged);
    BrowserGuide.TabListener = TabListener;

    local function SelectFirstCategory()
        BrowserGuide:Hide();
        NarciSpellVisualUtil:SelectFirstCategory();
    end

    local ExpandableFrames = Browser.ExpandableFrames;
    ExpandableFrames:SetScript("OnShow", function(self)
        After(0.6, function()
            BrowserGuide:NewText(L["Category"], L["Guide Spell Choose Category"], ExpandableFrames.ListFrame, 0, 0, SelectFirstCategory);
            TutorialDB["SpellVisualBrowser"] = false;
        end);
        self:SetScript("OnShow", EmptyFunc);
    end);
end




----------------------------
--Exit Confirmation Dialog--
----------------------------
local function MakeItInsanelyLarge()
    local ExitConfirm = Narci_ExitConfirmationDialog;
    ExitConfirm:SetScale(4);
    ExitConfirm:SetScript("OnHide", function(self)
        self:SetScale(1);
        TutorialDB["ExitConfirmation"] = false;
    end)
end


----------------------------------------------------------
local Initialization = CreateFrame("Frame");
Initialization:RegisterEvent("VARIABLES_LOADED");
Initialization:SetScript("OnEvent", function(self, event, ...)
    self:UnregisterEvent("VARIABLES_LOADED");
    After(3, function()
        TutorialDB = NarcissusDB.Tutorials;
        if not TutorialDB then return; end;

        --Enlarged Exit Confirmation
        if ShouldShowGuideForModule("ExitConfirmation") then
            MakeItInsanelyLarge();
        end

        --Spell Visual Browser
        if ShouldShowGuideForModule("SpellVisualBrowser") then
            BuildSpellVisualBrowserGuide();
        end

        --Equipment Set Manager

        --Character Movement
        if ShouldShowGuideForModule("Movement") then
            local Movement = CreateFrame("Frame", nil, Narci_ModelSettings, "NarciGenericGuideTemplate");
            Narci_ModelSettings:SetScript("OnShow", function(self)
                self:RegisterEvent("MODIFIER_STATE_CHANGED");
                After(2, function()
                    Movement:NewText(L["Guide Model Control Headline"], L["Guide Model Control Line1"], Narci_ModelSettings, 0, 32, "END");
                    TutorialDB["Movement"] = false;
                end);
                self:SetScript("OnShow", function(self)
                    self:RegisterEvent("MODIFIER_STATE_CHANGED");
                end);
            end);
        end

        --Minimap button can be influenced by other addons
        --[[
        if ShouldShowGuideForModule("IndependentMinimapButton") then
            local Mini = CreateFrame("Frame", nil, Minimap, "NarciGenericGuideTemplate");
            After(1, function()
                Mini:NewText(L["Guide Minimap Button Headline"], L["Guide Minimap Button Line1"], Narci_MinimapButton, 0, 0, "END", "LEFT");
            end)
            TutorialDB["IndependentMinimapButton"] = false;
        end
        --]]

        --NPC Browser Entrance
        if ShouldShowGuideForModule("NPCBrowserEntance") then
            local IndexButton2 = Narci_ActorPanel.ExtraPanel.buttons[2];
            local Entrance = CreateFrame("Frame", nil, IndexButton2, "NarciGenericGuideTemplate");
            local hasHidden = true;
            IndexButton2:SetScript("OnShow", function(self)
                After(0.5, function()
                    hasHidden = false;
                    Entrance:NewText(L["NPC Browser"], L["Guide NPC Entrance Line1"], IndexButton2, 0, -3, "END");
                    TutorialDB["NPCBrowserEntance"] = false;
                end);
                self:SetScript("OnShow", nil);
            end);

            IndexButton2:HookScript("OnLeave", function()
                if not hasHidden then
                    hasHidden = true;
                    FadeFrame(Entrance, 0.25, 0);
                end
            end)
        end

        --NPC Browser
        if ShouldShowGuideForModule("NPCBrowser") then
            local NPC = CreateFrame("Frame", nil, Narci_NPCBrowser, "NarciGenericGuideTemplate");
            Narci_NPCBrowser:SetScript("OnShow", function(self)
                After(0.5, function()
                    NPC:NewText(L["NPC Browser"], L["Guide NPC Browser Line1"], Narci_NPCBrowser, 0, 0, "END");
                    TutorialDB["NPCBrowser"] = false;
                end);
                self:SetScript("OnShow", nil);
            end);
        end

        --Shards of Domination
        --[[
        if ShouldShowGuideForModule("Domination") then
            local parent = Narci_Attribute;
            local Alert = CreateFrame("Frame", nil, parent,"NarciDominationNoEffectAlert");
            local function onShowFunc()
                Alert:ClearAllPoints();
                Alert:SetPoint("CENTER", Narci_ItemLevelFrame, "CENTER", 0, 0);
                Alert:ShowAlert();
            end
            local function onAlertShownFunc()
                TutorialDB["Domination"] = false;
            end
            Alert.onShowFunc = onAlertShownFunc;
            if not parent:GetScript("OnShow") then
                parent:SetScript("OnShow", onShowFunc);
            end
        end
        --]]
    end)
end);

function Narci:ResetGuide()
    NarcissusDB.Tutorials = {};
end