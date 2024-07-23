local _, addon = ...;

local L = Narci.L;
local FloatingCard = addon.FloatingCard;

local DIYContainer, EditorContainer, DIYCards, NewEntryButton;
local SelectedCard;

local EDIT_FRAME_HEADER_HEIGHT = 34;

--Functions
local ReskinButton = addon.ReskinButton;
local IsDarkTheme = addon.IsDarkTheme;

local After = C_Timer.After;
local floor = math.floor;
local ceil = math.ceil;
local strtrim = strtrim;
local gsub = string.gsub;
local upper = string.upper;
local cos = math.cos;
local pi = math.pi;

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end

local function GetTextureName(texture)
    local name = texture:GetTexture();
    if type(name) == "string" then
        name = gsub(name, "INTERFACE\\ICONS\\", "");
    end
    return name
end

local function UpperFirstLetter(str)
    str = strtrim(str);
    str = gsub(str, "^%l", upper);
    return (str:gsub("%s%l", upper))
end

local function GetToday()
    local time = C_DateAndTime.GetCurrentCalendarTime();
    local year = string.sub(time.year, -2, -1);
    return FormatShortDate(time.monthDay, time.month, year);
end

----------------------------------
local DataProvider = {};

function DataProvider:AddEntry(name, description, icon, points, date, rewardText, isAccountWide)
    icon = icon or 134400;
    if points and type(points) ~= "number" then
        points = 0;
    end

    local entry = {name = name, description = description, icon = icon, points = points, date = date, rewardText = rewardText, isAccountWide = isAccountWide};
    local index = #self.data;
    tinsert(self.data, entry);

    return entry, index + 1
end

function DataProvider:UpdateEntry(index, name, description, icon, points, date, rewardText, isAccountWide)
    icon = icon or 134400;
    if points and type(points) ~= "number" then
        points = 0;
    end
    if self.data[index] then
        self.data[index] = {name = name, description = description, icon = icon, points = points, date = date, rewardText = rewardText, isAccountWide = isAccountWide};
        return true
    else
        return false
    end
end

function DataProvider:ModifyField(index, key, value)
    if index and self.data[index] then
        self.data[index][key] = value;
    end
end

function DataProvider:RemoveEntry(index)
    if table.remove(self.data, index) then
        return true
    else
        return false
    end
end

function DataProvider:GetEntry(index)
    return self.data[index]
end

function DataProvider:GetNumEntries()
    return #self.data;
end

---------------------------------------------------------------------
local DEFAULT_HEADER = L["Custom Achievement"];
local DEFAULT_DESCRIPTION = L["Custom Achievement Description"];
local needConfirmation = false;

local function DarkenCard(card, darken, forcedUpdate)
    if not darken then
        card:SetAlpha(1);
        card.RewardFrame.reward:SetAlpha(1);
        
        if ((card.isDark == nil) or (card.isDark)) or (forcedUpdate) then
            if not forcedUpdate then card.isDark = false; end;
            
            card.icon:SetDesaturated(false);
            card.points:SetTextColor(0.8, 0.8, 0.8);
            if card.isDarkTheme then
                card.description:SetTextColor(0.8, 0.8, 0.8);
                if card.accountWide then
                    card.header:SetTextColor(0.427, 0.812, 0.965);
                    card.headerLong:SetTextColor(0.427, 0.812, 0.965);
                else
                    card.header:SetTextColor(0.9, 0.82, 0.58);
                    card.headerLong:SetTextColor(0.9, 0.82, 0.58);
                end
            else
                card.description:SetTextColor(0, 0, 0);
                card.header:SetTextColor(1, 1, 1);
                card.headerLong:SetTextColor(1, 1, 1);
            end
            card.icon:SetVertexColor(1, 1, 1);
            card.lion:SetVertexColor(1, 1, 1);
            card.border:SetVertexColor(1, 1, 1);
            card.background:SetVertexColor(1, 1, 1);
            card.bottom:SetVertexColor(1, 1, 1);
        end
    else
        card:SetAlpha(0.8);
        card.RewardFrame.reward:SetAlpha(0.60);

        if (card.isDark == nil) or (not card.isDark) then
            if not forcedUpdate then card.isDark = true; end;

            card.icon:SetDesaturated(true);
            card.points:SetTextColor(0.6, 0.6, 0.6);
            if card.isDarkTheme then
                card.description:SetTextColor(0.6, 0.6, 0.6);
                if card.accountWide then
                    card.header:SetTextColor(0.214, 0.406, 0.484);
                    card.headerLong:SetTextColor(0.214, 0.406, 0.484);
                else
                    card.header:SetTextColor(0.5, 0.46, 0.324);
                    card.headerLong:SetTextColor(0.5, 0.46, 0.324);
                end
            else
                card.description:SetTextColor(0, 0, 0);
                card.header:SetTextColor(0.5, 0.5, 0.5);
                card.headerLong:SetTextColor(0.5, 0.5, 0.5);
            end
            card.icon:SetVertexColor(0.60, 0.60, 0.60);
            card.lion:SetVertexColor(0.60, 0.60, 0.60);
            card.border:SetVertexColor(0.60, 0.60, 0.60);
            card.background:SetVertexColor(0.8, 0.8, 0.8);
            card.bottom:SetVertexColor(0.8, 0.8, 0.8);
        end
    end
end

local function HighlightCard(card)
    DarkenCard(card, false);
    local index = card.index;

    for i = 1, (index - 1) do
        DarkenCard(DIYCards[i], true);
    end
    for i = (index + 1), #DIYCards do
        DarkenCard(DIYCards[i], true);
    end
