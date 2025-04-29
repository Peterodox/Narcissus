local _, addon = ...
local ESM = Narci_EquipmentSetManager;      --defined in EquipmentSetManager.lua

local IsSpellPassive = addon.TransitionAPI.IsSpellPassive;

local IconPresets = {};
IconPresets.tank = {
    951819,     --Shield_draenorcrafted_d_02_b_alliance
    951820,     --Shield_draenorcrafted_d_02_b_horde
    2398168,    --Inv_shield_1h_bloodelfguard_d_01
};

IconPresets.healer = {
    460955,     --Priest_icon_innewill
    215433,     --spell_priest_chakra
    537099,     --Spell_priest_angelicbulwark
    135913,     --Spell_holy_greaterheal
    135930,     --Spell_holy_lesserheal02
};

IconPresets.pvp = {
    236335,     --Achievement_arena_3v3_6
    236328,     --Achievement_arena_2v2_6
    236340,     --Achievement_arena_5v5_4
    236357,     --Achievement_bg_kill_carrier_opposing_flagroom
    236349,     --Achievement_bg_captureflag_eos
    236320,     --Ability_wintergrasp_rank1
    458242,     --Trade_archaeology_generalbeauregardslaststand


};

IconPresets.dungeon = {
    236387,     --Achievement_bg_winab_underxminutes
    2011140,    --Achievement_dungeon_skycapnkragg
    2011149,    --Achievement_dungeon_toldagor
    1518644,    --Inv_misc_diachest03
    136180,     --Spell Disruption
    525134,     --Inv_relics_hourglass [Keystone]
    236353,     --Achievement_bg_grab_cap_flagunderxseconds
};



