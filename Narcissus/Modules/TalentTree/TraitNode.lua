local _, addon = ...

local OnEnterDelay = addon.TalentTreeOnEnterDelay;
local ClassTalentTooltipUtil = addon.ClassTalentTooltipUtil;

local GetDefinitionInfo = C_Traits.GetDefinitionInfo;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local GetPvpTalentInfoByID = GetPvpTalentInfoByID;
local IsSpellPassive = addon.TransitionAPI.IsSpellPassive;

local select = select;

local Handler;

local NodeUtil = {};
addon.TalentTreeNodeUtil = NodeUtil;

function NodeUtil:SetModeNormal()
    self.clickable = false;
end

NodeUtil:SetModeNormal();

function NodeUtil:SetModePickIcon()
    self.clickable = true;
end

function NodeUtil:AssignHandler(frame)
    Handler = frame;
end


NarciTalentTreeNodeMixin = {};

local function SetNodeIcon(node, definitionInfo, overrideSpellID)
    if definitionInfo then
        local overrideIcon = definitionInfo.overrideIcon;

        if not overrideIcon then
            local spellID = overrideSpellID or definitionInfo.spellID;
            if spellID then
                overrideIcon = select(8, GetSpellInfo(spellID));
            end
        end

        node.Icon:SetTexture(overrideIcon);
        node.Icon:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375);
    else
        node.Icon:SetTexture(nil);
    end
end

function NarciTalentTreeNodeMixin:SetNodeType(typeID, ranksPurchased)
    --typeID: this is custom value 0:Square 1:Circle 2:Octagon

    if typeID ~= self.typeID then
        self.typeID = typeID;
        if typeID == 0 then
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskSquare");
            self.IconBorder:SetTexCoord(0, 0.25, 0, 0.5);
            --self.Symbol:SetTexCoord(0, 0.25, 0, 0.25);
            self.Symbol:SetTexCoord(0.75, 1, 0.25, 0.5);    --DEBUG:Invisible
        elseif typeID == 1 then
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskCircle");
            self.IconBorder:SetTexCoord(0.25, 0.5, 0, 0.5);
            self.Symbol:SetTexCoord(0, 0.25, 0.25, 0.5);
        else    --2
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskOctagon");
            self.Symbol:SetTexCoord(0.75, 1, 0, 0.25);
            self.IconBorder:SetTexCoord(0, 0.25, 0.5, 1);
        end
    end

    if ranksPurchased ~= self.points then
        self.points = ranksPurchased;
        if typeID == 1 then
            if ranksPurchased == 1 then
                --1/2, 1/3
                self.IconBorder:SetTexCoord(0.5, 0.75, 0, 0.5);
                self.Symbol:SetTexCoord(0, 0.25, 0.5, 0.75);
            elseif ranksPurchased == 2 then
                --2/3
                self.IconBorder:SetTexCoord(0.75, 1, 0, 0.5);
                self.Symbol:SetTexCoord(0.25, 0.5, 0.75, 1);
            else
                --don't show number for fully purchased talent (1/1, 2/2, 3/3)
                self.IconBorder:SetTexCoord(0.25, 0.5, 0, 0.5);
                self.Symbol:SetTexCoord(0, 0.25, 0.25, 0.5);
            end
            self.Symbol:SetTexCoord(0.75, 1, 0.25, 0.5);    --DEBUG:Invisible
        elseif typeID == 2 then
            if ranksPurchased == 0 then
                --no slecion
                self.IconBorder:SetTexCoord(0, 0.25, 0.5, 1);
                self.Symbol:SetTexCoord(0.75, 1, 0, 0.25);
            elseif ranksPurchased == 1 then
                --select left
                self.IconBorder:SetTexCoord(0.25, 0.5, 0.5, 1);
                self.Symbol:SetTexCoord(0.25, 0.5, 0, 0.25);
            else
                --select right
                self.IconBorder:SetTexCoord(0.5, 0.75, 0.5, 1);
                self.Symbol:SetTexCoord(0.5, 0.75, 0, 0.25);
            end
        else
            self.IconBorder:SetTexCoord(0, 0.25, 0, 0.5);
        end
    end
end

function NarciTalentTreeNodeMixin:SetDefinitionID(definitionID)
    if not definitionID then return end;

    local info = GetDefinitionInfo(definitionID);
    self.definitionID = definitionID;
    SetNodeIcon(self, info);
end

function NarciTalentTreeNodeMixin:SetActive(state)
    if state or state == nil then
        if not self.isActive then
            self.isActive = true;
            self.Icon:SetVertexColor(1, 1, 1);
            self.Icon:SetDesaturated(false);
            self.IconBorder:SetVertexColor(1, 1, 1);
            self.IconBorder:SetDesaturated(false);
        end
    else
        if self.isActive or self.isActive == nil then
            self.isActive = nil;
            self.Icon:SetVertexColor(0.400, 0.400, 0.400);
            self.Icon:SetDesaturated(true);
            self.IconBorder:SetVertexColor(0.400, 0.400, 0.400);
            self.IconBorder:SetDesaturated(true);
        end
    end
end

function NarciTalentTreeNodeMixin:SetBorderColor(index)
    if index == self.colorIndex then return end;

    self.colorIndex = index;

    if index == 1 then
        self.IconBorder:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeIconBorderYellow");
    elseif index == 2 then
        self.IconBorder:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeIconBorderCyan");
    elseif index == 3 then
        self.IconBorder:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeIconBorderComparison");
    end
end


function NarciTalentTreeNodeMixin:OnEnter()
    if NodeUtil.clickable then
        Handler:HighlightButton(self);
        return
    end

    OnEnterDelay:WatchButton(self);
    ClassTalentTooltipUtil:UpdateCursorDelta();
