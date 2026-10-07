local _, addon = ...
local UpdateFunc = addon.StatUpdateFunc; ---@type StatUpdateFunc
local UIColorThemeUtil = addon.UIColorThemeUtil;


local StatButtonMixin = {};
addon.StatButtonMixin = StatButtonMixin;

function StatButtonMixin:Update()
    self:UpdateStat();

	if self.customValueSetter then
		self.customValueSetter(self, self.Value, self.ValueRating);
	end
end

function StatButtonMixin:UpdateStat()
	-- override
end

function StatButtonMixin:SetLabelAndValue(label, value, grey)
	self.Label:SetText(label);
	self.Value:SetText(value);
	if grey then
		self.Label:SetTextColor(0.5, 0.5, 0.5);
		self.Value:SetTextColor(0.5, 0.5, 0.5);
	else
		self.Label:SetTextColor(0.92, 0.92, 0.92);
		self.Value:SetTextColor(0.92, 0.92, 0.92);
	end
end

function StatButtonMixin:SetValueRating(valueRating)
	if self.ValueRating then
		self.ValueRating:SetText(valueRating);
	end
end

function StatButtonMixin:UpdateColor()
	local row = self.row or 0;
	local r, g, b = UIColorThemeUtil:GetActiveColor();
	if row % 2 == 0 then
		if self.Color then
			self.Color:SetColorTexture(r, g, b, 0.75);
			return;
		elseif self.Color1 and self.Color2 then
			self.Color1:SetColorTexture(r, g, b, 0.75);
			self.Color2:SetColorTexture(r, g, b, 0.75);
		end
	else
		if self.Color then
			self.Color:SetColorTexture(0.1, 0.1, 0.1, 0.75);
			return;
		elseif self.Color1 and self.Color2 then
			self.Color1:SetColorTexture(0.1, 0.1, 0.1, 0.75);
			self.Color2:SetColorTexture(0.1, 0.1, 0.1, 0.75);
		end
	end
end

local LeftColumnGradient = {
	MinColor = CreateColor(1, 1, 1, 1),
	MaxColor = CreateColor(0.6, 0.6, 0.6, 1),
};

local RightColumnGradient = {
	MinColor = CreateColor(0.45, 0.45, 0.45, 1),
	MaxColor = CreateColor(0.85, 0.85, 0.85, 1),
};

function StatButtonMixin:SetLeftColumn(isLeftCol)
	local tbl;
	if isLeftCol then
		tbl = LeftColumnGradient;
	else
		tbl = RightColumnGradient;
	end
	self.Color:SetGradient("HORIZONTAL", tbl.MinColor, tbl.MaxColor);
end

function StatButtonMixin:SetRow(row)
	self.row = row;
	self:UpdateColor();
	self.animIn.A2:SetStartDelay(row / 20);
end

function StatButtonMixin:GetRow()
	return self.row or 0;
end

function StatButtonMixin:SetToken(token)
	if UpdateFunc[token] then
		self.token = token;
		self.UpdateStat = UpdateFunc[token];
	end
end

function StatButtonMixin:OnLoad()
	if self.isLeftCol ~= nil then
		self:SetLeftColumn(self.isLeftCol);
	end

	if self.token then
		self:SetToken(self.token);
	end
end

function StatButtonMixin:OnShow()
	self:UpdateColor();
end

function StatButtonMixin:OnEnter()
	self:ShowTooltip();
end

function StatButtonMixin:ShowTooltip()
	Narci_ShowStatTooltip(self);
end

function StatButtonMixin:OnLeave()
	Narci:HideButtonTooltip();
end
