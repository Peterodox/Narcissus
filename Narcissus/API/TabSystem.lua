local _, addon = ...


---@class TabSystem : frame
---@field tabButtons table
---@field tabButtonSetup table Store tabButton layout info like alignment and spacing
---@field tabFrameSetup table Store tabFrame layout info like insets
---@field tabData table
---@field tabKeyXTabData table
---@field selectedTabKey number?
---@field isTabButtonTooWide boolean?
---@field lastTabButton button?
local TabSystemMixin = {};

---The container (frame) will be the tab button's parent and relativeTo 
function TabSystemMixin:SetTabButtonContainer(frame)
    self.tabButtonSetup.container = frame;
end

---@param tabButtonTemplate string tabButton needs to have these method(s): `SetSelected`, `SetText`, `SetButtonWidth`
function TabSystemMixin:SetTabButtonTemplate(tabButtonTemplate)
    self.tabButtonSetup.template = tabButtonTemplate;
end

---@param align "horizontal" | "vertical"
function TabSystemMixin:SetTabButtonAlignment(align)
    self.tabButtonSetup.isHorizontal = align == "horizontal";
    self.isTabDirty = true;
end

function TabSystemMixin:SetTabButtonSpacing(spacing)
    self.tabButtonSetup.spacing = spacing;
    self.isTabDirty = true;
end

---Change the first tab button's position.
---@param point "TOPLEFT" | "BOTTOMLEFT"
---@param relativePoint "TOPLEFT" | "BOTTOMLEFT"
---@param x number?
---@param y number?
function TabSystemMixin:SetFirstTabButtonPosition(point, relativePoint, x, y)
    self.tabButtonSetup.point = point;
    self.tabButtonSetup.relativePoint = relativePoint;
    self.tabButtonSetup.x = x or 0;
    self.tabButtonSetup.y = y or 0;
    self.isTabDirty = true;
end

---Place the last button to the mirrored position of the first button
function TabSystemMixin:OppositeAlignLastButton(oppositeLastButton)
    self.tabButtonSetup.oppositeLastButton = oppositeLastButton;
    self.isTabDirty = true;
end

---Called after changing tab button text or position
function TabSystemMixin:LayoutTabButtons()
    if not self.tabButtons then return; end

    local setup = self.tabButtonSetup;
    local numActive = 0;
    local isHorizontal = setup.isHorizontal;
    local spacing = setup.spacing or 0;
    local tabButtonWidth;

    self.isTabButtonTooWide = nil;
    self.lastTabButton = nil;

    for _, button in ipairs(self.tabButtons) do
        if button:IsShown() then
            numActive = numActive + 1;
        end
    end

    -- Limit the max text width for each button in case the text is too long to fit all labels
    if numActive > 1 then
        if isHorizontal then
            local containerWidth = setup.container:GetWidth() - 2 * setup.x;
            if self.totalButtonWidth > containerWidth then
                -- There are better methods to show more text without truncating but
                -- for simplicity, we use the average width.
                tabButtonWidth = math.floor(containerWidth / numActive);
                self.isTabButtonTooWide = true;
            end
        else
            tabButtonWidth = self.totalButtonWidth; -- for vertical tab, this is the max button width
        end
    end

    for i, button in ipairs(self.tabButtons) do
        if i > numActive then
            break;
        else
            button:ClearAllPoints();
        end

        if i == 1 then
            button:SetPoint(setup.point, setup.container, setup.relativePoint, setup.x, setup.y);
        elseif i == numActive and setup.oppositeLastButton then
            if isHorizontal then
                button:SetPoint("BOTTOM", self.tabButtons[1], "BOTTOM", 0, 0);
                button:SetPoint("RIGHT", setup.container, "RIGHT", -setup.x, 0);
            else
                button:SetPoint("LEFT", self.tabButtons[1], "LEFT", 0, 0);
                button:SetPoint("BOTTOM", setup.container, "BOTTOM", 0, setup.y);
            end
        else
            if isHorizontal then
                button:SetPoint("LEFT", self.tabButtons[i - 1], "RIGHT", spacing, 0);
            else
                button:SetPoint("TOP", self.tabButtons[i - 1], "BOTTOM", 0, -spacing);
            end
        end

        if tabButtonWidth then
            button:SetButtonWidth(tabButtonWidth);
        end

        if i == numActive then
            self.lastTabButton = button;
        end
    end
end

function TabSystemMixin:IsTabButtonTooWide()
    return self.isTabButtonTooWide;
end

function TabSystemMixin:SetTabFrameContainer(frame)
    self.tabFrameSetup.container = frame;
end

function TabSystemMixin:SetTabFrameInsets(left, right, top, bottom)
    self.tabFrameSetup.insets = {left or 0, right or 0, top or 0, bottom or 0};
end

function TabSystemMixin:InitTabFramePosition(tabFrame)
    local container = self.tabFrameSetup.container or self;
    local left, right, top, bottom = 0, 0, 0, 0;
    if self.tabFrameSetup.insets then
        left, right, top, bottom = unpack(self.tabFrameSetup.insets);
    end
    tabFrame:SetParent(container);
    tabFrame:ClearAllPoints();
    tabFrame:SetPoint("TOPLEFT", container, "TOPLEFT", left, -top);
    tabFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -right, bottom);
end

