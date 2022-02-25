local _, addon = ...

local IsFriend = C_FriendList.IsFriend;
local FadeFrame = NarciFadeUI.Fade;

NarciMsgAlertContainerMixin = {};

function NarciMsgAlertContainerMixin:OnLoad()
    addon.MsgAlertContainer = self;
end

function NarciMsgAlertContainerMixin:OnEvent(event, ...)
    if event == "SCREENSHOT_STARTED" then
        self:OnScreenshotStarted();
        return
    end

    local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID = ...;
    local isFriend;
    if event == "CHAT_MSG_BN_WHISPER" then
        --the "player name" above is protected
        isFriend = true;
        --[[
        if guid then
            local accountInfo = C_BattleNet.GetAccountInfoByGUID(guid);
            if accountInfo and accountInfo.battleTag then
                playerName = string.gsub(accountInfo.battleTag, "#%d+", "");
            end
        end
        --]]
    else
        isFriend = guid and IsFriend(guid);
    end

    if isFriend then
        self:SetMsg(playerName, text);
    end
end

function NarciMsgAlertContainerMixin:SetMsg(sender, message)
    self.MsgButton:SetMsg(sender, message);
    FadeFrame(self.CornerLight, 0.5, 1);
end

function NarciMsgAlertContainerMixin:Display()
    self:StopAnimating();
    self:Show();
end

function NarciMsgAlertContainerMixin:ListenEvents(state)
    if state then
        self:RegisterEvent("CHAT_MSG_WHISPER");
        self:RegisterEvent("CHAT_MSG_BN_WHISPER");
        self:RegisterEvent("SCREENSHOT_STARTED");
    else
        self:UnregisterEvent("CHAT_MSG_WHISPER");
        self:UnregisterEvent("CHAT_MSG_BN_WHISPER");
        self:UnregisterEvent("SCREENSHOT_STARTED");
    end
end

function NarciMsgAlertContainerMixin:OnShow()
    self:ListenEvents(true);
end

function NarciMsgAlertContainerMixin:OnHide()
    self:ListenEvents(false);
    self:StopAnimating();
    self.MsgButton:Hide();
    self.CornerLight:Hide();
    self.CornerLight:SetAlpha(0);
end

function NarciMsgAlertContainerMixin:SetDND(state)
    if state then
        self:ListenEvents(false);
        self.MsgButton:Hide();
        FadeFrame(self.CornerLight, 1, 0);
    else
        if self:IsShown() then
            self:ListenEvents(true);
        end
    end
end

function NarciMsgAlertContainerMixin:OnScreenshotStarted()
    self:StopAnimating();
    self.CornerLight:SetAlpha(0);
    self.CornerLight:Hide();
    self.MsgButton:Hide();
end