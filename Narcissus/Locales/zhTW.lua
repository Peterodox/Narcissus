if not(GetLocale() == "zhTW") then
    return
end

local L = Narci.L;
local S = Narci.L.S;

NARCI_WORDBREAK_COMMA = "，";

--Date--
L["Today"] = COMMUNITIES_CHAT_FRAME_TODAY_NOTIFICATION;
L["Yesterday"] = COMMUNITIES_CHAT_FRAME_YESTERDAY_NOTIFICATION;
L["Format Days Ago"] = "%d天前";
L["A Month Ago"] = "1個月前";
L["Format Months Ago"] = "%d個月前";
L["A Year Ago"] = "1年前";
L["Format Years Ago"] = "%d年前";
L["Date Colon"] = "日期: ";
L["Day Plural"] = "天";
L["Day Singular"] = "天";
L["Hour Plural"] = "小時";
L["Hour Singular"] = "小時";


L["Swap items"] = "更換裝備";
L["Movement Speed"] = "移動速度";
L["Damage Reduction Percentage"] = "減傷%";

L["Advanced Info"] = "點一下切換顯示進階資訊。";

L["Photo Mode"] = "拍照模式";
L["Photo Mode Tooltip Open"] = "點一下開啟截圖工具箱。";
L["Photo Mode Tooltip Close"] = "點一下關閉截圖工具箱。";
L["Photo Mode Tooltip Special"] = "在魔獸的 Screenshots 資料夾裡面的 截圖中將不會包含這個工具介面。";

L["Xmog Button"] = "分享塑形";
L["Xmog Button Tooltip Open"] = "點一下顯示塑形物品，而不是實際裝備。";
L["Xmog Button Tooltip Close"] = "點一下顯示裝備欄中穿著的實際裝備。";
L["Xmog Button Tooltip Special"] = "可以切換不同的版面配置。";

L["Emote Button"] = "表情動作";
L["Emote Button Tooltip Open"] = "搭配獨特的表情動畫。";

L["HideTexts Button"] = "隱藏文字";
L["HideTexts Button Tooltip Open"] = "點一下隱藏所有單位名稱、聊天泡泡和戰鬥文字。";
L["HideTexts Button Tooltip Close"] = "點一下恢復顯示單位名稱、聊天泡泡和戰鬥文字。";
L["HideTexts Button Tooltip Special"] = "結束拍照模式後都會恢復成原本的設定。";

L["TopQuality Button"] = "最高品質";
L["TopQuality Button Tooltip Open"] = "點一下將畫面設定中的每一個選項都設為最高值。";
L["TopQuality Button Tooltip Close"] = "點一下恢復畫面設定。";

L["Heritage Armor"] = "經典護甲";
L["Secret Finding"] = "秘密發現"

L["Heart Azerite Quote"] = "眼睛看不到的也非常重要。";

--Title Manager--
L["Open Title Manager"] = "開啟頭銜管理員";
L["Close Title Manager"] = "關閉頭銜管理員";

--Alias--
L["Use Alias"] = "切換成暱稱"
L["Use Player Name"] = "切換成玩家名稱";

L["Minimap Tooltip Double Click"] = "按兩下";
L["Minimap Tooltip Left Click"] = "左鍵|r";
L["Minimap Tooltip To Open"] = "|cffffffff開啟全螢幕角色資訊";
L["Minimap Tooltip Module Panel"] = "|cffffffff開啟工具面板";
L["Minimap Tooltip Right Click"] = "右鍵";
L["Minimap Tooltip Shift Right Click"] = "Shift + 右鍵"
L["Minimap Tooltip Hide Button"] = "|cffffffff隱藏這個按鈕|r"
L["Minimap Tooltip Middle Button"] = "|CFFFF1000中鍵 |cffffffff重置鏡頭";
L["Minimap Tooltip Set Scale"] = "設定縮放大小: |cffffffff/narci [大小數值 0.8~1.2]";
L["Corrupted Item Parser"] = "|cffffffff開啟腐化物品鏈接解析器|r";
L["Toggle Dressing Room"] = "|cffffffff開啟"..DRESSUP_FRAME.."|r";

