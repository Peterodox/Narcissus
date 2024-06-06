-- Creating a way to conveniently reload UI since we can't neutralize taint for good.

local InCombatLockdown = InCombatLockdown;
local time = time;

local SHOW_POPUP = true;

local AlertFrame;
local ErrorDB;

local EventListener = CreateFrame("Frame");
EventListener:RegisterEvent("PLAYER_ENTERING_WORLD");

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded;


--[[
local INCONSEQUENTIAL_ERROR = {
    ["CopyToClipboard()"] = true,
    --Narcissus Dressing Room: Caused by Clicking "Copy to Clipboard" if the dressing room was initialized by player clicking "Dressing Room" on Narcissus minimap flyout menu.
    --No way around this but we already provided an alternative to copy outfit string - showing an editbox where player can press Ctrl+C to copy.
};
--]]

local HIGH_PRIORITY_ERROR = {
    --Updates: Only shows pop-up when player can't use abilities or items.
    ["UseAction()"] = true,
    ["UseInventoryItem()"] = true,
    --The "unable to use item in the Backpack" error says Unknown() was blocked
    --/script local a = C_Container.UseContainerItem; C_Container.UseContainerItem = a;
};

local function ClearDatedData()
    if NarciStatisticsDB and NarciStatisticsDB.AddOnActionForbidden then
        ErrorDB = NarciStatisticsDB.AddOnActionForbidden;
        if not ErrorDB.addons then
            return
        end
        local currentTime = time();
        local fromIndex;
        local numRecords;
        local maxTimeDiff = 7 * 86400;
        for addonName, data in pairs(ErrorDB.addons) do
            if data.errorTime then
                fromIndex = nil;
                numRecords = #data.errorTime;
                for i = 1, numRecords do
                    if currentTime - data.errorTime[i] < maxTimeDiff then
                        fromIndex = i;
                        break
                    end
                end
                fromIndex = fromIndex or (numRecords + 1);
                if fromIndex > 1 then
                    local numNewData = numRecords - fromIndex + 1;
                    if numNewData > 0 then
                        for i = 1, numNewData do
                            data.errorTime[i] = data.errorTime[i + fromIndex - 1];
                        end

                        for i = numNewData + 1, numRecords do
                            data.errorTime[i] = nil;
                        end
                    else
                        data.errorTime = nil;
                    end
                end
            end
        end
    end
end

local function CountErrorTimes(addonName, days)
    local count = 0;
    if ErrorDB and ErrorDB.addons and ErrorDB.addons[addonName] then
        local record = ErrorDB.addons[addonName].errorTime;
        if record then
            local currentTime = time();
            local maxTimeDiff = days * 86400;
            for i, t in ipairs(record) do
                if currentTime - t < maxTimeDiff then
                    count = count + 1;
                else
                    break
                end
            end
        end
    end
    return count
end

local function SetupAlertFrame(addonName, functionName)
    addonName = addonName or "Unknown AddOn";
    functionName = functionName or "Unknown Function";

    local currentTime = time();

    if not ErrorDB then
        if not NarciStatisticsDB then
            NarciStatisticsDB = {};
        end
        if not NarciStatisticsDB.AddOnActionForbidden then
            NarciStatisticsDB.AddOnActionForbidden = {
                addons = {},
                timeLastError = currentTime,
            };
        end
        ErrorDB = NarciStatisticsDB.AddOnActionForbidden;
    end

    local lastTime = ErrorDB.timeLastError or currentTime;
    ErrorDB.timeLastError = currentTime;

    if not ErrorDB.addons[addonName] then
        ErrorDB.addons[addonName] = {
            count = 0;
        };
    end
    local addonErrorData = ErrorDB.addons[addonName];
    addonErrorData.count = addonErrorData.count + 1;
    addonErrorData.timeLastError = currentTime;

    if not addonErrorData.errorTime then
        addonErrorData.errorTime = {};
    end
    table.insert(addonErrorData.errorTime, currentTime);

    if SHOW_POPUP and HIGH_PRIORITY_ERROR[functionName] then
        if not AlertFrame then
            AlertFrame = CreateFrame("Frame", nil, UIParent, "NarciGenericTaintAlertFrameTemplate");
        end
        local daySinceLastError = math.floor((currentTime - lastTime)/86400);
        AlertFrame:SetupDescription(addonName, functionName);
        AlertFrame:ShowFrame();
        AlertFrame:PlayDaysAnimation(daySinceLastError > 0);
    end
