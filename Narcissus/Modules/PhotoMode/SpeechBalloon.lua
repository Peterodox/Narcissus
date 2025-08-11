local _, addon = ...

local SetModelLight = addon.TransitionAPI.SetModelLight;
local GetMouseFocus = addon.TransitionAPI.GetMouseFocus;

local BACKGROUND_INSET = 3.5;
local TEXT_INSET = 16;
local SPEECH_BALLOON_MIN_SIZE = 16;
local SIMPLE_BALLON_MIN_SIZE = 40;

local TEXTURE_PATH_PREFIX = "Interface\\AddOns\\Narcissus\\Art\\Modules\\PhotoMode\\SpeechBalloon\\";
local backdropInfo = {
    white = {
        nineSliceName = "chatBubbleWhite",
        tailSize = 40,
        tailFile = "Tail-White",
    },

    black = {
        nineSliceName = "chatBubbleBlack",
        tailSize = 48,
        tailFile = "Tail-Black",
    },
};

local STROKE_SIZE = {
    2, 3, 4, 6;
};

--------------------------------------------------------------
local max = math.max;
local min = math.min;
local floor = math.floor;
local sqrt = math.sqrt;
local abs = math.abs;
local atan2 = math.atan2;
local pi = math.pi;
local pi90 = pi/2;

local upper = string.upper;
local strsplit = strsplit;

local L = Narci.L;
local NarciAPI = NarciAPI;
local FadeFrame = NarciFadeUI.Fade;
local IsMouseButtonDown = IsMouseButtonDown;
local After = C_Timer.After;

local function round(a)
    if a then
        return floor(a + 0.5)
    else
        return 0
    end
end

local function GetCircleCenter(m, n, p, q, r, positive)   --2D points: (m, n) (p, q)  radius: r
    if q == n then
        return false
    end
    local K = (m - p)/(q - n);
    local B = (n + q)/2 - K*(m + p)/2

    local a = 1 + K*K;
    local b = 2 * (K * B - K * n - m);
    local c = m*m + n*n + B*B - 2*B*n - r*r;
    local delta = b ^ 2 - 4 * a * c;
    
    if delta and delta >= 0 then
        if positive then
            positive = 1;
        else
            positive = -1;
        end
        local cx = (- b + positive* sqrt(delta)) / ( 2*a );
        local cy = K * cx + B;
        return cx, cy
    else
        return false;
    end
end

local function GetDegrees(Px, Py, Ox, Oy)
    local x = Px - Ox;
    local y = Py - Oy;
    return atan2(x, y);
end

local function GetFontData(isBold, isItalic)
    local fontObject;
    if isBold then
        if isItalic then
            fontObject = NarciSpeechBalloonFontBoldItalic
        else
            fontObject =  NarciSpeechBalloonFontBold
        end
    else
        if isItalic then
            fontObject = NarciSpeechBalloonFontItalic
        else
            fontObject = NarciSpeechBalloonFontRegular
        end
    end
    return fontObject:GetFont()
end

