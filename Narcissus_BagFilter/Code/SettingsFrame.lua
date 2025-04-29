local _, addon = ...

local NineSliceUtil = addon.NineSliceUtil;
local API = addon.API;
local SettingFunctions = addon.SettingFunctions;

local MainFrame;
local CategoryButtons;
local CategoryOffsets;
local NUM_CATE;
local DB;
local SettingButtons = {};
local SubHeaders = {};

local FRAME_WDITH = 640;
local FRAME_HEIGHT = 360;
local LEFT_WIDTH = FRAME_WDITH - FRAME_HEIGHT * 4/3;



local function SetTextColorByID(fontString, id)
    if id == 3 then
        fontString:SetTextColor(0.95, 0.9, 0.6);
    elseif id == 2 then
        fontString:SetTextColor(0.6, 0.59, 0.5);
    else
        fontString:SetTextColor(0.77, 0.76, 0.62);
    end
end


local function SetCheckBoxState(checkbox, selected)
    if selected then
        checkbox.Selection:Show();
        checkbox.Border:SetTexCoord(0, 0.25, 0, 1);
    else
        checkbox.Selection:Hide();
        checkbox.Border:SetTexCoord(0.25, 0.5, 0, 1);
    end
    checkbox.selected = selected;
end


local function SetRatioButtonState(radioButton, selected)
    if selected then
        radioButton.Selection:Show();
        radioButton.Border:SetTexCoord(0, 0.25, 0, 1);
    else
        radioButton.Selection:Hide();
        radioButton.Border:SetTexCoord(0.25, 0.5, 0, 1);
    end
    radioButton.selected = selected;
end

local function UpdateRadioButtons(selectedButton)
    local groupID = selectedButton.groupID;

    local buttons = selectedButton:GetParent().radioGroups[groupID];
    if buttons then
        for i, b in ipairs(buttons) do
            if b == selectedButton then
                SetRatioButtonState(b, true);
            else
                SetRatioButtonState(b, false);
            end
        end
    end
end

local function UpdateAllSettingButtons()
    for _, button in pairs(SettingButtons) do
        button:UpdateState();
    end
end

local function SetCategoryEnabled(categoryID, state)
    if not CategoryButtons[categoryID] then
        return
    end

    local disabled = not state;
    local level = CategoryButtons[categoryID].level;
    CategoryButtons[categoryID].DisabledTexture:SetShown(disabled);

    for i = categoryID + 1, #CategoryButtons do
        if CategoryButtons[i].level > level then
            CategoryButtons[i].DisabledTexture:SetShown(disabled);
        else
            break
        end
    end

    for _, button in ipairs(SettingButtons) do
        if button.rootCategoryID == categoryID then
            if not button.alwaysHighlight then
                button:SetParentCategoryDisabled(disabled);
            end
        end
    end

    for _, fontString in ipairs(SubHeaders) do
        if fontString.rootCategoryID == categoryID then
            if not fontString.alwaysHighlight then
                if disabled then
                    SetTextColorByID(fontString, 2);
                else
                    SetTextColorByID(fontString, 1);
                end
            end
        end
    end
end


PictherSettingsSharedButtonMixin = {};

function PictherSettingsSharedButtonMixin:OnEnter()
    SetTextColorByID(self.Label, 3);
end

function PictherSettingsSharedButtonMixin:OnLeave()
    if self.disabled then
        SetTextColorByID(self.Label, 2);
    else
        SetTextColorByID(self.Label, 1);
    end
end

function PictherSettingsSharedButtonMixin:UpdateState()
    if self.buttonType == "checkbox" then
        if self.key then
            SetCheckBoxState(self, DB[self.key]);
        end
    elseif self.buttonType == "radio" then
        if self.key then
            SetRatioButtonState(self, DB[self.key] == self.id);
        end
    end

    if self.onValueChangedFunc then
        self.onValueChangedFunc(self);
    end
end

