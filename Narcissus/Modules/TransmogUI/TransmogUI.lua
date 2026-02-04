local _, addon = ...
local TransmogUIManager = addon.TransmogUIManager;


local MainModule = TransmogUIManager:CreateModule("Main");


local MainFrameMixin = {};
do
    local DynamicEvents = {
	    "VIEWED_TRANSMOG_OUTFIT_SLOT_SAVE_SUCCESS",
		"VIEWED_TRANSMOG_OUTFIT_CHANGED",                       --Fire after clicking an outfit, see TransmogCharacterMixin:RefreshSlots() for how get to appearance from outfitID
		"VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH",
		"VIEWED_TRANSMOG_OUTFIT_SLOT_WEAPON_OPTION_CHANGED",
		"VIEWED_TRANSMOG_OUTFIT_SECONDARY_SLOTS_CHANGED",
		"TRANSMOG_DISPLAYED_OUTFIT_CHANGED",
		"PLAYER_EQUIPMENT_CHANGED",
    };

    function MainFrameMixin:OnShow()
        FrameUtil.RegisterFrameForEvents(self, DynamicEvents);
    end

    function MainFrameMixin:OnHide()
        FrameUtil.UnregisterFrameForEvents(self, DynamicEvents);
    end

    function MainFrameMixin:OnEvent(event, ...)
        --print(event, ...);
    end
end

do
    function MainModule:OnLoad()
        local parent = TransmogFrame;

        local MainFrame = CreateFrame("Frame", nil, parent);
        MainFrame:Hide();
        self.MainFrame = MainFrame;
        Mixin(MainFrame, MainFrameMixin);
        MainFrame:SetScript("OnShow", MainFrame.OnShow);
        MainFrame:SetScript("OnHide", MainFrame.OnHide);
        MainFrame:SetScript("OnEvent", MainFrame.OnEvent);
        MainFrame:Show();
    end
end


local function TransmogUI_OnLoad()
    C_Timer.After(0, function()
        TransmogUIManager:LoadModules();
    end);
end


local EL = CreateFrame("Frame")
EL:RegisterEvent("ADDON_LOADED");

EL:SetScript("OnEvent", function(self, event, name)
    if name == "Blizzard_Transmog" then
        self:UnregisterEvent(event);
        if NarcissusDB and NarcissusDB.TransmogFrame then
            EL.loaded = true;
            TransmogUI_OnLoad();
        end
    end
end);


function TransmogUIManager.IsModuleLoaded()
    return EL.loaded
end

function TransmogUIManager.EnableModule()
    if not EL.loaded then
        if C_AddOns.IsAddOnLoaded("Blizzard_Transmog") then
            EL:UnregisterEvent("ADDON_LOADED");
            EL.loaded = true;
            TransmogUI_OnLoad();
        end
    end
end
