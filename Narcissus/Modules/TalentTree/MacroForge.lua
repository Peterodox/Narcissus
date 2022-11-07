local _, addon = ...

local DataProvider = addon.TalentTreeDataProvider;

local strtrim = strtrim;
local GetCursorInfo = GetCursorInfo;
local ClearCursor = ClearCursor;
local InCombatLockdown = InCombatLockdown;
local PickupMacro = PickupMacro;
local GetCursorPosition = GetCursorPosition;
local GetNumMacros = GetNumMacros;
local GetActionInfo = GetActionInfo;
local GetMacroInfo = GetMacroInfo;
local match = string.match;
local ipairs = ipairs;
local pairs = pairs;
local _G = _G;

local L = Narci.L;

local RootFrame;
local MainFrame;


local ActionBarUtil = {};
ActionBarUtil.listener = CreateFrame("Frame");

addon.TalentTreeActionBarUtil = ActionBarUtil;

local function SetBorderColor(border, colorIndex)
    if colorIndex == 1 then
        --border:SetVertexColor(1, 0.82, 0);
        --border:SetVertexColor(0.05, 0.41, 0.85);
        border:SetVertexColor(0.33, 0.66, 1);
    elseif colorIndex == 2 then
        border:SetVertexColor(1, 1, 1);
    elseif colorIndex == 3 then
        border:SetVertexColor(0.45, 0.80, 0.48);
    end
end

local function ClearCursorSafely()
    if not InCombatLockdown() then
        ClearCursor();
    end
end

local ReceptorScripts = {};

function ReceptorScripts.OnEnter(self)
    SetBorderColor(self.Border, 2);
    SetBorderColor(MainFrame.SubIconButton.Border, 2);
end

function ReceptorScripts.OnLeave(self)
    if MainFrame.isFinalStep then
        SetBorderColor(self.Border, 3);
        SetBorderColor(MainFrame.SubIconButton.Border, 3);
    else
        SetBorderColor(self.Border, 1);
    end
end

function ReceptorScripts.OnEnable(self)
    self.Icon:SetDesaturation(0);
    self.Icon:SetVertexColor(1, 1, 1);
    ReceptorScripts.OnLeave(self);
end

function ReceptorScripts.OnDisable(self)
    self.Icon:SetDesaturation(0.5);
    self.Icon:SetVertexColor(0.67, 0.67, 0.67);
    self.Border:SetVertexColor(0.25, 0.25, 0.25);
end

function ReceptorScripts.OnDragStart(self)
    if MainFrame.pendingMacroID then
        if not InCombatLockdown() then
            PickupMacro(MainFrame.pendingMacroID);
        end
    else

    end
end

function ReceptorScripts.OnDragStop(self)

end

function ReceptorScripts.OnMouseDown(self, button)
    if button == "RightButton" then
        MainFrame:HideFrame();
        ClearCursorSafely();
    end
end


local function GetCursorEquipmentSetID()
    local infoType, name = GetCursorInfo();
    if infoType == "equipmentset" then
        return C_EquipmentSet.GetEquipmentSetID(name);
    end
end

local function SetupReceptorFromCursor()
    if MainFrame.isFinalStep then
        ClearCursorSafely();
        return
    end

    local infoType, name = GetCursorInfo();
    if infoType == "equipmentset" then
        local setID = C_EquipmentSet.GetEquipmentSetID(name);
        if setID then
            local _, icon = C_EquipmentSet.GetEquipmentSetInfo(setID);
            local specIndex = C_EquipmentSet.GetEquipmentSetAssignedSpec(setID);
            

            if specIndex and (specIndex ~= DataProvider:GetCurrentSpecIndex()) then
                MainFrame:SetInstruction(L["Create Macro Wrong Spec"]);
                return
            else
                MainFrame.gearSetName = name;
                MainFrame.step = 2;
                MainFrame:UpdateStep();
                MainFrame:SetPrimaryIcon(icon);
            end
            MainFrame.gearSetID = setID;
        end
    end

    ClearCursorSafely();
end

function ReceptorScripts.OnReceiveDrag(self)
    if self:IsEnabled() then
        SetupReceptorFromCursor();
    else
        ClearCursorSafely();
    end
end

function ReceptorScripts.OnClick(self)
    if self:IsEnabled() then
        SetupReceptorFromCursor();
    end
end


local SubIconButtonScripts = {};

