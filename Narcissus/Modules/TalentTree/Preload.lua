local _, addon = ...

local OnEnterDelay = CreateFrame("Frame");

addon.TalentTreeOnEnterDelay = OnEnterDelay;


OnEnterDelay.onUpdate = function(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.1 then
        self:SetScript("OnUpdate", nil);
        self.t = 0;
        if self.button and self.button.OnEnterCallback then
            self.button.OnEnterCallback(self.button);
        end
        self.button = nil;
    end
end

function OnEnterDelay:WatchButton(button)
    self.button = button;
    self.t = 0;
    self:SetScript("OnUpdate", self.onUpdate);
end

function OnEnterDelay:ClearWatch()
    self.button = nil;
    self:SetScript("OnUpdate", nil);
end



local TextureUtil = {};
addon.TalentTreeTextureUtil = TextureUtil;

local SpecIDXBackgroundFile = {
	-- DK
    [250] = "deathknight-blood",
    [251] = "deathknight-frost",
    [252] = "deathknight-unholy",

    -- DH
    [577] = "demonhunter-havoc",
    [581] = "demonhunter-vengeance",

    -- Druid
    [102] = "druid-balance",
    [103] = "druid-feral",
    [104] = "druid-guardian",
    [105] = "druid-restoration",

    -- Evoker
    [1467] = "evoker-devastation",
    [1468] = "evoker-preservation",
    [1473] = "evoker-Augmentation",

    -- Hunter
    [253] = "hunter-beastmastery",
    [254] = "hunter-marksmanship",
    [255] = "hunter-survival",

    -- Mage
    [62] = "mage-arcane",
    [63] = "mage-fire",
    [64] = "mage-frost",

    -- Monk
    [268] = "monk-brewmaster",
    [269] = "monk-windwalker",
    [270] = "monk-mistweaver",

    -- Paladin
    [65] = "paladin-holy",
    [66] = "paladin-protection",
    [70] = "paladin-retribution",

    -- Priest
    [256] = "priest-discipline",
    [257] = "priest-holy",
    [258] = "priest-shadow",

    -- Rogue
    [259] = "rogue-assassination",
    [260] = "rogue-outlaw",
    [261] = "rogue-subtlety",

    -- Shaman
    [262] = "shaman-elemental",
    [263] = "shaman-enhancement",
    [264] = "shaman-restoration",

    -- Warlock
    [265] = "warlock-affliction",
    [266] = "warlock-demonology",
    [267] = "warlock-destruction",

    -- Warrior
    [71] = "warrior-arms",
    [72] = "warrior-fury",
    [73] = "warrior-protection",
};

function TextureUtil:GetSpecBackground(specID)
    if SpecIDXBackgroundFile[specID] then
        local path = "Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\ClassBackground\\"..SpecIDXBackgroundFile[specID];
        return path, path.."-blur";
    else
        return nil, nil
    end
end

function TextureUtil:CalculateTexCoord(cropWidth, cropHeight, alignment)
    local originalWidth = 1160;
    local originalHeight = 526;

    local l, r, t, b;
    local normalizedWidth = originalWidth * cropHeight / originalHeight;
    local coordRatioH = cropWidth/normalizedWidth;

    if alignment == "left" then
        l = 0;
        r = coordRatioH;
        t = 0;
        b = 1;
    elseif alignment == "center" then
        l = 0.5 - coordRatioH*0.5;
        r = 0.5 + coordRatioH*0.5;
        t = 0;
        b = 1;
    else
        l = 1 - coordRatioH;
        r = 1;
        t = 0;
        b = 1;
    end

    return l, r, t, b
end


local WidgetPixelSize = {
    normal = {
        buttonSize = 32,
        fontHeight = 16,
        smallFontHeight = 15,
        iconSize = 24,
        specButtonHeight = 56,
        specTabWidth = 216;
    },

    large = {
        buttonSize = 40,
        fontHeight = 18,
        smallFontHeight = 16,
        iconSize = 30,
        specButtonHeight = 56,
        specTabWidth = 256;
    },
};

function TextureUtil:UpdateWidgetSize(large)
    local sizeInfo;
    if large then
        sizeInfo = WidgetPixelSize.large;
    else
        sizeInfo = WidgetPixelSize.normal;
    end

    for i, callback in pairs(self.callbacks) do
        callback(sizeInfo);
    end
end

function TextureUtil:AddSizeChangedCallback(callback)
    if not self.callbacks then
        self.callbacks = {};
    end
    table.insert(self.callbacks, callback);
end