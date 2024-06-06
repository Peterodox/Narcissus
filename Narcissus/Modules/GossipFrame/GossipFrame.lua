local _, addon = ...

local TooltipFrame = addon.UIFrameTooltip;
local DataProvider = addon.GossipOptionsDataProvider;

local GetMouseFocus = addon.TransitionAPI.GetMouseFocus;
local GossipFrame = GossipFrame;
local GossipOptionOnClick = GossipOptionButtonMixin and GossipOptionButtonMixin.OnClick;
local find = string.find;

local EL = CreateFrame("Frame");

local function IsObjectValid_BlizzardUI(obj)
    return obj and obj.OnClick == GossipOptionOnClick
end

local function IsObjectValid_Immersion(obj)
    local name = obj and obj.GetName and obj:GetName();
    return name and find(name, "^ImmersionTitleButton");
end

local function IsObjectValid_Storyline(obj)
    --A bit tricky
end

local IsObjectValid = IsObjectValid_BlizzardUI;

local function TrackFocus_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    self.total = self.total + elapsed;  --force stop after 10s when out of bound, in case something went wrong

    if self.t > 0.2 then
        self.t = 0;

        local obj = GetMouseFocus();

        if IsObjectValid(obj) then
            self.total = 0;
            local orderIndex = obj:GetID();
            local gossipOptionID;

            if orderIndex and GossipFrame:IsShown() and GossipFrame.gossipOptions then
                for _, option in ipairs(GossipFrame.gossipOptions) do
                    if option.orderIndex == orderIndex then
                        gossipOptionID = option.gossipOptionID;
                        break
                    end
                end
            end

            if DataProvider:IsSupportedOption(gossipOptionID) then
                EL:ShowTooltip(obj, gossipOptionID)
            else
                self:TrackMouseFocus(false);
                return
            end
        else
            self:HideTooltip();
        end
    end

    if self.total > 10 then
        self:TrackMouseFocus(false);
    end
end

function EL:ShowTooltip(owner, gossipOptionID)
    if gossipOptionID == self.gossipOptionID then return end;
    self.gossipOptionID = gossipOptionID;

    local tooltip = TooltipFrame;
    tooltip:Hide();
    tooltip:SetOwner(owner, "ANCHOR_RIGHT");

    local success = DataProvider:SetupTooltipByGossipOptionID(tooltip, gossipOptionID);

    if success then
        tooltip:Show();
        tooltip:SetAlpha(0);
        tooltip:FadeIn(0.15, 0.2);
    else
        tooltip:Hide();
        tooltip:FadeOut();
    end
end

function EL:HideTooltip()
    self.gossipOptionID = 0;
    TooltipFrame:Hide();
    TooltipFrame:FadeOut();
end

function EL:TrackMouseFocus(state)
    if state then
        self.t = 0;
        self.total = 0;
        self:SetScript("OnUpdate", TrackFocus_OnUpdate);
    else
        self:SetScript("OnUpdate", nil);
        self.t = nil;
        self.total = nil;
        self:HideTooltip();
    end
end

EL:SetScript("OnEvent", function(self, event)
    if event == "GOSSIP_SHOW" then
        self:TrackMouseFocus(true);
    elseif event == "GOSSIP_CLOSED" then
        self:TrackMouseFocus(false);
    end
end);

function EL:EnableModule(state)
    if state then
        self:RegisterEvent("GOSSIP_SHOW");
        self:RegisterEvent("GOSSIP_CLOSED");

        if C_AddOns.IsAddOnLoaded("Immersion") then
            IsObjectValid = IsObjectValid_Immersion;
        end
    else
        self:UnregisterEvent("GOSSIP_SHOW");
        self:UnregisterEvent("GOSSIP_CLOSED");
        self:TrackMouseFocus(false);
    end
end

do
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.EnableGossipFrameSoloQueueLFRDetails(state, db)
        if state == nil then
            state = db["SoloQueueLFRDetails"];
        end
        EL:EnableModule(state);
    end
end