local _, Loader = ...

Loader:AddInitCallback( "GetMaxAnimationID" );

function Loader:GetMaxAnimationID()
    if not self.requireUpdate then
        return
    end

    if ScriptErrorsFrame and ScriptErrorsFrame.DisplayMessageInternal then
        local errorKeyword = ":SetAnimation";
        local errorPattern = "(%d+) %- (%d+)";
        hooksecurefunc(ScriptErrorsFrame, "DisplayMessageInternal", function(frame, msg, warnType, keepHidden, locals, msgKey)
            if not self.isErrorProcessed then
                --print(msg);
                if string.find(msg, errorKeyword) then
                    local minID, maxID = string.match(msg, errorPattern);
                    if maxID then
                        maxID = tonumber(maxID) - 1;
                        if maxID > 1000 then
                            local oldMax = NarciConstants.Animation.MaxAnimationID;
                            NarciConstants.Animation.MaxAnimationID = maxID;
                            NarciPhotoModeAPI:SetMaxAnimationID(maxID);
                            if oldMax ~= maxID then
                                self:NewMsg("New Animation Range: %d - %d", oldMax, maxID);
                            end
                        end
                    end

                    self.isErrorProcessed = true;

                    --Wipe Error Trace
                    local index = frame.seen[msgKey];
                    if index then
                        frame.seen[msgKey] = nil;
                        if index > 0 then
                            local tremove = function(t, i)
                                if t then
                                    table.remove(t, i);
                                end
                            end
                            tremove(frame.order, index);
                            tremove(frame.count, index);
                            tremove(frame.messages, index);
                            tremove(frame.times, index);
                            tremove(frame.locals, index);
                            tremove(frame.warnType, index);
                            frame.index = index - 1;
                        end
                    end

                    ScriptErrorsFrame:Hide();
                end
            end
        end);

        local model = CreateFrame("PlayerModel", nil, UIParent);
        model:Hide();
        model:SetAnimation(9999);
    end
end