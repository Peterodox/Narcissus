--TOC version 90200

NarciConstants = {
    --Constant


    --Auto-update
    Animation = {
        MaxAnimationID = 1681,
    },

    Soulbinds = {
        MaxRow = 12,    --8 before 9.1
    }
};

do
    local _, addon = ...
    if addon.IsDragonflight() then
        local maxAnimID = 1737;
        NarciConstants.Animation.MaxAnimationID = maxAnimID;
    end
end