local _, addon = ...

local UIParentFade = CreateFrame("Frame");
UIParentFade:Hide();
addon.UIParentFade = UIParentFade;

local UIParent = UIParent;
local InCombatLockdown = InCombatLockdown;


local ALPHA_UPDATE_INTERVAL = 0.08;     --Limit update frequency to mitigate the impact on FPS
local FADE_IN_RATE = 2;                 --0.5 second
local FADE_OUT_RATE = 2;                --0.5 second

local EVENTS_SHOW_UI = {
	START_PLAYER_COUNTDOWN = true,		--Raid countdown starts
	LFG_PROPOSAL_SHOW = true,			--LFG entering notice
	PLAYER_CHOICE_UPDATE = true,		--PlayerChoiceFrame shown. 11.1.7 Overcharged Belt
};


local function FadeIn_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
	self.alpha = self.alpha + FADE_IN_RATE * elapsed;

	if self.t < ALPHA_UPDATE_INTERVAL then
		return
	else
		self.t = 0;
	end

	if self.alpha >= 1 then
		self.alpha = 1;
        self:StopOnUpdate();
	end

	UIParent:SetAlpha(self.alpha);
end

local function FadeOut_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
	self.alpha = self.alpha - FADE_OUT_RATE * elapsed;

	if self.t < ALPHA_UPDATE_INTERVAL then
		return
	else
		self.t = 0;
	end

	if self.alpha <= 0 then
		self.alpha = 0;
        self:StopOnUpdate();
		SetUIVisibility(false); 		--Same as pressing Alt + Z
		UIParent:SetAlpha(1);
		return
	end

	UIParent:SetAlpha(self.alpha);
end

function UIParentFade:StopOnUpdate()
	self:SetScript("OnUpdate", nil);
	self.t = nil;
	self:UnregisterEvent("PLAYER_REGEN_DISABLED");
end

function UIParentFade:UpdateAlpha()
    self.alpha = UIParent:GetAlpha();
end

function UIParentFade:FadeInUIParent()
    if UIParent:IsVisible() and UIParent:GetAlpha() == 1 then return end;

	if InCombatLockdown() then
		return
	end

    NarciAPI.MuteTargetLostSound(false);
	self.t = 0;
    self.alpha = 0;
    UIParent:SetAlpha(self.alpha);
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:SetScript("OnUpdate", FadeIn_OnUpdate);
    self:Show();
    SetUIVisibility(true);
end

function UIParentFade:FadeOutUIParent()
    if not UIParent:IsVisible() then return end;

	NarciAPI.MuteTargetLostSound(true);

	self.t = 0;
    self:UpdateAlpha();
    self:SetScript("OnUpdate", FadeOut_OnUpdate);
    self:Show();
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
end

function UIParentFade:HideUIParent()
    if not UIParent:IsVisible() then return end;

    self:StopOnUpdate();
    UIParent:SetAlpha(1);
    SetUIVisibility(false);
end

function UIParentFade:ShowUIParent()
    if self.t == nil and UIParent:IsVisible() and UIParent:GetAlpha() == 1 then return end;

    self:StopOnUpdate();
    UIParent:SetAlpha(1);
    SetUIVisibility(true);
	NarciAPI.MuteTargetLostSound(false);
end

function UIParentFade:OnEvent(event, ...)
	if EVENTS_SHOW_UI[event] then
		self:ShowUIParent();
	elseif event == "PLAYER_REGEN_DISABLED" then
		self:ShowUIParent();
	end
end
UIParentFade:SetScript("OnEvent", UIParentFade.OnEvent);


do
	local function CharacterUI_ShowState(shown)
		if shown then
			for event in pairs(EVENTS_SHOW_UI) do
				UIParentFade:RegisterEvent(event);
			end
		else
			for event in pairs(EVENTS_SHOW_UI) do
				UIParentFade:UnregisterEvent(event);
			end
		end
	end
	addon.CallbackRegistry:Register("NarcissusCharacterUI.ShownState", CharacterUI_ShowState);
end