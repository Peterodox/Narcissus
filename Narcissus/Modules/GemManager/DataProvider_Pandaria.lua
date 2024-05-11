local _, addon = ...
local L = Narci.L;
local Gemma = addon.Gemma;
local AtlasUtil = Gemma.AtlasUtil;
local DataProvider = {};
local GemManagerMixin = {};
DataProvider.GemManagerMixin = GemManagerMixin;

Gemma:AddDataProvider("Pandaria", DataProvider);

local PATH = "Interface/AddOns/Narcissus/Art/Modules/GemManager/";
local TEXTURE_NAME = "TimerunningPandaria.png";

local GetItemGemID = C_Item.GetItemGemID;
local GetItemNumSockets = C_Item.GetItemNumSockets;     --10.2.7
local IsEquippableItem = C_Item.IsEquippableItem;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetInventoryItemLink = GetInventoryItemLink;

local GEM_TYPES = {
    [1] = "META",
    [2] = "COGWHEEL",
    [3] = "TINKER",
    [4] = "PRISMATIC",
};

local SLOT_ID = {
    HEAD = 1,
    FEET = 8,

    SHOULDER = 3,
    WRIST = 9,
    HANDS = 10,
    WAIST = 6,

    NECK = 2,
    CHEST = 5,
    LEGS = 7,
    RING1 = 11,
    RING2 = 12,
    TRINKET1 = 13,
    TRINKET2 = 14,
};

