local _, addon = ...

local L = Narci.L;
local Round = addon.Math.Round;
local GetItemQualityColor = NarciAPI.GetItemQualityColor;

local UIParent = UIParent;

local TooltipFrame = CreateFrame("Frame");
addon.UIFrameTooltip = TooltipFrame;

TooltipFrame:Hide();
TooltipFrame:SetSize(16, 16);
TooltipFrame:SetIgnoreParentScale(true);
TooltipFrame:SetIgnoreParentAlpha(true);
TooltipFrame:SetFrameStrata("TOOLTIP");
TooltipFrame:SetFixedFrameStrata(true);
TooltipFrame:SetClampedToScreen(true);
TooltipFrame:SetClampRectInsets(-4, 4, 4, -4);

NarciFadeUI.CreateFadeObject(TooltipFrame);

TooltipFrame.ShowFrame = TooltipFrame.Show;
TooltipFrame.HideFrame = TooltipFrame.Hide;

local LINE_TYPE_PRICE = Enum.TooltipDataLineType.SellPrice or 11;

local FONT_LARGE = "GameTooltipHeaderText";
local FONT_MEDIUM = "GameTooltipText";
local FONT_SMALL = "GameTooltipTextSmall";
local FONT_HEIGHT_MEDIUM = 12;
local FONTSTRING_MIN_GAP = 24;  --Betweeb the left and the right text of the same line
local SELL_PRICE_TEXT = (SELL_PRICE or "Sell Price").."  ";

do
    local _;
    _, FONT_HEIGHT_MEDIUM = _G[FONT_MEDIUM]:GetFont();
    FONT_HEIGHT_MEDIUM = Round(FONT_HEIGHT_MEDIUM);
end

local SPACING_NEW_LINE = 4;     --Between paragraphs
local SPACING_INTERNAL = 2;     --Within the same paragraph
local TOOLTIP_PADDING = 8;
local TOOLTIP_MAX_WIDTH = 320;
local FONTSTRING_MAX_WIDTH = TOOLTIP_MAX_WIDTH - 2*TOOLTIP_PADDING;


local C_TooltipInfo = C_TooltipInfo;
local unpack = unpack;
local pairs = pairs;
local floor = math.floor;


local function DisableSharpening(texture)
    texture:SetTexelSnappingBias(0);
    texture:SetSnapToPixelGrid(false);
end

local function EvaluateWidth(fontString, lastMax)
    local width = fontString:GetWrappedWidth();
    return ((width > lastMax) and width) or lastMax
end

function TooltipFrame:Init()
    if not self.Background then
        local texture = self:CreateTexture(nil, "BACKGROUND", nil, -1);
        self.Background = texture;
        texture:SetTexture("Interface/AddOns/Narcissus/Art/Tooltip/TooltipDefaultDarkLayout");
        DisableSharpening(texture);
        texture:SetTextureSliceMode(0); --Enum.UITextureSliceMode, 0 Stretched(Default)  1 Tiled
        texture:SetTextureSliceMargins(16, 16, 16, 16);
        texture:SetAllPoints(true);
    end

    if not self.Content then
        self.Content = CreateFrame("Frame", nil, self);
        self.Content:SetPoint("TOPLEFT", self, "TOPLEFT", TOOLTIP_PADDING, -TOOLTIP_PADDING);
        self.Content:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -TOOLTIP_PADDING, TOOLTIP_PADDING);
    end

    if not self.fontStrings then
        self.fontStrings = {};
    end

    --[[
    if not self.HotkeyIcon then
        self.HotkeyIcon = addon.CreateHotkeyIcon(self);
        local responsive = true;
        self.HotkeyIcon:SetKey("Alt", responsive);
        self.HotkeyIcon:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2);
        self.HotkeyIcon:Hide();
    end
    --]]

    self.Init = nil;
end

function TooltipFrame:UpdatePixel(scale)
    scale = scale or self:GetEffectiveScale();
    if scale ~= self.effectiveScale then
        self.effectiveScale = scale;
        local _, screenHeight = GetPhysicalScreenSize();    --Assume players don't change screen resolution (triggers DISPLAY_SIZE_CHANGED)
        local px = (768/screenHeight)/scale;
        local offset = 4*px;
        self.Background:ClearAllPoints();
        self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset);
        self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset);
    end
