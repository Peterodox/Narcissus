local BLIP_CYCLE = 1;   --2 seconds

local PATH_PREFIX = "Interface\\AddOns\\Narcissus\\Art\\IconHighlight\\";

local tex2x = {"OuterGlow", "Trail1", "Trail2", "Trail3", "Trail4"};
local tex1x = {"InnerGlow", "WhiteBorder", "TrailMask1", "TrailMask2", "TrailMask3", "TrailMask4"};
local tex05x = {"Blip1", "Blip2", "Blip3", "Blip4"};

NarciActivationAlertMixin = {};

function NarciActivationAlertMixin:UpdateSize()
    local parentButton = self:GetParent();
    if parentButton then
        local a = math.floor(parentButton:GetWidth() + 0.5);
        for _, childKey in pairs(tex2x) do
            self[childKey]:SetSize(2 * a, 2 * a);
        end
        for _, childKey in pairs(tex1x) do
            self[childKey]:SetSize(a, a);
        end
        for _, childKey in pairs(tex05x) do
            self[childKey]:SetSize(0.5 * a, 0.5 * a);
        end
    end
end

function NarciActivationAlertMixin:OnLoad()
    self.InnerGlow:SetTexture(PATH_PREFIX.."InnerGlow");
    self.OuterGlow:SetTexture(PATH_PREFIX.."OuterGlow");
    self.WhiteBorder:SetTexture(PATH_PREFIX.."WhiteBorder");
    for i = 1, 4 do
        self["Blip"..i]:SetTexture(PATH_PREFIX.."Blip");
        self["Trail"..i]:SetTexture(PATH_PREFIX.."Trail");
        self["TrailMask"..i]:SetTexture(PATH_PREFIX.."TrailMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    end
    self:UpdateSize();
end

function NarciActivationAlertMixin:OnUpdate(elapsed)
    --Update Blip Position
    self.t = self.t + elapsed;
    local cycle;
    if self.laps < 4 then
        cycle = ((4 - self.laps)/ 4) * 0.25 + (self.laps / 4) * BLIP_CYCLE;
    else
        cycle = BLIP_CYCLE;
    end
    if self.t > cycle then
        self.t = self.t - cycle;
        self.laps = self.laps + 1;
    end
    local w = self.blipRadius;
    local offset = 2 * w * self.t / cycle;

    self.Blip1:SetPoint("CENTER", self, "CENTER", -w + offset, w);
    self.Blip2:SetPoint("CENTER", self, "CENTER", w, w - offset );
    self.Blip3:SetPoint("CENTER", self, "CENTER", w - offset, -w);
    self.Blip4:SetPoint("CENTER", self, "CENTER", -w, -w + offset);
    self.TrailMask1:SetPoint("CENTER", self, "CENTER", -w + offset, w);
    self.TrailMask2:SetPoint("CENTER", self, "CENTER", w, w - offset );
    self.TrailMask3:SetPoint("CENTER", self, "CENTER", w - offset, -w);
    self.TrailMask4:SetPoint("CENTER", self, "CENTER", -w, -w + offset);

    --End Animation
    self.d = self.d + elapsed;
    if self.d >= self.duration and not self.isPlayingOutro then
        self.isPlayingOutro = true;
        self:PlayOutro();
    end
end

function NarciActivationAlertMixin:PlayIntro(duration)
    if not duration then
        return
    end
    self.duration = duration;
    self:StopAnimating();
    self.IntroAnim:Play();
    
    --Reset Blip Position
    self.t = 0;
    self.d = 0;
    self.laps = 0;
    self.isPlayingOutro = false;
    local w = self:GetWidth()/2 - 0.5;
    self.blipRadius = w;
    self.Blip1:SetPoint("CENTER", self, "CENTER", -w, w);
    self.Blip2:SetPoint("CENTER", self, "CENTER", w, w);
    self.Blip3:SetPoint("CENTER", self, "CENTER", w, -w);
    self.Blip4:SetPoint("CENTER", self, "CENTER", -w, -w);
    self.TrailMask1:SetPoint("CENTER", self, "CENTER", -w, w);
    self.TrailMask2:SetPoint("CENTER", self, "CENTER", w, w);
    self.TrailMask3:SetPoint("CENTER", self, "CENTER", w, -w);
    self.TrailMask4:SetPoint("CENTER", self, "CENTER", -w, -w);
    self:Show();
end

function NarciActivationAlertMixin:PlayHold()
    self:StopAnimating();
    self.HoldAnim:Play();
end


function NarciActivationAlertMixin:PlayOutro()
    self:StopAnimating();
    self.OutroAnim:Play();
end

function NarciActivationAlertMixin:Release()
    self:Hide();
end