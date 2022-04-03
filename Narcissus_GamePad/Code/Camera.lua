local _, addon = ...

--Process Camera Inertia
local CameraRotater = CreateFrame("Frame");
addon.CameraRotater = CameraRotater;

CameraRotater:Hide();
CameraRotater.value = 0;
CameraRotater.newValue = 0;
CameraRotater:SetScript("OnUpdate", function(self, elapsed)
    self.value = self.value + (0 - self.value) * 10 * elapsed;
    if self.processIntertia and (self.value < 0.01 and self.value > -0.01) then
        self.value = 0;
        self:Hide();
        self.processIntertia = false;
        MoveViewLeftStop();
        MoveViewRightStop();
    else
        if self.value < 0 then
            MoveViewLeftStart(-self.value);
        elseif self.value > 0 then
            MoveViewRightStart(self.value);
        else
            self:Hide();
            MoveViewLeftStop();
            MoveViewRightStop();
        end
    end
end);

function CameraRotater:Yaw(x)
    if not self.cameraYawMoveSpeed then
        self.cameraYawMoveSpeed = tonumber(GetCVar("cameraYawMoveSpeed"));
    end
    NarciAR.GamePadTurning:Start(-x);
    x = 90 * x;
    self:Hide();
    self.processIntertia = false;
    if x < 0 then
        MoveViewLeftStart(-x/self.cameraYawMoveSpeed);
        MoveViewRightStop();
        self.value = x/self.cameraYawMoveSpeed;
    elseif x > 0 then
        MoveViewRightStart(x/self.cameraYawMoveSpeed);
        MoveViewLeftStop();
        self.value = x/self.cameraYawMoveSpeed;
    else
        --MoveViewLeftStop();
        --MoveViewRightStop();
        self.processIntertia = true;
        self:Show();
    end
end

function CameraRotater:Stop()
    MoveViewLeftStop();
    MoveViewRightStop();
    self:Hide();
end