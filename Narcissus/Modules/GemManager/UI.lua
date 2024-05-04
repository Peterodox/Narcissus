local _, addon = ...
local Gemma = addon.Gemma;
local AtlasUtil = Gemma.AtlasUtil;
local ItemCache = Gemma.ItemCache;
local GetActionButton = Gemma.GetActionButton;
local DoesItemExistByID = addon.DoesItemExistByID;
local GetItemIcon = C_Item.GetItemIconByID;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;
local C_TooltipInfo = C_TooltipInfo;
local FadeFrame = NarciFadeUI.Fade;
local L = Narci.L;

local CreateFrame = CreateFrame;
local Mixin = Mixin;
local GameTooltip = GameTooltip;

local PATH = "Interface/AddOns/Narcissus/Art/Modules/GemManager/";
local TRAIT_BUTTON_SIZE = 40;     --Blizzard Talents
local FRAME_PADDING = 8;
local TAB_BUTTON_HEIGHT = 32;
local FRAME_WIDTH, FRAME_HEIGHT = 338, 424;
local FONT_FILE = GameFontNormal:GetFont();

local HEADER_HEIGHT = TAB_BUTTON_HEIGHT + FRAME_PADDING;

local MainFrame, TooltipFrame, SlotHighlight, PointsDisplay, GemList, ListHighlight;


local IS_TRAIT_ACTIVE = {}; --debug

local Mixin_TraitButton = {};

function Mixin_TraitButton:SetItem(itemID)
    self.itemID = itemID;
    self.Icon:SetTexture(GetItemIcon(itemID));
    self.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);

    local name = ItemCache:GetItemName(itemID, self);

    IS_TRAIT_ACTIVE[self.index] = true;
end

function Mixin_TraitButton:OnItemLoaded(itemID)
    if itemID == self.itemID then
        self:SetItem(itemID);
    end
end

function Mixin_TraitButton:ClearItem()
    self.itemID = nil;
    self:SetEmpty();
end

function Mixin_TraitButton:SetShape(shape)
    self.IconMask:SetTexture(PATH.."IconMask-"..shape, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
end

function Mixin_TraitButton:ShowGameTooltip()
    if self.itemID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        local spellID = Gemma:GetGemSpell(self.itemID);
        if spellID then
            GameTooltip:SetSpellByID(spellID);
        else
            GameTooltip:SetItemByID(self.itemID)
        end

        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(L["Click To Activate"], 0, 1, 0, true);
        GameTooltip:Show();

        SharedTooltip_SetBackdropStyle(GameTooltip, nil, true);


        local background = TooltipFrame.GameTooltipBackground;

        if not background then
            background = CreateFrame("Frame", nil, TooltipFrame);
            TooltipFrame.GameTooltipBackground = background;
            NarciAPI.NineSliceUtil.SetUpBorder(background, "classTalentTraitTransparent");

            background:SetScript("OnHide", function()
                background:Hide();
                background:ClearAllPoints();
            end);
        end

        local offset = 2;

        background:ClearAllPoints();
        background:SetPoint("TOPLEFT", GameTooltip, "TOPLEFT", -offset, offset);
        background:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMRIGHT", offset, -offset);
        background:Show();
        TooltipFrame:Show();
        TooltipFrame:ClearLines();
    end
end

function Mixin_TraitButton:ShowCustomTooltip()
    TooltipFrame:SetItemByID(self.itemID);
end

local TOOLTIP_METHOD = "ShowGameTooltip";

function Mixin_TraitButton:OnEnter(motion)
    SlotHighlight:HighlightSlot(self);

    self[TOOLTIP_METHOD](self);

    if motion then
        local ActionButton = GetActionButton(self);
    end
end

function Mixin_TraitButton:OnLeave(motion, fromActionButton)
    if (not fromActionButton) and self:IsMouseOver() then return end;

    GameTooltip:Hide();
    TooltipFrame:Hide();
    SlotHighlight:HighlightSlot(nil);
end

function Mixin_TraitButton:SetActive()
    self.Icon:SetVertexColor(1, 1, 1);
    self.Icon:SetDesaturation(0);
    self:SetBorderByState("active");
end

function Mixin_TraitButton:SetInactive()
    self.Icon:SetVertexColor(0.67, 0.67, 0.67);
    self.Icon:SetDesaturation(1);
    self:SetBorderByState("inactive");
end

function Mixin_TraitButton:SetUncollected()
    self.Icon:SetVertexColor(0.33, 0.33, 0.33);
    self.Icon:SetDesaturation(1);
    self:SetBorderByState("inactive");
end

function Mixin_TraitButton:SetAvailable()
    self.Icon:SetVertexColor(1, 1, 1);
    self.Icon:SetDesaturation(0);
    self:SetBorderByState("available");
end

function Mixin_TraitButton:SetDimmed()
    self.Border:SetTexCoord(192/1024, 288/1024, 0/1024, 96/1024);
    self.Icon:SetVertexColor(120/255, 90/255, 0/255);
    self.Icon:SetDesaturation(1);
    self:SetBorderByState("dimmed")
end

function Mixin_TraitButton:SetEmpty()
    self.Icon:SetVertexColor(1, 1, 1);
    self.Icon:SetDesaturation(0);
    self.Icon:SetTexture(PATH.."Gem-Empty");
    self.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);
    self:SetBorderByState("inactive");
