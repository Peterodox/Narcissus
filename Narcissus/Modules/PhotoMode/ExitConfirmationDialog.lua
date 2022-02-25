local L = Narci.L;
local step = 1;

local cos = math.cos;
local pi = math.pi;
local function inOutSine(t, b, c, d)
	return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function PlaySFX(id)
    PlaySound(id, "Master");
end

local Conversation;
local UpdateFrame = CreateFrame("Frame");
UpdateFrame:Hide();
UpdateFrame.t = 0;
UpdateFrame.d = 0.5;
UpdateFrame:SetScript("OnHide", function(self)
    self.t = 0;
    self.height = 0;
end);
UpdateFrame:SetScript("OnShow", function(self)
    self.StartHeight = Conversation:GetHeight();
end);
UpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    local extra = inOutSine(self.t, 0, self.height, self.d);
    if self.t >= self.d then
        extra = self.height;
        self:Hide();
    end
    Conversation:SetHeight(self.StartHeight + extra);
end);

local function HeightenTab(extraHeight)
    UpdateFrame:Hide();
    UpdateFrame.height = extraHeight;
    UpdateFrame:Show();
end


----------------------------------------------
--Clamp Animations
local MoveFrame = CreateFrame("Frame");
MoveFrame:Hide();
MoveFrame.t = 0;
MoveFrame.d = 1;
MoveFrame.X = 0;
MoveFrame:SetScript("OnHide", function(self)
    self.t = 0;
end);
MoveFrame:SetScript("OnShow", function(self)
    MoveFrame.t = 0;
end);
MoveFrame:SetScript("OnUpdate", function(self, elapsed)
    self.t = self.t + elapsed;
    local offset = inOutSine(self.t, self.Start, self.End - self.Start, self.d);
    if self.t >= self.d then
        offset = self.End;
        self:Hide();
    end
    self.Target:SetPoint(self.Point, self.RelativeTo, self.RelativePoint, self.X, offset);
end);


local function ClampMoveUp2()
    local Clamp = Conversation.Clamp;
    MoveFrame.Start = 20;
    MoveFrame.End = 440;
    MoveFrame.Target = Clamp;
    MoveFrame.Point = "BOTTOM";
    MoveFrame.RelativeTo = Narci_ExitConfirmationDialog;
    MoveFrame.RelativePoint = "TOP";
    MoveFrame.d = 4;
    MoveFrame:SetScript("OnHide", function()
        C_Timer.After(1, function()
            Conversation.Send:Enable();
        end);
        return;
    end);
    PlaySFX(4897);
    C_Timer.After(1, function()
        MoveFrame:Show();
    end);
end

local function UnClamping()
    PlaySFX(112166);
    local Clamp = Conversation.Clamp;
    C_Timer.After(0.2, function()
        Clamp.Front:SetTexCoord(0.5, 1, 0, 1);
        Clamp.Back:SetTexCoord(1, 0.5, 0, 1);
        Clamp.Dust.animIn:SetScript("OnFinished", ClampMoveUp2);
        Clamp.Dust.animIn:Play();
    end);
end

local function ClampMoveDown()
    local frame = Narci_ExitConfirmationDialog;
    frame:SetScale(1);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

    MoveFrame.Start = 500;
    MoveFrame.End = 15;
    MoveFrame.Target = frame;
    MoveFrame.Point = "CENTER";
    MoveFrame.RelativeTo = UIParent;
    MoveFrame.RelativePoint = "CENTER";
    MoveFrame.d = 4.3;
    MoveFrame:SetScript("OnHide", function()
        C_Timer.After(1, function()
            UnClamping();
        end);
    end);
    PlaySFX(4897);
    MoveFrame:Show();
    C_Timer.After(0.1, function()
        frame:SetAlpha(1);
    end);
end

local function ClampMoveUp1()
    local frame = Narci_ExitConfirmationDialog;
    MoveFrame.Start = 15;
    MoveFrame.End = 200;
    MoveFrame.Target = frame;
    MoveFrame.Point = "CENTER";
    MoveFrame.RelativeTo = UIParent;
    MoveFrame.RelativePoint = "CENTER";
    MoveFrame.d = 8;

    local function OnFinished(self)
        self.loop = self.loop + 1;
        local i = self.loop;
        if i < 10 then
            self:Play();
        else
            self.loop = 0;
            self:GetParent().animOut:Play();
        end
    end

    MoveFrame:SetScript("OnHide", function()
        PlaySFX(129677);
        local Clamp = Conversation.Clamp;
        Clamp.Halo.Bling:SetScript("OnFinished", OnFinished);
        C_Timer.After(0.5, function()
            Clamp.Halo.animIn:Play();        
        end);

        C_Timer.After(6, function()     
            ClampMoveDown();
        end)
    end)
    PlaySFX(4901);
    MoveFrame:Show();
end

local function BeginClamping(func)
    PlaySFX(112166);
    local Clamp = Conversation.Clamp;
    C_Timer.After(0.2, function()
        Clamp.Front:SetTexCoord(0, 0.5, 0, 1);
        Clamp.Back:SetTexCoord(0.5, 0, 0, 1);
        Clamp.Dust.animIn:SetScript("OnFinished", func);
        Clamp.Dust.animIn:Play();
    end);
end