L["Layout"] = "版面配置";
L["Symmetry"] = "對稱";
L["Asymmetry"] = "不對稱";
L["Copy Texts"] = "複製文字";
L["Syntax"] = "句法";
L["Plain Text"] = "純文字";
L["Export Includes"] = "同時導出...";

L["3D Model"] = "3D模組";
L["Equipment Slots"] = "裝備欄";

--Preferences--
L["Interface"] = "介面";
L["Themes"] = "主題";
L["Camera"] = "鏡頭";
L["Effects"] = "效果";
L["Transmog"] = "塑形";
L["Extensions"] = "拓展功能";
L["About"] = "關於";
L["Preferences"] = "偏好設定";
L["Preferences Tooltip"] = "點一下打開偏好設定";
L["Truncate Text"] = "截斷文字";
L["Stat Sheet"] = "屬性欄";
L["Text Width"] = "文字寬度";
L["Hotkey"] = "快捷鍵";
L["Double Tap"] = "按兩下打開";
L["Double Tap Description"] = "連按兩下打開角色面板的快捷鍵來打開此模組。"
L["Override"] = "是否覆蓋";
L["Invalid Key"] = "無效的值";
L["Minimap Button"] = "小地圖按鈕";
L["Shortcuts"] = "快捷方式";
L["Image Filter"] = "濾鏡";
L["Image Filter Description"] = "除暗角以外的所有濾鏡都會在幻化模式被暫時禁用。";
L["Grain Effect"] = "顆粒效果";
L["Camera Movement"] = "鏡頭運動";
L["Orbit Camera"] = "環繞鏡頭";
L["Orbit Camera Description On"] = "當妳打開此模組時，鏡頭會自動旋轉到角色面前並開始環繞。";
L["Orbit Camera Description Off"] = "當妳打開此模組時，鏡頭只會被拉近不會有任何旋轉。";
L["Camera Safe Mode"] = "鏡頭安全模式";
L["Camera Safe Mode Description"] = "在關閉此模組後徹底關閉ActionCam功能。";
L["Camera Safe Mode Description Extra"] = "已禁用因為妳正在使用DynamicCam模組。";
L["Fade Out"] = "自動淡化";
L["Fade Out Description"] = "在妳將鼠標從小地圖按鈕上移出後，降低其透明度。";
L["Fade Music"] = "淡入/淡出音樂";
L["Vignette Strength"] = "暗角強度";
L["Weather Effect"] = "天氣效果";
L["Letterbox"] = "寬熒幕效果";
L["Letterbox Ratio"] = "寬高比";
L["Letterbox Alert1"] = "妳屏幕的寬高比超過了所選比例。";
L["Letterbox Alert2"] = "建議將UI縮放比設置為%0.1f\n(當前縮放比為%0.1f)";
L["Default Layout"] = "預設佈局";
L["Transmog Layout1"] = "對稱，唯一模組";
L["Transmog Layout2"] = "雙模組";
L["Transmog Layout3"] = "緊湊模式";
L["Border Theme Header"] = "邊框主題";
L["Border Theme Bright"] = "明亮";
L["Border Theme Dark"] = "灰暗";
L["Always Show Model"] = "在使用對稱布局時顯示3D模組";
L["AFK Screen Description"] = "在妳的人物暫離後自動打開Narcissus。";
L["AFK Screen Description Extra"] = "勾選此選項將覆蓋ElvUI的AFK模式。";
L["Gemma"] = "\"Gemma\"";
L["Gemma Description"] = "在妳為壹件物品鑲嵌寶石時，顯示可用的寶石列表。";
L["Dressing Room"] = "試衣間";
L["Dressing Room Description"] = "增大試衣間窗口大小，並使妳能夠通過試衣間瀏覽、復制其他玩家的幻化調料包。";
L["Show Detailed Stats"] = "顯示詳盡的屬性信息";
L["Tooltip Color"] = "小提示顏色";
L["Entrance Visual"] = "登場效果";
L["Entrance Visual Description"] = "在模組登場時播放法術效果。";
L["Panel Scale"] = "面板縮放";
L["Exit Confirmation"] = "退出確認";
L["Exit Confirmation Texts"] = "退出合影模式？";
L["Exit Confirmation Leave"] = "退出";
L["Exit Confirmation Cancel"] = "取消";
L["Ultra-wide"] = "超寬屏";
L["Ultra-wide Optimization"] = "超寬屏優化";
L["Baseline Offset"] = "基準線偏移";
L["Ultra-wide Tooltip"] = "妳能看到此選項是因為妳正在使用壹臺%s:9顯示器。";
L["Interactive Area"] = "交互區域";
L["Item Socketing Tooltip"] = "雙擊左鍵進行鑲嵌";
L["No Available Gem"] = "|cffd8d8d8沒有可鑲嵌的寶石|r";
L["Credits"] = "致謝";
L["Use Bust Shot"] = "使用半身像";
L["Use Escape Button"] = "Esc鍵";
L["Use Escape Button Description1"] = "按下Esc鍵來退出模組。";
L["Use Escape Button Description2"] = "點擊屏幕右上角的X按鈕來退出模組。";
L["Show Module Panel Gesture"] = "鼠標懸停時顯示模塊面板";
L["Independent Minimap Button"] = "不受其他模組控制";
L["AFK Screen"] = "AFK画面";
L["Keep Standing"] = "保持站立";
L["Keep Standing Description"] = "當妳AFK後定時使用/站立表情。此選項不會中斷自動登出。"
L["None"] = "無";
L["NPC"] = "NPC";
L["Database"] = "數據庫";
L["Creature Tooltip"] = "生物信息";
L["RAM Usage"] = "內存占用";
L["Others"] = "其它";
L["Find Relatives"] = "查找相關生物";
L["Find Related Creatures Description"] = "找到與目標同姓的其他生物。";
L["Find Relatives Hotkey"] = "按Tab搜索相關生物。";
L["Find Relatives Hotkey Format"] = "按下%s開始查找。";
L["Translate Names"] = "翻譯姓名";
L["Translate Names Description On"] = "獲取目標譯名並將其顯示在...";
L["Select A Language"] = "已選語言：";
L["Select Multiple Languages"] = "已選語言：";
L["Load on Demand"] = "隨需求載入";
L["Load on Demand Description On"] = "在搜索功能被調用時再載入數據庫。";
L["Load on Demand Description Off"] = "數據庫將在妳登入時載入。";
L["Load on Demand Description Disabled"] = NARCI_COLOR_YELLOW.. "這壹選項被鎖住了，因為妳選擇顯示生物信息。";
L["Tooltip"] = "小提示";
L["Name Plate"] = "名條";
L["Y Offset"] = "縱向偏移";
L["Sceenshot Quality"] = "截圖質量";
L["Screenshot Quality Description"] = "更高的截圖質量會增加圖像大小。";
L["General"] = "通用設定";
L["Camera Transition"] = "鏡頭過渡";
L["Camera Transition Description On"] = "當你打開角色面板時鏡頭會平滑地運動到預設位置。";
L["Camera Transition Description Off"] = "鏡頭轉換變為瞬時。此效果將在你第二次使用角色面板時開始生效。\n此效果會占用鏡頭預設#4。";
L["Interface Options Tab Description"] = "你也可以點擊位於屏幕左下角Narcissus工具欄右端的小齒輪按鈕來打開偏好設置。";
L["Conduit Tooltip"] = "顯示更高級別的靈印效果";
L["Domination Indicator"] = "統御裂片指示器";

