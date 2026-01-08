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

function PopupModule:OnLoad()
    for k, v in pairs(self.Defs) do
        StaticPopupDialogs[k] = v;
    end
end