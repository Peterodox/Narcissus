local _, addon = ...

local API = addon.BagItemSearchAPI;
local DataProvider = addon.BagItemSearchDataProvider;
local outQuart = addon.EasingFunctions.outQuart;
local BagProcessor = addon.BagProcessor;
local ItemFilter = addon.ItemFilter;
local PrimarySearchBox = addon.PrimarySearchBox;

local GetMouseFocus = NarciAPI.TransitionAPI.GetMouseFocus;
local IsMouseButtonDown = IsMouseButtonDown;
local L = Narci.L;

local PAGE_FORMAT = COLLECTION_PAGE_NUMBER or "Page %s / %s";

local MainFrame, SearchBoxLabel;
local BUTTON_HEIGHT = 20;
local BUTTONS_PER_PAGE = 10;


local TradeskillButtons;

local TRADE_SKILL_DATA = {
    --tradeSkillID
    171,      --Alchemy
    164,      --Blacksmithing
    333,      --Enchanting
    202,      --Engineering
    182,      --Herbalism
    773,      --Inscription
    755,      --Jewelcrafting
    165,      --Leatherworking
    186,      --Mining
    393,      --Skinning
    197,      --Tailoring
    794,      --Archaeology
    185,      --Cooking
    356,      --Fishing
    129,      --First Aid
};


local PopupButtonPool = {};
PopupButtonPool.buttons = {};

function PopupButtonPool:Flush()
    self.i = 0;
    for i = 1, #self.buttons do
        self.buttons[i]:Hide();
    end
end

function PopupButtonPool:Accquire()
    self.i = self.i + 1;

    if not self.buttons[self.i] then
        self.buttons[self.i] = CreateFrame("Button", nil, MainFrame.SuggestionTab.ButtonContainer, "NarciBagItemSearchPopupButtonTemplate");
        self.buttons[self.i]:SetPoint("TOPLEFT", MainFrame.SuggestionTab.ButtonContainer, "TOPLEFT", 0, -6 + (1 - self.i)*BUTTON_HEIGHT);
    end

    return self.buttons[self.i]
end

function PopupButtonPool:GetNumShown()
    return self.i
end



local function IsMouseOverButtons()
    local obj = GetMouseFocus();
    return (obj and obj:IsObjectType("Button"));
end


local function SetTextColorByName(fontString, colorName)
    local r, g, b = API.GetColorByName(colorName);
    fontString:SetTextColor(r, g, b);
end


---- Sort Categoroes ----
local function SortByNameA2Z(name1, name2)
    return name1 < name2
end

local function SortByNameInInfoA2Z(info1, info2)
    return info1[1] < info2[1]
end

local function SortFunc_SimpleA2Z(tbl)
    table.sort(tbl, SortByNameInInfoA2Z);
    return tbl
end

local function SortFunc_Grouping(tbl)
    --e.g. (Blue Punchcard, Red Punchcard, Yellow Punchcard) move together
    --Only works in English: adjacent + noun

    local match = string.match;
    local tinsert = table.insert;
    local tsort = table.sort;

    tsort(tbl, SortByNameInInfoA2Z);

    local keywords = {};
    local groupByKeywords = {};
    local name;
    local lastWord;

    for i = 1, #tbl do
        name = tbl[i][1];
        lastWord = match(name, "%s([%S]+)$");

        if not lastWord then
            lastWord = name;
        end

        if not groupByKeywords[lastWord] then
            groupByKeywords[lastWord] = {};
            tinsert(keywords, lastWord);
        end

        tinsert(groupByKeywords[lastWord], tbl[i]);
    end

    local function SortByKeyword(k1, k2)
        local l1 = #groupByKeywords[k1];
        local l2 = #groupByKeywords[k2];

        if l1 == 1 then
            if l2 == 1 then
                return groupByKeywords[k1][1][1] < groupByKeywords[k2][1][1]
            else
                return groupByKeywords[k1][1][1] < k2
            end
        else
            if l2 == 1 then
                return k1 < groupByKeywords[k2][1][1]
            else
                return k1 < k2
            end
        end
    end

    tsort(keywords, SortByKeyword);

    local sortedList = {};
    local n = 0;
    local len;

    for i, w in ipairs(keywords) do
        len = #groupByKeywords[w];
        for j = 1, len do
            n = n + 1;
            sortedList[n] = groupByKeywords[w][j];
        end
    end

    return sortedList
