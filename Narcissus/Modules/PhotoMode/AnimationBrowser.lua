local _, addon = ...

local Narci = Narci;
local NarciAnimationInfo = NarciAnimationInfo;
local FadeFrame = NarciFadeUI.Fade;

local After = C_Timer.After;

local BrowserFrame, QuickFavoriteButton;


local outQuart = addon.EasingFunctions.outQuart;

local function FlyInText(button)
    local textWidth = button.Name:GetWidth();
    if textWidth > 82 then
        local offset = textWidth - 82;
        button.FlyIn:Stop();
        button.FlyIn.offset:SetOffset( -offset, 0 );
        button.FlyIn.offset:SetDuration( offset / 12);
        button.FlyIn:Play();
    end
end

local delayedAction = NarciAPI_CreateAnimationFrame(0.25);
delayedAction:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    if self.total >= self.duration then
        self:Hide();
        FlyInText(self.object);
    end
end)

NarciAnimationOptionButtonMixin = {};

function NarciAnimationOptionButtonMixin:Init()
    self.Name = self.FlyingTextFrame.Name;
    self.FlyIn = self.FlyingTextFrame.Name.FlyIn;

    self.Init = nil;
end

function NarciAnimationOptionButtonMixin:OnEnter()
    FadeFrame(self.Highlight, 0.12, 1);

    delayedAction:Hide();
    delayedAction.object = self;
    delayedAction:Show();

    local Star = QuickFavoriteButton;
    Star:ClearAllPoints();
    Star:SetPoint("CENTER", self.Star, "CENTER", 0, 0);   --Can't properly be aligned with it Why!!!!!!!
    Star.parent = self;
    Star:Show();
    Star.animationID = self.animationID;
    Star:SetFavorite(self.isFavorite);
    Star:SetParent(self);
end

function NarciAnimationOptionButtonMixin:OnLeave()
    FadeFrame(self.Highlight, 0.2, 0);
    self.FlyIn:Stop();
end

function NarciAnimationOptionButtonMixin:OnClick(button)
    local model = Narci:GetActiveActor();
    local id = self.animationID or 0;
    model:PlayAnimation(id);
    NarciModelControl_AnimationIDEditBox:SetText(id);
    if button == "RightButton" then
        BrowserFrame:Close();
    end
end

function NarciAnimationOptionButtonMixin:OnDoubleClick()
    return
end

function NarciAnimationOptionButtonMixin:SetFavorite(isFavorite)
    self.Star:SetShown(isFavorite);
    self.isFavorite = isFavorite;
end

function NarciAnimationOptionButtonMixin:SetAnimationInfo(id)
    if id ~= self.animationID then
        self.animationID = id;
        self.FlyIn:Stop();
        self.ID:SetText(id);
        self.Name:SetText( NarciAnimationInfo.GetOfficialName(id) );
        self:SetFavorite( NarciAnimationInfo.IsFavorite(id) );
        self:Show();
    end
end

function NarciAnimationOptionButtonMixin:SetEmpty()
    self.animationID = -1;
    self:Hide();
end

function NarciAnimationOptionButtonMixin:UpdateFavorite()
    self:SetFavorite(self.animationID and NarciAnimationInfo.IsFavorite(self.animationID));
end

----------------------------------------------------
--Animation Cache
local DataProvider = {};
DataProvider.maxAnimID = NarciConstants.Animation.MaxAnimationID or 1499;

function DataProvider:GetAvailableAnimationsForModel(model, forcedUpdate)
    if forcedUpdate or not model.isAnimationCached then
        local animations = {};
        local numAnim = 0;
        for i = 0, self.maxAnimID do
            if model:HasAnimation(i) then
                numAnim = numAnim + 1;
                animations[numAnim] = { i, NarciAnimationInfo.IsFavorite(i) };
            end
        end
        model.isAnimationCached = true;
        model.animationList = animations;
    end
    return model.animationList or {}
end

function DataProvider:GetAnimationsByIndex(fromIndex)
    local data = {};
    for i = 1, 10 do
        data[i] = BrowserFrame.availableAnimations[fromIndex + i];
    end
    return data
end


----------------------------------------------------
--Animation Browser

NarciAnimationBrowserMixin = {};

