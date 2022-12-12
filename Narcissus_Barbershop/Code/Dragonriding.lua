local _, addon = ...

--[[
    chrModelID:124, id:27, displayID:107058     --Renewed Proto-Drake 4278602
    chrModelID:129, id:27, displayID:105268     --Windrborne Velocidrake 4281540
    chrModelID:123, id:27, displayID:106003     --Highland Drake 4227968
    chrModelID:126, id:27, displayID:107056     --Cliffside Wylderdrake 4252337

    C_BarberShop.SetViewingChrModel(chrModelID)   New API for Dragon Customization

    4252339
--]]

function Debug_GetDragonModelID()
    local customizationData = C_BarberShop.GetAvailableCustomizations();

    for _, categoryData in ipairs(customizationData) do
        if categoryData.chrModelID then
            print("chrModelID:", categoryData.chrModelID, " id:", categoryData.id, " name:", categoryData.name);
        end
    end
end