local GEM_DATA = {
    --[itemID] = {type, spellID, role, uiOrder}
    --role: bits 000 (Tank/Healer/DPS): Tank 100(4), DPS 001(1), H/D 011(3), H 010(2)

    --Total: 12
    [221982] = {1, 447598, 4, 00},  --Bulwark of the Black Ox: Charge, Taunt, Ward
    [221977] = {1, 447566, 1, 20},  --Funeral Pyre: Stat, Self Harm
    [220211] = {1, 444954, 2, 60},  --Precipice of Madness: Ward
    [220120] = {1, 444677, 4, 70},  --Soul Tether: Redirect Damage
    [220117] = {1, 444622, 2, 90},  --Ward of Salvation: Restore HP, Overhealing to Ward, AoE
    [219878] = {1, 444128, 7, 85},  --Tireless Spirit: Reduce Resouce Cost
    [219386] = {1, 443389, 7, 35},  --Locus of Power: Stats
    [216974] = {1, 437495, 1, 40},  --Morphing Elements: Summon Portal, AoE
    [216711] = {1, 426268, 3, 10},  --Chi-ji, the Red Crane
    [216695] = {1, 437011, 3, 30},  --Lifestorm: Damage then Restore HP and Haste
    [216671] = {1, 426748, 7, 80},  --Thundering Orb: Transform, DR, Movement
    [216663] = {1, 435313, 1, 50},  --Oblivion Sphere: Crit Damage Taken, AoE, Control

    --Total：17
    [218110] = {2, 441759, 7, 45},  --Soulshape
    [218109] = {2, 441749, 7, 10},  --Death's Advance
    [218108] = {2, 441741, 7, 05},  --Dark Pack
    [218082] = {2, 441617, 7, 55},  --Spiritwalker's Grace (Cast while Moving)
    [218046] = {2, 441576, 7, 50},  --Spirit Walk
    [218045] = {2, 441569, 7, 20},  --Door of Shadows
    [218044] = {2, 441564, 7, 35},  --Pursuit of Justice (Passive)
    [218043] = {2, 441559, 7, 80},  --Wild Charge
    [218005] = {2, 441493, 7, 65},  --Stampeding Roar
    [218004] = {2, 441479, 7, 75},  --Vanish
    [218003] = {2, 441467, 7, 30},  --Leap of Faith
    [217989] = {2, 441348, 7, 70},  --Trailblazer
    [217983] = {2, 441299, 7, 15},  --Disengage
    [216632] = {2, 427030, 7, 60},  --Sprint
    [216631] = {2, 427026, 7, 40},  --Roll
    [216630] = {2, 427031, 7, 25},  --Heroic Leap
    [216629] = {2, 427053, 7, 05},  --Blink

    --Total: 25
    [219944] = {3, 444455, 2, 03},  --Bloodthirsty Coral: Damage taken to Healing
    [219818] = {3, 429007, 7, 06},  --Brilliance: Party Resouce Regen
    [219817] = {3, 429026, 7, 18},  --Freedom: Ckear Loss of Control
    [219801] = {3, 427064, 7, 00},  --Ankh of Reincarnation: Self-rez
    [219977] = {3, 428854, 4, 21},  --Grounding: Redirect Harmful Spell
    [219527] = {3, 443855, 7, 63},  --Vampiric Aura: +Leech, Party Leech
    [219523] = {3, 443834, 1, 57},  --Storm Overload: AoE, Control
    [219516] = {3, 443670, 3, 54},  --Static Charge: Heal or Damage
    [219389] = {3, 443498, 3, 30},  --Lightning Rod: Crit on Ally or Dot on Enemy
    [217964] = {3, 441209, 2, 27},  --Holy Martyr: Damage Taken to Party Healing
    [217961] = {3, 441198, 2, 42},  --Righteous Frency: Healing Proc Haste on Ally
    [217957] = {3, 441165, 2, 15},  --Deliverance: Store Healing. Healing when Low HP
    [217927] = {3, 441150, 2, 45},  --Savior: Healing Low HP Ally Grants Ward
    [217907] = {3, 441115, 4, 72},  --Warmth: +Healing Taken, Redistribute Overhealing
    [217903] = {3, 441092, 3, 69},  --Vindication: Damage Done Heals Allies
    [216651] = {3, 436586, 3, 48},  --Searing Light: Healing to Heal and AoE Damage
    [216650] = {3, 436583, 7, 36},  --Memory of Vegeance: For every 10s, gain primary stat for every 5% missing HP 
    [216649] = {3, 436578, 1, 09},  --Brittle: Store Damage Done, Death Trigger AoE
    [216648] = {3, 436577, 7, 12},  --Cold Front: Allies Ward, Enemies Debuff
    [216647] = {3, 436571, 1, 24},  --Hailstorm: AoE and Debuff
    [216628] = {3, 436467, 3, 66},  --Victory Fire: Enemy Death trigger AoE Damage and Healing
    [216627] = {3, 429230, 2, 60},  --Tinkmaster's Shield: Ward after not being damaged for 5s
    [216626] = {3, 429378, 1, 51},  --Slay: Extra Damage to Low Health Enemy
    [216625] = {3, 429373, 1, 39},  --Quick Strike: Melee Ability Triggers Additional Autoattacks
    [216624] = {3, 436461, 5, 33},  --Mark of Arrogance: Dot on Attackers

    [210715] = {4, nil, 0, 32},  --Mastery +
    [216640] = {4, nil, 0, 22},  --Mastery ++
    [211106] = {4, nil, 0, 12},  --Mastery +++
    [211108] = {4, nil, 0, 02},  --Mastery +++, STAM
    [210714] = {4, nil, 0, 30},  --Crit +
    [216644] = {4, nil, 0, 20},  --Crit ++
    [211123] = {4, nil, 0, 10},  --Crit +++
    [211102] = {4, nil, 0, 00},  --Crit +++, STAM
    [210681] = {4, nil, 0, 31},  --Haste +
    [216643] = {4, nil, 0, 21},  --Haste ++
    [211107] = {4, nil, 0, 11},  --Haste +++
    [211110] = {4, nil, 0, 01},  --Haste +++, STAM
    [220371] = {4, nil, 0, 33},  --Vers +
    [220372] = {4, nil, 0, 23},  --Vers ++
    [220374] = {4, nil, 0, 13},  --Vers +++
    [220373] = {4, nil, 0, 03},  --Vers +++, STAM
    [220367] = {4, nil, 0, 35},  --Armor +
    [220368] = {4, nil, 0, 25},  --Armor ++
    [220370] = {4, nil, 0, 15},  --Armor +++
    [220369] = {4, nil, 0, 05},  --Armor +++, STAM
    [211109] = {4, nil, 0, 36},  --Regen +
    [216642] = {4, nil, 0, 26},  --Regen ++
    [211125] = {4, nil, 0, 16},  --Regen +++
    [211105] = {4, nil, 0, 06},  --Regen +++, STAM
    [210717] = {4, nil, 0, 37},  --Leech +
    [216641] = {4, nil, 0, 27},  --Leech ++
    [210718] = {4, nil, 0, 17},  --Leech +++
    [211103] = {4, nil, 0, 07},  --Leech +++, STAM
    [210716] = {4, nil, 0, 38},  --Speed +
    [216639] = {4, nil, 0, 28},  --Speed ++
    [211124] = {4, nil, 0, 18},  --Speed +++
    [211101] = {4, nil, 0, 08},  --Speed +++, STAM
};

