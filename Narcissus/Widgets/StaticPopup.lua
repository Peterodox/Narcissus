local _, addon = ...
local L = Narci.L;


local InCombatLockdown = InCombatLockdown;
local CreateKeyChordStringUsingMetaKeyState = CreateKeyChordStringUsingMetaKeyState;


local Def = {
    FrameWidth = 320,
    FramePadding = 32,

    WidgetGapY = 8,
    LargeGapY = 16,

    DefaultWidgetWith = 240,   --192
};


local MainFrame;


local StaticPopupMixin = {};
do  --StaticPopup Basic
    function StaticPopupMixin:Close()
        self:Hide();
    end

    function StaticPopupMixin:FindBestPosition()
        self:ClearAllPoints();
        self:SetPoint("TOP", UIParent, "TOP", 0, -135);
    end

    function StaticPopupMixin:Reset()
        self.layoutObjects = {};
        self.fontStringPool:ReleaseAll();
        self.checkboxPool:ReleaseAll();
        self.EditBox:Hide();
        self.EditBox.isClipboard = nil;
        self.CloseButton:Hide();
        self.Button1:Hide();
        self.Button2:Hide();
        self:ListenHotkey(false);
    end

    function StaticPopupMixin:AddLayoutObject(object, preOffsetY, postOffsetY)
        table.insert(self.layoutObjects, {
            object = object,
            preOffsetY = preOffsetY or 0,
            postOffsetY = postOffsetY or Def.WidgetGapY;
        });
    end

    function StaticPopupMixin:Layout()
        local frameWidth = Def.FrameWidth;
        local padding = Def.FramePadding;

        local offsetY = padding;
        local widgetWidth = Def.DefaultWidgetWith --frameWidth - 2 * padding;
        local total = #self.layoutObjects;

        for i, v in ipairs(self.layoutObjects) do
            local object = v.object;
            if object:IsObjectType("FontString") then
                object:SetSpacing(2);
            end
            object:ClearAllPoints();
            offsetY = offsetY + v.preOffsetY;
            object:SetPoint("TOP", self, "TOP", 0, -offsetY);
            if not object.useFixedWidth then
                if object.SetEffectiveWidth then
                    object:SetEffectiveWidth(widgetWidth);
                else
                    object:SetWidth(widgetWidth);
                end
            end
            object:Show();
            offsetY = offsetY + object:GetHeight();
            if i < total then
                offsetY = offsetY + v.postOffsetY;
            end
            offsetY = math.ceil(offsetY);
        end

        if self.Button1:IsShown() then
            offsetY = offsetY + Def.LargeGapY + Def.WidgetGapY;
            self.Button1:ClearAllPoints();
            self.Button2:ClearAllPoints();
            local buttonHeight = 28;
            local buttonWidth;
            if self.Button2:IsShown() then
                local buttonGap = Def.WidgetGapY;
                buttonWidth = 0.5 * (Def.DefaultWidgetWith - buttonGap);
                self.Button1:SetPoint("TOPRIGHT", self, "TOP", -0.5*buttonGap, -offsetY);
                self.Button2:SetPoint("TOPLEFT", self, "TOP", 0.5*buttonGap, -offsetY);
            else
                buttonWidth = Def.DefaultWidgetWith;
                self.Button1:SetPoint("TOP", self, "TOP", 0, -offsetY);
            end
            self.Button1:SetSize(buttonWidth, buttonHeight);
            self.Button2:SetSize(buttonWidth, buttonHeight);
            offsetY = offsetY + buttonHeight;
        end

        offsetY = offsetY + padding;

        self:SetSize(frameWidth, offsetY);
    end

    function StaticPopupMixin:OnShow()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
        self:RegisterEvent("PLAYER_REGEN_ENABLED");
        self:RegisterEvent("PLAYER_REGEN_DISABLED");
        self:SetScript("OnEvent", self.OnEvent);
        if not InCombatLockdown() then
            self:SetScript("OnKeyDown", self.OnKeyDown);
        end
    end

    function StaticPopupMixin:OnHide()
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
        self:UnregisterEvent("PLAYER_REGEN_ENABLED");
        self:UnregisterEvent("PLAYER_REGEN_DISABLED");
        self:SetScript("OnEvent", nil);
        self:SetScript("OnKeyDown", nil);
    end

    function StaticPopupMixin:OnLoad()
        self.OnLoad = nil;

        self.CloseButton:SetScript("OnClick", function()
            self:Close();
        end);

        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnHide", self.OnHide);
    end

    function StaticPopupMixin:TryShow()
        self:FindBestPosition();
        self:Layout();
        self:Show();
    end

    function StaticPopupMixin:OnKeyDown(key)
        local propagate;
        if key == "ESCAPE" then
            propagate = false;
            self:Hide();
        else
            propagate = true;
        end

        if not InCombatLockdown() then
           self:SetPropagateKeyboardInput(propagate);
        end
    end

    function StaticPopupMixin:OnEvent(event)
        if event == "PLAYER_REGEN_ENABLED" then
            self:SetScript("OnKeyDown", self.OnKeyDown);
        elseif event == "PLAYER_REGEN_DISABLED" then
            self:SetScript("OnKeyDown", nil);
        end
    end
