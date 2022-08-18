local Clipboard = CreateFrame("Frame");
Clipboard:Hide();
Clipboard:SetSize(400, 300);
Clipboard:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
Clipboard.Background = Clipboard:CreateTexture(nil, "BACKGROUND");
Clipboard.Background:SetAllPoints(true);
Clipboard.Background:SetColorTexture(0.12, 0.12, 0.12, 0.8);

Clipboard.CloseButton = CreateFrame("Button", nil, Clipboard, "NarciCloseButtonTemplate");
Clipboard.CloseButton.noFading = true;
Clipboard.CloseButton:SetPoint("TOPRIGHT", Clipboard, "TOPRIGHT", 0, 0);

local function ExitEdit(self)
    self:ClearFocus();
end

local EditBox = CreateFrame("EditBox", nil, Clipboard);
EditBox:SetFontObject("NarciFontUniversal10");
EditBox:SetJustifyH("LEFT");
EditBox:SetJustifyV("TOP");
EditBox:SetPoint("TOPLEFT", Clipboard, "TOPLEFT", 6, -18);
EditBox:SetPoint("BOTTOMRIGHT", Clipboard, "BOTTOMRIGHT", -6, 6);
EditBox:SetAutoFocus(false);
EditBox:SetMultiLine(true);
EditBox:SetTextInsets(4, 4, 4, 4);
EditBox:SetSpacing(2);
EditBox:SetScript("OnEscapePressed", ExitEdit);

EditBox.Background = EditBox:CreateTexture(nil, "BACKGROUND");
EditBox.Background:SetAllPoints(true);
EditBox.Background:SetColorTexture(0.08, 0.08, 0.08, 0.8);



---- Print UiCamera data: Will be used in our Wardrobe in Classic ----
--Mouseover Appearance Collection: /dump GetMouseFocus().visualInfo.visualID

local ExampleItems = {
    --appearanceID (visualID)
    --restricted to Leather Class
    Head = 2627,
    Shoulder = 2392,
    Back = 4121,
    Chest = 244,
    Shirt = 906,
    Tabard = 11082,
    Wrist = 800,
    Hands = 283,
    Waist = 345,
    Legs = 254,
    Feet = 44317,   --406
    Robe = 2382,
};

local ExampleWeapons = {
    OneHAxe = 641,
    TwoHAxe = 0,
    OneHSword = 280,
    TwoHSword = 0,
    OneHMace = 1638,
    TwoHMace = 0,
    Polearm = 0,
    Staff = 0,
    Dagger = 5210,
    Thrown = 5210,
    Fist = 2495,
    Bow = 1084,
    Gun = 1066,   --406
    Crossbow = 3724,
    Wand = 0,
    FishingPole = 0,
    Shield = 0,
    Holdable = 0,
};

function PrintTransmogCameraID()
    --/run PrintTransmogCameraID()
    local IS_WEAPON = true;
    
    local uiCameraID;
    local text;
    local posX, posY, posZ, yaw, pitch, roll, animId, animVariation, animFrame, centerModel;

    local sourceTable;
    local textFormat;

    if IS_WEAPON then
        sourceTable = ExampleWeapons;
        textFormat = "[%d] = {%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %s, %s, %s, %s}, --%s";
    else
        sourceTable = ExampleItems;
        local _, raceFile = UnitRace("player");
        local gender = UnitSex("player");
        if gender == 2 then
            gender = "Male"
        else
            gender = "Female";
        end
    
        local postFix = " --"..raceFile.."-"..gender.."-%s";
        textFormat = "[%d] = {%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %s, %s, %s, %s}," ..postFix
    end



    local cameraIDs = {};

    for slotName, visualID in pairs(sourceTable) do
        uiCameraID = C_TransmogCollection.GetAppearanceCameraID(visualID);
        table.insert(cameraIDs, {uiCameraID, slotName});
    end

    if not IS_WEAPON then
        local detailsCameraID, vendorCameraID = C_TransmogSets.GetCameraIDs();
        table.insert(cameraIDs, {detailsCameraID, "Details"});
        table.insert(cameraIDs, {vendorCameraID, "Vendor"});
    end


    --Camera Info
    local cameraName;

    for _, data in pairs(cameraIDs) do
        uiCameraID = data[1];
        cameraName =data[2];
        if uiCameraID and uiCameraID ~= 0 then
            posX, posY, posZ, yaw, pitch, roll, animId, animVariation, animFrame, centerModel = GetUICameraInfo(uiCameraID);
            centerModel = tostring(centerModel);
            if text then
                text = text.."\n";
            else
                text = "";
            end
            text = text..string.format(textFormat, uiCameraID, posX, posY, posZ, yaw, pitch, roll, animId, animVariation, animFrame, centerModel, cameraName);
        end
        print(_, cameraName, uiCameraID)
    end


    --Race Slot to camera:
    text = text.."\n";
    for _, data in pairs(cameraIDs) do
        uiCameraID = data[1];
        cameraName = data[2];
        text = text.."\n"..string.format("%s = %d,", cameraName, uiCameraID);
    end


    Clipboard:Show();
    EditBox:SetText(text);
end