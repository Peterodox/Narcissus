--[[
Pawn Parameters:
    local Item = PawnGetItemData(ItemLink)
    local UnenchantedItem = PawnUnenchantItemLink(ItemLink)
Pawn API:
    PawnShouldItemLinkHaveUpgradeArrow(ItemLink, CheckLevel)        --return bool
    PawnGetItemDataForInventorySlot(Slot, Unenchanted, UnitName)    --return item, bool 
    PawnGetSingleValueFromItem
    PawnAddTooltipLine
    PawnUpdateTooltip("GameTooltip", "SetHyperlink", hyperlink)

    Item = PawnGetItemData(ItemLink)
	if Item then
		-- If this is a regular item, do the regular calculations to see if it's an upgrade.
        if PawnCommon.ShowUpgradesOnTooltips then UpgradeInfo, BestItemFor, SecondBestItemFor, NeedsEnhancements = PawnIsItemAnUpgrade(Item) end
    end
--]]