end


do  --StaticPopup Clipboard
    function StaticPopupMixin:SetupClipboard(instruction, content)
        self:Reset();

        local header = self.fontStringPool:Acquire();
        header:SetText(instruction);
        header:SetTextColor(0.6, 0.6, 0.6);
        self:AddLayoutObject(header);

        self.EditBox:Show();
        self.EditBox:SetDefaultText(content);
        self.EditBox.isClipboard = true;
        self:AddLayoutObject(self.EditBox);

        self.CloseButton:Show();

        self:ListenHotkey(true);
        self:TryShow();
        self.EditBox:SetFocus();
    end

    local function KeyListener_OnKeyDown(self, key)
        local keys = CreateKeyChordStringUsingMetaKeyState(key);
        if (keys == "CTRL-C" or key == "COMMAND-C") and MainFrame.EditBox:HasFocus() then
            self:SetScript("OnKeyDown", nil);
            MainFrame:OnCopySuccess();
        end
    end

    function StaticPopupMixin:ListenHotkey(state)
        if state then
            self.KeyListener:SetScript("OnKeyDown", KeyListener_OnKeyDown);
        else
            self.KeyListener:SetScript("OnKeyDown", nil);
        end
    end

    function StaticPopupMixin:OnCopySuccess()
        if not self.copySuccess then
            self.copySuccess = true;
            C_Timer.After(0, function()
                self.copySuccess = nil;
                self:Close();
                addon.DisplayTopMessage(TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD_NOTICE, "Green");
            end);
        end
    end
end


local EditBoxMixin = {};
do
    function EditBoxMixin:OnEnter()
        self:UpdateVisual();
    end

    function EditBoxMixin:OnLeave()
        self:UpdateVisual();
    end

    function EditBoxMixin:OnShow()
        self:SetFocus();
    end

    function EditBoxMixin:UpdateVisual()
        local a;
        if self:HasFocus() then
            a = 0.8;
        elseif self:IsMouseMotionFocus() then
            a = 0.6;
        else
            a = 0.4;
        end
    end

    function EditBoxMixin:OnEditFocusGained()
        self:HighlightText();
        self:UpdateVisual();
    end

    function EditBoxMixin:OnEditFocusLost()
        self:UpdateVisual();
        self:ClearHighlightText();
        if self.isClipboard then
            if self.defaultText then
                self:SetText(self.defaultText);
            end
        end
    end

    function EditBoxMixin:OnTextChanged(userInput)
        if self.isClipboard then
            if userInput then
                self:ClearFocus();
            end
        elseif self.onTextChangedFunc then
            self.onTextChangedFunc(self, userInput);
        end
    end

    function EditBoxMixin:OnEscapePressed()
        self:ClearFocus();
        MainFrame:Close();
    end

    function EditBoxMixin:OnEnterPressed()
        if self.isClipboard then
            self:ClearFocus();
            MainFrame:Close();
        elseif self.onEnterPressedFunc then
            self.onEnterPressedFunc(self);
        end
    end

    function EditBoxMixin:OnCursorChanged()
        if self.isClipboard then
            if self:HasFocus() then
                self:HighlightText();
            end
        end
    end

    function EditBoxMixin:SetDefaultText(text)
        self.defaultText = text;
        self:SetText(text or "");
        self:SetCursorPosition(0);
    end

    function EditBoxMixin:GetValidText()
        local text = strtrim(self:GetText());
        if text ~= "" then
            return text
        end
    end

    function EditBoxMixin:OnLoad()
        self.OnLoad = nil;

        local texture = "Interface/AddOns/Narcissus/Art/Modules/DressingRoom/CustomSetsMenu.png";
        self.Left:SetTexture(texture);
        self.Left:SetTexCoord(0, 24/512, 44/512, 92/512);
        self.Right:SetTexture(texture);
        self.Right:SetTexCoord(232/512, 256/512, 44/512, 92/512);
        self.Center:SetTexture(texture);
        self.Center:SetTexCoord(24/512, 232/512, 44/512, 92/512);

        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnEditFocusGained", self.OnEditFocusGained);
        self:SetScript("OnEditFocusLost", self.OnEditFocusLost);
        self:SetScript("OnTextChanged", self.OnTextChanged);
        self:SetScript("OnEscapePressed", self.OnEscapePressed);
        self:SetScript("OnEnterPressed", self.OnEnterPressed);
        self:SetScript("OnCursorChanged", self.OnCursorChanged);
    end
