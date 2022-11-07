
local function DoSomething(self)
    print("YES")
    self.Alert.FadeOut:Play();
end

local UPDATE_INTERVAL = 0.1;

NarciInteractableTextFrameMixin = {};

local function TestFrame_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > UPDATE_INTERVAL then
        self.t = 0;
        if self:IsMouseOver() and self:IsLinkFocused() then
            if not self.isLinkFocused then
                self.isLinkFocused = true;
                self.Text:SetText(self.highlightText);
            end
        else
            if self.isLinkFocused then
                self.isLinkFocused = nil;
                self.Text:SetText(self.normalText);
            end
        end
    end
end

function NarciInteractableTextFrameMixin:OnLoad()
    local linkText = "[Click Here To Do Something]";
    local normalLink = string.format("|cff54a8ff|Hitem:188901:|h%s|h|r", linkText);
    local highlightLink = string.format("|cffffffff|Hitem:188901:|h%s|h|r", linkText);
    local rawText = "You can %s. Give it a try!";
    local normalText = string.format(rawText, normalLink);
    local highlightText = string.format(rawText, highlightLink);
    self.linkStart, self.linkEnd = string.find(normalText, normalLink, 1, true);
    self.Text:SetText(normalText);
    self.normalText = normalText;
    self.highlightText = highlightText;
    
    self.t = 0;
    self:SetScript("OnUpdate", TestFrame_OnUpdate);
end

function NarciInteractableTextFrameMixin:IsLinkFocused()
    local x, y = GetCursorPosition();
    local characterIndex, inside = self.Text:FindCharacterIndexAtCoordinate(x, y);
    if inside and self.linkStart and self.linkEnd then
        if characterIndex >= self.linkStart and characterIndex <= self.linkEnd then
            return true
        end
    end
end

function NarciInteractableTextFrameMixin:OnMouseDown()
    if self:IsLinkFocused() then
        DoSomething(self);
    end
end