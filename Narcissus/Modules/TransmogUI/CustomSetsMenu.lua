local _, addon = ...
local L = Narci.L;
local TransmogUIManager = addon.TransmogUIManager;
local TransmogDataProvider = addon.TransmogDataProvider;


local Menu = CreateFrame("Frame", nil, UIParent);
Menu:Hide();


local Def = {
    MenuWidthMin = 240,
    MenuPaddingY = 8,
    MenuButtonHeight = 24,
};


local CreateMenuButton;
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

    function MenuButtonMixin:OnClick()

    end

    function MenuButtonMixin:OnEnable()
        self.Texture1:SetDesaturated(false);
        self.Texture2:SetDesaturated(false);
        self.ButtonText:SetTextColor(1, 1, 1);
    end

    function MenuButtonMixin:OnDisable()
        self.Texture1:SetDesaturated(true);
        self.Texture2:SetDesaturated(true);
        self.ButtonText:SetTextColor(0.5, 0.5, 0.5);
    end

    function MenuButtonMixin:SetRadio(selected)
        local offset = 10;
        self.Texture1:SetPoint("LEFT", self, "LEFT", offset, 0);
        self.Texture2:ClearAllPoints();
        self.Texture2:SetPoint("CENTER", self.Texture1, "CENTER", 0, 0);
        local useAtlasSize = true;
        self.Texture1:SetAtlas("common-dropdown-tickradial", useAtlasSize);
        self.Texture2:SetAtlas("common-dropdown-icon-radialtick-yellow", useAtlasSize);
        self.Texture2:SetShown(selected);
        self.ButtonText:SetPoint("LEFT", self, "LEFT", 20 + offset, 0);
    end

    function MenuButtonMixin:SetText(text, r, g, b)
        self.ButtonText:SetText(text);
        if r then
            self.ButtonText:SetTextColor(r, g, b);
        end
    end


    function CreateMenuButton(parent)
        local f = CreateFrame("Button", nil, parent, "NarciCustomSetsMenuButtonTemplate");
        Mixin(f, MenuButtonMixin);
        f:SetSize(Def.MenuWidthMin, Def.MenuButtonHeight);

        f:SetScript("OnEnter", f.OnEnter);
        f:SetScript("OnLeave", f.OnLeave);
        f:SetScript("OnClick", f.OnClick);
        f:SetScript("OnEnable", f.OnEnable);
        f:SetScript("OnDisable", f.OnDisable);

        return f
    end
end

do  --MenuMixin
    local Schematic_Static = {
        {type = "Radio", key = "SharedSourceButton", text = L["OutfitSource Shared"], tooltip = L["OutfitSource Shared Tooltip"], selected = true},
        {type = "Radio", key = "CurrentSourceButton", text = L["OutfitSource Default"]},
        {type = "Divider", key = "Divider"},
        {type = "Radio", key = "ListHeaderButton", text = L["OutfitSource Alts"], tooltip = L["OutfitSource Alts Tooltip"], disabled = true},
    };

    function Menu:Init()
        self.Init = nil;

        local texture = "Interface/AddOns/Narcissus/Art/Modules/DressingRoom/CustomSetsMenu.png";

        self:SetSize(240, 240);
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
        self:EnableMouse(true);
        self:EnableMouseMotion(true);
        self:EnableMouseWheel(true);


        local ButtonHighlight = self:CreateTexture(nil, "ARTWORK");
        self.ButtonHighlight = ButtonHighlight;
        ButtonHighlight:SetTexture(texture);
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
            end
        end

        --We only have one divider between to static buttons and the list

        
        self.staticHeight = offsetY + Def.MenuPaddingY;
    end

    function Menu:OnShow()
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    end

    function Menu:OnHide()
        self:Hide();
        self:ClearAllPoints();
        self:FocusObject(nil);
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
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

    function Menu:SetModeTransmogUI()
        self.menuHeight = self.staticHeight;
        TransmogUIManager:GetCharacterListByPlayerClass();
    end

    function Menu:SetMode(mode)
        if mode == self.mode then
            self:Refresh();
            return
        end

        if mode == "TransmogUI" then
            self:SetModeTransmogUI();
        elseif mode == "DressingRoom" then
            
        end

        self:SetHeight(Round(self.menuHeight));
    end

    function Menu:Refresh()

    end

    function Menu:FocusObject(object)
        self.ButtonHighlight:Hide();
        self.ButtonHighlight:ClearAllPoints();
        self.focusedObject = object;
        self.t = 0;
        if object then
            self.ButtonHighlight:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0);
            self.ButtonHighlight:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", 0, 0);
            self.ButtonHighlight:Show();
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