local _, addon = ...

local SetModelLight = addon.TransitionAPI.SetModelLight;


local DataAPI;
local GetItemName, GetSourceID, IsItemValidForTryOn;

local MainFrame, HomePage, FavButton;

local PI =  3.1416  --math.pi;
local floor = math.floor;
local tinsert = table.insert;
local tremove = table.remove;
local type = type;
local After = C_Timer.After;
local FadeFrame = NarciFadeUI.Fade;
local L = Narci.L;

local GetItemInfoInstant = C_Item.GetItemInfoInstant;

local TRY_ON_CHECK = false;
--[[
    Weapon Cam:
    /script local m=NarciPlayerModelFrame1;m:SetPosition(0, 0, 0);m:SetCameraPosition(14, 0, 0);m:SetCameraTarget(0, 0, 0);m:SetFacing(PI/2);m:SetLight(true, false, -0.72, 0, -0.68, 1, 0.8, 0.8, 0.8, 1, 0.8, 0.8, 0.8)

    MountJournalIcon
    MountJournalName
    MountJournalSource
    MountJournalLore
--]]

local outQuart = addon.EasingFunctions.outQuart;
local outQuint = addon.EasingFunctions.outQuint;
local inQuad = addon.EasingFunctions.inQuad;

local DataProvider = {};
local FavUtil = {};

local function GetSubclassID(itemID)
    local _, _, _, _, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemID);
    if itemClassID == 4 and itemSubClassID == 6 then --shield
        itemSubClassID = 69;
    elseif itemClassID ~= 2 then    --weapon
        itemSubClassID = 1208;     --Unknown    class 4 subclass 0 LE_ITEM_ARMOR_GENERIC
    end

    if itemClassID == 2 and itemSubClassID == 17 then
        itemSubClassID = 6;    --Redirect Spears to Polearm
    end
    return itemSubClassID
end


local ModelZoom = {};

function ModelZoom:Init()
    self.executeFrame = CreateFrame("Frame");
    self.widgets = {};
    self.zoomInfo = {};
    local transition = 0.6;

    local niche, info, offsetX, offsetZ, t;
    self.OnUpdate = function(frame, elapsed)
        local i = 1;
        local isComplete = true;
        while self.widgets[i] do
            niche = self.widgets[i];
            info = self.zoomInfo[niche];
            if info then
                t = info.t + elapsed;
                if t >= transition then
                    offsetX = info.wX;
                    offsetZ = info.sZ;
                    self.zoomInfo[niche] = nil;
                else
                    offsetX = outQuint(info.t, info.wB, info.wX, transition);
                    offsetZ = outQuint(info.t, info.sB, info.sZ, transition);
                    info.t = t;
                    isComplete = false;
                end
                niche.Model:SetPosition(offsetX, 0, 0);
                niche.ModelShadow:SetPosition(-offsetX, 0, offsetZ);
            end
            i = i + 1;
        end

        if isComplete then
            self:Clear();
        end
    end
end

function ModelZoom:Add(weaponNiche, weaponX, shadowZ)
    local _, _, fromZ = weaponNiche.ModelShadow:GetPosition();
    self.zoomInfo[weaponNiche] = {
        wB = weaponNiche.Model:GetPosition();
        wX = weaponX,
        sB = fromZ,
        sZ = shadowZ,
        t = 0,
    };

    for i = 1, #self.widgets do
        if self.widgets[i] == weaponNiche then
            return
        end
    end

    tinsert(self.widgets, weaponNiche);
    self.executeFrame:SetScript("OnUpdate", self.OnUpdate);
end

function ModelZoom:Clear()
    self.executeFrame:SetScript("OnUpdate", nil);
    self.widgets = {};
    self.zoomInfo = {};
end

-----------------------------------------------------------------------------
local TabUtil = {};

function TabUtil:SelectDefaultTab()
    self.activeTab = 1;
    for i = 1, #self.tabButtons do
        self.tabButtons[i]:UpdateVisual();
    end

    self.SelectDefaultTab = nil;
end

function TabUtil:UpdateCategories(dataSource, countSource)
    local container = HomePage.Container;
    --Sort by Name
    local categoryOrder = {};
    for subclassID, data in pairs(dataSource) do
        tinsert(categoryOrder, subclassID);
    end

    local subclassName = DataProvider.subclassInfo;
    local function SortFunc(a, b)
        if subclassName[a] and subclassName[b] then
            return subclassName[a] < subclassName[b];
        else
            return a > b
        end
    end
    table.sort(categoryOrder, SortFunc);

    --Create Buttons
    local button;
    local numWeapons;
    local subclassID;
    local i = 0;

    if not self.categorybuttons then
        self.categorybuttons = {};
    end
    local buttons = self.categorybuttons;
    local frameLevel = HomePage:GetFrameLevel() + 5;
    for index = 1, #categoryOrder do
        subclassID = categoryOrder[index];
        numWeapons = countSource[subclassID] or 0;
        if numWeapons > 0 then
            i = i + 1;
            if not buttons[i] then
                buttons[i] = CreateFrame("Button", nil, container, "NarciWeaponCategoryTemplate");
            end
            button = buttons[i];
            button:ClearAllPoints();
            if i == 1 then
                button:SetPoint("TOP", container, "TOP", 0, -38);
            else
                button:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, 0);
            end
            button:SetHeight(16.0);
            button:SetCatergory(subclassID, numWeapons);
            button:Show();
            button:SetFrameLevel(frameLevel);
        end
    end

    for index = i + 1, #buttons do
        buttons[index]:Hide();
    end

    HomePage.LoadingNotes:SetShown( i == 0 );
end

function TabUtil:ShowEverything()
    self:UpdateCategories(DataProvider.subclassInfo, DataAPI.GetWeaponCountTable());
end

function TabUtil:ShowFavorites()
    self:UpdateCategories(FavUtil:BuildList());
end
-----------------------------------------------------------------------------
local AlertUtil = {};

function AlertUtil:Init(widget)
    self.widget = widget;
end

function AlertUtil:SetReason(reasonIndex)
    if self.widget then
        if reasonIndex then
            local frame = self.widget;
            if self.Init then
                self.Init = nil;
                NarciAlertFrameMixin:AddShakeAnimation(frame.Reason);
            end

            local reasonText, useShake, colorIndex;
            if reasonIndex == 0 then
                reasonText = (L["Search Result None"]);
                colorIndex = 1;
            elseif reasonIndex == 1 then
                reasonText = ("The selected actor is hidden.");
                useShake = true;
                colorIndex = 2;
            elseif reasonIndex == 2 then
                reasonText = ("Fist weapons are invisible while sheathed.");
                useShake = true;
                colorIndex = 2;
            elseif reasonIndex == 3 then
                reasonText = ("This item is not available to the current model type.");
                useShake = true;
                colorIndex = 3;
            elseif reasonIndex == 4 then
                reasonText = ("This skin is not available to the current model type.");
                useShake = true;
                colorIndex = 3;
            else
                return
            end
            frame.Reason:SetText(reasonText);
            self:UpdateFadeDuration();
            self:SetBackgroundColor(colorIndex);
            self:ShowAlert(useShake);
        end
    end
end

function AlertUtil:ShowShorcutTooltip()
    if self.widget then
        self.widget.Reason:SetText(L["Weapon Browser Specify Hand"]);
        self:UpdateFadeDuration();
        self:SetBackgroundColor(1);
        self:ShowAlert(false);
    end
end

function AlertUtil:UpdateFadeDuration()
    local numLines = self.widget.Reason:GetNumLines();
    self.widget:SetHeight(numLines * 8 + 8);
    self.widget.animFade.Hold:SetStartDelay(2 + numLines * 1);
end

function AlertUtil:SetBackgroundColor(colorIndex)
    if colorIndex == 1 then
        --Black
        self.widget.Color:SetColorTexture(0.05, 0.05, 0.05, 0.9);
    elseif colorIndex == 2 then
        --Yellow
        self.widget.Color:SetColorTexture(1, 0.82, 0, 0.9);
    elseif colorIndex == 3 then
        --Red
        self.widget.Color:SetColorTexture(1, 0.3137, 0.3137, 0.9);
    else
        --Black
        self.widget.Color:SetColorTexture(0.05, 0.05, 0.05, 0.9);
    end