--Model Control--
L["Ranged Weapon"] = "遠程武器";
L["Melee Animation"] = "近戰武器";
L["Spellcasting"] = "施法動作";
L["Link Light Sources"] = "關聯燈光設定";
L["Link Model Scales"] = "關聯模組比例";
L["Hidden"] = "隱藏";
L["Light Types"] = "平行光/環境光";
L["Light Types Tooltip"] = "在以下兩種燈光間切換：\n- 可以被模組遮擋並投射陰影的平行光\n- 影響整個模組表面的環境光";

L["Group Photo"] = "合影模式";
L["Reset"] = "重置";
L["Actor Index"] = "序號";
L["Move To Font"] = "|cff40c7eb頂層|r";
L["Actor Index Tooltip"] = "拖動壹個序號按鈕來改變其模組的層級。";
L["Play Button Tooltip"] = "左鍵：播放此動畫\n右鍵：恢復所有模組的動畫";
L["Pause Button Tooltip"] = "左鍵：定格此動畫\n右鍵：暫停所有模組的動畫";
L["Save Layers"] = "保存圖層";
L["Save Layers Tooltip"] = "自動截取6張截圖以供後期合成使用。\n在此過程中請不要移動鼠標或點擊任何按鈕，否則在退出模組後妳的角色可能變為不可見。如果發生這種情況，請輸入以下指令：\n/console showplayer";
L["Ground Shadow"] = "模擬地面陰影";
L["Ground Shadow Tooltip"] = "為妳的模組下方添加壹個可調整的陰影。";
L["Hide Player"] = "隱藏玩家自身";
L["Hide Player Tooltip"] = "讓妳的角色變為不可見。";
L["Virtual Actor"] = "虛擬角色";
L["Virtual Actor Tooltip"] = "只有法術效果可見";
L["Self"] = "自身";
L["Target"] = "目標";
L["Compact Mode Tooltip"] = "僅用屏幕左側來展示妳的幻化。";
L["Toggle Equipment Slots"] = "顯示裝備欄";
L["Toggle Text Mask"] = "文字蒙版";
L["Toggle 3D Model"] = "顯示3D模組";
L["Toggle Model Mask"] = "模組蒙版";
L["Show Color Sliders"] = "顯示色彩滑桿";
L["Show Color Presets"] = "顯示色彩預設";
L["Show More options"] = "顯示更多選項";
L["Show Less Options"] = "隱藏更多選項";
L["Shadow"] = "陰影";
L["Light Source"] = "光源";
L["Light Source Independent"] = "獨立";
L["Light Source Interconnected"] = "關聯";

