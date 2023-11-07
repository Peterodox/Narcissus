local _, addon = ...
local SetGradient = addon.TransitionAPI.SetGradient;


local L = Narci.L;
local NarciThemeUtil = NarciThemeUtil;
local floor = math.floor;
local max = math.max;

local TitleTooltip, TitleList, TitleButtons, TitleFlash;
local NUM_TITLE_BUTTONS = 17;

-----------------------------
------Build Title Table------
-----------------------------
local function BuildTitlesDB(object)
    local NewTable = {};	--[TitleID] = {Category, Rarity, SourceID}
    for key, value in pairs(object) do
        NewTable[value[4]] = {value[1], value[2], value[5]}; --value[3] is the title's name // value[4] is TitleID // value[5] is AchievementID;
        --i = i + 1;
	end
    return NewTable;
end

local TitlesDB = BuildTitlesDB(Narci_CharacterTitlesTable);
Narci_CharacterTitlesTable = nil;

-----------------------------
-------Sorting Function------
-----------------------------
local sortMethod = "Category";
local function SortedByAlphabet(a, b) return a.name < b.name; end
local function SortedByCategory(a, b)
	local r;

	if a.category == b.category then
		if a.rarity == b.rarity then
			r = a.name < b.name;
		else
			r = a.rarity > b.rarity;
		end
	else
		r = a.category < b.category; 
	end

	return r;
end

--Displayed Gradient Type
local function ColorByDefault(button, index)
	if index % 2 == 1 then
		--button.BackgroundColor:SetGradient("HORIZONTAL", 0, 0 ,0, 0.2, 0.2, 0.2);
		SetGradient(button.BackgroundColor, "HORIZONTAL", 0, 0 ,0, 0.2, 0.2, 0.2);
	else
		--button.BackgroundColor:SetGradient("HORIZONTAL", 0.1, 0.1 ,0.1, 0.3, 0.3, 0.3);
		SetGradient(button.BackgroundColor, "HORIZONTAL", 0.1, 0.1 ,0.1, 0.3, 0.3, 0.3);
	end
end

local function ColorByCategory(button, type)
	if type == "achv" or type == "pve" or type == "repu" then
		--button.BackgroundColor:SetGradient("HORIZONTAL", 0.1, 0.1 ,0.1, 0.3, 0.3, 0.3);
		SetGradient(button.BackgroundColor, "HORIZONTAL", 0.1, 0.1 ,0.1, 0.3, 0.3, 0.3);
	else
		--button.BackgroundColor:SetGradient("HORIZONTAL", 0, 0 ,0, 0.2, 0.2, 0.2);
		SetGradient(button.BackgroundColor, "HORIZONTAL", 0, 0 ,0, 0.2, 0.2, 0.2);
	end
end

--Derivative from Blizzard: PaperDollFrame.lua GetKnownTitles()
--** Add a new sort func & Mark the current title in the table
--** Also returns a table which tells how many titles you've got in each category

