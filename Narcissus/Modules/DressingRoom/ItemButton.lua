local MogAPI = C_TransmogCollection;
local PlayerKnowsSource = MogAPI.PlayerKnowsSource;
local GetSourceInfo = MogAPI.GetSourceInfo;
local GetAllAppearanceSources = MogAPI.GetAllAppearanceSources;

local DataProvider = {};

function DataProvider:FindKnownSource(sourceID)
    if not sourceID then return end;

    if PlayerKnowsSource(sourceID) then
        return sourceID
    else
        if not self.sourceIDxKnownSourceID then
            self.sourceIDxKnownSourceID = {};
        end
        if self.sourceIDxKnownSourceID[sourceID] then
            return self.sourceIDxKnownSourceID[sourceID]
        end
        local sourceInfo = GetSourceInfo(sourceID);
        if sourceInfo then
            local visualID = sourceInfo.visualID;
            local sources = GetAllAppearanceSources(visualID);
            for i = 1, #sources do
                if sourceID ~= sources[i] then
                    if PlayerKnowsSource(sources[i]) then
                        self.sourceIDxKnownSourceID[sourceID] = sources[i];
                        sourceID = sources[i];
                        break
                    end
                end
            end
        end
    end

    return sourceID
end

local function GenerateHyperlinkAndSource(slotID, sourceID, enchantID)
    local sourceInfo = GetSourceInfo(sourceID);
    if not sourceInfo then return end;

    local itemID = sourceInfo.itemID;
    local itemQuality = sourceInfo.quality or 12;
    local sourceType = sourceInfo.sourceType;
    local itemModID = sourceInfo.itemModID;
    local hyperlink, unformatedHyperlink;
    local sourceTextColorized, sourcePlainText = "", nil;
    local _, _, _, hex = GetItemQualityColor(itemQuality)
    local bonusID = 0;
    enchantID = enchantID or "";

    if sourceType == 1 then --TRANSMOG_SOURCE_BOSS_DROP
        local drops = GetAppearanceSourceDrops(sourceID)
        if drops and drops[1] then
            sourceTextColorized = drops[1].encounter.." ".."|cFFFFD100"..drops[1].instance.."|r|CFFf8e694";
            sourcePlainText = drops[1].encounter.." "..drops[1].instance;
            
            if itemModID == 0 then 
                sourceTextColorized = sourceTextColorized.." "..PLAYER_DIFFICULTY1;
                sourcePlainText = sourcePlainText.." "..PLAYER_DIFFICULTY1;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:356".."1"..":1476:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:356".."1"..":1476";
                bonusID = 3561;
            elseif itemModID == 1 then 
                sourceTextColorized = sourceTextColorized.." "..PLAYER_DIFFICULTY2;
                sourcePlainText = sourcePlainText.." "..PLAYER_DIFFICULTY2;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:356".."2"..":1476:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:356".."2"..":1476";
                bonusID = 3562;
            elseif itemModID == 3 then 
                sourceTextColorized = sourceTextColorized.." "..PLAYER_DIFFICULTY6;
                sourcePlainText = sourcePlainText.." "..PLAYER_DIFFICULTY6;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:356".."3"..":1476:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:356".."3"..":1476";
                bonusID = 3563;
            elseif itemModID == 4 then
                sourceTextColorized = sourceTextColorized.." "..PLAYER_DIFFICULTY3;
                sourcePlainText = sourcePlainText.." "..PLAYER_DIFFICULTY3;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:356".."4"..":1476:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:356".."4"..":1476";
                bonusID = 3564;
            end
        end
    else
        if sourceType == 2 then --quest
            sourceTextColorized = TRANSMOG_SOURCE_2
            if itemModID == 3 then 
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:512".."6"..":1562:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:512".."6"..":1562";
                bonusID = 5126;
            elseif itemModID == 2 then 
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:512".."5"..":1562:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:512".."5"..":1562";
                bonusID = 5125;
            elseif itemModID == 1 then 
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120::::2:512".."4"..":1562:|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120::::2:512".."4"..":1562";
                bonusID = 5124;
            end
        elseif sourceType == 3 then --vendor
            sourceTextColorized = TRANSMOG_SOURCE_3
            hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
            unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
        elseif sourceType == 4 then --world drop
            sourceTextColorized = TRANSMOG_SOURCE_4
            hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
            unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
        elseif sourceType == 5 then --achievement
            sourceTextColorized = TRANSMOG_SOURCE_5
            hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r"
            unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::"
        elseif sourceType == 6 then	--profession
            sourceTextColorized = TRANSMOG_SOURCE_6
            hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
            unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
        else
            if itemQuality == 6 then
                sourceTextColorized = ITEM_QUALITY6_DESC;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
				if slotID == 16 then
					bonusID = itemModID or 0;	--Artifact use itemModID "7V0" + modID - 1
				else
					bonusID = 0;
				end
            elseif itemQuality == 5 then
                sourceTextColorized = ITEM_QUALITY5_DESC;
                hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
                unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
            end
        end
    end
    
    if not hyperlink then
        hyperlink = "|c"..hex.."|Hitem:"..itemID..":"..enchantID..":::::::120:::::|h[ ]|h|r";
        unformatedHyperlink = "item:"..itemID..":"..enchantID..":::::::120:::::";
    end
    
    return hyperlink, unformatedHyperlink, bonusID, sourceTextColorized, (sourcePlainText or sourceTextColorized);
end


NarciDressingRoomItemButtonMixin = {};

function NarciDressingRoomItemButtonMixin:Init(slotName)
    local slotID, textureName = GetInventorySlotInfo(slotName);
    self.slotID = slotID;
    self.emptyTexture = textureName;
end

function NarciDressingRoomItemButtonMixin:SetItemSource(sourceID, enchantID)
    sourceID = DataProvider:FindKnownSource(sourceID);
    self.sourceID = sourceID;

    if not(sourceID and sourceID ~= 0) then
        self.hyperlink = nil;
        self.ItemIcon:SetTexture(self.emptyTexture);
        return
    end

    self.ItemIcon:SetTexture( MogAPI.GetSourceIcon(sourceID) );
    self.hyperlink = GenerateHyperlinkAndSource(self.slotID, sourceID, enchantID)
end

function NarciDressingRoomItemButtonMixin:OnMouseDown(mouseButton)

end