--Animation Browser--
L["Animation"] = "角色動畫";
L["Animation Tooltip"] = "瀏覽和搜索動畫";
L["Animation Variation"] = "子類型";
L["Reset Slider"] = "重置為零";

--Spell Visual Browser--
L["Visuals"] = "法術效果";
L["Visual ID"] = "效果ID";
L["Animation ID Abbre"] = "動畫ID";
L["Category"] = "類別";
L["Sub-category"] = "子類別";
L["My Favorites"] = "收藏夾";
L["Reset Visual Tooltip"] = "移除未應用的效果";
L["Remove Visual Tooltip"] = "左鍵：移除選中的效果\n長按：移除所有效果";
L["Apply"] = "應用";
L["Applied"] = "已應用";
L["Remove"] = "刪除";
L["Rename"] = "重命名";
L["Refresh Model"] = "重載模組";
L["Toggle Browser"] = "效果瀏覽器";
L["Next And Previous"] = "左鍵：下壹個\n右鍵：上壹個";
L["New Favorite"] = "新的收藏";
L["Favorites Add"] = "添加到收藏夾";
L["Favorites Remove"] = "從收藏夾中移除";
L["Auto-play"] = "Auto-play";   --Auto-play suggested animation
L["Auto-play Tooltip"] = "如果存在與選中的效果相關的動畫，自動播放它";
L["Delete Entry Plural"] = "即將刪除%s個條目";
L["Delete Entry Singular"] = "即將刪除%s個條目";
L["History Panel Note"] = "被應用的效果會顯示在這裏";
L["Return"] = "返回";
L["Close"] = "關閉";

