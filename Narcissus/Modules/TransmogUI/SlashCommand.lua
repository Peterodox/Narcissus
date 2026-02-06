local _, addon = ...
local L = Narci.L;
local TransmogUIManager = addon.TransmogUIManager;


local SlashCommandModule = TransmogUIManager:CreateModule("SlashCommand");


local function CustomSetCommandCallback(msg)
    if InCombatLockdown() then
        addon.DisplayTopMessage(L["Error View Outfit In Combat"], "Red");
        return
    end

	local itemTransmogInfoList = TransmogUtil.ParseCustomSetSlashCommand(msg);
	if itemTransmogInfoList then
        if TransmogFrame and TransmogFrame:IsVisible() then
            TransmogUIManager:SetPendingFromTransmogInfoList(itemTransmogInfoList);
        else
            local showCustomSetDetails = true;
            DressUpItemTransmogInfoList(itemTransmogInfoList, showCustomSetDetails);
        end
    else
        addon.DisplayTopMessage(TRANSMOG_CUSTOM_SET_LINK_INVALID, "Red");
	end
end

function SlashCommandModule:OnLoad()
    local oldCommandKey = "TRANSMOG_CUSTOM_SET_OLD";
    _G["SLASH_"..oldCommandKey.."1"] = "/outfit";

    SlashCommandUtil.CheckAddSlashCommand(SLASH_COMMAND.TRANSMOG_CUSTOM_SET, SLASH_COMMAND_CATEGORY.TRANSMOG, CustomSetCommandCallback);
    SlashCommandUtil.CheckAddSlashCommand(oldCommandKey, SLASH_COMMAND_CATEGORY.TRANSMOG, CustomSetCommandCallback);


    local ModelFrame = TransmogFrame.CharacterPreview;
    local LinkButton = CreateFrame("Button", nil, ModelFrame, "SharedButtonTemplate");
    LinkButton:SetSize(128, 28);
    LinkButton:SetPoint("BOTTOMLEFT", ModelFrame, "BOTTOMLEFT", 9, 14);
    LinkButton:SetText(COMMUNITIES_INVITE_MANAGER_COLUMN_TITLE_LINK);
    LinkButton:SetFrameLevel(ModelFrame:GetFrameLevel() + 10);

    LinkButton:SetScript("OnClick", function(self)
        if self.NarcissusLinkMenu then
            self.NarcissusLinkMenu:Close();
            self.NarcissusLinkMenu = nil;
            return
        end

        local playerActor = ModelFrame.ModelScene:GetPlayerActor();
        addon.TransmogDataProvider.GenerateLinkMenu(self, playerActor);
    end)

    function LinkButton:HandlesGlobalMouseEvent(buttonName, event)
        return self:IsMouseOver()
    end
end
