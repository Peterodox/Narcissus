local _, addon = ...

local IS_DRAGONFLIGHT = addon.IsDragonflight();
local outSine = addon.EasingFunctions.outSine;
local inOutSine = addon.EasingFunctions.inOutSine
local FadeFrame = NarciFadeUI.Fade;
local L = Narci.L;
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded;

local Minimap = Minimap;
local After = C_Timer.After;
local cos = math.cos;
local sin = math.sin;
local sqrt = math.sqrt;
local atan2 = math.atan2;

local GetMouseFocus = addon.TransitionAPI.GetMouseFocus;

local MiniButton;

local DURATION_LOCK = 1;

-- Derivative from [[LibDBIcon-1.0]]
local MapShapeUtil = {};

MapShapeUtil.shapes = {
	["ROUND"] = {true, true, true, true},
	["SQUARE"] = {false, false, false, false},
	["CORNER-TOPLEFT"] = {false, false, false, true},
	["CORNER-TOPRIGHT"] = {false, false, true, false},
	["CORNER-BOTTOMLEFT"] = {false, true, false, false},
	["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
	["SIDE-LEFT"] = {false, true, false, true},
	["SIDE-RIGHT"] = {true, false, true, false},
	["SIDE-TOP"] = {false, false, true, true},
	["SIDE-BOTTOM"] = {true, true, false, false},
	["TRICORNER-TOPLEFT"] = {false, true, true, true},
	["TRICORNER-TOPRIGHT"] = {true, false, true, true},
	["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
	["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
};

function MapShapeUtil:IsAnchoredToMinimap(x, y)
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND";

	if shape == "SQUARE" then
		local x1, x2 = Minimap:GetLeft(), Minimap:GetRight();
		local y1, y2 = Minimap:GetBottom(), Minimap:GetTop();
		local offset = self.cornerRadius + 2;
		x1 = x1 - offset;
		x2 = x2 + offset;
		y1 = y1 - offset;
		y2 = y2 + offset;
		return (x >= x1 and x <= x2 and y >= y1 and y <= y2)
	else
		local r = Minimap:GetWidth() / 2 + self.cornerRadius + 2;
		local x0, y0 = Minimap:GetCenter();
		local d = sqrt( (x - x0)^2 + (y - y0)^2 );
		return d <= r
	end
end

local function MinimapButton_SetAngle(radian)
	local x, y, q = cos(radian), sin(radian), 1;
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end

	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND";
    if not MapShapeUtil.shapes[minimapShape] then
        minimapShape = "ROUND";
    end

	local quadTable = MapShapeUtil.shapes[minimapShape];
	local w = (Minimap:GetWidth() / 2) + MapShapeUtil.cornerRadius;
	local h = (Minimap:GetHeight() / 2) + MapShapeUtil.cornerRadius;
	if quadTable[q] then
		x, y = x*w, y*h;
	else
		local diagRadiusW = sqrt(2*(w)^2) - MapShapeUtil.cornerRadius;
		local diagRadiusH = sqrt(2*(h)^2) - MapShapeUtil.cornerRadius;
		x = math.max(-w, math.min(x*diagRadiusW, w));
		y = math.max(-h, math.min(y*diagRadiusH, h));
	end
	MiniButton:SetPoint("CENTER", Minimap, "CENTER", x, y);
end


NarciMinimapButtonMixin = {};

function NarciMinimapButtonMixin:CreatePanel()
	local Panel = self.Panel;
	Panel.narciWidget = true;

	local button;
	local buttons = {};

	local LOCALIZED_NAMES = {L["Photo Mode"], DRESSUP_FRAME, L["Turntable"], ACHIEVEMENT_BUTTON};	-- CHARACTER_BUTTON, "Character Info" "Dressing Room" "Achievements"
	local frameNames = {};
	frameNames[4] = "Narci_Achievement";

	local func = {
        function()
		    Narci_OpenGroupPhoto();
        end,

		function()
			Narci_ShowDressingRoom();
		end,

		function()
			NarciOutfitShowcase:Open();
		end,

		function()
			if not Narci_AchievementFrame then
				Narci.LoadAchievementPanel();
				return
			else
				Narci_AchievementFrame:SetShown(not Narci_AchievementFrame:IsShown());
			end
		end
	};

	local menuInfo = {};
	self.menuInfo = menuInfo;

	for i = 1, #LOCALIZED_NAMES do
		if func[i] then
			table.insert(menuInfo, {
				text = LOCALIZED_NAMES[i],
				func = func[i],
				notCheckable = true,
			}
		);
		end
	end

	local numButtons = #LOCALIZED_NAMES;

	local BUTTON_HEIGHT = 24;
	local offsetY = BUTTON_HEIGHT * (numButtons - 1) / 2;
	local middleHeight = 48 + (numButtons - 4) * BUTTON_HEIGHT;
	local button1OffsetY = offsetY - middleHeight/2 + BUTTON_HEIGHT/2
	local buttonFrameLevel = Panel:GetFrameLevel() + 1;

	local ClipFrame = Panel.ClipFrame;
	ClipFrame:SetFrameLevel(buttonFrameLevel + 1);
	ClipFrame:ClearAllPoints();
	ClipFrame:SetPoint("CENTER", Panel.Middle, "CENTER", 0, offsetY);
	ClipFrame.Highlight:SetTexture("Interface/AddOns/Narcissus/Art/Minimap/Panel", nil, nil, "TRILINEAR");
	ClipFrame.PushedHighlight:SetTexture("Interface/AddOns/Narcissus/Art/Minimap/Panel", nil, nil, "TRILINEAR");

	local animHighlight = NarciAPI_CreateAnimationFrame(0.25);
	animHighlight.object = ClipFrame;

	Panel:SetHeight(numButtons * BUTTON_HEIGHT + self:GetHeight());
	Panel:SetScript("OnLeave", function(frame)
		if not frame:IsMouseOver() then
			self:ShowPopup(false);
		else
			if not self:IsFocused() then
				self:ShowPopup(false);
			end
		end
	end)
	Panel:SetScript("OnHide", function(frame)
		frame:SetAlpha(0);
		frame:Hide();
		animHighlight:Hide();
		ClipFrame:SetPoint("CENTER", Panel.Middle, "CENTER", 0, offsetY);
		ClipFrame:Hide();
		self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
	end)

	-----------------------------------------------------------

	animHighlight:SetScript("OnUpdate", function(frame, elapsed)
		frame.total = frame.total + elapsed;
		local y = inOutSine(frame.total, frame.fromY, frame.toY, frame.duration);
		if frame.total >= frame.duration then
			y = frame.toY;
			frame:Hide();
		end
		frame.object:SetPoint("CENTER", Panel.Middle, "CENTER", 0, y);
	end);

	self.lastIndex = 1;
	local function UpdateHighlight(buttonIndex)
		ClipFrame:Show();
		if animHighlight:IsShown() then
			local newDirection;
			if buttonIndex > self.lastIndex then
				newDirection = -1;
			else
				newDirection = 1;
			end
			if newDirection ~= self.lastDirection then
				animHighlight:Hide();
				local _;
				_, _, _, _, animHighlight.fromY = ClipFrame:GetPoint();
			else
				--animHighlight.total = animHighlight.total / 2;
			end
		else
			local _;
			_, _, _, _, animHighlight.fromY = ClipFrame:GetPoint();
		end
		animHighlight.toY = offsetY - (buttonIndex - 1)*24;
		animHighlight:Show();
	end

	function self:IsInBound()
		for i = 1, numButtons do
			if buttons[i]:IsMouseOver() then
				return true
			end
		end
		return false
	end

	-----------------------------------------------------------
	local panelEntrance = NarciAPI_CreateAnimationFrame(0.25);
	self.panelEntrance = panelEntrance;
	panelEntrance.object = Panel.Middle;
	Panel.Middle:SetHeight(middleHeight);
	panelEntrance.toHeight = middleHeight;

	panelEntrance:SetScript("OnUpdate", function(frame, elapsed)
		frame.total = frame.total + elapsed;
		local height = outSine(frame.total, frame.fromHeight, frame.toHeight, frame.duration);
		local buttonDistance = outSine(frame.total, 12, 0, frame.duration);
		local alpha = math.min(Panel:GetAlpha() + elapsed/frame.duration, 1);
		if frame.total >= frame.duration then
			height = frame.toHeight;
			buttonDistance = 0;
			alpha = 1;
			frame:Hide();
		end
		frame.object:SetHeight(height);
		for i = 1, numButtons do
			if i == 1 then
				buttons[i]:SetPoint("TOP", Panel.Middle, "TOP", 0, button1OffsetY + buttonDistance);
			else
				buttons[i]:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, buttonDistance * sqrt(i));
			end
		end
		Panel:SetAlpha(alpha);
	end)

	Panel:SetScript("OnShow", function()
		panelEntrance.total = 0;
		if panelEntrance:IsShown() then
			panelEntrance.fromHeight = Panel:GetHeight();
		else
			panelEntrance.fromHeight = 1;
			panelEntrance:Show();
		end
	end)
	-----------------------------------------------------------
	local function OnEnter(button)
		if not ClipFrame:IsShown() then
			FadeFrame(ClipFrame, 0.2, 1);
		end
		if button:IsEnabled() then
			UpdateHighlight(button.index);
		end
		SetCursor("Interface/CURSOR/Item.blp");
	end

	local function OnLeave(button)
		if not self:IsInBound() then
			FadeFrame(ClipFrame, 0.2, 0);
			ResetCursor();
		end
		if not self:IsFocused() then
			self:ShowPopup(false);
		end
	end

	
	local function OnMouseDown()
		ClipFrame.PushedHighlight:Show();
	end

	local function OnMouseUp()
		ClipFrame.PushedHighlight:Hide();
	end

	for i = 1, numButtons do
		local frameName = frameNames[i];
		if frameName then
			frameName = frameName.."_MinimapButton";
		end
		button = CreateFrame("Button", frameName, Panel, "NarciMinimapPanelButtonTemplate");
		table.insert(buttons, button);
		button:SetFrameLevel(buttonFrameLevel);
		button.BlackText:SetText(LOCALIZED_NAMES[i]);
		button.WhiteText:SetText(LOCALIZED_NAMES[i]);
		button.BlackText:SetParent(ClipFrame);
		button.index = i;
		button.func = func[i];
		button.narciWidget = true;

		if i == 1 then
			button:SetPoint("TOP", Panel.Middle, "TOP", 0, button1OffsetY);
		else
			button:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, 0);
			--button:SetPoint("TOP", Panel.Middle, "TOP", 0, offsetY - middleHeight/2 + BUTTON_HEIGHT/2 - BUTTON_HEIGHT * (i - 1) );
		end

		button:SetScript("OnEnter", OnEnter);
		button:SetScript("OnLeave", OnLeave);
		button:SetScript("OnMouseDown", OnMouseDown);
		button:SetScript("OnMouseUp", OnMouseUp);
		button:SetScript("OnClick", function(frame, key)
			self:ShowPopup(false);
			if key == "LeftButton" and frame.func then
				frame.func();
			end
		end);

		if not func[i] then
			button:Disable();
		end
	end
	self.buttons = buttons;

	Panel.Version:SetText(NarciAPI.GetAddOnVersionInfo(true));
	self.CreatePanel = nil;
end

function NarciMinimapButtonMixin:IsFocused()
	if self:IsShown() then
		if self.Panel:IsShown()then
			if self.Panel:IsMouseOver() then
				local obj = GetMouseFocus();
				if obj and obj.narciWidget then
					return true
				end
			end
		end
	end
end

function NarciMinimapButtonMixin:OnLoad()
	MiniButton = self;
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:SetFrameStrata("MEDIUM");
	self:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp");
	self:RegisterForDrag("LeftButton");
	self.endAlpha = 1;
	self.narciWidget = true;
	self:CreatePanel();

	--Create Popup Delay
	local delay = NarciAPI_CreateAnimationFrame(0.35);	--Mouseover Delay
	self.onEnterDelay = delay;
	delay:SetScript("OnUpdate", function(frame, elapsed)
		frame.total = frame.total + elapsed;
		if frame.total >= frame.duration then
			if self:IsMouseOver() then
				self:ShowPopup(true);
			end
			frame:Hide();
		end
	end)

	local tooltip = self.TooltipFrame;
	tooltip.Left:SetVertexColor(0.686, 0.914, 0.996);
	tooltip.Middle:SetVertexColor(0.686, 0.914, 0.996);
	tooltip.Right:SetVertexColor(0.686, 0.914, 0.996);

	--Position Update Frame
	local f = CreateFrame("Frame");
	self.PositionUpdator = f;
	f:Hide();
	f.t = 0;
	f:SetScript("OnUpdate", function()
		local radian;
		local px, py = GetCursorPosition();
		px, py = px / f.uiScale, py / f.uiScale;
		radian = atan2(py - f.mapY, px - f.mapX);
		MinimapButton_SetAngle(radian);
		NarcissusDB.MinimapButton.Position = radian;
	end)


	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;
end

function NarciMinimapButtonMixin:UpdatePosition()
	if NarcissusDB.AnchorToMinimap then
		self:ClearAllPoints();
		local radian = NarcissusDB.MinimapButton.Position;
		MinimapButton_SetAngle(radian);
	end
end

function NarciMinimapButtonMixin:EnableButton()
	NarcissusDB.ShowMinimapButton = true;
	self:Show();
	self:PlayBling();
end

function NarciMinimapButtonMixin:ResetPosition()
	NarcissusDB.MinimapButton.Position = (-0.83 * math.pi);
	NarcissusDB.AnchorToMinimap = true;
	self:UpdatePosition();
	self:EnableButton();
end

function NarciMinimapButtonMixin:IsAnchoredToMinimap()
	local x, y = self:GetCenter();
	return MapShapeUtil:IsAnchoredToMinimap(x, y);
end

function NarciMinimapButtonMixin:SetTooltipText(text)
	local tooltip = self.TooltipFrame;
	tooltip.Description:SetText(text);
	local textWidth = tooltip.Description:GetWidth();
	tooltip:SetWidth(max(32, textWidth + 8));
	tooltip:ClearAllPoints();

	local scale = UIParent:GetEffectiveScale();
	local x, y = self:GetCenter();
	y = y + 36;
	tooltip:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x*scale, y*scale);
	tooltip:Show();
