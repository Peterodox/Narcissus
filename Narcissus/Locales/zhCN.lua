if not (GetLocale() == "zhCN") then
    return
end

local L = Narci.L;
local S = Narci.L.S;

NARCI_WORDBREAK_COMMA = "，";

--Date--
L["Today"] = COMMUNITIES_CHAT_FRAME_TODAY_NOTIFICATION;
L["Yesterday"] = COMMUNITIES_CHAT_FRAME_YESTERDAY_NOTIFICATION;
L["Format Days Ago"] = "%d天前";
L["A Month Ago"] = "1个月前";
L["Format Months Ago"] = "%d个月前";
L["A Year Ago"] = "1年前";
L["Format Years Ago"] = "%d年前";
L["Date Colon"] = "日期: ";
L["Day Plural"] = "天";
L["Day Singular"] = "天";
L["Hour Plural"] = "小时";
L["Hour Singular"] = "小时";

L["Swap items"] = "更换装备";
L["Movement Speed"] = STAT_MOVEMENT_SPEED;
L["Damage Reduction Percentage"] = COMBAT_TEXT_SHOW_RESISTANCES_TEXT;

L["Advanced Info"] = "点击以显示更详细的装备、属性信息";
L["Restore On Exit"] = "你先前的设置会在退出后自动恢复。"
L["Photo Mode"] = "照片模式";
L["Photo Mode Tooltip Open"] = "点击以打开截图工具箱";
L["Photo Mode Tooltip Close"] = "点击以关闭截图工具箱";
L["Photo Mode Tooltip Special"] = "此控件不会出现在你(魔兽安装目录Screenshots文件夹内)的游戏截图里";

L["Toolbar Mog Button"] = "照相模式";
L["Toolbar Mog Button Tooltip"] = "展示的你幻化。或创建一个场景并添加其他玩家或NPC的模型。";

L["Toolbar Emote Button"] = "快捷表情";
L["Toolbar Emote Button Tooltip"] = "播放具有独特动画效果的表情。";
L["Auto Capture"] = "自动截图";

L["Toolbar HideTexts Button"] = "隐藏文本";
L["Toolbar HideTexts Button Tooltip"] = "隐藏所有姓名、聊天气泡和战斗文字。" ..L["Restore On Exit"];

L["Toolbar TopQuality Button"] = "最佳画质";
L["Toolbar TopQuality Button Tooltip"] = "将画面设置中的所有选项都调至极佳" ..L["Restore On Exit"];

L["Toolbar Location Button"] = "位置信息";
L["Toolbar Location Button Tooltip"] = "显示当前区域名称和你的坐标。"

L["Toolbar Camera Button"] = "相机";
L["Toolbar Camera Button Tooltip"] = "暂时修改相机参数。"

L["Toolbar Preferences Button Tooltip"] = "打开偏好设定。";

L["Heritage Armor"] = "传承护甲";
L["Secret Finding"] = "解密活动";

L["Heart Azerite Quote"] = "最本质的东西，是无法用肉眼看见的";

--Title Manager--
L["Open Title Manager"] = "展开头衔列表";
L["Close Title Manager"] = "收起头衔列表";

--Alias--
L["Use Alias"] = "使用化名";
L["Use Player Name"] = "使用本名";

L["Minimap Tooltip Double Click"] = "双击";
L["Minimap Tooltip Left Click"] = "左键|r";
L["Minimap Tooltip To Open"] = "|cffffffff打开装备界面";
L["Minimap Tooltip Module Panel"] = "|cffffffff显示组件面板";
L["Minimap Tooltip Right Click"] = "右键";
L["Minimap Tooltip Shift Left Click"] = "Shift + 左键";
L["Minimap Tooltip Shift Right Click"] = "Shift + 右键";
L["Minimap Tooltip Hide Button"] = "隐藏此按钮"
L["Minimap Tooltip Middle Button"] = "|CFFFF1000中键 |cffffffff重置摄像机参数";
L["Minimap Tooltip Set Scale"] = "设置缩放: |cffffffff/narci [有效范围 0.8~1.2]";
L["MinimapButton Enable Instruction"] = "|cffffd100已隐藏Narcissus小地图按钮。你可以输入以下命令来重新启用它：|r |cffffffff/narci minimap|r";
L["MinimapButton Reenabled"] = "|cffffd100你已启用Narcissus小地图按钮。|r";
L["MinimapButton LibDBIcon"] = "使用LibDBIcon";
L["MinimapButton LibDBIcon Desc"] = "使用LibDBIcon来创建小地图按钮。\n你可以看见此选项因为你已安装LibDBIcon或植入了这个库的插件。";
L["MinimapButton LibDBIcon Hide"] = "隐藏按钮";
L["Corrupted Item Parser"] = "|cffffffff打开腐蚀物品链接解析器|r";
L["Toggle Dressing Room"] = "|cffffffff打开试衣间|r";
L["Reset Camera"] = "重置摄像机参数";
L["Character UI"] = "角色界面";
L["Module Menu"] = "模块菜单";

L["Layout"] = "布局";
L["Symmetry"] = "对称";
L["Asymmetry"] = "非对称";
L["Copy Texts"] = "复制文本";
L["Syntax"] = "语法";
L["Plain Text"] = "纯文本";
L["BB Code"] = "BB Code";
L["Markdown"] = "Markdown";
L["Export Includes"] = "在导出中包含...";

L["3D Model"] = "3D模型";
L["Equipment Slots"] = "装备栏位";

