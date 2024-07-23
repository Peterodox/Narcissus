local _;
local FORMAT_REQUIRES = ITEM_REQ_SPECIALIZATION;
local floor = math.floor;
local format = string.format;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetContainerNumSlots = C_Container.GetContainerNumSlots;
local GetContainerItemID = C_Container.GetContainerItemID;
local GetInventoryItemID = GetInventoryItemID;

local SlotData = {
    --[slotID] = {InventorySlotName, Localized Name, invType, texture, validForTransmog, ItemEnchancementSubclassID}    --GetInventorySlotInfo("SlotName")
    --Added in 10.2: ItemEnchancementSubclassID https://warcraft.wiki.gg/wiki/ItemType#8:_Item_Enhancement
    --Weapon Enchants depend on, surprisingly, weapons!
    [1] = {"HeadSlot", HEADSLOT, "INVTYPE_HEAD", 0, true, 0},
    [2] = {"NeckSlot", NECKSLOT, "INVSLOT_NECK", 0, 1},
    [3] = {"ShoulderSlot", SHOULDERSLOT, "INVTYPE_SHOULDER", 0, true, 2},
    [4] = {"ShirtSlot", SHIRTSLOT, "INVTYPE_BODY", 0, true},
    [5] = {"ChestSlot", CHESTSLOT, "INVTYPE_CHEST", 0, true, 4},
    [6] = {"WaistSlot", WAISTSLOT, "INVTYPE_WAIST", 0, true, 7},
    [7] = {"LegsSlot", LEGSSLOT, "INVTYPE_LEGS", 0, true, 8},
    [8] = {"FeetSlot", FEETSLOT, "INVTYPE_FEET", 0, true, 9},
    [9] = {"WristSlot", WRISTSLOT, "INVTYPE_WRIST", 0, true, 5},
    [10]= {"HandsSlot", HANDSSLOT, "INVTYPE_HAND", 0, true, 6},
    [11]= {"Finger0Slot", FINGER0SLOT_UNIQUE, "INVSLOT_FINGER1", 0, 10},
    [12]= {"Finger1Slot", FINGER1SLOT_UNIQUE, "INVSLOT_FINGER2", 0, 10},
    [13]= {"Trinket0Slot", TRINKET0SLOT_UNIQUE, "INVSLOT_TRINKET1", 0},
    [14]= {"Trinket1Slot", TRINKET1SLOT_UNIQUE, "INVSLOT_TRINKET2", 0},
    [15]= {"BackSlot", BACKSLOT, "INVTYPE_CLOAK", 0, true, 3},
    [16]= {"MainHandSlot", MAINHANDSLOT, "INVTYPE_WEAPONMAINHAND", 0, true, 128},
    [17]= {"SecondaryHandSlot", SECONDARYHANDSLOT, "INVTYPE_WEAPONOFFHAND", 0, true, 128},
    [18]= {"AmmoSlot", RANGEDSLOT, "INVSLOT_RANGED", 0},
    [19]= {"TabardSlot", TABARDSLOT, "INVTYPE_TABARD", 0, true},
}

local InvTypeXSlotID = {
    INVTYPE_WEAPON = 16,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_SHIELD = 17,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_RANGED = 16,    --actually held in offhand, 17
    INVTYPE_RANGEDRIGHT = 16,
    INVTYPE_FINGER = 11,
    INVTYPE_TRINKET = 13,
};

local HoldableItem = {
    INVTYPE_WEAPON = true,
    INVTYPE_2HWEAPON = true,
    INVTYPE_SHIELD = true,
    INVTYPE_HOLDABLE = true,
    INVTYPE_RANGED = true,
    INVTYPE_RANGEDRIGHT = true,
    INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND = true,
};

for slotID, info in pairs(SlotData) do
    _, info[4] = GetInventorySlotInfo(info[1]);  --texture
    InvTypeXSlotID[ info[3] ] = slotID;
end

local function GetSlotIDByInvType(invType)
    return InvTypeXSlotID[invType]
end

local function GetSlotIDByItemID(itemID)
    local _, _, _, invType = GetItemInfoInstant(itemID);
    return InvTypeXSlotID[invType]
end

