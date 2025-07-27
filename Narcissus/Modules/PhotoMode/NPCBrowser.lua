local _, addon = ...;

local SetModelLight = addon.TransitionAPI.SetModelLight;

local Narci = Narci;
local L = Narci.L;
local FadeFrame = NarciFadeUI.Fade;
local NarciPhotoModeAPI = NarciPhotoModeAPI;

local BROWSER_WIDTH = 192;
local BROWSER_HEIGHT = 208;
local BROWSER_SHRINK_WIDTH = 16;
local BROWSER_SHRINK_HEIGHT = 16;

local TAB_WIDTH = 192;
local COVER_BUTTON_HEIGHT = 96;
local COVER_BUTTON_WIDTH = 64;
local NUM_COVER_ROW_PER_PAGE = 2;

local BrowserFrame, CategoryTab, EntryTab, MatchTab, HeaderFrame, HomeButton, SearchBox, SearchTrigger, MatchPreviewModel;
local MouseOverButtons, QuickFavoriteButton;
local LoadingIndicator;

local TARGET_MODEL_INDEX = 1;     --Add an NPC to NarciNPCModelFrame(n)
local ACTOR_CREATED = false;      --Whether user has added an NPC from browser or not

local _G = _G;
local max = math.max;
local floor = math.floor;
local tinsert = table.insert;
local tremove = table.remove;
local After = C_Timer.After;

local outSine = addon.EasingFunctions.outSine;
local inOutSine = addon.EasingFunctions.inOutSine;

local function GetApproximation(number)
    --4 Decimals
    return floor(number* 10000 + 0.5)/ 10000
end

local sub = string.sub;
local gsub = string.gsub;
local format = string.format;

local function SortFunc(a, b)
    if a[1] == b[1] then
        return a[2] < b[2]
    else
        return a[1] < b[1]
    end
end

local function HexToRGBPercent(hexColor)
    return GetApproximation(tonumber(sub(hexColor, 1, 2), 16)/255), GetApproximation(tonumber(sub(hexColor, 3, 4), 16)/255), GetApproximation(tonumber(sub(hexColor, 5, 6), 16)/255)
end


--------------------------------------------------------------------------
--Tab Changing Animation    (Choose a category and go)
local SwipeAnim = NarciAPI_CreateAnimationFrame(0.25);

SwipeAnim:SetScript("OnShow", function(self)
    self.point, self.relativeTo, self.relativePoint, self.startOffset, self.offsetY = CategoryTab:GetPoint();
end);

local function Swipe_OnUpdate(self, elapsed)
	self.total = self.total + elapsed;
	local offset = outSine(self.total, self.startOffset, self.endOffset, self.duration);

	if self.total >= self.duration then
		offset = self.endOffset;
		self:Hide();
    end
    CategoryTab:SetPoint(self.point, self.relativeTo, self.relativePoint, offset, self.offsetY);
end

SwipeAnim:SetScript("OnUpdate", Swipe_OnUpdate);


local CURRENT_TAB_INDEX = 1;
local function GoToTab(index, isFavoriteTab)
    if index == CURRENT_TAB_INDEX then
        return
    else
        CURRENT_TAB_INDEX = index;
    end
    SwipeAnim:Hide();
    SwipeAnim.endOffset = (1 - index) * (TAB_WIDTH + 2);
    SwipeAnim:Show();
    EntryTab:SetShown(index == 2);
    MatchTab:SetShown(index == 3);
    if index == 1 then
        SearchTrigger:Show();
        SearchBox:Hide();
        MatchPreviewModel:Hide();
    else
        FadeFrame(HomeButton, 0.2, 1);
        HomeButton.CurrentTabIndex = index;
        if index == 2 then
            SearchTrigger:Hide();
            SearchBox:Hide();
            MatchPreviewModel:Hide();
        else
            --Tab 3
            if isFavoriteTab then
                SearchTrigger:Hide();
                SearchBox:Hide();
                HeaderFrame.Tab3Label:Show();
            else
                HeaderFrame.Tab3Label:Hide();
            end
        end
    end

    MouseOverButtons:Hide();
end


--Opening/closing animation
local animSizing = NarciAPI_CreateAnimationFrame(0.25);
animSizing.duration2 = 0.5;
animSizing.relativeTo = Narci_NPCBrowser_Toggle;
animSizing:SetScript("OnShow", function(self)
    self.startWidth, self.startHeight = BrowserFrame:GetSize();
end);

local function Sizing_OnUpdate(self, elapsed)
	self.total = self.total + elapsed;

    local width = inOutSine(self.total, self.startWidth, self.endWidth, self.duration);
    
	if self.total >= self.duration then
        width = self.endWidth;
        local height = inOutSine(self.total - self.duration, self.startHeight, self.endHeight, self.duration2 - self.duration);
        if self.total >= self.duration2 then
            height = self.endHeight;
            self:Hide();
        end
        BrowserFrame:SetHeight(height);
    end

    BrowserFrame:SetWidth(width);
end

local function Sizing_Collapse_OnUpdate(self, elapsed)
	self.total = self.total + elapsed;

    local width = inOutSine(self.total, self.startWidth, self.endWidth, self.duration);
    local height = inOutSine(self.total, self.startHeight, self.endHeight, self.duration);

    if self.total >= self.duration then
        width = self.endWidth;
        height = self.endHeight;

        if not self.trigger then
            self.trigger = true;
            After(0.15, function()
                FadeFrame(BrowserFrame, 0.15, 0);
            end)
        end

        local offsetY = inOutSine(self.total - self.duration, -5, -60, self.duration2 - self.duration);
        BrowserFrame:SetPoint("TOP", self.relativeTo, "TOP", 0, offsetY);
        if self.total >= self.duration2 then
            self:Hide();
            self.trigger = nil;
        end
    end

    BrowserFrame:SetSize(width, height);
end

animSizing:SetScript("OnUpdate", Sizing_OnUpdate);

local function PlayToggleAnimation(state)
    if animSizing:IsShown() then return end

    if state then
        animSizing.endWidth = BROWSER_WIDTH;
        animSizing.endHeight = BROWSER_HEIGHT;
        animSizing.duration = 0.25;
        animSizing:SetScript("OnUpdate", Sizing_OnUpdate);

        FadeFrame(BrowserFrame, 0.15, 1, 0);
    else
        animSizing.endWidth = BROWSER_SHRINK_WIDTH;
        animSizing.endHeight = BROWSER_SHRINK_HEIGHT;
        animSizing.duration = 0.2;
        animSizing:SetScript("OnUpdate", Sizing_Collapse_OnUpdate);
    end

    animSizing:Show();
end

--------------------------------------------------------------------------

local CP = { --Color presets
    ["r"] = "ce7272",
    ["o"] = "cfa972",       --Brown
    ["y"] = "ffd200",
    ["g"] = "72ce7d",
    ["c"] = "40c7eb",
    ["b"] = "7da7e0",
    ["p"] = "9f72ce",
    ["bp"] = "8c9ec4",      --Pastel Blue
    ["bk"] = "989898",      --Black
    ["tt"] = "b6f0f0",      --Titan
    ["dn"] = "b09dd3",      --Draenei
    ["lg"] = "a2ff00",      --Legion
    ["kt"] = "4eb38c",      --Kultiran
}

for k, v in pairs(CP) do
    CP[k] = {v, HexToRGBPercent(v)};
end

--[[
Weapons
2200    --Vial Offhand
2210    --Wood Shield
--]]