--偏好设定--
L["Interface"] = "界面";
L["Themes"] = "主题";
L["Camera"] = "镜头";
L["Effects"] = "效果";
L["Transmog"] = "幻化";
L["Extensions"] = "拓展功能";
L["Credits"] = "致谢";
L["About"] = "关于"
L["Preferences"] = "偏好设定";
L["Preferences Tooltip"] = "打开偏好设定。";
L["Truncate Text"] = "截断文字";
L["Stat Sheet"] = "属性栏";
L["Show Detailed Stats"] = "显示更多属性";
L["Text Width"] = "文本宽度";
L["Hotkey"] = "快捷键";
L["Double Tap"] = "启用双击";
L["Double Tap Description"] = "连按两下打开角色面板的快捷键来打开此插件。"
L["Override"] = "是否覆盖";
L["Invalid Key"] = "无效的组合键";
L["Minimap Button"] = "小地图按钮";
L["Show Minimap Button"] = "显示小地图按钮";
L["Add To AddOn Compartment"] = "加入到插件数字按钮里";
L["Shortcuts"] = "快捷方式";
L["Image Filter"] = "滤镜";
L["Image Filter Description"] = "除暗角以外的所有滤镜都会在幻化模式被暂时禁用。";
L["Grain Effect"] = "颗粒效果";
L["Camera Movement"] = "镜头运动";
L["Orbit Camera"] = "环绕镜头";
L["Orbit Camera Description On"] = "当你打开此插件时，镜头会自动旋转到角色面前并开始环绕。";
L["Orbit Camera Description Off"] = "当你打开此插件时，镜头只会被拉近不会有任何旋转。";
L["Camera Safe Mode"] = "镜头安全模式";
L["Camera Safe Mode Description"] = "在关闭此插件后彻底关闭ActionCam功能。";
L["Camera Safe Mode Description Extra"] = "已禁用因为你正在使用DynamicCam插件。";
L["Fade Out"] = "淡化图标";
L["Fade Out Description"] = "在你将鼠标从小地图按钮上移出后，降低其透明度。";
L["Fade Music"] = "淡入/淡出音乐";
L["Vignette Strength"] = "暗角强度";
L["Weather Effect"] = "天气效果";
L["Letterbox"] = "宽荧幕效果";
L["Letterbox Ratio"] = "宽高比";
L["Letterbox Alert1"] = "你屏幕的宽高比超过了所选比例。";
L["Letterbox Alert2"] = "建议将UI缩放比设置为%0.1f\n(当前缩放比为%0.1f)";
L["Default Layout"] = "默认布局";
L["Transmog Layout1"] = "对称，显示人物";
L["Transmog Layout2"] = "人物及模型";
L["Transmog Layout3"] = "紧凑模式";
L["Border Theme Header"] = "边框主题";
L["Border Theme Bright"] = "明亮";
L["Border Theme Dark"] = "灰暗";
L["Always Show Model"] = "在使用对称布局时显示3D模型";
L["AFK Screen Description"] = "在你的人物暂离后自动打开Narcissus。";
L["AFK Screen Description Extra"] = "勾选此选项将覆盖ElvUI的AFK模式。";
L["AFK Screen Delay"] = "在倒计时结束后打开";
L["Item Names"] = "装备名字";
L["Open Narcissus"] = "Narcissus角色界面";
L["Character Panel"] = "角色界面";
L["Screen Effects"] ="屏幕效果";

L["Gemma"] = "\"Gemma\"";
L["Gemma Description"] = "在你为一件物品镶嵌宝石时，显示可用的宝石列表。"
L["Gem Manager"] = "宝石助手";
L["Dressing Room"] = "试衣间"
L["Dressing Room Description"] = "增大试衣间窗口大小，并使你能够通过试衣间浏览、复制其他玩家的幻化调料包。";
L["Show Detailed Stats"] = "显示详尽的属性信息";
L["Tooltip Color"] = "小提示颜色";
L["Entrance Visual"] = "登场效果";
L["Entrance Visual Description"] = "在模型登场时播放法术效果。";
L["Panel Scale"] = "面板缩放";
L["Exit Confirmation"] = "退出确认";
L["Exit Confirmation Texts"] = "退出合影模式？";
L["Exit Confirmation Leave"] = "退出";
L["Exit Confirmation Cancel"] = "取消";
L["Ultra-wide"] = "超宽屏";
L["Ultra-wide Optimization"] = "超宽屏优化";
L["Baseline Offset"] = "基准线偏移";
L["Ultra-wide Tooltip"] = "你能看到此选项是因为你正在使用一台%s:9显示器。";
L["Interactive Area"] = "交互区域";
L["Use Bust Shot"] = "使用半身像";
L["Use Escape Button"] = "按下|cffffdd10(Esc)|r键来退出角色界面。";
L["Use Escape Button Description"] = "你也可以点击隐藏在屏幕右上角的X按钮来退出。";
L["Show Module Panel Gesture"] = "鼠标悬停时显示模块菜单";
L["Independent Minimap Button"] = "不受其他插件控制";
L["AFK Screen"] = "AFK画面";
L["Keep Standing"] = "保持站立";
L["Keep Standing Description"] = "当你AFK后定时使用/站立表情。此选项不会中断自动登出。"
L["None"] = "无";
L["NPC"] = "NPC";
L["Database"] = "数据库";
L["Creature Tooltip"] = "生物信息";
L["RAM Usage"] = "内存占用";
L["Others"] = "其它";
L["Find Relatives"] = "查找相关生物";
L["Find Related Creatures Description"] = "找到与目标同姓的其他生物。";
L["Find Relatives Hotkey"] = "按Tab搜索相关生物。";
L["Find Relatives Hotkey Format"] = "按下%s开始查找。";
L["Translate Names"] = "翻译姓名";
L["Translate Names Description"] = "获取目标译名并将其显示在...";
L["Translate Names Languages"] = "翻译为...";
L["Select Language Single"] = "选择一种语言显示在姓名版上";
L["Select Language Multiple"] = "选择显示在鼠标提示上的语言";
L["Load on Demand"] = "按需加载";
L["Load on Demand Description On"] = "在搜索功能被调用时再加载数据库。";
L["Load on Demand Description Off"] = "数据库将在你登入时加载。";
L["Load on Demand Description Disabled"] = NARCI_COLOR_YELLOW.. "这一选项被锁住了，因为你选择显示生物信息。";
L["Tooltip"] = "鼠标提示";
L["Name Plate"] = "姓名板";
L["Y Offset"] = "纵向偏移";
L["Sceenshot Quality"] = "截图质量";
L["Screenshot Quality Description"] = "提高截图质量会增加文件大小。";
L["General"] = "通用设置";
L["Camera Transition"] = "镜头过渡";
L["Camera Transition Description On"] = "当你打开角色面板时镜头会平滑地运动到预设位置。";
L["Camera Transition Description Off"] = "镜头转换变为瞬时。此效果将在你第二次使用角色面板时开始生效。\n此效果会占用镜头预设#4。";
L["Interface Options Tab Description"] = "你也可以点击位于屏幕左下角Narcissus工具栏右端的小齿轮按钮来打开偏好设置。";
L["Conduit Tooltip"] = "显示更高级别的导灵器效果";
L["Paperdoll Widget"] = "角色界面小部件";
L["Item Tooltip"] = "鼠标提示";
L["Style"] = "风格";
L["Tooltip Style 1"] = "下一代";
L["Tooltip Style 2"] = "经典";
L["Addtional Info"] = "额外信息";
L["Item ID"] = "物品ID";
L["Camera Reset Notification"] = "镜头水平偏移已重置为零。如果你想关闭这个功能，请打开“设置-镜头”然后关闭“镜头安全模式”。";
L["Binding Name Open Narcissus"] = "Narcissus角色面板";
L["Developer Colon"] = "开发者: ";
L["Project Page"] = "项目主页";
L["Press Copy Yellow"] = "按下|cffffd100".. NARCI_SHORTCUTS_COPY .."|r复制";
L["New Option"] = NARCI_NEW_ENTRY_PREFIX.." 新".."|r"
L["Expansion Features"] = "资料片特色";
L["LFR Wing Details"] = "随机难度团本区域信息";
L["LFR Wing Details Description"] = "在你单排随机难度的旧团本时，显示boss名称和进度情况。";
L["Speedy Screenshot Alert"] = "让截图成功通知更快地消失";

