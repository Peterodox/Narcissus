--/run NarciOutfitShowcase.BackdropSelect:Open()

local _, addon = ...


local NUM_ROW = 6;
local NUM_COL = 4;

local NUM_BUTTONS = NUM_ROW * NUM_COL;

local modf = math.modf;
local pow = math.pow;
local sin = math.sin;
local pi = math.pi;

local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end


local MainFrame, BackdropContainer, FocusedButton, SelectionFrame, HighlightFrame;

local SELECTED_INDEX, PREVIEW_INDEX;

local AreaData = {
    --[index] = {fileName, areaID},     --see https://wago.tools/db2/AreaTable
    --/script local s=7900;local n;for i = s, s+100 do n=C_Map.GetAreaInfo(i) if n then print(i.. "  "..n) end end
    {"stormwind_cathedral", 5151},
    {"ironforge", 809},
    {"darnassus", 1658},
    {"new_tinkertown", 6457},
    {"ammen_vale", 3526},
    {"gilneas_city", 4755},
    {"the_jade_forest", 5975},
    {"telogrus_rift", 9415},

    {"vindicaar", 9359},
    {"blackrock_depths", 10028},
    {"boralus", 8568},
    {"mechagon", 12825},
    {"valley_of_trials", 363},
    {"tirisfal_glades", 85},
    {"mulgore", 1638},
    {"darkspear_hold", 4866},

    {"sunstrider_isle", 3431},
    {"kezan", 4737},
    {"suramar", 8148},
    {"thunder_totem", 7731},
    {"valley_of_honor", 5168},
    {"dazaralor", 8670},
    {"voldun", 8854},
    {"halls_of_valor", 7672},

    {"trueshot_lodge", 7877},
    {"dalaran", 7502},
    {"black_rook_hold", 7780},
    {"netherlight_temple", 7834},
    {"edge_of_reality", 7519},
    {"sanctum_of_light", 8347},
    {"dreamgrove", 7979},
    {"throne_of_elements", 7280},

    {"peak_of_serenity", 6081},
    {"mardum", 7705},
    {"frozen_throne", 4859},
    {"elysian_hold", 11012},
    {"seat_of_the_primus", 12876},
    {"heart_of_the_forest", 12858},
    {"sinfall", 10986},
    {"torghast", 10472},

    {"oribos", 10565},
    {"stormwind_rain", 5151},
    {"undercity", 1497},
    {"silvermoon_city", 3487},
    {"broken_shore", 7543},
    {"bladespire_grounds", 3931},
    {"netherstorm", 3523},
    {"zulgurub", 19},

    {"zulaman", 3805},
    {"valley_of_kings", 924},
    {"twilight_citidel", 5473},
    {"marris_stead", 2260},
    {"gorgrond", 6721},
    {"deadwind_pass", 41},
    {"tanaris", 440},
    {"the_crucible", 13655},

    {"provis_fauna", 13706},
    {"akstad", 8279},
    {"black_tooth_hovel", 5652},
    {"bradensbrook", 7642},
    {"burning_breach", 9145},
    {"chapel_gardens", 6386},
    {"embaari_village", 6923},
    {"emerald_nightmare", 8026},

    {"feast_of_arrogance", 10980},
    {"glutharns_decay", 12805},
    {"halls_of_atonement", 10995},
    {"hellfire_peninsula", 3483},
    {"korthia", 13570},
    {"lake_elrendar", 3473},
    {"lunarfall", 6790},
    {"outrigger_post", 9582},

    {"skettis", 3679},
    {"talador", 6662},
    {"thastalah_basin", 7668},
    {"the_cracking_plains", 6774},
    {"the_lost_isles", 4720},
    {"the_shadow_vault", 4477},
    {"the_tremaculum", 13216},
    {"tomb_of_the_old_kings", 7744},

    {"uldum", 5034},
    {"underrot", 9391},
    {"wakeners_enclave", 8946},
    {"wardens_redoubt", 8371},
    {"waycrest_manor", 9561},
    {"winterspring", 618},
    {"zangarmarsh", 3521},
    {"moonbrook", 20},

    {"crapopolis", 11455},
    {"the_heartland", 5992},
    {"queens_court", 10425},
    {"nyalotha", 12877},
};

