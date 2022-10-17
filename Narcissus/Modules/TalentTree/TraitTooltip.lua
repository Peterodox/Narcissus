local _, addon = ...

local ClassTalentTooltipUtil = {};
addon.ClassTalentTooltipUtil = ClassTalentTooltipUtil;

local PrimaryTooltip;
local SecondaryTooltip;

local NarciAPI = NarciAPI;
local SecondsToCooldownAbbrev = NarciAPI.SecondsToCooldownAbbrev;

local C_TooltipInfo = C_TooltipInfo;
local GetDefinitionInfo = C_Traits.GetDefinitionInfo;
local GetSpellInfo = GetSpellInfo;
local GetSpellBaseCooldown = GetSpellBaseCooldown;
local C_Spell = C_Spell;
local IsPassiveSpell = IsPassiveSpell;
local GetActiveSpecGroup = GetActiveSpecGroup;
local GetPvpTalentInfoByID = GetPvpTalentInfoByID;

local type = type;

local PADDING_PIXEL_SIZE = 16;
local ICON_PIXEL_SIZE = 36;
local HEADER_PIXEL_SIZE = 16;
local TEXT_PIEXL_SIZE = 15;
local DESC_PIXEL_SIZE = 288;

local PIXEL = 1;
local PADDING = 16;
local COOLDOWN_ICON = "";
local DESC_MAX_LINES = 2;
local DESC_MAX_WIDTH = 288;

local function Tooltip_UpdatePixel(tooltip)
   local px = NarciAPI.GetPixelForWidget(tooltip, 1);
   PIXEL = px;
   PADDING = PADDING_PIXEL_SIZE * px;
   COOLDOWN_ICON = string.format("|TInterface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\CooldownTextIcon2:%d:%d:0:0:16:16:0:16:0:16:%d:%d:%d|t", 0, 1, 171, 171, 171);

   tooltip.Icon:SetSize(ICON_PIXEL_SIZE*px, ICON_PIXEL_SIZE*px);
   tooltip.IconBorder:SetSize(64*px, 64*px);

   local font, _, flag = tooltip.Header:GetFont();
   tooltip.Header:SetFont(font, HEADER_PIXEL_SIZE*px, flag);

   font, _, flag = tooltip.Subtext:GetFont();
   tooltip.Subtext:SetFont(font, TEXT_PIEXL_SIZE*px, flag);
   tooltip.Description:SetFont(font, TEXT_PIEXL_SIZE*px, flag);

   tooltip.Icon:ClearAllPoints();
   tooltip.Header:ClearAllPoints();
   tooltip.Subtext:ClearAllPoints();
   tooltip.Description:ClearAllPoints();

   tooltip.Icon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, -PADDING);
   tooltip.Header:SetPoint("TOPLEFT", tooltip.Icon, "TOPRIGHT", 8*px, 0);
   tooltip.Subtext:SetPoint("BOTTOMLEFT", tooltip.Icon, "BOTTOMRIGHT", 8*px, 0);
   tooltip.Description:SetPoint("TOPLEFT", tooltip.Icon, "BOTTOMLEFT", 0, -8*px);
   
   DESC_MAX_WIDTH = DESC_PIXEL_SIZE * px;
   tooltip.Description:SetWidth(DESC_MAX_WIDTH);
end

local function CreateTooltip()
    local tooltip = CreateFrame("Frame", nil, NarciMiniTalentTree, "NarciTalentTreeTraitTooltipTemplate");
    NarciAPI.NineSliceUtil.SetUpBackdrop(tooltip.Background, "classTalentTrait");
    Tooltip_UpdatePixel(tooltip);
    tooltip:SetFixedFrameStrata(true);
    tooltip:SetFrameStrata("TOOLTIP");
    tooltip:SetFrameLevel(80);
    tooltip.Description:SetMaxLines(DESC_MAX_LINES);

    return tooltip
end