local function PlayClampAnimation()
    local Clamp = Conversation.Clamp;
    MoveFrame.Start = 300;
    MoveFrame.End = 20;
    MoveFrame.Target = Clamp;
    MoveFrame.Point = "BOTTOM";
    MoveFrame.RelativeTo = Narci_ExitConfirmationDialog;
    MoveFrame.RelativePoint = "TOP";
    MoveFrame.d = 4.2;
    MoveFrame:SetScript("OnHide", function()
        C_Timer.After(1, function()
            BeginClamping(ClampMoveUp1);
        end);
    end);
    PlaySFX(4897);
    MoveFrame:Show();
end

local function ClampMoveUp3()
    local frame = Conversation;
    frame:SetClampedToScreen(false);
    MoveFrame.Start = 235;
    MoveFrame.X = -424;
    MoveFrame.End = 880;
    MoveFrame.Target = frame;
    MoveFrame.Point = "BOTTOMRIGHT";
    MoveFrame.RelativeTo = UIParent;
    MoveFrame.RelativePoint = "BOTTOM";
    MoveFrame.d = 4.3;
    MoveFrame:SetScript("OnHide", function()
        C_Timer.After(2, function()
            PlaySFX(16004);
            C_Timer.After(3, function()
                PlaySFX(4317);
            end);
        end);
    end);
    PlaySFX(4897);
    C_Timer.After(1, function()
        MoveFrame:Show();
    end);
end

local function PlayClampAnimation2()
    local Clamp = Conversation.Clamp;
    Clamp:ClearAllPoints();
    MoveFrame.Start = 350;
    MoveFrame.End = 20;
    MoveFrame.Target = Clamp;
    MoveFrame.Point = "BOTTOM";
    MoveFrame.RelativeTo = Conversation;
    MoveFrame.RelativePoint = "TOP";
    MoveFrame.d = 4.2;
    MoveFrame:SetScript("OnHide", function()
        C_Timer.After(1, function()
            BeginClamping(ClampMoveUp3);
        end);
    end);
    PlaySFX(4897);
    MoveFrame:Show();
end

------------------------------------------
local function Response(index, delay)
    if index <= 5 then
        local str = Conversation["A"..index];
        HeightenTab(str:GetHeight());
        local circle = Conversation.Loading;
        circle:ClearAllPoints();
        circle:SetPoint("CENTER", str, "CENTER", 0 ,0);
        circle:Show();
        if index <= 4 then
            C_Timer.After(delay, function()
                circle:Hide();
                PlaySFX(111367);
                UIFrameFadeIn(str, 0.25, 0, 1);
                
                if index == 3 then
                    C_Timer.After(2, function()
                        PlayClampAnimation();
                    end);
                else
                    Conversation.Send:Enable();
                end
            end);
        else
            C_Timer.After(3, function()
                PlayClampAnimation2();
            end);
        end
    end
end

local function Conversation_OnClick(self)
    local text, delay, delay2;
    --print(step)
    if step == 1 then
        text = L["Q2"];
        delay = 5;
        delay2 = 4;
    elseif step == 2 then
        text = L["Q3"];
        delay = 3;
        delay2 = 2;
    elseif step == 3 then
        text = L["Q4"];
        delay = 2;
        delay2 = 1;
    elseif step == 4 then
        text = L["Q5"];
        delay = 4;
        delay2 = 3;
    elseif step == 5 then
        text = "...";
        delay = 1;
        delay2 = "1";
    else
        return;
    end

    if step == 2 then
        C_Timer.After(3, function()
            --Gnome Laughs
            PlaySFX(6913);
        end);
    end

    self:Disable();
    self:SetScript("OnEnable", function(self)
        PlaySFX(3093);
        C_Timer.After(delay2, function()
            if self:IsEnabled() then
                self:SetText(text);
                self.Bling.animIn:Play();
            end
        end);
    end);
    local str = self:GetParent()["Q"..step];
    UIFrameFadeIn(str, 0.25, 0, 1);
    self.VirtualText:SetText(text);
    local height = self.VirtualText:GetHeight() + 16;
    self:SetHeight(height);
    HeightenTab(height);

    C_Timer.After(2, function()
        Response(step - 1, delay);
    end);
    step = step + 1;

    PlaySFX(111367);
end

local function Initialize()
    local ECD = Narci_ExitConfirmationDialog;
    Conversation = CreateFrame("Frame", nil, ECD, "Narci_ECDConversation");
    Conversation:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -424, 235);
    Conversation:Show();
    Conversation.Send:SetScript("OnClick", Conversation_OnClick);
    Conversation.Send:SetText(L["Q1"]);
    Conversation.Q1:SetText(L["Q1"]);
    Conversation.Q2:SetText(L["Q2"]);
    Conversation.Q3:SetText(L["Q3"]);
    Conversation.Q4:SetText(L["Q4"]);
    Conversation.Q5:SetText(L["Q5"]);
    Conversation.A1:SetText(L["A1"]);
    Conversation.A2:SetText(L["A2"]);
    Conversation.A3:SetText(L["A3"]);
    Conversation.A4:SetText(L["A4"]);
    Conversation.A5:SetText(L["A4"]);
end

local Initialization = CreateFrame("Frame");
Initialization:RegisterEvent("VARIABLES_LOADED");
Initialization:SetScript("OnEvent", function(self, event, ...)
    self:UnregisterEvent("VARIABLES_LOADED");
    if NarcissusDB.Tutorials["ExitConfirmation"] then
        Initialize();
    end
end);