local MAX_INDEX = #AreaData;
local MAX_PAGE = math.ceil(MAX_INDEX/NUM_BUTTONS);

local RaceImage = {
    --[raceID] = imageIndex
    [1] = 1,    --Human
    [2] = 13,   --Orc
    [3] = 2,    --Dwarf
    [4] = 3,    --NE
    [5] = 14,   --UD
    [6] = 15,   --Tauren
    [7] = 4,    --Gnome
    [8] = 16,   --Troll
    [9] = 18,   --Goblin
    [10]= 17,   --BE
    [11]= 5,    --Draenei
    [22]= 6,    --Worgen
    [24]= 7,    --Pandaren
    [25]= 7,
    [26]= 7,
    [27]= 19,   --Suramar
    [28]= 20,   --Highmountain
    [29]= 8,    --VE
    [30]= 9,    --Lightforged
    [31]= 22,   --Zandalari
    [32]= 11,   --Kul Tiran
    [34]= 10,   --Dark Iron
    [35]= 23,   --Vulpera
    [36]= 21,   --Maghar
    [37]= 12,   --Mechagnome
};

local ClassImage = {
    --[classID] = imageIndex
    [1] = 24,   --Warrior
    [2] = 30,   --Paladin
    [3] = 25,   --Hunter
    [4] = 27,   --Rogue
    [5] = 28,   --Priest
    [6] = 35,   --DK
    [7] = 32,   --Shaman
    [8] = 26,   --Mage
    [9] = 29,   --Warlock
    [10] = 33,  --Monk
    [11] = 31,  --Druid
    [12] = 34,  --DH
};



local Buttons = {};

local function SetupThumbnail(texture, index, inset, aspect)
    --"inset" is used to compensate the resampling issue (nicer edge)
    if index > MAX_INDEX then
        return false
    else
        local row = modf((index - 1) * 0.125);
        local col = index - row * 8 - 1;
        local offsetX = 0;
        if aspect then
            offsetX = (1 - aspect)*0.125 * 0.5;
        end
        texture:SetTexCoord(col*0.125 + inset + offsetX, (col+1)*0.125 - inset - offsetX, row*0.0625 + inset, (row+1)*0.0625 - inset);
        return true
    end
end

local function SetupSelection(button)
    SelectionFrame:ClearAllPoints();
    SelectionFrame.AnimShrink:Stop();
    if button then
        SelectionFrame:SetPoint("CENTER", button, "CENTER", 0, 0);
        SelectionFrame:Show();
        SelectionFrame.AnimShrink:Play();
        SelectionFrame:SetParent(button);
    else
        SelectionFrame:Hide();
        SelectionFrame:SetParent(MainFrame);
    end
end

local function SetPreviewImage(index, forceReload)
    if index ~= PREVIEW_INDEX or forceReload then
        PREVIEW_INDEX = index;
        SetupThumbnail(BackdropContainer.BackdropPreview, index, 0, MainFrame.aspect);
        BackdropContainer.BackdropPreview.FadeOut:Stop();
        BackdropContainer.BackdropPreview:Show();
        BackdropContainer.BackdropPreview.FadeOut:Play();
    end
    BackdropContainer.Backdrop:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\Backdrops\\"..AreaData[index][1]);
end

local function CalculateSize(a, pixel)
    return math.floor(a/pixel + 0.5)*pixel
end

local function ShowFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local width = outQuart(self.t, self.fromWidth, self.toWidth, self.duration);
    if self.t >= self.duration then
        width = self.toWidth;
    end
    local bt, alpha, offsetY;
    alpha = self.t * 4;
    if alpha > 1 then
        alpha = 1;
    end
    self.PageText:SetAlpha(alpha);
    self.Title:SetAlpha(alpha);
    for i = 1, NUM_BUTTONS do
        bt = self.t - Buttons[i].row * 0.08;
        if bt > 0 then
            alpha = bt * 4;
            if alpha > 1 then
                alpha = 1;
            end
            offsetY = outQuart(bt, self.buttonOffsetY, 0, 0.5);
            if bt >= 0.5 then
                offsetY = 0;
                alpha = 1;
                --[[
                if (not self.pageTurned) and Buttons[i].index == SELECTED_INDEX then
                    self.pageTurned = true;
                    SetupSelection(Buttons[i]);
                end
                --]]
            end
        else
            alpha = 0;
            offsetY = self.buttonOffsetY;
        end
        Buttons[i]:SetAlpha(alpha);
        Buttons[i]:SetOffsetY(offsetY);
    end
    if bt >= 0.5 then
        self:SetScript("OnUpdate", nil);
    end
    self:SetWidth(width);
