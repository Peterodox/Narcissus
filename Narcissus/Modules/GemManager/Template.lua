local _, addon = ...
local Gemma = addon.Gemma;
local AtlasUtil = Gemma.AtlasUtil;
local FadeFrame = NarciFadeUI.Fade;

local CreateFrame = CreateFrame;
local Mixin = Mixin;


do  --Progress Spinner
    local PATH = "Interface/AddOns/Narcissus/Art/Modules/GemManager/";

    local function CreateProgressSpinner(parent)
        local f = CreateFrame("Frame", nil, parent, "NarciGemManagerLoadingSpinnerTemplate");
        f:Hide();
        AtlasUtil:SetAtlas(f.Circle, "gemma-spinner-circle");
        AtlasUtil:SetAtlas(f.Dial, "gemma-spinner-dial");
        f.DialMask:SetTexture(PATH.."Mask-Radial", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
        f.AnimSpin:Play();
        return f
    end
    Gemma.CreateProgressSpinner = CreateProgressSpinner;
end


do  --Progress Bar (Cast Bar)
    local ProgressBarMixin = {};

    function ProgressBarMixin:OnLoad()
        self:SetSize(200, 18);

        self.Title:SetTextColor(0.88, 0.88, 0.88);

        local Fill = self.Fill;
        Fill:ClearAllPoints();
        Fill:SetPoint("LEFT", self, "LEFT", 6, 0);

        local fillAtlas = "gemma-progressbar-fill";

        AtlasUtil:SetAtlas(self.Border, "gemma-progressbar-border");
        AtlasUtil:SetAtlas(Fill, fillAtlas);
        AtlasUtil:SetAtlas(self.Background, "gemma-progressbar-bg");

        local left, right, top, bottom = AtlasUtil:GetTexCoord(fillAtlas);
        self.left = left;
        self.top = top;
        self.bottom = bottom;
        self.fillTexRange = right - left;
        self.fillFullWidth = 188;

        self:SetScript("OnEvent", self.OnEvent);
        self:SetScript("OnHide", self.OnHide);
    end

    function ProgressBarMixin:SetCastText(text)
        self.Title:SetText(text);
    end

    function ProgressBarMixin:SetProgress(progress)
        if progress <= 0 then
            progress = 0;
            self.Fill:Hide();
            return
        else
            self.Fill:Show();
            if progress > 1 then
                progress = 1;
            end
        end

        self.Fill:SetWidth(self.fillFullWidth * progress);
        self.Fill:SetTexCoord(self.left, self.left + self.fillTexRange * progress, self.top, self.bottom);
    end

    function ProgressBarMixin:ListenSpellCastEvent(state)
        if state then
            --UNIT_SPELLCAST_START is controlled by MainFrame
            self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
            self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player");
            self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player");
            self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player");
        else
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
            self:UnregisterEvent("UNIT_SPELLCAST_FAILED");
            self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
            self:UnregisterEvent("UNIT_SPELLCAST_STOP");
        end
    end

    function ProgressBarMixin:OnHide()
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        self:ListenSpellCastEvent(false);
        if self.Spinner then
            self.Spinner:Hide();
        end
    end

    function ProgressBarMixin:OnEvent(event, ...)
        --FAILED, INTERRUPTED fire after STOP
        --print(GetTime(), event);    --debug

        if event == "UNIT_SPELLCAST_FAILED" then
            self:ListenSpellCastEvent(false);
            self:DispalyErrorMessage(FAILED);
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            self:ListenSpellCastEvent(false);
            self:DispalyErrorMessage(SPELL_FAILED_INTERRUPTED);
        end
    end

    function ProgressBarMixin:DispalyErrorMessage(error)
        self:SetCastText(error);
        self:SetScript("OnUpdate", nil);
        self:PlayOutro(1);
        AtlasUtil:SetAtlas(self.Fill, "gemma-progressbar-fillred");
    end

    local function Fill_OnUpdate(self, elapsed)
        self.t = self.t + elapsed;
        if self.t >= self.duration then
            self.t = 0;
            self:SetScript("OnUpdate", nil);
            self:OnSucceeded();
        else
            self:SetProgress(self.t / self.duration);
        end
    end

    function ProgressBarMixin:OnSucceeded()
        self:SetProgress(1);
        self:SetScript("OnUpdate", nil);
        self:PlayOutro();
    end

    function ProgressBarMixin:SetDuration(duration)
        self.t = 0;
        self.duration = duration;
        self:SetProgress(0);
        self:SetScript("OnUpdate", Fill_OnUpdate);
    end

    function ProgressBarMixin:UpdateSpellCast()
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo("player");
        if name then
            self:SetCastText(text);
            self:PlayIntro();
            self:Show();
            self:ListenSpellCastEvent(true);
            self:SetDuration((endTimeMS - startTimeMS)/1000);
        else
            self:Hide();
        end
    end

    function ProgressBarMixin:UpdateSpellCooldown(spellID)
        local start, duration, enabled, modRate = GetSpellCooldown(spellID);
        if enabled == 1 and start > 0 and duration > 0 then
            local cdLeft = start + duration - GetTime();
            self:SetCastText("");
            self:PlayIntro();
            self:Show();
            self:ListenSpellCastEvent(true);
            self:SetDuration(cdLeft);
        else
            self:Hide();
        end
    end

    function ProgressBarMixin:PlayIntro()
        self:StopAnimating();
        self.AnimIn:Play();

        if self.Spinner then
            FadeFrame(self.Spinner, 0.5, 1, 0);
        end
    end

    function ProgressBarMixin:PlayOutro(delay)
        delay = delay or 0;
        self:StopAnimating();
        self.AnimOut.Fade:SetStartDelay(delay);
        self.AnimOut:Play();

        if self.Spinner then
            FadeFrame(self.Spinner, 0.5, 0);
        end
    end

    local function CreateProgressBar(parent)
        local f = CreateFrame("Frame", nil, parent, "NarciGemManagerProgressBarTemplate");
        f:Hide();
        Mixin(f, ProgressBarMixin);
        f:OnLoad();
        return f
    end
    Gemma.CreateProgressBar = CreateProgressBar;
end


do  --Frame General
    local SharedWindowMixin = {};

    function SharedWindowMixin:OnLoad()
        AtlasUtil:SetAtlas(self.Background, "remix-ui-bg");
        AtlasUtil:SetAtlas(self.HeaderDivider, "remix-ui-divider");
        AtlasUtil:SetAtlas(self.FooterDivider, "remix-ui-divider");
    end

    function SharedWindowMixin:SetTitle(title)
        self.Title:SetText(title);
    end

    function SharedWindowMixin:ShowFooterDivider(state)
        self.FooterDivider:SetShown(state);
    end

    local function CreateWindow(parent)
        local f = CreateFrame("Frame", nil, parent, "NarciGemManagerWindowTemplate");
        Mixin(f, SharedWindowMixin);
        f:OnLoad();
        return f
    end
    Gemma.CreateWindow = CreateWindow;
end




do
    local Mixin_IconButton = {};

    function Mixin_IconButton:OnEnter()
        self.Icon:SetVertexColor(1, 1, 1);

        if self.tooltipText then
            if not self.Tooltip then
                self.Tooltip = Gemma.CreateSimpleTooltip(self);
            end
            self.Tooltip:ShowTooltip(self, self.tooltipText);
        end
    end

    function Mixin_IconButton:OnLeave()
        self.Icon:SetVertexColor(0.5, 0.5, 0.5);

        if self.Tooltip then
            self.Tooltip:FadeOut();
        end
    end

    function Mixin_IconButton:OnDisable()
        self.Icon:SetVertexColor(0.1, 0.1, 0.1);
    end

    function Mixin_IconButton:OnEnable()
        if self:IsMouseOver() then
            self:OnEnter();
        else
            self:OnLeave();
        end
    end

    local function CreateIconButton(parent)
        local button = CreateFrame("Button", nil, parent);
        button.Icon = button:CreateTexture(nil, "OVERLAY");
        button.Icon:SetSize(16, 16);
        button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0);

        Mixin(button, Mixin_IconButton);
        button:SetScript("OnEnter", button.OnEnter);
        button:SetScript("OnLeave", button.OnLeave);
        button:SetScript("OnDisable", button.OnDisable);
        button:SetScript("OnEnable", button.OnEnable);

        button:OnLeave();

        return button
    end
    Gemma.CreateIconButton = CreateIconButton;