--Dressing Room--
L["Favorited"] = "已設為最愛";
L["Unfavorited"] = "已取消最愛";
L["Item List"] = "裝備清單";
L["Use Target Model"] = "使用目標外形";
L["Use Your Model"] = "使用自身外形";
L["Cannot Inspect Target"] = "無法檢視目標";
L["External Link"] = "外部鏈接";
L["Add to MogIt Wishlist"] = "加入MogIt願望清單";
L["Show Taint Solution"] = "如何避免此問題？";
L["Taint Solution Step1"] = "1.重新載入介面。";
L["Taint Solution Step2"] = "2."..NARCI_MODIFIER_CONTROL.."+左鍵點擊物品來打開試衣間。";

--NPC Browser--
NARCI_NPC_BROWSER_TITLE_LEVEL = ".*%?%?.?";      --Level ?? --Use this to check if the second line of the tooltip is NPC's title or unit type
L["NPC Browser"] = "NPC瀏覽器";
L["NPC Browser Tooltip"] = "在列表中選擇壹個人物並加入到當前場景。";
L["Search for NPC"] = "查找人物";
L["Name or ID"] = "姓名或ID";
L["NPC Has Weapons"] = "包含獨特武器";
L["Retrieving NPC Info"] = "正在獲取NPC信息";
L["Loading Database"] = "數據庫加載中...\n遊戲畫面可能會靜止幾秒鐘。";
L["Other Last Name Format"] = "其他"..NARCI_COLOR_GREY_70.." %s(s)|r:\n";
L["Too Many Matches Format"] = "\n超過%s個結果";

--Equipment Comparison--
L["Azerite Powers"] = "艾澤萊晶岩之力"
L["Gem Tooltip Format1"] = "%s和%s";
L["Gem Tooltip Format2"] = "%s、%s和另外%s種...";

--Equipment Set Manager
L["Toggle Equipment Set Manager"] = "點擊以打開/關閉裝備管理員";
L["Low Item Level"] = "物品等级過低";
L["1 Missing Item"] = "缺少1件物品";
L["n Missing Items"] = "缺少%s件物品";
L["Update Items"] = "更新裝備";
L["Don't Update Items"] = "不要更新裝備";
L["Update Talents"] = "更新天賦";
L["Don't Update Talents"] = "不要更新天賦";
L["Old Icon"] = "舊圖示";
L["NavBar Saved Sets"] = "已保存";
L["NavBar Incomplete Sets"] = "不完整";
L["Icon Selector"] = "圖示清單";
L["Delete Equipment Set Tooltip"] = "刪除此套裝\n|cff808080(按住左鍵)|r";

--Corruption System
L["Corruption System"] = "腐化裝備";
L["Eye Color"] = "眼睛顏色";
L["Blizzard UI"] = "原生界面";
L["Corruption Bar"] = "腐化條";
L["Corruption Bar Description"] = "在角色資訊旁邊顯示腐化程度條。";
L["Corruption Debuff Tooltip"] = "Debuff提示";
L["Corruption Debuff Tooltip Description"] = "將默認的描述性的Debuff提示替換為數值型提示。";
L["No Corrupted Item"] = "妳沒有裝備任何腐化物品。";

L["Crit Gained"] = CRIT_ABBR.."獲取";
L["Haste Gained"] = STAT_HASTE.."獲取";
L["Mastery Gained"] = STAT_MASTERY.."獲取";
L["Versatility Gained"] = STAT_VERSATILITY.."獲取";

L["Proc Crit"] = "觸發"..CRIT_ABBR;
L["Proc Haste"] = "觸發"..STAT_HASTE;
L["Proc Mastery"] = "觸發"..STAT_MASTERY;
L["Proc Versatility"] = "觸發"..STAT_VERSATILITY;

L["Critical Damage"] = "致命傷害";

L["Corruption Effect Format1"] = "|cffffffff%s%%|r 移動速度降低";
L["Corruption Effect Format2"] = "|cffffffff%s|r 初始傷害\n|cffffffff%s 碼|r 半徑";
L["Corruption Effect Format3"] = "|cffffffff%s|r 傷害\n|cffffffff%s%%|r 生命力上限";
L["Corruption Effect Format4"] = "被異界之物擊中會立刻觸發其余負面效果";
L["Corruption Effect Format5"] = "|cffffffff%s%%|r 受到的傷害和治療改變";

