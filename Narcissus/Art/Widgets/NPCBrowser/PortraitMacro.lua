/dump NarciNPCModelFrame2:GetPosition()
/dump NarciNPCModelFrame2:GetCameraPosition()

/run NarciNPCModelFrame2:SetPosition(0, -0.3, 0.12);NarciNPCModelFrame2:SetCameraPosition(3.84, 0, 0.8) --Gnome Male

/run NarciNPCModelFrame3:SetPosition(NarciNPCModelFrame2:GetPosition());NarciNPCModelFrame3:SetCameraPosition(NarciNPCModelFrame2:GetCameraPosition())