local NPCInfo = {
    --[ID] = { customTitle, color, voice, {weapons} }
    [4968]   = {"", "b", 7216, {2177} },          --Lady Jaina Proudmoore <Ruler of Theramore>
    [64727]  = {"", "b", 34500, {2177} },         --Jaina Kirin Tor
    [120922] = {"Lord Admiral", "bp", 115285, {153575} },        --Jaina 8.0
    [138197] = {"", "bp", 114950, {153575}},       --Little Jaina
    [144437] = {"", "kt", 114408},        --Tandred Proudmoore
    [140917] = {"", "bk", 127768},        --Derek Proudmoore UD
    [70084]  = {"King of Lordaeron", "o", 17398},    --Terenas Menethil
    [115489] = {"", "b", 78206},           --Anduin Lothar
    [115490] = {"", "tt", 78207},          --Prince Llane Wrynn
    [11699]  = {"", "y", 5971},            --Varian Old
    [29611]  = {"", "b", 16105, {45899}},         --King Varian Wrynn
    [142294] = {"", "g", 74134},           --Broll Bearmantle
    [142299] = {"", "o", 72747, {63052} },           --Archdruid Hamuul Runetotem
    [135614] = {"", "b", 74903, {47104, 47104} },         --Master Mathias Shaw
    [29607] = {"", "r", 72298, {171193, 171193} },         --Valeera
    [155496] = {"", "bk", 146147, {171194} },       --Wrathion <The Black Prince> humanoid
    [57777] = {"", "bk", 146147, },       --Wrathion <The Black Prince> Teen
    [44365]  = {"", "p", 95141, {42775} },         --Lady Sylvanas Windrunner <Banshee Queen>
    [144793] = {"", "b", 95141, {128826} },        --Sylvanas Windrunner <Ranger General of Quel'Thalas>
    [25237]  = {"", "r", 16024, {23428, 23428} },           --Garrosh Hellscream <Overlord of the Warsong Offensive>     Northrend
    [71865]  = {"", "r", 20516, {30414} },           --Garrosh Hellscream <Warchief>  --101441 Sha Weapon
    [97346]  = {"", "g", 57827},           --Sira Moonwarden <The Wardens>
    [149126] = {"", "p", 123599, {165224, 165224} },          --Sira Moonwarden <Dark Warden>
    [58207]  = {"", "r", 135369},          --Alexstrasza <Aspect of Life> Dragonkin
    [32295]  = {"", "r", 135371},          --Alexstrasza the Life-Binder <Queen of the Dragons> Dragon     animID 233
    [73691]  = {"", "o", 139316},          --Chromie <The Timewalkers> gnome
    [55913]  = {"", "o", 3525},            --Champion of Time <Bronze Dragonflight>
    [110596] = {"", "y", 71554},          --Calia Human 7.0
    [156513] = {"Princess of Lordaeron", "p", 139555},          --Calia Menethil
    [36743]  = {"", "bk", 19716, {46737} },          --King Genn Greymane  Gilneas City
    [120788] = {"", "o", 134540, {46737} },          --Genn Greymane <King of Gilneas> Human
    [149700] = {"", "o", 134542},          --Genn Greymane <King of Gilneas> Worgen
    [37065]  = {"", "bk", 19613},           --Prince Liam Greymane
    [142816] = {"", "b", 115307},          --Mia Greymane <Queen of Gilneas>
    [150115] = {"", "bk", 71562, {5284, 5284} },          --Princess Tess Greymane
    [35552] = {"", "o", 19501, {15258} },  --Lord Darius Crowley
    [37195] = {"", "bk", 81013, {56171} },  --Lord Darius Crowley Worgen
    [117480] = {"", "tt", 81272, {54877, 54878} },  --Lord Darius Crowley Worgen
    [35378] = {"", "o", 19681, {63227} },  --Lorna Crowley Gilneas
    [93779] = {"", "o", 53022, {60338, 43085}},  --Commander Lorna Crowley <Gilneas Brigade>

    [140176] = {"", "tt", 59119, {55305} },          --Nathanos Blightcaller    65795 Axe
    [20354]  = {"", "o", 5971},            --Nathanos Marris
    [139098] = {"", "kt", 108042},         --Thomas Zelling KT
    [142211] = {"", "p", 123088},          --Thomas Zelling UD
    [6767]   = {"", "bk", 21264, {31669, 31669} },           --Garona Vanilla
    [138708] = {"", "lg", 120388, {141347, 141347} },          --Garona Halforcen
    [26499]  = {"", "bp", 14326, {37579} },          --Arthas <Prince of Lordaeron>
    [32326]  = {"", "p", 14759, {33475} },           --Prince Arthas Menethil UD
    [103996]  = {"", "p", 14759, {33475} },           --Arthas the Lich King      --103996 No weapon     95941 Weapon
    [1748]   = {"", "bp", 5971, {2178, 143} },           --Highlord Bolvar Fordragon
    [95942]  = {"", "y", 121042, },          --Bolvar Fordragon <The Lich King>
    [146986] = {"", "y", 52473},           --The Lich King red
    [148015] = {"", "kt", 111570, {166781} },         --Taelia Fordragon
    [26528]  = {"", "b", 12840, {37579, 12860} },           --Uther the Lightbringer <Knight of the Silver Hand>
    [120424] = {"", "bp", 72735},          --Alonsus Faol <Bishop of Secrets> UD
    [146011] = {"", "o", 115196, {118400} },          --Saurfang Hoody
    [100636] = {"", "r", 115196, {155857} },          --High Overlord Saurfang
    [4949]   = {"", "bk", 7214, {56228} },            --Thrall Old
    [54634]  = {"", "o", 10700, {109674} },           --Thrall <The Earthen Ring> Hoody
    [110516] = {"", "o", 74514, {109674}},           --Thrall <The Earthen Ring>
    [152977] = {"", "o", 137435, {168268} },           --Thrall New
    [54938]  = {"", "b", 7218, {31700} },            --Archbishop Benedictus Old
    [54953]  = {"Twilight Prophet", "p", 127200, {31700} },          --Archbishop Benedictus Twilight Prophet
    [30115]  = {"", "b", 72851, {50268} },           --Vereesa Windrunner <Ranger-General of the Silver Covenant>    42140 Bow
    [121230] = {"", "b", 89530, {151781} },           --Alleria Windrunner
    [152718] = {"", "p", 89611},           --Alleria Windrunner Void
    [152194] = {"", "tt", 127919},         --MOTHER
    [7228]   = {"", "tt", 5851},           --Ironaya
    [154481] = {"", "bk", 76130},          --Spiritwalker Ebonhorn
    [152365] = {"", "b", 134249},          --Kalecgos <Emissary of the Blue Dragonflight>
    [56101]  = {"", "b", 134252},          --Kalecgos <The Spellweaver>
    [28859]  = {"", "b", 14527},           --Malygos Dragon
    [33535]  = {"", "b", 14539},           --Malygos <The Spell-Weaver> Human

    [89975]  = {"", "b", 54048},       --Senegos
    [89794]  = {"", "b", 54105},       --Stellagosa
    [89371]  = {"", "b", 3525},        --Stellagosa Dragon

    [2784]   = {"", "b", 7225, {158463, 161683}},            --King Magni Bronzebeard <Lord of Ironforge>
    [152206] = {"", "b", 115765, {101388, 138831} },          --Magni Bronzebeard <The Speaker>
    [127021] = {"", "b", 113541, {49775, 49774} },          --Muradin Bronzebeard <High Thane>
    [155934] = {"", "o", 14242},           --Brann Bronzebeard <Explorer's League>
    [152503] = {"", "o", 23615},           --Sir Finley Mrrgglton <Explorer's League>
    [152501] = {"", "o", 5998},            --Elise Starseeker <Explorer's League>
    [152502] = {"", "o", 48877},           --Reno Jackson <Explorer's League>
    [44238] =  {"", "bk", 5974},           --Harrison Jones <Archaeology Trainer>
    [8929]   = {"", "b", 7064},            --Princess Moira Bronzebeard <Princess of Ironforge>
    [100979] = {"", "bk", 114682, {95049, 12865} },         --Moira Thaurissan <Dark Iron Representative>
    [153051] = {"", "r", 21567, {22213} },           --Moira Thaurissan <Queen of the Dark Iron>
    [9019]   = {"", "b", 5908},            --Emperor Dagran Thaurissan
    [148104] = {"", "bk", 104920, {154134} },         --Bwonsamdi
    [21984]  = {"", "o", 114405},          --Rexxar <Champion of the Horde> 155098 Visons
    [148369] = {"", "r", 53739},           --Misha
    [157354] = {"", "p", 133720},          --Vexiona
    [1747]   = {"", "b", 21076, {12748} },           --Anduin Wrynn <Prince of Stormwind>
    [69257] = {"", "y", 27559, {12748} },		--Anduin MoP
    [100973] = {"", "b", 73936},           --Anduin Wrynn <Broken King of Stormwind>
    [134202] = {"", "y", 73936, {152482} },           --Anduin Wrynn <King of Stormwind> Helm On
    [91735] = {"", "y", 73936, {152482} },            --Anduin Wrynn <King of Stormwind> Helm Off
    [120264] = {"", "o", 73936},           --Anduin Wrynn <King of Stormwind> Hooded
    [119723] = {"", "b", 81431},           --Image of Aegwynn
    [125885] = {"", "bp", 88534},          --Aman'Thul
    [126267] = {"", "y", 90885},           --Eonar
    [126266] = {"", "tt", 13683},          --Norgannon
    [126268] = {"", "bp", 13683},          --Golganneth
    [125886] = {"", "o", 13683},           --Khaz'goroth
    [154427] = {"", "tt", 86365},          --Aggramar Blue
    [124691] = {"", "r", 86360, {147371} },           --Aggramar Red
    [126010] = {"", "o", 72358},           --Sargeras
    [145802] = {"", "r", 120829},          --Anasterian Sunstrider
    [115213] = {"", "b", 77539},           --Image of Arcanagos
    [114895] = {"", "bk", 77544},          --Nightbane
    [17968] = {"", "lg", 10990},           --Archimonde Hyjal Summit
    [91331] = {"", "lg", 50678},           --Archimonde <The Defiler>  Hellfire Citadel
    [124677] = {"", "dn", 9762},           --Archimonde <Master of the Augari>
    [143009] = {"", "kt", 104320},         --Daelin Proudmoore
    [121144] = {"", "kt", 115763},         --Katherine Proudmoore <Lord Admiral of Kul Tiras>

    [130704] = {"", "r", 108206, {159927} },       --Lord Stormsong
    [134060] = {"", "p", 110178},       --Lord Stormsong K'thir
    [121360] = {"", "r", 113406, {155816} },       --Priscilla Lady Ashvane
    [130934] = {"", "b", 112977, {155763, 155791} },       --Brother Pike
    [121239] = {"", "o", 110633, {155766, 155766} },       --Flynn Fairwind
    [133006] = {"", "o", 105945},       --Lady Meredith Waycrest
    [132994] = {"", "bk", 103406},      --Lord Arthur Waycrest
    [125380] = {"", "o", 103429},       --Lucille Waycrest
    [134953] = {"", "o", 112518},       --Alexander Treadward
    [144755] = {"", "p", 124584},     --Zaxasj the Speaker
    [137069] = {"", "bk", 94999},    --King Rakataka
    [128674] = {"", "r", 95000},     --Gut-Gut the Glutton
    [137194] = {"", "r", 90068},     --Ranishu Grub  Colors
    [134344] = {"", "y", 113927},     --Scrollsage Nola
    [134345] = {"", "g", 113384},     --Collector Kojo
    [134346] = {"", "r", 114411},     --Toki
    [123586] = {"", "o", 113030},     --Kiro
    [126848] = {"", "tt", 97234, {153433} },    --Captain Eudora
    [123876] = {"", "r", 112986},     --Nisha
    [122583] = {"", "r", 111563},     --Meerah
    [127742] = {"", "y", },     --Meerah's Caravan
    [124522] = {"", "o", 115778},     --Alpaca    Colors
    [133392] = {"", "tt", 114398},    --Sethraliss
    [134601] = {"", "r", 107664, {151335} },     --Emperor Korthek
    [128694] = {"", "g", 111567, {151335} },     --Vorrik
    [134292] = {"", "o", 109931},     --Sulthis
    [62837] = {"", "r", 29278},      --Grand Empress Shek'zeer
    [62151] = {"", "o", 32851},      --Xaril the Poisoned Mind
    [64724] = {"", "tt", 31059},     --Karanosh
    [134445] = {"", "r", 135563},     --Zek'voz <Herald of N'Zoth>
    [157620] = {"", "r", 143640},     --Prophet Skitra
    [144754] = {"", "r", 124585},     --Fa'thuul the Feared
    [37955] = {"", "r", 16782},      --Blood-Queen Lana'thel
    [25601] = {"", "tt", 16684},     --Prince Valanar
    [23953] = {"", "o", 16724},      --Prince Keleseth
    [135612] = {"", "y", 112840, {118080} },     --Halford Wyrmbane
    [38243] = {"", "g", 72314},      --Zen'tabra
    [3679] = {"", "g", 62223},      --Naralex
    [97923] = {"", "y", 75430},     --Rensar Greathoof <Archdruid of the Grove>
    [19554] = {"", "p", 31261},      --Dimensius the All-Devouring
    [20454] = {"", "kt", 9161},      --Nexus-King Salhadaar
    [121597] = {"", "p", 89046},     --Locus-Walker
    [104399] = {"", "p", 61633},     --Nexus-Prince Bilaal
    [86235] = {"", "p", 12215},     --Nhallish Void Revenant
    [93068] = {"", "lg", 50621},     --Xhul'horac
    [121663] = {"", "p", 88645},     --Nhal'athoth
    [8379] = {"", "bk", 84242, {29688} },     --Xylem


    [93951] = {"", "p", 5977},             --Gavinrad the Cruel
    [80747] = {"", "r", 6018},             --Golmash Hellscream
    [142275] = {"", "r", 6024},            --Grommash Hellscream <Warchief of the Mag'har>
    [76278] = {"", "r", 46500},            --Grommash Hellscream <Warchief of the Iron Horde>
    [18076] = {"", "kt", 6024},            --Grommash Hellscream <Chieftain of the Warsong Clan> Outland
    [17008] = {"", "p", 45320},            --Gul'dan BC
    [78333] = {"", "lg", 50946},           --Gul'dan 6.0
    --[52222]  = {"The Soulflayer", "r", 8465},       --Hakkar the Soulflayer
    [120533] = {"", "dn", 11789},          --Velen
    [127880] = {"", "dn", 45403},          --Echo of Velen <The Triumvirate>
    [142664] = {"", "dn", 45680},          --High Exarch Yrel <Voice of the Naaru>
    [81412]  = {"", "dn", 45582},          --Vindicator Yrel
    [75992]  = {"", "dn", 45681},          --Yrel
    [80078]  = {"", "dn", 46738},          --Exarch Akama <High Vindicator> Alternate
    [108249] = {"", "bk", 72162},          --Akama <Illidari>
    [18538] = {"", "tt", 68284},           --Ishanah <High Priestess of the Aldor>
    [91923]  = {"", "dn", 45900},          --Exarch Naielle <Rangari Prime>
    [75028]  = {"", "dn", 44640},          --Exarch Maladaar <Speaker for the Dead>
    [80076]  = {"", "dn", 43301},          --Exarch Othaar <Sha'tari Proconsul>
    [75145]  = {"", "dn", 44847},          --Vindicator Maraad
    [80075]  = {"", "dn", 46768},          --Exarch Hataaru <Chief Artificer>
    [19044]  = {"", "r", 11355},           --Gruul the Dragonkiller
    [17545]  = {"", "tt", 51323},          --K'ure
    [18481]  = {"", "tt", 51323},          --A'dal
    [82950]  = {"", "o", 42170},           --Pridelord Karash Saberon
    [77428]  = {"", "o", 42015},           --Imperator Mar'gok <Sorcerer King>
    [109222] = {"", "p", 72243},           --Meryl Felstorm
    [106313] = {"", "bk", 71521},           --Rehgar Earthfury <Hero of the Storm>
    [102846] = {"", "b", 72143},           --Alodi
    [18708]  = {"", "kt", 10820},          --Murmur
    [18166]  = {"", "b", 45024, {28067} },           --Archmage Khadgar <Sons of Lothar>
    [114562] = {"", "b", 1398},            --Khadgar's Upgraded Servant
    [15687]  = {"", "r", 9211},            --Moroes <Tower Steward> UD
    [101276] = {"", "r", 77510},           --Vision of Moroes <Tower Steward>
    [114463] = {"", "bk", 78202, {28067} },          --Medivh
    [117269] = {"", "r", 83568},           --Kil'jaeden <The Deceiver> ToS
    [25315]  = {"", "r", 12504},           --Kil'jaeden <The Deceiver> Sunwell
    [127878] = {"", "dn", 9766},           --Echo of Kil'jaeden <The Triumvirate>
    [125233] = {"", "lg", 87972},          --Talgath <Kil'jaeden's Second>
    [127872] = {"", "dn", 9762},           --Echo of Talgath <Council to the Triumvirate>
    [76268]  = {"", "p", 43586, {110990} },           --Ner'zhul <Warlord of the Shadowmoon Clan> 95946
    [55419]  = {"", "tt", 26138},          --Captain Varo'then <The Hand of Azshara>
    [56190]  = {"", "lg", 50453},          --Mannoroth <The Destructor> Well of Eternity
    [91349]  = {"", "lg", 50455},          --Mannoroth Bone
    [95990]  = {"", "lg", 50482},          --Mannoroth Flesh
    [115427] = {"", "b", 9325},            --Nielas Aran
    [15690]  = {"", "lg", 9322},           --Prince Malchezaar
    [34780]  = {"", "r", 16144},           --Lord Jaraxxus
    [90296]  = {"", "lg", 50250},          --Soulbound Construct
    [92330]  = {"", "lg", 50847},          --Soul of Socrethar
    [75884]  = {"", "r", 43250},           --Rulkan 	Leader of the Shadowmoon Exiles
    [11980]  = {"", "bk", 6024},           --Zuluhed the Whacked <Chieftain of the Dragonmaw Clan>
    [10812] = {"", "r", 5971},             --Grand Crusader Dathrohan
    [10813] = {"", "tt", 63807},           --Balnazzar Stratholme
    [90981] = {"", "p", 63804},            --Balnazzar Darkshore
    [21838] = {"", "o", 9092},             --Terokk
    [84017] = {"", "o", 46475},            --Terokk <The Talon King>
    [83599] = {"", "o", 42887},            --Lithic  daughter of Terokk
    [22871] = {"", "p", 11519},            --Teron Gorefiend Black Temple
    [103144] = {"", "b", 72733},           --Thoradin <King of Arathor>
    [109000] = {"The Four Horsemen", "b", 74263},          --King Thoras Trollbane
    [107806] = {"", "bk", 73977},          --Prince Galen Trollbane <Fallen Prince of Stromgarde>
    [137701] = {"", "r", 111573, {125319, 13814} },          --Danath Trollbane Arathi Red
    [96183] = {"", "b", 111573},           --Danath Trollbane  Helm
    [16819] = {"", "y", 111573},           --Force Commander Danath Trollbane <Sons of Lothar> Outland
    [12126] = {"", "b", 14879},            --Lord Tirion Fordring <Order of the Silver Hand>  Classic
    [31044] = {"", "y", 14568, {13262}},            --Highlord Tirion Fordring  Icecrown 54168
    [20349] = {"", "b", 5971},             --Tirion Fordring   Old Hillsbrad Foothills
    [126319] = {"", "y", 89488, {150577} },           --Turalyon
    [57945] = {"", "o", 25965},            --Nozdormu the Timeless One <Aspect of Time> Huamn
    [27925] = {"", "o", 25954},            --Nozdormu <The Lord of Time> Dragon
    [54432] = {"", "bk", 25936},           --Murozond <The Lord of the Infinite>
    [19935] = {"", "o", 9730},             --Soridormi <The Scale of Sands>     55395 Soridormi <Prime Consort to Nozdormu>
    [143692] = {"", "o", 6638},            --Anachronos
    [162419] = {"", "o", 5983},            --Zidormi
    [133263] = {"", "o", 5971},            --Rhonormu  Silithus
    [22004] = {"", "o", 6018},             --Leoroxx  father of Rexxar  Blade's Edge Mountains
    [151949] = {"", "g", 136237},          --Merithra of the Dream <Daughter of Ysera>
    [55393] = {"", "g", 60787},            --Ysera <The Dreamer> Dargon
    [104762] = {"", "r", 52058},           --Ysera <The Corrupted>
    [58209] = {"", "g", 26152},            --Ysera <Aspect of Dreams> Human
    [106316] = {"", "dn", 71242},          --Farseer Nobundo <The Earthen Ring>
    [85315] = {"", "dn", 44163},           --Vindicator Nobundo    Alternate
    [83474] = {"", "r", 50419},            --Kilrogg Deadeye <Warlord of the Bleeding Hollow>
    [90378] = {"", "lg", 50430},           --Kilrogg Deadeye Hellfire Citadel
    [135618] = {"", "o", 120874},          --Falstad Wildhammer <High Thane>
    [110513] = {"", "o", 20728},           --Kurdran Wildhammer
    [19379] = {"", "o", 1378},             --Sky'ree <Gryphon of Kurdran Wildhammer>
    [78714] = {"", "r", 44529},            --Kargath Bladefist <Warlord of the Shattered Hand> Alternate
    [16808] = {"", "r", 10325},            --Warchief Kargath Bladefist  Outland
    [22917] = {"", "lg", 11466, {32632, 32633} },           --Illidan Stormrage <The Betrayer>  --150732
    [55500] = {"", "kt", 26057, {32065, 32066} },           --Illidan Stormrage  Well of Eternity
    [113851] = {"", "g", 72793, {134845} },                 --Illidan Stormrage <Captain of the Moon Guard>
    [17011] = {"", "p", 62509},            --Blackhand the Destroyer <Warchief of the Horde>
    [77325] = {"", "r", 45420, {113126} },            --Blackhand <Warlord of the Blackrock> in Blackrock Foundry
    --[17028] = {"", "r", 6018},             --Maim Blackhand No pants!
    [10429] = {"", "r", 6018},             --Warchief Rend Blackhand 51419
    [77257] = {"", "r", 46079},            --Orgrim Doomhammer
    [92142] = {"", "lg", 50410, {124388} },            --Blademaster Jubei'thos
    [55971] = {"", "bk", 37644},           --Deathwing <The Destroyer> Dragon
    --[56173] = {"", "bk", 37644},           --Deathwing <The Destroyer> Maelstrom  Too Large!!!
    [33523] = {"", "bk", 5977},            --Neltharion <The Earthwarder>  Human
    [46471] = {"", "bk", 20282},           --Deathwing <Aspect of Death>  Human
    [23284] = {"", "bk", 67792},           --Lady Sinestra
    [45213] = {"", "bk", 20212},           --Sinestra <Consort of Deathwing>
    [1749] = {"", "bk", 5983},             --Lady Katrana Prestor
    [10184] = {"", "bk", 19755},           --Onyxia
    [74594] = {"", "r", 45297},            --Durotan <Chieftain of the Frostwolf Clan>
    [76354] = {"", "bk", 49565},            --Nightstalker <Durotan's Companion>
    [81695] = {"", "p", 46618},            --Cho'gall <Shadow Council>
    [43324] = {"", "p", 22079},            --Cho'gall  Bastion of Twilight
    [11946] = {"", "bp", 6024},             --Drek'Thar <Frostwolf General>   Alterac Valley
    [80597] = {"", "r", 46676},            --Farseer Drek'Thar Alternate
    [21181] = {"", "lg", 3685},            --Cyrukh the Firelord <The Dirge of Karabor>
    [90481] = {"", "o", 44754},            --Draka
    [137472] = {"", "r", 82183},           --Eitrigg

    [41406] = {"The Mother Wisp", "g", 	20733},  --Aessina
    [46753] = {"The Windlord", "tt", 20867},     --Al'Akir
    [32871] = {"", "bp", 15394},            --Algalon the Observer
    [131071] = {"", "bp", 132836, {163037} },          --Queen Azshara Naga
    [54853] = {"", "bp", 26026},             --Queen Azshara WoE
    [104636] = {"", "r", 58861},            --Cenarius Corrupted    --58869 Sacred Vine
    [40773] = {"", "g", 80403},             --Cenarius
    [115813] = {"", "g", 6516},             --Daughter of Cenarius
    [12238] = {"", "g", 1128},              --Zaetar's Spirit
    [71952] = {"", "r", 37257},             --Chi-Ji <The Red Crane>
    [71953] = {"", "bp", 38211},            --Xuen <The White Tiger>
    [71954] = {"", "o", 38755},             --Niuzao <The Black Ox>
    [71955] = {"", "g", 38225},             --Yu'lon <The Jade Serpent>
    [2748] = {"", "tt", 5858},              --Archaedas <Ancient Stone Watcher>
    [52571] = {"", "r", 24479},             --Majordomo Staghelm <Archdruid of the Flame>
    [40140] = {"", "g", 7222},              --Archdruid Fandral Staghelm
    [53286] = {"", "g", 5995},              --Valstann Staghelm
    [53289] = {"", "g", 5998},              --Leyara Wife
    [53014] = {"", "r", 6000},              --Leyara Flame Druid
    [53291] = {"", "r", 11819},             --Istaria  Daughter  Blood Elf Kid
    [32906] = {"", "tt", 15526},            --Freya
    [32913] = {"", "o", 6530},              --Elder Ironbranch
    [32914] = {"", "g", 6530},              --Elder Stonebark
    [32915] = {"", "p", 6530},              --Elder Brightleaf
    [115750] = {"", "tt", 22243},           --Goldrinn <Ancient>
    [97929] = {"", "tt", 22249},            --Tortolla <Ancient>
    [112927] = {"", "lg", 66565},           --Hakkar the Houndmaster
    [108695] = {"", "p", 1248},             --Czaadym <Hakkar's Minion>  Purple Felhound
    [107441] = {"", "r", 1248},             --Zoarg <Hakkar's Minion>  Red
    [108175] = {"", "bk", 1248},            --Pryykun <Hakkar's Minion>  Green
    [114537] = {"", "bp", 77492},           --Helya
    [101582] = {"", "bk", 51440},           --Dakarr <Shadow of Helya>  Nightsaber
    [96211] = {"", "b", 5977},              --Ignaeus Trollbane
    [107993] = {"", "tt", 74117},           --Hodir
    [33118]  = {"", "r", 15567},            --Ignis the Furnace Master
    [11496]  = {"", "p", 6819},             --Immol'thar
    [11486]  = {"", "kt", 5992},            --Prince Tortheldrin <Ruler of the Shen'dralar>
    [36479]  = {"", "bp", 5989},            --Archmage Mordent Evenshade <The Highborne>
    [89355] = {"", "p", 60765, {13753} },             --Prince Farondis
    [97903]  = {"", "o", 58525, {45266, 45287} },            --Jarod Shadowsong     109637
    [108610] = {"", "r", 61722},            --Kathra'natir
    [71155] = {"", "y", 38667},             --Korven the Prime
    [98965] = {"", "p", 54536},             --Kur'talos Ravencrest <Lord of Black Rook Hold>
    [68397] = {"", "bp", 35594},            --Lei Shen <The Thunder King>
    [58817] = {"", "o", 26943},             --Spirit of Lao-Fe <The Slavebinder>
    [61923] = {"", "o", 29368},             --Liu Lang

    [28923] = {"", "tt", 14162},            --Loken
    [106558] = {"", "tt", 72278},           --Mimiron
    --[106678] = {"", "y", },           --Aerial Command Unit <Mimiron's Creation>
    [154418] = {"", "tt", 146847},          --Ra-den <Keeper of Storms> --No sound names 8.3
    [69473]  = {"", "r", 35759},            --Ra-den <Fallen Keeper of Storms>
    [156866] = {"", "p", 144983},           --Ra-den <The Despoiled>
    [120436] = {"", "lg", 83443},           --Fallen Avatar

    [96281] = {"", "g", 54090, {32425} },             --Maiev Shadowsong <Warden>
    [106905] = {"", "tt", 71043},           --Malorne <Ancient>
    [106910] = {"", "tt", 62108},           --Ursol <Ancient>
    [106909] = {"", "tt", 62292},           --Ursoc <Ancient>
    [100497] = {"", "r", 58389},            --Ursoc <Cursed Bear God>
    [55570] = {"", "g", 26490},             --Malfurion Stormrage  WoE
    [15362] = {"", "g", 60972},             --Malfurion Stormrage
    [146990] = {"", "g", 121588},           --Malfurion Stormrage Bear
    [7999] = {"", "g", 114685, {77364} },             --Tyrande Whisperwind <High Priestess of Elune>
    [146927] = {"", "bk", 123536, {164726} },          --Tyrande Whisperwind <The Night Warrior>
    [145357] = {"", "g", 3604},             --Dori'thur <Tyrande's Companion>
    [103769] = {"", "r", 52106},            --Xavius <Nightmare Lord>  Giant
    [113587] = {"", "r", 54473},            --Xavius Defeated
    --Peroth'arn

    [61942] = {"", "y", 34425},            --The Monkey King
    [56336] = {"", "y", 26819},            --Chief Kah Kah
    [61603] = {"", "y", 26819},            --Emperor RikkTik
    [55678] = {"", "r", 31096},            --Riko

    [96219] = {"", "b", 5907},              --Modimus Anvilmar
    [156347] = {"", "bp", 19477},           --Neptulon <The Tidehunter>
    [11502] = {"The Firelord", "r", 8046},  --Ragnaros MC
    [52409] = {"The Firelord", "r", 24531},       --Ragnaros with feet
    [51600] = {"", "r", 23794},            --Lil' Ragnaros
    [143607] = {"", "r", 5907},             --High Justice Grimstone <Herald of Ragnaros>
    [44025] = {"", "o", 71137},             --Therazane <The Stonemother>
    [12201] = {"", "o", 209},               --Princess Theradras
    [119894] = {"", "tt", 71637},           --Odyn <Prime Designate>
    [112046] = {"", "tt", 76146},           --Thorim <The Stormlord>

    [60709] = {"", "r", 28059},             --Qiang the Merciless <Warlord King>
    [101651] = {"", "y", 61869},            --Belysra Starbreeze <Priestess of the Moon>
    [140323] = {"", "o", 123605, {55048} },           --Shandris Feathermoon <General of the Sentinel Army>
    [33196] = {"", "bp", 15777},            --Sif
    
    [73303] = {"", "y", 37308},             --Emperor Shaohao
    [54975] = {"", "b", 27407},             --Aysa Cloudsinger
    [54568] = {"", "r", 27310},             --Ji Firepaw
    [61907] = {"", "y", 29368},             --Kang <Fist of the First Dawn>
    [21212] = {"", "bp", 11533},            --Lady Vashj <Coilfang Matron>

    [10926] = {"", "b", 11819},             --Pamela Redpath
    [11063] = {"", "bk", 5977},             --Carlin Redpath <The Argent Crusade>  uncle
    --[11629] = {"", "b", 5986},              --Jessica Redpath  older sister
    [10936] = {"", "b", 5977},              --Joseph Redpath father
    --[30556] = {"", "b", 8983},              --Marlene Redpath aunt
    --[10938] = {"", "p", 5979},              --Redpath the Corrupted
    --[10937] = {"", "b", 5977},              --Captain Redpath
    [10944] = {"", "b", 5977},              --Davil Lightfire
    [10939] = {"", "p", 6041},              --Marduk the Black
    [10946] = {"", "p", 12939},             --Horgus the Ravager

    [33288] = {"", "p", 15755},             --Yogg-Saron
    [33136] = {"", "p", 99356},             --Guardian of Yogg-Saron
    [72228] = {"", "p", 37147},             --Heart of Y'Shaarj
    [15589] = {"", "p", 8582},              --Eye of C'Thun
    [22137] = {"", "p", 8674},              --Summoned Old God
    [15215] = {"", "p", 62501},             --Mistress Natalia Mar'alith <High Priestess of C'Thun>
    [158041] = {"", "p", 132781},           --N'Zoth the Corruptor
    [159767] = {"", "r", 115595},           --Sanguimar <Blood of N'Zoth>
    [163405] = {"", "r", 106383},           --G'huun
    [141851] = {"", "r", 28513},            --Spawn of G'huun
    [133007] = {"", "r", 115902},           --Unbound Abomination
    [131318] = {"", "r", 101025},           --Elder Leaxa <Voice of G'huun>
    [128184] = {"", "r", 101801},           --Jungo, Herald of G'huun
    [142765] = {"", "r", 98477},            --Ma'da Renkala <Disciple of G'huun>
    [126001] = {"", "p", 93891},            --Uul'gyneth <The Darkness>
    [26861] = {"", "o", 75200},             --King Ymiron
    [96756] = {"", "bk", 54357},            --Ymiron, the Fallen King
    [131442] = {"", "tt", 105628},          --Leandro Royston <Mayor of Falconhurst>
    [16802] = {"", "r", 95137, {168606} },             --Lor'themar Theron   Blood Elf
    [146430] = {"", "bp", 34502},           --Lor'themar Theron <Ranger Lord>
    [19622] = {"", "r", 11268},             --Kael'thas Sunstrider
    [24664] = {"", "bk", 12419},            --Kael'thas Sunstrider - Pale
    [146433] = {"", "bp", 120758},          --High Priestess Liadrin
    [17076]  = {"", "bp", 72771, {24034, 27406} },           --Liadrin Old
    [145793] = {"", "r", 114772, {163831, 163832} },         --Liadrin Arathi
    
    [3057] = {"", "o", 7219},               --Cairne Bloodhoof <High Chieftain>
    [36648]  = {"", "o", 123094},           --Baine Bloodhoof <High Chieftain>
    [149742] = {"", "o", 6058},             --Tamaala Cairne's wife
    [93846] = {"", "o", 74750},             --Mayla Highmountain
    [93841] = {"", "y", 76255},             --Lasan Skyhorn Chieftain
    [93833] = {"", "bp", 73184},            --Jale Rivermane Chieftain
    [93836] = {"", "r", 74745},             --Torok Bloodtotem
    [4046] = {"", "bk", 7220},              --Magatha Grimtotem <Elder Crone>
    [45410] = {"", "bk", 6014},             --Elder Stormhoof <Grimtotem Chief>
    [45438] = {"", "bk", 6011},             --Arnak Grimtotem
    [11858] = {"", "bk", 6008},             --Grundig Darkcloud <Chieftain>
    [99107] = {"", "lg", 6010},             --Feltotem Blademaster
    [2487] = {"", "y", 6008},               --Fleet Master Seahorn

    [96180] = {"", "g", 145490, {53096, 11587} },            --Gelbin Mekkatorque <High Tinker, King of Gnomes>
    [90716] = {"Mechbot", "y", 74125},      --Gelbin Mekkatorque's Steam Armor
    [42489]	= {"", "b", 134538},	        --Captain Tread Sparknozzle <Mekkatorque's Advisor>
    [147950] = {"", "b", 135067},           --Cog Captain Winklespring <G.E.A.R.>
    [40478] = {"", "b", 5937},              --Elgin Clickspring Advisor>
    [147952] = {"", "b", 136565},           --Fizzi Tinkerbow <G.E.A.R.>

    [150208] = {"", "b", 60731},            --Tinkmaster Overspark <Chief Architect of Gnomish Engineering>
    [162393] = {"", "b", 136484},           --Gila Crosswires <Tinkmaster's Assistant>
    [157997] = {"", "bk", 146131, {155762, 155762} },          --Kelsey Steelspark <Gnomeregan Covert Ops>
    [149814] = {"", "b", 134597},           --Sapphronetta Flivvers
    [42396] = {"", "g", 5922},              --Nevin Twistwrench <S.A.F.E. Commander>
    [124153] = {"", "p", 16269},            --Wilfred Fizzlebang <Master Summoner>
    [114596] = {"", "bp", 76192, {18842} },           --Millhouse Manastorm <Kirin Tor>
    [101976] = {"", "bk", 57473},           --Millificent Manastorm <Engineering Genius>
    [116744] = {"", "g", 5808},             --Mekgineer-Lord Thermaplugg
    [149816] = {"", "kt", 133698},          --Prince Erazmin
    [150397] = {"", "y", 132213},           --King Mechagon
    [150760] = {"", "y", 134769},           --Bondo Bigblock <Yard Chief>
    [152747] = {"", "y", 135755},           --Christy Punchcog <Upgrade Specialist>
    [154967] = {"", "y", 132716},           --Walton Cogfrenzy <Chief Architect of Mechagon>

    [145616] = {"", "y", 112983},           --King Rastakhan
    [120904] = {"", "y", },                 --Princess Talanji
    [69918] = {"", "y", 110631},            --Zul the Prophet
    [138967] = {"", "r", 106151},           --Zul, Reborn
    [122760] = {"", "y", 116102},           --Wardruid Loti <Zanchuli Council>
    [126564] = {"", "y", 115119},           --Hexlord Raal <Zanchuli Council>
    [122864] = {"", "tt", 112919},          --Yazma <Zanchuli Council>
    [146124] = {"", "tt", 100495},          --Jo'nok, Bulwark of Torcali <Zanchuli Council>
    [122866] = {"", "y", 102515},           --Vol'kaal <Zanchuli Council>
    [134231] = {"", "bk", 129708},          --High Prelate Rata
    
    [130122] = {"", "bk", 5955},            --Speaker Ik'nal <Shadowtooth Clan>
    [1061] = {"", "r", 5943},               --Gan'zulah <Bloodscalp Chief>

    [69131] = {"", "bp", 35390},            --Frost King Malakk
    [29306] = {"", "bp", 14430},            --Gal'darah <High Prophet of Akali>
    [28503] = {"", "bk", 14016},            --Overlord Drakuru
    [28902] = {"", "r", 5945},              --Warlord Zol'Maz
    [28916] = {"", "r", 5949},              --Tiri Wife of Zol'maz
    [28917] = {"", "r", 5955},              --Yara
    [28918] = {"", "r", 5943},              --Drek'Maz

    [130255] = {"", "g", 12098},            --Zul'jin Amani
    [69134] = {"", "g", 35570},             --Kazra'jin
    [23863] = {"", "o", 24221},             --Daakara <The Invincible>
    [24239] = {"", "p", 12041},             --Hex Lord Malacrass
    [15407] = {"", "g", 1034},              --Chieftain Zul'Marosh

    [10540] = {"", "r", 34556},             --Vol'jin
    [131465] = {"", "r", 111238, {29433} },         --Rokhan NEW
    [145377] = {"", "r", 142796, {29433} },         --Rokhan BFA NEW
    [82877] = {"", "r", 46575},             --High Warlord Volrath <Horde War Captain>
    [158312] = {"", "r", 123091},           --Zekhan
    [16575] = {"", "r", 5943},              --Shadow Hunter Ty'jin <Ears of the Warchief>

    [11380] = {"", "p", 24256},             --Jin'do the Hexxer
    [52148] = {"", "o", 24261},             --Jin'do the Godbreaker
    [2534] = {"", "kt", 24342},             --Zanzil the Outcast
    [69132] = {"", "tt", 35435},            --High Priestess Mar'li    Gurubashi

    [7267] = {"", "o", 5878},               --Chief Ukorz Sandscalp
    [7272] = {"", "o", 	8419},              --Theka the Martyr
    [122661] = {"", "o", 115760},           --General Jakra'zet <Zanchuli Council>

    [14625] = {"", "bk", 7060},             --Overseer Oilfist <The Thorium Brotherhood>
    [10637] = {"", "bk", 7063},             --Malyfous Darkhammer <The Thorium Brotherhood>
    [134578] = {"", "g", 115274},           --Captain Delaryn Summermoon
    [90688] = {"", "lg", 54810},            --Tichondrius the Darkener <Lord of the Nathrezim>
    [110965] = {"", "bp", 58566},           --Elisande <Grand Magistrix>
    [121540] = {"", "lg", 713},             --Lalathin <Elisande's Pet>
    [114915] = {"", "lg", 78373},           --Andaris Narassin
    [101830] = {"", "r", 71525},            --First Arcanist Thalyssra
    [115505] = {"", "r", 74306},            --Chief Telemancer Oculeth
    [104998] = {"", "p", 72159},            --Silgryn
    [115092] = {"", "p", 71132},            --Arcanist Valtrois
    [104218] = {"", "bp", 58654},           --Advisor Melandrus <First Blade of Elisande>
    [103758] = {"", "bp", 58445},           --Star Augur Etraeus
    [104881] = {"", "bp", 58392, {137255, 137258} },           --Spellblade Aluriel <Captain of the Magistrix's Guard>  Lots of Nightborne NPC weapons
    [104528] = {"", "y", 68622},            --High Botanist Tel'arn
    [98208] = {"", "bp", 57776},            --Advisor Vandros

    [92347] = {"", "y", 72092, {42322} },             --Aponi Brightmane <Sunwalker Chieftain>
    [90883]	= {"", "bk", 72221, {108923} },	        --Lord Maxwell Tyrosus
    [16886] = {"", "y", 75746, {26003} },             --Arator the Redeemer
    [90250] = {"", "o", 72221, {85428} },             --Lord Grayson Shadowbreaker
    [17684] = {"", "bk", 9762},             --Vindicator Boros <Triumvirate of the Hand>
    [17844] = {"", "bk", 9762},             --Vindicator Aesom <Triumvirate of the Hand>
    [17843] = {"", "g", 9762},              --Vindicator Kuros <Triumvirate of the Hand>
    [68019] = {"", "lg", 82756},            --Kanrethad Ebonlocke
    [14823] = {"", "bk", 5925},             --Silas Darkmoon
    [98771] = {"", "r", 72590},             --Ritssyn Flamescowl <Council of the Black Harvest>
    [101513] = {"", "bk", 75213},		    --Lord Jorach Ravenholdt #2
    [15552] = {"", "lg", 7071},             --Doctor Weavil
    [21691] = {"", "b", 5925, {42822} },              --Toshley
    [126646] = {"", "b", 94654},            --Magister Umbric
    [132382] = {"", "p", 95017, {125668} },            --Magister Umbric VE

    [35222]  = {"", "r", 137828},          --Trade Prince Gallywix
    [152522] = {"", "o", 137828},          --Gazlowe
    [155390] = {"", "o", 136034},          --Grizzek Fizzwrench
    [2496] = {"", "bk", 7228},             --Baron Revilgaz
    [86225] = {"", "o", 43738},            --Railmaster Rocketspark <Blackfuse Company>
    [72694] = {"", "p", 38462},            --Siegecrafter Blackfuse
    [80808] = {"", "tt", 46128},           --Neesa Nox
    [46078] = {"", "bk", 18812},           --Boss Mida <Her Tallness>
    [75986] = {"", "bk", 18812},            --Ketya Shrediron <Principal Engineer>
    [6946] = {"", "b", 5964},              --Renzik "The Shiv"
    [136579]= {"", "bp", 18812},            --Cesi Loosecannon <Boss of Anyport>
    [41018] = {"", "bp", 136423},           --King Gurboggle
    [149904] = {"", "bp", 136037},          --Neri Sharpfin
    [34954] =  {"", "o", 37113},            --Gobber   

    [46133] = {"", "o", 143110},            --King Phaoris
    [45799] = {"", "o", 22043},             --Prince Nadun
    [47753] = {"", "bk", 145746},           --Dark Pharaoh Tekahn

    [126983] = {"", "r", 97285, {159635, 159635} },            --Harlan Sweete <Lord of the Irontide>
    [126832] = {"", "r", 98113, {159587} },            --Skycap'n Kragg
    [126841] = {"", "r", 98104},            --Sharkbait

    [108571] = {"", "bp", 57869, {128360, 128370} },     --Altruis the Sufferer
    [89362] = {"", "r", 56763, {128359, 128371} },      --Kayn Sunfury
    [21215] = {"", "bk", 11305, {32065, 32066} },        --Leotheras the Blind   21845 Demon Grandpa
    [94836] = {"", "p", 52005, {128360, 128370} },         --Varedis Felsoul
    [98914] = {"", "p", 56205},         --Caria Felsoul
    [7783] = {"", "r", 5995},           --Loramus Thalipedes
    [89398] = {"", "o", 57068, {122430}},  --	Allari the Souleater
    [90624] = {"", "g", 56804, {128359, 128371} },      --Kor'vas Bloodthorn
    [101317] = {"", "p", 57101, {128360, 128370} },     --Illysanna Ravencrest
    [105841] = {"", "g", 53899},        --Lil'idan
    [142152] = {"", "r", 5937},         --Kinndy Sparkshine
    [29261] = {"", "p", 5922},          --Windle Sparkshine
    [16128] = {"", "bp", 15650, {42139} }, --Rhonin <Leader of the Kirin Tor>
    [16800] = {"", "r", 95030, {29114} }, --Grand Magister Rommath
    [16801] = {"", "bp", 72620, {128826} }, --Halduron Brightwing
    [122366]= {"", "lg", 87042},        --Varimathras LEG
    [16287] = {"", "r", 9742},  --Ambassador Sunsorrow
    [20406] = {"", "r", 9730, {27405, 27406} },  --Champion Cyssa Dawnrose
    [10778] = {"", "b", 5980},          --Janice Felstone
    [3520]  = {"", "o", 5983},          --Ol' Emma
    [4488]  = {"", "o", 6036},          --Parqual Fintallas     Desolate Council
    [36296] = {"", "p", 6044},          --Apothecary Hummel
    [16075] = {"", "g", 5964},          --Kwee Q. Peddlefeet
    [13429] = {"", "r", 6632},          --Nardstrum Copperpinch <Smokywood Pastures>
    [13434] = {"", "r", 6629},          --Macey Jinglepocket <Smokywood Pastures>
    [4606] = {"", "bp", 80723},         --Aelthalyste Banshee
    [10436] = {"", "p", 6052},          --Baroness Anastari     Stratholme
    [27683] = {"", "r", 7014},          --Dahlia Suntouch  High Elf
    [28318] = {"", "lg", 16294},        --Grand Apothecary Putress
    [27922] = {"", "bk", 123392, {34269} },   --Ranger Captain Areiel
    [36225] = {"", "bk", 123392, {45085, 45085} },   --Dark Ranger Anya
    [44637] = {"", "bk", 123392, {166783} },   --Dark Ranger Velonara
    [139609] = {"", "o", 5977},         --John J. Keeshan
    [117084] = {"", "bp", 70676, {13623} },       --Kruul     	Doomlord
    [94015]  = {"", "r", 50326, {124085} },        --Kazzak    --Same model as Kaz'rogal 95280
    [31283]  = {"", "r", 14608, {43110} },     --Orbaz Bloodbane <The Hand of Suffering>
    [95136] = {"", "r", 75387, {82594} },    --Addie Fizzlebog <Apprentice Hunter>
    [27210] = {"", "r", 14192, },           --High General Abbendis {14954} Scarlet Shield
    [3977] = {"", "r", 5840, {812} },       --Sally Whitemane
    [639] = {"", "bk", 5780, {68195, 68195} },   --Edwin Vancleef <Defias Kingpin>
    [42372] = {"", "r", 72306, {18816, 18816} },  --Vanessa Vancleef
    [102914] = {"", "g", 75808, {65972} },        --Emmarel Shadewarden
    [3432] = {"", "lg", 6018},          --Mankrik
    [10668] = {"Olgra", "kt", 6027},        --Beaten Corpse Olgra, Mankrik's Wife
    [54870] = {"", "r", 29194, {7612} },      --General Nazgrim
    [109915] = {"The Four Horsemen", "bk", 72381, {38633} },    --Nazgrim
    [112504] = {"The Four Horsemen", "p", 74292, {79321} },     --High Inquisitor Whitemane
    [113580] = {"", "bp", 38692},       --Whitemane's Deathcharger
    [26581] = {"", "bp", 75837, {35939} },     --Koltira Deathweaver
    [29799] = {"", "b", 14674, {35561, 35561} },      --Thassarian
    [18141] = {"", "bp", 6030},         --Greatmother Geyah
    [137837] = {"", "o", 115768, {118400} },     --Overlord Geya'rah
    [67846] = {"", "o", 6018, {13052} },      --Ishi <Blademaster>
    [44640] = {"", "bk", 6021, {105686} },     --High Warlord Cromush
    [37813] = {"", "bp", 16694, {51905} },     --Deathbringer Saurfang
    [25257] = {"Kor\'kron Warlord", "r", 6018, {12784} },  --Saurfang the Younger  Dranosh Saurfang
    [80751] = {"", "o", 6030},          --Mother Kashur
    [21950] = {"", "r", 6018},          --Garm Wolfbrother <Chieftain of the Thunderlord Clan>
    [18106] = {"", "bk", 6024},         --Jorin Deadeye
    [3230] = {"", "bk", 6021, {14870}},      --Nazgrel <Advisor to Thrall>
    [77020] = {"", "o", 39967},         --Kor'gall
    [29227] = {"", "b", 14497, {13262} },      --Highlord Alexandros Mograine <The Ashbringer>
    [28444] = {"The Four Horsemen", "bk", 14715, {40276, 40276} },     --Darion Mograine DK
    [20423] = {"", "p", 5974},          --Kel'Thuzad <The Kirin Tor>
    [15990] = {"", "p", 8811},          --Kel'Thuzad Lich
    [16028] = {"", "o", 8909},          --Patchwerk
    [16061] = {"", "bp", 8859},         --Instructor Razuvious
    [16060] = {"", "b", 8808},          --Gothik the Harvester
    [15953] = {"", "y", 8795},          --Grand Widow Faerlina
    [15954] = {"", "bk", 8846},         --Noth the Plaguebringer
    [15936] = {"", "p", 1333},          --Heigan the Unclean
    [4275] = {"", "lg", 5791, {6322} },  --Archmage Arugal
    [23433] = {"", "r", 9746},          --Barthamus
    [55869] = {"", "o", 25777},         --Alizabal <Mistress of Hate>
    [125083] = {"", "bk", 86926},       --Diima, Mother of Gloom
    [125084] = {"", "r", 87025},        --Noura, Mother of Flames
    [125085] = {"", "p", 86912},        --Asara, Mother of Night
    [125436] = {"", "lg", 87039},       --Thu'raya, Mother of the Cosmos
    [136413] = {"", "lg", 9888},        --Syrawon the Dominus
    [102649] = {"", "p", 82296, {49340, 49340} },   --Lilian Voss
    [138287] = {"", "bk", 140415, {160500, 160501} },   --Lilian Voss Horde

    --Shadowlands
    [165714] = {"", "b", 161885, {177089} },    --Kyrestia the Firstborne <Archon>
    [167168] = {"", "y", 162051, {174413} },    --Devos <Paragon of Loyalty>
    [167410] = {"", "p", 162051, {174415} },    --Devos Purple
    [159929] = {"", "b", 168730, },             --Uther Kyrian Blue
    [166668] = {"", "p", 168730, {173905} },    --Uther Kyrian Purple
    [165716] = {"", "y", 168051, {174438} },    --Xandria <Paragon of Courage>
    [166156] = {"", "y", 169715, {176074, 174433} },    --Thenios <Paragon of Wisdom>
    [166153] = {"", "bp", 169328, {171130, 174429} },   --Vesiphone <Paragon of Purity>
    [166609] = {"", "bp", 162228, {174424} },   --Chyrus <Paragon of Humility>
    [165097] = {"", "bp", 159616, {182152} },   --Polemarch Adrestes
    [165011] = {"", "bp", 160858, },            --Pelagos
    [165042] = {"", "bp", 160091, {171132} },   --Kleia
    [165248] = {"", "y", 158521, },             --Mikanikos <Forgelite Prime>

    [165653] = {"", "bp", 169436},  --Winter Queen
    [166909] = {"", "bp", 169689, {180024} }, --Lord Herne <The Wild Hunt>
    [165249] = {"", "bp", 165162, {180071} },   --Hunt-Captain Korayn
    [165250] = {"", "bp", 174884, {178119} },  --Ara'lon <The Wild Hunt>
    [165218] = {"", "bp", 163204, {178119} }, --Niya
    [165797] = {"", "bp", 159591},      --Lady Moonberry
    [165567] = {"", "tt", 164362},      --Dreamweaver
    [165246] = {"", "bp", 169665},      --Droman Tashmur
    [171648] = {"", "g", 166417},       --Ysera

    [165005] = {"", "r", 166196, {179391} },    --Sire Denathrius
    [158653] = {"", "y", 166196, {178716} },    --Prince Renathal
    [165291] = {"", "bk", 160308, {175939} },   --The Accuser <Harvester of Pride>
    [165589] = {"", "o", 166196, {178716} },    --The Curator <Harvester of Avarice>
    [165269] = {"", "bk", 160497, },    --The Countess <Harvester of Desire>
    [165820] = {"", "bk", 163359, {178494} },   --The Tithelord <Harvester of Envy>
    [165866] = {"", "bk", 160516, },    --The Stonewright <Harvester of Wrath>
    [166442] = {"", "bk", 167241, {173724} },   --The Fearstalker <Harvester of Dread>
    [165652] = {"", "r", 161346}, --Kael'thas
    [170813] = {"", "r", 161346}, --Kael'thas Sunstrider <Lord of the Blood Elves>
    [165864] = {"", "bk", 169130, {175847} },   --Nadjia the Mistblade
    [165031] = {"", "bk", 163273, },            --Theotar <The Mad Duke>
    [165676] = {"", "tt", 161345, {174639} },   --General Draven

    [165182] = {"", "g", 154350, {105037, 105037} }, --Baroness Draka
    [165417] = {"", "bk", 169153, {181255} },   --Alexandros Mograine <The Ashbringer>
    [165819] = {"", "y", 168421, }, --Kel'Thuzad <Archlich>
    [162549] = {"", "g", 169115, {156712} },   --Baroness Vashj <Matron of Spies>
    [165966] = {"", "r", 167843, {32841} },    --Khaliiq <Vashj's Devoted>
    [167748] = {"", "bk", 162237},  --Osbourne Black <Soul Warden>
    [158007] = {"", "o", 168807, },    --Margrave Krexus
    [165571] = {"", "bk", 164384, {176551} }, --Secutor Mevix <House of the Chosen>
    [165333] = {"", "bk", 169700},    --Plague Deviser Marileth
    [165210] = {"", "bk", 169669},  --Emeni <The Slaughter Daughter>
    [165130] = {"", "bk", 168753, {174305, 174305} },  --Bonesmith Heirmir
    
    [165654] = {"", "tt", },    --The Arbitor
    [167486] = {"", "tt", 164386},    --Tal-Inara <Honored Voice>
    [167424] = {"", "o", 165485}, --Overseer Kah-Sher <Will of the Arbiter>
    [163490] = {"", "bk", 165748, {177838}},    --Highlord Bolvar Fordragon <Knights of the Ebon Blade>

    [171770] = {"", "tt", 169718},  --Ve'nari
    [165799] = {"", "tt", },    --The Jailer **Sound
    [171356] = {"", "tt", 171008},    --Runecarver
    [164449] = {"", "tt", 139981, {181374}},    --Sylvanas Windrunner **Sound

    --9.1
    --Sound files are still encrypted
    [178372] = {"", "tt", nil, {183938} },  --Maw Anduin
    [178072] = {"", "tt", nil, {183938} },  --Maw Anduin Helm
    [179314] = {"", "bk", nil, },   --Banshee Sylvanas
    [180211] = {"", "y", nil, {168268} },    --Thrall SL
    [178295] = {"", "r", nil, },  --Kin'tessa Dread Queen
    [177514] = {"", "r", nil, },        --Mal'Ganis     Sound File:4078587

    --9.2
    [185421] = {"", "tt", nil, {185436} },   --The Jailer 2.0
    [180140] = {"", "bk", 182879, {185955} }, --Primus Regular

    [183685] = {"", "bk", 188855, },     --Pocopoc
    [181546] = {"", "y", }, --Prototype of Renewal
    [181548] = {"", "y", }, --Prototype of Absolution
    [181549] = {"", "y", }, --Prototype of War
    [181551] = {"", "y", nil, {189799}}, --Prototype of Duty
    [181286] = {"", "bk", 191052, {42775}},    --Sylvanas 9.2
    [181274] = {"", "bk", 191052},      --Sylvanas Simple
    --[] = {"", "", },
};


