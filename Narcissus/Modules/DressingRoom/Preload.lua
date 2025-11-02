local _, addon = ...
local DressingRoomSystem = {};
addon.DressingRoomSystem = DressingRoomSystem;

NarciDressingRoomAPI = {};


local HiddenVisuals = {
    --/dump C_TransmogCollection.GetAppearanceSources(GetMouseFoci()[1].visualInfo.visualID)
    --[slotID] = visualID (appearanceID)
    [1] = 29124,    --77344
    [3] = 24531,    --77343
    [5] = 40282,    --104602
    [4] = 33155,    --83202
    [19]= 33156,    --83203
    [9] = 40284,    --104604
    [10]= 37207,    --94331
    [6] = 33252,    --84233
    [7] = 42568,    --198608
    [8] = 40283,    --104603
};


local GetAppearanceSources = C_TransmogCollection.GetAppearanceSources;
local function GetHiddenSourceIDForSlot(slotID)
    local visualID = HiddenVisuals[slotID]
    local sources = visualID and GetAppearanceSources(visualID);
    if sources and sources[1] then
        return sources[1].sourceID
    end
end
addon.DressingRoomSystem.GetHiddenSourceIDForSlot = GetHiddenSourceIDForSlot;