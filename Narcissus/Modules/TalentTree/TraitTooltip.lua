local _, addon = ...

local ClassTalentTooltipUtil = {};
addon.ClassTalentTooltipUtil = ClassTalentTooltipUtil;

local DataProvider = addon.TalentTreeDataProvider;

local PrimaryTooltip;
local SecondaryTooltip;
local MainFrame;

local NarciAPI = NarciAPI;
local GetTraitEntryTooltip = NarciAPI.GetTraitEntryTooltip;
local GetPvpTalentTooltip = NarciAPI.GetPvpTalentTooltip

local C_Traits = C_Traits;
local GetSpellInfo = addon.TransitionAPI.GetSpellInfo;
local C_Spell = C_Spell;
local IsSpellPassive = addon.TransitionAPI.IsSpellPassive;
local GetActiveSpecGroup = GetActiveSpecGroup;
local GetPvpTalentInfoByID = GetPvpTalentInfoByID;
local GetCursorDelta = GetCursorDelta;

local type = type;

local PADDING_PIXEL_SIZE = 16;
local ICON_PIXEL_SIZE = 36;
local HEADER_TEXT_PIXEL_SIZE = 16;
local DESC_TEXT_PIXEL_SIZE = 15;
local DESC_WIDTH_PIXEL_SIZE = 288;

local PIXEL = 1;
local PADDING = 16;
local COOLDOWN_ICON = "";
local DESC_MAX_LINES = 2;
local DESC_MAX_WIDTH = 288;

local USE_CLASS_BACKGROUND = false;

do
    local function ChangePixelSize(sizeInfo)
        PADDING_PIXEL_SIZE = sizeInfo.fontHeight;
        HEADER_TEXT_PIXEL_SIZE = sizeInfo.fontHeight;
        DESC_TEXT_PIXEL_SIZE = sizeInfo.smallFontHeight;
    end
    addon.TalentTreeTextureUtil:AddSizeChangedCallback(ChangePixelSize);
end

local function AppendText(originalText, ...)
    local seg;
    for i = 1, select("#", ...) do
        seg = select(i, ...);
        if seg then
            if originalText then
                originalText = originalText .. "   " ..seg;
            else
                originalText = seg;
            end
        end
    end
    return originalText
end

local function Tooltip_UpdatePixel(tooltip)
   local px = NarciAPI.GetPixelForWidget(tooltip, 1);
   PIXEL = px;
   PADDING = PADDING_PIXEL_SIZE * px;
   COOLDOWN_ICON = string.format("|TInterface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\CooldownTextIcon2:%d:%d:0:0:16:16:0:16:0:16:%d:%d:%d|t", 0, 1, 171, 171, 171);

   tooltip.Icon:SetSize(ICON_PIXEL_SIZE*px, ICON_PIXEL_SIZE*px);
   tooltip.IconBorder:SetSize(64*px, 64*px);

   local font, _, flag = tooltip.Header:GetFont();
   tooltip.Header:SetFont(font, HEADER_TEXT_PIXEL_SIZE*px, flag);

   font, _, flag = tooltip.Subtext:GetFont();
   tooltip.Subtext:SetFont(font, DESC_TEXT_PIXEL_SIZE*px, flag);
   tooltip.Description:SetFont(font, DESC_TEXT_PIXEL_SIZE*px, flag);

   tooltip.Icon:ClearAllPoints();
   tooltip.Header:ClearAllPoints();
   tooltip.Subtext:ClearAllPoints();
   tooltip.Description:ClearAllPoints();

   tooltip.Icon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, -PADDING);
   tooltip.Header:ClearAllPoints();
   tooltip.Header:SetPoint("TOPLEFT", tooltip.Icon, "TOPRIGHT", 8*px, 0);
   tooltip.Subtext:ClearAllPoints();
   tooltip.Subtext:SetPoint("BOTTOMLEFT", tooltip.Icon, "BOTTOMRIGHT", 8*px, 0);
   tooltip.Description:ClearAllPoints();
   tooltip.Description:SetPoint("TOPLEFT", tooltip.Icon, "BOTTOMLEFT", 0, -8*px);
   
   DESC_MAX_WIDTH = DESC_WIDTH_PIXEL_SIZE * px;
   tooltip.Description:SetWidth(DESC_MAX_WIDTH);
