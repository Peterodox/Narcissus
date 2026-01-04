local _, addon = ...
local L = Narci.L;
local TransmogUIManager = addon.TransmogUIManager;
local ProfileAPI = addon.ProfileAPI;


local Menu = CreateFrame("Frame", nil, UIParent);
Menu:Hide();


local Def = {
    TextureFile = "Interface/AddOns/Narcissus/Art/Modules/DressingRoom/CustomSetsMenu.png",

    MenuWidthMin = 256,
    MenuPaddingY = 8,
    MenuButtonHeight = 24,
    CharacterButtonPerPage = 8,

    ButtonIconOffset = 10,
    ButtonTextOffset1 = 14,     --With no icon
    ButtonTextOffset2 = 30,     --With one icon
};


local CreateMenuButton;
local MenuButton_PostCreate;
do
    local MenuButtonMixin = {};
    
    function MenuButtonMixin:OnEnter()
        Menu:FocusObject(self);
    end

    function MenuButtonMixin:OnLeave()
        GameTooltip:Hide();
        Menu:FocusObject(nil);
    end

    function MenuButtonMixin:OnFocused()
        if self.data and self.data.tooltip then
            local tooltip = GameTooltip;
            tooltip:SetOwner(self, "ANCHOR_NONE");
            tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 4, 0);
            tooltip:SetText(self.data.text, 1, 1, 1);
            tooltip:AddLine(self.data.tooltip, 1, 0.82, 0, true);
            tooltip:Show();
        end
    end

    function MenuButtonMixin:OnClick(button)
        if self.onClickFunc then
            self.onClickFunc(self, button);
        end
        Menu:Hide();
    end

    function MenuButtonMixin:OnEnable()
        self.Texture1:SetDesaturated(false);
        self.ButtonText:SetTextColor(1, 1, 1);
    end

    function MenuButtonMixin:OnDisable()
        self.Texture1:SetDesaturated(true);
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end

    function MenuButtonMixin:SetRadio(selected)
        self.Texture1:SetPoint("LEFT", self, "LEFT", Def.ButtonIconOffset, 0);
        self:ShowRadioIcon(true, selected);
        self.ButtonText:SetPoint("LEFT", self, "LEFT", Def.ButtonTextOffset2, 0);
        self.RightText:ClearAllPoints();
        self.RightText:SetPoint("RIGHT", self, "RIGHT", -Def.ButtonTextOffset2, 0);
    end

    function MenuButtonMixin:ShowRadioIcon(state, selected)
        if state then
            if selected then
                self.Texture1:SetTexCoord(324/512, 356/512, 0, 32/512);
            else
                self.Texture1:SetTexCoord(292/512, 324/512, 0, 32/512);
            end
            self.Texture1:Show();
        else
            self.Texture1:Hide();
        end
    end

    function MenuButtonMixin:SetCharacterInfo(characterInfo)
        self:Enable();
        self.ButtonText:SetText(characterInfo.colorizedName);
        self.Texture1:Hide();
        self.ButtonText:SetPoint("LEFT", self, "LEFT", Def.ButtonTextOffset2, 0);

        if characterInfo.numSets > 0 then
            self.RightText:SetText(characterInfo.numSets);
            self.RightText:ClearAllPoints();
            self.RightText:SetPoint("CENTER", self, "RIGHT", -Def.ButtonTextOffset2 -2, 0);
            self.RightText:SetTextColor(0.5, 0.5, 0.5);
            self.ButtonText:SetAlpha(1);
        else
            self.RightText:SetText(nil);
            self.ButtonText:SetAlpha(0.6);
        end

        self.onClickFunc = function(self, button)
            --TransmogUIManager:CustomSetsTab_LoadAltSets(characterInfo);
            addon.CallbackRegistry:Trigger("TransmogUI.LoadAltSets", characterInfo);
        end
    end

    function MenuButtonMixin:SetText(text, r, g, b)
        self.ButtonText:SetText(text);
        if r then
            self.ButtonText:SetTextColor(r, g, b);
        end
    end

    function MenuButton_PostCreate(f)
        Mixin(f, MenuButtonMixin);
        f:SetSize(Def.MenuWidthMin, Def.MenuButtonHeight);

        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnClick", f.OnClick);
        f:SetScript("OnEnable", f.OnEnable);
        f:SetScript("OnDisable", f.OnDisable);

        f.Texture1:SetTexture(Def.TextureFile);
    end

    function CreateMenuButton(parent)
        local f = CreateFrame("Button", nil, parent, "NarciCustomSetsMenuButtonTemplate");
        MenuButton_PostCreate(f);
        return f
    end