end

local SORT_FUNC = SortFunc_SimpleA2Z;


---- Sizing Animation ----
local AnimSizing = CreateFrame("Frame");

local function AnimSizing_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;

    self.h = outQuart(self.t, self.fromH, self.toH, self.d);

    if self.changeW then
        --avoid jittering
        self.w = outQuart(self.t, self.fromW, self.toW, self.d);
    end

    if self.t >= self.d then
        self.w = self.toW;
        self.h = self.toH;
        self:SetScript("OnUpdate", nil);
    end

    MainFrame:SetSize(self.w, self.h);
end

local function IsEqual(v1, v2)
    local diff = v1 - v2;
    if diff < 0 then
        diff = -diff
    end
    return diff < 0.1
end

function AnimSizing:SetNewSize(width, height, instant)
    if instant then
        MainFrame:SetSize(width, height);
        self:SetScript("OnUpdate", nil);
        return
    end

    self.t = 0;
    self.fromW, self.fromH = MainFrame:GetSize();
    self.toW, self.toH = width, height;
    self.w = self.fromW;

    if IsEqual(self.fromW, self.toW) then
        self.changeW = nil;
    else
        self.changeW = true;
    end

    local delta = math.max( math.abs(self.fromW - self.toW), math.abs(self.fromH - self.toH) );
    if delta > 0 then
        self.d = math.max(delta/250, 0.15);
        if self.d > 0.35 then
            self.d = 0.35;
        end
        self:SetScript("OnUpdate", AnimSizing_OnUpdate);
    else
        self:SetScript("OnUpdate", nil);
    end
end


---- Anchoring ----
local AnchorUtil = {};

function AnchorUtil:PlacePopup()
    MainFrame:ClearAllPoints();
    MainFrame:SetPoint(self.point, PrimarySearchBox, self.relativePoint, self.offsetX, self.offsetY);
end

function AnchorUtil:SetDefaultPosition(index)
    if index == 2 then
        --above searchbox
        if self.alignToCenter then
            AnchorUtil.point = "BOTTOM";
            AnchorUtil.relativePoint = "TOP";
            AnchorUtil.offsetX = -4 + 3;
            AnchorUtil.offsetY = 4;
        else
            AnchorUtil.point = "BOTTOMLEFT";
            AnchorUtil.relativePoint = "TOPLEFT";
            AnchorUtil.offsetX = 0;
            AnchorUtil.offsetY = 4;
        end
    else
        --below searchbox
        if self.alignToCenter then
            AnchorUtil.point = "TOP";
            AnchorUtil.relativePoint = "BOTTOM";
            AnchorUtil.offsetX = -4 + 3;
            AnchorUtil.offsetY = -4;
        else
            AnchorUtil.point = "TOPLEFT";
            AnchorUtil.relativePoint = "BOTTOMLEFT";
            AnchorUtil.offsetX = 0;
            AnchorUtil.offsetY = -4;
        end
    end
end

AnchorUtil:SetDefaultPosition(2);