--模型控制面板--
L["Ranged Weapon"] = "远程武器";
L["Melee Animation"] = "近战武器";
L["Spellcasting"] = "施法动作";
L["Link Light Sources"] = "关联灯光设置";
L["Link Model Scales"] = "关联模型比例";
L["Hidden"] = "隐藏";
L["Light Types"] = "平行光/环境光";
L["Light Types Tooltip"] = "在以下两种灯光间切换：\n- 可以被模型遮挡并投射阴影的平行光\n- 影响整个模型表面的环境光";

L["Group Photo"] = "合影模式";
L["Reset"] = "重置";
L["Actor Index"] = "序号";
L["Move To Font"] = "|cff40c7eb顶层|r";
L["Actor Index Tooltip"] = "拖动一个序号按钮来改变其模型的层级。";
L["Play Button Tooltip"] = "左键：播放此动画\n右键：恢复所有模型的动画";
L["Pause Button Tooltip"] = "左键：定格此动画\n右键：暂停所有模型的动画";
L["Save Layers"] = "保存图层";
L["Save Layers Tooltip"] = "自动截取6张截图以供后期合成使用。\n在此过程中请不要移动鼠标或点击任何按钮，否则在退出插件后你的角色可能变为不可见。如果发生这种情况，请输入以下指令：\n/console showplayer";
L["Ground Shadow"] = "模拟地面阴影";
L["Ground Shadow Tooltip"] = "为你的模型下方添加一个可调整的阴影。";
L["Hide Player"] = "隐藏玩家自身";
L["Hide Player Tooltip"] = "让你的角色变为不可见。";
L["Virtual Actor"] = "虚拟角色";
L["Virtual Actor Tooltip"] = "只有法术效果可见";
L["Self"] = "自身";
L["Target"] = "目标";
L["Compact Mode Tooltip"] = "仅用屏幕左侧来展示你的幻化。";
L["Toggle Equipment Slots"] = "显示装备栏";
L["Toggle Text Mask"] = "文字蒙版";
L["Toggle 3D Model"] = "显示3D模型";
L["Toggle Model Mask"] = "模型蒙版";
L["Show Color Sliders"] = "显示色彩滑杆";
L["Show Color Presets"] = "显示色彩预设";
L["Keep Current Form"] = "按住"..NARCI_MODIFIER_ALT.."以保持变身形态";
L["Race Change Tooltip"] = "改变种族";
L["Sex Change Tooltip"] = "改变性别";
L["Show More options"] = "显示更多选项";
L["Show Less Options"] = "隐藏更多选项";
L["Shadow"] = "阴影";
L["Light Source"] = "光源";
L["Light Source Independent"] = "独立";
L["Light Source Interconnected"] = "关联";
L["Adjustment"] = "调整";

--Animation Browser--
L["Animation"] = "角色动画";
L["Animation Tooltip"] = "浏览和搜索动画";
L["Animation Variation"] = "子类型";
L["Reset Slider"] = "重置为零";
L["Available Count"] = "%d个可用";

