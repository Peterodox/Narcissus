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

    local menuInfo, menuFrame;

    local function Object_OnEnter(self)
        local tp = GameTooltip;
        tp:SetOwner(self, "ANCHOR_NONE")
        tp:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
        tp:ClearLines();

        local L = Narci.L;

        tp:SetText(NARCI_GRADIENT or "Narcissus");
        tp:AddLine(L["Minimap Tooltip Left Click"].." "..L["Minimap Tooltip To Open"], nil, nil, nil, true);
        tp:AddLine(L["Minimap Tooltip Right Click"].." "..L["Minimap Tooltip Module Panel"], nil, nil, nil, true);
        tp:AddLine(" ", nil, nil, nil, true);
	    tp:AddDoubleLine(" ",L["Version Colon"]..NarciAPI.GetAddOnVersionInfo(true), 0.67, 0.67, 0.67, 0.67, 0.67, 0.67);

        tp:Show();
    end

    local function Object_OnLeave(self)
        GameTooltip:Hide();
    end

    local function Object_OnClick(frame, button)
        GameTooltip:Hide();

        if button == "LeftButton" then
            Narci_Open();
        elseif button == "RightButton" then
            if not menuFrame then
                menuFrame = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate");
            end

            if not menuInfo then
                menuInfo = Narci_MinimapButton:GetMenuInfo();
            end

            if EasyMenu and menuFrame then
                EasyMenu(menuInfo, menuFrame, "cursor", 0 , 0, "MENU");
            end
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