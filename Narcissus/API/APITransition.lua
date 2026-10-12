local _, addon = ...

local TransitionAPI = {};
addon.TransitionAPI = TransitionAPI;
NarciAPI.TransitionAPI = TransitionAPI;

TransitionAPI.GetInventorySlotInfo = (C_PaperDollInfo and C_PaperDollInfo.GetInventorySlotInfo) or GetInventorySlotInfo;
