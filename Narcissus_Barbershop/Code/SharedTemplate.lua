local _, addon = ...

local GetColorByKey = addon.API.GetColorByKey;


local PIXEL = addon.pixel;
local BUTTON_HEIGHT = 20;


NarciBarberShopSharedTemplateMixin = {};

function NarciBarberShopSharedTemplateMixin:UpdatePixel()
    self.Exclusion:SetTexture(nil);
    self.Exclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");
    self.Exclusion:SetPoint("TOPLEFT", self, "TOPLEFT", PIXEL, -PIXEL);
    self.Exclusion:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -PIXEL, PIXEL);

    if self.GlowExclusion then
        self.GlowExclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");
    end

    self:OnLeave();
end

local function SetObjectColor(object, r, g, b, a)
    if not g then
        r, g, b = GetColorByKey(r);
        a = 1;
    end

    object:SetColorTexture(r, g, b, a);
end

function NarciBarberShopSharedTemplateMixin:SetBorderColor(r, g, b, a)
    SetObjectColor(self.Border, r, g, b, a);
end

function NarciBarberShopSharedTemplateMixin:SetBackgroundColor(r, g, b, a)
    SetObjectColor(self.Background, r, g, b, a);
end

function NarciBarberShopSharedTemplateMixin:OnEnter()
    self:SetBorderColor("focused");
    if self.ButtonText then
        self.ButtonText:SetTextColor(1, 1, 1);
    end
end

function NarciBarberShopSharedTemplateMixin:OnLeave()
    if self.IsEnabled and self:IsEnabled() then
        self:SetBorderColor("grey");
    else
        self:SetBorderColor("disabled");
    end
end

function NarciBarberShopSharedTemplateMixin:OnDisable()
    self:SetBorderColor("disabled");
    if self.ButtonText then
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function NarciBarberShopSharedTemplateMixin:OnEnable()
    self:SetBorderColor("grey");
    if self.ButtonText then
        self.ButtonText:SetTextColor(1, 1, 1);
    end
end

function NarciBarberShopSharedTemplateMixin:OnClick()
    if self.onClickFunc then
        self.onClickFunc(self, self.arg1, self.arg2);
    end
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function NarciBarberShopSharedTemplateMixin:SetButtonText(text)
    if self.ButtonText then
        self.ButtonText:SetText(text);

        local buttonWidth = self.ButtonText:GetWrappedWidth() + 24;
        if buttonWidth < 80 then
            buttonWidth = 80;
        end

        self:SetWidth(buttonWidth);
    end
end

