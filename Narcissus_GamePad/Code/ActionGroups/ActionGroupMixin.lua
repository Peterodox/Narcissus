local _, addon = ...

local ActionGroupMixin = {};

local function CreateActionGroup(name)
    if not name then
        print("A name is required");
        return
    end

    local object = {};
    for k, v in pairs(ActionGroupMixin) do
        object[k] = v;
    end

    addon.actionGroups[name] = object;

	return object
end

addon.CreateActionGroup = CreateActionGroup;


ActionGroupMixin.uiData = {
    desriptionPAD1 = nil,   --A
    desriptionPAD2 = nil,   --B
    desriptionPAD3 = nil,   --X
    desriptionPAD4 = nil,   --Y
};

function ActionGroupMixin:SetButtonDescription(index, drescription)
    if not index then return end;
    if type(index) == "string" then
        index = addon.GetPadKeyIndexByName(index);
    end
    self.uiData["desriptionPAD"..index] = drescription;
end


function ActionGroupMixin:GetUIData()
    return self.uiData or {}
end

function ActionGroupMixin:Init()
    --assign the controlled objects, etc...
end

function ActionGroupMixin:Click(button)
    if self.currentObj and self.currentObj.OnClick then
        self.currentObj:OnClick(button, nil, true);
        return true
    end
end

function ActionGroupMixin:Enter(currentObj)
    self:Leave();
    if currentObj and currentObj.OnEnter then
        currentObj:OnEnter(nil, true);
    end
    self.currentObj = currentObj;
end

function ActionGroupMixin:Leave()
    if self.currentObj and self.currentObj.OnLeave then
        self.currentObj:OnLeave();
        self.currentObj = nil;
    end
end

function ActionGroupMixin:KeyDown(key)
    local hold, propagate;
    return hold, propagate
end

function ActionGroupMixin:KeyUp(key)

end

function ActionGroupMixin:Navigate(x, y)
    --↑↓←→
    -- x > 0 PADDRIGHT, x < 0 PADDLEFT
    -- y > 0 PADDUP, x < 0 PADDDOWN
end

function ActionGroupMixin:Switch(x)
    --x > 0 PADRSHOULDER, x < 0 PADLSHOULDER
end

function ActionGroupMixin:Activate(mode)
    if self.Init then
        self:Init();
        self.Init = nil;
    end
    if self.OnActiveCallback then
        self:OnActiveCallback(mode);
    end
end

function ActionGroupMixin:OnDeactive()

end

function ActionGroupMixin:ResetNavigation()

end