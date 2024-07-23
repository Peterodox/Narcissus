local _, addon = ...

local IsSpecializationActivateSpell = IsSpecializationActivateSpell;

local function IsTalentChangingSpell(spellID)
    return spellID and IsSpecializationActivateSpell(spellID) or (spellID == 384255);   --COMMIT_COMBAT_TRAIT_CONFIG_CHANGES_SPELL_ID
end

local PIXEL;
local FONT_PIXEL_HEIGHT = 16;
local BAR_PIXEL_HEIGHT_SMALL = 28;
local BAR_PIXEL_WDITH_SMALL = 192;

local LoadingBar;

local TalentTreeLoadingBarUtil = {};
addon.TalentTreeLoadingBarUtil = TalentTreeLoadingBarUtil;


function TalentTreeLoadingBarUtil:Init()
    if not LoadingBar then
        LoadingBar = CreateFrame("Frame", nil, NarciMiniTalentTree, "NarciTalentTreeLoadingBarTemplate");
        local pixel = NarciAPI.GetPixelForWidget(NarciMiniTalentTree);
        LoadingBar:UpdatePixel(pixel);
    end
end

function TalentTreeLoadingBarUtil:SetFromSpecButton(specButton)
    self:Init();

    LoadingBar:SetParentObject(specButton, "spec");
    LoadingBar.ClipFrame.Name:SetText(specButton.Name:GetText());
    LoadingBar:OnInitiateCasting();
end

function TalentTreeLoadingBarUtil:SetFromLoadoutToggle(toggle)
    self:Init();

    LoadingBar:SetParentObject(toggle, "loadout");
    LoadingBar.ClipFrame.Name:SetText("Activating");
    LoadingBar:OnInitiateCasting();
end

function TalentTreeLoadingBarUtil:IsBarVisible()
    return LoadingBar and LoadingBar:IsShown()
end

function TalentTreeLoadingBarUtil:HideBar()
    if LoadingBar and not LoadingBar.isHidding then
        LoadingBar:Hide();
    end
end


NarciTalentTreeLoadingBarMixin = {};

function NarciTalentTreeLoadingBarMixin:UpdatePixel(px)
    PIXEL = px;

    local font = self.ClipFrame.Name:GetFont();
    self.ClipFrame.Name:SetFont(font, FONT_PIXEL_HEIGHT * px, "");

    self.ClipFrame.BlackLine:SetWidth(2*px);
    self.ClipFrame.BlackLine:SetPoint("TOPRIGHT", self.ClipFrame, "TOPRIGHT", -2*px, 0);
    self.ClipFrame.BlackLine:SetPoint("BOTTOMRIGHT", self.ClipFrame, "BOTTOMRIGHT", -2*px, 0);
    self.FinishingLine:SetWidth(2*px);
end

function NarciTalentTreeLoadingBarMixin:SetParentObject(anchorTo, mode)
    if mode == "spec" then
        self:ClearAllPoints();
        self:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", 0, 0);
        self:SetPoint("BOTTOMRIGHT", anchorTo, "BOTTOMRIGHT", 0, 0);
        if mode ~= self.mode then
            self.mode = mode;
            self:SetFullWidth( anchorTo:GetWidth(), anchorTo:GetHeight() );
            self.FinishingLine:Hide();
            self.ClipFrame.Name:ClearAllPoints();
            self.ClipFrame.Name:SetPoint("LEFT", self, "LEFT", 10, 0);
            self.ClipFrame.Name:SetJustifyH("LEFT");
        end
    elseif mode == "loadout" then
        self:ClearAllPoints();
        self:SetPoint("CENTER", anchorTo, "CENTER", 0, 0);
        if mode ~= self.mode then
            self.mode = mode;
            self:SetFullWidth(BAR_PIXEL_WDITH_SMALL, BAR_PIXEL_HEIGHT_SMALL, true);
            self.FinishingLine:Show();
            self.ClipFrame.Name:ClearAllPoints();
            self.ClipFrame.Name:SetPoint("CENTER", self, "CENTER", 0, 0);
            self.ClipFrame.Name:SetJustifyH("CENTER");
        end
    end
    self:SetFrameLevel(anchorTo:GetFrameLevel() + 10);
end