end

local function EventListener_OnEvent(self, event, ...)
    if event == "ADDON_ACTION_FORBIDDEN" then
        SetupAlertFrame(...);
    end
end

EventListener:SetScript("OnEvent", function(self, event, ...)
    self:UnregisterEvent(event);    --PLAYER_ENTERING_WORLD
    ClearDatedData();
    self:RegisterEvent("ADDON_ACTION_FORBIDDEN");
    self:SetScript("OnEvent", EventListener_OnEvent);

    if IsAddOnLoaded("BugSack") then
        SHOW_POPUP = false;
    end
end);


local BUTTON_TOP_PADDING = 14;
local PARAGRAPH_PADDING = 8;
local POPUP_TEXT_PADDING = 16;
local FRAME_WIDTH = 320;
local CLIPBOARD_HEIGHT = 160;

NarciGenericTaintAlertFrameMixin = {};

function NarciGenericTaintAlertFrameMixin:OnLoad()
    self.CloseButton:SetScript("OnClick", function()
        self:HideFrame();
    end);
    self.ShowMoreButton:SetScript("OnClick", function()
        self:ShowAdditionalOptions(not self.ReportButton:IsShown());
    end);

    self:SetWidth(FRAME_WIDTH);
    self.reloadButtonWidth = FRAME_WIDTH - 26*2 - 32 -12;
    self.ReloadButton:SetButtonWidth(self.reloadButtonWidth);
    self.ReloadButton:SetButtonText(RELOADUI or "Reload UI");
    self.ReloadButton:SetScript("OnClick", C_UI.Reload);

    self.LeaderboardButton:SetButtonText("Leaderboard");
    self.LeaderboardButton:SetScript("OnClick", function()
        self:TogggleLeaderboard();
    end);

    self.ReportButton:SetButtonText("Report");
    self.ReportButton:SetScript("OnClick", function()
        self:TogggleReport();
    end);

    local buttonWidth = (FRAME_WIDTH - 26*2 - 12) * 0.5;
    self.LeaderboardButton:SetButtonWidth(buttonWidth);
    self.ReportButton:SetButtonWidth(buttonWidth);

    --self:SetupDescription("DoSomething()");

    if InCombatLockdown() then
        self.ReloadButton:Disable();
    end
end

local function AlertFrame_OnKeyDown(self, key)
    if key == "ESCAPE" then
        self:HideFrame();
        self:SetPropagateKeyboardInput(false);
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciGenericTaintAlertFrameMixin:OnShow()
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:SetScript("OnKeyDown", AlertFrame_OnKeyDown);
    if InCombatLockdown() then
        self.ReloadButton:Disable();
    else
        self.ReloadButton:Enable();
    end
end

function NarciGenericTaintAlertFrameMixin:OnHide()
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
    self:UnregisterEvent("PLAYER_REGEN_ENABLED");
    self:SetScript("OnKeyDown", nil);
end

function NarciGenericTaintAlertFrameMixin:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self.ReloadButton:Disable();
    elseif event == "PLAYER_REGEN_ENABLED" then
        self.ReloadButton:Enable();
    end
end

function NarciGenericTaintAlertFrameMixin:ReleaseFontStrings()
    self.numTexts = 0;
    if self.fontStringPool then
        for i, fs in ipairs(self.fontStringPool) do
            fs:Hide();
            fs:SetText("");
            if i ~= 1 then
                fs:ClearAllPoints();
            end
        end
    end
end

