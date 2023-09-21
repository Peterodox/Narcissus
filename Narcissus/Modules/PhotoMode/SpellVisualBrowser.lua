local _, addon = ...

local TransitionAPI = addon.TransitionAPI;

------------------------------------------------------------------------
local VISUAL_ID_MAX = 190000;
local TAB_WIDTH = 116;
local NUM_MAX_HISTORY = 5;
local MODEL_SETTINGS_FRAME_WIDTH = 440;
local BROWSER_ANCHOR_OFFSET_COLLAPSED_X = 146;
local BROWSER_ANCHOR_OFFSET_EXPANED_X = -28;
local BROWSER_ANCHOR_OFFSET_Y = -6;
local FREQUENTLY_USED_BUTTON_TOOLTIP_DELAY = 1;
------------------------------------------------------------------------

local Narci = Narci;
local L = Narci.L;
local FadeFrame = NarciFadeUI.Fade;
local After = C_Timer.After;
local tinsert = table.insert;

local BrowserFrame, ListFrame, PreviewFrame, HistoryFrame, Tab1, ListScrollBar, HistoryButtonFrame, QuickFavoriteButton, SuggestionFrame, HomeButton, MyFavoriteEditFrame;
local NUM_VISIBLE_BUTTONS = 0;

local NarciSpellVisualBrowser = NarciSpellVisualBrowser;
local SpellVisualList = NarciSpellVisualBrowser.Catalogue;
local GetSpellVisualKitInfo = NarciSpellVisualBrowser.GetSpellVisualKitInfo;
local IsSpellVisualLogged = NarciSpellVisualBrowser.IsSpellVisualLogged;
local NarciTooltip = NarciTooltip;
local SelectedVisualIndex;

local function CountLength(table)
    local count = 0;
    for i = 1, #table do
        count = count + #table[i];
    end
    return count;
end

local function PrintTable(table)
    for k, v in pairs(table) do
        if v ~= nil then
            print(k.." -  "..v);
        end
    end
end

-------------------------------------------
--Public method : Used in PlayerModel.lua

function NarciSpellVisualBrowser:LoadHistory()
    local model = Narci.ActiveModel;
    if not model then return; end;

    SelectedVisualIndex = nil;
    local AppliedVisuals = model.AppliedVisuals;
    NUM_VISIBLE_BUTTONS = #AppliedVisuals;
    local buttons = HistoryFrame.HistoryButtonFrame.buttons;
    local button;
    local name, icon, animID;
    for i = 1, #buttons do
        button = buttons[i];
        if AppliedVisuals[i] then
            button:Show();
            button:SetAlpha(1);
            name, icon, animID = GetSpellVisualKitInfo( AppliedVisuals[i] );
            button.Icon:SetTexture(icon);
            button.Icon:SetAlpha(0.6);
            button.name = name;
        else
            button:Hide();
        end
        button.Border:SetTexCoord(0, 0.25, 0, 1);
        button.selected = false;
    end

    button = buttons[1];
    button:SetPoint("BOTTOMRIGHT", HistoryButtonFrame, "BOTTOMRIGHT", 24 * (1 - NUM_VISIBLE_BUTTONS), 0);
end

-------------------------------------------
------------Animation Container------------
-------------------------------------------
local AnimationContariner = CreateFrame("Frame");   --Root
local pi = math.pi;
local max = math.max;
local sin = math.sin;
local cos = math.cos;

local function linear(t, b, e, d)
	return (e - b) * t / d + b
end
local function outSine(t, b, e, d)                  --elapsed, begin, end, duration
	return (e - b) * sin(t / d * (pi / 2)) + b
end
local function inOutSine(t, b, e, d)
	return -(e - b) / 2 * (cos(pi * t / d) - 1) + b
end

-------------------------------------------
--Toggle Spell Visual Brower frame
local ExpandAnim = CreateFrame("Frame");
ExpandAnim:Hide();
ExpandAnim.total = 0;
ExpandAnim.duration = 0.25;
ExpandAnim:SetScript("OnHide", function(self)
    self.total = 0;
end);
ExpandAnim.duration2 = 0.5;
local ModelSettings = Narci_ModelSettings;

ExpandAnim:SetScript("OnShow", function(self)
    self.StartHeight = BrowserFrame:GetHeight();
    _, self.xRelativeTo, _, self.StartX = BrowserFrame:GetPoint();
    _, self.yRelativeTo, _, _, self.StartY = BrowserFrame.ExpandableFrames:GetPoint();
    self.StartWidth = ModelSettings:GetWidth();
end);

local function Expand_OnUpdate(self, elapsed)
    self.total = self.total + elapsed;
    local newTotal  = self.total;
    local offsetX = outSine(newTotal, self.StartX, self.EndX, self.duration);
    local width = outSine(newTotal, self.StartWidth, self.EndWidth, self.duration);
	if newTotal >= self.duration then
        offsetX = self.EndX;
        width = self.EndWidth;
        local offsetY = outSine(newTotal - self.duration, self.StartY, self.EndY, 0.25);
        if newTotal >= self.duration2 then
            offsetY = self.EndY;
            self:Hide();
        end
        BrowserFrame.ExpandableFrames:SetPoint("BOTTOM", self.yRelativeTo, "TOP", 0, offsetY);
    end
    BrowserFrame:SetPoint("BOTTOMRIGHT", self.xRelativeTo, "BOTTOMLEFT", offsetX, BROWSER_ANCHOR_OFFSET_Y);
    ModelSettings:SetWidth(width);

    --To keep the other panels still while widen this frame, their anchors must be updated
    --10 is ActorPanel's offset to its parent frame
    ModelSettings.ActorPanel:SetPoint("TOPLEFT", ModelSettings, "TOPLEFT", width - MODEL_SETTINGS_FRAME_WIDTH + 10, 0);
end

ExpandAnim:SetScript("OnUpdate", Expand_OnUpdate);

local MODEL_SETTINGS_FRAME_WIDTH = ModelSettings:GetWidth();

local function ReAnchorBrowser()
    --local oldRight = ModelSettings:GetRight();
    local oldCenterX = ModelSettings:GetCenter();
    local oldBottom = ModelSettings:GetBottom();
    local screenWidth = WorldFrame:GetWidth();
    local scale = ModelSettings:GetEffectiveScale();
    if not scale or scale == 0 then
        scale = 1;
        --return;
    end
    local width = ModelSettings:GetWidth()/2;
    ModelSettings:ClearAllPoints();
    ModelSettings:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", oldCenterX + width - screenWidth / scale , oldBottom);
end


function Narci_ToggleSpellVisualBrowser(self)
    if ExpandAnim:IsShown() then return; end;
    self.isActive = not self.isActive;
    ReAnchorBrowser();
    local state = self.isActive;
    BrowserFrame.isActive = state;
    
    local newWidth;
    local newOffsetX, newOffsetY;  --for 2 different widgets
    if state then
        newWidth = MODEL_SETTINGS_FRAME_WIDTH + 218;
        newOffsetY = 0;
        newOffsetX = BROWSER_ANCHOR_OFFSET_EXPANED_X;
        FadeFrame(BrowserFrame, 0.15, 1);
        FadeFrame(self.Background, 0.15, 0);
        FadeFrame(self.Label, 0.15, 0);
        After(0.25, function()
            FadeFrame(BrowserFrame.ExpandableFrames, 0.25, 1);
        end);

        self:SetWidth(24);
    else
        newWidth = MODEL_SETTINGS_FRAME_WIDTH;
        newOffsetX = BROWSER_ANCHOR_OFFSET_COLLAPSED_X;
        newOffsetY = -40;
        FadeFrame(BrowserFrame.ExpandableFrames, 0.15, 0);
        After(0.15, function()
            FadeFrame(BrowserFrame, 0.25, 0);
        end);

        self:SetWidth(58);
    end

    ExpandAnim.EndY = newOffsetY;       --ExpandableFrames
    ExpandAnim.EndX = newOffsetX;       --BrowserFrame
    ExpandAnim.EndWidth = newWidth;     --ModelSettings

    if state then
        --Expand
        ExpandAnim.duration2 = 0.5;
        ExpandAnim:Show();
    else
        ExpandAnim.duration2 = 0.25;
        After(0.2, function()
            ExpandAnim:Show();
            FadeFrame(self.Background, 0.15, 1);
            FadeFrame(self.Label, 0.15, 1);
        end);
    end
end


--Tab Changing Animation    (Choose a category and go)
local SwipeAnim = NarciAPI_CreateAnimationFrame(0.25);

SwipeAnim:SetScript("OnShow", function(self)
    self.point, self.relativeTo, self.relativePoint, self.startOffset = Tab1:GetPoint();
end);