function SubIconButtonScripts.OnEnter(self)
    SetBorderColor(self.Border, 2);
end

function SubIconButtonScripts.OnLeave(self)
    SetBorderColor(self.Border, 1);
end

function SubIconButtonScripts.OnClick(self)
    MainFrame:ShowIconSelect();
end

function SubIconButtonScripts.OnEnable(self)
    self:SetHitRectInsets(0, 0, 0, 0);
end

function SubIconButtonScripts.OnDisable(self)
    self:SetHitRectInsets(40, 40, 40, 40);
    SetBorderColor(self.Border, 3);
end



local NameEditBoxScripts = {};

function NameEditBoxScripts.OnEnter(self)
    if not self:HasFocus() then
        self:SetTextColor(0.92, 0.92, 0.92);
    end
end

function NameEditBoxScripts.OnLeave(self)
    if not self:HasFocus() then
        --self:SetTextColor(0.8, 0.8, 0.8);
        self:SetTextColor(0.33, 0.66, 1);
    end
end

function NameEditBoxScripts.OnEditFocusGained(self)
    self:HighlightText();
    self:SetTextColor(0.92, 0.92, 0.92);
end

function NameEditBoxScripts.OnEditFocusLost(self)
    self:HighlightText(0, 0);
    if self:IsMouseOver() then
        NameEditBoxScripts.OnEnter(self);
    else
        NameEditBoxScripts.OnLeave(self);
    end

    local text = strtrim(self:GetText());
    if text ~= "" then
        MainFrame.customName = text;
    else
        MainFrame.customName = nil;
        self:SetText(MainFrame.gearSetName or "Unnamed");
    end
end

function NameEditBoxScripts.OnEscapePressed(self)
    self:ClearFocus();
end

function NameEditBoxScripts.OnEnterPressed(self)
    self:ClearFocus();
    MainFrame:UpdateStep();
    C_Timer.After(0, function()
        MainFrame.NextButton:Click();
    end);
end


local NextButtonScripts = {};

function NextButtonScripts.OnEnter(self)
    self.ButtonText:SetTextColor(1, 1, 1);
end

function NextButtonScripts.OnLeave(self)
    self.ButtonText:SetTextColor(0.67, 0.67, 0.67);
    self.Border.Blink:Play();
end

function NextButtonScripts.OnClick(self)
    MainFrame.step = MainFrame.step + 1;
    MainFrame:UpdateStep();
end

function NextButtonScripts.OnEnable(self)
    self.Border:Show();
end

function NextButtonScripts.OnDisable(self)
    self.Border:Hide();
    self.Border:SetPoint("CENTER", 0, 0);
end

function NextButtonScripts.OnMouseDown(self)
    if self:IsEnabled() then
        self.Border:SetPoint("CENTER", 0, self.pushOffset or -1);
    end
end

function NextButtonScripts.OnMouseUp(self)
    self.Border:SetPoint("CENTER", 0, 0);
end

function NextButtonScripts.OnShow(self)
    self.Border.Blink:Play();
end


local function CreateCombinedMacro(macroName, loadoutConfigID, equipmentSetName, equipmentSetID, primaryIcon, secondaryIcon)
    if InCombatLockdown() then return end;

    local f = MacroFrame;
    if f and f:IsShown() then
        HideUIPanel(f);     --create macro while MarcoFrame is active can cause issues
    end

    --local body = string.format("/equipset %s;\n/script local g=%d;if Narci and Narci.AC then Narci.AC(g) else local C=C_ClassTalents;local d=PlayerUtil.GetCurrentSpecID();local r=C.LoadConfig(g,true);if r~= 0 then C.UpdateLastSelectedSavedConfigID(d,g); end end;", equipmentSetName, loadoutConfigID);  --too long
    local body = string.format("/equipset %s;\n/script local g=%d;if Narci and Narci.AC then Narci.AC(g) else C_ClassTalents.LoadConfig(g,true) end;--(%d,%d)", equipmentSetName, loadoutConfigID, equipmentSetID, secondaryIcon or 0);
    local macroID;

    local _, numCharacterMacros = GetNumMacros();
    local _, _, _, macroConfigID, macroSetID;
    for existingMacroID = 121, 121 + numCharacterMacros - 1 do
        _, _, _, macroConfigID, macroSetID = ActionBarUtil:ProcessMacro(existingMacroID);
        if macroSetID and macroSetID == equipmentSetID and loadoutConfigID == macroConfigID then
            macroID = existingMacroID;
            break
        end
    end

    if macroID then
        macroID = EditMacro(macroID, macroName, primaryIcon, body);
    else
        local perCharacter = true;
        macroID = CreateMacro(macroName, primaryIcon, body, perCharacter);
    end

    if macroID then
        return macroID
    else
        return false    --max char specific macros: 18
    end