function NarciGenericTaintAlertFrameMixin:AcquireAndSetFontString(text)
    if not self.fontStringPool then
        self.fontStringPool = {};
    end

    local index = self.numTexts + 1;
    self.numTexts = index;
    local fs = self.fontStringPool[index];
    if not fs then
        fs = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        fs:SetTextColor(0.8, 0.8, 0.8);
        fs:SetSpacing(2);
        fs:SetWidth(FRAME_WIDTH - 58);
        fs:SetJustifyH("LEFT");
        fs:SetJustifyV("TOP");
        self.fontStringPool[index] = fs;
        if index == 1 then
            fs:SetPoint("TOP", self.FontStringSinceLastError, "BOTTOM", 0, -PARAGRAPH_PADDING);
        end
    end
    if index > 1 then
        fs:SetPoint("TOP", self.fontStringPool[index - 1], "BOTTOM", 0, -PARAGRAPH_PADDING);
    end
    fs:Show();
    fs:SetText(text);
end

function NarciGenericTaintAlertFrameMixin:SetupDescription(addonName, blockedAction)
    self:ReleaseFontStrings();
    local descText;
    if blockedAction then
        descText = string.format("- Blocked function: |cffffffff%s (%s)|r ", blockedAction, addonName);
        self:AcquireAndSetFontString(descText);
    end
    local numErrorsToday = CountErrorTimes(addonName, 1);
    if numErrorsToday > 4 then
        local countAlert = string.format("- |cffffffff%s|r has been mentioned in the error message |cffffffff%s|r times today. Although it may not be the root of the problem.", addonName, numErrorsToday);
        self:AcquireAndSetFontString(countAlert);
    end
    self.addonName = addonName;
    self.blockedAction = blockedAction;
    self:UpdateLayout();
end

function NarciGenericTaintAlertFrameMixin:UpdateLayout()
    local bottomFontString;
    if self.numTexts > 0 then
        bottomFontString = self.fontStringPool[self.numTexts];
    else
        bottomFontString = self.FontStringSinceLastError;
    end


    local top = self:GetTop();
    local descBottom = bottomFontString:GetBottom();

    self.ReloadButton:ClearAllPoints();
    self.ReloadButton:SetPoint("TOPLEFT", self, "TOPLEFT", 26, descBottom - top -BUTTON_TOP_PADDING);
    local bottom = (self.LeaderboardButton:IsShown() and self.LeaderboardButton:GetBottom()) or self.ReloadButton:GetBottom();
    self:SetHeight(math.floor(top - bottom + 0.5) + 26);
end

function NarciGenericTaintAlertFrameMixin:HideFrame()
    self:Hide();
end

function NarciGenericTaintAlertFrameMixin:ShowFrame()
    self:ClearAllPoints();
    if StaticPopup1:IsShown() then
        self:SetPoint("TOP", StaticPopup1, "BOTTOM", 0, -24);
    else
        self:SetPoint("TOP", UIParent, "TOP", 0, -135);
    end
    self:Show();
end

function NarciGenericTaintAlertFrameMixin:PlayDaysAnimation(state)
    self.DayFrame:StopAnimating();
    if state then
        self.DayFrame.FontStringNumber.FlyDown:Play();
        self.DayFrame.FontStringOldNumber.FlyDown:Play();
    end
end

function NarciGenericTaintAlertFrameMixin:ShowAdditionalOptions(state)
    if state then
        self.LeaderboardButton:Show();
        self.ReportButton:Show();
        self.ShowMoreButton.Icon:SetTexCoord(0, 1, 1, 0);
    else
        self.LeaderboardButton:Hide();
        self.ReportButton:Hide();
        self.ShowMoreButton.Icon:SetTexCoord(0, 1, 0, 1);
    end
    self:UpdateLayout();
end

