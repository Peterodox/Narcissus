--Supports addons that use libdatabroker-1-1: Titan Panel, Bazooka, ElvUI



local function CreateDataObject()
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

    ldb:NewDataObject("Narcissus", {
        type = "launcher",
        icon = "Interface\\AddOns\\Narcissus\\Art\\Logos\\NarcissusLogo32",
        tocname = "Narcissus",
        --label = "Narcissus",

        OnClick = Object_OnClick,
        OnEnter = Object_OnEnter,
        OnLeave = Object_OnLeave,
    });

    return true
end

do
    local success = CreateDataObject();

    if not success then
        local _, addon = ...
        addon.AddInitializationCallback(CreateDataObject);
    end
end