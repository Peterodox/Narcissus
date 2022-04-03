local tinsert = table.insert;
local processors = {};

local function CreateProcessor(name, cycle)
   local p = CreateFrame("frame", name, nil);
    tinsert(processors, p);

    p:Hide();
    p.queue = {};

    if not cycle or type(cycle) ~= "number" then
        cycle = 0.25;    --1 update every 0.2 seconds
    end
    p.cycle = cycle;

    function p:Add(newWidget, queryFunc)
        self.t = 0;
        local inQueue;
        for i = 1, #self.queue do
            if self.queue[i][1] == newWidget then
                self.queue[i] = {newWidget, queryFunc, numQuery = 0};
                inQueue = true;
                break
            end
        end
        if not inQueue then
            tinsert(self.queue, {newWidget, queryFunc, numQuery = 0});
        end
        self:Show();
    end

    function p:Process()
        local isComplete = true;
        for i = 1, #self.queue do
            local widget = self.queue[i][1];
            if widget then
                local queryFunc = self.queue[i][2];
                local arg1 = self.queue[i][3];
                local numQuery = self.queue[i].numQuery;
                if (not queryFunc) or ( queryFunc(widget, arg1) ) or (not numQuery) or numQuery > 4 then
                    self.queue[i] = {};
                else
                    self.queue[i].numQuery = numQuery + 1;
                    isComplete = false;
                end
            end
        end
        return isComplete;
    end

    function p:Stop()
        self:Hide();
        self.t = 0;
        wipe(self.queue);
    end

    p:SetScript("OnUpdate", function(self, elapsed)
        self.t = self.t + elapsed;
        if self.t >= self.cycle then
            self.t = 0;
            local isComplete = self:Process();
            if isComplete then
                self:Stop();
            end
        end
    end)

    return p
end

local function StopAllProcessors()
    for i = 1, #processors do
        processors[i]:Stop();
    end
end


NarciAPI.CreateProcessor = CreateProcessor;
NarciAPI.StopAllProcessors = StopAllProcessors;