local function Swipe_OnUpdate(self, elapsed)
	self.total = self.total + elapsed;
	local offset = outSine(self.total, self.startOffset, self.endOffset, self.duration);

	if self.total >= self.duration then
		offset = self.endOffset;
		self:Hide();
    end
    Tab1:SetPoint(self.point, self.relativeTo, self.relativePoint, offset, 0);
end

SwipeAnim:SetScript("OnUpdate", Swipe_OnUpdate);

local function GoToTab(index)
    SwipeAnim:Hide();
    SwipeAnim.endOffset = (1 - index) * TAB_WIDTH;
    SwipeAnim:Show();
    if index ~= 1 then
        FadeFrame(HomeButton, 0.2, 1);
        HomeButton.CurrentTabIndex = index;
        PreviewFrame:Disable();
    else
        PreviewFrame:Enable();
    end
    
    --Guide
    if BrowserFrame.ShowGuide then
        BrowserFrame.Guide.TabListener:SetValue(3);
        BrowserFrame.ShowGuide = false;
    end
end


--Tab collapsing Animation
local CollapseAnim = NarciAPI_CreateAnimationFrame(0.2);

CollapseAnim:SetScript("OnShow", function(self)
    self.StartHeight = self.tab:GetHeight();
end);

local function Collapse_OnUpdate(self, elapsed)
	self.total = self.total + elapsed;
	local height = outSine(self.total, self.StartHeight, self.EndHeight, self.duration);

	if self.total >= self.duration then
		height = self.EndHeight;
		self:Hide();
    end
    self.tab:SetHeight(height);
end

CollapseAnim:SetScript("OnUpdate", Collapse_OnUpdate);

local function CollapseTab(tab, endHeight)
    CollapseAnim:Hide();
    CollapseAnim.tab = tab;
    CollapseAnim.EndHeight = endHeight;
    CollapseAnim:Show();
end


--Gradually Update Scroll Range
local RangeAnim = NarciAPI_CreateAnimationFrame(0.5);

RangeAnim:SetScript("OnShow", function(self)
    _, self.StartValue = ListScrollBar:GetMinMaxValues();
    if self.EndValue < 0.1 then
        ListScrollBar.Thumb:Hide();
    else
        ListScrollBar.Thumb:Show();
    end
end);

local function UpdateInnerShadowStates(scrollBar, newMax, smoothing)
	local currValue = scrollBar:GetValue();
    local minVal, maxVal = scrollBar:GetMinMaxValues();
    local maxVal = newMax or maxVal;
    if maxVal == 0 then
        scrollBar.Thumb:Hide();
    else
        scrollBar.Thumb:Show();
    end
    if not smoothing then
        if ( currValue >= maxVal - 12) then
            scrollBar.BottomShadow:Hide();
        else
            scrollBar.BottomShadow:Show();
        end
        
        if ( currValue <= minVal + 12) then
            scrollBar.TopShadow:Hide();
        else
            scrollBar.TopShadow:Show();
        end

        scrollBar.BottomShadow:SetAlpha(1);
        scrollBar.TopShadow:SetAlpha(1);
    else
        if ( currValue >= maxVal - 12) then
            FadeFrame(scrollBar.BottomShadow, 0.2, 0);
        else
            if not scrollBar.BottomShadow:IsShown() then
                FadeFrame(scrollBar.BottomShadow, 0.2, 1);
            end
        end
        
        if ( currValue <= minVal + 12) then
            FadeFrame(scrollBar.TopShadow, 0.2, 0);
        else
            if not scrollBar.TopShadow:IsShown() then
                FadeFrame(scrollBar.TopShadow, 0.2, 1);

            end
        end
    end
end

local function Range_OnUpdate(self, elapsed)
	self.total = self.total + elapsed;
	local range = inOutSine(self.total, self.StartValue, self.EndValue, self.duration);

	if self.total >= self.duration then
		range = self.EndValue;
        self:Hide();
    end
    ListScrollBar:SetMinMaxValues(0, range);
end

RangeAnim:SetScript("OnUpdate", Range_OnUpdate);

local function SmoothRange(newRange)
    RangeAnim:Hide();
    RangeAnim.EndValue = newRange;
    RangeAnim:Show();
end

--Add button onto History tab
local InsertAnim = NarciAPI_CreateAnimationFrame(0.5);
--Remove a button from History tab
local RemoveAnim = NarciAPI_CreateAnimationFrame(0.5);

local function RemapButton()
    --print(NUM_VISIBLE_BUTTONS)
    if NUM_VISIBLE_BUTTONS <= NUM_MAX_HISTORY then return; end
    local buttons = HistoryButtonFrame.buttons;
    local button, icon, name;
    local numButton = #buttons;

    local icons = {};
    local names = {};

    for i = 1, numButton do
        button = buttons[i];
        icon = button.textureID or 134400;
        tinsert(icons, icon);
        tinsert(names, button.name);
    end

    for i = 1, (numButton - 1) do
        button = buttons[i];
        icon = icons[i + 1];
        name = names[i + 1];
        button.Icon:SetTexture(icon);
        button.name = name;
        button.textureID = icon;
    end
    icon = icons[1];
    name = names[1];
    button = buttons[1];
    button:SetPoint("BOTTOMRIGHT", HistoryButtonFrame, "BOTTOMRIGHT", -(24 * (NUM_MAX_HISTORY - 1)) , 0);

    button = buttons[numButton];
    button.Icon:SetTexture(icon);  --icon[1], icon[2], icon[3]
    button.name = name;
    button.textureID = icon;

    buttons[NUM_MAX_HISTORY + 1]:Hide();
    --print("Remapped");
end

InsertAnim:SetScript("OnShow", function(self)
    local buttons = HistoryButtonFrame.buttons;
    local num = NUM_VISIBLE_BUTTONS;
    local NewButton = buttons[num];
    self.StartX = (num - 2) * 24;
    self.EndX = (num - 1) * 24;
    self.StartY = HistoryButtonFrame.offsetY;
    if num == 1 then
        self.button1 = nil;
        self.button2 = buttons[1];              --Drop down
        self.button3 = nil;
    else
        self.button1 = buttons[1];              --Move left
        self.button2 = NewButton;               --Drop down
        if num <= NUM_MAX_HISTORY then
            self.button3 = buttons[num - 1];    --Anchor button
        else
            self.button3 = nil;
        end
    end
    FadeFrame(NewButton, 0.12, 1);
    NewButton.animIn:Play();
end);

local function Insert_OnUpdate(self, elapsed)
	self.total = self.total + elapsed;
    local offsetX = inOutSine(self.total, self.StartX, self.EndX, self.duration);
    local offsetY = outSine(self.total, self.StartY, 0, self.duration);

	if self.total >= self.duration then
        offsetX = self.EndX;
        offsetY = 0;
        self:Hide();
        After(0, function()
            if self.button3 then
                self.button2:ClearAllPoints();
                self.button2:SetPoint("LEFT", self.button3, "RIGHT", 0, 0);
            end
            RemapButton();
        end);
    end
    
    if self.button1 then
        self.button1:SetPoint("BOTTOMRIGHT", HistoryButtonFrame, "BOTTOMRIGHT", -offsetX, 0);
    end
    self.button2:SetPoint("BOTTOMRIGHT", HistoryButtonFrame, "BOTTOMRIGHT", 0, offsetY);
end

InsertAnim:SetScript("OnUpdate", Insert_OnUpdate);

