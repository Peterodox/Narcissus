local MAX_ANIMKIT_ID = 23613;       --Note: not continuous!
local MODELS_PER_PAGE = 15;

NarciAnimKitTestFrameMixin = {};

function NarciAnimKitTestFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton");
    self.page = 1;

    local ROW = 3;
    local COL = 4;
    local GAP = 8;
    local W, H = 150, 200;
    local HEADER_HEIGHT = 16;

    local numModels = ROW * COL;
    MODELS_PER_PAGE = numModels;

    self.maxPage = math.ceil(MAX_ANIMKIT_ID / numModels);
    local pi = math.pi;

    local model;
    local models = {};
    local row, col = 1, 1;
    for i = 1, numModels do
        model = CreateFrame("DressUpModel", nil, self, "NarciAnimKitTestModelTemplate");
        models[i] = model;
        model:SetLight(true, false, math.cos(pi/4)*math.sin(-pi/4) ,  math.cos(pi/4)*math.cos(-pi/4) , -math.cos(pi/4), 1, 204/255, 204/255, 204/255, 1, 0.8, 0.8, 0.8);
        model:SetPoint("TOPLEFT", self, "TOPLEFT", (col - 1)*W + col * GAP, -HEADER_HEIGHT -((row - 1)*H + row * GAP));
        model:SetSize(W, H);
        col = col + 1;
        if col > COL then
            col = 1;
            row = row + 1;
        end
    end
    self.models = models;

    self:SetSize(COL*W + (COL+1)*GAP, ROW*H + (ROW+1)*GAP + HEADER_HEIGHT);

    self:SetScript("OnLoad", nil);
    self.OnLoad = nil;
end

function NarciAnimKitTestFrameMixin:OnShow()
    self:UpdatePage();
end

function NarciAnimKitTestFrameMixin:OnMouseWheel(delta)
    if delta > 0 then
        if self.page > 1 then
            if IsShiftKeyDown() then
                self.page = self.page - 100;
                if self.page < 1 then
                    self.page = 1;
                end
            else
                self.page = self.page - 1;
            end
        else
            return
        end
    else
        if self.page < self.maxPage then
            if IsShiftKeyDown() then
                self.page = self.page + 100;
                if self.page > self.maxPage then
                    self.page = self.maxPage;
                end
            else
                self.page = self.page + 1;
            end
        else
            return
        end
    end
    self:UpdatePage();
end

function NarciAnimKitTestFrameMixin:OnDragStart()
    self:StartMoving();
end

function NarciAnimKitTestFrameMixin:OnDragStop()
    self:StopMovingOrSizing();
end

function NarciAnimKitTestFrameMixin:UpdatePage()
    local id = (self.page - 1) * MODELS_PER_PAGE;
    for i = 1, MODELS_PER_PAGE do
        self.models[i]:SetNewAnimKit(id + i);
    end
    self.PageText:SetText(self.page.."/"..self.maxPage);
end



NarciAnimKitTestModelMixin = {};

function NarciAnimKitTestModelMixin:OnLoad()
    self:SetAutoDress(false);
    self:UseModelCenterToTransform(true);
end

function NarciAnimKitTestModelMixin:OnShow()
    if not self.isInit then
        --self:SetUnit("player");
        self:SetDisplayInfo(21976);
        self.isInit = true;
    end
    self:TryOn("item:72019");
    self:TryOn("item:72020");
end

function NarciAnimKitTestModelMixin:OnModelLoaded()
    self:Undress();
    self:SetAnimation(0, 0);
    self:SetModelScale(1.2);
    --self:MakeCurrentCameraCustom();
end

function NarciAnimKitTestModelMixin:SetNewAnimKit(id)
    self:StopAnimKit();
    self:SetAnimation(0, 0);
    self:PlayAnimKit(id, true);
    self.animKitID = id;
    self.IDText:SetText(id);
end