function PictherSettingsSharedButtonMixin:OnClick()
    if self.buttonType == "checkbox" then
        if self.key then
            local state = not DB[self.key];
            DB[self.key] = state;
            self:UpdateState();
            if self.onClickFunc then
                self.onClickFunc(self, state);
            end
        end
    elseif self.buttonType == "radio" then
        if self.key then
            DB[self.key] = self.id;
            UpdateRadioButtons(self);
            if self.onClickFunc then
                self.onClickFunc(self, self.id);
            end
            if self.onValueChangedFunc then
                self.onValueChangedFunc(self);
            end
        end
    end
end

function PictherSettingsSharedButtonMixin:SetLabelText(text)
    self.Label:SetText(text);
    local textWidth = self.Label:GetWrappedWidth();
    if textWidth then
        if textWidth > 120 then
            self:SetWidth(textWidth + 22);
        end
    end
end

function PictherSettingsSharedButtonMixin:SetParentCategoryDisabled(isDisabled)
    if isDisabled then
        SetTextColorByID(self.Label, 2);
        self.Border:SetVertexColor(0.80, 0.80, 0.80);
        self.Selection:SetVertexColor(0.80, 0.80, 0.80);
        self.disabled = true;
    else
        SetTextColorByID(self.Label, 1);
        self.Border:SetVertexColor(1, 1, 1);
        self.Selection:SetVertexColor(1, 1, 1);
        self.disabled = nil;
    end
end


local function ItemSearchToggle_OnClick(self, state)
    SettingFunctions.SetEnableSearchSuggestion(state)
end

local function ItemSearchToggle_OnValueChanged(self)
    if self.categoryID then
        SetCategoryEnabled(self.categoryID, self.selected);
    end
end


local function ItemSearchDirectionButton_OnClick(self, index)
    SettingFunctions.SetPopupDirection(index);
end

local function ItemSearchDirectionButton_OnValueChanged(self)
    if self.selected then
        if self.id == 1 then
            self.preview:SetTexCoord(0, 0.5, 0, 0.8125);
        else
            self.preview:SetTexCoord(0.5, 1, 0, 0.8125)
        end
    end
end

local function AutoFilterMail_OnClick(self, state)
    SettingFunctions.AutoFilterMail(state);
end

local function AutoFilterAuction_OnClick(self, state)
    SettingFunctions.AutoFilterAuction(state);
end

local function AutoFilterGem_OnClick(self, state)
    SettingFunctions.AutoFilterGem(state);
end


local Categories = {
    --{ CategoryName }
    {name = "Bag Filter", level = 0,
        widgets = {
            {type = "header", level = 0, text = "Bag Filter"},
            {type = "checkbox", level = 1, key = "SearchSuggestEnable", text = "Enable Search Suggetion and Auto Filter", onClickFunc = ItemSearchToggle_OnClick, onValueChangedFunc = ItemSearchToggle_OnValueChanged, alwaysHighlight = true} ,
        },
    },

    {name = "Position", level = 1,
        widgets = {
            {type = "header", level = 0, text = "Position"},
            {type = "text", level = 1, text="Place the window..."},
            {type = "radio", level = 2, key = "SearchSuggestDirection", texts = {"Below Search Box", "Above Search Box"}, onClickFunc = ItemSearchDirectionButton_OnClick,
                previewImage = "PopupPositionPreview", previewWidth = 200, previewHeight = 162, previewOffsetY = 28, onValueChangedFunc = ItemSearchDirectionButton_OnValueChanged,
            },
        },
    },

    {name = "Auto Filter", level = 1,
        widgets = {
            {type = "header", level = 0, text = "Auto Filter"},
            {type = "text", level = 1, text="Automatically filters items when you:"},
            {type = "checkbox", level = 2, key = "AutoFilterMail", text = "Send Mails", onClickFunc = AutoFilterMail_OnClick},
            {type = "checkbox", level = 2, key = "AutoFilterAuction", text = "Create Auctions", onClickFunc = AutoFilterAuction_OnClick},
            {type = "checkbox", level = 2, key = "AutoFilterGem", text = "Socket Items", onClickFunc = AutoFilterGem_OnClick},
        },
    },

    {name = "Credits", level = 0, },
    {name = "About", level = 0,
        widgets = {
            {type = "header", level = 0, text = "About"},
        },
    },
};