end

local function NeedConfirmation()
    if needConfirmation then
        DIYContainer.Editor.SaveButton.animError:Play();
        DIYContainer.Editor.CancelButton.animError:Play();
        return true
    else
        return false
    end
end

local function UpdateEditorScrollRange()
    local scrollBar = EditorContainer.scrollBar;
    local range;
    range = math.max(0, EditorContainer.ColorPicker:GetTop() -  EditorContainer.RemoveButton:GetBottom() - EditorContainer:GetHeight() + 60);

    scrollBar:SetMinMaxValues(0, range);
    EditorContainer.range = range;
    scrollBar:SetShown(range ~= 0);
end

local function HideEditor()
    if NeedConfirmation() then return end;
    
    DIYContainer.Editor:Hide();
    DIYContainer.Editor.removeMark:Hide();
    EditorContainer.ScrollChild:Hide();
    EditorContainer.notes:Show();

    for i = 1, #DIYCards do
        DarkenCard( DIYCards[i] , false);
    end
    SelectedCard = nil;

    UpdateEditorScrollRange();
end

local function ReAnchorEditor(card)
    if NeedConfirmation() then return end;

    if card == SelectedCard then
        HideEditor();
        return
    end
    
    SelectedCard = card;
    HighlightCard(card);
    EditorContainer.scrollBar:SetValue(0);

    local IconPicker = EditorContainer.IconPicker;
    local oldTexture = card.icon:GetTexture();
    IconPicker.oldTexture = oldTexture 
    IconPicker.CurrentIcon.icon:SetTexture(oldTexture);
    local iconName = GetTextureName(card.icon);
    IconPicker.iconName:SetText(iconName);
    IconPicker.IconContainer.iconName:SetText(iconName);

    EditorContainer.ColorPicker:SelectIcon(card.accountWide);
    EditorContainer.HeaderEditor.EditBox:SetText(card.header:GetText() or "");
    EditorContainer.DescriptionEditor.EditBox:SetText(card.description:GetText() or "");
    EditorContainer.PointsEditor.EditBox:SetText(card.points:GetText() or 0);
    EditorContainer.RewardEditor.EditBox:SetText(card.RewardFrame.reward:GetText() or "");
    EditorContainer.DateEditor.EditBox:SetText(card.date:GetText() or "");
    
    --------------------------------------
    local Editor = DIYContainer.Editor;
    Editor:ClearAllPoints();
    Editor:SetPoint("CENTER", card, "CENTER", 0, 0);
    Editor.IconArea:ClearAllPoints();
    Editor.IconArea:SetPoint("CENTER", card.icon, "CENTER", 0, 0);
    Editor.NameArea:ClearAllPoints();
    Editor.NameArea:SetPoint("CENTER", card.header, "CENTER", 0, 0);
    Editor.DescriptionArea:ClearAllPoints();
    Editor.DescriptionArea:SetPoint("TOP", card.description, "TOP", 0, 0);
    Editor.DescriptionArea:SetPoint("BOTTOM", card.description, "BOTTOM", 0, 0);
    Editor.RewardArea:ClearAllPoints();
    Editor.RewardArea:SetPoint("CENTER", card.RewardFrame.reward, "CENTER", 0, 0);
    Editor.PointsArea:ClearAllPoints();
    Editor.PointsArea:SetPoint("CENTER", card.points, "CENTER", 0, 0);
    Editor.DateArea:ClearAllPoints();
    Editor.DateArea:SetPoint("LEFT", card.date, "LEFT", -2, 0);
    Editor.DateArea:SetPoint("RIGHT", card.date, "RIGHT", 2, 0);

    Editor.SaveButton:ClearAllPoints();
    Editor.SaveButton:SetPoint("TOPRIGHT", card, "BOTTOM", -8, -4);
    Editor.CancelButton:ClearAllPoints();
    Editor.CancelButton:SetPoint("TOPLEFT", card, "BOTTOM", 8, -4);

    Editor:SetFrameLevel(10);
    Editor:Show();
    EditorContainer.ScrollChild:Show();
    EditorContainer.notes:Hide();

    UpdateEditorScrollRange();
end

local function Card_OnClick(self, button)
    if button == "LeftButton" then
        ReAnchorEditor(self);
    end
end

local function ModifyCardDescription(button, description, rewardText)
    local rewardHeight;
    local shadowHeight = 0;
    description = description or button.description:GetText();
    rewardText = rewardText or button.RewardFrame.reward:GetText();
    local isDarkTheme = button.isDarkTheme;
    if rewardText and rewardText ~= "" then
        rewardHeight = 24;
        shadowHeight = 6;
        if isDarkTheme then
            button.RewardFrame.reward:SetTextColor(0.64, 0.83, 0.61);
        else
            button.RewardFrame.reward:SetTextColor(1, 0.82, 0);
        end
        button.RewardFrame.reward:SetText(rewardText);
        button.RewardFrame:Show();
    else
        if isDarkTheme then
            rewardHeight = 2;
        else
            rewardHeight = 8;
        end
        button.RewardFrame:Hide();
        button.RewardFrame:SetHeight(2);
    end
    button.RewardFrame:SetHeight(rewardHeight);
    button.description:SetText(description);
    textHeight = floor( button.background:GetHeight() + 0.5 );

    local descriptionHeight = button.description:GetHeight();
    numLines = ceil( descriptionHeight / 14 - 0.1 );
    button:SetHeight(72 + rewardHeight + 14*(numLines - 1) );
    button.shadow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 12, - 6 - numLines * 6 - shadowHeight);

    if button.accountWide then
        if textHeight <= 288 then
            button.background:SetTexCoord(0.05078125, 0.94921875, 0.985 - textHeight/288/2, 0.985);
        else
            button.background:SetTexCoord(0.05078125, 0.94921875,  0.5, 1);
        end
    else
        if textHeight <= 288 then
            button.background:SetTexCoord(0.05078125, 0.94921875, 0.485 - textHeight/288/2, 0.485);
        else
            button.background:SetTexCoord(0.05078125, 0.94921875,  0, 0.485);
        end
    end