end

local CreateSearchBox;
do
    local SearchBoxMixin = {};

    function SearchBoxMixin:GetValidText()
        local text = strtrim(self:GetText());   --C_StringUtil in the future?
        if text ~= "" then
            return text
        end
    end

    function SearchBoxMixin:OnEditFocusLost()
        if not self:GetValidText() then
            self:SetText("");
            self.SearchIcon:SetVertexColor(0.5, 0.5, 0.5);
        end
        self:ClearHighlightText();
    end

    function SearchBoxMixin:OnEditFocusGained()
        self.SearchIcon:SetVertexColor(0.9, 0.9, 0.9);
    end

    function SearchBoxMixin:OnTextChanged(userInput)
        if self:GetText() ~= "" then
            self.SearchIcon:SetVertexColor(0.9, 0.9, 0.9);
            self.Instructions:Hide();
            self.ClearButton:Show();
        else
            self.Instructions:Show();
            self.ClearButton:Hide();
            if not self:HasFocus() then
                self.SearchIcon:SetVertexColor(0.5, 0.5, 0.5);
            end
        end

        if userInput then
            self.t = 0;
            self:SetScript("OnUpdate", self.OnUpdate);
        end
    end

    function SearchBoxMixin:OnEnter()
        Menu:FocusObject(self);
    end

    function SearchBoxMixin:OnLeave()
        Menu:FocusObject(nil);
        GameTooltip:Hide();
    end

    function SearchBoxMixin:OnFocused()
        local tooltip = GameTooltip;
        tooltip:SetOwner(self, "ANCHOR_NONE");
        tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 12, 0);
        tooltip:SetText(L["OutfitSource Alts"], 1, 1, 1);
        tooltip:AddLine(L["OutfitSource Alts Tooltip"], 1, 0.82, 0, true);
        tooltip:Show();
    end

    function SearchBoxMixin:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.2 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:RunSearch();
        end
    end

    local lower = string.lower;
    local find = string.find;

    local function StringMatch(baseString, word)
        if baseString and baseString ~= "" and find(lower(baseString), word, 1, true) then
            return true
        end
        return false
    end

    local function CheckCharacterDataForMatch(data, words)
        local matched = false;

        for _, word in ipairs(words) do
            if word ~= "" then
                if StringMatch(data.name, word) or StringMatch(data.raceName, word) or StringMatch(data.className, word) then
                    matched = true;
                    break
                end
            end
        end

        return matched
    end

    function SearchBoxMixin:RunSearch()
        local text = self:GetValidText();
        local filteredCharacters;

        if text then
            text = lower(text);
            local words = { string.split(" ", text) };
            local hasValidTerms;
            if words then
                for _, word in ipairs(words) do
                    if word ~= "" then
                        hasValidTerms = true;
                        break
                    end
                end
            end

            if hasValidTerms then
                filteredCharacters = {};
                local n = 0;
                for _, characterInfo in ipairs(TransmogUIManager:GetAllCharacterCustomSets()) do
                    if CheckCharacterDataForMatch(characterInfo, words) then
                        n = n + 1;
                        filteredCharacters[n] = characterInfo;
                    end
                end
            end
        else
            filteredCharacters = TransmogUIManager:GetAllCharacterCustomSets();
        end

        Menu.filteredCharacters = filteredCharacters or {};
        Menu.page = 1;
        Menu:Refresh();
    end

    function CreateSearchBox(parent)
        local f = CreateFrame("EditBox", nil, parent, "NarciCustomSetsMenuSearchBoxTemplate");
        Mixin(f, SearchBoxMixin);

        f:SetSize(Def.MenuWidthMin - 32, Def.MenuButtonHeight);
        f.hideHighlight = true;

        f.Left:SetTexture(Def.TextureFile);
        f.Left:SetTexCoord(0, 24/512, 44/512, 92/512);
        f.Right:SetTexture(Def.TextureFile);
        f.Right:SetTexCoord(232/512, 256/512, 44/512, 92/512);
        f.Center:SetTexture(Def.TextureFile);
        f.Center:SetTexCoord(24/512, 232/512, 44/512, 92/512);
        f.SearchIcon:SetTexture(Def.TextureFile);
        f.SearchIcon:SetTexCoord(260/512, 308/512, 44/512, 92/512);
        f.SearchIcon:SetVertexColor(0.5, 0.5, 0.5);

        f.ClearButton.Icon:SetTexture(Def.TextureFile);
        f.ClearButton.Icon:SetTexCoord(308/512, 356/512, 44/512, 92/512);
        f.ClearButton.Icon:SetVertexColor(0.6, 0.6, 0.6);
        f.ClearButton.Highlight:SetTexture(Def.TextureFile);
        f.ClearButton.Highlight:SetTexCoord(308/512, 356/512, 44/512, 92/512);
        f.ClearButton.Highlight:SetVertexColor(0.4, 0.4, 0.4);
        f.ClearButton:SetScript("OnClick", function()
            f:SetText("");
            f:RunSearch();
        end);

        f:SetScript("OnEditFocusLost", f.OnEditFocusLost);
        f:SetScript("OnEditFocusGained", f.OnEditFocusGained);
        f:SetScript("OnTextChanged", f.OnTextChanged);
        f:SetScript("OnEnterPressed", f.ClearFocus);
        f:SetScript("OnEscapePressed", f.ClearFocus);
        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);

        return f
    end
