local _, addon = ...

local UniversalFontUtil = {};
addon.UniversalFontUtil = UniversalFontUtil;

local function GetTextLanguage(str, firstLetterOnly)
    --sometimes examining the first character is enough?

	local len;
    if firstLetterOnly then
        len = 1;
    else
        len = string.len(str)
    end
	local i = 1;
    local c, shift;

	while i <= len do
		c = string.byte(str, i);
		shift = 1;
		if (c > 0 and c <= 127)then
			shift = 1;
		elseif c == 195 then
			shift = 2;	--Latin/Greek
		elseif (c >= 208 and c <=211) then
			shift = 2;
			return "ru" --RU
		elseif (c >= 224 and c <= 227) then
			shift = 3;	--JP
			return "cn"
		elseif (c >= 228 and c <= 233) then
			shift = 3;	--CN
			return "cn"
		elseif (c >= 234 and c <= 237) then
			shift = 3;	--KR
			return "cn"
		elseif (c >= 240 and c <= 244) then
			shift = 4;	--Unknown invalid
		end
		i = i + shift
	end

	return "rm"
end

local FallbackFonts = {
    rm = "Interface\\AddOns\\Narcissus\\Font\\SourceSansPro-Semibold.ttf",
    cn = "Interface\\AddOns\\Narcissus\\Font\\NotoSansCJKsc-Medium.otf",
    ru = "Interface\\AddOns\\Narcissus\\Font\\NotoSans-Medium.ttf",

    zhCN = "Fonts\\ARKai_T.TTF",
    zhTW = "Fonts\\bKAI00M.TTF",
    koKR = "Fonts\\2002.ttf",
};



local UniversalFontMixin = {};

function UniversalFontMixin:SetText(fontString, text)
    if text then
        local lang = GetTextLanguage(text, self.firstLetterOnly);
        if lang ~= fontString.lang then
            fontString.lang = lang;
            local font = (self.fonts and self.fonts[lang]) or (FallbackFonts[lang]);
            if font then
                if not (self.height and self.flags) then
                    local _, height, flag = fontString:GetFont();
                    self:SetFontHeight(height);
                    self:SetFontStyle(flag);
                end
                fontString:SetFont(font, self.height, self.flag);
            end
        end
    end
    fontString:SetText(text);
end

function UniversalFontMixin:SetFontHeight(height)
    self.height = height;
end

function UniversalFontMixin:SetFontStyle(flag)
    --flags: OUTLINE, THICKOUTLINE, MONOCHROME
    self.flag = flag;
end

function UniversalFontMixin:SetFonts(fonts)
    --fonts = { [locale] = path, }
    self.fonts = fonts;
end

function UniversalFontMixin:CheckFirstLetterOnly(state)
    self.firstLetterOnly = state;
end

function UniversalFontUtil.Create()
    local tbl = {};
    for i = 1, select("#", UniversalFontMixin) do
		local mixin = select(i, UniversalFontMixin);
		for k, v in pairs(mixin) do
			tbl[k] = v;
		end
	end
    return tbl
end


do
    local locale = GetLocale();
    local SYSTEM_FONT;

    if locale == "zhCN" or locale == "zhTW" or locale == "koKR" then
        SYSTEM_FONT = FallbackFonts[locale];
    end

    local function GetSystemFontIfNecessary(fontFile)
        if SYSTEM_FONT then
            return SYSTEM_FONT
        else
            return fontFile
        end
    end
    addon.GetSystemFontIfNecessary = GetSystemFontIfNecessary;
end