end

function NarciMinimapButtonMixin:StartRepositioning()
	self:ShowPopup(false);
	self:StopMovingOrSizing();
	self.PositionUpdator:Hide();
	self.TooltipFrame:Hide();
	self:ClearAllPoints();
	if not IsShiftKeyDown() and self:IsAnchoredToMinimap() then
		self:SetTooltipText("Hold Shift for free move");
		self.PositionUpdator.mapX, self.PositionUpdator.mapY = Minimap:GetCenter();
		self.PositionUpdator.uiScale = Minimap:GetEffectiveScale();
		self.PositionUpdator:Show();
		NarcissusDB.AnchorToMinimap = true;
	else
		self:StartMoving();
		NarcissusDB.AnchorToMinimap = false;
	end
	self:RegisterEvent("MODIFIER_STATE_CHANGED");
end

function NarciMinimapButtonMixin:OnDragStart()
	self:StartRepositioning();
end

function NarciMinimapButtonMixin:OnDragStop()
	self.PositionUpdator:Hide();
	self:StopMovingOrSizing();
	self:SetUserPlaced(true);
	if self:IsMouseOver() then
		self:OnEnter();
	end
	self:UnregisterEvent("MODIFIER_STATE_CHANGED");
	self.TooltipFrame:Hide();
end