end

function AlertUtil:ShowAlert(useShake)
    self.widget:StopAnimating();
    if useShake then
        self.widget.Reason:SetTextColor(0, 0, 0);
        self.widget.Reason.animError:Play();
    else
        self.widget.Reason:SetTextColor(0.5, 0.5, 0.5);
        self.widget.Color:SetColorTexture(0.05, 0.05, 0.05, 0.9);
    end
    self.widget.animFade:Play();
    self.widget:Show();
end

function AlertUtil:HideAlert()
    self.widget:Hide();
end

function AlertUtil:SetNumMatches(total, overFlow)
    if not total or total == 0 then
        self:SetReason(0);
    else
        if overFlow then
            self.widget.Reason:SetText(string.format(L["Search Result Overflow"], total));
        elseif total > 1 then
            self.widget.Reason:SetText(string.format(L["Search Result Plural"], total));
        else
            self.widget.Reason:SetText(string.format(L["Search Result Singular"], total));
        end

        self:UpdateFadeDuration();
        self:SetBackgroundColor(1);
        self:ShowAlert();
    end
end

-----------------------------------------------------------------------------
local TEMP = {};

TEMP.categoryOrder = {};

TEMP.categoryInfo = {
	[13] = "One-Handed Axes",		--Axe 1H
	[20] = "Two-Handed Axes",		--Axe 2H
	[25] = "Bows",		--Bow
	[26] = "Guns",		--Gun
	[15] = "One-Handed Maces",		--Mace 1H
	[22] = "Two-Handed Maces",		--Mace 2H
	[24] = "Polearms",		--Polearm
	[14] = "One-Handed Swords",		--Sword 1H
	[21] = "Two-Handed Swords",		--Sword 2H
	[28] = "Warglaives",		--Warglaive
	[23] = "Staves",		--Staff
	[17] = "Fist Weapons",		--Fist Weapon
	[0] = MISCELLANEOUS,		--Miscellaneous
	[16] = "Daggers",		--Dagger
	--[16] = INVTYPE_THROWN,		--Thrown
	--[17] = "Spears",		--Spears
	[27] = "Crossbows",		--Crossbow
	[12] = "Wands",		--Wands
	--[20] = "Fishing Poles",		--Fishing Poles
    [18] = "Shields",
    [19] = 'Held In Off-hand',
    [29] = 'Legion Artifacts',
};

function TEMP:CreateWeaponNiche(container)
    local button;
    local buttons = {};
    local numButtons = 6;
    for i = 1, numButtons do
        button = CreateFrame("Button", nil, container, "NarciWeaponNicheTemplate");
        buttons[i] = button;
        button:SetPoint("TOP", container, "TOP", 0, 90*(1 - i) );
    end

    container.buttons = buttons;
end

function TEMP:CreateTabButtons(container)
    local button;
    local numTabs = 2;
    local buttonWidth = floor(container:GetWidth() + 0.5) / numTabs;
    for i = 1, numTabs do
        button = CreateFrame("Button", nil, container, "NarciWeaponTabButtonTemplate");
        button:SetPoint("TOPLEFT", container, "TOPLEFT", buttonWidth*(i - 1), -16);
        button:Init(i);
    end

    TabUtil:SelectDefaultTab();
end

function TEMP:Release()
    TEMP = nil;
end



DataProvider.zoomDistance = {
    --subclassID    redirect Shields to 69
    [0] = 5,    --Axe
    [2] = 5.5,    --Bow
    [4] = 4.5,    --Mace 1H
    [5] = 5.5,    --Mace 2H
    [6] = 6,    --Polearm
    [7] = 4.5,   --1H Sword
    [8] = 5,    --2H Sword
    [9] = 5,    --Glaive
    [10] = 6,   --Staff
    [13] = 5,   --Fist
    [14] = 4,   --Miscellaneous
    [15] = 4,   --Dagger
    [18] = 5.5, --Crossbow
    [19] = 4,   --Wand
    [20] = 6,   --Fishing Poles

    [69] = 5.5,   --Shield
    [1208] = 4,     --Others
};

DataProvider.subclassInfo = {
	[0] = "One-Handed Axes",		--Axe 1H
	[1] = "Two-Handed Axes",		--Axe 2H
	[2] = "Bows",		--Bow
	[3] = "Guns",		--Gun
	[4] = "One-Handed Maces",		--Mace 1H
	[5] = "Two-Handed Maces",		--Mace 2H
	[6] = "Polearms",		--Polearm
	[7] = "One-Handed Swords",		--Sword 1H
	[8] = "Two-Handed Swords",		--Sword 2H
	[9] = "Warglaives",		--Warglaive
	[10] = "Staves",		--Staff
	[13] = "Fist Weapons",		--Fist Weapon
	[14] = MISCELLANEOUS,		--Miscellaneous
	[15] = "Daggers",		--Dagger
	[16] = INVTYPE_THROWN,		--Thrown
	--[17] = "Spears",		--Spears redirected to Polearms
	[18] = "Crossbows",		--Crossbow
	[19] = "Wands",		--Wands
	[20] = "Fishing Poles",		--Fishing Poles
    [69] = "Shields",
    [1208] = _G["INVTYPE_HOLDABLE"],
};

DataProvider.weaponList = {};
--/run Narci_WeaponBrowser:SetScale(1.2)
local UI_SCALE = 1;

function DataProvider:LocalizeSubclassName()
    local GetItemSubClassInfo = C_Item.GetItemSubClassInfo;

    for subclassID, name in pairs(self.subclassInfo) do
        if subclassID == 69 then
            self.subclassInfo[subclassID] = GetItemSubClassInfo(4, 6) or self.subclassInfo[subclassID];
        elseif subclassID ~= 1208 then
            self.subclassInfo[subclassID] = GetItemSubClassInfo(2, subclassID) or self.subclassInfo[subclassID];
        end
    end
end

function DataProvider:GetCameraInfo(subclassID, itemID)
    local fileID = DataAPI.GetItemModelFileID(itemID);
    if self.specialItemZoomDistance[fileID] then
        return UI_SCALE * (self.specialItemZoomDistance[fileID] or 5), self.specialItemCameraOffset[fileID];
    end

    if subclassID then
        return UI_SCALE*(self.zoomDistance[subclassID] or 5), self.specialItemCameraOffset[fileID];
    else
        return UI_SCALE*5, self.specialItemCameraOffset[fileID];
    end
end

function DataProvider:GetWeaponsByIndex(startIndex)
    local weapons = {};
    for i = 1, 6 do
        weapons[i] = self.weaponList[startIndex + i];
    end
    return weapons
end


local ViewUpdator = {};

-----------------------------------------------------------------------------
FavUtil.isFavItems = {};

function FavUtil:IsFavorite(itemID, itemModID)
    if itemModID then
        return self.isFavItems[itemID.." "..itemModID];
    else
        return self.isFavItems[itemID];
    end
end

function FavUtil:Add(itemID, itemModID)
    if itemID then
        if itemModID then
            self.isFavItems[itemID.." "..itemModID] = true;
        else
            self.isFavItems[itemID] = true;
        end

        self:Save();
    end
end

function FavUtil:Remove(itemID, itemModID)
    if itemID then
        if itemModID then
            self.isFavItems[itemID.." "..itemModID] = nil;
        else
            self.isFavItems[itemID] = nil;
        end
        self:Save();
    end
end

function FavUtil:Load()
    if not NarcissusDB then
        print("Cannot find NarcissusDB");
        return 0;
    end

    NarcissusDB.Favorites = NarcissusDB.Favorites or {};
    NarcissusDB.Favorites.FavoriteWeaponIDs = NarcissusDB.Favorites.FavoriteWeaponIDs or {};
    self.db = NarcissusDB.Favorites.FavoriteWeaponIDs;

    for i = 1, #self.db do
        self.isFavItems[ self.db[i] ] = true;
    end

    self.favList = {};
    self.favCount = {};

    self.isLoaded = true;
    self.requireUpdate = true;
end

function FavUtil:Save()
    if self.isLoaded then
        wipe(self.db);
        local numFavs = 0;
        for item, isFav in pairs(self.isFavItems) do
            if isFav then
                numFavs = numFavs + 1;
                self.db[numFavs] = item;
            end
        end
        self.requireUpdate = true;
        ViewUpdator:RefreshStar();
    end
