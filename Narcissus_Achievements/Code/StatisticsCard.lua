local _, addon = ...

local FloatingCard = addon.FloatingCard;
local IsBossCard = addon.IsBossCard;
local GetBossData = addon.GetBossData;
local IsRaid = addon.IsRaid;
local PinUtil = addon.PinUtil;
local GetCustomStatInfo = addon.GetCustomStatInfo;

local numCards = 0;
local cards = {};
local Controller = {};
local BossTooltip;
local MainFrame;

addon.StatCardController = Controller;

function Controller:GetTable()
    return cards;
end

function Controller:ReleaseAll()
    for _, card in pairs(cards) do
        card:ClearAllPoints();
        card:Hide();
    end
end

function Controller:Accquire(index)
    if not cards[index] then
        local container = Narci_AchievementFrame.AchievementCardFrame.ScrollChild;
        cards[index] = CreateFrame("Button", nil, container, "NarciStatGenericCardTemplate");
        if index == 1 then
            cards[index]:SetPoint("TOP", container, "TOP", 0, -18);
            BossTooltip = container:GetParent().BossTooltip;
        else
            cards[index]:SetPoint("TOP", cards[index - 1], "BOTTOM", 0, -4);
        end
        cards[index]:UseBossLayout(true);
    end
    return cards[index];
end

function Controller:HideRest(fromIndex)
    for i = fromIndex, #cards do
        cards[i]:Hide();
    end
end

function Controller:UpdateList()
    for i = 1, numCards do
        if cards[i]:IsShown() then
            cards[i]:Refresh();
        else
            break
        end
    end
end

local IS_DARK_THEME = true;
local TEX_Y_OFFSET = 0;
local SHOW_NAME_BACKGROUND = false;
local TEX_PREFIX = "Interface\\AddOns\\Narcissus_Achievements\\ART\\DarkWood\\";
local ZERO_TEXT = "|cff808080--|r";

function Controller:SetTheme(themeID)
    if themeID == 3 then
        IS_DARK_THEME = true;
        TEX_Y_OFFSET = 0;
        SHOW_NAME_BACKGROUND = true;
        TEX_PREFIX = "Interface\\AddOns\\Narcissus_Achievements\\ART\\Flat\\";
    elseif themeID == 2 then
        IS_DARK_THEME = false;
        TEX_Y_OFFSET = 0;
        SHOW_NAME_BACKGROUND = false;
        TEX_PREFIX = "Interface\\AddOns\\Narcissus_Achievements\\ART\\Classic\\";
    else
        IS_DARK_THEME = true;
        TEX_Y_OFFSET = -2;
        SHOW_NAME_BACKGROUND = false;
        TEX_PREFIX = "Interface\\AddOns\\Narcissus_Achievements\\ART\\DarkWood\\";
    end
    if IS_DARK_THEME then
        ZERO_TEXT = "|cff808080--|r";
    else
        ZERO_TEXT = "--";
    end

    for i = 1, numCards do
        if cards[i] then
            cards[i]:UpdateTheme();
        else
            break
        end
    end
end

--Animation
local pi = math.pi;
local sin = math.sin;
local pow = math.pow;

local function outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

function Controller:PlayAnimation()
    local DURATION = 0.4;
    local f = self.updateFrame;
    if not f then
        f = CreateFrame("Frame");
        f:Hide();
        f.t = 0;
        self.updateFrame = f;
        f:SetScript("OnUpdate", function(a, elapsed)
            f.t = f.t + elapsed;
            local oT;
            local offset, alpha, scale;
            for i = 1, f.numCards do
                oT = f.t - 0.05 * (i - 1);
                if oT > 0 then
                    if oT < DURATION then
                        offset = outQuart(oT, 36, 0, DURATION);
                        scale = outQuart(oT, 1.2, 1, DURATION);
                        alpha = oT/0.25;
                        if alpha > 1 then
                            alpha = 1;
                        end
                    else
                        offset = 0;
                        alpha = 1;
                        scale = 1;
                    end
                    cards[i].Background:SetPoint("TOP", cards[i], "TOP", 0, offset);
                    cards[i].Background:SetScale(scale);
                    cards[i].Mask:SetScale(scale);
                    cards[i]:SetAlpha(alpha);
                else
                    cards[i]:SetAlpha(0);
                end
            end
            if f.t >= f.fullDuration then
                f:Hide();
            end
        end);
    end
    f:Hide();
    f.numCards = numCards;
    f.fullDuration = numCards * DURATION;
    f.t = 0;
    f:Show();