local function BuildTitleList(sortMethod)
	local playerTitles = {};
	local numRare = 0;
	local titleCount = 2;
	local tempName = 0;
	local CurrentTitle = -1;
	local numPVP, numPVE, numACHV, numREPU, numEVENT = 0, 0, 0, 0, 0;
	local category, rarity;	
	local isPlayerTitle;
	playerTitles[1] = { };
	-- reserving space for None so it doesn't get sorted out of the top position
	playerTitles[1].name = "       ";
	playerTitles[1].id = -1;
	playerTitles[1].category = "Z";
	playerTitles[1].rarity = 0;

	local IsTitleKnown = IsTitleKnown;
	local GetTitleName = GetTitleName;
	local strtrim = strtrim;

	for i = 1, GetNumTitles() do
		if ( IsTitleKnown(i) ) then
			tempName, isPlayerTitle = GetTitleName(i);
			if ( tempName and isPlayerTitle ) then
				playerTitles[titleCount] = playerTitles[titleCount] or { };
				playerTitles[titleCount].name = strtrim(tempName);
				playerTitles[titleCount].id = i;

				if TitlesDB[i] then
					category = TitlesDB[i][1] or "achv";
					rarity = TitlesDB[i][2] or 0;
				else
					category = "achv";
					rarity = 0;
				end
				
				playerTitles[titleCount].category = category;
				playerTitles[titleCount].rarity = rarity;
				if category == "pvp" then
					numPVP = numPVP + 1;
				elseif category == "pve" then
					numPVE = numPVE + 1; 
				elseif category == "achv" then
					numACHV = numACHV + 1; 
				elseif category == "repu" then
					numREPU = numREPU + 1; 
				elseif category == "event" then
					numEVENT = numEVENT + 1; 
				end
				
				if rarity > 0 then
					numRare = numRare + 1;
				end
				titleCount = titleCount + 1;
			end
		end

		--------------------------
		--Debug Get unlogged title
		if false and not TitlesDB[i] then
			tempName, isPlayerTitle = GetTitleName(i);
			if tempName and isPlayerTitle then
				print("Unlogged Title #"..i..": "..tempName);
			end
		end
	end

	if sortMethod == "Alphabet" then
		table.sort(playerTitles, SortedByAlphabet);
	elseif sortMethod == "Category" then
		table.sort(playerTitles, SortedByCategory);
	end

	playerTitles[1].name = PLAYER_TITLE_NONE;
	CurrentTitle = GetCurrentTitle();
	if CurrentTitle then
		playerTitles.CurrentTitle = CurrentTitle;
	end

	local CategoryDetails = {};
	CategoryDetails[4] = {numPVP, CALENDAR_TYPE_PVP};
	CategoryDetails[3] = {numPVE, TRANSMOG_SET_PVE};
	CategoryDetails[1] = {numACHV, AUCTION_CATEGORY_MISCELLANEOUS};
	CategoryDetails[5] = {numREPU, REPUTATION};
	CategoryDetails[2] = {numEVENT, BATTLE_PET_SOURCE_7};
	CategoryDetails.sum = #playerTitles;
	CategoryDetails.rare = numRare;

	return playerTitles, CategoryDetails;
end

--Derivative from Blizzard: HybridScrollFrame_CreateButtons

local function CreateTitleOptions(self, buttonTemplate, initialOffsetX, initialOffsetY, initialPoint, initialRelative, offsetX, offsetY, point, relativePoint)
	local ScrollChild = self.ScrollChild;
	local button;
	TitleButtons = {};
	initialPoint = initialPoint or "TOPLEFT";
	initialRelative = initialRelative or "TOPLEFT";
	point = point or "TOPLEFT";
	relativePoint = relativePoint or "BOTTOMLEFT";
	offsetX = offsetX or 0;
	offsetY = offsetY or 0;

	local buttonHeight = 20;
	local numButtons = NUM_TITLE_BUTTONS;
	self:SetHeight(buttonHeight * (numButtons - 1));

	local buttonName = "NarciTitleOptionButton";

	for i = 1, numButtons do
		button = CreateFrame("BUTTON", buttonName..i, ScrollChild, buttonTemplate);
		button.order = i;
		button:SetPoint(initialPoint, ScrollChild, initialRelative, initialOffsetX, initialOffsetY + (1 - i) * buttonHeight);
		if button.BackgroundColor then
			if i % 2 == 1 then
				--button.BackgroundColor:SetGradient("HORIZONTAL", 0, 0 ,0, 0.2, 0.2, 0.2);
				SetGradient(button.BackgroundColor, "HORIZONTAL", 0, 0 ,0, 0.2, 0.2, 0.2);
			else
				--button.BackgroundColor:SetGradient("HORIZONTAL", 0.1, 0.1 ,0.1, 0.3, 0.3, 0.3);
				SetGradient(button.BackgroundColor, "HORIZONTAL", 0.1, 0.1 ,0.1, 0.3, 0.3, 0.3);
			end
		end
		tinsert(TitleButtons, button);
	end

	self.buttonHeight = floor(buttonHeight + 0.5) - offsetY;

	ScrollChild:SetWidth(self:GetWidth());
	ScrollChild:SetHeight(numButtons * buttonHeight);
	self:SetVerticalScroll(0);
	self:UpdateScrollChildRect();
	self.buttons = TitleButtons;

	local scrollBar = self.scrollBar;
	scrollBar:SetMinMaxValues(0, numButtons * buttonHeight);
	scrollBar.buttonHeight = buttonHeight;
	scrollBar:SetValue(0);

	ScrollChild:SetScript("OnShow", function(ScrollChild)
		local index = NarciThemeUtil:GetColorIndex();
		if index ~= ScrollChild.index then
			ScrollChild.index = index;
			local r, g, b = NarciThemeUtil:GetColor()
			for i = 1, numButtons do
				TitleButtons[i].HighlightColor:SetColorTexture(r, g, b);
				TitleButtons[i].SelectedColor:SetColorTexture(r, g, b);
			end
		end
	end);