---- Create UI ----
local function CreateTradeskillTab()
    TradeskillButtons = {};

    local GetTradeSkillName = C_TradeSkillUI.GetTradeSkillDisplayName;
    local GetTradeSkillTexture = C_TradeSkillUI.GetTradeSkillTexture;

    local BUTTON_SIZE = 36;
    local PER_ROW = 4;
    local PADDING = 12;
    local HEADER_HEIGHT = 24;

    local container = MainFrame.TradeskillTab;
    local name, icon, button;
    local numButtons = 0;
    local row, col = 1, 0;
    local fromOffsetY = -PADDING - HEADER_HEIGHT;

    for _, skillID in ipairs(TRADE_SKILL_DATA) do
        name = GetTradeSkillName(skillID);
        icon = GetTradeSkillTexture(skillID);
        if name and icon then
            numButtons = numButtons + 1;
            TradeskillButtons[numButtons] = CreateFrame("Button", nil, container, "NarciBagItemSearchPopupCategoryButtonTemplate");
            button = TradeskillButtons[numButtons];
            button.name = name;
            button.Icon:SetTexture(icon);
            col = col + 1;
            if col > PER_ROW then
                row = row + 1;
                col = 1;
            end
            button:SetPoint("TOPLEFT", container, "TOPLEFT", PADDING + BUTTON_SIZE * (col - 1), fromOffsetY + BUTTON_SIZE * (1-row));
        end
    end

    local tabWidth = BUTTON_SIZE * PER_ROW + 2*PADDING;
    local tabHeight = BUTTON_SIZE * row + 2*PADDING + HEADER_HEIGHT;

    container.width = tabWidth;
    container.height = tabHeight;

    container:SetSize(tabWidth, tabHeight);
end



local function CreateStaticCategory()
    local button;

    if API.IsAtAuctionHouse() then
        button = PopupButtonPool:Accquire();
        button:SetButtonAuctionHouse();
        button:Show();
    end

    if API.IsViewingMail() then
        button = PopupButtonPool:Accquire();
        button:SetButtonMail();
        button:Show();
    end

    if API.IsSocketingItem() then
        button = PopupButtonPool:Accquire();
        button:SetButtonGem();
        button:Show();
    end

    if DataProvider:HasAnyTeleportationItem() then
        button = PopupButtonPool:Accquire();
        button:SetButtonTravel();
        button:Show();
    end

    button = PopupButtonPool:Accquire();
    button:SetButtonCraftingReagent();
    button:Show();

    button = PopupButtonPool:Accquire();
    button:SetButtonTradeskills();
    button:Show();
end

local function CreateSearchSuggestion()
    PopupButtonPool:Flush();

    CreateStaticCategory();
    local numButtons = PopupButtonPool:GetNumShown();
    local listLength = numButtons;

    local typeList = {};
    for i = 1, listLength do
        typeList[i] = -1;
    end

    --Create Item Subtext Categories
    local itemSubTypeData, nameList = DataProvider:GetAllItemTypes();
    local sortedList;

    if #itemSubTypeData > 0 then
        sortedList = SORT_FUNC(nameList);

        local data;
        local button;
        for i, info in ipairs(sortedList) do
            data = itemSubTypeData[ info[2] ];
            if data.count > 0 then
                if numButtons < BUTTONS_PER_PAGE then
                    numButtons = numButtons + 1;
                    button = PopupButtonPool:Accquire();
                    button:SetItemSubType(data.text, data.count, data.r, data.g, data.b, data.filter);
                    button:Show();
                end
                listLength = listLength + 1;
                typeList[listLength] = info[2];
            end
        end
    end

    MainFrame.typeList = typeList;

    local maxPage = math.ceil(listLength / BUTTONS_PER_PAGE);
    MainFrame.page = 1;
    MainFrame.maxPage = maxPage;
    local extraHeight;
    if maxPage > 1 then
        MainFrame.SuggestionTab.Header:Show();
        extraHeight = 24;
    else
        MainFrame.SuggestionTab.Header:Hide();
        extraHeight = 0;
    end
    MainFrame:UpdatePage(true);

    --local numButtons = PopupButtonPool:GetNumShown();
    --MainFrame:SetHeight(12 + numButtons*BUTTON_HEIGHT);
    --MainFrame:SetWidth(240);
    AnimSizing:SetNewSize(240, 12 + numButtons*BUTTON_HEIGHT + extraHeight);