end

function FavUtil:BuildList()
    local numFavs = 0;
    local itemID, itemModID;
    local subclassID;

    if self.requireUpdate then
        wipe(self.favList);
        wipe(self.favCount);

        for item, isFav in pairs(self.isFavItems) do
            if isFav then
                numFavs = numFavs + 1;
                if type(item) == "string" then
                    itemID, itemModID = string.split(" ", item);
                    itemID = tonumber(itemID);
                    itemModID = tonumber(itemModID);
                else
                    itemID, itemModID = item, nil;
                end

                subclassID = GetSubclassID(itemID);

                if not self.favList[subclassID] then
                    self.favList[subclassID] = {};
                    self.favCount[subclassID] = 0;
                end

                if itemModID then
                    tinsert(self.favList[subclassID], {itemID, itemModID} );
                else
                    tinsert(self.favList[subclassID], itemID);
                end
                self.favCount[subclassID] = self.favCount[subclassID] + 1;
            end
        end

        self.requireUpdate = nil;
    end
    return self.favList, self.favCount;
end

function FavUtil:GetListBySubclassID(subclassID)
    return self.favList[subclassID] or {};
end

---------------------------------------------------------------
NarciWeaponBrowserQuickFavButtonMixin = {};

function NarciWeaponBrowserQuickFavButtonMixin:OnLoad()
    FavButton = self;
    self.Star:SetVertexColor(0.4, 0.4, 0.4);
end

function NarciWeaponBrowserQuickFavButtonMixin:OnHide()
    self:Hide();
end

function NarciWeaponBrowserQuickFavButtonMixin:OnEnter()
    self.Star:SetVertexColor(1, 1, 1);
    self.Star:Show();
end

function NarciWeaponBrowserQuickFavButtonMixin:OnLeave()
    self.Star:SetVertexColor(0.4, 0.4, 0.4);
    if self.isFav then
        self.Star:Hide();
    end
    if not MainFrame:IsMouseOver() then
        self:Hide();
    end
end

function NarciWeaponBrowserQuickFavButtonMixin:OnMouseDown()

end

function NarciWeaponBrowserQuickFavButtonMixin:OnMouseUp()

end

function NarciWeaponBrowserQuickFavButtonMixin:OnClick()
    if self.parentObject then
        if self.isFav then
            FavUtil:Remove(self.parentObject.itemID, self.parentObject.itemModID);
        else
            FavUtil:Add(self.parentObject.itemID, self.parentObject.itemModID);
            self.Star:Hide();
        end
    end
end

function NarciWeaponBrowserQuickFavButtonMixin:OnDoubleClick()

end

function NarciWeaponBrowserQuickFavButtonMixin:SetParentObject(weaponNiche)
    self:ClearAllPoints();
    self:SetParent(weaponNiche);
    self:SetPoint("TOPLEFT", weaponNiche, "TOPLEFT", 0, -12);
    self.parentObject = weaponNiche;
    self:SetFrameLevel( weaponNiche:GetFrameLevel() + 3);
    if weaponNiche.isFav then
        self.isFav = true;
        self.Star:SetTexCoord(0, 0.5, 0, 1);
        self.Star:Hide();
    else
        self.isFav = false;
        self.Star:SetTexCoord(0.5, 1, 0, 1);
        self.Star:Show();
    end
    self:Show();
end

-------------------------------------------------------------------------------
local TooltipUtil = {}
TooltipUtil.tooltip = NarciWeaponTooltip;

function TooltipUtil:ShowTooltip(object)
    self.tooltip:SetNameID(object.Name:GetText(), object.itemID, object);
end

function TooltipUtil:HideTooltip()
    self.tooltip:FadeOut();
end

-------------------------------------------------------------------------------
local ButtonHighlight = {};

ViewUpdator.b = 0;

function ViewUpdator:SetButtonGroup(buttons)
    self.buttons = buttons;
    self.numButtons = #buttons;
end

function ViewUpdator:UpdateReference()
    self.yTop = MainFrame:GetTop();
    self.yBot = MainFrame:GetBottom();
end

function ViewUpdator:UpdateVisibleArea(offsetY)
    local b = floor( offsetY / 90 + 0.5) - 1;   --90 ~ buttonHeight
    if b ~= self.b then --last offset
        local buttons = self.buttons;
        local data = DataProvider:GetWeaponsByIndex(b);
        if b > self.b then
            local topButton = tremove(buttons, 1);
            tinsert(buttons, topButton);
        else
            local bottomButton = tremove(buttons);
            tinsert(buttons, 1, bottomButton);
        end
        for i = 1, self.numButtons do
            buttons[i]:SetPoint("TOP", 0, -(b + i - 1) * 90);
            buttons[i]:SetItem(data[i]);
            buttons[i]:UpdateRoll(self.yTop, self.yBot);
        end
        self.b = b;
    else
        for i = 1, self.numButtons do
            self.buttons[i]:UpdateRoll(self.yTop, self.yBot);
        end
    end
end

function ViewUpdator:ForceUpdate()
    MainFrame.WeaponContainer.scrollBar:SetValue(0);

    local buttons = self.buttons;
    local data = DataProvider:GetWeaponsByIndex(0);
    for i = 1, self.numButtons do
        buttons[i]:SetPoint("TOP", 0, (1 - i) * 90);
        --buttons[i]:Clear();
        buttons[i]:SetItem(data[i]);
    end

    local top = MainFrame.WeaponContainer:GetTop();

    for i = 1, self.numButtons do
        buttons[i]:UpdateRoll(self.yTop, self.yBot, top - 90 * i + 45);
    end
end

function ViewUpdator:SetReversedFacing(state)
    if state ~= self.reversedFacing then
        self.reversedFacing = state;
        local d;
        if state then
            d = -PI/2
        else
            d = PI/2;
        end
        for i = 1, self.numButtons do
            self.buttons[i].Model:SetFacing(d);
        end
    end
end

function ViewUpdator:SetScrollRange(numWeapons)
    local ScrollFrame = MainFrame.WeaponContainer;
    local maxScroll = (numWeapons * 90 - ScrollFrame:GetHeight() + 90);
    ScrollFrame.scrollBar:SetRange(maxScroll, true);
end

function ViewUpdator:FindFocusedButton()
    if MainFrame:IsMouseOver() then
        local button;
        for i = 1, self.numButtons do
            button = self.buttons[i];
            if button:IsMouseOver() then
                button:OnEnter();
            end
        end
    end
end

function ViewUpdator:EnableShadow(state)
    for i = 1, self.numButtons do
        self.buttons[i].ModelShadow:SetShown(state)
    end
end

function ViewUpdator:PauseMouseMotion(state)
    for i = 1, self.numButtons do
        self.buttons[i].puaseMotion = state;
    end
end

function ViewUpdator:OnScrollStart()
    local v = ViewUpdator;
    if not v.isScrolling then
        if v.focusedButton then
            v.focusedButton:OnLeave(nil, true);
            v.focusedButton = nil;
        end
    end
    v.isScrolling = true;
    v:PauseMouseMotion(true);

    TooltipUtil.tooltip:Hide();
end

function ViewUpdator:ReleaseLastFocus()
    if self.focusedButton then
        self.focusedButton:OnLeave(nil, true);
        self.focusedButton = nil;
    end
end

function ViewUpdator:OnScrollEnd()
    local v = ViewUpdator;
    v.isScrolling = nil;
    v:PauseMouseMotion(nil);
    v:FindFocusedButton();
end

function ViewUpdator:ToggleName(state)
    if state then
        for i = 1, self.numButtons do
            FadeFrame(self.buttons[i].Name, 0.2, 1);
        end
    else
        for i = 1, self.numButtons do
            self.buttons[i].Name:SetAlpha(0);
        end
    end
end

function ViewUpdator:UpdateAnimation(scale, distance)
    local buttons = ViewUpdator.buttons;
    local button;
    for i = 1, #buttons do
        button = buttons[i];
        button.Background:SetScale(scale)
        button.Model:SetPosition(distance, 0, 0);
        button.ModelShadow:SetPosition(distance, 0, -button.Model.zoomDistance/100);
    end
end

