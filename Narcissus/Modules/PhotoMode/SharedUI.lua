function NarciPhotoModeBar_OnLoad(self)
    if self.barWidth then
        --n * button width
        self:SetWidth(24 * self.barWidth - 6);
        self.barWidth = nil;
    end

    if self.roundedLeft then
        self.BackgroundLeft:SetTexCoord(0.75, 0.5, 0.25, 0.5);
        self.Border.Left:SetTexCoord(0.75, 0.5, 0, 0.25)
    else
        self.BackgroundLeft:SetTexCoord(0, 0.25, 0.25, 0.5);
        self.Border.Left:SetTexCoord(0, 0.25, 0, 0.25)
    end
    self.roundedLeft = nil;

    if self.roundedRight then
        self.BackgroundRight:SetTexCoord(0.5, 0.75, 0.25, 0.5);
        self.Border.Right:SetTexCoord(0.5, 0.75, 0, 0.25)
    else
        self.BackgroundRight:SetTexCoord(0.25, 0, 0.25, 0.5);
        self.Border.Right:SetTexCoord(0.25, 0, 0, 0.25)
    end
    self.roundedRight = nil;

    self.Border:SetFrameLevel(self:GetFrameLevel() + 3);
end

function NarciPhotoModeButton_OnLoad(self)
    if self.shape then
        if self.shape == "square" then
            self.Border:SetTexCoord(0.125, 0.25, 0, 0.5);
            self.Background:SetTexCoord(0.125, 0.25, 0.5, 1);
        elseif self.shape == "hollow" then
            self.Border:SetTexCoord(0.25, 0.375, 0, 0.5);
            self.Background:SetTexCoord(0.125, 0.25, 0.5, 1);
        else    --circle
            self.Border:SetTexCoord(0, 0.125, 0, 0.5);
            self.Background:SetTexCoord(0, 0.125, 0.5, 1);
        end

        self.shape = nil;
    end

    if self.brightness then
        self.Border:SetVertexColor(self.brightness, self.brightness, self.brightness);
        self.brightness = nil;
    end

    if self.backgroundBrightness then
        local b = self.backgroundBrightness;
        self.Background:SetVertexColor(b, b, b);
        self.backgroundBrightness = nil;
    end
end