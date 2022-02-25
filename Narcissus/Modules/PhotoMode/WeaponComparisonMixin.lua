local GetItemAppearnceID = C_TransmogCollection.GetItemInfo;

NarciWeaponComparisonMixin = CreateFromMixins(NarciWeaponNicheMixin)

function NarciWeaponComparisonMixin:OnClick()
    self.isSelected = not self.isSelected;
    self:SetDim(self.isSelected);
end

function NarciWeaponComparisonMixin:SetComparisonItem(itemID, referenceItemID)
    self.isSelected = nil;
    self:SetDim(false);
    self:SetItem(itemID);
    if itemID and itemID == referenceItemID then
        self.Name:SetTextColor(1, 0.82, 0);
    else
        if GetItemAppearnceID(itemID) then
            self.Name:SetTextColor(0.66, 0.66, 0.66);
        else
            self.Name:SetTextColor(1, 0.3137, 0.3137);
        end
    end
end

function NarciWeaponComparisonMixin:SetDim(state)
    if state then
        self:SetAlpha(0.1);
    else
        self:SetAlpha(1);
    end
end

function NarciWeaponComparisonMixin:SetReversedFacing(state)
    local facing;
    if state then
        facing = -math.pi/2;
    else
        facing = math.pi/2;
    end
    self.Model:SetFacing(facing);
end