end

local function CloseNoChange_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local width = outSine(self.t, self.fromWidth, 0.1, 0.5);
    local alpha = 1 - 4*self.t;
    if alpha < 0 then
        alpha = 0;
    end
    if self.t >= 0.5 then
        width = 4;
        alpha = 0;
        self:Hide();
    end
    for i = 1, NUM_BUTTONS do
        Buttons[i]:SetAlpha(alpha);
    end
    self.PageText:SetAlpha(alpha);
    self.Title:SetAlpha(alpha);
    self:SetWidth(width);
end

local function SelectAndClose_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local wT = self.t - 0.5;
    local width;
    if wT > 0 then
        width = outSine(wT, self.fromWidth, 0.1, 0.5);
        self:SetWidth(width);
    end
    local alpha = 1 - 4*self.t;
    if alpha < 0.2 then
        alpha = 0.2;
    end
    if wT >= 0.5 then
        width = 4;
        alpha = 0;
        self:Hide();
    end
    for i = 1, NUM_BUTTONS do
        if Buttons[i].index ~= SELECTED_INDEX then
            Buttons[i]:SetAlpha(alpha);
        end
    end
    self.PageText:SetAlpha(alpha);
    self.Title:SetAlpha(alpha);
end


local function UseCurrentClassBackground()
    local _, _, id = UnitClass("player");
    SetPreviewImage((id and ClassImage[id]) or 34);
end

local function UseCurrentRaceBackground()
    local _, _, id = UnitRace("player");
    SetPreviewImage((id and RaceImage[id]) or 1);
end

local function UseModelBackgroundImage()
    local index = NarciTurntableOptions.BackgroundImageID;
    if not (index and AreaData[index]) then
        local _, _, id = UnitClass("player");
        index = (id and ClassImage[id]) or 34;
    end
    SELECTED_INDEX = index;
    SetPreviewImage(index);
    MainFrame.swtich.ValueText:SetText(  C_Map.GetAreaInfo(AreaData[index][2]) );
end

local function SetTextureCurrentClass(texture)
    local _, _, id = UnitClass("player");
    local index = (id and ClassImage[id]) or 34;
    texture:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\Showcase\\Backdrops\\"..AreaData[index][1]);
end

addon.UseCurrentClassBackground = UseCurrentClassBackground;
addon.UseCurrentRaceBackground = UseCurrentRaceBackground;
addon.UseModelBackgroundImage = UseModelBackgroundImage;
addon.SetTextureCurrentClass = SetTextureCurrentClass;

local function AbandonChangeAndClose()
    if SELECTED_INDEX then
        SetPreviewImage(SELECTED_INDEX);
        MainFrame:SetZoneName(AreaData[SELECTED_INDEX][2]);
    end
    MainFrame:Close();
end


NarciShowcaseThumbnailButtonMixin = {};

function NarciShowcaseThumbnailButtonMixin:OnClick(button)
    if button == "LeftButton" then
        SELECTED_INDEX = self.index;
        SetPreviewImage(self.index);
        SetupSelection(self);
        MainFrame.pageTurned = true;
        MainFrame:Close(true);
        NarciTurntableOptions.BackgroundImageID = self.index;
        UseModelBackgroundImage();
    else
        AbandonChangeAndClose();
    end
end

function NarciShowcaseThumbnailButtonMixin:OnEnter()
    HighlightFrame:ClearAllPoints();
    HighlightFrame:SetPoint("CENTER", self, "CENTER", 0, 0);
    HighlightFrame.FadeIn:Stop();
    if self.index then
        SetPreviewImage(self.index);
        FocusedButton = self;
        MainFrame:SetZoneName(AreaData[self.index][2]);
        HighlightFrame:Show();
        HighlightFrame.FadeIn:Play();
    else
        FocusedButton = nil;
        HighlightFrame:Hide();
    end
end

