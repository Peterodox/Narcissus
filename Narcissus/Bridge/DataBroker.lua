--Supports addons that use libdatabroker-1-1: Titan Panel, Bazooka, ElvUI



local function CreateDataObject()
    --"HidingBar" already handles our button well

    local externalHandlers = {
        "HidingBar",
    };

    for _, addonName in ipairs(externalHandlers) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            return
        end
    end

    if not (LibStub and LibStub.GetLibrary) then
        return
    end

    local silent = true;
    local ldb = LibStub:GetLibrary("LibDataBroker-1.1", silent);

    if not (ldb and ldb.NewDataObject) then
        return
    end

    local function Object_OnEnter(self)
        Narci_MinimapButton:ShowTooltip(self);
    end

    local function Object_OnLeave(self)
        GameTooltip:Hide();
    end

    local function Object_OnClick(frame, button)
        GameTooltip:Hide();

        if button == "LeftButton" then
            Narci_Open();
        elseif button == "RightButton" then
            Narci_MinimapButton:ShowBlizzardMenu(frame);
        end
    end

    local obj = ldb:NewDataObject("Narcissus", {
        type = "launcher",
        icon = "Interface\\AddOns\\Narcissus\\Art\\Logos\\Narcissus-32-White",
        tocname = "Narcissus",
        OnClick = Object_OnClick,
        OnEnter = Object_OnEnter,
        OnLeave = Object_OnLeave,
    });

    local icon = LibStub("LibDBIcon-1.0", true);
    if icon then
        local db = NarcissusDB or {};
        if not db.libdbicon then
            db.libdbicon = {};
        end
        if not (db.libdbicon.minimapPos and type(db.libdbicon.minimapPos) == "number") then
            db.libdbicon.minimapPos = 135;        --Degree. From Three O'clock. Counterclockwise: positive
        end
        icon:Register("Narcissus", obj, db.libdbicon);
    end

    return true
end

do
    local _, addon = ...
    addon.AddInitializationCallback(CreateDataObject);
end