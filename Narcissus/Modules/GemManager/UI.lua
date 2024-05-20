local _, addon = ...
local CallbackRegistry = addon.CallbackRegistry;
local Gemma = addon.Gemma;
local AtlasUtil = Gemma.AtlasUtil;
local ItemCache = Gemma.ItemCache;
local AcquireActionButton = Gemma.AcquireActionButton;
local DoesItemExistByID = addon.DoesItemExistByID;
local GetItemIcon = C_Item.GetItemIconByID;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;
local InCombatLockdown = InCombatLockdown;
local GetSpellCooldown = GetSpellCooldown;
local C_TooltipInfo = C_TooltipInfo;
local FadeFrame = NarciFadeUI.Fade;
local L = Narci.L;
local After = C_Timer.After;


local CreateFrame = CreateFrame;
local Mixin = Mixin;
local GameTooltip = GameTooltip;

local PATH = "Interface/AddOns/Narcissus/Art/Modules/GemManager/";
local TRAIT_BUTTON_SIZE = 38;     --40 Blizzard Talents
local FRAME_PADDING = 8;
local TAB_BUTTON_HEIGHT = 32;
local FRAME_WIDTH, FRAME_HEIGHT = 338, 424;
local FONT_FILE = GameFontNormal:GetFont();
local ACTIONBLOCKER_DURATION = 0.8;

local TOOLTIP_METHOD = "ShowGameTooltip";
local MainFrame, TooltipFrame, SlotHighlight, PointsDisplay, GemList, ListHighlight, ProgressBar, Spinner, MouseOverFrame;




local function GetColorByIndex(colorIndex)
    local r, g, b;
    if colorIndex == 0 then
        r, g, b = 0.5, 0.5, 0.5;
    elseif colorIndex == 1 then
        r, g, b = 1, 0.82, 0;
    elseif colorIndex == 2 then
        r, g, b = 0.098, 1.000, 0.098;
    elseif colorIndex == 3 then
        r, g, b = 1.000, 0.125, 0.125;
    else
        r, g, b = 0.88, 0.88, 0.88;
    end
    return r, g, b
end