function NarciAnimationBrowserMixin:OnLoad()
    BrowserFrame = self;

    --Expand Animation
    self:SetHeight(8);      --Collapsed Height
    self:SetAlpha(0);
    local animExpand = NarciAPI_CreateAnimationFrame(0.25);
    self.animExpand = animExpand;
    animExpand:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local height = outQuart(frame.total, frame.fromHeight, frame.toHeight, frame.duration);
        if frame.total >= frame.duration then
            height = frame.toHeight;
            frame:Hide();
        end
        self:SetHeight(height);
    end);

    --Expand Button
    local ExpandButton = self:GetParent().ExpandButton;
    self.ExpandButton = ExpandButton;
    self.ExpandArrow = ExpandButton.Arrow;

    self.forcedUpdate = true;
    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);
end

function NarciAnimationBrowserMixin:Init()
    self.Init = nil;


    local ScrollView = NarciAPI.CreateScrollView(self);
    self.ScrollView = ScrollView;
    ScrollView:SetSize(139, 128);
    ScrollView:SetPoint("BOTTOM", self, "BOTTOM", 0, 0);
    ScrollView:SetStepSize(16 * 3);
    ScrollView:OnSizeChanged();

    ScrollView:SetOnDragStartCallback(function()
        QuickFavoriteButton:Hide();
    end);

    local function AnimationButton_Create()
        local obj = CreateFrame("Button", nil, ScrollView, "Narci_AnimationButtonTemplate");
        obj:Init();
        return obj
    end

    local function AnimationButton_OnRemoved(obj)
        obj.FlyIn:Stop();
    end

    ScrollView:AddTemplate("AnimationButton", AnimationButton_Create, nil, AnimationButton_OnRemoved);


    QuickFavoriteButton = CreateFrame("Button", nil, ScrollView, "NarciQuickFavoriteButtonTemplate");
    local IDEditbox = BrowserFrame:GetParent().IDEditBox;
    local IDEditboxFavoriteButton = BrowserFrame:GetParent().FavoriteButton;

    local function QuickFavoriteButton_OnClick(button)
        local isFavorite = not button.isFav;
        button.parent.isFavorite = isFavorite;
        button.isFav = isFavorite;

        local animationID = button.animationID;
        if isFavorite then
            NarciAnimationInfo.AddFavorite(button.animationID);
        else
            NarciAnimationInfo.RemoveFavorite(button.animationID);
        end
        button:PlayVisual();
        BrowserFrame.forcedUpdate = true;

        if IDEditbox:GetNumber() == animationID then
            IDEditboxFavoriteButton:SetVisual(isFavorite);
        end
    end

    QuickFavoriteButton:SetScript("OnClick", QuickFavoriteButton_OnClick);
    QuickFavoriteButton:SetIconSize(16);
end

local sort = table.sort;

local function SortFunc(a, b)
    --favorite, id -
    if a[2] ~= b[2] then
        return a[2]
    else
        return a[1] < b[1]
    end
end

function NarciAnimationBrowserMixin:RefreshList()
    --{id, name, isFavorite}
    if #self.availableAnimations > 1 then
        sort(self.availableAnimations, SortFunc);
    end
    After(0, function()
        self:UpdateButtons();
    end)
end

function NarciAnimationBrowserMixin:UpdateButtons()
    local numResults = #self.availableAnimations;

    local content = {};
    local buttonHeight = 16;
    local top, bottom;
    local n = 0;
    local offsetY = 0;

    for k, v in ipairs(self.availableAnimations) do
        n = n + 1;
        top = offsetY;
        bottom = offsetY + buttonHeight;
        content[n] = {
            dataIndex = n,
            templateKey = "AnimationButton",
            setupFunc = function(obj)
                obj:SetAnimationInfo(v[1]);
            end,
            top = top,
            bottom = bottom,
        };
        offsetY = bottom;
    end

    self.ScrollView:SetContent(content);
    self.Editbox:SetNumResults(numResults);

    QuickFavoriteButton:Hide();
end

function NarciAnimationBrowserMixin:RefreshFavorite(animationID)
    self.forcedUpdate = true;

    if self:IsShown() and self.ScrollView then
        self.ScrollView:CallObjectMethod("AnimationButton", "UpdateFavorite");
    end
end

function NarciAnimationBrowserMixin:Open()
    local animExpand = self.animExpand;
    animExpand.fromHeight = self:GetHeight();
    animExpand.toHeight = 150;      --Full Height
    animExpand:Show();
    FadeFrame(self, 0.2, 1);
    self.ExpandArrow:SetTexCoord(0, 1, 0, 1);
end

