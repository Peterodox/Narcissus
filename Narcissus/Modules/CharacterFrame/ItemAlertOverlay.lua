local _, addon = ...

local GetSwipePosition = addon.SwipeTrailFunctions.Polygon;     --defined in Widgets/ClockFrame.lua     --arg: radius, progress, numSides

local tremove = table.remove;
local tinsert = table.insert;

local GetSpecialization = GetSpecialization;
local GetSpecializationInfo = GetSpecializationInfo;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;

local SLOT_PRIORITY = {
    --[slotID] = 1,  --(1 high priority, Show red glow) (0 low just a text says no enchant) (nil/false, don't show alert)
    [1] = false,    --Head
    [2] = false,    --Neck
    [3] = false,    --Shoulders
    [5] = false,    --Chest
    [6] = false,    --Waist
    [7] = false,    --Legs
    [8] = false,    --Feet
    [9] = false,    --Wrist
    [10] = false,   --Hands
    [11] = false,   --Finger1
    [12] = false,   --Finger2
    [15] = false,   --Back
    [16] = false,   --Main Hand
    [17] = false,   --Off Hand
};

local SLOT_PRIORITY_STR = {
    --primary stats: Strengh
    [5] = 1,
    [6] = 0,
    [7] = 1,
    [8] = 0,
    [9] = 0,
    [11] = 1,
    [12] = 1,
    [15] = 0,
    [16] = 1,
    [17] = 1,
};

local SLOT_PRIORITY_AGI = {
    --primary stats: Agility
    [5] = 1,
    [6] = 0,
    [7] = 1,
    [8] = 0,
    [9] = 0,
    [11] = 1,
    [12] = 1,
    [15] = 0,
    [16] = 1,
    [17] = 1,
};

local SLOT_PRIORITY_INT = {
    --primary stats: Intellect
    [5] = 1,
    [6] = 0,
    [7] = 1,
    [8] = 0,
    [9] = 0,
    [11] = 1,
    [12] = 1,
    [15] = 0,
    [16] = 1,
    [17] = 1,
};

local SLOT_PRIORITY_TWW_S1 = {
    [5] = 1,    --Chest
    [7] = 1,    --Legs
    [8] = 0,    --Feet
    [9] = 0,    --Wrist
    [11] = 1,   --Finger1
    [12] = 1,   --Finger2
    [15] = 0,   --Back
    [16] = 1,   --Main Hand
    [17] = 1,   --Off Hand
};
SLOT_PRIORITY = SLOT_PRIORITY_TWW_S1;

local NO_FLASH_ITEMS = {
    --Disable flash for some items with special border art.
    [203460] = true,
    [228411] = true,
};

local SharedUpdateFrame;

local function AlertOverlay_Clear(self)
    self:Hide();
    self:ClearAllPoints();
    self.t = 0;
end

local function AlertOverlay_Setup(self, alpha, x, y)
    self.SwipeMask:SetPoint("CENTER", x, y);
    self.BlinkTexture:SetAlpha(alpha);
end

local SlotButtonOverlayUtil = {};
addon.SlotButtonOverlayUtil = SlotButtonOverlayUtil;

SlotButtonOverlayUtil.enabled = true;
SlotButtonOverlayUtil.pool = {};
SlotButtonOverlayUtil.idle = {};
SlotButtonOverlayUtil.used = {};
SlotButtonOverlayUtil.numTotal = 0;
SlotButtonOverlayUtil.numUsed = 0;

local function SharedUpdateFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > self.d then
        self.t = self.t - self.d;
    end
    local p = self.t/self.d;

    local x, y = GetSwipePosition(30, p, 6);

    local alpha;
    if p < 0.5 then
        p =  p * 2;
        alpha = 0.2 * (1-p) + 1*p
    else
        p = (p - 0.5) * 2
        alpha = 1 * (1-p) + 0.2*p
    end

    for i = 1, SlotButtonOverlayUtil.numUsed do
        AlertOverlay_Setup(SlotButtonOverlayUtil.used[i], alpha, x, y);
    end
end

function SlotButtonOverlayUtil:GetOverlay()
    if not SharedUpdateFrame then
        SharedUpdateFrame = CreateFrame("Frame", nil, Narci_Character);
        SharedUpdateFrame.t = 0;
        SharedUpdateFrame.d = 4;
        SharedUpdateFrame:SetScript("OnUpdate", SharedUpdateFrame_OnUpdate);
    end
    SharedUpdateFrame:Show();

    local f = tremove(self.idle);
    if not f then
        f = CreateFrame("Frame", nil, Narci_Character, "NarciSlotButtonAlertOverlayTemplate")
        self.numTotal = self.numTotal + 1;
        self.pool[self.numTotal] = f;
    end
    tinsert(self.used, f);
    self.numUsed = self.numUsed + 1;
    f:Show();
    return f
end

function SlotButtonOverlayUtil:IsSlotValidForEnchant(slotID, itemID)
    if SLOT_PRIORITY[slotID] then
        if itemID and (slotID == 16 or slotID == 17) then
            local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID);
            if (classID ~= 2) or (subclassID == 14 or subclassID == 20) then
                return false  --skip shields and holdable off-hand items
            end
        end
        return true
    else
        return false
    end
end

function SlotButtonOverlayUtil:ShowEnchantAlert(slotButton, slotID, itemID)
    if self.enabled and itemID and not NO_FLASH_ITEMS[itemID] then
        if SLOT_PRIORITY[slotID] == 1 then  --self:IsSlotValidForEnchant(slotID, itemID) - already run
            local f = slotButton.slotOverlay or self:GetOverlay();
            f:ClearAllPoints();
            f:SetPoint("CENTER", slotButton, "CENTER", 0, 0);
            f:SetFrameStrata("HIGH");

            slotButton.slotOverlay = f;
            f.parent = slotButton;
        end
    end
end

function SlotButtonOverlayUtil:ClearOverlay(slotButton)
    if slotButton.slotOverlay then
        AlertOverlay_Clear(slotButton.slotOverlay);
        for i, overlay in ipairs(self.used) do
            if overlay == slotButton.slotOverlay then
                local f = tremove(self.used, i);
                tinsert(self.idle, f);
                self.numUsed = self.numUsed - 1;
                break
            end
        end
        slotButton.slotOverlay = nil;
        if self.numUsed == 0 and SharedUpdateFrame then
            SharedUpdateFrame:Hide();
        end
    end
end

function SlotButtonOverlayUtil:ClearAll()
    local f;
    for i = 1, self.numTotal do
        f = self.pool[i];
        f:Hide();
        f:ClearAllPoints();
        if f.parent then
            f.parent.slotOverlay = nil
        end
        self.idle[i] = f;
    end

    self.used = {};
    self.numUsed = 0;

    if SharedUpdateFrame then
        SharedUpdateFrame:Hide();
    end
end

function SlotButtonOverlayUtil:SetEnabled(state)
    self.enabled = state;
    if state then

    else
        self:ClearAll();
    end
end

function SlotButtonOverlayUtil:UpdateData()
    --[[
    local specID = GetSpecialization() or 1;

    local _, _, _, _, _, primaryStat = GetSpecializationInfo(specID);   --primaryStat may not be correct after the first PLAYER_ENTERING_WORLD
    primaryStat = primaryStat or 1;

    if primaryStat == 1 then
        SLOT_PRIORITY = SLOT_PRIORITY_STR;
    elseif primaryStat == 2 then
        SLOT_PRIORITY = SLOT_PRIORITY_AGI;
    else
        SLOT_PRIORITY = SLOT_PRIORITY_INT;
    end
    --]]
end