local Mixin_TraitButton = {};
do
    --traitState:
    --nil: Empty (Grey, no icon)
    --  0: Uncollected  (Grey)
    --  1: Inactive (Dark Yellow)
    --  2: Active (Yellow)
    --  3: Available (Green, click to activate)
    --  4: Empty but Selectable (Click to show gem list)

    function Mixin_TraitButton:SetItem(itemID)
        self.itemID = itemID;
        self.iconFile = GetItemIcon(itemID);
        self.Icon:SetTexture(self.iconFile);
        self.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);
    end

    function Mixin_TraitButton:OnItemLoaded(itemID)
        if itemID == self.itemID then
            self:SetItem(itemID);
        end
    end

    function Mixin_TraitButton:ClearItem()
        self.itemID = nil;
        self.iconFile = nil;
        self.traitState = nil;
        self:SetBorderByState("inactive");
        self:SetIconEmpty();
    end

    function Mixin_TraitButton:SetShape(shape)
        self.IconMask:SetTexture(PATH.."IconMask-"..shape, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    end

    function Mixin_TraitButton:ShowGameTooltip()
        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            local itemID = self.itemID;
            local spellID = Gemma:GetGemSpell(itemID);
            if spellID then
                GameTooltip:SetSpellByID(spellID);
            else
                GameTooltip:SetItemByID(itemID);
            end

            local statusText;
            local actionText;
            local colorIndex;   --0:Grey, 1:Yellow, 2:Green, 3:Red
            local traitState = self.traitState;

            if traitState == 0 then
                statusText = L["Gem Uncollected"];
                colorIndex = 0;
            elseif traitState == 1 then
    
            elseif traitState == 2 then
                if InCombatLockdown() then
                    actionText = L["Gem Removal Combat"];
                    colorIndex = 3;
                else
                    if Gemma:DoesBagHaveFreeSlot() then
                        if not self.isGemListButton then
                            --Right-clicking on a GemListButton closes gem list
                            actionText = L["Gem Removal Instruction"];
                            colorIndex = 1;
                        end
                    else
                        actionText = L["Gem Removal Bag Full"];
                        colorIndex = 3;
                    end
                end
            elseif traitState == 3 then
                if InCombatLockdown() then
                    actionText = L["Gem Removal Combat"];
                    colorIndex = 3;
                else
                    if Gemma:DoesBagHaveFreeSlot() then
                        if self.isGemListButton and (not Gemma:CanSwapGemInOneStep(itemID)) then
                            actionText = L["Gemma Click Twice To Insert"];
                            colorIndex = 2;
                        else
                            actionText = L["Gemma Click To Insert"];
                            colorIndex = 2;
                        end
                    else
                        actionText = L["Gem Removal Bag Full"];
                        colorIndex = 3;
                    end
                end
            end

            if statusText then
                GameTooltip:AddLine(" ");
                local r, g, b= GetColorByIndex(colorIndex);
                GameTooltip:AddLine(statusText, r, g, b, true);
                GameTooltip:Show();
            end

            if actionText then
                GameTooltip:AddLine(" ");
                local r, g, b= GetColorByIndex(colorIndex);
                GameTooltip:AddLine(actionText, r, g, b, true);
                GameTooltip:Show();
            end

            TooltipFrame:ShowGameTooltipBackground();

            local dataInstanceID = (GameTooltip.infoList) and (GameTooltip.infoList[1]) and (GameTooltip.infoList[1].tooltipData) and (GameTooltip.infoList[1].tooltipData.dataInstanceID);
            TooltipFrame:SetGameTooltipOwner(self, dataInstanceID);
        elseif self.tooltipFunc then
            TooltipFrame.gametooltipDataInstanceID = nil;
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            if self.tooltipFunc(GameTooltip) then
                TooltipFrame:ShowGameTooltipBackground();
            else
                GameTooltip:Hide();
            end
        end
    end

    function Mixin_TraitButton:ShowCustomTooltip()
        TooltipFrame.owner = self;
        TooltipFrame:SetItemByID(self.itemID);
    end

    function Mixin_TraitButton:OnEnter(motion, fromActionButton)
        SlotHighlight:HighlightSlot(self);
        MainFrame:SetFocusedButton(self);
    end

    function Mixin_TraitButton:OnLeave(motion, fromActionButton)
        if (not fromActionButton) and (self:IsShown() and self:IsMouseOver()) then return end;

        SlotHighlight:HighlightSlot(nil);
        MainFrame:HideTooltip();
        MainFrame:SetFocusedButton(nil);
    end

    function Mixin_TraitButton:SetActive()
        if self.traitState == 3 or self.traitState == 4 then
            MainFrame:ShineSlot(self);
        end
        self.traitState = 2;
        self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturation(0);
        self:SetBorderByState("active");
    end

    function Mixin_TraitButton:SetInactive()
        self.traitState = 1;
        self.Icon:SetTexture(self.iconFile);
        self.Icon:SetVertexColor(0.8, 0.8, 0.8);
        self.Icon:SetDesaturation(1);
        self:SetBorderByState("inactive");
    end

    function Mixin_TraitButton:SetUncollected()
        self.traitState = 0;
        self:SetBorderByState("inactive");
        self:SetIconEmpty();  --debug
        --self.Icon:SetTexture(self.iconFile);
        --self.Icon:SetVertexColor(0.8, 0.8, 0.8);
        --self.Icon:SetDesaturation(1);
    end

    function Mixin_TraitButton:SetAvailable()
        self.traitState = 3;
        self.Icon:SetTexture(self.iconFile);
        self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturation(0);
        self:SetBorderByState("available");
    end

    function Mixin_TraitButton:SetSelectable()
        self.traitState = 4;
        self:SetIconEmpty();
        self:SetBorderByState("available");
    end

    function Mixin_TraitButton:SetDimmed()
        if self.traitState == 3 then
            MainFrame:ShineSlot(self);
        end
        self.traitState = 2;
        self.Icon:SetTexture(self.iconFile);
        self.Icon:SetVertexColor(167/255, 154/255, 96/255);
        --self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturation(1);
        self:SetBorderByState("dimmed")
    end

    function Mixin_TraitButton:SetIconEmpty()
        self.Icon:SetVertexColor(1, 1, 1);
        self.Icon:SetDesaturation(0);
        self.Icon:SetTexture(PATH.."Gem-Empty");
    end

    function Mixin_TraitButton:OnClick(button)
        if self.onClickFunc and self.onClickFunc(button) then
            return
        end

        if button == "LeftButton" then

        elseif button == "RightButton" then

        end
    end

    function Mixin_TraitButton:SetButtonSize(buttonSize, iconSize)
        --For unique sized buttons
        self:SetSize(buttonSize, buttonSize);
        self.Icon:SetSize(iconSize, iconSize);
    end

    function Mixin_TraitButton:ResetButtonSize()
        self:SetSize(TRAIT_BUTTON_SIZE, TRAIT_BUTTON_SIZE);
        self.Icon:SetSize(30, 30);  --38
    end

    function Mixin_TraitButton:SetBorderByState(state)
        if self.borderTextures then
            AtlasUtil:SetAtlas(self.Border, self.borderTextures[state]);
        end
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
    local ON_EQUIP = "^".. (ITEM_SPELL_TRIGGER_ONEQUIP or "Equip:").."%s?";

    function Mixin_TooltipFrame:RemoveOnEquipText(text)
        return gusb(text, ON_EQUIP, "");
    end

    function Mixin_TooltipFrame:ShowGameTooltipBackground()
        SharedTooltip_SetBackdropStyle(GameTooltip, nil, true);

        local background = self.GameTooltipBackground;

        if not background then
            background = CreateFrame("Frame", nil, self);
            self.GameTooltipBackground = background;
            NarciAPI.NineSliceUtil.SetUpBorder(background, "classTalentTraitTransparent");

            background:SetScript("OnHide", function()
                background:Hide();
                background:ClearAllPoints();
            end);

            background:SetIgnoreParentAlpha(true);
        end

        local offset = 2;

        background:ClearAllPoints();
        background:SetPoint("TOPLEFT", GameTooltip, "TOPLEFT", -offset, offset);
        background:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMRIGHT", offset, -offset);
        background:Show();
        self:Show();
        self:ClearLines();
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

        local showBG;

        if title and title ~= "" then
            showBG = true;
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


        local statusText;
        local actionText;
        local colorIndex;   --0:Grey, 1:Yellow, 2:Green, 3:Red
        local traitState = self.owner.traitState;

        if traitState == 0 then
            statusText = L["Gem Uncollected"];
            colorIndex = 0;
        elseif traitState == 1 then

        elseif traitState == 2 then
            if InCombatLockdown() then
                actionText = L["Gem Removal Combat"];
                colorIndex = 3;
            else
                if Gemma:DoesBagHaveFreeSlot() then
                    actionText = L["Gem Removal Instruction"];
                    colorIndex = 1;
                else
                    actionText = L["Gem Removal Bag Full"];
                    colorIndex = 3;
                end
            end
        elseif traitState == 3 then
            if InCombatLockdown() then
                actionText = L["Gem Removal Combat"];
                colorIndex = 3;
            else
                actionText = L["Gemma Click To Insert"];
                colorIndex = 2;
            end
        end

        self.Header:SetText(title);
        self.Text1:SetText(desc);
        self.Text1:SetTextColor(0.88, 0.88, 0.88);

        local text2Height;

        if desc and (actionText or statusText) then
            self.Text2:SetText(actionText or statusText);
            text2Height = self.Text2:GetHeight() + 20;
            local r, g, b= GetColorByIndex(colorIndex);
            self.Text2:SetTextColor(r, g, b);
        else
            self.Text2:SetText(nil);
            text2Height = 0;
        end

        if showBG then
            local textHeight = self.Header:GetHeight() + self.Text1:GetHeight() + text2Height + 10;
            local textWidth = math.max(self.Header:GetWrappedWidth(), self.Text1:GetWrappedWidth());
            self.Background:SetSize(textWidth + 96, textHeight + 32);
            self.Background:Show();
        else
            self.Background:Hide();
        end

        FadeFrame(TooltipFrame, 0.15, 1);
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
        self.Header:SetText(nil);
        self.Text1:SetText(nil);
        self.Text2:SetText(nil);
        self.Background:Hide();
    end

    function Mixin_TooltipFrame:UpdateTooltipInfo()
        self:ProcessTooltipInfo();
    end

    function Mixin_TooltipFrame:SetDescriptionLine(lineIndex)
        self.descLineIndex = lineIndex;
    end

    function Mixin_TooltipFrame:SetGameTooltipOwner(slotButton, gametooltipDataInstanceID)
        self.gametooltipOwner = slotButton;
        self.gametooltipDataInstanceID = gametooltipDataInstanceID;
    end

    function Mixin_TooltipFrame:OnShow()
        self:RegisterEvent("TOOLTIP_DATA_UPDATE");
    end

    function Mixin_TooltipFrame:OnHide()
        self.dataInstanceID = nil;
        self.gametooltipDataInstanceID = nil;
        self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
    end

    function Mixin_TooltipFrame:OnEvent(event, ...)
        if event == "TOOLTIP_DATA_UPDATE" then
            local dataInstanceID = ...
            if dataInstanceID then
                if dataInstanceID == self.dataInstanceID then
                    self:UpdateTooltipInfo();
                elseif dataInstanceID == self.gametooltipDataInstanceID then
                    After(0, function()
                        if self.gametooltipOwner and self.gametooltipOwner:IsShown() and self.gametooltipOwner:IsMouseOver() then
                            self.gametooltipOwner:ShowGameTooltip();
                        end
                    end)
                end
            end
        end
    end

    function Mixin_TooltipFrame:SetMaxWdith(width)
        self:SetWidth(width);
        self:SetHeight(80);
        self.Header:SetWidth(width);
        self.Text1:SetWidth(width);
        self.Text2:SetWidth(width);
    end

    function Mixin_TooltipFrame:OnLoad()
        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnHide", self.OnHide);
        self:SetScript("OnEvent", self.OnEvent);


        AtlasUtil:SetAtlas(self.Background, "remix-ui-tooltip-bg");
        --self.Background:SetColorTexture(0, 0, 0, 0.5);

        local flag = "OUTLINE";
        self.Header:SetFont(FONT_FILE, 14, flag);
        self.Text1:SetFont(FONT_FILE, 12, flag);
        self.Text2:SetFont(FONT_FILE, 12, flag);
    end
end




local Mixin_SlotHighlight = {};
do
    local HIGHLIGHT_TEXTURE = {
        Hexagon = {
            Normal = {
                atlas = "remix-hexagon-highlight",
                alphaMode = "ADD",
                alpha = 0.8,
            },

            Dashed = {
                atlas = "remix-hexagon-dashedhighlight",
                alphaMode = "ADD",
                alpha = 0.8,
            },
        },

        BigSquare = {
            Normal = {
                atlas = "remix-bigsquare-highlight",
                alphaMode = "ADD",
                alpha = 0.5,
            },

            Dashed = {
                atlas = "remix-bigsquare-dashedhighlight",
                alphaMode = "ADD",
                alpha = 0.67,
            },
        },
    };

    function Mixin_SlotHighlight:SetShape(shape)
        local data = HIGHLIGHT_TEXTURE[shape];
        self.data = data;
        AtlasUtil:SetAtlas(self.Texture, data.Normal.atlas);
        self.Texture:SetBlendMode(data.Normal.alphaMode);
        self:SetAlpha(data.Normal.alpha);
        self.isDashed = false;
    end

    function Mixin_SlotHighlight:HighlightSlot(slot)
        self:ClearAllPoints();
        if slot then
            self:Show();
            self:SetParent(slot);
            self:SetPoint("CENTER", slot, "CENTER", 0, 0);

            local newStyle;

            if slot.traitState == 3 or slot.traitState == 4 then
                if not self.isDashed then
                    self.isDashed = true;
                    newStyle = self.data.Dashed;
                end
            else
                if self.isDashed then
                    self.isDashed = false;
                    newStyle = self.data.Normal;
                end
            end

            if newStyle then
                AtlasUtil:SetAtlas(self.Texture, newStyle.atlas);
                self.Texture:SetBlendMode(newStyle.alphaMode);
                self:SetAlpha(newStyle.alpha);
            end
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
        dot:Hide();

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




local Mixin_MouseOverFrame = {};
do  --Attribute Assignment
    --See StatAssignment.lua for StatButton methods
    local MinusPlusButtonMixin = {};

    function MinusPlusButtonMixin:OnClick()
        MainFrame:ShowActionBlocker();
    end

    function MinusPlusButtonMixin:OnMouseDown()
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, -1);
    end

    function MinusPlusButtonMixin:OnMouseUp()
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0);
    end

    function MinusPlusButtonMixin:OnEnter(motion, fromActionButton)
        self.owner:HighlightButton(self);
        if fromActionButton then return end;

        local itemID = Gemma:GetBestStatGemForAction(self.owner.statType, self.direction);
        if itemID then
            local ActionButton = AcquireActionButton(self);
            if ActionButton then
                if self.direction < 0 then
                    ActionButton:SetAction_RemovePandariaPrimaryGem(itemID);
                else
                    ActionButton:SetAction_InsertPandariaPrimaryGem(itemID);
                end
            end
        end
    end

    function MinusPlusButtonMixin:OnLeave(motion, fromActionButton)
        --if (not fromActionButton) and (self:IsShown() and self:IsMouseOver()) then return end;
        if (not fromActionButton) and (self:IsShown() and self:IsMouseOver()) then return end;

        self.owner:HighlightButton(nil);
    end

    local function CreateMinusPlusButton(parent, direction)
        local button = CreateFrame("Button", nil, parent);
        button:SetSize(36, 24); --25

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

    function Mixin_MouseOverFrame:OnLoad()
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

        self.Count:SetFont(FONT_FILE, 16, "");
        self.Count:SetTextColor(0, 0, 0);
    end

    function Mixin_MouseOverFrame:OnLeave()

    end

    function Mixin_MouseOverFrame:OnHide()
        self:Hide();
        self:HighlightButton(nil);
    end

    function Mixin_MouseOverFrame:HighlightButton(minusplusButton)
        self.Highlight:ClearAllPoints();
        if minusplusButton then
            self.Highlight:SetPoint("CENTER", minusplusButton, "CENTER", 0, 0);
            self.Highlight:Show();
            --FadeFrame(self.Highlight, 0.15, 1, 0);
        else
            self.Highlight:Hide();

            if (self.statButton and self.statButton:IsMouseOver()) and (not MainFrame.ActionBlocker:IsShown()) then
                
            else
                self:ShowStatAssignmentDetail(nil);
            end
        end
    end

    function Mixin_MouseOverFrame:ShowStatAssignmentDetail(statButton)
        self:ClearAllPoints();
        self.statButton = statButton;

        if statButton then
            self:SetPoint("CENTER", statButton, "CENTER", 0, 0);
            self.MinusButton:SetShown(statButton.showMinusButton);
            self.PlusButton:SetShown(statButton.showPlusButton);
            self.statType = statButton.index;
            self:Show();
            FadeFrame(self, 0.15, 1);
        else
            self.statType = nil;
            --self:Hide();
            FadeFrame(self, 0.15, 0);
            return
        end

        self.Count:SetText(statButton.Count:GetText());
    end