function NarciShowcaseThumbnailButtonMixin:OnLeave()
    if not self:IsMouseOver() then
        HighlightFrame:Hide();
    end
    if SELECTED_INDEX then
        SetPreviewImage(SELECTED_INDEX);
        MainFrame:SetZoneName(AreaData[SELECTED_INDEX][2]);
    end
end

function NarciShowcaseThumbnailButtonMixin:OnMouseDown()
    HighlightFrame.Highlight:SetColorTexture(1, 1, 1, 0.14);
end

function NarciShowcaseThumbnailButtonMixin:OnMouseUp()
    HighlightFrame.Highlight:SetColorTexture(1, 1, 1, 0.1);
end

function NarciShowcaseThumbnailButtonMixin:SetData(index)
    if SetupThumbnail(self.Texture, index, 0.001) then
        self:Show();
        self.index = index;
    else
        self:Hide();
        self.index = nil;
    end
end

function NarciShowcaseThumbnailButtonMixin:SetButtonSize(side, inset)
    self:SetSize(side, side);
    self:SetHitRectInsets(-inset, -inset, -inset, -inset);
end

function NarciShowcaseThumbnailButtonMixin:SetFinalPosition(x, y)
    self:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", x, y);
    self.toX = x;
    self.toY = y;
end

function NarciShowcaseThumbnailButtonMixin:SetOffsetY(dy)
    self:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", self.toX, self.toY + dy);
end

function NarciShowcaseThumbnailButtonMixin:ClearTemps()
    self.toX, self.toY = nil, nil;
end



NarciShowcaseBackdropSelectMixin = {};

function NarciShowcaseBackdropSelectMixin:OnLoad()
    self.sizeChanged = true;
    self.rootFrame = self:GetParent();
    MainFrame = self;
    BackdropContainer = self:GetParent().ModelScene;
    SelectionFrame = self.SelectionFrame;
    HighlightFrame = self.HighlightFrame;
end

function NarciShowcaseBackdropSelectMixin:OnShow()
    self:CreateThumbnails();
    if not self.page then
        self.page = 1;
        self:SetPage(self.page);
    end
    self:RegisterEvent("GLOBAL_MOUSE_DOWN");
end

function NarciShowcaseBackdropSelectMixin:OnHide()
    FocusedButton = nil;
    self:Hide();
    self.CursorBlock:Hide();
    HighlightFrame:Hide();
    self.t = nil;
    self.isActive = nil;
    self.pageTurned = nil;
    self:SetScript("OnUpdate", nil);
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
    self:StopAnimating();
    for _, button in pairs(Buttons) do
        button:ClearTemps();
    end
end

function NarciShowcaseBackdropSelectMixin:OnEvent(event, key)
    if not (self:IsMouseOver() or self.swtich:IsMouseOver() or self.rootFrame:IsMouseOver()) then
        if key ~= "MiddleButton" then
            self:Close();
        end
    end
end

function NarciShowcaseBackdropSelectMixin:OnMouseDown(button)
    if button == "RightButton" then
        AbandonChangeAndClose();
    end
end

