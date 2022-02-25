local FILE_PATH = "Interface\\AddOns\\Narcissus\\ART\\Splash\\Mawmart\\";

local After = C_Timer.After
local pi = math.pi;
local sin = math.sin;
local L = Narci.L;

local isMinimapHooked, SetUpMainButton, CreateMailButton;

local COLORS = {
    Blue = {0, 113/255, 220/255},   -- 0.44,  0.86
    DarkBlue = {4/255, 30/255, 60/255},
    LightBlue = {91/255, 177/255, 1},
    Green = {62/255, 173/255, 91/255},
};

local function GetColor(key)
    return unpack(COLORS[key]);
end

local HEADER_HEIGHT = 32;
local FRAME_HEIGHT;
local MainFrame, BuyButton, BackdropOverlay;


local function outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end

local function Header_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    local logoX, labelX;
    if self.t > 0 then
        logoX = outSine(self.t, -256, 8, self.duration);
        labelX = outSine(self.t, 256, -56, self.duration);
        local h = outSine(self.t, FRAME_HEIGHT, HEADER_HEIGHT, self.duration);
        if self.t > self.duration then
            h = HEADER_HEIGHT;
            logoX = 8;
            labelX = -56;
            self:SetScript("OnUpdate", nil);
            MainFrame.Content.FadeIn:Play();
            MainFrame.Content:Show();
        end
        BackdropOverlay:SetHeight(h);
    else
        logoX = -256;
        labelX = 256;
    end
    self.Logo1:SetPoint("LEFT", self, "LEFT", logoX, 0);
    self.Label1:SetPoint("RIGHT", self, "RIGHT", labelX, 0);
end

local itemData = {
    {name = "Incense", thumbnail = "Incense1", price = 1120, rating = 1.5, itemName = "Wrynnfall - Brass Incense Stick Holder - Limited Edition - Designed by Dan", numPreview = 3, category="Home / Decor / Candles & Home Fragrance", },
    {name = "Lego", thumbnail = "Lego1", price = 69.99, rating = 5.0, itemName = "Mediocre Bad Guys: Reassembled Nathaniel Minifigure", numPreview = 3, category="Toys / Building Sets & Blocks / LETGO", },
    {name = "Mug", thumbnail = "Mug1", price = 59.99 , rating = 2.8, itemName = "Best Dad Ever - Ceramic Coffee Mug Sets - 11 oz - Father's Day Gifts", numPreview = 3, category="Party & Occasions / Party Supplies / Party Tableware"},
    {name = "Castle", thumbnail = "Castle1", price = 49.99, rating = 4.6, itemName = "The Moving Castle - Eredar Children\'s Sand Castle Building Kit", numPreview = 4, category="Toys / Outdoor Play / Sandboxes & Water Tables", },
    {name = "Jigsaw", thumbnail = "Jigsaw1",  price = 829, rating = 3.4, itemName = "House of Light Jigsaw 1000 Pieces", numPreview = 2, category="Toys / Games & Puzzles / Puzzles", },
};

local function ShowMinimapMailButton(mailID)
    local MapButton = MiniMapMailFrame;
    local senderName;
    if mailID == 1 then
        senderName = "The Mailer";
    else
        senderName = "Oribos Customs and Portal Protection";
    end
    if not isMinimapHooked then
        isMinimapHooked = true;
        MapButton:HookScript("OnEnter", function(f)
            GameTooltip:Hide();
            GameTooltip:SetOwner(f, "ANCHOR_BOTTOMLEFT");
            if GameTooltip:IsOwned(f) then
                local senders = { senderName, GetLatestThreeSenders() };
                local headerText = #senders >= 1 and HAVE_MAIL_FROM or HAVE_MAIL;
                FormatUnreadMailTooltip(GameTooltip, headerText, senders);
                GameTooltip:Show();
            end
        end);
    end
    MapButton:Show();
end

local function OtherItem_OnEnter(self)
    self.Underline.Expand:Play();
    self.Underline:Show();
end

local function OtherItem_OnLeave(self)
    self.Underline.Expand:Stop();
    self.Underline:Hide();
