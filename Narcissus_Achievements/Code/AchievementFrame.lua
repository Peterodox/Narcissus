local _, addon = ...
local StatCardController = addon.StatCardController;
local GetCategoryNumAchievements = addon.GetCustomCategoryNumAchievements;
local IsBossCard = addon.IsBossCard;
local GetStatisticInfo = addon.GetStatisticInfo;
local DataProvider = addon.DataProvider;
local PinUtil = addon.PinUtil;
local BookmarkUtil = addon.BookmarkUtil;

--Constant
local NUM_ACHIEVEMENT_CARDS = 8;
local LEGACY_ID = 15234;
local FEAT_OF_STRENGTH_ID = 81;
--local GUILD_FEAT_OF_STRENGTH_ID = 15093;
--local GUILD_CATEGORY_ID = 15076;
local TITLE_REWARD_FORMAT = string.gsub((RENOWN_REWARD_TITLE_NAME_FORMAT or "Title: %s"), "%%s", "");

local sin = math.sin;
local cos = math.cos;
local abs = math.abs;
local min = math.min;
local max = math.max;
local sqrt = math.sqrt;
local pow = math.pow;
local pi = math.pi;
local floor = math.floor;
local ceil = math.ceil;
local After = C_Timer.After;
local bband = bit.band;
local format = string.format;
local tremove = table.remove;
local tinsert = table.insert;
local gsub = string.gsub;
local find = string.find;

local CreateFrame = CreateFrame;
local GetAchievementNumCriteria = GetAchievementNumCriteria;
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo;
local GetRewardItemID = C_AchievementInfo.GetRewardItemID;
local GetPreviousAchievement = GetPreviousAchievement;
local GetNextAchievement = GetNextAchievement;
local SetFocusedAchievement = SetFocusedAchievement;    --Requset guild achievement progress from server, will fire "CRITERIA_UPDATE" after calling GetAchievementCriteriaInfo()
local FadeFrame = NarciFadeUI.Fade;
local GetParentAchievementID = NarciAPI.GetParentAchievementID;
local L = Narci.L;

local function linear(t, b, e, d)
	return (e - b) * t / d + b
end

local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, e, d)
	return (b - e) / 2 * (cos(pi * t / d) - 1) + b
end

local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

addon.outQuart = outQuart;

--FormatShortDate Derivated from FormatShortDate (Util.lua)
local FormatDate;
if LOCALE_enGB then
    function FormatDate(day, month, year, twoRowMode)
        if (year) then
            if twoRowMode then
                return format("%1$d/%2$d\n20%3$02d", day, month, year);
            else
                return format("%1$d/%2$d/%3$02d", day, month, year);
            end
        else
            return format("%1$d/%2$d", day, month);
        end
    end
else
    function FormatDate(day, month, year, twoRowMode)
        if (year) then
            if twoRowMode then
                return format("%2$d/%1$02d\n20%3$02d", day, month, year);
            else
                return format("%2$d/%1$02d/%3$02d", day, month, year);
            end
        else
            return format("%2$d/%1$02d", day, month);
        end
    end
end

local themeID = 0;
local showNotEarnedMark = false;
local IS_DARK_THEME = true;
local isGuildView = false;
local TEXTURE_PATH = "Interface\\AddOns\\Narcissus_Achievements\\Art\\DarkWood\\";

local function ReskinButton(button)
    --if true then return end
    button.border:SetTexture(TEXTURE_PATH.."AchievementCardBorder");
    button.background:SetTexture(TEXTURE_PATH.."AchievementCardBackground");
    button.bottom:SetTexture(TEXTURE_PATH.."AchievementCardBackground");
    button.lion:SetTexture(TEXTURE_PATH.."Lion");
    button.mask:SetTexture(TEXTURE_PATH.."AchievementCardBorderMask");
    local isDarkTheme = IS_DARK_THEME;
    button.RewardFrame.background:SetShown(not isDarkTheme);
    button.RewardFrame.rewardNodeLeft:SetShown(isDarkTheme);
    button.RewardFrame.rewardNodeRight:SetShown(isDarkTheme);
    button.RewardFrame.rewardLineLeft:SetShown(isDarkTheme);
    button.RewardFrame.rewardLineRight:SetShown(isDarkTheme);
    button.RewardFrame.reward:SetPoint("BOTTOM", button.RewardFrame, "BOTTOM", 0, (isDarkTheme and 3) or 1);

    if isDarkTheme then
        button.description:SetFontObject(NarciAchievementText);
    else
        button.description:SetFontObject(NarciAchievementTextBlack);
    end
    button.isDarkTheme = isDarkTheme;

    --Reposition Elements
    button.icon:ClearAllPoints();
    button.lion:ClearAllPoints();
    button.date:ClearAllPoints();
    button.NotEarned:ClearAllPoints();
    if showNotEarnedMark then
        button.NotEarned:SetWidth(20);
    else
        button.NotEarned:SetWidth(0.1);
    end
    if themeID == 3 then
        button.icon:SetPoint("CENTER", button.border, "LEFT", 32, 0);
        button.lion:SetPoint("CENTER", button.border, "RIGHT", -28, -1);
        button.date:SetPoint("RIGHT", button.border, "TOPRIGHT", -54, -25);
        button.NotEarned:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 6, -2);
    else
        button.icon:SetPoint("CENTER", button.border, "LEFT", 27, 4);
        button.lion:SetPoint("CENTER", button.border, "RIGHT", -22, 3);
        button.date:SetPoint("RIGHT", button.border, "TOPRIGHT", -48, -25);
        button.NotEarned:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 7, -6.5);
    end

    button.isDark = nil;
end


local MainFrame, InspectionFrame, MountPreview, Tooltip, ReturnButton, SummaryButton, GoToCategoryButton, FilterButton;
local CategoryContainer, AchievementContainer, DIYContainer, EditorContainer, SummaryFrame, AchievementCards, TabButtons;
local UpdateSummaryFrame;

local TabUtil = {};
addon.TabUtil = TabUtil;

local CategoryButtons = {
    player = { parentButtons = {}, buttons = {}, },
    guild = { parentButtons = {}, buttons = {}, },
    stats = { parentButtons = {}, buttons = {}, },
    todo = { parentButtons = {}, buttons = {}, },
};

local IS_STAT_CATEGORY = {
    [-2] = true,    --Used to show pinned statistics
};

local ToDoListData = {
    buttons = {},
    parentButtons = {},
    structure = {},
};

function CategoryButtons:GetActiveParentButtons(tabID)
    tabID = tabID or TabUtil.tabID;
    if tabID == 1 then
        return self.player.parentButtons;
    elseif tabID == 2 then
        return self.guild.parentButtons;
    elseif tabID == 3 then
        return self.stats.parentButtons;
    elseif tabID == 5 then
        return ToDoListData.parentButtons;
    end
end

local CategoryStructure = {
    player = {},
    guild = {},
    stats = {},
};


local function IsAccountWide(flags)
    --ACHIEVEMENT_FLAGS_ACCOUNT
    if flags then
        return bband(flags, 131072) == 131072
    else
        return false
    end
end

addon.IsAccountWide = IsAccountWide;


local ScrollUtil = {};      --DataProvider for ScrollFrame

--Limit the request frequency
local processor = CreateFrame("Frame");
processor:Hide();
processor:SetScript("OnUpdate", function(self, elapsed)
    local processComplete;
    self.cycle = self.cycle + 1;
    if self.func then
        self.arg2, processComplete = self.func(self.arg1, self.arg2);
        if processComplete then
            self:Hide();
            self.func = nil;
            self.callback();
            if self.cycle == 2 then
                ScrollUtil:UpdateScrollChild(0);
            end
        end
        if self.cycle == 3 then
            ScrollUtil:UpdateScrollChild(0);
        end
    else
        self:Hide();
    end
end)

function processor:Start()
    local processComplete;
    if self.func then
        self.cycle = 1;
        self.arg2, processComplete = self.func(self.arg1, self.arg2);
        if processComplete then
            self:Hide();
            self.func = nil;
            self.callback();

            --Achievement Card Data is being constructed by OnUpdate script
            --The step is 4: Meaning it takes 2 frames to build the visible area
            --Update scrollframe on the 3rd frame
            ScrollUtil:UpdateScrollChild(0);
        else
            self:Show();
        end
    else
        self:Hide();
    end
end

------------------------------------------------------------------------------------------------------
local function HideItemPreview()
    GameTooltip:Hide();
    if MountPreview:IsShown() then
        MountPreview:FadeOut();
    end
    MountPreview:ClearCallback();
end


local animFlyIn = NarciAPI_CreateAnimationFrame(0.45);
local animFlyOut = NarciAPI_CreateAnimationFrame(0.25);

animFlyIn:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local alpha = outQuart(self.total, self.fromAlpha, 1, self.duration);
    local scale = outQuart(self.total, 0.5, 1, 0.2);

    if self.total >= 0.2 then
        scale = 1;
        local textAlpha = outQuart(self.total - 0.2, 0, 1, 0.2);
        if textAlpha > 1 then
            textAlpha = 1;
        elseif textAlpha < 0 then
            textAlpha = 0;
        end
        self.header:SetAlpha(textAlpha);
        self.description:SetAlpha(textAlpha);
        self.date:SetAlpha(textAlpha);
        self.reward:SetAlpha(textAlpha);
    end
    
    if self.total >= self.duration then
        alpha = 1;
        --offsetX = 0;
        --offsetY = 0;
        scale = 1;
        self.header:SetAlpha(1);
        self.description:SetAlpha(1);
        self.date:SetAlpha(1);
        self.reward:SetAlpha(1);
        self:Hide();
    end

    if alpha > 1 then
        alpha = 1;
    elseif alpha < 0 then
        alpha = 0;
    end
    self.background:SetAlpha(alpha);
    self.ObjectiveFrame:SetAlpha(alpha);
    self.ChainFrame:SetAlpha(alpha);
    self.Card:SetScale(scale);
end)


function animFlyIn:Play()
    self:Hide();
    self.Card:SetAlpha(1);
    self.header:SetAlpha(0);
    self.description:SetAlpha(0);
    self.date:SetAlpha(0);
    self.reward:SetAlpha(0);
    self.fromAlpha = self.background:GetAlpha();
    animFlyOut:Hide();
    self:Show();
end


animFlyOut:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local offsetX = inOutSine(self.total, self.fromX, self.toX, self.duration);
    local offsetY = outSine(self.total, self.fromY, self.toY, self.duration);
    local alpha = outQuart(self.total, 1, 0, self.duration);
    if self.total >= self.duration then
        offsetX = self.toX;
        offsetY = self.toY;
        alpha = 0;
        InspectionFrame:Hide();
        if self.button then
            self.button:Show();
        end
        self.noTranslation = nil;
        self:Hide();
    end
    self.background:SetAlpha(alpha);
    self.ObjectiveFrame:SetAlpha(alpha);
    self.ChainFrame:SetAlpha(alpha);
    if self.noTranslation then
        self.Card:SetAlpha(alpha);
    else
        self.Card:SetPoint("BOTTOM", InspectionFrame, "CENTER", offsetX, offsetY);
    end
end)

function animFlyOut:Play()
    animFlyIn:Hide();
    self:Hide();
    if self.button then
        --achievement button in the scrollframe
        self.button:Hide();
    end
    local _;
    _, _, _, self.fromX, self.fromY = self.Card:GetPoint();
    self:Show();
    HideItemPreview();
    InspectionFrame.isTransiting = true;
    InspectionFrame.HotkeyShiftClick:Hide();
    InspectionFrame.HotkeyMouseWheel:Hide();
    InspectionFrame.GetLink:Hide();
    InspectionFrame.GoToCategoryButton:Hide();
    InspectionFrame.Card.ParentAchievmentButton:Hide();
    InspectionFrame.PrevButton:Hide();
    InspectionFrame.NextButton:Hide();
end

------------------------------------------------------------------------------------------------------
local function DisplayProgress(id, flags)
    local cData, iData = {}, {};
    cData.names, iData.names = {}, {};
    cData.icons, iData.icons = {}, {};
    cData.assetIDs, iData.assetIDs = {}, {};
    cData.bars, iData.bars = {}, {};

    local numCompleted, numIncomplete = 0, 0;
    --if ( not ( bit.band(flags, 128) == 128 ) ) then   --ACHIEVEMENT_FLAGS_HAS_PROGRESS_BAR = 128!!
        local numCriteria =  GetAchievementNumCriteria(id);
        if numCriteria == 0 then
            numCompleted = 0;
            numIncomplete = 0;
        else
            local criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID, quantityString, criteriaID;

            for i = 1, numCriteria do
                criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID, quantityString, criteriaID = GetAchievementCriteriaInfo(id, i);
                --print(criteriaString, "criteriaType: "..criteriaType, "criteriaID: "..criteriaID, "assetID: "..assetID)     --debug

                if criteriaType == 8 and assetID then     --Meta, CRITERIA_TYPE_ACHIEVEMENT
                    if completed then
                        numCompleted = numCompleted + 1;
                        local icon = DataProvider:GetAchievementInfo(assetID, 10);
                        tinsert(cData.icons, icon);
                        tinsert(cData.assetIDs, assetID);
                    else
                        numIncomplete = numIncomplete + 1;
                        local icon = DataProvider:GetAchievementInfo(assetID, 10);
                        tinsert(iData.icons, icon);
                        tinsert(iData.assetIDs, assetID);
                    end
                elseif bband(flags, 1) == 1 then     --EVALUATION_TREE_FLAG_PROGRESS_BAR = 1
                    if completed then
                        numCompleted = numCompleted + 1;
                        tinsert(cData.bars, {quantity, reqQuantity, criteriaString});
                    else
                        numIncomplete = numIncomplete + 1;
                        tinsert(iData.bars, {quantity, reqQuantity, criteriaString});
                    end
                else    --TextStrings
                    if completed then
                        numCompleted = numCompleted + 1;
                        criteriaString = "|CFF5fbb46" .. criteriaString .. "|r"; --00FF00
                        tinsert(cData.names, criteriaString);
                    else
                        numIncomplete = numIncomplete + 1;
                        criteriaString = "|CFF808080" .. criteriaString .. "|r";
                        tinsert(iData.names, criteriaString);
                    end
                end
            end
        end
    --end

    cData.count = numCompleted;
    iData.count = numIncomplete;

    InspectionFrame:DisplayCriteria(cData, iData);
end


local InspectCard;  --function

local function ShutInspection()
    InspectionFrame:Hide();
end

local function ToggleTracking(id)
    if not id then return end;

    if DataProvider:IsTrackedAchievement(id) then
        DataProvider:StopTracking(id);
    else
        local MAX_TRACKED_ACHIEVEMENTS = 10;
        if ( DataProvider.numTrackedAchievements >= MAX_TRACKED_ACHIEVEMENTS ) then
            UIErrorsFrame:AddMessage(format(ACHIEVEMENT_WATCH_TOO_MANY, MAX_TRACKED_ACHIEVEMENTS), 1.0, 0.1, 0.1, 1.0);
            return;
        end

        local _, _, _, completed, _, _, _, _, _, _, _, isGuild, wasEarnedByMe = DataProvider:GetAchievementInfo(id);
        if ( (completed and isGuild) or wasEarnedByMe ) then
            UIErrorsFrame:AddMessage(ERR_ACHIEVEMENT_WATCH_COMPLETED, 1.0, 0.1, 0.1, 1.0);
            return;
        end

        DataProvider:StartTracking(id);
        return true
    end
end

local function ProcessModifiedClick(button)
    local achievementID = button.id;
    if not achievementID then return true end

    local isModifiedClick = IsModifiedClick();
	if isModifiedClick then
		local handled = nil;
		if ( IsModifiedClick("CHATLINK") ) then
			local achievementLink = GetAchievementLink(achievementID);
			if ( achievementLink ) then
				handled = ChatEdit_InsertLink(achievementLink);
				if ( not handled and SocialPostFrame and Social_IsShown() ) then
					Social_InsertLink(achievementLink);
					handled = true;
				end
			end
		end
		if not handled then
            if IsModifiedClick("QUESTWATCHTOGGLE") and not IsAltKeyDown() then
                local isTracking = ToggleTracking(achievementID);
                button.trackIcon:SetShown(isTracking);
            end
            if IsAltKeyDown() then
                BookmarkUtil:ToggleBookmark(achievementID);
                button.BookmarkIcon:SetShown(BookmarkUtil:IsBookmarked(achievementID));
            end
        end
    end
    return isModifiedClick
end

local function AchievementCard_OnClick(self)
    if not ProcessModifiedClick(self) then
        InspectCard(self, true);
    end
end

