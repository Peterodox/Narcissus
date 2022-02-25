--[[---- Addon Bridge ----
#   Addon Name      Functionality
1   Pawn            (show item value in Tooltip)
2   AzeriteUI       (Special minimap button. Show actionbars when dragging an equipment)

--]]

---- Pawn ----
local PawnTooltipLineNum = 1;
local PawnTooltipText = "";


---- Hook Function ----
local Bridge = CreateFrame("Frame");
Bridge:RegisterEvent("PLAYER_ENTERING_WORLD");
Bridge:SetScript("OnEvent",function(self, event, ...)
    self:UnregisterEvent(event);
    local _, isLoaded = IsAddOnLoaded("Pawn");
    if isLoaded and NarciRefVirtualTooltip and PawnUpdateTooltip and PawnAddTooltipLine then
        hooksecurefunc(NarciRefVirtualTooltip, "SetHyperlink", function(self, ...)
            PawnUpdateTooltip("NarciRefVirtualTooltip", "SetHyperlink", ...)
            PawnTooltipLineNum = 1;
            PawnTooltipText = "";
        end)
        hooksecurefunc("PawnAddTooltipLine", function(Tooltip, Text, r, g, b)
            if Tooltip:GetName() ~= "NarciRefVirtualTooltip" then
                PawnTooltipText = "";
                return;
            end
            PawnTooltipLineNum = PawnTooltipLineNum + 1;
            local Tooltip = Narci_Comparison;
            if not Text then
                Tooltip.PawnText:SetText("");
                Tooltip.PawnText:Hide();
                Narci_Comparison_Resize();
                return;
            end

            if PawnTooltipText then
                PawnTooltipText = PawnTooltipText.."\n"..Text;
            else
                PawnTooltipText = Text;
            end

            Tooltip.PawnText:SetText(PawnTooltipText);
            Tooltip.PawnText:Show();
            Narci_Comparison_Resize();
        end)
    end
end)