end

local function ModifyCardColor(button, isAccountWide)
    local textHeight = floor( button.background:GetHeight() + 0.5 );
    local isDarkTheme = button.isDarkTheme;

    if isAccountWide then
        button.accountWide = true;
        button.border:SetTexCoord(0.05078125, 0.94921875, 0.5, 1);
        button.bottom:SetTexCoord(0.05078125, 0.94921875, 0.985, 1);
        
        if textHeight <= 288 then
            button.background:SetTexCoord(0.05078125, 0.94921875, 0.985 - textHeight/288/2, 0.985);
        else
            button.background:SetTexCoord(0.05078125, 0.94921875,  0.5, 1);
        end
        if isDarkTheme then
            button.header:SetTextColor(0.427, 0.812, 0.965);
            button.headerLong:SetTextColor(0.427, 0.812, 0.965);
        else
            button.header:SetTextColor(1, 1, 1);
            button.headerLong:SetTextColor(1, 1, 1);
        end
    else
        button.accountWide = nil;
        button.border:SetTexCoord(0.05078125, 0.94921875, 0, 0.5);
        button.bottom:SetTexCoord(0.05078125, 0.94921875, 0.485, 0.5);

        if textHeight <= 288 then
            button.background:SetTexCoord(0.05078125, 0.94921875, 0.485 - textHeight/288/2, 0.485);
        else
            button.background:SetTexCoord(0.05078125, 0.94921875,  0, 0.485);
        end
        if isDarkTheme then
            button.header:SetTextColor(0.9, 0.82, 0.58);
            button.headerLong:SetTextColor(0.9, 0.82, 0.58);
        else
            button.header:SetTextColor(1, 1, 1);
            button.headerLong:SetTextColor(1, 1, 1);
        end
    end
end

local FormatCardByIndex;

local function CreateCustomFloatingCard(self)
    if NeedConfirmation() then return end;

    local index = self.index;
    local entry = DataProvider:GetEntry(index);
    if not entry then return end;

    self.AnimPushed:Stop();
    self:Hide();
    FloatingCard.parentCard = self;

    local card = FloatingCard:CreateFromCard(self);
    card.isDarkTheme = self.isDarkTheme;
    ReskinButton(card);
    FormatCardByIndex(card, entry.name, entry.description, entry.icon, entry.points, entry.date, entry.rewardText, entry.isAccountWide);
end

local function Card_OnDragStop(self)
    self.AnimPushed.hold:SetDuration(0);
end