end

local function ShowTradeskillTab()
    if not TradeskillButtons then
        CreateTradeskillTab();
    end
    --MainFrame:SetSize(MainFrame.TradeskillTab.width, MainFrame.TradeskillTab.height);
    AnimSizing:SetNewSize(MainFrame.TradeskillTab.width, MainFrame.TradeskillTab.height);
    MainFrame:StopAnimating();
    MainFrame.SuggestionTab:Hide();
    MainFrame.TradeskillTab.AnimIn:Play();
    MainFrame.TradeskillTab:Show();
    MainFrame.TradeskillTab.Header.HeaderText:SetText(TRADESKILLS);

    return true
end

local function ShowSuggestionTab()
    MainFrame:StopAnimating();
    CreateSearchSuggestion();
    MainFrame.TradeskillTab:Hide();
    if not MainFrame.SuggestionTab:IsShown() then
        MainFrame.SuggestionTab.AnimIn:Play();
        MainFrame.SuggestionTab:Show();
    end
    MainFrame.resetCategory = nil;
end



NarciBagItemSearchPopupMixin = {};

function NarciBagItemSearchPopupMixin:OnLoad()
    API.AddToEventListner(self);
    BagProcessor:SetCallbackFrame(self);
    MainFrame = self;
    NarciAPI.NineSliceUtil.SetUp(self.FrameBorder, "brownBorder", "backdrop", -13);
    self:SetAlpha(0);
    self:SetClampedToScreen(true);
    self:SetClampRectInsets(-8, 8, 8, -8);
    self.resetCategory = true;

    self.TradeskillTab.ReturnButton:SetScript("OnClick", ShowSuggestionTab);
end

local function FadeIn_OnUpdate(self, elapsed)
    self.alpha = self.alpha + 5*elapsed;
    if self.alpha >= 1 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
    end
    self:SetAlpha(self.alpha);
end

function NarciBagItemSearchPopupMixin:ShowUI()
    if not self.enabled then
        return
    end

    self.alpha = self:GetAlpha();
    if self.alpha ~= 1 then
        self:SetScript("OnUpdate", FadeIn_OnUpdate);
    end

    if BagProcessor:ProcessDirtyBags() and self.SuggestionTab:IsShown() then
        self.LoadingOverlay:Show();
        AnimSizing:SetNewSize(240, 52, true);
    else
        self.LoadingOverlay:Hide();
        if self.resetCategory then
            ShowSuggestionTab();
        end
    end

    AnchorUtil:PlacePopup();

    self:SetScale(PrimarySearchBox:GetEffectiveScale());
    self:SetFrameStrata("DIALOG");
    self:Show();
end




function NarciBagItemSearchPopupMixin:OnUpdateComplete()
    self.LoadingOverlay:Hide();
    if self:IsShown() and self.SuggestionTab:IsShown() then
        ShowSuggestionTab();
    end
end

function NarciBagItemSearchPopupMixin:HideUI()
    self:Hide();
end

function NarciBagItemSearchPopupMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciBagItemSearchPopupMixin:OnHide()
    self:Hide();
    self:SetAlpha(0);
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:UnregisterEvent("GLOBAL_MOUSE_UP");
end

function NarciBagItemSearchPopupMixin:OnEvent(event, ...)
    if not self.enabled then
        return
    end

    if event == "GLOBAL_MOUSE_DOWN" then
        if not (self:IsMouseOver() and IsMouseOverButtons()) then
            self:HideUI();
        end

    elseif event == "GLOBAL_MOUSE_UP" then
        if not ( self:IsMouseOver() ) then
            self:HideUI();
        end

    elseif event == "MAIL_SHOW" or event == "MAIL_CLOSED" or event == "AUCTION_HOUSE_SHOW" or event == "AUCTION_HOUSE_CLOSED" or event == "ITEM_SOCKETING_FRAME_SHOW" or event == "ITEM_SOCKETING_FRAME_CLOSED" then
        --Mail&AH Open/Closed
        --Controlled by EventListner in API.lua
        self.resetCategory = true;

    elseif event == "SEARCH_CHANGED_MANUALLY" or event == "PRIMARY_BAG_CLOSED" then  --custom event
        self:Hide();
        SearchBoxLabel:Remove();
        ItemFilter.RemoveLastFilter();

    elseif event == "PRIMARY_BAG_OPEN" or event == "SEARCH_CLEARED" then
        ItemFilter.RemoveLastFilter();

    end
