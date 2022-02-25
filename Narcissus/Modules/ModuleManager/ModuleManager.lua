local _, _, _, tocversion = GetBuildInfo();
tocversion = tonumber(tocversion);

if tocversion < 90000 then
    return
end

local EventToAddOn = {};

local Modules = {
    {name = "Narcissus_Barbershop", triggerEvent = "BARBER_SHOP_OPEN", triggerName = "Blizzard_BarbershopUI"},
}

local Manager = CreateFrame("Frame", "NarciModuleManager");

Manager:SetScript("OnEvent", function(self, event, ...)
    if EventToAddOn[event] then
        for i = 1, #EventToAddOn[event] do
            local name = EventToAddOn[event][i];
            --EnableAddOn(name);    --Forced Enable
            local loaded, reason = LoadAddOn(name);
            if loaded then
                self:UnregisterEvent(event);
            end
        end
    end
end);

for i = 1, #Modules do
    local event = Modules[i].triggerEvent;
    if event then
        Manager:RegisterEvent(event);
        if not EventToAddOn[event] then
            EventToAddOn[event] = {};
        end
        tinsert(EventToAddOn[event], Modules[i].name);
    end
end