function FormatCardByIndex(buttonIndex, name, description, icon, points, date, rewardText, isAccountWide)
    local headerObject, numLines, textHeight;
    local button;
    if type(buttonIndex) == "number" then
        button = DIYCards[buttonIndex];
    else
        button = buttonIndex;
    end

    if not button then
        button = CreateFrame("Button", nil, DIYContainer.ScrollChild, "NarciAchievementLargeCardTemplate");
        button:SetScript("OnDragStart", CreateCustomFloatingCard);
        button:SetScript("OnDragStop", Card_OnDragStop);

        if buttonIndex == 1 then
            button:SetPoint("TOP", DIYContainer.ScrollChild, "TOP", 0, -18);
        else
            button:SetPoint("TOP", DIYCards[buttonIndex - 1], "BOTTOM", 0, -4);
        end
        tinsert(DIYCards, button);
        button.index = buttonIndex;
        ReskinButton(button);
        button:SetScript("OnClick", Card_OnClick);
    end

    --for long text
    button.header:SetText(name);
    if button.header:IsTruncated() then
        headerObject = button.headerLong;
        headerObject:SetText(name);
        button.header:Hide();
    else
        headerObject = button.header;
        button.headerLong:Hide();
    end
    headerObject:Show();

    local isDarkTheme = button.isDarkTheme;

    if not points or points == 0 then
        button.points:SetText("");
        button.lion:Show();
    else
        if points > 100 then
            if not button.useSmallPoints then
                button.useSmallPoints = true;
                button.points:SetFontObject(NarciAchievemtPointsSmall);
            end
        else
            if button.useSmallPoints then
                button.useSmallPoints = nil;
                button.points:SetFontObject(NarciAchievemtPoints);
            end
        end
        button.points:SetText(points);
        button.lion:Hide();
    end

    button.icon:SetTexture(icon);
    button.date:SetText(date);

    local rewardHeight;
    local shadowHeight = 0;
    if rewardText and rewardText ~= "" then
        rewardHeight = 22;
        shadowHeight = 6;
        if isDarkTheme then
            button.RewardFrame.reward:SetTextColor(0.64, 0.83, 0.61);
        else
            button.RewardFrame.reward:SetTextColor(1, 0.82, 0);
        end
        button.RewardFrame.reward:SetText(rewardText);
        button.RewardFrame:Show();
    else
        if isDarkTheme then
            rewardHeight = 2;
        else
            rewardHeight = 8;
        end
        button.RewardFrame:Hide();
        button.RewardFrame:SetHeight(2);
    end
    button.RewardFrame:SetHeight(rewardHeight);
    button.description:SetText(description);
    textHeight = floor( button.background:GetHeight() + 0.5 );

    local descriptionHeight = button.description:GetHeight();
    numLines = ceil( descriptionHeight / 14 - 0.1 );
    button:SetHeight(72 + rewardHeight + 14*(numLines - 1) );
    button.shadow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 12, - 6 - numLines * 6 - shadowHeight);

    if isAccountWide then
        if button.accountWide ~= true then
            button.accountWide = true;
            button.border:SetTexCoord(0.05078125, 0.94921875, 0.5, 1);
            button.bottom:SetTexCoord(0.05078125, 0.94921875, 0.985, 1);
        end
        if textHeight <= 288 then
            button.background:SetTexCoord(0.05078125, 0.94921875, 0.985 - textHeight/288/2, 0.985);
        else
            button.background:SetTexCoord(0.05078125, 0.94921875,  0.5, 1);
        end
        if isDarkTheme then
            button.header:SetTextColor(0.427, 0.812, 0.965);
            button.headerLong:SetTextColor(0.427, 0.812, 0.965);
        else
            button.header:SetTextColor(1, 1, 1);
            button.headerLong:SetTextColor(1, 1, 1);
        end
    else
        if button.accountWide then
            button.accountWide = nil;
            button.border:SetTexCoord(0.05078125, 0.94921875, 0, 0.5);
            button.bottom:SetTexCoord(0.05078125, 0.94921875, 0.485, 0.5);
        end
        if textHeight <= 288 then
            button.background:SetTexCoord(0.05078125, 0.94921875, 0.485 - textHeight/288/2, 0.485);
        else
            button.background:SetTexCoord(0.05078125, 0.94921875,  0, 0.485);
        end
        if isDarkTheme then
            button.header:SetTextColor(0.9, 0.82, 0.58);
            button.headerLong:SetTextColor(0.9, 0.82, 0.58);
        else
            button.header:SetTextColor(1, 1, 1);
            button.headerLong:SetTextColor(1, 1, 1);
        end
    end

    button:Show();
end


--Limit the update frequency
local processor = CreateFrame("Frame");
processor:Hide();
processor:SetScript("OnUpdate", function(self, elapsed)
    local processComplete;
    if self.func then
        self.arg1, processComplete = self.func(self.arg1);
        if processComplete then
            self:Hide();
            self.func = nil;
            if self.callback then
                self.callback(self.arg2);
            end
        end
    else
        self:Hide();
    end
end)

local function UpdateScrollRange()
    local numEntries = DataProvider:GetNumEntries();
    local scrollBar = DIYContainer.scrollBar;
    local range;
    if numEntries == 0 then
        range = 0;
    else
        range = max(0, DIYCards[1]:GetTop() -  DIYCards[numEntries]:GetBottom() - DIYContainer:GetHeight() + 60 + 72*2);
    end
    scrollBar:SetMinMaxValues(0, range);
    DIYContainer.range = range;
    scrollBar:SetShown(range ~= 0);
end

local function ReAnchorNewEntryButton(numEntries)
    NewEntryButton:ClearAllPoints();
    if numEntries > 0 then
        NewEntryButton:SetPoint("TOP", DIYCards[numEntries], "BOTTOM", 0, -4);
    else
        NewEntryButton:SetPoint("TOP", DIYContainer.ScrollChild, "TOP", 0, -18);
    end
    UpdateScrollRange();
end

processor.callback = ReAnchorNewEntryButton;

local function Slice_Func(startIndex)
    local slice = 7;
    local processComplete = false;
    local numProcessed = 0;
    local entry;
    for i = startIndex, startIndex + slice do
        entry = DataProvider:GetEntry(i);
        if entry then
            FormatCardByIndex(i, entry.name, entry.description, entry.icon, entry.points, entry.date, entry.rewardText, entry.isAccountWide);
            numProcessed = i;
        else
            processComplete = true;
            break;
        end
    end

    return numProcessed + 1, processComplete
end

local function RefreshList()
    processor:Hide();
    processor.arg1 = 1;
    processor.func = Slice_Func;
    processor:Show();

    local numEntries = DataProvider:GetNumEntries();
    processor.arg2 = numEntries;

    for i = #DIYCards, numEntries + 1, -1 do
        DIYCards[i]:Hide();
    end
end

local function NewEntryButton_OnEnter(self)
    UIFrameFadeIn(self.background, 0.15, self.background:GetAlpha(), 1);
end

local function NewEntryButton_OnLeave(self)
    UIFrameFadeIn(self.background, 0.25, self.background:GetAlpha(), 0.6);
end

local function NewEntryButton_OnClick(self)
    if NeedConfirmation() then return end;

    local numEntries = DataProvider:GetNumEntries();
    local name = DEFAULT_HEADER.." #"..(numEntries + 1);
    local description = DEFAULT_DESCRIPTION;
    local icon = nil;
    local points = 10;
    local date = GetToday();
    local reward;
    local isAccountWide = (numEntries % 2 == 1);
    local entry, index = DataProvider:AddEntry(name, description, icon, points, date, reward, isAccountWide)
    if entry then
        FormatCardByIndex(index, entry.name, entry.description, entry.icon, entry.points, entry.date, entry.rewardText, entry.isAccountWide);
        ReAnchorNewEntryButton(index);
        ReAnchorEditor(DIYCards[index]);
    end