--Spell Visual Browser--
L["Visuals"] = "法术效果";
L["Visual ID"] = "效果ID";
L["Animation ID Abbre"] = "动画ID";
L["Category"] = "类别";
L["Sub-category"] = "子类别";
L["My Favorites"] = "收藏夹";
L["Reset Visual Tooltip"] = "移除未应用的效果";
L["Remove Visual Tooltip"] = "左键：移除选中的效果\n长按：移除所有效果";
L["Apply"] = "应用";
L["Applied"] = "已应用";
L["Remove"] = "删除";
L["Rename"] = "重命名";
L["Refresh Model"] = "重载模型";
L["Toggle Browser"] = "效果浏览器";
L["Next And Previous"] = "左键：下一个\n右键：上一个";
L["New Favorite"] = "新的收藏";
L["Favorites Add"] = "添加到收藏夹";
L["Favorites Remove"] = "从收藏夹中移除";
L["Auto-play"] = "自动播放";   --Auto-play suggested animation
L["Auto-play Tooltip"] = "如果存在与选中的效果相关的动画，自动播放它";
L["Delete Entry Plural"] = "即将删除%s个条目";
L["Delete Entry Singular"] = "即将删除%s个条目";
L["History Panel Note"] = "被应用的效果会显示在这里";
L["Return"] = "返回";
L["Close"] = "关闭";

--Dressing Room--
L["Undress"] = "脱光";
L["Favorited"] = "已设为偏好";
L["Unfavorited"] = "已取消偏好";
L["Item List"] = "装备清单";
L["Use Target Model"] = "使用目标模型";
L["Use Your Model"] = "使用自身模型";
L["Cannot Inspect Target"] = "无法检视目标";
L["External Link"] = "外部链接";
L["Add to MogIt Wishlist"] = "加入MogIt愿望清单";
L["Show Taint Solution"] = "如何避免此问题？";
L["Taint Solution Step1"] = "1.重载界面。";
L["Taint Solution Step2"] = "2."..NARCI_MODIFIER_CONTROL.."+左键点击物品来打开试衣间。";
L["Switch Form To Visage"] = "切换到|cffffffff幻容|r形态";
L["Switch Form To Dracthyr"] = "切换到|cffffffff龙希尔|r形态";
L["Switch Form To Worgen"] = "切换到|cffffffff狼|r形态";
L["Switch Form To Human"] = "切换到|cffffffff人|r形态";
L["InGame Command"] = "游戏内命令";
L["Hide Player Items"] = "隐藏玩家装备";
L["Hide Player Items Tooltip"] = "移除不属于此套装的装备。";

--NPC Browser--
NARCI_NPC_BROWSER_TITLE_LEVEL = ".*%?%?.?";      --Level ?? --Use this to check if the second line of the tooltip is NPC's title or unit type
L["NPC Browser"] = "NPC浏览器";
L["NPC Browser Tooltip"] = "在列表中选择一个人物并加入到当前场景。";
L["Search for NPC"] = "查找人物";
L["Name or ID"] = "姓名或ID";
L["NPC Has Weapons"] = "包含独特武器";
L["Retrieving NPC Info"] = "正在获取NPC信息";
L["Loading Database"] = "数据库加载中...\n游戏画面可能会静止几秒钟。";
L["Other Last Name Format"] = "其他"..NARCI_COLOR_GREY_70.." %s(s)|r:\n";
L["Too Many Matches Format"] = "\n超过%s个结果";

--装备对比--
L["Azerite Powers"] = "艾泽里特之力";
L["Gem Tooltip Format1"] = "%s和%s";
L["Gem Tooltip Format2"] = "%s、%s和另外%s种...";

--Equipment Set Manager
L["Equipped Item Level Format"] = "已装备%s";
L["Toggle Equipment Set Manager"] = "点击以打开/关闭套装管理器";
L["Duplicated Set"] = "重复的套装";
L["Low Item Level"] = "物品等级过低";
L["1 Missing Item"] = "缺失1件物品";
L["n Missing Items"] = "缺失%s件物品";
L["Update Items"] = "更新装备";
L["Don't Update Items"] = "不要更新装备";
L["Update Talents"] = "更新天赋";
L["Don't Update Talents"] = "不要更新天赋";
L["Old Icon"] = "旧图标";
L["NavBar Saved Sets"] = "已保存";
L["NavBar Incomplete Sets"] = "不完整";
L["Icon Selector"] = "图标列表";
L["Delete Equipment Set Tooltip"] = "删除此套装\n|cff808080(按住左键)|r";

--Corruption System
L["Corruption System"] = "腐蚀模块";
L["Eye Color"] = "眼睛顏色";
L["Blizzard UI"] = "原生界面";
L["Corruption Bar"] = "腐蚀条";
L["Corruption Bar Description"] = "在角色信息旁边显示腐蚀条。";
L["Corruption Debuff Tooltip"] = "Debuff提示";
L["Corruption Debuff Tooltip Description"] = "将默认的描述性的Debuff提示替换为数值型提示。";
L["No Corrupted Item"] = "你没有装备任何腐蚀物品。";

L["Crit Gained"] = "爆击获取";
L["Haste Gained"] = STAT_HASTE.."获取";
L["Mastery Gained"] = STAT_MASTERY.."获取";
L["Versatility Gained"] = STAT_VERSATILITY.."获取";

L["Proc Crit"] = "触发"..CRIT_ABBR;
L["Proc Haste"] = "触发"..STAT_HASTE;
L["Proc Mastery"] = "触发"..STAT_MASTERY;
L["Proc Versatility"] = "触发"..STAT_VERSATILITY;

L["Critical Damage"] = "爆击伤害";

L["Corruption Effect Format1"] = "|cffffffff%s%%|r 移动速度降低";
L["Corruption Effect Format2"] = "|cffffffff%s|r 初始伤害\n|cffffffff%s 码|r 半径";
L["Corruption Effect Format3"] = "|cffffffff%s|r 伤害\n|cffffffff%s%%|r 最大生命值";
L["Corruption Effect Format4"] = "被彼岸之物击中会立刻触发其余效果";
L["Corruption Effect Format5"] = "|cffffffff%s%%|r 受到的伤害和治疗改变";