---Add a tab. The tabFrame can be created on use.
---@param tabKey string [tabKey] -> tabFrame. tabKey must be unique
---@param tabName string Shown on tab button
---@param tabFrameOrTemplate frame|string? If nil or a template, we will create a frame then call initFunc(frame)
---@param initFunc function? Called when the tabFrame is shown for the first time
---@return boolean success
function TabSystemMixin:AddTab(tabKey, tabName, tabFrameOrTemplate, initFunc)
    if (not tabKey) or (self.tabKeyXTabData[tabKey]) then
        return false;
    end

    local data = {
        tabKey = tabKey,
        tabName = tabName,
        initFunc = initFunc,
        enabled = true,
    };

    if tabFrameOrTemplate then
        if type(tabFrameOrTemplate) == "string" then
            data.tabFrameTemplate = tabFrameOrTemplate;
        else
            data.tabFrame = tabFrameOrTemplate;
            data.positionDirty = true;
        end
    end

    table.insert(self.tabData, data);
    data.order = #self.tabData;
    self.tabKeyXTabData[tabKey] = data;

    return true;
end

function TabSystemMixin:SetTabEnabled(tabKey, enabled, forceUpdate)
    if self.tabKeyXTabData[tabKey] then
        self.isTabDirty = true;
        self.tabKeyXTabData[tabKey].enabled = enabled;
        if forceUpdate then
            self:Init();
        end
    end
end

---@param tabKey string
function TabSystemMixin:EnableTab(tabKey, forceUpdate)
    self:SetTabEnabled(tabKey, true, forceUpdate);
end

---@param tabKey string
function TabSystemMixin:DisableTab(tabKey, forceUpdate)
    self:SetTabEnabled(tabKey, false, forceUpdate);
end

---@return boolean success True if the tab is selected successfully
function TabSystemMixin:SelectTabByKey(tabKey)
    if not tabKey then return false; end

    for _, button in ipairs(self.tabButtons) do
        button:SetSelected(button.tabKey == tabKey);
    end

    if tabKey == self.selectedTabKey then return true; end
    self.selectedTabKey = tabKey;

    for _, data in ipairs(self.tabData) do
        if data.tabFrame then
            data.tabFrame:Hide();
        end
    end

    local data = self.tabKeyXTabData[tabKey];

    if not data then return false; end

    if not data.tabFrame then
        local frame = CreateFrame("Frame", nil, self, data.tabFrameTemplate);
        data.tabFrame = frame;
        self:InitTabFramePosition(data.tabFrame);
    end

    if data.positionDirty then
        data.positionDirty = nil;
        self:InitTabFramePosition(data.tabFrame);
    end

    if data.initFunc then
        local initFunc = data.initFunc;
        data.initFunc = nil;
        initFunc(data.tabFrame);
    end

    data.tabFrame:Show();

    return true;
end

function TabSystemMixin:SelectTabByIndex(tabIndex)
    local tabKey;
    for _, data in ipairs(self.tabData) do
        if data.tabIndex == tabIndex then
            tabKey = data.tabKey;
            break;
        end
    end
    self:SelectTabByKey(tabKey);
end

function TabSystemMixin:SetDefaultTabKey(defaultTabKey)
    self.defaultTabKey = defaultTabKey;
end

---Call this to initialize the tabButtons and frames
function TabSystemMixin:Init()
    -- isTabDirty = true after enabling/disabling a tab or when the main frame hasn't been initialized

    if not self.isTabDirty then return; end
    self.isTabDirty = nil;

    for _, button in ipairs(self.tabButtons) do
        button:Hide();
        button.tabKey = nil;
    end

    for _, data in ipairs(self.tabData) do
        data.tabIndex = nil;
    end

    local n = 0;
    local firstValidTabKey;
    local totalButtonWidth = 0;
    local isHorizontal = self.tabButtonSetup.isHorizontal;
    local tabButtonSpacing = self.tabButtonSetup.spacing or 0;

    for _, data in ipairs(self.tabData) do
        if data.enabled then
            n = n + 1;
            data.tabIndex = n;

            local button = self.tabButtons[n];
            if not button then
                button = CreateFrame("Button", nil, self.tabButtonSetup.container, self.tabButtonSetup.template);
                self.tabButtons[n] = button;
            end

            local buttonWidth = button:SetText(data.tabName) or 0;

            if isHorizontal then
                totalButtonWidth = totalButtonWidth + buttonWidth;
                if n > 1 then
                    totalButtonWidth = totalButtonWidth + tabButtonSpacing;
                end
            else
                if buttonWidth > totalButtonWidth then
                    totalButtonWidth = buttonWidth;
                end
            end

            button.tabKey = data.tabKey;
            button:Show();
            button.SelectTab = function()
                self:SelectTabByKey(data.tabKey);
            end

            if data.tabKey == self.selectedTabKey then
                firstValidTabKey = data.tabKey;
            end
        end
    end

    self.totalButtonWidth = totalButtonWidth;
    self:LayoutTabButtons();

    if not self:SelectTabByKey(firstValidTabKey or self.defaultTabKey) then
        self:SelectTabByIndex(1);
    end
end

function TabSystemMixin:GetEnabledTabData()
    local n = 0;
    local tbl = {};

    for _, data in ipairs(self.tabData) do
        if data.enabled then
            n = n + 1;
            tbl[n] = data;
        end
    end

    return tbl;
end

function TabSystemMixin:GetLastTabButton()
    return self.lastTabButton;
end


---Add TabSystemMixin methods to the frame
function addon.SeupTabSystem(frame)
    Mixin(frame, TabSystemMixin);

    frame.isTabDirty = true;
    frame.tabButtons = {};
    frame.tabButtonSetup = {};
    frame.tabFrameSetup = {};
    frame.tabData = {};
    frame.tabKeyXTabData = {};
end