end

function Mixin_TraitButton:OnClick(button)
    if button == "LeftButton" then
        if MainFrame.chooseTrait then
            IS_TRAIT_ACTIVE[self.index] = true;
            MainFrame:SetModeChooseTrait(false);
            MainFrame:ShineSlot(self);
            return
        end

        IS_TRAIT_ACTIVE[self.index] = not IS_TRAIT_ACTIVE[self.index];
        if IS_TRAIT_ACTIVE[self.index] then
            self:SetActive();
        else
            self:SetInactive();
        end
    elseif button == "RightButton" then
        IS_TRAIT_ACTIVE[self.index] = false;
        MainFrame:SetModeChooseTrait(true);
    end
end

function Mixin_TraitButton:SetButtonSize(buttonSize, iconSize)
    --For unique sized buttons
    self:SetSize(buttonSize, buttonSize);
    self.Icon:SetSize(iconSize, iconSize);
end

function Mixin_TraitButton:ResetButtonSize()
    self:SetSize(TRAIT_BUTTON_SIZE, TRAIT_BUTTON_SIZE);
    self.Icon:SetSize(38, 38);
end

function Mixin_TraitButton:SetBorderByState(state)
    if self.borderTextures then
        AtlasUtil:SetAtlas(self.Border, self.borderTextures[state]);
    end
end

local function CreateTraitButton(parent, shape)
    local button = CreateFrame("Button", nil, parent, "NarciGemManagerTraitButtonTemplate");
    Mixin(button, Mixin_TraitButton);
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