end

local function OtherItem_OnClick(self)
    MainFrame:DisplayItem(self.index);
end

local function SmallPreview_OnEnter(self)
    for i, button in pairs(self:GetParent().Previews) do
        button.Underline:Hide();
        button.Underline.Expand:Stop();
    end
    self.Underline.Expand:Play();
    self.Underline:Show();
    MainFrame.Content.MainPreview:SetTexture(FILE_PATH.. itemData[self.itemIndex].name .. self.order);
end

NarciItemShopMixin = {};

function NarciItemShopMixin:OnLoad()
    MainFrame = self;
    FRAME_HEIGHT = self:GetHeight();
    self.ShopLogoLeft:SetTexture(FILE_PATH.. "EntranceLogoLeft");
    self.ShopLogoRight:SetTexture(FILE_PATH.. "EntranceLogoRight");
    BackdropOverlay = self.BackdropOverlay;
    --self:PlayEntrance();

    --Set Delivery Time
    local futureDay = time() + 86400 * 3;
    local dateString = date("%a, %b %d", futureDay);
    self.Content.ETA:SetText(string.format("Arrives by %s", dateString));

    --Create OtherItems
    local OtherItemsFrame = self.Content.OtherItemsFrame;
    local NUM_BUTTONS = #itemData;
    local button;
    local buttonWidth, buttonOffset;
    for i = 1, NUM_BUTTONS do
        button = CreateFrame("Button", nil, OtherItemsFrame, "NarciItemShopOtherItemButtonTemplate");
        button:ClearAllPoints();
        button:SetScript("OnEnter", OtherItem_OnEnter);
        button:SetScript("OnLeave", OtherItem_OnLeave);
        button:SetScript("OnClick", OtherItem_OnClick);
        button.Underline:SetColorTexture( GetColor("Blue") );
        if i == 1 then
            buttonWidth = button:GetWidth();
            local w = OtherItemsFrame:GetWidth();
            buttonOffset = (w - NUM_BUTTONS * buttonWidth) / (NUM_BUTTONS - 1);
            button:SetPoint("BOTTOMLEFT", OtherItemsFrame, "BOTTOMLEFT", 0, 18);
        else
            button:SetPoint("BOTTOMLEFT", OtherItemsFrame.ItemButtons[i - 1], "BOTTOMRIGHT", buttonOffset, 0);
        end
        button.Thumbnail:SetTexture(FILE_PATH.. itemData[i].thumbnail, nil, nil, "TRILINEAR");
        button.Name:SetText(itemData[i].itemName);
        button.Price:SetText(string.format("$%.2f", itemData[i].price));
        button.index = i;
    end

    --Small Previews
    local PreviewFrame = self.Content.PreviewFrame;
    for i = 1, 4 do
        button = CreateFrame("Button", nil, PreviewFrame, "NarciItemShopSmallPreviewTemplate");
        button:ClearAllPoints();
        button:SetScript("OnEnter", SmallPreview_OnEnter);
        button.Underline:SetColorTexture( GetColor("Blue") );
        button.order = i;
        if i == 1 then
            button:SetPoint("TOPLEFT", PreviewFrame, "TOPLEFT", 0, 0);
        else
            button:SetPoint("TOP", PreviewFrame.Previews[i - 1], "BOTTOM", 0, -10);
        end
        button:Hide();
    end

    self:DisplayItem(1);
end

function NarciItemShopMixin:OnMouseDown()
    --self:PlayEntrance();
end

function NarciItemShopMixin:PlayEntrance()
    self.isPlayed = true;
    self.BackdropOverlay:SetHeight(FRAME_HEIGHT);
    self.BackdropOverlay:SetColorTexture( GetColor("Blue") );
    self.ShopLogoLeft:ClearAllPoints();
    self.ShopLogoLeft:SetPoint("CENTER", self, "CENTER", 0, 0);
    self.ShopLogoRight:ClearAllPoints();
    self.ShopLogoRight:SetPoint("CENTER", self, "CENTER", 0, 0);
    self:StopAnimating();
    self.Header:Hide();
    self.Header:SetScript("OnUpdate", nil);
    self.Content:Hide();
    self.Content:SetAlpha(0);
    self.Backdrop:Hide();
    self.animationIndex = 0;
    self:PlayNextAnimation();
