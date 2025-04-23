local _, addon = ...
local API = addon.API;

local GetBestSizeForPixel = NarciAPI.GetBestSizeForPixel;

---API---
--[[
    Category Structure: https://wowpedia.fandom.com/wiki/API_C_BarberShop.GetAvailableCustomizations
--]]

local FONT_HEIGHT = 16;
local FONT_SPACING = 8;
local SIDE_PADDING = 32;
local OPTION_CHOICE_GAP = 8;
local CATEGORY_GAP = 24;
local PORTRAIT_SIZE = 60;

local WidgetPool = {};

function WidgetPool:GetContainer()
    if not self.container then
        self.parent = API.GetSettingsFrame();
        local container = CreateFrame("Frame", nil, self.parent, "NarciChamferedFrameTemplate");
        self.container = container;
        self.parent:AddChildFrame(container);
        container:SetSize(8, 8);
        container:Hide();

        local v = 0.2;
        container:SetBorderColor(v, v, v, 1);
        container:SetBackgroundColor(0, 0, 0, 1);
        container:SetBorderOffset(0);

        local function Container_OnShow(f)
            f:RegisterEvent("GLOBAL_MOUSE_DOWN");
        end

        local function Container_OnHide(f)
            f:RegisterEvent("GLOBAL_MOUSE_DOWN");
            WidgetPool.HideContainer();
        end

        local function Container_OnEnter(f)
            container:SetBorderColor(0.80, 0.80, 0.80, 1);
        end

        local function Container_OnLeave(f)
            if not f:IsMouseOver() then
                container:SetBorderColor(0.2, 0.2, 0.2, 1);
            end
        end

        container:SetScript("OnShow", Container_OnShow);
        container:SetScript("OnHide", Container_OnHide);
        container:SetScript("OnEnter", Container_OnEnter);
        container:SetScript("OnLeave", Container_OnLeave);

        container:SetClampedToScreen(true);
        container:SetClampRectInsets(0, 0, 8, -8);

        local clipboard = CreateFrame("EditBox", nil, container, "NarciBarberShopAppearanceClipboardTemplate");
        clipboard:Hide();
        clipboard:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0);
        clipboard:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0);
        clipboard.parent = container;

        local function Container_OnMouseDown(f)
            if f.appearancePlainText then
                clipboard:Enable();
                clipboard:EnableMouse(true);
                clipboard:Show();
                clipboard:SetText(f.appearancePlainText);
                clipboard:SetFocus();
            end
        end

        local function Container_OnEvent(f, event, ...)
            if event == "GLOBAL_MOUSE_DOWN" then
                local button = ...
                if button ~= "LeftButton" then
                    clipboard:ClearFocus(false);
                end
            end
        end

        container:SetScript("OnMouseDown", Container_OnMouseDown);
        container:SetScript("OnEvent", Container_OnEvent);
    end

    self:GetPixel();
    self.container:ClearAllPoints();
    self.container:SetPoint("TOPLEFT", self.parent, "TOPRIGHT", self.pixel * 16, 0);

    return self.container
end

function WidgetPool:GetPixel()
    if not self.pixel then
        self.pixel = NarciAPI.GetPixelForWidget(self.container);
    end
    return self.pixel;
end

function WidgetPool:GetPortrait()
    if not self.portrait then
        self.portrait = self.container:CreateTexture(nil, "ARTWORK");

        local stroke = self.container:CreateTexture(nil, "OVERLAY");
        stroke:SetPoint("CENTER", self.portrait, "CENTER", 0, 0);
        stroke:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\BarberShop\\Ring64_Stroke2");
        stroke:SetSize(64, 64);
        stroke:SetVertexColor(0.2, 0.2, 0.2);
        self.portrait.stroke = stroke;
    end
    self.portrait:Show();

    return self.portrait
end

function WidgetPool.HideContainer()
    if WidgetPool.container then
        WidgetPool.container:Hide();
        WidgetPool.container.appearancePlainText = nil;
    end
end

function WidgetPool:ReleaseAll()
    self.numFontStrings = 0;

    if self.fontStrings then
        for _, fs in pairs(self.fontStrings) do
            fs:SetText("");
            fs:Hide();
            fs:ClearAllPoints();
        end
    end

    if self.portrait then
        self.portrait:Hide();
        self.portrait:SetTexture(nil);
        self.portrait:ClearAllPoints();
    end
end