end

function NarciBagItemSearchPopupMixin:OnMouseWheel(delta)
    if self.TradeskillTab:IsShown() then return end;

    if delta > 0 then
        if self.page > 1 then
            self.page = self.page - 1;
            --self:UpdatePage();
            self:UpdatePageUsingTransition(1);
        end
    elseif delta < 0 then
        if self.page < self.maxPage then
            self.page = self.page + 1;
            --self:UpdatePage();
            self:UpdatePageUsingTransition(-1);
        end
    end
end

function NarciBagItemSearchPopupMixin:UpdatePage(pageTextOnly)
    self.SuggestionTab.Header.PageText:SetText(string.format(PAGE_FORMAT, self.page, self.maxPage));

    if pageTextOnly then
        return
    end

    PopupButtonPool:Flush();

    local itemSubTypeData, nameList = DataProvider:GetAllItemTypes();
    local typeID, data, button;

    if self.page > 1 then
        local offset = (self.page - 1) * BUTTONS_PER_PAGE;
        for i = 1, BUTTONS_PER_PAGE do
            typeID = self.typeList[i + offset];
            if typeID then
                data = itemSubTypeData[typeID];
                if data.count > 0 then
                    button = PopupButtonPool:Accquire();
                    button:SetItemSubType(data.text, data.count, data.r, data.g, data.b, data.filter);
                    button:Show();
                end
            else
                break
            end
        end
    else
        CreateStaticCategory();
        local numButtons = PopupButtonPool:GetNumShown();
        for i = numButtons + 1, BUTTONS_PER_PAGE do
            typeID = self.typeList[i];
            if typeID then
                data = itemSubTypeData[typeID];
                if data.count > 0 then
                    button = PopupButtonPool:Accquire();
                    button:SetItemSubType(data.text, data.count, data.r, data.g, data.b, data.filter);
                    button:Show();
                end
            else
                break
            end
        end
    end
    
    --[[
    if self.SuggestionTab:IsShown() then
        self.SuggestionTab.ButtonContainer.FadeIn:Stop();
        self.SuggestionTab.ButtonContainer.FadeIn:Play();
    end
    --]]
end

local function OnNextPageTranstionComplete()
    if MainFrame.SuggestionTab:IsShown() then
        MainFrame:UpdatePage();
        MainFrame.SuggestionTab.ButtonContainer.FadeInUp:Play();
    end
end

local function OnPreviousPageTranstionComplete()
    if MainFrame.SuggestionTab:IsShown() then
        MainFrame:UpdatePage();
        MainFrame.SuggestionTab.ButtonContainer.FadeInDown:Play();
    end
end


function NarciBagItemSearchPopupMixin:UpdatePageUsingTransition(direction)
    self.SuggestionTab.ButtonContainer:StopAnimating();

    if direction > 0 then
        self.SuggestionTab.ButtonContainer.FadeOutDown:SetScript("OnFinished", OnPreviousPageTranstionComplete);
        self.SuggestionTab.ButtonContainer.FadeOutDown:Play();
        self.SuggestionTab.ButtonContainer.FadeOutUp:SetScript("OnFinished", nil);
    else
        self.SuggestionTab.ButtonContainer.FadeOutUp:SetScript("OnFinished", OnNextPageTranstionComplete);
        self.SuggestionTab.ButtonContainer.FadeOutUp:Play();
        self.SuggestionTab.ButtonContainer.FadeOutDown:SetScript("OnFinished", nil);
    end