--Text Overlay Frame
L["Text Overlay Button Tooltip1"] = "簡易聊天氣泡";
L["Text Overlay Button Tooltip2"] = "進階聊天氣泡";
L["Text Overlay Button Tooltip3"] = "Talking Head";
L["Text Overlay Button Tooltip4"] = "懸浮字幕";
L["Text Overlay Button Tooltip5"] = "黑條字幕";
L["Visibility"] = "可見性";

--Achievement Frame--
L["Use Achivement Panel"] = "設為首選成就面板";
L["Use Achivement Panel Description"] = "替代默認成就彈窗。點擊正在追蹤的成就來打開此面板。";
L["Incomplete First"] = "未完成在前";
L["Earned First"] = "已完成在前";
L["Settings"] = "設置";
L["Next Prev Card"] = "前壹項/後壹項";
L["Track"] = "追蹤";   --Track achievements
L["Show Unearned Mark"] = "顯示未獲取符號";
L["Show Unearned Mark Description"] = "用紅叉標記不是由當前角色獲得的成就。";
L["Show Dates"] = "顯示日期";
L["Hide Dates"] = "隱藏日期";


--Barbershop--
L["Save New Look"] = "保存外觀";
L["No Available Slot"] = "保存欄位已滿";
L["Look Saved"] = "已保存";
L["Cannot Save Forms"] = "不支持形態";
L["Profile"] = "存檔管理";
L["Save Notify"] = "提示妳保存新外觀";
L["Show Randomize Button"] = "顯示隨機外觀按鈕";
L["Coins Spent"] = "支出";
L["Locations"] = "地點";
L["Location"] = "地點";
L["Visits"] = "訪問次數";
L["Duration"] = "時長";
L["Edit Name"] = "修改名稱";
L["Delete Look"] = "按住刪除";

--Tutorial--
L["Alert"] = "警告";
L["Race Change"] = "種族/性別變更";
L["Race Change Line1"] = "妳又可以改變妳的種族和性別了。但是此功能存在壹些限制：\n1. 妳的武器會消失。\n2. 法術效果不再能被移除。\n3. 此操作對其他玩家或NPC無效。";
L["Guide Spell Headline"] = "試用和應用";
L["Guide Spell Criteria1"] = "單擊左鍵：試用";
L["Guide Spell Criteria2"] = "單擊右鍵：應用";
L["Guide Spell Line1"] = "大多數通過左鍵添加的效果會在幾秒內自行消失，而通過右鍵添加的效果會壹直保留在模組上。\n\n現在請將鼠標移到壹個條目上：";
L["Guide Spell Choose Category"] = "選擇壹個妳感興趣的類別，隨後展開壹個子類別。"
L["Guide History Headline"] = "歷史記錄面板";
L["Guide History Line1"] = "至多5個被應用的效果會出現在這裏。妳可以選中壹個，然後按右端的刪除按鈕將它移除。";
L["Guide Refresh Line1"] = "點擊此按鈕可以移除所有未被應用的效果。儲存在妳歷史記錄面板中的效果會被重新應用。";
L["Guide Input Headline"] = "自行輸入";
L["Guide Input Line1"] = "妳也可以自行輸入SpellVisualKitID。截至9.0版本，這個ID的上限約為155,000。\n妳可以用鼠標滾輪來快速預覽上/下壹個ID。\n有極少的ID可能會導致遊戲報錯。";
L["Guide Equipment Manager Line1"] = "雙擊：使用套裝\n右擊：編輯套裝";
L["Guide Model Control Headline"] = "模組控制";
L["Guide Model Control Line1"] = format("妳可以用控制試衣間的鼠標行為來控制此模組。此外，妳還可以：\n\n1.按住%s和鼠標左鍵來改變俯仰角。\n2.按住%s和鼠標右鍵來進行細微縮放。", NARCI_MODIFIER_ALT, NARCI_MODIFIER_ALT);
L["Guide Minimap Button Headline"] = "小地圖按鈕";
L["Guide Minimap Button Line1"] = "此按鈕現在可以被其他模組控制。\n妳可以在偏好設定中更改這壹選項，改動可能需要重載界面才能生效。";