end


do  --Checkbox Mixin
    NarciWoWCheckboxWithLabelMixin = {};

    function NarciWoWCheckboxWithLabelMixin:OnEnter()
        self:UpdateVisual();
        if self.onEnterFunc then
            self.onEnterFunc(self);
        end
    end

    function NarciWoWCheckboxWithLabelMixin:OnLeave()
        self:UpdateVisual();
        GameTooltip:Hide();
    end

    function NarciWoWCheckboxWithLabelMixin:OnClick(button)
        if self.onClickFunc then
            self.onClickFunc(self, button);
        end
    end

    function NarciWoWCheckboxWithLabelMixin:OnEnable()
        self:UpdateVisual();
    end

    function NarciWoWCheckboxWithLabelMixin:OnDisable()
        self:UpdateVisual();
    end

    function NarciWoWCheckboxWithLabelMixin:UpdateVisual()
        if self:IsEnabled() then
            self.NormalTexture:SetVertexColor(1, 1, 1);
            if self:IsMouseMotionFocus() then
                self.Label:SetTextColor(1, 1, 1);
            else
                self.Label:SetTextColor(1, 0.82, 0);
            end
        else
            self.NormalTexture:SetVertexColor(0.8, 0.8, 0.8);
            self.Label:SetTextColor(0.5, 0.5, 0.5);
        end
    end

    function NarciWoWCheckboxWithLabelMixin:SetLabel(text)
        self.Label:SetText(text);
    end

    function NarciWoWCheckboxWithLabelMixin:SetIconSize(size)
        self.NormalTexture:SetSize(size, size);
        self.Label:SetPoint("LEFT", self, "LEFT", size + 6, 0);
    end

    function NarciWoWCheckboxWithLabelMixin:ResizeToFit()
        local minWidth = 64;
        local gap = 6;
        local widgetWidth = self.NormalTexture:GetWidth() + gap + self.Label:GetWrappedWidth();

        if widgetWidth >= minWidth then
            self:SetWidth(math.ceil(widgetWidth));
        else
            self:SetWidth(minWidth);
            local offsetX = 0.5*(minWidth - widgetWidth);
            self.NormalTexture:SetPoint("LEFT", self, "LEFT", offsetX, 0);
            self.Label:SetPoint("LEFT", self, "LEFT", offsetX + self.NormalTexture:GetWidth() + 6, 0);
        end
    end
end


local function CreatePopup()
    if MainFrame then return end;

    MainFrame = CreateFrame("Frame", "NarciSharedStaticPopup", UIParent, "NarciSharedPopupFrameTemplate");
    Mixin(MainFrame, StaticPopupMixin);
    MainFrame.Def = Def;
    MainFrame:OnLoad();

    Mixin(MainFrame.EditBox, EditBoxMixin);
    MainFrame.EditBox:OnLoad();

    MainFrame.fontStringPool = CreateFontStringPool(MainFrame, "OVERLAY", 0, "GameFontNormal");
    MainFrame.checkboxPool = CreateFramePool("CheckButton", MainFrame, "NarciWoWCheckboxWithLabelTemplate");

    MainFrame:Reset();
end


local function ShowClipboard(text)
    CreatePopup();

    local hotkey;
    if IsMacClient and IsMacClient() then
        hotkey = "Command+C";
    else
        hotkey = "Ctrl+C";
    end

    MainFrame:SetupClipboard(L["Press Key To Copy Format"]:format(hotkey), text);
end
addon.ShowClipboard = ShowClipboard;


local function GetStaticPopup()
    CreatePopup();
    MainFrame:Hide();
    MainFrame:Reset();
    return MainFrame
end
addon.GetStaticPopup = GetStaticPopup;


local function HideStaticPopup()
    if MainFrame then
        MainFrame:Hide();
    end
end
addon.HideStaticPopup = HideStaticPopup;

addon.CallbackRegistry:Register("StaticPopup.CloseAll", HideStaticPopup);