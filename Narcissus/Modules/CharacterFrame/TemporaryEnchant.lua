local GetTemporaryItemBuff = NarciAPI.GetTemporaryItemBuff;
local GetEnchantDataByEnchantID = NarciAPI.GetEnchantDataByEnchantID;
local ConvertTextToSeconds = NarciAPI.ConvertTextToSeconds;
local GetItemIcon = C_Item.GetItemIconByID;

local SHOW_SECONDS_THRESHOLD = 60 * 60;     --Most boss fights end within 15 min

--[[
local function ConvertTextToSeconds(durationText)
    local hours = string.match(durationText, "(%d+) hours?");
    if hours then
        return tonumber(hours) * 3600
    end
    local minutes = string.match(durationText, "(%d+) min");
    if minutes then
        return tonumber(minutes) * 60
    end
    local seconds = string.match(durationText, "(%d+) sec");
    if seconds then
        return tonumber(seconds)
    end
    return 0
end
--]]

local function FormatSeconds(sec)
    if sec > 4500 then
        return string.format("%d hr", math.floor(sec/3600 + 0.5));
    elseif sec > SHOW_SECONDS_THRESHOLD then
        return string.format("%d min", math.floor(sec/60 + 0.5));
    else
        local minutes = math.floor(sec/60);
        local seconds = math.floor(sec - 60 * minutes + 0.5);
        if seconds < 10 then
            seconds = "0"..seconds;
        end
        return minutes..":"..seconds;
    end
end



local function InternalCountdown_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    self.secLeft = self.secLeft - elapsed;
    if self.secLeft <= 0 then
        self:SetExpired();
    else
        if self.t >= 1 then
            self.t = self.t - 1;    --modf?
            self.BuffDuration:SetText(FormatSeconds(self.secLeft));
        end
    end
end

local function CalculateDuration_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 1 then
        self.t = self.t - 1;
        local buffText, durationText;
        if self.invID then
            buffText, durationText = GetTemporaryItemBuff(self.invID);
        elseif self.bagID then
            buffText, durationText = GetTemporaryItemBuff(self.bagID, self.slotID);
        end
        local seconds = ConvertTextToSeconds(durationText);
        if seconds ~= self.lastSeconds then
            if seconds > 0 then
                self.secLeft = seconds;
                self:SetScript("OnUpdate", InternalCountdown_OnUpdate);
                self.isActive = true;
            end
        end
    end
end

NarciTempEnchantIndicatorMixin = {};

function NarciTempEnchantIndicatorMixin:OnLoad()
    self:SetIconSize(24);
    self:OnLeave();
    self:RegisterForDrag("LeftButton");
end

function NarciTempEnchantIndicatorMixin:OnEnter()
    self.BuffDuration:Show();
end

function NarciTempEnchantIndicatorMixin:OnLeave()
    self.BuffDuration:Hide();
end

function NarciTempEnchantIndicatorMixin:OnClick()

end

function NarciTempEnchantIndicatorMixin:SetExpired()
    self:SetScript("OnUpdate", nil);
    self.Icon:SetDesaturation(1);
    self.BuffDuration:SetText("--:--");
    self.isActive = false;
end

function NarciTempEnchantIndicatorMixin:SetInventoryItem(invID)
    self.invID = invID;
    self.bagID, self.slotID = nil, nil;

    local buffText, durationText = GetTemporaryItemBuff(invID);
    local isWeapon = (invID == 16 or invID == 17);
    local iconFileID = GetInventoryItemTexture("player", invID);
    local playGlow = false;
    if isWeapon then
        local hasEnchant, expiration, charges, enchantID = select(4 * (invID - 16) + 1, GetWeaponEnchantInfo());      --RETURNS_PER_ITEM = 4  (BuffFrame.lua)
        if hasEnchant then
            local secLeft = expiration/1000;
            self.t = math.modf(secLeft);
            if self.secLeft then
                if math.abs(secLeft - self.secLeft) > 2 then
                    playGlow = true;
                end
            end
            self.secLeft = secLeft;
            self:SetScript("OnUpdate", InternalCountdown_OnUpdate);
            self.isActive = true;
            self.Icon:SetDesaturation(0);
            if enchantID then
                local enchantData = GetEnchantDataByEnchantID(enchantID);
                if enchantData then
                    iconFileID = GetItemIcon(enchantData[4]) or iconFileID;
                end
            end
        else
            self:SetExpired();
        end
    else
        if durationText then
            self.t = 0;
            self.lastSeconds = ConvertTextToSeconds(durationText);
            self:SetScript("OnUpdate", CalculateDuration_OnUpdate);
            self.isActive = true;
            iconFileID = 3528447;
        end
    end

    if durationText then
        self.BuffDuration:SetText(durationText);
    end
    self.Icon:SetTexture(iconFileID);
    if playGlow then
        self:Glow();
    end
    return (buffText and buffText ~= "")
