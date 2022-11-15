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

    local _, _, _, tocVersion = GetBuildInfo();
    tocVersion = tonumber(tocVersion);

    if tocVersion and tocVersion > self.dbVersion then
        self.requireUpdate = true;
        self:NewMsg("New Game Version: %s |cff808080(DB version %s)|r", tocVersion, self.dbVersion);
    end
end

Loader:Init();