end

local function SmoothScrollFrame_Update(self, totalHeight, displayedHeight)
	local range = floor(totalHeight - self:GetHeight() + 0.5);

	if ( range > 0 and self.scrollBar ) then
		local minVal, maxVal = self.scrollBar:GetMinMaxValues();
		if ( floor(self.scrollBar:GetValue()) >= floor(maxVal) ) then
			self.scrollBar:SetMinMaxValues(0, range)
			if ( floor(self.scrollBar:GetValue()) ~= floor(range) ) then
				self.scrollBar:SetValue(range);
			else
				HybridScrollFrame_SetOffset(self, range); -- If we've scrolled to the bottom, we need to recalculate the offset.
			end
		else
			self.scrollBar:SetMinMaxValues(0, range)
		end
		self.scrollBar:Enable();
		self.scrollBar:Show();
	elseif ( self.scrollBar ) then
		self.scrollBar:SetValue(0);
		if ( self.scrollBar.doNotHide ) then
			self.scrollBar:Disable();
			self.scrollBar.thumbTexture:Hide();
		else
			self.scrollBar:Hide();
		end
	end

	self.range = range;
	self.totalHeight = totalHeight;
	self.ScrollChild:SetHeight(displayedHeight);
	self:UpdateScrollChildRect();
end

--Derivative from Blizzard: HybridScrollFrame_Update
local function TitileManager_UpdateList()
	local scrollFrame = TitleList.ScrollFrame;
	local List = scrollFrame.updatedList;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;

	local numList = #List   --#buttons;
	--print("numList: "..numList)
	if numList > 1 then
		scrollFrame.scrollBar.thumbTexture:SetHeight(max((320*2/numList), 8))
	end

	for i= 1, #buttons do
		local button = buttons[i];
		local displayIndex = i + offset;
		if ( displayIndex <= numList ) then
			button.titleID = List[displayIndex].id;

			if button.titleID == List.CurrentTitle then
				button.SelectedColor:Show();
			else
				button.SelectedColor:Hide();
			end
			
			if button.BackgroundColor then
				if sortMethod == "Alphabet" then
					ColorByDefault(button, displayIndex);
				elseif sortMethod == "Category" then
					ColorByCategory(button, List[displayIndex].category);
				end
			end
			
			button.Name:SetText(List[displayIndex].name);
			button.Name:SetAlpha(1)

			if List[displayIndex].rarity > 0 then
				button.Star:Show();
			else
				button.Star:Hide();
			end

			button:Show();
			button:SetEnabled(true);
		else
			button:Hide();
			button:SetEnabled(false);
		end
	end
	
	local totalHeight = numList * buttons[1]:GetHeight();
	SmoothScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight());
end


-----------------------------
--------Initialization-------
-----------------------------

local sortedList = {};
local CategoryNumDetails = {};

local function SortTitleList(method)
	local scrollFrame = TitleList.ScrollFrame;
	sortedList, CategoryNumDetails = BuildTitleList(method);
	scrollFrame.updatedList = sortedList;
	TitileManager_UpdateList();
end