function ViewUpdator:PlayTabTransition(isHomePage)
    self.animHome:Hide();
    MainFrame.HomePage.MotionBlocker:Show();
    ButtonHighlight:Hide();
    if isHomePage then
        ButtonHighlight:ResetState();
        self.animHome.easeFunc = outQuint;
        self.animHome.toY = -16;
        self.animHome.fromY = -400;
        self.animHome.duration = 0.6;
        After(0.25, function()
            MainFrame.HomePage.MotionBlocker:Hide();
        end)
    else
        self:PauseMouseMotion(nil);
        self.animHome.easeFunc = inQuad;
        self.animHome.toY = -400;
        self.animHome.fromY = -16;
        self.animHome.duration = 0.45;
    end
    self.animHome.toBeHidden = not isHomePage;
    self.animHome:Show();
end

function ViewUpdator:RecolorCurrentList()
    for i = 1, self.numButtons do
        self.buttons[i]:RecolorItemName();
    end
end

function ViewUpdator:RefreshStar()
    for i = 1, self.numButtons do
        self.buttons[i]:RefreshStar();
        if self.buttons[i]:IsMouseOver() then
            FavButton:SetParentObject(self.buttons[i]);
        end
    end
end
-------------------------------------------------------------------------------
--Entrance Visual
local Roller = CreateFrame("Frame");
Roller:Hide();
Roller.toRoll = 0;

function Roller:SetButtonGroup(buttons)
    self.objects = buttons;
    self.fromRoll = -PI/2;
    self.duration = 0.5;
    self.numObjects = 4 --#buttons;
end

function Roller:Start(withDelay)
    self.times = {};
    if withDelay then
        if self.objects then
            for i = 1, self.numObjects do
                self.times[i] = 0.1*(- i);
            end
        end
    else
        if self.objects then
            for i = 1, self.numObjects do
                self.times[i] = 0.05*(1 - i);
            end
        end
    end
    self:Stop();
    self:Show();
end

function Roller:Stop()
    self:Hide();
    self.times = {};
    if self.objects then
        for i = 1, self.numObjects do
            self.times[i] = 0.1*(- i) --0.05*(1 - i);
        end
    end
end

Roller:SetScript("OnUpdate", function(self, elapsed)
    local obj, t, roll;
    local isRolling = false;

    for i = 1, self.numObjects do
        obj, t = self.objects[i], self.times[i];
        t = t + elapsed;
        self.times[i] = t;
        if t >= self.duration then
            roll = 0;
            isRolling = isRolling or false;
        elseif t >= 0 then
            roll = outQuart(t, self.fromRoll, self.toRoll, self.duration);
            isRolling = true;
        else
            roll = self.fromRoll;
            isRolling = true;
        end
        obj:SetItemRoll(roll);
    end

    if not isRolling then
        self:Stop();
    end
end);


-------------------------------------------------------------------------------
local function Niche_OnModelLoaded(self)
    self.isLoaded = true;
    self:SetKeepModelOnHide(true);
    self:MakeCurrentCameraCustom();
    self:SetCameraPosition(self.zoomDistance, 0, 0);
    self:SetCameraTarget(0, 0, 0);
    self:SetViewTranslation(0, self.offsetY or 0);

    self:GetParent().ModelShadow:SetAnimation(0, 0);
    self:SetAnimation(0, 0);
end

local function RenderedShadow_OnModelLoaded(self)
    local m = self:GetParent().Model;
    self:SetParticlesEnabled(false);
    self:SetKeepModelOnHide(true);
    self:MakeCurrentCameraCustom();
    self:SetCameraPosition(m.zoomDistance, 0, 0);
    self:SetCameraTarget(0, 0, 0);
    self:SetViewTranslation(0, m.offsetY or 0);
    self:SetPosition(0, 0, -m.zoomDistance/100);
    m:SetAnimation(0, 0);
    self:SetAnimation(0, 0);
end

NarciWeaponNicheMixin = {};

function NarciWeaponNicheMixin:OnLoad()
    self.defaultRoll = 0;

    local m = self.Model;
    m:SetScript("OnModelLoaded", Niche_OnModelLoaded);
    SetModelLight(m, true, false, -0.55, 0, -0.83, 1, 0.8, 0.8, 0.8, 1, 0.6, 0.6, 0.6);
    m:SetFacing(PI/2);
    m:UseModelCenterToTransform(true);

    local ms = self.ModelShadow;
    local a = 0.1;
    ms:SetFogColor(a, a, a);
    SetModelLight(ms, false);
    ms:SetScript("OnModelLoaded", RenderedShadow_OnModelLoaded);
    m:SetFacing(PI/2);
    ms:UseModelCenterToTransform(true);
end

function NarciWeaponNicheMixin:Clear()
    self.itemID = nil;
    self.itemModID = nil;
    self.sourceID = nil;
    self.Model:ClearModel();
    self.ModelShadow:ClearModel();
end

function NarciWeaponNicheMixin:SetItem(itemID, itemModID)
    --itemID: number or {itemID, itemModID}: table
    if itemID then
        if type(itemID) == "table" then
            self.sourceID = itemID[3];
            itemID, itemModID = itemID[1], itemID[2];
        end
        if itemID ~= self.itemID or itemModID ~= self.itemModID then
            self.Model.isLoaded = false;
            self.itemID = itemID;
            self.itemModID = itemModID;

            local name = GetItemName(itemID);
            self.Name:SetFontObject("NarciIndicatorLetter");
            self.Name:SetText(name);
            if self.Name:IsTruncated() then
                self.Name:SetFontObject("NarciIndicatorDigitTiny");
            end

            local _, _, _, _, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemID);
            if itemClassID and itemSubClassID then
                if (itemClassID == 4 and (itemSubClassID == 0 or itemSubClassID == 6)) then  --Shield
                    itemSubClassID = 69;
                    self.Model:SetFacing(-PI/2);
                    self.ModelShadow:SetFacing(-PI/2);
                elseif itemSubClassID == 2 then     --Bow
                    self.Model:SetFacing(-PI/2);
                    self.ModelShadow:SetFacing(-PI/2);
                else
                    self.Model:SetFacing(PI/2);
                    self.ModelShadow:SetFacing(PI/2);
                end
                if itemSubClassID == 18 then    --Crossbow: Tilt a bit
                    self.defaultRoll = 0.3925;
                else
                    self.defaultRoll = 0;
                end
            end
            self.itemSubClassID = itemSubClassID;
            self.Model.zoomDistance, self.Model.offsetY = DataProvider:GetCameraInfo(itemSubClassID, itemID);

            if itemModID then
                self.Model:SetItem(itemID, itemModID);
                self.ModelShadow:SetItem(itemID, itemModID);
            else
                self.Model:SetItem(itemID);
                self.ModelShadow:SetItem(itemID);
            end

            local isFav = FavUtil:IsFavorite(itemID, itemModID);
            self.isFav = isFav;
            self.FavStar:SetShown(isFav);

            --Valid For DressUpModel
            if TRY_ON_CHECK then
                if IsItemValidForTryOn(itemID) then
                    self.Name:SetTextColor(0.66, 0.66, 0.66);
                else
                    self.Name:SetTextColor(1, 0.3137, 0.3137);  --red
                end
            else
                if self.itemModID then
                    self.Name:SetTextColor(1, 0.3137, 0.3137);  --red
                else
                    self.Name:SetTextColor(0.66, 0.66, 0.66);
                end
            end
        end
        self:Show();
    else
        self.itemID = nil;
        self.Model:ClearModel();
        self.ModelShadow:ClearModel();
        self:Hide();
    end
end

function NarciWeaponNicheMixin:RecolorItemName()
    if self.itemID then
        if TRY_ON_CHECK then
            if IsItemValidForTryOn(self.itemID) then
                self.Name:SetTextColor(0.66, 0.66, 0.66);
            else
                self.Name:SetTextColor(1, 0.3137, 0.3137);  --red
            end
        else
            if self.itemModID then
                self.Name:SetTextColor(1, 0.3137, 0.3137);  --red
            else
                self.Name:SetTextColor(0.66, 0.66, 0.66);
            end
        end
    end
end