local ActorNameFont = {
	["CN"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
	["RM"] = {"Interface\\AddOns\\Narcissus\\Font\\OpenSans-Semibold.ttf", 9},
	["RU"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSans-Medium.ttf", 8},
	["KR"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
	["JP"] = {"Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf", 8},
};

local function SmartFontType(fontstring, text)
	--Automatically apply different font based on given text languange. Change text color after this step.
	if not fontstring then return; end;
	fontstring:SetText(text);
	local Language = NarciAPI.LanguageDetector(text);
	if Language and ActorNameFont[Language] then
		fontstring:SetFont(ActorNameFont[Language][1] , ActorNameFont[Language][2], "");
	end
end

-------------------------------------------------------------------
local Container, EditButton, PrimaryEditBox, Tooltip, Toolbar, ModelDropDownMenu, ColorDropDown, FontSizeDropDown;

local function HideEditor()
    Container:HideAllControlNodes();
    Toolbar:Hide();
    EditButton:Hide();
    EditButton:ResetState();
    PrimaryEditBox:Hide();
    PrimaryEditBox:ConfirmChanges();
end

local function IsWidgetFocused(frame)
    return frame and frame:IsFocused()
end

-------------------------------------------------------------------

local function CreateUpdater()
    local frame = CreateFrame("Frame");
    frame:Hide();
    frame.t = 0;
    frame.duration = 0.5;
    return frame
end

local simple_updateWidth = CreateUpdater();
simple_updateWidth.direction = 1;
simple_updateWidth:SetScript("OnUpdate", function(self, elapsed)
    local cursorX, cursorY = GetCursorPosition();
    cursorX = cursorX - self.dx;
    local x = self.direction * (cursorX - self.x0);   --distance from cursor to center
    self.parent:SetBoundaryWidth(2 * x);
end);

local simple_updateHeight = CreateUpdater();
simple_updateHeight:SetScript("OnUpdate", function(self, elapsed)
    local cursorX, cursorY = GetCursorPosition();
    cursorY = cursorY - self.dy;
    local y = cursorY - self.y0;   --distance from cursor to center
    self.parent:SetBoundaryHeight(2 * y);
end);

local simple_updateTailAttach = CreateUpdater();
simple_updateTailAttach:SetScript("OnUpdate", function(self, elapsed)
    local cursorX = GetCursorPosition();
    cursorX = cursorX - self.dx;
    local x = cursorX - self.x0;

    local maxOffset = self.maxOffset;
    if x > maxOffset then
        x = maxOffset;
    elseif x < -maxOffset then
        x = -maxOffset;
    end
    self.parent:SetTailAttachOffset(x);
end);

-------------------------------------------------------------------

local SharedSpeechBallonMixin = {};


function SharedSpeechBallonMixin:OnDragStart()
    self:StartMoving();
end

function SharedSpeechBallonMixin:OnDragStop()
    self:StopMovingOrSizing();

    --convert anchor to CENTER;
    local x, y = self:GetCenter();
    self:ClearAllPoints();
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y);
end

function SharedSpeechBallonMixin:OnEnter()
    if not IsMouseButtonDown() then
        if EditButton.parentObject == self then
            EditButton:FadeIn(0.25);
        end
    end
end

function SharedSpeechBallonMixin:OnLeave()
    if not self:IsMouseOver() then
        EditButton:FadeOut(0.25);
    end
end

function SharedSpeechBallonMixin:SetBold(state)
    self.isBold = state;
    self:UpdateText();
end

function SharedSpeechBallonMixin:SetItalic(state)
    self.isItalic = state;
    self:UpdateText();
end

function SharedSpeechBallonMixin:SetAllCaps(state)
    self.isAllCaps = state;
    self:UpdateText();
end

function SharedSpeechBallonMixin:SetNodesTransparency(value)
    value = value or 1;
    local visible = (value ~= 0)
    local node;
    for i = 1, #self.Nodes do
        node = self.Nodes[i];
        node:SetAlpha(value);
        node:SetShown(visible);
    end
end

function SharedSpeechBallonMixin:OnClick()
    if self.Nodes[1]:IsShown() then
        HideEditor();
    else
        Toolbar:SetParentObject(self);
        Container:HideAllControlNodes(self);
        EditButton:SetParentObject(self);
        if not IsMouseButtonDown() then
            EditButton:FadeIn(0.25);
        end
    end
end

function SharedSpeechBallonMixin:IsFocused()
    if self:IsMouseOver(16, -16, -16, 16) then
        return true
    else
        for i = 1, #self.Nodes do
            if self.Nodes[i]:IsMouseOver() then
                return true
            end
        end
    end
    return false
end

-------------------------------------------------------------------

NarciSimpleSpeechBalloonMixin = CreateFromMixins(SharedSpeechBallonMixin);

function NarciSimpleSpeechBalloonMixin:OnLoad()
    self:RegisterForDrag("LeftButton");
    self.balloonTpye = 1;
    self:SelectTheme(2);
    self:SetText("");
    self:SetTailAttachOffset(0);
    self:SetBoundaryWidth(180);
    self:SetBoundaryHeight(90);
    self:SetNodesTransparency(0);
    self:UpdateText();
    self.padding = 14;

    self.WidthNode.transformFunc = function(dx, dy)
        simple_updateWidth.x0 = self:GetCenter();
        simple_updateWidth.direction = -1;
        simple_updateWidth.parent = self;
        simple_updateWidth.dx, simple_updateWidth.dy = dx, dy;
        simple_updateWidth:Show();
    end

    self.WidthNodeRight.transformFunc = function(dx, dy)
        simple_updateWidth.x0 = self:GetCenter();
        simple_updateWidth.direction = 1;
        simple_updateWidth.parent = self;
        simple_updateWidth.dx, simple_updateWidth.dy = dx, dy;
        simple_updateWidth:Show();
    end

    self.HeightNode.transformFunc = function(dx, dy)
        local _;
        _, simple_updateHeight.y0 = self:GetCenter();
        simple_updateHeight.dx, simple_updateHeight.dy = dx, dy;
        simple_updateHeight.parent = self;
        simple_updateHeight:Show();
    end

    self.TailAttachNode.transformFunc = function(dx, dy)
        simple_updateTailAttach.parent = self;
        simple_updateTailAttach.x0 = self:GetCenter();
        simple_updateTailAttach.dx = dx;
        simple_updateTailAttach.maxOffset = self:GetWidth()/2 - 16;
        simple_updateTailAttach:Show();
    end
end



function NarciSimpleSpeechBalloonMixin:AutoSizing()
    local textHeight = round( self.ShownText:GetStringHeight() );
    textHeight = textHeight - 1;
    self:SetHeight( max(SIMPLE_BALLON_MIN_SIZE, 2*(BACKGROUND_INSET + TEXT_INSET) + textHeight) );
    local textWidth = round(self.ShownText:GetStringWidth());
    self:SetWidth( max(SIMPLE_BALLON_MIN_SIZE, 2*(BACKGROUND_INSET + TEXT_INSET) + textWidth) );
end

function NarciSimpleSpeechBalloonMixin:SetBoundaryWidth(width)
    local minWidth = SIMPLE_BALLON_MIN_SIZE;
    if width < minWidth then
        width = minWidth;
    end
    self.WidthNode:SetPoint("CENTER", self, "CENTER", -width/2, 0);
    self.WidthNodeRight:SetPoint("CENTER", self, "CENTER", width/2, 0);
    self:SetWidth(width + 6);

    --Update tail position
    local maxOffset = width/2 - 16;
    local tailAttachOffset = self.tailAttachOffset or 0;
    self.maxOffset = maxOffset;
    if tailAttachOffset < -maxOffset then
        self:SetTailAttachOffset(-maxOffset);
    elseif tailAttachOffset > maxOffset then
        self:SetTailAttachOffset(maxOffset);
    end
end

function NarciSimpleSpeechBalloonMixin:SetBoundaryHeight(height)
    local minHeight = SIMPLE_BALLON_MIN_SIZE;
    if height < minHeight then
        height = minHeight;
    end
    self.HeightNode:SetPoint("CENTER", self, "CENTER", 0, height/2);
    self:SetHeight(height + 6);
end

function NarciSimpleSpeechBalloonMixin:SetTailAttachOffset(offset)
    if offset > -8 and offset < 8 then
        offset = 0;
    end
    if offset < 0 then
        if self.facingRight then
            self.facingRight = false;
            self.Tail:SetTexCoord(0, 1, 0, 1);
        end
    elseif offset > 0 then
        if not self.facingRight then
            self.facingRight = true;
            self.Tail:SetTexCoord(1, 0, 0, 1);
        end
    end
    self.Tail:SetPoint("CENTER", self, "BOTTOM", offset, 4);
    self.TailAttachNode:SetPoint("CENTER", self, "BOTTOM", offset, 10);
    self.tailAttachOffset = offset;
end

function NarciSimpleSpeechBalloonMixin:SetText(str)
    str = str or "";
    self.rawText = str;
    if self.isAllCaps then
        str = upper(str);
    end
    self.ShownText:SetText(str);
    self:AutoSizing();
end

local THEME_PRESETS = {
    --For Simple Balloon
    {1, 1, 1},
    {0.15, 0.15, 0.15},
};

function NarciSimpleSpeechBalloonMixin:SelectTheme(themeID)
    themeID = themeID or 1;     --Default White
    self.themeID = themeID;
    self.backgroundColor = THEME_PRESETS[themeID];

    local info;

    if themeID == 1 then
        info = backdropInfo.white;
        self.ShownText:SetTextColor(0, 0, 0);
        self.ShownText:SetShadowColor(0, 0, 0, 0);
        self.ShownText:SetShadowOffset(0, 0);
    else
        info = backdropInfo.black;
        self.ShownText:SetTextColor(1, 0.91, 0.647);
        self.ShownText:SetShadowColor(0, 0, 0, 1);
        self.ShownText:SetShadowOffset(1, -1);
    end

    local tailSize = info.tailSize;
    self.Tail:SetSize(tailSize, tailSize);
    self.Tail:SetTexture(TEXTURE_PATH_PREFIX.. info.tailFile, nil, nil, "TRILINEAR");

    NarciAPI.NineSliceUtil.SetUpBackdrop(self, info.nineSliceName);
end

function NarciSimpleSpeechBalloonMixin:UpdateText()
    local font, height = GetFontData(self.isBold, self.isItalic);
    height = round(height);
    self.fontPath = font;
    if not self.fontHeight then
        self.fontHeight = height;
    else
        height = self.fontHeight;
    end

    if self.isAllCaps then
        self.ShownText:SetText(upper(self.rawText));
    else
        self.ShownText:SetText(self.rawText);
    end

    self.ShownText:SetFont(font, height, "");
end

function NarciSimpleSpeechBalloonMixin:SetFontColor(r, g, b)
    self.ShownText:SetTextColor(r, g, b);
end

function NarciSimpleSpeechBalloonMixin:OnClick()
    if self.Nodes[1]:IsShown() then
        HideEditor();
    else
        Toolbar:SetParentObject(self);
        Container:HideAllControlNodes(self);
        EditButton:SetParentObject(self);
        if not IsMouseButtonDown() then
            EditButton:FadeIn(0.25);
        end
    end
end


---------------------------------------------------------------------------------------------------------
local LetteringSystem = {};
local wordFrame = CreateFrame("Frame");
wordFrame:SetAlpha(0);
wordFrame:SetSize(8, 8);
wordFrame:SetPoint("TOP", UIParent, "BOTTOM", 0, 0);
LetteringSystem.wordContainer = wordFrame:CreateFontString(nil, "BACKGROUND", "NarciSpeechBalloonFontItalic");

function LetteringSystem:GetWordWidth(word)
    self.wordContainer:SetText(word);
    local width = self.wordContainer:GetStringWidth();
    return width
end

function LetteringSystem:EvaluateWidth(word, boundaryWidth)
    return (self:GetWordWidth(word) <= boundaryWidth) ;
end

function LetteringSystem:GetLine(object, index)
    if not object.lines then
        object.lines = {};
    end
    local line = object.lines[index];
    if not line then
        local font, height = object.fontPath, object.fontHeight;
        line = object:CreateFontString(nil, "OVERLAY");
        line:SetFont(font, height, "");
        local r, g, b = object.ShownText:GetTextColor();
        line:SetTextColor(r, g, b);
        line:SetMaxLines(1);
        line:SetHeight(round(height) + 0.10);
        tinsert(object.lines, line);
        if index == 1 then
            line:SetPoint("TOP", object, "TOP", 0, -object.padding);
        else
            line:SetPoint("TOP", object.lines[index - 1], "BOTTOM", 0, -2);
        end
    end
    line:SetWidth( object:GetWidth() - object.padding*2 );
    return line
end

function LetteringSystem:UpdateFont(object)
    if object.lines then
        local r, g, b = object.ShownText:GetTextColor();
        local line;
        local font, height = object.fontPath, object.fontHeight;
        for i = 1, #object.lines do
            line = object.lines[i];
            line:SetFont(font, height, "");
            line:SetTextColor(r, g, b);
            line:SetHeight(round(height) + 0.10);
        end
    end
    self:SetText(object);
end

function LetteringSystem:GetBoundaryWidth(object, lineIndex)
    local w, h = object:GetSize();
    local yMax = h/2;
    local R = object.cornerRadius;
    local a, b = -w/2 + R, yMax - R;
    local padding = object.padding;

    local x, y;
    y = yMax - padding * lineIndex - 2*(lineIndex - 1)
    if y > yMax - R then
        y = yMax - padding * lineIndex - 2*(lineIndex - 1);
        local z = (R - padding)^2 - (y - b)^2;
        if z < 0 then z = 0; end
        x = sqrt(z) - a;
    elseif y < -yMax + R then
        y = y - 14;
        local z = (R - padding)^2 - (y + b)^2;
        if z < 0 then z = 0; end
        x = sqrt(z) - a;
    else
        x = w/2 - padding;
    end

    return 2*x
end

function LetteringSystem:ShowText(object, state)
    if object.lines then
        for i = 1, #object.lines do
            object.lines[i]:SetShown(state);
        end
    end
end

function LetteringSystem:SetText(object, text)
    if not object.textWrapping then
        if object.lines then
            for i = 1, #object.lines do
                object.lines[i]:SetText("");
            end
        end
        return
    end

    if text then
        object.rawText = text;
    else
        text = object.rawText or "";
    end
    if object.isAllCaps then
        text = upper(text);
    end

    local words = { strsplit(" ", text) };
    if not words then return end;

    local line, lineString, fineString;
    local wordIndex = 0;
    local numLines = 0;
    local numWords = #words;


    while( (numLines < 20) and (wordIndex < numWords) ) do
        wordIndex = wordIndex + 1;
        lineString = words[wordIndex];
        numLines = numLines + 1;
        local boundaryWidth = self:GetBoundaryWidth(object, numLines);
        line = self:GetLine(object, numLines);
        line:SetWidth(boundaryWidth);
        line:SetText(lineString);
        local nextWord;
        for i = wordIndex + 1, numWords do
            wordIndex = wordIndex + 1;
            nextWord = " ".. words[i];
            line:SetText(lineString..nextWord);
            if not line:IsTruncated() then
                lineString = lineString..nextWord;
            else
                wordIndex = wordIndex -1;
                line:SetText(lineString);
                break; 
            end
        end
        --print(numLines)
    end

    for i = numLines + 1, #object.lines do
        object.lines[i]:SetText("");
    end
end


local updateCorner = CreateUpdater()
updateCorner:SetScript("OnUpdate", function(self, elapsed)
    local cursorX, cursorY = GetCursorPosition();
    cursorX = cursorX - self.dx;
    cursorY = cursorY - self.dy;
    --local d = sqrt( (cursorX - self.x0)^2 + (cursorY - self.y0)^2 );
    --d = d / 1.4142;
    local r = min(cursorX - self.x0, self.y0- cursorY);
    if r > self.maxRadius then
        r = self.maxRadius;
    elseif r <= 0 then
        r = 0.1;
    end
    self.parent:SetCornerRadius(r);

    self.t = self.t + elapsed;
    if self.t >= self.duration then
        self.t = 0;
        LetteringSystem:SetText(self.parent);
    end
end);

local function SetParentObject(object)
    local updateCorner = updateCorner;
    updateCorner.maxRadius = min(object:GetHeight(), object:GetWidth())/2
    updateCorner.parent = object;
end


local updateWidth = CreateUpdater()
updateWidth.direction = 1;
updateWidth:SetScript("OnUpdate", function(self, elapsed)
    local cursorX, cursorY = GetCursorPosition();
    cursorX = cursorX - self.dx;
    local x = self.direction * (cursorX - self.x0);   --distance from cursor to center
    self.parent:SetBoundaryWidth(2 * x);

    self.t = self.t + elapsed;
    if self.t >= self.duration then
        self.t = 0;
        LetteringSystem:SetText(self.parent);
    end
end);

local updateHeight = CreateUpdater()
updateHeight:SetScript("OnUpdate", function(self, elapsed)
    local cursorX, cursorY = GetCursorPosition();
    cursorY = cursorY - self.dy;
    local y = cursorY - self.y0;   --distance from cursor to center
    self.parent:SetBoundaryHeight(2 * y);

    self.t = self.t + elapsed;
    if self.t >= self.duration then
        self.t = 0;
        LetteringSystem:SetText(self.parent);
    end
end);

local updateTailEnd = CreateUpdater()
updateTailEnd:SetScript("OnUpdate", function(self, elapsed)
    local cursorX, cursorY = GetCursorPosition();
    cursorX = cursorX - self.dx;
    cursorY = cursorY - self.dy;
    local x, y = cursorX - self.x0, cursorY - self.y0;
    if y > 0 then
        y = 0;
    end
    self.parent:SetTailEnd(x, y);
end);

local updateTailAttach = CreateUpdater()
updateTailAttach:SetScript("OnUpdate", function(self, elapsed)
    local cursorX = GetCursorPosition();
    cursorX = cursorX - self.dx;
    local x = cursorX - self.x0;

    local maxOffset = self.maxOffset;
    if x > maxOffset then
        x = maxOffset;
    elseif x < -maxOffset then
        x = -maxOffset;
    end
    self.parent:SetTailAttachOffset(x);
end);

local updateTailWidth = CreateUpdater()
updateTailWidth:SetScript("OnUpdate", function(self, elapsed)
    local cursorX = GetCursorPosition();
    cursorX = cursorX - self.dx;
    local x = cursorX - self.x0;
    if x < 10 then
        x = 10;
    elseif x > 40 then
        x = 40;
    end
    self.parent:SetTailWidth(x);
end);

local updateTailArc = CreateUpdater()
updateTailArc:SetScript("OnUpdate", function(self, elapsed)
    local cursorX = GetCursorPosition();
    local x = cursorX - self.dx - self.x0;
    if self.facingRight then
        if x < 10 then
            x = 10;
        elseif x > 80 then
            x = 80;
        end
    else
        if x > -10 then
            x = 10;
        elseif x < -80 then
            x = 80;
        end
    end
    x = abs(x);
    self.parent:SetTailArcRadius(4*x);
end);

local function Node_OnMouseUp()
    simple_updateHeight:Hide();
    simple_updateWidth:Hide();
    simple_updateTailAttach:Hide();
    updateWidth:Hide();
    updateHeight:Hide();
    updateCorner:Hide();
    updateTailEnd:Hide();
    updateTailAttach:Hide();
    updateTailWidth:Hide();
    updateTailArc:Hide();
end

local function ColorButton_OnClick(self)
    self.parent:SetBackgroundColor(237/255, 28/255, 36/255);
end


NarciAdjustableSpeechBalloonMixin = CreateFromMixins(SharedSpeechBallonMixin);

function NarciAdjustableSpeechBalloonMixin:OnLoad()
    self.rawText = "";

    self.padding = 12;
    self.corners = {self.CornerTopLeft, self.CornerTopRight, self.CornerBottomLeft, self.CornerBottomRight};
    self.borders = {self.BorderMaskTopLeft, self.BorderMaskTopRight, self.BorderMaskBottomLeft, self.BorderMaskBottomRight};
    self:RegisterForDrag("LeftButton");

    self.CornerNode.isBoundaryButton = true;
    self.CornerNode.transformFunc = function(dx, dy)
        updateCorner.uiScale = UIParent:GetEffectiveScale();
        updateCorner.x0 = self:GetLeft();
        updateCorner.y0 = self:GetTop();
        updateCorner.dx, updateCorner.dy = dx, dy;
        SetParentObject(self);
        updateCorner:Show();
    end

    self.WidthNode.isBoundaryButton = true;
    self.WidthNode.transformFunc = function(dx, dy)
        updateWidth.x0 = self:GetCenter();
        updateWidth.direction = -1;
        updateWidth.parent = self;
        updateWidth.dx, updateWidth.dy = dx, dy;
        updateWidth:Show();
    end

    self.WidthNodeRight.isBoundaryButton = true;
    self.WidthNodeRight.transformFunc = function(dx, dy)
        updateWidth.x0 = self:GetCenter();
        updateWidth.direction = 1;
        updateWidth.parent = self;
        updateWidth.dx, updateWidth.dy = dx, dy;
        updateWidth:Show();
    end

    self.HeightNode.isBoundaryButton = true;
    self.HeightNode.transformFunc = function(dx, dy)
        local _;
        _, updateHeight.y0 = self:GetCenter();
        updateHeight.dx, updateHeight.dy = dx, dy;
        updateHeight.parent = self;
        updateHeight:Show();
    end

    self.TailEndNode.transformFunc = function(dx, dy)
        updateTailEnd.parent = self;
        updateTailEnd.x0 = self:GetCenter();
        updateTailEnd.y0 = self:GetBottom();
        updateTailEnd.dx, updateTailEnd.dy = dx, dy;
        updateTailEnd:Show();
    end

    self.TailAttachNode.transformFunc = function(dx, dy)
        updateTailAttach.parent = self;
        updateTailAttach.x0 = self:GetCenter();
        updateTailAttach.dx = dx;
        updateTailAttach.maxOffset = self:GetWidth()/2 - self.cornerRadius - self.tailWidth/2;
        updateTailAttach:Show();
    end

    self.TailWidthNode.transformFunc = function(dx, dy)
        updateTailWidth.parent = self;
        updateTailWidth.x0 = self:GetCenter() + self.tailAttachOffset;
        updateTailWidth.dx = dx;
        updateTailWidth:Show();
    end

    self.TailArcNode.transformFunc = function(dx, dy)
        updateTailArc.parent = self;
        updateTailArc.x0 = self.TailEndNode:GetCenter();
        updateTailArc.dx = dx;
        updateTailArc.facingRight = self.facingRight;
        updateTailArc:Show();
    end

    self.ColorButton.parent = self;
    self.ColorButton:SetScript("OnClick", ColorButton_OnClick);

    self:SetNodesTransparency(0);
    self:SetBorderThickness(3);
    self:SetCornerRadius(6);
    self:SetBoundaryWidth(180);
    self:SetBoundaryHeight(90);
    self:SetPadding(12);
    self:SetTail(-12, -20, 0, 20, 200);
    self:SetBackgroundColor(1, 1, 1);
    self:SetBorderColor(0, 0, 0);
    self:SetTextWrapping(false);
    self:UpdateText();
    LetteringSystem:SetText(self, "");
end

function NarciAdjustableSpeechBalloonMixin:SetBorderThickness(value)
    self.borderPixelSize = value;
    local pixel = NarciAPI.GetPixelForWidget(self, value);
    value = pixel;        --Pixel Scale
    self.thickness = value;
    local cornerRadius = self.CornerTopRight:GetWidth();
    self.BorderLeft:SetPoint("TOPLEFT", self, "TOPLEFT", -value, value);
    self.BorderLeft:SetPoint("BOTTOMRIGHT", self, "BOTTOM", 0, -value);
    self.BorderRight:SetPoint("TOPLEFT", self, "TOP", -0, value);
    self.BorderRight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", value, -value);
    self.BorderMaskTopLeft:SetSize(cornerRadius + value, cornerRadius + value);
    self.BorderMaskTopRight:SetSize(cornerRadius + value, cornerRadius + value);
    self.BorderMaskBottomLeft:SetSize(cornerRadius + value, cornerRadius + value);
    self.BorderMaskBottomRight:SetSize(cornerRadius + value, cornerRadius + value);

    if self.tailEndOffsetX then
        self:UpdateTail();
    else
        local tailD = 2 * (self.Circle1:GetWidth());
        local tailBorderThickness = value * 1.832;
        self.TailBorderCircle1:SetSize(tailD + tailBorderThickness, tailD + tailBorderThickness);
        self.TailBorderCircle2:SetSize(tailD + tailBorderThickness, tailD + tailBorderThickness);
    end
end

function NarciAdjustableSpeechBalloonMixin:SetCornerRadius(r)
    local showMask = true;
    local CornerNode = self.CornerNode;
    if r <= 4 then
        showMask = false;
        CornerNode:SetPoint("CENTER", self, "TOPLEFT", 4, -4);
        CornerNode.Mark:SetPoint("CENTER", CornerNode, "CENTER", -4/1.414 - 2, 4/1.414 + 2);
        CornerNode.Mark:SetTexCoord(0, 1, 0, 1);
        self.cornerRadius = 0;
    else
        CornerNode:SetPoint("CENTER", self, "TOPLEFT", r, -r);
        self.cornerRadius = r;
        if r < 25 then
            CornerNode.Mark:SetTexCoord(0, 1, 0, 1);
            CornerNode.Mark:SetPoint("CENTER", CornerNode, "CENTER", -r/1.414 - 2, r/1.414 + 2);
        else
            CornerNode.Mark:SetTexCoord(1, 0, 1, 0);
            CornerNode.Mark:SetPoint("CENTER", CornerNode, "CENTER", -r/1.414 + 2, r/1.414 - 2);
        end
    end

    for i = 1, #self.corners do
        self.corners[i]:SetSize(r, r);
    end
    local r2 = r + (self.thickness or 2);
    for i = 1, #self.borders do
        self.borders[i]:SetSize(r2, r2);
    end

    for i = 1, #self.corners do
        self.corners[i]:SetShown(showMask);
    end
    for i = 1, #self.borders do
        self.borders[i]:SetShown(showMask);
    end

    self:UpdateTailPosition();

    --Reposition EidtButton
    if EditButton then
        local offset = (0.4142 * r + 24)/1.4142;
        EditButton:SetPoint("CENTER", self, "BOTTOMRIGHT", -offset, offset);
    end
end

function NarciAdjustableSpeechBalloonMixin:SetBoundaryWidth(width)
    local minWidth = max(2 * self.CornerTopLeft:GetWidth(), SPEECH_BALLOON_MIN_SIZE + 2*self.padding);
    if width < minWidth then
        width = minWidth;
    end
    self.WidthNode:SetPoint("CENTER", self, "CENTER", -width/2, 0);
    self.WidthNodeRight:SetPoint("CENTER", self, "CENTER", width/2, 0);
    self:SetWidth(width);
    
    self:UpdateTailPosition();
end

function NarciAdjustableSpeechBalloonMixin:SetBoundaryHeight(height)
    local cornerRadius = self.CornerTopLeft:GetWidth();
    local minHeight = max(2 * cornerRadius, SPEECH_BALLOON_MIN_SIZE + 2*self.padding);
    if height < minHeight then
        height = minHeight;
    end
    self.HeightNode:SetPoint("CENTER", self, "CENTER", 0, height/2);
    self:SetHeight(height);
end

function NarciAdjustableSpeechBalloonMixin:SetPadding(distance)
    distance = distance or 0;
    if distance < 0 then
        distance = 0;
    end
    self.padding = distance;
    self.ShownText:ClearAllPoints();
    self.ShownText:SetPoint("TOPLEFT", self, "TOPLEFT", distance, -distance - 2);
    self.ShownText:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -distance, distance);
end

function NarciAdjustableSpeechBalloonMixin:SetTail(m, n, o, d, r)
    --local m, n = -20, -120;
    local r1 = r;
    local r2 = r;

    if n >= -12 then        --minimum offsetY
        n = -12;
    end

    local facingRight = m > o;

    local a1, b1 = GetCircleCenter(m, n, o - d/2, 0, r1, facingRight);
    local a2, b2 = GetCircleCenter(m, n, o + d/2, 0, r2, facingRight);

    if a1 and a2 then
        self.tailEndOffsetX = m;
        self.tailEndOffsetY = n;
        self.tailAttachOffset = o;
        self.tailWidth = d;
        self.tailArcRadius = r;

        local thickness = self.thickness * 1.832;
        r1 = r1 * 2;
        r2 = r2 * 2;
        self.Circle1:SetSize(r1, r1);
        self.Circle2:SetSize(r2, r2);
        self.Circle1:SetPoint("CENTER", self, "BOTTOM", a1, b1);
        self.Circle2:SetPoint("CENTER", self, "BOTTOM", a2, b2);
        if facingRight then
            self.TailBorderCircle1:SetSize(r1 + thickness, r1 + thickness);
            self.TailBorderCircle2:SetSize(r2 - thickness, r2 - thickness);
            if not self.facingRight then
                self.facingRight = true;
                self.Circle2:SetTexture(TEXTURE_PATH_PREFIX.. "CircleOuter-ShowLeft", "CLAMPTOWHITE", "CLAMPTOWHITE");
                self.Circle1:SetTexture(TEXTURE_PATH_PREFIX.. "Circle512", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
                self.TailBorderCircle2:SetTexture(TEXTURE_PATH_PREFIX.. "CircleOuter-ShowLeft", "CLAMPTOWHITE", "CLAMPTOWHITE");
                self.TailBorderCircle1:SetTexture(TEXTURE_PATH_PREFIX.. "Circle512", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
            end
        else
            self.TailBorderCircle1:SetSize(r1 - thickness, r1 - thickness);
            self.TailBorderCircle2:SetSize(r2 + thickness, r2 + thickness);
            if self.facingRight then
                self.facingRight = false;
                self.Circle1:SetTexture(TEXTURE_PATH_PREFIX.. "CircleOuter-ShowRight", "CLAMPTOWHITE", "CLAMPTOWHITE");
                self.Circle2:SetTexture(TEXTURE_PATH_PREFIX.. "Circle512", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
                self.TailBorderCircle1:SetTexture(TEXTURE_PATH_PREFIX.. "CircleOuter-ShowRight", "CLAMPTOWHITE", "CLAMPTOWHITE");
                self.TailBorderCircle2:SetTexture(TEXTURE_PATH_PREFIX.. "Circle512", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
            end
        end
        self.TailBorderCircle1:SetPoint("CENTER", self, "BOTTOM", a1, b1);
        self.TailBorderCircle2:SetPoint("CENTER", self, "BOTTOM", a2, b2);

        --Update button position
        self.TailEndNode:SetPoint("CENTER", self, "BOTTOM", m, n);
        self.TailAttachNode:SetPoint("CENTER", self, "BOTTOM", o, 0);

        local TailArcNode = self.TailArcNode;
        local markX, degrees;
        local markY = n + 24; 
        if facingRight then
            TailArcNode:SetPoint("CENTER", self.TailEndNode, "CENTER", r/4, 6);
            markX = -sqrt(r^2 - (markY - b2)^2) + a2;
            degrees = GetDegrees(markX, markY, a2, b2);
        else
            TailArcNode:SetPoint("CENTER", self.TailEndNode, "CENTER", -r/4, 6);
            markX = sqrt(r^2 - (markY - b1)^2) + a1;
            degrees = GetDegrees(markX, markY, a1, b1);
        end
        TailArcNode.Mark:SetPoint("CENTER", self, "BOTTOM", markX, markY);
        TailArcNode.Mark:SetRotation(pi90 - degrees);

        local TailWidthNode = self.TailWidthNode;
        TailWidthNode.Mark1:ClearAllPoints();
        TailWidthNode.Mark1:SetPoint("RIGHT", self.TailAttachNode, "CENTER", -d/2 + 2, 8);
        TailWidthNode.Mark2:ClearAllPoints();
        TailWidthNode.Mark2:SetPoint("LEFT", self.TailAttachNode, "CENTER", d/2 - 2, 8);
        TailWidthNode:SetPoint("CENTER", self, "BOTTOM", o + d, 0);
    end
end

function NarciAdjustableSpeechBalloonMixin:SetTailEnd(m, n)
    self:SetTail(m, n, self.tailAttachOffset, self.tailWidth, self.tailArcRadius);
end

function NarciAdjustableSpeechBalloonMixin:SetTailWidth(d)
    self:SetTail(self.tailEndOffsetX, self.tailEndOffsetY, self.tailAttachOffset, d, self.tailArcRadius);
end

function NarciAdjustableSpeechBalloonMixin:SetTailAttachOffset(o)
    if o > -4 and o < 4 then
        o = 0;
    end
    self:SetTail(self.tailEndOffsetX, self.tailEndOffsetY, o, self.tailWidth, self.tailArcRadius);
end

function NarciAdjustableSpeechBalloonMixin:SetTailArcRadius(r)
    self:SetTail(self.tailEndOffsetX, self.tailEndOffsetY, self.tailAttachOffset, self.tailWidth, r);
end

function NarciAdjustableSpeechBalloonMixin:UpdateTail(r)
    self:SetTail(self.tailEndOffsetX, self.tailEndOffsetY, self.tailAttachOffset, self.tailWidth, self.tailArcRadius);
end

function NarciAdjustableSpeechBalloonMixin:UpdateTailPosition()
    local maxOffset = abs(self:GetWidth()/2 - self.cornerRadius - (self.tailWidth or 0) );
    local tailAttachOffset = self.tailAttachOffset or 0;
    local direction = false;
    if tailAttachOffset < -maxOffset then
        direction = -1;
        tailAttachOffset = maxOffset;
    elseif tailAttachOffset > maxOffset then
        direction = 1;
        tailAttachOffset = maxOffset;
    end
    if direction then
        self:SetTailAttachOffset(direction * tailAttachOffset);
    end
end

function NarciAdjustableSpeechBalloonMixin:SetBackgroundColor(r, g, b)
    self.BackgroundLeft:SetColorTexture(r, g, b);
    self.BackgroundRight:SetColorTexture(r, g, b);
    self.TailBackground:SetColorTexture(r, g, b);
    self.backgroundColor = {r, g, b};
end

function NarciAdjustableSpeechBalloonMixin:UpdateText()
    local font, height = GetFontData(self.isBold, self.isItalic);
    height = round(height);
    self.fontPath = font;
    if not self.fontHeight then
        self.fontHeight = height;
    else
        height = self.fontHeight;
    end
    LetteringSystem:UpdateFont(self);
    if self.textWrapping then
        self.ShownText:SetText("");
    else
        if self.isAllCaps then
            self.ShownText:SetText(upper(self.rawText));
        else
            self.ShownText:SetText(self.rawText);
        end
    end
    self.ShownText:SetFont(font, height, "");
end

function NarciAdjustableSpeechBalloonMixin:SetBorderColor(r, g, b, a)
    self.BorderLeft:SetColorTexture(r, g, b);
    self.BorderRight:SetColorTexture(r, g, b);
    self.TailBorder:SetColorTexture(r, g, b);
    self.borderColor = {r, g, b};
end

function NarciAdjustableSpeechBalloonMixin:SetFontColor(r, g, b)
    self.ShownText:SetTextColor(r, g, b);
    LetteringSystem:UpdateFont(self);
end


function NarciAdjustableSpeechBalloonMixin:SetTextWrapping(state)
    self.textWrapping = state;
    self:UpdateText();
end

function NarciAdjustableSpeechBalloonMixin:OnDoubleClick()
    --EditButton:Click();
end


-----------------------------------------------------------------
NarciSpeechBalloonControlNodeMixin = {};

function NarciSpeechBalloonControlNodeMixin:OnLoad()
    self.Texture:SetTexture(TEXTURE_PATH_PREFIX.. "ControlNode", nil, nil, "TRILINEAR");
end

function NarciSpeechBalloonControlNodeMixin:OnClick()
    self.Bling:Show();
    self.Bling.animScale:Play();
end

function NarciSpeechBalloonControlNodeMixin:OnMouseDown()
    self:LockHighlight();
    local cx, cy = GetCursorPosition();
    local x0, y0 = self:GetCenter();
    if self.transformFunc then
        self.transformFunc(cx - x0, cy- y0);
    end
    EditButton:FadeOut(0.12);
end

function NarciSpeechBalloonControlNodeMixin:OnMouseUp()
    self:UnlockHighlight();
    if self.isBoundaryButton then
        Node_OnMouseUp();
        LetteringSystem:SetText(self:GetParent());
    else
        Node_OnMouseUp();
    end
    if not self:IsMouseOver() then
        if self.Mark then
            self.Mark:Hide();
        end
        if self.Mark1 then
            self.Mark1:Hide();
            self.Mark2:Hide();
        end
    end

    if self:GetParent():IsMouseOver() then
        EditButton:FadeIn(0.5);
    end
end

function NarciSpeechBalloonControlNodeMixin:OnEnter()
    if (not IsMouseButtonDown()) then
        if self.Mark then
            self.Mark:Show();
        end
        if self.Mark1 then
            self.Mark1:Show();
            self.Mark2:Show();
        end
    end
end

function NarciSpeechBalloonControlNodeMixin:OnLeave()
    if (not IsMouseButtonDown()) then
        if self.Mark then
            self.Mark:Hide();
        end
        if self.Mark1 then
            self.Mark1:Hide();
            self.Mark2:Hide();
        end
    end
    EditButton:SmartFadeOut();
end


----------------------------------------------------------
NarciSpeechBalloonToolbarButtonMixin = {};

function NarciSpeechBalloonToolbarButtonMixin:OnEnter()
    Tooltip:ShowDelayedTooltip(self);
    if self.expandable then
        if not self.isOn then
            self.Arrow:Show();
            self.Arrow.flyInUp:Play();
        end
    end
end

function NarciSpeechBalloonToolbarButtonMixin:OnLeave()
    Tooltip:HideTooltip();
    if self.expandable then
        self.Arrow:Hide();
    end
end

function NarciSpeechBalloonToolbarButtonMixin:SetBackgroundColor(r, g, b)
    if self.Background then
        self.Background:SetVertexColor(r, g, b);
    elseif self.Middle then
        self.Left:SetVertexColor(r, g, b);
        self.Middle:SetVertexColor(r, g, b);
        self.Right:SetVertexColor(r, g, b);
    end
end

function NarciSpeechBalloonToolbarButtonMixin:Select()
    self.Background:SetVertexColor(0.72, 0.72, 0.72);
    self.Icon:SetVertexColor(0, 0, 0);
end

function NarciSpeechBalloonToolbarButtonMixin:Deselect()
    self.Background:SetVertexColor(0.35, 0.35, 0.35);
    self.Icon:SetVertexColor(1, 1, 1);
end

function NarciSpeechBalloonToolbarButtonMixin:UpdateSelection(isSelected)
    if isSelected then
        self:Select();
    else
        self:Deselect();
    end
end

function NarciSpeechBalloonToolbarButtonMixin:OnEvent(event)
    if self.options then
        local isInbound = self:IsMouseOver();
        for i = 1, #self.options do
            isInbound = isInbound or self.options[i]:IsMouseOver();
            if isInbound then
                return
            end
        end
        if not isInbound then
            self:UnregisterEvent(event);
            if self.closeFunc then
                self.closeFunc(self);
            end
        end
    end
end


NarciSpeechBalloonToolbarLongButtonMixin = CreateFromMixins(NarciSpeechBalloonToolbarButtonMixin)

function NarciSpeechBalloonToolbarLongButtonMixin:OnEnter()
    Tooltip:ShowDelayedTooltip(self);
    if self.expandable then
        if not self.isOn then
            self.Arrow:Show();
            self.Arrow.flyInUp:Play();
        end
    end
    self:SetBackgroundColor(0.92, 0.92, 0.92);
end

function NarciSpeechBalloonToolbarLongButtonMixin:OnLeave()
    Tooltip:HideTooltip();
    if self.expandable then
        self.Arrow:Hide();
    end
    if not self.isActive then
        self:SetBackgroundColor(0.72, 0.72, 0.72);
    end
end
----------------------------------------------------------

local function ToggleBorderThicknessOptions(self, visible)
    if visible ~= nil then
        self.isOn = visible;
    else
        self.isOn = not self.isOn;
    end
    if not self.options then
        self.options = {};
        local widget;
        for i = 1, #STROKE_SIZE do
            widget = CreateFrame("Button", nil, self, "NarciSpeechBalloonLineThicknessButtonTemplate");
            widget:SetFrameLevel(15);
            tinsert(self.options, widget);
            if i == 1 then
                widget:SetPoint("TOP", self, "BOTTOM", 0, -8);
            else
                widget:SetPoint("TOP", self.options[i - 1], "BOTTOM", 0, 1.5);
            end
            widget:SetValue(STROKE_SIZE[i]);
        end
    end

    if self.isOn then
        self.isActive = true;
        local widget;
        local selectedValue = self.value;
        for i = 1, #self.options do
            widget = self.options[i];
            widget:Show();
            if widget.value == selectedValue then
                widget.isActive = true;
                widget:OnEnter();
            else
                widget.isActive = false;
                widget:OnLeave();
            end
        end
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    else
        self.isActive = false;
        for i = 1, #self.options do
            self.options[i]:Hide();
        end
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        self.isActive = false;
        if not self:IsMouseOver() then
            self:OnLeave();
        end
    end
end

local COLOR_PRESETS = {
    {255, 255, 255},
    {204, 204, 204},
    {166, 166, 166},
    {128, 128, 128},
    {85, 85, 85},
    {51, 51, 51},
    {13, 13, 13},

    {237, 28, 36},
    {122, 0, 38},
    {244, 154, 193},
    {255, 232, 165},
    {198, 156, 109},
    {255, 210, 0},
    {124, 197, 118},

    {0, 191, 243},
    {90, 163, 255},
    {172, 115, 238},

};

for i = 2, #COLOR_PRESETS do
    local r, g, b = unpack(COLOR_PRESETS[i]);
    COLOR_PRESETS[i] = {r/255, g/255, b/255};
end


local function ToggleColorDropDown(colorSwitch, state, modeIndex)
    if not ColorDropDown then
        ColorDropDown = CreateFrame("Frame", nil, Toolbar);
        ColorDropDown:Hide();
        ColorDropDown:SetSize(16, 16);
        ColorDropDown.buttons = {};

        --[[Area Text]]--
        --[[
        local backdrop = ColorDropDown:CreateTexture(nil, "BACKGROUND");
        backdrop:SetPoint("TOPLEFT", ColorDropDown, "TOPLEFT", 0, 0);
        backdrop:SetPoint("BOTTOMRIGHT", ColorDropDown, "BOTTOMRIGHT", 0, 0);
        backdrop:SetColorTexture(1, 0, 0, 0.5);
        --]]

        function ColorDropDown:SetMode(mode)
            if mode ~= self.mode then
                ColorDropDown.mode = mode;
                self:UpdateButtons(mode);
            end
        end

        function ColorDropDown:GetMode()
            return self.mode
        end

        function ColorDropDown:UpdateButtons(mode)
            local colors;
            if mode == 1 then
                colors = THEME_PRESETS;
            else
                colors = COLOR_PRESETS;
            end
            if colors == self.colors then
                return
            else
                self.colors = colors;
            end
            if colors then
                local col = 1;
                local row = 1;
                for i = 1, #colors do
                    if not self.buttons[i] then
                        self.buttons[i] = CreateFrame("Button", nil, self, "NarciSpeechBalloonColorButtonTemplate");
                        self.buttons[i]:SetPoint("TOPLEFT", self, "TOPLEFT", (col - 1) * 20, (1 - row) * 20);
                        self.buttons[i].id = i;
                    end
                    col = col + 1;
                    if col > 7 then
                        col = 1;
                        row = row + 1;
                    end
                    self.buttons[i]:SetColor( colors[i] );
                    self.buttons[i]:Show();
                end
                if row == 1 then
                    self:SetSize(20 * col, 20);
                else
                    self:SetSize(20 * 7, 20 * row);
                end
                for i = #colors + 1, #self.buttons do
                    self.buttons[i]:Hide();
                end
            end
        end

        function ColorDropDown:IsFocused()
            return self:IsShown() and ( self:IsMouseOver(4, -4, -4, 4) or (self.parentButton and self.parentButton:IsMouseOver() ));
        end

        ColorDropDown:SetScript("OnEvent", function(self, event)
            if not self:IsFocused() then
                self:Hide();
            end
        end);

        ColorDropDown:SetScript("OnShow", function(self)
            self:RegisterEvent("GLOBAL_MOUSE_DOWN");
        end);

        ColorDropDown:SetScript("OnHide", function(self)
            self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        end);
    end

    ColorDropDown:ClearAllPoints();
    if state == nil then
        state = not ColorDropDown:IsShown()
    end
    if state then
        ColorDropDown.parentButton = colorSwitch;
        ColorDropDown:SetPoint("TOPLEFT", colorSwitch, "BOTTOMLEFT", 0, -8);
        ColorDropDown:SetMode(modeIndex);
        ColorDropDown:Show();
    else
        ColorDropDown:Hide();
    end
end

local function ToggleThemeOptions(self, visible)
    ToggleColorDropDown(self, visible, 1);
end

local function ToggleBackgroundColorOptions(self, visible)
    ToggleColorDropDown(self, visible, 2);
end

local function ToggleBorderColorOptions(self, visible)
    ToggleColorDropDown(self, visible, 3);
end

local function ToggleFontColorOptions(self, visible)
    ToggleColorDropDown(self, visible, 4);
end

local FONT_SIZES = {
    12,
    14,
    16,
    18,
    24,
    30,
    36,
    48,
};

local ToggleFontSizeOptions;

local function FontSizeOption_OnClick(self)
    local switch = self:GetParent():GetParent();
    local value = self.value;
    switch.value = value;
    switch.Label:SetText(value.." x");
    ToggleFontSizeOptions(switch, false);
    local parentObject = Toolbar.parentObject;
    if parentObject then
        parentObject.fontHeight = value;
        parentObject:UpdateText();
    end
end

function ToggleFontSizeOptions(self, visible)
    if visible ~= nil then
        self.isOn = visible;
    else
        self.isOn = not self.isOn;
    end
    if not FontSizeDropDown then
        self.options = {};
        FontSizeDropDown = CreateFrame("Frame", nil, self);
        FontSizeDropDown:SetPoint("TOP", self, "BOTTOM", 0, -8);
        local numButtons = #FONT_SIZES;
        FontSizeDropDown:SetSize(48, 16 * numButtons);
        local widget;
        local value;
        for i = 1, numButtons do
            widget = CreateFrame("Button", nil, FontSizeDropDown, "NarciSpeechBalloonLongButtonTemplate");
            widget:SetFrameLevel(15);
            self.options[i] = widget;
            if i == 1 then
                widget:SetPoint("TOP", FontSizeDropDown, "TOP", 0, 0);
            else
                widget:SetPoint("TOP", self.options[i - 1], "BOTTOM", 0, 1.5);
            end
            widget:SetScript("OnClick", FontSizeOption_OnClick);
            value = FONT_SIZES[i];
            widget.Label:SetText(value.." x");
            widget.value = value;
        end

        function FontSizeDropDown:IsFocused()
            return FontSizeDropDown:IsShown() and FontSizeDropDown:IsMouseOver()
        end
    end

    if self.isOn then
        self.isActive = true;
        local widget;
        local selectedValue = self.value;
        for i = 1, #self.options do
            widget = self.options[i];
            if widget.value == selectedValue then
                widget.isActive = true;
                widget:SetBackgroundColor(0.92, 0.92, 0.92);
            else
                widget.isActive = false;
                widget:SetBackgroundColor(0.72, 0.72, 0.72);
            end
        end
        FontSizeDropDown:Show();
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    else
        self.isActive = false;
        FontSizeDropDown:Hide();
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        if not self:IsMouseOver() then
            self:SetBackgroundColor(0.72, 0.72, 0.72);
        end
    end
end

---------------------------------------------------------------------------------------------------------
NarciSpeechBalloonLineThicknessButtonMixin = CreateFromMixins(NarciSpeechBalloonToolbarButtonMixin);

function NarciSpeechBalloonLineThicknessButtonMixin:SetValue(pixelSize)
    local i;
    pixelSize = round(pixelSize);
    if pixelSize < 5 then
        i = pixelSize - 1;
    else
        i = 4;
    end
    self.value = pixelSize;
    self.Icon:SetTexCoord( (i - 1)*0.25, i*0.25, 0, 1);
    self.Label:SetText(pixelSize.." x");
end

function NarciSpeechBalloonLineThicknessButtonMixin:OnClick()
    local parentButton = self:GetParent();
    local parentObject = parentButton:GetParent():GetParent().parentObject;
    local thickness = self.value;

    ToggleBorderThicknessOptions(parentButton, false);
    if parentObject then
        parentObject:SetBorderThickness(thickness);
        parentButton:SetValue(self.value);
        parentButton:OnLeave();
    end
end

function NarciSpeechBalloonLineThicknessButtonMixin:OnEnter()
    self:SetBackgroundColor(0.92, 0.92, 0.92);
    Tooltip:ShowDelayedTooltip(self);
    if self.expandable then
        if not self.isOn then
            self.Arrow:Show();
            self.Arrow.flyInUp:Play();
        end
    end
end

function NarciSpeechBalloonLineThicknessButtonMixin:OnLeave()
    Tooltip:HideTooltip();
    if not self.isActive then
        self:SetBackgroundColor(0.72, 0.72, 0.72);
    end
    if self.expandable then
        self.Arrow:Hide()
    end
end


NarciSpeechBalloonToolbarColorButtonMixin = CreateFromMixins(NarciSpeechBalloonToolbarButtonMixin);

function NarciSpeechBalloonToolbarColorButtonMixin:OnLoad()
    self.Icon:SetTexture(TEXTURE_PATH_PREFIX.."TextButton-NoColor");
    self.Icon:Hide();
end

function NarciSpeechBalloonToolbarColorButtonMixin:SetColor(colors)
    if colors then
        self.Icon:Hide();
        self:SetBackgroundColor(unpack(colors));
    else
        self.Icon:Show();
    end
    self.value = colors;
end

function NarciSpeechBalloonToolbarColorButtonMixin:OnClick()
    local parentButton = ColorDropDown.parentButton;
    local parentObject = Toolbar.parentObject;

    local mode = ColorDropDown:GetMode();

    if mode == 2 then
        if parentObject then
            local colors = self.value;
            parentObject:SetBackgroundColor(unpack(colors));
            parentButton:SetBackgroundColor(unpack(colors));
        end
    elseif mode == 3 then
        if parentObject then
            local colors = self.value;
            parentObject:SetBorderColor(unpack(colors));
            parentButton:SetBackgroundColor(unpack(colors));
        end
    elseif mode == 4 then
        if parentObject then
            local colors = self.value;
            parentObject:SetFontColor(unpack(colors));
            parentButton:SetBackgroundColor(unpack(colors));
        end
    elseif mode == 1 then
        if parentObject then
            parentObject:SelectTheme(self.id);
            parentButton:SetBackgroundColor(unpack(self.value));
            local textColorButton = Toolbar.Bar2.buttons[4];
            if self.id == 1 then
                textColorButton:SetBackgroundColor(0, 0, 0);
            else
                textColorButton:SetBackgroundColor(1, 0.91, 0.647);
            end
        end
    end

    ColorDropDown:Hide();
end

NarciSpeechBalloonTextWrappingButtonMixin = {};

function NarciSpeechBalloonTextWrappingButtonMixin:OnEnter()
    Tooltip:ShowDelayedTooltip(self);
end

function NarciSpeechBalloonTextWrappingButtonMixin:OnLeave()
    Tooltip:HideTooltip();
end

function NarciSpeechBalloonTextWrappingButtonMixin:Select()
    self.isOn = true;
    self.Background:SetTexCoord(0.5, 1, 0, 0.5);
end

function NarciSpeechBalloonTextWrappingButtonMixin:Deselect()
    self.isOn = false;
    self.Background:SetTexCoord(0, 0.5, 0, 0.5);
end

function NarciSpeechBalloonTextWrappingButtonMixin:UpdateSelection(isSelected)
    if isSelected then
        self:Select();
    else
        self:Deselect();
    end
end

function NarciSpeechBalloonTextWrappingButtonMixin:SetBackgroundColor()

end

function NarciSpeechBalloonTextWrappingButtonMixin:OnClick()
    self.isOn = not self.isOn;
    local state = self.isOn;
    if state then
        self:Select();
    else
        self:Deselect();
    end
    local parentObject = self:GetParent():GetParent().parentObject;
    if parentObject then
        parentObject:SetTextWrapping(state);
    end
end


NarciTextOverlayEditButtonMixin = {};

function NarciTextOverlayEditButtonMixin:OnLoad()
    EditButton = self;
    local filter = "TRILINEAR";
    self.Texture:SetTexture(TEXTURE_PATH_PREFIX.. "EditButton", nil, nil, filter);
    self.Highlight:SetTexture(TEXTURE_PATH_PREFIX.. "EditButton", nil, nil, filter);
    self.Icon:SetTexture(TEXTURE_PATH_PREFIX.. "EditButton");
    self:SetAlpha(0);
    self:SetColor(1);
    NarciAPI_CreateFadingFrame(self);
end

function NarciTextOverlayEditButtonMixin:OnEnter()
    FadeFrame(self.Highlight, 0.15, 0.66);
    if not IsMouseButtonDown() then
        self:FadeIn(0.25);
    end
end

function NarciTextOverlayEditButtonMixin:SmartFadeOut()
    if not self:IsMouseOver() then
        if (self.parentObject) and (not self.parentObject:IsMouseOver()) then
            self:FadeOut(0.25);
        end
    end
end

function NarciTextOverlayEditButtonMixin:OnLeave()
    FadeFrame(self.Highlight, 0.2, 0);
    self:SmartFadeOut();
end

function NarciTextOverlayEditButtonMixin:OnHide()
    self.parentObject = nil;
    self:SetAlpha(0);
end

function NarciTextOverlayEditButtonMixin:OnMouseDown()
    self.animPushed:Stop();
    self.animPushed.hold:SetDuration(20);
    self.animPushed:Play();
end

function NarciTextOverlayEditButtonMixin:OnMouseUp()
    self.animPushed.hold:SetDuration(0);
end

function NarciTextOverlayEditButtonMixin:SetColor(index)
    if index == 2 then
        self.Texture:SetVertexColor(0.37, 0.74, 0.42);
    else
        --self.Texture:SetVertexColor(1, 0.91, 0.65);
        self.Texture:SetVertexColor(0.25, 0.78, 0.92);
    end
end

function NarciTextOverlayEditButtonMixin:SetParentObject(object)
    if object == self.parentObject then return end;

    self.parentObject = object;
    local r = object.cornerRadius or 0;
    local offset = (0.4142 * r + 24)/1.4142;
    self:SetPoint("CENTER", object, "BOTTOMRIGHT", -offset, offset);
end

function NarciTextOverlayEditButtonMixin:OnClick()
    self.isOn = not self.isOn;
    local Icon = self.Icon;
    Icon:StopAnimating();
    if self.isOn then
        self:SetColor(2);
        Icon:SetTexCoord(0.5, 1, 0.5, 1);
        Icon.rotateClockwise:Play();
        if self.parentObject then
            PrimaryEditBox:SetParentObject(self.parentObject);
        end
    else
        self:SetColor(1);
        Icon:SetTexCoord(0, 0.5, 0.5, 1);
        Icon.rotateCounterClockwise:Play();
        if self.parentObject then
            PrimaryEditBox:SetEnabled(false);
        end
    end
end

function NarciTextOverlayEditButtonMixin:OnDoubleClick()

end

function NarciTextOverlayEditButtonMixin:ResetState()
    self:StopAnimating();
    self.Icon:SetTexCoord(0, 0.5, 0.5, 1);
    self:SetColor(1);
    self.isOn = nil;
end


---------------------------------------------------------------------------------------
NarciSpeechBalloonEditBoxMixin = {};

function NarciSpeechBalloonEditBoxMixin:OnLoad()
    PrimaryEditBox = self;
    self:Disable();
    self:SetEnabled(false);
end

function NarciSpeechBalloonEditBoxMixin:SetParentObject(object)
    self.parentObject = object;
    self:ClearAllPoints();
    local padding = object.padding;
    self:SetParent(object);
    self:SetPoint("TOPLEFT", object, "TOPLEFT", padding, -padding);
    self:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", -padding, padding);
    self:SetText(object.rawText);
    self:SetEnabled(true);
    
    local font, height = object.ShownText:GetFont();
    self:SetFont(font, height, "");
    self:SetTextColor(object.ShownText:GetTextColor());

    object.ShownText:Hide();
    LetteringSystem:ShowText(object, false);
    object:SetNodesTransparency(0.5);
end

function NarciSpeechBalloonEditBoxMixin:OnDisable()
    self.Highlight:Hide();
    self:EnableMouse(false);
    self:HighlightText(0, 0);
    self:Hide();
    if self.parentObject then
        self.parentObject:SetNodesTransparency(1);
        self:ConfirmChanges();
    end
end

function NarciSpeechBalloonEditBoxMixin:ConfirmChanges()
    if self.parentObject then
        local text = self:GetText() or "";
        self.parentObject.rawText = text;
        self.parentObject:UpdateText();
        self.parentObject.ShownText:Show();
        LetteringSystem:ShowText(self.parentObject, true);
        self.parentObject = nil;
    end
end

function NarciSpeechBalloonEditBoxMixin:OnEnable()
    self:Show();
    self.Highlight:Show();
    self:EnableMouse(true);
    self:SetFocus();
    self:SetCursorPosition(999);
end

function NarciSpeechBalloonEditBoxMixin:OnEditFocusLost()

end

function NarciSpeechBalloonEditBoxMixin:OnEscapePressed()
    if self:IsEnabled() then
        if EditButton.parentObject == self:GetParent() then
            EditButton:Click();
        end
    end
end


---------------------------------------------------------------------------------------
NarciTextOverlayTooltipMixin = {};

function NarciTextOverlayTooltipMixin:OnLoad()
    self.backgrounds = { self.Left, self.Right, self.Middle};
    self:SetBackgroundColor();

    local timer = NarciAPI_CreateAnimationFrame(0.6);
    self.timer = timer;
    timer:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        if frame.total >= frame.duration then
            frame:Hide();
            if self.widget and self.widget == GetMouseFocus() then
                self:ShowTooltip(self.widget);
            end
        end
    end)
    timer:SetScript("OnShow", function(frame)
        frame:RegisterEvent("GLOBAL_MOUSE_DOWN");
    end);
    timer:SetScript("OnEvent", function(frame)
        frame:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        frame.total = 0;
        frame:Hide();
    end);

    self:SetAlpha(0);
    NarciAPI_CreateFadingFrame(self);
end

function NarciTextOverlayTooltipMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciTextOverlayTooltipMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:Hide();
    self:SetAlpha(0);
end

function NarciTextOverlayTooltipMixin:OnEvent(event)
    self.animFade:Hide();
    self.timer:Hide();
    self:Hide();
end

function NarciTextOverlayTooltipMixin:SetBackgroundColor(r, g, b)
    if not r then
        r, g, b = 175, 233, 254;
    end
    if r > 1 then
        r, g, b = r/255, g/255, b/255;
    end
    for i = 1, #self.backgrounds do
        self.backgrounds[i]:SetVertexColor(r, g, b);
    end
end

function NarciTextOverlayTooltipMixin:SetText(str)
    self.Description:SetText(str);
    local textWidth = self.Description:GetWidth();
    self:SetWidth(round(textWidth) + 8);
end

function NarciTextOverlayTooltipMixin:ShowTooltip(widget)
    if not widget then return end;

    if widget.tooltip then
        if widget.tooltipColor then
            self:SetBackgroundColor(unpack(widget.tooltipColor))
        else
            self:SetBackgroundColor();
        end
        self:SetText(widget.tooltip);
        self:ClearAllPoints();
        --self:SetPoint("BOTTOMLEFT", widget, "TOPLEFT", 0, 8);
        self:SetPoint("TOPLEFT", widget, "BOTTOMLEFT", 0, -8);
        self:Show();
        self:FadeIn(0.15);
    end
end

function NarciTextOverlayTooltipMixin:HideTooltip()
    self.widget = nil;
    self:Hide();
    self.timer:Hide();
end

function NarciTextOverlayTooltipMixin:ShowDelayedTooltip(widget)
    self.timer:Hide();
    if widget.tooltip then
        self.widget = widget;
        self.timer:Show();
    end
end

---------------------------------------------------------------------------------------
--Toolbar
NarciSpeechBalloonToolbarMixin = {};

function NarciSpeechBalloonToolbarMixin:OnLoad()
    local timer = NarciAPI_CreateAnimationFrame(1);

    timer:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        if frame.total >= frame.duration then
            frame:Hide();
            if not (self:IsMouseOver() or (self.parentObject and self.parentObject:IsMouseOver()) ) then
                self:FadeOut(0.5);
            end
        end
    end);
end

local function ToolbarFade_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
end

local function Toolbar_OnEvent(self, event, ...)
    if not ( self:IsMouseOver(10, -10, -10, 10) or IsWidgetFocused(self.parentObject) or IsWidgetFocused(ColorDropDown) or IsWidgetFocused(FontSizeDropDown) ) then
        HideEditor();
    end
end

function NarciSpeechBalloonToolbarMixin:FadeIn(duration)
    self:Show();
end

function NarciSpeechBalloonToolbarMixin:FadeOut(duration)
    self:Hide();
end

function NarciSpeechBalloonToolbarMixin:SetParentObject(object)
    self.parentObject = object;
    self:ClearAllPoints();
    self:SetPoint("BOTTOM", object, "TOP", 0, 8);
    self:FadeIn(0.25);

    --Load Settings
    local buttons = self.buttons;
    if object.balloonTpye == 1 then
        self:SetWidth(self.barWidth0);
        self.Bar0:Show();
        self.Bar1:Hide();
        self.Bar2:SetPoint("LEFT", self.Bar0, "RIGHT", 4, 0);
        self.Bar2:SetWidth(140);
        buttons[0]:SetBackgroundColor( unpack(object.backgroundColor) );
        buttons[1]:SetBackgroundColor( unpack(object.backgroundColor) );
        buttons[9]:Hide();
    else
        self:SetWidth(self.barWidth1);
        self.Bar0:Hide();
        self.Bar1:Show();
        self.Bar2:SetPoint("LEFT", self.Bar1, "RIGHT", 4, 0);
        self.Bar2:SetWidth(164);
        buttons[1]:SetBackgroundColor( unpack(object.backgroundColor) );
        buttons[2]:SetBackgroundColor( unpack(object.borderColor) );
        buttons[3]:SetValue( object.borderPixelSize );
        buttons[9]:UpdateSelection( object.textWrapping );
        buttons[9]:Show();
    end
    buttons[4]:UpdateSelection( object.isBold );
    buttons[5]:UpdateSelection( object.isItalic );
    buttons[6]:UpdateSelection( object.isAllCaps );
    buttons[7]:SetBackgroundColor( object.ShownText:GetTextColor() );
    local value = object.fontHeight;
    buttons[8].Label:SetText(value.." x");
    buttons[8].value = value;
end

function NarciSpeechBalloonToolbarMixin:OnShow()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    self:SetScript("OnEvent", Toolbar_OnEvent);
end

function NarciSpeechBalloonToolbarMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:SetScript("OnEvent", nil);
end

local BACKGROUND_SETTINGS = {
    [1] = {
        name = "Background Color",
        expandable = true,
        --template = "NarciSpeechBalloonColorButtonTemplate",
        func = function(self) ToggleBackgroundColorOptions(self) end,
        defaultValue = {1, 1, 1};
    },

    [2] = {
        name = "Stroke Color",
        icon = "SquareInner",
        expandable = true,
        --template = "NarciSpeechBalloonColorButtonTemplate",
        func = function(self) ToggleBorderColorOptions(self) end,
        defaultValue = {0.1, 0.1, 0.1};
    },

    [3] = {
        name = "Stroke Width",
        isLongButton = true,
        expandable = true,
        template = "NarciSpeechBalloonLineThicknessButtonTemplate",
        func = function(self) ToggleBorderThicknessOptions(self) end,
        closeFunc = function(self) ToggleBorderThicknessOptions(self, false) end,
        defaultValue = 2;
    },
};

local TEXT_SETTINGS = {
    [1] = {
        name = "Bold",
        icon = "TextIcon-Bold",
        func = function(self)
            local parentObject = self:GetParent():GetParent().parentObject;
            self.isOn = not self.isOn;
            local state = self.isOn;
            if state then
                self:Select();
            else
                self:Deselect();
            end
            if parentObject then
                parentObject:SetBold(state);
            end
        end,
        defaultValue = false;
    },

    [2] = {
        name = "Italic",
        icon = "TextIcon-Italic",
        func = function(self)
            local parentObject = self:GetParent():GetParent().parentObject;
            self.isOn = not self.isOn;
            local state = self.isOn;
            if state then
                self:Select();
            else
                self:Deselect();
            end
            if parentObject then
                parentObject:SetItalic(state);
            end
        end,
        defaultValue = false;
    },

    [3] = {
        name = "All Caps",
        icon = "TextButton-Caps",
        func = function(self)
            local parentObject = self:GetParent():GetParent().parentObject;
            self.isOn = not self.isOn;
            local state = self.isOn;
            if state then
                self:Select();
            else
                self:Deselect();
            end
            if parentObject then
                parentObject:SetAllCaps(state);
            end
        end,
        defaultValue = false;
    },

    
    [4] = {
        name = "Text Color",
        gap = 8,
        expandable = true,
        func = function(self) ToggleFontColorOptions(self) end,
        defaultValue = {0.1, 0.1, 0.1};
    },

    [5] = {
        name = "Font Size",
        isLongButton = true,
        expandable = true,
        func = function(self) ToggleFontSizeOptions(self) end,
        closeFunc = function(self) ToggleFontSizeOptions(self, false) end,
        defaultValue = 14;
    },

    [6] = {
        name = "Wrap text around the corner",
        template = "NarciSpeechBalloonTextWrappingButtonTemplate",
        gap = 8,
        defaultValue = false;
    },
};

local REMOVE_SETTINGS = {
    [1] = {
        name = "Remove",
        icon = "TextButton-Remove",
        template = "NarciSpeechBalloonRemoveButtonTemplate",
        tooltipColor = {215, 31, 38},
    },
};

local SIMPLE_BALLOON_SETTINGS = {
    [1] = {
        name = "Theme",
        expandable = true,
        func = function(self) ToggleThemeOptions(self) end,
    },
};

local function CreateSubBar(toolbarData)
    --Toolbar
    local parent = nil;
    local Bar = CreateFrame("Frame", nil, parent, "NarciSpeechBalloonToolbarTemplate");
    Bar:ClearAllPoints();
    Bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

    --Button
    local GAP = 4;
    local numButtons = #toolbarData;
    local buttonWidth = 0;
    local button;
    local buttons = {};
    local template;
    for i = 1, numButtons do
        local data = toolbarData[i];
        if data.template then
            template = data.template;
        else
            if data.isLongButton then
                template = "NarciSpeechBalloonLongButtonTemplate";
            else
                template = "NarciSpeechBalloonSquareButtonTemplate";
            end
        end
        button = CreateFrame("Button", nil, Bar, template);
        tinsert(buttons, button);
        buttonWidth = buttonWidth + round(button:GetWidth());
        local gap;
        if i == 1 then
            gap = 0;
            button:SetPoint("LEFT", Bar, "LEFT", GAP, 0);
        else
            gap = data.gap or GAP;
            button:SetPoint("LEFT", buttons[i - 1], "RIGHT", gap, 0);
            if i == numButtons then
                --gap = 0;
            end
        end
        buttonWidth = buttonWidth + gap;

        if data.icon then
            button.Icon:SetTexture(TEXTURE_PATH_PREFIX.. data.icon);
        end
        if data.isLongButton then
            button:OnLeave();
        else
            button:SetBackgroundColor(0.35, 0.35, 0.35);
        end
        if data.defaultValue ~= nil then
            button.value = data.defaultValue;
        end
        if data.func then
            button:SetScript("OnClick", data.func);
        end
        if data.closeFunc then
            button.closeFunc = data.closeFunc;
        end
        if data.expandable then
            button.expandable = true;
        end
        if data.tooltipColor then
            button.tooltipColor = data.tooltipColor;
        end
        button.tooltip = data.name;
    end
    Bar.buttons = buttons;
    Bar:SetWidth(round(buttonWidth + 2 * GAP));

    return Bar
end

local function CreateBallonToolbar()
    local GAP = 4;
    Toolbar:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    
    local Bar0 = CreateSubBar(SIMPLE_BALLOON_SETTINGS);
    local Bar1 = CreateSubBar(BACKGROUND_SETTINGS);
    local Bar2 = CreateSubBar(TEXT_SETTINGS);
    local Bar3 = CreateSubBar(REMOVE_SETTINGS);
    Toolbar.Bar0 = Bar0;
    Toolbar.Bar1 = Bar1;
    Toolbar.Bar2 = Bar2;
    Toolbar.Bar3 = Bar3;

    local barWidth0 = round(Bar0:GetWidth() + Bar2:GetWidth() + Bar3:GetWidth() + 2*GAP - 24);
    local barWidth1 = round(Bar1:GetWidth() + Bar2:GetWidth() + Bar3:GetWidth() + 2*GAP);
    Toolbar.barWidth0 = barWidth0;
    Toolbar.barWidth1 = barWidth1;

    Toolbar:SetSize(barWidth1, 24);
    Bar0:Hide();
    Bar0:ClearAllPoints();
    Bar1:ClearAllPoints();
    Bar2:ClearAllPoints();
    Bar3:ClearAllPoints();
    Bar0:SetParent(Toolbar);
    Bar1:SetParent(Toolbar);
    Bar2:SetParent(Toolbar);
    Bar3:SetParent(Toolbar);
    Bar0:SetPoint("LEFT", Toolbar, "LEFT", 0, 0);
    Bar1:SetPoint("LEFT", Toolbar, "LEFT", 0, 0);
    Bar2:SetPoint("LEFT", Bar1, "RIGHT", GAP, 0);
    Bar3:SetPoint("LEFT", Bar2, "RIGHT", GAP, 0);

    Toolbar:Hide();
    --
    local RemoveButton = Bar3.buttons[1];
    RemoveButton.HighlightTexture:SetVertexColor(0.8, 0, 0);
    RemoveButton:SetScript("OnMouseDown", function(self)
        self.Fill.Timer:Play();
    end)
    RemoveButton:SetScript("OnMouseUp", function(self)
        self.Fill.Timer:Stop();
    end)
    RemoveButton.Fill.Timer:SetScript("OnFinished", function()
        RemoveButton:Disable();
        After(0.35, function()
            RemoveButton:Enable();
        end)
        local parentObject = Toolbar.parentObject;
        Toolbar:FadeOut(0.25);
        EditButton:Hide();
        if parentObject then
            parentObject:Hide();
        end
    end)

    local FontSizeButton = Bar2.buttons[5];
    FontSizeButton.Label:SetText("14 x");

    
    local buttons = { [0] = Bar0.buttons[1] };
    for i = 1, #Bar1.buttons do
        tinsert(buttons, Bar1.buttons[i]);
    end
    for i = 1, #Bar2.buttons do
        tinsert(buttons, Bar2.buttons[i]);
    end
    Toolbar.buttons = buttons;
end

local function CreateModelDropDown()
    --
    ModelDropDownMenu = Container.ModelDropDownMenu;
    local menu = ModelDropDownMenu;


    function ModelDropDownMenu:SetParentObject(object)
        menu:ClearAllPoints();
        menu:SetPoint("TOPLEFT", object.Model, "TOPRIGHT", 2, 5);
        menu:Show();
        menu.parentObject = object;
    end

    --Buttons
    local selfButton = CreateFrame("Button", nil, menu, "NarciTalkingHeadModelDropDownButtonTemplate");
    local targetButton = CreateFrame("Button", nil, menu, "NarciTalkingHeadModelDropDownButtonTemplate");
    local buttons = {selfButton, targetButton};
    local actorButtons = {};
    local MAX_ACTORS = 8;
    local button;

    selfButton.Label:SetText(L["Self"]);
    selfButton:SetScript("OnClick", function()
        ModelDropDownMenu.parentObject:SetUnit("player");
        menu:Hide();
    end)

    targetButton:SetScript("OnClick", function()
        ModelDropDownMenu.parentObject:SetUnit("target");
        menu:Hide();
    end)

    for i = 1, MAX_ACTORS do
        button = CreateFrame("Button", nil, menu, "NarciTalkingHeadModelDropDownButtonTemplate");
        tinsert(actorButtons, button);
        tinsert(buttons, button);
        button.index = i;
        button:SetScript("OnClick", function(self)
            ModelDropDownMenu.parentObject:SetCreature(self.creatureID, self.Label:GetText());
            menu:Hide();
        end)
    end

    local numButtons = #buttons;
    for i = 1, numButtons do
        button = buttons[i];
        if i < 3 then
            button:SetPoint("TOP", menu, "TOP", 0, -16 * i);
        else
            button:SetPoint("TOP", menu, "TOP", 0, -16 * (i + 1));
        end
    end

    menu:SetHeight( 16*(numButtons + 1) );

    local function UpdateTargetName()
        if UnitExists("target") then
            local name = UnitName("target");
            local _, className = UnitClass("target");
            local r, g, b = GetClassColor(className);
            targetButton.Label:SetTextColor(r, g, b);
            SmartFontType(targetButton.Label, name);
            targetButton:Enable();
        else
            targetButton.Label:SetTextColor(1, 0.3137, 0.3137);		--Pastel Red
            targetButton.Label:SetText(ERR_GENERIC_NO_TARGET);
            targetButton:Disable();
        end
    end

    local function UpdateNPCName()
        local numModels = 0;
        local model;
        for i = 1, MAX_ACTORS do
            model = _G["NarciNPCModelFrame"..i];
            if model then
                numModels = numModels + 1;
                actorButtons[numModels].Label:SetText(model.creatureName or ("NPC #"..i));
                actorButtons[numModels].creatureID = model.creatureID;
                actorButtons[numModels]:Show();
            end
        end
        for i = numModels + 1, MAX_ACTORS do
            actorButtons[i]:Hide();
        end

        if numModels == 0 then
            menu.None:Show();
            numModels = 1;
        else
            menu.None:Hide();
        end
        menu:SetHeight(16*(numModels + 4));
    end

    menu.None:SetTextColor(1, 0.3137, 0.3137);		--Pastel Red

    menu:SetScript("OnShow", function(self)
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
        self:RegisterEvent("PLAYER_TARGET_CHANGED");
        UpdateTargetName();
        UpdateNPCName();
    end)

    menu:SetScript("OnHide", function(self)
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        self:UnregisterEvent("PLAYER_TARGET_CHANGED");
        self:Hide();
    end)

    menu:SetScript("OnEvent", function(self, event)
        if event == "GLOBAL_MOUSE_DOWN" then
            if not self:IsMouseOver() then
                self:Hide();
            end
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdateTargetName();
        end
    end)
end

local function SetUpOverlayFrame()
    local frame = Narci_TextOverlay;
    frame:SetFrameLevel(60);

    local VisibilityButton = frame.VisibilityButton;
    VisibilityButton.Icon:SetTexture(TEXTURE_PATH_PREFIX.."Icons", nil, nil, "TRILINEAR");
    VisibilityButton.Icon:SetTexCoord(0, 0.125, 0, 0.5);
    VisibilityButton.tooltipDescription = L["Visibility"];

    VisibilityButton:SetScript("OnClick", function(self)
        local visible = not Container:IsShown();
        Container:SetShown(visible);
        if visible then
            self.Icon:SetTexCoord(0.125, 0.25, 0, 0.5);
        else
            self.Icon:SetTexCoord(0, 0.125, 0, 0.5);
        end
    end)

    VisibilityButton:SetScript("OnShow", function(self)
        if Container:IsShown() then
            self.Icon:SetTexCoord(0.125, 0.25, 0, 0.5);
        else
            self.Icon:SetTexCoord(0, 0.125, 0, 0.5);
        end
    end);

    VisibilityButton:SetScript("OnHide", function(self)
        if Container:IsShown() then
            self:Click();
        end
    end)

    VisibilityButton:SetScript("OnMouseDown", function(self)
        self.Icon:SetSize(20, 20);
    end)
    VisibilityButton:SetScript("OnMouseUp", function(self)
        self.Icon:SetSize(22, 22);
    end)
    VisibilityButton:SetScript("OnEnter", function(self)
        self.Highlight:Show();
        NarciTooltip:ShowButtonTooltip(self);
    end)
    VisibilityButton:SetScript("OnLeave", function(self)
        self.Highlight:Hide();
        NarciTooltip:HideTooltip();
    end)
    --
    frame.Tooltip:SetGradientExtraWidth(10);

    --Create Type Button
    local button;
    local numButtons = 5;
    for i = numButtons, 1, -1 do
        button = CreateFrame("Button", nil, frame, "NarciNewTextOverlayButtonTemplate");
        button:SetPoint("RIGHT", frame, "RIGHT", -5 + (i - numButtons) * 24, 0);
        button:SetID(i);
        button:OnLoad();
    end
end

local function Init()
    Tooltip = Container.Tooltip;
    Toolbar = Container.Toolbar;
    SetUpOverlayFrame();
    CreateBallonToolbar();
    CreateModelDropDown();
end


NarciTextOverlayFrameMixin = {};

function NarciTextOverlayFrameMixin:OnLoad()
    Narci_ModelSettings:AddSubFrame(self, "TextOverlayMenu");
    self.Label:SetText(Narci.L["Text Overlay"]);
end

function NarciTextOverlayFrameMixin:OnShow()
    if Init then
        Init();
        Init = nil;
    end
    self:SetScript("OnShow", nil);
end

function NarciTextOverlayFrameMixin:IsFocused()
    return self:IsShown() and self:IsMouseOver();
end


----------------------------------------------------------------------------------
local positionFrame = CreateFrame("Frame");
positionFrame.screenMidPoint = WorldFrame:GetWidth()/2;
positionFrame:Hide();
positionFrame:SetScript("OnUpdate", function(self)
    local cursorX, cursorY = GetCursorPosition();
    local uiScale = self.uiScale or 1;
    cursorX, cursorY = cursorX/uiScale, cursorY/uiScale;
    local compensatedX = cursorX - self.offsetX;
    local midPoint = self.screenMidPoint/uiScale;
    if (compensatedX > midPoint - 40) and (compensatedX < midPoint + 40) then
        compensatedX = midPoint;
    end
    if self.object then
        self.object:SetPoint("CENTER", Container, "BOTTOMLEFT", compensatedX, cursorY - self.offsetY);
    else
        self:Hide();
    end
end);


----------------------------------------------------------------------------------
local function InteractableLineBorder_OnDragStart(self)
    if self:GetParent().OnDragStart then
        self:GetParent():OnDragStart();
    end
end

local function InteractableLineBorder_OnDragStop(self)
    if self:GetParent().OnDragStop then
        self:GetParent():OnDragStop();
    end
end

local function InteractableLineBorder_OnClick(self)
    Container.GenericEditBox:SetParentObject(self.parentObject);
    self:Hide();
end

local function InitializeInteractableLineBorder(frame, parentObject)
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", InteractableLineBorder_OnDragStart);
    frame:SetScript("OnDragStop", InteractableLineBorder_OnDragStop);
    frame:SetScript("OnClick", InteractableLineBorder_OnClick);
    frame.parentObject = parentObject;
    parentObject.area = frame;
end

NarciCustomTalkingHeadMixin = {};

function NarciCustomTalkingHeadMixin:OnLoad()
    self:RegisterForDrag("LeftButton");
    self:SetScale(0.8);
    self.Name:SetFixedColor(true)
    self.Text:SetFontObjectsToTry(SystemFont_Shadow_Large, SystemFont_Shadow_Med2, SystemFont_Shadow_Med1);
    self.Text:SetText("");

    local area1 = CreateFrame("Button", nil, self, "NarciInteractableAreaIndicatorTemplate");
    InitializeInteractableLineBorder(area1, self.Name);
    area1:SetPoint("TOPLEFT", self.Name, "TOPLEFT", 0, 0);
    area1:SetPoint("RIGHT", self, "TOPRIGHT", -42, 0);
    area1:SetHeight(24);

    local area2 = CreateFrame("Button", nil, self, "NarciInteractableAreaIndicatorTemplate");
    InitializeInteractableLineBorder(area2, self.Text);
    area2:SetPoint("TOPLEFT", self.Text, "TOPLEFT", 0, 0);
    area2:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -42, 12);

    local Model = self.Model;
    Model:EnableMouse(true);
    Model:SetKeepModelOnHide(true);
    Model:SetScript("OnModelLoaded", function()
        self:OnModelLoaded();
    end)

    local button = self.ModelOptionButton;
    button:RegisterForDrag("LeftButton");
    button:SetScript("OnClick", function()
        ModelDropDownMenu:SetParentObject(self);
    end)
    button:SetScript("OnDragStart", function()
        self:OnDragStart();
    end)
    button:SetScript("OnDragStop", function()
        self:OnDragStop();
    end)
    button:SetScript("OnEnter", function(frame)
        frame:SetAlpha(1);
    end)
    button:SetScript("OnLeave", function(frame)
        frame:SetAlpha(0);
    end)
end

function NarciCustomTalkingHeadMixin:OnShow()
    if not self.hasUnitSet then
        self.hasUnitSet = true;
        After(0, function()
            self:SetUnit("target");
        end)
    end
end

function NarciCustomTalkingHeadMixin:OnDragStart()
    positionFrame:Hide();
    local uiScale = self:GetScale();
    positionFrame.object = self;
    positionFrame.uiScale = uiScale;
    local cursorX, cursorY = GetCursorPosition();
    cursorX, cursorY = cursorX/uiScale, cursorY/uiScale;
    local x0, y0 = self:GetCenter();
    positionFrame.offsetX = cursorX - x0;
    positionFrame.offsetY = cursorY - y0;
    positionFrame:Show();
    self:ClearAllPoints();
end

function NarciCustomTalkingHeadMixin:OnDragStop()
    positionFrame:Hide();
end

function NarciCustomTalkingHeadMixin:SetUnit(unit)
    local Model = self.Model;
    unit = unit or "player";
    if not UnitExists(unit) then
        unit = "player";
    end
    Model:SetUnit(unit);
    self.Name:SetText(UnitName(unit));
end

function NarciCustomTalkingHeadMixin:SetCreature(creatureID, creatureName)
    if not creatureID then return end;
    self.Model:SetCreature(creatureID);
    self.Name:SetText(creatureName);
end

function NarciCustomTalkingHeadMixin:OnModelLoaded()
    SetModelLight(self.Model, true, false, -0.5124, -0.4872, -0.7071, 1, 204/255, 204/255, 204/255, 1, 0.8, 0.8, 0.8);
    self.Model:SetCamera(0);
    self.Model:SetPortraitZoom(1);
    self.Model:SetPortraitZoom(0.975);
    self.Model:SetAnimation(0, 0);
end

function NarciCustomTalkingHeadMixin:OnClick()
    --self:SetUnit();
end

----------------------------------------------
NarciTextOverlayGenericEditBoxMixin = {};

function NarciTextOverlayGenericEditBoxMixin:SetParentObject(fontString)
    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", fontString.area, "TOPLEFT", 0, 0);
    self:SetPoint("BOTTOMRIGHT", fontString.area, "BOTTOMRIGHT", 0, 0);
    local font, height = fontString:GetFont();
    self:SetFont(font, height, "");
    self:SetTextColor( fontString:GetTextColor() );
    self:Show();
    self:SetText(fontString:GetText() or "");
    self:SetFocus();
    self:SetCursorPosition(999);
    self:SetScale(fontString:GetEffectiveScale());
    if self.parentObject then
        self.parentObject:Show();
        self.parentObject.area:Show();
    end
    self.parentObject = fontString;
    fontString:Hide();
end

function NarciTextOverlayGenericEditBoxMixin:OnTextChanged()

end

function NarciTextOverlayGenericEditBoxMixin:OnEscapePressed()
    self:ClearFocus();
end

function NarciTextOverlayGenericEditBoxMixin:OnEditFocusLost()
    self:HighlightText(0, 0);
    self:Hide();
    if self.parentObject then
        self.parentObject:SetText(self:GetText() or "");
        self.parentObject:Show();
        self.parentObject.area:Show();
        self.parentObject = nil;
    end
end


----Overlay Container----
NarciTextOverlayContainerMixin = {};

function NarciTextOverlayContainerMixin:OnLoad()
    Container = self;
    self.simpleBalloons = {};
    self.advancedBalloons = {};
    self.talkingHeads = {};

    --Only one subtile
    self.SubtitleFrame.Subtitle:SetFontObjectsToTry(GameFontHighlightLarge, GameFontHighlightMedium, GameFontHighlight, GameFontHighlightSmall);
    local area1 = CreateFrame("Button", nil, self.SubtitleFrame, "NarciInteractableAreaIndicatorTemplate");
    InitializeInteractableLineBorder(area1, self.SubtitleFrame.Subtitle);
    area1:SetPoint("TOPLEFT", self.SubtitleFrame.BlackBarBottom, "TOPLEFT", 100, -8);
    area1:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -100, 8);
    self.SubtitleFrame.Subtitle:SetText("Subtitle");

    local MovieSubtitle = self.MovieSubtitleFrame.MovieSubtitle;
    MovieSubtitle:SetText("Subtitle");
    local area2 = CreateFrame("Button", nil, self.MovieSubtitleFrame, "NarciInteractableAreaIndicatorTemplate");
    InitializeInteractableLineBorder(area2, MovieSubtitle);
    area2:SetPoint("TOPLEFT", MovieSubtitle, "TOPLEFT", 0, 0);
    area2:SetPoint("BOTTOMRIGHT", MovieSubtitle, "BOTTOMRIGHT", 0, 0);
end

function NarciTextOverlayContainerMixin:ToggleBlackBar()
    if not self.SubtitleFrame:IsShown() then
		local width = CinematicFrame:GetWidth();
		local height = CinematicFrame:GetHeight();
		local viewableHeight = width * 9 / 16;
		local worldFrameHeight = WorldFrame:GetHeight();
        local halfDiff = math.max(math.floor((worldFrameHeight - viewableHeight) / 2), 0);
        
        local barHeight = max(halfDiff, 48);    --40

        self.SubtitleFrame.BlackBarTop:SetHeight(barHeight);
        self.SubtitleFrame.BlackBarBottom:SetHeight(barHeight);
        self.SubtitleFrame:Show();
        return true
    else
        --WorldFrame:SetAllPoints(nil);
        self.SubtitleFrame:Hide();
        return false
    end
end

function NarciTextOverlayContainerMixin:ToggleMovieSubtitle()
    local visible = not self.MovieSubtitleFrame:IsShown();
    self.MovieSubtitleFrame:SetShown(visible);
    return visible
end

function NarciTextOverlayContainerMixin:OnHide()

end

function NarciTextOverlayContainerMixin:CreateSimpleBalloon()
    local Balloon;
    local numBalloons = #self.simpleBalloons
    for i = 1, numBalloons do
        if not self.simpleBalloons[i]:IsShown() then
            Balloon = self.simpleBalloons[i];
            break;
        end
    end
    if not Balloon then
        Balloon = CreateFrame("Button", nil, self, "NarciSimpleSpeechBalloonTemplate");
        tinsert(self.simpleBalloons, Balloon);
    end
    Balloon:Show();
    Balloon:Click();
    return Balloon
end

function NarciTextOverlayContainerMixin:CreateAdvancedBalloon()
    local Balloon;
    local numBalloons = #self.advancedBalloons
    for i = 1, numBalloons do
        if not self.advancedBalloons[i]:IsShown() then
            Balloon = self.advancedBalloons[i];
            break;
        end
    end
    if not Balloon then
        Balloon = CreateFrame("Button", nil, self, "NarciAdjustableSpeechBalloonTemplate");
        tinsert(self.advancedBalloons, Balloon);
    end
    Balloon:Show();
    Balloon:Click();
    return Balloon
end

function NarciTextOverlayContainerMixin:HideAllControlNodes(exemption)
    local ballons;
    for i = 1, #self.simpleBalloons do
        ballons = self.simpleBalloons[i];
        if ballons ~= exemption then
            ballons:SetNodesTransparency(0);
        else
            if PrimaryEditBox:IsEnabled() then
                ballons:SetNodesTransparency(0.5);
            else
                ballons:SetNodesTransparency(1);
            end
        end
    end
    for i = 1, #self.advancedBalloons do
        ballons = self.advancedBalloons[i];
        if ballons ~= exemption then
            ballons:SetNodesTransparency(0);
        else
            if PrimaryEditBox:IsEnabled() then
                ballons:SetNodesTransparency(0.5);
            else
                ballons:SetNodesTransparency(1);
            end
        end
    end
end

function NarciTextOverlayContainerMixin:CreateTalkingHead()
    local Head;
    local numHeads = #self.talkingHeads
    for i = 1, numHeads do
        if not self.talkingHeads[i]:IsShown() then
            Head = self.talkingHeads[i];
            break;
        end
    end
    if not Head then
        Head = CreateFrame("Button", nil, self, "NarciTalkingHeadTemplate");
        tinsert(self.talkingHeads, Head);
    end
    Head:Show();
    return Head
end

function NarciTextOverlayContainerMixin:CreateOverlay(typeID)
    local visible;

    if typeID == 1 then
        self:CreateSimpleBalloon();
    elseif typeID == 2 then
        self:CreateAdvancedBalloon();
    elseif typeID == 3 then
        self:CreateTalkingHead();
    elseif typeID == 4 then
        visible = self:ToggleMovieSubtitle();
    elseif typeID == 5 then
        visible = self:ToggleBlackBar();
    end

    return visible
end

function NarciTextOverlayContainerMixin:HideAllWidgets()
    local tables = {self.simpleBalloons, self.advancedBalloons, self.talkingHeads};
    for i = 1, #tables do
        for j = 1, #tables[i] do
            tables[i][j]:Hide();
        end
    end
    self.SubtitleFrame:Hide();
end

--Click to create a text overlay--
NarciNewTextOverlayButtonMixin = {};

function NarciNewTextOverlayButtonMixin:OnLoad()
    self.Icon:SetTexture(TEXTURE_PATH_PREFIX.."Icons", nil, nil, "LINEAR");--"TRILINEAR" "LINEAR"
    local id = self:GetID();
    self.id = id;
    self.Icon:SetTexCoord((id - 1)*0.125, id * 0.125, 0.5, 1);
    self.Icon:SetAlpha(0.6);
    if id == 5 then
        self.Icon:SetPoint("CENTER", self, "CENTER", -2, 0);
    elseif id == 1 then
        self.Icon:SetPoint("CENTER", self, "CENTER", 2, 0);
    end
    self.Icon:SetSize(22, 22);

    self.tooltip = L["Text Overlay Button Tooltip"..id] or " ";
end

function NarciNewTextOverlayButtonMixin:OnEnter()
    self.Icon:SetAlpha(1);
    local Tooltip = self:GetParent().Tooltip;
    Tooltip:ClearAllPoints();
    Tooltip.Label:SetText(self.tooltip);
    Tooltip:SetWidth( Tooltip.Label:GetWidth() + 8)
    Tooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0);
    Tooltip:Show();