local Catalogue = {
    --[[
        [CategoryIndex] = { ["name"] = Category Name,
            [headerIndex] = { ["name"] = Subcategory Name,
                {npcID,  {r, g, b}, weaponMainhand, weaponOffhand},
            }
        }
    --]]

    {["name"] = "Shadowlands",
        [1] = {["name"] = "Bastion",
            165714,    --Kyrestia the Firstborne <Archon>
            167168,    --Devos <Paragon of Loyalty>
            167410,    --Devos Purple
            159929,    --Uther Kyrian Blue
            166668,    --Uther Kyrian Purple
            165716,    --Xandria <Paragon of Courage>
            166156,    --Thenios <Paragon of Wisdom>
            166153,    --Vesiphone <Paragon of Purity>
            166609,    --Chyrus <Paragon of Humility>
            165097,    --Polemarch Adrestes
            165011,    --Pelagos
            165042,    --Kleia
            165248,    --Mikanikos <Forgelite Prime>
        },

        [2] = {["name"] = "Revendreth",
            165005,     --Sire Denathrius
            158653,     --Prince Renathal
            165291,     --The Accuser <Harvester of Pride>
            165589,     --The Curator <Harvester of Avarice>
            165269,     --The Countess <Harvester of Desire>
            165820,     --The Tithelord <Harvester of Envy>
            165866,     --The Stonewright <Harvester of Wrath>
            166442,     --The Fearstalker <Harvester of Dread>
            165652,     --Kael'thas
            170813,     --Kael'thas Sunstrider <Lord of the Blood Elves>
            165864,     --Nadjia the Mistblade
            165031,     --Theotar <The Mad Duke>
            165676,     --General Draven
        },

        [3] = {["name"] = "Ardenweald",
            165653,     --Winter Queen
            166909,     --Lord Herne <The Wild Hunt>
            165249,     --Hunt-Captain Korayn
            165250,     --Ara'lon <The Wild Hunt>
            165218,     --Niya
            165797,     --Lady Moonberry
            165567,     --Dreamweaver
            165246,     --Droman Tashmur
            171648,     --Ysera
        },

        [4] = {["name"] = "Maldraxxus",
            180140,     --Primus
            165182,     --Baroness Draka
            165417,     --Alexandros Mograine <The Ashbringer>
            165819,     --Kel'Thuzad <Archlich>
            162549,     --Baroness Vashj <Matron of Spies>
            165966,     --Khaliiq <Vashj's Devoted>
            167748,     --Osbourne Black <Soul Warden>
            158007,     --Margrave Krexus
            165571,     --Secutor Mevix <House of the Chosen>
            165333,     --Plague Deviser Marileth
            165210,     --Emeni <The Slaughter Daughter>
            165130,     --Bonesmith Heirmir
        },

        [5] = {["name"] = "The Maw",
            165799,     --The Jailer
            171356,     --Runecarver
            171770,     --Ve'nari
            164449,     --Sylvanas Windrunner
            179314,     --Banshee Sylvanas
            178372,     --Maw Anduin
            178072,     --Maw Anduin Helm
            178295,     --Kin'tessa
        },

        [6] = {["name"] = "Oribos",
            165654,     --The Arbitor
            167486,     --Tal-Inara <Honored Voice>
            167424,     --Overseer Kah-Sher <Will of the Arbiter>
            163490,     --Bolvar
            180211,     --Thrall SL
        },

        [7] = {["name"] = "Eternity\'End",
            185421,     --Jailer
            177514,     --MalGanis
            183685,     --Pocopoc
            181546,     --Proto-Winter Queen
            181548,     --Proto-Denathrius
            181549,     --Proto-Primus
            181551,     --Proto-Kyrestia
            181274,     --Sylvanas
            181286,     --Sylvanas
        },
    },

    {["name"] = "Human",
        [1] = {["name"] = "Stormwind",
            115490,         --Prince Llane Wrynn
            11699,          --Varian Gladiator
            29611,          --King Varian Wrynn 
            1747,           --Anduin Wrynn <Prince of Stormwind>
            69257,          --Anduin Wrynn MoP
            100973,         --Anduin Wrynn <Broken King of Stormwind>
            120264,         --Anduin Wrynn <King of Stormwind> Hooded
            134202,         --Anduin Wrynn <King of Stormwind> Helm On
            91735,          --Anduin Wrynn <King of Stormwind> Helm Off
            1748,           --Highlord Bolvar Fordragon
            135612,         --Halford Wyrmbane
            135614,         --Master Mathias Shaw
            54938,          --Archbishop Benedictus Old
            54953,          --Archbishop Benedictus Twilight Prophet
            139609,         --John J. Keeshan
            44238,          --Harrison Jones <Archaeology Trainer>
        },
        
        [2] = {["name"] = "Lordaeron",
            70084,          --Terenas Menethil
            110596,         --Calia Human 7.0
            26499,          --Arthas <Prince of Lordaeron>
            20354,          --Nathanos Marris
            10778,          --Janice Felstone
            3520,           --Ol' Emma
        },

        [3] = {["name"] = "Gilneas",
            36743,          --King Genn Greymane  Gilneas City
            120788,         --Genn Greymane <King of Gilneas> Human
            149700,         --Genn Greymane <King of Gilneas> Worgen
            142816,         --Mia Greymane <Queen of Gilneas>
            37065,          --Prince Liam Greymane
            150115,         --Princess Tess Greymane
            35552,          --Lord Darius Crowley
            37195,          --Lord Darius Crowley Worgen
            117480,          --Lord Darius Crowley Worgen2
            35378,          --Lorna Crowley Gilneas
            93779,          --Commander Lorna Crowley <Gilneas Brigade>
        },

        [4] = {["name"] = "Kultiras",
            143009,         --Daelin Proudmoore
            121144,         --Katherine Proudmoore
            138197,         --Lil' Jaina
            120922,         --Jaina Kultiras
            144437,         --Tandred Proudmoore
            148015,         --Taelia Fordragon
            121360,         --Priscilla Ashvane
            130704,         --Lord Stormsong
            130934,         --Brother Pike
            139098,         --Thomas Zelling KT
            121239,         --Flynn Fairwind
            132994,         --Lord Arthur Waycrest
            133006,         --Lady Meredith Waycrest
            125380,         --Lucille Waycrest
            134953,         --Alexander Treadward
            126983,         --Harlan Sweete
            131442,         --Leandro Royston <Mayor of Falconhurst>
        },

        [5] = {["name"] = "Spellcaster",
            119723,         --Image of Aegwynn
            4968,           --Jaina Theramore
            64727,          --Jaina Kirin Tor Ashen Hair
            16128,          --Rhonin
            18166,          --Archmage Khadgar <Sons of Lothar>
            114463,         --Medivh
            115427,         --Nielas Aran
            102846,         --Alodi
            20423,          --Kel'Thuzad
            8379,           --Xylem
            4275,           --Archmage Arugal
            68019,          --Kanrethad Ebonlocke
        },

        [6] = {["name"] = "Stromgarde",
            103144,         --Thoradin <King of Arathor>
            96211,          --Ignaeus Trollbane
            107806,         --Prince Galen Trollbane <Fallen Prince of Stromgarde>
            137701,         --Danath Trollbane Arathi Red
            96183,          --Danath Trollbane  Helm
            16819,          --Force Commander Danath Trollbane <Sons of Lothar> Outland
        },

        [7] = {["name"] = "Silver Hand",
            26528,          --Uther the Lightbringer <Knight of the Silver Hand>
            29227,          --Highlord Alexandros Mograine
            10812,          --Dathrohan
            20349,          --Tirion Fordring   Old Hillsbrad Foothills
            12126,          --Lord Tirion Fordring <Order of the Silver Hand>  Classic
            31044,          --Highlord Tirion Fordring  Icecrown 54168
            90883,          --Lord Maxwell Tyrosus
            93951,          --Gavinrad the Cruel
            126319,         --Turalyon
            90250,          --Lord Grayson Shadowbreaker
            10944,          --Davil Lightfire
        },

        [8] = {["name"] = "Misc",
            639,        --Edwin Vancleef <Defias Kingpin>
            42372,      --Vanessa Vancleef
            3977,       --Sally Whitemane
            27210,      --High General Abbendis
            101513,     --Lord Jorach Ravenholdt #2
            101276,     --Vision of Moroes <Tower Steward>
            10926,      --Pamela Redpath
            10936,      --Joseph Redpath father
            11063,      --Carlin Redpath <The Argent Crusade>  uncle
        },

    },

    {["name"] = "Elf",
        [1] = {["name"] = "Night Elf",
            22917,            --Illidan Stormrage <The Betrayer>
            55500,            --Illidan Stormrage  Well of Eternity
            113851,           --Illidan Stormrage <Captain of the Moon Guard>
            55570,            --Malfurion Stormrage  WoE
            15362,            --Malfurion Stormrage
            146990,           --Malfurion Stormrage Bear
            7999,             --Tyrande Whisperwind <High Priestess of Elune>
            146927,           --Tyrande Whisperwind <The Night Warrior>
            145357,           --Dori'thur <Tyrande's Companion>
            140323,           --Shandris Feathermoon
            96281,            --Maiev Shadowsong <Warden>
            97903,            --Jarod Shadowsong
            134578,           --Captain Delaryn Summermoon
            97346,            --Sira Moonwarden <The Wardens>
            149126,           --Sira Moonwarden <Dark Warden>
            40140,            --Archdruid Fandral Staghelm
            52571,            --Majordomo Staghelm <Archdruid of the Flame>
            53286,            --Valstann Staghelm
            53289,            --Leyara Wife
            53014,            --Leyara Flame Druid
            142294,           --Broll Bearmantle
            98965,            --Kur'talos Ravencrest <Lord of Black Rook Hold>
            3679,             --Naralex
            97923,            --Rensar Greathoof <Archdruid of the Grove>
            101651,           --Belysra Starbreeze <Priestess of the Moon>
            102914,           --Emmarel Shadewarden
            15215,            --Mistress Natalia Mar'alith <High Priestess of C'Thun>
        },

        [2] = {["name"] = "Nightborne",
            110965,           --Elisande <Grand Magistrix>
            121540,           --Lalathin <Elisande's Pet>
            101830,           --First Arcanist Thalyssra
            115505,           --Chief Telemancer Oculeth
            115092,           --Arcanist Valtrois
            104998,           --Silgryn
            104218,           --Advisor Melandrus <First Blade of Elisande>
            98208,            --Advisor Vandros
            103758,           --Star Augur Etraeus
            104881,           --Spellblade Aluriel <Captain of the Magistrix's Guard>
            104528,           --High Botanist Tel'arn
            114915,           --Andaris Narassin    Felborne
        },

        [3] = {["name"] = "Highborne",
            54853,          --Queen Azshara WoE
            89355,          --Prince Farondis
            36479,          --Archmage Mordent Evenshade <The Highborne>
            11486,          --Prince Tortheldrin <Ruler of the Shen'dralar>
        },

        [4] = {["name"] =  "High Elf",
            145802,        --Anasterian Sunstrider
            146430,        --Lor'themar Theron   Ranger Lord
            146433,        --High Priestess Liadrin
            121230,        --Alleria Windrunner
            144793,        --Sylvanas Ranger General
            30115,         --Vereesa Windrunner <Ranger-General of the Silver Covenant>
            16886,         --Arator the Redeemer
            27683,         --Dahlia Suntouch
            126646,        --Magister Umbric
        },

        [5] = {["name"] =  "Blood Elf",
            19622,      --Kael'thas Sunstrider
            24664,      --Kael'thas Sunstrider - Pale
            16802,      --Lor'themar Theron Blood Elf
            16800,      --Grand Magister Rommath
            16801,      --Halduron Brightwing
            17076,      --Liadrin Old
            145793,     --Liadrin Arathi
            29607,      --Valeera
            16287,      --Ambassador Sunsorrow
            20406,      --Champion Cyssa Dawnrose
            53291,      --Istaria  Daughter  Blood Elf Kid
        },

        [6] = {["name"] = "Void Elf",
            152718,      --Alleria Windrunner Void
            132382,      --Magister Umbric
        },

        [7] = {["name"] = "Darkfallen",
            37955,          --Blood-Queen Lana'thel
            25601,          --Prince Valanar
            23953,          --Prince Keleseth
        },

        [8] = {["name"] = "Naga",
            131071,         --Queen Azshara
            21212,          --Lady Vashj <Coilfang Matron>
        },
    },

    {["name"] = "Tauren",
        [1] = {["name"] = "Thunder Bluff",
            36648,     --Baine Bloodhoof <High Chieftain>
            149742,    --Tamaala Cairne's wife
            3057,      --Cairne Bloodhoof <High Chieftain>
            142299,    --Archdruid Hamuul Runetotem
            92347,     --Aponi Brightmane <Sunwalker Chieftain>
        },

        [2] = {["name"] = "Highmountain",
            154481,         --Spiritwalker Ebonhorn
            93846,          --Mayla Highmountain
            93841,          --Lasan Skyhorn Chieftain
            93833,          --Jale Rivermane Chieftain
            93836,          --Torok Bloodtotem
        },

        [3] = {["name"] = "Grimtotem",
            4046,     --Magatha Grimtotem <Elder Crone>
            45410,    --Elder Stormhoof <Grimtotem Chief>
            45438,    --Arnak Grimtotem
            11858,    --Grundig Darkcloud <Chieftain>
        },

        [4] = {["name"] = "Misc",
            2487,   --Fleet Master Seahorn
            99107,     --Feltotem
        },
    },
    
    {["name"] = "Undead",
        [1] = {["name"] = "The Forsaken",
            44365,          --Lady Sylvanas Windrunner <Banshee Queen>
            164449,         --Sylvanas Windrunner
            140176,         --Nathanos Blightcaller
            102649,         --Lilian Voss
            138287,         --Lilian Voss Horde
            4488,           --Parqual Fintallas
            4606,           --Aelthalyste Banshee
            10436,          --Baroness Anastari
            36296,          --Apothecary Hummel
            27922,          --Ranger Captain Areiel
            36225,          --Dark Ranger Anya
            44637,          --Dark Ranger Velonara
            149126,         --Sira Moonwarden <Dark Warden>
            142211,         --Thomas Zelling UD
        },

        [2] = {["name"] = "Scourge",
            32326,          --Prince Arthas Menethil UD
            103996,         --Arthas the Lich King
            15990,          --Kel'Thuzad Lich
            16060,          --Gothik the Harvester
            15936,          --Heigan the Unclean
            15953,          --Grand Widow Faerlina
            15954,          --Noth the Plaguebringer
            16028,          --Patchwerk
            37813,          --Deathbringer Saurfang
            31283,          --Orbaz Bloodbane
            10939,          --Marduk the Black
            10946,          --Horgus the Ravager
        },

        [3] = {["name"] = "Ebon Blade",
            95942,          --Bolvar Fordragon <The Lich King>
            146986,         --The Lich King red
            163490,         --Bolvar
            26581,          --Koltira Deathweaver
            28444,          --Darion Mograine DK
            109000,         --King Thoras Trollbane
            109915,         --Nazgrim
            112504,         --High Inquisitor Whitemane
            113580,         --Whitemane's Deathcharger
            16061,          --Instructor Razuvious
        },

        [4] = {["name"] = "Neutral",
            156513,         --Calia Menethil
            140917,         --Derek Proudmoore UD
            120424,         --Alonsus Faol <Bishop of Secrets> UD
            109222,         --Meryl Felstorm
            15687,          --Moroes <Tower Steward> UD
        },
    },

    {["name"] = "Gnome",
        [1] = {["name"] = "Gnomeregan",
            96180,      --Gelbin
            90716,      --Gelbin's bot
            116744,     --Mekgineer-Lord Thermaplugg
            157997,     --Kelsey Steelspark <Gnomeregan Covert Ops>
            150208,     --Tinkmaster Overspark <Chief Architect of Gnomish Engineering>
            162393,     --Gila Crosswires <Tinkmaster's Assistant>
            149814,     --Sapphronetta Flivvers
            42489,	    --Captain Tread Sparknozzle <Mekkatorque's Advisor>
            147950,     --Cog Captain Winklespring <G.E.A.R.>
            147952,     --Fizzi Tinkerbow <G.E.A.R.>
            40478,      --Elgin Clickspring
            42396,      --Nevin Twistwrench
        },

        [2] = {["name"] = "Mechagon",
            150397,     --King Mechagon
            149816,     --Prince Erazmin
            150760,     --Bondo Bigblock <Yard Chief>
            152747,     --Christy Punchcog <Upgrade Specialist>
            154967,     --Walton Cogfrenzy <Chief Architect of Mechagon>
        },

        [3] = {["name"] = "Misc",
            124153,     --Wilfred Fizzlebang <Master Summoner>
            114596,     --Millhouse Manastorm <Kirin Tor>
            101976,     --Millificent Manastorm <Engineering Genius>
            14823,      --Silas Darkmoon
            21691,      --Toshley
            15552,      --Doctor Weavil
            29261,      --Windle Sparkshine
            142152,     --Kinndy Sparkshine
            95136,      --Addie Fizzlebog
        },
    },

    {["name"] = "Goblin",
        [1] = {["name"] = "Goblin",
            35222,      --Trade Prince Gallywix
            152522,     --Gazlowe
            155390,     --Grizzek Fizzwrench
            2496,       --Baron Revilgaz
            86225,      --Railmaster Rocketspark <Blackfuse Company>
            72694,      --Siegecrafter Blackfuse
            6946,       --Renzik "The Shiv"
            46078,      --Boss Mida <Her Tallness>
            80808,      --Neesa Nox
            75986,      --Ketya Shrediron <Principal Engineer>
            136579,     --Cesi Loosecannon <Boss of Anyport>
            16075,      --Kwee Q. Peddlefeet
            13429,      --Nardstrum Copperpinch <Smokywood Pastures>
            13434,      --Macey Jinglepocket <Smokywood Pastures>
        },

        [2] = {["name"] = "Gilblin",
            41018,      --King Gurboggle
            149904,     --Neri Sharpfin
        },

        [3] = {["name"] = "Hobgoblin",
            34954,      --Gobber
        },
    },

    {["name"] = "Dragon",
        [1] = {["name"] = "Black",
            55971,          --Deathwing <The Destroyer> Dragon
            33523,          --Neltharion <The Earthwarder>  Human
            46471,          --Deathwing <Aspect of Death>  Human
            23284,          --Lady Sinestra
            45213,          --Sinestra <Consort of Deathwing>
            1749,           --Lady Katrana Prestor
            10184,          --Onyxia
            57777,          --Wrathion Teen
            155496,         --Wrathion <The Black Prince> humanoid
        },

        [2] = {["name"] = "Red",
            58207,      --Alexstrasza <Aspect of Life> Dragonkin
            32295,      --Alexstrasza the Life-Binder <Queen of the Dragons> Dragon
        },

        [3] = {["name"] = "Bronze",
            57945,      --Nozdormu the Timeless One <Aspect of Time> Huamn
            27925,      --Nozdormu <The Lord of Time> Dragon
            54432,      --Murozond <The Lord of the Infinite>
            73691,      --Chromie <The Timewalkers> gnome
            55913,      --Champion of Time <Bronze Dragonflight>
            19935,      --Soridormi <The Scale of Sands>     55395 Soridormi <Prime Consort to Nozdormu>
            143692,     --Anachronos
            162419,     --Zidormi
            133263,     --Rhonormu  Silithus
        },

        [4] = {["name"] = "Blue",
            152365,          --Kalecgos <Emissary of the Blue Dragonflight>
            56101,           --Kalecgos <The Spellweaver>
            28859,           --Malygos Dragon
            33535,           --Malygos <The Spell-Weaver> Human
            115213,          --Image of Arcanagos
        },

        [5] = {["name"] = "Azure",
            89975,       --Senegos
            89794,       --Stellagosa
            89371,       --Stellagosa Dragon
        },

        [6] = {["name"] = "Green",
            55393,           --Ysera <The Dreamer> Dargon
            104762,          --Ysera <The Corrupted>
            58209,           --Ysera <Aspect of Dreams> Human
            151949,          --Merithra of the Dream <Daughter of Ysera>
        },

        [7] = {["name"] = "Misc",
            157354,         --Vexiona
            114895,         --Nightbane
            23433,          --Barthamus
        },
    },

    {["name"] = "Elemental",
        [1] = {["name"] = "Fire",
            11502,          --Ragnaros MC
            52409,          --Ragnaros with feet
            51600,         --Lil' Ragnaros
            21181,          --Cyrukh the Firelord <The Dirge of Karabor>

        },
        
        [2] = {["name"] = "Air",
            46753,          --Al'Akir
        },

        [3] = {["name"] = "Earth",
            44025,           --Therazane <The Stonemother>
            12201,           --Princess Theradras
        },

        [4] = {["name"] = "Water",
            156347,         --Neptulon <The Tidehunter>
        },

        [5] = {["name"] = "Nature",
            32913,              --Elder Ironbranch
            32914,              --Elder Stonebark
            32915,              --Elder Brightleaf
        },

        [6] = {["name"] = "Misc",
            18708,           --Murmur
            114562,          --Khadgar's Upgraded Servant
        },
    },


    {["name"] = "Dwarf",
        [1] = {["name"] = "Ironforge",
            96219,          --Modimus Anvilmar
            2784,           --King Magni Bronzebeard <Lord of Ironforge>
            152206,         --Magni Bronzebeard <The Speaker>
            127021,         --Muradin Bronzebeard <High Thane>
            155934,         --Brann Bronzebeard <Explorer's League>
            8929,           --Princess Moira Bronzebeard <Princess of Ironforge>
        },

        [2] = {["name"] = "Wildhammer",
            135618,              --Falstad Wildhammer <High Thane>
            110513,              --Kurdran Wildhammer
            19379,               --Sky'ree <Gryphon of Kurdran Wildhammer>
        },


        [3] = {["name"] = "Dark Iron",
            9019,            --Emperor Dagran Thaurissan
            100979,          --Moira Thaurissan <Dark Iron Representative>
            153051,          --Moira Thaurissan <Queen of the Dark Iron>
            14625,           --Overseer Oilfist <The Thorium Brotherhood>
            10637,           --Malyfous Darkhammer <The Thorium Brotherhood>
        },
    },

    {["name"] = "Orc",
        [1] = {["name"] = "Warsong",
            80747,         --Golmash Hellscream
            142275,        --Grommash Hellscream <Warchief of the Mag'har>
            76278,         --Grommash Hellscream <Warchief of the Iron Horde>
            18076,         --Grommash Hellscream <Chieftain of the Warsong Clan> Outland
            25237,         --Garrosh Hellscream <Overlord of the Warsong Offensive>     Northrend
            71865,         --Garrosh Hellscream <Warchief>
        },

        [2] = {["name"] = "Frostwolf",
            74594,      --Durotan <Chieftain of the Frostwolf Clan>
            76354,      --Nightstalker <Durotan's Companion>
            90481,      --Draka
            4949,       --Thrall Old
            54634,      --Thrall <The Earthen Ring> Hoody
            110516,     --Thrall <The Earthen Ring>
            152977,     --Thrall New
            180211,     --Thrall SL
            11946,      --Drek'Thar <Frostwolf General>   Alterac Valley
            80597,      --Farseer Drek'Thar Alternate
            3230,       --Nazgrel <Advisor to Thrall>
        },

        [3] = {["name"] = "Blackrock",
            92142,      --Blademaster Jubei'thos
            77257,      --Orgrim Doomhammer
            17011,      --Blackhand the Destroyer <Warchief of the Horde>
            77325,      --Blackhand <Warlord of the Blackrock> in Blackrock Foundry
            10429,      --Warchief Rend Blackhand 51419
            146011,     --Saurfang Hoody
            100636,     --High Overlord Saurfang
            137472,     --Eitrigg
            25257,      --Saurfang the Younger  Dranosh Saurfang
        },

        [4] = {["name"] = "Shadowmoon",
            76268,      --Ner'zhul
            17008,      --Gul'dan BC
            78333,      --Gul'dan 6.0
            22871,      --Teron Gorefiend Black Temple
            75884,      --Rulkan Leader of the Shadowmoon Exiles
        },

        [5] = {["name"] = "Bleeding Hollow",
            83474,          --Kilrogg Deadeye <Warlord of the Bleeding Hollow>
            90378,          --Kilrogg Deadeye Hellfire Citadel
            18106,          --Jorin Deadeye
        },

        [6] = {["name"] = "Shattered Hand",
            78714,            --Kargath Bladefist <Warlord of the Shattered Hand> Alternate
            16808,            --Warchief Kargath Bladefist  Outland
        },

        [7] = {["name"] = "Mag\'har",
            18141,      --Greatmother Geyah
            80751,      --Mother Kashur
            137837,     --Overlord Geya'rah
            44640,      --High Warlord Cromush
            67846,      --Ishi <Blademaster>
        },

        [8] = {["name"] = "Misc",
            54870,          --General Nazgrim
            6767,           --Garona Vanilla
            138708,         --Garona Halforcen
            22004,          --Leoroxx  father of Rexxar  Blade's Edge Mountains
            21984,          --Rexxar <Champion of the Horde> 155098 Visons
            148369,         --Misha
            106313,         --Rehgar Earthfury <Hero of the Storm>
            3432,           --Mankrik
            10668,          --Beaten Corpse Olgra
            21950,          --Garm Wolfbrother
            98771,          --Ritssyn Flamescowl <Council of the Black Harvest>
            11980,          --Zuluhed the Whacked <Chieftain of the Dragonmaw Clan>
            126832,         --Skycap'n Kragg
            126841,         --Sharkbait
        },

    },


    {["name"] = "Troll",
        [1] = {["name"] = "Darkspear",
            10540,          --Vol'jin
            131465,         --Rokhan new
            145377,         --Rokhan BFA new
            82877,          --High Warlord Volrath <Horde War Captain>
            158312,         --Zekhan
            16575,          --Shadow Hunter Ty'jin <Ears of the Warchief>
            38243,          --Zen'tabra
        },

        [2] = {["name"] = "Zandalari",
            145616,         --King Rastakhan
            120904,         --Princess Talanji
            69918,          --Zul the Prophet
            138967,         --Zul, Reborn
            122760,         --Wardruid Loti <Zanchuli Council>
            126564,         --Hexlord Raal <Zanchuli Council>
            122864,         --Yazma <Zanchuli Council>
            146124,         --Jo'nok, Bulwark of Torcali <Zanchuli Council>
            122866,         --Vol'kaal <Zanchuli Council>
            134231,         --High Prelate Rata
        },

        [3] = {["name"] = "Gurubashi",
            11380,             --Jin'do the Hexxer
            52148,             --Jin'do the Godbreaker
            2534,              --Zanzil the Outcast
            69132,             --High Priestess Mar'li 
        },

        [4] = {["name"] = "Amani",
            130255,          --Zul'jin
            69134,           --Kazra'jin
            23863,           --Daakara <The Invincible>
            24239,           --Hex Lord Malacrass
            15407,           --Chieftain Zul'Marosh
        },

        [5] = {["name"] = "Drakkari",
            69131,            --Frost King Malakk
            29306,            --Gal'darah <High Prophet of Akali>
            28503,            --Overlord Drakuru
            28902,            --Warlord Zol'Maz
            28916,            --Tiri Wife of Zol'maz
            28917,            --Yara
            28918,            --Drek'Maz
        },

        [6] = {["name"] = "Farraki",
            7267,             --Chief Ukorz Sandscalp
            7272,             --Theka the Martyr
            122661,           --General Jakra'zet <Zanchuli Council>
        },

        [7] = {["name"] = "Misc",
            148104,         --Bwonsamdi
            131318,          --Elder Leaxa <Voice of G'huun>
            142765,          --Ma'da Renkala <Disciple of G'huun>
            130122,            --Speaker Ik'nal <Shadowtooth Clan>
            1061,               --Gan'zulah <Bloodscalp Chief>
        },

    },

    {["name"] = "Interstellar",
        [1] = {["name"] = "Titans",
            125885,          --Aman'Thul
            126267,          --Eonar
            126266,          --Norgannon
            126268,          --Golganneth
            125886,          --Khaz'goroth
            154427,          --Aggramar Blue
            124691,          --Aggramar Red
            126010,          --Sargeras
            120436,          --Fallen Avatar
            
        },


        [2] = {["name"] = "Naaru",
            18481,          --A'dal
            17545,          --K'ure
        },

        [3] = {["name"] = "Constellar",
            32871,          --Algalon the Observer
        },
    },

    {["name"] = "Titan-forged",

        [1] = {["name"] = "Watchers",
            119894,          --Odyn <Prime Designate>
            154418,          --Ra-den <Keeper of Storms> --No sound names 8.3
            69473,           --Ra-den <Fallen Keeper of Storms>
            156866,          --Ra-den <The Despoiled>
            28923,           --Loken
            107993,          --Hodir
            106558,          --Mimiron
            112046,          --Thorim <The Stormlord>
            32906,           --Freya
            2748,            --Archaedas <Ancient Stone Watcher>
            152194,          --MOTHER
            7228,            --Ironaya

        },

        [2] = {["name"] = "Vrykul",
            114537,          --Helya
            101582,          --Dakarr <Shadow of Helya>  Nightsaber
            26861,           --King Ymiron
            96756,           --Ymiron, the Fallen King
            33196,           --Sif
        },
    
        [3] = {["name"] = "Tol\'vir",
            46133,           --King Phaoris
            45799,           --Prince Nadun
            47753,           --Dark Pharaoh Tekahn
        },

        [4] = {["name"] = "Mogu",
            68397,              --Lei Shen <The Thunder King>
            58817,              --Spirit of Lao-Fe <The Slavebinder>
            60709,              --Qiang the Merciless <Warlord King>
        },

        [5] = {["name"] = "Giants",
            33118,           --Ignis the Furnace Master
        },
    },

    {["name"] = "Demon",
        [1] = {["name"] = "Demon Hunter",
            22917,      --Illidan Stormrage <The Betrayer>
            108571,     --Altruis the Sufferer
            89362,      --Kayn Sunfury
            21215,      --Leotheras the Blind
            94836,      --Varedis Felsoul
            98914,      --Caria Felsoul
            7783,       --Loramus Thalipedes
            90624,      --Kor'vas Bloodthorn
            101317,     --Illysanna Ravencrest
            105841,     --Lil'idan
        },

        [2] = {["name"] = "Eredar",
            17968,      --Archimonde Hyjal Summit
            91331,      --Archimonde <The Defiler>  Hellfire Citadel
            124677,     --Archimonde <Master of the Augari>
            117269,     --Kil'jaeden <The Deceiver> ToS
            25315,      --Kil'jaeden <The Deceiver> Sunwell
            15690,      --Prince Malchezaar
            34780,      --Jaraxxus
            125233,     --Talgath <Kil'jaeden's Second>
            92330,      --Soul of Socrethar
            90296,      --Soulbound Construct
        },
        
        [3] = {["name"] = "Annihilan",
            56190,          --Mannoroth <The Destructor> Well of Eternity
            91349,          --Mannoroth Bone
            95990,          --Mannoroth Flesh
        },
        
        [4] = {["name"] = "Nathrezim",
            90688,          --Tichondrius
            10813,          --Balnazzar Stratholme
            90981,          --Balnazzar Darkshore
            122366,         --Varimathras
            108610,         --Kathra'natir
            178295,         --Kin'tessa
        },

        [5] = {["name"] = "Doomlord",
            117084,       --Kruul
            94015,        --Kazzak
        },

        [6] = {["name"] = "Satyr",
            103769,            --Xavius <Nightmare Lord>  Giant
            103769,            --Xavius <Nightmare Lord>  Human
            113587,            --Xavius Defeated
            --Peroth'arn
        },

        [7] = {["name"] = "Mo\'arg",
            112927,            --Hakkar the Houndmaster
            108695,            --Czaadym <Hakkar's Minion>  Purple Felhound
            107441,            --Zoarg <Hakkar's Minion>  Red
            108175,            --Pryykun <Hakkar's Minion>  Green
        },

        [8] = {["name"] = "Shivarra",
            55869,      --Alizabal <Mistress of Hate>
            125083,     --Diima, Mother of Gloom
            125084,     --Noura, Mother of Flames
            125085,     --Asara, Mother of Night
            125436,     --Thu'raya, Mother of the Cosmos
            136413,     --Syrawon the Dominus
        },
    
    },

    {["name"] = "Draenei",
        [1] = {["name"] = "Argus",
            120533,         --Velen
            127880,         --Echo of Velen <The Triumvirate>
            127878,         --Echo of Kil'jaeden <The Triumvirate>
            127872,         --Echo of Talgath <Council to the Triumvirate>
            91923,          --Exarch Naielle <Rangari Prime>
            75028,          --Exarch Maladaar <Speaker for the Dead>
            80076,          --Exarch Othaar <Sha'tari Proconsul>
            75145,          --Vindicator Maraad
            80075,          --Exarch Hataaru <Chief Artificer>
            17684,          --Vindicator Boros <Triumvirate of the Hand>
            17843,          --Vindicator Kuros <Triumvirate of the Hand>
            17844,          --Vindicator Aesom <Triumvirate of the Hand>
        },

        [2] = {["name"] = "Alternate Draenor",
            75992,          --Yrel
            81412,          --Vindicator Yrel
            142664,         --High Exarch Yrel <Voice of the Naaru>
            80078,          --Exarch Akama <High Vindicator> Alternate
            85315,          --Vindicator Nobundo    Alternate
            
        },

        [3] = {["name"] = "Outland",
            108249,         --Akama <Illidari>
            18538,          --Ishanah
            106316,         --Farseer Nobundo <The Earthen Ring>
        },
    },

    {["name"] = "Draenor",
        [1] = {["name"] = "Gronn",
            19044,          --Gruul the Dragonkiller
        },

        [2] = {["name"] = "Ogres",
            77428,          --Imperator Mar'gok <Sorcerer King>
            81695,          --Cho'gall <Shadow Council>
            43324,          --Cho'gall  Bastion of Twilight
            77020,          --Kor'gall
        },

        [3] = {["name"] = "Arakkoa",
            21838,          --Terokk
            84017,          --Terokk <The Talon King>
            83599,          --Lithic  daughter of Terokk
        },
        
        [4] = {["name"] = "Misc",
            82950,          --Pridelord Karash Saberon

        },
    },

    {["name"] = "Ancients",
        [1] = {["name"] = "August Celestial",
            71952,            --Chi-Ji <The Red Crane>
            71953,            --Xuen <The White Tiger>
            71954,            --Niuzao <The Black Ox>
            71955,            --Yu'lon <The Jade Serpent>
        },

        [2] = {["name"] = "Wild Gods",
            104636,           --Cenarius Corrupted    --58869 Sacred Vine
            40773,            --Cenarius
            115813,           --Daughter of Cenarius
            12238,            --Zaetar's Spirit
            106905,           --Malorne <Ancient>
            106910,           --Ursol <Ancient>
            106909,           --Ursoc <Ancient>
            100497,           --Ursoc <Cursed Bear God>
            115750,           --Goldrinn <Ancient>
            97929,            --Tortolla <Ancient>
        },
    },

    {["name"] = "Void",
        [1] = {["name"] = "Old Gods",
            33288,            --Yogg-Saron
            72228,            --Heart of Y'Shaarj
            15589,            --Eye of C'Thun
            22137,            --Summoned Old God
            158041,           --N'Zoth the Corruptor
            163405,           --G'huun
        },

        [2] = {["name"] = "Faceless",
            144754,     --Fa'thuul the Feared
            33136,      --Guardian of Yogg-Saron
            128184,     --Jungo, Herald of G'huun
        },

        [3] = {["name"] = "K\'thir",
            144755,     --Zaxasj the Speaker
            134060,     --Lord Stormsong K'thir
        },

        [4] = {["name"] = "C\'Thrax",
            126001,     --Uul'gyneth <The Darkness>
        },

        [5] = {["name"] = "Aqir",
            134445,     --Zek'voz
            157620,     --Prophet Skitra
        },

        [6] = {["name"] = "Void Lord",
            19554,      --Dimensius the All-Devouring
        },

        [7] = {["name"] = "Void Revenant",
            121663,     --Nhal'athoth
            93068,     --Xhul'horac
            86235,      --Nhallish
        },

        [8] = {["name"] = "Ethereal",
            20454,      --Nexus-King Salhadaar
            121597,     --Locus-Walker
            104399,     --Nexus-Prince Bilaal
        },

        [9] = {["name"] = "Misc",
            11496,      --Immol'thar
            159767,     --Sanguimar <Blood of N'Zoth>
            141851,     --Spawn of G'huun
            133007,     --Unbound Abomination
        },
    },

    {["name"] = "Pandaria",
        [1] = {["name"] = "Pandaren",
            73303,      --Emperor Shaohao
            54975,      --Aysa Cloudsinger
            54568,      --Ji Firepaw
            61907,      --Kang <Fist of the First Dawn>
            61923,      --Liu Lang
        },

        [2] = {["name"] = "Mantid",
            62837,      --Grand Empress Shek'zeer
            71155,      --Korven the Prime
            62151,      --Xaril the Poisoned Mind
            64724,      --Karanosh
        },

        [3] = {["name"] = "Hozen",
            61942,     --The Monkey King
            56336,     --Chief Kah Kah
            61603,     --Emperor RikkTik
            55678,     --Riko
        },
    },

    {["name"] = "Zandalar",
        [1] = {["name"] = "Vulpera",
            123586,     --Kiro
            126848,     --Captain Eudora
            123876,     --Nisha
            122583,     --Meerah
            127742,     --Caravan
            124522,     --Alpaca
        },

        [2] = {["name"] = "Sethrak",
            133392,     --Sethraliss
            134601,     --Emperor Korthek
            128694,     --Vorrik
            134292,     --Sulthis
        },

        [3] = {["name"] = "Tortollan",
            134344,     --Scrollsage Nola
            134345,     --Collector Kojo
            134346,     --Toki
        },

        [4] = {["name"] = "Ranishu",
            137069,     --King Rakataka
            128674,     --Gut-Gut the Glutton
            137194,     --Ranishu Grub
        },
    },
    --[[
    {["name"] = "",
        [1] = {["name"] = "",

        },
    },
    --]]
};