end




local Mixin_GemList = {};
do
    local ITEMS_PER_PAGE = 8;
    local LISTBUTTON_HEIGHT = 44;
    local FROM_Y = -40 -4;

    local ItemDataProvider;

    local Mixin_GemListButton = {};

    function Mixin_GemListButton:OnLoad()
        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnClick", self.OnClick);

        self.Text1:SetFont(FONT_FILE, 14, "OUTLINE");

        local delay = self.index * 0.05;
        self.AnimFlyIn.Delay1:SetStartDelay(delay);
        self.AnimFlyIn.Delay2:SetStartDelay(delay);
        self.AnimFlyIn.Delay3:SetStartDelay(delay);
        self.AnimFlyIn.Delay4:SetStartDelay(delay);

        self.isGemListButton = true;
    end

    function Mixin_GemListButton:OnClick(button)
        if button == "RightButton" then
            MainFrame:CloseGemList();
            return
        end

        if button == "LeftButton" then
            
        end
    end

    function Mixin_GemListButton:OnEnter()
        ListHighlight:ClearAllPoints();
        ListHighlight:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
        ListHighlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
        ListHighlight:Show();

        --Mixin_TraitButton.ShowGameTooltip(self);

        MainFrame:SetFocusedButton(self);
    end

    function Mixin_GemListButton:OnLeave(motion, fromActionButton)
        if (not fromActionButton) and (self:IsShown() and self:IsMouseOver()) then return end;
        ListHighlight:Hide();
        MainFrame:HideTooltip();
        MainFrame:SetFocusedButton(nil);
    end

    function Mixin_GemListButton:SetItem(itemID)
        self.itemID = itemID;
        self.Icon:SetTexture(GetItemIcon(itemID));
        self.Icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);

        local name = ItemCache:GetItemName(itemID, self);
        self.Text1:SetText(name);

        local quality = ItemCache:GetItemQuality(itemID, self);
        local r, g, b = GetItemQualityColor(quality);

        if (not ItemDataProvider) or ItemDataProvider:IsGemCollected(itemID) then
            self.Icon:SetDesaturation(0);
            self.Icon:SetVertexColor(1, 1, 1);
            self.traitState = 3;
        else
            self.Icon:SetDesaturation(1);
            self.Icon:SetVertexColor(0.8, 0.8, 0.8);
            r, g, b = 0.5, 0.5, 0.5;
            self.traitState = 0;
        end

        self.Text1:SetTextColor(r, g, b);
    end

    function Mixin_GemListButton:OnItemLoaded(itemID)
        if itemID == self.itemID then
            self:SetItem(itemID);
        end
    end

    function Mixin_GemListButton:ClearItem()
        self.itemID = nil;
        self:Hide();
    end

    function Mixin_GemListButton:PlayFlyInAnimation()
        self.AnimFlyIn:Stop();
        if self:IsShown() then
            self.AnimFlyIn:Play();
        end
    end

    function Mixin_GemListButton:ShowGameTooltip()
        Mixin_TraitButton.ShowGameTooltip(self);
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

        AtlasUtil:SetAtlas(self.SelectionFrame.Border, "remix-square-yellow");
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
        local itemID;

        self.SelectionFrame:Hide();

        MainFrame:SetFocusedButton(nil);

        for i = 1, ITEMS_PER_PAGE do
            dataIndex = fromIndex + i;
            button = self.listButtons[i];
            itemID = self.itemList[dataIndex];

            if itemID then
                if not button then
                    button = CreateFrame("Button", nil, self, "NarciGemManagerGemListButtonTemplate");
                    self.listButtons[i] = button;
                    Mixin(button, Mixin_GemListButton);
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

    function Mixin_GemList:UpdatePage()
        if self:IsShown() and self.page then
            self:SetPage(self.page);
        end
    end

    function Mixin_GemList:SetItemList(itemList, title, dataProvider)
        self.Title:SetText(title);

        if itemList ~= self.itemList then
            self.itemList = itemList;
        else
            if self.page then
                self:SetPage(self.page);
                return
            end
        end

        ItemDataProvider = dataProvider;

        local bestPage = 1;
        for i, itemID in ipairs(itemList) do
            if dataProvider:IsGemCollected(itemID) then
                bestPage = math.floor((i - 1) / ITEMS_PER_PAGE) + 1;
                break
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

    function Mixin_GemList:Close()
        self:Hide();
    end

    function Mixin_GemList:PlayFlyInAnimation()
        for i, button in ipairs(self.listButtons) do
            button:PlayFlyInAnimation();
        end
    end
