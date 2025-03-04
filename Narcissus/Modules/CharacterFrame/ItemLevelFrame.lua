local _, addon = ...

local FadeFrame = NarciFadeUI.Fade;
local GetNumClassSetItems = NarciAPI.GetNumClassSetItems;
local floor = math.floor;
local After = C_Timer.After;
local outSine = addon.EasingFunctions.outSine;

local MAJORFACTION_EXPANSION = 9;


local function RoundLevel(lvl)
	return floor(lvl * 100 + 0.5)/100
end


local function ClassSet_OnEnter(self)
	local p = self:GetParent();
	local nodes = p.ClassSetOverlay.Nodes;
	for _, node in pairs(nodes) do
		node.HighlightTexture.FadeIn:Play();
	end

	local f = NarciClassSetTooltip;
	f:ClearAllPoints();
	f:SetParent(p.ClassSetOverlay);
	f:SetPoint("TOP", p, "BOTTOM", 0, -8);
	f:SetFrameStrata("TOOLTIP");
	f:FadeIn(true);
end

local function ClassSet_OnLeave(self)
	local nodes = self:GetParent().ClassSetOverlay.Nodes;
	if nodes then
		for _, node in pairs(nodes) do
			node.HighlightTexture.FadeOut:Play();
		end
		NarciClassSetTooltip:FadeOut();
	end
end

local function GenericItemLevel_OnEnter(self)
	Narci_ShowButtonTooltip(self);
end

local function Domination_OnEnter(self)
	NarciAPI_RunDelayedFunction(self, 0.2, function()
		local f = NarciGameTooltip;
		self:GetParent().DominationOverlay:ShowTooltip(f, "TOP", self, "BOTTOM", 0, -12);
		f:SetAlpha(0);
		FadeFrame(f, 0.2, 1);
	end);
end


local Themes = {
    grey = {
        fluidColor = {0.9, 0.9, 0.9},
        showLevel = true,
		frameTex = "HexagonTube",
        backgroundTex = "QualityGrey",
        highlightTex = "GenericHighlight",
        highlightSize = 100,
        highlightBlend = "ADD",
    },

    kyrian = {
        fluidColor = {0.76, 0.89, 0.94},
        showLevel = true,
		frameTex = "HexagonTube",
        backgroundTex = "CovenantKyrian",
        highlightTex = "GenericHighlight",
        highlightSize = 100,
        highlightBlend = "ADD",
    },

    venthyr = {
        fluidColor = {0.55, 0, 0.19},
        showLevel = true,
		frameTex = "HexagonTube",
        backgroundTex = "CovenantVenthyr",
        highlightTex = "GenericHighlight",
        highlightSize = 100,
        highlightBlend = "ADD",
    },

    fae = {
        fluidColor = {0.11, 0.42, 0.80},
        showLevel = true,
		frameTex = "HexagonTube",
        backgroundTex = "CovenantNightFae",
        highlightTex = "GenericHighlight",
        highlightSize = 100,
        highlightBlend = "ADD",
    },

    necrolord = {
        fluidColor = {0, 0.63, 0.43},
        showLevel = true,
		frameTex = "HexagonTube",
        backgroundTex = "CovenantNecrolord",
        highlightTex = "GenericHighlight",
        highlightSize = 100,
        highlightBlend = "ADD",
    },

    domination = {
        frameTex = "Domination",
        highlightTex = "DominationHighlight",
        highlightSize = 128,
        highlightBlend = "ADD",
		onEnterFunc = Domination_OnEnter,
    },


    classSet_Progenitor = {
        frameTex = "Progenitor\\ItemLevelHex",
        highlightTex = "Progenitor\\ItemLevelHexHighlight",
		nodeTex = "Progenitor\\SetPieceCount",
		nodeHighlightTex = "Progenitor\\SetPieceCountHighlight",
        highlightSize = 104,
        highlightBlend = "ADD",
        highlightLevel = 4,
		onEnterFunc = ClassSet_OnEnter,
		onLeaveFunc = ClassSet_OnLeave,
    },

    classSet_Neltharion = {
        frameTex = "Neltharion\\ItemLevelHex",
        highlightTex = "Neltharion\\ItemLevelHexHighlight",
		nodeTex = "Neltharion\\SetPieceCount",
		nodeHighlightTex = "Neltharion\\SetPieceCountHighlight",
        highlightSize = 104,
        highlightBlend = "ADD",
        highlightLevel = 4,
		onEnterFunc = ClassSet_OnEnter,
		onLeaveFunc = ClassSet_OnLeave,
    },

	classSet_EmeraldDream = {
		frameTex = "EmeraldDream\\ItemLevelHex",
		--highlightTex = "EmeraldDream\\ItemLevelHexHighlight",
		nodeTex = "EmeraldDream\\SetPieceCount",
		nodeHighlightTex = "EmeraldDream\\SetPieceCountHighlight",
		highlightSize = 104,
		highlightBlend = "ADD",
		highlightLevel = 4,
		onEnterFunc = ClassSet_OnEnter,
		onLeaveFunc = ClassSet_OnLeave,
	};
};