end

local function LoadContainer()
    local deltaRatio = 1;
    local speedRatio = 0.24;
    local positionFunc;
    local buttonHeight = 64;
    local range = 0;
    
    NarciAPI_ApplySmoothScrollToScrollFrame(DIYContainer, deltaRatio, speedRatio, positionFunc, buttonHeight, range);
end


local function StartEditing(editor)
    if not editor.isActive then
        editor.isActive = true;
        if editor.onStartFunc then
            editor.onStartFunc(editor);
        end
    end
    UpdateEditorScrollRange();
end

local function QuitEditing(editor)
    if editor.isActive then
        editor.isActive = nil;
        if editor.onQuitFunc then
            editor.onQuitFunc(editor);
        end
    end
    UpdateEditorScrollRange();
end

local function Editor_OnClick(editor)
    if editor.isActive then
        QuitEditing(editor);
    else
        StartEditing(editor);
    end
end

local ICONS = {};
local function GetIcons()
    ICONS = {"INV_MISC_QUESTIONMARK"};
	GetLooseMacroItemIcons(ICONS);
	GetLooseMacroIcons(ICONS);
	GetMacroItemIcons(ICONS);
    GetMacroIcons(ICONS);
    
    local numIcons = #ICONS;
    local numString = 0;
    for i = 1, numIcons do
        if type(ICONS[i]) == "string" then
            numString = numString + 1;
        end
    end
    --print("numIcons: "..numIcons);
    --print("names: "..numString)
end

local function CreateColorPicker()
    local ColorPicker = EditorContainer.ColorPicker;
    ColorPicker:ClearAllPoints();
    ColorPicker:SetParent(EditorContainer.ScrollChild);
    ColorPicker:SetPoint("TOP", EditorContainer.ScrollChild, "TOP", 0, -24);
    ColorPicker.label:SetText(L["Color"]);
    ColorPicker.label:ClearAllPoints();
    ColorPicker.label:SetPoint("LEFT", ColorPicker, "LEFT", 10, 0);
    ColorPicker:SetParent(EditorContainer.ScrollChild);

    local buttons = {};
    local button;

    local function ColorButton_OnClick(self)
        local card = SelectedCard
        if card then
            local isAccountWide = self.index == 1;
            ColorPicker:SelectIcon(isAccountWide);
            local i = card.index;
            DataProvider:ModifyField(i, "isAccountWide", isAccountWide);
            ModifyCardColor(card, isAccountWide);
        end
    end

    function ColorPicker:SelectIcon(isAccountWide)
        if isAccountWide then
            buttons[1]:LockHighlight();
            buttons[2]:UnlockHighlight();
        else
            buttons[2]:LockHighlight();
            buttons[1]:UnlockHighlight();
        end
    end

    for i = 1, 2 do
        button = CreateFrame("Button", nil, ColorPicker, "NarciAchievementColorPickerButtonTemplate");
        tinsert(buttons, button);
        button.index = i;
        button:SetScript("OnClick", ColorButton_OnClick);
        if i == 1 then
            button:SetPoint("RIGHT", ColorPicker.colorBackground, "RIGHT", -8, 1);
            button.color:SetVertexColor(0.427, 0.812, 0.965);
            button.highlight:SetVertexColor(0.427, 0.812, 0.965);
        else
            button:SetPoint("RIGHT", buttons[i - 1], "LEFT", -2, 0);
            button.color:SetVertexColor(0.9, 0.82, 0.58);
            button.highlight:SetVertexColor(0.9, 0.82, 0.58);
        end
    end
end