end

function TooltipFrame:ClearLines()
    if self.numLines == 0 then return end;

    self.numLines = 0;
    self.numCols = 1;
    self.numFontStrings = 0;
    self.dataInstanceID = nil;
    self.fontChanged = false;
    self.grid = {};
    self.useGridLayout = false;

    if self.fontStrings then
        for _, fontString in pairs(self.fontStrings) do
            fontString:Hide();
            fontString:SetText(nil);
        end
    end

    self:SetAlternateTooltipFunc(nil);
end

function TooltipFrame:SetOwner(owner, anchor, offsetX, offsetY)
    if self.Init then
        self:Init();
    end

    self.owner = owner;
    anchor = anchor or "ANCHOR_BOTTOM";
    offsetX = offsetX or 0;
    offsetY = offsetY or 0;

    self:ClearAllPoints();
    self:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", offsetX, offsetY);
end

function TooltipFrame:SetLineFont(fontString, sizeIndex)
    if fontString.sizeIndex ~= sizeIndex then
        fontString.sizeIndex = sizeIndex;
        if sizeIndex == 1 then
            fontString:SetFontObject(FONT_LARGE);
        elseif sizeIndex == 2 then
            fontString:SetFontObject(FONT_MEDIUM);
        elseif sizeIndex == 3 then
            fontString:SetFontObject(FONT_SMALL);
        end
        return true
    end
end

function TooltipFrame:SetLineAlignment(fontString, alignIndex)
    if fontString.alignIndex ~= alignIndex then
        fontString.alignIndex = alignIndex;
        if alignIndex == 1 then
            fontString:SetJustifyH("LEFT");
        elseif alignIndex == 2 then
            fontString:SetJustifyH("CENTER");
        elseif alignIndex == 3 then
            fontString:SetJustifyH("RIGHT");
        end
        return true
    end
end

function TooltipFrame:AcquireFontString()
    local n = self.numFontStrings + 1;
    self.numFontStrings = n;

    if not self.fontStrings[n] then
        self.fontStrings[n] = self.Content:CreateFontString(nil, "ARTWORK", FONT_MEDIUM);
        self.fontStrings[n]:SetSpacing(SPACING_INTERNAL);
        self.fontStrings[n].sizeIndex = 2;
        self.fontStrings[n].alignIndex = 1;
        self.fontStrings[n]:SetJustifyV("MIDDLE");
    end

    return self.fontStrings[n]
end

function TooltipFrame:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex)
    r = r or 1;
    g = g or 1;
    b = b or 1;
    wrapText = (wrapText == true) or false;
    offsetY = offsetY or -SPACING_NEW_LINE;
    sizeIndex = sizeIndex or 2;
    alignIndex = alignIndex or 1;

    local fs = self:AcquireFontString();

    local fontChanged = self:SetLineFont(fs, sizeIndex);
    if fontChanged then
        self.fontChanged = true;
    end
    self:SetLineAlignment(fs, alignIndex);

    fs:ClearAllPoints();
    fs:SetPoint("TOPLEFT", self.Content, "TOPLEFT", 0, 0);

    fs:SetWidth(FONTSTRING_MAX_WIDTH);
    fs:SetText(text);
    fs:SetTextColor(r, g, b, 1);
    fs:Show();
    fs.inGrid = nil;

    return fs
end

function TooltipFrame:SetGridLine(row, col, text, r, g, b, sizeIndex, alignIndex)
    if not text then return end

    if self.grid[row] and self.grid[row][col] then
        self.grid[row][col]:SetText("(Occupied)")
        return
    end

    local fs = self:AddText(text, r, g, b, nil, nil, sizeIndex, alignIndex);
    fs.inGrid = true;

    if not self.grid[row] then
        self.grid[row] = {};
    end
    self.grid[row][col] = fs;

    if row > self.numLines then
        self.numLines = row;
    end

    if col > self.numCols then
        self.numCols = col;
    end

    self.useGridLayout = true;
end

