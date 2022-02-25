--Not Loaded
local After = C_Timer.After;

local DistanceCalculator;
local MovementListener;

function NarciAPI_ActivateDistanceCalculator(calibrateDistance)
    if not DistanceCalculator then
        --Timer frame
        DistanceCalculator = CreateFrame("Frame");
        DistanceCalculator:Hide();
        DistanceCalculator.basicSpeed = 0;

        local function OnUpdate(self, elapsed)
            self.t = self.t + elapsed;
        end

        DistanceCalculator:SetScript("OnShow", function(self)
            self.t = 0;
        end);

        DistanceCalculator:SetScript("OnHide", function(self)
            print(self.t);
            if self.basicSpeed > 0 then
                local d = self.basicSpeed * self.t;
                d = math.floor(d * 100 + 0.5) / 100;
                print("|cffFFF569"..d.." yd|r");
            elseif self.t > 0.2 then
                if self.calibrateDistance then
                    self.basicSpeed = self.calibrateDistance / self.t;
                    self.calibrateDistance = nil;
                    print("Speed: ".. math.floor(self.basicSpeed * 100 + 0.5) / 100 .. " yd/s" );
                else
                    print("Speed Not Calibrated");
                end
            end
            self.t = 0;
        end);

        DistanceCalculator:SetScript("OnUpdate", OnUpdate);

        --Event listener
        MovementListener = CreateFrame("Frame");
        MovementListener:Hide();

        MovementListener:SetScript("OnShow", function(self)
            self:RegisterEvent("PLAYER_STARTED_MOVING");
            self:RegisterEvent("PLAYER_STOPPED_MOVING");
        end);

        local function OnEvent(self, event)
            if event == "PLAYER_STARTED_MOVING" then
                DistanceCalculator:Show();
            else
                DistanceCalculator:Hide();
            end
        end

        MovementListener:SetScript("OnEvent", OnEvent);

        --Global
        function NarciAPI_DeactivateDistanceCalculator()
            MovementListener:Hide();
            DistanceCalculator:Hide();
        end
    end

    MovementListener:Show();

    if calibrateDistance and type(calibrateDistance) == "number" and calibrateDistance >= 5 then
        DistanceCalculator.basicSpeed = 0;
        DistanceCalculator.calibrateDistance = calibrateDistance;
    end
end

local _G = _G;
local Globals;
local totalGlobals;

local SEARCH_PER_FRAME = 240;
local numLoop = 0;
local numMatch = 0;
local function SearchLoop(b, key, value)
    local find = string.find;
    local index;

    if key then
        local globalName
        for i = b, b + SEARCH_PER_FRAME  do
            if Globals[i] then
                index = i;
                globalName = Globals[i];
                if find(globalName, key) then
                    numMatch = numMatch + 1;
                    
                    local t = type(_G[ globalName ]);
                    if t == "number" or t == "string" then
                        print("|cffffd200".. globalName.."|r = ".. (_G[ globalName ] or "nil") );
                    else
                        print("|cff808080"..t.." |cffffd200".. globalName);
                    end
                end
            else
                print("Search Completes ---------------")
                print("Found ".. "|cffffd200".. numMatch .. "|r matches.")
                numLoop = 0;
                return
            end
        end
    else
        local globalValue;
        value = tostring(value);
        for i = b, b + SEARCH_PER_FRAME  do
            if Globals[i] then
                index = i;
                globalValue = _G[ Globals[i] ];
                if (type(globalValue) == "string" or type(globalValue) == "number") and find(globalValue, value) then
                    numMatch = numMatch + 1;
                    print("|cffffd200".. Globals[i].."|r = ".. (globalValue or "nil") );
                end
            else
                print("Search Completes ---------------")
                print("Found ".. "|cffffd200".. numMatch .. "|r matches.")
                numLoop = 0;
                return
            end
        end
    end

    After(0, function()
        SearchLoop(b + SEARCH_PER_FRAME + 1, key)
    end)


    numLoop = numLoop + 1;
    if numLoop == 100 then
        numLoop = 0;
        print(math.floor(index / totalGlobals * 10000 + 0.5)/100 .. "% ----------------------------")
    end
end

function Narci_SearchGlobalString(key, value)
    if key then
        if type(key) ~= "string" then
            print("The key must be a string!");
            return
        end
    elseif value then
        if type(value) ~= "number" and type(value) ~= "string" then
            print("The value  must be a string or number!");
            return
        end
    else
        return
    end

    if not Globals then
        Globals = {};
        totalGlobals = 0;
        for k, v in pairs(_G) do
            Globals[totalGlobals] = k;
            totalGlobals = totalGlobals + 1;
        end
    end

    numLoop = 0;
    numMatch = 0;
    local beginning = 1;
    if value then
        SearchLoop(beginning, nil, value)
    else
        SearchLoop(beginning, key)
    end
end