local _, addon = ...


local Def = {
    HideUncollectedSlot = false,    --Does not save between sessions in case player forgot it
    ModelViewTranslationY = 14,     --Move the model upwards to compensate for the checkbox below
};


local EL = CreateFrame("Frame");

function EL:RequestUpdate()
    self.t = 0;
    self:SetScript("OnUpdate", self.OnUpdate);
end

function EL:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0.016 then
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        self:UpdateSlotVisibility();
    end
end

function EL:UpdateSlotVisibility(userInput)
    if not Def.enabled then return end;

    local allCollected;
    local setInfo = self.setID and C_TransmogSets.GetSetInfo(self.setID);
    if setInfo and setInfo.collected then
        allCollected = true;
    end

    self.Checkbox:SetShown(not allCollected);


    if (not Def.HideUncollectedSlot) and not userInput then return end;

    local f = WardrobeCollectionFrame.SetsCollectionFrame;
    local sources;

    if Def.HideUncollectedSlot then
        for itemFrame in f.DetailsFrame.itemFramesPool:EnumerateActive() do
            if itemFrame.collected then
                if not sources then
                    sources = {};
                end
                table.insert(sources, itemFrame.sourceID);
            else
                allCollected = false;
            end
        end
    else
        for itemFrame in f.DetailsFrame.itemFramesPool:EnumerateActive() do
            if not sources then
                sources = {};
            end
            table.insert(sources, itemFrame.sourceID);
            if  not itemFrame.collected then
                allCollected = false;
            end
        end
    end

    f.Model:Undress();

    if sources then
        for _, sourceID in ipairs(sources) do
            f.Model:TryOn(sourceID);
        end
    end
end


local function OnDisplaySet(self, setID)
    EL.setID = setID;
    EL:RequestUpdate();
end


local function InitModule()
    if Def.loaded then return end;
    Def.loaded = true;

    local f = WardrobeCollectionFrame.SetsCollectionFrame;

    hooksecurefunc(f, "DisplaySet", OnDisplaySet);
    f.Model:SetViewTranslation(0, Def.ModelViewTranslationY);

    --Create Checkbox
    local Checkbox = CreateFrame("CheckButton", nil, f, "NarciWoWCheckboxWithLabelTemplate");
    EL.Checkbox = Checkbox;
    Checkbox:SetPoint("BOTTOM", f.RightInset, "BOTTOM", 0, 4);
    Checkbox:SetLabel(Narci.L["Hide Uncollected Slots"]);
    Checkbox:SetIconSize(20);
    Checkbox:ResizeToFit();
    Checkbox:SetFrameLevel(128);
    Checkbox:SetChecked(Def.HideUncollectedSlot);


    Checkbox.onClickFunc = function(self, button)
        if button == "LeftButton" then
            Def.HideUncollectedSlot = self:GetChecked();
            EL:UpdateSlotVisibility(true);
        end
    end

    Checkbox.onEnterFunc = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(Narci.L["Hide Uncollected Slots Tooltip"]:format(string.upper(NARCI_MODIFIER_ALT)), 1, 1, 1);
        GameTooltip:Show();
    end

    Checkbox:SetScript("OnShow", function(self)
        self:SetChecked(Def.HideUncollectedSlot);
        self:RegisterEvent("MODIFIER_STATE_CHANGED");
    end);

    Checkbox:SetScript("OnHide", function(self)
        self:UnregisterEvent("MODIFIER_STATE_CHANGED");
    end);

    Checkbox:SetScript("OnEvent", function(self, event, ...)
        local key, down = ...
        if down == 0 and (key == "LALT" or key == "RALT") and WardrobeCollectionFrame:IsMouseOver() then
            --Use key release as Click to avoid being triggered by Alt + Tab
            self:SetChecked(not Def.HideUncollectedSlot);
            self.onClickFunc(self, "LeftButton");
        end
    end);
end

local function EnableModule(state)
    local name = "Blizzard_Collections";

    if state and not Def.enabled then
        Def.enabled = true;

        if C_AddOns.IsAddOnLoaded(name) then
            InitModule();
        else
            if not Def.registered then
                Def.registered = true;
                EventUtil.ContinueOnAddOnLoaded(name, InitModule);
            end
        end

        if EL.Checkbox then
            EL.Checkbox:Show();
        end

        if WardrobeCollectionFrame then
            WardrobeCollectionFrame.SetsCollectionFrame.Model:SetViewTranslation(0, Def.ModelViewTranslationY);
        end

    elseif (not state) and Def.enabled then
        Def.enabled = nil;

        if EL.Checkbox then
            EL.Checkbox:Hide();
        end

        if WardrobeCollectionFrame then
            WardrobeCollectionFrame.SetsCollectionFrame.Model:SetViewTranslation(0, 0);
        end
    end
end

addon.SettingFunctions.WardrobeCollectionSetsCheckbox = function(state, db)
    if state == nil then
        state = db["WardrobeCollectionSetsCheckbox"];
    end
    EnableModule(state);
end
