if not (GetLocale() == "koKR") then
    return;
end

local L = Narci.L

L["Heritage Armor"] = "유산 방어구";

--Model Control--
NARCI_GROUP_PHOTO = "단체 사진";

--NPC Browser--
NARCI_NPC_BROWSER_TITLE_LEVEL = "%?%? 레벨%s*";      --Level ?? --Use this to check if the second line of the tooltip is NPC's title or unit type

L["Item Bonus"] = "추가 효과:";

L["No Service"] = "서비스 없음";
L["Shards Disabled"] = "나락 외부에서 지배의 조각이 비활성화됩니다.";
L["Day Plural"] = "일";
L["Day Singular"] = "일";
L["Hour Plural"] = "시간";
L["Hour Singular"] = "시간";


--TransmogUI--
L["Transmog UI"] = "형상변환";
L["Transmog UI Description"] = "모든 캐릭터가 이용할 수 있는 커스텀 세트를 생성합니다.";
L["OutfitSource Default"] = "현재 캐릭터";
L["OutfitSource Default Tooltip"] = "데이터는 서버에 저장됩니다.";
L["OutfitSource Shared"] = "공유 목록";
L["OutfitSource Shared Tooltip"] = "모든 캐릭터가 이 목록을 이용할 수 있습니다.\n\n데이터는 Narcissus 애드온에 로컬로 저장됩니다.";
L["OutfitSource Alts"] = "다른 캐릭터";
L["OutfitSource Alts Tooltip"] = "Narcissus 애드온을 활성화한 상태로 다른 캐릭터에 로그인한 적이 있다면, 해당 캐릭터의 커스텀 세트를 볼 수 있습니다.\n\n현재 캐릭터에서는 세트를 수정할 수 없습니다.";
L["Cannot Delete On Alts"] = "이 세트는 다른 캐릭터의 것이므로 수정할 수 없습니다";
L["Your Money Amount"] = "소지 금액";
L["TransmogSet No Valid Items"] = "유효한 아이템이 없습니다.";
L["Copy To Shared List"] = "공유 목록에 복사";
L["Insturction Delete Without Confirm"] = "Shift 클릭으로 확인 없이 삭제합니다.";
L["Press Key To Copy Format"] = "|cffffd100%s|r 키를 눌러 복사";
L["Added To Shared List"] = "공유 목록에 추가됨";
L["Added To Shared List Alert Format"] = "이 세트는 이미 공유 목록에 \"%s\"(으)로 추가되었습니다";
L["New Set Location Default"] = "이 커스텀 세트는 현재 캐릭터에 저장됩니다.";
L["New Set Location Shared"] = "이 커스텀 세트는 공유 목록에 추가됩니다.";
L["Save Custom Set Location"] = "저장 위치:";
L["Save Slots Colon"] = "저장 슬롯: ";
L["Error View Outfit In Combat"] = "전투 중에는 커스텀 세트를 볼 수 없습니다";