do
	Themes.classSet = Themes.classSet_Neltharion;	--TWW S2 Undermine
end


NarciItemLevelFrameMixin = {};

function NarciItemLevelFrameMixin:UpdateItemLevel(playerLevel)
	--playerLevel = playerLevel or UnitLevel("player");
	local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel();
	local avgItemLevelBase = floor(avgItemLevel);
	avgItemLevel = RoundLevel(avgItemLevel);
	avgItemLevelEquipped = RoundLevel(avgItemLevelEquipped);
	avgItemLevelPvp = RoundLevel(avgItemLevelPvp);
	self.LeftButton.avgItemLevel = avgItemLevel;
	self.LeftButton.avgItemLevelPvp = avgItemLevelPvp;
	self.LeftButton.isSameLevel = (avgItemLevel == avgItemLevelEquipped);
	self.LeftButton.Level:SetText(avgItemLevelEquipped);
	
	local percentage = avgItemLevel - avgItemLevelBase;

	local height;		--Set the bar(Fluid) height in the Tube
	if percentage < 0.10 then
		height = 0.1;
	elseif percentage > 0.90 then
		height = 84;
	else
		height = 84 * percentage;
	end
	self.CenterButton.Fluid:SetHeight(height);
	self.CenterButton.Level:SetText(avgItemLevelBase);
	self.CenterButton.tooltipHeadline = STAT_AVERAGE_ITEM_LEVEL .." "..avgItemLevel;
end

function NarciItemLevelFrameMixin:UpdateCovenantRenownLevel(newLevel)
	local renownLevel = newLevel or C_CovenantSanctumUI.GetRenownLevel() or 0;
	local headerText = string.format(COVENANT_SANCTUM_LEVEL, renownLevel);
	if C_CovenantSanctumUI.HasMaximumRenown() then
		headerText = headerText.. "  (maxed)";
	end
	local frame = self.RightButton;
	frame.Header:SetText("RN");
	frame.tooltipHeadline = headerText;
	frame.Number:SetText(renownLevel);
	frame.tooltipLine1 = COVENANT_RENOWN_TUTORIAL_PROGRESS;
end

function NarciItemLevelFrameMixin:UpdateRenownLevel()
	if not self.majorFactionIDs then
		local bestExpansionID;
		local playerLevel = UnitLevel("player");

		if playerLevel and playerLevel > 70 then
			bestExpansionID = 10;
			self.majorFactionLandingPageTitle = WAR_WITHIN_LANDING_PAGE_TITLE;
		else
			bestExpansionID = 9;
			self.majorFactionLandingPageTitle = DRAGONFLIGHT_LANDING_PAGE_TITLE;
		end

		local tbl = {};
		local factionIDs = C_MajorFactions.GetMajorFactionIDs(bestExpansionID);

		for _, majorFactionID in ipairs(factionIDs) do
			local data = C_MajorFactions.GetMajorFactionData(majorFactionID);
			if data then
				table.insert(tbl, majorFactionID);
			end
		end

		self.majorFactionIDs = tbl;
	end

	local level, primaryFactionID;
	local maxLevel = 0;

	for _, majorFactionID in ipairs(self.majorFactionIDs) do
		level = C_MajorFactions.GetCurrentRenownLevel(majorFactionID);
		if level > maxLevel then
			primaryFactionID = majorFactionID;
			maxLevel = level;
		end
	end

	local frame = self.RightButton;
	frame.Header:SetText("RN");
	frame.Number:SetText(maxLevel);
end