local function AddToHistory(visualID)
    local model = Narci.ActiveModel;
    if not model then return; end;

    local AppliedVisuals = model.AppliedVisuals or {};
    local NewHistory = {};

    for i = 1, #AppliedVisuals do
        NewHistory[i] = AppliedVisuals[i];
    end

    if #NewHistory < NUM_MAX_HISTORY then
        tinsert(NewHistory, visualID);
    else
        for i = 1, (#NewHistory - 1) do
            NewHistory[i] = NewHistory[i + 1];
        end
        NewHistory[NUM_MAX_HISTORY] = visualID;
    end
    wipe(model.AppliedVisuals);
    model.AppliedVisuals = NewHistory;
end

local function HistoryButton_ResetSelection()
    local buttons = HistoryButtonFrame.buttons;
    SelectedVisualIndex = nil;
    local button;
    for i = 1, #buttons do
        button = buttons[i];
        button.Border:SetTexCoord(0, 0.25, 0, 1);
        button.selected = false;
        button.Icon:SetAlpha(0.6);
    end  
end

local function SmoothInsert(visualID, textureID, visualName)
    if RemoveAnim:IsShown() or InsertAnim:IsShown() then return; end;

    local model = Narci.ActiveModel;
    if model then
        model:ApplySpellVisualKit(visualID, false);
    else
        return;
    end

    local button;
    if NUM_VISIBLE_BUTTONS <= NUM_MAX_HISTORY then
        NUM_VISIBLE_BUTTONS = NUM_VISIBLE_BUTTONS + 1;
        button = HistoryButtonFrame.buttons[NUM_VISIBLE_BUTTONS];
    else
        button = HistoryButtonFrame.buttons[NUM_MAX_HISTORY + 1];
    end
    
    HistoryButton_ResetSelection();
    textureID = textureID or 134400;
    button.Icon:SetTexture(textureID);
    button.Icon:SetTexCoord(0, 1, 0, 1);
    button.textureID = textureID;
    button.visualID = visualID;
    button.name = visualName;
    InsertAnim:Show();
    AddToHistory(visualID);
    FadeFrame(HistoryFrame.Note, 0.25, 0);
    FadeFrame(HistoryFrame.Label, 0.15, 1);

    if model.isVirtual then
        --Rewrite model index button's tooltip
        local button = Narci_ActorPanel.ExtraPanel.buttons[model.buttonIndex];
        if button then
            button.Label:SetText(visualName);
        end
    end
end

----------------------------------------------------------------

RemoveAnim:SetScript("OnShow", function(self)
    self.ReAnchoredButton:ClearAllPoints();
    self.EndX = self.StartX + 24;
end)

local function RemapIcons(buttonID)
    local buttons = HistoryButtonFrame.buttons;
    local button, icon, name;
    local numButton = #buttons;

    local icons = {};
    local names = {};

    for i = 1, numButton do
        button = buttons[i];
        icon = button.textureID or 134400;
        tinsert(icons, icon);
        tinsert(names, button.name);
    end

    if buttonID == 1 then
        for i = 1, numButton - 1 do
            button = buttons[i];
            icon = icons[i + 1];
            name = names[i + 1];
            button.Icon:SetTexture(icon);
            button.name = name;
            button.textureID = icon;
        end
    else
        for i = buttonID, numButton - 1 do
            button = buttons[i];
            icon = icons[i + 1];
            name = names[i + 1];
            button.Icon:SetTexture(icon);
            button.name = name;
            button.textureID = icon;
        end
    end
end

local function Remove_OnUpdate(self, elapsed)
    self.total = self.total + elapsed;
    local alpha = linear(self.total, 1, 0, self.duration - 0.25) ;
    local offsetX = inOutSine(self.total, self.StartX, self.EndX, self.duration);
	if self.total >= self.duration then
        alpha = 0;
        offsetX = self.EndX;
        self:Hide();
        After(0, function()
            HistoryButton_ResetSelection();
            self.RemovedButton:SetAlpha(1);
            if self.LeftButton then
                self.RemovedButton:SetPoint("LEFT", self.LeftButton, "RIGHT", 0, 0);
            end
            if self.ReAnchoredButton then
                self.ReAnchoredButton:SetPoint("LEFT", self.RemovedButton, "RIGHT", 0, 0);
            end
            if not self.Reposition then
                self.LeadButton:SetPoint("BOTTOMRIGHT", HistoryButtonFrame, "BOTTOMRIGHT", offsetX, 0);
            end
            RemapIcons(self.buttonID)
        end);
    end
    if alpha < 0 then
        alpha = 0;
    end
    self.RemovedButton:SetAlpha(alpha);
    if self.Reposition then
        self.LeadButton:SetPoint("BOTTOMRIGHT", HistoryButtonFrame, "BOTTOMRIGHT", offsetX, 0);
    end
end

RemoveAnim:SetScript("OnUpdate", Remove_OnUpdate);

local function SmoothRemove(buttonID)
    if not buttonID or RemoveAnim:IsShown() or InsertAnim:IsShown() then return; end;
    local buttons = HistoryButtonFrame.buttons;
    local RemovedButton = buttons[buttonID];
    RemoveAnim.RemovedButton = RemovedButton;
    RemoveAnim.LeadButton = buttons[1];
    RemoveAnim.LeftButton = buttons[buttonID - 1];
    RemoveAnim.ReAnchoredButton = buttons[buttonID + 1];
    _, _, _, RemoveAnim.StartX = buttons[1]:GetPoint();
    RemoveAnim.buttonID = buttonID;
    if buttonID == 1 then
        RemoveAnim.Reposition = false;
    else
        RemoveAnim.Reposition = true;
    end

    if buttonID ~= 1 then
        RemovedButton:ClearAllPoints();
    end

    if NUM_VISIBLE_BUTTONS > NUM_MAX_HISTORY then
        NUM_VISIBLE_BUTTONS = NUM_MAX_HISTORY - 1;
    else
        NUM_VISIBLE_BUTTONS = NUM_VISIBLE_BUTTONS - 1;
    end
    RemoveAnim:Show();
end
-----------------------------------------------------------------------

local function UpdateScrollRange(smoothing)
    local ScrollFrame = ListFrame.ScrollFrame;
    local ScrollChild = ScrollFrame.ScrollChild;
    local TotalButton = ScrollChild.numEffectiveButtons;
    local parentButtons = ScrollChild.parentButtons;
    local collapsedButton = 0;
    local parentButton;

    for i = 1, #parentButtons do
        parentButton = parentButtons[i];
        if parentButton.collapsed then
            collapsedButton = collapsedButton + parentButton.childNum;
        end
    end

    local buttonHeight = 16;
    local ButtonPerPage = 8;
    local TotalHeight = (TotalButton - collapsedButton) * buttonHeight;
    local MaxScroll = max(0, TotalHeight - ButtonPerPage * buttonHeight);
    ScrollFrame.range = MaxScroll;
    if smoothing then
        SmoothRange(MaxScroll);
        UpdateInnerShadowStates(ListScrollBar, MaxScroll, true);
    else
        ScrollFrame.scrollBar:SetMinMaxValues(0, MaxScroll);
        UpdateInnerShadowStates(ListScrollBar, MaxScroll, false);
    end
end

local function SubcategoryButton_OnClick(self)
    self.collapsed = not self.collapsed;
    local tabHeight;
    if self.collapsed then
        FadeFrame(self.Drawer, 0.15, 0);
        self.Icon:SetTexCoord(0, 1, 0, 1);
        tabHeight = 16;
    else
        FadeFrame(self.Drawer, 0.2, 1);
        self.Icon:SetTexCoord(0, 1, 1, 0);
        tabHeight = 16 * (self.childNum + 1);
    end

    CollapseTab(self.Drawer, tabHeight - 1);
    UpdateScrollRange(true);
end

local clickCounter = {};
clickCounter.leftButton = 0;

local function EntryButton_OnClick(self, button)
    local model = Narci.ActiveModel;
    if not model then return; end;
    if button == "LeftButton" then
        model:ApplySpellVisualKit(self.visualID, true);

        --Show Mouse Button Tooltip:    Right-click to apply visuals
        if not clickCounter.tooltipShown then
            clickCounter.leftButton = clickCounter.leftButton + 1;
            if clickCounter.leftButton >= 3 then
                clickCounter.tooltipShown = true;
                BrowserFrame.MouseButton:FadeIn();
            end
        end

    elseif button == "RightButton" then
        SmoothInsert(self.visualID, self.texID, self:GetText());
    end

    --Set Suggested AnimationID
    local animID = self.animID;
    SuggestionFrame.IDButton.animID = animID;
    if animID then
        if SuggestionFrame.AutoPlay.IsOn then
            model:PlayAnimation(animID);
            animID = "|cffd9cdb4"..animID;
        end
    else
        animID = "|cffa7a7a7".."N/A";
    end
    SuggestionFrame.IDButton:SetText(animID);
end

local function SuggestedID_OnClick(self)
    if self.animID then
        local model = Narci.ActiveModel;
        if not model then return; end;
        model:PlayAnimation(self.animID);
        NarciModelControl_AnimationIDEditBox:SetText(self.animID);
    end
end
-------------------------------------------------
----------------Set preview image----------------
-------------------------------------------------
local PreviewTimer = NarciAPI_CreateAnimationFrame(0.25);
PreviewTimer:SetScript("OnHide", function(self)
    self:Hide();
    self.total = 0;
end);
PreviewTimer:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    if self.total >= self.duration then
        if self.visualID == self.pendingID then                --Some times when you collpase/expand a tab, OnEnter gets triggerred. In this case don't update prewview image
                --print(self.visualID)
            if IsSpellVisualLogged(self.visualID) then
                PreviewFrame.TopImage.FadeOut:Play();
                --print("Has preview")
            else
                --print("no preview")
                PreviewFrame.BottomImage:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SpellVisualPreviews\\Blank");
            end
        end
        self:Hide();
    end
end);

