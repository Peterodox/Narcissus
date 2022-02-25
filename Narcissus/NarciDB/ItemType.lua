local _;
local floor = math.floor;
local format = string.format;
local GetItemInfoInstant = GetItemInfoInstant;
local FORMAT_REQUIRES = ITEM_REQ_SPECIALIZATION;

local slotData = {
    --[slotID] = {InventorySlotName, Localized Name, invType, textureID}    --GetInventorySlotInfo("SlotName")
    [1] = {"HeadSlot", HEADSLOT, "INVTYPE_HEAD"},
    [2] = {"NeckSlot", NECKSLOT, "INVSLOT_NECK"},
    [3] = {"ShoulderSlot", SHOULDERSLOT, "INVTYPE_SHOULDER"},
    [4] = {"ShirtSlot", SHIRTSLOT, "INVTYPE_BODY"},
    [5] = {"ChestSlot", CHESTSLOT, "INVTYPE_CHEST"},
    [6] = {"WaistSlot", WAISTSLOT, "INVTYPE_WAIST"},
    [7] = {"LegsSlot", LEGSSLOT, "INVTYPE_LEGS"},
    [8] = {"FeetSlot", FEETSLOT, "INVTYPE_FEET"},
    [9] = {"WristSlot", WRISTSLOT, "INVTYPE_WRIST"},
    [10]= {"HandsSlot", HANDSSLOT, "INVTYPE_HAND"},
    [11]= {"Finger0Slot", FINGER0SLOT_UNIQUE, "INVSLOT_FINGER1"},
    [12]= {"Finger1Slot", FINGER1SLOT_UNIQUE, "INVSLOT_FINGER2"},
    [13]= {"Trinket0Slot", TRINKET0SLOT_UNIQUE, "INVSLOT_TRINKET1"},
    [14]= {"Trinket1Slot", TRINKET1SLOT_UNIQUE, "INVSLOT_TRINKET2"},
    [15]= {"BackSlot", BACKSLOT, "INVTYPE_CLOAK"},
    [16]= {"MainHandSlot", MAINHANDSLOT, "INVTYPE_WEAPONMAINHAND"},
    [17]= {"SecondaryHandSlot", SECONDARYHANDSLOT, "INVTYPE_WEAPONOFFHAND"},
    [18]= {"AmmoSlot", RANGEDSLOT, "INVSLOT_RANGED"},
    [19]= {"TabardSlot", TABARDSLOT, "INVTYPE_TABARD"},
}

local invTypeSlotID = {
    INVTYPE_WEAPON = 16,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_SHIELD = 17,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_RANGED = 16,    --actually held in offhand, 17
    INVTYPE_RANGEDRIGHT = 16,
    INVTYPE_FINGER = 11,
    INVTYPE_TRINKET = 13,
};

for slotID, info in pairs(slotData) do
    _, info[4] = GetInventorySlotInfo(info[1]);  --texture
    invTypeSlotID[ info[3] ] = slotID;
end

local function GetSlotIDByInvType(invType)
    return invTypeSlotID[invType]
end

local function GetSlotIDByItemID(itemID)
    local _, _, _, invType = GetItemInfoInstant(itemID);
    return invTypeSlotID[invType]
end

local function GetSlotNameAndTexture(slotID)
    if slotData[slotID] then
        return slotData[slotID][2], slotData[slotID][4]
    end
end

local function GetInventorySlotNameBySlotID(slotID)
    if slotData[slotID] then
        return slotData[slotID][1]
    end
end

local function GetSlotButtonNameBySlotID(slotID)
    if slotData[slotID] then
        return "Character"..slotData[slotID][1];
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

local itemTypes = {
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

for key, data in pairs(itemTypes) do
    local classID, subclassID, tempItemID = unpack(data);
    local itemID, itemType, itemSubType = GetItemInfoInstant(tempItemID);
    if itemID then
        itemTypes[key][3] = itemSubType;
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
    if key and itemTypes[key] then
        return itemTypes[key][3]
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


NarciAPI.GetItemTempEnchantType = GetItemTempEnchantType;
NarciAPI.GetItemTempEnchantRequirement = GetItemTempEnchantRequirement;
NarciAPI.IsWeaponValidForEnchant = IsWeaponValidForEnchant;