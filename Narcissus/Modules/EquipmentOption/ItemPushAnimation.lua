NarciItemPushOverlayMixin = {};

function NarciItemPushOverlayMixin:WatchIcon(iconFileID)
    self:Init();
    self.watchedIcon = iconFileID;
    self.Icon:SetTexture(iconFileID);
    self:Show();
end

function NarciItemPushOverlayMixin:PlayFlyOut()
    self:StopAnimating();
    self.FlyOut:Play();
    if ItemSocketingSocket1 and ItemSocketingSocket1.icon then
        ItemSocketingSocket1.icon:Hide();
    end
end

function NarciItemPushOverlayMixin:HideIfIdle()
    if not self.FlyOut:IsPlaying() then
        self:Hide();
    end
end

function NarciItemPushOverlayMixin:Init()
    local offsetY = 52;
    self:ClearAllPoints();
    self:SetPoint("CENTER", ItemSocketingFrame, "BOTTOM", 0, offsetY);
    self:SetParent(ItemSocketingFrame);
    self:SetFrameStrata("HIGH");
    self:StopAnimating();
end

function NarciItemPushOverlayMixin:OnShow()
    self:RegisterEvent("ITEM_PUSH");
end

function NarciItemPushOverlayMixin:OnHide()
    self:UnregisterEvent("ITEM_PUSH");
    self.watchedIcon = nil;
    self:Hide();
end

function NarciItemPushOverlayMixin:OnEvent(event, ...)
    --gem icon changes after SOCKET_INFO_UPDATE so the animation might fail to sync
    if event == "ITEM_PUSH" then
        local bagSlot, iconFileID = ...;
        if iconFileID == self.watchedIcon then
            self:PlayFlyOut();
            self:UnregisterEvent(event);
        end
    end
end