local function CreateIconEditor()
    local IconPicker = EditorContainer.IconPicker;
    IconPicker:SetScript("OnClick", StartEditing);
    IconPicker.label:SetText(L["Icon"]);
    IconPicker:SetParent(EditorContainer.ScrollChild)
    GetIcons();

    local numButton = 0;
    local buttons = {};
    local button;
    local row = 5;
    local col = 5;
    local gap = 2;
    local iconSize = 36;
    local padding = 10;

    local collapsedHeight = iconSize + 2*padding;

    local CurrentIcon = CreateFrame("Frame", nil, IconPicker ,"NarciAchievementIconButtonTemplate");
    local offsetX = (iconSize + gap)*(col - 1)/2;
    CurrentIcon:SetPoint("TOPRIGHT", IconPicker, "TOPRIGHT", -padding, -padding);
    CurrentIcon.icon:SetTexture(134400);
    IconPicker.CurrentIcon = CurrentIcon;

    IconPicker.onQuitFunc = function(self)
        self:StopAnimating();
        self.IconContainer:Hide();
        self:SetHeight(collapsedHeight);
        self.label:Show();
        self.iconName:Show();
        local name = GetTextureName(CurrentIcon.icon)
        self.iconName:SetText(name)
    end

    IconPicker.isActive = true;
    QuitEditing(IconPicker);

    local IconContainer = IconPicker.IconContainer;

    local function Icon_OnClick(self)
        local iconFile = self.icon:GetTexture();
        CurrentIcon.icon:SetTexture(iconFile);
        IconContainer.iconName:SetText( strtrim(self.iconName, ".") );
        
        if SelectedCard then
            SelectedCard.icon:SetTexture(iconFile);
        end
    end

    
    --[[
    local delays = {
        [13] = 0,
        [12] = 0.1, [14] = 0.1, [8] = 0.1, [18] = 0.1,
        [7] = 0.2, [17] = 0.2, [11] = 0.2, [15] = 0.2, [9] = 0.2, [19] = 0.2, [3] = 0.2, [23] = 0.2,
        [2] = 0.3, [4] = 0.3, [6] = 0.3, [10] = 0.3, [16] = 0.3, [20] = 0.3, [22] = 0.3, [24] = 0.3,
        [1] = 0.4, [5] = 0.4, [21] = 0.4, [25] = 0.4,
    };
    --]]

    for i = 1, row do
        for j = 1, col do
            button = CreateFrame("Button", nil, IconContainer ,"NarciAchievementIconButtonTemplate");
            tinsert(buttons, button);
            button:SetScript("OnClick", Icon_OnClick);

            numButton = numButton + 1;
            button.id = numButton;
            
            button.fadeIn.a1:SetStartDelay((i)*0.03)

            if i == 1 then
                if j == 1 then
                    button:SetPoint("TOP", IconPicker, "TOP", -offsetX, -66);
                else
                    button:SetPoint("LEFT", buttons[numButton - 1], "RIGHT", gap, 0);
                end
            else
                if j == 1 then
                    button:SetPoint("TOP", buttons[numButton - col], "BOTTOM", 0, -gap);
                else
                    button:SetPoint("LEFT", buttons[numButton - 1], "RIGHT", gap, 0);
                end
            end
        end
    end

    local pageTextHeight = 8;
    local iconListHeight = (iconSize + gap) * row - gap + 2*padding + pageTextHeight;
    local expandedHeight = collapsedHeight + iconListHeight;

    IconPicker.onStartFunc = function(self)
        self.IconContainer:Show();
        self:SetHeight(expandedHeight);
        self.label:Hide();
        self.iconName:Hide();
    end

    IconContainer:SetHeight(iconListHeight);
    --IconPicker:SetHeight(98 + height);


    local MAX_PAGES = ceil( #ICONS/(row * col) );

    local texture;
    local function UpdateIcons(page)
        local button;
        local fromIndex = 1 + (page - 1) * (row * col);
        for i = 1, numButton do
            button = buttons[i];
            texture = ICONS[i + fromIndex];
            button.iconName = texture;
            if texture then
                button:Show();
                if(type(texture) == "number") then
                    button.icon:SetTexture(texture);
                else
                    button.icon:SetTexture("INTERFACE\\ICONS\\"..texture);
                end
            else
                button:Hide();
            end
        end
        IconContainer.pageText:SetText(page.."/"..MAX_PAGES)
    end

    UpdateIcons(1);

    IconContainer.page = 1;
    local function IconContainer_OnMouseWheel(self, delta)
        local page = self.page;
        if delta == -1 then
            if page < MAX_PAGES then
                if IsShiftKeyDown() then
                    page = page + 4;
                    if page > MAX_PAGES then
                        page = MAX_PAGES;
                    end
                else
                    page = page + 1;
                end
                self.page = page;
                UpdateIcons(page);
            end
        else
            if page > 1 then
                if IsShiftKeyDown() then
                    page = page - 4;
                    if page < 1 then
                        page = 1;
                    end
                else
                    page = page - 1;
                end
                self.page = page;
                UpdateIcons(page);
            end
        end
    end

    IconContainer:SetScript("OnMouseWheel", IconContainer_OnMouseWheel);


    local numCategories = 50;
    local deltaRatio = 1;
    local speedRatio = 0.2;
    local buttonHeight = 72;
    local range = buttonHeight * 5.5;
    local positionFunc;
    
    NarciAPI_ApplySmoothScrollToScrollFrame(EditorContainer, deltaRatio, speedRatio, positionFunc, buttonHeight, range);

    --Picker Buttons
    IconContainer.CancelButton.icon:SetTexCoord(0.75, 1, 0.5, 1);
    IconContainer.CancelButton:SetScript("OnClick", function()
        local oldTexture = IconPicker.oldTexture;
        if oldTexture then
            CurrentIcon.icon:SetTexture(oldTexture);
            if SelectedCard then
                SelectedCard.icon:SetTexture(oldTexture);
            end
        end
        QuitEditing(IconPicker);
    end)
    IconContainer.ConfirmButton:SetScript("OnClick", function()
        if SelectedCard then
            local index = SelectedCard.index;
            local texture = CurrentIcon.icon:GetTexture();
            DataProvider:ModifyField(index, "icon", texture)
        end
        QuitEditing(IconPicker);
    end)
end

local function CreateTextEditor()
    local text;

    --Name
    local HeaderEditor = EditorContainer.HeaderEditor;
    HeaderEditor:SetParent(EditorContainer.ScrollChild);
    HeaderEditor.label:SetText(NAME);
    local EditBox = HeaderEditor.EditBox;
    EditBox:SetMaxLetters(64);
    EditBox:SetScript("OnEditFocusGained", function(self)
        if string.find(self:GetText(), DEFAULT_HEADER) then
            self:HighlightText();
        end
    end);
    EditBox:SetScript("OnTextChanged", function(self, isUserInput)
        if SelectedCard and isUserInput then
            needConfirmation = true;
            text = self:GetText();
            text = UpperFirstLetter(text);
            SelectedCard.header:SetText(text);
            SelectedCard.headerLong:SetText(text);
            local isLong = SelectedCard.header:IsTruncated()
            SelectedCard.header:SetShown(not isLong);
            SelectedCard.headerLong:SetShown(isLong);
        end
        local height = self:GetHeight();
        if height ~= self.oldHeight then
            self.oldHeight = height;
            HeaderEditor:SetHeight(EDIT_FRAME_HEADER_HEIGHT + height);
            UpdateEditorScrollRange();
        end
    end);

    --Description
    local DescriptionEditor = EditorContainer.DescriptionEditor;
    DescriptionEditor:SetParent(EditorContainer.ScrollChild);
    DescriptionEditor.label:SetText(L["Description"]);
    local EditBox = DescriptionEditor.EditBox;
    EditBox:SetMaxLetters(280);
    EditBox.enableLineFeed = true;
    EditBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == DEFAULT_DESCRIPTION then
            self:HighlightText();
        end
    end);

    EditBox:SetScript("OnTextChanged", function(self, isUserInput)
        if SelectedCard and isUserInput then
            needConfirmation = true;
            text = self:GetText();
            if not text or text == "" then
                text = " ";
            end
            SelectedCard.description:SetText(text);
            local descriptionHeight = SelectedCard.description:GetHeight();
            if descriptionHeight ~= self.oldDescriptionHeight then
                self.oldDescriptionHeight = descriptionHeight;
                ModifyCardDescription(SelectedCard, text);
                UpdateEditorScrollRange();
            end
        end
        local height = self:GetHeight();
        if height ~= self.oldHeight then
            self.oldHeight = height;
            DescriptionEditor:SetHeight(EDIT_FRAME_HEADER_HEIGHT + height);
        end
    end);
    
    --Points
    local PointsEditor = EditorContainer.PointsEditor;
    PointsEditor:SetParent(EditorContainer.ScrollChild);
    PointsEditor.label:SetText(L["Points"]);
    local EditBox = PointsEditor.EditBox;
    EditBox:SetMaxLetters(3);
    EditBox:SetNumeric(true);
    EditBox:SetScript("OnTextChanged", function(self, isUserInput)
        if SelectedCard and isUserInput then
            needConfirmation = true;
            local value = self:GetNumber() or 0;
            local points = SelectedCard.points;
            points:SetText(value);
            points:SetShown(value ~= 0)
            SelectedCard.lion:SetShown(value == 0);
            if value >= 100 then
                points:SetFontObject(NarciAchievemtPointsSmall);
            else
                points:SetFontObject(NarciAchievemtPoints);
            end
        end
    end);
    EditBox:SetScript("OnEditFocusLost", function(self)
        local value = self:GetNumber() or 0;
        self:SetText(value);
    end)

    --Reward
    local RewardEditor = EditorContainer.RewardEditor;
    RewardEditor:SetParent(EditorContainer.ScrollChild);
    RewardEditor.label:SetText(L["Reward"]);
    local EditBox = RewardEditor.EditBox;
    EditBox:SetMaxLetters(48);
    EditBox:SetScript("OnTextChanged", function(self, isUserInput)
        if SelectedCard and isUserInput then
            needConfirmation = true;
            text = self:GetText();
            if text and strtrim(text) ~= "" then
                text = UpperFirstLetter(text);
                SelectedCard.RewardFrame.reward:SetText(text);
                if not SelectedCard.RewardFrame:IsShown() then
                    ModifyCardDescription(SelectedCard, nil, text);
                end
            else
                if SelectedCard.RewardFrame:IsShown() then
                    ModifyCardDescription(SelectedCard, nil, "");
                end
            end
        end
        local height = self:GetHeight();
        if height ~= self.oldHeight then
            self.oldHeight = height;
            RewardEditor:SetHeight(EDIT_FRAME_HEADER_HEIGHT + height);
            UpdateEditorScrollRange();
        end
    end);

    --Date
    local DateEditor = EditorContainer.DateEditor;
    DateEditor:SetParent(EditorContainer.ScrollChild);
    DateEditor.label:SetText(L["Date"]);
    local EditBox = DateEditor.EditBox;
    EditBox:SetMaxLetters(10);
    EditBox:SetScript("OnTextChanged", function(self, isUserInput)
        if SelectedCard and isUserInput then
            needConfirmation = true;
            local text = self:GetText();
            SelectedCard.date:SetText(text);
        end
    end);


    --Remove Button
    local CardEditor = DIYContainer.Editor;
    local markMask = CardEditor.markMask;
    local animMark = NarciAPI_CreateAnimationFrame(0.45);
    animMark:SetScript("OnUpdate", function(self, elapsed)
        self.total = self.total + elapsed;
        local offset = inOutSine(self.total, -540, 0, self.duration);
        if self.total >= self.duration then
            offset = 0;
        end
        markMask:SetPoint("CENTER", CardEditor, "CENTER", offset, 0);
    end);
    local function PlayAnimMark()
        animMark:Hide();
        animMark:Show();
    end

    local RemoveButton = EditorContainer.RemoveButton;
    NarciAPI.NineSliceUtil.SetUpOverlay(RemoveButton, "blizzardTooltipBorder", 0, 0.5, 0.2, 0.2);
    RemoveButton:SetParent(EditorContainer.ScrollChild);
    RemoveButton.label:SetText(L["Remove"]);
    --RemoveButton.label:SetTextColor();
    RemoveButton.fill.Timer:SetScript("OnFinished", function(self)
        if SelectedCard then
            needConfirmation = false;
            if DataProvider:RemoveEntry(SelectedCard.index) then
                DIYContainer:Refresh();
                HideEditor();
            end
        end
    end);

    RemoveButton:SetScript("OnEnter", function(self)
        self.colorBackground:SetColorTexture(0.5, 0.2, 0.2);
        self.label:SetText(L["Click And Hold"]);
        DIYContainer.Editor.removeMark:Show();
        PlayAnimMark();
    end);

    RemoveButton:SetScript("OnLeave", function(self)
        self.colorBackground:SetColorTexture(0.2, 0.2, 0.2);
        self.label:SetText(L["Remove"]);
        if not IsMouseButtonDown() then
            DIYContainer.Editor.removeMark:Hide();
        end
    end);

    RemoveButton:SetScript("OnMouseDown", function(self)
        self:StopAnimating();
        self.fill:Show();
        self.fill.Timer:Play();
    end);
    RemoveButton:SetScript("OnMouseUp", function(self)
        self.fill.Timer:Pause();
        self.fill.FadeOut:Play();
    end);

    --Interactable area on the selected card
    local E = DIYContainer.Editor;
    E.IconArea:SetScript("OnClick", function() EditorContainer.IconPicker:Click(); EditorContainer.scrollBar:SetValue(0) end);
    E.NameArea:SetScript("OnClick", function() HeaderEditor.EditBox:SetFocus() end);
    E.DescriptionArea:SetScript("OnClick", function() DescriptionEditor.EditBox:SetFocus() end);
    E.PointsArea:SetScript("OnClick", function() PointsEditor.EditBox:SetFocus() end);
    E.RewardArea:SetScript("OnClick", function() RewardEditor.EditBox:SetFocus() end);
    E.DateArea:SetScript("OnClick", function() DateEditor.EditBox:SetFocus() end);
