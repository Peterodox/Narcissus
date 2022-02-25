local L = Narci.L;
local FadeFrame = NarciAPI_FadeFrame;

local pow = math.pow;
local cos = math.cos;
local pi = math.pi;

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end

local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

local function CreateRoundGroupButton(parent, groupIndex, data, point, relativeTo, relativePoint, offsetX, offsetY, customSectorHeight)
    --Create Buttons
    local button;
    local buttons = {};

    local buttonDistanceY = 4;

    local numButton = #data;
    local maxWidth = 0;
    for i = 1, numButton do
        button = CreateFrame("Button", nil, parent, "NarciDarkRoundButtonTemplate");
        button.index = i;
        tinsert(buttons, button);
        button:Initialize( groupIndex, unpack(data[i]) );
        if i == 1 then
            button:SetPoint("CENTER", parent, "CENTER", 0, 0);
            button:UpdateVisual();
        else
            button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -buttonDistanceY);
            if i == numButton then
                maxWidth = button:UpdateGroupHitBox();
            end
        end
    end

    --Create Sector
    local Sector = CreateFrame("Frame", nil, parent, "NarciDarkButtonSectorTemplate");
    if not parent.sectors then
        parent.sectors = {};
    end
    tinsert(parent.sectors, Sector);

    local inset = 8;
    local buttonHeight = button:GetHeight();
    local sectorWidth = maxWidth + 2*inset;
    local sectorHeight = customSectorHeight or (numButton * buttonHeight + (numButton - 1) * buttonDistanceY + 12 + 2*inset + 4);

    Sector:SetPoint(point, relativeTo or parent, relativePoint, offsetX, offsetY);
    Sector:SetSize(sectorWidth, sectorHeight);
    Sector.Label:SetText(data.header);

    local button1 = buttons[1];
    button1:ClearAllPoints();
    --button1:SetPoint("TOPLEFT", Sector.Header, "BOTTOMLEFT", inset, -inset);      --Anchor to Header
    button1:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", offsetX + inset, 68 -inset -12);  --Anchor to Parent. Assign header animation   -12 ~ minus Header Height
    parent.lightOptions = buttons;
    return sectorWidth, sectorHeight
end

local function CreateSquareGroupButton(parent, groupIndex, data, point, relativeTo, relativePoint, offsetX, offsetY, customSectorHeight)
    local button;
    local buttons = {};

    local buttonDistanceX = 2;
    local buttonDistanceY = 2;

    local numButton = #data;
    local buttonWidth = 0;
    local buttonsPerRow = data.buttonsPerRow or 1;
    
    for i = 1, numButton do
        button = CreateFrame("Button", nil, parent, "NarciDarkSquareButtonTemplate");
        button.index = i;
        tinsert(buttons, button);
        button:Initialize( groupIndex, unpack(data[i]) );
        if i == 1 then
            button:SetPoint("CENTER", parent, "CENTER", 0, 0);
            buttonWidth = button:GetWidth();
            button:UpdateVisual();
        else
            if i % buttonsPerRow == 1 then
                button:SetPoint("TOPLEFT", buttons[i - buttonsPerRow], "BOTTOMLEFT", 0, -buttonDistanceY);
            else
                button:SetPoint("TOPLEFT", buttons[i - 1], "TOPRIGHT", buttonDistanceX, 0);
            end
        end
    end

    local Sector = CreateFrame("Frame", nil, parent, "NarciDarkButtonSectorTemplate");
    local inset = 8;
    local buttonHeight = button:GetHeight();
    local sectorWidth = buttonsPerRow * buttonWidth + (buttonsPerRow - 1) * buttonDistanceX + 2*inset;
    local sectorHeight = customSectorHeight or (numButton * buttonHeight + (numButton - 1) * buttonDistanceY + 12 + 2*inset + 4);

    Sector:SetPoint(point, relativeTo or parent, relativePoint, offsetX, offsetY);
    Sector:SetSize(sectorWidth, sectorHeight);
    Sector.Label:SetText(data.header);

    local button1 = buttons[1];
    button1:ClearAllPoints();
    button1:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", offsetX + inset, 68 -inset -12);  --Anchor to Parent. Assign header animation   -12 ~ minus Header Height

    parent.shadowOptions = buttons;
    return sectorWidth, sectorHeight
end


NarciGroundShadowOptionMixin = {};

function NarciGroundShadowOptionMixin:SelectShadowStyle(index)
    local isRadialShadow = (index == 2);
    local GroundShadowContainer = self.GroundShadowContainer;
    GroundShadowContainer.Shadow:SetShown(not isRadialShadow);
    GroundShadowContainer.RadialShadow:SetShown(isRadialShadow);
    GroundShadowContainer.RadialShadowMask:SetShown(isRadialShadow);
    self.RotationButton:SetShown(isRadialShadow);
    GroundShadowContainer.useRadialShadow = isRadialShadow;
end

function NarciGroundShadowOptionMixin:EnableLightControl(state)
    local GroundShadowContainer = self.GroundShadowContainer;
    GroundShadowContainer.controlLights = state;
end

