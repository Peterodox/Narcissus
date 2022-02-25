local MIN_SIZE = 48;

local sin = math.sin;
local pi = math.pi;
local sqrt = math.sqrt;

local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end


local function AnimateSize_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local w, h;
    if self.t > self.duration then
        w, h = self.toW, self.toH;
        self.t = nil;
        self.fromW = nil;
        self.toW = nil;
        self.fromH = nil;
        self.toH = nil;
        self.t = nil;
        self:Hide();
    else
        w = outSine(self.t, self.fromW, self.toW, self.duration);
        h = outSine(self.t, self.fromH, self.toH, self.duration);
    end
    self.parentFrame:SetFrameSize(w, h);
end

local function CalculateDurationByDistance(w1, h1, w2, h2)
    local d = sqrt( (w1 - w2)^2 + (h1 - h2)^2 )/200
    if d > 0.4 then
        d = 0.4;
    end
    return d
end


NarciAnimatedSizingFrameMixin = {};

function NarciAnimatedSizingFrameMixin:OnLoad()

end

function NarciAnimatedSizingFrameMixin:SetFrameSize(width, height)
    if width < 32 then
        self.Top:Hide();
        self.Bottom:Hide();
        width = 32;
    else
        self.Top:SetWidth(width - 32);
        self.Bottom:SetWidth(width - 32);
        self.Top:Show();
        self.Bottom:Show();
    end
    if height < 32 then
        self.Left:Hide();
        self.Right:Hide();
        height = 32;
    else
        self.Left:SetHeight(height - 32);
        self.Right:SetHeight(height - 32);
        self.Left:Show();
        self.Right:Show();
    end
    self:SetSize(width, height);
end

function NarciAnimatedSizingFrameMixin:AnimateSize(width, height, fixedDuration)
    local d = self.Driver;
    if not d then
        d = CreateFrame("Frame", nil, self);
        d.parentFrame = self;
        self.Driver = d;
        d:Hide();
        d:SetScript("OnUpdate", AnimateSize_OnUpdate);
    end

    if self.maxHeight then
        if height > self.maxHeight then
            height = self.maxHeight;
        end
    end
    if self.maxWidth then
        if width > self.maxWidth then
            width = self.maxWidth;
        end
    end

    d.fromW, d.fromH = self:GetSize();
    d.toW, d.toH = width, height;
    d.t = 0;

    local isInstant = (fixedDuration and fixedDuration <= 0) or (not self:IsVisible());
    if isInstant then
        d:Hide();
        self:SetFrameSize(width, height);
    else
        d.duration = fixedDuration or CalculateDurationByDistance(d.fromW, d.fromH, width, height);
        d:Show();
    end
end

function NarciAnimatedSizingFrameMixin:SetBorderColor(r, g, b, alpha)
    for _, tex in pairs(self.BorderTextures) do
        tex:SetVertexColor(r, g, b, alpha or 1);
    end
end

function NarciAnimatedSizingFrameMixin:SetBackdropColor(r, g, b, alpha)
    self.Backdrop:SetColorTexture(r, g, b, alpha or 1);
end