function NarciShowcaseBackdropSelectMixin:CreateThumbnails()
    local level = self:GetFrameLevel() + 2;
    self.CursorBlock:SetFrameLevel(level + 10);
    local pixel, multipler = self:GetParent():GetPixelSize();
    local spanX = self.fullWidth - math.floor(multipler * 48 + 0.5) * pixel;
    spanX = CalculateSize(spanX, pixel);
    local spacing = math.floor(6 * multipler + 0.5) * pixel;
    local buttonHitRectInset = spacing * 0.6;
    local frameWidth = self.fullWidth;
    local frameHeight = self:GetHeight();
    local side = (spanX - (NUM_COL - 1) * spacing) / NUM_COL;
    side = CalculateSize(side, pixel);
    local frameLeft = self:GetLeft();
    local offsetX = CalculateSize((frameWidth - spanX) * 0.5, pixel);
    local spanY = (side + spacing) * NUM_ROW - spacing;
    local offsetY = CalculateSize(-(frameHeight - spanY) * 0.5, pixel);
    local distance = side + spacing;
    local col, row = 0, 0;
    local button;
    for i = 1, 24 do
        button = Buttons[i];
        if not button then
            Buttons[i] = CreateFrame("Button", nil, self, "NarciShowcaseThumbnailButtonTemplate");
            button = Buttons[i];
            button.row = row;
            button.col = col;
        end
        button:SetButtonSize(side, buttonHitRectInset);
        button:SetFinalPosition( CalculateSize(offsetX + col * distance, pixel), CalculateSize(offsetY - row * distance, pixel));
        button:SetFrameLevel(level);
        col = col + 1;
        if col >= NUM_COL then
            col = 0;
            row = row + 1;
        end
    end
    self.buttonOffsetY = side * -0.25;

    self.Title:ClearAllPoints();
    self.Title:SetPoint("BOTTOMLEFT", self, "TOPLEFT", offsetX, offsetY + 2*spacing);
    self.Title:SetWidth(spanX);
    if multipler > 1 then
        self.Title:SetFontObject("NarciFontUniversal12");
    else
        self.Title:SetFontObject("NarciFontUniversal9");
    end
    self.Title:SetTextColor(0.8, 0.8, 0.8);

    self.PageText:ClearAllPoints();
    self.PageText:SetPoint("TOPRIGHT", self, "TOPLEFT", offsetX + NUM_COL * distance - spacing, offsetY - NUM_ROW*distance - spacing);

    HighlightFrame:SetSize(side, side);
    HighlightFrame:SetFrameLevel(level + 1);
    SelectionFrame:SetSize(side, side);
    SelectionFrame.BorderOutter:SetSize(side + 6*pixel, side + 6*pixel);
    SelectionFrame.Exclusion:SetSize(side - 4*pixel, side - 4*pixel);
    SelectionFrame:SetFrameLevel(level + 2);
end

function NarciShowcaseBackdropSelectMixin:SetPage(page)
    page = page or 1;
    local offset = (page - 1)*24;
    local id;
    SetupSelection(nil);
    for i = 1, 24 do
        id = i + offset;
        Buttons[i]:SetData(id);
        if id == SELECTED_INDEX then
            SetupSelection(Buttons[i]);
        end
    end
    self.PageText:SetText(string.format(COLLECTION_PAGE_NUMBER, self.page, MAX_PAGE));
    if FocusedButton then
        FocusedButton:OnEnter();
    end
end

function NarciShowcaseBackdropSelectMixin:OnMouseWheel(delta)
    if delta < 0 and self.page < MAX_PAGE then
        self.page = self.page + 1;
        self:SetPage(self.page);
        self.pageTurned = true;
    elseif delta > 0 and self.page > 1 then
        self.page = self.page - 1;
        self:SetPage(self.page);
        self.pageTurned = true;
    end
end

function NarciShowcaseBackdropSelectMixin:SetZoneName(id)
    if id then
        self.Title:SetText( C_Map.GetAreaInfo(id) );
    end
end

function NarciShowcaseBackdropSelectMixin:HasFocus()
    return self:IsVisible() and self:IsMouseOver();
end

function NarciShowcaseBackdropSelectMixin:SetFrameWidth(width)
    self.toWidth = width;
    self.fullWidth = width;
    self:SetWidth(width);
    self.CursorBlock:SetWidth(width);
end

function NarciShowcaseBackdropSelectMixin:Open()
    if not self.isActive then
        self.isActive = true;
        --SelectionFrame:Hide();
        self.fromWidth = 4;
        self.t = 0;
        self.duration = 0.6;
        self:SetScript("OnUpdate", ShowFrame_OnUpdate);
        self:Show();
        self.CursorBlock:Hide();
    end
end

function NarciShowcaseBackdropSelectMixin:Close(anyChange)
    if self.isActive then
        self.isActive = nil;
        self.pageTurned = nil;
        self.fromWidth = self:GetWidth();
        self.t = 0;
        if anyChange then
            self.duration = 0.6;
            self:SetScript("OnUpdate", SelectAndClose_OnUpdate);
        else
            self.duration = 0.6;
            self:SetScript("OnUpdate", CloseNoChange_OnUpdate);
        end
        self.CursorBlock:Show();
    end
end

function NarciShowcaseBackdropSelectMixin:Toggle()
    if self.isActive then
        self:Close();
    else
        self:Open();
    end
end

--texture:IsObjectLoaded()