local ScrollHistory = {};
do
    ScrollHistory.history = {};

    function ScrollHistory:SetActiveCategory(categoryIndex)
        if not self.history[categoryIndex] then
            self.history[categoryIndex] = {};
        end
        self.activeCategoryIndex = categoryIndex;
        self.activeHistory = self.history[categoryIndex];
    end

    function ScrollHistory:GetActiveCategoryIndex()
        return self.activeCategoryIndex
    end

    function ScrollHistory:IsHeaderExpanded(headerIndex)
        return self.activeHistory[headerIndex] == true
    end

    function ScrollHistory:ToggleHeaderExpanded(headerIndex)
        if self:IsHeaderExpanded(headerIndex) then
            self.activeHistory[headerIndex] = false;
        else
            self.activeHistory[headerIndex] = true;
        end
    end

    function ScrollHistory:SaveOffset()
        self.activeHistory.lastOffset = EntryTab.ScrollView:GetOffset();
    end

    function ScrollHistory:GetLastOffset()
        return self.activeHistory.lastOffset
    end
end


local NUM_MAX_ENTRY_BUTTONS = 0;

Catalogue.numCategory = #Catalogue;
for i = 1, Catalogue.numCategory do
    local subCategory = Catalogue[i];
    local numSubcategory = #subCategory;
    local entry;
    local numEntries = 0;
    local numButtons = 0;
    for j = 1, numSubcategory do
        entry = subCategory[j];
        numEntries = numEntries + #entry;
    end
    numButtons = numEntries + numSubcategory;
    subCategory.numEntries = numEntries;
    NUM_MAX_ENTRY_BUTTONS = max(NUM_MAX_ENTRY_BUTTONS, numButtons);