local Mixin_TooltipFrame = {};
do
    local gusb = string.gsub;
    local ON_EQUIP = "^".. (ITEM_SPELL_TRIGGER_ONEQUIP or "Equip:");

    function Mixin_TooltipFrame:RemoveOnEquipText(text)
        return gusb(text, ON_EQUIP, "");
    end

    function Mixin_TooltipFrame:ProcessTooltipInfo()
        local title, titleColor;
        local desc;

        local tooltipData = C_TooltipInfo[self.method](self.arg1, self.arg2);
        if tooltipData and tooltipData.lines then
            self.dataInstanceID = tooltipData.dataInstanceID;
            for index, lineData in ipairs(tooltipData.lines) do
                if lineData.leftText then
                    if index == 1 then
                        title = lineData.leftText;
                        titleColor = lineData.leftColor;
                    elseif index == self.descLineIndex then
                        desc = lineData.leftText;
                    end
                end
            end
        end

        local showFrame;

        if title and title ~= "" then
            showFrame = true;
            local r, g, b;
            if titleColor then
                r, g, b = titleColor:GetRGB();
            else
                r, g, b = 1, 1, 1;
            end
            self.Header:SetTextColor(r, g, b);
        end

        if desc then
            desc = self:RemoveOnEquipText(desc);
        end

        self.Header:SetText(title);
        self.Text1:SetText(desc);
        self.Text1:SetTextColor(0.88, 0.88, 0.88);

        if showFrame then
            local textHeight = self.Header:GetHeight() + self.Text1:GetHeight() + 10;
            local textWidth = math.max(self.Header:GetWrappedWidth(), self.Text1:GetWrappedWidth());
            self.Background:SetSize(textWidth + 32, textHeight + 32);
            self.Background:Show();
        else
            self.Background:Hide();
        end
    end

    function Mixin_TooltipFrame:SetItemByID(itemID)
        if itemID and DoesItemExistByID(itemID) then
            self:Show();
        else
            self:Hide();
            return
        end

        self.method = "GetItemByID";
        self.arg1 = itemID;
        self.arg2 = nil;
        self:ProcessTooltipInfo();
    end

    function Mixin_TooltipFrame:ClearLines()
        self.dataInstanceID = nil;
        self.Header:SetText(nil);
        self.Text1:SetText(nil);
        self.Background:Hide();
    end

    function Mixin_TooltipFrame:UpdateTooltipInfo()
        self:ProcessTooltipInfo();
    end

    function Mixin_TooltipFrame:SetDescriptionLine(lineIndex)
        self.descLineIndex = lineIndex;
    end

    function Mixin_TooltipFrame:OnShow()
        self:RegisterEvent("TOOLTIP_DATA_UPDATE");
    end

    function Mixin_TooltipFrame:OnHide()
        self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
    end

    function Mixin_TooltipFrame:OnEvent(event, ...)
        if event == "TOOLTIP_DATA_UPDATE" then
            local dataInstanceID = ...
            if dataInstanceID and dataInstanceID == self.dataInstanceID then
                self:UpdateTooltipInfo();
            end
        end
    end

    function Mixin_TooltipFrame:SetMaxWdith(width)
        self:SetWidth(width);
        self:SetHeight(80);
        self.Header:SetWidth(width);
        self.Text1:SetWidth(width);
    end

    function Mixin_TooltipFrame:OnLoad()
        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnHide", self.OnHide);
        self:SetScript("OnEvent", self.OnEvent);


        AtlasUtil:SetAtlas(self.Background, "remix-ui-tooltip-bg");
        --self.Background:SetColorTexture(0, 0, 0, 0.5);
    end
end


local Mixin_SlotHighlight = {};
do
    local HIGHLIGHT_TEXTURE = {
        Hexagon = {
            atlas = "remix-hexagon-highlight",
            alphaMode = "ADD",
            alpha = 0.5;
        },
    
        BigSquare = {
            atlas = "remix-bigsquare-highlight",
            alphaMode = "ADD",
            alpha = 0.5;
        },
    };

    function Mixin_SlotHighlight:SetShape(shape)
        local data = HIGHLIGHT_TEXTURE[shape];
        AtlasUtil:SetAtlas(self.Texture, data.atlas);
        self.Texture:SetBlendMode(data.alphaMode);
        self:SetAlpha(data.alpha);
    end

    function Mixin_SlotHighlight:HighlightSlot(slot)
        self:ClearAllPoints();
        if slot then
            self:Show();
            self:SetParent(slot);
            self:SetPoint("CENTER", slot, "CENTER", 0, 0);
        else
            self:Hide();
        end
    end
end


