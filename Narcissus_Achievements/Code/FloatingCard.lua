local _, addon = ...;

local FadeFrame = NarciFadeUI.Fade;
local FloatingCard = CreateFrame("Frame");  --"FloatingCardContainer"
addon.FloatingCard = FloatingCard;

local MainFrame;
local positionFrame;
local hotkeyFrame;


local function MoveFloatingCard(card)
    positionFrame:Hide();
    local uiScale = card:GetScale();
    positionFrame.object = card;
    positionFrame.uiScale = uiScale;
    local cursorX, cursorY = GetCursorPosition();
    cursorX, cursorY = cursorX/uiScale, cursorY/uiScale;
    local x0, y0 = card:GetCenter();
    positionFrame.offsetX = cursorX - x0;
    positionFrame.offsetY = cursorY - y0;
    positionFrame:Show();
end

local function FloatingCard_OnDragStop(self)
    positionFrame:Hide();
end

local function FloatingCard_OnClick(self, button)
    if button == "RightButton" then
        self:Hide();
    end
end

local function FloatingCard_OnEnter(self)
    hotkeyFrame:ClearAllPoints();
    hotkeyFrame:SetParent(self);
    hotkeyFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -8, -4);
    hotkeyFrame:ShowTooltip();
end

local function FloatingCard_OnLeave(self)
    hotkeyFrame:JustHide();
end



function FloatingCard:Init()
    MainFrame = Narci_AchievementFrame;
    positionFrame = CreateFrame("Frame");

    positionFrame.screenMidPoint = WorldFrame:GetWidth()/2;
    positionFrame:Hide();
    positionFrame:SetScript("OnUpdate", function(self)
        local cursorX, cursorY = GetCursorPosition();
        local uiScale = self.uiScale;
        cursorX, cursorY = cursorX/uiScale, cursorY/uiScale;
        local compensatedX = cursorX - self.offsetX;
        local midPoint = self.screenMidPoint/uiScale;
        if (compensatedX > midPoint - 40) and (compensatedX < midPoint + 40) then
            compensatedX = midPoint;
        end
        if self.object then
            self.object:SetPoint("CENTER", UIParent, "BOTTOMLEFT", compensatedX, cursorY - self.offsetY);
        else
            self:Hide();
        end
    end);

    hotkeyFrame = CreateFrame("Frame", nil, self, "NarciHotkeyNotificationTemplate");
    hotkeyFrame:SetKey(nil, "RightButton", Narci.L["Remove"]);
    hotkeyFrame:SetIgnoreParentScale(true);
    hotkeyFrame:SetScale(0.8);
    hotkeyFrame:Hide();

    self.Init = nil;
end

function FloatingCard:SetTheme(index)
    self.themeIndex = index;
    if self.achvCards then
        for _, card in pairs(self.achvCards) do
            card:UpdateTheme(index);
        end
    end
    if self.statCards then
        for _, card in pairs(self.statCards) do
            card:UpdateTheme(index);
        end
    end
end

function FloatingCard:Acquire(cardType)
    if self.Init then
        self:Init();
    end
    self:RegisterEvent("GLOBAL_MOUSE_UP");
    local template;
    local cardPool;
    local isStat = cardType == 2;
    if isStat then
        template = "NarciStatFloatingCardTemplate";
        if not self.statCards then
            self.statCards = {};
        end
        cardPool = self.statCards;
    else
        template = "NarciAchievementFloatingCardTemplate";
        if not self.achvCards then
            self.achvCards = {};
        end
        cardPool = self.achvCards;
    end
    local card;
    for i = 1, #cardPool + 1 do
        card = cardPool[i];
        if card and (not card:IsShown()) then
            break
        end
        if not card then
            card = CreateFrame("Button", nil, self, template);
            card:SetClampedToScreen(true);
            card.index = i;
            card:SetFrameStrata("DIALOG");
            card:SetFrameLevel(i);
            card:SetScript("OnDragStart", MoveFloatingCard);
            card:SetScript("OnDragStop", FloatingCard_OnDragStop);
            card:SetScript("OnClick", FloatingCard_OnClick);
            card:SetScript("OnEnter", FloatingCard_OnEnter);
            card:SetScript("OnLeave", FloatingCard_OnLeave);
            card:RegisterForDrag("LeftButton");
            card.isFloatingCard = true;   --Hide Pin
            if isStat then
                card.isHeader = true;   --force to refresh layout
            end
            tinsert(cardPool, card);
            break
        end
    end

    self.pendingCard = card;
    return card
end

function FloatingCard:CreateFromCard(oldCard, cardType)
    self.parentCard = oldCard;
    local newCard = self:Acquire(cardType);
    newCard.id = oldCard.id;

    local uiScale = MainFrame:GetEffectiveScale();
    newCard:SetScale(uiScale);
    newCard.uiScale = uiScale;

    
    positionFrame.object = newCard;
    positionFrame.uiScale = uiScale;

    local cursorX, cursorY = GetCursorPosition();
    cursorX, cursorY = cursorX/uiScale, cursorY/uiScale;
    local x0, y0 = oldCard:GetCenter();
    positionFrame.offsetX = cursorX - x0;
    positionFrame.offsetY = cursorY - y0;
    positionFrame:Show();

    newCard:UpdateTheme();
    newCard:ClearAllPoints();
    newCard:SetAlpha(1);
    newCard:Show();
    return newCard;
end

local function IsCardInsideMainFrame(card)
    local left = MainFrame:GetLeft() or 0;
    local right = MainFrame:GetRight();
    local top = MainFrame:GetTop();
    local bottom = MainFrame:GetBottom();
    local x, y = card:GetCenter();
    return (x > left and x < right and y < top and y > bottom)
end

function FloatingCard:PostCreate()
    if self.parentCard then
        self.parentCard:SetAlpha(0);
        FadeFrame(self.parentCard, 0.5, 1);
    end

    local pendingCard = self.pendingCard;
    if pendingCard then
        if MainFrame:IsMouseOver() and IsCardInsideMainFrame(pendingCard) then
            pendingCard:Hide();
            pendingCard = nil;
        else
            FloatingCard_OnDragStop(pendingCard);
        end
    end
end

function FloatingCard:OnEvent(event, ...)
    if event == "GLOBAL_MOUSE_UP" then
        self:UnregisterEvent(event);
        self:PostCreate();
    end
end

function FloatingCard:GetTotal()
    local total = 0;
    if self.achvCards then
        total = total + #self.achvCards;
    end
    if self.statCards then
        total = total + #self.statCards;
    end
    return total
end

FloatingCard:SetScript("OnEvent", function(frame, event, ...)
    frame:OnEvent(event, ...);
end);