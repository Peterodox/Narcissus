local _, addon = ...
local API = addon.API;

local Coder = {};
addon.Coder = Coder;

local tinsert = table.insert;
local L = Narci.L;

local strtrim = strtrim;
local gsub = string.gsub;
local match = string.match;
local find = string.find;
local format = string.format;

local C_BarberShop = C_BarberShop;
local SetCustomizationChoice = C_BarberShop.SetCustomizationChoice;

local IMPORTED_PROFILE_NAME;

local COMPLEX_ENCODING = false;

local function SortByOptionID(a, b)
    return a[1] < b[1]
end

local function SortByValue(a, b)
    return a < b
end

local CASE_TYPES = {
    --when caseID < 100, it's PlayerRaceID, and the subcaseID is 0(male) or 1(female)
    --caseID = 101 Reserved for Dragon Riding Customization. subcaseID is dragon variants

    [0] = "unkown";
    [101] = "dragonriding",
};

local function GetProfileStringType(caseID)
    if caseID then
        if caseID < 100 then
            return "player"
        else
            return CASE_TYPES[caseID] or "unkown"
        end
    else
        return "unknown"
    end
end

local FAILURE_REASONS = {
    [-1] ="Unknown",
    [0] = "Decode",
    [1] = "Wrong Character",
    [2] = "Dragonriding",
};

local function GetFailureReasonByID(failureID)
    if failureID and FAILURE_REASONS[failureID] then
        return L["Failure Reason "..FAILURE_REASONS[failureID]]
    else
        return  L["Failure Reason Unknown"]
    end
end


local MAPPING = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,

    ["a"] = 10,
    ["b"] = 11,
    ["c"] = 12,
    ["d"] = 13,
    ["e"] = 14,
    ["f"] = 15,
    ["g"] = 16,
    ["h"] = 17,
    ["i"] = 18,
    ["j"] = 19,
    ["k"] = 20,
    ["l"] = 21,
    ["m"] = 22,
    ["n"] = 23,
    ["o"] = 24,
    ["p"] = 25,
    ["q"] = 26,
    ["r"] = 27,
    ["s"] = 28,
    ["t"] = 29,
    ["u"] = 30,
    ["v"] = 31,
    ["w"] = 32,
    ["x"] = 33,
    ["y"] = 34,
    ["z"] = 35,

    ["A"] = 36,
    ["B"] = 37,
    ["C"] = 38,
    ["D"] = 39,
    ["E"] = 40,
    ["F"] = 41,
    ["G"] = 42,
    ["H"] = 43,
    ["I"] = 44,
    ["J"] = 45,
    ["K"] = 46,
    ["L"] = 47,
    ["M"] = 48,
    ["N"] = 49,
    ["O"] = 50,
    ["P"] = 51,
    ["Q"] = 52,
    ["R"] = 53,
    ["S"] = 54,
    ["T"] = 55,
    ["U"] = 56,
    ["V"] = 57,
    ["W"] = 58,
    ["X"] = 59,
    ["Y"] = 60,
    ["Z"] = 61,

    --[[
    ["!"] = 62,
    ["@"] = 63,
    ["#"] = 64,
    ["$"] = 65,
    ["%"] = 66,
    ["^"] = 67,
    ["&"] = 68,
    ["*"] = 69,
    ["+"] = 70,
    ["/"] = 71,
    --]]
};

local TOKENS = {};
local NUM_TOKENS = 0;

for k, v in pairs(MAPPING) do
    TOKENS[v] = k;
    NUM_TOKENS = NUM_TOKENS + 1;
end


local BASE3 = NUM_TOKENS^3;
local BASE2 = NUM_TOKENS^2;
local BASE1 = NUM_TOKENS;
local floor = math.floor;
local split = string.split;
local strsub = string.sub;
local strlen = string.len;
local tonumber = tonumber;
local tostring = tostring;

local POWS = {
    [1] = 1,
    [2] = BASE1,
    [3] = BASE2,
    [4] = BASE3,
};