--Text Overlay Frame
L["Text Overlay"] = "文字覆盖";
L["Text Overlay Button Tooltip1"] = "简易聊天气泡";
L["Text Overlay Button Tooltip2"] = "高级聊天气泡";
L["Text Overlay Button Tooltip3"] = "Talking Head";
L["Text Overlay Button Tooltip4"] = "悬浮字幕";
L["Text Overlay Button Tooltip5"] = "黑条字幕";
L["Visibility"] = "可见性";
L["Photo Mode Frame"] = "边框";

--Achievement Frame--
L["Use Achievement Panel"] = "设为首选成就面板";
L["Use Achievement Panel Description"] = "替代默认成就弹窗。点击正在追踪的成就来打开此面板。";
L["Incomplete First"] = "未完成在前";
L["Earned First"] = "已完成在前";
L["Settings"] = "设置";
L["Next Prev Card"] = "前项/后项";
L["Track"] = "追踪";   --Track achievements
L["Show Unearned Mark"] = "显示未获取符号";
L["Show Unearned Mark Description"] = "用红叉标记不是由当前角色获得的成就。";
L["Show Dates"] = "显示日期";
L["Hide Dates"] = "隐藏日期";
L["Pinned Entries"] = "置顶条目";
L["Pinned Entry Format"] = "已置顶  %d/%d";
L["Create A New Entry"] = "创建一个新条目";
L["Custom Achievement"] = "自定义成就";
L["Custom Achievement Description"] = "这里是说明。";
L["Custom Achievement Select And Edit"] = "选择右侧的一个条目进行修改";
L["Cancel"] = "取消";
L["Color"] = "颜色";
L["Icon"] = "图标";
L["Description"] = "说明";
L["Points"] = "点数";
L["Reward"] = "奖励";
L["Date"] = "日期";
L["Click And Hold"] = "按住鼠标左键";
L["To Do List"] = "待办事项";
L["Error Alert Bookmarks Too Many"] = "你最多同时选择%s个成就。";
L["Instruction Add To To Do List"] = string.format("%s 左键 点击一个未完成的成就，可把它加入到你的待办事项里。", NARCI_MODIFIER_ALT);
L["Instruction Remove From To Do List"] = string.format("%s 左键点击以从待办事项中移除。", NARCI_MODIFIER_ALT);
L["DIY"] = "DIY";
L["DIY Tab Tooltip"] = "自定义一个成就供截图使用。"
L["Binding Name Open Achievement"] = "Narcissus成就面板";

--Barbershop--
L["Save New Look"] = "保存外观";
L["No Available Slot"] = "保存栏位已满";
L["Look Saved"] = "已保存";
L["Cannot Save Forms"] = "不支持形态";
L["Profile"] = "存档管理";
L["Share"] = "分享";
L["Save Notify"] = "提示你保存新外观";
L["Save Notify Tooltip"] = "在你应用一个套新外观后提示你是否保存。";
L["Show Randomize Button"] = "显示随机外观按钮";
L["Coins Spent"] = "支出";
L["Locations"] = "地点";
L["Location"] = "地点";
L["Visits"] = "访问次数";
L["Duration"] = "时长";
L["Edit Name"] = "修改名称";
L["Delete Look"] = "长按删除";
L["Export"] = "导出";
L["Import"] = "导入";
L["Paste Here"] = "此处粘贴";
L["Press To Copy"] = "按 |cffcccccc".. NARCI_SHORTCUTS_COPY.."|r 复制";
L["String Copied"] = NARCI_COLOR_GREEN_MILD.. "已复制".."|r";
L["Failure Reason Unknown"] = "未知错误";
L["Failure Reason Decode"] = "解码失败";
L["Failure Reason Wrong Character"] = "当前种族，性别或形态与导入的档案不符。";
L["Failure Reason Dragonriding"] = "这是订制巨龙的档案。";
L["Wrong Character Format"] = "需要 %s %s."; --e.g. Rquires Male Human
L["Import Lack Option"] = "有%d|4个类别:个类别;没有找到";
L["Import Lack Choice"] = "有%d|4个选项:个选项;没有找到";
L["Decode Good"] = "解码成功";
L["Barbershop Export Tooltip"] = "用当前外观生成一串可在网上分享的字符串。\n你可以修改冒号前的文字。";
L["Settings And Share"] = "设置与分享";
L["Loading Portraits"] = "生成头像";
L["Private Profile"] = "个人";   --used by the current character
L["Public Profile"] = "共用";     --shared among all your characters
L["No Saves"] = "没有存档";
L["Profile Type Tooltip"] = "选择当前角色所用档案。\n\n个人:|cffedd100 由此角色创建的档案|r\n\n共用:|cffedd100 可被你所有角色共用的档案|r";
L["Profile Migration Okay"] = "好的";
L["Profile Migration CopyButton Tooltip"] = "复制此外观到共用档案";

