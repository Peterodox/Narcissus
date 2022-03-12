local crystallicItems = {
    190979, 190997, 190991, 190985, --Cryptic/Oracular/

};

for i = 1, #crystallicItems do
    local itemID = crystallicItems[i];
    crystallicItems[itemID] = true;
    crystallicItems[i] = nil;
end


local function DoesItemHaveCrystallicSocket(item)
    if not item then return; end

    if type(item) == "number" then
        return crystallicItems[item]
    end

    local itemID, gemID = string.match(item, "item:(%d+)::(%d*)");

    itemID = tonumber(itemID);
    if crystallicItems[itemID] then
        return true, gemID and tonumber(gemID)
    else
        return false
    end
    --local gemName, gemLink = GetItemGem(itemLink, 1);
    --EMPTY_SOCKET_CYPHER

    return nil, nil;
end

NarciAPI.DoesItemHaveCrystallicSocket = DoesItemHaveCrystallicSocket;



local crystallicSpell = {
    [189723] = 367264,      --Absorptialic
    [189722] = 367260,      --Alacrialic
    [189732] = 367263,      --Constialic
    [189560] = 367265,      --Deflectialic
    [189763] = 367269,      --Efficialic
    [189724] = 367267,      --Extractialic
    [189725] = 367258,      --Flexialic
    [189726] = 367257,      --Focialic
    [189762] = 367270,      --Fortialic
    [189727] = 367266,      --Healialic
    [189728] = 367255,      --Obscurialic
    [189729] = 367259,      --Osmosialic
    [189730] = 367262,      --Perceptialic
    [189731] = 367254,      --Potentialic
    [189764] = 367268,      --Reflectialic
    [189733] = 367173,      --Relialic
    [189734] = 367261,      --Rigialic
    [189760] = 367272,      --Robustialic
    [189761] = 367271,      --Toxicialic
    [189735] = 367256,      --Velocialic
};

local function GetCrystallicSpell(spheroidItemID)
    return crystallicSpell[spheroidItemID]
end

NarciAPI.GetCrystallicSpell = GetCrystallicSpell;


local function GetCrystallicEffect(spheroidItemID)
    return crystallicSpell[spheroidItemID] and GetSpellDescription(crystallicSpell[spheroidItemID]);
end

NarciAPI.GetCrystallicEffect = GetCrystallicEffect;