function TooltipFrame:AddLeftLine(text, r, g, b, wrapText, offsetY, sizeIndex)
    --This will start a new line

    if not text then return end
    local n = self.numLines + 1;
    self.numLines = n;

    local alignIndex = 1;
    local fs = self:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex);

    if not self.grid[n] then
        self.grid[n] = {};
    end
    self.grid[n][1] = fs;
end

function TooltipFrame:AddCenterLine(text, r, g, b, wrapText, offsetY, sizeIndex)
    --This will also start a new line
    --Align to the center

    if not text then return end
    local n = self.numLines + 1;
    self.numLines = n;

    local alignIndex = 2;
    local fs = self:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex);

    if not self.grid[n] then
        self.grid[n] = {};
    end
    self.grid[n][1] = fs;
end

function TooltipFrame:AddRightLine(text, r, g, b, wrapText, offsetY, sizeIndex)
    --Right line must come in pairs with a LeftLine
    --This will NOT start a new line

    if not text then return end
    local alignIndex = 3;
    local fs = self:AddText(text, r, g, b, wrapText, offsetY, sizeIndex, alignIndex);
    local n = self.numLines;

    if not self.grid[n] then
        self.grid[n] = {};
    end
    self.grid[n][2] = fs;

    self.numCols = 2;
end

function TooltipFrame:AddBlankLine()
    local n = self.numLines + 1;
    self.numLines = n;
    self.grid[n] = {
        gap = SPACING_NEW_LINE,
    };
end

function TooltipFrame:ProcessInfo(info)
    self.lastInfo = info;

    if not info then
		return false
	end

    local tooltipData;
    if info.getterArgs then
        tooltipData = C_TooltipInfo[info.getterName](unpack(info.getterArgs));
    else
        tooltipData = C_TooltipInfo[info.getterName]();
    end

    self:ClearLines();
    self:SetScript("OnUpdate", nil);

    local success = self:ProcessTooltipData(tooltipData);

    if success then
        self:Show();
    else
        self:Hide();
    end
end

local OVERRIDE_COLORS = {
    ["ffa335ee"] = 4,
    ["ff0070dd"] = 3,
};

local function GenerateMoneyText(rawCopper)
    --Price
    local text;
	local gold = floor(rawCopper / 10000);
	local silver = floor((rawCopper - gold * 10000) / 100);
	local copper = floor(rawCopper - gold * 10000 - silver * 100);
    local iconOffsetX = 2;

    local goldText, silverText, copperText;

    if copper > 0 then
        copperText = string.format("%s|TInterface/AddOns/Narcissus/Art/Tooltip/Coins:0:0:%s:-%s:128:32:0:32:0:32|t", copper, iconOffsetX, SPACING_INTERNAL);
        text = copperText;
    end

    if gold ~= 0 or silver ~= 0 then
        silverText = string.format("%s|TInterface/AddOns/Narcissus/Art/Tooltip/Coins:0:0:%s:-%s:128:32:32:64:0:32|t", silver, iconOffsetX, SPACING_INTERNAL);
        if gold > 0 then
            goldText = string.format("%s|TInterface/AddOns/Narcissus/Art/Tooltip/Coins:0:0:%s:-%s:128:32:64:96:0:32|t", gold, iconOffsetX, SPACING_INTERNAL);
            if text then
                text = goldText.." "..silverText.." "..text;
            elseif silver == 0 then
                text = goldText;
            else
                text = goldText.." "..silverText;
            end
        else
            if text then
                text = silverText.." "..text;
            else
                text = silverText;
            end
        end
    end

    return text
end