function NarciMinimapButtonMixin:PostClick(button, down)
	if button == "MiddleButton" then
		Narci:EmergencyStop();
	end
end

function NarciMinimapButtonMixin:OnMouseDown()
	self.onEnterDelay:Hide();
end

function NarciMinimapButtonMixin:OnClick(button, down)
	self.onEnterDelay:Hide();
	GameTooltip:Hide();

	if button == "MiddleButton" then
		return;
	elseif button == "RightButton" then
		if IsShiftKeyDown() then
			NarcissusDB.ShowMinimapButton = false;
			print("Minimap button has been hidden. You may type /Narci minimap to re-enable it.");
			self:Hide();
		else
			if self.showPanelOnMouseOver then
				Narci_OpenGroupPhoto();
				GameTooltip:Hide();
				self:Disable();
				After(DURATION_LOCK, function()
					self:Enable()
				end)
			else
				self:ShowPopup(true);
			end
		end
		return;
	end

	--"LeftButton"
	if IsShiftKeyDown() then
		Narci_ShowDressingRoom();
		return;
	end

	self:Disable();
	Narci_Open();

	After(DURATION_LOCK, function()
		self:Enable();
	end)
end

function NarciMinimapButtonMixin:SetBackground(index)
	local useCovenantColor = false;
	local prefix = "Interface/AddOns/Narcissus/Art/Minimap/LOGO-";
	local tex;

	local customStyleID = NarcissusDB.MinimapIconStyle;
	if not customStyleID then
		if IsAddOnLoaded("AzeriteUI") then
			customStyleID = 2;
		elseif IsAddOnLoaded("SexyMap") then
			customStyleID = 3;
		elseif IS_DRAGONFLIGHT then
			customStyleID = 4;
		else
			customStyleID = 1;
		end
		--NarcissusDB.MinimapIconStyle = customStyleID;
	end

	if customStyleID == 2 then
		tex = prefix.."Thick";		--AzeriteUI
	elseif customStyleID == 3 then
		tex = prefix.."Hollow";		--SexyMap
	elseif customStyleID == 4 then
		tex = prefix.."Dragonflight";
	else
		useCovenantColor = true;
	end

	if useCovenantColor then
		local id = index or C_Covenants.GetActiveCovenantID();
		if id == 2 then
			tex = prefix.."Brown";		--Venthyr
		elseif id == 4 then
			tex = prefix.."Green";		--Necrolord
		else
			tex = prefix.."Cyan";
		end
	end

	self.Background:SetTexture(tex);
	self.Color:SetTexture(tex);

	local pixelSize = NarciAPI.GetTexturePixelSize(self.Background);
	if pixelSize < 64 then
		--use low-rez texture for better smoothness
		self.Background:SetTexCoord(0, 0.25, 0.75, 1);
		self.Color:SetTexCoord(0.25, 0.5, 0.75, 1);
	else
		self.Background:SetTexCoord(0, 0.5, 0, 0.5);
		self.Color:SetTexCoord(0.5, 1, 0, 0.5);
	end
