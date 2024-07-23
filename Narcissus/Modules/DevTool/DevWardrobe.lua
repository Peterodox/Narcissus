local ITEM_IDS = {
    189792,
    189869,
    189870,
    189871,
    189872,
    189873,
    189874,
    189875,
    189876,
    189877,
    189878,
    189879,
    189880,
    189881,
    189883,
    189884,
    189886,
    189897,
    189898,
    190064,
    190066,
    190067,
    190068,
    190069,
    190070,
    190071,
    190072,
    190073,
    190074,
    190075,
    190076,
    190078,
    190079,
    190080,
    190131,
    190132,
    190134,
    190135,
    190136,
    190137,
    190138,
    190139,
    190140,
    190141,
    190142,
    190143,
    190144,
    190146,
    190147,
    190148,
    190152,
    190165,
    190167,
    190168,
    190173,
    190176,
    190201,
    190202,
    190203,
    190206,
    190207,
    190208,
    190209,
    190210,
    190211,
    190212,
    190213,
    190218,
    190219,
    190230,
    190231,
    190428,
    190429,
    190430,
    190432,
    190434,
    190435,
    190436,
    190437,
    190440,
    190442,
    190445,
    190446,
    190539,
    190544,
    190547,
    190548,
    190549,
    190550,
    190551,
    190552,
    190553,
    190554,
    190555,
    190556,
    190574,
    190575,
    190599,
    190604,
    190607,
    190672,
    190673,
    190675,
    190676,
    190677,
    190678,
    190679,
    190680,
    190681,
    190682,
    190683,
    190684,
    190685,
    190686,
    190687,
    190689,
    190691,
    190696,
    190697,
    190698,
    190699,
    190700,
    190701,
    190702,
    190703,
    190704,
    190705,
    190706,
    190707,
    190708,
    190709,
    190710,
    190711,
    190713,
    190714,
    190715,
    190718,
    190767,
    190772,
    190787,
    190788,
    190799,
    190803,
    190806,
    190809,
    190810,
    190811,
    190815,
    190830,
    190834,
    190835,
    190836,
    190837,
    190838,
    190839,
    190840,
    190841,
    190846,
    190855,
    190856,
    190858,
    190861,
    190862,
    190863,
    190864,
    190865,
    190866,
    190867,
    190868,
    190879,
    190888,
    190894,
    190897,
    193912,
    200919,
    200920,
    200921,
    200922,
    200923,
    201960,
    201961,
    201962,
    201990,
    202015,
    202020,
    202035,
    202039,
    202096,
    202112,
    202153,
    202154,
    202155,
    202156,
    202157,
    202158,
    202159,
    202160,
    202161,
    202165,
    202166,
    202167,
    202168,
    202169,
    202170,
    202207,
    202208,
    202209,
    202210,
    202211,
    202212,
    202213,
    202214,
    202215,
    202216,
    202217,
    202218,
    202219,
    202220,
    202221,
    202223,
    202224,
    202226,
    202227,
    202228,
    202229,
    202230,
    202231,
    202232,
    202233,
    202234,
    202235,
    202236,
    202237,
    202249,
    202252,
    202295,
    202296,
    202297,
    202298,
    202300,
    202301,
    202303,
    202304,
    202305,
    202306,
    202307,
    202308,
    202309,
    202310,
    202360,
    202371,
    202380,
    202691,
    203226,
    203382,
    203431,
    203461,
    203469,
    203471,
    203476,
    203478,
    203489,
    203490,
    203491,
    203492,
    203493,
    203494,
    203495,
    203496,
    203497,
    203498,
    203499,
    203500,
    203501,
    203502,
    203503,
    203504,
    203505,
    203506,
    203507,
    203508,
    203509,
    203510,
    203511,
    203512,
    203513,
    203514,
    203515,
    203516,
    203517,
    203518,
    203519,
    203520,
    203521,
    203522,
    203523,
    203524,
    203525,
    203526,
    203527,
    203528,
    203529,
    203530,
    203531,
    203532,
    203533,
    203534,
    203535,
    203536,
    203537,
    203538,
    203539,
    203540,
    203541,
    203542,
    203543,
    203544,
    203545,
    203546,
    203547,
    203548,
    203549,
    203550,
    203551,
    203552,
    203553,
    203554,
    203555,
    203556,
    203557,
    203558,
    203559,
    203560,
    203561,
    203562,
    203563,
    203564,
    203565,
    203566,
    203567,
    203568,
    203569,
    203570,
    203571,
    203572,
    203573,
    203574,
    203575,
    203576,
    203577,
    203578,
    203579,
    203580,
    203581,
    203582,
    203583,
    203584,
    203585,
    203586,
    203587,
    203588,
    203589,
    203590,
    203591,
    203592,
    203593,
    203594,
    203595,
    203596,
    203597,
    203598,
    203599,
    203600,
    203601,
    203602,
    203603,
    203604,
    203605,
    203606,
    203658,
    203659,
    203660,
    203661,
    203662,
    203663,
    203664,
    203665,
    203666,
    203667,
    203668,
    203669,
    203670,
    203671,
    203672,
    203673,
    203674,
    203675,
    203676,
    203677,
    203681,
    203716,
    3889,
    3892,
    6834,
    6835,
    6836,
    7996,
    7997,
    6786,
    6787,
    8749,
    10053,
    13895,
    13896,
    13897,
    13898,
    13899,
    13900,
    19028,
    20406,
    20407,
    20408,
    21040,
    21154,
    21542,
    22276,
    22277,
    22278,
    22279,
    22280,
    22281,
    22282,
    22742,
    22743,
    22744,
    22745,
    23909,
    24580,
    25345,
    30719,
    30721,
    33047,
    33436,
    33438,
    34718,
    34085,
    34086,
    34087,
    34784,
    34008,
    34827,
    34828,
    38276,
    38277,
    38278,
    38285,
    38160,
    38286,
    38161,
    38162,
    38163,
    38089,
    44692,
    44737,
    44647,
    44648,
    46735,
    45860,
    45998,
    49916,
    52485,
    52486,
    52487,
    54441,
    54451,
    58255,
    59600,
    60222,
    60734,
    61509,
    62058,
    62103,
    62133,
    63205,
    67108,
    69864,
    69865,
    73240,
    90042,
    90986,
    90744,
    90774,
    92553,
    106347,
    106306,
    117483,
    121364,
    138730,
    139293,
    139294,
    139295,
    139296,
    139297,
    139298,
    139301,
    139303,
    139304,
    139305,
    144342,
    151397,
    153169,
    153170,
    153093,
    154791,
    176431,
    176950,
    177761,
    176310,
    180596,    
};