function NarciItemLevelFrameMixin:SetThemeByName(themeName)
	if themeName ~= self.theme then
		local asset = Themes[themeName];
		local prefix = "Interface\\AddOns\\Narcissus\\Art\\Widgets\\ItemLevel\\";

		local file = prefix.. asset.frameTex;
		self.CenterButton.FluidBackground:SetTexture(file);
		self.CenterButton.TubeBorder:SetTexture(file);
		self.LeftButton.Background:SetTexture(file);
		self.LeftButton.Highlight:SetTexture(file);
		self.RightButton.Background:SetTexture(file);
		self.RightButton.Highlight:SetTexture(file);

		self.CenterButton:ShowMaxLevel(asset.showLevel);

		if asset.highlightTex then
			file = prefix.. asset.highlightTex;
			self.CenterButton.Highlight:SetTexture(file, nil, nil, "TRILINEAR");
			self.CenterButton.Highlight:SetSize(asset.highlightSize, asset.highlightSize);
			self.CenterButton.Highlight:SetDrawLayer("OVERLAY", asset.highlightLevel or 1);
			self.CenterButton.Highlight:SetBlendMode(asset.highlightBlend or "ADD");
		end

		if asset.backgroundTex then
			self.CenterButton.Background:SetTexture(prefix.. asset.backgroundTex);
			self.CenterButton.Background:SetTexCoord(0, 1, 0, 1);
		else
			self.CenterButton.Background:SetTexture(nil);
		end

		if asset.fluidColor then
			self.CenterButton.Fluid:SetColorTexture(unpack(asset.fluidColor));
		end

		self.theme = themeName;

		self.CenterButton.onEnterFunc = asset.onEnterFunc or GenericItemLevel_OnEnter;
		self.CenterButton.onLeaveFunc = asset.onLeaveFunc;
		self.ClassSetOverlay:SetShown(themeName == "classSet");

		if self.ClassSetOverlay and self.ClassSetOverlay.Nodes then
			local nodeTex, highlightTex;

			if asset.nodeTex then
				nodeTex = prefix.. asset.nodeTex;
			end

			if asset.nodeHighlightTex then
				highlightTex = prefix.. asset.nodeHighlightTex;
			end

			for i, node in ipairs(self.ClassSetOverlay.Nodes) do
				node.NormalTexture:SetTexture(nodeTex);
				node.HighlightTexture:SetTexture(highlightTex);
			end
		end
	end
end

function NarciItemLevelFrameMixin:UpdateDomination()
	if not self.checkDomination then return end;
	if not self.pauseUpdate then
		self.pauseUpdate = true;
		After(0, function()
			local isDomination = self.DominationOverlay:Update();
			if isDomination then
				self:SetThemeByName("domination");
			end
			self.pauseUpdate = nil;
		end)
	end
end

function NarciItemLevelFrameMixin:UpdateClassSet(numSetItems)
	local node;
	local f = self.ClassSetOverlay;
	if not f.Nodes then
		f.Nodes = {};
		local _, _, classID = UnitClass("player");
		f.ClassIcon = f:CreateTexture(nil, "OVERLAY", nil, 4);
		f.ClassIcon:SetSize(24, 24);
		f.ClassIcon:SetPoint("CENTER", f, "CENTER", 0, 0);
		f.ClassIcon:SetTexture( "Interface\\AddOns\\Narcissus\\Art\\Widgets\\Progenitor\\ClassIcon".. (classID or 1) );
	end
	f.ClassIcon:SetShown(numSetItems >= 2);

	for i = 1, 4 do
		node = f.Nodes[i];
		if not node then
			node = CreateFrame("Frame", nil, f, "NarciClassSetIndicatorNodeTemplate");
			if i == 1 then
				node:SetPoint("TOPRIGHT", f, "CENTER", 0, 0);
				node.NormalTexture:SetTexCoord(0, 0.25, 0.25, 0.5);
				node.HighlightTexture:SetTexCoord(0, 0.5, 0.5, 1);
			elseif i == 2 then
				node:SetPoint("BOTTOMRIGHT", f, "CENTER", 0, 0);
				node.NormalTexture:SetTexCoord(0, 0.25, 0, 0.25);
				node.HighlightTexture:SetTexCoord(0, 0.5, 0, 0.5);
			elseif i == 3 then
				node:SetPoint("BOTTOMLEFT", f, "CENTER", 0, 0);
				node.NormalTexture:SetTexCoord(0.25, 0.5, 0, 0.25);
				node.HighlightTexture:SetTexCoord(0.5, 1, 0, 0.5);
			else
				node:SetPoint("TOPLEFT", f, "CENTER", 0, 0);
				node.NormalTexture:SetTexCoord(0.25, 0.5, 0.25, 0.5);
				node.HighlightTexture:SetTexCoord(0.5, 1, 0.5, 1);
			end
		end
		if i <= numSetItems then
			if not node:IsShown() then
				node:StopAnimating();
                node.HighlightTexture.Shine:Play();
				node:Show();
			end
		else
			node:Hide();
		end
	end
	f.numSetItems = numSetItems;