function NarciGenericTaintAlertFrameMixin:GetPopupFrame()
    if not self.PopupFrame then
        local popup = CreateFrame("Frame", nil, self);
        self.PopupFrame = popup;
        popup:SetSize(96, 96);
        popup:SetPoint("TOP", self, "BOTTOM", 0, -8);
        NarciAPI.NineSliceUtil.SetUp(popup, "classTalentTraitTransparent", "backdrop");
        popup:SetScript("OnShow", function(f)
            f:RegisterEvent("GLOBAL_MOUSE_DOWN");
        end);
        popup:SetScript("OnHide", function(f)
            f:Hide();
            f:RegisterEvent("GLOBAL_MOUSE_DOWN");
            f.TextLeft:SetText("");
            f.TextRight:SetText("");
            f.Header:SetText("");
        end);
        popup:SetScript("OnEvent", function(f, event, ...)
            if not (f:IsMouseOver() or (f.parentButton and f.parentButton:IsMouseOver())) then
                f:Hide();
            end
        end);

        popup.TextLeft = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        popup.TextLeft:SetTextColor(1, 1, 1);
        popup.TextLeft:SetPoint("TOPLEFT", popup, "TOPLEFT", POPUP_TEXT_PADDING, -2*POPUP_TEXT_PADDING);
        popup.TextLeft:SetJustifyH("LEFT");
        popup.TextLeft:SetJustifyV("TOP");
        popup.TextLeft:SetSpacing(4);

        popup.TextRight = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        popup.TextRight:SetTextColor(1, 1, 1);
        popup.TextRight:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -POPUP_TEXT_PADDING, -2*POPUP_TEXT_PADDING);
        popup.TextRight:SetJustifyH("RIGHT");
        popup.TextRight:SetJustifyV("TOP");
        popup.TextRight:SetSpacing(4);

        popup.Header = popup:CreateFontString(nil, "OVERLAY", "GameFontBlackSmall");
        popup.Header:SetTextColor(0.5, 0.5, 0.5);
        popup.Header:SetPoint("TOP", popup, "TOP", 0, -POPUP_TEXT_PADDING);
        popup.Header:SetJustifyH("CENTER");
        popup.Header:SetJustifyV("TOP");

        popup.Clipboard = CreateFrame("Frame", nil, popup, "NarciScrollEditBoxTemplate");
        popup.Clipboard:SetWidth(FRAME_WIDTH - 2*POPUP_TEXT_PADDING);
        popup.Clipboard:SetHeight(CLIPBOARD_HEIGHT);
        popup.Clipboard:ClearAllPoints();
        popup.Clipboard:SetPoint("TOP", popup, "TOP", 0, -2*POPUP_TEXT_PADDING);
        popup.Clipboard:Hide();
        popup.Clipboard:SetFontObject(GameFontHighlight);
        popup.Clipboard:SetFontColor(1, 1, 1);

        popup:Hide();
    end
    return self.PopupFrame
end

local function ConcatenateTexts(data)
    local leftText, rightText;
    for i = 1, #data do
        if i == 1 then
            leftText = data[i][1];
            rightText = data[i][2];
        else
            if i%2 == 0 then
                leftText = leftText.."\n|cffcccccc"..data[i][1].."|r";
                rightText = rightText.."\n|cffcccccc"..data[i][2].."|r";
            else
                leftText = leftText.."\n"..data[i][1];
                rightText = rightText.."\n"..data[i][2];
            end
        end
    end
    return leftText, rightText;
end

function NarciGenericTaintAlertFrameMixin:TogggleLeaderboard()
    local popup = self:GetPopupFrame();
    popup.parentButton = self.LeaderboardButton;
    if popup:IsShown() then
        popup:Hide();
        return
    else
        popup:Show();
        popup.Clipboard:Hide();
        popup.Header:SetText("NUMBERS OF ERRORS OVER THE LAST WEEK");

        local stats = {};

        local numRecords;
        for addonName, data in pairs(ErrorDB.addons) do
            if data.errorTime then
                numRecords = #data.errorTime;
                if numRecords > 0 then
                    table.insert(stats, {addonName, numRecords});
                end
            end
        end

        if #stats == 0 then
            stats = {"None", 0};
        end

        local function SortMethod(a, b)
            if a[2] == b[2] then
                return a[1] < b[1];
            else
                return a[2] > b[2]
            end
        end
        table.sort(stats, SortMethod);
        local leftText, rightText = ConcatenateTexts(stats);
        popup.TextLeft:SetText(leftText);
        popup.TextRight:SetText(rightText);
        local width = math.floor( math.max(popup.Header:GetWrappedWidth(), popup.TextLeft:GetWrappedWidth() + popup.TextRight:GetWrappedWidth() + 16) + 0.5) + 2*POPUP_TEXT_PADDING;
        local height = math.floor(popup:GetTop() - popup.TextLeft:GetBottom() + POPUP_TEXT_PADDING + 0.5);
        popup:SetSize(width, height);
    end