end

function NarciMinimapButtonMixin:SetIconScale(scale)
	self.Background:SetScale(scale);
end

function NarciMinimapButtonMixin:OnEnter()
	if IsMouseButtonDown() then return; end;
	self:ShowMouseMotionVisual(true);
	if (not IsShiftKeyDown()) then
		if self.showPanelOnMouseOver then
			self.onEnterDelay:Show();
		elseif not self.Panel:IsShown() then
			local tooltip = GameTooltip;
			tooltip:SetOwner(self, "ANCHOR_NONE");
			tooltip:SetPoint("TOPRIGHT", self, "BOTTOM", 0, 0);
			tooltip:SetText(NARCI_GRADIENT);
			
			--Normal Tooltip
			local HotKey1, HotKey2 = GetBindingKey("TOGGLECHARACTER0");
			local KeyText;
			local LeftClickText = L["Minimap Tooltip Left Click"];
			if HotKey1 and NarcissusDB.EnableDoubleTap then
				KeyText = "("..HotKey1..")";
				if HotKey2 then
					KeyText = KeyText .. "|cffffffff or |r("..HotKey2..")";
				end
				LeftClickText = LeftClickText.." |cffffffff".."/".." |r"..L["Minimap Tooltip Double Click"].." "..KeyText.."|r";
			end
		
			local bindAction = "CLICK MiniButton:LeftButton";
			local keyBind = GetBindingKey(bindAction);
			if keyBind and keyBind ~= "" then
				LeftClickText = LeftClickText.." |cffffffff".."/|r "..keyBind;
			end
		
			tooltip:AddLine(LeftClickText.." "..L["Minimap Tooltip To Open"], nil, nil, nil, false);
			tooltip:AddLine(L["Minimap Tooltip Right Click"].." "..L["Minimap Tooltip Module Panel"], nil, nil, nil, false);
			tooltip:AddLine(L["Minimap Tooltip Shift Left Click"].." "..L["Toggle Dressing Room"], nil, nil, nil, true);
			tooltip:AddLine(L["Minimap Tooltip Shift Right Click"].." "..L["Minimap Tooltip Hide Button"], nil, nil, nil, true);
			tooltip:AddLine(L["Minimap Tooltip Middle Button"], nil, nil, nil, true);
			tooltip:AddLine(" ", nil, nil, nil, true);
			tooltip:AddDoubleLine(NarciAPI.GetAddOnVersionInfo(true), L["Developer Info"], 0.8, 0.8, 0.8, 0.8, 0.8, 0.8);
			tooltip:AddLine("https://wow.curseforge.com/projects/narcissus", 0.5, 0.5, 0.5, false);

			tooltip:Show();
		end
	end