--Others need to be localized--
L["Level"] = "等級";
L["Resource"] = "能量";
L["Camera has been reset."] = "鏡頭已經重置。"
L["Minimap button has been hidden. You may type /Narci minimap to re-enable it."] = "小地圖按鈕已經隱藏，可以輸入 /Narci minimap 來重新啟用。"
L["Minimap button has been re-enabled."] = "小地圖按鈕已經重新啟用。"

--Splash--
L["Splash Whats New Format"] = "Narcissus %s ".."更新内容";
L["Splash Category1"] = "照片模式";
L["Splash Content1 Name"] = "添加文字";
L["Splash Content1 Description"] = "-妳可以在合影模式中創建聊天氣泡，talking heads和字幕。";
L["Splash Content2 Name"] = "動畫面板";
L["Splash Content2 Description"] = "-妳可以搜索和收藏動畫ID。\n-有些動畫ID包含多種動作,現在妳也可以進行選擇了。";
L["Splash Content3 Name"] = "地面陰影";
L["Splash Content3 Description"] = "-新增加了壹種放射狀陰影，它在某些場景下會更加真實。";
L["Splash Category2"] = "理發店";
L["Splash Content4 Name"] = "理發店增強";
L["Splash Content4 Description"] = "-妳可以保存外觀。\n-每個角色擁有20個保存欄位(男女各10個)。\n-壹些統計功能？";
L["Splash Category3"] = "成就";
L["Splash Content5 Name"] = "成就面板";
L["Splash Content5 Description"] = "-獨立的成就面板。\n-可以方便地在相關成就間切換。\n-左鍵拖拽壹項成就即可生成壹張懸浮的成就卡片。\n-更加流暢，更少卡頓。";
L["Splash Category4"] = "其他";
L["Splash Content6 Name"] = "鏡頭運動";
L["Splash Content6 Description"] = "-在妳遊戲期間第二次使用Narcissus角色面板時，鏡頭會瞬間移動到預設位置。";
L["Splash Content7 Name"] = "最佳畫質";
L["Splash Content7 Description"] = "如果妳的系統支持的話，妳可以壹鍵將光線追蹤陰影暫時調制最佳。";
L["Splash Content8 Name"] = "小地圖按鈕";
L["Splash Content8 Description"] = "按住Shift並拖動此按鈕可使其脫離小地圖。";

--Project Details--
L["AboutTab Developer Note"] = "感謝妳使用此模組！如果妳遇到任何問題，或者有任何想法或建議，請在CurseForge項目主頁上留言，或者在以下網站上聯系我。";

--Conversation--
L["Q1"] = "這是什麽？";
L["Q2"] = "這我知道。但是它為什麽這麽大？";
L["Q3"] = "這不好笑。我只想要個正常大小的提示。";
L["Q4"] = "很好。但我該怎麽禁用這個提示呢？";
L["Q5"] = "還有壹件事：妳能保證不再搞惡作劇了嗎？";
L["A1"] = "顯然這是壹個退出確認窗口。當妳嘗試按下快捷鍵來退出合影模式時它就會彈出來。";
L["A2"] = "哈哈哈，她也是這麽說的。";
L["A3"] = "好吧...好吧..."
L["A4"] = "打開偏好設定，然後選擇拍照模式標簽，妳就能看到這個選項啦。";

--Search--
L["Search Result Singular"] = "%s結果";
L["Search Result Plural"] = "%s个結果";
L["Search Result Overflow"] = "超過%s個結果";

--Weapon Browser--
L["Draw Weapon"] = "握住武器";
L["Unequip Item"] = "卸下武器";


--Pet Stables--
L["PetStable Tooltip"] = "從獸欄中選擇寵物。";
L["PetStable Loading"] = "正在獲取寵物信息";