local ITEM_APPEARANCE_IDS = {
    190147,
    190146,
    190145,
    190144,
    190143,
    190142,
    190141,
    190140,
    190139,
    190138,
    190137,
    190136,
    190135,
    190134,
    190133,
    190132,
    190131,
    190130,
    190129,
    190128,
    190127,
    190126,
    190125,
    190124,
    190123,
    190122,
    190121,
    190120,
    190119,
    190118,
    190116,
    190110,
    189976,
    189975,
    189974,
    189973,
    189972,
    189971,
    189970,
    189969,
    189968,
    189967,
    189966,
    189965,
    189964,
    189963,
    189962,
    189961,
    189960,
    189959,
    189958,
    189957,
    189956,
    189955,
    189954,
    189953,
    189952,
    189951,
    189950,
    189949,
    189948,
    189947,
    189946,
    189945,
    189944,
    189943,
    189942,
    189941,
    189918,
    189917,
    189916,
    189915,
    189914,
    189913,
    189912,
    189911,
    189910,
    189909,
    189908,
    189907,
    189906,
    189905,
    189904,
    189903,
    189902,
    189901,
    189900,
    189899,
    189898,
    189897,
    189896,
    189895,
    189894,
    189893,
    189892,
    189891,
    189890,
    189889,
    189888,
    189887,
    189886,
    189885,
    189884,
    189883,
    189882,
    189881,
    189880,
    189879,
    189878,
    189877,
    189876,
}

local _, addon = ...
local TransitionAPI = addon.TransitionAPI;

local NUM_MODEL_X = 4;
local NUM_MODEL_Y = 3;
local MODEL_GAP = 8;
local SCALE = 1.25;
local MODEL_WIDTH, MODEL_HEIGHT = 78*SCALE, 104*SCALE;


local NUM_MODELS = NUM_MODEL_X * NUM_MODEL_Y;

local WardrobeContainer;
local Models;