local function UpdatePreview(visualID)
    if not visualID then return; end;
    PreviewFrame.BottomImage:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SpellVisualPreviews\\"..tostring(visualID));
    PreviewTimer.total = 0;
    PreviewTimer.visualID = visualID;
    PreviewTimer:Show();
end

-------------------------------------------------
local function ShowHighlight(self)
    PreviewTimer.pendingID = self.visualID;
    FadeFrame(self.Highlight, 0.12,  1);
end

local function HideHighlightAndClearID(self)
    PreviewTimer.pendingID = nil;
    FadeFrame(self.Highlight, 0.2, 0);
end

local function SubcategoryButton_OnEnter(self)
    ShowHighlight(self);
    --self:SetIgnoreParentAlpha(true);
    QuickFavoriteButton:Hide();
end

local function SubcategoryButton_OnLeave(self)
    HideHighlightAndClearID(self);
    self:GetParent():SetAlpha(1);
    --self:SetIgnoreParentAlpha(false);
end

local FavoriteSpellVisualKitIDs = {};
local IsFavorite = {};

local function EnrtyButton_OnEnter(self)
    ShowHighlight(self);
    if not self.visualID then return; end;
    UpdatePreview(self.visualID);
    local Star = QuickFavoriteButton;
    Star:SetPoint("CENTER", self.Star, "CENTER", 0, 0);
    Star.parent = self;
    Star:Show();
    Star.visualID = self.visualID;
    Star:SetFavorite(IsFavorite[self.visualID]);
end


local function CreateEntryButtonFrames(Category)
    local ScrollFrame = ListFrame.ScrollFrame
    local ScrollChild = ScrollFrame.ScrollChild;
    local scrollBar = ScrollFrame.scrollBar;
    scrollBar:SetValue(0);
    scrollBar.BottomShadow:SetAlpha(0);
    scrollBar.TopShadow:SetAlpha(0);
    local button, drawerFrame;
    local entryFrames = {};
    local totalFrames = ScrollChild.buttons or {};
    local parentButtons = {};
    local list, listLength;
    local totalButton, totalEntry = 1, 0;
    local info, tex;

    if totalFrames then
        for i = 1, #totalFrames do
            totalFrames[i]:Hide();
            totalFrames[i].childNum = 0;
        end
    end

    for i = 1, #SpellVisualList[Category] do
        --Tab Button--
        list = SpellVisualList[Category][i];
        listLength = #list;
        button = totalFrames[totalButton];
        if not button then
            button = CreateFrame("Button", nil, ScrollChild, "Narci_OptionalSpellVisualButtonTemplate");
            tinsert(totalFrames, button);
        else
            button:ClearAllPoints();
            button:SetParent(ScrollChild);
        end
        tinsert(parentButtons, button);

        if totalButton == 1 then
            button:SetPoint("TOP", ScrollChild, "TOP", 0, -16);
        else
            button:SetPoint("TOP", parentButtons[i - 1].Drawer, "BOTTOM", 0, 0);
        end
        button:Show();
        button:SetText(list["name"]);
        button.Drawer:Hide();
        button.Drawer:SetAlpha(0);
        button.Drawer:SetHeight(15);
        button.Divider:Show()
        button.collapsed = true;
        button.text = list["name"];
        button.ButtonText:SetJustifyH("CENTER");
        button.ButtonText:SetPoint("CENTER", 0, 0);
        button.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\SpellVisualBrowser\\ExpandMark");
        button.Icon:SetTexCoord(0, 1, 0, 1);
        button.Star:Hide();
        button.visualID = nil;
        button.Count:SetText(listLength);
        button.Count:Show();
        button.Background:Show();
        button.childNum = listLength;
        button:SetPushedTextOffset(0, 0);
        button:SetScript("OnClick", SubcategoryButton_OnClick);
        button:SetScript("OnEnter", SubcategoryButton_OnEnter);
        button:SetScript("OnLeave", SubcategoryButton_OnLeave);

        totalButton = totalButton + 1;
        drawerFrame = button.Drawer;

        for j = listLength, 1, -1 do                                            --1, listLength, 1
            --Entry button--
            button = totalFrames[totalButton];
            if not button then
                button = CreateFrame("Button", nil, drawerFrame, "Narci_OptionalSpellVisualButtonTemplate");
                tinsert(totalFrames, button);
            else
                button:ClearAllPoints();
                button:SetParent(drawerFrame);
            end
            tinsert(entryFrames, button);

            button:Show();
            drawerFrame:SetAlpha(0);
            drawerFrame:Hide();
            drawerFrame:SetHeight(15);
            if j == listLength then
                --button:SetPoint("BOTTOM", drawerFrame, "BOTTOM", 0, 0);    -- 0,-16 When anchor to the top
                button.Divider:Show()
            else
                --button:SetPoint("BOTTOM", entryFrames[totalEntry], "TOP", 0, 0);
                button.Divider:Hide();
            end
            button:SetPoint("BOTTOM", drawerFrame, "BOTTOM", 0, 16*(listLength - j));
            button.Background:Hide();
            info = list[j];
            button.visualID = info[1];
            button.animID = info[4];
            if IsFavorite[info[1]] then
                button.Star:Show();
            else
                button.Star:Hide();
            end
            button:SetText(info[2]);
            button.ButtonText:SetJustifyH("LEFT");
            button.ButtonText:SetPoint("CENTER", 13, 0);
            button.Count:Hide();
            tex = info[3];
            if tex == 1 then
                tex = 134400;
            end
            button.texID = tex;
            button.Icon:SetTexture(tex);
            button.Icon:SetTexCoord(0.065, 0.945, 0.065, 0.935);

            button:SetScript("OnClick", EntryButton_OnClick);
            button:SetScript("OnEnter", EnrtyButton_OnEnter);
            button:SetScript("OnLeave", HideHighlightAndClearID);

            totalEntry = totalEntry + 1;
            totalButton = totalButton + 1;
        end
    end

    ScrollChild.numEffectiveButtons = totalButton - 1;
    ScrollChild.buttons = totalFrames;
    ScrollChild.parentButtons = parentButtons;
end

local function CategoryButton_OnClick(self)
    CreateEntryButtonFrames(self.index);
    ListFrame.Header.Tab2Label:SetText(self:GetText());
    After(0, function()
        UpdateScrollRange();
        GoToTab(2);  
    end);
end


local function SavedEntryButton_OnEnter(self)
    ShowHighlight(self);
    if not self.visualID then return; end;
    UpdatePreview(self.visualID);

    --Relocate edit buttons (rename, delete)
    if MyFavoriteEditFrame.EditBox:HasFocus() then
        return;
    end
    MyFavoriteEditFrame.parent = self;
    MyFavoriteEditFrame:SetParent(self);
    MyFavoriteEditFrame:SetFrameLevel(self:GetFrameLevel());
    MyFavoriteEditFrame:SetPoint("RIGHT", self, "RIGHT", -4, 0);
    MyFavoriteEditFrame:Show();
end

local function SavedEntryButton_OnLeave(self)
    HideHighlightAndClearID(self);
    if not self:IsMouseOver() and not MyFavoriteEditFrame.EditBox:HasFocus() then
        MyFavoriteEditFrame:Hide();
    end
end

local function SavedEntryButton_OnClick(self, button)
    local model = Narci.ActiveModel;
    if not model then return; end;
    if button == "LeftButton" then
        model:ApplySpellVisualKit(self.visualID, true);
    elseif button == "RightButton" then
        SmoothInsert(self.visualID, self.texID, self:GetText());
    end
end
----------------------------------------------------------------

local function UpdateScrollRange_Generic(scrollFrame)
    local ScrollFrame = scrollFrame;
    local ScrollChild = ScrollFrame.ScrollChild;
    local TotalButton = ScrollChild.numEffectiveButtons;

    local buttonHeight = 16;
    local ButtonPerPage = 8;
    local TotalHeight = TotalButton * buttonHeight;
    local MaxScroll = max(0, TotalHeight - ButtonPerPage * buttonHeight);
    ScrollFrame.range = MaxScroll;
    ScrollFrame.scrollBar:SetMinMaxValues(0, MaxScroll);
    UpdateInnerShadowStates(ScrollFrame.scrollBar, MaxScroll, false);
end