end

local function AsyncUpdate_OnUpdate(self, elapsed)
	self.delay = self.delay + elapsed;
	if self.delay >= 0 then
		self:SetScript("OnUpdate", nil);
		self:InstantUpdate();
		self.delay = nil;
	end
end

function NarciItemLevelFrameMixin:AsyncUpdate(delay)
	if not self.delay then
		self.delay = (delay and -delay) or 0;
		self:SetScript("OnUpdate", AsyncUpdate_OnUpdate);
	end
end

function NarciItemLevelFrameMixin:InstantUpdate()
	local themeName;
	local numSetItems = GetNumClassSetItems(true);
	if numSetItems > 0 then
		themeName = "classSet";
		self:UpdateClassSet(numSetItems);	--numSetItems
	else
		local covenantID = C_Covenants.GetActiveCovenantID();
		if covenantID and covenantID ~= 0 then
			if covenantID == 1 then
				themeName = "kyrian";
			elseif covenantID == 2 then
				themeName = "venthyr";
			elseif covenantID == 3 then
				themeName = "fae";
			elseif covenantID == 4 then
				themeName = "necrolord";
			end
		else
			themeName = "grey";
		end
	end
	self:SetThemeByName(themeName);
	self:UpdateItemLevel();
	self:UpdateRenownLevel();
end

function NarciItemLevelFrameMixin:ToggleExtraInfo(state, replayAnimation)
	if not self.animFrame then
		self.animFrame = CreateFrame("Frame");
		self.animFrame:Hide();
		self.animFrame:SetScript("OnUpdate", function(f, elapsed)
			f.t = f.t + elapsed;
			local offsetX = outSine(f.t, f.fromX, f.toX, 0.4);
			if f.t >= 0.4 then
				offsetX = f.toX;
				f:Hide();
				if f.hideButton then
					self.LeftButton:Hide();
					self.RightButton:Hide();
				end
			end
			self.LeftButton:SetPoint("RIGHT", self, "CENTER", -offsetX, 0);
			self.RightButton:SetPoint("LEFT", self, "CENTER", offsetX, 0);
		end);
	end
	self.animFrame:Hide();
	self.animFrame.t = 0;
	local _, _, _, fromX = self.RightButton:GetPoint();
	self.animFrame.fromX = fromX;
	if state then
		self.animFrame.toX = 28;
		self.LeftButton:Show();
		self.RightButton:Show();
		self.animFrame.hideButton = false;
	else
		self.animFrame.toX = -32;
		self.animFrame.hideButton = true;
	end
	if fromX ~= self.animFrame.toX or replayAnimation then
		self.animFrame:Show();
	end
end