end

function NarciNewTextOverlayButtonMixin:OnLeave()
    self.Icon:SetAlpha(0.6);
    self:GetParent().Tooltip:Hide();
end

function NarciNewTextOverlayButtonMixin:OnMouseDown()
    self.Icon:SetSize(20, 20);
end

function NarciNewTextOverlayButtonMixin:OnMouseUp()
    self.Icon:SetSize(22, 22);
end

function NarciNewTextOverlayButtonMixin:OnClick()
    if not Container:IsShown() then
        self:GetParent().VisibilityButton:Click();
    end
    local visible = Container:CreateOverlay(self.id);
    if visible then
        self.Icon:SetVertexColor(0.33, 1, 0.8);
    else
        self.Icon:SetVertexColor(1, 1, 1);
    end
end

function NarciNewTextOverlayButtonMixin:OnDoubleClick()

end

function NarciNewTextOverlayButtonMixin:OnHide()
    self.Icon:SetVertexColor(1, 1, 1);
end

--[[
/run NarciAdjustableSpeechBalloonTemplate:SetTail();
/run LetteringSystem:SetText(NarciAdjustableSpeechBalloonTemplate);
/run NarciTextOverlayContainer:CreateAdvancedBalloon();
/run NarciTextOverlayContainer:CreateTalkingHead();
/run NarciTextOverlayContainer.TalkingHead:SetUnit();
--]]