end

function NarciTalentTreeNodeMixin:OnEnterCallback()
    if self.isPvp then
        ClassTalentTooltipUtil.SetFromPvPButton(self);
    else
        ClassTalentTooltipUtil.SetFromNode(self);
    end
end

function NarciTalentTreeNodeMixin:OnLeave()
    if NodeUtil.clickable then
        Handler:HighlightButton();
    end

    OnEnterDelay:ClearWatch();
    ClassTalentTooltipUtil.HideTooltip();
end

function NarciTalentTreeNodeMixin:OnMouseDown()
    if NodeUtil.clickable then
        Handler:SetSecondaryIcon(self.Icon:GetTexture(), true);
    end
end

function NarciTalentTreeNodeMixin:SetPvPTalent(talentID)
    self.talentID = talentID;
    if talentID then
        local _, _, icon, _, _, spellID = GetPvpTalentInfoByID(talentID);
        self.Icon:SetTexture(icon);
        self:SetActive(true);
        if IsSpellPassive(spellID) then
            self:SetNodeType(1);
        else
            self:SetNodeType(0);
        end
    else
        self.Icon:SetTexture(nil);
        self:SetActive(false);
        self:SetNodeType(2, 0);
    end
end

function NarciTalentTreeNodeMixin:SetComparison(typeID, targetRank, playerRank)
    --typeID: this is custom value 0:Square 1:Circle 2:Octagon
    self.points = nil;
    self.currentRank = targetRank;

    if typeID ~= self.typeID then
        self.typeID = typeID;
        if typeID == 0 then
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskSquare");
            self.Symbol:SetTexCoord(0, 0.25, 0, 0.25);
        elseif typeID == 1 then
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskCircle");
            self.Symbol:SetTexCoord(0, 0.25, 0.25, 0.5);
        else
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskOctagon");
            self.Symbol:SetTexCoord(0.75, 1, 0, 0.25);
        end
    end

    if typeID == 0 then
        if targetRank < playerRank then
            self.IconBorder:SetTexCoord(0, 0.125, 0, 0.25);
        else
            self.IconBorder:SetTexCoord(0, 0.125, 0.5, 0.75);
        end
    elseif typeID == 1 then
        if targetRank < playerRank then
            if targetRank == 0 then
                if playerRank == 1 then --0:1
                    self.IconBorder:SetTexCoord(0.5, 0.625, 0.75, 1);
                elseif playerRank == 2 then --0:2
                    self.IconBorder:SetTexCoord(0.625, 0.75, 0.75, 1);
                elseif playerRank == 3 then --0:3
                    self.IconBorder:SetTexCoord(0.75, 0.875, 0.75, 1);
                else
                    self.IconBorder:SetTexCoord(0.125, 0.25, 0, 0.25);
                end
            elseif targetRank == 1 then
                if playerRank == 2 then --1:2
                    self.IconBorder:SetTexCoord(0.5, 0.625, 0, 0.25);
                elseif playerRank == 3 then --1:3
                    self.IconBorder:SetTexCoord(0.625, 0.75, 0, 0.25);
                else
                    self.IconBorder:SetTexCoord(0.125, 0.25, 0, 0.25);
                end
            else    --2:3
                self.IconBorder:SetTexCoord(0.825, 1, 0.25, 0.5);
            end
        elseif targetRank > playerRank then
            if playerRank == 0 then
                if targetRank == 1 then --1:0
                    self.IconBorder:SetTexCoord(0.5, 0.625, 0.5, 0.75);
                elseif targetRank == 2 then --2:0
                    self.IconBorder:SetTexCoord(0.625, 0.75, 0.5, 0.75);
                elseif targetRank == 3 then --3:0
                    self.IconBorder:SetTexCoord(0.75, 0.875, 0.5, 0.75);
                else
                    self.IconBorder:SetTexCoord(0.125, 0.25, 0.5, 0.75);
                end
            elseif playerRank == 1 then
                if targetRank == 2 then --2:1
                    self.IconBorder:SetTexCoord(0.75, 0.875, 0, 0.25);
                elseif targetRank == 3 then --3:1
                    self.IconBorder:SetTexCoord(0.875, 1, 0, 0.25);
                else
                    self.IconBorder:SetTexCoord(0.125, 0.25, 0.5, 0.75);
                end
            else    --3:2
                self.IconBorder:SetTexCoord(0.875, 1, 0.25, 0.5);
            end
        else
            self.IconBorder:SetTexCoord(0.125, 0.25, 0.5, 0.75);
        end
    elseif typeID == 2 then
        if targetRank == playerRank then
            if targetRank == 0 then
                self.IconBorder:SetTexCoord(0, 0.125, 0.75, 1);
            elseif targetRank == 1 then
                self.IconBorder:SetTexCoord(0.125, 0.25, 0.75, 1);
            else
                self.IconBorder:SetTexCoord(0.25, 0.375, 0.75, 1);
            end
        else
            if targetRank == 0 then
                if playerRank == 1 then --left
                    self.IconBorder:SetTexCoord(0, 0.125, 0.25, 0.5);
                else    --right
                    self.IconBorder:SetTexCoord(0.125, 0.25, 0.25, 0.5);
                end
            elseif targetRank == 1 then
                if playerRank == 0 then
                    self.IconBorder:SetTexCoord(0.125, 0.25, 0.75, 1);
                else --left,right
                    self.IconBorder:SetTexCoord(0.5, 0.625, 0.25, 0.5);
                end
            else
                if playerRank == 0 then
                    self.IconBorder:SetTexCoord(0.25, 0.375, 0.75, 1);
                else --left,right
                    self.IconBorder:SetTexCoord(0.625, 0.75, 0.25, 0.5);
                end
            end
        end
    end
end