end

-----------------------------------------------------------------------
local GetAchievementInfo = GetAchievementInfo;
local GetStatistic = GetStatistic;
local EJ_GetInstanceInfo = EJ_GetInstanceInfo;
local DataProvider = {};

local difficultyTypes = addon.difficultyTypes;



local KILLS = " [Kk]ills";  --Remove the words "kills" leave the boss's name.
local BRACKET_CONTENT = " %(.+%)";

do
    local locale = GetLocale()
    if locale == "zhCN" then
        BRACKET_CONTENT = "（.+）";
        KILLS = "消灭";
    elseif locale == "zhTW" then
        BRACKET_CONTENT = "%(.+%)";
        KILLS = "擊殺數";
    elseif locale == "deDE" then
        KILLS = "Siege über";
    end
end

local function FormatZero(value)
    if value then
        value = tonumber(value);
        if value and value > 0 then
            return value;
        else
            return ZERO_TEXT
        end
    else
        return ZERO_TEXT
    end
end

local function GetBossName(achievementID, instanceID)
    local _, name = GetAchievementInfo(achievementID);
    if instanceID then
        if not IsRaid(instanceID) then
            name = name .. " - "..DataProvider:GetInstanceName(instanceID)    --Add instance name as a suffix
        end
        name = string.gsub(name, BRACKET_CONTENT, "");
        name = string.gsub(name, KILLS, "");
    else
        name = string.gsub(name, KILLS, "");
    end
    return name
end

function DataProvider:GetInstanceName(instanceID)
    --https://wow.tools/dbc/?dbc=journalinstance&build=9.2.0.42423#page=1
    if not self.instanceNames then
        self.instanceNames = {};
    end

    if self.instanceNames[instanceID] then
        return self.instanceNames[instanceID]
    else
        local name = EJ_GetInstanceInfo(instanceID);
        if name and name ~= "" then
            self.instanceNames[instanceID] = name;
        end
        return name or "";
    end
end

NarciStatGenericCardMixin = {};

function NarciStatGenericCardMixin:OnLoad()
    tinsert(cards, self);
    self.isBoss = true;
    numCards = numCards + 1;
    self:RegisterForDrag("LeftButton");
end

function NarciStatGenericCardMixin:OnMouseDown()
    self.AnimPushed:Stop();
    self.AnimPushed.hold:SetDuration(20);
    self.AnimPushed:Play();
end

function NarciStatGenericCardMixin:OnMouseUp()
    self.AnimPushed.hold:SetDuration(0);
end

function NarciStatGenericCardMixin:OnDragStart()
    self.AnimPushed:Stop();
    self:Hide();

    local card = FloatingCard:CreateFromCard(self, 2);
end

function NarciStatGenericCardMixin:OnClick(button)
    if not MainFrame then
        MainFrame = Narci_AchievementFrame;
    end
    if IsModifiedClick("QUESTWATCHTOGGLE") then
        local pinResult = PinUtil:Toggle(self.id);
        if pinResult == 1 then
            self.TrackIcon:Show();
        else
            self.TrackIcon:Hide();
            if pinResult == 2 then
                --Can't pin more
                print("Capped")
            end
        end
        MainFrame:UpdatePinCount();
    else
        if button == "LeftButton" then
            MainFrame:InspectCard(self, true);
        end
    end
end

function NarciStatGenericCardMixin:SetStat(id, index)
    local value = GetStatistic(id, index);
    --value = id  --testing
    local _, name = GetAchievementInfo(id, index);
    self.Name:SetText(name);
    if not value or value == "--" or value == 0 then
        value = ZERO_TEXT;
    end
    self.ValueText:SetText(value);
    if not self.isFloatingCard then
        self.TrackIcon:SetShown(PinUtil:IsPinned(id));
    end
end