--Tutorial--
L["Alert"] = "警告";
L["Race Change"] = "种族/性别变更";
L["Race Change Line1"] = "你又可以改变你的种族和性别了。但是此功能存在一些限制：\n1. 你的武器会消失。\n2. 法术效果不再能被移除。\n3. 此操作对其他玩家或NPC无效。";
L["Guide Spell Headline"] = "试用和应用";
L["Guide Spell Criteria1"] = "单击左键：试用";
L["Guide Spell Criteria2"] = "单击右键：应用";
L["Guide Spell Line1"] = "大多数通过左键添加的效果会在几秒内自行消失，而通过右键添加的效果会一直保留在模型上。\n\n现在请将鼠标移到一个条目上：";
L["Guide Spell Choose Category"] = "选择一个你感兴趣的类别，随后展开一个子类别。"
L["Guide History Headline"] = "历史记录面板";
L["Guide History Line1"] = "至多5个被应用的效果会出现在这里。你可以选中一个，然后按右端的删除按钮将它移除。";
L["Guide Refresh Line1"] = "点击此按钮可以移除所有未被应用的效果。储存在你历史记录面板中的效果会被重新应用。";
L["Guide Input Headline"] = "人工输入";
L["Guide Input Line1"] = "你也可以自行输入SpellVisualKitID。截至9.0版本，这个ID的上限约为155,000。\n你可以用鼠标滚轮来快速预览上/下一个ID。\n有极少的ID可能会导致游戏报错。";
L["Guide Equipment Manager Line1"] = "双击：使用套装\n右击：编辑套装";
L["Guide Model Control Headline"] = "模型控制";
L["Guide Model Control Line1"] = format("你可以用控制试衣间的鼠标行为来控制此模型。此外，你还可以：\n\n1.按住%s和鼠标左键来改变俯仰角。\n2.按住%s和鼠标右键来进行细微缩放。", NARCI_MODIFIER_ALT, NARCI_MODIFIER_ALT);
L["Guide Minimap Button Headline"] = "小地图按钮";
L["Guide Minimap Button Line1"] = "此按钮现在可以被其他插件控制。\n你可以在偏好设定中更改这一选项，改动可能需要重载界面才能生效。"

--Splash--
L["Splash Whats New Format"] = "Narcissus %s ".."更新内容";
L["Splash Category1"] = L["Photo Mode"];
L["Splash Content1 Name"] = "武器浏览器";
L["Splash Content1 Description"] = "-浏览并使用所有存在于数据库内（包括那些玩家无法获取）的武器。";
L["Splash Content2 Name"] = "角色选择界面";
L["Splash Content2 Description"] = "-你可以使用装饰性的边框来创建你自己的角色选择界面。";
L["Splash Content3 Name"] = "试衣间";
L["Splash Content3 Description"] = "-对试衣间模块进行了重新设计。\n-幻化调料包现在支持显示不对称的肩部幻化以及武器幻象。";
L["Splash Content4 Name"] = "NPC浏览器";
L["Splash Content4 Description"] = "-内置数据库已更新至9.1，其中包含152,219个NPC。";
L["Splash Category2"] = "装备界面";
L["Splash Content5 Name"] = "统御碎片";
L["Splash Content5 Description"] = "-统御碎片指示器会在你装备相应物品后出现。\n-镶嵌物品的时候会显示你背包中可用的统御碎片。";
L["Splash Content6 Name"] = "灵魂羁绊";
L["Splash Content6 Description"] = "-更新了灵魂羁绊UI。你可以查看更高等级的导灵器效果。";
L["Splash Content7 Name"] = "外观";
L["Splash Content7 Description"] = "-六边形装备边框有了新的外观。特定物品具有独特的皮肤。";

--Project Details--
L["AboutTab Developer Note"] = "感谢你使用此插件！如果你遇到任何问题，或者有任何想法或建议，请在CurseForge项目主页上留言，或者在以下网站上联系我。";

--Conversation--
L["Q1"] = "这是个啥？";
L["Q2"] = "这我知道。但是它为什么这么大？";
L["Q3"] = "这不好笑。我只想要个正常大小的提示。";
L["Q4"] = "很好。但我该怎么禁用这个提示呢？";
L["Q5"] = "还有一件事：你能保证不再搞恶作剧了吗？";
L["A1"] = "显然这是一个退出确认窗口。当你尝试按下快捷键来退出合影模式时它就会弹出来。";
L["A2"] = "哈哈哈，她也是这么说的。";
L["A3"] = "好吧...好吧..."
L["A4"] = "打开偏好设定，然后选择拍照模式标签，你就能看到这个选项啦。";

--Search--
L["Search Result Singular"] = "%s结果";
L["Search Result Plural"] = "%s个结果";
L["Search Result Overflow"] = "超过%s个结果";

--Weapon Browser--
L["Draw Weapon"] = "握住武器";
L["Unequip Item"] = "卸下武器";
L["WeaponBrowser Guide Hotkey"] = "指定用哪只手来握住武器：";
L["WeaponBrowser Guide ModelType"] = "有些武器只能被添加到特定类型的模型上：";
L["WeaponBrowser Guide DressUpModel"] = "当你的目标是玩家时，默认创建此种模型的模型。除非你在点击添加角色的同时按住<%s>键。";
L["WeaponBrowser Guide CinematicModel"] = "当添加的角色是NPC时，模型的类型只能为此种。此种模型不支持收起武器。";

--Pet Stables--
L["PetStable Tooltip"] = "从兽栏中选择宠物。";
L["PetStable Loading"] = "正在获取宠物信息";

--Domination Item--
L["Item Bonus"] = "加成：";
L["Combat Error"] = NARCI_COLOR_RED_MILD.."此操作无法在战斗中进行".."|r";
L["Extract Shard"] = "取下统御碎片";
L["No Service"] = "信号不佳";
L["Shards Disabled"] = "统御碎片在噬渊之外的地区无效。";
L["Unsocket Gem"] = "取下宝石";

--Mythic+ Leaderboard--
L["Mythic Plus"] = "大秘境";
L["Mythic Plus Abbrev"] = "大秘境";
L["Total Runs"] = "完成次数：";
L["Complete In Time"] = "限时";
L["Complete Over Time"] = "超时";
L["Runs"] = "分布图";

--Equipment Upgrade--
L["Temp Enchant"] = "暂时性附魔";
L["Owned"] = "拥有的";
L["At Level"] = "在%d级时:";
L["No Item Alert"] = "没有匹配的物品";
L["Click to Insert"] = "左键点击以镶嵌";
L["No Socket"] = "这件物品不带孔";
L["No Other Item For Slot"] = "没有其他的%s装备";
L["In Bags"] = "背包内";
L["Item Socketing Tooltip"] = "双击左键进行镶嵌";
L["No Available Gem"] = "|cffd8d8d8没有可镶嵌的宝石|r";
L["Missing Enchant Alert"] = "附魔提示";
L["Missing Enchant"] = NARCI_COLOR_RED_MILD.."缺失附魔".."|r";
L["Socket Occupied"] = "插槽已被占用";