--Domination Item--
L["Item Bonus"] = "獎勵：";
L["Combat Error"] = NARCI_COLOR_RED_MILD.."此操作無法在戰鬥中進行".."|r";
L["Extract Shard"] = "取下統御裂片";
L["No Service"] = "沒有服務";
L["Shards Disabled"] = "統御裂片在淵喉之外的地區無效。";

--Mythic+ Leaderboard--
L["Mythic Plus"] = "傳奇地城";
L["Mythic Plus Abbrev"] = "傳奇地城";
L["Total Runs"] = "完成次數：";
L["Complete In Time"] = "限時";
L["Complete Over Time"] = "超時";
L["Runs"] = "分佈圖";

--Equipment Upgrade--
L["Temp Enchant"] = "暫時性附魔";
L["Owned"] = "擁有的";                       --Only show owned items
L["At Level"] = "在%d級時:";                 --Enchants scale with player level
L["No Item Alert"] = "沒有相容的物品";
L["Click to Insert"] = "左鍵進行鑲嵌";       --Insert a gem
L["No Socket"] = "沒有插槽";
L["No Other Item For Slot"] = "没用其他的%s装备";       --where %s is the slot name
L["In Bags"] = "背包中";

--Statistics--
S["Narcissus Played"] = "Narcissus使用時長";
S["Format Since"] = "(自%s以來)";
S["Screenshots"] = "使用Narcissus擷圖";

--Turntable Showcase--
L["Turntable"] = "轉台";
L["Picture"] = "圖像";
L["Elapse"] = "時間軸"
L["Turntable Tab Animation"] = "人物動作";
L["Turntable Tab Image"] = "圖像參數";
L["Turntable Tab Quality"] = "反鋸齒";
L["Turntable Tab Background"] = "背景";
L["Spin"] = "旋轉";
L["Sync"] = "與試衣間同步";
L["Rotation Period"] = "旋轉周期";
L["Period Tooltip"] = "角色旋轉一周所用的時間，也應成爲你視頻或動圖的|cffcccccc截取時長|r。";
L["MSAA Tooltip"] = "暫時調整多重採樣反鋸齒等級來平滑模型邊緣。";
L["Image Size"] = "圖像大小";
L["Item Name Show"] = "顯示物品名稱";
L["Item Name Hide"] = "隱藏物品名稱";
L["Outline Show"] = "點擊顯示輔助邊框";
L["Outline Hide"] = "點擊隱藏輔助邊框";
L["Preset"] = "預設";
L["File"] = "文件";     --File Name
L["File Tooltip"] = "把你的圖像文件放在|cffccccccWorld of Warcraft\\retail\\Interface\\AddOns|r目錄下，然後將文件名填入此方框。\n圖像必須爲|cffcccccc512x512|r或|cffcccccc1024x1024|r的|cffccccccJPG|r文件";
L["Raise Level"] = "置于頂層";
L["Lower Level"] = "取消置頂";
L["Show Mount"] = "顯示坐騎";
L["Hide Mount"] = "隱藏坐騎";
L["Click To Continue"] = "點擊以繼續";
L["Showcase Splash 1"] = "使用Narcissus和錄屏軟件來制作轉台動畫以展示你的塑形。";
L["Showcase Splash 2"] = "點擊下方按鈕來複制試衣間中的物品。";
L["Showcase Splash 3"] = "點擊下方按鈕可讓你的角色旋轉起來。";
L["Showcase Splash 4"] = "錄制屏幕然後將視頻轉換爲GIF動圖。";

--Item Sets--
L["Cycle Spec"] = "按Tab键切换专精";
L["Paperdoll Splash 1"] = "使用套装指示器？";
L["Paperdoll Splash 2"] = "选择主题色";

--Outfit Select--
L["Models"] = "模組";
L["Origin Outfits"] = "原始造型";
L["Outfit Owner Format"] = "%s的造型";
L["SortMethod Recent"] = "近期登錄";
L["SortMethod Name"] = "角色姓名";