local function GenerateItemIDsFromAppearances()
    ITEM_IDS = {};

    local sources, sourceID, sourceInfo, itemID;
    local GetAllAppearanceSources = C_TransmogCollection.GetAllAppearanceSources;
    local GetSourceInfo = C_TransmogCollection.GetSourceInfo;
    local tinsert = table.insert;

    for _, appearanceID in ipairs(ITEM_APPEARANCE_IDS) do
        sources = GetAllAppearanceSources(appearanceID);
        sourceID = sources and sources[1];
        if sourceID then
            sourceInfo = GetSourceInfo(sourceID);
            if sourceInfo and sourceInfo.itemID then
                tinsert(ITEM_IDS, sourceInfo.itemID);
            else
                print("No Source Info: "..sourceID);
            end
        else
            print("Cannot Find Appearance: "..appearanceID);
        end
    end
end

local function GenerateItemIDsFromSources()
    ITEM_IDS = {};

    local sources, sourceInfo, itemID;
    local GetSourceInfo = C_TransmogCollection.GetSourceInfo;
    local tinsert = table.insert;

    for _, sourceID in ipairs(ITEM_APPEARANCE_IDS) do
        sourceInfo = GetSourceInfo(sourceID);
        if sourceInfo and sourceInfo.itemID then
            tinsert(ITEM_IDS, sourceInfo.itemID);
        else
            print("No Source Info: "..sourceID);
        end
    end
end

local function GenerateDressableItems()
    local tbl = {};
    for i, v in ipairs(ITEM_IDS) do
        tbl[i] = v;
    end

    ITEM_IDS = {};

    local IsDressableItemByID = C_Item.IsDressableItemByID;
    local n = 0;

    for i, v in ipairs(tbl) do
        if IsDressableItemByID(v) then
            n = n + 1;
            ITEM_IDS[n] = v;
        end
    end
end

local function Model_OnMouseDown(self)
    if IsModifiedClick("DRESSUP") then
        DressUpFrame_Show(DressUpFrame);
        local actor = DressUpFrame.ModelScene:GetPlayerActor();
        actor:TryOn("item:"..self.itemID);
    end
end

local function CreateModel(parent)
    local function OnModelLoaded(f)
        if f.cameraID then
            Model_ApplyUICamera(f, f.cameraID);
        end
    end

    local m = CreateFrame("DressUpModel", nil, parent);
    m:SetSize(MODEL_WIDTH, MODEL_HEIGHT);
    m:SetScript("OnModelLoaded", OnModelLoaded);
    m:SetScript("OnMouseDown", Model_OnMouseDown);
    m.RefreshCamera = OnModelLoaded;

    m:SetAutoDress(false);
    m:SetDoBlend(false);
    m:SetUseTransmogSkin(true);
    m:SetUnit("player");
    m:FreezeAnimation(0, 0, 0);
    m:SetModelDrawLayer("ARTWORK");
    m:EnableMouse(true);

    local label = m:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny");
    label:SetJustifyH("CENTER");
    label:SetJustifyV("TOP");
    label:SetPoint("TOPLEFT", m, "TOPLEFT", 8, -8);
    label:SetPoint("TOPRIGHT", m, "TOPRIGHT", -8, -8);
    label:SetText("Item Name");
    label:SetSpacing(1);

    local font = GameFontNormalTiny:GetFont();
    label:SetFont(font, 8, "OUTLINE");
    label:SetShadowOffset(1, -1);

    m.Label = label;

    TransitionAPI.SetModelLight(m, true, false, -1, 1, -1, 0.8, 1, 1, 1, 0.5, 1, 1, 1);

    return m
end