local function EncodeNumber(n)
    local output;
    local i;

    if n >= BASE3 then
        i = floor(n / BASE3);
        if i < BASE1 then
            output = TOKENS[i];
        end
        n = n - BASE3 * i;
    end

    if n >= BASE2 then
        i = floor(n / BASE2);
        if output then
            output = output..TOKENS[i];
        else
            output = TOKENS[i];
        end
        n = n - BASE2 * i;
    elseif output then
        output = output .. "0";
    end

    if n >= BASE1 then
        i = floor(n / BASE1);
        if output then
            output = output..TOKENS[i];
        else
            output = TOKENS[i];
        end
        n = n - BASE1 * i;
    elseif output then
        output = output .. "0";
    end

    if n >= 0 then
        if output then
            output = output..TOKENS[n];
        else
            output = TOKENS[n];
        end
    end

    return output
end


local function DecodeSegment(seg)
    local n = 0;
    local char;

    local length = strlen(seg);
    if length > 3 then
        return
    end

    for i = 1, length do
        char = strsub(seg, -i, -i);
        if MAPPING[char] then
            n = n + MAPPING[char] * POWS[i];
        else
            return false
        end
    end

    return n
end

local function DecodeStringToString(str)
    local segs = {split(".", str)};
    local accumulatedNumber;
    local decodedNumber;
    local decodedString;

    for i = 1, #segs do
        decodedNumber = DecodeSegment(segs[i]);
        if decodedNumber then
            if i == 1 then
                accumulatedNumber = decodedNumber;
            else
                accumulatedNumber = accumulatedNumber + decodedNumber;
            end
        
            if decodedString then
                decodedString = decodedString.."."..accumulatedNumber;
            else
                decodedString = accumulatedNumber;
            end
        else
            --something's wrong
            break
        end
    end

    return decodedString
end


local function DecodeString_Complex(str)
    local segs = {split(".", str)};
    local totalSegs = #segs;

    if totalSegs > 10 or totalSegs < 3 then
        return
    end

    local numSeg = DecodeSegment(segs[1]);
    if not numSeg then return end;

    local unslicedCode = segs[totalSegs];

    local totalBits = math.ceil(numSeg/6);

    local seg, segLength, completeLength;

    local bitIndex = 1;
    local bitOffset;
    local codeSlice;
    local output;

    for i = 1, totalBits do
        seg = DecodeSegment(segs[i + 1]);
        seg = tostring(seg);
        segLength = strlen(seg);

        if i == (totalBits) then
            completeLength = numSeg - 6 * (totalBits - 1);
        else
            completeLength = 6;
        end

        while (segLength < completeLength) do
            seg = "0"..seg;
            segLength = segLength + 1;
        end

        for index = 1, completeLength do
            bitOffset = tonumber(strsub(seg, index, index)) or 0
            codeSlice = strsub(unslicedCode, bitIndex, bitIndex + bitOffset);
            bitIndex = bitIndex + bitOffset + 1;
            if output then
                output = output.."."..codeSlice
            else
                output = codeSlice;
            end
        end
    end

    return output
end


local function DecodeStringToTable(str)
    local decodedTable = {};

    local profileName;

    if find(str, ":") then
        local _, numMatch = gsub(str, ":", ":");
        if numMatch > 1 then
            str = gsub(str, ":", "", numMatch - 1);
        end
        profileName = match(str, "([^:]+):");
        str = match(str,  ":([^:]+%.*)");
        str = strtrim(str);
    end

    IMPORTED_PROFILE_NAME = profileName;

    if COMPLEX_ENCODING then
        str = DecodeString_Complex(str);
    end

    local segs = {split(".", str)};
    local accumulatedNumber;
    local decodedNumber;

    local total = 0;

    if #segs < 2 then
        return
    end

    for i = 1, #segs do
        decodedNumber = DecodeSegment(segs[i]);
        if decodedNumber then
            if i == 1 then
                decodedTable.caseID = decodedNumber;
            elseif i == 2 then
                decodedTable.subcaseID = decodedNumber;
            else
                if i == 3 then
                    accumulatedNumber = decodedNumber;
                else
                    accumulatedNumber = accumulatedNumber + decodedNumber;
                end
            
                total = total + 1;
                decodedTable[total] = accumulatedNumber;
            end
        else
            --something's wrong
            break
        end
    end

    return decodedTable
end