function NarciStatGenericCardMixin:SetBoss(bossIDs, difficultyType, icon, instanceID)
    self.Icon:SetTexture(icon);
    local id = bossIDs[1];
    self.Name:SetText(GetBossName(id, instanceID, difficultyType));
    self.instanceID = instanceID;
    if difficultyType ~= self.difficultyType then
        self.difficultyType = difficultyType;
        for i = 1, 4 do
            self.BossFrame["Value"..i]:Hide();
            self.BossFrame["Cate"..i]:Hide();
            self.BossFrame["Cate"..i]:SetText(difficultyTypes[difficultyType][i]);
        end
    end

    local numDifficuties = #bossIDs;
    local HEADER_WIDTH = 90;
    local HEADER_GAP = -8;
    local offset0 = -0.5 * (numDifficuties * HEADER_WIDTH + (numDifficuties - 1) * HEADER_GAP);
    local value;
    for i = 1, numDifficuties do
        value = GetStatistic(bossIDs[i]);
        self.BossFrame["Value"..i]:SetText( FormatZero(value) );
        self.BossFrame["Value"..i]:Show();
        self.BossFrame["Cate"..i]:Show();
        self.BossFrame["Cate"..i]:SetPoint("TOPLEFT", self.BossFrame, "TOP", offset0 + (HEADER_WIDTH + HEADER_GAP) * (i - 1), 0);
    end

    if not self.isFloatingCard then
        self.TrackIcon:SetShown(PinUtil:IsPinned(id));
    end
end

function NarciStatGenericCardMixin:SetCustomStat(statID)
    local name, value = GetCustomStatInfo(statID);
    self.Name:SetText(name);
    self.ValueText:SetText(value);
    if not self.isFloatingCard then
        self.TrackIcon:SetShown(PinUtil:IsPinned(statID));
    end
end

function NarciStatGenericCardMixin:SetHeader(headerID)
    self.Name:SetText(DataProvider:GetInstanceName(-headerID));
    self.NameBackground:SetWidth(self.Name:GetStringWidth() + 16);
end

function NarciStatGenericCardMixin:UseNormalLayout(forcedUpdate)
    if forcedUpdate or self.isBoss or self.isHeader then
        self.isBoss = false;
        self.isHeader = false;
        self.instanceID = nil;
        self.Name:ClearAllPoints();
        self.Name:SetPoint("CENTER", self.Background, "TOP", 0, -28);
        self.Name:SetWidth(462);
        self.ValueText:Show();
        self.Mask:SetTexture(TEX_PREFIX.."StatCardNormalMask");
        self.Background:SetTexture(TEX_PREFIX.."StatCardNormal");
        self.Background:SetTexCoord(0.05078125, 0.94921875, 0, 1);
        self.Background:SetSize(518, 72);
        self.Mask:SetSize(518, 72);
        self.Shadow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 12, -12);
        self:SetSize(518, 72);
        self.TrackIcon:ClearAllPoints();

        self.BossFrame:Hide();
        self.Icon:Hide();
        self.Shadow:Show();
        self.NameBackground:Hide();
        self:Enable();
        self:EnableMouse(true);

        if IS_DARK_THEME then
            self.Name:SetTextColor(0.72, 0.72, 0.72);
            self.Name:SetShadowOffset(0, 2);
            self.Name:SetShadowColor(0, 0, 0);
            self.ValueText:SetTextColor(0.8, 0.8, 0.8);
            self.ValueText:SetShadowOffset(0, 2);
            self.ValueText:SetShadowColor(0, 0, 0);
            self.ValueText:SetPoint("CENTER", self.Background, "BOTTOM", 0, 23);
        else
            self.Name:SetTextColor(0, 0, 0);
            self.Name:SetShadowOffset(0, -2);
            self.Name:SetShadowColor(0.9, 0.82, 0.58);
            self.ValueText:SetTextColor(0, 0, 0);
            self.ValueText:SetShadowOffset(0, -2);
            self.ValueText:SetShadowColor(0.9, 0.82, 0.58);
            self.ValueText:SetPoint("CENTER", self.Background, "BOTTOM", 0, 27);
        end
        self.TrackIcon:SetPoint("CENTER", self.Background, "LEFT", 21, TEX_Y_OFFSET);
    end
end

