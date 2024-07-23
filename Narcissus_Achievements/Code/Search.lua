local _, addon = ...

local DataProvider = addon.DataProvider;
local IsAccountWide = addon.IsAccountWide;
local InspectResult = addon.InspectResult;
local TabUtil = addon.TabUtil;
local outQuart = addon.outQuart;

local SetAchievementSearchString = SetAchievementSearchString;
local GetAchievementCategory = GetAchievementCategory;
local SwitchAchievementSearchTab = SwitchAchievementSearchTab;
local GetNumFilteredAchievements = GetNumFilteredAchievements;
local GetFilteredAchievementID = GetFilteredAchievementID;
local GetStatistic = GetStatistic;
local strlen = strlen;

local MIN_CHARACTER_SEARCH = MIN_CHARACTER_SEARCH;

local SearchBox, ResultFrame;

local IS_ACHIEVEMENT = true;


function TabUtil:EnableSearchBox(state)
    if state then
        SearchBox:Enable();
        SearchBox.Instructions:SetText(SEARCH or "Search");
    else
        SearchBox:Disable();
        SearchBox.Instructions:SetText("N/A");
    end
end

local ClearButtonScripts = {};

ClearButtonScripts.OnEnter = function(self)
    self.Icon:SetAlpha(1);
end

ClearButtonScripts.OnLeave = function(self)
    self.Icon:SetAlpha(0.5);
end

ClearButtonScripts.OnMouseDown = function(self)
    self.Icon:SetSize(12, 12);
end

ClearButtonScripts.OnMouseUp = function(self)
    self.Icon:SetSize(14, 14);
end

ClearButtonScripts.OnClick = function(self)
    SearchBox:SetText("");
end

ClearButtonScripts.PreClick = function(self)
    if SearchBox.wasEditbing then
        SearchBox:SetFocus();
    end
end

ClearButtonScripts.PostClick = function(self)
    if SearchBox.wasEditbing then
        SearchBox:SetFocus();
    end
end

function NarciAchievementSearchBoxMixin:OnLoad()
    SearchBox = self;
    self:SetTextInsets(16, 20, 0, 0);
    self.Instructions:SetText(SEARCH);
	self.Instructions:ClearAllPoints();
	self.Instructions:SetPoint("TOPLEFT", self, "TOPLEFT", 16, 0);
	self.Instructions:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -20, 0);
    self.Instructions:SetMaxLines(1);
	self.SearchIcon:SetVertexColor(0.6, 0.6, 0.6);


    local delayedSearch = NarciAPI_CreateAnimationFrame(0.5);
    self.delayedSearch = delayedSearch;
    delayedSearch:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        if frame.total >= frame.duration then
            frame:Hide();
            SetAchievementSearchString(self.keyword);
        end
    end)

    ---Clear Button
    for scriptName, func in pairs(ClearButtonScripts) do
        self.ClearButton:SetScript(scriptName, func);
    end

    ---
    ResultFrame = self.ClipFrame.ResultFrame;
    self.ResultFrame = ResultFrame;
    local buttons = {};
    local button;
    for i = 1, 5 do
        button = CreateFrame("Button", nil, ResultFrame, "NarciAchievementSearchResultButtonTemplate");
        tinsert(buttons, button);
        if i == 1 then
            button:SetPoint("TOP", ResultFrame, "TOP", 0, -24);
        else
            button:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, -2);
        end
        button:Hide();
    end
    ResultFrame.buttons = buttons;

    self.ResultFrame:SetScript("OnMouseWheel", function(frame, delta)
        if self.numResults and self.numResults > 5 then
            if delta > 0 then
                if self.currentPage > 1 then
                    self.currentPage = self.currentPage - 1;
                    self:UpdatePage();
                end
            else
                if self.currentPage < self.maxPage then
                    self.currentPage = self.currentPage + 1;
                    self:UpdatePage();
                end
            end
        end
    end)

    --Animation
    local animDrop = NarciAPI_CreateAnimationFrame(0.35);
    animDrop:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local alpha = outQuart(frame.total, frame.fromAlpha, frame.toAlpha, frame.duration);

        if frame.total >= frame.duration then
            frame:Hide();
            alpha = frame.toAlpha;
            if alpha == 0 then
                ResultFrame:Hide();
            end
        end

        ResultFrame:SetAlpha(alpha);
    end)

    function self:ShowResults()
        animDrop:Hide();
        animDrop.fromAlpha = ResultFrame:GetAlpha();
        animDrop.toAlpha = 1;
        ResultFrame:Show();
        animDrop:Show();
    end

    function self:HideResults()
        animDrop:Hide();
        animDrop.fromAlpha = ResultFrame:GetAlpha();
        animDrop.toAlpha = 0;
        animDrop:Show();
    end

    ResultFrame:SetAlpha(0);