local function FormatRewardText(id, rewardText)
    local rawText = rewardText;
    local rewardItemID = GetRewardItemID(id);
    local categoryText, colon, rewardName;

    if rewardItemID then
        categoryText, colon, rewardName = string.match(rewardText, "(.+)([:：]+)(.+)");
    end

    if categoryText and colon and rewardName then
        local itemID, itemType, itemSubType, _, icon, itemClassID, itemSubClassID = C_Item.GetItemInfoInstant(rewardItemID);
        local itemProcessed;
        if itemSubType == "Mount" then
            local mountID = C_MountJournal.GetMountFromItem(itemID);
            if mountID then
                local mountName = C_MountJournal.GetMountInfoByID(mountID);
                if mountName then
                    categoryText = MOUNT or categoryText;
                    rewardName = " "..mountName;
                    itemProcessed = true;
                end
            end
        elseif C_ToyBox.GetToyInfo(itemID) ~= nil then
            categoryText = TOY or categoryText;
            itemProcessed = true;
        else
            local petName = C_PetJournal.GetPetInfoByItemID(rewardItemID);
            if petName then
                categoryText = PET or categoryText;
                rewardName = " "..petName;
                itemProcessed = true;
            else

            end
        end

        if IS_DARK_THEME then
            rewardText = format("|cff808080%s%s|r|cff8950c6%s|r", categoryText, colon, rewardName);
        else
            rewardText = "|cffffd200"..categoryText..colon..rewardName.."|r";
        end

        if find(rawText, TITLE_REWARD_FORMAT) then
            if itemProcessed then
                if IS_DARK_THEME then
                    rawText = "|cffa3d39c"..rawText.."|r";
                end
                rewardText = rawText.."   "..rewardText;
            else
                if IS_DARK_THEME then
                    rewardText = "|cffa3d39c"..rawText.."|r";
                else
                    rewardText = rawText;
                end
            end
        end
    else
        if IS_DARK_THEME then
            rewardText = "|cffa3d39c"..rawText.."|r";
        else
            rewardText = "|cffffd200"..rewardText.."|r";
        end
    end

    return rewardText, rewardItemID
end

local function GetProgressivePoints(achievementID, basePoints)
	local points;
    local _, progressivePoints, completed
    if basePoints then
        progressivePoints = basePoints;
    else
        _, _, progressivePoints, completed = DataProvider:GetAchievementInfo(achievementID);
    end
    achievementID = GetPreviousAchievement(achievementID);
	while achievementID do
		_, _, points, completed = DataProvider:GetAchievementInfo(achievementID);
        progressivePoints = progressivePoints + points;
        achievementID = GetPreviousAchievement(achievementID);
	end

	if ( progressivePoints ) then
		return progressivePoints;
	else
		return 0;
	end
end


local function FormatAchievementCard(button, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe)
    if not button then
        return
    end
    local headerObject, numLines, textHeight;

    button.id = id;
    button.trackIcon:SetShown( DataProvider:IsTrackedAchievement(id) );
    button.BookmarkIcon:SetShown(BookmarkUtil:IsBookmarked(id));

    if ( not completed or ( not isGuild and not wasEarnedByMe ) ) and (showNotEarnedMark) then
        button.NotEarned:Show();
    else
        button.NotEarned:Hide();
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

    if IsAccountWide(flags) then
        if completed then
            if IS_DARK_THEME then
                headerObject:SetTextColor(0.427, 0.812, 0.965); --(0.427, 0.812, 0.965)(0.4, 0.755, 0.9)
            else
                headerObject:SetTextColor(1, 1, 1);
            end
        else
            if IS_DARK_THEME then
                headerObject:SetTextColor(0.214, 0.406, 0.484);
            else
                headerObject:SetTextColor(0.5, 0.5, 0.5);
            end
        end
    else
        if completed then
            if IS_DARK_THEME then
                headerObject:SetTextColor(0.9, 0.82, 0.58);  --(1, 0.91, 0.647); --(0.9, 0.82, 0.58) --(0.851, 0.774, 0.55)
            else
                headerObject:SetTextColor(1, 1, 1);
            end
        else
            if IS_DARK_THEME then
                headerObject:SetTextColor(0.5, 0.46, 0.324);
            else
                headerObject:SetTextColor(0.5, 0.5, 0.5);
            end
        end
    end

    points = GetProgressivePoints(id, points);
    if points == 0 then
        button.points:SetText("");
        button.lion:Show();
    else
        if points >= 100 then
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

    local rewardHeight;
    local shadowHeight = 0;
    if rewardText and rewardText ~= "" then
        local itemID;
        rewardHeight = 22;
        rewardText, itemID = FormatRewardText(id, rewardText);
        button.RewardFrame.reward:SetText(rewardText);
        button.RewardFrame.itemID = itemID;
        button.itemID = itemID;
        button.RewardFrame:Show();
    else
        if IS_DARK_THEME then
            rewardHeight = 2;
        else
            rewardHeight = 8;
        end
        button.RewardFrame:Hide();
        button.RewardFrame:SetHeight(2);
    end
    button.RewardFrame:SetHeight(rewardHeight);
    button.description:SetHeight(0);
    button.description:SetText(description);
    textHeight = floor( button.background:GetHeight() + 0.5 );
    local descriptionHeight = button.description:GetHeight();
    button.description:SetHeight(descriptionHeight + 2)
    numLines = ceil( descriptionHeight / 14 - 0.1 );
    button:SetHeight(72 + rewardHeight + 14*(numLines - 1) );
    button.shadow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 12, - 6 - numLines * 6 - shadowHeight);

    if IsAccountWide(flags) then     --ACHIEVEMENT_FLAGS_ACCOUNT
        if button.accountWide ~= true then
            button.accountWide = true;
            button.border:SetTexCoord(0.05078125, 0.94921875, 0.5, 1);
            button.bottom:SetTexCoord(0.05078125, 0.94921875, 0.985, 1);
        end
        if textHeight <= 288 then
            button.background:SetTexCoord(0.05078125, 0.94921875, 0.985 - textHeight/288/2, 0.985);
        else
            button.background:SetTexCoord(0.05078125, 0.94921875,  0.5, 0.985);
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
    end

    if completed then
        button.date:SetText( FormatDate(day, month, year) );
        button.RewardFrame.reward:SetAlpha(1);

        if (button.isDark == nil) or (button.isDark) then
            button.isDark = false;
            button.icon:SetDesaturated(false);
            button.points:SetTextColor(0.8, 0.8, 0.8);
            if IS_DARK_THEME then
                button.description:SetTextColor(0.72, 0.72, 0.72);
            else
                button.description:SetTextColor(0, 0, 0);
            end
            button.icon:SetVertexColor(1, 1, 1);
            button.lion:SetVertexColor(1, 1, 1);
            button.border:SetVertexColor(1, 1, 1);
            button.background:SetVertexColor(1, 1, 1);
            button.bottom:SetVertexColor(1, 1, 1);
            button.border:SetDesaturated(false);
            button.background:SetDesaturated(false);
            button.bottom:SetDesaturated(false);
        end
    else
        button.date:SetText("");
        button.RewardFrame.reward:SetAlpha(0.60);

        if (button.isDark == nil) or (not button.isDark) then
            button.isDark = true;
            button.icon:SetDesaturated(true);
            button.points:SetTextColor(0.6, 0.6, 0.6);
            if IS_DARK_THEME then
                button.description:SetTextColor(0.6, 0.6, 0.6);
            else
                button.description:SetTextColor(0, 0, 0);
            end
            button.icon:SetVertexColor(0.60, 0.60, 0.60);
            button.lion:SetVertexColor(0.60, 0.60, 0.60);
            button.border:SetVertexColor(0.60, 0.60, 0.60);
            button.background:SetVertexColor(0.72, 0.72, 0.72);
            button.bottom:SetVertexColor(0.72, 0.72, 0.72);
            button.border:SetDesaturation(0.6);
            button.background:SetDesaturation(0.6);
            button.bottom:SetDesaturation(0.6);
        end
    end
    
    button:SetShown(id);
end

local function FormatAchievementCardByIndex(buttonIndex, ...)
    local button = AchievementCards[buttonIndex];
    if button then
        FormatAchievementCard(button, ...);
        if buttonIndex > 7 or buttonIndex < 0 then
            button:SetAlpha(1);
        else
            button.toAlpha = 1;     --for flip animation
        end
    end
end

local function InspectAchievement(achievementID)
    if not achievementID then return end;

    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe = DataProvider:GetAchievementInfo(achievementID);
    local displayCard;
    if DataProvider:IsStatistic(achievementID) then
        displayCard = InspectionFrame.StatCard;
        InspectionFrame.Card:Hide();
        displayCard:SetData(achievementID);
        displayCard:Show();
        displayCard:SetAlpha(1);
        displayCard:ClearAllPoints();
        displayCard:SetPoint("BOTTOM", InspectionFrame, "CENTER", 0, 36);
    else
        displayCard = InspectionFrame.Card;
        InspectionFrame.StatCard:Hide();
        FormatAchievementCardByIndex(-1, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe);
    end
    animFlyOut.Card = displayCard;

    DisplayProgress(id, flags);
    InspectionFrame.currentAchievementID = id;
    InspectionFrame.currentAchievementName = name;
    InspectionFrame:Show();
    InspectionFrame.HotkeyShiftClick:Show();
    InspectionFrame.GetLink:Show();

    local itemID = GetRewardItemID(id);
    if itemID then
        MountPreview:SetItem(itemID);
    else
        HideItemPreview();
    end

    InspectionFrame:UpdateChain(id, completed);
    InspectionFrame:FindParentAchievementID(id);
    GoToCategoryButton:SetAchievement(id, isGuild);

    return completed, displayCard:GetHeight()/2
end

local function FormatStatCard(buttonIndex, id)
    local button = StatCardController:Accquire(buttonIndex);
    if button then
        button:SetData(id);
    end
end

ScrollUtil.heightData = {};
ScrollUtil.achievementID = {};
ScrollUtil.totalHeight = 0;
ScrollUtil.positionToButton = {};
ScrollUtil.formatFunc = FormatAchievementCardByIndex;

function ScrollUtil:ResetHeights()
    self.totalHeight = 18;
    self.position = 1;
    self.lastOffset = 0;
    self.nextOffset = 0;
    self.heightData = {};
end

function ScrollUtil:GetScrollRange()
    local range = self.totalHeight - (AchievementContainer:GetHeight() or 0) + 18;
    if range < 0 then
        range = 0;
    end
    return range;
end

function ScrollUtil:SetCardData(cardIndex, achievementID, description, rewardText)
    local rewardHeight;
    if rewardText and rewardText ~= "" then
        rewardHeight = 22;
    else
        if IS_DARK_THEME then
            rewardHeight = 2;
        else
            rewardHeight = 8;
        end
    end
    self.textReference:SetText("");
    self.textReference:SetHeight(0);
    self.textReference:SetText(description);
    local descriptionHeight = self.textReference:GetHeight();
    local numLines = ceil( descriptionHeight / 14 - 0.1 );
    local buttonHeight = 72 + rewardHeight + 14*(numLines - 1) + 4;     --4 is the Gap

    self.heightData[cardIndex] = self.totalHeight;
    self.achievementID[cardIndex] = achievementID;
    self.totalHeight = self.totalHeight + buttonHeight;

    return buttonHeight;
end

function ScrollUtil:SetStatCardData(cardIndex, achievementID)
    local buttonHeight;
    if achievementID < 0 then
        buttonHeight = 48;
    else
        if IsBossCard(achievementID) then
            --boss card
            buttonHeight = 94;
        else
            buttonHeight = 72;
        end
    end

    self.heightData[cardIndex] = self.totalHeight;
    self.achievementID[cardIndex] = achievementID;
    self.totalHeight = self.totalHeight + buttonHeight;

    return buttonHeight;
end

function ScrollUtil:GetTopButtonIndex(scrollOffset)
    if scrollOffset > self.nextOffset then
        local p = self.position + 1;
        if self.heightData[p] then
            self.position = p;
            self.lastOffset = self.heightData[p];
            self.nextOffset = self.heightData[p + 1];
            self:UpdateScrollChild(-1);
        end
    elseif scrollOffset < self.lastOffset then
        local p = self.position - 1;
        if self.heightData[p] then
            self.nextOffset = self.heightData[p + 1];
            self.lastOffset = self.heightData[p];
            if p < 1 then
                p = 1;
            end
            self.position = p;
            self:UpdateScrollChild(1);
        end
    end
end

function ScrollUtil:UpdateScrollChild(direction)
    if direction < 0 then
        local topButton = tremove(self.activeCards, 1);
        tinsert(self.activeCards, topButton);
    elseif direction > 0 then
        local bottomButton = tremove(self.activeCards);
        tinsert(self.activeCards, 1, bottomButton);
    end
    self.positionToButton = {};
    local p = self.position;
    local id;
    local positionIndex;
    local realID, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe;
    local card;
    for i = 1, NUM_ACHIEVEMENT_CARDS do
        card = self.activeCards[i];
        if not card then break end;
        positionIndex = p + i - 1;
        card.positionIndex = positionIndex;
        --card.TableIndex:SetText(i);
        if self.heightData[positionIndex] then
            card:SetPoint("TOP", AchievementContainer.ScrollChild, "TOP", 0, -self.heightData[positionIndex]);
            self.positionToButton[positionIndex] = card;
            id = self.achievementID[positionIndex];
            if id then
                if card.id ~= id then
                    realID, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe = DataProvider:GetAchievementInfo(id);
                    self.formatFunc(i, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe);
                    card:Show();
                else
                    card:Show();
                end
            else
                card:Hide();
            end
        else
            card:Hide();
        end
    end
end

function ScrollUtil:GetOffsetByPositionIndex(index)
    return self.heightData[index] or 0
end

function ScrollUtil:GetAchievementIDByPositionIndex(index)
    return self.achievementID[index];
end

function ScrollUtil:GetCardByPositionIndex(index)
    return self.positionToButton[index];
end

function InspectCard(button, playAnimation)    --Private
    local index = button.positionIndex;
    if not index then return end;

    local Card = InspectionFrame.Card;
    local id = button.id;
    Card:ClearAllPoints();
    Card:SetPoint("BOTTOM", InspectionFrame, "CENTER", 0, 36);

    InspectionFrame.pauseScroll = nil;
    InspectionFrame.dataIndex = index;

    local numAchievements = InspectionFrame.numAchievements;

    if index <= 1 then
        index = 1;
        InspectionFrame.PrevButton:Disable();
        InspectionFrame.NextButton:Enable();
        InspectionFrame.NextButton:Show();
    elseif index >= numAchievements then
        index = numAchievements;
        InspectionFrame.PrevButton:Enable();
        InspectionFrame.PrevButton:Show();
        InspectionFrame.NextButton:Disable();
    else
        InspectionFrame.PrevButton:Enable();
        InspectionFrame.NextButton:Enable();
        InspectionFrame.PrevButton:Show();
        InspectionFrame.NextButton:Show();
    end
    if numAchievements > 0 then
        InspectionFrame.HotkeyMouseWheel:Show();
    else
        InspectionFrame.HotkeyMouseWheel:Hide();
    end

    local completed, extraY = InspectAchievement(id);

    --Animation
    local x0, y0 = InspectionFrame:GetCenter();
    local x1, y1 = button:GetCenter();
    local offsetX = x1 - x0;
    local offsetY = y1 - y0 - extraY;

    --animFlyIn.fromX, animFlyIn.fromY = offsetX, offsetY;
    animFlyOut.toX, animFlyOut.toY = offsetX, offsetY;
    animFlyOut.button = button;
    animFlyOut.duration = max(0.2, 0.2*(sqrt(offsetX^2 + (offsetY - 36)^2))/150 );

    if playAnimation then
        InspectionFrame:SyncBlurOffset(index);
        animFlyIn:Play();
        if DataProvider:IsStatistic(id) then
            InspectionFrame.StatCard:SetAlpha(0);
            FadeFrame(InspectionFrame.StatCard, 0.2, 1);
        end
    end
end


local function Slice_UpdateAchievementCards(categoryID, startIndex)
    --from 1st complete achievement to bottom
    local slice = 4;
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe;
    local processComplete = false;
    local numProcessed = 0;
    
    --print("process: "..startIndex);
    for i = startIndex, startIndex + slice do
        id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe = DataProvider:GetAchievementInfoByOrder(categoryID, i);
        if i > 0 and id then
            if i <= NUM_ACHIEVEMENT_CARDS then
                FormatAchievementCardByIndex(i, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe);
            end
            ScrollUtil:SetCardData(i, id, description, rewardText);
            numProcessed = i;
        else
            processComplete = true;
            break;
        end
    end

    return numProcessed + 1, processComplete
end

local function Slice_ReverselyUpdateAchievementCards_Callback(categoryID, startIndex)
    --from 1st complete achievement to 1st incomplete
    local slice = 4;
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe;
    local processComplete = false;
    local numProcessed = 0;
    local numAchievements, numCompleted, numIncomplete = GetCategoryNumAchievements(categoryID, false);
    local index;
    for i = startIndex, startIndex + slice do
        id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe = DataProvider:GetAchievementInfoByOrder(categoryID, i);
        if i <= numCompleted then
            index = i + numIncomplete;
            if i <= NUM_ACHIEVEMENT_CARDS then
                FormatAchievementCardByIndex(index, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe);
            end
            ScrollUtil:SetCardData(index, id, description, rewardText);
            numProcessed = i;
        else
            processComplete = true;
            break;
        end
    end

    return numProcessed + 1, processComplete