end
Catalogue.numCategory = Catalogue.numCategory + 1;

--------------------------------------------------------------------------
local function UpdateInnerShadowStates(scrollBar, newMax, smoothing)
	local currValue = scrollBar:GetValue();
    local minVal, maxVal = scrollBar:GetMinMaxValues();
    local maxVal = newMax or maxVal;
    if maxVal == 0 then
        scrollBar.Thumb:Hide();
        scrollBar.TopShadow:Hide();
        scrollBar.BottomShadow:Hide();
        return
    else
        scrollBar.Thumb:Show();
    end

    if not smoothing then
        if ( currValue >= maxVal - 12) then
            scrollBar.BottomShadow:Hide();
        else
            scrollBar.BottomShadow:Show();
        end
        
        if ( currValue <= minVal + 12) then
            scrollBar.TopShadow:Hide();
        else
            scrollBar.TopShadow:Show();
        end

        scrollBar.BottomShadow:SetAlpha(1);
        scrollBar.TopShadow:SetAlpha(1);
    else
        if ( currValue >= maxVal - 12) then
            FadeFrame(scrollBar.BottomShadow, 0.2, 0);
            --reach bottom
        else
            if not scrollBar.BottomShadow:IsShown() then
                FadeFrame(scrollBar.BottomShadow, 0.2, 1);
            end
        end
        
        if ( currValue <= minVal + 12) then
            FadeFrame(scrollBar.TopShadow, 0.2, 0);
        else
            if not scrollBar.TopShadow:IsShown() then
                FadeFrame(scrollBar.TopShadow, 0.2, 1);
            end
        end
    end