end

local function CreateTooltip()
    local tooltip = CreateFrame("Frame", nil, MainFrame, "NarciTalentTreeTraitTooltipTemplate");
    Tooltip_UpdatePixel(tooltip);
    tooltip:SetFrameStrata("TOOLTIP");
    tooltip:SetFixedFrameStrata(true);
    tooltip:SetFrameLevel(80);
    --tooltip.Description:SetMaxLines(DESC_MAX_LINES);

    --[[
    local offset = 0;
    tooltip.BlurBackground:ClearAllPoints();
    tooltip.BlurBackground:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", -offset, offset);
    tooltip.BlurBackground:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", offset, -offset);
    local mask = tooltip:CreateMaskTexture(nil, "ARTWORK");
    mask:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 0, 0);
    mask:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 0, 0);
    tooltip.BlurBackground:AddMaskTexture(mask);
    mask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Full", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");

    local softenEdgeMask = tooltip:CreateMaskTexture(nil, "ARTWORK");
    softenEdgeMask:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", -offset, offset);
    softenEdgeMask:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", offset, -offset);
    tooltip.BlurBackground:AddMaskTexture(softenEdgeMask);
    softenEdgeMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Modules\\TalentTree\\FullFrameSoftEdgeMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    --]]

    if USE_CLASS_BACKGROUND then
        NarciAPI.NineSliceUtil.SetUpBorder(tooltip.Border, "classTalentTraitTransparent");
    else
        NarciAPI.NineSliceUtil.SetUpBorder(tooltip.Border, "classTalentTrait");
    end

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
    local deltaX, deltaY = ClassTalentTooltipUtil:GetCursorDelta();
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
    tooltip.t = (tooltip.isSecondary and -0.05) or 0;
    tooltip:SetAlpha(0);
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

local function Tooltip_OnSpellDataLoaded_TraitEntry(self, event, spellID, success)
    --print(event, spellID)
    if spellID == self.pendingSpell then
        self:SetScript("OnEvent", nil);
        self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
        self.pendingSpell = nil;

        local subtext;
        if self.ranksPurchased and self.maxRanks then
            subtext = self.ranksPurchased.."/"..self.maxRanks;
            if self.ranksPurchased > 0 then
                if self.ranksPurchased ~= self.maxRanks then
                    subtext = "|cffffffff"..subtext.."|r";
                end
            end
        end

        local traitData = GetTraitEntryTooltip(self.entryID, self.rank);
        if traitData then
            if traitData.replaceSpell then
                subtext = subtext .. "   "..traitData.replaceSpell;
            end
            if traitData.costText then
                subtext = subtext .. "   "..traitData.costText;
            end
            if traitData.castText then
                subtext = subtext .. "   "..traitData.castText;
            end
            if traitData.rangeText then
                subtext = subtext .. "   "..traitData.rangeText;
            end
            if traitData.cdText then
                subtext = subtext .. "   "..traitData.cdText;
            end
            self.Subtext:SetText(subtext);

            local desc = "";
            if traitData.descriptions then
                for i = 1, #traitData.descriptions do
                    if i == 1 then
                        desc = traitData.descriptions[i];
                    else
                        desc = desc.."\n"..traitData.descriptions[i];
                    end
                end
                self.Description:SetText(desc);
            end

            Tooltip_UpdateSize(self);
        else
            self:Hide();
        end
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

        local traitData = GetPvpTalentTooltip(self.talentID, self.isInspecting, self.specGroupIndex, self.slotIndex)
        if traitData then
            local subtext;
            subtext = AppendText(subtext, traitData.replaceSpell, traitData.costText, traitData.castText, traitData.rangeText, traitData.cdText);
            self.Subtext:SetText(subtext);

            local desc = "";
            if traitData.descriptions then
                for i = 1, #traitData.descriptions do
                    if i == 1 then
                        desc = traitData.descriptions[i];
                    else
                        desc = desc.."\n"..traitData.descriptions[i];
                    end
                end
                self.Description:SetText(desc);
            end

            Tooltip_UpdateSize(self);
        else
            self:Hide();
        end
    end

    if not self.pendingSpell then
        self:SetScript("OnEvent", nil);
        self:UnregisterEvent("SPELL_DATA_LOAD_RESULT");
    end