end

local function Slice_ReverselyUpdateAchievementCards(categoryID, startIndex)
    --from 1st incomplete achievement to the bottom
    local slice = 4;
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe;
    local processComplete = false;
    local numProcessed = 0;
    local numAchievements, numCompleted = GetCategoryNumAchievements(categoryID, false);

    --print("reverse process: "..startIndex);
    for i = startIndex, startIndex + slice do
        id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe = DataProvider:GetAchievementInfoByOrder(categoryID, numCompleted + i);
        if id then
            --print("id #"..id)
            if not completed then
                if i <= NUM_ACHIEVEMENT_CARDS then
                    FormatAchievementCardByIndex(i, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe);
                end
                ScrollUtil:SetCardData(i, id, description, rewardText);
                numProcessed = i;
            end
        else
            --print("Break, begin forward")
            processor:Hide();
            processor.arg1 = categoryID;
            processor.arg2 = 1;     --startIndex
            processor.func = Slice_ReverselyUpdateAchievementCards_Callback  --Slice_UpdateAchievementCards;
            processor:Show();
            return 1, false
        end
    end

    return numProcessed + 1, processComplete
end

local function Slice_UpdateStatCards(categoryID, startIndex)
    --from 1st complete achievement to bottom
    local slice = 4;
    local id;
    local processComplete = false;
    local numProcessed = 0;

    for i = startIndex, startIndex + slice do
        id = GetStatisticInfo(categoryID, i);
        if i > 0 and id then
            ScrollUtil:SetStatCardData(i, id);
            numProcessed = i;
        else
            processComplete = true;
            break;
        end
    end

    return numProcessed + 1, processComplete
end

local function Slice_UpdateToDoList(categoryID, startIndex)
    local slice = 4;
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe;
    local processComplete = false;
    local numProcessed = 0;

    for i = startIndex, startIndex + slice do
        id = BookmarkUtil:GetAchievementIDInCategory(categoryID, i);
        id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe = DataProvider:GetAchievementInfo(id);
        if i > 0 and id then
            if i <= NUM_ACHIEVEMENT_CARDS then
                FormatAchievementCardByIndex(i, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe);
            end
            ScrollUtil:SetCardData(i, id, description, rewardText);
            numProcessed = i;
        else
            processComplete = true;
            break;
        end
    end

    return numProcessed + 1, processComplete
end

local function UpdateAchievementScrollRange()
    local scrollBar = AchievementContainer.scrollBar;
    local range = ScrollUtil:GetScrollRange();
    scrollBar:SetMinMaxValues(0, range);
    AchievementContainer.range = range;
    scrollBar:SetShown(range ~= 0);
end

processor.func = Slice_ReverselyUpdateAchievementCards  --Slice_UpdateAchievementCards;
processor.callback = UpdateAchievementScrollRange;


local animFlip = CreateFrame("Frame");

function animFlip:Play(groupIndex)
    self:Hide();
    self.t = 0;
    local objects;
    if groupIndex == 1 then
        objects = AchievementCards;
    else
        return
    end
    local numObjects = #objects;
    numObjects = min(numObjects, 6);
    for i = 1, numObjects do
        objects[i]:SetAlpha(0);
    end

    local oT, card;
    local scale, offset1, offset2, alpha;
    local fullDuration = numObjects * 0.05 + 0.4;
    self:SetScript("OnUpdate", function(f, elapsed)
        self.t = self.t + elapsed;
        for i = 1, numObjects do
            oT = self.t - 0.05 * (i - 1);
            if oT > 0 then
                if oT < 0.4 then
                    scale = outQuart(oT, 1.25, 1, 0.4);
                    offset1 = outQuart(oT, 24, 0, 0.4);
                    offset2 = outQuart(oT, -72, -48, 0.4);
                    alpha = min(1, linear(oT, 0, 1, 0.25));
                else
                    scale = 1;
                    offset1 = 0;
                    offset2 = -48;
                    alpha = 1;
                end
                card = objects[i];
                card:SetAlpha(alpha);
                card.border:SetPoint("TOP", 0, offset1);
                card.description:SetPoint("TOP", 0, offset2);
                card.points:SetScale(scale);
                card.icon:SetScale(scale);
                card.lion:SetScale(scale);
                card.border:SetScale(scale);
            end
        end
        if self.t > fullDuration then
            self:Hide();
        end
    end);
    self:Show();
end


local SORT_FUNC = Slice_ReverselyUpdateAchievementCards;
local function UpdateAchievementCardsBySlice(categoryID)
    ScrollUtil:ResetHeights();

    processor:Hide();
    AchievementContainer.scrollBar:SetValue(0);
    for i = 1, NUM_ACHIEVEMENT_CARDS do
        AchievementCards[i]:Hide();
    end

    local numAchievements, numCompleted, numIncomplete = GetCategoryNumAchievements(categoryID, false);
    DataProvider.numAchievements = numAchievements;
    processor.arg1 = categoryID;
    processor.arg2 = 1;     --fromIndex
    processor.func = SORT_FUNC;
    processor:Start();

    --animation
    if numAchievements ~= 0 then
        animFlip:Play(1);
    end
end

local function SwitchToSortMethod(index)
    if index == 2 then
        SORT_FUNC = Slice_UpdateAchievementCards;
    else
        SORT_FUNC = Slice_ReverselyUpdateAchievementCards;
    end

    local categoryID = DataProvider.currentCategory;
    if categoryID and categoryID > 0 then
        UpdateAchievementCardsBySlice(categoryID);
    end
end

local function UpdateStatCardsBySlice(categoryID)
    ScrollUtil:ResetHeights();
    processor:Hide();
    AchievementContainer.scrollBar:SetValue(0);
    local card;
    local numAchievements = GetCategoryNumAchievements(categoryID, false);
    local numCards = math.min(numAchievements, NUM_ACHIEVEMENT_CARDS);
    for i = 1, numCards do
        card = StatCardController:Accquire(i);
        card:Show();
        --card:SetStat(categoryID, i);
    end
    StatCardController:HideRest(numCards + 1);

    DataProvider.numAchievements = numAchievements;
    processor.arg1 = categoryID;
    processor.arg2 = 1;     --fromIndex
    processor.func = Slice_UpdateStatCards;
    processor:Start();

    StatCardController:PlayAnimation();
end

local function UpdateToDoListBySlice(categoryID)
    ScrollUtil:ResetHeights();
    processor:Hide();
    AchievementContainer.scrollBar:SetValue(0);
    for i = 1, NUM_ACHIEVEMENT_CARDS do
        AchievementCards[i]:Hide();
    end

    local numAchievements = BookmarkUtil:GetNumAchievementsInCategory(categoryID);
    DataProvider.numAchievements = numAchievements;
    processor.arg1 = categoryID;
    processor.arg2 = 1;     --fromIndex
    processor.func = Slice_UpdateToDoList;
    processor:Start();

    --animation
    if numAchievements ~= 0 then
        animFlip:Play(1);
    end
end

---------------------------------------------------------------------------------------------------
local function UpdateCategoryScrollRange()
    local button, buttons;
    local totalHeight = 0;
    local parentButtons = CategoryButtons:GetActiveParentButtons();
    if not parentButtons then return end;

    for i = 1, #parentButtons do
        button = parentButtons[i];
        if button.expanded then
            totalHeight = totalHeight + ( button.expandedHeight or 32);
        else
            totalHeight = totalHeight + 32;
        end

        totalHeight = totalHeight + 4;
    end

    local scrollBar = CategoryContainer.scrollBar;
    local newRange = max(0, totalHeight - CategoryContainer:GetHeight() + 52);
    local _, oldRange = scrollBar:GetMinMaxValues();

    CategoryContainer.positionFunc = nil;
    if (newRange < oldRange) and (scrollBar:GetValue() > newRange) then
        CategoryContainer.positionFunc = function(endValue, delta, scrollBar)
            if scrollBar:GetValue() <= newRange then
                CategoryContainer.positionFunc = nil;
                scrollBar:SetShown(newRange ~= 0);
                scrollBar:SetMinMaxValues(0, newRange);
                CategoryContainer.range = newRange;
            end
        end
    else
        scrollBar:SetShown(newRange ~= 0);
        scrollBar:SetMinMaxValues(0, newRange);
        CategoryContainer.range = newRange;
    end
end


local animExpand = NarciAPI_CreateAnimationFrame(0.25);
animExpand:SetScript("OnUpdate", function(self, elapsed)
    self.total = self.total + elapsed;
    local height = outSine(self.total, self.fromHeight, self.toHeight, self.duration);
    if self.total >= self.duration then
        self:Hide()
        height = self.toHeight;
    end
    animExpand.object:SetHeight(height);
end)

function animExpand:Set(object, toHeight)
    if self:IsShown() then
        if object == self.object then
            self:Hide();
        else
            --Snap to destination
            self.object:SetHeight(self.toHeight);
            self:Hide();
        end
    end
    local fromHeight = object:GetHeight();
    self.object = object;
    self.fromHeight = fromHeight;
    self.toHeight = toHeight;
    local duration = sqrt(abs(fromHeight - toHeight)/32)*0.085;
    if duration > 0.01 then
        self.duration = duration;
        self:Show();
    end
end

function animExpand:CollapseAll()
    self:Hide();
    local button;
    local parentButtons = CategoryButtons:GetActiveParentButtons();

    for i = 1, #parentButtons do
        button = parentButtons[i];
        button.box:SetHeight(32);
        button.drawer:Hide();
        button.drawer:SetAlpha(0);
        button.expanded = nil;
        if not (button.isStats or button.isToDo) then
            button.progress:Hide();
            button.percentSign:Show();
            button.value:Show();
        end
    end
    local lastButton = DataProvider:GetCategoryButtonByID(DataProvider.currentCategory);
    if lastButton then
        lastButton.label:SetTextColor(0.8, 0.8, 0.8);
    end

    CategoryContainer.scrollBar:SetValue(0);
    UpdateCategoryScrollRange();
end


local function SetCategoryButtonProgress(button, numAchievements, numCompleted, isFeatsOfStrength)
    if numAchievements == 0 or numCompleted == 0 then
        button.fill:Hide();
        button.fillEnd:Hide();
        button.progress:SetText(0 .."/".. numAchievements);
    else
        if isFeatsOfStrength then
            button.fill:Hide();
            button.fillEnd:Hide();
            button.progress:SetText(numCompleted);
        else
            local percentage = numCompleted / numAchievements;
            if percentage == 1 then
                button.fill:Hide();
                button.fillEnd:Hide();
                button.progress:SetText(numAchievements);
                button.label:SetPoint("LEFT", 27, 0);
                button.greenCheck:Show();
            else
                button.fill:Show();
                button.fillEnd:Show();
                button.fill:SetWidth(button.fillWidth * percentage);
                button.fill:SetTexCoord(0, percentage *  0.75, 0, 1);
                button.progress:SetText(numCompleted .."/".. numAchievements);
                button.label:SetPoint("LEFT", 10, 0);
                button.greenCheck:Hide();
            end
        end
    end
    button.progress:Show();
    button.percentSign:Hide();
    button.value:Hide();
    button.numAchievements, button.numCompleted = numAchievements, numCompleted;
end

local function UpdateCategoryButtonProgress(button)
    local categoryID = button.id;

    if button.isToDo then
        local numAchievements = BookmarkUtil:GetNumAchievementsInCategory(categoryID);
        button.progress:SetText(numAchievements);
        button.progress:Show();
        button.percentSign:Hide();
        button.value:Hide();
        return
    end

    local totalAchievements, totalCompleted = GetCategoryNumAchievements(categoryID, true);   --ACHIEVEMENT_COMPARISON_SUMMARY_ID

    button.numAchievements, button.numCompleted = totalAchievements, totalCompleted;

    if button.isStats then
        button.progress:SetText(totalAchievements);
        button.progress:Show();
        button.percentSign:Hide();
        button.value:Hide();
        if button.subCategories then
            local numAchievements;
            for i = 1, #button.subCategories do
                categoryID = button.subCategories[i];
                numAchievements = GetCategoryNumAchievements(categoryID, true);
                totalAchievements = totalAchievements + numAchievements;
                local childButton = DataProvider:GetCategoryButtonByID(categoryID);
                if childButton then
                    childButton.progress:SetText(numAchievements);
                    childButton.progress:Show();
                    childButton.percentSign:Hide();
                    childButton.value:Hide();
                end
            end
        end
        return
    end

    local noPercent = button.noPercent;
    if noPercent then
        button.progress:SetText(totalCompleted);
    else
        button.progress:SetText(totalCompleted .."/".. totalAchievements);
    end

    if button.expanded then
        button.progress:Show();
        button.percentSign:Hide();
        button.value:Hide();
    else
        button.progress:Hide();
        button.percentSign:Show();
        button.value:Show();
    end


    if button.subCategories then
        local numAchievements, numCompleted;
        for i = 1, #button.subCategories do
            categoryID = button.subCategories[i];
            numAchievements, numCompleted = GetCategoryNumAchievements(categoryID, true);
            totalAchievements = totalAchievements + numAchievements;
            totalCompleted = totalCompleted + numCompleted;
            local childButton = DataProvider:GetCategoryButtonByID(categoryID);
            if childButton then
                SetCategoryButtonProgress(childButton, numAchievements, numCompleted, noPercent);
            end
        end
    end

    button.totalAchievements, button.totalCompleted = totalAchievements, totalCompleted;

    if totalAchievements == 0 or totalCompleted == 0 then
        button.fill:Hide();
        button.fillEnd:Hide();
        button.value:SetText("0");
    else
        if noPercent then
            button.fill:Hide();
            button.fillEnd:Hide();
            button.value:SetText(totalCompleted);
        else
            button.fill:Show();
            button.fillEnd:Show();

            local percentage = totalCompleted / totalAchievements;
            button.fill:SetWidth(button.fillWidth * percentage);
            button.fill:SetTexCoord(0, percentage *  0.75, 0, 1);
            if percentage == 1 then
                button.value:SetText("100");
            else
                button.value:SetText( floor(100 * percentage) );
            end
        end
    end
end

local function UpdateCategoryButtonProgressByCategoryID(categoryID)
    local button = DataProvider:GetCategoryButtonByID(categoryID);
    if button then
        UpdateCategoryButtonProgress(button)
    end
end

local function ReleaseAchievementCard()
    for _, card in pairs(AchievementCards) do
        --card:ClearAllPoints();
        card:Hide();
    end
end

local function SelectCategory(categoryID)
    if IS_STAT_CATEGORY[categoryID] then
        --statistics
        AchievementContainer:Show();
        ScrollUtil.formatFunc = FormatStatCard;
        ScrollUtil.activeCards = StatCardController:GetTable();
        UpdateStatCardsBySlice(categoryID);
        ReleaseAchievementCard();
        SummaryFrame:Hide();
        InspectionFrame.numAchievements = GetCategoryNumAchievements(categoryID, false);
    else
        AchievementContainer:Show();
        ScrollUtil.formatFunc = FormatAchievementCardByIndex;
        ScrollUtil.activeCards = AchievementCards;
        StatCardController:ReleaseAll();
        if categoryID == -1 then
            UpdateSummaryFrame();
            SummaryFrame:Show();
        elseif TabUtil:IsToDoList() then
            UpdateToDoListBySlice(categoryID);
            SummaryFrame:Hide();
            InspectionFrame.numAchievements = BookmarkUtil:GetNumAchievementsInCategory(categoryID);
        else
            UpdateAchievementCardsBySlice(categoryID);
            SummaryFrame:Hide();
            InspectionFrame.numAchievements = GetCategoryNumAchievements(categoryID, false);
        end
    end
end

local function ToggleFeatOfStrenghtText(button)
    if button.isFoS then
        local _, totalCompleted = GetCategoryNumAchievements(button.id, false);
        if totalCompleted == 0 then
            if isGuildView then
                MainFrame.FeatOfStrengthText:SetText(GUILD_FEAT_OF_STRENGTH_DESCRIPTION);
            else
                MainFrame.FeatOfStrengthText:SetText(FEAT_OF_STRENGTH_DESCRIPTION);
            end
            MainFrame.FeatOfStrengthText:Show();
        else
            MainFrame.FeatOfStrengthText:Hide();
        end
    else
        MainFrame.FeatOfStrengthText:Hide();
    end
end

local function SubCategoryButton_OnClick(button)
    local categoryID = button.id;
    if categoryID ~= DataProvider.currentCategory then
        --print(categoryID);
        local lastButton = DataProvider:GetCategoryButtonByID(DataProvider.currentCategory);
        DataProvider.currentCategory = categoryID;
        if lastButton then
            lastButton.label:SetTextColor(0.8, 0.8, 0.8);
        end

        if button.isToDo then
            --Some hack
            for _, b in pairs(ToDoListData.buttons) do
                b.label:SetTextColor(0.8, 0.8, 0.8);
            end
        end

        button.label:SetTextColor(1, 0.91, 0.647);
        SelectCategory(categoryID);
    else
        --print("old")
    end
    ToggleFeatOfStrenghtText(button);