end

local UpdateModelDelay = NarciAPI_CreateAnimationFrame(0.25);
UpdateModelDelay:SetScript("OnUpdate", function(self, elapsed)
	self.total = self.total + elapsed;
    if self.total >= self.duration then
        self:Hide();
        MatchPreviewModel:Show();
        MatchPreviewModel:SetAlpha(0);
        if self.isDisplayID then
            MatchPreviewModel.isDisplayID = true;
            MatchPreviewModel:SetDisplayInfo(self.id);
        elseif self.isFileID then
            MatchPreviewModel.isDisplayID = nil;
            MatchPreviewModel:SetModel(self.id);
        else
            MatchPreviewModel.isDisplayID = nil;
            MatchPreviewModel:SetCreature(self.id);
        end
        MatchPreviewModel.id = self.id;
        After(0.1, function()
            FadeFrame(MatchPreviewModel, 0.25, 1, 0);
        end)
    end
end)

local function UpdatePreviewModel(id, isDisplayID, isFileID)
    if id then
        if UpdateModelDelay.id ~= id or UpdateModelDelay.isDisplayID ~= isDisplayID then
            UpdateModelDelay.total = 0;
            UpdateModelDelay.id = id;
            UpdateModelDelay.isDisplayID = isDisplayID;
            UpdateModelDelay.isFileID = isFileID;
            UpdateModelDelay:Show();
        end
    end
end

--------------------------------------------------------------------------
--Creature Name Getter
local find = string.find;
local NARCI_NPC_BROWSER_TITLE_LEVEL = NARCI_NPC_BROWSER_TITLE_LEVEL;      --"Level ??"

local CreatureInfoUtil = {};

do
    function CreatureInfoUtil:LoadDatabaseAndGetUnloadedNPC()
        if not NarciPhotoModeDB then
            NarciPhotoModeDB = {};
        end

        if not NarciPhotoModeDB.CreatureInfo then
            NarciPhotoModeDB.CreatureInfo = {};
        end

        local locale = GetLocale();
        if not NarciPhotoModeDB.CreatureInfo[locale] then
            NarciPhotoModeDB.CreatureInfo[locale] = {};
        end

        local db = NarciPhotoModeDB.CreatureInfo[locale];
        self.db = db;


        local npcIDList = {};
        local n = 0;
        local info;
        for creatureID, v in pairs(NPCInfo) do
            info = db[creatureID];
            if info then
                NPCInfo[creatureID][1] = info;
            else
                n = n + 1;
                npcIDList[n] = creatureID;
                self:RequestInfo(creatureID);
            end
        end

        return npcIDList
    end


    --For different versions of API
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local GetInfoByHyperlink = C_TooltipInfo.GetHyperlink;

        local function GetLineText(lines, index)
            if lines[index] and lines[index].leftText then
                return lines[index].leftText;
            end
        end

        function CreatureInfoUtil:RequestInfo(creatureID)
            if not creatureID then return end;
            GetInfoByHyperlink("unit:Creature-0-0-0-0-"..creatureID);
        end

        function CreatureInfoUtil:RequestInfoFromList(list)
            local func = GetInfoByHyperlink;
            for creatureID, v in pairs(list) do
                func("unit:Creature-0-0-0-0-"..creatureID);
            end
        end

        function CreatureInfoUtil:GetName(creatureID)
            if not creatureID then return end;
            local tooltipData = GetInfoByHyperlink("unit:Creature-0-0-0-0-"..creatureID);
            if tooltipData then
                return GetLineText(tooltipData.lines, 1);
            end
        end

        function CreatureInfoUtil:GetTitle(creatureID)
            if (not creatureID) or (creatureID == 0) then return end;
            local tooltipData = GetInfoByHyperlink("unit:Creature-0-0-0-0-"..creatureID);
            if tooltipData then
                local text = GetLineText(tooltipData.lines, 2);
                if text and (not (find(text, "%?") or find(text, NARCI_NPC_BROWSER_TITLE_LEVEL))) then
                    return text
                end
            end
        end

        function CreatureInfoUtil:GetNameAndTitle(creatureID)
            if not creatureID then return end;
            local tooltipData = GetInfoByHyperlink("unit:Creature-0-0-0-0-"..creatureID);
            if tooltipData then
                local nameText = GetLineText(tooltipData.lines, 1);
                if find(nameText, "%?") then
                    return {nameText}, false
                end
                local titleText = GetLineText(tooltipData.lines, 2);
                if titleText and (find(titleText, "%?") or find(titleText, NARCI_NPC_BROWSER_TITLE_LEVEL)) then
                    titleText = nil;
                end

                local info = {nameText, titleText};
                self.db[creatureID] = info;
                return info, nameText == ""
            else
                return {""}, true
            end
        end

    else
        --Old Method
        local VirtualTooltipName = "Narci_CreatureNameRetriever";
        local UIParent = UIParent;
        local VirtualTooltip = CreateFrame("GameTooltip", VirtualTooltipName, UIParent, "GameTooltipTemplate");
        if VirtualTooltip:HasScript("OnTooltipAddMoney") then --dragonflight
            VirtualTooltip:SetScript("OnTooltipAddMoney", nil);
        end
        if VirtualTooltip:HasScript("OnTooltipCleared") then
            VirtualTooltip:SetScript("OnTooltipCleared", nil);
        end
        local lineName = _G[VirtualTooltipName.. "TextLeft1"];
        local lineTitle = _G[VirtualTooltipName.. "TextLeft2"];

        local function IsTooltipLineTitle(text)
            if not text then
                return false
            else
                return not (find(text, "%?") or find(text, NARCI_NPC_BROWSER_TITLE_LEVEL))--"Level %d"
            end
        end

        function CreatureInfoUtil:RequestInfo(creatureID)
            VirtualTooltip:SetHyperlink("unit:Creature-0-0-0-0-"..creatureID);
        end

        function CreatureInfoUtil:RequestInfoFromList(list)
            for creatureID, v in pairs(list) do
                VirtualTooltip:SetHyperlink("unit:Creature-0-0-0-0-"..creatureID);
            end
        end

        function CreatureInfoUtil:GetName(creatureID)
            VirtualTooltip:SetOwner(UIParent, "ANCHOR_NONE");
            VirtualTooltip:SetHyperlink("unit:Creature-0-0-0-0-"..creatureID);
            return lineName:GetText()
        end

        function CreatureInfoUtil:GetTitle(creatureID)
            VirtualTooltip:SetOwner(UIParent, "ANCHOR_NONE");
            VirtualTooltip:SetHyperlink("unit:Creature-0-0-0-0-"..creatureID);
            if IsTooltipLineTitle(lineTitle:GetText()) then
                return lineTitle:GetText()
            else
                return false
            end
        end

        local TEMP_NAME;
        function CreatureInfoUtil:GetNameAndTitle(creatureID)
            VirtualTooltip:SetOwner(UIParent, "ANCHOR_NONE");
            VirtualTooltip:SetHyperlink(format("unit:Creature-0-0-0-0-%d", creatureID));
            TEMP_NAME = lineName:GetText() or "";

            if find(TEMP_NAME, "%?") then
                return {creatureID}, false
            end

            local info;
            if IsTooltipLineTitle(lineTitle:GetText()) then
                info = {TEMP_NAME, lineTitle:GetText()};
            else
                info = {TEMP_NAME};
            end
            self.db[creatureID] = info;
            return info, (TEMP_NAME == "")
        end
    end