local function EncodeString_Complex(str)
    local noDotStr, numDots = gsub(str, "%.", "");
    local char;
    local numBits = 0;
    local bitString = "";
    local bitStringLengh = 0;

    local output = EncodeNumber(numDots + 1);

    str = str .. ".";

    for i = 1, strlen(str) do
        char = strsub(str, i, i);
        if char == "." then
            bitStringLengh = bitStringLengh + 1;
            if bitStringLengh == 6 then
                bitString = bitString.. tostring(numBits - 1);
                output = output .."."..EncodeNumber(tonumber(bitString));
                bitString = nil;
                bitStringLengh = 0;
            else
                if bitString then
                    bitString = bitString.. tostring(numBits - 1);
                else
                    bitString = tostring(numBits - 1);
                end
            end
            
            numBits = 0;
        else
            numBits = numBits + 1;
        end
    end

    if bitString then
        output = output .."."..EncodeNumber(tonumber(bitString));
    end

    output = output .."."..noDotStr;

    return output
end

local function PackOptionChoicePairs(selectedChoiceIDs)
    if not selectedChoiceIDs then
        return
    end

    local customizationData = C_BarberShop.GetAvailableCustomizations();
    if not customizationData then
        return
    end

    local choiceIDList = {};
    local totalImport = #selectedChoiceIDs;
    for i = 1, totalImport do
        choiceIDList[ selectedChoiceIDs[i] ] = true;
    end

    local optionID;
    local totalFound = 0;
    local totalOptions = 0;
    local anyMatch;
    local choicePairs = {};

    for _, category in ipairs(customizationData) do
        for _, option in ipairs(category.options) do
            anyMatch = false;
            optionID = option.id;
            totalOptions = totalOptions + 1;

            for _, choice in ipairs(option.choices) do
                if choiceIDList[ choice.id ] then
                    totalFound = totalFound + 1;
                    tinsert(choicePairs, {optionID, choice.id});
                    anyMatch = true;
                    break
                end
            end

            if not anyMatch then
                tinsert(choicePairs, {optionID, option.choices[ (option.currentChoiceIndex or 1) ].id} );
            end
        end
    end

    return choicePairs, totalImport, totalFound, totalOptions
end

local function GetCurrentCharacterRaceSex()
    local comboName = API.GetActiveAppearanceName();
    local raceID, sex;
    local raceName, sexName;
    local chrModelID = C_BarberShop.GetViewingChrModel();

    if chrModelID then
        raceID = chrModelID;
        sex = 0;
        if not comboName then
            comboName = API.GetChrModelName(chrModelID) or "Unknown";
        end
    else
        raceID = API.GetPlayerRaceID();
        local characterData = C_BarberShop.GetCurrentCharacterData();

        if characterData then
            sex = characterData.sex or 0;
            raceName = characterData.name;
            if characterData.alternateFormRaceData then
                if C_BarberShop.IsViewingAlteredForm() then
                    --e.g. human is Worgen's alternate form
                    --raceID = characterData.alternateFormRaceData.raceID or 1;
                    raceName = characterData.alternateFormRaceData.name;
                else
                    raceName = characterData.name;
                end
            end
        else
            sex = 0;
        end

        if sex == 0 then
            sexName = MALE;
        else
            sexName = FEMALE;
        end

        if not comboName then
            comboName = format("%s %s", (raceName or ""), (sexName or ""));
        end
    end

    return raceID, sex, comboName, raceName
end
API.GetCurrentCharacterRaceSex = GetCurrentCharacterRaceSex;


function Coder:EncodeList(list)
    --Remove optionID, keep choiceID
    local output = "";

    if list.caseID then
        output = output.. (EncodeNumber(tonumber(list.caseID)) or "0");
    else
        output = output.. "0";
    end

    if list.subcaseID then
        output = output.. "."..(EncodeNumber(tonumber(list.subcaseID)) or "0");
    else
        output = output..".0";
    end

    local choiceIDs = {};
    for i, data in ipairs(list) do
        tinsert(choiceIDs, data[2])
    end
    table.sort(choiceIDs, SortByValue);

    local id, diff;
    for i, choiceID in ipairs(choiceIDs) do
        if id then
            diff = choiceID - id;
        else
            diff = choiceID;
        end
        id = choiceID;

        diff = EncodeNumber(diff);

        if output then
            output = output ..".".. diff;
        else
            output = diff;
        end
    end

    --print("encoded: ", output);
    --local decodedTable = DecodeStringToTable(output);
    --PackOptionChoicePairs(decodedTable);

    if COMPLEX_ENCODING then
        output = EncodeString_Complex(output);
    end

    if list.profileName then
        output = list.profileName ..": "..output;
    end


    return output
