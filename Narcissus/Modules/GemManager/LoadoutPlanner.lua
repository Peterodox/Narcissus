local _, addon = ...
local Gemma = addon.Gemma;
local AtlasUtil = Gemma.AtlasUtil;
local ItemCache = Gemma.ItemCache;
local L = Narci.L;
local GetItemIcon = C_Item.GetItemIconByID;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;

local PATH = "Interface/AddOns/Narcissus/Art/Modules/GemManager/";

local CreateFrame = CreateFrame;
local Mixin = Mixin;
local GameTooltip = GameTooltip;
local UIParent = UIParent;

local EditWindow, LoadoutPlanner, DataProvider, SlotHighlight, GemList, GemListHighlight, StatsMouseOverFrame;

local POINTS_REQUIRED_TINKER = 12;
local POINTS_REQUIRED_STATS1 = 6;
local POINTS_REQUIRED_STATS2 = 6;
local POINTS_REQUIRED_STATS3 = 9;




local TraitButtonMixin = {};
do
    local TRAIT_BUTTON_SIZE = 38

    function TraitButtonMixin:SetItem(itemID)
        self.itemID = itemID;
        self.iconFile = GetItemIcon(itemID);
        self.Icon:SetTexture(self.iconFile);
        self.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);
    end

    function TraitButtonMixin:OnItemLoaded(itemID)
        if itemID == self.itemID then
            self:SetItem(itemID);
        end
    end

    function TraitButtonMixin:ClearItem()
        self.itemID = nil;
        self.iconFile = nil;
        self.traitState = nil;
        self:SetBorderByState("inactive");
        self:SetIconEmpty();
    end

    function TraitButtonMixin:SetShape(shape)
        self.IconMask:SetTexture(PATH.."IconMask-"..shape, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    end

    function TraitButtonMixin:ShowGameTooltip()
        LoadoutPlanner:ShowButtonTooltip(self);
    end

    function TraitButtonMixin:OnEnter()
        SlotHighlight:HighlightSlot(self);
        LoadoutPlanner:SetFocusedButton(self);
    end

    function TraitButtonMixin:OnLeave()
        SlotHighlight:HighlightSlot(nil);
        LoadoutPlanner:SetFocusedButton(nil);
    end

    function TraitButtonMixin:SetActive()
        self.traitState = 2;
        self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturation(0);
        self:SetBorderByState("active");
    end

    function TraitButtonMixin:SetInactive()
        self.traitState = 1;
        self.Icon:SetTexture(self.iconFile);
        self.Icon:SetVertexColor(0.8, 0.8, 0.8);
        self.Icon:SetDesaturation(1);
        self:SetBorderByState("inactive");
    end

    function TraitButtonMixin:SetUncollected()
        self.traitState = 0;
        self:SetBorderByState("inactive");
        self:SetIconEmpty();
    end

    function TraitButtonMixin:SetAvailable()
        self.traitState = 3;
        self.Icon:SetTexture(self.iconFile);
        self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturation(0);
        self:SetBorderByState("available");
    end

    function TraitButtonMixin:SetSelectable()
        self.traitState = 4;
        self:SetIconEmpty();
        self:SetBorderByState("available");
    end

    function TraitButtonMixin:SetDimmed()
        self.traitState = 2;
        self.Icon:SetTexture(self.iconFile);
        self.Icon:SetVertexColor(167/255, 154/255, 96/255);
        self.Icon:SetDesaturation(1);
        self:SetBorderByState("dimmed")
    end

    function TraitButtonMixin:SetIconEmpty()
        self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturation(0);
        self.Icon:SetTexture(PATH.."Gem-Empty");
    end

    function TraitButtonMixin:OnClick(button)
        if button == "LeftButton" then
            LoadoutPlanner:SelectTinker(self.itemID, true);
        elseif button == "RightButton" then
            LoadoutPlanner:SelectTinker(self.itemID, false);
        end
        self:OnEnter();
    end

    function TraitButtonMixin:SetButtonSize(buttonSize, iconSize)
        --For unique sized buttons
        self:SetSize(buttonSize, buttonSize);
        self.Icon:SetSize(iconSize, iconSize);
    end

    function TraitButtonMixin:ResetButtonSize()
        self:SetSize(TRAIT_BUTTON_SIZE, TRAIT_BUTTON_SIZE);
        self.Icon:SetSize(30, 30);
    end

    function TraitButtonMixin:SetBorderByState(state)
        if self.borderTextures then
            AtlasUtil:SetAtlas(self.Border, self.borderTextures[state]);
        end
    end
end

local function CreateTraitButton(parent, shape)
    local button = CreateFrame("Button", nil, parent, "NarciGemManagerTraitButtonTemplate");
    Mixin(button, TraitButtonMixin);
    button:ResetButtonSize();

    if shape then
        button:SetShape(shape);
    end

    button.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);

    button:SetScript("OnEnter", button.OnEnter);
    button:SetScript("OnLeave", button.OnLeave);
    button:SetScript("OnClick", button.OnClick);

    return button