end

function NarciAchievementSearchBoxMixin:OnUpdate()
    self.pauseUpdate = true;
end

function NarciAchievementSearchBoxMixin:HasText()
    return self:GetText() ~= ""
end

function NarciAchievementSearchBoxMixin:OnTextChanged()
    self.keyword = self:GetText();
    if ( strlen(self.keyword) >= MIN_CHARACTER_SEARCH ) then
        self.delayedSearch.total = 0;
        self.delayedSearch:Show();
    else
        self.delayedSearch:Hide();
    end

    if self.keyword == "" then
        self.Instructions:Show();
        self.SearchIcon:SetVertexColor(0.6, 0.6, 0.6);
		self.ClearButton:Hide();
    else
        self.Instructions:Hide();
        self.SearchIcon:SetVertexColor(1, 1, 1);
		self.ClearButton:Show();
    end
end

function NarciAchievementSearchBoxMixin:OnEditFocusGained()
    local tabID = TabUtil:GetTabID();
    if tabID > 3 then return end;

    IS_ACHIEVEMENT = (tabID == 1 or tabID == 2);
    if tabID ~= self.tabID then
        self.tabID = tabID;
        SwitchAchievementSearchTab(tabID);
    end
    self:RegisterEvent("ACHIEVEMENT_SEARCH_UPDATED");
    local numResults = GetNumFilteredAchievements() or 0;
    --this filter might be removed by using the original AchievementFrame so we need to set again
    if numResults > 0 then
        self:ShowResults();
    else
        if self:HasText() then
            self:ShowNoMatch();
            self:OnTextChanged();
        end
    end
    self.SearchIcon:SetVertexColor(1, 1, 1);
end

function NarciAchievementSearchBoxMixin:OnEditFocusLost()
    if not self.ResultFrame:IsMouseOver() then
        self:HideResults();
    end
    self:UnregisterEvent("ACHIEVEMENT_SEARCH_UPDATED");

    if not self:HasText() then
        self.SearchIcon:SetVertexColor(0.6, 0.6, 0.6);
        self.ClearButton:Hide();
    end

    if self:IsMouseOver() and IsMouseButtonDown("LeftButton") then
        self.wasEditbing = true;
    else
        self.wasEditbing = false;
    end

    self:HighlightText(0, 0);
end

function NarciAchievementSearchBoxMixin:OnEnterPressed()
    self:ClearFocus();
    if self:HasText() then
        local button1 = self.ResultFrame.buttons[1];
        if button1:IsShown() then
            button1:Click();
        end
    end
end

function NarciAchievementSearchBoxMixin:OnHide()
    self:UnregisterEvent("ACHIEVEMENT_SEARCH_UPDATED");
    self.ResultFrame:Hide();
end

function NarciAchievementSearchBoxMixin:ProcessResults()
    local numResults = GetNumFilteredAchievements();
    self.numResults = numResults;
    self.ResultFrame.count:SetText(numResults.." |cff808080Results|r");
    local numPages = math.ceil(numResults / 5);
    self.maxPage = numPages;
    if ( numResults > 0 ) then
        self.currentPage = 1;
        self:UpdatePage();
        self:ShowResults();
    else
        if self:HasText() then
            self:ShowNoMatch();
        else
            self:HideResults();
        end
    end
end

function NarciAchievementSearchBoxMixin:OnEvent(event)
    self:ProcessResults();
end