function WidgetPool:GetFontString()
    if not self.fontStrings then
        self.fontStrings = {};
        local font = GameFontNormal:GetFont();
        self.font = font;
    end

    self.numFontStrings = self.numFontStrings + 1;

    local f = self.fontStrings[self.numFontStrings];
    if not f then
        f = self.container:CreateFontString(nil, "OVERLAY");
        self.fontStrings[self.numFontStrings] = f;
    end

    f:SetFont(self.font, self.pixel * FONT_HEIGHT, "");
    f:SetSpacing(self.pixel * FONT_SPACING);
    f:Show();

    return f
end

function WidgetPool:ConcatenateFontStringTexts()
    local txt = "";

    if self.fontStrings then
        for i = 1, self.numFontStrings do
            if i == 1 then
                txt = self.fontStrings[i]:GetText();
            else
                txt = txt..self.fontStrings[i]:GetText();
            end
        end
    end

    return txt
end

local function SortByOrderIndex(a, b)
    if a.orderIndex and b.orderIndex then
        return a.orderIndex < b.orderIndex;
    else
        return true
    end
end

local function CreateSwatchTexture(swatchIndex, r, g, b, offsetX, offsetY)
    if r and g and b then
        swatchIndex = swatchIndex or 1;
        offsetX = offsetX or 0;
        offsetY = offsetY or 0;
        return string.format("|TInterface\\AddOns\\Narcissus\\Art\\Modules\\BarberShop\\Swatch%d:0:0:%d:%d:16:16:0:16:0:16:%d:%d:%d|t", swatchIndex, offsetX, offsetY, r, g, b);
    else
        return "";
    end
end