end




local GemListMixin = {};
do
    local ITEMS_PER_PAGE = 8;
    local LISTBUTTON_HEIGHT = 44;
    local FROM_Y = -40 -4;

    local GemListMixinButton = {};

    function GemListMixinButton:OnLoad()
        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnClick", self.OnClick);

        local delay = self.index * 0.05;
        self.AnimFlyIn.Delay1:SetStartDelay(delay);
        self.AnimFlyIn.Delay2:SetStartDelay(delay);
        self.AnimFlyIn.Delay3:SetStartDelay(delay);
        self.AnimFlyIn.Delay4:SetStartDelay(delay);
    end

    function GemListMixinButton:OnClick(button)
        if button == "RightButton" then
            LoadoutPlanner:Hide();
            return
        end

        if button == "LeftButton" then
            LoadoutPlanner:SaveCurrentChoice(self.itemID);
        end
    end

    function GemListMixinButton:OnEnter()
        GemListHighlight:ClearAllPoints();
        GemListHighlight:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        GemListHighlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
        GemListHighlight:Show();

        LoadoutPlanner:SetFocusedButton(self);
    end

    function GemListMixinButton:OnLeave(motion, fromActionButton)
        if (not fromActionButton) and (self:IsShown() and self:IsMouseOver()) then return end;
        GemListHighlight:Hide();
        LoadoutPlanner:SetFocusedButton(nil);
    end

    function GemListMixinButton:SetItem(itemID)
        self.itemID = itemID;
        self.Icon:SetTexture(GetItemIcon(itemID));
        self.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);

        local name = ItemCache:GetItemName(itemID, self);
        self.Text1:SetText(name);

        local quality = ItemCache:GetItemQuality(itemID, self);
        local r, g, b = GetItemQualityColor(quality);

        self.Icon:SetDesaturation(0);
        self.Icon:SetVertexColor(1, 1, 1);
        self.traitState = 3;

        self.Text1:SetTextColor(r, g, b);
    end

    function GemListMixinButton:OnItemLoaded(itemID)
        if itemID == self.itemID then
            self:SetItem(itemID);
        end
    end

    function GemListMixinButton:ClearItem()
        self.itemID = nil;
        self:Hide();
    end

    function GemListMixinButton:PlayFlyInAnimation()
        self.AnimFlyIn:Stop();
        if self:IsShown() then
            self.AnimFlyIn:Play();
        end
    end

    function GemListMixinButton:ShowGameTooltip()

    end




    function GemListMixin:OnLoad()
        local height = 24;
        self.listButtons = {};

        local PageText = self:CreateFontString(nil, "OVERLAY", "NarciGemmaFontMedium");
        self.PageText = PageText;
        PageText:SetWidth(72);
        PageText:SetHeight(height);
        PageText:SetJustifyH("CENTER");
        PageText:SetPoint("BOTTOM", self, "BOTTOM", 0, 3);
        PageText:SetTextColor(0.88, 0.88, 0.88);

        self:SetScript("OnMouseDown", self.OnMouseDown);
        self:SetScript("OnMouseWheel", self.OnMouseWheel);

        local button1 = Gemma.CreateIconButton(self);
        self.PrevButton = button1;
        AtlasUtil:SetAtlas(button1.Icon, "gemlist-prev");
        button1:SetSize(height, height);
        button1:SetPoint("RIGHT", PageText, "LEFT", 0, 0);
        button1:SetScript("OnClick", function()
            self:OnMouseWheel(1);
        end);

        local button2 = Gemma.CreateIconButton(self);
        self.NextButton = button2;
        AtlasUtil:SetAtlas(button2.Icon, "gemlist-next");
        button2:SetSize(height, height);
        button2:SetPoint("LEFT", PageText, "RIGHT", 0, 0);
        button2:SetScript("OnClick", function()
            self:OnMouseWheel(-1);
        end);

        self.SelectionFrame = CreateFrame("Frame", nil, self, "NarciGemManagerSelectionVisualTemplate");
        AtlasUtil:SetAtlas(self.SelectionFrame.Border, "remix-square-yellow");
    end

    function GemListMixin:OnMouseDown(button)
        if button == "RightButton" then
            LoadoutPlanner:Hide();
        end
    end

    function GemListMixin:OnMouseWheel(delta)
        if delta > 0 and self.page > 1 then
            self.page = self.page - 1;
            self:SetPage(self.page);
        elseif delta < 0 and self.page < self.numPages then
            self.page = self.page + 1;
            self:SetPage(self.page);
        end
    end

    function GemListMixin:SetPage(page)
        self.page = page;
        self.PageText:SetText(page.." / "..self.numPages);

        if page > 1 then
            self.PrevButton:Enable();
        else
            self.PrevButton:Disable();
        end

        if page < self.numPages then
            self.NextButton:Enable();
        else
            self.NextButton:Disable();
        end

        local fromIndex = (page - 1) * ITEMS_PER_PAGE;
        local dataIndex;
        local button;
        local itemID;

        self.SelectionFrame:Hide();

        LoadoutPlanner:SetFocusedButton(nil);

        for i = 1, ITEMS_PER_PAGE do
            dataIndex = fromIndex + i;
            button = self.listButtons[i];
            itemID = self.itemList[dataIndex];

            if itemID then
                if not button then
                    button = CreateFrame("Button", nil, self, "NarciGemManagerGemListButtonTemplate");
                    self.listButtons[i] = button;
                    Mixin(button, GemListMixinButton);
                    button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, FROM_Y + (1 - i) * LISTBUTTON_HEIGHT);
                    button.index = i;
                    button:OnLoad();
                end

                button:Hide();
                button:SetItem(itemID);
                button.onClickFunc = self.onClickFunc;
                button:Show();

                if itemID == self.activeGemID then
                    self.SelectionFrame:ClearAllPoints();
                    self.SelectionFrame:SetPoint("CENTER", button.Icon, "CENTER", 0, 0);
                    self.SelectionFrame:Show();
                    self.SelectionFrame.AnimShrink:Stop();
                    self.SelectionFrame.AnimShrink:Play();
                    button.Text1:SetTextColor(1, 0.82, 0);
                    button.traitState = 2;
                end
            else
                if button then
                    button:ClearItem();
                end
            end
        end
    end

    function GemListMixin:UpdatePage()
        if self:IsShown() and self.page then
            self:SetPage(self.page);
        end
    end

    function GemListMixin:SetItemList(itemList, title, dataProvider)
        if itemList ~= self.itemList then
            self.itemList = itemList;
        else
            if self.page then
                self:SetPage(self.page);
                return
            end
        end

        local bestPage = 1;
        if self.activeGemID then
            for i, itemID in ipairs(itemList) do
                if itemID == self.activeGemID then
                    bestPage = math.floor((i - 1) / ITEMS_PER_PAGE) + 1;
                    break
                end
            end
        end

        local numPages = itemList and #itemList or 0;
        numPages = math.ceil(numPages / ITEMS_PER_PAGE);
        self.numPages = numPages;
        self:SetPage(bestPage);

        local showNavButton = numPages > 1;
        self.PrevButton:SetShown(showNavButton);
        self.NextButton:SetShown(showNavButton);
    end

    function GemListMixin:PlayFlyInAnimation()
        for i, button in ipairs(self.listButtons) do
            button:PlayFlyInAnimation();
        end
    end
