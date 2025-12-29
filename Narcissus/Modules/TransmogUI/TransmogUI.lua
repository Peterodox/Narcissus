local _, addon = ...
local TransmogUIManager = addon.TransmogUIManager;


if not addon.IsTOCVersionEqualOrNewerThan(120000) then return end;


local function TransmogUI_OnLoad()
    C_Timer.After(0, function()
        TransmogUIManager:LoadModules();
    end);
end


EventUtil.ContinueOnAddOnLoaded("Blizzard_Transmog", TransmogUI_OnLoad);