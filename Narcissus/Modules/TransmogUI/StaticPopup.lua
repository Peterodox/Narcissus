local _, addon = ...
local TransmogUIManager = addon.TransmogUIManager;


local PopupModule = TransmogUIManager:CreateModule("StaticPopup");
PopupModule.Defs = {};

--StaticPopupDialogs

PopupModule.Defs["NARCISSUS_TRANSMOG_CUSTOM_SET_NAME"] = {
	text = TRANSMOG_CUSTOM_SET_NAME,
	button1 = SAVE,
	button2 = CANCEL,
	OnAccept = function(dialog, data)
		if data then
            local name = dialog:GetEditBox():GetText();
            TransmogUIManager:TryRenameSharedSet(data.dataIndex, name);
        end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	hasEditBox = 1,
	maxLetters = 31,
	OnShow = function(dialog, data)
		dialog:GetButton1():Disable();
		dialog:GetButton2():Enable();
		dialog:GetEditBox():SetFocus();

		if data then
			dialog:GetEditBox():SetText(data.name);
		end
	end,
	OnHide = function(dialog, data)
		dialog:GetEditBox():SetText("");
	end,
	EditBoxOnEnterPressed = function(editBox, data)
		if editBox:GetParent():GetButton1():IsEnabled() then
			StaticPopup_OnClick(editBox:GetParent(), 1);
		end
	end,
	EditBoxOnTextChanged = function(editBox, data)
		local dialog = editBox:GetParent();
		local button1 = dialog:GetButton1();

		local enabled = UserEditBoxNonEmpty(editBox);
		if data then
			enabled = editBox:GetText() ~= data.name;
		end
		button1:SetEnabled(enabled);
	end,
	EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
};

PopupModule.Defs["NARCISSUS_TRANSMOG_CUSTOM_SET_DELETE"] = {
	text = "",
	button1 = YES,
	button2 = NO,
	OnShow = function(dialog, data)
		dialog:SetFormattedText(TRANSMOG_CUSTOM_SET_CONFIRM_DELETE, data.name);
	end,
	OnAccept = function(dialog, data)
		TransmogUIManager:DeleteSharedSet(data.dataIndex);
	end,
	OnCancel = function(dialog, data) end,
	hideOnEscape = 1,
	timeout = 0,
	whileDead = 1,
};