end




local StatsMouseOverFrameMixin = {};
do  --Attribute Assignment
    --See StatAssignment.lua for StatButton methods
    local MinusPlusButtonMixin = {};

    function MinusPlusButtonMixin:OnClick()
        LoadoutPlanner:ModifyStat(self.owner.statType, self.direction);
        LoadoutPlanner:ShowStatAssignmentDetail(self.owner.statButton);
    end

    function MinusPlusButtonMixin:OnMouseDown()
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, -1);
    end

    function MinusPlusButtonMixin:OnMouseUp()
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0);
    end

    function MinusPlusButtonMixin:OnEnter()
        self.owner:HighlightButton(self);
    end

    function MinusPlusButtonMixin:OnLeave()
        self.owner:HighlightButton(nil);
    end

    local function CreateMinusPlusButton(parent, direction)
        local button = CreateFrame("Button", nil, parent);
        button:SetSize(36, 24);

        button.Icon = button:CreateTexture(nil, "OVERLAY");
        button.Icon:SetSize(14, 14);
        button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0);
        button.direction = direction;
        if direction < 0 then
            AtlasUtil:SetAtlas(button.Icon, "gemma-stats-mouseover-minus");
        else
            AtlasUtil:SetAtlas(button.Icon, "gemma-stats-mouseover-plus");
        end

        Mixin(button, MinusPlusButtonMixin);
        button:SetScript("OnClick", button.OnClick);
        button:SetScript("OnMouseDown", button.OnMouseDown);
        button:SetScript("OnMouseUp", button.OnMouseUp);
        button:SetScript("OnEnter", button.OnEnter);
        button:SetScript("OnLeave", button.OnLeave);

        button.owner = parent;

        return button
    end

    function StatsMouseOverFrameMixin:OnLoad()
        self:SetHeight(24);
        AtlasUtil:SetAtlas(self.Background, "gemma-stats-mouseover-bg");
        AtlasUtil:SetAtlas(self.Highlight, "gemma-stats-mouseover-buttonhighlight");
        self:SetScript("OnHide", self.OnHide);

        if not self.MinusButton then
            self.MinusButton = CreateMinusPlusButton(self, -1);
            self.MinusButton:SetPoint("CENTER", self.Count, "LEFT", -12, 0);
        end

        if not self.PlusButton then
            self.PlusButton = CreateMinusPlusButton(self, 1);
            self.PlusButton:SetPoint("CENTER", self.Count, "RIGHT", 12, 0);
        end

        local font = NarciSystemFont_Medium_Outline:GetFont();
        self.Count:SetFont(font, 16, "");
        self.Count:SetTextColor(0, 0, 0);
    end

    function StatsMouseOverFrameMixin:OnLeave()

    end

    function StatsMouseOverFrameMixin:OnHide()
        self:Hide();
        self:HighlightButton(nil);
    end

    function StatsMouseOverFrameMixin:HighlightButton(minusplusButton)
        self.Highlight:ClearAllPoints();
        if minusplusButton then
            self.Highlight:SetPoint("CENTER", minusplusButton, "CENTER", 0, 0);
            self.Highlight:Show();
            --FadeFrame(self.Highlight, 0.15, 1, 0);
        else
            self.Highlight:Hide();
            self:ShowStatAssignmentDetail(nil);
        end
    end

    function StatsMouseOverFrameMixin:ShowStatAssignmentDetail(statButton)
        self:ClearAllPoints();
        self.statButton = statButton;

        if statButton then
            self.Count:SetText(statButton.Count:GetText());
            self:SetPoint("CENTER", statButton, "CENTER", 0, 0);
            self.MinusButton:SetShown(statButton.showMinusButton);
            self.PlusButton:SetShown(statButton.showPlusButton);
            self.statType = statButton.index;
            self:SetFrameLevel(statButton:GetFrameLevel() + 2);
            self:Show();
        else
            self.statType = nil;
            self:Hide();
        end
    end