end




local CreateProgressBar;
do
    local Mixin_ProgressBar = {};

    function Mixin_ProgressBar:OnLoad()
        self:SetSize(200, 18);

        local flag = "OUTLINE";
        self.Title:SetFont(FONT_FILE, 12, flag);
        self.Title:SetTextColor(0.88, 0.88, 0.88);

        local Fill = self.Fill;
        Fill:ClearAllPoints();
        Fill:SetPoint("LEFT", self, "LEFT", 6, 0);

        local fillAtlas = "gemma-progressbar-fill";

        AtlasUtil:SetAtlas(self.Border, "gemma-progressbar-border");
        AtlasUtil:SetAtlas(Fill, fillAtlas);
        AtlasUtil:SetAtlas(self.Background, "gemma-progressbar-bg");

        local left, right, top, bottom = AtlasUtil:GetTexCoord(fillAtlas);
        self.left = left;
        self.top = top;
        self.bottom = bottom;
        self.fillTexRange = right - left;
        self.fillFullWidth = 188;

        self:SetScript("OnEvent", self.OnEvent);
        self:SetScript("OnHide", self.OnHide);
    end

    function Mixin_ProgressBar:SetCastText(text)
        self.Title:SetText(text);
    end

    function Mixin_ProgressBar:SetProgress(progress)
        if progress <= 0 then
            progress = 0;
            self.Fill:Hide();
            return
        else
            self.Fill:Show();
            if progress > 1 then
                progress = 1;
            end
        end

        self.Fill:SetWidth(self.fillFullWidth * progress);
        self.Fill:SetTexCoord(self.left, self.left + self.fillTexRange * progress, self.top, self.bottom);
    end

    function Mixin_ProgressBar:ListenSpellCastEvent(state)
        if state then
            --UNIT_SPELLCAST_START is controlled by MainFrame
            self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
            self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player");
            self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player");
            self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player");
        else
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
            self:UnregisterEvent("UNIT_SPELLCAST_FAILED");
            self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
            self:UnregisterEvent("UNIT_SPELLCAST_STOP");
        end
    end

    function Mixin_ProgressBar:OnHide()
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        self:ListenSpellCastEvent(false);
        Spinner:Hide();
    end

    function Mixin_ProgressBar:OnEvent(event, ...)
        --FAILED, INTERRUPTED fire after STOP
        --print(GetTime(), event);    --debug

        if event == "UNIT_SPELLCAST_FAILED" then
            self:ListenSpellCastEvent(false);
            self:DispalyErrorMessage(FAILED);
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            self:ListenSpellCastEvent(false);
            self:DispalyErrorMessage(SPELL_FAILED_INTERRUPTED);
        end
    end

    function Mixin_ProgressBar:DispalyErrorMessage(error)
        self:SetCastText(error);
        self:SetScript("OnUpdate", nil);
        self:PlayOutro(1);
        AtlasUtil:SetAtlas(self.Fill, "gemma-progressbar-fillred");
    end

    local function Fill_OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        if self.t >= self.duration then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:OnSucceeded();
        else
            self:SetProgress(self.t / self.duration);
        end
    end

    function Mixin_ProgressBar:OnSucceeded()
        self:SetProgress(1);
        self:SetScript("OnUpdate", nil);
        self:PlayOutro();
    end

    function Mixin_ProgressBar:SetDuration(duration)
        self.t = 0;
        self.duration = duration;
        self:SetProgress(0);
        self:SetScript("OnUpdate", Fill_OnUpdate);
    end

    function Mixin_ProgressBar:UpdateSpellCast()
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo("player");
        if name then
            self:SetCastText(text);
            self:PlayIntro();
            self:Show();
            self:ListenSpellCastEvent(true);
            self:SetDuration((endTimeMS - startTimeMS)/1000);
        else
            self:Hide();
        end
    end

    function Mixin_ProgressBar:UpdateSpellCooldown(spellID)
        local start, duration, enabled, modRate = GetSpellCooldown(spellID);
        if enabled == 1 and start > 0 and duration > 0 then
            local cdLeft = start + duration - GetTime();
            self:SetCastText("");
            self:PlayIntro();
            self:Show();
            self:ListenSpellCastEvent(true);
            self:SetDuration(cdLeft);
        else
            self:Hide();
        end
    end

    function Mixin_ProgressBar:PlayIntro()
        self:StopAnimating();
        self.AnimIn:Play();

        FadeFrame(Spinner, 0.5, 1, 0);
    end

    function Mixin_ProgressBar:PlayOutro(delay)
        delay = delay or 0;
        self:StopAnimating();
        self.AnimOut.Fade:SetStartDelay(delay);
        self.AnimOut:Play();

        FadeFrame(Spinner, 0.5, 0);
    end

    function CreateProgressBar(parent)
        local f = CreateFrame("Frame", nil, parent, "NarciGemManagerProgressBarTemplate");
        f:Hide();
        Mixin(f, Mixin_ProgressBar);
        f:OnLoad();

        return f
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
    local headerHeight = TAB_BUTTON_HEIGHT + FRAME_PADDING;
    self.HeaderFrame:SetHeight(headerHeight);

    Gemma.MainFrame = self;
    MainFrame = self;
    TooltipFrame = self.TooltipFrame;
    SlotHighlight = self.SlotFrame.ButtonHighlight;
    PointsDisplay = self.SlotFrame.PointsDisplay;
    MouseOverFrame = self.SlotFrame.MouseOverFrame;
    GemList = self.GemList;
    ListHighlight = self.GemList.ButtonHighlight;

    Mixin(SlotHighlight, Mixin_SlotHighlight);
    Mixin(GemList, Mixin_GemList);

    CallbackRegistry:Register("GemManager.BagScan.OnStart", MainFrame.OnBagUpdateStart, MainFrame);