local function DisplayCurrentCustomizations()
    --/run DisplayCurrentCustomizations()
    local customizationCategoryData = C_BarberShop.GetAvailableCustomizations();
    if not customizationCategoryData then
        return
    end

    local chrModelID = C_BarberShop.GetViewingChrModel();

    local playerClass;
    local playerRace = UnitRace("player");

    WidgetPool:ReleaseAll();

    local container = WidgetPool:GetContainer();
    local px = WidgetPool:GetPixel();
    local texOffsetY = -8;

    table.sort(customizationCategoryData, SortByOrderIndex);

    local numNormalCategories = 0;
    local hasShapeshiftForms;
    local hasChrModels;     --Dragonriding
    local showCategory;

    local options, choiceData;
    local optionText, choiceText, choicePlainText;
    local currentChoiceIndex;

    local plainText = playerRace;

    local optionChoiceTexts = {};
    local numCategory = 0;

    local tinsert = table.insert;

	for _, categoryData in ipairs(customizationCategoryData) do
		showCategory = not (categoryData.spellShapeshiftFormID or categoryData.chrModelID);
        --print(categoryData.spellShapeshiftFormID)
		if showCategory then
            numCategory = numCategory + 1;
            local categoryTexts = {
                leftTexts = {};
                rightTexts = {};
            };

            plainText = plainText.."\n";
			numNormalCategories = numNormalCategories + 1;

            options = categoryData.options;
            table.sort(options, SortByOrderIndex);

            for _, optionData in ipairs(options) do
                currentChoiceIndex = optionData.currentChoiceIndex or 1;
                optionText = optionData.name;
                choiceText = currentChoiceIndex;
                choicePlainText = choiceText;

                if optionData.optionType == 0 then  --popout
                    choiceData = optionData.choices and optionData.choices[currentChoiceIndex];
                    if choiceData.swatchColor1 then
                        local r, g, b = choiceData.swatchColor1:GetRGBAsBytes();
                        choiceText = currentChoiceIndex.." "..CreateSwatchTexture(1, r, g, b, 0, texOffsetY);
                        if choiceData.swatchColor2 then
                            r, g, b = choiceData.swatchColor2:GetRGBAsBytes();
                            choiceText = choiceText..""..CreateSwatchTexture(2, r, g, b, 0, texOffsetY);
                        end
                    else
                        if choiceData and choiceData.name and choiceData.name ~= "" then
                            choiceText = currentChoiceIndex.." "..choiceData.name;
                            choicePlainText = choiceText;
                        end
                    end
                elseif optionData.optionType == 1 then  --checkbox
                    if currentChoiceIndex == 2 then
                        choiceText = YES or "Yes";
                    else
                        choiceText = NONE or "None";
                    end
                    choicePlainText = choiceText;
                elseif optionData.optionType == 2 then  --Slider

                else

                end

                tinsert(categoryTexts.leftTexts, optionText);
                tinsert(categoryTexts.rightTexts, choiceText);
                --print(optionText, choiceText);

                plainText = plainText.."\n"..optionText..": "..choicePlainText;
            end
            --print(" ");

            table.insert(optionChoiceTexts, categoryTexts);
		end

        if categoryData.chrModelID then
            hasChrModels = true;
            if chrModelID == categoryData.chrModelID then
                playerClass = categoryData.name;
            end
        elseif categoryData.spellShapeshiftFormID then
            hasShapeshiftForms = true;
        end
	end


    local numOptions = #optionChoiceTexts;
    if numOptions == 0 then
        container:Hide();
        return
    end

    ----Display----
    local padding = px*SIDE_PADDING;
    local strokePixel = 2;
    local portraitTextOffset = px * (OPTION_CHOICE_GAP + strokePixel);
    local gapH = px * OPTION_CHOICE_GAP;
    local gapV = px * CATEGORY_GAP;

    local portrait = WidgetPool:GetPortrait();
    portrait:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0);
    portrait:SetSize(px*PORTRAIT_SIZE, px*PORTRAIT_SIZE);
    portrait.stroke:SetSize(px*64, px*64);

    local headerText = WidgetPool:GetFontString();
    headerText:SetJustifyH("LEFT");
    headerText:SetJustifyV("MIDDLE");
    headerText:SetPoint("LEFT", portrait, "RIGHT", portraitTextOffset, 0);

    local playerName = UnitNameUnmodified("player");

    if not playerClass then
        playerClass = UnitClass("player");
        playerClass = playerRace.." "..playerClass
    end

    SetPortraitTexture(portrait, "player");
    if not IsUnitModelReadyForUI("player") then
        C_Timer.After(0.1, function()
            SetPortraitTexture(portrait, "player");
        end);
    end

    headerText:SetText(playerName.."\n"..playerClass);
    headerText:SetTextColor(1, 1, 1);

    local headerWidth = headerText:GetWrappedWidth() + px*(OPTION_CHOICE_GAP + PORTRAIT_SIZE + strokePixel);
    local headerHeight = px*(SIDE_PADDING + PORTRAIT_SIZE + CATEGORY_GAP);

    local leftText, rightText;
    local leftFontStrings = {};
    --local rightFontStrings = {};
    local lfs, rfs;

    local maxLeftWidth = 0;
    local maxRightWidth = 0;

    for i, categoryTexts in ipairs(optionChoiceTexts) do
        leftText = nil;
        rightText = nil;

        for j, text in ipairs(categoryTexts.leftTexts) do
            if not leftText then
                leftText = text;
                rightText = categoryTexts.rightTexts[j];
            else
                leftText = leftText.."\n"..text;
                rightText = rightText.."\n"..categoryTexts.rightTexts[j];
            end
        end

        lfs = WidgetPool:GetFontString();
        lfs:SetJustifyH("RIGHT");
        lfs:SetJustifyV("TOP");
        lfs:SetText(leftText);
        lfs:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0);
        lfs:SetTextColor(0.67, 0.67, 0.67);
        leftFontStrings[i] = lfs;

        rfs = WidgetPool:GetFontString();
        rfs:SetJustifyH("LEFT");
        rfs:SetJustifyV("TOP");
        rfs:SetText(rightText);
        rfs:SetPoint("TOPLEFT", lfs, "TOPRIGHT", gapH, 0);
        rfs:SetTextColor(1, 1, 1);
        --rightFontStrings[i] = rfs;

        maxLeftWidth = math.max(maxLeftWidth, lfs:GetWrappedWidth());
        maxRightWidth = math.max(maxRightWidth, rfs:GetWrappedWidth());
    end

    local leftOffset = padding + maxLeftWidth;

    for i, lfs in ipairs(leftFontStrings) do
        lfs:ClearAllPoints();

        if i == 1 then
            lfs:SetPoint("TOPRIGHT", container, "TOPLEFT", leftOffset, -headerHeight);
        else
            lfs:SetPoint("TOPRIGHT", leftFontStrings[i - 1], "BOTTOMRIGHT", 0, -gapV);
        end
    end

    local textWidth = maxLeftWidth + maxRightWidth + gapH;
    local textHeight = leftFontStrings[1]:GetTop() - leftFontStrings[#leftFontStrings]:GetBottom();

    local fullWidth = math.max(headerWidth, textWidth) + 2*padding;
    local fullHeight = headerHeight + textHeight + padding;

    fullWidth = GetBestSizeForPixel(fullWidth, px);
    fullHeight = GetBestSizeForPixel(fullHeight, px);

    container:SetSize(fullWidth, fullHeight);

    local portraitOffset = GetBestSizeForPixel(0.5*(fullWidth - headerWidth), px);
    portrait:ClearAllPoints();
    portrait:SetPoint("TOPLEFT", container, "TOPLEFT", portraitOffset, -padding);

    container:Show();
    container.appearancePlainText = plainText;
end

API.ShowAppearanceList = DisplayCurrentCustomizations;
API.HideAppearanceList = WidgetPool.HideContainer;