end

--------------------------------------------------------------------------
--My Favorites
local FavUtil = {};
FavUtil.favNPCs = {};
FavUtil.numFavs = 0;

function FavUtil:Load()
    if not NarcissusDB then
        print("Cannot find NarcissusDB");
        return
    end

    NarcissusDB.Favorites = NarcissusDB.Favorites or {};
    NarcissusDB.Favorites.FavoriteCreatureIDs = NarcissusDB.Favorites.FavoriteCreatureIDs or {};
    self.db = NarcissusDB.Favorites.FavoriteCreatureIDs;

    local numFavs = 0;
    for npcID, isFav in pairs(self.db) do
        if isFav then
            self.favNPCs[npcID] = true;
            numFavs = numFavs +1;
            CreatureInfoUtil:RequestInfo(npcID);
        end
    end
    self.numFavs = numFavs;

    return numFavs
end

function FavUtil:Add(creatureID)
    if creatureID then
        self.favNPCs[creatureID] = true;
        self.db[creatureID] = true;
        self.numFavs = self.numFavs + 1;
        PlaySound(39672, "SFX");
        return true;
    else
        return false;
    end
end

function FavUtil:Remove(creatureID)
    if not creatureID then return false end;
    self.favNPCs[creatureID] = false;
    local numFavs = 0;
    self.db = {};
    for id, isFav in pairs(self.favNPCs) do
        if isFav then
            self.db[id] = true;
            numFavs = numFavs + 1;
        end
    end
    self.numFavs = numFavs;

    return numFavs;
end

function FavUtil:IsFavorite(creatureID)
    return self.favNPCs[creatureID];
end

function FavUtil:GetFavoriteNPCs()
    return self.favNPCs;
end

function FavUtil:GetNumFavorites()
    return self.numFavs or 0;
end


--------------------------------------------------------------------------
local NPCCardAPI = {};

local function ShowMouseOverButtons(anchorButton)
    MouseOverButtons:SetPoint("RIGHT", anchorButton, "RIGHT", -2, 0);
    MouseOverButtons:Show();
    MouseOverButtons:SetParent(anchorButton);
    MouseOverButtons.parent = anchorButton;
    QuickFavoriteButton.parent = anchorButton;
    QuickFavoriteButton.isFav = anchorButton.isFav;

    if anchorButton.isFav then
        QuickFavoriteButton.Icon:SetTexCoord(0.75, 1, 0.25, 0.5);
    else
        QuickFavoriteButton.Icon:SetTexCoord(0.5, 0.75, 0.25, 0.5);
    end

    MouseOverButtons.WeaponMark:SetShown(anchorButton.weapons);
end

local function SetNPCModel(model, id, isDisplayID)
    model.isModelLoaded = false;
    model:ClearModel();
    model.isCameraDirty = true;
    if isDisplayID then
        model:SetDisplayInfo(id);
        model.displayID = id;
        model.creatureID = nil;
    else
        model:SetCreature(id);
        model.creatureID = id;
        model.displayID = nil;
    end

    model:SetModelAlpha(0);
    After(0.1, function()
        model:SetModelAlpha(1);
	end);
end

local function NPCCard_OnEnter(self)
    FadeFrame(self.Highlight, 0.12, 1);

    if self.creatureID then
        ShowMouseOverButtons(self);
    else
        MouseOverButtons:Hide();
    end
end

local function NPCCard_OnLeave(self)
    self.Highlight:Hide();
end

local function NPCCard_OnClick(self, button, down, holdWeapon)
    if self.creatureID or self.displayID then
        ACTOR_CREATED = true;
        local model = _G["NarciNPCModelFrame"..TARGET_MODEL_INDEX];
        if self.displayID then
            SetNPCModel(model, self.displayID, true);
        else
            SetNPCModel(model, self.creatureID);
        end

        model.holdWeapon = holdWeapon;
        model.equippedWeapons = self.weapons;
        if holdWeapon and self.weapons then
            for i = 1, #self.weapons do
                model:EquipItem(self.weapons[i]);
            end
        end
        if self.voiceID then
            PlaySound(self.voiceID, "Dialog");
        end

        local creatureName = self.creatureName;
        model.creatureName = creatureName;
        if self.hasPortrait and self.creatureID then
            NarciPhotoModeAPI.OverrideActorInfo(TARGET_MODEL_INDEX, creatureName, self.weapons, "Interface/AddOns/Narcissus/Art/Widgets/NPCBrowser/Portraits/".. self.creatureID);
        else
            NarciPhotoModeAPI.OverrideActorInfo(TARGET_MODEL_INDEX, creatureName, self.weapons);
        end
        model:SetActive(true);

        if button == "RightButton" then
            BrowserFrame:Close();
        end
    end
end

local function AddModelAndEquipItems(self, button)
    if not MouseOverButtons.parent then return end
    local holdWeapon = true;
    NPCCard_OnClick(MouseOverButtons.parent, button, nil, holdWeapon);
end