local function CreateSliderTextureAndLabel()
	if not CategoryNumDetails then
		return;
	end
	local numTotal = CategoryNumDetails.sum or 1;
	local slider = TitleList.ScrollFrame.scrollBar;
	local ScrollChildHeight = numTotal * 20 --Title Button Height;
	local baseHeight = TitleList.ScrollFrame:GetHeight() or 1;
	local offsetX = 2;
	local width = 2;
	local minHeight = 8;
	local heightRatio = baseHeight/numTotal;
	local height = max(CategoryNumDetails[1][1] * heightRatio, minHeight);
	local lastHeight = height;
	local numType = 5;
	local Tex = slider:CreateTexture(nil, "BACKGROUND");
	local Texs = {};
	local button = CreateFrame("BUTTON", nil, slider, "NarciTitleCategoryLabelTemplate");
	local buttonHeight = button:GetHeight();
	local buttons = {};
	local num = CategoryNumDetails[1][1] or 0;
	local lastNum = 0;

	local FilterButton = TitleList.FilterButton;
	local numRare = CategoryNumDetails.rare or 0;
	FilterButton.Label:SetText(TOTAL.." "..(numTotal-1))
	if numRare > 0 then
		FilterButton.numRare:SetText(numRare)
		FilterButton.numRare:Show()
		FilterButton.Star:Show()
	end

	Tex:SetWidth(width);
	Tex:SetHeight(height);
	Tex:SetPoint("TOP", slider, "TOP", 0, 0)
	Tex:SetColorTexture(0.6, 0.6, 0.6, 1)
	tinsert(Texs, Tex);
	button:SetPoint("TOPLEFT", Tex, "TOPRIGHT", 2, 0)
	button.Label:SetText(num.." "..CategoryNumDetails[1][2]);
	button.value = lastNum;
	lastNum = lastNum + num;
	tinsert(buttons, button);

	for i = 2, numType do
		num = CategoryNumDetails[i][1] or 0;
		height = max(num * heightRatio, minHeight);
		Tex = slider:CreateTexture(nil, "BACKGROUND");
		Tex:SetWidth(width);
		

		if i < numType then
			Tex:SetHeight(height);
			Tex:SetPoint("TOP", Texs[i-1], "BOTTOM", 0, 0)
		else
			Tex:SetPoint("TOP", Texs[i-1], "BOTTOM", 0, 0)
			Tex:SetPoint("BOTTOM", slider, "BOTTOM", 0, 0)
		end

		button = CreateFrame("BUTTON", nil, slider, "NarciTitleCategoryLabelTemplate");
		button:SetPoint("TOPLEFT", Tex, "TOPRIGHT", offsetX, 0)
		button.Label:SetText(num.." "..CategoryNumDetails[i][2]);


		if lastHeight < buttonHeight then
			button:ClearAllPoints();
			button:SetPoint("TOPLEFT", Tex, "TOPRIGHT", offsetX, lastHeight - buttonHeight)
		end
		lastHeight = height;

		if i % 2 == 1 then
			Tex:SetColorTexture(0.6, 0.6, 0.6, 1)
		else
			Tex:SetColorTexture(0.3, 0.3, 0.3, 1)
		end

		button.value = 20 * lastNum
		lastNum = lastNum + num;

		tinsert(Texs, Tex);
		tinsert(buttons, button);
	end

	slider.buttons = buttons;
	slider.Texs = Texs;
end

local function HideSliderLabel()
	local slider = TitleList.ScrollFrame.scrollBar;
	if not(slider.Texs and slider.buttons) then
		return;
	end
	
	local flag = NarcissusDB.IsSortedByCategory;

	for i=1, #slider.Texs do
		slider.Texs[i]:SetShown(flag);
	end
	for i=1, #slider.Texs do
		slider.buttons[i]:SetShown(flag);
	end
end


-----------------------------
-----Create Smooth Scroll----
-----------------------------
local function ScrollFrame_PositionFunc(endValue, delta, scrollBar, isTop, isBottom)
	TitleTooltip:Hide();
	TitleTooltip.isPaused = true;
end

local function ScrollFrame_OnScrollFinishedFunc()
	TitleTooltip:OnScrollStopped();
end