function NarciAchievementSearchBoxMixin:ShowNoMatch()
    self.numResults = 0;
    self.ResultFrame.pageText:SetText(nil);
    self.ResultFrame.count:SetText("0 |cff808080Results|r");
    for _, button in pairs(self.ResultFrame.buttons) do
        button:Hide();
    end
    self:ShowResults();
end

function NarciAchievementSearchBoxMixin:UpdatePage()
    local page = self.currentPage or 1;
    local numPages = math.ceil(self.numResults / 5);
    local buttons = self.ResultFrame.buttons;
    if numPages > 0 then
        self.ResultFrame.pageText:SetText(page.."/"..numPages);
        local firstID = 5*(page - 1);
        local button;
        local index;
        for i = 1, 5 do
            index = i + firstID;
            button = buttons[i];
            if index <= self.numResults then
                button:SetData( GetFilteredAchievementID(index) );
                button:Show();
            else
                button:Hide();
            end
        end
    else
        self.ResultFrame.pageText:SetText(nil);
        for i = 1, 5 do
            buttons[i]:Hide();
        end
    end
end

function NarciAchievementSearchBoxMixin:QuitEditing()
    self:ClearFocus();
end



---------------------------------------------------------------
--Matches

NarciAchievementSearchResultButtonMixin = {};

function NarciAchievementSearchResultButtonMixin:OnMouseDown()
    self.AnimPushed:Stop()
    self.AnimPushed.hold:SetDuration(20);
    self.AnimPushed:Play()
end

function NarciAchievementSearchResultButtonMixin:OnMouseUp()
    self.AnimPushed.hold:SetDuration(0);
end

function NarciAchievementSearchResultButtonMixin:OnClick()
    InspectResult(self);
    ResultFrame:Hide();
end

function NarciAchievementSearchResultButtonMixin:SetAchievement(achievementID)
    local id, name, points, completed, _, _, _, _, flags, icon = DataProvider:GetAchievementInfo(achievementID);
    self.id = id;
    self.header:SetFontObject(NarciAchievementText);
    self.header:SetText(name);
    self.icon:SetTexture(icon);
    if IsAccountWide(flags) then     --ACHIEVEMENT_FLAGS_ACCOUNT
        self.header:SetTextColor(0.427, 0.812, 0.965);
        self.background:SetTexCoord(0, 1, 0.5, 1);
    else
        self.header:SetTextColor(1, 0.91, 0.647);
        self.background:SetTexCoord(0, 1, 0, 0.5);
    end

    local categoryID = GetAchievementCategory(id);
    local categoryName, parentCategoryID = DataProvider:GetCategoryInfo(categoryID);
    local path = categoryName;
    while ( not (parentCategoryID == -1) ) do
        categoryName, parentCategoryID = DataProvider:GetCategoryInfo(parentCategoryID);
        path = categoryName.." > "..path;
    end
    self.path:SetText(path);

    if completed then
        self.header:SetAlpha(1);
        self.icon:SetDesaturated(false);
        self.icon:SetVertexColor(1, 1, 1);
        self.background:SetVertexColor(1, 1, 1);
    else
        self.header:SetAlpha(0.5);
        self.icon:SetDesaturated(true);
        self.icon:SetVertexColor(0.5, 0.5, 0.5);
        self.background:SetVertexColor(0.5, 0.5, 0.5);
    end
end

function NarciAchievementSearchResultButtonMixin:SetStatistics(statID)
    local id, name = DataProvider:GetAchievementInfo(statID);
    self.id = statID;
    self.header:SetFontObject(GameFontHighlightSmall);
    self.header:SetText(name);
    self.icon:SetTexture(3610506);
    self.icon:SetDesaturated(true);
    self.header:SetTextColor(1, 0.91, 0.647);
    self.background:SetTexCoord(0, 1, 0, 0.5);
    local path = GetStatistic(id);
    self.path:SetText(path);
    self.header:SetAlpha(1);
    self.icon:SetVertexColor(1, 1, 1);
    self.background:SetVertexColor(1, 1, 1);
end

function NarciAchievementSearchResultButtonMixin:SetData(id)
    if IS_ACHIEVEMENT then
        self:SetAchievement(id);
    else
        self:SetStatistics(id);
    end
end