local function CreateMyFavorites()
    ListFrame.Header.Tab3Label:SetText("My Favorites");
    local ScrollFrame = ListFrame.MyFavorites;
    local ScrollChild = ScrollFrame.ScrollChild;
    local scrollBar = ScrollFrame.scrollBar;
    scrollBar:SetValue(0);
    scrollBar.BottomShadow:SetAlpha(0);
    scrollBar.TopShadow:SetAlpha(0);
    local button;
    local buttons = ScrollChild.buttons or {};
    local List = FavoriteSpellVisualKitIDs;
    local totalButton = 1;
    local tex;

    if buttons then
        for i = 1, #buttons do
            buttons[i]:Hide();
        end
    end

    for k, v in pairs(List) do
        local i = totalButton;
        button = buttons[i];
        if not button then
            button = CreateFrame("Button", nil, ScrollChild, "Narci_SavedSpellVisualButtonTemplate");
            tinsert(buttons, button);
        else
            button:ClearAllPoints();
            button:SetParent(ScrollChild);
        end

        if i == 1 then
            button:SetPoint("TOP", ScrollChild, "TOP", 0, -16);
        else
            button:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, 0);
        end

        button:Show();
        button:Enable();
        button:SetText(v[1]);
        button.text = v[1];
        button.ButtonText:SetJustifyH("LEFT");
        button.ButtonText:SetPoint("CENTER", 13, 0);
        tex = v[2] or 134400;
        button.Icon:SetTexture(tex);
        button.Icon:SetTexCoord(0.065, 0.945, 0.065, 0.935);
        button.texID = tex;
        button.visualID = k;
        button.ToBeDeleted = false;

        button:SetPushedTextOffset(1, -0.6);
        button:SetScript("OnClick", SavedEntryButton_OnClick);
        button:SetScript("OnEnter", SavedEntryButton_OnEnter);
        button:SetScript("OnLeave", SavedEntryButton_OnLeave);

        totalButton = totalButton + 1;
    end

    ScrollChild.numEffectiveButtons = totalButton - 1;
    ScrollChild.buttons = buttons;

    UpdateScrollRange_Generic(ScrollFrame);
    ScrollFrame.EditFrame:Hide();
end

local function GoToMyFavorites()
    CreateMyFavorites();
    After(0, function()
        GoToTab(3);  
    end);
end

local function CountFavorites()
    local sum = 0;
    if not NarcissusDB or not NarcissusDB.Favorites or not NarcissusDB.Favorites.FavoriteSpellVisualKitIDs then
        return 0
    end
    local list = NarcissusDB.Favorites.FavoriteSpellVisualKitIDs;
    for k, v in pairs(list) do
        sum = sum + 1;
    end 
    return sum;
end

local MyCategoryButton;

local function UpdateCategoryButtons()
    local frame = ListFrame.Category;
    if not frame.CategoryButtons then
        frame.CategoryButtons = {};
    end
    local button;
    local buttons = frame.CategoryButtons;
    local totalPresets = #SpellVisualList + 1;  --The last one is reserved for My Favorites
    for i = 1, totalPresets do
        button = buttons[i];
        if not button then
            button = CreateFrame("Button", nil, frame, "Narci_SpellVisualCategoryButtonTemplate");
            buttons[i] = button;
        end
        if i == 1 then
            button:SetPoint("TOP", frame, "TOP", 0, -16);
        else
            button:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, 0);
        end
        button.index = i;
        if i == totalPresets then
            button:SetText("My Favorites");
            local numFavorites = CountFavorites();
            button.Count:SetText(numFavorites);
            button:SetScript("OnClick", GoToMyFavorites);
            MyCategoryButton = button;
        else
            button:SetText(SpellVisualList[i]["name"]);
            button.Count:SetText( CountLength( SpellVisualList[i] ) );
            button:SetScript("OnClick", CategoryButton_OnClick);
        end
        button:Show();
    end

    for i = totalPresets + 1, #buttons do
        buttons[i]:Hide();
    end
end

function NarciSpellVisualBrowser:SelectPack(index)
    local packName;
    SpellVisualList, packName = self:GetPack(index);
    UpdateCategoryButtons();
    After(0, function()
        HomeButton:Click();
    end)
    return packName
end

function NarciSpellVisualBrowser:SelectFirstEntry()
    --for tutorial
    ListFrame.Category.CategoryButtons[1]:Click();
    After(0.65, function()
        if ListFrame.ScrollFrame.ScrollChild.buttons[1] then
            ListFrame.ScrollFrame.ScrollChild.buttons[1]:Click();
        end
    end);
end
-----------------------------------------------------------------------
--History Tab

local function HistoryButton_OnClick(self)
    local id = self:GetID();
    local buttons = self:GetParent().buttons;
    local button;
    for i = 1, #buttons do
        button = buttons[i];
        button.Border:SetTexCoord(0, 0.25, 0, 1);
        if i ~= id then
            button.selected = false;
            button.Icon:SetAlpha(0.6);
        end
    end

    local DeleteIcon = self:GetParent():GetParent().DeleteButton.Icon;
    self.selected = not self.selected;
    if self.selected then
        self.Border:SetTexCoord(0.25, 0.5, 0, 1);
        SelectedVisualIndex = id;
        DeleteIcon:SetDesaturated(false);
    else
        self.Border:SetTexCoord(0, 0.25, 0, 1);
        SelectedVisualIndex = nil;
        DeleteIcon:SetDesaturated(true);
    end
end

local function HistoryButton_OnEnter(self)
    self.Icon:Show();
    self.Icon:SetAlpha(1);
    local tooltip = BrowserFrame.HistoryTooltip;
    local formatedID = "|cff999999"..self.visualID.."|r  ";
    tooltip:SetPoint("BOTTOM", self, "TOP", 0, 0);
    if self.name and self.name ~= "" then
        tooltip.Label:SetText(formatedID.. self.name);
        PreviewTimer.pendingID = self.visualID;
        UpdatePreview(self.visualID);
    else
        tooltip.Label:SetText(formatedID.. "Custom");
    end
    tooltip:Show();
end

local function HistoryButton_OnLeave(self)
    BrowserFrame.HistoryTooltip:Hide();
    if self.selected then return; end;
    FadeFrame(self.Icon, 0.2, 0.6);
end

local function CreateHistoryButtonFrame(self)
    local NumVisibleButtons = NUM_MAX_HISTORY;
    local offsetX = 24;
    local offsetY = 18;
    local button;
    local buttons = {};
    for i = 1, NumVisibleButtons + 1 do
        button = CreateFrame("Button", nil, self, "Narci_HistoryButtonTemplate");
        if i == 1 then
            button:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 24);
        else
            button:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offsetX * (i - 1) , 24);
        end
        
        button.Icon:SetSize(14, 14);
        button.Icon:SetAlpha(0.6);
        button.ID:SetText(i);
        button:SetID(i);
        button:SetScript("OnClick", HistoryButton_OnClick);
        button:SetScript("OnEnter", HistoryButton_OnEnter);
        button:SetScript("OnLeave", HistoryButton_OnLeave);
        tinsert(buttons, button);
    end
    self.buttons = buttons;
    self.numEffectiveButtons = 0;
    self.offsetY = offsetY;
end


-----------------------------------------------------------------------
--Edit box frame
local function EditBox_OnEnterPressed(self)
    self:ClearFocus();
	self.Highlight:Hide();
	local id = math.min(self:GetNumber(), VISUAL_ID_MAX);

    local model = Narci.ActiveModel;
    if not model then return; end;

    model:ApplySpellVisualKit(id, true);
end

local function EditBox_OnMouseWheel(self, delta)
	local id = self:GetNumber();

	if delta < 0 and id < VISUAL_ID_MAX then
		id = id + 1;
	elseif delta > 0 and id > 0 then
        id = id - 1;
    else
        return;
	end

    local model = Narci.ActiveModel;
    if not model then return; end;

    self:SetNumber(id)
    model:ApplySpellVisualKit(id, true);
end

local function EditBox_OnTextChanged(self)
    --Update Favorite button
    local Star = self:GetParent().FavoriteButton;
    Star.IsFirstClick = true;
    local id = self:GetNumber();
    if IsFavorite[id] then
        Star.Icon:SetAlpha(1);
        Star.Icon:SetTexCoord(0.25, 0.5, 0, 1);
        Star.IsFav = true;
    else
        Star.Icon:SetAlpha(0.6);
        Star.Icon:SetTexCoord(0, 0.25, 0, 1);
        Star.IsFav = false;
    end
    ----
    self.Timer:Stop();
    Narci_SpellVisualBrowser_PopUpFrame:Hide();
end

local function ReApplySpellVisual(model)
    model = model or Narci.ActiveModel;
    if not model then return; end;
    local visualID;
    local AppliedVisuals = model.AppliedVisuals;
    for i = 1, #AppliedVisuals do
        visualID = AppliedVisuals[i];
        if visualID then
            model:ApplySpellVisualKit(visualID, false);
        end
    end
end