end

NarciBagItemSearchPopupButtonMixin = {};

function NarciBagItemSearchPopupButtonMixin:OnLoad()
    self.Count:SetTextColor(0.5, 0.5, 0.5);
end

function NarciBagItemSearchPopupButtonMixin:OnEnter()
    MainFrame.ButtonHighlight:ClearAllPoints();
    MainFrame.ButtonHighlight:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
    MainFrame.ButtonHighlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
    MainFrame.ButtonHighlight:SetParent(self);
    MainFrame.ButtonHighlight:Show();
end

function NarciBagItemSearchPopupButtonMixin:OnLeave()
    MainFrame.ButtonHighlight:Hide();
end

function NarciBagItemSearchPopupButtonMixin:OnClick()
    local notSearch;

    if self.onClickFunc then
        notSearch = self.onClickFunc();
    else
        --PrimarySearchBox:SetText(self.Name:GetText());
        ItemFilter.SearchKeyword(self.Name:GetText());
    end

    if self.hideUIAfterClick then
        MainFrame:HideUI();
    end

    if notSearch then
        
    else
        SearchBoxLabel:CopyLabelText(self.Name);
    end
end

function NarciBagItemSearchPopupButtonMixin:OnMouseDown()
    self.Name:SetPoint("LEFT", self, "LEFT", 11, 0);
end

function NarciBagItemSearchPopupButtonMixin:OnMouseUp()
    self.Name:SetPoint("LEFT", self, "LEFT", 10, 0);
end

function NarciBagItemSearchPopupButtonMixin:SetItemSubType(name, count, r, g, b, filterKey)
    if filterKey and ItemFilter[filterKey] then
        self.onClickFunc = ItemFilter[filterKey];
    else
        self.onClickFunc = nil;
    end

    self.hideUIAfterClick = true;

    self.Name:SetText(name);
    self.Name:SetTextColor(r, g, b);
    self.Count:SetText(count);
    self.Icon:Hide();
end

function NarciBagItemSearchPopupButtonMixin:SetButtonCraftingReagent()
    self.onClickFunc = nil;
    self.hideUIAfterClick = true;

    self.Name:SetText(L["Item Type Reagent"]);
    --self.Name:SetTextColor(0.4, 0.733, 1);
    SetTextColorByName(self.Name, "LightBrown");
    self.Count:SetText(nil);
    self.Icon:Hide();

    self.Icon:Show();
    self.Icon:SetTexCoord(0.5, 0.625, 0.875, 1);
end

function NarciBagItemSearchPopupButtonMixin:SetButtonTradeskills()
    self.onClickFunc = ShowTradeskillTab;
    self.hideUIAfterClick = nil;

    self.Name:SetText(TRADESKILLS);
    SetTextColorByName(self.Name, "LightBrown");
    self.Icon:Show();
    self.Icon:SetTexCoord(0, 0.125, 0.875, 1);
    self.Count:SetText(nil);
end

function NarciBagItemSearchPopupButtonMixin:SetButtonAuctionHouse()
    self.onClickFunc = ItemFilter.ShowAuctionable;
    self.hideUIAfterClick = true;

    self.Name:SetText(L["Item Type Auctionable"]);
    SetTextColorByName(self.Name, "LightBrown");
    self.Icon:Show();
    self.Icon:SetTexCoord(0.25, 0.375, 0.875, 1);
    self.Count:SetText(nil);
end

function NarciBagItemSearchPopupButtonMixin:SetButtonMail()
    self.onClickFunc = ItemFilter.ShowMailable;
    self.hideUIAfterClick = true;

    self.Name:SetText(L["Item Type Mailable"]);
    SetTextColorByName(self.Name, "LightBrown");
    self.Icon:Show();
    self.Icon:SetTexCoord(0.125, 0.25, 0.875, 1);
    self.Count:SetText(nil);