end

function NarciItemShopMixin:PlayNextAnimation()
    local index = self.animationIndex + 1;
    self.animationIndex = index;
    if index == 1 then
        self.SponsoredBy.FadeIn:Play();
    elseif index == 2 then
        self.SponsoredBy.FadeOut:Play();
        self.ShopLogoLeft.FlyUp:Play();
    elseif index == 3 then
        self.ShopLogoLeft.FlyDown:Play();
        self.Slogan.Fade:Play();
        After(0.02, function()
            self.BackdropOverlay:SetColorTexture( GetColor("DarkBlue") );
            self.Header:SetScript("OnUpdate", Header_OnUpdate);
            self.Header:Show();
        end);
        self.Backdrop:Show();
        self.Header.t = -3.5;
        self.Header.duration = 1.5;
        self.ShopLogoRight.FlyIn:Play();
    end
end

function NarciItemShopMixin:SetRating(rating)
    local f = self.Content.RatingFrame;
    local ratingCap = 5;
    if rating > ratingCap then
        rating = ratingCap;
    end
    if not f.stars then
        f.stars = {};
        local star;
        for i = 1, ratingCap do
            star = f:CreateTexture(nil, "OVERLAY");
            star:SetSize(12, 12);
            star:SetPoint("LEFT", f, "LEFT", (i - 1) * 12, 0);
            star:SetTexture(FILE_PATH.."RatingStar");
            f.stars[i] = star;
        end
    end
    local numStars = math.ceil(rating);
    local star;
    for i = 1, numStars do
        star = f.stars[i];
        if i == numStars then
            if rating == numStars then
                star:SetTexCoord(0, 0.25, 0, 1);
            else
                --half
                star:SetTexCoord(0.25, 0.5, 0, 1);
            end
        else
            --full
            star:SetTexCoord(0, 0.25, 0, 1);
        end
    end
    for i = numStars + 1, ratingCap do
        star = f.stars[i];
        --hollow
        star:SetTexCoord(0.5, 0.75, 0, 1);
    end

    f.Number:SetText(string.format("(%.1f)", rating));
end

function NarciItemShopMixin:DisplayItem(index)
    local data = itemData[index];
    if not data then return end;
    
    if index ~= self.displayedItem then
        self.displayedItem = index;
    else
        return
    end

    --self.Content.MainPreview:SetTexture(FILE_PATH.. data.name.."1");
    self.Content.ItemHeader:SetText(data.itemName);
    self.Content.Price:SetText(string.format("$oul %.2f", data.price));
    self.Content.ItemCategory:SetText(data.category);
    self:SetRating(data.rating);
    BuyButton.index = index;
    BuyButton:SetState(data.isPurchased);

    local numPreview = data.numPreview;
    local Previews = self.Content.PreviewFrame.Previews;
    for i = 1, numPreview do
        Previews[i].Thumbnail:SetTexture(FILE_PATH.. data.name .. i, nil, nil, "TRILINEAR");
        Previews[i].itemIndex = index;
        Previews[i]:Show();
    end
    for i = numPreview + 1, #Previews do
        Previews[i]:Hide();
    end
    SmallPreview_OnEnter(Previews[1]);
end

function NarciItemShopMixin:OnHide()
    if self.hasBought then
        self.hasBought = nil;
        NarcissusDB.ShowOrderConfirmation = true;
        CreateMailButton(1);
        ShowMinimapMailButton(1);
        ShowMinimapMailButton(1);
        SetUpMainButton("The Mailer", "Your Order Has Been Verified", 365, 133473);
    end
end

NarciItemShopBuyButtonMixin = {};

function NarciItemShopBuyButtonMixin:OnLoad()
    BuyButton = self;
end

