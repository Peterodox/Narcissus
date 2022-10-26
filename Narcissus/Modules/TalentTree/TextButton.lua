local _, addon = ...
local TalentTreeOnEnterDelay = addon.TalentTreeOnEnterDelay;


local TextButtonUtil = {};
addon.TalentTreeTextButtonUtil = TextButtonUtil;


local function TextButton_SetGrayscale(f, grey)
    f.ButtonText:SetTextColor(grey, grey, grey);    --0.67, 0.5
    f.Icon:SetVertexColor(grey, grey, grey)
end

local function TextButton_OnEnter(f)
    TextButton_SetGrayscale(f, f.c1);    --1, 0.92
end

local function TextButton_OnLeave(f)
    TextButton_SetGrayscale(f, f.c0);    --0.67, 0.5
    TalentTreeOnEnterDelay:ClearWatch();
end


local function TextButton_OnMouseDown(f)
    if f:IsEnabled() then
        if f.pushDirection == "vertical" then
            f.Reference:SetPoint("CENTER", 0, -TextButtonUtil.pixel or -0.8);
        else
            f.Reference:SetPoint("CENTER", TextButtonUtil.pixel or 0.8, 0);
        end
    end
end

local function TextButton_OnMouseUp(f)
    f.Reference:SetPoint("CENTER", 0, 0);
end

function TextButtonUtil:CreateButton(container, iconPosition, textAlignment, pushDirection, customButtonWidth, iconKey)
    if not self.buttons then
        self.buttons = {};
    end

    local button = CreateFrame("Button", nil, container, "NarciTalentTreeTextButtonTemplate");
    table.insert(self.buttons, button);
    button.c1 = 0.92;
    button.c0 = 0.5;
    button:SetScript("OnEnter", TextButton_OnEnter);
    button:SetScript("OnLeave", TextButton_OnLeave);
    button:SetScript("OnMouseDown", TextButton_OnMouseDown);
    button:SetScript("OnMouseUp", TextButton_OnMouseUp);
    button.iconPosition = iconPosition;
    button.textAlignment = textAlignment;
    button.pushDirection = pushDirection;
    button.iconHeight = 16;

    if textAlignment == "left" then
        button.ButtonText:SetJustifyH("LEFT");
        if iconPosition == "left" then
            button.Icon:ClearAllPoints();
            button.ButtonText:ClearAllPoints();
            button.Icon:SetPoint("LEFT", button.Reference, "LEFT", 0, 0);
            button.ButtonText:SetPoint("LEFT", button.Icon, "RIGHT", 4, 0);
        else
            button.Icon:ClearAllPoints();
            button.ButtonText:ClearAllPoints();
            button.ButtonText:SetPoint("LEFT", button.Reference, "LEFT", 0, 0);
            button.Icon:SetPoint("LEFT", button.ButtonText, "RIGHT", 4, 0);
        end
    elseif textAlignment == "right" then
        button.ButtonText:SetJustifyH("RIGHT");
        if iconPosition == "left" then
            button.Icon:ClearAllPoints();
            button.ButtonText:ClearAllPoints();
            button.ButtonText:SetPoint("RIGHT", button.Reference, "RIGHT", 0, 0);
            button.Icon:SetPoint("RIGHT", button.ButtonText, "LEFT", -4, 0);
        else
            button.Icon:ClearAllPoints();
            button.ButtonText:ClearAllPoints();
            button.Icon:SetPoint("RIGHT", button.Reference, "RIGHT", 0, 0);
            button.ButtonText:SetPoint("RIGHT", button.Icon, "LEFT", -4, 0);
        end
    else
        button.ButtonText:SetJustifyH("CENTER");
        if iconPosition == "left" then
            button.Icon:ClearAllPoints();
            button.ButtonText:ClearAllPoints();
            button.ButtonText:SetPoint("CENTER", button.Reference, "CENTER", 0, 0);
            button.Icon:SetPoint("RIGHT", button.ButtonText, "LEFT", -4, 0);
        else
            button.Icon:ClearAllPoints();
            button.ButtonText:ClearAllPoints();
            button.ButtonText:SetPoint("CENTER", button.Reference, "CENTER", 0, 0);
            button.Icon:SetPoint("LEFT", button.ButtonText, "RIGHT", 4, 0);
        end
    end


    TextButton_SetGrayscale(button, button.c0);

    if customButtonWidth then
        button:SetWidth(customButtonWidth);
    end

    if iconKey then
        self:SetButtonIcon(button, iconKey);
    end

    return button
end