local CUSTOM_SORT_ORDER = {
    [219944] = 2,
    [219818] = 12,
    [219817] = 8,
    [219801] = 4,
    [219977] = 1,

    [219527] = 24,
    [219523] = 6,
    [219516] = 23,
    [219389] = 13,
    [217964] = 5,

    [217961] = 14,
    [217957] = 25,
    [217927] = 20,
    [217907] = 9,
    [217903] = 17,

    [216651] = 18,
    [216650] = 7,
    [216649] = 15,
    [216648] = 11,
    [216647] = 16,

    [216628] = 22,
    [216627] = 19,
    [216626] = 10,
    [216625] = 21,
    [216624] = 3,
};

local GEM_REMOVAL_TOOL = {"spell", 433397};
GEM_REMOVAL_TOOL = {"spell", 405805};   --debug
GEM_REMOVAL_TOOL = {"item", 202087};   --debug

local function SortFunc_UIOrder(a, b)
    if CUSTOM_SORT_ORDER[a] and CUSTOM_SORT_ORDER[b] then
        return CUSTOM_SORT_ORDER[a] < CUSTOM_SORT_ORDER[b]
    end

    return GEM_DATA[a][4] < GEM_DATA[b][4]
end

function DataProvider:GetSortedItemList()
    --Loaded once when used

    if self.gemList then return self.gemList end;

    local tinsert = table.insert;
    local tsort = table.sort;

    local tbl = {};
    local numTypes = #GEM_TYPES;

    for i = 1, numTypes do
        tbl[i] = {};
    end

    for itemID, data in pairs(GEM_DATA) do
        local gemType = data[1];
        tinsert(tbl[gemType], itemID);

        Gemma:SetGemRemovalTool(itemID, GEM_REMOVAL_TOOL);
    end

    for gemType, gems in pairs(tbl) do
        tsort(gems, SortFunc_UIOrder);
    end

    self.gemList = tbl;

    return tbl
end

function DataProvider:GetGemTypeName(gemType)
    local lookup = "EMPTY_SOCKET_"..GEM_TYPES[gemType];
    if _G[lookup] then
        return _G[lookup]
    else
        return GEM_TYPES[gemType]
    end
end

function DataProvider:GetItemListByType(gemType)
    local itemList = self:GetSortedItemList();
    return itemList[gemType];
end

function DataProvider:IsGemActive(itemID)
    return true
end

function DataProvider:IsGemCollected(itemID)
    return true
end

local function GetNumSocketsForSlot(slotID)
    local itemLink = GetInventoryItemLink("player", slotID);
    if itemLink then
        return GetItemNumSockets(itemLink) or 0
    else
        return 0
    end
end

function DataProvider:DoesPlayerHaveHead()
    return GetNumSocketsForSlot(SLOT_ID.HEAD) > 0
end

function DataProvider:DoesPlayerHaveFeet()
    return GetNumSocketsForSlot(SLOT_ID.FEET) >= 0  --debug
end

local function GetItemGemFromSlot(slotID, index)
    local itemLink = GetInventoryItemLink("player", slotID);
    if itemLink then
        return GetItemGemID(itemLink, index);
    end
end

function DataProvider:GetHeadGem()
    return GetItemGemFromSlot(SLOT_ID.HEAD, 1)
end

function DataProvider:GetFeetGem()
    return GetItemGemFromSlot(SLOT_ID.FEET, 1)
end

function DataProvider:GetGemSpell(itemID)
    if GEM_DATA[itemID] then
        return GEM_DATA[itemID][2]
    end
end

