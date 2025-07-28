local _, addon = ...

local TransitionAPI = addon.TransitionAPI;

------------------------------------------------------------------------
local VISUAL_ID_MAX = 220000;
local TAB_WIDTH = 116;
local NUM_MAX_HISTORY = 5;
local BROWSER_ANCHOR_OFFSET_COLLAPSED_X = 146;
local BROWSER_ANCHOR_OFFSET_EXPANED_X = -28;
local BROWSER_ANCHOR_OFFSET_Y = -6;
------------------------------------------------------------------------

local Narci = Narci;
local L = Narci.L;
local FadeFrame = NarciFadeUI.Fade;
local After = C_Timer.After;
local tinsert = table.insert;

local BrowserFrame, ListFrame, EntryTab, PreviewFrame, HistoryFrame, Tab1, HistoryButtonFrame, QuickFavoriteButton, SuggestionFrame, HomeButton, MyFavoriteEditFrame, EditBoxFavoriteButton, VisualIDEditBox, EditorPopup, SearchBox;
local NUM_VISIBLE_BUTTONS = 0;

local NarciSpellVisualUtil = NarciSpellVisualUtil;
local SpellVisualList = NarciSpellVisualUtil.Catalogue;
local GetSpellVisualKitInfo = NarciSpellVisualUtil.GetSpellVisualKitInfo;
local IsSpellVisualLogged = NarciSpellVisualUtil.IsSpellVisualLogged;
local NarciTooltip = NarciTooltip;
local SelectedVisualIndex;

local FavUtil = {};

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

function NarciSpellVisualUtil:LoadHistory()
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
local AnimationContariner = CreateFrame("Frame");

local outSine = addon.EasingFunctions.outSine;
local inOutSine = addon.EasingFunctions.inOutSine;
local linear = addon.EasingFunctions.linear;


-------------------------------------------
--Toggle Spell Visual Brower frame
local ExpandAnim = CreateFrame("Frame");
ExpandAnim:Hide();
ExpandAnim.total = 0;
ExpandAnim.duration = 0.25;
ExpandAnim.baseOffsetX = -430;
ExpandAnim:SetScript("OnHide", function(self)
    self.total = 0;
end);
ExpandAnim.duration2 = 0.5;
local ModelSettings = Narci_ModelSettings;

ExpandAnim:SetScript("OnShow", function(self)
    self.StartHeight = BrowserFrame:GetHeight();
    _, self.xRelativeTo, _, self.fromX = BrowserFrame:GetPoint();
    _, self.yRelativeTo, _, _, self.fromY = BrowserFrame.ExpandableFrames:GetPoint();
    self.fromWidth = ModelSettings:GetWidth();
end);

local function Expand_OnUpdate(self, elapsed)
    self.total = self.total + elapsed;
    local newTotal  = self.total;
    local offsetX = outSine(newTotal, self.fromX, self.toX, self.duration);
    local width = outSine(newTotal, self.fromWidth, self.toWidth, self.duration);
	if newTotal >= self.duration then
        offsetX = self.toX;
        width = self.toWidth;
        local offsetY = outSine(newTotal - self.duration, self.fromY, self.EndY, 0.25);
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
    ModelSettings.ActorPanel:SetPoint("TOPLEFT", ModelSettings, "TOPLEFT", width + self.baseOffsetX, 0);
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
    ExpandAnim.toX = newOffsetX;       --BrowserFrame
    ExpandAnim.toWidth = newWidth;     --ModelSettings

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


local ScrollHistory = {};
do
    ScrollHistory.history = {};

    function ScrollHistory:SetActiveCategory(categoryIndex)
        if not self.history[categoryIndex] then
            self.history[categoryIndex] = {};
        end
        self.activeCategoryIndex = categoryIndex;
        self.activeHistory = self.history[categoryIndex];
    end

    function ScrollHistory:GetActiveCategoryIndex()
        return self.activeCategoryIndex
    end

    function ScrollHistory:IsHeaderExpanded(headerIndex)
        return self.activeHistory[headerIndex] == true
    end

    function ScrollHistory:ToggleHeaderExpanded(headerIndex)
        if self:IsHeaderExpanded(headerIndex) then
            self.activeHistory[headerIndex] = false;
        else
            self.activeHistory[headerIndex] = true;
        end
    end

    function ScrollHistory:SaveOffset()
        if self.activeHistory then
            self.activeHistory.lastOffset = EntryTab.ScrollView:GetOffset();
        end
    end

    function ScrollHistory:GetLastOffset()
        return self.activeHistory.lastOffset
    end

    function ScrollHistory:Reset()
        self.history = {};
        self.activeHistory = nil;
        self.activeCategoryIndex = nil;
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