function NarciItemLevelFrameMixin:Init()
	local function SideButton_OnEnter(f)
		if f.onEnterFunc then
			f.onEnterFunc(f);
			FadeFrame(f.Highlight, 0.15, 1);
		end
	end

	local function SideButton_OnLeave(f)
		Narci:HideButtonTooltip();
		FadeFrame(f.Highlight, 0.25, 0);
	end

	local function SideButton_ShowDetailedItemLevel(f)
		if f.isSameLevel then
			f.tooltipHeadline = string.format(f.tooltipFormat, f.Level:GetText());
		else
			f.tooltipHeadline = string.format(f.tooltipFormat, f.Level:GetText()) .. string.format("  (max %s)", f.avgItemLevel);
		end
		if f.avgItemLevelPvp and f.avgItemLevelPvp ~= 0 then
			f.tooltipSpecial = string.format(STAT_AVERAGE_PVP_ITEM_LEVEL, f.avgItemLevelPvp);
		else
			f.tooltipSpecial = nil;
		end
		Narci_ShowButtonTooltip(f);
	end

	local function SideButton_ShowMajorFactionInfo(f)
		local DefaultTooltip = NarciGameTooltip;
		DefaultTooltip:HideTooltip();

		if not self.majorFactionIDs then
			self:UpdateRenownLevel();
		end

		DefaultTooltip:SetOwner(f, "ANCHOR_NONE");
		DefaultTooltip:SetPoint("BOTTOM", f, "TOP", 0, 2);
		DefaultTooltip:SetText(self.majorFactionLandingPageTitle);

		local factionIDs = self.majorFactionIDs;
		local factionList = {};

		if factionIDs and #factionIDs > 0 then
			local factionData;
			for _, majorFactionID in ipairs(factionIDs) do
				factionData = C_MajorFactions.GetMajorFactionData(majorFactionID);
				if factionData then
					table.insert(factionList, factionData);
				end
			end

			local function UnlockOrderSort(faction1, faction2)
				if faction1.uiPriority then
					return faction1.uiPriority < faction2.uiPriority;
				else
					return faction1.unlockOrder < faction2.unlockOrder;
				end
			end

			table.sort(factionList, UnlockOrderSort);

			--Embedded Frame
			if not f.FactionListFrame then
				f.FactionListFrame = CreateFrame("Frame", nil, f);
				f.factionButtons = {};
				f.FactionListFrame:SetWidth(154);
			end

			for i = 1, #f.factionButtons do
				f.factionButtons[i]:Hide();
			end

			local maxTextWidth = 0;
			local description, level, textWidth;
			for i, data in ipairs(factionList) do
				if not f.factionButtons[i] then
					f.factionButtons[i] = CreateFrame("Frame", nil, f.FactionListFrame, "NarciGameTooltipEmbeddedIconTextFrame");
					if i == 1 then
						f.factionButtons[i]:SetPoint("TOPLEFT", f.FactionListFrame, "TOPLEFT", 0, 0);
					else
						f.factionButtons[i]:SetPoint("TOPLEFT", f.factionButtons[i - 1], "BOTTOMLEFT", 0, -6);
					end
				end
				level = data.renownLevel or 0;
				if level < 10 then
					level = level.."  ";
				end
				if not data.isUnlocked then
					description = MAJOR_FACTION_BUTTON_FACTION_LOCKED;
				elseif C_MajorFactions.HasMaximumRenown(data.factionID) then
					if C_Reputation.IsFactionParagon(data.factionID) then
						local totalEarned, threshold = C_Reputation.GetFactionParagonInfo(data.factionID);
						if totalEarned and threshold and threshold ~= 0 then
							local paragonLevel = floor(totalEarned / threshold);
							local currentValue = totalEarned - paragonLevel * threshold;
							description = string.format("|cff00ccffP%s|r  %d/%d", paragonLevel, currentValue, threshold);
						else
							description = MAJOR_FACTION_MAX_RENOWN_REACHED;
						end
					else
						description = MAJOR_FACTION_MAX_RENOWN_REACHED;
					end
				else
					description = string.format("|cffffd100%s|r  %d/%d", level, data.renownReputationEarned, data.renownLevelThreshold);
				end
				f.factionButtons[i].Icon:SetAtlas(string.format("majorFactions_icons_%s512", data.textureKit), false);
				f.factionButtons[i].Text:SetText(string.format("|cffffffff%s|r\n%s", data.name, description));
				f.factionButtons[i].Text:SetTextColor(0.5, 0.5, 0.5);
				f.factionButtons[i]:Show();

				textWidth = f.factionButtons[i].Text:GetWrappedWidth();
				if textWidth and textWidth > maxTextWidth then
					maxTextWidth = textWidth;
				end
			end
			local numButtons = #factionList;
			f.FactionListFrame:SetHeight((28 + 6)*numButtons - 12);
			f.FactionListFrame:SetWidth(floor(maxTextWidth + 0.5) + 28 + 6);

			local function GameTooltip_InsertFrame(tooltipFrame, frame, verticalPadding)	-- this is an exact copy of GameTooltip_InsertFrame to avoid "Execution tainted"
				verticalPadding = verticalPadding or 0;
				local textSpacing = tooltipFrame:GetCustomLineSpacing() or 2;
				local textHeight = Round(_G[tooltipFrame:GetName().."TextLeft2"]:GetLineHeight());
				local neededHeight = Round(frame:GetHeight() + verticalPadding);
				local numLinesNeeded = math.ceil(neededHeight / (textHeight + textSpacing));
				local currentLine = tooltipFrame:NumLines();

				if numLinesNeeded ~= nil then
					for i = 1, numLinesNeeded do
						tooltipFrame:AddLine(" ");
					end
				end

				frame:SetParent(tooltipFrame);
				frame:ClearAllPoints();
				frame:SetPoint("TOPLEFT", tooltipFrame:GetName().."TextLeft"..(currentLine + 1), "TOPLEFT", 0, -verticalPadding);
				if not tooltipFrame.insertedFrames then
					tooltipFrame.insertedFrames = { };
				end
				local frameWidth = frame:GetWidth();
				if tooltipFrame:GetMinimumWidth() < frameWidth then
					tooltipFrame:SetMinimumWidth(frameWidth);
				end
				frame:Show();
				table.insert(tooltipFrame.insertedFrames, frame);
				return (numLinesNeeded * textHeight) + (numLinesNeeded - 1) * textSpacing;
			end

			GameTooltip_InsertFrame(DefaultTooltip, f.FactionListFrame, 6);
		else
			DefaultTooltip:AddLine(MAJOR_FACTION_BUTTON_FACTION_LOCKED, 0.5, 0.5, 0.5, true);
		end
		DefaultTooltip:Show();
		DefaultTooltip:FadeIn();
	end

	local LeftButton = self.LeftButton;
	LeftButton:SetScript("OnEnter", SideButton_OnEnter);
	LeftButton:SetScript("OnLeave", SideButton_OnLeave);
	LeftButton.onEnterFunc = SideButton_ShowDetailedItemLevel;
	LeftButton.tooltipFormat = Narci.L["Equipped Item Level Format"];
	LeftButton.tooltipLine1 = STAT_AVERAGE_ITEM_LEVEL_TOOLTIP;

	local RightButton = self.RightButton;
	RightButton:SetScript("OnEnter", SideButton_OnEnter);
	RightButton:SetScript("OnLeave", SideButton_OnLeave);
	RightButton.onEnterFunc = SideButton_ShowMajorFactionInfo;
