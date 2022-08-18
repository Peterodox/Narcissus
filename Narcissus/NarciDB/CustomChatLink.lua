local IS_HOOKED = false;
local MessageQueue;

local EventFrame = CreateFrame("Frame");



local function TurnOffCameraSafeMode(button)
    if NarcissusDB.CameraSafeMode then
        NarcissusDB.CameraSafeMode = false;
        DEFAULT_CHAT_FRAME:AddMessage(" ");
        DEFAULT_CHAT_FRAME:AddMessage("Camera Safe Mode Disabled", 1, 0.82, 0);
    end
end

local LinkData = {
    camera = {  --Go to Camera Safe toggle
        callback = TurnOffCameraSafeMode,
        linkText = "Click Here";
        message = "Camera offset has been reset to zero because Camera Safe Mode is on. If you wish to disable this feature, \124Hitem:narcissus:camera:\124h\124cffffffff[Click Here]\124h\124r";
    },
};


local function ProcessNarcissusLink(f, link, text, button)
    --print(link)
    local linkType, arg1, arg2 = string.match(link, "(.-):([^:]+):([^:]+)");
    if arg1 == "narcissus" and arg2 and LinkData[arg2] then
        LinkData[arg2].callback(button);
    end
end

local function HookChatFrame()
    if not IS_HOOKED then
        IS_HOOKED = true;
        hooksecurefunc("ChatFrame_OnHyperlinkShow", ProcessNarcissusLink);
    end
end


local function PrintPresetMessage(key)
    if LinkData[key] and DEFAULT_CHAT_FRAME then
        HookChatFrame();

        if EventFrame.loadingScreenOff then
            DEFAULT_CHAT_FRAME:AddMessage(NARCI_GRADIENT..": "..LinkData[key].message, 1, 0.82, 0);
        else
            if not MessageQueue then
                MessageQueue = {};
            end

            for i, msgKey in ipairs(MessageQueue) do
                if msgKey == key then
                    return
                end
            end

            table.insert(MessageQueue, key);
        end
    end
end

NarciAPI.PrintPresetMessage = PrintPresetMessage;




local function EventFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0 then
        self:SetScript("OnUpdate", nil);
        for i, messageKey in ipairs(MessageQueue) do
            PrintPresetMessage(messageKey);
        end
        MessageQueue = nil;
    end
end


EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
EventFrame:RegisterEvent("LOADING_SCREEN_ENABLED");
EventFrame:RegisterEvent("LOADING_SCREEN_DISABLED");
EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self.loadingScreenOff = false;
    elseif event == "LOADING_SCREEN_DISABLED" then
        self.loadingScreenOff = true;
        if MessageQueue then
            self.t = -3;
            self:SetScript("OnUpdate", EventFrame_OnUpdate);
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        self.loadingScreenOff = false;
    end
end);




--[[
    /script DEFAULT_CHAT_FRAME:AddMessage("\124Hitem:narcissus:camera:\124h[Test Link]\124h\124r");
--]]