end

local function InstructionFrame_DynamicTransparency_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.0167 then
        self.t = 0;
        local x, y = GetCursorPosition();
        if y > self.bottom then
            local alpha = 1 - (y - self.bottom)/48;
            if alpha < 0 then
                alpha = 0;
            end
            self:SetAlpha(alpha);
        else
            self:SetAlpha(1);
        end
    end
end

local function InstructionFrame_SetDynamicTransparency(self)
    self.bottom = self.Instruction:GetBottom() - 32;
    self.t = 0;
    self:SetScript("OnUpdate", InstructionFrame_DynamicTransparency_OnUpdate);
end

local function InstructionFrame_FadeOutIn(self, elapsed)
    self.alpha = self.alpha + elapsed * self.delta;
    if self.alpha < 0 then
        self.alpha = 0;
        self.delta = -self.delta;
        self.Instruction:SetText(self.pendingText);
    end

    if self.alpha > 1 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
        if self.callback then
            self.callback(self);
            self.callback = nil;
        end
    end

    self:SetAlpha(self.alpha);
end

NarciMiniTalentTreeMacroForgeMixin = {};

function NarciMiniTalentTreeMacroForgeMixin:OnLoad()
    MainFrame = self;
    RootFrame = self:GetParent();

    self.step = 1;
    self.Instruction = self.InstructionFrame.Instruction;

    for name, script in pairs(ReceptorScripts) do
        self.Receptor:SetScript(name, script);
    end
    ReceptorScripts.OnLeave(self.Receptor);
    self.Receptor:RegisterForDrag("LeftButton");

    for name, script in pairs(SubIconButtonScripts) do
        self.SubIconButton:SetScript(name, script);
    end

    for name, script in pairs(NextButtonScripts) do
        self.NextButton:SetScript(name, script);
    end

    for name, script in pairs(NameEditBoxScripts) do
        self.NameEditBox:SetScript(name, script);
    end
    self.NameEditBox:SetHighlightColor(0.05, 0.41, 0.85);
    self.NameEditBox:SetMaxLetters(30);

    local basicLevel = self:GetFrameLevel();
    self.Receptor:SetFrameLevel(basicLevel + 6);
    self.SubIconButton:SetFrameLevel(basicLevel + 10);
    self.InstructionFrame:SetFrameLevel(basicLevel + 4);
    self.NodeHighlight:SetFrameLevel(basicLevel + 6);
    self.NameEditBox:SetFrameLevel(basicLevel + 6);
    self.CombatBlocker:SetFrameLevel(basicLevel + 20);

    self.LeftArrow:SetVertexColor(0.4, 0.4, 0.4);
    self.RightArrow:SetVertexColor(0.4, 0.4, 0.4);
    self.LeftArrowLight:SetVertexColor(0.8, 0.8, 0.8);
    self.RightArrowLight:SetVertexColor(0.8, 0.8, 0.8);

    addon.TalentTreeNodeUtil:AssignHandler(self);
end

function NarciMiniTalentTreeMacroForgeMixin:HighlightButton(node)
    if node then
        self.NodeHighlight:ClearAllPoints();
        self.NodeHighlight:SetPoint("CENTER", node, "CENTER", 0, 0);
        if node.typeID == 0 then    --square
            self.NodeHighlight.Border:SetTexCoord(0.5, 1, 0, 0.5);
        elseif node.typeID == 1 then    --circle
            self.NodeHighlight.Border:SetTexCoord(0, 0.5, 0, 0.5);
        elseif node.typeID == 2 then    --oct
            self.NodeHighlight.Border:SetTexCoord(0, 0.5, 0.5, 1);
        else
            self.NodeHighlight.Border:SetTexCoord(0.5, 1, 0.5, 1);
        end
        self.NodeHighlight:Show();
    else
        self.NodeHighlight:Hide();
    end
end