local StaticPopupMixin = {};
do  --StaticPopupMixin, Save Custom Set
    function StaticPopupMixin:SetupCustomSet_Rename(defaultText)
        local header = self.fontStringPool:Acquire();
        header:SetTextColor(1, 1, 1);
        header:SetText(TRANSMOG_CUSTOM_SET_NAME);
        self:AddLayoutObject(header);

        self.EditBox:SetDefaultText(defaultText);
        self:AddLayoutObject(self.EditBox);
    end

    function StaticPopupMixin:SetupCustomSet_NewSet(fromSharedSet, transmogInfoList)
		local L = Narci.L;

        StaticPopupMixin.SetupCustomSet_Rename(self, nil);

        local header = self.fontStringPool:Acquire();
        header:SetTextColor(1, 1, 1);
        header:SetText(L["Save Custom Set Location"]);
        self:AddLayoutObject(header, self.Def.LargeGapY);

        local checkbox1 = self.checkboxPool:Acquire();
        checkbox1:SetLabel(L["OutfitSource Default"]);
		checkbox1:SetChecked(not fromSharedSet);
        self:AddLayoutObject(checkbox1);

        local checkbox2 = self.checkboxPool:Acquire();
        checkbox2:SetLabel(L["OutfitSource Shared"]);
		checkbox2:SetChecked(fromSharedSet);
        self:AddLayoutObject(checkbox2);

        self.Button1:Show();
        self.Button1:SetText(SAVE);
        self.Button2:Show();
        self.Button2:SetText(CANCEL);

        self.Button2:SetScript("OnClick", function()
            self:Hide();
        end);

		local function SaveButton_OnClick()
			local name = self.EditBox:GetValidText();
			if not name then return end;

			local refreshSharedSets;

			if checkbox2:GetChecked() and TransmogUIManager:CanSaveMoreSharedSet() then
				if TransmogUIManager:TrySaveSharedSet(name, transmogInfoList) then
					refreshSharedSets = true;
				end
			end

			if checkbox1:GetChecked() and TransmogUIManager:CanSaveMoreCustomSet() and C_TransmogCollection.IsValidCustomSetName(name) then
				refreshSharedSets = false;
				TransmogUIManager:SetRecentlySavedCustomSetFlag(name);
				WardrobeCustomSetManager:SetItemTransmogInfoList(transmogInfoList);
				WardrobeCustomSetManager:NameCustomSet(name);
			end

			self:Hide();

			if refreshSharedSets then
				addon.CallbackRegistry:Trigger("TransmogUI.ReloadSharedSets");
			end
		end

        self.Button1:SetScript("OnClick", SaveButton_OnClick);

		local function UpdateSaveButton(updateCheckbox)
			if updateCheckbox then
				if TransmogUIManager:CanSaveMoreCustomSet() then
					checkbox1:Enable();
				else
					checkbox1:Disable();
					checkbox1:SetChecked(false);
				end

				if TransmogUIManager:CanSaveMoreSharedSet() then
					checkbox2:Enable();
				else
					checkbox2:Disable();
					checkbox2:SetChecked(false);
				end
			end

			local valid;

			if checkbox1:GetChecked() then
				valid = true;
			end

			if checkbox2:GetChecked() then
				valid = true;
			end


			local name = self.EditBox:GetValidText();
			if (not name) or not C_TransmogCollection.IsValidCustomSetName(name) then
				valid = false;
			end

			if valid then
				self.Button1:Enable();
			else
				self.Button1:Disable();
			end
		end

		self.EditBox.onTextChangedFunc = function(_, userInput)
			UpdateSaveButton();
		end

		self.EditBox.onEnterPressedFunc = function()
			if self.Button1:IsEnabled() then
				SaveButton_OnClick();
			end
		end

		checkbox1.onClickFunc = function(_, button)
			UpdateSaveButton(true);
		end

		checkbox2.onClickFunc = function(_, button)
			UpdateSaveButton(true);
		end


		local function AddSetCount(tooltip, current, max)
			tooltip:AddLine(" ");
			local lineText = string.format("|cffffd100%s|r%d/%d", L["Save Slots Colon"], current, max);
			if current >= max then
				tooltip:AddLine(lineText, 1, 0.125, 0.125, false);
			else
				tooltip:AddLine(lineText, 1, 1, 1, false);
			end
		end

		checkbox1.onEnterFunc = function(self)
			local tooltip = GameTooltip;
			tooltip:SetOwner(self, "ANCHOR_RIGHT");
			tooltip:SetText(L["OutfitSource Default"], 1, 1, 1, 1, true);
			tooltip:AddLine(L["OutfitSource Default Tooltip"], 1, 0.82, 0, true);
			local current, max = TransmogUIManager:GetDefaultCustomSetsCount();
			AddSetCount(tooltip, current, max);
			tooltip:Show();
		end;

		checkbox2.onEnterFunc = function(self)
			local tooltip = GameTooltip;
			tooltip:SetOwner(self, "ANCHOR_RIGHT");
			tooltip:SetText(L["OutfitSource Shared"], 1, 1, 1, 1, true);
			tooltip:AddLine(L["OutfitSource Shared Tooltip"], 1, 0.82, 0, true);
			local current = TransmogUIManager:GetNumSharedSets();
			local max = TransmogUIManager:GetNumMaxSharedSets();
			AddSetCount(tooltip, current, max);
			tooltip:Show();
		end;

		UpdateSaveButton(true);
    end
end


function TransmogUIManager:ShowPopup_NewSet(fromSharedSet, transmogInfoList)
	local popup = addon.GetStaticPopup();

	StaticPopupMixin.SetupCustomSet_NewSet(popup, fromSharedSet, transmogInfoList);
	popup:TryShow();
end


function PopupModule:OnLoad()
    for k, v in pairs(self.Defs) do
        StaticPopupDialogs[k] = v;
    end
end