end

local function Tooltip_SetTraitEntry(tooltip, entryID, rank, definitionID, ranksPurchased, maxRanks, selectedEntryID)
    if not entryID then
        tooltip:Hide();
        return
    end

    tooltip.entryID = entryID;
    tooltip.rank = rank;
    tooltip.maxRanks = maxRanks;
    tooltip.ranksPurchased = ranksPurchased;
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
        local firstEntryInfo = DataProvider.GetEntryInfo(firstEntryID);
        local secondEntryInfo = DataProvider.GetEntryInfo(secondEntryID);

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


    local _, spellID, icon, traitName, originalIcon, isPassive;
    if definitionID then
        local definitionInfo = C_Traits.GetDefinitionInfo(definitionID);
        spellID = definitionInfo and (definitionInfo.spellID or definitionInfo.overriddenSpellID);
        icon = (definitionInfo and definitionInfo.overrideIcon);
        if spellID then
            traitName, _, _, _, _, _, _, originalIcon = GetSpellInfo(spellID);
            if not icon then
                icon = originalIcon;
            end
            isPassive = IsSpellPassive(spellID);
        end
    else
        print("NarcissusTalentTree: Missing DefinitionID");
        return
    end


    if isPassive then
        if not tooltip.isPassive then
            tooltip.isPassive = true;
            tooltip.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Circle");
            tooltip.IconBorder:SetTexCoord(0.5, 1, 0, 1);
        end
    else
        if tooltip.isPassive then
            tooltip.isPassive = nil;
            tooltip.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Full");
            tooltip.IconBorder:SetTexCoord(0, 0.5, 0, 1);
        end
    end

    local isSpellDescriptionCached;

    local subtext;
    if ranksPurchased and maxRanks then
        subtext = ranksPurchased.."/"..maxRanks;
        if ranksPurchased > 0 then
            Tooltip_SetActive(tooltip, true);
            if ranksPurchased ~= maxRanks then
                subtext = "|cffffffff"..subtext.."|r";
            end
        else
            Tooltip_SetActive(tooltip, false);
        end
    end

    if C_Spell.IsSpellDataCached(spellID) then
        local traitData = GetTraitEntryTooltip(entryID, rank);
        if traitData then
            isSpellDescriptionCached = true;
            if traitData.replaceSpell then
                subtext = subtext .. "   "..traitData.replaceSpell;
            end
            if traitData.costText then
                subtext = subtext .. "   "..traitData.costText;
            end
            if traitData.castText then
                subtext = subtext .. "   "..traitData.castText;
            end
            if traitData.rangeText then
                subtext = subtext .. "   "..traitData.rangeText;
            end
            if traitData.cdText then
                subtext = subtext .. "   "..traitData.cdText;
            end

            local desc = "";
            if traitData.descriptions then
                for i = 1, #traitData.descriptions do
                    if i == 1 then
                        desc = traitData.descriptions[i];
                    else
                        desc = desc.."\n"..traitData.descriptions[i];
                    end
                end
                tooltip.Description:SetText(desc);
            end
        else
            tooltip:Hide();
            return
        end
    else
        tooltip.Description:SetText(RETRIEVING_DATA);
    end

    tooltip.Icon:SetTexture(icon);
    tooltip.Header:SetText(traitName);
    tooltip.Subtext:SetText(subtext);

    if isSpellDescriptionCached and icon then
        tooltip.pendingSpell = nil;
    else
        tooltip.pendingSpell = spellID;
        tooltip:RegisterEvent("SPELL_DATA_LOAD_RESULT");
        tooltip:SetScript("OnEvent", Tooltip_OnSpellDataLoaded_TraitEntry);
        C_Spell.RequestLoadSpellData(spellID);
    end

    Tooltip_UpdateSize(tooltip);
    if not tooltip:IsShown() then
        Tooltip_FadeIn(tooltip);
    end
    tooltip:Show();