function NarciWeaponNicheMixin:RefreshStar()
    if self.itemID then
        self.FavStar:StopAnimating();
        if FavUtil:IsFavorite(self.itemID, self.itemModID) then
            self.isFav = true;
            if not self.FavStar:IsShown() then
                self.FavStar:Show();
                self.FavStar.Background.FlyIn:Play();
                self.FavStar.Star.ScaleIn:Play();
            end
        else
            self.isFav = false;
            self.FavStar:Hide();
        end
    end
end

function NarciWeaponNicheMixin:SetItemRoll(r)
    r = r + self.defaultRoll;
    self.Model:SetRoll(r);
    self.ModelShadow:SetRoll(r);
end

function NarciWeaponNicheMixin:SetZoomDistance(distance, scale)
    self.Background:SetScale(scale);
    self.Model:SetPosition(distance, 0, 0);
    self.ModelShadow:SetPosition(distance, 0, -self.Model.zoomDistance/100);
end

function NarciWeaponNicheMixin:UpdateRoll(topY, botY, designatedY)
    --if not self.Model.isLoaded then print("Not Loaded") return end;
    local x, y;
    if designatedY then
        y = designatedY;
    else
        x, y = self:GetCenter();
    end
    local r = 0;
    local a = 1;
    if y < botY + 50 then
        r = (y - botY - 50)*0.035;
        if r < - PI/2 then
            r = - PI/2
        end
        a  = 1 + (y - botY - 30)/30;
    elseif y > topY - 60 then
        r = (y - topY + 60)*0.035;
        if r > PI/2 then
            r = PI/2;
        end
        a = 1 - (y - topY + 60)/50;
    else

    end
    
    if a < 0 then
        a = 0;
        self.Model:Hide();
        self.ModelShadow:Hide();
    elseif a > 1 then
        a = 1;
        self.Model:Show();
        self.ModelShadow:Show();
    else
        self.Model:Show();
        self.ModelShadow:Show();
    end

    r = r + self.defaultRoll;
    
    self.Model:SetRoll(r);
    self.ModelShadow:SetRoll(r);

    self.Model:SetModelAlpha(a);
    self.ModelShadow:SetModelAlpha(a);
end

function NarciWeaponNicheMixin:OnClick(mouseButton)
    if IsModifiedClick() then
        local model = Narci:GetActiveActor();
        if model then
            local slot;
            if IsAltKeyDown() then
                slot = 2;
            else    --IsControlKeyDown or Shift
                slot = 1;
            end

            --Failure Reason
            local hasReason;
            if not model:IsVisible() then
                AlertUtil:SetReason(1);     --Actor is hidden
                hasReason = true;
            elseif self.itemSubClassID == 13 and model.GetSheathed and model:GetSheathed() then
                AlertUtil:SetReason(2);     --Sheathed fist weapons
                hasReason = true;
            end

            if model.widgetType == 2 then
                --CinematicModel
                if self.itemModID then
                    AlertUtil:SetReason(4);
                    hasReason = true;
                end
            else
                --DressUpModel
                --temp fix for 9.1
                if not IsItemValidForTryOn(self.itemID) then
                    local itemInfo = C_Item.GetItemInfo(self.itemID);
                    if not itemInfo then
                        AlertUtil:SetReason(4);
                        hasReason = true;
                    end
                end
            end

            if not self.itemModID then
                self.sourceID = GetSourceID(self.itemID) or 0;
            end
            local itemTryOnSuccess, effectiveSlot, widgetType = model:EquipWeapon(self.itemID, self.sourceID, slot);
            if itemTryOnSuccess then
                Narci_PhotoModeWeaponFrame:SetItemInfo(self.itemID, effectiveSlot, self.Name:GetText(), widgetType == 2);
                if not hasReason then
                    AlertUtil:HideAlert();
                end
            else
                AlertUtil:SetReason(3);
            end
        end
    else
        if mouseButton == "RightButton" then
            MainFrame:ReturnHome();
        else
            --MainFrame:ShowModelComparison(self.itemID);
            AlertUtil:ShowShorcutTooltip();
        end
    end
end

function NarciWeaponNicheMixin:OnEnter()
    --self.Model:SetPosition(0.4, 0, 0);
    if not self.puaseMotion then
        ViewUpdator.focusedButton = self;
        ModelZoom:Add(self, 0.4, -(self.Model.zoomDistance/50));
        TooltipUtil:ShowTooltip(self);
    end
    FavButton:SetParentObject(self);
end

function NarciWeaponNicheMixin:OnLeave(motion, forcedLeave)
    --self.Model:SetPosition(0, 0, 0);
    if self.itemID and not self.puaseMotion and (forcedLeave or not self:IsMouseOver(0, 0, 0, -12)) then
        ViewUpdator.focusedButton = nil;
        ModelZoom:Add(self, 0, -(self.Model.zoomDistance/100));
        TooltipUtil:HideTooltip();
        FavButton:Hide();
    end
end

function NarciWeaponNicheMixin:OnMouseDown()

end

function NarciWeaponNicheMixin:OnMouseUp()

end


-------------------------------------------------------------------------------
local Turner = CreateFrame("Frame");
Turner:Hide();
Turner.t = 0;
Turner.d = 0.5;
Turner:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    if self.model then
        self.model:SetFacing( outQuart(self.t, self.fromFacing, self.toFacing, self.d));
    else

    end
    if self.t >= self.d then
        self.t = 0;
        self:Hide();
    end
end);

function Turner:Start(facing)
    self.t = 0;
    self.fromFacing = facing - 0.25;
    self.toFacing = facing
    self:Show();
end

function Turner:Stop()
    self:Hide();
    self.t = 0;
end




ButtonHighlight.typicalModelInfo = {
    -- [subclassID] = {itemID, facing, {camPosition}, {modelPosition}, {backgroundGradient}}

	[0] = {168268, 5.453, {3.435, 0, -2.638}, {0, 0.273, -0.767}},		--Axe 1H
	[1] = {128323, 5.491, {3.376, 0, -1.43}, {0, 0.394, -0.407}},		--Axe 2H
	[2] = {151781, 2.162, {2.876, 0, -1.522}, {0, 0.298, -0.27}},		--Bow
	[3] = {153648, 5.464, {2.241, 0, -0.449}, {0, 0.115, -0.301}},		--Gun
	[4] = {115283, 5.432, {3.006, 0, -1.904}, {0, 0.247, -0.651}},		--Mace 1H
	[5] = {177838, 5.469, {3.184, 0, -1.504}, {0, 0.534, -0.607}},		--Mace 2H
	[6] = {174994, 5.384, {3.065, 0, -2.268}, {0, 0.555, -0.774}},		--Polearm
	[7] = {178906, 5.635, {2.206, 0, -0.907}, {0, 0.192, -0.464} },		--Sword 1H
	[8] = {152482, 5.645, {2.909, 0, -0.904}, {0, 0.230, -0.515} },		--Sword 2H
	[9] = {120370, 2.205, {4.034, 0, -1.282}, {0, 0.519, -0.686} }, -- [4],		--Warglaive
	[10] = {153575, 5.48, {3.276, 0, -2.147}, {0, 0.402, -0.778}},		--Staff
	[13] = {165224, 2.018, {3.901, 0, -1.058}, {0, 0.296, -0.177}},		--Fist Weapon
	[14] = {167044, 5.608, {2.123, 0, -0.354}, {0, 0.116, -0.116}},		--Miscellaneous
	[15] = {171193, 5.549, {2.292, 0, -0.856}, {0, 0.182, -0.413}},		--Dagger
	[16] = {39490, 2.023, {2.166, 0, -0.377}, {0, 0.175, -0.328}},		--Thrown
	--[17] = {174994, 5.384, {3.065, 0, -2.268}, {0, 0.555, -0.774}},		--Spears
	[18] = {179729, 5.565, {3.526, 0, -2.109}, {0, 0.238, -0.842}},		--Crossbow
	[19] = {117628, 5.379, {2.661, 0, -1.921}, {0, 0.268, -0.664}},		--Wands
	[20] = {44050, 5.683, {3.612, 0, -1.065}, {0, 0.281, -0.443}},		--Fishing Poles
    [69] = {139622, 4.344, {3.506, 0, -0.56}, {0, 0.094, -0.399}},   --Shield
    [1208] = {176455, 1.01, {2.834, 0, -0.299}, {0, 0.184, 0.219}},		--Miscellaneous
};

