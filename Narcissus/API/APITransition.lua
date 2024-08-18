local _, addon = ...

local TransitionAPI = {};
addon.TransitionAPI = TransitionAPI;
NarciAPI.TransitionAPI = TransitionAPI;


if addon.IsTOCVersionEqualOrNewerThan(110000) then
    function TransitionAPI.IsTWW()
        return true
    end
else
    function TransitionAPI.IsTWW()
        return false
    end
end