end

function NarciTempEnchantIndicatorMixin:SetBagItem(bagID, slotID)
    self.invID = nil;
    self.bagID, self.slotID = bagID, slotID;

    local buffText, durationText = GetTemporaryItemBuff(bagID, slotID);
end

function NarciTempEnchantIndicatorMixin:Refresh()
    if self.invID then
        self:SetInventoryItem(self.invID);
    elseif self.bagID then
        self:SetBagItem(self.bagID, self.slotID);
    end
end

function NarciTempEnchantIndicatorMixin:Clear()
    self.invID, self.bagID, self.SlotID = nil, nil, nil;
    self:SetScript("OnUpdate", nil);
end


function NarciTempEnchantIndicatorMixin:SetIconSize(a)
    self:SetSize(a, a);
    self.Icon:SetSize(a, a);
    self.Ring:SetSize(2*a, 2*a);
end

function NarciTempEnchantIndicatorMixin:OnHide()
    self:Hide();
    self:SetScript("OnUpdate", nil);
    self.Highlight:Hide();
    self.secLeft = nil;
    self.lastSeconds = nil;
    self.isActive = false;
end

function NarciTempEnchantIndicatorMixin:Glow()
    if self.Highlight then
        self.Highlight.Glow:Stop();
        self.Highlight.Glow:Play();
        self.Highlight:Show();
    end
end

--/run NarciTemporaryEnchancementIndicatorTemplate:SetInventoryItem(16)


function NarciTempEnchantIndicatorMixin:OnClick()
    self:SetInventoryItem(16);
end

function NarciTempEnchantIndicatorMixin:OnDragStart()
    self:StartMoving();
end

function NarciTempEnchantIndicatorMixin:OnDragStop()
    self:StopMovingOrSizing();
end




NarciTempEnchantIndicatorController = {};
NarciTempEnchantIndicatorController.pool = {};

function NarciTempEnchantIndicatorController:AccquireFrame()
    for _, frame in pairs(self.pool) do
        if not frame.isActive then
            return frame
        end
    end
    local frame = CreateFrame("Frame", nil, UIParent, "NarciSimpleTempEnchantIndicatorTemplate");
    frame.isActive = true;
    tinsert(self.pool, frame);
    return frame
end

function NarciTempEnchantIndicatorController:InitFromSlotButton(slotButton)
    local invID = slotButton.slotID;
    local buffText, durationText = GetTemporaryItemBuff(invID);
    if buffText and durationText then
        local frame = slotButton.TempEnchantIndicator;
        if not frame then
            frame = self:AccquireFrame();
        end
        if frame:GetParent() ~= slotButton then
            frame:GetParent().TempEnchantIndicator = nil;
        end
        slotButton.TempEnchantIndicator = frame;
        frame:SetParent(slotButton);
        frame:SetInventoryItem(invID);
        local width, height = frame.BuffDuration:GetSize();
        frame:SetSize(width + 16, height);
        frame:Show();
        return true
    else
        if slotButton.TempEnchantIndicator then
            slotButton.TempEnchantIndicator:Hide();
        end
    end
end

function NarciTempEnchantIndicatorController:GetTotal()
    local total = 0;
    for _, frame in pairs(self.pool) do
        total = total + 1;
    end
    return total
end