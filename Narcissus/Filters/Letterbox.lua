local FadeFrame = NarciAPI_FadeFrame;

--------------------------------------
-----------Letterbox Filter-----------
--------------------------------------
function Narci_ScreenMask_Initialize()
    local frame = Narci_FullScreenMask;
	local scale = UIParent:GetEffectiveScale();
	local Width, Height = GetScreenWidth()*scale, GetScreenHeight()*scale;

    --Constant--
    local ratio = NarcissusDB.LetterboxRatio or 2.35;
	local croppedHeight = Width/ratio;	--2.35/2/1.8
	local speed = 50;
	------------
	
	local maskHeight = math.floor((Height - croppedHeight)/2 - 0.5);
	if maskHeight > 0 then
		frame.BottomMask:SetHeight(maskHeight);
		frame.TopMask:SetHeight(maskHeight);
	else
		frame.BottomMask:Hide();
		frame.TopMask:Hide();
		Narci_LetterboxButton:Disable();
		Narci_LetterboxButton:Hide();
		return false;
	end

	------------
	local offsetY = maskHeight + 1;
    local t = math.floor(10*(maskHeight / speed) + 0.5)/10;	--1.6
    
	frame.BottomMask.animIn.StartPosition:SetOffset(0, -offsetY);
	frame.BottomMask.animIn.Translation:SetOffset(0, offsetY);
	frame.BottomMask.animIn.Translation:SetDuration(t);
    frame.BottomMask.animOut.Translation:SetOffset(0, -offsetY);
    frame.BottomMask.animOut.Translation:SetDuration(0.5);
	frame.TopMask.animIn.StartPosition:SetOffset(0, offsetY);
	frame.TopMask.animIn.Translation:SetOffset(0, -offsetY);
	frame.TopMask.animIn.Translation:SetDuration(t);
    frame.TopMask.animOut.Translation:SetOffset(0, offsetY);
    frame.TopMask.animOut.Translation:SetDuration(0.5);
    ------------
    if ratio == 2.35 then
        Narci_LetterboxButton.Arrow:SetTexCoord(0, 0.25, 0.5, 1);
    else
        Narci_LetterboxButton.Arrow:SetTexCoord(0.25, 0.5, 0.5, 1);
	end
	
	return true;
end

local Narci_ScreenMask_Initialize = Narci_ScreenMask_Initialize;

function Narci_LetterboxButton_OnClick(self)
	local value
    if NarcissusDB.LetterboxRatio == 2.35 then
		value = 2;
    else
		value = 2.35;
    end
	--Narci_ScreenMask_Initialize();
	NarcissusDB.LetterboxRatio = value
	Narci_LetterboxRatioSlider:SetValue(value);
end


local initialize = CreateFrame("Frame")
initialize:RegisterEvent("VARIABLES_LOADED");
initialize:SetScript("OnEvent",function(self,event,...)
    Narci_ScreenMask_Initialize();
end)