local function Tooltip_UpdateSize(tooltip)
    local headerWidth = (ICON_PIXEL_SIZE + 8) * PIXEL + math.max(tooltip.Header:GetWrappedWidth() or 0, tooltip.Subtext:GetWrappedWidth() or 0);
    local descHeight = tooltip.Description:GetHeight();
    local descWidth = tooltip.Description:GetWrappedWidth() or 0;
    if tooltip.Description:IsTruncated() then
        descWidth = DESC_MAX_WIDTH;
    end
    tooltip:SetSize(2*PADDING + math.max(headerWidth, descWidth), (ICON_PIXEL_SIZE + 8 + 2*PADDING_PIXEL_SIZE)*PIXEL + descHeight);
end

local function Tooltip_FadeIn_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        if self.t < 0.125 then
            self:SetAlpha(8 * self.t);
        else
            self:SetAlpha(1);
            self:SetScript("OnUpdate", nil);
        end
    else
        self:SetAlpha(0);
    end
end

local function Tooltip_FadeIn(tooltip)
    if not tooltip.animIn then
        tooltip.animIn = tooltip:CreateAnimationGroup();
        local ag = tooltip.animIn;
        local tran1 = ag:CreateAnimation("translation");
        tran1:SetDuration(0);
        tran1:SetOrder(1);
        tran1:SetOffset(0, -8);
        local tran2 = ag:CreateAnimation("translation");
        tran2:SetSmoothing("OUT");
        tran2:SetDuration(0.15);
        tran2:SetOrder(1);
        tran2:SetStartDelay(0.08);
        tran2:SetOffset(0, 8);
        tooltip.tran1 = tran1;
        tooltip.tran2 = tran2;
    end
    local deltaX, deltaY = GetCursorDelta();
    local d = math.sqrt(deltaX*deltaX + deltaY*deltaY);
    if d == 0 then
        tooltip.tran1:SetOffset(0, 0);
        tooltip.tran2:SetOffset(0, 0);
    else
        tooltip.tran1:SetOffset(-deltaX, -deltaY);
        tooltip.tran2:SetOffset(deltaX, deltaY);
    end
    tooltip.animIn:Stop();
    tooltip.animIn:Play();
    tooltip.t = (tooltip.isSecondary and -0.125) or 0;
    tooltip:SetScript("OnUpdate", Tooltip_FadeIn_OnUpdate);
end

local function Tooltip_SetActive(tooltip, isActive)
    if isActive ~= tooltip.isActive then
        tooltip.isActive = isActive;
        if isActive then
            tooltip.Header:SetTextColor(1, 1, 1);
            tooltip.Subtext:SetTextColor(0.67, 0.67, 0.67);
            tooltip.Description:SetTextColor(1, 0.82, 0);
            tooltip.Icon:SetDesaturated(false);
            tooltip.Icon:SetVertexColor(1, 1, 1);
        else
            tooltip.Header:SetTextColor(0.67, 0.67, 0.67);
            tooltip.Subtext:SetTextColor(0.5, 0.5, 0.5);
            tooltip.Description:SetTextColor(0.67, 0.67, 0.67);
            tooltip.Icon:SetDesaturated(true);
            tooltip.Icon:SetVertexColor(0.8, 0.8, 0.8);
        end
    end
end

local function SetTooltipLineText(fontString, line)
    if line and line.args then
        if line.args[2] then
            fontString:SetText(line.args[2].stringVal);
            return true
        end
    end
end

local function IsLineColorYellow(colorVal)
    if colorVal then
        local r, g, b = colorVal.r, colorVal.g, colorVal.b;
        if (r > 0.99 and r < 1.01) and (g > 0.81 and g < 0.83) then
            return true
        end
    end
end

local function GetLineText(line, yellowTextOnly)
    local text;

    if line and line.args then
        if line.args[2] then
            text = line.args[2].stringVal;
        end
        AG = line.args
    else
        return
    end

    if text == "" then
        return
    else
        if yellowTextOnly then
            --usually the spell's descriotion
            if IsLineColorYellow(line.args[3].colorVal) then
                if text ~= "" then
                    return text
                end
            end
        else
            return text
        end
    end
