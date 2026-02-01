local _, addon = ...


local FadeFrame = NarciFadeUI.Fade;
local GetCursorPosition = GetCursorPosition;
local tinsert = table.insert;
local ipairs = ipairs;
local IsAltKeyDown = IsAltKeyDown;


local UIParent = UIParent;


local LoveGenerator = {};   --dropping hearts when creadit list is focused
local CreditList = {};
addon.CreditList = CreditList;


local PADDING_H = 18;
local BUTTON_LEVEL_OFFSET = 12;


local function SetFontStringColor(fontString)
    fontString:SetTextColor(0.40, 0.40, 0.40);
end


do  --LoveGenerator
    function LoveGenerator.HeartAnimationOnStop(animGroup)
        local tex = animGroup:GetParent();
        tex:Hide();
        tinsert(LoveGenerator.recyledTextures, tex);
    end

    function LoveGenerator:GetHeart()
        if not self.textures then
            self.textures = {};
        end
        if not self.recyledTextures then
            self.recyledTextures = {};
        end

        if #self.recyledTextures > 0 then
            return table.remove(self.recyledTextures, #self.recyledTextures)
        else
            local tex = CreditList.MainFrame.HeartContainer:CreateTexture(nil, "OVERLAY", "NarciPinkHeartTemplate", 2);
            tex.FlyDown:SetScript("OnFinished", LoveGenerator.HeartAnimationOnStop);
            tex.FlyDown:SetScript("OnStop", LoveGenerator.HeartAnimationOnStop);
            self.textures[ #self.textures + 1 ] = tex;
            return tex
        end
    end

    function LoveGenerator:CreateHeartAtCursorPosition()
        if CreditList.MainFrame.HeartContainer:IsMouseOver() then
            local heart = self:GetHeart();

            local px, py = GetCursorPosition();
            local scale = CreditList.MainFrame:GetEffectiveScale();
            px, py = px / scale, py / scale;

            local d = math.max(py - CreditList.MainFrame:GetBottom() + 16, 0); --distance
            local depth = math.random(1, 8);
            local scale = 0.25 + 0.25 * depth;
            local size = 32 * scale;
            local alpha = 1.35 - 0.15 * depth;
            local v = 20 + 10 * depth;
            local t= d / v;

            if alpha > 0.5 then
                alpha = 0.5;
            end

            heart.FlyDown.Translation:SetOffset(0, -d);
            heart.FlyDown.Translation:SetDuration(t);
            heart:ClearAllPoints();
            heart:SetPoint("CENTER", UIParent, "BOTTOMLEFT" , px, py);

            heart:SetSize(size, size);
            heart:SetAlpha(alpha);
            heart.FlyDown:Play();
            heart:Show();
        end
    end

    function LoveGenerator:StopAnimation()
        if self.textures then
            for _, tex in ipairs(self.textures) do
                tex.FlyDown:Stop();
            end
        end
    end
end


local Memembers = {
"Albator S.",
"Lala.Kawaii",
"Celierra & Darvian",
"Elexys",
"Faelor",
"Pierre-Yves Bertolus",
"Terradon",
"Samuel Kohlhepp",
"Ryan Zerbin",
"Solanya",
"Brian Haberer",
"Miroslav Kovac",
"cybern4ut",
"Ben Ashley",
"Knightlord",
"Felicia",
"Andrew Phoenix",
"Alex Boehm",
"Nantangitan ",
"Mike Rudziensky",
"Markus Magnitz",
"Blastflight",
"Sixsten",
"Helene Rigo",
"Ethan Hamric",
"Lars Norberg",
"eranor",
"Altina",
"Valnoressa",
"Nimrodan",
"Seizure Augustus",
"Федор Назаров",
"Brux",
"Nisutec",
"Karl ",
"Acein20",
"HueStL",
"Christian Williamson",
"Adrien Le Texier",
"Timothy phillips",
"Elrathir",
"8nxtsuke",
"Tzutzu",
"Ghibligeek",
"Paxim ",
"Nina Recchia",
"Ren",
"Jeremy Hill",
"Supporter 237",
"nohitjerome",
"Psyloken",
"heiteo",
"Tezenari",
"AndrewHayden",
"Raidri",
"Justin Gum",
"Nila",
"Victor Torres",
"Jesse Blick",
"Kit M",
"Rui",
"David Hoecker",
"Ellypse",
"Kat Smith",
};


local SpecialNameCards = {
    {text = "Marlamin | WoW.tools"},
    {text = "Meorawr | Wondrous Wisdomball"},

    {text = " "},

    {text = "Hubbotu | Translator - Russian"},
    {text = "Romanv | Translator - Spanish"},
    {text = "Onizenos | Translator - Portuguese"},
};


local FocusSolver = CreateFrame("Frame");
do
    function FocusSolver:OnUpdate(elapsed)
        self.t = self.t + elapsed;
        if self.t >= 0.5 then
            self.t = nil;
            self:SetScript("OnUpdate", nil);
            if self:IsObjectFocused() then
                self.object:OnFocused();
            end
        end
    end

    function FocusSolver:Stop()
        self.t = 0;
        self:SetScript("OnUpdate", nil);
    end

    function FocusSolver:SetFocus(object)
        self.object = object;
        if object then
            if not self.t then
                self:SetScript("OnUpdate", self.OnUpdate);
            end
            self.t = 0;
        else
            self:Stop();
        end
    end

    function FocusSolver:SetUseModifierKeys(useModifierKeys)
        self.useModifierKeys = useModifierKeys;
    end

    function FocusSolver:OnHide()
        self:Stop();
    end

    function FocusSolver:IsObjectFocused()
        if self.object then
            return self.object:IsMouseMotionFocus()
        end
    end
end


local NameCardMixin = {};
do
    function NameCardMixin:OnEnter()
        FocusSolver:SetFocus(self);
    end

    function NameCardMixin:OnLeave()
        self.focused = false;
        FadeFrame(self.Dot, 0.25, 0);
        if self.onLeaveFunc then
            self.onLeaveFunc(self);
        end
    end

    function NameCardMixin:OnHide()
        self.focused = false;
        self:SetScript("OnUpdate", nil);
        if self.onHideCallback then
            self.onHideCallback(self);
        end
    end

    function NameCardMixin:OnMouseDown()
        if self.onClickFunc then
            self.onClickFunc(self);
        end
    end

    function NameCardMixin:GetTextWidth()
        if self.textWidth then return self.textWidth; end;
        return self.Label:GetWrappedWidth();
    end

    function NameCardMixin:OnLoad()
        self:SetScript("OnEnter", self.OnEnter);
        self:SetScript("OnLeave", self.OnLeave);
        self:SetScript("OnHide", self.OnHide);
        self:SetScript("OnMouseDown", self.OnMouseDown);
    end

    function NameCardMixin:OnFocused()
        self.focused = true;
        if self.onFocusdFunc then
            self.onFocusdFunc(self);
            FadeFrame(self.Dot, 0.25, 0.4);
        end
    end


    local function Lerp(startValue, endValue, amount)
        return (1 - amount) * startValue + amount * endValue;
    end

    local function Clamp(value, min, max)
        if value > max then
            return max
        elseif value < min then
            return min
        end
        return value
    end


    local function Saturate(value)
        return Clamp(value, 0.0, 1.0);
    end

    local function DeltaLerp(startValue, endValue, amount, timeSec)
        return Lerp(startValue, endValue, Saturate(amount * timeSec * 60.0));
    end


    tinsert(SpecialNameCards, 3, {
        text = "Keyboardturner | Avid Bug Finder(Generator)",
        setupFunc = function(self)
            local text = "Keyboardturner";
            local letters = {};
            self.letters = letters;
            local n = 0;
            local fullWidth = self.fromOffsetX;
            for v in string.gmatch(text, "%a") do
                n = n + 1;
                local fs = self:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
                letters[n] = fs;
                SetFontStringColor(fs);
                fs:SetText(v);
                fs:SetPoint("LEFT", self, "LEFT", fullWidth, 0);
                fs:SetHeight(16);
                --if n == 1 then
                --    fs:SetPoint("LEFT", self, "LEFT", 0, 0);
                --else
                --    fs:SetPoint("LEFT", letters[n - 1], "RIGHT", 0, 0);
                --end
                fs:SetJustifyH("CENTER");
                fs:SetJustifyV("MIDDLE");
                fullWidth = fullWidth + fs:GetWidth();
            end

            self.Label:SetText(" | Avid Bug Finder(Generator)");
            self.Label:ClearAllPoints();
            self.Label:SetPoint("LEFT", self, "LEFT", fullWidth, 0);
        end,

        mixin = {
            onFocusdFunc = function(self)
                self.t = 0;
                self:SetScript("OnUpdate", function(_, elapsed)
                    self.t = self.t + elapsed;
                    if self.t > 0.016 then
                        local px, py = GetCursorPosition();
                        local scale = self:GetEffectiveScale();
                        px, py = px / scale, py / scale;
                        local x, a;
                        local range = 32;
                        for i, fs in ipairs(self.letters) do
                            x = fs:GetCenter();
                            a = (px - x) / range
                            if a > 1 then
                                a = 1;
                            elseif a < -1 then
                                a = -1;
                            end
                            if a > 0 then
                                --fs:SetRotation((1 - a) * 1.57);
                                fs:SetRotation(DeltaLerp(fs:GetRotation(), (1 - a) * 1.57,  0.2, elapsed));
                            else
                                --fs:SetRotation((1 + a) * 1.57);
                                fs:SetRotation(DeltaLerp(fs:GetRotation(), (1 + a) * 1.57,  0.2, elapsed));
                            end
                        end
                    end
                end);
            end,

            onLeaveFunc = function(self)
                for i, fs in ipairs(self.letters) do
                    fs:SetRotation(0);
                end
                self:SetScript("OnUpdate", nil);
            end,
        },
    });


    tinsert(SpecialNameCards, 4, {
        text = "Ghost | Real Person",
        setupFunc = function(self)
            local container = CreditList.MainFrame.ArtContainer;
            self.Portrait = container:CreateTexture(nil, "ARTWORK");
            self.Portrait:SetSize(190, 190);
            self.Portrait:SetPoint("CENTER", self, "RIGHT", -16, 0);
            self.Portrait:SetTexture("Interface/AddOns/Narcissus/Art/SettingsFrame/Blue.png");
            self.Portrait:SetTexCoord(72/512, 440/512, 72/512, 440/512);
            self.Portrait:SetAlpha(0.5);
            local ag = self.Portrait:CreateAnimationGroup();
            self.AnimIn = ag;
            local a1 = ag:CreateAnimation("Rotation");
            a1:SetDegrees(7.5);
            a1:SetDuration(0.6);
            a1:SetSmoothing("OUT");
            a1:SetOrder(1);
            a1:SetEndDelay(60);
            self.Portrait:Hide();
            self.Portrait:SetAlpha(0);
        end,

        mixin = {
            onFocusdFunc = function(self)
                self.t = 0;
                self:SetScript("OnUpdate", function(_, elapsed)
                    self.t = self.t + elapsed;
                    if self.t > 0.5 then
                        self.t = 0;
                        self:SetScript("OnUpdate", nil);
                        self.AnimIn:Stop();
                        self.AnimIn:Play();
                        FadeFrame(self.Portrait, 0.5, 0.5);
                    end
                end);
            end,

            onLeaveFunc = function(self)
                FadeFrame(self.Portrait, 0.25, 0);
                self:SetScript("OnUpdate", nil);
                self.t = 0;
            end,
        },
    });


    tinsert(SpecialNameCards, 5, {
        text = "Solanya | CEO of RP",
        setupFunc = function(self)
            local f = CreateFrame("Frame");
            f:SetFrameStrata("FullScreen");
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
            f:SetSize(8, 8);
            f:Hide();
            self.SecondaryTextContainer = f;

            local Text1 = f:CreateFontString(nil, "OVERLAY");
            local fontFile, height, flag = NarciFontMedium13:GetFont();
            Text1:SetFont(fontFile, 96, "");
            Text1:SetTextColor(1, 0.125, 0.125);
            Text1:SetText("\87\73\80\69\68\32\89\79\85\82\32\84\82\80");
            Text1:SetPoint("CENTER", f, "CENTER", 0, -12);

            local Text2 = f:CreateFontString(nil, "OVERLAY");
            Text2:SetFont(fontFile, 24, "");
            Text2:SetTextColor(1, 1, 1);
            Text2:SetText("\84\72\69\32\67\69\79\32\79\70\32\82\80");
            Text2:SetPoint("BOTTOM", Text1, "TOP", 0, 0);

            local ag = f:CreateAnimationGroup();
            self.AnimFade = ag;
            ag:SetToFinalAlpha(true);
            local a1 = ag:CreateAnimation("alpha");
            a1:SetFromAlpha(0);
            a1:SetToAlpha(1);
            a1:SetDuration(0.05);
            a1:SetOrder(1);
            local a2 = ag:CreateAnimation("alpha");
            a2:SetFromAlpha(1);
            a2:SetToAlpha(0);
            a2:SetStartDelay(2);
            a2:SetDuration(0.5);
            a2:SetOrder(2);

            self.onHideCallback = function()
                f:Hide();
                ag:Stop();
            end;
        end,

        mixin = {
            onClickFunc = function(self)
                if self.focused and not self.AnimFade:IsPlaying() then
                    self.AnimFade:Stop();
                    self.AnimFade:Play();
                    self.SecondaryTextContainer:Show();
                end
            end,

            onFocusdFunc = function(self)
            end,
        },
    });


    tinsert(SpecialNameCards, 6, {
        text = "Raenore | ",

        setupFunc = function(self)
            self.Label2 = self:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
            SetFontStringColor(self.Label2);
            self.Label2:SetText("Infamous Dressing Room Bottom Bar™ Bug Finder");
            self.Label2:SetPoint("LEFT", self.Label, "RIGHT", 0, 0);

            self.AltText = self:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
            SetFontStringColor(self.AltText);
            self.AltText:SetText(""); --"\65\110\100\32\70\111\114\32\66\101\105\110\103\32\77\121\32\70\114\105\101\110\100"
            self.AltText:SetPoint("LEFT", self.Label, "RIGHT", 0, 0);
            self.AltText:SetAlpha(0);
        end,

        mixin = {
            onFocusdFunc = function(self)
                self.t1 = 1;
                self.t2 = 1;

                local letters = {
                    "\65", "\110", "\100", "\32", "\70", "\111", "\114", "\32", "\66", "\101", "\105", "\110", "\103", "\32", "\77", "\121", "\32", "\70", "\114", "\105", "\101", "\110", "\100",
                };

                self.total = #letters;
                if not self.i then
                    self.i = 0;
                end
                self.delay = 0.5;

                self:SetScript("OnUpdate", function(_, elapsed)
                    self.t1 = self.t1 + elapsed;
                    self.t2 = self.t2 + elapsed;
                    if self.t1 > 0.032 then
                        self.t1 = 0;
                        self.altKeyDown = IsAltKeyDown();
                    end
                    if self.altKeyDown then
                        self.alpha = self.AltText:GetAlpha();
                        self.alpha = self.alpha + 5 * elapsed;
                        if self.alpha > 1 then
                            self.alpha = 1;
                        end
                        self.AltText:SetAlpha(self.alpha);
                        self.Label2:SetAlpha(1 - self.alpha);
                        if self.t2 > self.delay then
                            self.t2 = 0;
                            self.i = self.i + 1;
                            if self.i > self.total then
                                self.i = self.total + 1;
                                self.delay = 1;
                            else
                                local text = "";
                                for i = 1, self.i do
                                    text = text..letters[i];
                                end
                                self.AltText:SetText(text);
                                if self.i < 13 then
                                    self.delay = 0.5;
                                elseif self.i > 13 then
                                    self.delay = 0.05;
                                else
                                    self.delay = 2;
                                end
                            end
                        end
                    else
                        self.alpha = self.AltText:GetAlpha();
                        self.alpha = self.alpha - 5 * elapsed;
                        if self.alpha < 0 then
                            self.alpha = 0;
                        end
                        self.AltText:SetAlpha(self.alpha);
                        self.Label2:SetAlpha(1 - self.alpha);
                    end
                end);
            end,

            onLeaveFunc = function(self)
                self.altKeyDown = nil;
                self.t = 0;
                self:SetScript("OnUpdate", nil);
                self.Label2:SetAlpha(1);
                self.AltText:SetAlpha(0);
            end,
        }
    });
end

local function CreateSpecialNameCard(anchorTo, fromOffsetY)
    local cards = {};
    CreditList.nameCards = cards;

    local cardHeight = 24;

    for i, v in ipairs(SpecialNameCards) do
        local f = CreateFrame("Frame", nil, CreditList.parent);
        cards[i] = f;
        f:SetSize(360, cardHeight);
        f.fromOffsetX = 32;
        f.Label = f:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
        f.Label:SetJustifyH("LEFT");
        f.Label:SetPoint("LEFT", f, "LEFT", f.fromOffsetX, 0);
        f.Label:SetText(v.text);
        SetFontStringColor(f.Label);

        f.Dot = f:CreateTexture(nil, "OVERLAY");
        f.Dot:SetSize(8, 8);
        f.Dot:SetPoint("RIGHT", f, "LEFT", f.fromOffsetX - 4, 0);
        f.Dot:SetTexture("Interface/AddOns/Narcissus/Art/SettingsFrame/Dot16");
        f.Dot:SetAlpha(0.4);
        f.Dot:SetAlpha(0);
        f.Dot:Hide();

        if v.setupFunc then
            v.setupFunc(f);
        end

        f:SetPoint("TOP", anchorTo, "TOP", -32, fromOffsetY - (i - 1) * cardHeight);

        Mixin(f, NameCardMixin);
        if v.mixin then
            Mixin(f, v.mixin);
        end
        f:OnLoad();
    end
end


do  --CreditList
    function CreditList:CreateList(parent, anchorTo, fromOffsetY)
        --local aciveColor = "|cff914270";

        local numTotal = #Memembers;
        local totalHeight;

        local upper = string.upper;

        table.sort(Memembers, function(a, b)
            return upper(a) < upper(b)
        end);


        local header = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
        header:SetPoint("TOP", anchorTo, "TOP", 0, fromOffsetY);
        header:SetText(string.upper("Patrons"));
        SetFontStringColor(header, 1);

        totalHeight = header:GetHeight() + 12;
        fromOffsetY = fromOffsetY - totalHeight;

        local numRow = math.ceil(numTotal/3);

        local sidePadding = PADDING_H + BUTTON_LEVEL_OFFSET;
        self.sidePadding = sidePadding;
        self.anchorTo = anchorTo;
        self.parent = parent;

        local colWidth = (self.MainFrame.ScrollFrame:GetWidth() - sidePadding*2) / 3;
        local text;
        local fontString;
        local height;

        local i = 0;
        local maxHeight = 0;
        local totalTextWidth = 0;
        local width = 0;

        local fontStrings = {};

        for col = 1, 3 do
            fontString = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
            fontString:SetWidth(colWidth);
            fontString:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", 0, fromOffsetY);
            fontString:SetJustifyH("LEFT");
            fontString:SetJustifyV("TOP");
            fontString:SetSpacing(8);
            fontStrings[col] = fontString;
            SetFontStringColor(fontString, 1);

            text = nil;
            for row = 1, numRow do
                i = i + 1;
                if Memembers[i] then
                    if text then
                        text = text .. "\n" .. Memembers[i];
                    else
                        text = Memembers[i];
                    end
                end
            end

            fontString:SetText(text);
            height = fontString:GetHeight();
            width = fontString:GetWrappedWidth();
            totalTextWidth = totalTextWidth + width;

            if height > maxHeight then
                maxHeight = height;
            end
        end

        self.totalTextWidth = totalTextWidth;
        self.fontStrings = fontStrings;
        self.offsetY = fromOffsetY;

        fromOffsetY = fromOffsetY - maxHeight - 48;

        local header2 = parent:CreateFontString(nil, "OVERLAY", "NarciFontMedium13");
        header2:SetPoint("TOP", anchorTo, "TOP", 0, fromOffsetY);
        header2:SetText(string.upper("special thanks"));
        SetFontStringColor(header2, 1);

        fromOffsetY = fromOffsetY - header2:GetHeight() - 12;

        CreateSpecialNameCard(anchorTo, fromOffsetY);
        local bottomObject = self.nameCards[#self.nameCards];

        self.specialNames = fontString;
        self.specialNamesOffsetY = fromOffsetY;

        totalHeight = math.floor(header:GetTop() - bottomObject:GetBottom() + 36.5);

        self:UpdateAlignment();

        Memembers = nil;

        return totalHeight
    end

    function CreditList:UpdateAlignment()
        if self.fontStrings then
            local offsetX = self.sidePadding;
            local parentWidth = self.MainFrame.ScrollFrame:GetWidth();

            local gap = (parentWidth - self.sidePadding*2 - self.totalTextWidth) * 0.5;
            for col = 1, 3 do
                self.fontStrings[col]:ClearAllPoints();
                self.fontStrings[col]:SetPoint("TOPLEFT", self.anchorTo, "TOPLEFT", offsetX, self.offsetY);
                offsetX = offsetX + self.fontStrings[col]:GetWrappedWidth() + gap;
            end

            --local specialNameWidth = self.specialNames:GetWrappedWidth();
            --offsetX = (parentWidth - specialNameWidth) * 0.5;
            --self.specialNames:SetPoint("TOPLEFT", self.anchorTo, "TOPLEFT", offsetX, self.specialNamesOffsetY);
        end
    end

    function CreditList.TimerOnUpdate(f, elapsed)
        f.t = f.t + elapsed;
        if f.t > 3 then
            f.t = 0;
            LoveGenerator:CreateHeartAtCursorPosition();
        end
    end

    function CreditList:OnFocused(state, offset)
        if state and offset < 4800 then
            if not self.focused then
                self.focused = true;
                self.parent.t = 0;
                self.parent:SetScript("OnUpdate", CreditList.TimerOnUpdate);
                FadeFrame(self.MainFrame.HeartContainer, 0.5, 1);
            end
        else
            if self.focused then
                self.focused = nil;
                self.parent:SetScript("OnUpdate", nil);
                FadeFrame(self.MainFrame.HeartContainer, 0.5, 0);
            end
        end
    end

    function CreditList:StopAnimation()
        if self.focused then
            LoveGenerator:StopAnimation();
        end
    end
end