end

local function CategoryButton_OnClick(button, mouse)
    SummaryButton:Show();

    local expandedHeight = button.expandedHeight;
    local isExpanded = not button.expanded;
    if expandedHeight ~= 32 then
        if (mouse == "RightButton" or DataProvider.currentCategory == button.id) and (not isExpanded) then
            FadeFrame(button.drawer, 0.15, 0);
            animExpand:Set(button.box, 32);
            button.expanded = nil;
        else
            FadeFrame(button.drawer, 0.2, 1);
            animExpand:Set(button.box, expandedHeight);
            button.expanded = true;
            if mouse ~= "RightButton" then
                SubCategoryButton_OnClick(button);
            end
        end
    else
        button.expanded = isExpanded;
        SubCategoryButton_OnClick(button);
    end

    if button.isStats then

    elseif button.isToDo then
        
    else
        if button.expanded then
            button.progress:Show();
            button.percentSign:Hide();
            button.value:Hide();
        else
            button.progress:Hide();
            button.percentSign:Show();
            button.value:Show();
        end
    end


    UpdateCategoryScrollRange();


    ----
    ToggleFeatOfStrenghtText(button);
end

local function ExpandCategoryButtonNoAnimation(button)
    if not button then return end;

    if not button.expanded then
        button.progress:Show();
        button.percentSign:Hide();
        button.value:Hide();

        local expandedHeight = button.expandedHeight;
        if expandedHeight ~= 32 then
            button.box:SetHeight(expandedHeight);
            button.drawer:Show();
            button.drawer:SetAlpha(1);
        end
        button.expanded = true;

        UpdateCategoryScrollRange();
        ToggleFeatOfStrenghtText(button);
    end
end

local function BuildCategoryStructure(tabID)
    local GUILD_FEAT_OF_STRENGTH_ID = 15093;
    local GUILD_CATEGORY_ID = 15076;


    local categories, structure, feats, legacys;
    local IsToDoList;

    if tabID == 2 then
        categories = GetGuildCategoryList();
        structure = CategoryStructure.guild;
        feats = { FEAT_OF_STRENGTH_ID };
        legacys = {};
    elseif tabID == 1 then
        categories = GetCategoryList();
        structure = CategoryStructure.player;
        feats = { GUILD_FEAT_OF_STRENGTH_ID };
        legacys = { LEGACY_ID };
    elseif tabID == 3 then
        categories = GetStatisticsCategoryList();
        structure = CategoryStructure.stats;
        feats = {};
        legacys = {};
        tinsert(categories, 12080000);  --reserved for Narcissus Stat
        for k, id in pairs(categories) do
            IS_STAT_CATEGORY[id] = true;
        end
    elseif tabID == 5 then
        IsToDoList = true;
        ToDoListData.structure = {};    --To-do list category may change
        categories = BookmarkUtil:GetCategoryList();
        structure = ToDoListData.structure;
        feats = {};
        legacys = {};
    end

    local id;
    local name, parentID;
    local id2Order = {};
    local subCategories = {};

    local numParent = 0;

    for i = 1, #categories do
        id = categories[i];
        name, parentID = DataProvider:GetCategoryInfo(id);

        if DataProvider:IsRootCategory(id) then
            if not id2Order[id] then
                numParent = numParent + 1;
                structure[ numParent ] = { ["id"] = id, ["name"] = name, ["children"] = {} };
                id2Order[ id ] = numParent;
            end
        else
            tinsert(subCategories, id);

            if IsToDoList then
                --Bookmarked achievement may not be a Root Category, so we need to create that
                if not id2Order[parentID] then
                    numParent = numParent + 1;
                    name = DataProvider:GetCategoryInfo(parentID);
                    structure[ numParent ] = { ["id"] = parentID, ["name"] = name, ["children"] = {} };
                    id2Order[ parentID ] = numParent;
                end
            end
        end

        if parentID == LEGACY_ID then
            tinsert(legacys, id);
        elseif parentID == FEAT_OF_STRENGTH_ID then
            tinsert(feats, id);
        end
    end

    local order;
    for i = 1, #subCategories do
        id = subCategories[i];
        name, parentID = DataProvider:GetCategoryInfo(id);

        order = id2Order[parentID];
        if order then
            tinsert( structure[ order ].children,  id);
        end
    end

    structure.numCategories = #categories;
end

local function SetCategoryButtonType(categoryButton, index)
    if index == categoryButton.categoryType then return end;
    categoryButton.categoryType = index;

    if index == 1 then  --Category
        categoryButton:SetWidth(208);
        categoryButton.fillWidth = 198;
        categoryButton.background:SetTexture(TEXTURE_PATH.."CategoryButton");
        categoryButton.background:SetTexCoord(0.125, 0.875, 0, 1);
    elseif index == 2 then  --Subcategory
        categoryButton:SetWidth(192);
        categoryButton.fillWidth = 182;
        categoryButton.background:SetTexture(TEXTURE_PATH.."SubCategoryButton");
        categoryButton.background:SetTexCoord(0.203125, 0.875, 0, 1);
    end
end

local function CreateCategoryButtons(tabID)
    local frame;
    local button, parentButton, parentData, id;
    local structure;
    local numButtons = 0;
    local parentButtons, buttons;

    if not CategoryButtons.buttons then
        CategoryButtons.buttons = {};
    end

    local isStats, isToDo;
    local parentButtons = CategoryButtons:GetActiveParentButtons(tabID);

    if tabID == 1 then
        buttons = CategoryButtons.player.buttons;
        structure = CategoryStructure.player;
        frame = CategoryContainer.ScrollChild.PlayerCategory;
        --CategoryContainer.ScrollChild.GuildCategory:Hide();
    elseif tabID == 2 then
        buttons = CategoryButtons.guild.buttons;
        structure = CategoryStructure.guild;
        frame = CategoryContainer.ScrollChild.GuildCategory;
        --CategoryContainer.ScrollChild.PlayerCategory:Hide();
    elseif tabID == 3 then
        buttons = CategoryButtons.stats.buttons;
        structure = CategoryStructure.stats;
        frame = CategoryContainer.ScrollChild.StatsCategory;
        isStats = true;
        --CategoryContainer.ScrollChild.GuildCategory:Hide();
    elseif tabID == 5 then
        buttons = ToDoListData.buttons;
        structure = ToDoListData.structure;
        frame = CategoryContainer.ScrollChild.ToDoCategory;
        ToDoListData.parentButtons = {};
        parentButtons = ToDoListData.parentButtons;
        isToDo = true;
    end
    --frame:Show();

    for i = 1, #structure do
        numButtons = numButtons + 1;
        parentButton = buttons[numButtons];
        parentData = structure[i];
        id = parentData.id;
        if not parentButton then
            parentButton = CreateFrame("Button", nil, frame, "NarciAchievementCategoryButtonTemplate");
            tinsert(buttons, parentButton);
        else
            SetCategoryButtonType(parentButton, 1);
        end
        if not DataProvider.id2Button[id] then
            DataProvider.id2Button[id] = parentButton;
        end
        tinsert(parentButtons, parentButton);
        parentButton:SetScript("OnClick", CategoryButton_OnClick);
        parentButton.isParentButton = true;
        parentButton:SetParent(frame);
        parentButton:ClearAllPoints();

        if i == 1 then
            parentButton:SetPoint("TOP", frame, "TOP", 2 , -24);
        else
            parentButton:SetPoint("TOP", parentButtons[i - 1].box, "BOTTOM", 0, -2);
        end

        if id == LEGACY_ID or id == FEAT_OF_STRENGTH_ID or id == 15093 then
            parentButton.noPercent = true;
            parentButton.percentSign:SetText("");
            parentButton.value:SetPoint("RIGHT", parentButton, "RIGHT", -10, 0);
            if id == FEAT_OF_STRENGTH_ID or id == 15093 then
                parentButton.isFoS = true;
            end
        else
            parentButton.noPercent = nil;
            parentButton.percentSign:SetText("%");
            parentButton.value:SetPoint("RIGHT", parentButton, "RIGHT", -16, 0);
        end

        parentButton.id = id;
        parentButton.label:SetText(parentData.name);
        parentButton.subCategories = parentData.children;

        local numChildren = #parentData.children;
        parentButton.expandedHeight = numChildren * 32 + 32;

        parentButton.isStats = (isStats and true) or nil;
        parentButton.isToDo = (isToDo and true) or nil;

        for j = 1, numChildren do
            numButtons = numButtons + 1;
            button = buttons[numButtons];
            id = parentData.children[j];
            if not button then
                button = CreateFrame("Button", nil, parentButton.drawer, "NarciAchievementSubCategoryButtonTemplate");
                button.label:SetWidth(130);
                tinsert(buttons, button);
            else
                SetCategoryButtonType(button, 2);
            end
            button:SetScript("OnClick", SubCategoryButton_OnClick);
            if not DataProvider.id2Button[id] then
                DataProvider.id2Button[id] = button;
            end
            button.isParentButton = nil;
            button:SetParent(parentButton.drawer);

            button:ClearAllPoints();
            button:SetPoint("TOPRIGHT", parentButton.drawer, "BOTTOMRIGHT", 0, 32*(1-j));

            button.id = id;
            button.label:SetText( DataProvider:GetCategoryInfo(id, 1) );
            button.noPercent = nil;

            button.isStats = (isStats and true) or nil;
            button.isToDo = (isToDo and true) or nil;
        end

        UpdateCategoryButtonProgress(parentButton);
    end

    for i = numButtons + 1, #buttons do
        buttons[i]:Hide();
        buttons[i]:ClearAllPoints();
    end
end


local function CreateAchievementButtons(frame)
    local button;
    local buttons = {};
    local numButtons = 0;

    for i = 1, NUM_ACHIEVEMENT_CARDS do
        button = CreateFrame("Button", nil, frame, "NarciAchievementLargeCardTemplate");
        button:SetScript("OnClick", AchievementCard_OnClick);
        button.index = i;
        --button.AbsoluteIndex:SetText(i)
        tinsert(buttons, button);
        if i == 1 then
            button:SetPoint("TOP", frame, "TOP", 0, -18);
        else
            button:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, -4);
        end
        ReskinButton(button);
    end

    frame.buttons = buttons;
    AchievementCards = buttons;

    --Pop-up Card : Achievement details
    local Card = InspectionFrame.Card
    Card:SetScript("OnClick", AchievementCard_OnClick);
    AchievementCards[-1] = Card;
    animFlyIn.Card = Card;
    animFlyOut.Card = Card;
    animFlyIn.header = Card.header;
    animFlyIn.description = Card.description;
    animFlyIn.date = Card.date;
    animFlyIn.reward = Card.RewardFrame;
end

------------------------------------------------
NarciAchievementInspectionFrameMixin = {};

function NarciAchievementInspectionFrameMixin:OnLoad()
    if not self.isLoaded then
        self.isLoaded = true;
    else
        return
    end

    InspectionFrame = self;

    local CompleteFrame = self.CriteriaFrame.LeftInset;
    CompleteFrame.header:SetText(string.upper(CRITERIA_COMPLETED or "Completed"));
    CompleteFrame.header:SetTextColor(0.216, 0.502, 0.2);
    CompleteFrame.count:SetTextColor(0.216, 0.502, 0.2);
    self.numCompleted = CompleteFrame.count;

    local IncompleteFrame = self.CriteriaFrame.RightInset;
    IncompleteFrame.header:SetText(string.upper(INCOMPLETE or "Incomplete"));
    IncompleteFrame.header:SetTextColor(0.502, 0.2, 0.2);
    IncompleteFrame.count:SetTextColor(0.502, 0.2, 0.2);
    self.numIncomplete = IncompleteFrame.count;

    animFlyIn.background = self.blur;
    animFlyIn.ObjectiveFrame = self.CriteriaFrame;
    animFlyIn.ChainFrame = self.ChainFrame;
    animFlyOut.background = self.blur;
    animFlyOut.ObjectiveFrame = self.CriteriaFrame;
    animFlyOut.ChainFrame = self.ChainFrame;

    self.dataIndex = 1;


    self.TextContainerLeft = self.CriteriaFrame.LeftInset.TextFrame;
    self.TextContainerRight = self.CriteriaFrame.RightInset.TextFrame;
    self.MetaContainerLeft = self.CriteriaFrame.LeftInset.MetaFrame;
    self.MetaContainerRight = self.CriteriaFrame.RightInset.MetaFrame;
    self.BarContainerLeft = self.CriteriaFrame.LeftInset.BarFrame;
    self.BarContainerRight = self.CriteriaFrame.RightInset.BarFrame;


    --Achievement Container Blur
    local BlurFrame = self.blur;
    local BlurAnchor = BlurFrame.ScrollChild;
    local blur1 = BlurFrame.ScrollChild.blur1;
    local blur2 = BlurFrame.ScrollChild.blur2;

    local deltaRatio = 1;
    local speedRatio = 0.24;
    local blurHeight = 77;
    local range = 20000;
    local RepositionBlur = function(value, delta)
        local index;
        if delta < 0 then
            index = ceil( (value - 200) /940);
        else
            index = ceil( (value - 200) /940) - 1;
        end
        if index < 0 then
            index = 1;
        end
        if index ~= self.blurOffset then
            self.blurOffset = index;
            if index % 2 == 1 then
                blur2:SetPoint("TOPLEFT", BlurAnchor, "TOPLEFT", 0, -index * 940);
                blur2:SetPoint("TOPRIGHT", BlurAnchor, "TOPRIGHT", 0, -index * 940);
            else
                blur1:SetPoint("TOPLEFT", BlurAnchor, "TOPLEFT", 0, -index * 940);
                blur1:SetPoint("TOPRIGHT", BlurAnchor, "TOPRIGHT", 0, -index * 940);
            end
        end
    end


    NarciAPI_ApplySmoothScrollToScrollFrame(BlurFrame, deltaRatio, speedRatio, RepositionBlur, blurHeight, range);
    local Blur_OnMouseWheel = BlurFrame:GetScript("OnMouseWheel");

    function self:ScrollBlur(delta)
        if delta ~= 0 then
            Blur_OnMouseWheel(BlurFrame, delta);
            ReturnButton:Hide();
        end
    end

    function self:SyncBlurOffset(buttonIndex)
        self.blurOffset = -1;
        local value = (buttonIndex - 1) * blurHeight;
        BlurFrame.scrollBar:SetValue(value);

        local index = ceil( (value - 200) /940);
        if index < 0 then
            index = 1;
        end
        if index % 2 == 1 then
            blur1:SetPoint("TOPLEFT", BlurAnchor, "TOPLEFT", 0, (1 - index) * 940);
            blur1:SetPoint("TOPRIGHT", BlurAnchor, "TOPRIGHT", 0, (1 - index) * 940);
            blur2:SetPoint("TOPLEFT", BlurAnchor, "TOPLEFT", 0, -index * 940);
            blur2:SetPoint("TOPRIGHT", BlurAnchor, "TOPRIGHT", 0, -index * 940);
        else
            blur1:SetPoint("TOPLEFT", BlurAnchor, "TOPLEFT", 0, -index * 940);
            blur1:SetPoint("TOPRIGHT", BlurAnchor, "TOPRIGHT", 0, -index * 940);
            blur2:SetPoint("TOPLEFT", BlurAnchor, "TOPLEFT", 0, (1- index) * 940);
            blur2:SetPoint("TOPRIGHT", BlurAnchor, "TOPRIGHT", 0, (1 -index) * 940);
        end
    end

    --ScrollFrames: Criteria: Text, Meta
    local function UpdateScrollFrameDivider(value, delta, scrollBar)
        local minVal, maxVal = scrollBar:GetMinMaxValues();

        if value >= maxVal - 0.1 then
            scrollBar.divLeft:Hide();
            scrollBar.divCenter:Hide();
            scrollBar.divRight:Hide();
        elseif maxVal ~= 0 then
            scrollBar.divLeft:Show();
            scrollBar.divCenter:Show();
            scrollBar.divRight:Show();
        end
    end

    local positionFunc = UpdateScrollFrameDivider;
    local parentScrollFunc = function(delta)
        InspectionFrame:OnMouseWheel(delta);
    end

    local numLines = 30;
    local deltaRatio = 2;
    local speedRatio = 0.24;
    local buttonHeight = 26;
    local range = numLines * buttonHeight - IncompleteFrame:GetHeight();
    
    NarciAPI_ApplySmoothScrollToScrollFrame(IncompleteFrame.TextFrame, deltaRatio, speedRatio, positionFunc, buttonHeight, range, parentScrollFunc);
    NarciAPI_ApplySmoothScrollToScrollFrame(CompleteFrame.TextFrame, deltaRatio, speedRatio, positionFunc, buttonHeight, range, parentScrollFunc);

    local buttonHeight = 36;
    local deltaRatio = 2;
    NarciAPI_ApplySmoothScrollToScrollFrame(IncompleteFrame.MetaFrame, deltaRatio, speedRatio, positionFunc, buttonHeight, range, parentScrollFunc);
    NarciAPI_ApplySmoothScrollToScrollFrame(CompleteFrame.MetaFrame, deltaRatio, speedRatio, positionFunc, buttonHeight, range, parentScrollFunc);

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciAchievementInspectionFrameMixin:OnShow()
    self.isTransiting = nil;