local Mixin_TabButton = {}
do
    function Mixin_TabButton:OnLoad()
        self.Name = self:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        self.Name:SetJustifyH("CENTER");
        self.Name:SetPoint("CENTER", self, "CENTER", 0, 0);

        local dot = self:CreateTexture(nil, "OVERLAY");
        self.GreenDot = dot;
        dot:SetSize(6, 6);
        dot:SetPoint("CENTER", self.Name, "TOPRIGHT", 2, -2);
        dot:SetTexture(PATH.."GreenDot", nil, nil, "TRILINEAR");
        dot:SetTexelSnappingBias(0);
        dot:SetSnapToPixelGrid(false);

        local flag = "OUTLINE";
        self.Name:SetFont(FONT_FILE, 14, flag);
        self:SetHeight(TAB_BUTTON_HEIGHT);

        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnClick", self.OnClick);
    end

    function Mixin_TabButton:OnEnter()
        self.Name:SetTextColor(1, 1, 1);
    end

    function Mixin_TabButton:OnLeave()
        self:UpdateColor();
    end

    function Mixin_TabButton:UpdateColor()
        if self.isSelected then
            self.Name:SetTextColor(1, 1, 1);
        else
            self.Name:SetTextColor(0.67, 0.67, 0.67);
        end
    end

    function Mixin_TabButton:SetSelected(isSelected)
        self.isSelected = isSelected or false;
        self:UpdateColor();
    end

    function Mixin_TabButton:OnClick()
        MainFrame:SelectTabByID(self.id);
    end

    function Mixin_TabButton:SetName(name)
        self.Name:SetText(name);
        local width = self.Name:GetWrappedWidth();
        local buttonWidth = math.max(width, 64);
        self:SetWidth(buttonWidth);
        return buttonWidth
    end
end


local Mixin_PointsDisplay = {};
do
    local NUMBER_SIZE = 28;
    local NUMBER_LABEL_GAP = 6;

    function Mixin_PointsDisplay:OnLoad()
        local flag = "OUTLINE";

        self.Amount:SetFont(FONT_FILE, NUMBER_SIZE, flag);
        self.Label:SetFont(FONT_FILE, 12, flag);
        self.Label:ClearAllPoints();
        self.Label:SetPoint("LEFT", self, "LEFT", NUMBER_SIZE + NUMBER_LABEL_GAP, 0);
        self.Amount:ClearAllPoints();
        self.Amount:SetPoint("RIGHT", self.Label, "LEFT", -NUMBER_LABEL_GAP, -1)

        self.Label:SetTextColor(0.88, 0.88, 0.88);
        self:SetHeight(NUMBER_SIZE);
    end

    function Mixin_PointsDisplay:SetLabel(text)
        text = string.upper(text);
        self.Label:SetText(text);
        local textWidth = self.Label:GetWrappedWidth();
        local frameWidth = NUMBER_SIZE + NUMBER_LABEL_GAP + textWidth;
        self:SetWidth(frameWidth);
    end

    function Mixin_PointsDisplay:SetAmount(amount)
        self.Amount:SetText(amount);
        self.Amount:SetTextColor(0, 1, 0);
    end
end

local CreateIconButton;
do
    local Mixin_IconButton = {};

    function Mixin_IconButton:OnEnter()
        self.Icon:SetVertexColor(1, 1, 1);
    end

    function Mixin_IconButton:OnLeave()
        self.Icon:SetVertexColor(0.5, 0.5, 0.5);
    end

    function Mixin_IconButton:OnDisable()
        self.Icon:SetVertexColor(0.1, 0.1, 0.1);
    end

    function Mixin_IconButton:OnEnable()
        if self:IsMouseOver() then
            self:OnEnter();
        else
            self:OnLeave();
        end
    end

    function CreateIconButton(parent)
        local button = CreateFrame("Button", nil, parent);
        button.Icon = button:CreateTexture(nil, "OVERLAY");
        button.Icon:SetSize(16, 16);
        button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0);

        Mixin(button, Mixin_IconButton);
        button:SetScript("OnEnter", button.OnEnter);
        button:SetScript("OnLeave", button.OnLeave);
        button:SetScript("OnDisable", button.OnDisable);
        button:SetScript("OnEnable", button.OnEnable);

        button:Disable();

        return button
    end
end