do
    local ChoiceButtonMixin = {};

    function ChoiceButtonMixin:OnEnter()
        if not self.selected then
            local r, g, b = GetColorByKey("focused");
            self.ButtonText:SetTextColor(r, g, b);
        end
    end

    function ChoiceButtonMixin:OnLeave()
        if not self.selected then
            self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
        end
    end

    function ChoiceButtonMixin:OnClick()
        self.owner:SelectChoice(self.index);
        self.owner.onSelectChoice(self.index);
    end


    local function CreateChoiceButton(choiceFrame)
        local button = CreateFrame("Button", nil, choiceFrame);
        button.owner = choiceFrame;
        button.ButtonText = button:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
        button.ButtonText:SetJustifyH("CENTER");
        button.ButtonText:SetPoint("CENTER", button, "CENTER", 0, 0);
        Mixin(button, ChoiceButtonMixin);
        button:SetScript("OnEnter", button.OnEnter);
        button:SetScript("OnLeave", button.OnLeave);
        button:SetScript("OnClick", button.OnClick);
        return button
    end

    local ChoiceFrameMixin = {};

    function ChoiceFrameMixin:SetFrameWidth(width)
        self:SetWidth(width);
        self.frameWidth = width;
    end

    function ChoiceFrameMixin:SetData(data)
        if not self.Label then
            self.Label = self:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
            self.Label:SetJustifyH("LEFT");
            self.Label:SetJustifyV("MIDDLE");
            self.Label:SetPoint("LEFT", self, "LEFT", 0, 0);
            self.Label:SetWidth(self.frameWidth*0.4 - 12);
            self.Label:SetTextColor(0.5, 0.5, 0.5);
        end

        self.Label:SetText(data.label);

        if data.tooltip then
            if not self.InfoButton then
                self.InfoButton = CreateFrame("Frame", nil, self, "NarciBarberShopInfoButtonTemplate");
            end
            self.InfoButton:ClearAllPoints();
            self.InfoButton:SetPoint("LEFT", self.Label, "LEFT", self.Label:GetWrappedWidth() + 5, 0);
            self.InfoButton.tooltipText = data.tooltip;
        elseif self.InfoButton then
            self.InfoButton:Hide();
        end

        if not self.choiceButtons then
            self.choiceButtons = {};
        else
            for _, button in ipairs(self.choiceButtons) do
                button:Hide();
                button:ClearAllPoints();
            end
        end

        local numChoices = #data.choices;
        local buttonFullWidth = self.frameWidth*0.6;
        local fromOffset = self.frameWidth - buttonFullWidth;
        local buttonWidth = buttonFullWidth/numChoices;
        local buttonHeight = BUTTON_HEIGHT;
        local button;

        for i, choiceData in ipairs(data.choices) do
            button = self.choiceButtons[i];
            if not button then
                button = CreateChoiceButton(self);
                self.choiceButtons[i] = button;
            end
            button = self.choiceButtons[i];
            button:SetSize(buttonWidth, buttonHeight);
            button:SetPoint("LEFT", self, "LEFT", fromOffset + (i - 1) * buttonWidth, 0);
            button:Show();
            button.index = i;
            button.ButtonText:SetText(choiceData.text);
        end


        if data.getChoice then
            local choiceIndex = data.getChoice();
            self:SelectChoice(choiceIndex);
        end

        self.onSelectChoice = data.onSelectChoice;

        if not self.ButtonBorder then
            self.ButtonBorder = CreateFrame("Frame", nil, self, "NarciBarberShopStrokeFrameNoScriptTemplate");
            self.ButtonBorder:SetPoint("RIGHT", self, "RIGHT", 0, 0);
            self.ButtonBorder.Background:Hide();
            self.ButtonBorder:SetBorderColor("grey");
        end
        self.ButtonBorder:SetSize(buttonFullWidth, buttonHeight);
    end

    function ChoiceFrameMixin:SelectChoice(choiceIndex)
        if not self.Selection then
            self.Selection = self:CreateTexture(nil, "BACKGROUND");
            self.Selection:SetColorTexture(0.2, 0.5, 0.2);
        end

        self.Selection:Hide();
        self.Selection:ClearAllPoints();

        for i, button in ipairs(self.choiceButtons) do
            if i == choiceIndex then
                button.selected = true;
                local px2 = 2*PIXEL;
                self.Selection:SetPoint("TOPLEFT", button, "TOPLEFT", px2, -px2);
                self.Selection:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -px2, px2);
                self.Selection:Show();
                button.ButtonText:SetTextColor(1, 1, 1);
            else
                button.selected = nil;
                if button:IsMouseOver() then
                    button:OnEnter();
                else
                    button:OnLeave();
                end
            end
        end
    end

    local function CreateChoiceFrame(parent)
        local f = CreateFrame("Frame", nil, parent);
        Mixin(f, ChoiceFrameMixin);
        f:SetHeight(BUTTON_HEIGHT);
        return f
    end
    addon.CreateChoiceFrame = CreateChoiceFrame;
end


