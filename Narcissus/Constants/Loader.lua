local _, Loader = ...

Loader.eventFrame = CreateFrame("frame");
Loader.dbVersion = 110002;

Loader.eventCallback = {};
Loader.initCallback = {};

function Loader:Release()
    self.eventFrame:Hide();

    _ = nil;
    Loader = nil;
end

function Loader:RegisterEvent(event)
    self.eventFrame:RegisterEvent(event);
end

function Loader:UnregisterEvent(event)
    self.eventFrame:UnregisterEvent(event);
end

function Loader:SetScript(scriptName, func)
    self.eventFrame:SetScript(scriptName, func);
end

function Loader:Check()
    for event, callback in pairs(self.eventCallback) do
        if callback then
            return false
        end
    end

    self:Release();
end

function Loader:OnEvent(event, ...)
    C_Timer.After(0.5, function()
        Loader:Check();
    end);

    if Loader.eventCallback[event] then
        Loader:UnregisterEvent(event);
        local tempCallback = Loader.eventCallback[event];
        Loader.eventCallback[event] = nil;
        tempCallback(self, ...);
    end
end

function Loader:AddInitCallback(callback)
    tinsert(self.initCallback, callback);
end

function Loader:NewMsg(pattern, ...)
    if pattern then
        pattern = "|cFFFFD100"..pattern;
        pattern = string.gsub(pattern, ":", ":|r");
        pattern = (NARCI_GRADIENT or "[Narcissus]") .." ".. pattern;
        print(string.format(pattern, ...));
    end
end