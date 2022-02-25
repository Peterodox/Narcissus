local QuestDataProvider = {};

function QuestDataProvider:GetQuestObjectives(questLogIndex)
    local objectives;
    self.temp1, objectives = GetQuestLogQuestText(questLogIndex);
    self.temp1 = nil;
    return objectives
end

function QuestPinMixin:OnMouseEnter()
    local questID = self.questID;
	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID);
	local title = C_QuestLog.GetTitleForQuestID(questID);
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 5, 2);
	GameTooltip:SetText(title);
	QuestUtils_AddQuestTypeToTooltip(GameTooltip, questID, NORMAL_FONT_COLOR);
	GameTooltip_CheckAddQuestTimeToTooltip(GameTooltip, questID);

    GameTooltip:AddLine(QuestDataProvider:GetQuestObjectives(questLogIndex), 1, 1, 1, true);
    local numObjectives = GetNumQuestLeaderBoards(questLogIndex);

    for i = 1, numObjectives do
        local text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex);
        if ( text and not finished ) then
            GameTooltip:AddLine(QUEST_DASH..text, 1, 1, 1, true);
        end
    end

    GameTooltip:Show();
    self:GetMap():TriggerEvent("SetHighlightedQuestPOI", questID);
end