end


local function ArePlayerRaceIDMatched(id1, id2)
    --id1 is current player
    --id2 is imported string
    --Returns: raceMatched, proceedWithError
    if id1 == id2 then
        return true
    elseif (id1 == 24 or id1 == 25 or id1 == 26) and (id2 == 24 or id2 == 25 or id2 == 26) then
        --Pandaren Factions
        return true
    elseif (id1 == 52 or id1 == 70) and (id2 == 52 or id2 == 70) then
        --Dracthyr Factions
        return true
    elseif (id1 == 84 or id1 == 85) and (id2 == 84 or id2 == 85) then
        --Earthen Factions
        return true
    elseif (id1 == 1 or id1 == 22) and (id2 == 1 or id2 == 22) then
        --Human/Worgen
        return false, true
    else
        return false, false
    end
end

local function LoadCustomizationFromEncodedString(encodedString)
    --/run LoadCustomizationFromEncodedString("NE: 4.0.bl.g.18.Jq.12x.6j.l.p.j.n.8.6.7.8.B")

    if not encodedString then return end

    local failedReasonID, case, subcase;

    local decodedTable = DecodeStringToTable(encodedString);
    if not decodedTable then
        failedReasonID = 0;
        return false, failedReasonID
    end

    case, subcase = GetCurrentCharacterRaceSex();
    local  raceMatched, proceedWithError = ArePlayerRaceIDMatched(case, decodedTable.caseID);
    local sexMatched = subcase == decodedTable.subcaseID;
    if not (raceMatched and sexMatched) then
        failedReasonID = 1;
        case = decodedTable.caseID;
        subcase = decodedTable.subcaseID;
        if not proceedWithError then
            return false, failedReasonID, case, subcase
        end
    end

    local choicePairs, totalImport, totalFound, totalOptions = PackOptionChoicePairs(decodedTable);

    if choicePairs then
        for i = 1, #choicePairs do
            SetCustomizationChoice(choicePairs[i][1], choicePairs[i][2]);
        end

        if totalFound == 0 then
            if not failedReasonID then
                failedReasonID = -1;
            end
        else
            BarberShopFrame:UpdateCharCustomizationFrame();
            return true, totalImport, totalFound, totalOptions
        end
    end

    if not failedReasonID then
        failedReasonID = 0;
    end
    return false, failedReasonID, case, subcase
end

local function GetCustomizationOptions()
    local customizationData = C_BarberShop.GetAvailableCustomizations();
    if not customizationData then
        return
    end
    local numCatetroy = #customizationData;
    local options, optionID, cuurentChoiceIndex, choice, choiceName, choiceID;
    local selectedOptions = {};

    for i = 1, numCatetroy do
        options = customizationData[i].options;
        local numOptions = #options;
        for j = 1, numOptions do
            optionID = options[j].id;
            cuurentChoiceIndex = options[j].currentChoiceIndex or 1;
            choice = options[j].choices[cuurentChoiceIndex];
            --choiceName = choice.name or "";
            choiceID = choice.id;
            tinsert(selectedOptions, {optionID, choiceID} );
        end
    end

    selectedOptions.caseID, selectedOptions.subcaseID, selectedOptions.profileName = GetCurrentCharacterRaceSex();

    return selectedOptions
end



---- EditBox UI ----
local CreateKeyChordStringUsingMetaKeyState = CreateKeyChordStringUsingMetaKeyState;

--Show visual feedback (glow) after pressing Ctrl+C
local HotkeyListener = CreateFrame("Frame");
HotkeyListener:SetFrameStrata("TOOLTIP");
HotkeyListener:Hide();
HotkeyListener:SetPropagateKeyboardInput(true);
HotkeyListener:SetScript("OnKeyDown", function(self, key)
    local keys = CreateKeyChordStringUsingMetaKeyState(key);
    if keys == "CTRL-C" or key == "COMMAND-C" then
        if self.parentEditBox then
            self:Hide();
            local editBox = self.parentEditBox;
            C_Timer.After(0, function()
                --Texts won't be copied if the editbox hides immediately
                if editBox.OnSuccess then
                    editBox.OnSuccess(editBox);
                end
                editBox:ClearFocus();
            end);
        end
    end
end);

function HotkeyListener:SetParentObject(editbox)
    self.parentEditBox = editbox;
    self:Show();