local CreditList = {};

function CreditList:CreateList(parent, fromOffsetY)
    local active = {"Albator S.", "Solanya", "Erik Shafer", "Celierra&Darvian", "Pierre-Yves Bertolus", "Terradon", "Alex Boehm", "Miroslav Kovac", "Ryan Zerbin", "Nisutec"};
    local inactive = {"Elexys", "Ben Ashley", "Knightlord", "Brian Haberer", "Andrew Phoenix", "Nantangitan", "Blastflight", "Lars Norberg", "Valnoressa", "Nimrodan", "Brux",
        "Karl", "Webb", "acein", "Christian Williamson", "Tzutzu", "Anthony Cordeiro", "Nina Recchia", "heiteo", "Psyloken", "Jesse Blick", "Victor Torres"};
    local special = {"Marlamin | WoW.tools", };

    local numTotal = #active;
    local mergedList = active;
    local totalHeight;

    for i = 1, #inactive do
        numTotal = numTotal + 1;
        mergedList[numTotal] = inactive[i];
    end

    local upper = string.upper;

    table.sort(mergedList, function(a, b)
        return upper(a) < upper(b)
    end);


    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    header:SetPoint("TOP", parent, "TOP", 0, fromOffsetY);
    header:SetText(string.upper("Patrons"));
    SetTextColorByID(header, 2);

    totalHeight = header:GetHeight() + 12;
    fromOffsetY = fromOffsetY - totalHeight;

    local numRow = math.ceil(numTotal/3);

    local sidePadding = 30;
    self.sidePadding = sidePadding;
    self.parent = parent;

    local colWidth = (parent:GetWidth() - sidePadding*2) / 3;
    local text;
    local fontString;
    local height;

    local i = 0;
    local maxHeight = 0;
    local totalTextWidth = 0;
    local width = 0;

    local fontStrings = {};

    for col = 1, 3 do
        fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        fontString:SetWidth(colWidth);
        fontString:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, fromOffsetY);
        fontString:SetJustifyH("LEFT");
        fontString:SetJustifyV("TOP");
        fontString:SetSpacing(8);
        fontStrings[col] = fontString;
        SetTextColorByID(fontString, 1);

        text = nil;
        for row = 1, numRow do
            i = i + 1;
            if mergedList[i] then
                if text then
                    text = text .. "\n" .. mergedList[i];
                else
                    text = mergedList[i];
                end
            end
        end

        fontString:SetText(text);
        height = fontString:GetHeight();
        width = fontString:GetWrappedWidth();
        totalTextWidth = totalTextWidth + width;

        if height > maxHeight then
            maxHeight = height;
        end
    end

    self.totalTextWidth = totalTextWidth;
    self.fontStrings = fontStrings;
    self.offsetY = fromOffsetY;

    fromOffsetY = fromOffsetY - maxHeight - 48;

    local header2 = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    header2:SetPoint("TOP", parent, "TOP", 0, fromOffsetY);
    header2:SetText(string.upper("special thanks"));
    SetTextColorByID(header2, 2);


    text = nil;
    for i = 1, #special do
        if i == 1 then
            text = special[i];
        else
            text = text .. "\n" .. special[i];
        end
    end

    fromOffsetY = fromOffsetY - header2:GetHeight() - 12;

    fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    fontString:SetPoint("TOPLEFT", parent, "TOPLEFT", sidePadding, fromOffsetY);
    fontString:SetJustifyH("LEFT");
    fontString:SetJustifyV("TOP");
    fontString:SetSpacing(8);
    fontString:SetText(text);
    SetTextColorByID(fontString, 1);

    self.specialNames = fontString;
    self.specialNamesOffsetY = fromOffsetY;

    totalHeight = math.floor(header:GetTop() - fontString:GetBottom() + 0.5 + 36);

    self:UpdateAlignment();

    return totalHeight
end