function Narci_TitleList_ScrollFrame_OnLoad(self)
	TitleList = self:GetParent();
	TitleFlash = self.ScrollChild.TitleFlash;

	function TitleFlash:FlashOnButton(f)
		self:ClearAllPoints();
		self:SetPoint("RIGHT", f, "LEFT", 0, 0);
		self.FlyBy:Stop();
		self.FlyBy:Play();
		self:Show();
	end

    self:EnableMouse(true);
    CreateTitleOptions(self, "NarciTitleOptionTemplate", 0, 0, nil, nil, 0, 0);
	NarciAPI_SmoothScroll_Initialization(self, nil, TitileManager_UpdateList, 3, 0.2, nil, ScrollFrame_PositionFunc, ScrollFrame_OnScrollFinishedFunc);

	--Scrollbar methods
	local scrollBar = self.scrollBar;
	local HybridScrollFrame_SetOffset = HybridScrollFrame_SetOffset;
	scrollBar:SetScript("OnValueChanged", function(scrollBar, value)
		HybridScrollFrame_SetOffset(self, value);
	end);

	scrollBar:SetScript("OnEnter", function(scrollBar)
		scrollBar.thumbTexture:SetColorTexture(1, 1, 1);
		TitleTooltip:FadeOut();
	end)

	scrollBar:SetScript("OnLeave", function(scrollBar)
		if not scrollBar:IsDraggingThumb() then
			scrollBar.thumbTexture:SetColorTexture(0.25, 0.78, 0.92);
		end
	end)

	scrollBar:SetScript("OnMouseDown", function(scrollBar)
		scrollBar.isMouseDown = true;
		--Narci_LinearScrollUpdater:Start(self, 80, true);
	end)

	scrollBar:SetScript("OnMouseUp", function(scrollBar)
		scrollBar.isMouseDown = false;
		if not scrollBar:IsMouseOver() then
			scrollBar.thumbTexture:SetColorTexture(0.25, 0.78, 0.92);
		end
	end)

	scrollBar:SetObeyStepOnDrag(false);


	self:SetScript("OnLoad", nil);
	Narci_TitleList_ScrollFrame_OnLoad = nil;
end


-------------------
local pow = math.pow;
local pi = math.pi;
local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

-------------------
local LIST_FULL_HEIGHT = 320 + 20;

local animList = NarciAPI_CreateAnimationFrame(0.5);

animList:SetScript("OnUpdate", function(self, elapsed)
	self.total = self.total + elapsed;
	local alpha = outQuart(self.total, self.fromAlpha, self.toAlpha, self.duration);
	local height = outQuart(self.total, self.fromHeight, self.toHeight, self.duration);
	if self.total >= self.duration then
		self:Hide();
		alpha = self.toAlpha;
		height = self.toHeight;
		self:Hide();
		if self.toAlpha == 0 then
			Narci_TitleFrame:Hide();
		end
	end
	self.BlackScreen:SetAlpha(alpha);
	self.TitleListFrame:SetHeight(height);
end);


function animList:Collapse()
	self:Hide();
	self.toHeight = 0.1;
	local fromHeight = self.TitleListFrame:GetHeight();
	self.fromHeight = fromHeight;
	self.fromAlpha = self.BlackScreen:GetAlpha();
	self.toAlpha = 0;
	self:Show();
end

function animList:Expand()
	self:Hide();
	self.toHeight = LIST_FULL_HEIGHT;
	local fromHeight = self.TitleListFrame:GetHeight();
	self.fromHeight = fromHeight;
	self.fromAlpha = self.BlackScreen:GetAlpha();
	self.toAlpha = 1;
	self:Show();
end

local function ShowTitleMangerTooltip(self, elapsed)
	self.counter = self.counter + elapsed;
	if self.counter > 0.8 then
		local tooltipFrame = self.Tooltip;
		local titleFrame = Narci_PlayerInfoFrame.Miscellaneous;
		if self.isOn then
			tooltipFrame:SetText(L["Close Title Manager"]);
		else
			tooltipFrame:SetText(L["Open Title Manager"]);
		end
		UIFrameFadeIn(tooltipFrame, 0.25, tooltipFrame:GetAlpha(), 1);
		UIFrameFadeOut(titleFrame, 0.15, titleFrame:GetAlpha(), 0);
		self.counter = 0;
		self:SetScript("OnUpdate", nil);
	end
end

local function Narci_TitleManager_Switch_TooltipCountDown(self)
	self:SetScript("OnUpdate", ShowTitleMangerTooltip);
end


NarciTitleOptionMixin = {};

function NarciTitleOptionMixin:OnLoad()
	self.Star:SetTexture("Interface/AddOns/Narcissus/Art/Tooltip/Hexagram", nil, nil, "TRILINEAR");
end

function NarciTitleOptionMixin:OnClick(button, down)
	if self.titleID then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
		SetCurrentTitle(self.titleID);
		local scrollFrame = TitleList.ScrollFrame;
		scrollFrame.updatedList.CurrentTitle = self.titleID;
		TitileManager_UpdateList();

		TitleFlash:FlashOnButton(self);
	end