function TooltipFrame:ProcessTooltipData(tooltipData)
    if not (tooltipData and tooltipData.lines) then
        return false
    end

    self.dataInstanceID = tooltipData.dataInstanceID;
    self:RegisterEvent("TOOLTIP_DATA_UPDATE");

    local leftText, leftColor, wrapText, rightText, leftOffset;
    local r, g, b;

    for i, lineData in ipairs(tooltipData.lines) do
        leftText = lineData.leftText;
        leftColor = lineData.leftColor or NORMAL_FONT_COLOR;
        rightText = lineData.rightText;
        wrapText = lineData.wrapText or false;
        leftOffset = lineData.leftOffset;

        if leftText then
            if leftText == " "then
                --A whole blank line is too tall, so we change its height
                self:AddBlankLine();
            else
                if i == 1 then
                    local hex = leftColor:GenerateHexColor();
                    if OVERRIDE_COLORS[hex] then
                        leftColor = GetItemQualityColor( OVERRIDE_COLORS[hex] );
                    end
                end

                if lineData.type ~= LINE_TYPE_PRICE then
                    r, g, b = leftColor:GetRGB();
                    self:AddLeftLine(leftText, r, g, b, wrapText, nil, (i == 1 and 1) or 2);
                elseif lineData.price and lineData.price > 0 then
                    local cointText = GenerateMoneyText(lineData.price);
                    if cointText then
                        leftText = SELL_PRICE_TEXT .. cointText;
                        --self:AddBlankLine();
                        self:AddLeftLine(leftText, 1, 1, 1, false, nil, 2);
                    end
                end
            end
        end
	end

    return true
end

function TooltipFrame:Layout()
    local textWidth, textHeight, lineWidth;
    local totalHeight = 0;
    local maxLineWidth = 0;
    local maxLineHeight = 0;
    local grid = self.grid;
    local fs;
    local ref = self.Content;

    local colMaxWidths, rowOffsetYs;
    local numCols = self.numCols;
    local useGridLayout = self.useGridLayout;
    if useGridLayout then
        colMaxWidths = {};
        rowOffsetYs = {};
        for i = 1, numCols do
            colMaxWidths[i] = 0;
        end
    end

    for row = 1, self.numLines do
        if grid[row] then
            lineWidth = 0;
            maxLineHeight = 0;
            if grid[row].gap then
                --Positive value increase the distance between lines
                totalHeight = totalHeight + grid[row].gap;
            end
            for col = 1, numCols do
                fs = grid[row][col];
                if fs then
                    textWidth = fs:GetWrappedWidth();
                    textHeight = fs:GetHeight();

                    if col == 1 then
                        lineWidth = textWidth;
                    else
                        lineWidth = lineWidth + FONTSTRING_MIN_GAP + textWidth;
                    end

                    if lineWidth > maxLineWidth then
                        maxLineWidth = lineWidth;
                    end

                    if textHeight > maxLineHeight then
                        maxLineHeight = textHeight;
                    end

                    if useGridLayout and textWidth > colMaxWidths[col] and fs.inGrid then
                        colMaxWidths[col] = textWidth;
                    end
                end
            end

            if row ~= 1 then
                totalHeight = totalHeight + SPACING_NEW_LINE;
            end
            totalHeight = Round(totalHeight);

            if useGridLayout then
                rowOffsetYs[row] = -totalHeight;
            else
                for col = 1, numCols do
                    fs = grid[row][col];
                    if fs then
                        fs:ClearAllPoints();
                        if fs.alignIndex == 2 then
                            fs:SetPoint("TOP", ref, "TOP", 0, -totalHeight);
                        elseif fs.alignIndex == 3 then
                            fs:SetPoint("TOPRIGHT", ref, "TOPRIGHT", 0, -totalHeight);
                        else
                            fs:SetPoint("TOPLEFT", ref, "TOPLEFT", 0, -totalHeight);
                        end
                    end
                end
            end

            totalHeight = totalHeight + maxLineHeight;
            totalHeight = Round(totalHeight);
        end
    end

    if useGridLayout then
        local offsetX, offsetY;
        for row = 1, self.numLines do
            offsetX = 0;
            offsetY = rowOffsetYs[row];
            for col = 1, numCols do
                fs = grid[row][col];
                textWidth = colMaxWidths[col] + 1;
                if fs then
                    fs:ClearAllPoints();
                    if fs.alignIndex == 2 then
                        if fs.inGrid then
                            fs:SetPoint("TOPLEFT", ref, "TOPLEFT", offsetX, offsetY);
                            fs:SetWidth(textWidth);
                        else
                            fs:SetPoint("TOP", ref, "TOP", offsetX, offsetY);
                        end
                    elseif fs.alignIndex == 3 then
                        if col == numCols then
                            fs:SetPoint("TOPRIGHT", ref, "TOPRIGHT", 0, offsetY);
                        else
                            fs:SetPoint("TOPLEFT", ref, "TOPLEFT", offsetX, offsetY);
                            fs:SetWidth(textWidth);
                        end
                    else
                        fs:SetPoint("TOPLEFT", ref, "TOPLEFT", offsetX, offsetY);
                    end
                end

                offsetX = offsetX + colMaxWidths[col] + FONTSTRING_MIN_GAP;
            end
        end

        maxLineWidth = 0;
        for col = 1, numCols do
            maxLineWidth = maxLineWidth + colMaxWidths[col];
            if col > 1 then
                maxLineWidth = maxLineWidth + FONTSTRING_MIN_GAP;
            end
        end
    end

    local fullWidth = Round(maxLineWidth) + 2*TOOLTIP_PADDING;
    local fullHeight = Round(totalHeight) + 2*TOOLTIP_PADDING;
    self:SetSize(fullWidth, fullHeight);