function NarciMiniTalentTreeMacroForgeMixin:SetInstruction(text, instant)
    if instant then
        self.InstructionFrame.Instruction:SetText(text);
        self.InstructionFrame.pendingText = nil;
        self.InstructionFrame:SetScript("OnUpdate", nil);
        self.InstructionFrame:SetAlpha(1);
        return
    end

    if text == self.InstructionFrame.pendingText then return end;

    self.InstructionFrame.alpha = self.Instruction:GetAlpha();
    self.InstructionFrame.delta = -5;
    self.InstructionFrame.pendingText = text;
    self.InstructionFrame:SetScript("OnUpdate", InstructionFrame_FadeOutIn);
end

function NarciMiniTalentTreeMacroForgeMixin:OnCursorChanged(isDefault, newCursorType, oldCursorType)
    if newCursorType == 13 then
        self:ShowFrame();
    else
        if not self.gearSetName then
            self:HideFrame();
        end
    end
end

local function FadeIn_OnUpdate(self, elapsed)
    self.alpha = self.alpha + 5 * elapsed;
    if self.alpha > 1 then
        self.alpha = 1;
        self:SetScript("OnUpdate", nil);
    end
    self:SetAlpha(self.alpha);
end

local function FadeOut_OnUpdate(self, elapsed)
    self.alpha = self.alpha - 5 * elapsed;
    if self.alpha < 0 then
        self.alpha = 0;
        self:SetScript("OnUpdate", nil);
        self:Hide();
    end
    self:SetAlpha(self.alpha);
end

function NarciMiniTalentTreeMacroForgeMixin:ShowFrame()
    self:ResetSteps();
    self:Show();
    self.alpha = self:GetAlpha();
    self:SetScript("OnUpdate", FadeIn_OnUpdate);
    if InCombatLockdown() then
        self.CombatBlocker:Show();
    end
end

function NarciMiniTalentTreeMacroForgeMixin:HideFrame(fadeOut)
    if fadeOut then
        if self:IsVisible() then
            self.alpha = self:GetAlpha();
            self:SetScript("OnUpdate", FadeOut_OnUpdate);
        end
    else
        self:Hide();
    end
end

function NarciMiniTalentTreeMacroForgeMixin:OnShow()
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("PLAYER_REGEN_ENABLED");
end

function NarciMiniTalentTreeMacroForgeMixin:OnHide()
    self:UnregisterEvent("PLAYER_REGEN_DISABLED");
    self:UnregisterEvent("PLAYER_REGEN_ENABLED");
    self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED");
    self:Hide();
    self.CombatBlocker:Hide();
    self:SetAlpha(0);
    RootFrame:RaiseActiveNodesFrameLevel(false);
end

function NarciMiniTalentTreeMacroForgeMixin:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self.NextButton:Disable();
        self.CombatBlocker:Show();
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not self.isFinalStep then
            self.NextButton:Enable();
        end
        self.CombatBlocker:Hide();
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        local slot = ...
        local actionType, id, subType = GetActionInfo(slot);
        if actionType == "macro" then
            if id == self.pendingMacroID then
                self:UnregisterEvent(event);
                self.pendingMacroID = nil;
                self:HideFrame(true);
                --ActionBarUtil:UpdateListenerStatus();
                ActionBarUtil:OnMacroUpdated()
            end
        end
    end
end

