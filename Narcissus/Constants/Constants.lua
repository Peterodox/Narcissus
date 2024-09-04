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
        local _, _, _, tocVersion = GetBuildInfo();
        local maxAnimID;
        if tocVersion and tocVersion >= 110000 then
            maxAnimID = 1787;
        else
            maxAnimID = 1757;
        end
        NarciConstants.Animation.MaxAnimationID = maxAnimID;
    end
end