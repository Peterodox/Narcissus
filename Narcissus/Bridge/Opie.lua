-- Create Custom Ring for Opie
--[[
    _u: uprefix
    c: hexColor
    icon: file

    api.setSliceProperty("icon", path or text)
--]]


local function AddCustomRing()
    if not (OPie and OPie.CustomRings and OPie.CustomRings.SetExternalRing and OPie.ActionBook) then return end;

    --[[
    local RingData = {
        {id="/run print('1')", _u="a", c="ffffff", icon="Interface\\AddOns\\Narcissus\\Art\\Logos\\Narcissus",},
        {id="/run print('2')", _u="b", c="ffffff"},
        {id="/run print('3')", _u="c", c="ffffff"},
        {id="/run print('4')", _u="d", c="ffffff"},
    
        name = "Narcissus",
        --hotkey="",
        --limit="",
        _u = "NARCISSUS",
        v = 1,  --?
    };
    --]]
    --OPie.CustomRings:AddDefaultRing("Narcissus", RingData);

    local categoryName = "Narcissus";
    local actionType = "opie.Narcissus.Module";


    local AB = assert(OPie.ActionBook:compatible(2, 36), "A compatible version of ActionBook is required")
    if not AB then return end;

    local moduleData = {};

    local function SetModuleIcon(moduleID, iconPostfix)
        if moduleData[moduleID] then
            moduleData[moduleID].icon = "Interface\\AddOns\\Narcissus\\Art\\Logos\\ActionIcon-64-"..iconPostfix;
        end
    end

    local menuInfo = Narci_MinimapButton:GetMenuInfo();

    moduleData[1] = {
        label = Narci.L["Character Panel"],
        callback = function() Narci_Open() end;
    };

    for i, info in ipairs(menuInfo.objects) do
        if info.type == "Button" then
            table.insert(moduleData, {
                label = info.name,
                callback = info.OnClick,
            });
        end
    end

    table.insert(moduleData, {
        label = Narci.L["Settings"],
        callback = NarciAPI.ToggleSettings,
    });

    SetModuleIcon(1, "Narcissus");
    SetModuleIcon(2, "PhotoMode");
    SetModuleIcon(3, "DressingRoom");
    SetModuleIcon(4, "Turntable");
    SetModuleIcon(5, "Achievement");
    SetModuleIcon(6, "Settings");


    --ActionBook
    local nameMap = {}
    local function call(obj, button)
        obj:callback(button)
    end
    local function GetDescription(index)
        local obj = moduleData[index];
        return "Narcissus", obj and obj.label or index, obj and obj.icon or "Interface/Icons/INV_Misc_QuestionMark", obj
    end
    local function GetHint(obj)
        if not obj then return end
        return true, 0, obj.icon, obj.label or obj.text, 0,0,0, obj.OnTooltipShow, nil, obj
    end
    local function CreateAction(index, flags)
        local rightClick = flags == 8
        local pname = index .. "#" .. (rightClick and "R" or "L")
        if not nameMap[pname] then
            local obj = moduleData[index];
            if not obj then return end
            nameMap[pname] = AB:CreateActionSlot(GetHint, obj, "func", call, obj, rightClick and "RightButton" or "LeftButton")
        end
        return nameMap[pname]
    end
    AB:RegisterActionType(actionType, CreateAction, GetDescription, 2)  --2: num args

    --Create Category
    AB:AugmentCategory(categoryName, function(_, add)
        for id = 1, #moduleData do
            add(actionType, id);
        end
    end)
    AB:NotifyObservers(actionType)
end

do
    local _, addon = ...
    addon.AddLoadingCompleteCallback(AddCustomRing);
end