end

function NarciGemManagerMixin:AnchorToPaperDollFrame()
    if self.positionSet then
        return
    else
        self.positionSet = true;
    end

    self:ClearAllPoints();
    self:SetParent(PaperDollFrame);

    if CharacterStatsPaneilvl and Gemma.PaperdollWidget then    --Chonky Character Sheet
        local f = Gemma.PaperdollWidget;
        self:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, 0);
    else
        local f = PaperDollFrame;
        self:SetPoint("TOPLEFT", f, "TOPRIGHT", 24, 0);
    end
end

function NarciGemManagerMixin:OnShow()
    if self.Init then
        self:Init();
    end

    self:SetDataProviderByName("Pandaria");
    self:AnchorToPaperDollFrame();

    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");

    self:UpdateTabGreenDot();
    self:AutoSelectBestTab();
end

function NarciGemManagerMixin:OnHide()
    self:Hide();

    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");

    self:SetWatchedSpell(nil);
    self:SetFocusedButton(nil);
    self:HideTooltip();

    SlotHighlight:Hide();

    if ProgressBar then
        ProgressBar:Hide();
    end

    self:CloseGemList();
end

function NarciGemManagerMixin:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_START" then
        local _, _, spellID = ...
        --print(spellID)
        if spellID and spellID == self.watchedSpellID then
            ProgressBar:UpdateSpellCast();
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        --Changing gem in an equipped item doesn't always trigger this
    end

    --print(event)