local function Init()
    if WardrobeContainer then return end;

    --GenerateItemIDsFromAppearances();
    --GenerateDressableItems();
    GenerateItemIDsFromSources();

    local GetItemInfoInstant = GetItemInfoInstant;

    local function SortByType(item1, item2)
        local _, classID1, classID2, subclassID1, subclassID2;
        _, _, _, _, _, classID1, subclassID1 = GetItemInfoInstant(item1);
        _, _, _, _, _, classID2, subclassID2 = GetItemInfoInstant(item2);

        if classID1 == classID2 then
            if subclassID1 == subclassID2 then
                return item1 < item2
            else
                return subclassID1 < subclassID2
            end
        else
            return classID1 < classID2
        end
    end

    table.sort(ITEM_IDS, SortByType);


    WardrobeContainer = CreateFrame("Frame");
    WardrobeContainer:Hide();

    local bg = WardrobeContainer:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints(true);
    bg:SetColorTexture(0, 0, 0);
    WardrobeContainer:SetPoint("CENTER", 0, 0);
    WardrobeContainer:SetSize(8, 8);

    local pageText = WardrobeContainer:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
    WardrobeContainer.pageText = pageText;
    pageText:SetPoint("TOP", WardrobeContainer, "BOTTOM", 0, -8);
    pageText:SetJustifyH("CENTER");

    Models = {};

    local row = 1;
    local col = 1;

    for i = 1, NUM_MODELS do
        if col > NUM_MODEL_X then
            col = 1;
            row = row + 1;
        end
        if not Models[i] then
            Models[i] = CreateModel(WardrobeContainer);
            Models[i]:ClearAllPoints();
            Models[i]:SetPoint("TOPLEFT", WardrobeContainer, "TOPLEFT", MODEL_GAP + (MODEL_WIDTH + MODEL_GAP)*(col - 1), -MODEL_GAP + (MODEL_HEIGHT + MODEL_GAP)*(1 - row));
        end
        col = col + 1;
    end

    WardrobeContainer:SetSize(MODEL_GAP + NUM_MODEL_X*(MODEL_WIDTH + MODEL_GAP), MODEL_GAP + NUM_MODEL_Y*(MODEL_HEIGHT + MODEL_GAP));

    local MAX_PAGE = math.ceil(#ITEM_IDS / NUM_MODELS);
    WardrobeContainer.page = 1;

    local function UpdatePage()
        local indexOffset = (WardrobeContainer.page - 1) * NUM_MODELS;
        local index, itemID, appearanceID, sourceID, cameraID;
        local itemName, quality, r, g, b, itemDesc;
        local _, itemSubType, classID, subclassID;
        for i = 1, NUM_MODELS do
            index = i + indexOffset;
            itemID = ITEM_IDS[index];
            itemSubType = nil;
            if itemID then
                quality = C_Item.GetItemQualityByID(itemID);
                r, g, b = NarciAPI.GetItemQualityColor(quality);
                itemName = C_Item.GetItemNameByID(itemID);
    
                appearanceID, sourceID = C_TransmogCollection.GetItemInfo(itemID);

                --override
                sourceID = ITEM_APPEARANCE_IDS[index];

                if sourceID and sourceID ~= 0 then
                    cameraID = C_TransmogCollection.GetAppearanceCameraIDBySource(sourceID);
                    Models[i].cameraID = cameraID;
                    if NarciAPI.IsHoldableItem(itemID) then
                        Models[i]:SetItemAppearance(appearanceID);
                        Models[i].type = nil;
                    else
                        if Models[i].type ~= "armor" or true then
                            Models[i].type = "armor";
                            TransitionAPI.SetModelByUnit(Models[i], "player");
                        end
                        Models[1]:Undress();
                        Models[i]:TryOn(sourceID);
                        Models[i]:RefreshCamera();
                    end
                    Models[i]:FreezeAnimation(0, 0, 0);
                else
                    Models[i].type = nil;
                    Models[i]:ClearModel();
                end

                _, _, itemSubType, _, _, classID, subclassID = GetItemInfoInstant(itemID);
                if subclassID == 5 then
                    itemSubType = "|cffff80ff"..itemSubType.."|r";
                else
                    itemSubType = "|cffffd100"..itemSubType.."|r";
                end
            else
                itemName = ""
                r = nil;
                Models[i].type = nil;
                Models[i]:ClearModel();
            end
    
            if itemSubType and itemName then
                itemName = itemName.."\n"..itemSubType
            end
            Models[i].Label:SetText(itemName);
            if r then
                Models[i].Label:SetTextColor(r, g, b);
            end

            Models[i].itemID = itemID;
            Models[i].sourceID = sourceID;
        end

        pageText:SetText(WardrobeContainer.page.." / "..MAX_PAGE);
    end

    local function OnMouseWheel(f, delta)
        if delta < 0 and f.page < MAX_PAGE then
            f.page = f.page + 1;
        elseif delta > 0 and f.page > 1 then
            f.page = f.page - 1;
        else
            return
        end

        UpdatePage();
    end

    WardrobeContainer:SetScript("OnMouseWheel", OnMouseWheel);
    WardrobeContainer.UpdatePage = UpdatePage;
end


function NarciDevTool_PreviewItemModel()
    Init();

    local state = not WardrobeContainer:IsShown();
    WardrobeContainer:SetShown(state);

    if state then
        WardrobeContainer.UpdatePage();
    end
end