local Mixin_GemList = {};
do
    local ITEMS_PER_PAGE = 8;
    local LISTBUTTON_HEIGHT = 44;
    local FROM_Y = -40 -4;

    local Mixin_ListButton = {};

    function Mixin_ListButton:OnLoad()
        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnClick", self.OnClick);

        self.Text1:SetFont(FONT_FILE, 14, "OUTLINE");
    end

    function Mixin_ListButton:OnClick(button)
        if button == "RightButton" then
            MainFrame:CloseGemList();
            return
        end

        if button == "LeftButton" then
            
        end
    end

    function Mixin_ListButton:OnEnter()
        ListHighlight:ClearAllPoints();
        ListHighlight:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        ListHighlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
        ListHighlight:Show();

        Mixin_TraitButton.ShowGameTooltip(self);
    end

    function Mixin_ListButton:OnLeave()
        ListHighlight:Hide();
        GameTooltip:Hide();
        TooltipFrame:Hide();
    end

    function Mixin_ListButton:SetItem(itemID)
        self.itemID = itemID;
        self.Icon:SetTexture(GetItemIcon(itemID));
        self.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);
    
        local name = ItemCache:GetItemName(itemID, self);
        self.Text1:SetText(name);

        local quality = ItemCache:GetItemQuality(itemID, self);
        local r, g, b = GetItemQualityColor(quality);
        self.Text1:SetTextColor(r, g, b);
    end

    function Mixin_ListButton:OnItemLoaded(itemID)
        if itemID == self.itemID then
            self:SetItem(itemID);
        end
    end

    function Mixin_ListButton:ClearItem()
        self.itemID = nil;
        self:Hide();
    end

    function Mixin_GemList:OnLoad()
        local height = 24;
        self.listButtons = {};
        
        local PageText = self:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        self.PageText = PageText;
        PageText:SetWidth(72);
        PageText:SetHeight(height);
        PageText:SetJustifyH("CENTER");
        PageText:SetPoint("BOTTOM", self, "BOTTOM", 0, 3);

        local flag = "OUTLINE";
        PageText:SetFont(FONT_FILE, 12, flag);
        PageText:SetTextColor(0.88, 0.88, 0.88);

        self:SetScript("OnMouseDown", self.OnMouseDown);
        self:SetScript("OnMouseWheel", self.OnMouseWheel);

        self.Title:SetFont(FONT_FILE, 14, flag);
        self.Title:SetTextColor(0.88, 0.88, 0.88);

        local button1 = CreateIconButton(self);
        self.PrevButton = button1;
        AtlasUtil:SetAtlas(button1.Icon, "gemlist-prev");
        button1:SetSize(height, height);
        button1:SetPoint("RIGHT", PageText, "LEFT", 0, 0);
        button1:SetScript("OnClick", function()
            self:OnMouseWheel(1);
        end);

        local button2 = CreateIconButton(self);
        self.NextButton = button2;
        AtlasUtil:SetAtlas(button2.Icon, "gemlist-next");
        button2:SetSize(height, height);
        button2:SetPoint("LEFT", PageText, "RIGHT", 0, 0);
        button2:SetScript("OnClick", function()
            self:OnMouseWheel(-1);
        end);

        local button3 = CreateIconButton(self);
        self.ReturnButton = button3;
        AtlasUtil:SetAtlas(button3.Icon, "gemlist-return");
        button3:SetSize(60, TAB_BUTTON_HEIGHT);
        button3:SetPoint("LEFT", MainFrame, "TOPLEFT", 0, -22);
        button3:Enable();
        button3:SetScript("OnClick", function()
            MainFrame:CloseGemList();
        end);
    end

    function Mixin_GemList:OnMouseDown(button)
        if button == "RightButton" then
            MainFrame:CloseGemList();
        end
    end

    function Mixin_GemList:OnMouseWheel(delta)
        if delta > 0 and self.page > 1 then
            self.page = self.page - 1;
            self:SetPage(self.page);
        elseif delta < 0 and self.page < self.numPages then
            self.page = self.page + 1;
            self:SetPage(self.page);
        end
    end

    function Mixin_GemList:SetPage(page)
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

        for i = 1, ITEMS_PER_PAGE do
            dataIndex = fromIndex + i;
            button = self.listButtons[i];

            if self.itemList[dataIndex] then
                if not button then
                    button = CreateFrame("Button", nil, self, "NarciGemManagerGemListButtonTemplate");
                    self.listButtons[i] = button;
                    Mixin(button, Mixin_ListButton);
                    button:SetPoint("TOPLEFT", self, "TOPLEFT", 0, FROM_Y + (1 - i) * LISTBUTTON_HEIGHT);
                    button:OnLoad();
                end

                button:Hide();
                button:SetItem(self.itemList[dataIndex]);
                button:Show();
            else
                if button then
                    button:ClearItem();
                end
            end
        end
    end

    function Mixin_GemList:SetItemList(itemList, title)
        self.Title:SetText(title);

        if itemList ~= self.itemList then
            self.itemList = itemList;
        else
            return
        end

        local numPages = itemList and #itemList or 0;
        numPages = math.ceil(numPages / ITEMS_PER_PAGE);
        self.numPages = numPages;
        self:SetPage(1);

        local showNavButton = numPages > 1;
        self.PrevButton:SetShown(showNavButton);
        self.NextButton:SetShown(showNavButton);
    end

    function Mixin_GemList:Close()
        self:Hide();
    end