function NarciMiniTalentTreeMacroForgeMixin:UpdatePixel(px)
    self.Receptor:SetSize(64*px, 64*px);
    self.Receptor.Icon:SetSize(48*px, 48*px);
    self.Receptor.Background:SetSize(96*px, 96*px);
    self.Receptor.Highlight:SetSize(128*px, 128*px);
    self.Receptor:ClearAllPoints();
    self.Receptor:SetPoint("CENTER", self, "CENTER", 0, 0);

    self.SubIconButton:SetSize(32*px, 32*px);
    self.SubIconButton.Icon:SetSize(20*px, 20*px);
    self.SubIconButton:ClearAllPoints();
    self.SubIconButton:SetPoint("CENTER", self.Receptor, "CENTER", -18*px, 18*px);

    self.LeftArrow:SetSize(32*px, 16*px);
    self.LeftArrow:ClearAllPoints();
    self.LeftArrow:SetPoint("RIGHT", self, "CENTER", -40*px, 0);
    self.RightArrow:SetSize(32*px, 16*px);
    self.RightArrow:ClearAllPoints();
    self.RightArrow:SetPoint("LEFT", self, "CENTER", 40*px, 0);

    self.LeftArrowLight:SetSize(24*px, 16*px);
    self.LeftArrowLight.Anim.MoveRight:SetOffset(56*px, 0);
    self.RightArrowLight:SetSize(24*px, 16*px);
    self.RightArrowLight.Anim.MoveLeft:SetOffset(-56*px, 0);

    self.NodeHighlight:SetSize(64*px, 64*px);
    self.SubIconButton.Highlight:SetSize(64*px, 64*px);

    local font, _, _ = self.Instruction:GetFont();

    self.Instruction:SetFont(font, 16*px, "OUTLINE");
    self.Instruction:SetWidth(190 * px);
    self.Instruction:ClearAllPoints();
    self.Instruction:SetPoint("BOTTOM", self, "CENTER", 0, 80*px);

    self.NextButton.ButtonText:SetFont(font, 16*px, "OUTLINE");
    self.NextButton:SetSize(96*px, 36*px);
    self.NextButton.Border:SetSize(96*px, 36*px);
    self.NextButton.pushOffset = -px;
    self.NextButton:ClearAllPoints();
    self.NextButton:SetPoint("TOP", self, "CENTER", 0, -80*px);
    self.NextButton.Exclusion:ClearAllPoints();
    self.NextButton.Exclusion:SetPoint("TOPLEFT", self.NextButton.Border, "TOPLEFT", 2*px, -2*px);
    self.NextButton.Exclusion:SetPoint("BOTTOMRIGHT", self.NextButton.Border, "BOTTOMRIGHT", -2*px, 2*px);
    self.NextButton.Exclusion:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Exclusion", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST");

    self.NameEditBox:SetFont(font, 20*px, "");
    self.NameEditBox:SetSize(160*px, 40*px);
    self.NameEditBox:ClearAllPoints();
    self.NameEditBox:SetPoint("BOTTOM", self, "CENTER", 0, 64*px);

    self.CombatBlocker.AlertText:SetFont(font, 16*px, "OUTLINE");
    self.CombatBlocker.AlertText:ClearAllPoints();
    self.CombatBlocker.AlertText:SetPoint("BOTTOM", self, "BOTTOM", 0, 32*px);
    self.CombatBlocker.AlertText:SetText(L["Create Macro In Combat"]);

    self.MotionBlocker:SetScript("OnMouseDown", function(f, button)
        ClearCursorSafely();
        if button == "RightButton" then
            self:HideFrame();
        end
    end)
end

function NarciMiniTalentTreeMacroForgeMixin:SetSecondaryIcon(icon, viaClick)
    self.secondaryIcon = icon;
    self.SubIconButton.Icon:SetTexture(icon);
    self.SubIconButton.Highlight.Glow:Stop();
    if icon then
        self.SubIconButton.Highlight.Glow:Play();
    end
    if viaClick then
        self:HighlightButton();
    end
end

function NarciMiniTalentTreeMacroForgeMixin:SetPrimaryIcon(icon)
    self.primaryIcon = icon;
    self.Receptor.Icon:SetTexture(icon);
end

function NarciMiniTalentTreeMacroForgeMixin:ResetSteps()
    self.step = 1;
    self.configID = nil;
    self.gearSetName = nil;
    self.customName = nil;
    self.pendingMacroID = nil;
    self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED");
    self:SetPrimaryIcon(nil);
    self:SetSecondaryIcon(nil);
    self.NameEditBox:SetText("");
    self.SubIconButton.Icon:SetTexture(nil);
    self.Receptor.Highlight:Hide();
    self:ShowReceptor();
end

function NarciMiniTalentTreeMacroForgeMixin:UpdateStep()
    if self.step == 2 then
        self:ShowIconSelect()
    elseif self.step == 3 then
        self:ShowRename();
    elseif self.step == 4 then
        self:ShowComplete();
    else
        self:ShowReceptor();
    end
end

