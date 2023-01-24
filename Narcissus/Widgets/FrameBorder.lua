local PIECE_SIZE = 16;

local nineSlices = {
	"TopLeftCorner", "TopEdge", "TopRightCorner",
    "LeftEdge", "Center", "RightEdge",
	"BottomLeftCorner", "BottomEdge", "BottomRightCorner",
};

local BACKDROP_FILLET_R8 = {
    edgeFile = "Interface\\AddOns\\Narcissus\\Art\\Frames\\WhiteBorderR8",
    tile = true,
    tileEdge = true,
    tileSize = PIECE_SIZE,
    edgeSize = PIECE_SIZE,
};

local BACKDROP_FILLET_R4 = {
    edgeFile = "Interface\\AddOns\\Narcissus\\Art\\Frames\\WhiteBorderR4",
    tile = true,
    tileEdge = true,
    tileSize = PIECE_SIZE,
    edgeSize = PIECE_SIZE,
};

local BACKDROP_FILLET_R4_GLOW = {
    green = {
        edgeFile = "Interface\\AddOns\\Narcissus\\Art\\Frames\\WhiteBorderR4-Glow-Green",
        tile = true,
        tileEdge = true,
        tileSize = PIECE_SIZE,
        edgeSize = PIECE_SIZE,
    }
};

local function SetBorderBlendMode(frame, mode)
    local region;
    for i, pieceName in pairs(nineSlices) do
        region = frame[pieceName];
        if region then
            region:SetBlendMode(mode);
        end
    end
end


NarciFrameBorderMixin = CreateFromMixins(BackdropTemplateMixin);

function NarciFrameBorderMixin:OnLoad()
    local backdropInfo;

    if self.cornerRadius then
        if self.cornerRadius == 4 then
            backdropInfo = BACKDROP_FILLET_R4;
        else
            backdropInfo = BACKDROP_FILLET_R8;
        end
    else
        backdropInfo = BACKDROP_FILLET_R4;
    end

    if self.isSubFrame then
        self.Background:Hide();
        self.CloseButton:Hide();
    end

    self:SetBackdrop(backdropInfo);
    self:SetBorderBrightness(0.25);

    self.BorderGlow:SetBackdrop(BACKDROP_FILLET_R4_GLOW);
    self:SetGlowColor("green");
end

function NarciFrameBorderMixin:SetBorderColor(r, g, b)
    self:SetBackdropBorderColor(r, g, b, 1);
    self.borderColor = {r, g, b};
end

function NarciFrameBorderMixin:SetGlowColor(colorName)
    if BACKDROP_FILLET_R4_GLOW[colorName] then
        self.BorderGlow:SetBackdrop(BACKDROP_FILLET_R4_GLOW[colorName]);
        SetBorderBlendMode(self.BorderGlow, "ADD");
    end
end

function NarciFrameBorderMixin:Glow()
    self.BorderGlow:Show();
    self.BorderGlow.Glow:Stop();
    self.BorderGlow.Glow:Play();
end

function NarciFrameBorderMixin:SetBorderBrightness(v)
    self:SetBorderColor(v, v, v);
end

function NarciFrameBorderMixin:LockHighlight(state)
    self.isHighlightLocked = state;

    if state then
        self:SetBackdropBorderColor(0.8, 0.8, 0.8, 1);
    else
        self:SetBorderColor(unpack(self.borderColor));
    end
end

function NarciFrameBorderMixin:IsHighlightLocked()
    return self.isHighlightLocked;
end

function NarciFrameBorderMixin:OnEnter()
    if not self:IsHighlightLocked() then
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1);
    end
    if self.onMouseMotion then
        self.onMouseMotion(self, true);
    end
end

function NarciFrameBorderMixin:OnLeave()
    if not self:IsHighlightLocked() then
        self:SetBorderColor(unpack(self.borderColor));
    end
    if self.onMouseMotion then
        self.onMouseMotion(self, false);
    end
end


NarciFrameCloseButtonMixin = {};

function NarciFrameCloseButtonMixin:ResetColor()
    self.Cross:SetVertexColor(0.25, 0.25, 0.25);
end

function NarciFrameCloseButtonMixin:OnEnter()
    self.Cross:SetVertexColor(0.93, 0.11, 0.14);
end

function NarciFrameCloseButtonMixin:OnLeave()
    self:ResetColor();
end

function NarciFrameCloseButtonMixin:OnLoad()
    self:ResetColor();

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciFrameCloseButtonMixin:OnHide()
    self:ResetColor();
end

function NarciFrameCloseButtonMixin:OnClick()
    local parentName = self:GetParent();
    if parentName.Close then
        parentName:Close();
    else
        parentName:Hide();
    end
end




NarciChamferedFrameMixin = {};

function NarciChamferedFrameMixin:CreateBackground()
    if not self.BorderFrame then
        self.BorderFrame = CreateFrame("Frame", nil, self);
        self.BorderFrame:SetAllPoints(true);
        NarciAPI.NineSliceUtil.SetUpBorder(self.BorderFrame, "genericChamferedBorder", nil, 0.25, 0.25, 0.25, 1, 7);
    end

    if not self.BackgroundFrame then
        self.BackgroundFrame = CreateFrame("Frame", nil, self);
        self.BackgroundFrame:SetAllPoints(true);
        self.BackgroundFrame:SetFrameLevel(self:GetFrameLevel());
        NarciAPI.NineSliceUtil.SetUpBackdrop(self.BackgroundFrame, "genericChamferedBackground", nil, 0, 0, 0, 1, -8);
    end
end

function NarciChamferedFrameMixin:SetBackgroundColor(r, g, b, a)
    if not self.BackgroundFrame then
        self:CreateBackground();
    end
    NarciAPI.NineSliceUtil.SetBackdropColor(self.BackgroundFrame, r, g, b, a);
end

function NarciChamferedFrameMixin:SetBorderColor(r, g, b, a)
    if not self.BorderFrame then
        self:CreateBackground();
    end
    NarciAPI.NineSliceUtil.SetBorderColor(self.BorderFrame, r, g, b, a);
end

function NarciChamferedFrameMixin:SetBorderOffset(value)
    --positive value expand the frame background
    self:CreateBackground();
    NarciAPI.NineSliceUtil.SetUpBorder(self.BorderFrame, "genericChamferedBorder", -value);
    NarciAPI.NineSliceUtil.SetUpBackdrop(self.BackgroundFrame, "genericChamferedBackground", -value);
end

function NarciChamferedFrameMixin:Toggle()
    self:SetShown(not self:IsShown());
end

function NarciChamferedFrameMixin:HideWhenParentIsHidden(state)
    if state then
        self:SetScript("OnHide", function()
            self:Hide()
        end);
    else
        self:SetScript("OnHide", nil);
    end
end