local CURRENT_TAB_INDEX = 1;
local function GoToTab(index)
    if index == CURRENT_TAB_INDEX then return end;
    CURRENT_TAB_INDEX = index;

    SwipeAnim:Hide();

    if index == 1 then
        ScrollHistory:SaveOffset();
        SwipeAnim.endOffset = 0;
        PreviewFrame:Enable();
        FavUtil.sortedList = nil;
    else
        SwipeAnim.endOffset = -TAB_WIDTH;
        FadeFrame(HomeButton, 0.2, 1);
        PreviewFrame:Disable();
    end

    SearchBox:SetShown(index == 3);
    ListFrame.Header.Tab2Label:SetShown(index ~= 3);
    HomeButton:SetHitRectInsets(0, (index == 3 and -1) or -10, -1, 0);
    if EntryTab.ScrollView then
        EntryTab.ScrollView:SetAlwaysHideScrollBar(index == 2);
    end

    SwipeAnim:Show();

    --Guide
    if BrowserFrame.ShowGuide then
        BrowserFrame.Guide.TabListener:SetValue(3);
        BrowserFrame.ShowGuide = false;
    end
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
end

InsertAnim:SetScript("OnShow", function(self)
    local buttons = HistoryButtonFrame.buttons;
    local num = NUM_VISIBLE_BUTTONS;
    local NewButton = buttons[num];
    self.fromX = (num - 2) * 24;
    self.toX = (num - 1) * 24;
    self.fromY = HistoryButtonFrame.offsetY;
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
    local offsetX = inOutSine(self.total, self.fromX, self.toX, self.duration);
    local offsetY = outSine(self.total, self.fromY, 0, self.duration);

	if self.total >= self.duration then
        offsetX = self.toX;
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
    self.toX = self.fromX + 24;
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
    local offsetX = inOutSine(self.total, self.fromX, self.toX, self.duration);
	if self.total >= self.duration then
        alpha = 0;
        offsetX = self.toX;
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
    _, _, _, RemoveAnim.fromX = buttons[1]:GetPoint();
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


local clickCounter = {};
clickCounter.leftButton = 0;


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
        if self.visualID then
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
do  --FavUtil
    FavUtil.isFavorite = {};
    FavUtil.numFavs = 0;

    function FavUtil:Load()
        if not NarcissusDB then
            self.db = {};
            self.numFavs = 0;
            return 0
        end

        if not NarcissusDB.Favorites then
            NarcissusDB.Favorites = {};
        end

        if not NarcissusDB.Favorites.FavoriteSpellVisualKitIDs then
            NarcissusDB.Favorites.FavoriteSpellVisualKitIDs = {};
        end

        self.db = NarcissusDB.Favorites.FavoriteSpellVisualKitIDs;


        local total = 0;
        for visualID, info in pairs(self.db) do
            total = total + 1;
            self.isFavorite[visualID] = true;
        end

        self.numFavs = total;

        return total;
    end

    function FavUtil:IsFavorite(visualID)
        return self.isFavorite[visualID];
    end

    local function SortFunc_Name(a, b)
        if a[4] ~= b[4] then
            return a[4] < b[4]
        end

        return a[1] > b[1]
    end

    function FavUtil:GetSortedList()
        if self.sortedList then
            return self.sortedList
        end

        local n = 0;
        local tbl = {};
        local lower = string.lower;
        local keyword = SearchBox:GetValidText();

        if keyword then
            keyword = lower(keyword);
            local find = string.find;
            local lowcaseName;
            for visualID, info in pairs(self.db) do
                lowcaseName = lower(info[1]);
                if find(lowcaseName, keyword) then
                    n = n + 1;
                    tbl[n] = {
                        visualID, info[1], info[2], lower(info[1])
                    };
                end
            end
        else
            for visualID, info in pairs(self.db) do
                n = n + 1;
                tbl[n] = {
                    visualID, info[1], info[2], lower(info[1])
                };
            end
        end


        table.sort(tbl, SortFunc_Name);
        self.sortedList = tbl;

        return tbl
    end

    function FavUtil:GetEntryNameByIndex(index)
        if self.sortedList and index then
            return self.sortedList[index][2]
        end
    end

    function FavUtil:GetNumFavorites()
        return self.numFavs or 0;
    end

    function FavUtil:Add(visualID, customName)
        self.sortedList = nil;
        local name, icon = GetSpellVisualKitInfo(visualID);
        customName = customName or name or "";
        self.db[visualID] = {customName};
        if not self.isFavorite[visualID] then
            self.isFavorite[visualID] = true;
            self.numFavs = self.numFavs + 1;
            return true
        end
    end

    function FavUtil:Remove(visualID)
        self.sortedList = nil;
        self.isFavorite[visualID] = nil;
        if self.db[visualID] then
            self.db[visualID] = nil;
            self.numFavs = self.numFavs - 1;
            return true
        end
    end

    function FavUtil:Rename(visualID, newName, index)
        if self.db[visualID] then
            newName = newName or "";
            self.db[visualID] = {newName};
            if self.sortedList and index and self.sortedList[index] then
                self.sortedList[index][2] = newName;
            end
            return true
        end
    end

    function FavUtil:MarkForRemoval(visualID)
        if not self.pendingRemovalVisuals then
            self.pendingRemovalVisuals = {};
        end
        self.pendingRemovalVisuals[visualID] = true;
    end

    function FavUtil:ToggleRemoval(visualID)
        if not self.pendingRemovalVisuals then
            self.pendingRemovalVisuals = {};
        end
        self.pendingRemovalVisuals[visualID] = not self.pendingRemovalVisuals[visualID];
        return self.pendingRemovalVisuals[visualID]
    end

    function FavUtil:IsMarkedForRemoval(visualID)
        return self.pendingRemovalVisuals and self.pendingRemovalVisuals[visualID] == true
    end

    function FavUtil:GetNumPendingRemoval()
        local total = 0;
        if self.pendingRemovalVisuals then
            for visualID, state in pairs(self.pendingRemovalVisuals) do
                if state and self.db[visualID] then
                    total = total + 1;
                end
            end
        end
        return total
    end

    function FavUtil:CancelPendingRemoval()
        self.pendingRemovalVisuals = nil;
    end

    function FavUtil:ConfirmPendingRemoval()
        local total = 0;
        if self.pendingRemovalVisuals then
            for visualID, state in pairs(self.pendingRemovalVisuals) do
                if state and self.db[visualID] then
                    total = total + 1;
                    self.db[visualID] = nil;
                    self.isFavorite[visualID] = nil;
                end
            end
            self.pendingRemovalVisuals = nil;
        end
        self.numFavs = self.numFavs - total;

        if total > 0 then
            self.sortedList = nil;
        end

        return total
    end

    function FavUtil:SetMyCategoryButton(myCategoryButton)
        self.myCategoryButton = myCategoryButton;
    end

    function FavUtil:UpdateMyCategoryButton(diff)
        local button = self.myCategoryButton;
        if button then
            button.Count:SetText(self:GetNumFavorites());
            if diff then
                if diff > 0 then
                    button.Differential:SetText("|cff7cc576+"..diff.."|r");
                else
                    button.Differential:SetText("|cffff5050-"..-diff.."|r");
                end
                button.Differential.FadeText:Play();
            end
        end
    end
end


local EntryButtonMixin = {};
local FavoredEntryMixin = {};


local function EntryTab_Init()
    if EntryTab.ScrollView then return end;

    local Mixin = NarciAPI.Mixin;
    local ScrollView = NarciAPI.CreateScrollView(EntryTab);
    EntryTab.ScrollView = ScrollView;
    ScrollView:SetSize(116, 128);
    ScrollView:SetPoint("BOTTOM", EntryTab, "BOTTOM", 0, 0);
    ScrollView:SetStepSize(16 * 3);
    ScrollView:OnSizeChanged();
    ScrollView:SetBottomOvershoot(16);


    local function EntryButton_Create()
        local obj = CreateFrame("Button", nil, ScrollView, "NarciSpellViusalBrowserEntryButtonTemplate");
        Mixin(obj, EntryButtonMixin);
        return obj
    end

    ScrollView:AddTemplate("EntryButton", EntryButton_Create);


    local function FavoredButton_Create()
        local obj = CreateFrame("Button", nil, ScrollView, "Narci_SavedSpellVisualButtonTemplate");
        Mixin(obj, FavoredEntryMixin);
        obj:OnLoad();
        return obj
    end

    ScrollView:AddTemplate("FavoredButton", FavoredButton_Create);


    local BottomShadow = ScrollView:CreateTexture(nil, "OVERLAY", nil, 5);
    BottomShadow:SetTexture("Interface/AddOns/Narcissus/Art/Widgets/SpellVisualBrowser/Panel");
    BottomShadow:SetSize(126, 20);
    BottomShadow:SetTexCoord(0, 0.228515625, 0.923828125, 0.970703125);
    BottomShadow:SetPoint("BOTTOM", ScrollView, "BOTTOM", 0, -2);
    BottomShadow:Hide();

    ScrollView:SetOnScrollableChangedCallback(function(scrollable)
        BottomShadow:SetShown(scrollable);
    end);

    ScrollView:SetOnScrollStartCallback(function()
        MyFavoriteEditFrame.EditBox.anyChange = nil;
        MyFavoriteEditFrame:Hide();
    end);


    local ButtonHighlight = ScrollView:CreateTexture(nil, "OVERLAY", nil, 4);
    ButtonHighlight:Hide();
    ButtonHighlight:SetSize(116, 16);
    ButtonHighlight:SetColorTexture(1, 1, 1, 0.08);


    function ScrollView:HighlightButton(button)
        ButtonHighlight:Hide();
        ButtonHighlight:ClearAllPoints();
        if button then
            ButtonHighlight:SetPoint("CENTER", button, "CENTER", 0, 0);
            ButtonHighlight:Show();
        end
    end
end

local function DisplayVisualsByCategory(categoryIndex, fromRefresh)
    --scrollBar.BottomShadow:SetAlpha(0);
    --scrollBar.TopShadow:SetAlpha(0);

    ScrollHistory:SetActiveCategory(categoryIndex);
    EntryTab_Init();

    local content = {};
    local buttonHeight = 16;
    local offsetY = 0;
    local n = 0;
    local top, bottom;

    local category = SpellVisualList[categoryIndex];

    for headerIndex, visualInfoList in ipairs(category) do
        n = n + 1;
        top = offsetY;
        bottom = offsetY + buttonHeight;
        local count = #visualInfoList;
        content[n] = {
            dataIndex = n,
            templateKey = "EntryButton",
            setupFunc = function(obj)
                obj:SetHeader(headerIndex, visualInfoList.name, count);
            end,
            top = top,
            bottom = bottom,
        };
        offsetY = bottom;

        if ScrollHistory:IsHeaderExpanded(headerIndex) then
            for j, info in ipairs(visualInfoList) do
                n = n + 1;
                top = offsetY;
                bottom = offsetY + buttonHeight;
                content[n] = {
                    dataIndex = n,
                    templateKey = "EntryButton",
                    setupFunc = function(obj)
                        obj:SetEntry(info);
                        if j == count then
                            obj.Divider:Show();
                        end
                    end,
                    top = top,
                    bottom = bottom,
                };
                offsetY = bottom;
            end
        end
    end

    local retainPosition = fromRefresh;
    EntryTab.ScrollView:SetContent(content, retainPosition);

    if not fromRefresh then
        local lastOffset = ScrollHistory:GetLastOffset();
        if lastOffset then
            EntryTab.ScrollView:SnapTo(lastOffset);
        end
    end
end


do  --EntryButtonMixin
    function EntryButtonMixin:OnClick_Header()
        if self.headerIndex then
            ScrollHistory:ToggleHeaderExpanded(self.headerIndex);
            DisplayVisualsByCategory(ScrollHistory:GetActiveCategoryIndex(), true);
        end
    end

    function EntryButtonMixin:OnEnter_Header()
        self:GetParent():HighlightButton(self);
        QuickFavoriteButton:Hide();
    end

    function EntryButtonMixin:OnLeave_Header()
        self:GetParent():HighlightButton();
        --self:GetParent():SetAlpha(1);
    end

    function EntryButtonMixin:OnClick_Entry(button)
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

    function EntryButtonMixin:OnEnter_Entry()
        self:GetParent():HighlightButton(self);
        if not self.visualID then return; end;
        UpdatePreview(self.visualID);
        local Star = QuickFavoriteButton;
        Star:SetPoint("CENTER", self.Star, "CENTER", 0, 0);
        Star:SetParent(self);
        Star.parent = self;
        Star:Show();
        Star.visualID = self.visualID;
        Star:SetFavorite(FavUtil:IsFavorite(self.visualID));
    end

    function EntryButtonMixin:OnLeave_Entry()
        self:GetParent():HighlightButton();
    end


    function EntryButtonMixin:SetHeader(headerIndex, name, count)
        self:SetText(name);
        self.headerIndex = headerIndex;
        self.Divider:Show()
        self.collapsed = true;
        self.ButtonText:SetJustifyH("CENTER");
        self.ButtonText:SetPoint("CENTER", 0, 0);
        self.Icon:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Widgets\\SpellVisualBrowser\\ExpandMark");
        self:UpdateCollapsed();
        self.Star:Hide();
        self.visualID = nil;
        self.Count:SetText(count);
        self.Count:Show();
        self.Background:Show();
        self:SetPushedTextOffset(0, 0);
        self:SetScript("OnClick", self.OnClick_Header);
        self:SetScript("OnEnter", self.OnEnter_Header);
        self:SetScript("OnLeave", self.OnLeave_Header);
    end

    function EntryButtonMixin:SetEntry(info)
        self.visualID = info[1];
        self.animID = info[4];
        self.headerIndex = nil;
        self.collapsed = nil;
        self.Divider:Hide();
        if FavUtil:IsFavorite(self.visualID) then
            self.Star:Show();
        else
            self.Star:Hide();
        end
        self:SetText(info[2]);
        self.ButtonText:SetJustifyH("LEFT");
        self.ButtonText:SetPoint("CENTER", 13, 0);
        self.Count:Hide();
        self.Background:Hide();
        self.texID = info[3];
        if self.texID == 1 then
            self.texID = 134400;
        end
        self.Icon:SetTexture(self.texID);
        self.Icon:SetTexCoord(0.09375, 0.90625, 0.09375, 0.90625);
        self:SetPushedTextOffset(1, -0.6);
        self:SetScript("OnClick", self.OnClick_Entry);
        self:SetScript("OnEnter", self.OnEnter_Entry);
        self:SetScript("OnLeave", self.OnLeave_Entry);
    end

    function EntryButtonMixin:UpdateCollapsed()
        if self.headerIndex then
            if ScrollHistory:IsHeaderExpanded(self.headerIndex) then
                self.Icon:SetTexCoord(0, 1, 1, 0);
            else
                self.Icon:SetTexCoord(0, 1, 0, 1);
            end
        end
    end
end


local function CategoryButton_OnClick(self)
    DisplayVisualsByCategory(self.index);
    ListFrame.Header.Tab2Label:SetText(self:GetText());
    After(0, function()
        GoToTab(2);
    end);
end


do  --FavoredEntryMixin
    function FavoredEntryMixin:OnEnter()
        self:GetParent():HighlightButton(self);

        if not self.visualID then return; end;
        UpdatePreview(self.visualID);

        --Relocate edit buttons (rename, delete)
        if MyFavoriteEditFrame.EditBox:HasFocus() then
            return
        end

        MyFavoriteEditFrame.parent = self;
        MyFavoriteEditFrame.visualID = self.visualID;
        MyFavoriteEditFrame:SetParent(self);
        MyFavoriteEditFrame:SetFrameLevel(self:GetFrameLevel() + 1);
        MyFavoriteEditFrame:SetPoint("RIGHT", self, "RIGHT", -4, 0);
        MyFavoriteEditFrame:Show();
    end

    function FavoredEntryMixin:OnLeave()
        if self:IsMouseOver() then return end;
        self:GetParent():HighlightButton(nil);
        if not MyFavoriteEditFrame.EditBox:HasFocus() then
            MyFavoriteEditFrame:Hide();
        end
    end

    function FavoredEntryMixin:OnClick(button)
        local model = Narci.ActiveModel;
        if not model then return; end;
        if button == "LeftButton" then
            model:ApplySpellVisualKit(self.visualID, true);
        elseif button == "RightButton" then
            SmoothInsert(self.visualID, self.texID, self:GetText());
        end
    end

    function FavoredEntryMixin:OnEnable()
        self.Icon:SetDesaturated(false);
        self:SetAlpha(1);
    end

    function FavoredEntryMixin:OnDisable()
        self.Icon:SetDesaturated(true);
        self:SetAlpha(0.4);
    end

    function FavoredEntryMixin:SetInfo(info)
        self:Show();
        self:Enable();
        self.visualID = info[1];
        self.text = info[2];
        self:SetText(FavUtil:GetEntryNameByIndex(self.index) or self.text);
        self.ButtonText:SetJustifyH("LEFT");
        self.ButtonText:SetPoint("CENTER", 13, 0);
        local _, icon = GetSpellVisualKitInfo(self.visualID);
        local texID = icon or 134400;
        self.Icon:SetTexture(texID);
        self.Icon:SetTexCoord(0.09375, 0.90625, 0.09375, 0.90625);
        self.texID = texID;

        if FavUtil:IsMarkedForRemoval(self.visualID) then
            self:Disable();
        else
            self:Enable();
        end
    end

    function FavoredEntryMixin:OnLoad()
        self:SetPushedTextOffset(1, -0.6);
        self:SetScript("OnClick", self.OnClick);
        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnEnable", self.OnEnable);
        self:SetScript("OnDisable", self.OnDisable);
    end
end

----------------------------------------------------------------
local function DisplayFavorites(fromRefresh)
    ListFrame.Header.Tab2Label:SetText(L["My Favorites"]);

    ScrollHistory:SetActiveCategory(0);
    EntryTab_Init();

    local content = {};
    local buttonHeight = 16;
    local offsetY = 2;  --SearchBox's ClearTextButton is too close to the delete button on the top entry
    local n = 0;
    local top, bottom;

    for index, info in pairs(FavUtil:GetSortedList()) do
        n = n + 1;
        top = offsetY;
        bottom = offsetY + buttonHeight;
        content[n] = {
            dataIndex = n,
            templateKey = "FavoredButton",
            setupFunc = function(obj)
                obj.index = index;
                obj:SetInfo(info);
            end,
            top = top,
            bottom = bottom,
        };
        offsetY = bottom;
    end

    local retainPosition = fromRefresh;
    EntryTab.ScrollView:HighlightButton(nil);
    EntryTab.ScrollView:SetContent(content, retainPosition);

    if not fromRefresh then
        local lastOffset = ScrollHistory:GetLastOffset();
        if lastOffset then
            EntryTab.ScrollView:SnapTo(lastOffset);
        end
    end

    MyFavoriteEditFrame:Hide();
    SearchBox.NoMatchText:SetShown(n == 0);
end

local function GoToMyFavorites()
    DisplayFavorites();
    After(0, function()
        GoToTab(3);
    end);
end


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
            button:SetText(L["My Favorites"]);
            button.Count:SetText(FavUtil:GetNumFavorites());
            button:SetScript("OnClick", GoToMyFavorites);
            FavUtil:SetMyCategoryButton(button);
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

function NarciSpellVisualUtil:SelectPack(index)
    local packName;
    SpellVisualList, packName = self:GetPack(index);
    UpdateCategoryButtons();
    ScrollHistory:Reset();
    After(0, function()
        HomeButton:Click();
    end)
    return packName
end

function NarciSpellVisualUtil:SelectFirstCategory()
    --for tutorial
    local categoryIndex = 1;
    DisplayVisualsByCategory(categoryIndex);
    ListFrame.Header.Tab2Label:SetText(SpellVisualList[categoryIndex].name);
    After(0, function()
        GoToTab(2);
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
    local visualID = self:GetNumber();
    if FavUtil:IsFavorite(visualID) then
        Star.Icon:SetAlpha(1);
        Star.Icon:SetTexCoord(0.25, 0.5, 0, 1);
        Star.isFav = true;
    else
        Star.Icon:SetAlpha(0.6);
        Star.Icon:SetTexCoord(0, 0.25, 0, 1);
        Star.isFav = false;
    end
    ----
    self.Timer:Stop();
    EditorPopup:Hide();
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
    elseif model.fileID then
        model:SetModel(model.fileID);
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
    NarciTooltip:NewText(self, L["Remove Visual Tooltip"], nil, nil, true);
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
        model.AppliedVisuals = {};
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


local EditBoxFavoriteButtonMixin = {};
do
    function EditBoxFavoriteButtonMixin:OnLoad()
        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnClick", self.OnClick);
    end

    function EditBoxFavoriteButtonMixin:OnEnter()
        self.Icon:SetAlpha(1);
        self.Highlight:Show();
        if not self:GetParent().PopUpFrame:IsShown() then
            if self.isFav then
                NarciTooltip:NewText(self, L["Favorites Remove"], nil, nil, true);
            else
                NarciTooltip:NewText(self, L["Favorites Add"], nil, nil, true);
            end
        end
    end

    function EditBoxFavoriteButtonMixin:OnLeave()
        NarciTooltip:HideTooltip();
        self.Highlight:Hide();
        if not self.isFav then
            self.Icon:SetAlpha(0.6);
        end
    end

    function EditBoxFavoriteButtonMixin:Update()
        local visualID = VisualIDEditBox:GetNumber();
        if FavUtil:IsFavorite(visualID) then
            self.Icon:SetAlpha(1);
            self.Icon:SetTexCoord(0.25, 0.5, 0, 1);
            self.isFav = true;
        else
            if self:IsMouseMotionFocus() then
                self.Icon:SetAlpha(1);
            else
                self.Icon:SetAlpha(0.6);
            end
            self.Icon:SetTexCoord(0, 0.25, 0, 1);
            self.isFav = false;
        end
    end

    function EditBoxFavoriteButtonMixin:OnClick()
        NarciTooltip:HideTooltip();
        local visualID = VisualIDEditBox:GetNumber();
        if not visualID then return end;


        if not self.isFav then
            if EditorPopup:IsShown() then
                EditorPopup:Confirm();
                self.Icon:SetTexCoord(0.25, 0.5, 0, 1);
                self.isFav = true;
                self.Icon:SetAlpha(1);
            else
                BrowserFrame.ArtFrame.Bling.animIn:Play();
                local index = FavUtil:GetNumFavorites() + 1;
                EditorPopup.HiddenFrame.EditBox:SetText("Custom Visual " .. index);
                FadeFrame(EditorPopup, 0.15, 1);
            end
        else
            if FavUtil:Remove(visualID) then
                self.isFav = false;
                self.Icon:SetTexCoord(0, 0.25, 0, 1);
                FavUtil:UpdateMyCategoryButton(-1);
                if CURRENT_TAB_INDEX == 3 then
                    FavUtil:CancelPendingRemoval();
                    DisplayFavorites();
                end
            end
        end
    end
end


local EditorPopupMixin = {};
do
    function EditorPopupMixin:Confirm()
        local EditBox = EditorPopup.HiddenFrame.EditBox;
        local visualID = VisualIDEditBox:GetNumber();
        if FavUtil:Add(visualID, EditBox:GetText()) then
            FavUtil:UpdateMyCategoryButton(1);
        end
        EditBox:ClearFocus();
        EditBoxFavoriteButton:Update();
        FadeFrame(EditorPopup, 0.25, 0);

        if CURRENT_TAB_INDEX == 3 then
            FavUtil:CancelPendingRemoval();
            DisplayFavorites();
        end
    end

    function EditorPopupMixin:Cancel()
        FadeFrame(EditorPopup, 0.15, 0);
        EditBoxFavoriteButton:Update();
    end

    function EditorPopupMixin:OnLoad()
        local f = self.HiddenFrame;
        f.Header:SetText(L["New Favorite"]);
        f.ConfirmButton:SetScript("OnClick", self.Confirm);
        f.CancelButton:SetScript("OnClick", self.Cancel);
        f.EditBox:SetScript("OnEnterPressed", self.Confirm);
        f.EditBox:SetScript("OnEscapePressed", self.Cancel);
    end
end


local function UpdateDeleteInfo()
    local numToBeDeleted = FavUtil:GetNumPendingRemoval();
    local TextFormat;
    if numToBeDeleted > 1 then
        TextFormat = L["Delete Entry Plural"];          --plural
    else
        TextFormat = L["Delete Entry Singular"];        --singular
    end
    ListFrame.Header.Tab2Label:SetText( string.format(TextFormat, numToBeDeleted) );
end

local function EditFrame_EditBox_Confirm()
    local EntryButton = MyFavoriteEditFrame.parent;
    local newName = MyFavoriteEditFrame.EditBox:GetText();
    MyFavoriteEditFrame.EditBox.anyChange = nil;
    MyFavoriteEditFrame.EditBox:SetText("");
    MyFavoriteEditFrame.EditBox:Hide();
    EntryButton:SetText(newName);

    if FavUtil:Rename(EntryButton.visualID, newName, EntryButton.index) then
        DisplayFavorites(true);
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
    local FavoredEntry = self:GetParent().parent;
    if not FavoredEntry then return; end;

    if FavoredEntry.visualID then
        local markedForRemoval = FavUtil:ToggleRemoval(FavoredEntry.visualID);
        if markedForRemoval then
            FavoredEntry:Disable();
        else
            FavoredEntry:Enable();
        end
    end

    UpdateDeleteInfo();

    local EditBox = self:GetParent().EditBox;
    EditFrame_EditBox_Cancel(EditBox);
end

local function EditFrame_RenameButton_OnClick(self)
    local EditBox = MyFavoriteEditFrame.EditBox;
    local FavoredEntry = MyFavoriteEditFrame.parent;
    self.IsOn = not self.IsOn;
    if self.IsOn then
        MyFavoriteEditFrame.EditBoxBackground:Show();

        local oldText = FavoredEntry:GetText();
        EditBox:Show();
        EditBox:SetText(oldText or "");
        EditBox:SetFocus();
        EditBox:HighlightText();

        if FavUtil:IsMarkedForRemoval(FavoredEntry.visualID) then
            --Rename a entry that is about to be deleted will cancel deletion
            FavUtil:ToggleRemoval(FavoredEntry.visualID);
            FavoredEntry:Enable();
            UpdateDeleteInfo();
        end
    else
        EditFrame_EditBox_Cancel(EditBox);
    end
end

local function QuickFavoriteButton_OnClick(self)
    if not self.visualID then return end;

    if FavUtil:IsFavorite(self.visualID) then
        FavUtil:Remove(self.visualID);
        self.isFav = false;
    else
        FavUtil:Add(self.visualID);
        self.isFav = true;
    end
    FavUtil:UpdateMyCategoryButton();

    self:PlayVisual();
end

local function HomeButton_OnClick(self)
    if CURRENT_TAB_INDEX == 3 then
        --If you just go back from My Favorites, start removing selected favorites
        local numDeleted = FavUtil:ConfirmPendingRemoval();
        if numDeleted > 0 then
            FavUtil:UpdateMyCategoryButton(-numDeleted);
            EditBoxFavoriteButton:Update();
        end
    end

    GoToTab(1);
    FadeFrame(self, 0.2, 0);
    PreviewFrame:ResetCover();
end


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


NarciSpellVisualBrowserMixin = {};
do
    function NarciSpellVisualBrowserMixin:Init()
        self.Init = nil;

        SetAutoPlayButtonScript(SuggestionFrame.AutoPlay);
        FavUtil:Load();
        FavUtil:UpdateMyCategoryButton();
    end

    function NarciSpellVisualBrowserMixin:OnShow()
        if self.Init then
            self:Init();
        end
        AnimationContariner:Show();
    end

    function NarciSpellVisualBrowserMixin:OnHide()
        AnimationContariner:Hide();
        clickCounter.leftButton = 0;
        clickCounter.tooltipShown = nil;
    end

    function NarciSpellVisualBrowserMixin:OnLoad()
        BrowserFrame = self;
        self:SetPoint("BOTTOMRIGHT", Narci_AnimationIDFrame, "BOTTOMLEFT", BROWSER_ANCHOR_OFFSET_COLLAPSED_X, BROWSER_ANCHOR_OFFSET_Y);

        local ExpandableFrames = self.ExpandableFrames;
        ListFrame = self.ExpandableFrames.ListFrame.Container;
        SuggestionFrame = self.ExpandableFrames.SuggestionFrame;
        HistoryFrame = self.ExpandableFrames.HistoryFrame;
        Tab1 = ListFrame.Category;
        EntryTab = ListFrame.EntryTab;
        VisualIDEditBox = ExpandableFrames.EditBox;


        ExpandableFrames.EditBox:SetScript("OnMouseWheel", EditBox_OnMouseWheel);
        ExpandableFrames.EditBox:SetScript("OnEnterPressed", EditBox_OnEnterPressed);
        ExpandableFrames.EditBox:SetScript("OnTextChanged", EditBox_OnTextChanged);
        ExpandableFrames.PlusButton:SetScript("OnClick", PlusButton_OnClick);
        ExpandableFrames.ApplyButton:SetScript("OnClick", ApplyButton_OnClick);
        ExpandableFrames.ResetButton:SetScript("OnClick", ResetButton_OnClick);

        EditBoxFavoriteButton = ExpandableFrames.FavoriteButton;
        NarciAPI.Mixin(EditBoxFavoriteButton, EditBoxFavoriteButtonMixin);
        EditBoxFavoriteButton:OnLoad();

        EditorPopup = ExpandableFrames.PopUpFrame;
        NarciAPI.Mixin(EditorPopup, EditorPopupMixin);
        EditorPopup:OnLoad();

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


        QuickFavoriteButton = ListFrame.EntryTab.QuickFavoriteButton;
        QuickFavoriteButton:SetScript("OnClick", QuickFavoriteButton_OnClick);

        MyFavoriteEditFrame = ListFrame.EditFrame;
        MyFavoriteEditFrame.DeleteButton:SetScript("OnClick", EditFrame_DeleteButton_OnClick);
        MyFavoriteEditFrame.RenameButton:SetScript("OnClick", EditFrame_RenameButton_OnClick);
        MyFavoriteEditFrame.EditBox:SetScript("OnEnterPressed", EditFrame_EditBox_Confirm);
        MyFavoriteEditFrame.EditBox:SetScript("OnEscapePressed", EditFrame_EditBox_Cancel);
        MyFavoriteEditFrame.EditBox:SetScript("OnEditFocusLost", EditFrame_EditBox_OnEditFocusLost);
        MyFavoriteEditFrame.EditBox:SetScript("OnTextChanged", EditFrame_EditBox_OnTextChanged);

        function MyFavoriteEditFrame.EditBox:HasStickyFocus()
            return DoesAncestryIncludeAny(self, GetMouseFoci())
        end


        local IDLabel = self.VisualIDFrame.Label;
        IDLabel:SetText("ID");
        IDLabel:SetPoint("LEFT", self.VisualIDFrame, "LEFT", 30, 0);

        local b = CreateFrame("Frame", nil, self.ExpandableFrames, "NarciGenericInfoButtonTemplate");
        self.InfoButton = b;
        b:ClearAllPoints();
        b:SetPoint("LEFT", self.VisualIDFrame, "LEFT", 6, 0);
        b:SetSize(18, 18);
        b:SetHitRectInsets(0, 0, 0, 0);
        b:SetNormalColor(0.65, 0.65, 0.65);
        b:SetHighlightColor(0.88, 0.88, 0.88);
        b:SetVisualType(2);
        b:SetCursorColor(2);
        b:SetUsePrivateTooltip(true, L["FindVisual Tooltip"]);
        b:SetFrameLevel(self.VisualIDFrame:GetFrameLevel() + 10);
        b:SetScript("OnMouseDown", function()
            NarciAPI.ToggleSpellVisualTutorial();
        end);
    end
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
    self.packName = NarciSpellVisualUtil:SelectPack(packID);
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




NarciSpellVisualSearchBoxMixin = CreateFromMixins(NarciSearchBoxSharedMixin);

function NarciSpellVisualSearchBoxMixin:OnLoad()
    SearchBox = self;
    NarciSearchBoxSharedMixin.OnLoad(self);
    self.DefaultText:SetText(SEARCH);
    self.DefaultText:SetPoint("LEFT", self, "LEFT", 16, 0);
    self.NoMatchText:ClearAllPoints();
    self.NoMatchText:SetPoint("TOP", self:GetParent(), "TOP", 0, -16 - 4);
    self.noAutoFocus = true;

    self.onSearchFunc = function(word)
        FavUtil.sortedList = nil;
        if CURRENT_TAB_INDEX == 3 then
            DisplayFavorites();
        end
    end
end

function NarciSpellVisualSearchBoxMixin:OnTextChanged(isUserInput)
    local str = self:GetText();
    if str and str ~= "" then
        if isUserInput then
            self.DefaultText:Hide();
        end
        self.EraseButton:Show();
    else
        self.DefaultText:Show();
        self.EraseButton:Hide();
    end

    self:Search(true);
    self.NoMatchText:Hide();
end

function NarciSpellVisualSearchBoxMixin:OnFocusGained()
    self:OnEditFocusGained();
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