function CreditList:UpdateAlignment()
    if self.fontStrings then
        local offsetX = self.sidePadding;
        local parentWidth = MainFrame.ScrollFrame:GetWidth();

        local gap = (parentWidth - self.sidePadding*2 - self.totalTextWidth) / 2;
        for col = 1, 3 do
            self.fontStrings[col]:ClearAllPoints();
            self.fontStrings[col]:SetPoint("TOPLEFT", self.parent, "TOPLEFT", offsetX, self.offsetY);
            offsetX = offsetX + self.fontStrings[col]:GetWrappedWidth() + gap;
        end

        local specialNameWidth = self.specialNames:GetWrappedWidth();
        offsetX = (parentWidth - specialNameWidth) * 0.5;
        self.specialNames:SetPoint("TOPLEFT", self.parent, "TOPLEFT", offsetX, self.specialNamesOffsetY);
    end
end


local function CreateAboutTab(parent, fromOffsetY)
    local offsetX = 18;
    local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    fontString:SetSpacing(8);
    fontString:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, fromOffsetY);
    fontString:SetJustifyH("LEFT");
    fontString:SetJustifyV("TOP");

    local version, releaseDate, timeDiff = addon.GetVersionInfo();
    local text = "Version: "..version .. "\nDate: "..releaseDate;
    if timeDiff then
        text = text .." ("..timeDiff..")";
    end
    text = text .. "\nDeveloper: Peterodox";

    fontString:SetText(text);
    SetTextColorByID(fontString, 1);
end


local function HighlightCategoryButton(id)
    for i, b in ipairs(CategoryButtons) do
        if i == id then
            b.selected = true;
            SetTextColorByID(b.ButtonText, 3);
        else
            if b.selected then
                b.selected = nil;
                SetTextColorByID(b.ButtonText, 2);
            end
        end
    end
end

local function SelectCategory(id)
    HighlightCategoryButton(id);
    MainFrame.ScrollFrame:SetOffset(CategoryOffsets[id] or 0);
end


local function CreateWidget(parent, anchorTo, offsetX, offsetY, widgetData, rootCategoryID)
    local height;
    local widgetType = widgetData.type;
    local obj;

    if widgetType == "header" then
        obj = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        obj:SetJustifyH("LEFT");
        obj:SetJustifyV("TOP");
        obj:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX + ((widgetData.level and widgetData.level * 12) or 0), offsetY);
        obj:SetText(string.upper(widgetData.text));
        SetTextColorByID(obj, 2);
        height = obj:GetHeight();
        height = height + 12;

    elseif widgetType == "text" then
        obj = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        obj:SetJustifyH("LEFT");
        obj:SetJustifyV("TOP");
        obj:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX + ((widgetData.level and widgetData.level * 12) or 0), offsetY);
        obj:SetText(widgetData.text);
        SetTextColorByID(obj, 1);
        height = obj:GetHeight();
        height = height + 12;
        table.insert(SubHeaders, obj);

    elseif widgetType == "radio" then
        local numButtons = #widgetData.texts;

        local preview;
        local sectorHeight;

        if widgetData.previewImage then
            preview = parent:CreateTexture(nil, "ARTWORK");
            preview:SetSize(widgetData.previewWidth, widgetData.previewHeight);
            preview:SetPoint("TOPRIGHT", anchorTo, "TOPRIGHT", -24, offsetY + (widgetData.previewOffsetY or 0));
            preview:SetTexture("Interface\\AddOns\\Pitcher\\Art\\Settings\\"..widgetData.previewImage);
            sectorHeight = widgetData.previewHeight - (widgetData.previewOffsetY or 0);
        end

        if not parent.radioGroups then
            parent.radioGroups = {};
        end

        local groupID = #parent.radioGroups + 1;
        parent.radioGroups[groupID] = {};

        for i = 1, numButtons do
            obj = CreateFrame("Button", nil, parent, "PitcherSettingsRadioButtonTemplate");
            table.insert(SettingButtons, obj);
            obj:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX + ((widgetData.level and widgetData.level * 12) or 0), offsetY + (1 - i) * 28);
            obj.groupID = groupID;
            obj.id = i;
            obj.key = widgetData.key;
            obj.rootCategoryID = rootCategoryID;
            obj:SetLabelText(widgetData.texts[i]);
            obj.preview = preview;
            SetTextColorByID(obj.Label, 1);
            parent.radioGroups[groupID][i] = obj;
            obj.onClickFunc = widgetData.onClickFunc;
            obj.onValueChangedFunc = widgetData.onValueChangedFunc;
            --NineSliceUtil.AddPixelPerfectTexture(MainFrame, obj.Border, 32, 32);
        end

        height = 24 * numButtons;

        if sectorHeight and height < sectorHeight then
            height = sectorHeight;
        end

        height = height + 12;

    elseif widgetType == "checkbox" then
        obj = CreateFrame("Button", nil, parent, "PitcherSettingsCheckBoxTemplate");
        table.insert(SettingButtons, obj);
        obj:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", offsetX + ((widgetData.level and widgetData.level * 12) or 0), offsetY);
        obj.key = widgetData.key;
        obj:SetLabelText(widgetData.text);
        SetTextColorByID(obj.Label, 1);
        obj.onClickFunc = widgetData.onClickFunc;
        obj.onValueChangedFunc = widgetData.onValueChangedFunc;
        --NineSliceUtil.AddPixelPerfectTexture(MainFrame, obj.Border, 32, 32);

        height = 24;
        height = height + 4;

    elseif widgetType == "slider" then
        height = 0;
    end

    if obj then
        obj.alwaysHighlight = widgetData.alwaysHighlight;
    end

    return obj, math.floor(height + 0.5)