function NarciItemShopBuyButtonMixin:OnEnter()
    self.Background:SetColorTexture( GetColor("LightBlue") );
end

function NarciItemShopBuyButtonMixin:OnLeave()
    self.Background:SetColorTexture( GetColor("Blue") );
end

function NarciItemShopBuyButtonMixin:OnClick()
    self:SetState(true);
    self.Shake:Play();
    itemData[self.index].isPurchased = true;
    NarcissusDB.UserIsCurious = true;
    NarcissusDB.DeliveryArrival = time() + 86400 * 3;
    MainFrame.hasBought = true;
end

function NarciItemShopBuyButtonMixin:SetState(isPurchased)
    if isPurchased then
        self:Disable();
        self.Background:SetColorTexture( GetColor("Green") );
        self.ButtonText:SetText("Purchased");
    else
        self:Enable();
        self.Background:SetColorTexture( GetColor("Blue") );
        self.ButtonText:SetText("Buy Now");
    end
    self.Shake:Stop();
end





--Mail
local presets = {};

local MailButton;

--MailButton.Button.Icon:SetTexture(133473);

local function SetOpenMain(contentIndex)
    OpenMailInvoiceFrame:Hide();
    OpenMailScrollFrame:Show();

    local data = presets[contentIndex];
    OpenMailSender.Name:SetText(data[1]);
    OpenMailSubject:SetText(data[2]);

    --Text
    local playerName = UnitName("player");
    OpenMailBodyText:SetText( string.format(data[3], playerName) , true);
    OpenStationeryBackgroundLeft:SetTexture(136859);
    OpenStationeryBackgroundRight:SetTexture(136860);
    --Attachment
    local attachmentText = OpenMailAttachmentText;
    if attachmentText then
        local marginxl = 10 + 4;
        local marginxr = 43 + 4;
        local areax = OpenMailFrame:GetWidth() - marginxl - marginxr;
        local gapy1 = 3;
        local gapy2 = 3;
        local indenty = 28 + gapy2;
        local iconx, icony = MailButton.Button:GetSize();
        iconx, icony = iconx + 2, icony + 2;
        local itemRowCount = 0;
        local areay = gapy2 + attachmentText:GetHeight() + gapy2 + (icony * itemRowCount) + (gapy1 * (itemRowCount - 1)) + gapy2;
        local scrollHeight = 305 - areay;
        if (scrollHeight > 256) then
            scrollHeight = 256;
            areay = 305 - scrollHeight;
        end
        attachmentText:SetText(NO_ATTACHMENTS);
        attachmentText:SetTextColor(0.5, 0.5, 0.5);
        local height = attachmentText:GetHeight();
        attachmentText:SetPoint("TOPLEFT", OpenMailFrame, "BOTTOMLEFT", marginxl + (areax - attachmentText:GetWidth()) / 2, indenty + (areay - height) / 2 + height);

        -- Resize the scroll frame
        local min = math.min;
        OpenMailScrollFrame:SetHeight(scrollHeight);
        OpenMailScrollChildFrame:SetHeight(scrollHeight);
        OpenMailHorizontalBarLeft:SetPoint("TOPLEFT", "OpenMailFrame", "BOTTOMLEFT", 2, 39 + areay);
        OpenScrollBarBackgroundTop:SetHeight(min(scrollHeight, 256));
        OpenScrollBarBackgroundTop:SetTexCoord(0, 0.484375, 0, min(scrollHeight, 256) / 256);
        OpenStationeryBackgroundLeft:SetHeight(scrollHeight);
        OpenStationeryBackgroundLeft:SetTexCoord(0, 1.0, 0, min(scrollHeight, 256) / 256);
        OpenStationeryBackgroundRight:SetHeight(scrollHeight);
        OpenStationeryBackgroundRight:SetTexCoord(0, 1.0, 0, min(scrollHeight, 256) / 256);

        -- Disable Button
        OpenMailReplyButton:Disable();
        OpenMailDeleteButton:SetText(MAIL_RETURN);
		OpenMailReportSpamButton:Hide();
		OpenMailSender:SetPoint("BOTTOMRIGHT", OpenMailFrame, "TOPRIGHT" , -12, -54);
    end
    --Hide Attachment Button
    for key, itemButton in pairs(OpenMailFrame.OpenMailAttachments) do
        itemButton:Hide();
    end

    if not GetLatestThreeSenders() then
        MiniMapMailFrame:Hide();
    end

    NarcissusDB.ShowOrderConfirmation = nil;