local function ResetModel()
    local model = Narci.ActiveModel;
    if not model then return; end;

    local posX, posY, posZ = model:GetPosition();
    local camX, camY, camZ = model:GetCameraPosition();
    local _, _, dirX, dirY, dirZ, _, ambR, ambG, ambB, _, dirR, dirG, dirB = TransitionAPI.GetModelLight(model);
    local distance = model.cameraDistance;
    local animationID = model.animationID;
    local isPaused = model.isPaused;
    --[[
    if model.isPlayer then
        if model.hasRaceChanged then
            model:SetCustomRace();
        end
    end
    --]]

    model.isCameraDirty = false;

    if model.creatureID then
        model:SetCreature(model.creatureID);
    elseif model.displayID then
        model:SetDisplayInfo(model.displayID);
    else
        if model.unit and model.unit == "player" then
            TransitionAPI.SetModelByUnit(model, "player");
        else
            model:RefreshUnit();
        end
    end

    After(0, function()
        model:MakeCurrentCameraCustom();
        model:SetPosition(posX, posY, posZ);
        TransitionAPI.SetCameraTarget(model, 0, 0, 0.8);
        TransitionAPI.SetCameraPosition(model, camX, camY, camZ);
        model.cameraDistance = distance;
        TransitionAPI.SetModelLight(model, true, false, dirX, dirY, dirZ, 1, ambR, ambG, ambB, 1, dirR, dirG, dirB);
        if isPaused then
            --model:Freeze(animationID);
            NarciModelControl_AnimationSlider:SetValue(model.freezedFrame or 0, true)
        else
            model:PlayAnimation(animationID);
        end

        After(0, function()
            ReApplySpellVisual(model);
            model:ReEquipWeapons();

            if model.isVirtual then
                model:SetModelAlpha(0);
            end
        end)
    end);
end

NarciPhotoModeAPI.ResetModel = ResetModel;

local function ResetButton_OnClick(self)
    ResetModel();
end

local function DeleteButton_OnClick(self)
    self.Icon:SetDesaturated(true);
    NarciTooltip:HideTooltip();
    if not SelectedVisualIndex then return; end;

    local model = Narci.ActiveModel;
    if not model then
        return;
    end

    local AppliedVisuals = model.AppliedVisuals;
    SmoothRemove(SelectedVisualIndex);
    if AppliedVisuals[SelectedVisualIndex] then
        local NewHistory = {};
        local index = 1;
        for i = 1, NUM_VISIBLE_BUTTONS do
            if index == SelectedVisualIndex then
                index = index + 1;
            end
            NewHistory[i] = AppliedVisuals[index];
            index = index + 1;
        end
        wipe(model.AppliedVisuals);
        model.AppliedVisuals = NewHistory;
    else
        return;
    end
    HistoryButton_ResetSelection();
    --PrintTable(Narci.ActiveModel.AppliedVisuals);
    ResetModel();
end

local function DeleteButton_OnEnter(self)
    self.Highlight:Show();
    NarciTooltip:NewText(L["Remove Visual Tooltip"], nil, nil, FREQUENTLY_USED_BUTTON_TOOLTIP_DELAY);
end

local function ButtonWithTooltip_OnLeave(self)
    self.Highlight:Hide();
    NarciTooltip:HideTooltip();
end

local function HistoryButton_RemoveAll()
    SelectedVisualIndex = nil;
    NUM_VISIBLE_BUTTONS = 0;
    local buttons = HistoryButtonFrame.buttons;
    local button;
    for i = 1, #buttons do
        button  = buttons[i];
        button.Border:SetTexCoord(0, 0.25, 0, 1);
        After( (i - 1)/10, function()
            FadeFrame(buttons[i], 0.25, 0);
        end);
    end  
end

local function DeleteButton_OnLongClick(self)
    local model = Narci.ActiveModel;
    if model then
        HistoryButton_RemoveAll();
        wipe(model.AppliedVisuals);
        --PrintTable(model.AppliedVisuals);
        ResetModel();
        self:GetParent().FadeOut:Play();
        self:GetParent():GetParent().Icon:SetSize(18, 18);
    else
        local AlertFrame = Narci_AlertFrame_Autohide;
        AlertFrame:SetAnchor(self, -24, true);
        AlertFrame:AddMessage("No active model", true);
    end
end

local function PlusButton_OnClick(self, button)
    local EditBox = self:GetParent().EditBox;
	EditBox:ClearFocus();
	local id = EditBox:GetNumber();
	if button == "LeftButton" and id < VISUAL_ID_MAX then
		id = id + 1;
	elseif button == "RightButton" and id > 0 then
		id = id - 1;
	end
    EditBox:SetNumber(id);

    local model = Narci.ActiveModel;
    if model then
        model:ApplySpellVisualKit(id, true)
    end
end

local function ApplyButton_OnClick(self, button)
    local EditBox = self:GetParent().EditBox;
    EditBox:ClearFocus();
    EditBox.Highlight:Hide();
	local id = EditBox:GetNumber();
    id = tonumber(id);

    local name, icon, animationID = GetSpellVisualKitInfo(id);
    SmoothInsert(id, icon, name);
end

local function FavoriteButton_OnEnter(self)
    self.Icon:SetAlpha(1);
    self.Highlight:Show();
    if not self:GetParent().PopUpFrame:IsShown() then
        if self.IsFav then
            NarciTooltip:NewText(L["Favorites Remove"], nil, nil, FREQUENTLY_USED_BUTTON_TOOLTIP_DELAY);
        else
            NarciTooltip:NewText(L["Favorites Add"], nil, nil, FREQUENTLY_USED_BUTTON_TOOLTIP_DELAY);
        end
    end
end

local function FavoriteButton_OnLeave(self)
    NarciTooltip:HideTooltip();
    self.Highlight:Hide();
    if not self.IsFav then
        self.Icon:SetAlpha(0.6);
    end
end

local function AddToFavorites(SpellVisualKitID, CustomName, CustomAnimationID)
    if not SpellVisualKitID then return; end;
    local name, icon, animationID = GetSpellVisualKitInfo(SpellVisualKitID);
    local ShowPreview;
    if name ~= "" then
        ShowPreview = true;
    else
        ShowPreview = false;
        icon = nil;
    end
    name = CustomName or name;
    animationID = CustomAnimationID or animationID;
    FavoriteSpellVisualKitIDs[SpellVisualKitID] = {name, icon, animationID, ShowPreview};
    IsFavorite[SpellVisualKitID] = true;

    MyCategoryButton.Count:SetText( tonumber( MyCategoryButton.Count:GetText() ) + 1);
    MyCategoryButton.Differential:SetText("|cff7cc576+1");     --Green 7cc576
    MyCategoryButton.Differential.FadeText:Play(); 
    
    After(0, CreateMyFavorites);

    PlaySound(39672, "SFX");
end

local function RenameFavorite(SpellVisualKitID, newName)
    if SpellVisualKitID then
        local entry = NarcissusDB.Favorites.FavoriteSpellVisualKitIDs[SpellVisualKitID];
        if entry then
            entry[1] = newName;
            return true;
        else
            return false;
        end
    else
        return false;
    end
end

local function RemoveFromFavortes(IDsToBeDeleted)
    if not IDsToBeDeleted then return; end;

    local ShouldBeDeleted = {};
    local IDType = type(IDsToBeDeleted);
    if IDType == "number" then
        ShouldBeDeleted[ IDsToBeDeleted ] = true;
    elseif IDType == "table" then
        for i = 1, #IDsToBeDeleted do
            ShouldBeDeleted[ IDsToBeDeleted[i] ] = true;
        end
    end

    local currentID = BrowserFrame.ExpandableFrames.EditBox:GetNumber();

    local newList = {};
    local oldList = FavoriteSpellVisualKitIDs;
    local sum = 0;
    for id, v in pairs(oldList) do
        if not ShouldBeDeleted[id] then
            newList[id] = v;
            sum = sum + 1;
        else
            IsFavorite[id] = false;

            if id == currentID then
                --Update favorite button
                local Star = BrowserFrame.ExpandableFrames.FavoriteButton;
                Star.Icon:SetTexCoord(0, 0.25, 0, 1);
                Star.Icon:SetAlpha(0.6);
                Star.IsFav= false;
                Star.IsFirstClick = true;
            end
        end
    end
    
    wipe(NarcissusDB.Favorites.FavoriteSpellVisualKitIDs);
    NarcissusDB.Favorites.FavoriteSpellVisualKitIDs = newList;
    FavoriteSpellVisualKitIDs = NarcissusDB.Favorites.FavoriteSpellVisualKitIDs;
    return sum;
end

