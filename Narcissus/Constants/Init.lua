local _, Loader = ...

function Loader:Load()
    for index, callbackName in pairs(Loader.initCallback) do
        Loader[callbackName](Loader);
    end
end

function Loader:Init()
    self.eventCallback["PLAYER_ENTERING_WORLD"] = self.Load;

    self:SetScript("OnEvent", self.OnEvent);
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
end

Loader:Init();