end


local function CategoryButton_OnClick(self)
    SelectCategory(self.id);
end

local function CategoryButton_OnEnter(self)
    SetTextColorByID(self.ButtonText, 3);
end

local function CategoryButton_OnLeave(self)
    if not self.selected then
        SetTextColorByID(self.ButtonText, 2);
    end
end


local function CloseButton_OnEnter(self)
    self.Cross:SetVertexColor(0.95, 0.9, 0.6)
end

local function CloseButton_OnLeave(self)
    self.Cross:SetVertexColor(0.6, 0.59, 0.5)
end

local function CloseButton_OnMouseDown(self)
    self.Cross:SetScale(0.8);
    self.Texture:SetTexCoord(0.375, 0.75, 0, 0.75);
end

local function CloseButton_OnMouseUp(self)
    self.Cross:SetScale(1);
    self.Texture:SetTexCoord(0, 0.375, 0, 0.75);
end

local function CloseButton_OnClick(self)
    MainFrame:CloseUI();
end


local function FindCurrentCategory(scrollFrame)
    local offset = scrollFrame:GetOffset() + 32;
    local matchID;

    for i = NUM_CATE, 1, -1 do
        if offset >= CategoryOffsets[i] then
            matchID = i;
            break
        end
    end

    if matchID ~= scrollFrame.matchID then
        scrollFrame.matchID = matchID;
        HighlightCategoryButton(matchID);
    end
end


