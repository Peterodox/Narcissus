local AFK = CreateFrame("Frame");
AFK:RegisterEvent("CHAT_MSG_SYSTEM")
--local UnitIsAFK = UnitIsAFK;

local AFK_MSG = string.format(MARKED_AFK_MESSAGE, DEFAULT_AFK_MESSAGE)

AFK:SetScript("OnEvent",function(self,event,...)
    if not NarcissusDB or not NarcissusDB.AFKScreen then return; end
    --[[
    if IsInCinematicScene() or InCinematic() then
        print("Play Cinematic");
    end
    --]]
    local name = ...
    if name == AFK_MSG and not(C_PvP.IsActiveBattlefield() or CinematicFrame:IsShown() or MovieFrame:IsShown()) then
        if not Narci.isActive then
            Narci_MinimapButton:Click();
            Narci.isAFK = true;
            C_Timer.After(2, function()
                if NarcissusDB.AFKAutoStand then
                    Narci_Character.AutoStand:Play();
                end
            end)
            C_Timer.After(0.6, function()
                if IsResting() then
                    --DoEmote("Read", "none");
                end
            end)
        end
    end
end)

--[[
local Chat = CreateFrame("Frame");
Chat.t = 0.08;

local events = {"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_YELL", };
for i = 1, #events do
    Chat:RegisterEvent(events[i]);
end
wipe(events)

local GetAllChatBubbles = C_ChatBubbles.GetAllChatBubbles

local pieceNames = {
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center";
}

local function SkinBubble(frame)
    BB = frame;
    frame.Tail:Hide();
    local piece;
    for _, pieceName in pairs(pieceNames) do
        piece = frame[pieceName];
        if piece then
            piece:Hide();
        end
    end
end

local function Skin_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0.1 then
        self.t = 0
        for _, frame in pairs(GetAllChatBubbles()) do
            local bubble = frame:GetChildren()
            if bubble and not frame.narciReskin then
                frame.narciReskin = true;
                SkinBubble(bubble);
            end
        end
    end
end

Chat:SetScript("OnEvent", function(self, event, ...)
    print(event)
    self:SetScript("OnUpdate", Skin_OnUpdate);
end)
--]]

--[[
local EL = CreateFrame("Frame");
local events = {"UNIT_SPELLCAST_SENT", };
for i = 1, #events do
    EL:RegisterEvent(events[i])
end

EL:SetScript("OnEvent", function(self, event, ...)
    print(event)
    print(...)
end);
--]]