end

function NarciAchievementInspectionFrameMixin:OnMouseDown()
    if not self.NextButton:IsMouseOver() and not self.PrevButton:IsMouseOver() then
        animFlyOut:Play();
    end
end

function NarciAchievementInspectionFrameMixin:ScrollToCategoryButton(button)
    if button then
        local topButton =  CategoryButtons.player.buttons[1];
        local offset = max(0, topButton:GetTop() -  button:GetTop() - (CategoryContainer:GetHeight()/2 or 32) +32); --Attempt to position it to the vertical center
        CategoryContainer.scrollBar:SetValue(offset);
    end
end

function NarciAchievementInspectionFrameMixin:ScrollToPosition(positionIndex)
    local offset = ScrollUtil:GetOffsetByPositionIndex(positionIndex) - 18;
    AchievementContainer.scrollBar:SetValue(offset);
end

function NarciAchievementInspectionFrameMixin:OnMouseWheel(delta, stopLooping)
    if self.isTransiting or self.pauseScroll then return end;

    local index = self.dataIndex;
    if delta > 0 then
        index = index - 1;
    else
        index = index + 1;
    end
    if index < 1 or index > self.numAchievements then
        return
    else
        self.dataIndex = index;
    end

    self.dataIndex = index;
    self:ScrollBlur(delta);
    self:ScrollToPosition(index);

    local newButton = ScrollUtil:GetCardByPositionIndex(index);
    if newButton then
        if newButton.isHeader and not stopLooping then
            --skip statistic header
            self:OnMouseWheel(delta, true);
            return
        end
        InspectCard(newButton);
    end
end

local function FormatTextButtons(container, data, count, completed)
    if not container.buttons then
        container.buttons = {};
    end
    local buttons = container.buttons;
    local button, numLines;
    
    for i = 1, count do
        button = buttons[i];
        if not button then
            button = CreateFrame("Button", nil, container.ScrollChild, "NarciAchievementObjectiveTextButton");
            tinsert(buttons, button);
            if i == 1 then
                button:SetPoint("TOPLEFT", container.ScrollChild, "TOPLEFT", 0, 0);
                button:SetPoint("TOPRIGHT", container.ScrollChild, "TOPRIGHT", 0, 0);
            elseif i % 5 == 1 then
                --bigger distance for every 5 entries
                button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -14);
                button:SetPoint("TOPRIGHT", buttons[i - 1], "TOPRIGHT", 0, -14);
            else
                button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, 0);
                button:SetPoint("TOPRIGHT", buttons[i - 1], "TOPRIGHT", 0, 0);
            end

            if not completed then
                button.dash:SetTextColor(0.6, 0.6, 0.6);
                button.icon:SetDesaturated(true);
            else
                button.dash:SetText("|CFF5fbb46- |r");
                button.icon:SetDesaturated(false);
            end
        end
        button.name:SetText(data.names[i]);
        numLines = ceil( button.name:GetHeight() / 12 - 0.1 );
        button.icon:SetTexture(nil);
        button:SetHeight(18 + (numLines - 1)*12 );
        button:Show();
    end

    for i = count + 1, #buttons do
        buttons[i]:Hide();
    end

    --Update Scroll Range
    local scrollBar = container.scrollBar;
    local range;
    if count == 0 then
        range = 0;
    else
        range = max(0, buttons[1]:GetTop() -  buttons[count]:GetBottom() - container:GetHeight() + 4);
        range = floor(range + 0.2);
    end
    scrollBar:SetValue(0);
    scrollBar:SetMinMaxValues(0, range);
    scrollBar:SetShown(range ~= 0);
    container.positionFunc(0, 1, scrollBar);
    container.range = range;
end

local function FormatMetaButtons(container, data, count, completed)
    if not container.buttons then
        container.buttons = {};
    end
    local buttons = container.buttons;
    local button, icon;

    for i = 1, count do
        button = buttons[i];
        if not button then
            button = CreateFrame("Button", nil, container.ScrollChild, "NarciAchievementObjectiveMetaAchievementButton");
            tinsert(buttons, button);
            if i == 1 then
                local buttonWidth = button:GetWidth();
                button:SetPoint("TOP", container.ScrollChild, "TOP", -(buttonWidth + 1) * 3, 0);
            elseif i % 7 == 1 then
                button:SetPoint("TOPLEFT", buttons[i - 7], "BOTTOMLEFT", 0, -1);
            else
                button:SetPoint("TOPLEFT", buttons[i - 1], "TOPRIGHT", 1, 0);
            end
            if not completed then
                button.icon:SetDesaturated(true);
            end
        end
        icon = data.icons[i];
        button.icon:SetTexture(icon);
        local id = data.assetIDs[i];
        button.id = id;
        if id then
            button.textMode = nil;
            button.criteriaString = nil;
        else
            button.textMode = true;
            button.criteriaString = data.names[i];
            if completed then
                button.icon:SetTexture(461267);     --ThumbsUp
            else
                button.icon:SetTexture(456031);     --Thumbsdown
            end
        end
        button.trackIcon:SetShown( DataProvider:IsTrackedAchievement(id) );
        button:Show();
    end
    for i = count + 1, #buttons do
        buttons[i]:Hide();
    end

    local header = container.name;
    local numRow = ceil( count / 7);

    header:ClearAllPoints();
    if numRow < 3 then
        header:SetPoint("TOPLEFT", buttons[1 + (numRow - 1)*7], "BOTTOMLEFT", 3, -4);
    else
        header:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 3, -16);
    end

    local focusedButtonIndex;

    if completed then
        header:SetText("");
        container.description:SetText("");
        container.points:SetText("");
        container.shield:Hide();
    else
        focusedButtonIndex = 1;
    end

    for i = 1, count do
        if buttons[i]:IsMouseOver() then
            focusedButtonIndex = i;
            break
        end
    end

    if focusedButtonIndex then
        buttons[focusedButtonIndex]:SetAchievement();
    end

    --Update Scroll Range
    local scrollBar = container.scrollBar;
    local range;
    if count == 0 then
        range = 0;
    else
        range = max(0, buttons[1]:GetTop() -  buttons[count]:GetBottom() - container:GetHeight());
    end
    scrollBar:SetValue(0);
    scrollBar:SetMinMaxValues(0, range);
    scrollBar:SetShown(range ~= 0);
    container.positionFunc(0, 1, scrollBar);
    container.range = range;
end

local function FormatStatusBars(container, data, count, completed)
    if not container.bars then
        container.bars = {};
    end
    local bars = container.bars;
    local numBars = #data.bars;
    local bar, barData;

    for i = 1, numBars do
        bar = bars[i];
        if not bar then
            bar = CreateFrame("Button", nil, container, "NarciAchievementObjectiveStatusBar");
            tinsert(bars, bar);
            if i == 1 then
                bar:SetPoint("TOP", container, "TOP", 0, -2);
            else
                bar:SetPoint("TOP", bars[i - 1], "BOTTOM", 0, -16);
            end
            if completed then
                bar.label:SetTextColor(0.8, 0.8, 0.8);
            else
                bar.label:SetTextColor(0.6, 0.6, 0.6);
            end
        end
        barData = data.bars[i];
        bar:SetMinMaxValues(0, barData[2]);
        bar:SetValue(barData[1], true);
        bar.label:SetText(barData[3]);
        bar:SetHeight(bar.label:GetHeight() + 22);
        bar:Show();
    end
    for i = numBars + 1, #bars do
        bars[i]:Hide();
    end
end

function NarciAchievementInspectionFrameMixin:FindParentAchievementID(achievementID)
    local parentAchievementID = GetParentAchievementID(achievementID);
    local button = AchievementCards[-1].ParentAchievmentButton;
    if parentAchievementID then
        local _, name, _, completed, month, day, year, _, _, icon = DataProvider:GetAchievementInfo(parentAchievementID);
        if completed then
            button:SetAlpha(1);
        else
            button:SetAlpha(0.60);
        end
        button.name = name;
        button.id = parentAchievementID;
        button.icon:SetTexture(icon);
        button.icon:SetDesaturated(not completed);
        button:Show();
        if not button.hasInitialized then
            button.hasInitialized = true;
            button.border:SetTexture("Interface\\AddOns\\Narcissus_Achievements\\Art\\Shared\\IconBorderMiniPointRight");
        end
    else
        button:Hide();
    end
end

function NarciAchievementInspectionFrameMixin:UpdateChain(achievementID, currentIsCompleted)
    local ChainFrame = self.ChainFrame;
    if not ChainFrame.buttons then
        ChainFrame.buttons = {};
    end
    local buttons = ChainFrame.buttons;
    local button;
    local achievements = { achievementID };
    local currentAchievementID = achievementID;
    local currentPosition = 1;

    achievementID = GetPreviousAchievement(currentAchievementID);
    while achievementID do
        tinsert(achievements, 1, achievementID);
        achievementID = GetPreviousAchievement(achievementID);
        currentPosition = currentPosition + 1;
    end

    achievementID = GetNextAchievement(currentAchievementID);
    while achievementID do
        tinsert(achievements, achievementID);
        achievementID = GetNextAchievement(achievementID);
    end

    local numAchievements = #achievements;
    
    if numAchievements > 1 then
        local gap = 1;
        local extraHeight = 0;
        local buttonWidth;
        local id, completed, month, day, year, icon, _;
        local numCompleted = 0;
        for i = 1, numAchievements do
            button = buttons[i];
            if not button then
                button = CreateFrame("Button", nil, ChainFrame, "NarciAchievementChainButton");
                button.date.flyIn.hold1:SetDuration( (i - 1)*0.025 );
                button.date.flyIn.hold2:SetDuration( (i - 1)*0.025 );
                tinsert(buttons, button);
            end

            id = achievements[i];
            _, _, _, completed, month, day, year, _, _, icon = DataProvider:GetAchievementInfo(id);
            if completed then
                numCompleted = numCompleted + 1;
            end

            button:ClearAllPoints();
            if i == 1 then
                buttonWidth = button:GetWidth();
                local numButtonsFirstRow = min(15, numAchievements);
                button:SetPoint("CENTER", ChainFrame.reference, "TOP", (buttonWidth + gap)*(1 - numButtonsFirstRow)/2 , -buttonWidth/2);
                buttonWidth = buttonWidth + gap;
            elseif i % 15 == 1 then
                --15 buttons per row
                local numButtonsThisRow = mod(numAchievements, 15);
                extraHeight = extraHeight + buttonWidth;
                local offsetY;
                if ChainFrame.showDates and completed then
                    offsetY = -78;
                else
                    offsetY = -1.5 * buttonWidth;
                end
                button:SetPoint("CENTER", ChainFrame.reference, "TOP", (buttonWidth + gap)*(1 - numButtonsThisRow)/2, offsetY);
            else
                button:SetPoint("CENTER", buttons[i - 1], "CENTER", buttonWidth, 0);
            end

            if i == currentPosition then
                button.border:SetTexture("Interface\\AddOns\\Narcissus_Achievements\\Art\\Shared\\IconBorderPointyMini");
                button:SetAlpha(1);
            else
                button.border:SetTexture("Interface\\AddOns\\Narcissus_Achievements\\Art\\Shared\\IconBorderMini");
                if completed then
                    button:SetAlpha(0.60);
                else
                    button:SetAlpha(0.33);
                end
            end

            if completed then
                button.date:SetText( FormatDate(day, month, year, true) );
            else
                button.date:SetText("");
            end

            button.icon:SetDesaturated(not completed);
            button.id = id;
            button.icon:SetTexture(icon);
            button:Show();
        end

        for i = numAchievements + 1, #buttons do
            buttons[i]:Hide();
        end

        ChainFrame.count:SetText( numCompleted .."/".. numAchievements);

        ChainFrame.reference:SetHeight(34 + extraHeight);   --base height 34
        ChainFrame:Show();

        return true
    else
        ChainFrame:Hide();
        return false
    end
end

function NarciAchievementInspectionFrameMixin:DisplayCriteria(cData, iData)
    local numCompleted = cData.count;
    local numIncomplete = iData.count;

    self.numCompleted:SetText(numCompleted);
    self.numIncomplete:SetText(numIncomplete);

    local TextContainer = self.TextContainerLeft;
    local MetaContainer = self.MetaContainerLeft;
    local BarContainer = self.BarContainerLeft;
    local icon = cData.icons[1];
    local numBars = #cData.bars;
    local type = 1;

    if numBars ~= 0 then
        type = 3
    elseif icon then
        type = 2;
    end

    if numCompleted == 0 then
        TextContainer:Hide();
        MetaContainer:Hide();
        BarContainer:Hide();
    else
        if type == 2 then
            TextContainer:Hide();
            MetaContainer:Show();
            BarContainer:Hide();
            FormatMetaButtons(MetaContainer, cData, numCompleted, true);
        elseif type == 3 then
            TextContainer:Hide();
            MetaContainer:Hide();
            BarContainer:Show();
            FormatStatusBars(BarContainer, cData, numCompleted, true);
        else
            TextContainer:Show();
            MetaContainer:Hide();
            BarContainer:Hide();
            FormatTextButtons(TextContainer, cData, numCompleted, true);
        end
    end

    --
    local TextContainer = self.TextContainerRight;
    local MetaContainer = self.MetaContainerRight;
    local BarContainer = self.BarContainerRight;
    local icon = iData.icons[1];
    local numBars = #iData.bars;
    local type = 1;
    if numBars ~= 0 then
        type = 3
    elseif icon then
        type = 2;
    end

    if numIncomplete == 0 then
        TextContainer:Hide();
        MetaContainer:Hide();
        BarContainer:Hide();
    else
        if type == 2 then
            TextContainer:Hide();
            MetaContainer:Show();
            BarContainer:Hide();
            FormatMetaButtons(MetaContainer, iData, numIncomplete);
        elseif type == 3 then
            TextContainer:Hide();
            MetaContainer:Hide();
            BarContainer:Show();
            FormatStatusBars(BarContainer, iData, numIncomplete);
        else
            TextContainer:Show();
            MetaContainer:Hide();
            BarContainer:Hide();
            FormatTextButtons(TextContainer, iData, numIncomplete);
        end
    end
end

function NarciAchievementInspectionFrameMixin:ShowOrHideChainDates()
    local ChainFrame = self.ChainFrame;
    local showDates = ChainFrame.showDates;
    local buttons = ChainFrame.buttons;
    local button;

    local offsetY;
    if showDates then
        offsetY = -78;
    else
        offsetY = -52.5;
    end

    for i = 1, #buttons do
        button = buttons[i];
        button.date:SetShown(showDates);
        if showDates then
            button.date.flyIn:Play();
        else
            button.date.flyIn:Stop();
        end

        if i ~= 1 and i % 15 == 1 then
            local date = button.date:GetText();
            if date and date ~= "" then
                local point, relativeTo, relativePoint, xOfs, yOfs = button:GetPoint();
                button:SetPoint(point, relativeTo, relativePoint, xOfs, offsetY);
            end
        end
    end

    --Update toggle visual
    if showDates then
        ChainFrame.DateToggle:SetLabelText(L["Hide Dates"]);
    else
        ChainFrame.DateToggle:SetLabelText(L["Show Dates"]);
    end
    ChainFrame.count:SetShown(not showDates);
    ChainFrame.header:SetShown(not showDates);
    ChainFrame.divLeft:SetShown(not showDates);
    ChainFrame.divRight:SetShown(not showDates);
end


------------------------------------------------------------------------------
NarciAchievementGoToCategoryButtonMixin = {};

function NarciAchievementGoToCategoryButtonMixin:OnLoad()
    GoToCategoryButton = self;
    self:OnLeave();
end

function NarciAchievementGoToCategoryButtonMixin:OnEnter()
    self.Label:SetTextColor(0.8, 0.8, 0.8);
    self.Icon:SetTexCoord(0.5, 1, 0, 1);
    self.Icon:SetAlpha(0.6);
end

function NarciAchievementGoToCategoryButtonMixin:OnLeave()
    self.Label:SetTextColor(0.6, 0.6, 0.6);
    self.Icon:SetTexCoord(0, 0.5, 0, 1);
    self.Icon:SetAlpha(0.4);
end

