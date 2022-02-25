--NarciItemDatabase

local function OnAddOnLoaded()
    local browser = Narci_WeaponBrowser;
    if browser and browser.Load then
        browser:Load();
    end
end

local f = CreateFrame("Frame");

f:RegisterEvent("ADDON_LOADED");

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...;
        if name == "Narcissus_Database_Item" then
            self:UnregisterEvent(event);
            OnAddOnLoaded();

            if not NarciItemDatabaseOutput then
                NarciItemDatabaseOutput = {};
            end

            if not NarciItemDatabaseFailure then
                NarciItemDatabaseFailure = {};
            end
        end
    end
end)