function DataProvider:GetActiveGems()
    --debug
    if not self.debugGemList then
        local tbl = {};
        local tinsert = table.insert;

        for i = 1, 2 do
            local gems = self:GetItemListByType(i);
            tinsert(tbl, gems[1]);
        end

        local gems = self:GetItemListByType(3);
        for i = 1, 12 do
            tinsert(tbl, gems[i]);
        end

        self.debugGemList = tbl;
    end

    return self.debugGemList
end



function DataProvider:ResetBagInfo()
    self.gemCount = {};
end

local function BagSearch_ProcessItem(self, itemLink)
    if IsEquippableItem(itemLink) then
        for index = 1, GetItemNumSockets(itemLink) do
            local itemID = GetItemGemID(itemLink, index);
            if itemID and GEM_DATA[itemID] then
                if not self.gemCount[itemID] then
                    self.gemCount[itemID] = 1;
                else
                    self.gemCount[itemID] = self.gemCount[itemID] + 1;
                end
            end
        end
    else
        local itemID = GetItemInfoInstant(itemLink);
        if GEM_DATA[itemID] then
            if not self.gemCount[itemID] then
                self.gemCount[itemID] = 1;
            else
                self.gemCount[itemID] = self.gemCount[itemID] + 1;
            end
        end
    end
end

DataProvider.schematic = {
    background = "remix-ui-bg",
    topDivider = "remix-ui-divider",

    tabData = {
        {
            name = L["Pandamonium Gem Category 1"],  --Major
            method = "ShowMajors",
            background = nil,
            useCustomTooltip = false,
        },

        {
            name = L["Pandamonium Gem Category 2"],  --Tinker
            method = "ShowTraits",
            background = "remix-ui-tinker-bg",
            useCustomTooltip = true,
        },

        {
            name = L["Pandamonium Gem Category 3"],  --Prismatic
            method = "ShowStats",
            background = nil,
            useCustomTooltip = false,
        },
    },

    bagSearchProcessor = BagSearch_ProcessItem,
};

local BorderTextures_Hexagon = {
    active = "remix-hexagon-yellow",
    inactive = "remix-hexagon-grey",
    available = "remix-hexagon-green",
    dimmed = "remix-hexagon-darkyellow",
};

local BorderTextures_BigSquare = {
    active = "remix-bigsquare-yellow",
    inactive = "remix-bigsquare-grey",
    available = "remix-bigsquare-green",
};


local function sin(deg)
    return math.sin(math.rad(deg));
end

local function cos(deg)
    return math.cos(math.rad(deg));
end

local function CreateSlotShadow(self, slotButton)
    local shadow = self:AcquireTexture("Back", "BACKGROUND");
    AtlasUtil:SetAtlas(shadow, "remix-bigsquare-shadow");
    shadow:SetPoint("CENTER", slotButton, "CENTER", 0, 0);
end


function GemManagerMixin:SetupMajorSlotButton(itemID)
    local button = self:AcquireSlotButton("BigSquare");
    button.borderTextures = BorderTextures_BigSquare;
    button:SetButtonSize(64, 53);   --buttonSize, iconSize

    if itemID then
        button:SetItem(itemID);
        button:SetActive();
    else
        button:ClearItem();
    end

    local shadow = self:AcquireTexture("Back", "BACKGROUND");
    AtlasUtil:SetAtlas(shadow, "remix-bigsquare-shadow");
    shadow:SetPoint("CENTER", button, "CENTER", 0, 0);

    return button
end

