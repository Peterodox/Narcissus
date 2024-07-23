local _, addon = ...

local MainFrame;
local NavBar = Narci_NavBar;

local buttonData = {
    {"Equipment", function() NavBar:SelectTab(1) end},
    {"Title", function() local b = Narci_TitleManager_Switch; if not b.isOn then b:Click() end end},
    {"Sets",  function() NavBar:SelectTab(2) end},
    --{"Soulbinds",  function() NavBar:SelectTab(3) end},
    {"M+",  function() NavBar:SelectTab(3) end},
};

NarciGamePadNavBarButtonMixin = {};

function NarciGamePadNavBarButtonMixin:SetButtonName(name)
    self.ButtonName:SetWidth(0);
    self.ButtonName:SetText( string.upper(name) );
    local width = math.max(48, (self.ButtonName:GetWrappedWidth() or 0) + 12);
    self.ButtonName:SetWidth(width);
    self:SetWidth(width);
    return width
end

function NarciGamePadNavBarButtonMixin:OnEnter()
    self.ButtonName:SetTextColor(1, 1, 1);
end

function NarciGamePadNavBarButtonMixin:OnLeave()
    if not self.isOn then
        self.ButtonName:SetTextColor(0.60, 0.60, 0.60);
    end
end

function NarciGamePadNavBarButtonMixin:OnMouseDown()
    self.ButtonName:SetPoint("CENTER", self, "CENTER", 0, -0.8);
end

function NarciGamePadNavBarButtonMixin:OnMouseUp()
    self.ButtonName:SetPoint("CENTER", self, "CENTER", 0, 0);
end

function NarciGamePadNavBarButtonMixin:OnClick()
    MainFrame:SelectButton(self);
    if self.onClickFunc then
        self.onClickFunc();
    end
end

function NarciGamePadNavBarButtonMixin:SetSelection(state)
    if state then
        self.isOn = true;
        self:OnEnter();
    else
        self.isOn = nil;
        self:OnLeave();
    end
end




NarciGamePadNavBarMixin = {};

local function UpdateThemeColor_OnShow(self)
    self.SelectionHighlight:SetVertexColor( NarciThemeUtil:GetColor() );
end

function NarciGamePadNavBarMixin:OnLoad()
    addon.GamePadNavBar = self;
    MainFrame = self;
    if not self.NavButtons then
        self.NavButtons = {};
    end
    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciGamePadNavBarMixin:OnShow()
    self:Init();
    UpdateThemeColor_OnShow(self);
    self:SetScript("OnShow", UpdateThemeColor_OnShow);
end

function NarciGamePadNavBarMixin:SetBumperStyle(id)
    local styleName;
    if id == 2 then
        styleName = "PS";
    else
        styleName = "Xbox";
    end
    self.LeftBumper:SetTexture("Interface\\AddOns\\Narcissus_GamePad\\Art\\"..styleName.."\\Bumpers");
    self.RightBumper:SetTexture("Interface\\AddOns\\Narcissus_GamePad\\Art\\"..styleName.."\\Bumpers");
end

function NarciGamePadNavBarMixin:Init()
    self:ClearAllPoints();
    --self:SetPoint("TOPLEFT", Narci_Character, "TOPLEFT", 24, -24);
    self:SetPoint("TOP", Narci_GuideLineFrame, "TOP", 0, 0);

    self:SetBumperStyle(1);

    --Create Buttons
    local button;
    local width;
    local padding = 72;
    local fullWidth = padding;
    for i = 1, #buttonData do
        if not self.NavButtons[i] then
            self.NavButtons[i] = CreateFrame("Button", nil, self, "NarciGamePadNavBarButtonTemplate");
        end
        button = self.NavButtons[i];
        button:SetPoint("LEFT", self, "LEFT", fullWidth, 0);
        button.onClickFunc = buttonData[i][2];
        width = button:SetButtonName(buttonData[i][1]);
        fullWidth = fullWidth + width;
    end
    fullWidth = fullWidth + padding;
    self:SetWidth(fullWidth);
end

function NarciGamePadNavBarMixin:SelectButton(navButton)
    for _, button in pairs(self.NavButtons) do
        button:SetSelection(false);
    end

    if navButton then
        navButton:SetSelection(true);
        local width = navButton:GetWidth();
        self.SelectionHighlight:SetWidth( math.max(width, 72) );
        self.SelectionHighlight:ClearAllPoints();
        self.SelectionHighlight:SetPoint("BOTTOM", navButton, "BOTTOM", 0, 0);
        self.SelectionHighlight:Show();
    else
        self.SelectionHighlight:Hide();
    end
end

function NarciGamePadNavBarMixin:SelectButtonByID(id)
    self:SelectButton(self.NavButtons[id]);
end