end

local function SharedTooltip_OnUpdate_Layout(self, elapsed)
    self:SetScript("OnUpdate", nil);
    self:Layout();
end

function TooltipFrame:LayoutNextUpdate()
    self:SetScript("OnUpdate", SharedTooltip_OnUpdate_Layout);
end

function TooltipFrame:Show()
    if self.fontChanged or self.useGridLayout then
        --fontString width will take one frame to change
        self:LayoutNextUpdate();
    else
        self:Layout();
    end

    self:ShowFrame();

    local scale = UIParent:GetEffectiveScale();
    self:SetScale(scale);
    self:UpdatePixel(scale);
end

function TooltipFrame:Hide()
    self:HideFrame();
    self:ClearAllPoints();
    self:SetScript("OnUpdate", nil);
    self:ClearLines();
end

local function SharedTooltip_OnModifierStateChanged(key, down)
    --Show extra/alternate info when ALT pressed
    if key == "LALT" or key == "RALT" then
        if down == 1 then
            local newMode = not TooltipFrame.alternateMode;
            TooltipFrame.alternateMode = newMode;
            if TooltipFrame.alternateTooltipFunc then
                TooltipFrame.alternateTooltipFunc(TooltipFrame, newMode);
            end
        end
    end
end

function TooltipFrame:OnEvent(event, ...)
	if event == "TOOLTIP_DATA_UPDATE" then
		local dataInstanceID = ...
		if dataInstanceID and dataInstanceID == self.dataInstanceID then
			self:ProcessInfo(self.lastInfo);
		end
    elseif event == "MODIFIER_STATE_CHANGED" then
        SharedTooltip_OnModifierStateChanged(...)
	end
end

TooltipFrame:SetScript("OnEvent", TooltipFrame.OnEvent);

TooltipFrame:SetScript("OnHide", function(self)
    self:UnregisterEvent("TOOLTIP_DATA_UPDATE");
    self:UnregisterEvent("MODIFIER_STATE_CHANGED");
    self.lastInfo = nil;
end);


function TooltipFrame:SetAlternateTooltipFunc(setupFunc)
    TooltipFrame.alternateTooltipFunc = setupFunc;
    if setupFunc then
        self:RegisterEvent("MODIFIER_STATE_CHANGED");
    else
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
    end
end


do
    --Emulate the default GameTooltip
    --Code from Interface/SharedXML/Tooltip/TooltipDataHandler.lua

    local function AddTooltipDataAccessor(handler, accessor, getterName)
        handler[accessor] = function(self, ...)
            local tooltipInfo = {
                getterName = getterName,
                getterArgs = { ... };
            };
            return self:ProcessInfo(tooltipInfo);
        end
    end


    local accessors = {
        SetItemByID = "GetItemByID",
        SetCurrencyByID = "GetCurrencyByID",
    };

    local handler = TooltipFrame;
    for accessor, getterName in pairs(accessors) do
		AddTooltipDataAccessor(handler, accessor, getterName);
	end

    function TooltipFrame:SetText(text, r, g, b, wrapText)
        self:AddLeftLine(text, r, g, b, wrapText);
    end

    function TooltipFrame:AddLine(text, r, g, b, wrapText)
        self:AddLeftLine(text, r, g, b, wrapText);
    end

    function TooltipFrame:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB)
        self:AddLeftLine(leftText, leftR, leftG, leftB, false);
        self:AddRightLine(rightText, rightR, rightG, rightB, false);
    end
end