function NarciAchievementGoToCategoryButtonMixin:OnClick()
    if self.categoryID then
        if TabUtil:IsToDoList() then
            if self.isGuild then
                TabUtil:ToggleAchievement(2);
            else
                TabUtil:ToggleAchievement(1);
            end
        end

        local categoryButton = DataProvider:GetCategoryButtonByID(self.categoryID, self.isGuild);
        if categoryButton and (self.categoryID ~= DataProvider.currentCategory) then
            if not categoryButton.isParentButton then
                local parentCategoryButton = DataProvider:GetCategoryButtonByID(self.parentCategoryID, self.isGuild);
                ExpandCategoryButtonNoAnimation(parentCategoryButton);
            end
            categoryButton:Click();
            animFlyOut.noTranslation = true;
            animFlyOut:Play();

            InspectionFrame:ScrollToCategoryButton(categoryButton);

            AchievementContainer:Show();
            SummaryButton:Show();
        else
            animFlyOut:Play();
        end
    end
end

function NarciAchievementGoToCategoryButtonMixin:SetAchievement(achievementID, isGuild)
    local categoryID = DataProvider:GetAchievementCategory(achievementID);
    local name, parentCategoryID = DataProvider:GetCategoryInfo(categoryID);
    if categoryID then
        self.categoryID = categoryID;
        self.parentCategoryID = parentCategoryID;
        self.isGuild = isGuild;
        self.Label:SetText(name);
        self:Show();
        self:SetWidth(max(self.Label:GetWidth() + 60, 96));
    end
end


NarciMetaAchievementButtonMixin = {};

function NarciMetaAchievementButtonMixin:SetAchievement()
    local id = self.id;
    if id then
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText = DataProvider:GetAchievementInfo(id);
        local parent = self:GetParent():GetParent();
        parent.name:SetText(name);
        parent.description:SetText(description);
        parent.points:SetText(points);
        parent.shield:SetShown(points ~= 0);
        if completed then
            if IsAccountWide(flags) then
                parent.name:SetTextColor(0.427, 0.812, 0.965);
            else
                parent.name:SetTextColor(1, 0.91, 0.647);
            end
        else
            parent.name:SetTextColor(0.8, 0.8, 0.8);
        end

        self.name = name;
    end
end

function NarciMetaAchievementButtonMixin:OnEnter()
    if self.textMode then
        local parent = self:GetParent():GetParent();
        parent.name:SetText(self.criteriaString);
        parent.description:SetText(nil);
        parent.points:SetText(nil);
        parent.shield:Hide();
    else
        self:SetAchievement();
    end
    self.icon.animIn:Play();
    self.border.animIn:Play();
end

function NarciMetaAchievementButtonMixin:OnLeave()
    self.icon.animIn:Stop();
    self.border.animIn:Stop();
    self.icon:SetScale(1);
    self.border:SetScale(1);
end

function NarciMetaAchievementButtonMixin:OnClick()
    if ProcessModifiedClick(self) then return end;

    local id = InspectionFrame.currentAchievementID;
    if id and id ~= self.id then
        ReturnButton:AddToQueue(id, InspectionFrame.currentAchievementName);
        InspectAchievement(self.id);
    end
end

NarciAchievementChainButtonMixin = {};

function NarciAchievementChainButtonMixin:OnLoad()
    
end

function NarciAchievementChainButtonMixin:OnEnter()
    self:SetAchievement();
    self.icon.animIn:Play();
    self.border.animIn:Play();
end

function NarciAchievementChainButtonMixin:OnLeave()
    self.icon.animIn:Stop();
    self.border.animIn:Stop();
    self.icon:SetScale(1);
    self.border:SetScale(1);

    Tooltip:FadeOut();
    local ChainFrame = self:GetParent();
    if ChainFrame.DateToggle and not ChainFrame:IsMouseOver() then
        ChainFrame.DateToggle:FadeOut();
    end
end

function NarciAchievementChainButtonMixin:SetAchievement()
    local id = self.id;
    if id then
        Tooltip:ClearAllPoints();
        Tooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 1, -2);
        Tooltip:SetAchievement(id);
    end
end

function NarciAchievementChainButtonMixin:OnMouseDown()
    Tooltip:FadeOut();
end

NarciAchievementTooltipMixin = {};

function NarciAchievementTooltipMixin:OnLoad()
    NarciAPI.NineSliceUtil.SetUpBorder(self.FrameBorder, "whiteBorder", -12, 0.67, 0.67, 0.67);

    local animFade = NarciAPI_CreateAnimationFrame(0.25);
    self.animFade = animFade;
    animFade:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local alpha = outQuart(frame.total, frame.fromAlpha, frame.toAlpha, frame.duration);
        if frame.total >= frame.duration then
            frame:Hide();
            alpha = frame.toAlpha;
            if alpha == 0 then
                self:Hide();
            end
        end
        self:SetAlpha(alpha);
    end)

    function self:FadeIn()
        if InspectionFrame.isTransiting then return end;
        self:Show();
        animFade:Hide();
        animFade.fromAlpha = self:GetAlpha();
        animFade.toAlpha = 1;
        animFade:Show();
    end

    function self:FadeOut()
        animFade.toAlpha = 0;
        if not self:IsShown() then return end;
        animFade:Hide();
        animFade.fromAlpha = self:GetAlpha();
        animFade:Show();
    end

    local showDelay = NarciAPI_CreateAnimationFrame(0.12);
    self.showDelay = showDelay;
    showDelay:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        if frame.total >= frame.duration then
            frame:Hide();
            if animFade.toAlpha == 1 then
                self:FadeIn();
            end
        end
    end)
end

function NarciAchievementTooltipMixin:OnHide()
    self:Hide();
    self:SetAlpha(0);
end

function NarciAchievementTooltipMixin:ResizeAndShow()
    self:SetHeight( self.name:GetHeight() + self.description:GetHeight() + 4 + 24 );
    self:SetWidth( max(self.name:GetWrappedWidth() + (self.points:IsShown() and 48 or 0), self.description:GetWrappedWidth() + (self.date:IsShown() and 88 or 0) ) + 24);

    if not self:IsShown() then
        self.animFade.toAlpha = 1;
        self.showDelay:Show();
    elseif self.animFade.toAlpha == 0 then
        self:FadeIn();
    end
end

function NarciAchievementTooltipMixin:SetAchievement(id)
    local _, name, points, completed, month, day, year, description, flags, icon = DataProvider:GetAchievementInfo(id);

    self.name:SetText(name);
    self.description:SetText(description);
    
    if completed then
        if IsAccountWide(flags) then
            self.name:SetTextColor(0.427, 0.812, 0.965);
        else
            self.name:SetTextColor(1, 0.91, 0.647);
        end
        self.date:SetText( FormatDate(day, month, year) );
        self.date:Show();
    else
        self.name:SetTextColor(0.8, 0.8, 0.8);
        self.date:SetText("");
        self.date:Hide();
    end

    if points == 0 then
        self.shield:Hide();
        self.points:Hide();
    else
        self.shield:Show();
        self.points:SetText(points);
        self.points:Show();
    end

    self:ResizeAndShow();
end

----------------------------------------------------------------------------------
NarciAchievementReturnButtonMixin = {};

function NarciAchievementReturnButtonMixin:OnLoad()
    ReturnButton = self;
    self.structure = {};
end

function NarciAchievementReturnButtonMixin:PlayFlyIn()
    self.flyIn:Play();
end

function NarciAchievementReturnButtonMixin:OnEnter()
    self.label:SetTextColor(0.88, 0.88, 0.88);
end

function NarciAchievementReturnButtonMixin:OnLeave()
    self.label:SetTextColor(0.6, 0.6, 0.6);
end

function NarciAchievementReturnButtonMixin:OnHide()
    self:Hide();
    self:StopAnimating();
    self.structure = {};
end

function NarciAchievementReturnButtonMixin:SetLabelText(text)
    self.label:SetText("");
    self.label:SetWidth(0);
    self.label:SetText(text);

    local textWidth = min(140, self.label:GetWidth());
    self.label:SetWidth(textWidth)
    self:SetWidth(textWidth + 24);
end

function NarciAchievementReturnButtonMixin:AddToQueue(achievementID, achievementName)
    for i = 1, #self.structure + 1 do
        if self.structure[i] == nil then
            self.structure[i] = {id = achievementID, name = achievementName};
            break;
        end
    end
    self:SetLabelText(achievementName);
    self:Show();
    self:PlayFlyIn();
end

function NarciAchievementReturnButtonMixin:OnClick()
    for i = #self.structure, 1, -1 do
        local info = self.structure[i];
        if info and info.id then
            InspectAchievement(info.id);
            if i == 1 then
                self:Hide();
            else
                self:SetLabelText(self.structure[i - 1].name)
            end
            self.structure[i] = nil;
            break;
        end
    end
end


NarciAchievementSearchBoxMixin = {};

local function InspectResult(button)
    local playAnimation = not InspectionFrame:IsShown();

    local id = button.id;
    local Card = InspectionFrame.Card;
    Card:ClearAllPoints();
    Card:SetPoint("BOTTOM", InspectionFrame, "CENTER", 0, 36);

    InspectionFrame.PrevButton:Disable();
    InspectionFrame.NextButton:Disable();
    InspectionFrame.pauseScroll = true;

    InspectAchievement(id);

    animFlyOut.button = nil;
    animFlyOut.fromX, animFlyOut.toX, animFlyOut.fromY, animFlyOut.toY = 0, 0, 0, 0;
    animFlyOut.noTranslation = true;

    if playAnimation then
        animFlyIn:Play();
        if DataProvider:IsStatistic(id) then
            InspectionFrame.StatCard:SetAlpha(0);
            FadeFrame(InspectionFrame.StatCard, 0.25, 1);
        end
    end
end

addon.InspectResult = InspectResult;


--------------------------------------------------------------
local DateUtil = {};
function DateUtil:GetToday()
    self.today = time();
end

function DateUtil:GetDifference(day, month, year)
    year = 2000 + year;
    local past = time( {day = day, month = month, year = year} )
    if not self.today then
        self.today = time();
    end
    return (self.today - past)
end

function DateUtil:GetPastDays(day, month, year)
    local diff = self:GetDifference(day, month, year);
    local d = floor(diff / 86400);
    if d <= 0 then
        return L["Today"]
    elseif d == 1 then
        return L["Yesterday"]
    elseif d < 31 then
        return format(L["Format Days Ago"], d);
    else
        local m = floor(d / 30.5);
        if m <= 1 then
            return L["A Month Ago"]
        elseif m < 12 then
            return format(L["Format Months Ago"], m);
        else
            local y = floor(m / 12 + 0.15);
            if y == 1 then
                return L["A Year Ago"]
            else
                return format(L["Format Years Ago"], y);
            end
        end
    end
end


local UpdateHeaderFrame;

function UpdateSummaryFrame(breakLoop)
    local recentAchievements = { GetLatestCompletedAchievements(isGuildView) };
    local numAchievements = #recentAchievements;
    if (numAchievements < 5) and (not breakLoop) then
        After(0.05, function()
            UpdateSummaryFrame(true);
        end);
        return
    end

    ScrollUtil:ResetHeights();
    processor:Hide();
    AchievementContainer.scrollBar:SetValue(0);
    for i = 1, NUM_ACHIEVEMENT_CARDS do
        AchievementCards[i]:Hide();
    end
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild;
    for i = 1, #recentAchievements do
        id = recentAchievements[i];
        if id then
            id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild = DataProvider:GetAchievementInfo(id);
            if i <= NUM_ACHIEVEMENT_CARDS then
                FormatAchievementCardByIndex(i, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, true);
                AchievementCards[i].date:SetText( DateUtil:GetPastDays(day, month, year) );
            end
            ScrollUtil:SetCardData(i, id, description, rewardText);
        else
            break;
        end
    end
    UpdateAchievementScrollRange();
    ScrollUtil:UpdateScrollChild(0);
    UpdateHeaderFrame(isGuildView);
    if numAchievements ~= 0 then
        animFlip:Play(1);
    end
    InspectionFrame.numAchievements = numAchievements;
end

----------------------------------------------------------------------------------
TabUtil.categories = {
    "PlayerCategory", "GuildCategory", "StatsCategory", "ToDoCategory",
};

function TabUtil:SaveOffset()
    --currentTab before switching
    local button = DataProvider:GetCategoryButtonByID(DataProvider.currentCategory);
    local offset = CategoryContainer.scrollBar:GetValue();
    if self.tabID == 1 then
        --achievement
        self.lastPlayerButton = button;
        self.lastPlayerScrollValue = offset;

    elseif self.tabID == 2 then
        --guild
        self.lastGuildButton = button;
        self.lastGuildScrollValue = offset;

    elseif self.tabID == 3 then
        --statistics
        self.lastStatButton = button;
        self.lastStatScrollValue = offset;
    elseif self.tabID == 5 then
        self.lastBookmarkButton = button;
        self.lastBookmarkScrollValue = offset;
    end
    ShutInspection();
end

function TabUtil:ResumeOffset()
    local lastButton, lastOffset;
    if self.tabID == 1 then
        lastButton = self.lastPlayerButton;
        lastOffset = self.lastPlayerScrollValue;
    elseif self.tabID == 2 then
        lastButton = self.lastGuildButton;
        lastOffset = self.lastGuildScrollValue;
    elseif self.tabID == 3 then
        lastButton = self.lastStatButton;
        lastOffset = self.lastStatScrollValue;
    elseif self.tabID == 5 then
        lastButton = self.lastBookmarkButton;
        lastOffset = self.lastBookmarkScrollValue;
    end
    if lastButton then
        AchievementContainer:Show();
        SummaryButton:Show();
        SubCategoryButton_OnClick(lastButton);
        ToggleFeatOfStrenghtText(lastButton);
    else
        if self.tabID == 4 then

        elseif self.tabID == 5 then
            SummaryButton:Click();
        else
            SummaryButton:Click();
        end
    end
    AchievementContainer.scrollBar:SetValue(0);
    CategoryContainer.scrollBar:SetValue(lastOffset or 0);
end

function TabUtil:ShowCategory(categoryKey)
    for _, name in ipairs(self.categories) do
        CategoryContainer.ScrollChild[name]:SetShown(categoryKey == name);
    end
end

function TabUtil:ToggleAchievement(tabID)
    if tabID ~= self.tabID then
        self:SaveOffset();

        if self.tabID == 5 then
            --Force update achievement list
            DataProvider.currentCategory = nil;
        end

        self.tabID = tabID;
        local isGuild = (tabID == 2);
        isGuildView = isGuild;
        if isGuild then
            self:ShowCategory("GuildCategory");
        else
            self:ShowCategory("PlayerCategory");
        end
        DIYContainer:Hide();
        EditorContainer:Hide();
        CategoryContainer:Show();
        UpdateCategoryScrollRange();
        MainFrame.HeaderFrame.points:SetText( BreakUpLargeNumbers(GetTotalAchievementPoints(isGuild)) );
        FilterButton:Enable();
        SummaryButton:SetMode(1);
        self:ResumeOffset();
        self:EnableSearchBox(true);
    end
end

function TabUtil:ToggleStats()
    if self.tabID == 3 then return end;
    self:SaveOffset();
    self.tabID = 3;
    self:ShowCategory("StatsCategory");
    MainFrame.FeatOfStrengthText:Hide();
    MainFrame:UpdatePinCount();
    DIYContainer:Hide();
    EditorContainer:Hide();
    CategoryContainer:Show();
    UpdateCategoryScrollRange();
    FilterButton:Disable();
    SummaryButton:SetMode(2);
    self:ResumeOffset();
    self:EnableSearchBox(true);
end

function TabUtil:ToggleDIY()
    if self.tabID == 4 then return end;
    self:SaveOffset();
    self.tabID = 4;
    DataProvider.currentCategory = nil;
    DIYContainer:Show();
    if not TabUtil.isDIYLoaded then
        TabUtil.isDIYLoaded = true;
        DIYContainer:Refresh();
        DIYContainer.scrollBar:SetValue(0);
    end

    EditorContainer:Show();
    CategoryContainer:Hide();
    AchievementContainer:Hide();
    FilterButton:Disable();
    SummaryButton:SetMode(3);
    MainFrame.FeatOfStrengthText:Hide();
    self:EnableSearchBox(false);
end

function TabUtil:ToggleToDoList()
    if self.tabID == 5 then return end;
    self:SaveOffset();
    self.tabID = 5;
    DataProvider.currentCategory = nil;

    AchievementContainer:Hide();
    FilterButton:Disable();
    SummaryButton:SetMode(5);
    MainFrame:UpdateToDoListCount();
    self:EnableSearchBox(false);
    self:ShowCategory("ToDoCategory");

    DIYContainer:Hide();
    EditorContainer:Hide();
    CategoryContainer:Show();
    UpdateCategoryScrollRange();
    self:ResumeOffset();

    self:UpdateToDoListCategory();
end

function TabUtil:GetTabID()
    return self.tabID or 1;
end

function TabUtil:IsToDoList()
    return self:GetTabID() == 5
end