end


local function ExportBox_OnCursorChanged(self)
    if self:HasFocus() then
        self:HighlightText();
    end
end

local function ExportBox_OnTextChanged(self, userInput)
    if userInput then
        self.anyManualChange = true;
        self:ClearFocus();
    end
end

local function ExportBox_UpdateString(self)
    if not self.profileString then
        self.profileString = Coder:EncodeList(GetCustomizationOptions());
        self:SetText(self.profileString);
        self:SetCursorPosition(0);
    end
end

local function ExportBox_OnHide(self)
    self.profileString = nil;
end

local function ExportBox_OnEditFocusGained(self)
    self:OnEditFocusGained();

    HotkeyListener:SetParentObject(self);
    self.BorderGlow:Hide();
    self.AlertText.AnimFade:Stop();
    self.AlertText:SetText(L["Press To Copy"]);
    self.AlertText:Show();

    if self.HiddenObject then
        self.HiddenObject:Show();
    end
end

local function ExportBox_OnEditFocusLost(self)
    HotkeyListener:Hide();

    if self.anyManualChange then
        self.anyManualChange = nil;
        self:SetText(self.profileString);
    end

    self:OnEditFocusLost();

    if not self.AlertText.AnimFade:IsPlaying() then
        self.AlertText:Hide();
    end

    if self.HiddenObject then
        self.HiddenObject:Hide();
    end
end

local function ExportBox_OnSuccess(self)
    self.AlertText:SetText(L["String Copied"]);
    self:PlayGlow();
end

local function CanSaveNewLook()
    local case = Narci_BarbershopFrame.PlusButton:GetCase();
    if case == 1 then
        --Valid
        return true, _G["SAVE"]
    elseif case == 2 then
        --Already exists
        return false, L["Look Saved"]
    elseif case == 3 then
        return false, L["No Available Slot"]
    elseif case == 4 then
        return false, L["Cannot Save Forms"]
    end
end

local function ImportEditBox_Repeat(self, elapsed)
    self.t = self.t + elapsed;
    if self.t < 0.33 then return end;
    self:SetScript("OnUpdate", nil);

    local alertText;
    local fadeText, showSaveButton;
    local result, var1, var2, var3 = LoadCustomizationFromEncodedString(self.encodedString);
    self.encodedString = nil;

    local totalImport, totalFound, totalOptions = var1, var2, var3;

    if totalImport > 0 and totalImport == totalFound then
        if totalImport == totalOptions then
            --everything matched
            self.colorKey = "green";
            alertText = L["Decode Good"];
            showSaveButton = true;
            --fadeText = 1;
        else
            --imported string doesn't cover all options
            self.colorKey = "yellow";
            alertText = format(L["Import Lack Option"], (totalOptions - totalImport));
            showSaveButton = true;
        end
    elseif totalFound == 0 then
        --wrong character (race/sex);
        self.colorKey = "red";
        alertText = GetFailureReasonByID(1);
    else
        --failed to match some due to new options/choice not unlocked
        self.colorKey = "yellow";
        alertText = format(L["Import Lack Choice"], (totalOptions - totalFound));
        showSaveButton = true;
    end
    self:HighlightBorder(true);

    self.AlertText.AnimFade:Stop();
    self.AlertText:SetText(alertText);
    self.AlertText:Show();

    if fadeText then
        self.AlertText.AnimFade.Anim1:SetStartDelay(fadeText);
        self.AlertText.AnimFade:Play();
    end

    if showSaveButton then
        local canSave, reason = CanSaveNewLook();
        self.SaveButton:SetText(reason);
        if canSave then
            self.SaveButton:Enable();
        else
            self.SaveButton:Disable();
        end
        self.SaveButton:Show();
    else
        self.SaveButton:SetShown(showSaveButton);
    end
end