end

local function Tooltip_OnSpellDataLoaded_TraitEntry(self, event, spellID, success)
    --print(event, spellID)
    if spellID == self.pendingSpell then
        self:SetScript("OnEvent", nil);
        self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
        self.pendingSpell = nil;
        local data = C_TooltipInfo.GetTraitEntry(self.entryID, self.rank);
        if data and data.lines then
            local text = GetLineText(data.lines[3]);
            self.Description:SetText(text);
            Tooltip_UpdateSize(self);
        end
        return
    end

    if not self.pendingSpell then
        self:SetScript("OnEvent", nil);
        self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    end
end

local function Tooltip_OnSpellDataLoaded_PvPTalent(self, event, spellID, success)
    --print(event, spellID)
    if spellID == self.pendingSpell then
        self:SetScript("OnEvent", nil);
        self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
        self.pendingSpell = nil;
        local data = C_TooltipInfo.GetPvpTalent(self.talentID, self.isInspecting, self.specGroupIndex, self.Index);
        if data and data.lines then
            local text = GetLineText(data.lines[3], true);
            if not text then
                text = GetLineText(data.lines[4], true);
            end
            if not text then
                text = "Loading"
            end
            DT = data.lines
            self.Description:SetText(text);
            Tooltip_UpdateSize(self);
        end
        return
    end

    if not self.pendingSpell then
        self:SetScript("OnEvent", nil);
        self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    end
end

local function SetupTooltipBySpellID(tooltip, spellID, subtext, castTime)
    local isPassive = IsPassiveSpell(spellID);
    local extraText;

    if isPassive then
        if not tooltip.isPassive then
            tooltip.isPassive = true;
            tooltip.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Circle");
            tooltip.IconBorder:SetTexCoord(0.5, 1, 0, 1);
        end
        extraText = SPELL_PASSIVE;
    else
        if tooltip.isPassive then
            tooltip.isPassive = nil;
            tooltip.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Full");
            tooltip.IconBorder:SetTexCoord(0, 0.5, 0, 1);
        end

        if not castTime then
            local _;
            _, _, _, castTime = GetSpellInfo(spellID);
        end
        if castTime == 0 then
            extraText = SPELL_CAST_TIME_INSTANT;
        else
            extraText = "Cast";
        end
        
        local cd = GetSpellBaseCooldown(spellID or 0);
        if cd and cd > 0 then
            local cdText = SecondsToCooldownAbbrev(cd / 1000);
            extraText = extraText.. "   CD: " .. cdText;
        end
    end

    if subtext then
        subtext = subtext.."   "..extraText;
    else
        subtext = extraText;
    end

    tooltip.Subtext:SetText(subtext);
end