function NarciMiniTalentTreeMacroForgeMixin:ShowReceptor()
    local setID = GetCursorEquipmentSetID();
    local configID = DataProvider:GetSelecetdConfigID();
    local _, numCharacterMacros = GetNumMacros();
    local macroName, macroIcon1, macroIcon2, macroConfigID, macroSetID;
    local oldMacroID;
    if setID then
        for macroID = 121, 121 + numCharacterMacros - 1 do
            macroName, macroIcon1, macroIcon2, macroConfigID, macroSetID = ActionBarUtil:ProcessMacro(macroID);
            if macroSetID and macroSetID == setID and configID == macroConfigID then
                oldMacroID = macroID;
                break
            end
        end
    end

    self.step = 1;
    self.isFinalStep = nil;

    self:UpdateWidgetStates();
    self.LeftArrowLight.Anim:Stop();
    self.RightArrowLight.Anim:Stop();

    if not oldMacroID then
        if (not numCharacterMacros) or numCharacterMacros >= 18 then
            self:SetInstruction(L["Create Marco No Slot"], true);
            self.Receptor:Disable();
            self.Receptor.Border:SetVertexColor(1, 0.2, 0.2);
            return
        else
            local loadoutName = DataProvider:GetActiveLoadoutName();
            self:SetInstruction(string.format(L["Create Macro Instruction 1"], loadoutName), true);
        end
    else    --edit a existing macro
        self:SetInstruction(string.format(L["Create Macro Instruction Edit"], macroName), true);
        self.customName = macroName;
        self:SetPrimaryIcon(macroIcon1);
        self:SetSecondaryIcon(macroIcon2);
    end
    self.configID = configID;
    SetBorderColor(self.Receptor.Border, 1);
    self.LeftArrowLight.Anim:Play();
    self.RightArrowLight.Anim:Play();
end

function NarciMiniTalentTreeMacroForgeMixin:ShowIconSelect()
    self.step = 2;
    self.isFinalStep = nil;
    SetBorderColor(self.SubIconButton.Border, 1);
    self.InstructionFrame.callback = InstructionFrame_SetDynamicTransparency;
    self:SetInstruction(L["Create Macro Instruction 2"]);
    self.NextButton.ButtonText:SetText(L["Create Macro Next"]);
    self:UpdateWidgetStates();
end

function NarciMiniTalentTreeMacroForgeMixin:ShowRename()
    self.step = 3;
    self.isFinalStep = nil;
    self:SetInstruction(L["Create Macro Instruction 3"]);
    self.NextButton.ButtonText:SetText(L["Create Macro Next"]);
    self:UpdateWidgetStates();
    self.NameEditBox:SetText(self.customName or self.gearSetName or "");
    self.NameEditBox:SetFocus();
end

function NarciMiniTalentTreeMacroForgeMixin:ShowComplete()
    self.step = 4;
    self.isFinalStep = true;
    self:SetInstruction(L["Create Macro Instruction 4"]);
    self.Receptor.Highlight:Show();
    SetBorderColor(self.Receptor.Border, 3);
    self.NextButton.ButtonText:SetText(L["Create Marco Created"]);
    self:UpdateWidgetStates();

    if self.secondaryIcon then
        self.Receptor.Highlight:SetTexCoord(0.25, 0.5, 0.25, 0.5);
    else
        self.Receptor.Highlight:SetTexCoord(0, 0.25, 0.25, 0.5);
        self.SubIconButton:Hide();
    end

    local macroID;
    if self.gearSetName and self.configID then
        local macroName = self.customName or self.gearSetName or "GearSetAndLoadout";
        macroID = CreateCombinedMacro(macroName, self.configID, self.gearSetName, self.gearSetID, self.primaryIcon, self.secondaryIcon);
    end

    self.pendingMacroID = macroID;
    self.Receptor:SetEnabled(macroID ~= nil);
    self.Receptor.Highlight.Blink:Stop();
    if macroID then
        self.Receptor.Highlight.Blink:Play();
        self:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
    else
        self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED");
    end
end

function NarciMiniTalentTreeMacroForgeMixin:UpdateWidgetStates()
    self.NextButton:SetShown(self.step > 1);
    self.NameEditBox:SetShown(self.step == 3);
    self.SubIconButton:SetShown(self.step > 1);
    self.LeftArrow:SetShown(self.step == 1);
    self.RightArrow:SetShown(self.step == 1);
    self.LeftArrowLight:SetShown(self.step == 1);
    self.RightArrowLight:SetShown(self.step == 1);

    self.Receptor:SetEnabled(self.step == 1);
    self.SubIconButton:SetEnabled(not self.isFinalStep);
    self.NextButton:SetEnabled(not self.isFinalStep);

    RootFrame:RaiseActiveNodesFrameLevel(self.step == 2);