end


local SetupModelScene;
do
    function SetupModelScene(self)
        self:SetSize(FRAME_WIDTH, FRAME_HEIGHT);
        self:SetCameraPosition(10, 0, 0);
        self:SetCameraOrientationByAxisVectors(-1, 0, 0, 0, -1, 0, 0, 0, 1);

        for i = 1, 2 do
            local actor = self:CreateActor("AT");
            actor:SetPosition(-40, -10, 12);
            actor:SetModelByFileID(1567107);
            actor:SetPitch(0);
            actor:SetYaw(1.5);
            actor:SetRoll(1.8);
            actor:SetUseCenterForOrigin(true, true, true);
        end
    end
end


NarciGemManagerMixin = {};

function NarciGemManagerMixin:OnLoad()
    self:SetSize(FRAME_WIDTH, FRAME_HEIGHT);
    self.HeaderFrame:SetHeight(HEADER_HEIGHT);

    MainFrame = self;
    TooltipFrame = self.TooltipFrame;
    SlotHighlight = self.SlotFrame.ButtonHighlight;
    PointsDisplay = self.SlotFrame.PointsDisplay;
    GemList = self.GemList;
    ListHighlight = self.GemList.ButtonHighlight;
end

function NarciGemManagerMixin:AnchorToPaperDollFrame()
    self:ClearAllPoints();
    local f = PaperDollFrame;
    self:SetParent(f);
    self:SetPoint("TOPLEFT", f, "TOPRIGHT", 24, 0);
end

function NarciGemManagerMixin:OnShow()
    if self.Init then
        self:Init();
    end

    self:SetDataProviderByName("Pandaria");
    self:AnchorToPaperDollFrame();
end

function NarciGemManagerMixin:Init()
    self.Init = nil;

    Mixin(TooltipFrame, Mixin_TooltipFrame);
    TooltipFrame:SetMaxWdith(FRAME_WIDTH - 48);
    TooltipFrame:OnLoad();

    local flag = "OUTLINE";

    TooltipFrame.Header:SetFont(FONT_FILE, 14, flag);
    TooltipFrame.Text1:SetFont(FONT_FILE, 12, flag);

    Mixin(SlotHighlight, Mixin_SlotHighlight);

    local TabButtonSelection = self.HeaderFrame.TabButtonContainer.Selection;
    TabButtonSelection:SetTexture(PATH.."TabButtonSelection");
    TabButtonSelection:SetBlendMode("ADD");

    Mixin(PointsDisplay, Mixin_PointsDisplay);
    PointsDisplay:OnLoad();
    PointsDisplay:ClearAllPoints();
    PointsDisplay:SetPoint("TOP", self.HeaderFrame, "BOTTOM", 0, -16);
    PointsDisplay:SetLabel("Points Available");
    PointsDisplay:SetAmount(3);

    Mixin(GemList, Mixin_GemList);
    GemList:OnLoad();

    AtlasUtil:SetAtlas(ListHighlight.Texture, "remix-listbutton-highlight");
    ListHighlight.Texture:SetBlendMode("ADD");

    SetupModelScene(self.ModelScene);