function NarciGroundShadowOptionMixin:OnLoad()
    local texFile = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\LightSetup\\ShadowStyleIcon";
    local data1 = {
        ["header"] = L["Shadow"],
        ["buttonsPerRow"] = 2,
        [1] = {texFile, {0, 0.25, 0, 1}, nil, function() self:SelectShadowStyle(1) end},
        [2] = {texFile, {0.25, 0.5, 0, 1}, nil, function() self:SelectShadowStyle(2) end},
    }
    local data2 = {
        ["header"] = L["Light Source"],
        [1] = {L["Light Source Independent"], nil, function() self:EnableLightControl(false) end},
        [2] = {L["Light Source Interconnected"], nil, function() self:EnableLightControl(true) end},
    }

    local totalWidth = 384;
    local gap = 4;
    local collapsedHeight = 2;
    local relativeTo = self;
    local w1, h1 = CreateSquareGroupButton(self, 1, data1, "TOPLEFT", relativeTo, "TOPLEFT", 0, 0, height);
    local w2, h2 = CreateRoundGroupButton(self, 2, data2, "TOPLEFT", relativeTo, "TOPLEFT", w1 + gap, 0);

    local Sector = CreateFrame("Frame", nil, relativeTo, "NarciDarkButtonSectorTemplate");
    local usedWidth = w1 + w2 + 2*gap;
    Sector:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", usedWidth, 0);
    Sector:SetSize(totalWidth - usedWidth, 68);
    Sector.Label:SetText("Ajustment");
    local numSectors = #self.sectors;

    local fullHeight = h2;  --68
    self:SetSize(totalWidth, collapsedHeight);
    self:SetAlpha(0);

    --Fly/Fade In Animation
    local animFly = NarciAPI_CreateAnimationFrame(0.2);
    animFly:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local height;
        if frame.isExpanding then
            height = outQuart(frame.total, frame.fromHeight, frame.toHeight, frame.duration);
        else
            height = inOutSine(frame.total, frame.fromHeight, frame.toHeight, frame.duration);
        end

        if frame.total >= frame.duration then
            height = frame.toHeight;
            frame:Hide();
        end
        self:SetHeight(height);
    end)

    function self:FlyIn(enter)
        animFly:Hide();
        animFly.fromHeight = self:GetHeight();
        animFly.isExpanding = enter;
        if enter then
            animFly.toHeight = fullHeight;  --height + 2
            FadeFrame(self, 0.2, "IN");
        else
            animFly.toHeight = collapsedHeight;  --height + 2
            FadeFrame(self, 0.1, "OUT");
        end
        animFly:Show();
    end


    --Toggle
    local Toggle = self:GetParent().GroundShadowOptionToggle;
    self.Toggle = Toggle;

    Toggle.Label:SetText(L["Show More options"]);
    local toggleWidth = Toggle.Label:GetWidth()
    Toggle:SetWidth( math.max(toggleWidth + 12, 80) );
    Toggle:SetScript("OnEnter", function(button)
        button.Label:SetTextColor(1, 1, 1);
    end)
    Toggle:SetScript("OnLeave", function(button)
        button.Label:SetTextColor(0.25, 0.78, 0.92);
    end)
    Toggle:SetScript("OnClick", function(button)
        self.isExpanded = not self.isExpanded;
        local state = self.isExpanded;
        self:UpdateSliderVisibility();
        --self:SetShown(state);
        if state then
            button.Label:SetText(L["Show Less Options"]);
            --button.Arrow:SetTexCoord(0, 1, 0, 1);
            button.Arrow.flyOutUp:Play();
            self:FlyIn(true);
        else
            button.Label:SetText(L["Show More options"]);
            --button.Arrow:SetTexCoord(0, 1, 1, 0);
            button.Arrow.flyOutDown:Play();
            self:FlyIn(false);
        end
    end)
    Toggle:SetScript("OnDoubleClick", function()
        return
    end)

    self.ColorPickerButton = self:GetParent().ColorPickerButton;
    self.ColorPickerButton.onClickFunc = function()
        if Narci_ColorPicker:IsShown() then
            self.ColorPickerButton:Deselect();
            Narci_ColorPicker:Hide();
        else
            Narci_ColorPicker:SetObject(self.ColorPickerButton);
        end
        
    end;

    self.OnLoad = nil;
end

function NarciGroundShadowOptionMixin:UpdateSliderVisibility()
    local parent = self:GetParent();
    if parent then
        local visible = self.isExpanded;
        parent.SizeSlider:SetShown(visible);
        parent.AlphaSlider:SetShown(visible);
        local Shadow = parent:GetParent();
        local hitOffset;
        if visible then
            hitOffset = 68;
        else
            hitOffset = 0;
        end
        Shadow.offsetTop = hitOffset;
        Shadow:SetHitRectInsets(0, 0, -hitOffset, 0);
    end
end

function NarciGroundShadowOptionMixin:UpdateUI()
    self:UpdateSliderVisibility();
    if self.GroundShadowContainer.useRadialShadow then
        self.shadowOptions[2]:UpdateVisual();
        self.RotationButton:Show();
    else
        self.shadowOptions[1]:UpdateVisual();
        self.RotationButton:Hide();
    end
    if self.GroundShadowContainer.controlLights then
        self.lightOptions[2]:UpdateVisual();
    else
        self.lightOptions[1]:UpdateVisual();
    end
end

function NarciGroundShadowOptionMixin:ReAnchor(model, parent)
    self.object = parent;
    self:ClearAllPoints();
    self:SetParent(parent);
    self:SetPoint("BOTTOM", parent, "TOP", 0, 0);
    self:SetFrameLevel(parent:GetFrameLevel() - 1);
    self.Toggle:ClearAllPoints();
    self.Toggle:SetParent(parent);
    self.Toggle:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -4);

    self.ColorPickerButton:ClearAllPoints();
    self.ColorPickerButton:SetParent(parent);
    self.ColorPickerButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6);
    self.ColorPickerButton.objects = {
        model.GroundShadow.ShadowTextures.Shadow,
        model.GroundShadow.ShadowTextures.RadialShadow,
    };

    self.GroundShadowContainer = model.GroundShadow.ShadowTextures;
    self.RotationButton = model.GroundShadow.Option.RotationButton;
    self:UpdateUI();

    Narci_ColorPicker:Hide();
end