end




local CreateStatButton;
do
    local CreateFrame = CreateFrame;
    local Mixin = Mixin;

    local StatButtonMixin = {};

    function StatButtonMixin:SetData()

    end

    function StatButtonMixin:SetName(name)
        self.Name:SetText(name);
    end

    function StatButtonMixin:SetCount(count)
        self.amount = count;
        self.Count:SetText(count);
        if count > 0 then
            self.Count:SetTextColor(1, 0.82, 0);
            self.MinusButton:Show();
            self.showMinusButton = true;
        else
            self.Count:SetTextColor(0.5, 0.5, 0.5);
            self.MinusButton:Hide();
            self.showMinusButton = false;
        end
    end

    function StatButtonMixin:SetPlusButtonVisibility(showPlusButton)
        self.PlusButton:SetShown(showPlusButton);
        self.showPlusButton = showPlusButton;
    end

    function StatButtonMixin:SetValue(value)
        if self.valueFormat then
            value = string.format(self.valueFormat, value);
        end
        self.Value:SetText(value);
    end

    function StatButtonMixin:OnEnter()
        LoadoutPlanner:ShowStatAssignmentDetail(self);
    end

    function StatButtonMixin:OnLeave()
        if not self:IsMouseOver() then
            LoadoutPlanner:ShowStatAssignmentDetail(nil);
        end
    end

    function CreateStatButton(parent)
        local f = CreateFrame("Frame", nil, parent, "NarciGemManagerStatAssignmentTemplate");
        f:SetHeight(24);

        Mixin(f, StatButtonMixin);
        f.Count:SetTextColor(1, 0.82, 0);
        f.Name:SetTextColor(0.88, 0.88, 0.88);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);

        f:SetCount(0);

        AtlasUtil:SetAtlas(f.MinusButton, "gemma-stats-minus");
        AtlasUtil:SetAtlas(f.PlusButton, "gemma-stats-plus");

        f.MinusButton:SetVertexColor(0.5, 0.5, 0.5);
        f.PlusButton:SetVertexColor(0.5, 0.5, 0.5);

        return f
    end
