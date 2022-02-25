--Add flash to a Blizzard red button

NarciRedButtonFlashMixin = {};

function NarciRedButtonFlashMixin:SetTextureHeight(height)
    self.Left:SetSize(height, height);
    self.Right:SetSize(height, height);
    self.Center:SetHeight(height);
end

function NarciRedButtonFlashMixin:FlashButton(redButton)
    if not redButton or redButton:IsProtected() then
        self:Hide();
        return
    end

    local w0, h0 = redButton:GetSize();
    self:SetSize(w0, h0);
    self:SetTextureHeight(h0 * 2);
    self:SetPoint("CENTER", redButton, "CENTER", 0, 0);
    self:SetParent(redButton);
    self.Anim:Play();
    self:Show();
    self:SetFrameStrata("HIGH");
end

function NarciRedButtonFlashMixin:OnHide()
    self:Hide();
    self.Anim:Stop();
    self:Release();
end

function NarciRedButtonFlashMixin:Release()
    self:ClearAllPoints();
    self:SetParent(nil);
end