do
    local DropdownFrameMixin = {};
    local NUM_ENTRY_PER_PAGE = 5;
    local BUTTON_TEXT_OFFSET = 6;
    local FORMAT_PAGE = PAGE_NUMBER_WITH_MAX or "Page %d/%d";


    function DropdownFrameMixin:SetData(data)
        self.LeftText:SetText(data.text);
        self.dataProvider = data.dataProvider;
    end

    function DropdownFrameMixin:Collapse()
        self.expanded = nil;
        self:SetHeight(BUTTON_HEIGHT);
        self.Arrow:SetTexCoord(0, 1, 0, 1);
        self.Menu:Hide();

        if self:IsVisible() and self:IsMouseOver() then
            self:SetBorderColor("focused");
        else
            self:SetBorderColor("grey");
        end
    end

    function DropdownFrameMixin:Expand()
        self.expanded = true;
        self:SetHeight(BUTTON_HEIGHT * (2 + NUM_ENTRY_PER_PAGE));
        self.Arrow:SetTexCoord(0, 1, 1, 0);
        self:SetBorderColor("grey");
        self.Menu:Show();
        self.Menu:SetFrameLevel(self:GetFrameLevel());

        local list = self.dataProvider:GetList();
        self.list = list;
        self.numPages = math.ceil(#list / NUM_ENTRY_PER_PAGE);

        local page;
        if self.page then
            if self.page == 0 then
                page = 1;
            else
                page = self.page;
            end
        else
            page = 1;
        end

        if page > self.numPages then
            page = self.numPages;
        end

        self:SetPage(page);
    end

    function DropdownFrameMixin:Toggle()
        if self.expanded then
            self:Collapse();
        else
            self:Expand();
        end
    end

    function DropdownFrameMixin:OnHide()
        if self.expanded then
            self:Collapse();
        end
    end

    function  DropdownFrameMixin:SelectData(data)
        local closeMenu = self.dataProvider:SelectData(data);
        self.dataProvider:SetData(self, data);
        return closeMenu
    end

    local function DropdownButton_OnEnter(self)
        self.owner:HighlightButton(self);
    end

    local function DropdownButton_OnLeave(self)
        self.owner:HighlightButton(nil);
    end

    local function DropdownButton_OnClick(self)
        if self.owner:SelectData(self.data) then
            self.owner:Collapse();
        end
    end

    local function CreateDropdownButton(parent)
        local button = CreateFrame("Button", nil, parent);

        button.LeftText = button:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
        button.LeftText:SetPoint("LEFT", button, "LEFT", BUTTON_TEXT_OFFSET, 0);
        button.LeftText:SetJustifyH("LEFT");
        button.LeftText:SetTextColor(0.8, 0.8, 0.8);

        button.RightText = button:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
        button.RightText:SetPoint("RIGHT", button, "RIGHT", -BUTTON_TEXT_OFFSET, 0);
        button.RightText:SetJustifyH("RIGHT");
        button.RightText:SetTextColor(0.8, 0.8, 0.8);

        button:SetScript("OnEnter", DropdownButton_OnEnter);
        button:SetScript("OnLeave", DropdownButton_OnLeave);
        button:SetScript("OnClick", DropdownButton_OnClick);

        return button
    end

    function DropdownFrameMixin:SetPage(page)
        self.page = page;
        self.PageText:SetText(FORMAT_PAGE:format(page, self.numPages));

        local fromIndex = (self.page - 1) * NUM_ENTRY_PER_PAGE;
        local dataIndex;
        local button;

        for i = 1, NUM_ENTRY_PER_PAGE do
            dataIndex = fromIndex + i;
            button = self.DropdownButtons[i];

            if self.list[dataIndex] then
                if not button then
                    button = CreateDropdownButton(self.Menu);
                    button:SetPoint("TOPLEFT", self.Menu, "TOPLEFT", 0, (1 - i) * BUTTON_HEIGHT - 4);
                    button:SetSize(self:GetWidth(), BUTTON_HEIGHT);
                    button.owner = self;
                    self.DropdownButtons[i] = button;
                end
                self.dataProvider:SetData(self.DropdownButtons[i], self.list[dataIndex]);
            else
                if button then
                    button:Hide();
                end
            end
        end
    end

    function DropdownFrameMixin:SetPageByDelta(delta)
        if delta < 0 then
            if self.page < self.numPages then
                self.page = self.page + 1;
            else
                return
            end
        else
            if self.page > 1 then
                self.page = self.page - 1;
            else
                return
            end
        end

        self:SetPage(self.page);
    end

    function DropdownFrameMixin:HighlightButton(button)
        if not self.ButtonHighlight then
            self.ButtonHighlight = self:CreateTexture(nil, "BACKGROUND", nil, 1);
            self.ButtonHighlight:SetColorTexture(0.2, 0.2, 0.2);
        end

        self.ButtonHighlight:ClearAllPoints();

        if button then
            self.ButtonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
            self.ButtonHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
            self.ButtonHighlight:Show();
        else
            self.ButtonHighlight:Hide();
        end
    end

    local function Menu_OnShow(self)
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    end

    local function Menu_OnHide(self)
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    end

    local function Menu_OnEvent(self)
        if not self.owner:IsMouseOver() then
            self.owner:Collapse();
        end
    end

    local function CreateDropdownFrame(parent)
        local f = CreateFrame("Frame", nil, parent, "NarciBarberShopStrokeFrameNoScriptTemplate");
        Mixin(f, DropdownFrameMixin);

        f:SetBorderColor("grey");
        f:SetScript("OnHide", f.OnHide);
        f.DropdownButtons = {};

        local bt = f:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
        f.LeftText = bt;
        bt:SetTextColor(1, 1, 1);
        bt:SetJustifyH("LEFT");
        bt:SetMaxLines(1);
        bt:SetPoint("LEFT", f, "TOPLEFT", BUTTON_TEXT_OFFSET, -0.5*BUTTON_HEIGHT);
        bt:SetPoint("RIGHT", f, "TOPRIGHT", -32, -0.5*BUTTON_HEIGHT);

        local arrow = f:CreateTexture(nil, "OVERLAY");
        arrow:SetSize(12, 12);
        arrow:SetPoint("CENTER", f, "TOPRIGHT", -0.5*BUTTON_HEIGHT, -0.5*BUTTON_HEIGHT);
        arrow:SetTexture("Interface/AddOns/Narcissus/Art/Modules/BarberShop/DropdownArrow-Down");
        f.Arrow = arrow;

        local tb = CreateFrame("Button", nil, f);
        f.ToggleButton = tb;
        tb:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0);
        tb:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0);
        tb:SetHeight(BUTTON_HEIGHT);

        tb:SetScript("OnClick", function()
            f:Toggle();
        end);

        tb:SetScript("OnEnter", function()
            f:SetBorderColor("focused");
        end);

        tb:SetScript("OnLeave", function()
            f:SetBorderColor("grey");
        end);

        local menu = CreateFrame("Frame", nil, f);
        f.Menu = menu;
        menu:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -BUTTON_HEIGHT);
        menu:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0);
        menu:Hide();
        menu.owner = f;

        menu:SetScript("OnShow", Menu_OnShow);
        menu:SetScript("OnHide", Menu_OnHide);
        menu:SetScript("OnEvent", Menu_OnEvent);

        menu:SetScript("OnMouseWheel", function(_, delta)
            f:SetPageByDelta(delta);
        end);

        local pt = menu:CreateFontString(nil, "OVERLAY", "SystemFont_Tiny");
        f.PageText = pt;
        pt:SetHeight(BUTTON_HEIGHT);
        pt:SetJustifyH("CENTER");
        pt:SetPoint("BOTTOM", menu, "BOTTOM", 0, 0);
        pt:SetTextColor(0.5, 0.5, 0.5);


        local px1 = PIXEL;

        f.TopDiv = menu:CreateTexture(nil, "OVERLAY");
        f.TopDiv:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 4, -BUTTON_HEIGHT);
        f.TopDiv:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -4, -BUTTON_HEIGHT);
        f.TopDiv:SetHeight(px1);
        f.TopDiv:SetColorTexture(0.2, 0.2, 0.2);

        return f
    end
    addon.CreateDropdownFrame = CreateDropdownFrame;
end