end

do  --MenuMixin
    local Schematic_Static = {
        {type = "Radio", key = "CurrentSourceButton", text = L["OutfitSource Default"],
            onClickFunc = function()
                addon.CallbackRegistry:Trigger("TransmogUI.LoadDefaultSets");
            end,
        },
        {type = "Radio", key = "SharedSourceButton", text = L["OutfitSource Shared"], tooltip = L["OutfitSource Shared Tooltip"],
            onClickFunc = function()
                addon.CallbackRegistry:Trigger("TransmogUI.LoadSharedSets");
            end,
        },
        {type = "Divider", key = "Divider"},
        --{type = "Radio", key = "ListHeaderButton", text = L["OutfitSource Alts"], tooltip = L["OutfitSource Alts Tooltip"], disabled = true},
    };

    function Menu:Init()
        self.Init = nil;

        self:SetSize(Def.MenuWidthMin, 240);
        self:SetFrameStrata("HIGH");

        --See MenuStyle1Mixin:Generate (Blizzard_Menu/Mainline/MenuTemplates.lua)
        local Background = self:CreateTexture(nil, "BACKGROUND");
        self.Background = Background;
        Background:SetAtlas("common-dropdown-bg");
        Background:SetAlpha(0.925);
        local x = 8;      --Adjust background so its border line up with frame's
        Background:SetPoint("TOPLEFT", -x, 6);
        Background:SetPoint("BOTTOMRIGHT", x, -12);

        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnHide", self.OnHide);
        self:SetScript("OnEvent", self.OnEvent);
        self:SetScript("OnMouseWheel", function() end);
        self:EnableMouse(true);
        self:EnableMouseMotion(true);

        local ButtonHighlight = self:CreateTexture(nil, "ARTWORK");
        self.ButtonHighlight = ButtonHighlight;
        ButtonHighlight:SetTexture(Def.TextureFile);
        ButtonHighlight:SetTexCoord(0, 0.5, 0, 40/512);
        ButtonHighlight:SetVertexColor(1, 1, 1);
        ButtonHighlight:Hide();


        --Static Buttons

        local offsetY = Def.MenuPaddingY;

        for _, v in ipairs(Schematic_Static) do
            local obj;
            if v.type == "Radio" then
                obj = CreateMenuButton(self);
                obj:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY);
                obj:SetText(v.text, 1, 1, 1);
                obj:SetRadio(v.selected);
                offsetY = offsetY + Def.MenuButtonHeight;
            elseif v.type == "Divider" then
                obj = self:CreateTexture(nil, "OVERLAY");
                local _offsetY = 0;
                local objectHeight = 13;
                offsetY = offsetY + _offsetY;
                obj:SetHeight(objectHeight);
                obj:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent");
                obj:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -offsetY);
                obj:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -offsetY);
                offsetY = offsetY + objectHeight + _offsetY;
            end

            if obj then
                obj.data = v;

                if v.key then
                    self[v.key] = obj;
                end

                if v.disabled then
                    obj:Disable();
                end

                obj.onClickFunc = v.onClickFunc;
            end
        end

        self.staticHeight = offsetY + Def.MenuPaddingY;
    end

    function Menu:OnShow()
        self.wasShown = true;
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    end

    function Menu:OnHide()
        self:Hide();
        self:ClearAllPoints();
        self:FocusObject(nil);
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        C_Timer.After(0, function()
            self.wasShown = nil;
        end);
    end

    function Menu:IsFocused()
        return self:IsShown() and (self:IsMouseOver() or (self.owner and self.owner:IsMouseOver()))
    end

    function Menu:OnEvent(event, ...)
        if event == "GLOBAL_MOUSE_DOWN" then
            if not self:IsFocused() then
                self:Hide();
            end
        end
    end

    function Menu:SetOwner(owner)
        self:SetParent(owner);
        self.owner = owner;
    end

    function Menu:OnMouseWheel(delta)
        if not self.page then return end;

        if delta > 0 and self.page > 1 then
            self.page = self.page - 1;
        elseif delta < 0 and self.page < self.maxPage then
            self.page = self.page + 1;
        else
            return
        end

        self:UpdateListFrame();
    end

    function Menu:UpdateListFrame()
        local total = #self.filteredCharacters;
        self.maxPage = math.ceil(total / Def.CharacterButtonPerPage);

        if not self.page then
            self.page = 1;
        end

        self.NoDataAlert:SetShown(total == 0);

        self.ListButtons:ReleaseAll();
        local uid = TransmogUIManager:GetSelectedCharacterUID();
        local fromDataIndex = (self.page - 1) * Def.CharacterButtonPerPage;
        local offsetY = Def.MenuButtonHeight + Def.MenuPaddingY;
        local characterInfo;
        for index = fromDataIndex + 1, fromDataIndex + Def.CharacterButtonPerPage do
            characterInfo = self.filteredCharacters[index];
            if characterInfo then
                characterInfo:LoadData();
                local button = self.ListButtons:Acquire();
                button:SetPoint("TOP", self.ListFrame, "TOP", 0, -offsetY);
                button:SetCharacterInfo(characterInfo);
                button:ShowRadioIcon(characterInfo.uid == uid, true);
                button:Show();
                offsetY = offsetY + Def.MenuButtonHeight;
            end
        end
        self.PageText:SetText(string.format("%d/%d", self.page <= self.maxPage and self.page or 0, self.maxPage));
        self.PrevButton:SetEnabled(self.page > 1);
        self.NextButton:SetEnabled(self.page < self.maxPage);
    end

    function Menu:InitListFrame()
        if self.ListFrame then
            return
        end

        local ListFrame = CreateFrame("Frame", nil, self);
        self.ListFrame = ListFrame;
        ListFrame:SetScript("OnMouseWheel", function(_, delta)
            Menu:OnMouseWheel(delta)
        end);

        local resetFunc = nil;
        local forbidden = false;
        self.ListButtons = CreateFramePool("Button", ListFrame, "NarciCustomSetsMenuButtonTemplate", resetFunc, forbidden, MenuButton_PostCreate);

        local height = 24;

        local PageText = ListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        self.PageText = PageText;
        PageText:SetWidth(48);
        PageText:SetHeight(height);
        PageText:SetJustifyH("CENTER");
        PageText:SetPoint("BOTTOM", ListFrame, "BOTTOM", 0, 4);
        PageText:SetTextColor(0.88, 0.88, 0.88);
        PageText:SetText("1/1");

        local function PageButton_OnEnable(f)
            f.Icon:SetVertexColor(1, 0.82, 0);
        end

        local function PageButton_OnDisable(f)
            f.Icon:SetVertexColor(0.4, 0.4, 0.4);
        end

        local function CreatePageButton(delta)
            local f = CreateFrame("Button", nil, ListFrame);
            f:SetSize(height, height);
            f.delta = delta;
            f.Icon = f:CreateTexture(nil, "OVERLAY");
            f.Icon:SetPoint("CENTER", f, "CENTER", 0, 0);
            f.Icon:SetSize(16, 16);
            f.Icon:SetTexture(Def.TextureFile);
            f.Highlight = f:CreateTexture(nil, "HIGHLIGHT");
            f.Highlight:SetPoint("TOPLEFT", f.Icon, "TOPLEFT", 0, 0);
            f.Highlight:SetPoint("BOTTOMRIGHT", f.Icon, "BOTTOMRIGHT", 0, 0);
            f.Highlight:SetTexture(Def.TextureFile);
            f.Highlight:SetBlendMode("ADD");
            if delta > 0 then
                f.Icon:SetTexCoord(260/512, 292/512, 0/512, 32/512);
                f.Highlight:SetTexCoord(260/512, 292/512, 0/512, 32/512);
            else
                f.Icon:SetTexCoord(292/512, 260/512, 0/512, 32/512);
                f.Highlight:SetTexCoord(292/512, 260/512, 0/512, 32/512);
            end
            PageButton_OnEnable(f);
            f:SetScript("OnEnable", PageButton_OnEnable);
            f:SetScript("OnDisable", PageButton_OnDisable);
            f:SetScript("OnClick", function()
                Menu:OnMouseWheel(f.delta);
            end);

            return f
        end

        self.PrevButton = CreatePageButton(1);
        self.PrevButton:SetPoint("RIGHT", PageText, "LEFT", 0, 0);

        self.NextButton = CreatePageButton(-1);
        self.NextButton:SetPoint("LEFT", PageText, "RIGHT", 0, 0);

        local NoDataAlert = ListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
        self.NoDataAlert = NoDataAlert;
        NoDataAlert:SetTextColor(0.5, 0.5, 0.5);
        NoDataAlert:SetJustifyH("CENTER");
        NoDataAlert:SetPoint("LEFT", ListFrame, "LEFT", 16, 0);
        NoDataAlert:SetPoint("RIGHT", ListFrame, "RIGHT", -16, 0);
        NoDataAlert:SetText(CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS);

        --Search Bar
        local SearchBox = CreateSearchBox(ListFrame);
        SearchBox:SetPoint("TOP", ListFrame, "TOP", 0, 0);
        SearchBox.Instructions:SetText(L["OutfitSource Alts"]);
    end

    function Menu:SetModeTransmogUI()
        self:InitListFrame()

        local offsetY = self.staticHeight;
        local listHeight = (Def.CharacterButtonPerPage + 1) * Def.MenuButtonHeight + 2*Def.MenuPaddingY + 22;
        self.ListFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY);
        self.ListFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
        self.menuHeight = offsetY + listHeight;

        self.filteredCharacters = TransmogUIManager:GetAllCharacterCustomSets();
        self:Refresh();
    end

    function Menu:SetMode(mode)
        if mode == self.mode then
            self:Refresh();
            return
        end

        if mode == "TransmogUI" then
            self:SetModeTransmogUI();
        elseif mode == "DressingRoom" then
            
        else
            return
        end

        self.mode = mode;
        self:SetHeight(Round(self.menuHeight));
    end

    function Menu:Refresh()
        self.CurrentSourceButton:ShowRadioIcon(true, TransmogUIManager:IsOutfitSource("Default"));
        self.SharedSourceButton:ShowRadioIcon(true, TransmogUIManager:IsOutfitSource("Shared"));
        self:UpdateListFrame();
    end

    function Menu:FocusObject(object)
        self.ButtonHighlight:Hide();
        self.ButtonHighlight:ClearAllPoints();
        self.focusedObject = object;
        self.t = 0;
        if object then
            if object:IsEnabled() and not object.hideHighlight then
                self.ButtonHighlight:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0);
                self.ButtonHighlight:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", 0, 0);
                self.ButtonHighlight:Show();
            end
            self:SetScript("OnUpdate", self.OnUpdate);
        else
            self:SetScript("OnUpdate", nil);
        end
    end

    function Menu:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.1 then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            if self.focusedObject and self.focusedObject:IsMouseMotionFocus() then
                self.focusedObject:OnFocused();
            end
            self.focusedObject = nil;
        end
    end
end


function TransmogUIManager:ShowCustomSetsMenu(owner)
    Menu:Hide();
    Menu:ClearAllPoints();
    Menu:SetOwner(owner);
    Menu:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, 0);
    if Menu.Init then
        Menu:Init();
    end
    Menu:SetMode("TransmogUI");
    Menu:Show();
end

function TransmogUIManager:ToggleCustomSetsMenu(owner)
    if Menu.owner == owner and Menu:IsShown() then
        Menu:Hide();
    else
        self:ShowCustomSetsMenu(owner);
    end
end

function TransmogUIManager:IsCustomSetsMenuShown()
    return Menu:IsShown() or Menu.wasShown
end