end

local function SaveCard(card)
    needConfirmation = false;
    if not card then return false end;
    local index = card.index;
    local name = card.header:GetText();
    local description = card.description:GetText();
    local icon = card.icon:GetTexture();
    local points = tonumber(card.points:GetText());
    local date = card.date:GetText();
    local reward = card.RewardFrame.reward:GetText();

    local isAccountWide = card.accountWide;
    DataProvider:UpdateEntry(index, name, description, icon, points, date, reward, isAccountWide);
end

local function CreateSaveButtons()
    DIYContainer.Editor:SetParent(DIYContainer.ScrollChild);

    local SaveButton = DIYContainer.Editor.SaveButton;
    NarciAPI.NineSliceUtil.SetUpOverlay(SaveButton, "blizzardTooltipBorder", 0, 0.37, 0.74, 0.42);
    SaveButton.label:SetText(L["Save"]);
    SaveButton.label:SetTextColor(0.64, 0.83, 0.61);    --0.37, 0.74, 0.42

    SaveButton:SetScript("OnEnter", function(self)
        self.colorBackground:SetColorTexture(0.37, 0.74, 0.42);
    end);

    SaveButton:SetScript("OnClick", function()
        SaveCard(SelectedCard);
        HideEditor();
    end);

    local CancelButton = DIYContainer.Editor.CancelButton;
    CancelButton.label:SetText(L["Cancel"]);
    NarciAPI.NineSliceUtil.SetUpOverlay(CancelButton, "blizzardTooltipBorder", 0, 0.5, 0.5, 0.5);
    CancelButton:SetScript("OnClick", function()
        needConfirmation = false;
        if SelectedCard then
            local index = SelectedCard.index;
            local entry = DataProvider:GetEntry(index)
            if entry then
                FormatCardByIndex(index, entry.name, entry.description, entry.icon, entry.points, entry.date, entry.rewardText, entry.isAccountWide);
            end
        end
        HideEditor();
    end)

    NarciAlertFrameMixin:AddShakeAnimation(SaveButton);
    NarciAlertFrameMixin:AddShakeAnimation(CancelButton);