local function ImportEditBox_OnTextChanged(self, userInput)
    if not userInput then return end;

    local text = strtrim(self:GetText());

    if text == "" then
        self.colorKey = nil;
        self:HighlightBorder(true);
        self.AlertText:SetText("");
        self.SaveButton:Hide();
        return
    end
    self.encodedString = text;

    local alertText;
    local result, var1, var2, var3 = LoadCustomizationFromEncodedString(text);

    if result then
        --successfully decoded
        self.t = 0;
        self:SetScript("OnUpdate", ImportEditBox_Repeat);
    else
        --failed to decode
        self:SetScript("OnUpdate", nil);
        local failedReasonID, case, subcase = var1, var2, var3;
        self.colorKey = "red";
        self:HighlightBorder(true);
        if failedReasonID == 0 or failedReasonID == -1 then
            alertText = GetFailureReasonByID(failedReasonID);
        elseif failedReasonID == 1 then
            --wrong race/gender
            local chrModelName = API.GetChrModelName(case);
            if chrModelName then
                alertText = format(ERR_USE_LOCKED_WITH_ITEM_S or "Requires: %s", chrModelName);
            else
                local sexName = (subcase == 0 and MALE) or FEMALE;
                local raceInfo = case and C_CreatureInfo.GetRaceInfo(case);
                local raceName;
                if raceInfo then
                    raceName = raceInfo.raceName;
                    alertText = format(L["Wrong Character Format"], sexName, raceName);
                else
                    alertText = GetFailureReasonByID(1);
                end
            end
        end
    end

    self.AlertText.AnimFade:Stop();
    self.AlertText:SetText(alertText);
    self.AlertText:Show();
    self.SaveButton:Hide();
end

local function ImportEditBox_OnHide(self)
    self:StopAnimating();
    self.BorderGlow:Hide();
    self.AlertText:Hide();
    self.SaveButton:Hide();
    self:SetScript("OnUpdate", nil);

    if not self.DefaultText:IsShown() then
        self:SetText("");
        self.DefaultText:Show();
    end

    if self.colorKey then
        self.colorKey = nil;
        self:HighlightBorder(false);
    end
end

local function SaveImportButton_OnClick(self)
    Narci_BarbershopFrame:FadeIn(0.2);
    local result = API.SaveCurrentAppearance(IMPORTED_PROFILE_NAME);
    if result then
        self:SetText(L["Look Saved"]);
        self:Disable();
    else
        self:SetText(FAILED);
        self:Disable();
    end
end


NarciBarberShopProfileTextBoxMixin = CreateFromMixins(NarciBarberShopSharedTemplateMixin);


function NarciBarberShopProfileTextBoxMixin:OnLoad()
    if self.action == "import" then
        self.Header:SetText(L["Import"]);
        self.DefaultText:SetText(L["Paste Here"]);
        self.DefaultText:Show();
        self:SetScript("OnTextChanged", ImportEditBox_OnTextChanged);
        self:SetScript("OnHide", ImportEditBox_OnHide);

        self.SaveButton.onClickFunc = SaveImportButton_OnClick;

    elseif self.action == "export" then
        self.Header:SetText(L["Export"]);
        self.AlertText:SetText(L["Press Copy"]);
        self.BorderGlow:SetColorTexture(API.GetColorByKey("green"));
        self.OnSuccess = ExportBox_OnSuccess;

        self:SetScript("OnTextChanged", ExportBox_OnTextChanged);
        self:SetScript("OnCursorChanged", ExportBox_OnCursorChanged);
        self:SetScript("OnEditFocusGained", ExportBox_OnEditFocusGained);
        self:SetScript("OnEditFocusLost", ExportBox_OnEditFocusLost)
        self:SetScript("OnShow", ExportBox_UpdateString);
        self:SetScript("OnHide", ExportBox_OnHide);

        self.UpdateContent = function()
            self.profileString = nil;
            ExportBox_UpdateString(self);
        end

        self.InfoButton.tooltipText = L["Barbershop Export Tooltip"];
    end

    self.action = nil;
    self:UpdatePixel();
end

function NarciBarberShopProfileTextBoxMixin:HighlightBorder(state)
    if state then
        if self.colorKey then
            self:SetBorderColor(self.colorKey);
        else
            self:SetBorderColor("focused");
        end
    else
        if self.colorKey then
            return
        end
        if not (self:IsShown() and self:IsMouseOver()) then
            self:SetBorderColor("grey");
        end
    end
end

function NarciBarberShopProfileTextBoxMixin:OnEditFocusGained()
    self:HighlightBorder(true);
    self:SetBackgroundColor(0.2, 0.2, 0.2);
    self:SetCursorPosition(0);
    self:HighlightText();
    self.DefaultText:Hide();

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function NarciBarberShopProfileTextBoxMixin:OnEditFocusLost()
    self:HighlightBorder(false);
    self:SetBackgroundColor(0, 0, 0);
    self:HighlightText(0, 0);
    self:SetCursorPosition(0);

    if strtrim(self:GetText()) == "" then
        self.DefaultText:Show();
    else
        self.DefaultText:Hide();
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
end