end

function NarciTitleOptionMixin:OnEnter()
	self.HighlightColor:Show();
	self.Name:SetTextColor(1, 1, 1, 1);

	local id = self.titleID;
	TitleTooltip.parentButton = self;

	if not TitleTooltip.isPaused then
		if not id or id == -1 or not TitlesDB[id] then
			TitleTooltip:FadeOut();
		else
			TitleTooltip:SetSource(self, TitlesDB[id][3]);
		end
	end
end

function NarciTitleOptionMixin:OnLeave()
	self.Name:SetTextColor(0.8, 0.8, 0.8, 1);
	self.HighlightColor:Hide();
	TitleTooltip:FadeOut();
	TitleTooltip.parentButton = nil;
end

function NarciTitleOptionMixin:OnHide()
	self.HighlightColor:Hide();
end

function NarciTitleOptionMixin:OnMouseDown(button, isGamepad)

end

function NarciTitleOptionMixin:OnMouseUp(button, isGamepad)

	TitleTooltip.isPaused = false;
end


NarciTitleCategoryButtonMixin = {};

function NarciTitleCategoryButtonMixin:OnEnter()
	TitleTooltip:FadeOut();
	self.Label:SetAlpha(1);
end

function NarciTitleCategoryButtonMixin:OnLeave()
	self.Label:SetAlpha(0.5);
end

function NarciTitleCategoryButtonMixin:OnClick()
	if self.value then
		local scrollFrame = TitleList.ScrollFrame;
		local top = scrollFrame:GetTop();
		local bottom = self:GetTop();
		local offset = top - bottom;
		local scrollBar = scrollFrame.scrollBar
		scrollBar:SetValue(self.value - offset + 20);
	end
end


NarciTitleTooltipMixin = {};

function NarciTitleTooltipMixin:OnLoad()
	TitleTooltip = self;
	self.achievementID = 1208;
	self.Pointer:SetTexture("Interface/AddOns/Narcissus/Art/Tooltip/Diamond", nil, nil, "TRILINEAR");
	self.animFade = NarciAPI_CreateFadingFrame(self);
end

function NarciTitleTooltipMixin:OnHide()
	self.animFade:Hide();
	self:Hide();
	self:SetAlpha(0);
end

function NarciTitleTooltipMixin:PauseAndHide()
	self:Hide();
	self.isPaused = true;
end

function NarciTitleTooltipMixin:OnScrollStopped()
	self.isPaused = false;
	if self.parentButton then
		self.parentButton:OnEnter();
	end
end

function NarciTitleTooltipMixin:ShowSource()
	local _, name, description, icon;
	if self.achievementID then
		_, name, _, _, _, _, _, description, _, icon = GetAchievementInfo(tonumber(self.achievementID));
		self.Icon:SetTexture(icon);
		self.Title:SetText(name);
		self.Description:SetText(description);
		if not description then return; end;
		local lines = self.Description:GetNumLines() + self.Title:GetNumLines();
		if lines < 2 then
			self.Description:SetText(description.."\n \n ");
		elseif lines < 3 then
			self.Description:SetText(description.."\n ");
		end
	else
		return false
	end

	if name then
		return true
	else
		return false
	end
end

function NarciTitleTooltipMixin:SetSource(button, achievementID)
	if not achievementID then
		self:FadeOut();
		return
	end

	self.achievementID = achievementID;
	if self:ShowSource() then
		self:ClearAllPoints();
		self:SetPoint("TOPRIGHT", button, "TOPLEFT", -8, 0);
		self:FadeIn();
	else
		self:FadeOut();
	end
end


local function UpdateFilter(self)
	if NarcissusDB.IsSortedByCategory then
		sortMethod = "Category";
		self.Method:SetText(CATEGORY);
	else
		sortMethod = "Alphabet";
		self.Method:SetText(COMPACT_UNIT_FRAME_PROFILE_SORTBY_ALPHABETICAL);

	end
	SortTitleList(sortMethod);
end

NarciTitleFilterButtonMixin = {};

function NarciTitleFilterButtonMixin:OnLoad()
	self.Star:SetTexture("Interface/AddOns/Narcissus/Art/Tooltip/Hexagram", nil, nil, "TRILINEAR");