end

local function Tooltip_SetPvpTalent(tooltip, talentID, isInspecting, slotIndex)
    if not talentID then
        tooltip:Hide();
        return
    end

    local specGroupIndex =  GetActiveSpecGroup(isInspecting);
    tooltip.talentID, tooltip.isInspecting, tooltip.specGroupIndex, tooltip.slotIndex = talentID, isInspecting, specGroupIndex, slotIndex;

    local _, talentName, icon, _, _, spellID = GetPvpTalentInfoByID(talentID, isInspecting, specGroupIndex, slotIndex);
    local isPassive;

    if spellID then
        isPassive = IsSpellPassive(spellID);
    end
    if isPassive then
        if not tooltip.isPassive then
            tooltip.isPassive = true;
            tooltip.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Circle");
            tooltip.IconBorder:SetTexCoord(0.5, 1, 0, 1);
        end
    else
        if tooltip.isPassive then
            tooltip.isPassive = nil;
            tooltip.IconMask:SetTexture("Interface\\AddOns\\Narcissus\\Art\\Masks\\Full");
            tooltip.IconBorder:SetTexCoord(0, 0.5, 0, 1);
        end
    end

    local isSpellDescriptionCached;
    local subtext;

    if C_Spell.IsSpellDataCached(spellID) then
        local traitData = GetPvpTalentTooltip(talentID, isInspecting, specGroupIndex, slotIndex)
        if traitData then
            isSpellDescriptionCached = true;
            subtext = AppendText(subtext, traitData.replaceSpell, traitData.costText, traitData.castText, traitData.rangeText, traitData.cdText);

            local desc = "";
            if traitData.descriptions then
                for i = 1, #traitData.descriptions do
                    if i == 1 then
                        desc = traitData.descriptions[i];
                    else
                        desc = desc.."\n"..traitData.descriptions[i];
                    end
                end
                tooltip.Description:SetText(desc);
            end
        else
            tooltip:Hide();
            return
        end
    else
        tooltip.Description:SetText(RETRIEVING_DATA);
    end

    tooltip.Icon:SetTexture(icon);
    tooltip.Header:SetText(talentName);
    tooltip.Subtext:SetText(subtext);

    if isSpellDescriptionCached and icon then
        tooltip.pendingSpell = nil;
    else
        tooltip.pendingSpell = spellID;
        tooltip:RegisterEvent("SPELL_DATA_LOAD_RESULT");
        tooltip:SetScript("OnEvent", Tooltip_OnSpellDataLoaded_PvPTalent);
        C_Spell.RequestLoadSpellData(spellID);
    end

    Tooltip_UpdateSize(tooltip);
    if not tooltip:IsShown() then
        Tooltip_FadeIn(tooltip);
    end

    Tooltip_SetActive(tooltip, true);
    tooltip:Show();
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
    ClassTalentTooltipUtil:UpdateCursorDelta();
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

function ClassTalentTooltipUtil:UpdateCursorDelta()
    self.deltaX, self.deltaY = GetCursorDelta();
end

function ClassTalentTooltipUtil:GetCursorDelta()
    return (self.deltaX or 0), (self.deltaY or 0)
end

function ClassTalentTooltipUtil:SetUseClassBackground(state)
    USE_CLASS_BACKGROUND = state;

    local themeName;
    if state then
        themeName = "classTalentTraitTransparent";
    else
        themeName = "classTalentTrait";
    end
    if PrimaryTooltip then
        NarciAPI.NineSliceUtil.SetUpBorder(PrimaryTooltip.Border, themeName);
    end
    if SecondaryTooltip then
        NarciAPI.NineSliceUtil.SetUpBorder(SecondaryTooltip.Border, themeName);
    end
end

function ClassTalentTooltipUtil:AssignMainFrame(frame)
    MainFrame = frame;
end

function ClassTalentTooltipUtil:UpdatePixel()
    if PrimaryTooltip then
        Tooltip_UpdatePixel(PrimaryTooltip);
    end
    if SecondaryTooltip then
        Tooltip_UpdatePixel(SecondaryTooltip);
    end
end

--[[
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
--]]