function GemManagerMixin:ShowMajors()
    self.useSlotFrame = true;

    local shape = "BigSquare";
    local container = self.SlotFrame;

    local numButtons = 0;
    local button1, button2;

    if DataProvider:DoesPlayerHaveHead() then
        local itemID = DataProvider:GetHeadGem();
        local gems = DataProvider:GetItemListByType(1); --debug
        itemID = gems[1];
        local button = self:SetupMajorSlotButton(itemID);

        numButtons = numButtons + 1;
        button1 = button;
    end

    if DataProvider:DoesPlayerHaveFeet() then
        local itemID = DataProvider:GetFeetGem();
        local gems = DataProvider:GetItemListByType(2); --debug
        itemID = gems[1];
        local button = self:SetupMajorSlotButton(itemID);

        numButtons = numButtons + 1;
        if not button1 then
            button1 = button;
        else
            button2 = button;
        end
    end

    if numButtons == 0 then

    else
        if numButtons == 2 then
            local offsetX = 8;
            local offsetY = 16;
            button1:SetPoint("BOTTOMRIGHT", container, "CENTER", -offsetX, offsetY);
            button2:SetPoint("TOPLEFT", container, "CENTER", offsetX, -offsetY);
        elseif numButtons == 1 then
            button1:SetPoint("CENTER", container, "CENTER", 0, 0);
        end
    end

    self.SlotFrame.ButtonHighlight:SetShape(shape);

    self:ShowGemList();
end

function GemManagerMixin:ShowGemList()
    local gemType = 1;
    local gems = DataProvider:GetItemListByType(gemType);
    self.GemList:SetItemList(gems, DataProvider:GetGemTypeName(gemType));

    self:OpenGemList();
end

function GemManagerMixin:ShowTraits()
    self.useSlotFrame = true;

    local shape = "Hexagon";
    local diagonal = 46;
    local gap = 4;
    local container = self.SlotFrame;

    local deltaXPerRow = ((diagonal * cos(30)) + gap) * 0.5;
    local deltaYPerRow = (diagonal * cos(30) + gap) * cos(30);
    local offsetX = diagonal * cos(30) + gap;

    local contentWidth = 6 * offsetX - gap;
    local contentHeight = 5 * deltaYPerRow + diagonal;

    local frameWidth = container:GetWidth();
    local frameHeight = container:GetHeight();

    local paddingX = (frameWidth - contentWidth) * 0.5;
    local paddingY = (frameHeight - contentHeight) * 0.5;

    local refX = frameWidth * 0.5;
    local refY = (deltaYPerRow - diagonal * 0.5) - paddingY;

    local gemType = 3;  --Tinker
    local gems = DataProvider:GetItemListByType(gemType);

    local button;
    local row = 1;
    local col = 1;
    local maxCol = 1;
    local fromX, fromY = 0, 0;
    local x, y;

    for index, itemID in ipairs(gems) do
        button = self:AcquireSlotButton(shape);
        button:ResetButtonSize();
        button.borderTextures = BorderTextures_Hexagon;

        if row == 1 then
            col = col + 1;
        end

        if col > maxCol then
            maxCol = maxCol + 1;
            col = 1;
            row = row + 1;

            fromX = refX - (row - 1) * deltaXPerRow;
            fromY = refY - (row - 1) * deltaYPerRow;
        end

        if (row == 7 and col == 1) then
            col = col + 1;
        end

        x = fromX + (col - 1) * offsetX;
        y = fromY;
        button:SetPoint("CENTER", self.SlotFrame, "TOPLEFT", x, y);
        button:SetItem(itemID);

        col = col + 1;
    end

    self.TooltipFrame:ClearAllPoints();
    self.TooltipFrame:SetPoint("TOP", container, "CENTER", 0, -contentHeight * 0.5 - 16);
    self.TooltipFrame:SetDescriptionLine(6);

    self.SlotFrame.ButtonHighlight:SetShape(shape);

    local shine = self.SlotFrame.ButtonShine;
    shine.Mask:SetTexture(PATH.."IconMask-"..shape, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    shine.Mask:SetSize(38, 38);
    shine.Texture:SetTexture(PATH.."SlotShine");
    shine.Texture:SetSize(48, 48);
    shine.Texture:SetBlendMode("ADD");

    self:UpdateSlots();
end

function GemManagerMixin:UpdateSlots()
    for index, button in ipairs(self.slotButtons) do
        if button:IsShown() then
            if DataProvider:IsGemActive(button.itemID) then
                button:SetActive();
            elseif DataProvider:IsGemCollected(button.itemID) then
                button:SetInactive();
            else
                button:SetUncollected();
            end
        else
            break
        end
    end
end

function GemManagerMixin:ShowStats()
    self.useSlotFrame = false;
end


do
    Gemma.BagSearch:AddOnStartCallback(function()
        DataProvider:ResetBagInfo();
    end);
end