function NarciAnimationBrowserMixin:Close(noAnimation)
    if noAnimation then
        self:Hide();
        self:SetAlpha(0);
        self:SetHeight(8);
    else
        local animExpand = self.animExpand;
        animExpand.fromHeight = self:GetHeight();
        animExpand.toHeight = 8;        --Collapsed Height
        animExpand:Show();
        FadeFrame(self, 0.25, 0);
    end
    self.ExpandArrow:SetTexCoord(0, 1, 1, 0);
end

function NarciAnimationBrowserMixin:Toggle()
    if self.animExpand:IsShown() then
        return
    end

    if self:IsShown() then
        self:Close();
    else
        if not self.isLoaded then
            self.isLoaded = true;
            if NarciConstants and NarciConstants.Animation and NarciConstants.Animation.MaxAnimationID then
                DataProvider.maxAnimID = NarciConstants.Animation.MaxAnimationID;
            end
        end

        if self.forcedUpdate then
            self.forcedUpdate = nil;
            self:BuildListForModel(true);
        else
            self:BuildListForModel();
        end

        self:Open();
    end
end

function NarciAnimationBrowserMixin:BuildListForModel(forcedUpdate)
    local model = Narci:GetActiveActor();
    local fileID = model:GetModelFileID();
    if fileID ~= self.lastFileID or forcedUpdate then
        self.lastFileID = fileID;
        self.availableAnimations = DataProvider:GetAvailableAnimationsForModel(model, forcedUpdate) or {};
        self.Editbox:ClearText();
        self:RefreshList();
    end
end

function NarciAnimationBrowserMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    if self.Init then
        self:Init();
    end
    DataProvider.activeModel = Narci:GetActiveActor();
end

function NarciAnimationBrowserMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:Close(true);
end

function NarciAnimationBrowserMixin:OnEvent(event)
    if event == "GLOBAL_MOUSE_DOWN" then
        if not self:IsMouseOver(0, -20, 0, 0) then
            if not self.animExpand:IsShown() then
                self:Close();
            end
        end
    end
end

function NarciAnimationBrowserMixin:OnMouseDown()

end

function NarciAnimationBrowserMixin:SearchAnimation(keyword)
    keyword = string.gsub(keyword, "^%s+", "");  --trim left
    if keyword and keyword ~= "" then
        self.availableAnimations = NarciAnimationInfo.SearchByName(keyword);
        self:RefreshList();
    else
        self:BuildListForModel(true);
    end
end

--------------------------------------------------
NarciAnimationSearchBoxMixin = CreateFromMixins(NarciSearchBoxSharedMixin);

function NarciAnimationSearchBoxMixin:PostLoad()
    self:OnLoad();
    self.onSearchFunc = function(word) BrowserFrame:SearchAnimation(word); end;
    self.NoMatchText:SetPoint("TOP", self, "BOTTOM", -14, -4);
end

function NarciAnimationSearchBoxMixin:OnShow()
    if self.numResults then
        self.DefaultText:SetText(string.format(Narci.L["Available Count"], self.numResults));
        self.DefaultText.FadeOut:Play();
    end
    self:SetFocus();
end

function NarciAnimationSearchBoxMixin:OnHide()
    self:StopAnimating();
    self.delayedSearch:Hide();
end

function NarciAnimationSearchBoxMixin:OnEnter()
    self.DefaultText:SetTextColor(0.88, 0.88, 0.88);
end

function NarciAnimationSearchBoxMixin:OnLeave()
    if not self:IsMouseOver() then
        self.DefaultText:SetTextColor(0.72, 0.72, 0.72);
    end
end

function NarciAnimationSearchBoxMixin:OnTextChanged(isUserInput)
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

    if isUserInput then
        self:Search(true);
    end
end

function NarciAnimationSearchBoxMixin:ClearText(reset)
    self:SetText("");
    self.DefaultText:Show();
    self.EraseButton:Hide();
    if reset then
        --Unfilter search
        self:Search(true);
    end
end

function NarciAnimationSearchBoxMixin:Search(on)
    self.delayedSearch:Hide();
    if on then
        self.delayedSearch:Show();
    end
end

function NarciAnimationSearchBoxMixin:SetNumResults(numResults)
    self.numResults = numResults;
    self.DefaultText:SetText(string.format(Narci.L["Available Count"], numResults));
    self.NoMatchText:SetShown(numResults == 0);
    if self:GetText() == "" and self:IsShown() then
        self.DefaultText.FadeOut:Play();
    end
end