local function Highlight_OnModelLoaded(self)
    self:MakeCurrentCameraCustom();
    self:SetCameraTarget(0, 0, 0)
    self:SetCameraPosition( unpack(self.cameraPosition) );
    self:SetPosition( unpack(self.modelPosition) );
    self:SetFacing(self.facing);
    MD = self
end

function ButtonHighlight:Init(widget)
    self.object = widget;
    Turner.model = widget.WeaponModel;
    SetModelLight(widget.WeaponModel, true, false, -0.61, 0.52, -0.6, 1, 0.5, 0.5, 0.5, 1, 1, 1, 1);
    widget.WeaponModel:SetScript("OnModelLoaded", Highlight_OnModelLoaded);
end

function ButtonHighlight:SetFocus(categoryButton)
    self.lastFocus = categoryButton;

    self.object:ClearAllPoints();
    self.object:SetPoint("LEFT", categoryButton, "LEFT", 0, 0);
    self.object.ItemCount:SetText(categoryButton.numWeapons);
    local itemInfo = self.typicalModelInfo[categoryButton.subclassID];
    if itemInfo then
        self.object.WeaponModel:SetItem(itemInfo[1]);  --182575 180218 120370
        self.object.WeaponModel.facing = itemInfo[2];
        Turner:Start(itemInfo[2]);
        self.object.WeaponModel.cameraPosition = itemInfo[3];
        self.object.WeaponModel.modelPosition = itemInfo[4];
    end

    self.object:Show();
end

function ButtonHighlight:Hide()
    self.object:Hide();
    Turner:Stop();
end

function ButtonHighlight:SetColor(v)
    self.object.Background:SetColorTexture(v, v, v);
end

function ButtonHighlight:ResetState()
    if self.lastFocus then
        self.lastFocus.pauseMotion = nil;
        self.lastFocus:OnLeave();
    end
end

-------------------------------------------------------------------------------
NarciWeaponCategoryMixin = {};

function NarciWeaponCategoryMixin:SetCatergory(subclassID, numWeapons)
	local cate = DataProvider.subclassInfo[subclassID];
	if cate then
		if type(cate) == "number" then

		else
			self.Name:SetText(cate);
		end
	else
		self.Name:SetText("Unknown "..subclassID);
	end

	self.subclassID = subclassID;
    self.numWeapons = numWeapons;
    self.ItemCountRight:SetText( numWeapons );
end

function NarciWeaponCategoryMixin:OnClick()
    if TabUtil.activeTab == 2 then
        DataProvider.weaponList =  FavUtil:GetListBySubclassID(self.subclassID);
    else
	    DataProvider.weaponList = DataAPI.GetWeaponsBySubclassID(self.subclassID);
    end

    ViewUpdator:SetScrollRange(self.numWeapons);
    ViewUpdator:SetReversedFacing(self.subclassID == 69 or self.subclassID == 2);   --Shield/Bow
	MainFrame:GoToWeapons();
    MainFrame.Header.Tab2Label:SetText(self.Name:GetText());
    Roller:Start(true);

    self.pauseMotion = true;
end

function NarciWeaponCategoryMixin:OnDoubleClick()

end

function NarciWeaponCategoryMixin:OnEnter()
    ButtonHighlight:SetFocus(self);
	self.Name:SetTextColor(0.8, 0.8, 0.8);
    self.ItemCountRight:Hide();
    self:SetHeight(30.0);
end

function NarciWeaponCategoryMixin:OnLeave()
    if not self.pauseMotion then
        self.Name:SetTextColor(0.66, 0.66, 0.66);
        self.ItemCountRight:Show();
        self:SetHeight(16.0);
        ButtonHighlight:Hide();
    end
end

function NarciWeaponCategoryMixin:OnMouseDown()
    ButtonHighlight:SetColor(0.08);
end

function NarciWeaponCategoryMixin:OnMouseUp()
    ButtonHighlight:SetColor(0);
end


-------------------------------------------------------------------------------
NarciWeaponBrowserMixin = {};

function NarciWeaponBrowserMixin:Open()
    self:Show();
    if self.Load then
        --Enable Database
        After(0.2, function()
            local addOnName = "Narcissus_Database_Item";
            if C_AddOns.GetAddOnEnableState(addOnName, UnitName("player")) == 0 then
                C_AddOns.EnableAddOn(addOnName);
            end
            local loaded, reason = C_AddOns.LoadAddOn(addOnName);
        end);
    end
end

function NarciWeaponBrowserMixin:Preload()
	MainFrame = self;
    ViewUpdator:UpdateReference();

    local a = 0.15;
    self.Backdrop:SetColorTexture(a, a, a);

    self.InnerShadow:Hide();
    self.HomePage.LoadingNotes:SetText(Narci.L["Loading Database"]);

    local tooltip = NarciWeaponTooltip;
    if tooltip then
        tooltip:SetParent(self);
        tooltip:SetFrameStrata("TOOLTIP");
        tooltip:SetFrameLevel(80);
    end

    self:SetClampedToScreen(true);
    local height = self:GetHeight();
    self:SetClampRectInsets(0, 0, 0, height - 32);  --Clamp header to the screen
end

function NarciWeaponBrowserMixin:Load()
    --Fetch
    if not NarciItemDatabase then
        print("Failed to find NarciItemDatabase");
        return
    end
    DataAPI = NarciItemDatabase;
    GetItemName = DataAPI.GetItemName;
    GetSourceID = DataAPI.GetSourceID;
    IsItemValidForTryOn = DataAPI.IsItemValidForTryOn;

    DataProvider:LocalizeSubclassName();

    local ScrollFrame = self.WeaponContainer;
    local ScrollChild = ScrollFrame.ScrollChild;
    TEMP:CreateWeaponNiche(ScrollChild);
    local weaponButtons = ScrollChild.buttons;
    ViewUpdator:SetButtonGroup(weaponButtons);
    Roller:SetButtonGroup(weaponButtons);
    
    local buttonHeight = 90;
    local numButtons = #weaponButtons;
    local numButtonsPerPage = 1;
    local totalHeight = floor(numButtons * buttonHeight + 0.5);
    local maxScroll = floor((5000 - numButtonsPerPage) * buttonHeight + 0.5 - self:GetHeight()/2);

    ScrollFrame.scrollBar:SetMinMaxValues(0, maxScroll)
    ScrollFrame.buttonHeight = totalHeight;
    ScrollFrame.range = maxScroll;

    NarciAPI_SmoothScroll_Initialization(ScrollFrame, nil, nil, 1/numButtons, 0.14, nil, ViewUpdator.OnScrollStart, ViewUpdator.OnScrollEnd);
    ScrollFrame.scrollBar.onValueChangedFunc = function(value)
        ScrollFrame:SetVerticalScroll(value);
        ViewUpdator:UpdateVisibleArea(value);
    end

    --Create Categories
    HomePage = self.HomePage;
    ButtonHighlight:Init(HomePage.ButtonHighlight);
    TabUtil:ShowEverything();
    TEMP:CreateTabButtons(HomePage.Container);   --Above Categories

    local animHome = NarciAPI_CreateAnimationFrame(0.6);
    animHome:SetScript("OnUpdate", function(frame, elapsed)
        frame.total = frame.total + elapsed;
        local offsetY;
        if frame.total >= frame.duration then
            offsetY = frame.toY;
            frame:Hide();
            if frame.toBeHidden then
                MainFrame.HomePage:Hide();
            end
        else
            offsetY = frame.easeFunc(frame.total, frame.fromY, frame.toY, frame.duration);
        end
        HomePage:SetPoint("TOP", self, "TOP", 0, offsetY);
    end);
    ViewUpdator.animHome = animHome;

    --Search Box
    local SearchBox = self.Header.SearchBox;
    SearchBox.DefaultText:SetText("Item Name");
    SearchBox.onSearchFunc = function(word)
        local numMacthes, overFlow;
        local id = tonumber(word);
        if id and id ~= 0 then
            if GetItemInfoInstant(id) then
                DataProvider.searchResult = { id };
                numMacthes = 1;
            else
                DataProvider.searchResult = {};
                numMacthes = 0;
            end
        else
            DataProvider.searchResult, numMacthes, overFlow = DataAPI.SearchItemByName(word);
            DataProvider.numMacthes = numMacthes;
        end

        DataProvider.weaponList = DataProvider.searchResult;
        ViewUpdator:SetScrollRange(numMacthes);
        ViewUpdator:ForceUpdate();
        Roller:Start();
        --SearchBox.NoMatchText:SetShown(numMacthes == 0);
        AlertUtil:SetNumMatches(numMacthes, overFlow);
    end

    AlertUtil:Init(self.AlertFrame);
    ModelZoom:Init();

    self:SetParent(Narci_ModelSettings);
    self:SetIgnoreParentAlpha(true);
    self:SetFrameLevel(70);
    self.ComparisonFrame:SetFrameStrata("LOW");
    self.ComparisonFrame:SetFrameLevel(1);

    FavUtil:Load();

    self.InnerShadow:Show();
    HomePage.LoadingNotes:Hide();

    HomePage.LoadingNotes:SetText("No favorite weapons.");

    --Guide Frame
    local GuideFrame = self.GuideFrame;
    GuideFrame.Tip1:SetText(L["WeaponBrowser Guide Hotkey"]);
    GuideFrame.Tip2:SetText(L["WeaponBrowser Guide ModelType"]);
    GuideFrame.DressUpModelNote:SetText(string.format(L["WeaponBrowser Guide DressUpModel"], NARCI_MODIFIER_ALT));
    GuideFrame.CinematicModelNote:SetText(L["WeaponBrowser Guide CinematicModel"]);
    if NarcissusDB.Tutorials["WeaponBrowser"] then
        NarcissusDB.Tutorials["WeaponBrowser"] = false;
        After(1.5, function()
            self:ShowGuide();
        end);
    end
    TEMP:Release();
    self.Load = nil;
    collectgarbage("collect");

    --self.TempMouseAction:SetText(NARCI_MODIFIER_CONTROL.."-Click: ".."|cff808080Main Hand|r  "..NARCI_MODIFIER_ALT.."-Click: ".."|cff808080Off Hand|r");