end



do  --Simple Tooltip (Shared)
    local Tooltip;
    local TEXT_PADDING = 16;    --Sum of both sides

    local SimpleTooltipMixin = {};

    local function SimpleTooltip_FadeIn(self, elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0 then
            self.alpha = self.alpha + 8 * elapsed;
            if self.alpha >= 1 then
                self.alpha = 1;
                self:SetScript("OnUpdate", nil);
            end
            self:SetAlpha(self.alpha);
        end
    end

    local function SimpleTooltip_FadeOut(self, elapsed)
        self.alpha = self.alpha - 4 * elapsed;
        if self.alpha <= 0 then
            self.alpha = 0;
            self:SetScript("OnUpdate", nil);
            self:Hide();
        end
        self:SetAlpha(self.alpha);
    end

    function SimpleTooltipMixin:OnShow()
        self:RegisterEvent("GLOBAL_MOUSE_DOWN");
    end

    function SimpleTooltipMixin:OnHide()
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
        self:SetScript("OnUpdate", nil);
        self.alpha = 0;
        self.t = nil;
        self:SetAlpha(0);
    end

    function SimpleTooltipMixin:OnEvent(event)
        self:UnregisterEvent(event);
        self:FadeOut();
    end

    function SimpleTooltipMixin:FadeIn()
        if self.t then
            self.t = 0;
        else
            self.t = -0.25;  --show after delay
            self.alpha = 0;
            self:SetAlpha(0);
        end
        self:Show();
        self:SetScript("OnUpdate", SimpleTooltip_FadeIn);
    end

    function SimpleTooltipMixin:FadeOut()
        self:SetScript("OnUpdate", SimpleTooltip_FadeOut);
    end

    function SimpleTooltipMixin:ShowTooltip(owner, text)
        if not (owner and text) then
            self:Hide();
            return
        end

        self:ClearAllPoints();
        self:SetPoint("BOTTOM", owner, "TOP", 0, 4);
        self:SetParent(owner);
        self.TooltipText:SetText(text);
        self:SetSize(self.TooltipText:GetWrappedWidth() + TEXT_PADDING, self.TooltipText:GetHeight() + TEXT_PADDING);
        self:FadeIn();
    end

    local function CreateSimpleTooltip(parent)
        if not Tooltip then
            Tooltip = CreateFrame("Frame", nil, parent, "NarciGemManagerSliceFrameTemplate");
            AtlasUtil:SetAtlas(Tooltip.Background, "simpletooltip-bg");

            local fs = Tooltip:CreateFontString(nil, "OVERLAY", "NarciGemmaFontMedium");
            Tooltip.TooltipText = fs;
            fs:SetJustifyH("CENTER");
            fs:SetJustifyV("BOTTOM");
            fs:SetPoint("CENTER", Tooltip, "CENTER", 0, 0);
            fs:SetSpacing(2);

            Mixin(Tooltip, SimpleTooltipMixin);
            Tooltip:SetScript("OnShow", Tooltip.OnShow);
            Tooltip:SetScript("OnHide", Tooltip.OnHide);
            Tooltip:SetScript("OnEvent", Tooltip.OnEvent);

            Tooltip:SetFrameStrata("TOOLTIP");
            Tooltip.alpha = 0;
            Tooltip:SetAlpha(0);
            Tooltip:Hide();
        end

        return Tooltip
    end
    Gemma.CreateSimpleTooltip = CreateSimpleTooltip;
end




do
    local NUMBER_SIZE = 28;
    local NUMBER_LABEL_GAP = 6;

    local PointsDisplayMixin = {};

    function PointsDisplayMixin:OnLoad()

    end

    function PointsDisplayMixin:SetLabel(text)
        text = string.upper(text);
        self.Label:SetText(text);
        local textWidth = self.Label:GetWrappedWidth();
        local frameWidth = NUMBER_SIZE + NUMBER_LABEL_GAP + textWidth;
        self:SetWidth(frameWidth);
    end

    function PointsDisplayMixin:SetAmount(amount)
        self.Amount:SetText(amount);
        if amount > 0 then
            self.Amount:SetTextColor(0, 1, 0);
        else
            self.Amount:SetTextColor(0.5, 0.5, 0.5);
        end
    end


    local function CreatePointsDisplay(parent)
        local f = CreateFrame("Frame", nil, parent);
        f:SetSize(80, NUMBER_SIZE);
        Mixin(f, PointsDisplayMixin);

        local Label = f:CreateFontString(nil, "OVERLAY", "NarciGemmaFontMedium");
        f.Label = Label;
        Label:SetJustifyH("LEFT");
        Label:SetJustifyV("MIDDLE");
        Label:SetWidth(128);
        Label:SetPoint("LEFT", f, "LEFT", NUMBER_SIZE + NUMBER_LABEL_GAP, 0);
        Label:SetTextColor(0.88, 0.88, 0.88);
    
        local Amount = f:CreateFontString(nil, "OVERLAY", "NarciGemmaFontLarge");
        f.Amount = Amount;
        Amount:SetJustifyH("RIGHT");
        Amount:SetJustifyV("MIDDLE");
        Amount:SetPoint("RIGHT", Label, "LEFT", -NUMBER_LABEL_GAP, -1)

        local font = NarciGemmaFontLarge:GetFont();
        Amount:SetFont(font, NUMBER_SIZE, "OUTLINE");

        return f
    end
    Gemma.CreatePointsDisplay = CreatePointsDisplay;
end




do
    local SlotHighlightMixin = {};

    local HIGHLIGHT_TEXTURE = {
        Hexagon = {
            Normal = {
                atlas = "remix-hexagon-highlight",
                alphaMode = "ADD",
                alpha = 0.8,
            },

            Dashed = {
                atlas = "remix-hexagon-dashedhighlight",
                alphaMode = "ADD",
                alpha = 0.8,
            },
        },

        BigSquare = {
            Normal = {
                atlas = "remix-bigsquare-highlight",
                alphaMode = "ADD",
                alpha = 0.5,
            },

            Dashed = {
                atlas = "remix-bigsquare-dashedhighlight",
                alphaMode = "ADD",
                alpha = 0.67,
            },
        },
    };

    function SlotHighlightMixin:SetShape(shape)
        local data = HIGHLIGHT_TEXTURE[shape];
        self.data = data;
        AtlasUtil:SetAtlas(self.Texture, data.Normal.atlas);
        self.Texture:SetBlendMode(data.Normal.alphaMode);
        self:SetAlpha(data.Normal.alpha);
        self.isDashed = false;
    end

    function SlotHighlightMixin:HighlightSlot(slot)
        self:ClearAllPoints();
        if slot then
            self:Show();
            self:SetParent(slot);
            self:SetPoint("CENTER", slot, "CENTER", 0, 0);

            local newStyle;

            if slot.traitState == 3 or slot.traitState == 4 then
                if not self.isDashed then
                    self.isDashed = true;
                    newStyle = self.data.Dashed;
                end
            else
                if self.isDashed then
                    self.isDashed = false;
                    newStyle = self.data.Normal;
                end
            end

            if newStyle then
                AtlasUtil:SetAtlas(self.Texture, newStyle.atlas);
                self.Texture:SetBlendMode(newStyle.alphaMode);
                self:SetAlpha(newStyle.alpha);
            end
        else
            self:Hide();
        end
    end

    function SlotHighlightMixin:SetLayerFront(state)
        if state then
            self.Texture:SetDrawLayer("OVERLAY", 7);
        else
            self.Texture:SetDrawLayer("ARTWORK", 0);
        end
    end

    local function CreateSlotHighlight(parent)
        local f = CreateFrame("Frame", nil, parent, "NarciGemManagerButtonHighlightTemplate");
        Mixin(f, SlotHighlightMixin);
        return f
    end
    Gemma.CreateSlotHighlight = CreateSlotHighlight;
end