local function GetRandomIcon(subclass)
    local IconCategory = IconPresets[subclass];
    return ( IconCategory[ math.random( #IconCategory ) ] );
end

--[[
    --Dev Tool
local IconNames = {};
local IconNames_LowerCase = {};
local SetTimer = C_Timer.After;
local find = string.find;

IconNames = GetLooseMacroIcons();

local index = 1;
local totalMatches = 0;
local isConsecutive = false;
local isMatch = false;
local totalIcon = #IconNames;

local function ConvertToLowerCase()
    local strlower = string.lower;
    for i = 1, #IconNames do
        IconNames_LowerCase[i] = strlower(IconNames[i]);
    end
end

ConvertToLowerCase();

local function ResetFlags()
    print("Found ".. totalMatches .. "matches.")
    index = 1;
    totalMatches = 0;
    isConsecutive = false;
    isMatch = false;
end

local function PrintIcons(name)
    --Ability_ClassName_SpellName
    if index <= totalIcon then
        isMatch = find(IconNames_LowerCase[index], name, 9)
        if isMatch then
            print("|cFFFFD100"..index .."|r ".. IconNames[index]);
            totalMatches = totalMatches + 1;
            isConsecutive = true;
        end

        
        if isConsecutive and (not isMatch) then
            print("|cffff5050"..index .."|r ".. IconNames[index]);    --Irregular
            print("Searching ended.")
            ResetFlags();
            return;
        end

        index = index + 1;
        SetTimer(0, function()
            PrintIcons(name)
        end); 
    else
        print("Searching completed.");
        ResetFlags();
    end
end

function SearchIconsByClassName(ClassName)
    local name = strlower(ClassName);
    PrintIcons(name);
end
--]]
----------------------------------------------------------
local staticIcons = {};     --exclude passive spell
local usedIcons = {};       --usedIcons = staticIcons∪recently used icons
local excludedIcons = {     --Reset
    132296,     --DH:       Double Jump
    132301,     --Rogue:    Fleet Footed
};

local function IsUniqueIcon(icon)
    if not icon then return false; end;
    local isUnique = not usedIcons[icon];
    usedIcons[icon] = true;
    return isUnique;
end

local function GetStaticIcons() --FillOutExtraIconsMapWithSpells (Interface/AddOns/Blizzard_FrameXMLBase/Mainline/IconDataProvider.lua)
    local GetSpellTexture = C_Spell.GetSpellTexture;
    local GetSpellBookItemType = C_SpellBook.GetSpellBookItemType;
    local GetSpellBookItemTexture = C_SpellBook.GetSpellBookItemTexture;
    local GetFlyoutInfo = GetFlyoutInfo;
    local GetFlyoutSlotInfo = GetFlyoutSlotInfo;
    local PLAYER = Enum.SpellBookSpellBank.Player;
    local spellIndex, spellType, ID, fileID;
    local _, numSlots, isKnown;
    local spellID, overrideSpellID, isSlotKnown;

    for skillLineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex);
		for i = 1, skillLineInfo.numSpellBookItems do
			spellIndex = skillLineInfo.itemIndexOffset + i;
			spellType, ID = GetSpellBookItemType(spellIndex, PLAYER);
			if spellType ~= "FUTURESPELL" then
				fileID = GetSpellBookItemTexture(spellIndex, PLAYER);
				if fileID ~= nil then
					staticIcons[fileID] = true;
				end
			end

			if spellType == "FLYOUT" then
				_, _, numSlots, isKnown = GetFlyoutInfo(ID);
				if isKnown and (numSlots > 0) then
					for k = 1, numSlots do
						spellID, overrideSpellID, isSlotKnown = GetFlyoutSlotInfo(ID, k)
						if isSlotKnown then
							fileID = GetSpellTexture(spellID);
							if fileID ~= nil then
								staticIcons[fileID] = true;
							end
						end
					end
				end
			end
		end
	end

    for i = 1, #excludedIcons do
        staticIcons[ excludedIcons[i] ] = true;
    end

    return staticIcons
end

local GetEquipmentSetInfo = C_EquipmentSet.GetEquipmentSetInfo;
local function LoadEquipmentSetIcons()
    local SetIDs = C_EquipmentSet.GetEquipmentSetIDs() or {};
    for i = 1, #SetIDs do
        local _, iconFileID = GetEquipmentSetInfo(SetIDs[i]);
        usedIcons[iconFileID] = true;
    end
end

local function GetSelectedPvpTalentIcons()
    local talentIDs = C_SpecializationInfo.GetAllSelectedPvpTalentIDs();   --Return talentID
    if talentIDs and #talentIDs > 1 then
        local icons = {};
        for i = 2, #talentIDs do
            local _, _, icon = GetPvpTalentInfoByID(talentIDs[i]);
            tinsert(icons, icon);
        end
        return icons;
    else
        return false;
    end
end

local GetInventoryItemTexture = GetInventoryItemTexture;
local GetInventoryItemQuality = GetInventoryItemQuality;
local DoesItemExist = C_Item.DoesItemExist;
local function GenerateIcons()                             --Passive talent only
    local icons, names = {}, {};
    local MaxTiers = GetMaxTalentTier();                   --based on the character's level
    local talentGroup = GetActiveSpecGroup();
    local talentID, icon, spellID, name;
    local IsSpellPassive = IsSpellPassive;
    local tinsert = table.insert;

    --from Inventory
    local itemLocation = ItemLocation:CreateFromEquipmentSlot(16);   --Main Hand
    if DoesItemExist(itemLocation) then
        icon = C_Item.GetItemIcon(itemLocation);
        if IsUniqueIcon(icon) then
            name = C_Item.GetItemName(itemLocation);
            tinsert(icons, icon);
            tinsert(names, name);
        end
    end

    itemLocation = ItemLocation:CreateFromEquipmentSlot(15)     --INVSLOT_BACK
    if DoesItemExist(itemLocation) then
        local quality = C_Item.GetItemQuality(itemLocation);
        if quality == 5 or quality == 6 then                        --Legendary & Artifact
            icon = C_Item.GetItemIcon(itemLocation);
        end
        if IsUniqueIcon(icon) then
            name = C_Item.GetItemName(itemLocation);
            tinsert(icons, icon);
            tinsert(names, name);
        end
    end

    local playerSpellIcons = GetStaticIcons();
    for k, v in pairs(playerSpellIcons) do
        tinsert(icons, k);
        tinsert(names, k);
    end

    --from spell book
    --[[
    local GetSpellBookItemTexture = GetSpellBookItemTexture;
    local GetSpellBookItemInfo = GetSpellBookItemInfo;
    local _, _, tabOffset, numEntries = GetSpellTabInfo(2)      --1:General 2:Current Spec
    for i = (tabOffset + numEntries) , tabOffset + 1 , -1 do    --Passive spell sits in the back
        _, spellID = GetSpellBookItemInfo(i, "spell");
        if spellID and IsSpellPassive(spellID) then
            icon = GetSpellBookItemTexture(i, "spell");
            if IsUniqueIcon(icon) then
                tinsert(icons, icon);
                name = GetSpellBookItemName(i, "spell");
                tinsert(names, name);
            end
        else
            --break;
        end
    end
    --]]

    --Regular talent tree
    if talentGroup then
        local column;
        for tier = 1, MaxTiers do
            _, column = GetTalentTierInfo(tier, talentGroup);
            if column then
                talentID, name, icon, _, _, spellID = GetTalentInfo(tier, column, talentGroup);
                if spellID and IsSpellPassive(spellID) and IsUniqueIcon(icon) then
                    tinsert(icons, icon);
                    tinsert(names, name);
                end
            end
        end
    end

    --PvP talents
    local talentIDs = C_SpecializationInfo.GetAllSelectedPvpTalentIDs();   --Return talentID
    if talentIDs and #talentIDs > 1 then
        for i = 2, #talentIDs do
            _, name, icon, _, _, spellID = GetPvpTalentInfoByID(talentIDs[i]);
            if spellID and IsSpellPassive(spellID) and IsUniqueIcon(icon) then
                tinsert(icons, icon);
                tinsert(names, name);
            end
        end
    end

    itemLocation = ItemLocation:CreateFromEquipmentSlot(17);    --INVSLOT_OFFHAND 
    if DoesItemExist(itemLocation) then
        if #icons < 2 then
            icon = C_Item.GetItemIcon(itemLocation);
            if IsUniqueIcon(icon) then
                name = C_Item.GetItemName(itemLocation);
                tinsert(icons, icon);
                tinsert(names, name);
            end
        end
    end
    return icons, names;
end

local function GetPassiveSpellIcons()
    --from spell book
    local GetSpellBookItemTexture = GetSpellBookItemTexture;
    local GetSpellBookItemInfo = GetSpellBookItemInfo;
    local spellID;
    local icons = {};
    local icon;
    local _, _, tabOffset, numEntries = GetSpellTabInfo(2)      --1:General 2:Current Spec
    for i = (tabOffset + numEntries) , tabOffset + 1 , -1 do    --Passive spell sits in the back
        _, spellID = GetSpellBookItemInfo(i, "spell");
        if spellID and IsSpellPassive(spellID) then
            icon = GetSpellBookItemTexture(i, "spell");
            if IsUniqueIcon(icon) then
                tinsert(icons, icon);
            end
        else
            --break;
        end
    end
    return icons;
end

local GetEquipmentSetIDByName = C_EquipmentSet.GetEquipmentSetID;
local function ConvertToUniqueName(setName)
    setName = setName or "";
    local newName = setName;
    local index = 2;
    while (GetEquipmentSetIDByName(newName) and index <= 10) do
        newName = setName..index;
        index = index + 1
    end
    return newName;
end

function ESM:GetCurrentSpecializationNameAndIcons()
    LoadEquipmentSetIcons();
    local currentSpec = GetSpecialization() or 1;
    local _, currentSpecName, _, specIcon, role = GetSpecializationInfo(currentSpec);
    local roleName, subclass;
    currentSpecName = ConvertToUniqueName(currentSpecName);
    if role == "TANK" then
        subclass = "tank";
        roleName = TANK;
    elseif role == "HEALER" then
        subclass = "healer";
        roleName = HEALER;
    else        --"DAMAGER" and else
        subclass = "pvp";
        roleName = DAMAGER;
    end
    local roleIcon = GetRandomIcon(subclass);
    local dungeonIcon = GetRandomIcon("dungeon");
    local pvpIcon = GetRandomIcon("pvp");
    local spellIcons, spellNames = GenerateIcons();     --table

    C_Timer.After(0.2, function()
        usedIcons = GetStaticIcons();
    end)

    return currentSpecName, specIcon, roleIcon, dungeonIcon, pvpIcon, spellIcons, roleName, spellNames;
end

----------------------------------------------------------

NarciEquipmentSetIconSelectorMixin = {};

function NarciEquipmentSetIconSelectorMixin:OnLoad()
    ESM.IconSelector = self;
    self.Header:SetText(Narci.L["Icon Selector"]);
end

function NarciEquipmentSetIconSelectorMixin:OnHide()
    self:Hide();
    self:SetAlpha(0);
    self.Header:SetText(Narci.L["Icon Selector"]);
end

function NarciEquipmentSetIconSelectorMixin:Load()
    if self.Init then
        self:Init();
    end
end


function NarciEquipmentSetIconSelectorMixin:Init()
    usedIcons = GetStaticIcons();
    LoadEquipmentSetIcons()

    local row, column = 4, 3;
    local size = 48;

    self:SetSize(size * column, size * row);
    self.row, self.column = row, column;

    --Crreate icon buttons
    local button;
    local buttons = {};
    local icons = {};

    for i = 1 , (row * column) do
        button = CreateFrame("Button", nil, self, "NarciEquipmentSetIconTemplate");
        if i == 1 then
            button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0);        --Start from bottom-left
        elseif i % column == 1 then
            button:SetPoint("BOTTOM", buttons[i - column], "TOP", 0, 0);        --New row
        else
            button:SetPoint("LEFT", buttons[i - 1], "RIGHT", 0, 0);
        end
        tinsert(icons, button.Icon);
        tinsert(buttons, button);
    end

    self.icons = icons;
    self.buttons = buttons;

    self.Init = nil;
end