end

function NarciGemManagerMixin:ReleaseTabs()
    if self.tabButtons then
        for _, button in pairs(self.tabButtons) do
            button:Hide();
            button:ClearAllPoints();
        end
    end
end

function NarciGemManagerMixin:SelectTabByID(id)
    if id == self.tabID then
        return
    else
        self.tabID = id;
    end

    local data = self.tabData[id];
    local method = data.method;

    if method then
        self:ReleaseContent();
        self[method](self);
        AtlasUtil:SetAtlas(self.SlotFrame.Background, data.background);
        self:OnTabChanged();
    end

    if data.useCustomTooltip then
        TOOLTIP_METHOD = "ShowCustomTooltip";
    else
        TOOLTIP_METHOD = "ShowGameTooltip";
    end
end

function NarciGemManagerMixin:OnTabChanged()
    --Tab Button Visual
    local selection = self.HeaderFrame.TabButtonContainer.Selection;
    selection:ClearAllPoints();
    selection:Hide();

    for i, button in pairs(self.tabButtons) do
        if button:IsShown() then
            button:SetSelected(i == self.tabID);
            if i == self.tabID then
                selection:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0);
                selection:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
                selection:Show();
            end
        end
    end
end

function NarciGemManagerMixin:SetTabData(tabData)
    self.tabData = tabData;
    self:ReleaseTabs();

    if not self.tabButtons then
        self.tabButtons = {};
    end

    local button;
    local buttonWidth;
    local gap = 12;
    local fullWidth = 0;

    for i, data in ipairs(tabData) do
        button = self.tabButtons[i];
        if not self.tabButtons[i] then
            button = CreateFrame("Button", nil, self.HeaderFrame.TabButtonContainer);
            self.tabButtons[i] = button;
            Mixin(button, Mixin_TabButton);
            button:OnLoad();
            button.id = i;
        end

        button:Show();
        buttonWidth = button:SetName(data.name);
        fullWidth = fullWidth + buttonWidth;
        button:ClearAllPoints();

        if i == 1 then

        else
            fullWidth = fullWidth + gap;
            button:SetPoint("LEFT", self.tabButtons[i - 1], "RIGHT", gap, 0);
        end

        --debug
        button:SetSelected(i == 1);
    end

    local frameWidth = FRAME_WIDTH;
    local refX = 0.5 * (frameWidth - fullWidth);
    local refY = -FRAME_PADDING;

    self.tabButtons[1]:SetPoint("TOPLEFT", self, "TOPLEFT", refX, refY);
end

function NarciGemManagerMixin:ReleaseSlots()
    if self.slotButtons then
        for _, button in pairs(self.slotButtons) do
            button:Hide();
            button:ClearAllPoints();
            button.itemID = nil;
        end
        self.numSlotButtons = 0;
    end
end

function NarciGemManagerMixin:ReleaseTextures()
    if self.fronTextures then
        if self.numfronTextures > 0 then
            for _, texture in pairs(self.fronTextures) do
                texture:Hide();
                texture:ClearAllPoints();
                texture:SetTexture(nil);
            end
            self.numfronTextures = 0;
        end
    end
    if self.backTextures then
        if self.numbackTextures > 0 then
            for _, texture in pairs(self.backTextures) do
                texture:Hide();
                texture:ClearAllPoints();
                texture:SetTexture(nil);
            end
            self.numbackTextures = 0;
        end
    end
end