local function SetupFrame()
    if CategoryButtons then return end;

    DB = PitcherSharedDB;

    local texPath = "Interface\\AddOns\\Pitcher\\Art\\Settings\\";

    local f = MainFrame;

    f:SetSize(FRAME_WDITH, FRAME_HEIGHT);

    f.CategoryFrame:SetWidth(LEFT_WIDTH);
    f.ScrollFrame.ScrollChild:SetWidth(FRAME_WDITH - LEFT_WIDTH);

    f.Divider = f.OverlayFrame:CreateTexture(nil, "OVERLAY", nil, 1);
    f.Divider:SetPoint("TOP", f.CategoryFrame, "TOPRIGHT", 0, -1);
    f.Divider:SetPoint("BOTTOM", f.CategoryFrame, "BOTTOMRIGHT", 0, 1);
    f.Divider:SetWidth(32);
    f.Divider:SetTexture(texPath.."DividerVertical");

    NineSliceUtil.SetUp(f.BorderFrame, "chamfer8Border", "backdrop");
    NineSliceUtil.SetUp(f.BackgroundFrame, "chamfer8Background", "backdrop");
    NineSliceUtil.AddPixelPerfectTexture(f.BorderFrame, f.Divider, 32);


    local CloseButton = CreateFrame("Button", nil, f.OverlayFrame);
    f.CloseButton = CloseButton;
    CloseButton:SetSize(36, 36);
    CloseButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0);

    CloseButton.Texture = CloseButton:CreateTexture(nil, "BACKGROUND");
    CloseButton.Texture:SetSize(36, 36);
    CloseButton.Texture:SetPoint("CENTER", CloseButton, "CENTER", 0, 0);
    CloseButton.Texture:SetTexture(texPath.."CloseButton");
    CloseButton.Texture:SetTexCoord(0, 0.375, 0, 0.75);

    CloseButton.Cross = CloseButton:CreateTexture(nil, "OVERLAY");
    CloseButton.Cross:SetSize(18, 18);
    CloseButton.Cross:SetPoint("CENTER", CloseButton, "CENTER", 0, 0);
    CloseButton.Cross:SetTexture(texPath.."CloseButton");
    CloseButton.Cross:SetTexCoord(0.8125, 1, 0, 0.375);

    CloseButton:SetScript("OnEnter", CloseButton_OnEnter);
    CloseButton:SetScript("OnLeave", CloseButton_OnLeave);
    CloseButton:SetScript("OnMouseDown", CloseButton_OnMouseDown);
    CloseButton:SetScript("OnMouseUp", CloseButton_OnMouseUp);
    CloseButton:SetScript("OnClick", CloseButton_OnClick);

    CloseButton_OnMouseUp(CloseButton);
    CloseButton_OnLeave(CloseButton);

    CategoryButtons = {};
    CategoryOffsets = {};

    local numCate = #Categories;
    local bottomCateIndex = numCate - 2;
    local frameHeight = math.floor(f.ScrollFrame:GetHeight() + 0.5);

    local PADDING_H = 18;
    local PADDING_V = 12;
    local CATE_BUTTON_WIDTH = LEFT_WIDTH;
    local CATE_BUTTON_HEIGHT = 24;
    local CATE_TEXCOORD_X = CATE_BUTTON_WIDTH / (512*CATE_BUTTON_HEIGHT/32);
    local LEVEL_OFFSET = 12;
    local CATE_OFFSET = 36;

    local obj, height;
    local totalScrollHeight = PADDING_H;
    local categoryHeight = 0;
    local rootCategoryID;

    for i, cateData in ipairs(Categories) do
        categoryHeight = 0;

        obj = CreateFrame("Button", nil, f.CategoryFrame, "PitcherSettingsCategoryButtonTemplate");
        CategoryButtons[i] = obj;
        CategoryOffsets[i] = totalScrollHeight - PADDING_H;

        obj.id = i;
        obj.level = cateData.level;

        if cateData.level == 0 then
            rootCategoryID = i;
        end
        obj.rootCategoryID = rootCategoryID;

        obj:SetScript("OnClick", CategoryButton_OnClick);
        obj:SetScript("OnEnter", CategoryButton_OnEnter);
        obj:SetScript("OnLeave", CategoryButton_OnLeave);

        obj:SetWidth(CATE_BUTTON_WIDTH);
        obj:SetHitRectInsets(0, 8, 0, 0);
        obj.DisabledTexture:SetTexCoord(0, CATE_TEXCOORD_X, 0, 0.5);
        obj.ButtonText:SetText(cateData.name);
        obj.ButtonText:SetPoint("LEFT", obj, "LEFT", PADDING_H + LEVEL_OFFSET*cateData.level, 0);
    
        if i > bottomCateIndex then
            obj:SetPoint("BOTTOMLEFT", f.CategoryFrame, "BOTTOMLEFT", 0, PADDING_V + (numCate - i) * CATE_BUTTON_HEIGHT);
            if i == numCate then

            else
                --Credit List
                totalScrollHeight = math.ceil(totalScrollHeight/frameHeight) * frameHeight;
                CategoryOffsets[i] = totalScrollHeight - PADDING_H;

                height = CreditList:CreateList(f.ScrollFrame.ScrollChild, -totalScrollHeight);
                totalScrollHeight = totalScrollHeight + height;
            end
        else
            obj:SetPoint("TOPLEFT", f.CategoryFrame, "TOPLEFT", 0, -PADDING_V + (1 - i) * CATE_BUTTON_HEIGHT);
        end
    
        SetTextColorByID(obj.ButtonText, 2);

        if cateData.widgets then
            for j = 1, #cateData.widgets do
                obj, height = CreateWidget(f.ScrollFrame.ScrollChild, f.ScrollFrame.ScrollChild, PADDING_H, -totalScrollHeight, cateData.widgets[j], rootCategoryID);
                categoryHeight = categoryHeight + height;
                totalScrollHeight =  totalScrollHeight + height;
                if obj then
                    obj.categoryID = i;
                    obj.rootCategoryID = rootCategoryID;
                end
            end
        end

        if i == numCate then
            --About List
            CreateAboutTab(f.ScrollFrame.ScrollChild, -totalScrollHeight)
        end

        totalScrollHeight = totalScrollHeight + CATE_OFFSET;
    end

    API.SetupScrollFrame(f.ScrollFrame);
    NUM_CATE = #CategoryOffsets;
    local scrollRange = CategoryOffsets[ NUM_CATE ];
    f.ScrollFrame:SetScrollRange(scrollRange);
    f.ScrollFrame:SetValueStep(80);
    f.ScrollFrame:SetLessFrequentPositionFunc(FindCurrentCategory);

    CategoryButtons[1]:Click();
    UpdateAllSettingButtons();

    Categories = nil;