local function DisplayNPCInCategory(categoryID, fromRefresh)
    ScrollHistory:SetActiveCategory(categoryID);

    local frame = EntryTab;
    if not frame.ScrollView then
        local ScrollView = NarciAPI.CreateScrollView(frame);
        frame.ScrollView = ScrollView;
        ScrollView:SetSize(192, 192);
        ScrollView:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);
        ScrollView:SetStepSize(32 * 2);
        ScrollView:OnSizeChanged();
        ScrollView:SetAlwaysHideScrollBar(true);

        local function NPCButton_Create()
            local obj = CreateFrame("Button", nil, ScrollView, "NarciNPCButtonWithPortaitTemplate");
            obj:SetScript("OnEnter", NPCCard_OnEnter);
            obj:SetScript("OnLeave", NPCCard_OnLeave);
            return obj
        end

        local function NPCButton_Remove(obj)
            obj.HighlightNPC:Hide();
            obj.HighlightFull:Hide();
        end

        ScrollView:AddTemplate("NPCButton", NPCButton_Create, NPCButton_Remove);
    end

    local category = Catalogue[categoryID];
    if not category then return end;


    local content = {};
    local headerHeight = 16;
    local buttonHeight = 32;
    local offsetY = 0;
    local n = 0;
    local top, bottom;

    for headerIndex, subCategory in ipairs(category) do
        local firstEntry = true;
        for _, creatureID in ipairs(subCategory) do
            if firstEntry then
                firstEntry = false;
                n = n + 1;
                top = offsetY;
                bottom = offsetY + headerHeight;
                content[n] = {
                    dataIndex = n,
                    templateKey = "NPCButton",
                    setupFunc = function(obj)
                        NPCCardAPI:SetHeader(obj, headerIndex, subCategory.name, #subCategory)
                    end,
                    top = top,
                    bottom = bottom,
                };
                offsetY = bottom;
                if not ScrollHistory:IsHeaderExpanded(headerIndex) then
                    break
                end
            end

            n = n + 1;
            top = offsetY;
            bottom = offsetY + buttonHeight;
            content[n] = {
                dataIndex = n,
                templateKey = "NPCButton",
                setupFunc = function(obj)
                    NPCCardAPI:SetNPC(obj, creatureID);
                end,
                top = top,
                bottom = bottom,
            };
            offsetY = bottom;
        end
    end

    local retainPosition = fromRefresh;
    frame.ScrollView:SetContent(content, retainPosition);

    if not fromRefresh then
        local lastOffset = ScrollHistory:GetLastOffset();
        if lastOffset then
            frame.ScrollView:SnapTo(lastOffset);
        end
        After(0, function()
            GoToTab(2);
        end)
    end
end


local function Category_OnClick(self)
    ScrollHistory:ToggleHeaderExpanded(self.headerIndex);
    DisplayNPCInCategory(ScrollHistory:GetActiveCategoryIndex(), true);
end


function NPCCardAPI:SetNPC(button, id)
    button.mode = "npc";
    button:SetHeight(32);
    button.Highlight = button.HighlightNPC;

    local info = NPCInfo[id];
    button.creatureID = id;

    if info then
        button.isCategorized = true;
        button.voiceID = info[3];
        button.weapons = info[4];
        button.hasPortrait = true;
        if info[1][2] then
            button.Name:SetText(info[1][1]);
            button.Title:SetText(info[1][2]);
            button.Name:Show();
            button.Title:Show();
            button.NameCenter:Hide();
            button.hasTitle = true;
        else
            button.NameCenter:SetText(info[1][1]);
            button.NameCenter:Show();
            button.Name:Hide();
            button.Title:Hide();
            button.hasTitle = nil;
        end

        local color = CP[info[2]] or {"cccccc", 0.5, 0.5, 0.5};
        button.ColorBackground:SetColorTexture(color[2], color[3], color[4]);
        button.Title:SetTextColor(color[2], color[3], color[4]);
        button.ColorBackground:Show();
        button.creatureName = "|cff".. color[1] .. info[1][1] .."|r";   --for actor panel label
        local texture = "Interface/AddOns/Narcissus/Art/Widgets/NPCBrowser/Portraits/".. id;
        button.Portrait:SetTexture(texture);
        button.HighlightNPC:SetTexture(texture);
    else
        button.hasPortrait = nil;
        button.Portrait:SetTexture(nil);
        button.HighlightNPC:SetTexture(nil);
    end

    button.CategoryName:Hide();
    button.Count:Hide();
    button.ExpandMark:Hide();
    button.GreyBackground:Hide();
    button.HighlightFull:Hide();
    button.Portrait:Show();

    button:SetScript("OnClick", NPCCard_OnClick);

    --Favorites
    if FavUtil:IsFavorite(id) then
        button.isFav = true;
        button.Star:Show();
    else
        button.isFav = nil;
        button.Star:Hide();
    end
end

function NPCCardAPI:SetHeader(button, headerIndex, name, numChild)
    button.mode = "category";
    button.creatureID = nil;
    button.creatureName = nil;
    button.isFav = false;
    button.headerIndex = headerIndex;
    button:SetHeight(16);
    button.Highlight = button.HighlightFull;

    button.Name:Hide();
    button.Title:Hide();
    button.NameCenter:Hide();
    button.ColorBackground:Hide();
    button.Portrait:Hide();
    button.HighlightNPC:Hide();

    button.CategoryName:Show();
    button.Count:Show();
    button.ExpandMark:Show();
    button.GreyBackground:Show();
    button.Star:Hide();

    button.CategoryName:SetText(name);
    button.Count:SetText(numChild);
    button.numChild = numChild;

    button:SetScript("OnClick", Category_OnClick);

    self:UpdateCollapsed(button);
end

function NPCCardAPI:UpdateCollapsed(button)
    if button.headerIndex then
        if ScrollHistory:IsHeaderExpanded(button.headerIndex) then
            button.ExpandMark:SetTexCoord(0, 1, 1, 0);
        else
            button.ExpandMark:SetTexCoord(0, 1, 0, 1);
        end
    end
end


local upper = string.upper;
local HighlightMatchedWord;

do
    local textLocale = GetLocale();
    if textLocale == "enUS" or textLocale == "ruRU" then
        function HighlightMatchedWord(name, keyword)
            if keyword then
                keyword = gsub(keyword, "^%l", upper);
                keyword = gsub(keyword, " %l", upper);
                return gsub(name, keyword, "|cffffffff"..keyword.."|r", 1);
            else
                return "|cffffffff"..name.."|r";
            end
        end
    else
        function HighlightMatchedWord(name, keyword)
            if keyword then
                return gsub(name, keyword, "|cffffffff"..keyword.."|r", 1);
            else
                return "|cffffffff"..name.."|r";
            end
        end
    end
end

function NPCCardAPI:SetMatchedNPC(button, id, name, title, keyword)
    if id ~= button.creatureID then
        button.mode = "npc";
        button.creatureID = id;

        if title then
            button.hasTitle = true;
            button.Name:Show();
            button.Title:Show();
            button.NameCenter:Hide();
            button.Name:SetTextColor(0.72, 0.72, 0.72);
            button.Title:SetText(title);
        else
            button.hasTitle = nil;
            button.Name:Hide();
            button.Title:Hide();
            button.NameCenter:Show();
            button.NameCenter:SetTextColor(0.72, 0.72, 0.72);
        end
    end

    button.creatureName = name;

    --Highlight matched words
    name = HighlightMatchedWord(name, keyword)
    if button.hasTitle then
        button.Name:SetText(name);
    else
        button.NameCenter:SetText(name);
    end

    button.Highlight:SetAlpha(0)

    --Favorites
    if FavUtil:IsFavorite(id) then
        button.isFav = true;
        button.Star:Show();
    else
        button.isFav = nil;
        button.Star:Hide();
    end
end


--------------------------------------------------------------------------
local function CreateSmoothScroll(scrollFrame, buttonHeight, numButtonPerpage, step, positionFunc)
    local totalHeight = floor(numButtonPerpage * buttonHeight + 0.5);
    local maxScroll = max(0, totalHeight - numButtonPerpage * buttonHeight);
    scrollFrame.scrollBar:SetMinMaxValues(0, maxScroll)
    scrollFrame.scrollBar:SetValueStep(0.001);
    scrollFrame.buttonHeight = totalHeight;
    scrollFrame.range = 0; --maxScroll
    scrollFrame.scrollBar:SetScript("OnValueChanged", function(self, value)
        self:GetParent():SetVerticalScroll(value);
        UpdateInnerShadowStates(self, nil, false);
    end)
    NarciAPI_SmoothScroll_Initialization(scrollFrame, nil, nil, step/(numButtonPerpage), 0.14, nil, positionFunc);
end

local function SetUpMatchButton(button, creatureData, keyword)
    if creatureData then
        button:Show();
        if creatureData[3] then
            --displayID
            local displayID = creatureData[3];
            button.creatureID = nil;
            button.displayID = displayID;
            button.fileID = nil;
            button.Name:Show();
            button.Title:Show();
            button.NameCenter:Hide();
            button.Name:SetTextColor(1, 1, 1);
            button.Title:SetText("DisplayID");
            button.Name:SetText(displayID);
            button.isFav = nil;
            button.Star:Hide();
            button.creatureName = "|cffffd200DisplayID: "..displayID.."|r";
        elseif creatureData[4] then
            --FileID
            local fileID = creatureData[4];
            button.creatureID = nil;
            button.displayID = nil;
            button.fileID = fileID;
            button.Name:Show();
            button.Title:Show();
            button.NameCenter:Hide();
            button.Name:SetTextColor(1, 1, 1);
            button.Title:SetText("File");
            button.Name:SetText(fileID);
            button.isFav = nil;
            button.Star:Hide();
            button.creatureName = "|cffffd200File: "..fileID.."|r";
        else
            button.displayID = nil;
            button.fileID = nil;
            local id = creatureData[2];
            local name, title;
            if id ~= button.creatureID then
                button.creatureID = id;
                name = creatureData[1];
                title = CreatureInfoUtil:GetTitle(id);
                if title then
                    button.hasTitle = true;
                    button.Name:Show();
                    button.Title:Show();
                    button.NameCenter:Hide();
                    button.Name:SetTextColor(0.72, 0.72, 0.72);
                    button.Title:SetText(title);
                else
                    button.hasTitle = nil;
                    button.Name:Hide();
                    button.Title:Hide();
                    button.NameCenter:Show();
                    button.NameCenter:SetTextColor(0.72, 0.72, 0.72);
                end
            else
                return
            end

            button.creatureName = "|cffffd200"..name.."|r";

            --Highlight matched words
            name = HighlightMatchedWord(name, keyword)
            if button.hasTitle then
                button.Name:SetText(name);
            else
                button.NameCenter:SetText(name);
            end

            --Favorites
            if FavUtil:IsFavorite(id) then
                button.isFav = true;
                button.Star:Show();
            else
                button.isFav = nil;
                button.Star:Hide();
            end
        end
    else
        button:Hide();
        button.creatureID = nil;
        button.displayID = nil;
    end
end

local function MatchButton_OnEnter(self)
    self.Highlight:Show();
    SetModelLight(MatchPreviewModel, true, false, - 0.44699833180028 ,  0.72403680806459 , -0.52532198881773, 0.8, 172/255, 172/255, 172/255, 1, 0.8, 0.8, 0.8);
    if self.displayID then
        UpdatePreviewModel(self.displayID, true);
        MouseOverButtons:Hide();
    elseif self.creatureID then
        UpdatePreviewModel(self.creatureID);
        ShowMouseOverButtons(self);
    elseif self.fileID then
        UpdatePreviewModel(self.fileID, nil, true);
        MouseOverButtons:Hide();
    end
end

local function MatchButton_OnLeave(self)
    if not self:IsMouseOver() then
        self.Highlight:Hide();
    end
end


local function SetCreaturePreview(id)
    local model = MatchPreviewModel;
    if id then
        model:SetAlpha(0);
        model:SetCreature(id);
        model.id = id;
        FadeFrame(model, 0.25, 1);
        MatchTab.Notes:Hide();
    else
        FadeFrame(model, 0.12, 0);
        MatchTab.Notes:Show();
    end
end

local function CreateMatchTabScrollView()
    local ScrollView = NarciAPI.CreateScrollView(MatchTab);
    MatchTab.ScrollView = ScrollView;
    ScrollView:SetSize(192, 192);
    ScrollView:SetPoint("BOTTOM", MatchTab, "BOTTOM", 0, 0);
    ScrollView:SetStepSize(32 * 2);
    ScrollView:OnSizeChanged();
    ScrollView:SetAlwaysHideScrollBar(true);


    ScrollView:SetOnHideCallback(function()
        UpdateModelDelay.id = nil;
        ScrollView:ProcessActiveObjects("MatchButton", function(obj)
            obj.Highlight:Hide();
        end);
    end);

    local function MatchButton_Create()
        local button = CreateFrame("Button", nil, MatchTab, "NarciNPCMatchButtonTemplate");
        button:SetScript("OnEnter", MatchButton_OnEnter);
        button:SetScript("OnLeave", MatchButton_OnLeave);
        button:SetScript("OnClick", NPCCard_OnClick);
        return button
    end

    local function MatchButton_Remove(obj)
        obj.Highlight:Hide();
    end

    ScrollView:AddTemplate("MatchButton", MatchButton_Create, MatchButton_Remove);


    return ScrollView
end

local function DisplaySearchResult(matchTable, keyword)
    if not matchTable then matchTable = {}; end;

    if not MatchTab.ScrollView then
        MatchTab.ScrollView = CreateMatchTabScrollView();
    end

    local numMacthes = #matchTable;
    MouseOverButtons:Hide();
    if numMacthes > 0 then
        MatchTab.Notes:Hide();
    else
        MatchPreviewModel:Hide();
        MatchTab.Notes:Show();
    end

    local content = {};
    local buttonHeight = 32;
    local offsetY = 0;
    local n = 0;
    local top, bottom;

    for i, creatureData in ipairs(matchTable) do
        n = n + 1;
        top = offsetY;
        bottom = offsetY + buttonHeight;
        content[n] = {
            dataIndex = n,
            templateKey = "MatchButton",
            setupFunc = function(obj)
                SetUpMatchButton(obj, creatureData, keyword);
            end,
            top = top,
            bottom = bottom,
        };
        offsetY = bottom;
        if n >= 100 then break end;
    end

    MatchTab.ScrollView:SetContent(content);
end

local function DisplayFavorites()
    --not a RAM friendly way but let it be for now
    local matchedIDs = {};
    local name;
    for npcID, isFav in pairs( FavUtil:GetFavoriteNPCs() ) do
        if isFav then
            name = CreatureInfoUtil:GetName(npcID) or "";
            tinsert(matchedIDs, {name, npcID});
        end
    end
    table.sort(matchedIDs, SortFunc);
    DisplaySearchResult(matchedIDs);
    local isFavoriteTab = true;
    GoToTab(3, isFavoriteTab);
end

NarciNPCBrowserCoverButtonMixin = {};

function NarciNPCBrowserCoverButtonMixin:OnClick()
    if self.categoryID ~= 0 then
        DisplayNPCInCategory(self.categoryID);
        HeaderFrame.Tab2Label:SetText(self.Name:GetText());
    else
        DisplayFavorites();
    end
end

function NarciNPCBrowserCoverButtonMixin:OnMouseUp()
    self.Image:SetTexCoord(0.046875, 0.625, 0.06640625, 0.93359375);
end

function NarciNPCBrowserCoverButtonMixin:OnMouseDown()
    self.Image:SetTexCoord(0, 0.66796875, 0, 1);
end

function NarciNPCBrowserCoverButtonMixin:OnEnter()
    FadeFrame(self.Highlight, 0.12, 1);
    self.Name:SetAlpha(1);
end

function NarciNPCBrowserCoverButtonMixin:OnLeave()
    FadeFrame(self.Highlight, 0.2, 0);
    self.Name:SetAlpha(0.88);
end

function NarciNPCBrowserCoverButtonMixin:Init(categoryID)
    if (categoryID == self.categoryID) and (categoryID ~= 0) then
        return
    end
    self.categoryID = categoryID;

    if categoryID then
        if categoryID == 0 then
            self.Count:SetText( FavUtil:GetNumFavorites() );
            self.Name:SetText(L["My Favorites"]);
            self.Image:SetTexture("Interface/AddOns/Narcissus/Art/Widgets/NPCBrowser/Covers/MyFavorites");
        else
            local category = Catalogue[categoryID];
            if category then
                self.Count:SetText(category.numEntries);
                self.Name:SetText(category.name);
                self.Image:SetTexture("Interface/AddOns/Narcissus/Art/Widgets/NPCBrowser/Covers/".. (category.name) );
            else
                self:Hide();
                return
            end
        end
        self:Show();
    else
        self:Hide();
    end
end

local ScrollCategory = {};
ScrollCategory.indexOffset = -1;
ScrollCategory.buttons = {};
ScrollCategory.numButtons = 12; --6 visible, 6 for buffer

function ScrollCategory:UpdateData()
    self.data = {};

    local numCategory = Catalogue.numCategory;
    local index;
    if FavUtil:GetNumFavorites() > 0 then
        numCategory = numCategory + 1;
        index = 0;
    else
        index = 1;
    end
    local numCol = 3;
    local numRow = math.ceil(numCategory / numCol);
    for row = 1, numRow do
        self.data[row] = {};
        for col = 1, numCol do
            self.data[row][col] = index;
            index = index + 1;
            if index > numCategory then
                return
            end
        end
    end
end

function ScrollCategory:UpdateScrollChild(offset, forced)
    local index = floor((offset + 2) / COVER_BUTTON_HEIGHT) - 1;
    if index == self.indexOffset and not forced then
        return
    end

    local anchorTo = CategoryTab.ScrollChild;
    local row, col = index + 1, 1;
    local button;

    if index > self.indexOffset then
        local topButton;
        for i = 1, 3 do
            topButton = tremove(self.buttons, 1);
            if topButton then
                tinsert(self.buttons, topButton);
            else
                break;
            end
        end
    else
        local bottomButton;
        for i = 1, 3 do
            bottomButton = tremove(self.buttons);
            if bottomButton then
                tinsert(self.buttons, 1, bottomButton);
            else
                break;
            end
        end
    end
    self.indexOffset = index;

    for i = 1, self.numButtons do
        button = self.buttons[i];
        if not button then
            button = CreateFrame("Button", nil, anchorTo, "NarciNPCCoverTemplate");
            self.buttons[i] = button;
        end
        button:ClearAllPoints();
        button:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", COVER_BUTTON_WIDTH * (col - 1), COVER_BUTTON_HEIGHT * (1 - row));
        if self.data[row] then
            button:Init( self.data[row][col] );
        else
            button:Init(nil);
        end
        col = col + 1;
        if col > 3 then
            col = 1;
            row = row + 1;
        end
    end
end

function ScrollCategory:Update()
    ScrollCategory:UpdateData();
    ScrollCategory:UpdateScrollChild(0, true);
end


local function QuickFavoriteButton_OnClick(self)
    if not self.parent then return end

    local isFav = not self.isFav;
    self.isFav = isFav;
    self.parent.isFav = isFav;
    local creatureID = MouseOverButtons.parent.creatureID;
    if isFav then
        FavUtil:Add(creatureID);
    else
        FavUtil:Remove(creatureID);
    end
    self:PlayVisual();

    ScrollCategory:Update();
end
--------------------------------------------------------------------------

local function NPCBrowser_OnLoad(self)
    CategoryTab = self.Container.CategoryTab;
    EntryTab = self.Container.EntryTab;
    MatchTab = self.Container.MatchTab;
    MatchPreviewModel = self.MatchPreview;
    MouseOverButtons = self.Container.MouseOverButtons;
    QuickFavoriteButton = MouseOverButtons.QuickFavoriteButton;
    HeaderFrame = self.Container.Header;
    HomeButton = HeaderFrame.HomeButton;
    SearchBox = HeaderFrame.SearchBox;
    SearchTrigger = HeaderFrame.SearchTrigger;
    LoadingIndicator = self.Container.LoadingIndicator;

    ScrollCategory:Update();
    CreateSmoothScroll(CategoryTab, COVER_BUTTON_HEIGHT, NUM_COVER_ROW_PER_PAGE, 1);
    CategoryTab.scrollBar:SetScript("OnValueChanged", function(bar, value)
        CategoryTab:SetVerticalScroll(value);
        ScrollCategory:UpdateScrollChild(value);
    end);


    local numCover = Catalogue.numCategory;
    local numRow = floor( (numCover + 2) /3 );
    local maxScroll = max(0, (numRow - NUM_COVER_ROW_PER_PAGE) * COVER_BUTTON_HEIGHT);
    CategoryTab.range = maxScroll;
    CategoryTab.scrollBar:SetMinMaxValues(0, maxScroll);

    HomeButton:SetScript("OnClick", function(self)
        if CURRENT_TAB_INDEX == 2 then
            ScrollHistory:SaveOffset();
        end
        GoToTab(1);
        FadeFrame(self, 0.2, 0);
    end)

    SearchTrigger:Show();
    HeaderFrame.Tab1Label:SetTextColor(0.72, 0.72, 0.72);
    SearchTrigger:SetScript("OnClick", function(self)
        self:Hide();
        SearchBox:Show();
        GoToTab(3);

        if not self.isDatabaseLoaded then
            if MatchTab.ScrollView then
                MatchTab.ScrollView:SetContent(nil);
            end

            local addOnName = "Narcissus_Database_NPC";
            if C_AddOns.IsAddOnLoaded(addOnName) then
                self.isDatabaseLoaded = true;
            else
                local timeStart = 0;

                self:RegisterEvent("ADDON_LOADED");
                self:SetScript("OnEvent", function(self, event, ...)
                    if event == "ADDON_LOADED" then
                        local name = ...
                        if name == addOnName then
                            self.isDatabaseLoaded = true;
                            self:UnregisterAllEvents();
                            After(0.5, function()
                                FadeFrame(LoadingIndicator, 0.5, 0);
                            end)
                        end
                    end
                end)

                if C_AddOns.GetAddOnEnableState(addOnName, UnitName("player")) == 0 then
                    C_AddOns.EnableAddOn(addOnName);
                end

                LoadingIndicator.Notes:SetText(L["Loading Database"]);
                LoadingIndicator:Show();

                After(0.2, function()
                    local loaded, reason = C_AddOns.LoadAddOn(addOnName);
                    if not loaded then
                        PlaySound(138528);
                        if reason == "DISABLED" then
                            LoadingIndicator.Notes:SetText("Please enable Narcissus Database on the addon list.")
                        else
                            LoadingIndicator.Notes:SetText( _G["ADDON_"..reason] );
                        end
                        self:UnregisterEvent("ADDON_LOADED");
                        self.isDatabaseLoaded = true;
                        LoadingIndicator.Notes:SetTextColor(1, 0.3137, 0.3137);
                        LoadingIndicator.LoadingIcon:Hide();
                        After(3, function()
                            FadeFrame(LoadingIndicator, 1, 0);
                        end)
                    end
                end)
            end
        end
    end)

    QuickFavoriteButton:SetScript("OnClick", QuickFavoriteButton_OnClick);
    MouseOverButtons.WeaponMark:SetScript("OnClick", AddModelAndEquipItems);

    --localization
    MatchTab.Notes:SetText(CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS);   --No matches
    HeaderFrame.Tab3Label:SetText(L["My Favorites"]);
end



--------------------------------------------------------------------------
--Search Box

local SearchDelay = NarciAPI_CreateAnimationFrame(0.5);

local function StartSearching()
    if not SearchDelay.LoadingIcon then
        SearchDelay.LoadingIcon = MatchTab.LoadingIcon;
        SearchDelay.LoadingIcon.Rotate:Play();
    end
    MatchTab.Notes:Hide();
    SearchDelay:Show();
end

local function SearchByID(id)
    if IsKeyDown("BACKSPACE") then return end

    local result;

    local name = CreatureInfoUtil:GetName(id);
    if name and name ~= "" then
        SetCreaturePreview(id);
        result = {
            {name, id},             --npcID
        };
        DisplaySearchResult(result, nil);
    end

    if NarciAPI.DoesCreatureDisplayIDExist(id) then
        if result then
            tinsert(result, {"DisplayID", 0, id});
        else
            result = {
                {"DisplayID", 0, id},
            };
        end
    end

    DisplaySearchResult(result, nil);
end

local function SearchByName(str)
    if not str or str == "" or IsKeyDown("BACKSPACE") then return end
    if not NarciCreatureInfo then
        --Database Not Loaded
        MatchTab.Notes:SetText("Database Disabled");
        MatchTab.Notes:Show();
        return
    end

    str = gsub(str, "[%c, %-]", "%%%1");
    local keyword = gsub(str, "[%.]", "%%%1");
    local matchedIDs, numMacthes = NarciCreatureInfo.SearchNPCByName(str);

    if numMacthes > 0 then
        for i = 1, numMacthes do
            CreatureInfoUtil:GetTitle(matchedIDs[i][2]);
        end
    end

    After(0.2, function()
        if numMacthes > 0 then
            table.sort(matchedIDs, SortFunc);
        end
        DisplaySearchResult(matchedIDs, keyword);
    end);
end

SearchDelay:SetScript("OnUpdate", function(self, elapsed)
	self.total = self.total + elapsed;
    if self.total >= self.duration then
        self:Hide();
        if self.type == "ID" then
            SearchByID(self.creatureID);
        else
            SearchByName(self.text);
        end
    end
end)

SearchDelay:SetScript("OnHide", function(self)
    self.total = 0;
    self.LoadingIcon:Hide();
end);

SearchDelay:SetScript("OnShow", function(self)
    self.LoadingIcon:Show();
end);


local SearchBoxOnKeydownFunc = function(self, key)
    if key == "DELETE" then
        self.onDeletePressedFunc(self, key);
    elseif self.hasNumber then
        if key == "DOWN" then
            self:SetText(self:GetNumber() + 1);
        elseif key == "UP" then
            self:SetText( max(self:GetNumber() - 1, 1) );
        end
    end
end

NarciNPCSearchBoxMixin = CreateFromMixins(NarciSearchBoxSharedMixin);

function NarciNPCSearchBoxMixin:OnLoad()
    self.delayedSearch = SearchDelay;
    self.onKeyDownFunc = SearchBoxOnKeydownFunc;
    self.DefaultText:SetText(L["Name or ID"]);
end

function NarciNPCSearchBoxMixin:OnMouseWheel(delta)
    if self.hasNumber then
        if delta < 0 then
            self:SetText(self:GetNumber() + 1);
        else
            self:SetText( max(self:GetNumber() - 1, 1) );
        end
    end
end

function NarciNPCSearchBoxMixin:OnTextChanged(isUserInput)
    SearchDelay.total = 0;
    local str = self:GetNumber();

    if str ~= 0 then
        self.hasNumber = true;
        self.DefaultText:Hide();
        self.EraseButton:Show();

        SearchDelay.type = "ID";
        SearchDelay.requireUpdate = nil;

        --Input NPC ID
        SearchDelay.text = "";
        local id = str;
        if id <= 999999 then
            SearchDelay.creatureID = id;
            CreatureInfoUtil:RequestInfo(id);
            NarciAPI.DoesCreatureDisplayIDExist(id);    --Query
            --NarciAPI.DoesModelFileExist(id);          ----Unused. Potentially crash the game
            StartSearching();
        end
    else
        self.hasNumber = false;

        --NPC's name
        str = self:GetText();
        SearchDelay.type = "name";
        SearchDelay.text = str;

        if not str or str == "" then
            self.DefaultText:Show();
            self.EraseButton:Hide();
            MatchTab.Notes:Hide();
        else
            self.DefaultText:Hide();
            self.EraseButton:Show();
            if isUserInput then
                StartSearching();
            end
        end
    end
end

function NarciNPCSearchBoxMixin:OnFocusGained()
    self:OnEditFocusGained();
    if self:GetNumber() ~= 0 then
        self.hasNumber = true;
    else
        self.hasNumber = nil;
    end
end

--------------------------------------------------------------------------
local function BuildNPCList()
    local npcIDList = CreatureInfoUtil:LoadDatabaseAndGetUnloadedNPC();

    local numTotal = #npcIDList;
    local numLeft = numTotal;

    local id, shouldQueue;
    local idQueued = {};
    local pausedTime = 0;
    local paused;

    local function Loader_OnUpdate(f, elapsed)
        if paused then
            pausedTime = pausedTime + elapsed;
            if pausedTime > 0.2 then
                paused = false;
            else
                return
            end
        end

        id = npcIDList[numLeft];
        if id then
            NPCInfo[id][1], shouldQueue = CreatureInfoUtil:GetNameAndTitle(id);
            if shouldQueue then
                if idQueued[id] then
                    numLeft = numLeft - 1;
                else
                    idQueued[id] = true;
                    paused = true;
                    pausedTime = 0;
                end
            else
                numLeft = numLeft - 1;
            end

            if numLeft % 2 == 0 then
                LoadingIndicator.Progress:SetText( (numTotal - numLeft) .."/"..numTotal);
            end
        end

        if numLeft == 0 then
            --Loading Complete
            f:SetScript("OnUpdate", nil);
            f:Hide();
            NPCBrowser_OnLoad(BrowserFrame);
            LoadingIndicator.Progress:SetText("");
            LoadingIndicator:Hide();
        end
    end

    FavUtil:Load();

    local Loader = CreateFrame("Frame");
    After(1.5, function()
        Loader:SetScript("OnUpdate", Loader_OnUpdate);
    end);
end


NarciNPCBrowserMixin = {};

function NarciNPCBrowserMixin:OnLoad()
    BrowserFrame = self;
    self:Minimize();

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciNPCBrowserMixin:OnEnter()
end

function NarciNPCBrowserMixin:OnHide()
    self:Hide();
    self:Minimize();
    TARGET_MODEL_INDEX = nil;
    ACTOR_CREATED = nil;
end

function NarciNPCBrowserMixin:Minimize()
    self:SetSize(BROWSER_SHRINK_WIDTH, BROWSER_SHRINK_HEIGHT);
end

function NarciNPCBrowserMixin:Init()
    if not self.isLoaded then
        self.isLoaded = true;
        LoadingIndicator = self.Container.LoadingIndicator;
        LoadingIndicator:Show();
        BuildNPCList();
        BuildNPCList = nil;
        self.Container.Header.SearchTrigger:Hide();
    end
end

function NarciNPCBrowserMixin:Open(anchorButton)
    FadeFrame(Narci_ActorPanelPopUp, 0.15, 0);
    self:ClearAllPoints();
    self:SetPoint("TOP", anchorButton, "TOP", 0, -5);
    PlayToggleAnimation(true);
    Narci_ModelSettings:SetPanelAlpha(0.5, false);
    local PopUp = anchorButton:GetParent();
    local index = PopUp.Index;
    NarciPhotoModeAPI.CreateEmptyModelForNPCBrowser(index);     --Defined in PlayerModel.lua
    TARGET_MODEL_INDEX = index;
    self:Init();
end

function NarciNPCBrowserMixin:Close()
    PlayToggleAnimation(false);
    Narci_ModelSettings:SetPanelAlpha(1, false);
    if not ACTOR_CREATED then
        NarciPhotoModeAPI.RemoveActor(TARGET_MODEL_INDEX)
    end
    ACTOR_CREATED = false;
    if MatchPreviewModel then
        MatchPreviewModel:Hide();
    end
end

function NarciNPCBrowserMixin:IsFocused()
    return self:IsShown() and self:IsMouseOver()
end