local function GetSlotNameAndTexture(slotID)
    if SlotData[slotID] then
        return SlotData[slotID][2], SlotData[slotID][4]
    end
end

local function GetInventorySlotNameBySlotID(slotID)
    if SlotData[slotID] then
        return SlotData[slotID][1]
    end
end

local function GetSlotButtonNameBySlotID(slotID)
    if SlotData[slotID] then
        return "Character"..SlotData[slotID][1];
    end
end


NarciAPI.GetSlotIDByInvType = GetSlotIDByInvType;
NarciAPI.GetSlotIDByItemID = GetSlotIDByItemID;
NarciAPI.GetInventorySlotNameBySlotID = GetInventorySlotNameBySlotID;       --used by model:TryOn(sourceID, slotName)
NarciAPI.GetSlotNameAndTexture = GetSlotNameAndTexture;             --localized names
NarciAPI.GetSlotButtonNameBySlotID = GetSlotButtonNameBySlotID;     --names of the buttons on PaperdollFrame




--------------------------------------------------
local function toGUID(classID, subclassID)
    return classID * 100 + subclassID
end

local function toClassID(guid)
    local classID = floor(guid/100);
    local subclassID = guid - classID * 100;
    return classID, subclassID
end

local function ConvertTableToBool(list)
    local tbl = {};
    local key;
    for i = 1, #list do
        key = list[i];
        tbl[key] = true;
    end
    return tbl
end

local ItemTypes = {
    -- {classID, subclassID, exampleItemID(then placed by type name)}
    Axe1H = {2, 0, 37},
    Axe2H = {2, 1, 12282},
    Bow = {2, 2, 2504},
    Gun = {2, 3, 2508},
    Mace1H = {2, 4, 36},
    Mace2H = {2, 5, 2361},
    Polearm = {2, 6, 57243},
    Sword1H = {2, 7, 25},
    Sword2H = {2, 8, 2489},
    Warglaive = {2, 9, 112458},
    Staff = {2, 10, 35},
    Unarmed = {2, 13, 2942},    --Fist Weapon
    Dagger = {2, 15, 2092},
    Crossbow = {2, 18, 15807},
    Wand = {2, 19, 5069},
    Fishingpole = {2, 20, 6256},
    Shield = {4, 6, 2362},
};

local typeIDKeys = {};

for key, data in pairs(ItemTypes) do
    local classID, subclassID, tempItemID = unpack(data);
    local itemID, itemType, itemSubType = GetItemInfoInstant(tempItemID);
    if itemID then
        ItemTypes[key][3] = itemSubType;
        local guid = toGUID(classID, subclassID);
        typeIDKeys[guid] = key;
    else
        print("Item: "..itemID.." no longer exists");
    end
end


local bladedWeapons = {
    --TempEnchantType 1
    --Axe1H/Axe2H/Polearm/Sword1H/Sword2H/Warglaive/Fist Weapon/Dagger
    200, 201, 206, 207, 208, 209, 213, 215,
};

local isBladed = ConvertTableToBool(bladedWeapons);

local bluntWeapons = {
    --TempEnchantType 2
    --Mace1H/Mace2H/Staff
    204, 205, 210,
};

local isBlunt = ConvertTableToBool(bluntWeapons);

local hunterRangedWeapons = {
    --TempEnchantType 3
    --Bow/Gun/Crossbow
    202, 203, 218,
};

local isHunter = ConvertTableToBool(hunterRangedWeapons);

local enchantableWeapons = {
    200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 213, 215, 218, 220,
};

local isEnchantableWeapon = ConvertTableToBool(enchantableWeapons);


local function GetItemTypeNameByGUID(guid)
    local key = typeIDKeys[guid];
    if key and ItemTypes[key] then
        return ItemTypes[key][3]
    end
end

local function GetItemTypeString(...)
    local guid, name;
    local str;
	for i = 1, select("#", ...) do
		guid = select(i, ...);
        name = GetItemTypeNameByGUID(guid);
        if name then
            if str then
                str = str.. (NARCI_WORDBREAK_COMMA or ", ") ..name;
            else
                str = name;
            end
        end
	end
    return str or ""
end