end

function NarciWeaponBrowserMixin:ReturnHome()
	self.WeaponContainer:Hide();
    --self.HomePage:SetAlpha(0);
	self.HomePage:Show();
    self.Header.SearchBox:Hide();
    self.Header.SearchTrigger:Show();
    self.Header.Tab2Label:Hide();
    self.Header.HomeButton:Hide();
    TooltipUtil:HideTooltip();
    ViewUpdator:ReleaseLastFocus();
    ViewUpdator:PlayTabTransition(true);
    AlertUtil:HideAlert();

    if TabUtil.activeTab == 2 and FavUtil.requireUpdate then
        TabUtil:ShowFavorites();
    end
end

function NarciWeaponBrowserMixin:GoToWeapons()
	--self.HomePage:Hide();
    self.Header.SearchBox:Hide();
    self.Header.SearchTrigger:Hide();
    self.Header.Tab2Label:Show();
    self.Header.HomeButton:Show();
	self.WeaponContainer:Show();
    ViewUpdator:UpdateReference();
    ViewUpdator:ForceUpdate();
    ViewUpdator:PlayTabTransition(false);
end

function NarciWeaponBrowserMixin:GoToSearch()
    ViewUpdator:UpdateReference();
    DataProvider.weaponList = DataProvider.searchResult or {};
    ViewUpdator:SetScrollRange(DataProvider.numMacthes or 0);
	--self.HomePage:Hide();
    self.Header.SearchBox:Show();
    self.Header.SearchTrigger:Hide();
    self.Header.Tab2Label:Hide();
    self.Header.HomeButton:Show();
	self.WeaponContainer:Show();
    ViewUpdator:ForceUpdate();
    TooltipUtil:HideTooltip();
    ViewUpdator:PlayTabTransition(false);
end

function NarciWeaponBrowserMixin:Close()
    self:Hide();
end

function NarciWeaponBrowserMixin:OnDragStart()
    self:StartMoving();
end

function NarciWeaponBrowserMixin:OnDragStop()
    self:StopMovingOrSizing();
    ViewUpdator:UpdateReference();
end

function NarciWeaponBrowserMixin:ShowModelComparison(itemID)
    if not itemID then return end;  --base itemID

    local frame = self.ComparisonFrame;
    local fileID = DataAPI.GetItemModelFileID(itemID);
    frame.Header.Title:SetText( "ModelFileID: "..fileID )

    if not fileID then return end;

    local items = DataAPI.GetItemsByFileID(fileID);
    if not frame.models then
        frame.models = {};
    end
    local models = frame.models;

    local numItems = #items;
    local MODELS_PER_PAGE = 12;

    local m, id, appearanceID, skip;
    local isAppearanceLogged = {};
    local numUnique = 0;
    for index = 1, numItems do
        skip = false;
        id = items[index];
        appearanceID = C_TransmogCollection.GetItemInfo(id);
        if appearanceID then
            if isAppearanceLogged[appearanceID] then
                skip = true;
            else
                isAppearanceLogged[appearanceID] = true;
                numUnique = numUnique + 1;
            end
        else
            numUnique = numUnique + 1;
        end

        if numUnique > MODELS_PER_PAGE then
            numUnique = numUnique - 1;
            break;
        end

        if not skip then
            m = models[numUnique];
            if not m then
                local i = numUnique;
                m = CreateFrame("Button", nil, frame, "NarciWeaponComparisonTemplate");
                models[i] = m;
                local row = math.ceil(i / 3);
                local col = i - (row - 1) * 3;
                m:ClearAllPoints();
                m:SetPoint("TOPLEFT", frame, "TOPLEFT", 192*(col - 1), -16 - 90*(row-1) );
            end
            m:SetComparisonItem(id, itemID);
        end
    end

    for i = numUnique + 1, MODELS_PER_PAGE do
        m = models[i];
        if m then
            m:SetItem();
        else
            break;
        end
    end

    frame:Show();
end


function NarciWeaponBrowserMixin:ToggleShadow()
    self.isShadowEnabled = not self.isShadowEnabled;
    ViewUpdator:EnableShadow(self.isShadowEnabled)
end
--/run Narci_WeaponBrowser:ToggleShadow();

function NarciWeaponBrowserMixin:RefreshingCurrentList()

end

function NarciWeaponBrowserMixin:ChangeActiveModelType(widgetType)
    local checkTryOn;
    if widgetType == 1 then
        checkTryOn = true;
    else
        checkTryOn = false;
    end

    if self.Load then
        TRY_ON_CHECK = checkTryOn;
    else

        if checkTryOn ~= TRY_ON_CHECK then
            TRY_ON_CHECK = checkTryOn;
            ViewUpdator:RecolorCurrentList();
        end
    end
end

function NarciWeaponBrowserMixin:OnHide()
    self:Hide();
    self.ComparisonFrame:Hide();
    self.GuideFrame:Hide();
end

function NarciWeaponBrowserMixin:ShowGuide()
    self.GuideFrame:SetAlpha(0);
    FadeFrame(self.GuideFrame, 0.2, 1);
end
------------------------------------------------------------------
NarciWeaponTabButtonMixin = {};

function NarciWeaponTabButtonMixin:Init(tabID)
    self.tabID = tabID;
    if not TabUtil.tabButtons then
        TabUtil.tabButtons = {};
    end

    tinsert(TabUtil.tabButtons, self);

    if tabID == 1 then
        self.ButtonText:SetText(VIDEO_OPTIONS_EVERYTHING);
    elseif tabID == 2 then
        self.ButtonText:SetText( (FAVORITES or "Favorites") );
    end

    self.ButtonText:SetWidth( self:GetWidth() - 8 );

    self.Init = nil;
end

function NarciWeaponTabButtonMixin:OnEnter()
    self.ButtonText:SetTextColor(0.8, 0.8, 0.8);
end

function NarciWeaponTabButtonMixin:OnLeave()
    self.ButtonText:SetTextColor(0.35, 0.35, 0.35);
end

function NarciWeaponTabButtonMixin:OnMouseUp()
    self.ButtonText:SetPoint("CENTER", 0, 0);
end

function NarciWeaponTabButtonMixin:OnMouseDown()
    self.ButtonText:SetPoint("CENTER", 0, -1);
end