end



NarciItemLevelCenterButtonMixin = {};

function NarciItemLevelCenterButtonMixin:OnLoad()
	self.tooltipLine1 = HIGHLIGHT_FONT_COLOR_CODE .. STAT_AVERAGE_ITEM_LEVEL_TOOLTIP .. FONT_COLOR_CODE_CLOSE;
	--self.tooltip3 = L["Toggle Equipment Set Manager"];

	self:SetScript("OnLoad", nil);
	self.OnLoad = nil;
end

local function OnEnterDelay_OnUpdate(self, elapsed)
	self.delay = self.delay + elapsed;
	if self.delay > 0 then
		if self.onEnterFunc then
			self.onEnterFunc(self);
		end
		self:StopDelay();
	end
end

function NarciItemLevelCenterButtonMixin:OnEnter()
	FadeFrame(self.Highlight, 0.2, 1);

	if self.onEnterFunc then
		self.delay = -0.15;
		self:SetScript("OnUpdate", OnEnterDelay_OnUpdate);
	else
		self:StopDelay();
	end
end

function NarciItemLevelCenterButtonMixin:OnMouseDown()
	self.Background:SetPoint("CENTER", 0, -4);
end

function NarciItemLevelCenterButtonMixin:OnMouseUp()
	self.Background:SetPoint("CENTER", 0, 0);
end

function NarciItemLevelCenterButtonMixin:OnLeave()
	FadeFrame(self.Highlight, 0.2, 0);
	Narci:HideButtonTooltip();
	if self.onLeaveFunc then
		self.onLeaveFunc(self);
	end
	self:StopDelay();
end

function NarciItemLevelCenterButtonMixin:OnClick()

end

function NarciItemLevelCenterButtonMixin:OnHide()
	if self.onHideFunc then
		self.onHideFunc(self);
	end
	self:StopDelay();
end

function NarciItemLevelCenterButtonMixin:ShowItemLevel()
	self:GetParent():Update();
end

function NarciItemLevelCenterButtonMixin:ShowMaxLevel(state)
	self.Header:SetShown(state);
	self.Level:SetShown(state);
	self.Surface:SetShown(state);
	self.Fluid:SetShown(state);
	self.Background:SetShown(state);
end

function NarciItemLevelCenterButtonMixin:StopDelay()
	if self.delay then
		self:SetScript("OnUpdate", nil);
		self.delay = nil;
	end
end

function NarciItemLevelCenterButtonMixin:OnMouseWheel(delta)
	if NarciClassSetTooltip:IsVisible() then
		if delta > 0 then
			NarciClassSetTooltip:CycleSpec(-1, true);
		else
			NarciClassSetTooltip:CycleSpec(1, true);
		end
	end
end