end

function NarciMinimapButtonMixin:ShowMouseMotionVisual(visible)
	if not self:IsShown() then return end;
	if visible then
		SetCursor("Interface/CURSOR/Item.blp");
		self.Color:Show();
		self:SetIconScale(1.1);
		FadeFrame(self.Color, 0.2, 1);
		FadeFrame(self, 0.2, 1);
	else
		ResetCursor();
		FadeFrame(self.Color, 0.2, 0);
		FadeFrame(self, 0.2, self.endAlpha);
		self:SetIconScale(1);
	end
end

function NarciMinimapButtonMixin:PlayBling()
	self.Bling:Show();
	self.Bling.animScale:Play();
end

function NarciMinimapButtonMixin:OnLeave()
	GameTooltip:Hide();
	if self.PositionUpdator:IsShown() then
		return;
	end
	if not self:IsFocused() then
		self:ShowPopup(false);
	else
		self.Color:SetAlpha(0);
	end
end

function NarciMinimapButtonMixin:OnHide()
	self:ShowPopup(false);
	self.Panel.ClipFrame:Hide();
	self:UnregisterEvent("MODIFIER_STATE_CHANGED");
end

function NarciMinimapButtonMixin:ShowPopup(visible)
	if visible then
		self.Panel:Show();
		self:RegisterEvent("GLOBAL_MOUSE_DOWN");
	else
		FadeFrame(self.Panel, 0.15, 0);
		self:ShowMouseMotionVisual(false);
		self.onEnterDelay:Hide();
		self.panelEntrance:Hide();
		self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
	end