function NarciBarberShopProfileTextBoxMixin:OnEnter()
    self:HighlightBorder(true);
end

function NarciBarberShopProfileTextBoxMixin:OnLeave()
    if not self:HasFocus() then
        self:HighlightBorder(false);
        self:SetBackgroundColor(0, 0, 0);
        self:HighlightText(0, 0);
    end
end

function NarciBarberShopProfileTextBoxMixin:OnEscapePressed()
    self:ClearFocus();
end

function NarciBarberShopProfileTextBoxMixin:PlayGlow()
    self.BorderGlow.Glow:Stop();
    self.BorderGlow.Glow:Play();
    self.BorderGlow:Show();
    self.AlertText:Show();
    self.AlertText.AnimFade:Play();
end


NarciBarberShopAppearanceClipboardMixin = {};

function NarciBarberShopAppearanceClipboardMixin:OnLoad()
    self:SetScript("OnCursorChanged", ExportBox_OnCursorChanged);
end

function NarciBarberShopAppearanceClipboardMixin:OnEditFocusGained()
    self.parent:SetBorderColor(0.80, 0.80, 0.80, 1);

    self:Enable();
    self:EnableMouse(true);
    self:SetCursorPosition(0);
    self:HighlightText();
    self.BackgroundOverlay:Show();

    self.AlertText.AnimFade:Stop();
    self.AlertText:Show();
    self.AlertText:SetText(L["Press To Copy"]);

    HotkeyListener:SetParentObject(self);
end

function NarciBarberShopAppearanceClipboardMixin:OnEditFocusLost()
    HotkeyListener:Hide();

    self:Disable();
    self:EnableMouse(false);
    self:HighlightText(0, 0);
    self:SetText("");
    self.BackgroundOverlay:Hide();

    if self.parent:IsVisible() and self.parent:IsMouseOver() then
        self.parent:SetBorderColor(0.80, 0.80, 0.80, 1);
    else
        self.parent:SetBorderColor(0.2, 0.2, 0.2, 1);
    end

    if not self.AlertText.AnimFade:IsPlaying() then
        self.AlertText:Hide();
    end
end

function NarciBarberShopAppearanceClipboardMixin:OnTextChanged(userInput)
    if userInput then
        self:ClearFocus();
    end
end

function NarciBarberShopAppearanceClipboardMixin:OnEscapePressed()
    self:ClearFocus();
end

function NarciBarberShopAppearanceClipboardMixin:OnSuccess()
    self.AlertText.AnimFade:Stop();
    self.AlertText:SetText(L["String Copied"]);
    self.AlertText.AnimFade:Play();
end

--[[
function GetCustomizationOptions()
    local customizationData = C_BarberShop.GetAvailableCustomizations();
    if not customizationData then
        return
    end
    local numCatetroy = #customizationData;
    local options, optionName, optionID, cuurentChoiceIndex, choice, choiceName, choiceID;
    local selectedOptions = {};
    local optionIDs = {};

    local total = 0;

    for i = 1, numCatetroy do
        options = customizationData[i].options;
        local numOptions = #options;
        for j = 1, numOptions do
            optionName = options[j].name;
            optionID = options[j].id;
            cuurentChoiceIndex = options[j].currentChoiceIndex or 1;
            choice = options[j].choices[cuurentChoiceIndex];
            choiceName = choice.name or "";
            choiceID = choice.id;
            print(optionName.."("..optionID.."): "..choiceName.."("..choiceID..")");
            tinsert(selectedOptions, {optionID, choiceID} );
            tinsert(optionIDs, optionID);
            total = total + 1;
        end
    end
    

    print("Total Options: "..total.."\n ")
    table.sort(optionIDs, function(a, b) return a < b end);
    Coder:EncodeList(selectedOptions);

    local optionString;
    for _, id in ipairs(optionIDs) do
        if optionString then
            optionString = optionString..", "..id;
        else
            optionString = id;
        end
    end
    
    C_Timer.After(1, function()
        ChatFrame1EditBox:SetText(optionString)
        ChatFrame1EditBox:Show();
    end);
end
--]]