end


function NarciBagItemSearchPopupButtonMixin:SetButtonTravel()
    self.onClickFunc = ItemFilter.ShowTeleport;
    self.hideUIAfterClick = true;

    self.Name:SetText(L["Item Type Teleportation"]);
    SetTextColorByName(self.Name, "LightBrown");
    self.Icon:Show();
    self.Icon:SetTexCoord(0.375, 0.5, 0.875, 1);
    self.Count:SetText(nil);
end

function NarciBagItemSearchPopupButtonMixin:SetButtonGem()
    self.onClickFunc = ItemFilter.ShowGem;
    self.hideUIAfterClick = true;

    self.Name:SetText(L["Item Type Gems"]);
    SetTextColorByName(self.Name, "LightBrown");
    self.Icon:Show();
    self.Icon:SetTexCoord(0.625, 0.75, 0.875, 1);
    self.Count:SetText(nil);
end


NarciBagItemSearchTradeskillCategoryButtonMixin = {};

function NarciBagItemSearchTradeskillCategoryButtonMixin:OnEnter()
    MainFrame.TradeskillTab.Header.HeaderText:SetText(self.name);

    MainFrame.TradeskillTab.ButtonHighlight:ClearAllPoints();
    MainFrame.TradeskillTab.ButtonHighlight:SetParent(self);
    MainFrame.TradeskillTab.ButtonHighlight:SetPoint("CENTER", self.Icon, "CENTER", 0, 0);
    MainFrame.TradeskillTab.ButtonHighlight:Show();
end

function NarciBagItemSearchTradeskillCategoryButtonMixin:OnLeave()
    MainFrame.TradeskillTab.ButtonHighlight:Hide();
end

function NarciBagItemSearchTradeskillCategoryButtonMixin:OnClick(button)
    if button ~= "LeftButton" then
        ShowSuggestionTab();
        return
    end
    --PrimarySearchBox:SetText(self.name);
    ItemFilter.SearchKeyword(self.name);
    MainFrame:HideUI();

    if SearchBoxLabel.enabled then
        SearchBoxLabel.Text:SetText(self.name);
        SetTextColorByName(SearchBoxLabel.Text, "LightBrown");
    end
end

function NarciBagItemSearchTradeskillCategoryButtonMixin:OnMouseDown()
    self.Icon:SetPoint("CENTER", 0, -1);
    self.Border:SetPoint("CENTER", 0, -1);
end

function NarciBagItemSearchTradeskillCategoryButtonMixin:OnMouseUp()
    self.Icon:SetPoint("CENTER", 0, 0);
    self.Border:SetPoint("CENTER", 0, 0);
end



NarciBagItemSearchBoxLabelMixin = {};

function NarciBagItemSearchBoxLabelMixin:OnLoad()
    SearchBoxLabel = self;

    --If the bag addon uses its own search API (libBagSearch), we put a " " space into the search box instead of the actual keyword.
    --It's short so it won't start that addon's bag search and cause stutter.
    --However, we may need to display some texts in that search box so the user knows a filter is in place 
end

function NarciBagItemSearchBoxLabelMixin:SetEnabled(state)
    if state then
        self.enabled = true;
    else
        self.enabled = nil;
        self.inUse = nil;
        self:Hide();
    end
end

function NarciBagItemSearchBoxLabelMixin:CopyLabelText(fontString)
    if self.enabled then
        self.Text:SetText(fontString:GetText());
        local r, g, b = fontString:GetTextColor();
        self.Text:SetTextColor(r, g, b);
        self.inUse = true;
        self:Show();
    end
end

function NarciBagItemSearchBoxLabelMixin:Remove()
    self.inUse = nil;
    self:Hide();
end