function NarciWeaponTabButtonMixin:OnClick()
    if TabUtil.activeTab ~= self.tabID then
        TabUtil.activeTab = self.tabID;
        for i = 1, #TabUtil.tabButtons do
            TabUtil.tabButtons[i]:UpdateVisual();
        end

        if self.tabID == 1 then
            TabUtil:ShowEverything();
        elseif self.tabID == 2 then
            TabUtil:ShowFavorites();
        end
    end
end

function NarciWeaponTabButtonMixin:UpdateVisual()
    if TabUtil.activeTab == self.tabID then
        self:Disable();
        if self.tabID == 1 then
            self.ButtonText:SetTextColor(0.24, 0.52, 0.55);
        else
            self.ButtonText:SetTextColor(0.7, 0.57, 0.18);
        end
        self.Background:Hide();
        self.HighlightBorder:Show();
        --FadeFrame(self.Background, 0.12, 0);
        self:OnMouseDown();
    else
        self:Enable();
        self.ButtonText:SetTextColor(0.35, 0.35, 0.35);
        self.Background:Show();
        self.HighlightBorder:Hide();
        --FadeFrame(self.Background, 0.15, 1);
        self:OnMouseUp()
    end
end

------------------------------------------------------------------------
DataProvider.specialItemZoomDistance = {
    --[fileID] = distance
    [3846175] = 6,
    [3620241] = 8,
    [4323001] = 7,
    [3996209] = 8,
    [3813079] = 7,

    [3562415] = 3.5,    --Reven Dagger AGI
    [294450] = 7.5,   --Lance
    [3587362] = 6.5,    --Fae Glaive
    [3515407] = 6,      --Fist
    [252284] = 5,   --Foam Sword
    [147035] = 3,   --Potion
    [147029] = 3,   --Vial

    [146970] = 2.5,   --Flower
    [146974] = 2.5,   --Flower
    [146978] = 2.5,   --Flower
    [146982] = 2.5,   --Flower
    [146990] = 2.5,   --Flower

    [146950] = 2.5,     --Bottle
    [146955] = 2.5,     --Bottle

    [3734213] = 5.5,      --Maw 2H Sword
    [2741338] = 5.5,    --Ankoan Great Cleaver
    [1373498] = 6,      --Felborne Staff
    [1305005] = 6,      --Nightborne Sword

    [3307325] = 5.5,    --Remornia
    [147996] = 6,       --Maiev's Blade
    [147257] = 6,       --Hellfire Polearm
    [114217] = 7,       --Naga Spear
    [3486056] = 6,      --Maldraxxus Polearm
    [3260377] = 7,      --Archon's Spear
    [2909741] = 6,      --Mechagon Fishing Pole
    [1340861] = 6.5,      --Artifact Fish
    [238795] = 5,       --Jeweled Fish
    [2267316] = 6,      --Tyrande's Glaive
    [1536191] = 7,      --Mo'arg
    [1240191] = 7,      --Mo'arg

    [1900900] = 4,      --Pistol
    [1321556] = 4,      --Pistol
    [148583] = 3,       --Throwing Glaive
    [148575] = 3,       --Throwing Glaive
    [148579] = 3,       --Throwing Glaive

    [147080] = 5,       --Broom
    [1709375] = 6,      --Mop
    [2887299] = 5.5,    --Thrall Axe
    [1678516] = 6,      --Paddle
    [1598037] = 7,      --Immortal Mace

    [135129] = 6,       --Harpoon
    [42507] = 6,
    [160435] = 6,       --Kultiras Harpoon
    [144607] = 5,       --Pick
    [3235091] = 3.5,      --Revendreth Vial
    [3259852] = 3,      --Revendreth Crystal
    [929895] = 3.5,     --Crystal

    [3615913] = 4.5,
    [2837989] = 6,
    [3159878] = 6,
    [1107166] = 6,
    [1568517] = 6.5,    --Sentinel's Glaive
    [2097231] = 6,      --Dark Iron Shield
    [146376] = 5,       --Voodoo Hexblade
    [462667] = 7,       --Banner
    [462668] = 7,
    [1634861] = 5.5,      --Pick
    [1064752] = 5.5,      --Pick
    [3511043] = 5.5,     --Revendreth Lantern
    [3257381] = 5.5,     --Lantern
    [2976753] = 6,      --N'Zoth Shield
    [2905985] = 6,    --Naga Shield
    [2905995] = 6.5,    --Naga Shield
    [3580503] = 8.5,
    [3566444] = 7.5,
    [1028009] = 7,
    [1028010] = 7,
    [1028011] = 7,
    [1028012] = 7,
    [147611] = 6,
    [147505] = 6,
    [3195516] = 7,

    [3955579] = 7,
    [3949874] = 20,
    [3620241] = 7,
    [3615460] = 6.5,
    [4064752] = 6.5,
    [3597245] = 6,
    [3754266] = 5.5,
};

DataProvider.specialItemCameraOffset = {
    [3885243] = 8,
    [3620241] = 4,
    [4323001] = 16,
    [3813079] = 6,
    [531010] = 12,
    [3511043] = 26,     --Revendreth Lantern
    [3257381] = 26,     --Lantern
    [3191966] = -16,    --Lantern
    [3562415] = 8,      --Revendreth Dagger
    [3066367] = 10,     --Nzoth Dagger
    [853141] = 12,      --Grievous Gladiator's Shanker
    [1543574] = 8,      --Sargeras Sword
    [3482550] = 12,      --Revendreth 2H Sword
    [1340861] = 6,      --Fishing Artifact
    [2004589] = -8,     --Uldir Fist
    [1709375] = 12,      --Mop
    [1117094] = 8,      --Ashbringer
    [3566444] = 6,
    [1305009] = -8,    --Nightborne Shield
    [1269880] = 12,     --Nightborne Sword
    [3994706] = 32,
    [3621054] = 32,
    [3951950] = -8,
    [3621079] = 8,
    [3754266] = -4,
    [4051695] = 8,
};


--Development
--[[
local function Round4(num)
    return floor(num*1000 + 0.5)/1000
end

function Narci_SaveModelInfo(self)
    local model = self:GetParent().WeaponModel;
    local camX, camY, camZ = model:GetCameraPosition();
    local facing = model:GetFacing();
    local x, y, z = model:GetPosition();
    camX, camY, camZ = Round4(camX), Round4(camY), Round4(camZ);
    x, y, z = Round4(x), Round4(y), Round4(z);
    facing = Round4(facing);

    if not NarciDevToolOutput then
        NarciDevToolOutput = {};
    end
    if not NarciDevToolOutput.weaponInfo then
        NarciDevToolOutput.weaponInfo = {};
    end
    local db = NarciDevToolOutput.weaponInfo;
    db[model.itemID] = {model.itemID, facing, {camX, camY, camZ}, {x, y, z}};
    print("Model Info Saved!")
end

function Narci_LoadModelInfo(self)
    local model = self:GetParent().WeaponModel;
    local data = NarciDevToolOutput.weaponInfo[model.itemID];
    if data then
        model:SetFacing(data[2]);
        model:SetCameraPosition(unpack(data[3]));
        model:SetPosition(unpack(data[4]));
        print("Load Model Info")
    end
end
--]]

--------------------------
--Special
--[[
    115283 Light Hammer
    108736 Green Enchant Pick
    182161 Stone Hammer
    33604   Plague Shooter
    
    67108   Lord Crowley's Old Spectacles
    52487   Jeweler's Amber Monocle 52486 52485
    47163 47164
    63277   Mask    63278 105957
    79784 Heml


--]]
    
--[[
    /script local m=TestFrame.WeaponModel;m:SetItem(176455);m.itemID=176455;
/run TestFrame.WeaponModel:SetLight(true, false, 0.21, -0.49, -0.84, 1, 0.5, 0.5, 0.5, 1, 1, 1, 1)

function SetMountByDisplayID(displayID)
    local animID = 91;
    local isSelfMount = false;
    local disablePlayerMountPreview = false;

    local frame = MountJournal.MountDisplay;
	local mountActor = MountJournal.MountDisplay.ModelScene:GetActorByTag("unwrapped");
	if mountActor then
		mountActor:SetModelByCreatureDisplayID(displayID);
		mountActor:SetAnimationBlendOperation(0);
		mountActor:SetAnimation(0);
		frame.ModelScene:AttachPlayerToMount(mountActor, animID, isSelfMount, disablePlayerMountPreview);
	end
end
--]]