end



local ActionBarNames = {
    "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight", "MultiBar5", "MultiBar6", "MultiBar7",
};

--[[
local ActionBarSlotRange = {
    [1] = "MainMenuBar",            --Page1 1-12  Page2 13-24, Stance 73-120
    [2] = "MultiBarRight",          --25-36
    [3] = "MultiBarLeft",           --37-48
    [4] = "MultiBarBottomRight",    --49-60
    [5] = "MultiBarBottomLeft",     --61-72
    [6] = "MultiBar5",              --145-156
    [7] = "MultiBar6",              --157-168
    [8] = "MultiBar7",              --169-180
};
--]]

function ActionBarUtil:GetActionButtonBySlotID(slotID)
    if (not slotID) or (slotID >= 120 and slotID <= 132) then return end;

    if slotID <= 12 then
        return _G["ActionButton"..(slotID)];
    elseif slotID <= 24 then
        return _G["ActionButton"..(slotID - 12)];
    elseif slotID <= 36 then
        return _G["MultiBarRightButton"..(slotID - 24)];
    elseif slotID <= 48 then
        return _G["MultiBarLeftButton"..(slotID - 36)];
    elseif slotID <= 60 then
        return _G["MultiBarBottomRightButton"..(slotID - 48)];
    elseif slotID <= 72 then
        return _G["MultiBarBottomLeftButton"..(slotID - 60)];
    elseif slotID <= 84 then
        return _G["ActionButton"..(slotID - 72)];
    elseif slotID <= 96 then
        return _G["ActionButton"..(slotID - 84)];
    elseif slotID <= 108 then
        return _G["ActionButton"..(slotID - 96)];
    elseif slotID <= 120 then
        return _G["ActionButton"..(slotID - 108)];
    elseif slotID >= 145 then
        if slotID <= 156 then
            return _G["MultiBar5Button"..(slotID - 144)];
        elseif slotID <= 168 then
            return _G["MultiBar6Button"..(slotID - 156)];
        elseif slotID <= 180 then
            return _G["MultiBar7Button"..(slotID - 168)];
        end
    end
end

ActionBarUtil.container = CreateFrame("Frame");
ActionBarUtil.overlayInSlot = {};

function ActionBarUtil:ReleaseOverlays()
    if self.overlays then
        for i, overlay in ipairs(self.overlays) do
            overlay:Hide();
            overlay:ClearAllPoints();
            overlay:SetParent(self.container);
        end
    end
    self.numOverlays = 0;
end

function ActionBarUtil:AcquireOverlay()
    self.numOverlays = self.numOverlays + 1;
    if not self.overlays then
        self.overlays = {};
    end
    local overlay = self.overlays[self.numOverlays];
    if not overlay then
        overlay = CreateFrame("Frame", nil, self.container, "NarciMiniTalentTreeActionBarOverlayTemplate");
        self.overlays[self.numOverlays] = overlay;
    end

    return overlay;
end

local function ActionBarUpdator_UpdateAll_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.05 then
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        if InCombatLockdown() then
            self:RegisterEvent("PLAYER_REGEN_ENABLED");
            return
        else
            ActionBarUtil:ProcessAllButtons();
            self:UnregisterEvent("PLAYER_REGEN_ENABLED");
        end
    end
end

local function ActionBarUpdator_CheckMacro_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.1 then
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        ActionBarUtil:UpdateListenerStatus();
    end
end

local function ActionBarListener_OnEvent(self, event, ...)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        ActionBarUtil:RequestUpdate();
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:SetScript("OnUpdate", nil);
        self:UnregisterEvent(event);
        ActionBarUtil:ProcessAllButtons();
    elseif event == "ACTIONBAR_PAGE_CHANGED" then
        ActionBarUtil:RequestUpdate();
    elseif event == "UPDATE_MACROS" then
        ActionBarUtil:OnMacroUpdated();
    end
end

function ActionBarUtil:RequestUpdate()
    self.listener.t = 0;
    self.listener:SetScript("OnUpdate", ActionBarUpdator_UpdateAll_OnUpdate);
end

function ActionBarUtil:OnMacroUpdated()
    self.numCombinedMacros = nil;
    self.listener.t = 0;
    self.listener:SetScript("OnUpdate", ActionBarUpdator_CheckMacro_OnUpdate);
end

