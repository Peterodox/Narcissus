local _, addon = ...

local ClassTalentTooltipUtil = addon.ClassTalentTooltipUtil;

local GetDefinitionInfo = C_Traits.GetDefinitionInfo;
local C_TooltipInfo = C_TooltipInfo;
local GetSpellInfo = GetSpellInfo;
local GetPvpTalentInfoByID = GetPvpTalentInfoByID;
local IsPassiveSpell = IsPassiveSpell;

local select = select;

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
    end
end

function NarciTalentTreeNodeMixin:SetNodeType(typeID, ranksPurchased)
    --typeID: this is custom value 0:Square 1:Circle 2:Octagon
    if typeID ~= self.typeID then
        self.typeID = typeID;
        if typeID == 0 then
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskSquare");
            self.IconBorder:SetTexCoord(0, 0.25, 0, 0.5);
            self.Symbol:SetTexCoord(0, 0.25, 0, 0.25);
        elseif typeID == 1 then
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskCircle");
            self.IconBorder:SetTexCoord(0.25, 0.5, 0, 0.5);
            self.Symbol:SetTexCoord(0, 0.25, 0.25, 0.5);
        else
            self.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeMaskOctagon");
            self.Symbol:SetTexCoord(0.75, 1, 0, 0.25);
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
        end
    end
end

function NarciTalentTreeNodeMixin:SetDefinitionID(definitionID)
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

function NarciTalentTreeNodeMixin:SetBorderColor(isBlue)
    if isBlue then
        if not self.isBlue then
            self.isBlue = true;
            self.IconBorder:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeIconBorderCyan");
        end
    else
        if self.isBlue then
            self.isBlue = nil;
            self.IconBorder:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\NodeIconBorder");
        end
    end
end


local ColorWhite = CreateColor(1, 1, 1);

function NarciTalentTreeNodeMixin:OnEnterOld()
    print(self.nodeID);
    local tooltip = GameTooltip;
    tooltip:Hide();
    tooltip:SetOwner(self, "ANCHOR_NONE");
    tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 4, 0);

    --tooltip:SetTraitEntry(self.entryID, self.rank);
    local info = {};
    local data = C_TooltipInfo.GetTraitEntry(self.entryID, self.rank);
    if data and data.lines then
        local args = {};
        local traitName;
        if self.definitionID then
            local definitionInfo = C_Traits.GetDefinitionInfo(self.definitionID);
            local spellID = definitionInfo and definitionInfo.spellID;
            if spellID then
                traitName = GetSpellInfo(spellID);
                print(traitName)
            end
        end
        args[1] = {intVal = 0, field = "type"};
        args[2] = {stringVal = traitName, field = "leftText"};
        args[3] = {colorVal = ColorWhite, field="leftColor"};
        table.insert(data.lines, 1, {args = args});

    end
    info.tooltipData = data;
    tooltip:ProcessInfo(info);
    tooltip:Show();

    EI = C_TooltipInfo.GetTraitEntry(self.entryID, self.rank);
end

function NarciTalentTreeNodeMixin:OnEnter()
    --print("definitionID: "..self.definitionID)
    ClassTalentTooltipUtil.SetFromNode(self);
end

function NarciTalentTreeNodeMixin:OnLeave()
    GameTooltip:Hide();
    ClassTalentTooltipUtil.HideTooltip();
end

function NarciTalentTreeNodeMixin:SetPvPTalent(talentID, inspectUnit)
    self.talentID = talentID;
    if talentID then
        local _, _, icon, _, _, spellID = GetPvpTalentInfoByID(talentID);
        self.Icon:SetTexture(icon);
        self:SetActive(true);
        if IsPassiveSpell(spellID) then
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