end

function NarciGemManagerMixin:SetWatchedSpell(spellID)
    self.watchedSpellID = spellID;
    if spellID then
        self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player");
    else
        self:UnregisterEvent("UNIT_SPELLCAST_START");
    end
end

function NarciGemManagerMixin:Init()
    self.Init = nil;

    Mixin(TooltipFrame, Mixin_TooltipFrame);
    TooltipFrame:SetMaxWdith(FRAME_WIDTH - 60);
    TooltipFrame:OnLoad();

    local TabButtonSelection = self.HeaderFrame.TabButtonContainer.Selection;
    TabButtonSelection:SetTexture(PATH.."TabButtonSelection");
    TabButtonSelection:SetBlendMode("ADD");

    Mixin(PointsDisplay, Mixin_PointsDisplay);
    PointsDisplay:OnLoad();
    PointsDisplay:ClearAllPoints();
    PointsDisplay:SetPoint("TOP", self.HeaderFrame, "BOTTOM", 0, -20);
    PointsDisplay:SetLabel("Points Available");
    PointsDisplay:SetAmount(3);

    GemList:OnLoad();

    Mixin(MouseOverFrame, Mixin_MouseOverFrame);
    MouseOverFrame:OnLoad();

    AtlasUtil:SetAtlas(ListHighlight.Texture, "remix-listbutton-highlight");
    ListHighlight.Texture:SetBlendMode("ADD");

    SetupModelScene(self.ModelScene);


    ProgressBar = CreateProgressBar(self.SlotFrame);
    ProgressBar:SetPoint("BOTTOM", self, "BOTTOM", 0, 16);


    Spinner = CreateFrame("Frame", nil, self.SlotFrame, "NarciGemManagerLoadingSpinnerTemplate");
    Spinner:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    Spinner:Hide();
    AtlasUtil:SetAtlas(Spinner.Circle, "gemma-spinner-circle");
    AtlasUtil:SetAtlas(Spinner.Dial, "gemma-spinner-dial");
    Spinner.DialMask:SetTexture(PATH.."Mask-Radial", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    Spinner.AnimSpin:Play();


    self.ActionBlocker:SetScript("OnUpdate", function(f, elapsed)
        f.t = f.t + elapsed;
        if f.t > ACTIONBLOCKER_DURATION then
            f.t = 0;
            f:Hide();
            FadeFrame(self.LoadingIndicator, 0.15, 0);
        end
    end);

    AtlasUtil:SetAtlas(self.LoadingIndicator.Icon, "remix-ui-loadingicon");
    self.LoadingIndicator.AnimLoading:Play();
    self:CenterLoadingIndicator(false);

    local Alert = self.SlotFrame.NoSocketAlert;
    Alert:SetFont(FONT_FILE, 14, "OUTLINE");
    Alert:SetShadowOffset(1, -1);
    Alert:SetShadowColor(0, 0, 0);
    Alert:SetTextColor(0.5, 0.5, 0.5);
    Alert:SetText(L["No Sockets Were Found"]);
end




do  --Process OnEnter after a short delay
    local MouseOverSolver;
    local FocusedButton;

    local function ProcessFocusedButton()
        if not (FocusedButton and FocusedButton:IsVisible()) then return end;

        Mixin_TraitButton[TOOLTIP_METHOD](FocusedButton);

        local itemID = FocusedButton.itemID;
        local traitState = FocusedButton.traitState;
        if itemID and (traitState == 2 or traitState == 3) then
            --2: Active, 3:Available(Select)
            local ActionButton = AcquireActionButton(FocusedButton);
            if ActionButton then
                local method = Gemma:GetActionButtonMethod(itemID);
                ActionButton[method](ActionButton, itemID);  --SetAction_RemoveTinker   SetAction_RemovePrimordialStone
            end
        end
    end

    local function MouseOverSolver_OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        if self.t > 0.033 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            ProcessFocusedButton();
        end
    end

    function NarciGemManagerMixin:SetFocusedButton(button, forceUpdate)
        if button == FocusedButton and (not forceUpdate) then return end;
        FocusedButton = button;

        if not MouseOverSolver then
            MouseOverSolver = CreateFrame("Frame", nil, self);
        end

        MouseOverSolver.t = 0;

        if button ~= nil then
            MouseOverSolver:SetScript("OnUpdate", MouseOverSolver_OnUpdate);
        else
            MouseOverSolver:SetScript("OnUpdate", nil);
        end
    end
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
    if self.slotButtons and self.numSlotButtons ~= 0 then
        for _, button in pairs(self.slotButtons) do
            button:Hide();
            button:ClearAllPoints();
            button.itemID = nil;
            button.traitState = nil;
            button.tooltipFunc = nil;
            button.onClickFunc = nil;
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
    self:ReleaseStatButtons();
    self:ReleaseTextures();
    self:ShineSlot(nil);
    self:ShowStatAssignmentDetail(nil);
    self:ShowNoSocketAlert(false);
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
        container = self.SlotFrame.FrontFrame;
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
        texture = container:CreateTexture(nil, drawLayer);
        pool[index] = texture;
    end

    texture:Show();
    texture:SetDrawLayer(drawLayer);

    return texture
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

function NarciGemManagerMixin:UpdateCurrentTab()

end

function NarciGemManagerMixin:UpdateTabGreenDot()

end


function NarciGemManagerMixin:OpenGemList()
    self.gemListShown = true;
    self.autoShowGemList = nil;
    self.SlotFrame:Hide();
    self.HeaderFrame.TabButtonContainer:Hide();
    SlotHighlight:HighlightSlot(nil);
    self:SetFocusedButton(nil);
    self:HideTooltip();
    GemList:Show();
    GemList:PlayFlyInAnimation();
    FadeFrame(self.ModelScene, 0.1, 0.2);
    self:CenterLoadingIndicator(true);
end

function NarciGemManagerMixin:CloseGemList()
    if not self.gemListShown then return end;

    self.gemListShown = nil;
    GemList:Close();
    self.HeaderFrame.TabButtonContainer:Show();

    if self.useSlotFrame then
        self.SlotFrame:Show();
    end

    FadeFrame(self.ModelScene, 0.5, 1);

    self:CenterLoadingIndicator(false);
    self:HideTooltip();
end

function NarciGemManagerMixin:HideTooltip()
    GameTooltip:Hide();
    --TooltipFrame:Hide();
    FadeFrame(TooltipFrame, 0.2, 0);
end

function NarciGemManagerMixin:AnchorSpinnerToButton(button)
    if not button then return end;

    Spinner:ClearAllPoints();
    Spinner:SetPoint("CENTER", button, "CENTER", 0, 0);
    Spinner:SetFrameLevel(button:GetFrameLevel() - 1);
end

function NarciGemManagerMixin:ToggleUI()
    self:SetShown(not self:IsShown());
end

function NarciGemManagerMixin:SetPointDisplayAmount(amount)
    PointsDisplay:SetAmount(amount);
    if amount > 0 then
        PointsDisplay:Show();
    else
        PointsDisplay:Hide();
    end
end

function NarciGemManagerMixin:ShowActionBlocker()
    self.ActionBlocker.t = 0;
    self.ActionBlocker:Show();
    Gemma.HideActionButton();
    self:SetFocusedButton(nil);
    self:HideTooltip();
    --MouseOverFrame:Hide();

    FadeFrame(self.LoadingIndicator, 0.15, 1);
end

function NarciGemManagerMixin:OnBagUpdateStart()
    self:ShowActionBlocker();
end

function NarciGemManagerMixin:OnBagUpdateComplete()
    self:UpdateCurrentTab();
    self:UpdateTabGreenDot();

    --self.ActionBlocker:Hide();
end

function NarciGemManagerMixin:AutoSelectBestTab()
    if self.tabButtons then
        for id, button in ipairs(self.tabButtons) do
            if button.GreenDot:IsShown() then
                self:SelectTabByID(id);
                return
            end
        end
    end

    if not self.tabID then
        self:SelectTabByID(1);
    end
end

function NarciGemManagerMixin:ShowNoSocketAlert(state)
    self.SlotFrame.NoSocketAlert:SetShown(state);
end

function NarciGemManagerMixin:ShowStatAssignmentDetail(statButton)
    if MouseOverFrame.ShowStatAssignmentDetail then
        MouseOverFrame:ShowStatAssignmentDetail(statButton);
    end
end

function NarciGemManagerMixin:CenterLoadingIndicator(isCentered)
    self.LoadingIndicator:ClearAllPoints();
    if isCentered then
        self.LoadingIndicator:SetPoint("CENTER", self.SlotFrame, "CENTER", 0, 0);
    else
        self.LoadingIndicator:SetPoint("CENTER", self, "BOTTOM", 0, 40);
    end
end