local BLADED_WEAPON_NAMES = GetItemTypeString(unpack(bladedWeapons));
local BLUNT_WEAPON_NAMES = GetItemTypeString(unpack(bluntWeapons));
local HUNTER_RANGED_WEAPON_NAMES = GetItemTypeString(unpack(hunterRangedWeapons));

local function GetItemGUID(item)
    if not item then return end;
    local itemID, _, _, _, _, classID, subclassID = GetItemInfoInstant(item);
    if not itemID then return end;
    return toGUID(classID, subclassID)
end

local function GetItemTempEnchantType(item)
    local guid = GetItemGUID(item);
    if guid then
        if isBladed[guid] then
            return 1
        elseif isBlunt[guid] then
            return 2
        elseif isHunter[guid] then
            return 3
        end
    end
end

local function IsWeaponValidForEnchant(item)
    local guid = GetItemGUID(item);
    if guid then
        return isEnchantableWeapon[guid]
    end
end

local function GetItemTempEnchantRequirement(typeID)
    if typeID == 1 then
        return format(FORMAT_REQUIRES, BLADED_WEAPON_NAMES)
    elseif typeID == 2 then
        return format(FORMAT_REQUIRES, BLUNT_WEAPON_NAMES)
    elseif typeID == 3 then
        return format(FORMAT_REQUIRES, HUNTER_RANGED_WEAPON_NAMES)
    end
end

local function IsSlotValidForTransmog(slotID)
    return slotID and SlotData[slotID][5]
end

local function IsHoldableItem(item)
    if item then
        local _, _, _, itemEquipLoc = GetItemInfoInstant(item);
        return HoldableItem[itemEquipLoc];
    end
end

NarciAPI.GetItemTempEnchantType = GetItemTempEnchantType;
NarciAPI.GetItemTempEnchantRequirement = GetItemTempEnchantRequirement;
NarciAPI.IsWeaponValidForEnchant = IsWeaponValidForEnchant;
NarciAPI.IsSlotValidForTransmog = IsSlotValidForTransmog;
NarciAPI.IsHoldableItem = IsHoldableItem;




--Find bag items by Class/Subclass ID
local function GetItemEnchancementSubclassIDFromSlot(slotID)
    local subclassID;

    if slotID == 16 or slotID == 17 then
        --Weapon Slots
        local itemID = GetInventoryItemID("player", slotID);
        if itemID then
            local classID, itemSubclassID = select(6, GetItemInfoInstant(itemID));
            if classID == 4 and itemSubclassID == 6 then
                subclassID = 13;    --Shield
            elseif classID == 2 then
                if itemSubclassID == 2 or itemSubclassID == 3 or itemSubclassID == 18 then
                    subclassID = 12;    --Hunter ranged weapon is deemed Two-Handed Weapon
                elseif itemSubclassID == 20 then
                    subclassID = 14;    --Misc Tools Fishingpole
                else
                    subclassID = 11;
                end
            end
        end
    else
        subclassID = SlotData[slotID][6];
    end

    return subclassID
end

local function GetBagItemsByItemType(condition)
    --Doesn't work on Wrath reputation enchants like [Arcanum of X]
    --Don't appear to cause any stutter
    local _, itemID, classID, subclassID;
    local n = 0;
    local itemFound = {};
    local itemList = {};
    for i = 0, 4 do     --NUM_BAG_SLOTS
        for j = 1, GetContainerNumSlots(i) do
            itemID = GetContainerItemID(i, j);
            if itemID then
                itemID, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID);
                if condition(classID, subclassID) then
                    if not itemFound[itemID] then
                        itemFound[itemID] = true;
                        n = n + 1;
                        itemList[n] = itemID;
                    end
                end
            end
        end
    end

    return itemList, n
end

local function GetBagItemEnchancementForSlot(slotID)
    local subclassID = GetItemEnchancementSubclassIDFromSlot(slotID);
    if subclassID then
        local condition = function(itemClassID, itemSubclassID)
            return itemClassID == 8 and itemSubclassID == subclassID;
        end
        return GetBagItemsByItemType(condition);
    else
        return nil, 0
    end
end


NarciAPI.GetBagItemsByItemType = GetBagItemsByItemType;
NarciAPI.GetBagItemEnchancementForSlot = GetBagItemEnchancementForSlot;