end

function CreateMailButton(mailID)
    if not MailButton then
        MailButton = CreateFrame("Frame", nil, InboxFrame, "NarciMailItemTemplate");
        MailButton:Hide();
        local anchorTo = MailItem1;
        MailButton:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", 0, 0);
        MailButton:SetPoint("BOTTOMRIGHT", anchorTo, "BOTTOMRIGHT", 0, 0);
        MailButton:SetFrameStrata("HIGH");
        MailButton.mailID = mailID;


        local function MailButton_OnClick(self)
            if ( self:GetChecked() ) then
                --ShowUIPanel(OpenMailFrame);
                OpenMailFrame:Show();
                OpenMailFrameInset:SetPoint("TOPLEFT", 4, -80);
                PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN);
                InboxFrame.openMailID = nil;
                if MailButton.mailID == 1 then
                    SetOpenMain("confirm");
                else
                    SetOpenMain("confiscate");
                end
            end
            MailButton:Hide();
            NarcissusDB.ShowOrderConfirmation = nil;
        end
        
        local function MailButton_OnShow(self)
            anchorTo:SetAlpha(0);
        end
        
        local function MailButton_OnHide(self)
            MailButton:Hide();
            anchorTo:SetAlpha(1);
            if not GetLatestThreeSenders() then
                MiniMapMailFrame:Hide();
            end
        end
        
        MailButton.Button:SetScript("OnClick", MailButton_OnClick);
        MailButton.Button:SetScript("OnShow", MailButton_OnShow);
        MailButton.Button:SetScript("OnHide", MailButton_OnHide);
    end
end


function SetUpMainButton(sender, subject, daysLeft, icon)
    MailButton.Sender:SetText(sender);
    MailButton.Subject:SetText(subject);
    daysLeft = "|cff20ff20"..string.format(DAYS_ABBR, math.floor(daysLeft)).." |r";  --GREEN_FONT_COLOR_CODE
    MailButton.ExpireTime:SetText(daysLeft);
    MailButton.Button.Icon:SetTexture(icon);
    MailButton:Show();
end

presets = {
    confirm = {"The Mailer", "Your Mawmart Order Has Been Verified", "%s,\n\nThank you for your purchase. The master is pleased. For every Soul Coin you spend, a blade is forged, honed and ready to cut into the hearts of the non-believers.\n\nKind regards,\nThe Mailer"};
    confiscate = {"Oribos Customs and Portal Protection", "We Have Seized Your Package", "Greetings Maw Walker,\n\nWe just confiscated a package sent from the Maw, and the items inside seemed to be purchased under your name. We have started an investigation to find the perpetrator because we are sure that a hero like you won't do anything to jeopardize the Purpose?"};
};


local MailLoader = CreateFrame("Frame");
MailLoader:RegisterEvent("PLAYER_ENTERING_WORLD");
MailLoader:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent(event);
    local language = GetLocale();
    if language ~= "enUS" then
        return
    end
    if NarcissusDB.ShowOrderConfirmation then
        C_Timer.After(2, function()
            CreateMailButton(1);
            ShowMinimapMailButton(1);
            SetUpMainButton("The Mailer", "Your Order Has Been Verified", 365, 133473);
        end)
    end
    if NarcissusDB.DeliveryArrival then
        local now = time();
        if now > NarcissusDB.DeliveryArrival then
            NarcissusDB.DeliveryArrival = nil;
            C_Timer.After(2.5, function()
                CreateMailButton(2);
                ShowMinimapMailButton(2);
                SetUpMainButton("Oribos Customs and Portal Protection", "We Have Seized Your Package", 365, 354719);
            end)
        end
    end
end)