function TextButtonUtil:SetButtonNormalAndHiglightColor(button, normalBrightness, highlightBrightness)
    button.c0 = normalBrightness;
    button.c1 = highlightBrightness;
    TextButton_SetGrayscale(button, normalBrightness);
end

function TextButtonUtil:UpdatePixel(px, fontPixelSize)
    if not self.buttons then return end;

    self.pixel = px;

    local fontSize = fontPixelSize * px;

    local effectiveHitHeight = 24;

    local verticalCompensation = (fontSize - effectiveHitHeight)/2;
    if verticalCompensation > 0 then
        verticalCompensation = 0;
    end

    local font = self.buttons[1].ButtonText:GetFont();
    local buttonWidth;

    local leftSideCompensation, rightCompensation;

    for i, b in ipairs(self.buttons) do
        b.ButtonText:SetFont(font, fontSize, "");
        b:SetHeight(fontSize);
        buttonWidth = b:GetWidth();
        b.Reference:SetSize(buttonWidth, fontSize);

        if b.iconWidth and b.iconHeight then
            b.Icon:SetSize(b.iconWidth * px, b.iconHeight * px);
        end

        b.Icon:ClearAllPoints();
        b.ButtonText:ClearAllPoints();

        if b.textAlignment == "left" then
            leftSideCompensation = -8;
            rightCompensation = 0;
            if b.iconPosition == "left" then
                b.Icon:SetPoint("LEFT", b.Reference, "LEFT", 0, 0);
                b.ButtonText:SetPoint("LEFT", b.Icon, "RIGHT", 4*px, 0);
            else
                b.ButtonText:SetPoint("LEFT", b.Reference, "LEFT", 0, 0);
                b.Icon:SetPoint("LEFT", b.ButtonText, "RIGHT", 4*px, 0);
            end
        elseif b.textAlignment == "right" then
            leftSideCompensation = 0;
            rightCompensation = -8;
            if b.iconPosition == "left" then
                b.ButtonText:SetPoint("RIGHT", b.Reference, "RIGHT", 0, 0);
                b.Icon:SetPoint("RIGHT", b.ButtonText, "LEFT", -4*px, 0);
            else
                b.Icon:SetPoint("RIGHT", b.Reference, "RIGHT", 0, 0);
                b.ButtonText:SetPoint("RIGHT", b.Icon, "LEFT", -4*px, 0);
            end
        else
            leftSideCompensation = 0;
            rightCompensation = 0;
            if b.iconPosition == "left" then
                b.ButtonText:SetPoint("CENTER", b.Reference, "CENTER", (b.iconWidth or 16)*px*0.5, 0);
                b.Icon:SetPoint("RIGHT", b.ButtonText, "LEFT", -4*px, 0);
            else
                b.ButtonText:SetPoint("CENTER", b.Reference, "CENTER", -(b.iconWidth or 16)*px*0.5, 0);
                b.Icon:SetPoint("LEFT", b.ButtonText, "RIGHT", 4*px, 0);
            end
        end

        b:SetHitRectInsets(leftSideCompensation, rightCompensation, verticalCompensation, verticalCompensation);
    end
end


local ICON_INFO = {
    --[iconKey] = {halfWidth, texCoords...}
    arrowRight = {true, 0, 0.125, 0, 0.25},
    arrowLeft = {true, 0.125, 0.25, 0, 0.25},
    arrowDown = {false, 0.25, 0.5, 0, 0.25},
    cog = {false, 0.5, 0.75, 0, 0.25},
    share = {false, 0.75, 1, 0, 0.25},
    inspectNode = {false, 0, 0.25, 0.75, 1},
    diffNode = {false, 0.25, 0.5, 0.75, 1},
    plus = {false, 0, 0.25, 0.25, 0.5},
    check = {false, 0.25, 0.5, 0.25, 0.5},
    cross = {false, 0.5, 0.75, 0.25, 0.5},
};

function TextButtonUtil:SetButtonIcon(textButton, icon)
    if ICON_INFO[icon] then
        local halfWidth, l, r, t, b = unpack(ICON_INFO[icon]);
        textButton.Icon:SetTexCoord(l, r, t, b);
        textButton.iconWidth = (halfWidth and 8) or 16;
        if self.pixel then
            textButton.Icon:SetSize((halfWidth and 8*self.pixel) or (16*self.pixel), 16*self.pixel);
        end
    end
end

function TextButtonUtil:SetButtonColor(textButton, r, g, b)
    textButton.ButtonText:SetTextColor(r, g, b);    --0.67, 0.5
    textButton.Icon:SetVertexColor(r, g, b)
end