end




local LoadoutPlannerMixin = {};
do
    function LoadoutPlannerMixin:OnLoad()
        self:SetScript("OnHide", self.OnHide);
    end

    function LoadoutPlannerMixin:OnHide()
        self:Hide();
        self:SetFocusedButton(nil);
    end

    function LoadoutPlannerMixin:ShowTinker(selectedTinkersList)
        if self.categoryKey ~= "tinker" then
            self.categoryKey = "tinker";
            self:ReleaseContent();
            self:ShowTraits();
        end
        self:ShowFooterDivider(true);
        self:SetTitle(L["Pandamonium Gem Category 2"]);


        selectedTinkersList = selectedTinkersList or {};

        local gemType = 3;  --Tinker
        local gems = DataProvider:GetItemListByType(gemType);
        local isTinkerSelected = {};
        self.isTinkerSelected = isTinkerSelected;

        for _, itemID in ipairs(gems) do
            isTinkerSelected[itemID] = false;
        end

        for _, itemID in ipairs(selectedTinkersList) do
            isTinkerSelected[itemID] = true;
        end

        self:UpdateTinkerSelection();
    end

    function LoadoutPlannerMixin:SelectTinker(itemID, state)
        if (state and self.chooseItem and (not self.isTinkerSelected[itemID])) or ((not state) and self.isTinkerSelected[itemID]) then
            self.isTinkerSelected[itemID] = state;
            self:UpdateTinkerSelection();
        end
    end

    function LoadoutPlannerMixin:UpdateTinkerSelection()
        local pointsInvested = 0;

        for itemID, selected in pairs(self.isTinkerSelected) do
            if selected then
                pointsInvested = pointsInvested + 1;
            end
        end

        local totalMissing = POINTS_REQUIRED_TINKER - pointsInvested;
        local chooseItem = totalMissing > 0;
        self.chooseItem = chooseItem;
        self:SetPointDisplayAmount(totalMissing);

        for index, button in ipairs(self.slotButtons) do
            if button:IsShown() then
                if self.isTinkerSelected[button.itemID] then
                    if chooseItem then
                        button:SetDimmed();
                    else
                        button:SetActive();
                    end
                else
                    if chooseItem then
                        button:SetAvailable();
                    else
                        button:SetInactive();
                    end
                end
            else
                break
            end
        end
    end


    function LoadoutPlannerMixin:ShowMajorGem(gemType, selectedItemID)
        if not gemType then return end;

        self:ReleaseContent();
        self:ShowFooterDivider(false);
        self.PointsDisplay:Hide();
        self.AcceptButton:Hide();
        self.chooseItem = true;

        if not GemList then
            GemList = CreateFrame("Frame", nil, self);
            GemList:SetAllPoints(true);
            Mixin(GemList, GemListMixin);
            GemList:OnLoad();
        end

        local title;

        if gemType == 1 then
            title = META_GEM;
            self.categoryKey = "head";
        elseif gemType == 2 then
            title = COGWHEEL_GEM;
            self.categoryKey = "feet";
        end

        GemList.activeGemID = selectedItemID;
    
        local gems = DataProvider:GetItemListByType(gemType);
        GemList:SetItemList(gems, DataProvider:GetGemTypeName(gemType), DataProvider);
        GemList:Show();

        self:SetTitle(title);
    end

    local function GetNumStatsPointInvested(gemInfoStats)
        local pointsInvested = 0;
        for statType, amount in pairs(gemInfoStats) do
            pointsInvested = pointsInvested + amount;
        end
        return pointsInvested
    end

    function LoadoutPlannerMixin:GetPointMissing()
        if self.pointsRequired and self.gemInfoStats then
            return self.pointsRequired - GetNumStatsPointInvested(self.gemInfoStats);
        else
            return 0
        end
    end

    function LoadoutPlannerMixin:ShowPrismaticGems(statsGroupIndex, gemInfoStats)
        self:ReleaseContent();
        self:ShowStats();

        gemInfoStats = gemInfoStats or {};
        self.gemInfoStats = gemInfoStats;

        local title;
        local helpTip;

        if statsGroupIndex == 1 then
            title = L["Pandamonium Slot Category 1"];
            self.pointsRequired = POINTS_REQUIRED_STATS1;
            self.categoryKey = "stats1";
        elseif statsGroupIndex == 2 then
            title = L["Pandamonium Slot Category 2"];
            self.pointsRequired = POINTS_REQUIRED_STATS2;
            local effectiveness = 75;
            helpTip = L["Format Gem Slot Stat Budget"]:format(title, effectiveness);
            self.categoryKey = "stats2";
        elseif statsGroupIndex == 3 then
            title = L["Pandamonium Slot Category 3"];
            self.pointsRequired = POINTS_REQUIRED_STATS3;
            local effectiveness = 73;
            helpTip = L["Format Gem Slot Stat Budget"]:format(title, effectiveness);
            self.categoryKey = "stats3";
        end

        self:SetTitle(title);
        self.HelpTip:SetText(helpTip);
        self:UpdatePrismaticGems();
    end

    function LoadoutPlannerMixin:UpdatePrismaticGems()
        local totalMissing = self:GetPointMissing();
        local chooseItem = totalMissing > 0;
        self:SetPointDisplayAmount(totalMissing);

        local count;

        for statType, button in ipairs(self.statButtons) do
            count = self.gemInfoStats[statType] or 0;
            button:SetCount(count);
            button:SetPlusButtonVisibility(chooseItem);
        end


    end

    function LoadoutPlannerMixin:ModifyStat(statType, delta)
        if delta > 0 and self:GetPointMissing() > 0 then
            if not self.gemInfoStats[statType] then
                self.gemInfoStats[statType] = 0;
            end
            self.gemInfoStats[statType] = self.gemInfoStats[statType] + 1;
        elseif delta < 0 then
            if self.gemInfoStats[statType] and self.gemInfoStats[statType] > 0 then
                self.gemInfoStats[statType] = self.gemInfoStats[statType] - 1;
            else
                return
            end
        end

        self:UpdatePrismaticGems();
    end

    local function ShowTooltip_OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.2 then
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            if self.focusedButton then
                self:ShowButtonTooltip(self.focusedButton);
            end
        end
    end

    function LoadoutPlannerMixin:SetFocusedButton(slotButton)
        --Show tooltip after delay
        self.focusedButton = slotButton;
        if slotButton then
            self.t = 0;
            self:SetScript("OnUpdate", ShowTooltip_OnUpdate);
        else
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            self:HideTooltip();
        end
    end

    function LoadoutPlannerMixin:ShowButtonTooltip(slotButton)
        local TooltipFrame = self.TooltipFrame;

        GameTooltip:SetOwner(slotButton, "ANCHOR_NONE");   --ANCHOR_RIGHT;

        if self:GetRight() + 256 < UIParent:GetRight() then
            GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 4, 0);
        else
            GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -8);
        end


        local itemID = slotButton.itemID;
        local spellID = Gemma:GetGemSpell(itemID);
        if spellID then
            GameTooltip:SetSpellByID(spellID);
        else
            GameTooltip:SetItemByID(itemID);
        end

        local actionText;
        local traitState = slotButton.traitState;
        local r, g, b;

        if traitState == 2 then
            actionText = L["Gemma Click To Deselect"];
            r, g, b = 1, 0.82, 0;
        else
            if self.chooseItem then
                actionText = L["Gemma Click To Select"];
                r, g, b = 0.098, 1.000, 0.098;
            end
        end

        if actionText then
            GameTooltip:AddLine(" ");
            GameTooltip:AddLine(actionText, r, g, b, true);
            GameTooltip:Show();
        end

        TooltipFrame:ShowGameTooltipBackground();

        local dataInstanceID = (GameTooltip.infoList) and (GameTooltip.infoList[1]) and (GameTooltip.infoList[1].tooltipData) and (GameTooltip.infoList[1].tooltipData.dataInstanceID);
        TooltipFrame:SetGameTooltipOwner(slotButton, dataInstanceID);
    end

    function LoadoutPlannerMixin:SetPointDisplayAmount(amount)
        self.PointsDisplay:SetAmount(amount);

        if amount > 0 then
            self.PointsDisplay:Show();
            self.AcceptButton:Hide();
        else
            self.PointsDisplay:Hide();
            self.AcceptButton:Show();
        end
    end


    function LoadoutPlannerMixin:AcquireSlotButton(shape)
        if not self.slotButtons then
            self.slotButtons = {};
            self.numSlotButtons = 0;
        end
    
        local index = self.numSlotButtons + 1;
        self.numSlotButtons = index;
    
        if not self.slotButtons[index] then
            local button = CreateTraitButton(self.SlotFrame, shape);
            button.index = index;
            self.slotButtons[index] = button;
        end
    
        self.slotButtons[index]:Show();
    
        if shape then
            self.slotButtons[index]:SetShape(shape);
        end
    
        return self.slotButtons[index]
    end

    function LoadoutPlannerMixin:AcquireStatButton()
        if not self.statButtons then
            self.statButtons = {};
            self.numStatButtons = 0;
        end

        local index = self.numStatButtons + 1;
        self.numStatButtons = index;

        if not self.statButtons[index] then
            local button = CreateStatButton(self.SlotFrame);
            button.index = index;
            self.statButtons[index] = button;

            AtlasUtil:SetAtlas(button.Background, "gemma-stats-bg");
            if index % 2 == 1 then
                button.Background:SetVertexColor(0.08, 0.08, 0.08, 0.9);
            else
                button.Background:SetVertexColor(38/255, 31/255, 28/255, 0.9);
            end
        end

        self.statButtons[index]:Show();

        return self.statButtons[index]
    end

    function LoadoutPlannerMixin:ReleaseContent()
        self:ReleaseSlots();
        self:ReleaseStatButtons();
        if GemList then
            GemList:Hide();
            GemListHighlight:Hide();
        end

        if self.HelpTip then
            self.HelpTip:SetText("");
        end
    end

    function LoadoutPlannerMixin:ShowTab(categoryKey, choice)
        if categoryKey == "tinker" then
            self:ShowTinker(choice);
        elseif categoryKey == "head" then
            self:ShowMajorGem(1, choice);
        elseif categoryKey == "feet" then
            self:ShowMajorGem(2, choice);
        elseif categoryKey == "stats1" then
            self:ShowPrismaticGems(1, choice);
        elseif categoryKey == "stats2" then
            self:ShowPrismaticGems(2, choice);
        elseif categoryKey == "stats3" then
            self:ShowPrismaticGems(3, choice);
        end
    end

    function LoadoutPlannerMixin:ShowStatAssignmentDetail(statButton)
        if statButton then
            if not StatsMouseOverFrame then
                StatsMouseOverFrame = CreateFrame("Frame", nil, self, "NarciGemManagerStatsMouseOverFrame");
                Mixin(StatsMouseOverFrame, StatsMouseOverFrameMixin);
                StatsMouseOverFrame:OnLoad();
            end
            StatsMouseOverFrame:ShowStatAssignmentDetail(statButton);
        else
            if StatsMouseOverFrame then
                StatsMouseOverFrame:Hide();
            end
        end
        
    end

    function LoadoutPlannerMixin:SaveCurrentChoice(arg1)
        local categoryKey = self.categoryKey;
        if not categoryKey then return end;

        if categoryKey == "tinker" then
            local tinker = {};
            local n = 0;

            for itemID, selected in pairs(self.isTinkerSelected) do
                if selected then
                    n = n + 1;
                    tinker[n] = itemID;
                end
            end

            if n == POINTS_REQUIRED_TINKER then
                table.sort(tinker);
                EditWindow:SetPendingChoice(categoryKey, tinker);
            end
        elseif categoryKey == "head" or categoryKey == "feet" then
            local itemID = arg1;
            EditWindow:SetPendingChoice(categoryKey, itemID);
        elseif categoryKey == "stats1" or categoryKey == "stats2" or categoryKey == "stats3" then
            local gemInfoStats = self.gemInfoStats;
            EditWindow:SetPendingChoice(categoryKey, gemInfoStats);
        end

        self:Hide();
    end


    local function CreateLoadoutPlanner(parent)
        local f = Gemma.CreateWindow(parent);
        LoadoutPlanner = f;
        EditWindow = parent;
    
        Mixin(f, LoadoutPlannerMixin);
        f.isLoadoutPlanner = true;

        local HEADER_HEIGHT = 40;
        local FOOTER_HEIGHT = 64;

        local PointsDisplay = Gemma.CreatePointsDisplay(f);
        f.PointsDisplay = PointsDisplay;
        PointsDisplay:ClearAllPoints();
        --PointsDisplay:SetPoint("TOP", f, "TOP", 0, -HEADER_HEIGHT - 20);
        PointsDisplay:SetPoint("CENTER", f, "BOTTOM", 0, 34);
        PointsDisplay:SetLabel(L["Pandamonium Sockets Available"]);
        PointsDisplay:SetAmount(0);

        f.AcceptButton = CreateFrame("Button", nil, f); --Size and position setup in Loadout.lua
        f.AcceptButton:SetScript("OnClick", function()
            LoadoutPlanner:SaveCurrentChoice();
        end);

        DataProvider = Gemma:GetDataProviderByName("Pandaria");
        Mixin(f, DataProvider.GemManagerMixin);

        local inheritedMethods = {
            "ReleaseSlots", "ReleaseStatButtons",
            "HideTooltip",
        };

        local fromMixin = NarciGemManagerMixin;

        for _, method in ipairs(inheritedMethods) do
            f[method] = fromMixin[method];
        end


        f.SlotFrame = CreateFrame("Frame", nil, f);
        f.SlotFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -HEADER_HEIGHT);
        f.SlotFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, FOOTER_HEIGHT);

        SlotHighlight = Gemma.CreateSlotHighlight(f.SlotFrame);
        SlotHighlight:SetLayerFront(true);
        SlotHighlight:SetShape("Hexagon");

        f.TooltipFrame = NarciGemManager.TooltipFrame;


        GemListHighlight = CreateFrame("Frame", nil, f, "NarciGemManagerButtonHighlightTemplate");
        GemListHighlight.Texture:ClearAllPoints();
        GemListHighlight.Texture:SetAllPoints(true);
        AtlasUtil:SetAtlas(GemListHighlight.Texture, "remix-listbutton-highlight");
        GemListHighlight.Texture:SetBlendMode("ADD");

        f.HelpTip = f:CreateFontString(nil, "OVERLAY", "NarciGemmaFontMedium");
        f.HelpTip:SetJustifyH("CENTER");
        f.HelpTip:SetJustifyV("TOP");
        f.HelpTip:SetPoint("TOP", f, "TOP", 0, -HEADER_HEIGHT - 14);
        f.HelpTip:SetTextColor(0.5, 0.5, 0.5);
        f.HelpTip:SetWidth(240);


        f:OnLoad();

        return f
    end
    Gemma.CreateLoadoutPlanner = CreateLoadoutPlanner;
end