function NarciBagItemSearchBoxLabelMixin:SetParentSearchBox(searchbox)
    if not self.enabled then return end;

    self:ClearAllPoints();
    if searchbox then
        self:SetParent(searchbox);
        local left, right = searchbox:GetTextInsets();
        self:SetPoint("LEFT", searchbox, "LEFT", left, 0);
        self:SetPoint("RIGHT", searchbox, "RIGHT", -right, 0);
        self:SetFrameLevel(searchbox:GetFrameLevel() + 10);
        
        local w, h = searchbox:GetHeight();
        if w and h then
            self:SetHeight(h);
        end

        local font, height, mode = searchbox:GetFont();
        if font and height then
            self.Text:SetFont(font, height, mode);
        end

        if not self.isHooked then
            self.isHooked = true;

            searchbox:HookScript("OnEditFocusGained", function()
                self:Hide();
            end);

            searchbox:HookScript("OnEditFocusLost", function(f)
                if self.inUse and f:GetText() == " " and (not MainFrame:IsMouseOver()) then
                    f:HighlightText(0, 0);
                    self:Show();
                end
            end);

            if searchbox.ClearFocus then
                hooksecurefunc(searchbox, "ClearFocus",  function(f)
                    if self.inUse and f:GetText() == "" then
                        self:Hide();
                    end
                end);
            end

        end
    else
        self:SetParent(UIParent);
        self:SetPoint("TOP", UIParent, "BOTTOM", 0, -16);
    end
end


---- Show Popup by Activate Searchbox ----

local function SearchBox_OnEditFocusGained()
    MainFrame:ShowUI();
end

local function SearchBox_OnEditFocusLost()
    if MainFrame:IsMouseOver() and IsMouseButtonDown() and MainFrame:IsShown() then
        MainFrame:RegisterEvent("GLOBAL_MOUSE_UP");
    else
        MainFrame:HideUI();
    end
end

local function SearchBox_OnHide()
    MainFrame.resetCategory = true;
    if MainFrame:IsShown() then
        MainFrame:HideUI();
        MainFrame:SetWidth(240);
    end
end


---- Settings ----
local function SetPopupPosition(index, db)
    if index == nil then
        index = db["SearchSuggestDirection"];
    end
    AnchorUtil:SetDefaultPosition(index);
end

addon.SettingFunctions.SetItemSearchPopupDirection = SetPopupPosition;

local function SetEnableSearchSuggestion(state, db)
    if state == nil then
        state = db["SearchSuggestEnable"];
    end

    if MainFrame.enabled then
        MainFrame:HideUI();
    end
    MainFrame.enabled = state;

    API.EnableAutoFilter(state);
end

addon.SettingFunctions.SetEnableSearchSuggestion = SetEnableSearchSuggestion;



local function AssginSearchBox(addonName, searchbox, notUsingBlizzardSearch)
    PrimarySearchBox = searchbox;

    if PrimarySearchBox:GetScript("OnEditFocusGained") then
        PrimarySearchBox:HookScript("OnEditFocusGained", SearchBox_OnEditFocusGained);
    else
        PrimarySearchBox:SetScript("OnEditFocusGained", SearchBox_OnEditFocusGained);
    end

    if PrimarySearchBox:GetScript("OnEditFocusLost") then
        PrimarySearchBox:HookScript("OnEditFocusLost", SearchBox_OnEditFocusLost);
    else
        PrimarySearchBox:SetScript("OnEditFocusLost", SearchBox_OnEditFocusLost);
    end

    if PrimarySearchBox:GetScript("OnHide") then
        PrimarySearchBox:HookScript("OnHide", SearchBox_OnHide);
    else
        PrimarySearchBox:SetScript("OnHide", SearchBox_OnHide);
    end

    if notUsingBlizzardSearch then
        SearchBoxLabel:SetEnabled(true);
        SearchBoxLabel:SetParentSearchBox(PrimarySearchBox);
    end

    if addonName == "Blizzard" then
        AnchorUtil.alignToCenter = true;
    end

    SetPopupPosition(nil, NarcissusDB);
end

API.AddSearchBoxAssignee(AssginSearchBox);