end

local function CreateEditor()
    CreateColorPicker();
    CreateIconEditor();
    CreateTextEditor();
    CreateSaveButtons();
    HideEditor();
end

--------------------------------------------------------------


--------------------------------------------------------------
local function LoadDIY()
    DIYContainer = Narci_AchievementFrame.DIYContainer;
    EditorContainer = Narci_AchievementFrame.EditorContainer;
    DIYContainer.cards = {};
    DIYCards = DIYContainer.cards;
    NewEntryButton = DIYContainer.NewEntry;
    NewEntryButton:SetParent(DIYContainer.ScrollChild);
    NewEntryButton.plus:SetVertexColor(0.68, 0.58, 0.51);
    NewEntryButton.label:SetTextColor(0.68, 0.58, 0.51);
    
    NewEntryButton:SetScript("OnEnter", NewEntryButton_OnEnter);
    NewEntryButton:SetScript("OnLeave", NewEntryButton_OnLeave);
    NewEntryButton:SetScript("OnClick", NewEntryButton_OnClick);

    function DIYContainer:Refresh()
        RefreshList()
    end

    function DIYContainer:RefreshTheme()
        local card;
        for i = 1, #DIYCards do
            card = DIYCards[i];
            ModifyCardDescription(card);
            DarkenCard(card, card.isDark, true);
        end
    end
    
    if not NarciAchievementOptions.DIY then
        NarciAchievementOptions.DIY = {};
    end

    EditorContainer.notes:SetText(L["Custom Achievement Select And Edit"]);

    CreateEditor();

    After(0, function()
        DataProvider.data = NarciAchievementOptions.DIY;
        LoadContainer();
    end)
end

addon.LoadDIY = LoadDIY;