local function StartRemovingFavorites()
    local MyFavorites = ListFrame.MyFavorites;
    local EditFrame = MyFavorites.EditFrame;
    EditFrame:Hide();
    EditFrame.DeleteButton.numToBeDeleted = 0;
    
    local numButtons = MyFavorites.ScrollChild.numEffectiveButtons;
    local buttons = MyFavorites.ScrollChild.buttons;
    if not buttons or numButtons == 0 then return false; end

    local IDsToBeDeleted = {};
    local NumDeleted
    local button;
    for i = 1, numButtons do
        button = buttons[i];
        if button.ToBeDeleted then
            tinsert(IDsToBeDeleted, button.visualID);
        end
    end
    
    local numAfterDeleted = RemoveFromFavortes(IDsToBeDeleted);
    --print(#IDsToBeDeleted.." entries have been removed")
    return #IDsToBeDeleted, numAfterDeleted;
end

local function FavoritePopUp_Confirm()
    local PopUp = Narci_SpellVisualBrowser_PopUpFrame;
    local EditBox = PopUp.HiddenFrame.EditBox;
    local ID = tonumber(BrowserFrame.ExpandableFrames.EditBox:GetText());
    AddToFavorites(ID, EditBox:GetText());
    EditBox:ClearFocus();
    FadeFrame(PopUp, 0.25, 0);

    local Star = PopUp:GetParent().FavoriteButton;
    Star.Icon:SetTexCoord(0.25, 0.5, 0, 1);
    Star.Icon:SetAlpha(1);
    Star.IsFav= true;
    Star.IsFirstClick = true;

    After(0, function()
        local sum = CountFavorites();
        MyCategoryButton.Count:SetText(sum);
    end)
end

local function FavoritePopUp_Cancel()
    local PopUp = Narci_SpellVisualBrowser_PopUpFrame;
    FadeFrame(PopUp, 0.25, 0);

    local Star = PopUp:GetParent().FavoriteButton;
    Star.Icon:SetTexCoord(0, 0.25, 0, 1);
    Star.Icon:SetAlpha(0.6);
    Star.IsFav= false;
    Star.IsFirstClick = true;
end

local function FavoriteButton_OnClick(self)
    NarciTooltip:HideTooltip();
    local PopUp = self:GetParent().PopUpFrame;
    if not self.IsFav then
        self.Icon:SetTexCoord(0.25, 0.5, 0, 1);
        if self.IsFirstClick then
            self.IsFirstClick = false;
            BrowserFrame.ArtFrame.Bling.animIn:Play();
            local index = MyCategoryButton.Count:GetText() + 1;
            PopUp.HiddenFrame.EditBox:SetText("Custom Visual " .. index);
            FadeFrame(PopUp, 0.15, 1);
        else
            FavoritePopUp_Confirm();
        end
    else
        local ID = self:GetParent().EditBox:GetNumber();
        local numLeft = RemoveFromFavortes(ID);
        if numLeft then
            self.IsFav = false;
            self.Icon:SetTexCoord(0, 0.25, 0, 1);
            self.IsFirstClick = true;
            MyCategoryButton.Count:SetText(numLeft);
            MyCategoryButton.Differential:SetText("|cffff5050-1");  --minus 1
            MyCategoryButton.Differential.FadeText:Play();
            After(0, CreateMyFavorites);
        end
    end
end

local function UpdateDeleteInfo(numToBeDeleted)
    local TextFormat;
    if numToBeDeleted > 1 then
        TextFormat = L["Delete Entry Plural"];          --plural
    else
        TextFormat = L["Delete Entry Singular"];        --singular
    end
    ListFrame.Header.Tab3Label:SetText( string.format(TextFormat, numToBeDeleted) );
end

local function EditFrame_EditBox_Confirm()
    local EntryButton = MyFavoriteEditFrame.parent;
    local NewText = MyFavoriteEditFrame.EditBox:GetText();
    MyFavoriteEditFrame.EditBox.anyChange = nil;
    MyFavoriteEditFrame.EditBox:SetText("");
    MyFavoriteEditFrame.EditBox:Hide();
    EntryButton:SetText(NewText);

    if RenameFavorite(EntryButton.visualID, NewText) then
        --Rename succeeded
        EntryButton.Green.animIn:Stop();
        EntryButton.Green.animIn:Play();
    end

    NarciTooltip:HideTooltip();
end

local function EditFrame_EditBox_Cancel(self)
    self.anyChange = nil;
    self:SetText("");
    self:Hide();
    NarciTooltip:HideTooltip();
end

local function EditFrame_EditBox_OnTextChanged(self, isUserInput)
    if isUserInput then
        self.anyChange = true;
    end
end

local function EditFrame_EditBox_OnEditFocusLost(self)
    self:Hide();
    Narci.UserIsInputing = false;
    self:HighlightText(0,0);
    if self.anyChange then
        self.anyChange = nil;
        EditFrame_EditBox_Confirm();
    end
    MyFavoriteEditFrame.EditBoxBackground:Hide();
end

local function EditFrame_DeleteButton_OnClick(self)
    local EntryButton = self:GetParent().parent;
    if not EntryButton then return; end;

    EntryButton.ToBeDeleted = not EntryButton.ToBeDeleted;
    local EditBox = self:GetParent().EditBox;
    EditFrame_EditBox_Cancel(EditBox);

    if EntryButton.ToBeDeleted then
        self.numToBeDeleted = self.numToBeDeleted or 0;
        self.numToBeDeleted = self.numToBeDeleted + 1;
        EntryButton:Disable();
    else
        self.numToBeDeleted = self.numToBeDeleted - 1;
        EntryButton:Enable();
    end

    UpdateDeleteInfo(self.numToBeDeleted);
end


local function EditFrame_RenameButton_OnClick(self)
    local EditBox = MyFavoriteEditFrame.EditBox;
    local EntryButton = MyFavoriteEditFrame.parent;
    self.IsOn = not self.IsOn;
    if self.IsOn then
        MyFavoriteEditFrame.EditBoxBackground:Show();

        local OldText = EntryButton:GetText();
        EditBox:Show();
        EditBox:SetText(OldText or "");
        EditBox:SetFocus();
        EditBox:HighlightText();

        if EntryButton.ToBeDeleted then
            --Rename a entry that is about to be deleted will cancel deletion
            EntryButton.ToBeDeleted = false;
            EntryButton:Enable();

            --Update delete info
            local DeleteButton = MyFavoriteEditFrame.DeleteButton;
            DeleteButton.numToBeDeleted = DeleteButton.numToBeDeleted or 1;
            DeleteButton.numToBeDeleted = DeleteButton.numToBeDeleted - 1;
            UpdateDeleteInfo(DeleteButton.numToBeDeleted);
        end
    else
        EditFrame_EditBox_Cancel(EditBox);
    end
end


local function QuickFavoriteButton_OnClick(self)
    self.isFav = not self.isFav;
    if self.isFav then
        AddToFavorites(self.visualID);
    else
        RemoveFromFavortes(self.visualID);
    end
    self:PlayVisual();
end

local function HomeButton_OnClick(self)
    GoToTab(1);
    FadeFrame(self, 0.2, 0);
    if self.CurrentTabIndex == 3 then
        --If you just go back from My Favorites, start removing selected favorites
        local numDeleted, numLeft = StartRemovingFavorites();
        if numDeleted and numDeleted ~= 0 then
            MyCategoryButton.Count:SetText(numLeft);
            MyCategoryButton.Differential:SetText("|cffff5050-"..numDeleted);     --Red ff5050 Green 7cc576
            MyCategoryButton.Differential.FadeText:Play();      
        end
    end
    PreviewFrame:ResetCover();
end

local function ScrollFrame_OnLoad(self)
    local buttonHeight = 16;
    local TotalTab = 12;
    local TotalHeight = floor(TotalTab * buttonHeight + 0.5);
    local MaxScroll = floor((TotalTab - 7) * buttonHeight + 0.5);
    self.scrollBar:SetMinMaxValues(0, MaxScroll)
    self.scrollBar:SetValueStep(0.001);
    self.buttonHeight = TotalHeight;
    self.range = MaxScroll;
    self.scrollBar:SetScript("OnValueChanged", function(self, value)
        --HybridScrollFrame_SetOffset(self:GetParent(), value)
        self:GetParent():SetVerticalScroll(value);
        UpdateInnerShadowStates(self, nil, false);
    end)
    NarciAPI_SmoothScroll_Initialization(self, nil, nil, 3/(TotalTab), 0.14);
end

local function Browser_OnShow(self)
    AnimationContariner:Show();
end

local function Browser_OnHide(self)
    AnimationContariner:Hide();
    clickCounter.leftButton = 0;
    clickCounter.tooltipShown = nil;
end

local function LoadFavorites()
    if not NarcissusDB then
        print("Cannot find NarcissusDB");
        return 0;
    end
    NarcissusDB.Favorites = NarcissusDB.Favorites or {};
    NarcissusDB.Favorites.FavoriteSpellVisualKitIDs = NarcissusDB.Favorites.FavoriteSpellVisualKitIDs or {};
    FavoriteSpellVisualKitIDs = NarcissusDB.Favorites.FavoriteSpellVisualKitIDs;

    local sum = 0;
    local name, icon;
    for k, v in pairs(FavoriteSpellVisualKitIDs) do
        name, icon = GetSpellVisualKitInfo(k);
        if name == "" then      --no match
            v[4] = false;       --no preview
        else
            v[4] = true;        --show preview
        end
        v[2] = icon;
        sum = sum + 1;
        IsFavorite[k] = true;
    end

    return sum;
end

--[[
    function WipeFavorites()
    wipe(NarcissusDB.Favorites);
end
--]]

local function SetAutoPlayButtonScript(self)
    local function SetFormat(self)
        if self.IsOn then
            self.Label:SetPoint("CENTER", self, "CENTER", 6, 0);
            self:SetText(self.EnabledText);
        else
            self.Label:SetPoint("CENTER", self, "CENTER", 0, 0);
            self:SetText(self.DisabledText);
        end
    end

    local function OnClick(self)
        self.IsOn = not self.IsOn;
        NarcissusDB.AutoPlayAnimation = self.IsOn;
        self.Tick:SetShown(self.IsOn);
        self.Label:ClearAllPoints();
        SetFormat(self);
    end
    local state = NarcissusDB.AutoPlayAnimation;
    self.IsOn = state;
    self.Tick:SetShown(state);
    self.Label:ClearAllPoints();
    SetFormat(self);
    self:SetScript("OnClick", OnClick);
end

local initialize = CreateFrame("Frame");
initialize:RegisterEvent("VARIABLES_LOADED");
initialize:SetScript("OnEvent", function(self)
    self:UnregisterEvent("VARIABLES_LOADED");
    After(4.5, function()
        SetAutoPlayButtonScript(SuggestionFrame.AutoPlay);
        local numFavorites = LoadFavorites();
        MyCategoryButton.Count:SetText(numFavorites);
    end);
end);

function Narci_SpellVisualBrowser_OnLoad(self)
    self:SetScript("OnShow", Browser_OnShow);
    self:SetScript("OnHide", Browser_OnHide);
    self:SetPoint("BOTTOMRIGHT", Narci_AnimationIDFrame, "BOTTOMLEFT", BROWSER_ANCHOR_OFFSET_COLLAPSED_X, BROWSER_ANCHOR_OFFSET_Y);
    BrowserFrame = self;
    local ExpandableFrames = self.ExpandableFrames;
    ListFrame = self.ExpandableFrames.ListFrame.Container;
    SuggestionFrame = self.ExpandableFrames.SuggestionFrame;
    HistoryFrame = self.ExpandableFrames.HistoryFrame;
    Tab1 = ListFrame.Category;
    ListScrollBar = ListFrame.ScrollFrame.scrollBar;
    

    ExpandableFrames.EditBox:SetScript("OnMouseWheel", EditBox_OnMouseWheel);
    ExpandableFrames.EditBox:SetScript("OnEnterPressed", EditBox_OnEnterPressed);
    ExpandableFrames.EditBox:SetScript("OnTextChanged", EditBox_OnTextChanged);
    ExpandableFrames.PlusButton:SetScript("OnClick", PlusButton_OnClick);
    ExpandableFrames.ApplyButton:SetScript("OnClick", ApplyButton_OnClick);
    ExpandableFrames.ResetButton:SetScript("OnClick", ResetButton_OnClick);
    local FavoriteButton = ExpandableFrames.FavoriteButton;
    FavoriteButton:SetScript("OnEnter", FavoriteButton_OnEnter);
    FavoriteButton:SetScript("OnLeave", FavoriteButton_OnLeave);
    FavoriteButton:SetScript("OnClick", FavoriteButton_OnClick);
    local FavoritePopUp = ExpandableFrames.PopUpFrame.HiddenFrame;
    FavoritePopUp.Header:SetText(L["New Favorite"]);
    FavoritePopUp.ConfirmButton:SetScript("OnClick", FavoritePopUp_Confirm);
    FavoritePopUp.CancelButton:SetScript("OnClick", FavoritePopUp_Cancel);
    FavoritePopUp.EditBox:SetScript("OnEscapePressed", FavoritePopUp_Cancel);
    FavoritePopUp.EditBox:SetScript("OnEnterPressed", FavoritePopUp_Confirm);

    HomeButton = ListFrame.Header.HomeButton;
    HomeButton:SetScript("OnClick", HomeButton_OnClick);
    HomeButton.tooltipDescription = L["Return"];

    HistoryFrame.DeleteButton:SetScript("OnClick", DeleteButton_OnClick);
    HistoryFrame.DeleteButton:SetScript("OnEnter", DeleteButton_OnEnter);
    HistoryFrame.DeleteButton:SetScript("OnLeave", ButtonWithTooltip_OnLeave);
    HistoryFrame.DeleteButton.Fill.Timer:SetScript("OnFinished", DeleteButton_OnLongClick);
    HistoryButtonFrame = HistoryFrame.HistoryButtonFrame;

    SuggestionFrame.IDButton:SetScript("OnClick", SuggestedID_OnClick);

    UpdateCategoryButtons();
    CreateHistoryButtonFrame(HistoryButtonFrame);
    CreateEntryButtonFrames(1);

    ScrollFrame_OnLoad(ListFrame.ScrollFrame);
    ScrollFrame_OnLoad(ListFrame.MyFavorites);
    
    QuickFavoriteButton = ListFrame.ScrollFrame.QuickFavoriteButton;
    QuickFavoriteButton:SetScript("OnClick", QuickFavoriteButton_OnClick);

    MyFavoriteEditFrame = ListFrame.MyFavorites.EditFrame;
    MyFavoriteEditFrame.DeleteButton:SetScript("OnClick", EditFrame_DeleteButton_OnClick);
    MyFavoriteEditFrame.DeleteButton.numToBeDeleted = 0;
    MyFavoriteEditFrame.RenameButton:SetScript("OnClick", EditFrame_RenameButton_OnClick);
    MyFavoriteEditFrame.EditBox:SetScript("OnEnterPressed", EditFrame_EditBox_Confirm);
    MyFavoriteEditFrame.EditBox:SetScript("OnEscapePressed", EditFrame_EditBox_Cancel);
    MyFavoriteEditFrame.EditBox:SetScript("OnEditFocusLost", EditFrame_EditBox_OnEditFocusLost);
    MyFavoriteEditFrame.EditBox:SetScript("OnTextChanged", EditFrame_EditBox_OnTextChanged);
end


-------------------------------------------------
NarciSpellVisualBrowserPreviewFrameMixin = {};

function NarciSpellVisualBrowserPreviewFrameMixin:OnLoad()
    PreviewFrame = self;
    self.packName = "Standard";
    self.isStandardPack = true;
    self.tooltipDescription = L["Change Pack"];
end

function NarciSpellVisualBrowserPreviewFrameMixin:OnClick()
    self.isStandardPack = not self.isStandardPack;
    local packID;
    if self.isStandardPack then
        packID = 0;
    else
        packID = 1;
    end
    self.packName = NarciSpellVisualBrowser:SelectPack(packID);
    --]]