end

function NarciMinimapButtonMixin:OnEvent(event)
	if event == "GLOBAL_MOUSE_DOWN" then
		if not self:IsInBound() then
			self:ShowPopup(false);
		end
	elseif event == "MODIFIER_STATE_CHANGED" then
		if self:IsDragging() then
			self:StartRepositioning();
		end
	elseif event == "UI_SCALE_CHANGED" then
		self:SetBackground();
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        self:Init();
	end
end

function NarciMinimapButtonMixin:SetIndependent(state)
	if state == nil then
		state = NarcissusDB.IndependentMinimapButton;
	end

    if state then
        self:SetParent(Narci_MinimapButtonContainer);
    else
        self:SetParent(Minimap);
    end

	self:UpdatePosition();
	self:SetFrameStrata("MEDIUM");
	self:SetFrameLevel(62);
end

function NarciMinimapButtonMixin:Init()
    local iconSize = 42;
    local cornerRadius = 10;

    --Optimize this minimap button's radial offset

    if IsAddOnLoaded("AzeriteUI") then
        cornerRadius = 18;
        iconSize = 48;
    elseif IsAddOnLoaded("DiabolicUI") then
        cornerRadius = 12;
    elseif IsAddOnLoaded("GoldieSix") then
        --GoldpawUI
        cornerRadius = 18;
    elseif IsAddOnLoaded("GW2_UI") then
        cornerRadius = 44;
    elseif IsAddOnLoaded("SpartanUI") then
        cornerRadius = 8;
    else
        cornerRadius = 10;
    end
    self.Background:SetSize(iconSize, iconSize);
    MapShapeUtil.cornerRadius =cornerRadius;

    self:UpdatePosition();
    self:SetBackground();
    self:SetIndependent();
    self:RegisterEvent("UI_SCALE_CHANGED");

    self.Init = nil;
end

function NarciMinimapButtonMixin:GetMenuInfo()
	return self.menuInfo
end


do
    local SettingFunctions = addon.SettingFunctions;

	function SettingFunctions.ShowMinimapButton(state, db)
		if state == nil then
			state = db["ShowMinimapButton"];
		end
		MiniButton:SetShown(state);
	end

	function SettingFunctions.ShowMinimapModulePanel(state, db)
		if state == nil then
			state = db["ShowModulePanelOnMouseOver"];
		end
		MiniButton.showPanelOnMouseOver = state;
	end

	function SettingFunctions.FadeOutMinimapButton(state, db)
		if state == nil then
			state = db["FadeButton"];
		end
		local alpha = (state and 0.25) or 1;
		MiniButton.endAlpha = alpha;
		MiniButton:SetAlpha(alpha);
	end
end