end

local function GenerateReport()
    local format = string.format;
    local GetAddOnInfo = C_AddOns.GetAddOnInfo;
    local GetAddOnMetadata = C_AddOns.GetAddOnMetadata;

    local line1 = format("Date: %s", date());
    local osName = (IsWindowsClient() and "Windows") or (IsMacClient() and "Mac") or (IsLinuxClient() and "Linux");
    local line2 = format("OS: %s", osName);
    local line3 = format("Region: %s (%s)", GetCurrentRegion(), GetCurrentRegionName());
    local line4 = format("Locale: %s", GetLocale());

    local line5 = format("Build Info: %s (%s)  %s  (TOC Version %s)" , GetBuildInfo());
    if IsPublicBuild() then
        line5 = line5 .. "  Public Build";
    end
    if IsTestBuild() then
        line5 = line5 .. "  Test Build";
    end

	local specName, _;
    local primaryTalentTree = GetSpecialization();
    local sex = UnitSex("player");
    local className = UnitClass("player");
	if (primaryTalentTree) then
		_, specName = GetSpecializationInfo(primaryTalentTree, nil, nil, nil, sex);
	end
	local level = UnitLevel("player");
    local raceName, raceFile, raceID = UnitRace("player");
    local line6 = format("Character: Level %s %s (%s) %s %s", level, raceName, raceID, specName or "", className);

    local mapName;
    local mapID = C_Map.GetBestMapForUnit("player");
    if mapID then
        local mapInfo = C_Map.GetMapInfo(mapID);
        if mapInfo then
            mapName = mapInfo.name .. " ("..mapID..")";
        end
    end
    local zoneName = GetMinimapZoneText();
    if zoneName then
        if mapName and zoneName ~= mapName then
            mapName = mapName .. ", "..zoneName
        else
            mapName = zoneName;
        end
    end
    local line7 = format("Location: %s", mapName);

    local errorAddOnName = AlertFrame.addonName;
    local addonVersion = GetAddOnMetadata(errorAddOnName, "version");
    if addonVersion then
        errorAddOnName = errorAddOnName.." ("..addonVersion..")";
    end
    local line8 = format("Blocked Action: %s  %s", AlertFrame.blockedAction, errorAddOnName);

    local report = string.join("\n", line8, "", line1, line2, line3, line4, line5, line6, line7, "", "Loaded AddOns:");


    local addonList;
    local addonName;
    for i = 1, C_AddOns.GetNumAddOns() do
        if IsAddOnLoaded(i) then
            addonName = GetAddOnInfo(i);
            addonVersion = GetAddOnMetadata(i, "version");
            if addonVersion then
                addonName = addonName.." ("..addonVersion..")";
            end
            if addonList then
                addonList = addonList.."\n"..addonName;
            else
                addonList = addonName;
            end
        end
    end
    if addonList then
        report = report .. "\n" ..addonList
    end
    return report
end

function NarciGenericTaintAlertFrameMixin:TogggleReport()
    local popup = self:GetPopupFrame();
    popup.parentButton = self.ReportButton;
    if popup:IsShown() then
        popup:Hide();
    else
        popup:Show();
        popup.TextLeft:Hide();
        popup.TextRight:Hide();
        popup.Clipboard:Show();
        popup:SetWidth(FRAME_WIDTH);
        popup:SetHeight( math.floor(popup:GetTop() - popup.Clipboard:GetBottom() + POPUP_TEXT_PADDING + 0.5) );
        popup.Header:SetText(Narci.L["Press Copy Yellow"]);
        popup.Clipboard:SetText( GenerateReport() );
        popup.Clipboard:SetFocus();
    end
end