function NarciStatGenericCardMixin:UseBossLayout(forcedUpdate)
    if forcedUpdate or not self.isBoss or self.isHeader then
        self.isBoss = true;
        self.isHeader = false;
        self.Name:ClearAllPoints();
        self.Name:SetPoint("CENTER", self.Background, "TOP", 0, -26);
        self.Name:SetWidth(364);
        self.ValueText:Hide();
        self.Mask:SetTexture(TEX_PREFIX.."StatCardBossMask");
        self.Background:SetTexture(TEX_PREFIX.."StatCardBoss");
        self.Background:SetTexCoord(0.05078125, 0.94921875, 0, 0.65234375);
        self.Shadow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 12, -16);
        self.Background:SetSize(518, 94);
        self.Mask:SetSize(518, 94);
        self:SetSize(518, 94);
        self.TrackIcon:ClearAllPoints();
        self.TrackIcon:SetPoint("CENTER", self.Background, "LEFT", 84, 20);
        self.BossFrame:Show();
        self.Icon:Show();
        self.Shadow:Show();
        self.NameBackground:Hide();
        self:Enable();
        self:EnableMouse(true);

        if IS_DARK_THEME then
            self.Name:SetTextColor(0.8, 0.8, 0.8);
            self.Name:SetShadowOffset(0, 2);
            self.Name:SetShadowColor(0, 0, 0);
            for i = 1, 4 do
                self.BossFrame["Cate"..i]:SetTextColor(0.5, 0.5, 0.5);
                self.BossFrame["Cate"..i]:SetShadowOffset(0, 2);
                self.BossFrame["Cate"..i]:SetShadowColor(0, 0, 0, 1);
                self.BossFrame["Value"..i]:SetTextColor(0.9, 0.82, 0.58);
                self.BossFrame["Value"..i]:SetShadowOffset(0, 2);
                self.BossFrame["Value"..i]:SetShadowColor(0, 0, 0, 1);
            end
        else
            self.Name:SetTextColor(1, 1, 1);
            self.Name:SetShadowOffset(0, 2);
            self.Name:SetShadowColor(0, 0, 0);
            for i = 1, 4 do
                self.BossFrame["Cate"..i]:SetTextColor(0, 0, 0);
                self.BossFrame["Cate"..i]:SetShadowOffset(0, -2);
                self.BossFrame["Cate"..i]:SetShadowColor(0.894, 0.761, 0.408, 1);
                self.BossFrame["Value"..i]:SetTextColor(0, 0, 0);
                self.BossFrame["Value"..i]:SetShadowOffset(0, -2);
                self.BossFrame["Value"..i]:SetShadowColor(0.95, 0.90, 0.6, 1);
            end
        end
    end
end

function NarciStatGenericCardMixin:UseHeaderLayout(forcedUpdate)
    if forcedUpdate or not self.isHeader then
        self.isHeader = true;
        self.instanceID = nil;
        self.Name:ClearAllPoints();
        self.Name:SetPoint("CENTER", self, "CENTER", 0, -6);
        self.Name:SetWidth(470);
        self.ValueText:Hide();
        self.Mask:SetTexture(TEX_PREFIX.."RaidBreakMask");
        self.Background:SetTexture(TEX_PREFIX.."RaidBreak");
        self.Background:SetTexCoord(0, 1, 0, 1);
        self.Background:SetSize(576, 72);
        self.Mask:SetSize(576, 72);
        self:SetSize(518, 48);
        self.BossFrame:Hide();
        self.Icon:Hide();
        self.Shadow:Hide();
        self.TrackIcon:Hide();
        self:Disable();
        self:EnableMouse(false);
        self.Name:SetTextColor(0.6, 0.6, 0.6);
        self.NameBackground:SetShown(SHOW_NAME_BACKGROUND);
    end
end

function NarciStatGenericCardMixin:SetData(achievementID, forcedUpdate)
    if not forcedUpdate and achievementID == self.id then return end;

    self.id = achievementID;
    if not achievementID then
        return
    end

    if achievementID < 0 then
        self:UseHeaderLayout(forcedUpdate);
        self:SetHeader(achievementID);
    elseif achievementID > 12080000 then
        self:UseNormalLayout(forcedUpdate);
        self:SetCustomStat(achievementID);
    else
        if IsBossCard(achievementID) then
            self:UseBossLayout(forcedUpdate);
            self:SetBoss(unpack( GetBossData(achievementID) ));
        else
            self:UseNormalLayout(forcedUpdate);
            self:SetStat(achievementID);
        end
    end

    --self.ValueText:SetText(achievementID);  --For Debug Display AchievementID
end

function NarciStatGenericCardMixin:Refresh()
    if self.id and self:IsShown() then
        self:SetData(self.id, true);
    end
end


function NarciStatGenericCardMixin:UpdateTheme()
    self:SetData(self.id, true);
end

function NarciStatGenericCardMixin:OnEnter()
    --[[
    if self.instanceID and IsRaid(self.instanceID) then
        if self.instanceID ~= BossTooltip.BossTooltip then
            BossTooltip.Text:SetText( DataProvider:GetInstanceName(self.instanceID) );
        end
        BossTooltip:Show();
    else
        BossTooltip:Hide();
    end
    --]]
end

function NarciStatGenericCardMixin:OnLeave()
    --BossTooltip:Hide();
end


--/run NarciStatGenericCardTemplate:SetData(14078)    --15160
--/run NarciStatGenericCardMixin:SetBoss(15173, id2, id3, icon)