end


PitcherSettingsFrameMixin = {};

function PitcherSettingsFrameMixin:OnLoad()
    MainFrame = self;

    --Create UI on Interface Options Panel (ESC-Interface)
    local panel = Pitcher_InterfaceOptionsPanel;
    panel.name = "Pitcher";
    panel.Header:SetText("Pitcher");
    --panel.Description:SetText(L["Interface Options Tab Description"]);
    
    panel:HookScript("OnShow", function(f)
        if f:IsVisible() then
            MainFrame:ShowUI("blizzard");
        end
    end);
    
    panel:HookScript("OnHide", function(f)
        MainFrame:CloseUI();
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Pitcher");
    Settings.RegisterAddOnCategory(category);
end

function PitcherSettingsFrameMixin:OnShow()

end

function PitcherSettingsFrameMixin:ShowUI(mode)
    SetupFrame();

    mode = mode or "default";
    if mode ~= self.mode then
        if mode == "blizzard" then
            self:AnchorToInterfaceOptions();
        else
            self:ResetAnchor();
        end
        self.mode = mode;
    end

    self:Show();
end

function PitcherSettingsFrameMixin:CloseUI()
    self:Hide();
end

function PitcherSettingsFrameMixin:ResetAnchor()
    self:ClearAllPoints();
    self:SetParent(UIParent);
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    self:SetSize(FRAME_WDITH, FRAME_HEIGHT);
    self.ScrollFrame.ScrollChild:SetWidth(FRAME_WDITH - LEFT_WIDTH);
    self.CloseButton:Show();
    self.BackgroundFrame:Show();
    self.BorderFrame:Show();
    self.Background:Hide();
    CreditList:UpdateAlignment();
end

function PitcherSettingsFrameMixin:AnchorToInterfaceOptions()
    local container = Pitcher_InterfaceOptionsPanel;
    if not container then return end;

    self:ClearAllPoints();
    local containerHeight = container:GetHeight();
    local containerWidth = container:GetWidth();
    local padding = 4;
    self:SetSize(containerWidth -2*padding, containerHeight - 2*padding);
    self:SetParent(container);
    self:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", padding, padding);
    local scrollFrameWidth = self.ScrollFrame:GetWidth();
    self.ScrollFrame.ScrollChild:SetWidth(scrollFrameWidth);
    self.CloseButton:Hide();
    self.BackgroundFrame:Hide();
    self.BorderFrame:Hide();
    self.Background:Show();
    CreditList:UpdateAlignment();
end