--Statistics--
S["Narcissus Played"] = "Narcissus使用时长";
S["Format Since"] = "(自%s以来)";
S["Screenshots"] = "使用Narcissus截图";
S["Shadowlands Quests"] = "暗影界任务";
S["Quest Text Reading Speed Format"] = "已完成: %s (%s个字)  阅读时长: %s (每分钟%s字)";

--Turntable Showcase--
L["Turntable"] = "转台";
L["Picture"] = "图片";
L["Elapse"] = "时间轴"
L["Turntable Tab Animation"] = "人物动作";
L["Turntable Tab Image"] = "图像参数";
L["Turntable Tab Quality"] = "抗锯齿";
L["Turntable Tab Background"] = "背景";
L["Spin"] = "旋转";
L["Sync"] = "与试衣间同步";
L["Rotation Period"] = "旋转周期";
L["Period Tooltip"] = "角色旋转一周所用的时间，也应成为你视频或动图的|cffcccccc截取时长|r。";
L["MSAA Tooltip"] = "暂时调整多重采样抗锯齿等级来平滑模型边缘。";
L["Image Size"] = "图像大小";
L["Item Name Show"] = "显示物品名称";
L["Item Name Hide"] = "隐藏物品名称";
L["Outline Show"] = "点击显示辅助边框";
L["Outline Hide"] = "点击隐藏辅助边框";
L["Preset"] = "预设";
L["File"] = "文件";     --File Name
L["File Tooltip"] = "把你的图片文件放在|cffccccccWorld of Warcraft\\retail\\Interface\\AddOns|r目录下，然后将文件名填入此方框。\n图片必须为|cffcccccc512x512|r或|cffcccccc1024x1024|r的|cffccccccJPG|r文件";
L["Raise Level"] = "置于顶层";
L["Lower Level"] = "取消置顶";
L["Show Mount"] = "显示坐骑";
L["Hide Mount"] = "隐藏坐骑";
L["Loop Animation On"] = "循环播放动画";
L["Click To Continue"] = "点击以继续";
L["Showcase Splash 1"] = "使用Narcissus和录屏软件来制作转台动画以展示你的幻化。";
L["Showcase Splash 2"] = "点击下方按钮来复制试衣间中的物品。";
L["Showcase Splash 3"] = "点击下方按钮可让你的角色旋转起来。";
L["Showcase Splash 4"] = "录制屏幕然后将视频转换为GIF动图。";
L["Loop Animation"] = "循环播放动画";

--Item Sets--
L["Cycle Spec"] = "使用滚轮切换专精";
L["Paperdoll Splash 1"] = "使用套装指示器？";
L["Paperdoll Splash 2"] = "选择主题色";
L["Theme Changed"] = "主题色已改变";

--Outfit Select--
L["Outfit"] = "外观方案";
L["Models"] = "模型";
L["Origin Outfits"] = "原始外观";
L["Outfit Owner Format"] = "%s的外观方案";
L["SortMethod Recent"] = "最近登录";
L["SortMethod Name"] = "角色姓名";

--Tooltip Match Format--
L["Find Cooldown"] = "冷却时间";
L["Find Recharge"] = "充能时间";


--Talent Tree--
L["Mini Talent Tree"] = "迷你天赋树";
L["Show Talent Tree When"] = "在以下情形显示天赋树：";
L["Show Talent Tree Paperdoll"] = "打开角色信息";
L["Show Talent Tree Inspection"] = "观察其他玩家";
L["Show Talent Tree Equipment Manager"] = "使用装备管理";
L["Appearance"] = "外观";
L["Use Class Background"] = "专精背景";
L["Use Bigger UI"] = "更大的界面";
L["Empty Loadout Name"] = "配置名字";
L["No Save Slot Red"] = NARCI_COLOR_RED_MILD.. "存档已满" .."|r";
L["Save"] = "保存";
L["Create Macro Wrong Spec"] = "这个装备方案被指定为另一个专精所用！";
L["Create Marco No Slot"] = "无法创建更多角色专用宏。";
L["Create Macro Instruction 1"] = "将装备方案放入下面的方框中，与以下天赋方案结合\n|cffebebeb%s|r";
L["Create Macro Instruction Edit"] = "将装备方案放入下面的方框中以修改宏\n|cffebebeb%s|r";
L["Create Macro Instruction 2"] = "为这个符合宏选择一个|cff53a9ff副图标|r。";
L["Create Macro Instruction 3"] = "给宏命名\n ";
L["Create Macro Instruction 4"] = "将这个宏拖拽到你的技能栏。";
L["Create Macro In Combat"] = "无法在战斗中创建宏。";
L["Create Macro Next"] = "下一步";
L["Create Marco Created"] = "创建成功";
L["Place UI"] = "把界面放在角色信息的...";
L["Place Talent UI Right"] = "右侧";
L["Place Talent UI Bottom"] = "下方";
L["Loadout"] = "配置方案";
L["No Loadout"] = "无配置方案";
L["PvP"] = "PvP";

--Bag Item Filter--
L["Bag Item Filter"] = "背包物品过滤器";
L["Bag Item Filter Enable"] = "启用搜索建议和自动过滤";
L["Place Window"] = "将窗口放在搜索栏的...";
L["Below Search Box"] = "下方";
L["Above Search Box"] = "上方";
L["Auto Filter Case"] = "在以下情形自动过滤物品：";
L["Send Mails"] = "发送右键";
L["Create Auctions"] = "拍卖物品";
L["Socket Items"] = "镶嵌宝石";

