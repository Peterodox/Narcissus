local _, addon = ...
local L = Narci.L;
local Gemma = addon.Gemma;
local DataProvider = {};
Gemma:AddDataProvider("Legion", DataProvider);

local tinsert = table.insert;
local GetItemInfoInstant = C_Item.GetItemInfoInstant;
local GetInventoryItemLink = GetInventoryItemLink;

local C_RemixArtifactUI = C_RemixArtifactUI;
local GetNodeInfo = C_Traits.GetNodeInfo;
local GetEntryInfo = C_Traits.GetEntryInfo;
local GetDefinitionInfo = C_Traits.GetDefinitionInfo;




do
	local IncreasableTraits = {
		{108106, 133489, 138275}, --Souls of the Caw
		{108110, 133493, 138279}, --Highmountain Fortitude
		{108702, 134248, 139024}, --Touch of Malice
		{108105, 133488, 138274}, --I Am My Scars!
		{108132, 133525, 138311}, --Call of the Legion ??
		{108102, 133485, 138271}, --Volatile Magics
		{108103, 133486, 138272}, --Arcane Aegis
		{108103, 133508, 138294}, --Arcane Ward
		{108107, 133490, 138276}, --Temporal Retaliation
		{108108, 133491, 138277}, --Terror From Below
		{108104, 133487, 138273}, --Storm Surger
		{109265, 135326, 140093}, --Light's Vengeance
	};

	function DataProvider:GetIncreasedTraits()
		local GetIncreasedTraitData = C_Traits.GetIncreasedTraitData;
		local isLoaded = true;
		local tbl;
		for _, v in ipairs(IncreasableTraits) do
			local nodeID, entryID, definitionID = v[1], v[2], v[3];
			local increasedTraitDataList = GetIncreasedTraitData(nodeID, entryID);
			if increasedTraitDataList and #increasedTraitDataList > 0 then
				local definitionInfo = GetDefinitionInfo(definitionID);
				local spellID = definitionInfo and definitionInfo.spellID;
				--local spellInfo = spellID and C_Spell.GetSpellInfo(spellID);
				if spellID then
					if C_Spell.IsSpellDataCached(spellID) then
						local spellInfo = C_Spell.GetSpellInfo(spellID);
						local spellName = spellInfo.name;
						local spellIcon = spellInfo.iconID or spellInfo.originalIconID;
						local totalIncreased = 0;
						for _index, increasedTraitData in ipairs(increasedTraitDataList) do
							--local r, g, b = C_Item.GetItemQualityColor(increasedTraitData.itemQualityIncreasing);
							--local qualityColor = CreateColor(r, g, b, 1);
							--local coloredItemName = qualityColor:WrapTextInColorCode(increasedTraitData.itemNameIncreasing);
							--local wrapText = true;
							local numPointsIncreased = increasedTraitData.numPointsIncreased;
							totalIncreased = totalIncreased + numPointsIncreased;
							--print(numPointsIncreased, coloredItemName);
							--GameTooltip_AddColoredLine(tooltip, TALENT_FRAME_INCREASED_RANKS_TEXT:format(numPointsIncreased, coloredItemName), GREEN_FONT_COLOR, wrapText);
						end
                        if not tbl then
                            tbl = {};
                        end
                        tinsert(tbl, string.format("+%d  |T%s:16:16:0:0:64:64:4:60:4:60|t |cffffd100%s|r", totalIncreased, spellIcon, spellName))
					else
						isLoaded = false;
					end
				end
			end
		end
		return tbl, isLoaded
	end
end