local function Tooltip_SetTraitEntry(tooltip, entryID, rank, definitionID, ranksPurchased, maxRanks, selectedEntryID)
    if not entryID then
        tooltip:Hide();
        return
    end

    tooltip.entryID = entryID;
    tooltip.rank = rank;
    tooltip.definitionID = definitionID;

    if type(entryID) == "table" then
        if not SecondaryTooltip then
            SecondaryTooltip = CreateTooltip();
            SecondaryTooltip:SetPoint("TOPLEFT", PrimaryTooltip, "BOTTOMLEFT", 0, 0);
            SecondaryTooltip:SetFrameLevel(PrimaryTooltip:GetFrameLevel() - 4);
            SecondaryTooltip.isSecondary = true;
        end

        local firstEntryID = entryID[1];
        local secondEntryID = entryID[2];
        local firstEntryInfo = NarciMiniTalentTree:GetAndCacheEntryInfo(firstEntryID);
        local secondEntryInfo = NarciMiniTalentTree:GetAndCacheEntryInfo(secondEntryID);

        if selectedEntryID == firstEntryID or selectedEntryID == secondEntryID then
            if selectedEntryID == firstEntryID then
                Tooltip_SetTraitEntry(tooltip, firstEntryID, 0, firstEntryInfo.definitionID, 1, 1);
                Tooltip_SetTraitEntry(SecondaryTooltip, secondEntryID, 0, secondEntryInfo.definitionID, 0, 1);
                SecondaryTooltip:SetPoint("TOPLEFT", PrimaryTooltip, "BOTTOMLEFT", 32*PIXEL, 0);
            else
                Tooltip_SetTraitEntry(tooltip, secondEntryID, 0, secondEntryInfo.definitionID, 1, 1);
                Tooltip_SetTraitEntry(SecondaryTooltip, firstEntryID, 0, firstEntryInfo.definitionID, 0, 1);
                SecondaryTooltip:SetPoint("TOPLEFT", PrimaryTooltip, "BOTTOMLEFT", -32*PIXEL, 0);
            end
        else
            Tooltip_SetTraitEntry(tooltip, firstEntryID, 0, firstEntryInfo.definitionID, 0, 1);
            Tooltip_SetTraitEntry(SecondaryTooltip, secondEntryID, 0, secondEntryInfo.definitionID, 0, 1);
            SecondaryTooltip:SetPoint("TOPLEFT", PrimaryTooltip, "BOTTOMLEFT", 32*PIXEL, 0);
        end
        return
    end

    local data = C_TooltipInfo.GetTraitEntry(entryID, rank);
    if data and data.lines then
        local traitName, icon, castTime, _, minRange, maxRange, originalIcon;
        local spellID, isPassive;
        if definitionID then
            local definitionInfo = GetDefinitionInfo(definitionID);
            spellID = definitionInfo and (definitionInfo.spellID or definitionInfo.overriddenSpellID);
            icon = (definitionInfo and definitionInfo.overrideIcon);
            if spellID then
                traitName, _, icon, castTime, minRange, maxRange, _, originalIcon = GetSpellInfo(spellID);
                if not icon then
                    icon = originalIcon;
                end
            end
        else
            print("NarcissusTalentTree: Missing DefinitionID");
            return
        end

        tooltip.Icon:SetTexture(icon);
        tooltip.Header:SetText(traitName);

        local text, text2;
    
        if ranksPurchased and maxRanks then
            text2 = ranksPurchased.."/"..maxRanks;
            if ranksPurchased > 0 then
                Tooltip_SetActive(tooltip, true);
                if ranksPurchased ~= maxRanks then
                    text2 = "|cffffffff"..text2.."|r";
                end
            else
                Tooltip_SetActive(tooltip, false);
            end
        end
        SetupTooltipBySpellID(tooltip, spellID, text2, castTime);

        local isSpellDescriptionCached;

        if C_Spell.IsSpellDataCached(spellID) then
            text = GetLineText(data.lines[3]);
            if not text then
                text = GetLineText(data.lines[2]);  --sometimes the second line is the description
            end
            if text then
                isSpellDescriptionCached = true;
                tooltip.Description:SetText(text);
            end
        end

        if isSpellDescriptionCached then
            tooltip.pendingSpell = nil;
        else
            tooltip.Description:SetText(RETRIEVING_DATA);
            tooltip.pendingSpell = spellID;
            tooltip:RegisterEvent("SPELL_DATA_LOAD_RESULT");
            tooltip:SetScript("OnEvent", Tooltip_OnSpellDataLoaded_TraitEntry);
            C_Spell.RequestLoadSpellData(spellID);
        end
    
        Tooltip_UpdateSize(tooltip);
        tooltip:Show();
        Tooltip_FadeIn(tooltip);
    else
        tooltip:Hide();
    end
end