end

function NarciTitleFilterButtonMixin:OnEnter()
	TitleTooltip:FadeOut();
	self.Highlight:Show();
end

function NarciTitleFilterButtonMixin:OnLeave()
	self.Highlight:Hide();
end

function NarciTitleFilterButtonMixin:OnClick()
	NarcissusDB.IsSortedByCategory = not NarcissusDB.IsSortedByCategory;
	UpdateFilter(self);
	HideSliderLabel();
	TitleList.ScrollFrame.scrollBar:SetValue(0);
	TitleTooltip:FadeOut();
end


NarciTitleManagerSwitchMixin = {};

function NarciTitleManagerSwitchMixin:OnLoad()
	self.isOn = false;
	self.counter = 0;
	NarciAPI.NineSliceUtil.SetUpBackdrop(self, "focus");
end

function NarciTitleManagerSwitchMixin:Close()
	if self.isOn then
		self.isOn = false;
		animList:Collapse()
		TitleTooltip.isPaused = true;
		TitleTooltip:Hide();
		self.Tooltip:SetText(L["Open Title Manager"]);
		self:SetScript("OnUpdate", nil);
		self.counter = 0;
		self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
	end
end

function NarciTitleManagerSwitchMixin:OnClick()
	self.isOn = not self.isOn;
	if self.isOn then
		TitleTooltip.isPaused = false;
		Narci_TitleFrame:Show()
		animList:Expand();
		self.Tooltip:SetText(L["Close Title Manager"]);
		self:RegisterEvent("GLOBAL_MOUSE_DOWN");
	else
		TitleTooltip.isPaused = true;
		animList:Collapse();
		self.Tooltip:SetText(L["Open Title Manager"]);
		TitleTooltip:FadeOut();
		self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
	end

	self:SetScript("OnUpdate", nil);
	self.counter = 0;
end

function NarciTitleManagerSwitchMixin:OnEnter()
	TitleTooltip:FadeOut();
	UIFrameFadeIn(self, 0.15, self:GetAlpha(), 1);
	Narci_TitleManager_Switch_TooltipCountDown(self);
end

function NarciTitleManagerSwitchMixin:OnLeave()
	UIFrameFadeOut(self, 0.25, self:GetAlpha(), 0);
	self.counter = 0;
	self:SetScript("OnUpdate", nil);
	UIFrameFadeOut(self.Tooltip, 0.15, self.Tooltip:GetAlpha(), 0);
	local titleFrame = Narci_PlayerInfoFrame.Miscellaneous;
	UIFrameFadeIn(titleFrame, 0.25, titleFrame:GetAlpha(), 1);
end

function NarciTitleManagerSwitchMixin:OnShow()
	TitleList:SetHeight(0.1);
	TitleList.ScrollFrame.scrollBar:SetValue(40);   --workaround
	TitleList.ScrollFrame.scrollBar:SetValue(0);
	animList:Hide();
	Narci_TitleFrame.BlackScreen:SetAlpha(0);
end

function NarciTitleManagerSwitchMixin:OnHide()
	self:SetAlpha(0);
	self.counter = 0;
	self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
	if self.isOn then
		self.isOn = nil;
		self.Tooltip:SetText(L["Open Title Manager"]);
		TitleTooltip:Hide();
		animList.TitleListFrame:SetHeight(0.1);
		animList.BlackScreen:SetAlpha(0);
		Narci_TitleFrame:Hide();
	end
end


function NarciTitleManagerSwitchMixin:IsInBound()
	return (TitleList:IsMouseOver(0, 0, -72, 0) or self:IsMouseOver());
end

function NarciTitleManagerSwitchMixin:OnEvent(event)
	if not self:IsInBound() then
		self:Close();
	end
end

local LoadSettings = CreateFrame("Frame");
LoadSettings:RegisterEvent("PLAYER_ENTERING_WORLD");
LoadSettings:SetScript("OnEvent",function(self,event,...)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD");
	animList.BlackScreen = Narci_TitleFrame.BlackScreen;
	animList.TitleListFrame = TitleList;
	C_Timer.After(2, function()
		UpdateFilter(TitleList.FilterButton);
		CreateSliderTextureAndLabel();
		HideSliderLabel();
	end)
end)