function TabUtil:UpdateToDoListCategory()
    local anyChange = BookmarkUtil:OnTabSelected();
    if not anyChange then return end;

    BuildCategoryStructure(5);
    CreateCategoryButtons(5);

    animExpand:CollapseAll();

    local buttons = ToDoListData.buttons;
    local numAchievements, numChildAchievements;
    for _, button in pairs(buttons) do
        numAchievements, numChildAchievements = BookmarkUtil:GetNumAchievementsInCategory(button.id);
        if numChildAchievements and numChildAchievements > 0 then
            numAchievements = numAchievements .. " ("..numChildAchievements..")";
        end
        button.progress:SetText(numAchievements);
        button.progress:Show();
        button.percentSign:Hide();
        button.value:Hide();
    end
end

--------------------------------------------------------------
NarciAchievementFilterButtonMixin = {};

function NarciAchievementFilterButtonMixin:OnLoad()
    self:OnLeave();
    FilterButton = self;
    self.OnLoad = nil;
    self:SetScript("OnLoad", nil);
end

function NarciAchievementFilterButtonMixin:OnClick()
    local state = not NarciAchievementOptions.IncompleteFirst;
    NarciAchievementOptions.IncompleteFirst = state;
    self:UpdateFilter();
end

function NarciAchievementFilterButtonMixin:OnEnable()
    self.label:SetTextColor(0.8, 0.8, 0.8);
    self:EnableMouse(true);
end

function NarciAchievementFilterButtonMixin:OnDisable()
    self.label:SetTextColor(0.5, 0.5, 0.5);
    self:EnableMouse(false);
end

function NarciAchievementFilterButtonMixin:UpdateFilter()
    if NarciAchievementOptions.IncompleteFirst then
        self.label:SetText(L["Incomplete First"]);
        SwitchToSortMethod(1);
    else
        self.label:SetText(L["Earned First"]);
        SwitchToSortMethod(2);
    end
end

function NarciAchievementFilterButtonMixin:OnMouseDown()
    self.texture:SetTexCoord(0, 1, 0.5, 1);
end

function NarciAchievementFilterButtonMixin:OnMouseUp()
    self.texture:SetTexCoord(0, 1, 0, 0.5);
end

function NarciAchievementFilterButtonMixin:OnEnter()
    self.texture:SetVertexColor(1, 1, 1);
end

function NarciAchievementFilterButtonMixin:OnLeave()
    self.texture:SetVertexColor(0.66, 0.66, 0.66);
end

------------------------------------------------------------------
NarciAchievementSummaryButtonMixin = {};

function NarciAchievementSummaryButtonMixin:OnClick()
    self:Hide();
    local categoryID;
    if self.modeID == 2 then
        AchievementContainer:Show();
        SelectCategory(-2);
        animExpand:CollapseAll();
        categoryID = - 2;
        MainFrame.FeatOfStrengthText:Hide();
    elseif self.modeID == 5 then    --To-do list
        SelectCategory(-5);
    else
        categoryID = -1;
        SelectCategory(-1);
        MainFrame.FeatOfStrengthText:Hide();
    end
    if DataProvider.currentCategory ~= categoryID then
        animExpand:CollapseAll();
        DataProvider.currentCategory = categoryID;
    end
end

function NarciAchievementSummaryButtonMixin:OnMouseDown()
    self.texture:SetTexCoord(0, 1, 0.5, 0.8125);
    self.label:SetTextColor(0.6, 0.6, 0.6);
end

function NarciAchievementSummaryButtonMixin:OnMouseUp()
    self.texture:SetTexCoord(0, 1, 0, 0.3125);
    self.label:SetTextColor(0.8, 0.8, 0.8);
end

function NarciAchievementSummaryButtonMixin:SetMode(modeID)
    self.modeID = modeID;
    if modeID == 3 then
        self:Show();
        self:Disable();
        self.label:SetText("DIY");
    else
        if modeID == 1 then
            self.label:SetText(ACHIEVEMENT_SUMMARY_CATEGORY or "Summary");
        elseif modeID == 2 then
            self.label:SetText(L["Pinned Entries"]);    --Pinned Stats
        elseif modeID == 5 then
            self.label:SetText(ACHIEVEMENTFRAME_FILTER_ALL or "All");
        end
        self:Enable();
    end
end

function NarciAchievementSummaryButtonMixin:OnEnable()
    self:EnableMouse(true);
    self:OnMouseUp();
end

function NarciAchievementSummaryButtonMixin:OnDisable()
    self:EnableMouse();
    self:OnMouseDown();
end
------------------------------------------------------------------


local function CreateTabButtons()
    local tabNames = {ACHIEVEMENTS, ACHIEVEMENTS_GUILD_TAB, STATISTICS, "DIY", L["To Do List"], L["Settings"]};
    local frame = Narci_AchievementFrame;
    local buttons = {};
    local function DeselectRest(button)
        for i = 1, #buttons do
            if buttons[i] ~= button then
                buttons[i]:Deselect();
            end
        end
    end

    local funcs = {
        function(self)
            TabUtil:ToggleAchievement(1);
            DeselectRest(self);
            self:Select();
        end,

        function(self)
            TabUtil:ToggleAchievement(2);
            DeselectRest(self);
            self:Select();
        end,

        function(self)
            TabUtil:ToggleStats();
            DeselectRest(self);
            self:Select();
        end,

        function(self)
            TabUtil:ToggleDIY();
            DeselectRest(self);
            self:Select();
        end,

        function(self)
            TabUtil:ToggleToDoList();
            DeselectRest(self);
            self:Select();
        end,

        function(self)
            MainFrame.Settings:Toggle();
        end,
    }
    
    local numTabs = #tabNames;
    for i = 1, numTabs do
        local button = CreateFrame("Button", nil, frame, "NarciAchievementTabButtonTemplate");
        tinsert(buttons, button);
        button:SetLabel(tabNames[i]);
        button.id = i;
        button:SetID(i);

        if i == 1 then
            button:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 23, 0);
            button:Select();
        elseif i == numTabs then
            --settings
            button:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -23, 0);
            MainFrame.Settings.linkedTabButton = button;
        else
            button:SetPoint("TOPLEFT", buttons[i - 1], "TOPRIGHT", 14, 0);
        end

        button:SetScript("OnClick", funcs[i]);
    end

    TabButtons = buttons;

    TabUtil:ToggleAchievement(1);
end
----------------------------------------------------------------------------------
local function GetInspectedCardLink()
    local achievementID = InspectionFrame.currentAchievementID;
    if not achievementID then return end;

    local URL = NarciLanguageUtil:GetWowheadLink();
    URL = URL .. "achievement=" .. tostring(achievementID);

    return URL
end

NarciAchievementGetLinkButtonMixin = {};

function NarciAchievementGetLinkButtonMixin:OnLoad()
    self.Label:SetText(L["External Link"]);
    local textWidth = max(40, floor( self.Label:GetWidth() + 0.5 ) );
    self:SetWidth(textWidth + 40 + 16);

    local range = textWidth + 24;
    self.Icon:SetPoint("RIGHT", self, "RIGHT", -18, 0);


    local animShow = NarciAPI_CreateAnimationFrame(0.25);
    self.animShow = animShow;
    animShow:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local offsetX = inOutSine(frame.total, frame.fromX, frame.toX, frame.duration);
        local textOffset = inOutSine(frame.total, frame.fromTextX, frame.toTextX, frame.duration);
        local alpha = outQuart(frame.total, frame.fromAlpha, frame.toAlpha, frame.duration);
        if frame.total >= frame.duration then
            offsetX = frame.toX;
            textOffset = frame.toTextX;
            alpha = frame.toAlpha;
            frame:Hide();

            if alpha == 0 then
                self.Clipboard:Hide();
            end
        end
        self.Icon:SetPoint("RIGHT", self, "RIGHT", offsetX, 0);
        self.Label:SetPoint("RIGHT", self, textOffset, 0);
        self.Label:SetAlpha(alpha);
        self.Clipboard:SetAlpha(alpha);
    end);

    function self:AnimShow()
        animShow:Hide();
        local offsetX, _;
        _, _, _, offsetX = self.Icon:GetPoint();
        _, _, _, animShow.fromTextX = self.Label:GetPoint();
        animShow.duration = ( sqrt(1 - abs(offsetX)/ range) * 0.4);
        animShow.fromX = offsetX;
        animShow.toX = -range;
        --animShow.fromTextX = -28; --keep label still
        animShow.toTextX = -28;
        animShow.fromAlpha = self.Label:GetAlpha();
        animShow.toAlpha = 1;
        animShow:Show();
    end

    function self:AnimHide()
        animShow:Hide();
        local offsetX, _;
        _, _, _, offsetX = self.Icon:GetPoint();
        _, _, _, animShow.fromTextX = self.Label:GetPoint();
        animShow.duration = ( sqrt(abs(offsetX)/ range) * 0.5);
        animShow.fromX = offsetX;
        animShow.toX = -20;
        animShow.toTextX = -10;
        animShow.fromAlpha = self.Label:GetAlpha();
        animShow.toAlpha = 0;
        animShow:Show();
    end

    self.Clipboard:SetScript("OnLeave", function()
        self:OnLeave();
    end);
    self.Clipboard.EditBox:SetScript("OnLeave", function()
        self:OnLeave();
    end);

    self.Clipboard:ReAnchorTooltipToObject(self.Label);
    self.Clipboard.EditBox.onQuitFunc = function()
        self:OnLeave();
    end
end

function NarciAchievementGetLinkButtonMixin:OnClick()
    self.Clipboard:ShowClipboard();
    self.Clipboard:SetText( GetInspectedCardLink() );
    self.Clipboard:SetFocus();
    self.Label:Hide();
end

function NarciAchievementGetLinkButtonMixin:OnEnter()
    --self.Label:SetTextColor(1, 1, 1);
    self.Icon:SetTexCoord(0.5, 1, 0, 1);
    self.Icon:SetAlpha(0.6);
    self:AnimShow();
    self.Label:Show();
end

function NarciAchievementGetLinkButtonMixin:OnLeave()
    if not self:IsMouseOver() and not self.Clipboard:HasFocus() then
        self.Label:SetTextColor(0.8, 0.8, 0.8);
        self.Icon:SetTexCoord(0, 0.5, 0, 1);
        self.Icon:SetAlpha(0.4);
        self:AnimHide();
        self.Clipboard.EditBox:HighlightText(0, 0);
    end
end


--------------------------------------------------------
local function InitializeFrame(frame)
    --Category
    CategoryContainer = frame.CategoryFrame;
    local isGuild = true;
    CreateCategoryButtons(2);
    isGuild = not isGuild;
    CreateCategoryButtons(1);
    CreateCategoryButtons(3);
    local numCategories = CategoryStructure.player.numCategories;
    local deltaRatio = 2;
    local speedRatio = 0.15;
    local buttonHeight = 32;
    local range = numCategories  * (buttonHeight + 4) - CategoryContainer:GetHeight();
    local positionFunc;
    
    NarciAPI_ApplySmoothScrollToScrollFrame(CategoryContainer, deltaRatio, speedRatio, positionFunc, buttonHeight, range);
    UpdateCategoryScrollRange();


    --Sort Method
    FilterButton:UpdateFilter();
    showNotEarnedMark = NarciAchievementOptions.ShowRedMark;

    --Achievement
    AchievementContainer = frame.AchievementCardFrame;
    CreateAchievementButtons(AchievementContainer.ScrollChild);

    local numCards = #AchievementCards;
    local deltaRatio = 1;
    local speedRatio = 0.24;
    local buttonHeight = 64;
    local range = numCards  * (buttonHeight + 4) - AchievementContainer:GetHeight();
    local positionFunc;
    NarciAPI_ApplySmoothScrollToScrollFrame(AchievementContainer, deltaRatio, speedRatio, positionFunc, buttonHeight, range);
    local scrollBar = AchievementContainer.scrollBar;
    scrollBar:SetScript("OnValueChanged", function(bar, value)
        AchievementContainer:SetVerticalScroll(value);
        ScrollUtil:GetTopButtonIndex(value);
    end);
    UpdateAchievementScrollRange();

    --Model Preview
    MountPreview = CreateFrame("ModelScene", nil, frame,"NarciAchievementRewardModelTemplate");
    MountPreview:ClearAllPoints();
    MountPreview:SetPoint("LEFT", frame, "RIGHT", 4, 0);

    Tooltip = frame.Tooltip;

    --Header Filter, Total Points, Search, Close
    local HeaderFrame = frame.HeaderFrame;

    SummaryButton = frame.SummaryButton;
    
    function UpdateHeaderFrame(isGuild) --Private
        local total, completed = GetNumCompletedAchievements(isGuild);
        HeaderFrame.totalAchievements:SetText(completed.."/"..total);
        HeaderFrame.points:SetText( BreakUpLargeNumbers(GetTotalAchievementPoints(isGuild)) );
        if completed > 0 then
            HeaderFrame.fill:Show();
            local percentage = completed / total;
            HeaderFrame.fill:SetWidth(198 * percentage);
            HeaderFrame.fill:SetTexCoord(0, percentage *  0.75, 0, 1);
            if percentage == 1 then
                HeaderFrame.value:SetText("100");
                HeaderFrame.fillEnd:Hide();
            else
                HeaderFrame.value:SetText( floor(100 * percentage) );
                HeaderFrame.fillEnd:Show();
            end
        end
        HeaderFrame.value:Show();
        HeaderFrame.percentSign:Show();
        HeaderFrame.progress:Hide();
    end

    --SummaryFrame
    SummaryFrame = frame.SummaryFrame;

    --DIY Achievements
    DIYContainer = frame.DIYContainer;
    EditorContainer = frame.EditorContainer;

    --Tabs
    CreateTabButtons();
    NarciAchievement_SelectTheme(NarciAchievementOptions.Theme or 1);

    frame:Show();
    UpdateSummaryFrame();

    --To-do List
    CreateCategoryButtons(5);

    --Reclaim Temp
    CategoryStructure = nil;
    CreateAchievementButtons = nil;
    CreateTabButtons = nil;
    InitializeFrame = nil;
end

-----------------------------------------
local FloatingCard = addon.FloatingCard;


local function RefreshInspection(achievementID)
    --Refresh inspection card
    if InspectionFrame:IsShown() then
        if achievementID then
            if (achievementID == InspectionFrame.Card.id) then
                InspectAchievement(achievementID);
            end
        else
            if InspectionFrame.Card.id then
                InspectAchievement(InspectionFrame.Card.id);
            end
        end
    end
end
--------------------------------------------------------------------
--Public
NarciAchievementFrameMixin = {};

function NarciAchievementFrameMixin:OnLoad()
    MainFrame = self;

    ScrollUtil.textReference = self.TextHeightRetriever;

    self:RegisterForDrag("LeftButton");
    self:SetAttribute("nodeignore", true);  --ConsolePort: Ignore this frame
    table.insert(UISpecialFrames, self:GetName());
end

local function AchievementFrame_OnKeyDown(self, key)
    if key == "ESCAPE" then
        self:SetPropagateKeyboardInput(false);
        self:Hide();
    else
        self:SetPropagateKeyboardInput(true);
    end
end

function NarciAchievementFrameMixin:OnShow()
    if self.pendingCategoryID then
        SelectCategory(self.pendingCategoryID);
        self.pendingCategoryID = nil;
    elseif self.pendingUpdate then
        self.pendingUpdate = nil;
        UpdateSummaryFrame();
    end
    self:RegisterDynamicEvent(true);
    RefreshInspection();
    StatCardController:UpdateList();
    --self:SetScript("OnKeyDown", AchievementFrame_OnKeyDown);
end

function NarciAchievementFrameMixin:OnHide()
    self:RegisterDynamicEvent(false);
    --self:SetScript("OnKeyDown", nil);
end

function NarciAchievementFrameMixin:RegisterDynamicEvent(state)
    if state then
        self:RegisterEvent("CRITERIA_UPDATE");
        self:RegisterEvent("CRITERIA_COMPLETE");
    else
        self:UnregisterEvent("CRITERIA_UPDATE");
        self:UnregisterEvent("CRITERIA_COMPLETE");
    end
end

function NarciAchievementFrameMixin:OnEvent(event, ...)
    RefreshInspection(...);
    if event == "CRITERIA_UPDATE" then
        StatCardController:UpdateList();
    end
end

function NarciAchievementFrameMixin:ShowRedMark(visible)
    showNotEarnedMark = visible;
    for i = 1, #AchievementCards do
        if visible then
            AchievementCards[i].NotEarned:SetWidth(20);
        else
            AchievementCards[i].NotEarned:SetWidth(0.1);
        end
    end
    if MainFrame:IsShown() then
        local categoryID = DataProvider.currentCategory;
        if categoryID and categoryID ~= 0 then
            SelectCategory(categoryID);
        end
    end
end

