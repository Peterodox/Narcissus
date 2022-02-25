NarciPowersFrameMixin = {};

function NarciPowersFrameMixin:OnLoad()
    self:ClearAllPoints();
    self:SetPoint("TOP", Narci_ItemLevelFrame, "BOTTOM", 0, -98);
end