function ActionBarUtil:Monitor(state)
    if state then
        self.listener:SetScript("OnEvent", ActionBarListener_OnEvent);
        self.listener:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
        self.listener:RegisterEvent("ACTIONBAR_PAGE_CHANGED");
        self.listener:RegisterEvent("UPDATE_MACROS");
    else
        self.listener:SetScript("OnEvent", nil);
        self.listener:SetScript("OnUpdate", nil);
        self.listener:UnregisterEvent("ACTIONBAR_SLOT_CHANGED");
        self.listener:UnregisterEvent("ACTIONBAR_PAGE_CHANGED");
        self.listener:UnregisterEvent("UPDATE_MACROS");
    end
end

ActionBarUtil.listener:RegisterEvent("PLAYER_ENTERING_WORLD");
ActionBarUtil.listener:SetScript("OnEvent", function(self, event, ...)
    --Initialization
    self:UnregisterEvent(event);
    ActionBarUtil:UpdateListenerStatus();
end);


function ActionBarUtil:ProcessMacro(macroID)
    local name, icon, body = GetMacroInfo(macroID);
    if body then
        local setName = match(body, "/equipset (%C+);");
        local configID = match(body, "local g=(%d+)");
        if setName and configID then
            configID = tonumber(configID);
            if not DataProvider:IsConfigIDValid(configID) then
                --print(configID.. " No longer exists.")
                return
            end

            local setID, secondaryIcon = match(body, "--%((%d+),(%d+)%)");
            if setID and secondaryIcon then
                secondaryIcon = tonumber(secondaryIcon);
                setID = tonumber(setID);
                if secondaryIcon == 0 then
                    secondaryIcon = nil;
                end
                return name, icon, secondaryIcon, configID, setID
            end
        end
    end
end

function ActionBarUtil:UpdateListenerStatus()
    local numCombinedMacros = self:GetCombinedMacro(true);
    if numCombinedMacros > 0 then
        ActionBarUtil:Monitor(true);
        ActionBarUtil:RequestUpdate();
    else
        ActionBarUtil:Monitor(false);
        self:ReleaseOverlays();
    end
end

function ActionBarUtil:GetCombinedMacro(onlyCounting)
    if onlyCounting then
        if not self.numCombinedMacros then
            local _, perChar = GetNumMacros();
            local total = 0;
            local name;
            for macroID = 121, 121 + perChar - 1 do
                name = self:ProcessMacro(macroID);
                if name then
                    total = total + 1;
                end
            end
            self.numCombinedMacros = total;
        end
        return self.numCombinedMacros
    else
        if not self.macroData then
            self.macroData = {};
            local _, perChar = GetNumMacros();
            local total = 0;
            local name, icon1, icon2, configID, setID;
            for macroID = 121, 121 + perChar - 1 do
                name, icon1, icon2, configID, setID = self:ProcessMacro(macroID);
                if name then
                    total = total + 1;
                    self.macroData[total] = {name, icon1, icon2, configID, setID};
                end
            end
        end
        return self.macroData
    end
end


function ActionBarUtil:ProcessAllButtons()
    ActionBarUtil:ReleaseOverlays();
    local _G = _G;
    local GetActionInfo = GetActionInfo;
    local bar;
    local slot;
    local actionType, id, subType;
    local _, secondaryIcon, configID;
    local overlay;

    local activeConfigID = DataProvider:GetPlayerActiveConfigID();

    for i = 1, #ActionBarNames do
        bar = _G[ActionBarNames[i]];
        if bar and bar:IsVisible() and bar.actionButtons then
            for index, button in ipairs(bar.actionButtons) do
                slot = button.action;
                if slot then
                    actionType, id, subType = GetActionInfo(slot);
                    if actionType and actionType == "macro" and id and id > 120 then
                        _, _, secondaryIcon, configID = self:ProcessMacro(id);
                        if secondaryIcon then
                            overlay = ActionBarUtil:AcquireOverlay();
                            overlay.Icon:SetTexture(secondaryIcon);
                            overlay:ClearAllPoints();
                            overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2);
                            overlay:Show();
                            overlay:SetParent(button);
                            overlay.slot = slot;
                            if configID and configID == activeConfigID then
                                overlay.Border:SetTexCoord(0.5, 1, 0, 1);
                            else
                                overlay.Border:SetTexCoord(0, 0.5, 0, 1);
                            end
                        end
                    end
                end
            end
        end
    end
end