local function Tooltip_SetPvpTalent(tooltip, talentID, isInspecting, slotIndex)
    if not talentID then
        tooltip:Hide();
        return
    end

    local specGroupIndex =  GetActiveSpecGroup(isInspecting);
    local data = C_TooltipInfo.GetPvpTalent(talentID, isInspecting, specGroupIndex, slotIndex);
    
    tooltip.talentID, tooltip.isInspecting, tooltip.specGroupIndex, tooltip.Index = talentID, isInspecting, specGroupIndex, slotIndex;

    if data and data.lines then
        local _, name, icon, _, _, spellID = GetPvpTalentInfoByID(talentID, isInspecting, specGroupIndex, slotIndex);
        tooltip.Icon:SetTexture(icon);
        tooltip.Header:SetText(name);

        SetupTooltipBySpellID(tooltip, spellID);

        local isSpellDescriptionCached;
    
        if C_Spell.IsSpellDataCached(spellID) then
            local text = GetLineText(data.lines[3], true);
            if not text then
                text = GetLineText(data.lines[4], true);
            end
            if text then
                tooltip.Description:SetText(text);
                isSpellDescriptionCached = true;
            end
        end

        if isSpellDescriptionCached then
            tooltip.pendingSpell = nil;
        else
            tooltip.Description:SetText(RETRIEVING_DATA);
            tooltip.pendingSpell = spellID;
            tooltip:RegisterEvent("SPELL_DATA_LOAD_RESULT");
            tooltip:SetScript("OnEvent", Tooltip_OnSpellDataLoaded_PvPTalent);
            C_Spell.RequestLoadSpellData(spellID);
        end

        Tooltip_UpdateSize(tooltip);
        Tooltip_SetActive(tooltip, true);
        tooltip:Show();
        Tooltip_FadeIn(tooltip);
    else
        tooltip:Hide();
    end
end

function ClassTalentTooltipUtil.SetFromNode(nodeButton)
    if not PrimaryTooltip then
        PrimaryTooltip = CreateTooltip();
        PrimaryTooltip:SetScript("OnHide", ClassTalentTooltipUtil.HideTooltip);
    end

    PrimaryTooltip:Hide();
    PrimaryTooltip:SetPoint("TOPLEFT", nodeButton, "TOPRIGHT", 4, 0);
    Tooltip_SetTraitEntry(PrimaryTooltip, nodeButton.entryIDs or nodeButton.entryID, nodeButton.rank, nodeButton.definitionID, nodeButton.currentRank, nodeButton.maxRanks, nodeButton.entryID);
end

function ClassTalentTooltipUtil.HideTooltip()
    if PrimaryTooltip then
        PrimaryTooltip:Hide();
    end
    if SecondaryTooltip then
        SecondaryTooltip:Hide();
    end
end

function ClassTalentTooltipUtil.SetFromPvPButton(pvpButton)
    if not PrimaryTooltip then
        PrimaryTooltip = CreateTooltip();
        PrimaryTooltip:SetScript("OnHide", ClassTalentTooltipUtil.HideTooltip);
    end

    PrimaryTooltip:Hide();
    PrimaryTooltip:SetPoint("TOPLEFT", pvpButton, "TOPRIGHT", 4, 0);
    Tooltip_SetPvpTalent(PrimaryTooltip, pvpButton.talentID, pvpButton.isInspecting, pvpButton.index);
end

function ClassTalentTooltipUtil.UpdateMaxLines()
    if PrimaryTooltip then
        PrimaryTooltip.Description:SetMaxLines(DESC_MAX_LINES);
    end

    if SecondaryTooltip then
        SecondaryTooltip.Description:SetMaxLines(DESC_MAX_LINES);
    end
end

do
    local SettingFunctions = addon.SettingFunctions;

    function SettingFunctions.TruncateTalentTreeTooltip(state, db)
        if state == nil then
            state = db["TalentTreeShortTooltip"];
        end
        if state then
            DESC_MAX_LINES = 2;
        else
            DESC_MAX_LINES = 0;
        end
        ClassTalentTooltipUtil.UpdateMaxLines();
    end
end