--Perks Program--
L["Perks Program Unclaimed Tender Format"] = "- 收集者宝箱中有 |cffffffff%s|r 枚未拾取的商贩标币。";     --PERKS_PROGRAM_UNCOLLECTED_TENDER
L["Perks Program Unearned Tender Format"] = "- 旅行者日志中有 |cffffffff%s|r 枚待获取的商贩标币。";     --PERKS_PROGRAM_ACTIVITIES_UNEARNED
L["Perks Program Item Added In Format"] = "加入于 %s";
L["Perks Program Item Unavailable"] = "这个物品目前不可用。";
L["Perks Program See Wares"] = "显示商品";
L["Perks Program No Cache Alert"] = "与商栈商人交谈以获取本月的商品列表。";
L["Perks Program Using Cache Alert"] = "正在使用你上次访问商栈时的数据。价格信息有可能不准确。";
L["Modify Default Pose"] = "更改默认动作";   --Change the default pose/animation/camera yaw when viewing transmog items
L["Modify Default Pose Tooltip"] = "勾选此选项将默认动画改为“站立”，并调整人物的面向来更清晰地展示武器外观。";
L["Include Header"] = "包含物品：";  --The transmog set includes...
L["Auto Try On All Items"] = "自动试穿整套物品";
L["Full Set Cost"] = "整套物品价格";   --Purchasing the full set will cost you x Trader's Tender
L["You Will Receive One Item"] = "你将获得|cffffffff一件|r物品：";
L["Format Item Belongs To Set"] = "这件物品属于套装|cffffffff[%s]|r";
L["Default Animation"] = "默认动画";


--Quest--
L["Auto Display Quest Item"] = "自动阅读任务物品的文字说明";
L["Drag To Move"] = "左击并拖动来移动位置";
L["Middle Click Reset Position"] = "鼠标中键重置位置。"
L["Change Position"] = "改变位置";


--Timerunning--
L["Primary Stat"] = "主属性";
L["Stamina"] = "耐力"
L["Crit"] = "爆击";
L["Haste"] = "急速";
L["Mastery"] = "精通";
L["Versatility"] = "全能";

L["Leech"] = "吸血";
L["Speed"] = "加速";
L["Format Stat EXP"] = "+%d%% 经验获取";
L["Format Rank"] = "等级 %d";
L["Cloak Rank"] = "披风等级";


--Gem Manager--
L["Gem Manager"] = "宝石管理器";
L["Pandamonium Gem Category 1"] = "首要";
L["Pandamonium Gem Category 2"] = "匠械";
L["Pandamonium Gem Category 3"] = "棱彩";
L["Pandamonium Slot Category 1"] = "胸部和腿部";
L["Pandamonium Slot Category 2"] = "饰品";
L["Pandamonium Slot Category 3"] = "项链和戒指";
L["Gem Removal Instruction"] = "<右键点击移除此宝石>";
L["Gem Removal No Tool"] = "你没有能取下这颗宝石的工具。";
L["Gem Removal Bag Full"] = "背包里需要有空位才能取下此宝石！";
L["Gem Removal Combat"] = "不能在战斗中更换宝石";
L["Gemma Click To Activate"] = "<左键点击以激活>";
L["Gemma Click To Insert"] = "<左键点击以镶嵌>";
L["Gemma Click Twice To Insert"] = "<左键点击|cffffffff两次|r来镶嵌>";
L["Gemma Click To Select"] = "<左键选择>";
L["Gemma Click To Deselect"] = "<右键取消>";
L["Stat Health Regen"] = "生命回复";
L["Gem Uncollected"] = "未收集";
L["No Sockets Were Found"] = "没有找到合适的插槽。";
L["Click To Show Gem List"] = "<点击打开宝石列表>";
L["Remix Gem Manager"] = "Remix宝石管理器";
L["Select A Loadout"] = "选择方案";
L["Loadout Equipped"] = "已装备";
L["Loadout Equipped Partially"] = "部分装备";
L["Last Used Loadout"] = "最近应用过";
L["New Loadout"] = "新方案";
L["New Loadout Blank"] = "创建一个空白的方案";
L["New Loadout From Equipped"] = "使用已装备的宝石";
L["Edit Loadout"] = "编辑";
L["Delete Loadout One Click"] = "删除";
L["Delete Loadout Long Click"] = "|cffff4800删除|r\n|cffcccccc(长按左键)|r";
L["Select Gems"] = "选择";
L["Equipping Gems"] = "装备中...";
L["Pandamonium Sockets Available"] = "可用点数";
L["Click To Open Gem Manager"] = "左键点击以打开宝石管理器";
L["Loadout Save Failure Incomplete Choices"] = "|cffff4800没有选够足够的宝石|r";
L["Loadout Save Failure Dupe Loadout Format"] = "|cffff4800此方案与|r%s相同";
L["Loadout Save Failure Dupe Name Format"] = "|cffff4800方案名称重复|r";
L["Loadout Save Failure No Name"] = "|cffff4800请为方案命名|r";
L["Empty Socket"] = "空插槽";

L["Format Equipping Progress"] = "正在装备 %d/%d";
L["Format Click Times To Equip Singular"] = "点击 |cff19ff19%d|r 次以装备";
L["Format Click Times To Equip Plural"] = "点击 |cff19ff19%d|r 次以装备";   --|4Time:Times; cannot coexist with color code?
L["Format Free Up Bag Slot"] = "背包中需腾出%d个格子";
L["Format Number Items Selected"] = "%d 已选择";
L["Format Gem Slot Stat Budget"] = "在 %s 中的宝石只有 %s%% 的效果"  --e.g. Gems in trinket are 75% effective


--Game Pad--
L["GamePad Select"] = "选择";
L["GamePad Cancel"] = "取消";
L["GamePad Use"] = "使用";
L["GamePad Equip"] = "装备";