function NarciGemManagerMixin:ReleaseContent()
    self:ReleaseSlots();
    self:ReleaseTextures();
    self:ShineSlot(nil);
    TooltipFrame:Hide();
    SlotHighlight:Hide();
    PointsDisplay:Hide();
end

function NarciGemManagerMixin:AcquireSlotButton(shape)
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

function NarciGemManagerMixin:AcquireTexture(depth, drawLayer)
    depth = depth or "Front";
    drawLayer = drawLayer or "ARTWORK";

    local container, pool, index;

    if depth == "Front" then
        if not self.fronTextures then
            self.fronTextures = {};
            self.numfronTextures = 0;
        end
        container = self.SlotFrame.FontFrame;
        pool = self.fronTextures;
        index = self.numfronTextures + 1;
        self.numfronTextures = index;
    else
        if not self.backTextures then
            self.backTextures = {};
            self.numbackTextures = 0;
        end
        container = self.SlotFrame.BackFrame;
        pool = self.backTextures;
        index = self.numbackTextures + 1;
        self.numbackTextures = index;
    end

    local texture = pool[index];

    if not texture then
        texture = container:CreateTexture(nil, drawLayer)
        pool[index] = texture;
    end

    texture:Show();
    texture:SetDrawLayer(drawLayer);

    return texture
end

function NarciGemManagerMixin:SetModeChooseTrait(state)
    self.chooseTrait = state;

    if state then
        for index, slot in ipairs(self.slotButtons) do
            if slot:IsShown() then
                if not IS_TRAIT_ACTIVE[index] then
                    slot:SetAvailable();
                else
                    slot:SetDimmed();
                end
            end
        end
        PointsDisplay:Show();
    else
        for index, slot in ipairs(self.slotButtons) do
            if slot:IsShown() then
                if IS_TRAIT_ACTIVE[index] then
                    slot:SetActive();
                else
                    slot:SetInactive();
                end
            end
        end
        PointsDisplay:Hide();
    end
end

function NarciGemManagerMixin:ShineSlot(slot)
    local shine = self.SlotFrame.ButtonShine;
    shine:ClearAllPoints();
    shine.AnimShine:Stop();
    if slot then
        shine:SetParent(slot);
        shine:SetPoint("CENTER", slot, "CENTER", 0, 0);
        shine:Show();
        shine.AnimShine:Play();
    else
        shine:SetParent(self.SlotFrame);
        shine:SetPoint("CENTER", self.SlotFrame, "CENTER", 0, 0);
        shine:Hide();
    end
end

function NarciGemManagerMixin:SetDataProviderByName(name)
    if name == self.dataProviderName then
        return
    else
        self.dataProviderName = name;
    end

    Gemma:SetDataProviderByName("Pandaria");

    Mixin(self, Gemma:GetActiveMethods());
    self:SetTabData(Gemma:GetActiveTabData());

    local schematic = Gemma:GetActiveSchematic();

    AtlasUtil:SetAtlas(self.Background, schematic.background);
    AtlasUtil:SetAtlas(self.HeaderFrame.Divider, schematic.topDivider);
end

function NarciGemManagerMixin:UpdateSlots()

end


function NarciGemManagerMixin:OpenGemList()
    GemList:Show();
    self.SlotFrame:Hide();
    self.HeaderFrame.TabButtonContainer:Hide();

    FadeFrame(self.ModelScene, 0, 0.2);
end

function NarciGemManagerMixin:CloseGemList()
    GemList:Close();
    self.HeaderFrame.TabButtonContainer:Show();

    if self.useSlotFrame then
        self.SlotFrame:Show();
    end

    FadeFrame(self.ModelScene, 0.5, 1);
end


C_Timer.After(1, function()
    MainFrame:Show();
end)


do
    local function DLIN()
        local itemList = Gemma:GetSortedItemList()
        local name;
        for gemType, gems in ipairs(itemList) do
            for index, itemID in ipairs(gems) do
                name = ItemCache:GetItemName(itemID);
                if name then
                    print(name)
                end
            end
        end
    end
end