end

function NarciSpellVisualBrowserPreviewFrameMixin:ResetCover()
    PreviewFrame.BottomImage:SetTexture("Interface\\AddOns\\Narcissus\\Art\\SpellVisualPreviews\\Pack-".. self.packName);
    After(0, function()
        PreviewFrame.TopImage.FadeOut:Play();
    end);
end

function NarciSpellVisualBrowserPreviewFrameMixin:OnHide()
    self:StopAnimating();
end

function NarciSpellVisualBrowserPreviewFrameMixin:OnEnter()
    NarciTooltip:ShowButtonTooltip(self);
end

function NarciSpellVisualBrowserPreviewFrameMixin:OnLeave()
    NarciTooltip:HideTooltip();
end

--[[
function GetReAnchor()
    ModelSettings:StartMoving();
    ModelSettings:StopMovingOrSizing();
    local point, _, relativePoint, offsetX, offsetY = ModelSettings:GetPoint();
    print(point, relativePoint, offsetX, offsetY );

    local oldCenterX = ModelSettings:GetCenter();
    local width = ModelSettings:GetWidth()/2;
    local screenWidth = WorldFrame:GetWidth();
    local scale = ModelSettings:GetEffectiveScale();
    print("1 ", oldCenterX + width - screenWidth)
    print("2 ",oldCenterX + width - screenWidth/scale)
    print("3 ",(oldCenterX + width)*scale - screenWidth)
end

function SetSpellVisualBrowserOffset(offsetX)
    BrowserFrame:SetPoint("BOTTOMRIGHT", Narci_AnimationIDFrame, "BOTTOMLEFT", offsetX, BROWSER_ANCHOR_OFFSET_Y);
end
--]]