function NarciTalentTreeLoadingBarMixin:SetFullWidth(width, height, isPixelSize)
    local barWidth, barHeight;
    local pixelW, pixelH;

    if isPixelSize then
        barWidth = width * PIXEL;
        barHeight = height * PIXEL;
        pixelW = width;
        pixelH = height;
    else
        barWidth = width;
        barHeight = height;
        pixelW = width / PIXEL;
        pixelH = height / PIXEL;
    end

    self:SetSize(barWidth, barHeight);

    self.barPixelWidth = pixelW;
    self.translationRange = pixelW - 256;
    if self.translationRange < 0 then
        self.translationRange = 0;
    end

    self.fullWidth = barWidth;
    self.coordTop = (1 - (pixelH / 64))/2;
    self.ClipFrame.Background:SetTexCoord((256 - pixelW)/256, 1, self.coordTop, 1-self.coordTop);
end

function NarciTalentTreeLoadingBarMixin:ListenEvents(state)
    if state then
        self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player");
        self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player");
        self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player");
    else
        self:UnregisterEvent("UNIT_SPELLCAST_START");
        self:UnregisterEvent("UNIT_SPELLCAST_FAILED");
        self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
    end
end

function NarciTalentTreeLoadingBarMixin:OnHide()
    self:ListenEvents(false);
    self:Hide();
    self:SetScript("OnUpdate", nil);
    self.isHidding = nil;
end

local function SetBarTexCoord(texture, progress, translationRange, barPixelWidth, coordTop)
    texture:SetTexCoord(translationRange*(1-progress)/256, (256*(1-progress) + progress * barPixelWidth)/256, coordTop, 1-coordTop);
end

local function LoadingBar_OnHold_OnUpdate(self, elapsed)
    --prevent frame from being shown indefinitely when something unexpected happens (connection issue, failed to use loadout, etc.)
    self.t = self.t + elapsed;
    if self.t > 1 then
        self:SetScript("OnUpdate", nil);
        NarciMiniTalentTree:OnSwitchLoadoutFailed();
    end
end

local function LoadingBar_Loading_Update(self, elapsed)
    self.t = self.t + elapsed;
    self.p = self.t / self.d;
    if self.p > 1 then
        self.p = 1;
        self:SetScript("OnUpdate", nil);
    end
    self.ClipFrame:SetWidth( self.p * self.fullWidth );
    SetBarTexCoord(self.ClipFrame.Background, self.p, self.translationRange, self.barPixelWidth, self.coordTop);
end

local function LoadingBar_Interrupted_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;

    self.p = self.p + elapsed*8;
    if self.p > 1 then
        self.p = 1;
    end
    self.ClipFrame:SetWidth( self.p * self.fullWidth );
    SetBarTexCoord(self.ClipFrame.Background, 1, self.translationRange, self.barPixelWidth, self.coordTop);

    if self.t > 0 then
        local a = 1 - 5*self.t;
        if a < 0 then
            self:SetScript("OnUpdate", nil);
            self:Hide();
        else
            self:SetAlpha(a);
        end
    end
end

function NarciTalentTreeLoadingBarMixin:OnInitiateCasting()
    self:ListenEvents(true);
    self:SetAlpha(0);
    self:Show();
    self.t = 0;
    self.isHidding = nil;
    self:SetScript("OnUpdate", LoadingBar_OnHold_OnUpdate);
    self.ClipFrame.Background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\ProgressBarBackground");
end

function NarciTalentTreeLoadingBarMixin:OnInterrupted(customError)
    self.ClipFrame.Background:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\ProgressBarBackgroundRed");
    SetBarTexCoord(self.ClipFrame.Background, 1, 0, self.barPixelWidth, self.coordTop);
    self.ClipFrame:SetWidth(self.fullWidth);
    self.ClipFrame.Name:SetText(customError or INTERRUPTED);
    self.t = -0.5;
    if (not self.p) or self.p == 0 then
        self:SetScript("OnUpdate", nil);
        self:Hide();
    else
        self:SetScript("OnUpdate", LoadingBar_Interrupted_OnUpdate);
        self.isHidding = true;
    end
end


function NarciTalentTreeLoadingBarMixin:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_START" then
        local spellID = select(3, ...);
        if IsTalentChangingSpell(spellID) then
            self:UnregisterEvent(event);
            local _, _, _, startTime, endTime = UnitCastingInfo("player");
            local duration = (endTime - startTime)/1000;
            if duration ~= 0 then
                self.t = 0;
                self.d = duration;
                self:SetAlpha(1);
                self:SetScript("OnUpdate", LoadingBar_Loading_Update);
            end
        end

    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        local cancelledSpellID = select(3, ...);
        if IsTalentChangingSpell(cancelledSpellID) then
            self:OnInterrupted();
        end
    end
end