function NarciAchievementFrameMixin:LocateAchievement(achievementID, clickAgainToClose)
    local Card = InspectionFrame.Card;

    if  (not achievementID) or ( clickAgainToClose and (Card.id == achievementID) and MainFrame:IsShown() and InspectionFrame:IsShown() ) then
        MainFrame:Hide();
        return
    end
    
    MainFrame:Show();
    local playAnimation = not InspectionFrame:IsShown();
    Card:ClearAllPoints();
    Card:SetPoint("BOTTOM", InspectionFrame, "CENTER", 0, 36);

    InspectionFrame.PrevButton:Disable();
    InspectionFrame.NextButton:Disable();
    InspectionFrame.pauseScroll = true;

    InspectAchievement(achievementID);

    animFlyOut.button = nil;
    animFlyOut.fromX, animFlyOut.toX, animFlyOut.fromY, animFlyOut.toY = 0, 0, 0, 0;
    animFlyOut.noTranslation = true;

    if playAnimation then
        animFlyIn:Play();
    end
end

function NarciAchievementFrameMixin:OnDragStart()
    self:StartMoving();

    --Anchor settings frame to self
    local f = self.Settings;
    f:ClearAllPoints();
    f:SetPoint("TOPLEFT", self, "TOPRIGHT", 8, -4);
end

function NarciAchievementFrameMixin:OnDragStop()
    self:StopMovingOrSizing();

    self.Settings.AnchorToUIParent();
end

function NarciAchievementFrameMixin:UpdatePinCount()
    local HeaderFrame = self.HeaderFrame;
    local total, cap = PinUtil:GetTotal();
    HeaderFrame.totalAchievements:SetText(L["Pinned Entries"]);
    HeaderFrame.progress:SetText(format("%d/%d", total, cap));
    HeaderFrame.progress:Show();
    HeaderFrame.value:Hide();
    HeaderFrame.percentSign:Hide();

    if total > 0 then
        HeaderFrame.fill:Show();
        local percentage = total / cap;
        HeaderFrame.fill:SetWidth(198 * percentage);
        HeaderFrame.fill:SetTexCoord(0, percentage *  0.75, 0, 1);
        if percentage == 1 then
            HeaderFrame.fillEnd:Hide();
        else
            HeaderFrame.fillEnd:Show();
        end
    else
        HeaderFrame.fill:Hide();
        HeaderFrame.fillEnd:Hide();
    end
end

function NarciAchievementFrameMixin:UpdateToDoListCount()
    local HeaderFrame = self.HeaderFrame;
    local total = BookmarkUtil:GetNumAchievementsInCategory(-5);
    HeaderFrame.totalAchievements:SetText(L["To Do List"]);
    HeaderFrame.progress:SetText(total);
    HeaderFrame.progress:Show();
    HeaderFrame.value:Hide();
    HeaderFrame.percentSign:Hide();
    HeaderFrame.fill:Hide();
    HeaderFrame.fillEnd:Hide();

    if total > 0 then
        self.FeatOfStrengthText:Hide();
    else
        self.FeatOfStrengthText:SetText(L["Instruction Add To To Do List"]);
        self.FeatOfStrengthText:Show();
    end
end


--[[
function NarciAchievement_FormatAlertCard(card)
    local achievementID = card.id;
    local uiScale = MainFrame:GetEffectiveScale();
    card.uiScale = uiScale;
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText = DataProvider:GetAchievementInfo(achievementID);
    FormatFloatingCard(card, id, name, points, completed, month, day, year, description, flags, icon, rewardText);
    ReskinButton(card);
end

function NarciAchievement_ReskinButton(card)
    ReskinButton(card);
    card.isDarkTheme = IS_DARK_THEME;
end
--]]


local BookmarkIconMixin = {};
do
    function BookmarkIconMixin:OnEnter()
        local tooltip = GameTooltip;
        tooltip:SetOwner(self, "ANCHOR_RIGHT");
        tooltip:SetText(L["To Do List"], 1, 1, 1, true);
        tooltip:AddLine(L["Instruction Remove From To Do List"], 1, 0.82, 0, true);
        tooltip:Show();
    end

    function BookmarkIconMixin:OnLeave()
        GameTooltip:Hide();
    end
end


NarciAchievementLargeCardMixin = {};

function NarciAchievementLargeCardMixin:OnDragStart()
    --Create Floating Card
    if not self.id then return end;
    self.AnimPushed:Stop();
    self:Hide();

    local card = FloatingCard:CreateFromCard(self, 1);
end

function NarciAchievementLargeCardMixin:OnLoad()
    self:RegisterForDrag("LeftButton");
    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;

    self.BookmarkIcon:SetScript("OnEnter", BookmarkIconMixin.OnEnter);
    self.BookmarkIcon:SetScript("OnLeave", BookmarkIconMixin.OnLeave);
end

function NarciAchievementLargeCardMixin:OnMouseDown()
    self.AnimPushed:Stop();
    self.AnimPushed.hold:SetDuration(20);
    self.AnimPushed:Play();
end

function NarciAchievementLargeCardMixin:OnMouseUp()
    self.AnimPushed.hold:SetDuration(0);
end

function NarciAchievementLargeCardMixin:UpdateTheme()
    ReskinButton(self);
    if self.id then
        local visibility = self:IsShown();
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, earnedByMe  = DataProvider:GetAchievementInfo(self.id);
        FormatAchievementCard(self, id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, earnedByMe);
        self:SetShown(visibility);
    end
end

function NarciAchievement_SelectTheme(index)
    if not index or index > 3 or index < 1 then
        index = 1;
    end
    if index == themeID then return end;

    themeID = index;
    NarciAchievementOptions.Theme = index;

    if index == 3 then
        IS_DARK_THEME = true;
        TEXTURE_PATH = "Interface\\AddOns\\Narcissus_Achievements\\Art\\Flat\\";
    elseif index == 2 then
        IS_DARK_THEME = false;
        TEXTURE_PATH = "Interface\\AddOns\\Narcissus_Achievements\\Art\\Classic\\";
    else
        IS_DARK_THEME = true;
        TEXTURE_PATH = "Interface\\AddOns\\Narcissus_Achievements\\Art\\DarkWood\\";
    end

    --Statistics
    StatCardController:SetTheme(index);
    InspectionFrame.StatCard:UpdateTheme();
    for i = 1, #AchievementCards do
        ReskinButton(AchievementCards[i]);
    end

    ReskinButton(AchievementCards[-1]);

    --DIY Cards
    if DIYContainer.cards then
        for i = 1, #DIYContainer.cards do
            ReskinButton(DIYContainer.cards[i]);
            DIYContainer.cards[i].isDarkTheme = IS_DARK_THEME;
        end
    end
    DIYContainer:RefreshTheme();
    DIYContainer.NewEntry.background:SetTexture(TEXTURE_PATH.."NewEntry");
    if index == 1 then
        EditorContainer.notes:SetFontObject(NarciAchievementText);
        EditorContainer.notes:SetTextColor(0.68, 0.58, 0.51);
    elseif index == 2 then
        EditorContainer.notes:SetFontObject(NarciAchievementTextBlack);
        EditorContainer.notes:SetTextColor(0, 0, 0);
    else
        EditorContainer.notes:SetFontObject(NarciAchievementText);
        EditorContainer.notes:SetTextColor(0.5, 0.5, 0.5);
    end

    local inspectedAchievementID = AchievementCards[-1].id;
    if inspectedAchievementID then
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText = DataProvider:GetAchievementInfo(inspectedAchievementID);
        FormatAchievementCardByIndex(-1, id, name, points, completed, month, day, year, description, flags, icon, rewardText);
    end
    
    if SummaryFrame:IsVisible() then
        UpdateSummaryFrame();
    else
        if not DIYContainer:IsShown() then
            local categoryID = DataProvider.currentCategory;
            SelectCategory(categoryID);
        end
    end

    --Search Results:
    local ResultFrame = MainFrame.HeaderFrame.SearchBox.ClipFrame.ResultFrame;
    local resultButtonGap;
    if index == 3 then
        resultButtonGap = -1;
    else
        resultButtonGap = -2
    end
    ResultFrame.background:SetTexture(TEXTURE_PATH.."SearchResultFrame");
    for i = 1, #ResultFrame.buttons do
        ResultFrame.buttons[i].background:SetTexture(TEXTURE_PATH.."ResultButton");
        ResultFrame.buttons[i].mask:SetTexture(TEXTURE_PATH.."ResultButtonMask");
        if i ~= 1 then
            ResultFrame.buttons[i]:SetPoint("TOP", ResultFrame.buttons[i - 1], "BOTTOM", 0, resultButtonGap);
        end
    end

    --Border Skin
    local HeaderFrame = MainFrame.HeaderFrame;
    HeaderFrame.background:SetTexture(TEXTURE_PATH.."BoxHeaderBorder");
    HeaderFrame.mask:SetTexture(TEXTURE_PATH.."BoxHeaderBorderMask");

    MainFrame.background:SetTexture(TEXTURE_PATH.."BoxRight");
    MainFrame.categoryBackground:SetTexture(TEXTURE_PATH.."BoxLeft");

    AchievementContainer.OverlayFrame.top:SetTexture(TEXTURE_PATH.."BoxRight");
    AchievementContainer.OverlayFrame.bottom:SetTexture(TEXTURE_PATH.."BoxRight");
    AchievementContainer.scrollBar.Thumb:SetTexture(TEXTURE_PATH.."SliderThumb");
    
    CategoryContainer.OverlayFrame.top:SetTexture(TEXTURE_PATH.."BoxLeft");
    CategoryContainer.OverlayFrame.bottom:SetTexture(TEXTURE_PATH.."BoxLeft");
    CategoryContainer.scrollBar.Thumb:SetTexture(TEXTURE_PATH.."SliderThumb");

    DIYContainer.OverlayFrame.top:SetTexture(TEXTURE_PATH.."BoxRight");
    DIYContainer.OverlayFrame.bottom:SetTexture(TEXTURE_PATH.."BoxRight");
    DIYContainer.scrollBar.Thumb:SetTexture(TEXTURE_PATH.."SliderThumb");

    EditorContainer.OverlayFrame.top:SetTexture(TEXTURE_PATH.."BoxLeft");
    EditorContainer.OverlayFrame.bottom:SetTexture(TEXTURE_PATH.."BoxLeft");
    EditorContainer.scrollBar.Thumb:SetTexture(TEXTURE_PATH.."SliderThumb");
    
    --Scroll frame inner Shadow
    local showShadow = index == 1;
    AchievementContainer.OverlayFrame.topShadow:SetShown(showShadow);
    AchievementContainer.OverlayFrame.bottomShadow:SetShown(showShadow);
    DIYContainer.OverlayFrame.topShadow:SetShown(showShadow);
    DIYContainer.OverlayFrame.bottomShadow:SetShown(showShadow);
    CategoryContainer.OverlayFrame.topShadow:SetShown(showShadow);
    CategoryContainer.OverlayFrame.bottomShadow:SetShown(showShadow);
    EditorContainer.OverlayFrame.topShadow:SetShown(showShadow);
    EditorContainer.OverlayFrame.bottomShadow:SetShown(showShadow);

    --Category Buttons
    local cateButtons = {CategoryButtons.player.buttons, CategoryButtons.guild.buttons, CategoryButtons.stats.buttons,  ToDoListData.buttons};
    for _, buttons in pairs(cateButtons) do
        for i = 1, #buttons do
            if buttons[i].isParentButton then
                buttons[i].background:SetTexture(TEXTURE_PATH.."CategoryButton");
            else
                buttons[i].background:SetTexture(TEXTURE_PATH.."SubCategoryButton");
            end
            buttons[i].fill:SetTexture(TEXTURE_PATH.."CategoryButtonBar");
            buttons[i].fillEnd:SetTexture(TEXTURE_PATH.."CategoryButtonBar");
        end
    end

    HeaderFrame.fill:SetTexture(TEXTURE_PATH.."CategoryButtonBar");
    HeaderFrame.fillEnd:SetTexture(TEXTURE_PATH.."CategoryButtonBar");

    --Header Reposition
    local offsetY = 0;
    if index == 2 then
        offsetY = -6;
    end

    local FilterButton = MainFrame.FilterButton;
    FilterButton:ClearAllPoints();
    FilterButton:SetPoint("TOPRIGHT", MainFrame, "TOP", -2, -12 + offsetY);
    FilterButton.texture:SetTexture(TEXTURE_PATH.."DropDownButton");

    local CloseButton = MainFrame.CloseButton;
    CloseButton:ClearAllPoints();
    CloseButton:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -11, -11 + offsetY);
    CloseButton.texture:SetTexture(TEXTURE_PATH.."CloseButton");
    if index == 2 then
        CloseButton:SetSize(39, 26);
    else
        CloseButton:SetSize(36, 26);
    end

    local SearchBox = HeaderFrame.SearchBox
    SearchBox:ClearAllPoints();
    SearchBox:SetPoint("TOPRIGHT", HeaderFrame, "TOPRIGHT", -67, -5 + offsetY);

    local points = HeaderFrame.points;
    points:ClearAllPoints();
    points:SetPoint("TOPRIGHT", HeaderFrame, "TOP", 137, -17 + offsetY);

    local reference = HeaderFrame.reference;  --Summary All Points/Achv
    if index == 2 then
        reference:SetHeight(35);
    else
        reference:SetHeight(32);
    end

    SummaryButton:ClearAllPoints();
    SummaryButton:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 32, -8 + offsetY);
    SummaryButton.texture:SetTexture(TEXTURE_PATH.."SummaryButton");


    --Tab buttons
    for i = 1, #TabButtons do
        TabButtons[i]:SetButtonTexture(TEXTURE_PATH.."TabButton");
        if index == 1 then
            TabButtons[i]:SetTextOffset(28);
        else
            TabButtons[i]:SetTextOffset(20);
        end
    end


    --AlertSystem

    --Floating Cards
    FloatingCard:SetTheme(index);
end


--------------------------------------------------------------------
local function UpdateTrackAchievements()
    local changedAchievementID = DataProvider:GetTrackedAchievements();
    if not changedAchievementID then return end

    local currentCategory = DataProvider.currentCategory;
    local categoryID = DataProvider:GetAchievementCategory(changedAchievementID);
    local shouldUpdate;
    if categoryID == currentCategory then
        shouldUpdate = true;
    end
    local isTracked = DataProvider:IsTrackedAchievement(changedAchievementID);

    if shouldUpdate then
        local numAchievements = DataProvider.numAchievements or 0;
        local card;
        for i = 1, numAchievements do
            card = AchievementCards[i];
            if card then
                if card.id == changedAchievementID then
                    card.trackIcon:SetShown(isTracked);
                end
            else
                break
            end
        end
    end

    if (InspectionFrame:IsShown()) and (changedAchievementID == InspectionFrame.Card.id) then
        InspectionFrame.Card.trackIcon:SetShown(isTracked);
    end
end


-----------------------------------------------------------------------------
function NarciAchievementFrameMixin:Init()
    DataProvider:GetTrackedAchievements();
    PinUtil:Load();
    addon.LoadDIY();
    self:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED");
    BuildCategoryStructure(2);
    BuildCategoryStructure(1);
    BuildCategoryStructure(3);
    BuildCategoryStructure(5);
    InitializeFrame(Narci_AchievementFrame);
    self:RegisterEvent("ACHIEVEMENT_EARNED");
    self:RegisterEvent("CRITERIA_EARNED");
    self.Init = nil;
end

function NarciAchievementFrameMixin:InspectCard(card, playAnimation)
    InspectCard(card, playAnimation);
end


local function OnAchivementEarned(achievementID)
    DataProvider:UpdateAchievementCache(achievementID);
    RefreshInspection(achievementID);

    local categoryID = DataProvider:GetAchievementCategory(achievementID);
    if categoryID then
        DataProvider.achievementOrderCache[categoryID] = {};
        UpdateCategoryButtonProgressByCategoryID(categoryID);
        if categoryID == DataProvider.currentCategory then
            if MainFrame:IsShown() then
                SelectCategory(categoryID);
            else
                MainFrame.pendingCategoryID = categoryID;
            end
            return;
        end
    end
    if SummaryFrame:IsShown() then
        MainFrame.pendingUpdate = true;
    end
end

local EventListener = CreateFrame("Frame");
EventListener:RegisterEvent("ACHIEVEMENT_EARNED");
EventListener:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED");
EventListener:RegisterEvent("CONTENT_TRACKING_UPDATE");

EventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "ACHIEVEMENT_EARNED" then
        local achievementID = ...
        OnAchivementEarned(achievementID);
        if not self.pauseUpdate then
            self.pauseUpdate = true;
            After(0, function()
                UpdateHeaderFrame(isGuildView);
                self.pauseUpdate = nil;
            end);
        end
    elseif event == "TRACKED_ACHIEVEMENT_LIST_CHANGED" then
        UpdateTrackAchievements();
    elseif event == "CONTENT_TRACKING_UPDATE" then
        local type, id, isTracked = ...
        if type == 2 then
            UpdateTrackAchievements();
        end
    end
end)


addon.ReskinButton = ReskinButton;
addon.FormatAchievementCard = FormatAchievementCard;

local function IsDarkTheme()
    return IS_DARK_THEME;
end

addon.IsDarkTheme = IsDarkTheme;