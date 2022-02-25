--Coutesy of ZamestoTV. Thank you!    --Translator: ZamestoTV as of 1.1.7

if not (GetLocale() == "ruRU") then
    return;
end

local L = Narci.L;
local S = Narci.L.S;

if IsMacClient() then
    --Mac OS
	NARCI_MODIFIER_CONTROL = "Команды";
    NARCI_MODIFIER_ALT = "Вариант";
    NARCI_SHORTCUTS_COPY = "Команда+C";
end

L["Swap items"] = "Менять предметы";
L["Press Copy"] = NARCI_COLOR_GREY_70.. "Нажмите |r".. NARCI_SHORTCUTS_COPY.. NARCI_COLOR_GREY_70 .." чтобы скопировать";
L["Copied"] = NARCI_COLOR_GREEN_MILD.. "Ссылка Скопирована";

L["Movement Speed"] = "СД";
L["Damage Reduction Percentage"] = "СУ%";

L["Advanced Info"] = "Щелкните ЛКМ для переключения расширенной информации.";

L["Photo Mode"] = "Фото Режим";
L["Photo Mode Tooltip Open"] = "Откройте Панель инструментов скриншоты.";
L["Photo Mode Tooltip Close"] = "Закройте панель инструментов скриншотов.";
L["Photo Mode Tooltip Special"] = "Ваши захваченные скриншоты в папке WoW Screenshots не будут включать этот виджет.";

L["Xmog Button"] = "Поделиться Трансмогом";
L["Xmog Button Tooltip Open"] = "Показать предметы трансмога вместо реальных предметов.";
L["Xmog Button Tooltip Close"] = "Отображает фактическую экипировку, без трансмога.";
L["Xmog Button Tooltip Special"] = "Вы можете попробовать разные макеты.";

L["Emote Button"] = "Сделать Эмоцию";
L["Emote Button Tooltip Open"] = "Делайте эмоции с уникальными анимациями.";
L["Auto Capture"] = "Авто Захват";

L["HideTexts Button"] = "Скрыть Тексты";
L["HideTexts Button Tooltip Open"] = "Скрыть все имена, пузырьки чата и боевые тексты.";
L["HideTexts Button Tooltip Close"] = "Восстановите имена, пузыри чата и боевые тексты.";
L["HideTexts Button Tooltip Special"] = "Предыдущие настройки будут восстановлены при выходе из системы.";

L["TopQuality Button"] = "Высокое качество";
L["TopQuality Button Tooltip Open"] = "Установите все параметры качества графики на максимум.";
L["TopQuality Button Tooltip Close"] = "Восстановите настройки графики.";

--Special Source--
L["Heritage Armor"] = "Традиционные Доспехи";
L["Secret Finding"] = "Секретная Находка"

HEART_QUOTE_1 = "то, что существенно, невидимо для глаза.";

--Title Manager--
L["Open Title Manager"] = "Открыть Меню Титулов";
L["Close Title Manager"] = "Закрыть Меню Титулов";

--Alias--
L["Use Alias"] = "Переключиться на псевдоним"
L["Use Player Name"] = "Переключиться на "..CALENDAR_PLAYER_NAME;

L["Minimap Tooltip Double Click"] = "Двойное нажатие";
L["Minimap Tooltip Left Click"] = "ЛКМ|r";
L["Minimap Tooltip To Open"] = "|cffffffffОткрыть "..CHARACTER_INFO;
L["Minimap Tooltip Module Panel"] = "|cffffffffВойдите в фото режим";
L["Minimap Tooltip Right Click"] = "ПКМ";
L["Minimap Tooltip Shift Left Click"] = "Shift + ЛКМ";
L["Minimap Tooltip Shift Right Click"] = "Shift + ПКМ";
L["Minimap Tooltip Hide Button"] = "|cffffffffСкрыть эту кнопку|r"
L["Minimap Tooltip Middle Button"] = "|CFFFF1000Средняя кнопка |cffffffffСброс камеры";
L["Minimap Tooltip Set Scale"] = "Установите Масштаб: |cffffffff/narci [масштаб 0.8~1.2]";
L["Corrupted Item Parser"] = "|cffffffffПереключить парсер порченого предмета|r";
L["Toggle Dressing Room"] = "|cffffffffПереключить на "..DRESSUP_FRAME.."|r";

NARCI_CLIPBOARD = "Буфер Обмена";
L["Layout"] = "Место";
L["Symmetry"] = "Симметрия";
L["Asymmetry"] = "Асимметрия";
L["Copy Texts"] = "Скопировать Текст";
L["Syntax"] = "Синтаксис";
L["Plain Text"] = "Обычный Текст";
L["BB Code"] = "BB Code";
L["Markdown"] = "Снижение";
L["Export Includes"] = "Экспорт Включает В Себя...";
NARCI_ITEM_ID = "ID Предмета";

L["3D Model"] = "3D Модель";
NARCI_EQUIPMENTSLOTS = "Слоты Экипировки";

--Preferences--

NARCI_PHOTO_MODE = L["Фото Режим"];
NARCI_OVERRIDE = "Переопределение";
NARCI_INVALID_KEY = "Недопустимая комбинация клавиш.";
NARCI_REQUIRE_RELOAD = NARCI_COLOR_RED_MILD.. "Требуется перезагрузка пользовательского интерфейса.|r";

L["Preferences"] = "Предпочтения";
L["Preferences Tooltip"] = "Нажмите, чтобы открыть рамку предпочтений.";
L["Extensions"] = "Расширения";
L["About"] = "О нас";
L["Image Filter"] = "Фильтры";
L["Image Filter Description"] = "Все фильтры, за исключением затемнения будет отключен в режиме трансмогрификации.";
L["Grain Effect"] = "Зерновой Эффект";
L["Fade Music"] = "Приглушить Музыку ввод/вывод";
L["Vignette Strength"] = "Уровень Затемнения";
L["Weather Effect"] = "Погодные эффекты";
L["Letterbox"] = "Широкоформатный режим";
L["Letterbox Ratio"] = "Соотношение"
L["Letterbox Alert1"] = "Соотношение сторон вашего монитора превышает выбранное соотношение!"
L["Letterbox Alert2"] = "Рекомендуется установить масштаб пользовательского интерфейса на %0.1f\n(текущий масштаб %0.1f)"
L["Default Layout"] = "Макет по умолчанию";
L["Transmog Layout1"] = "Симметрия, 1 Модель";
L["Transmog Layout2"] = "2 модели";
L["Transmog Layout3"] = "Компактный Режим";
L["Always Show Model"] = "Всегда Показывайте Модель";
L["AFK Screen Description"] = "Автоматически открывает Narcissus когда вы АФК.";
L["AFK Screen Description Extra"] = "Это будет переопределять ElvUI режим АФК.";
L["Gemma"] = "\"Gemma\"";   --Don't translate
L["Gemma Description"] = "Показать список камней, когда вы носите экипировку.";
L["Dressing Room"] = "Гардеробная"
L["Dressing Room Description"] = "Большая панель гардеробной с возможностью просмотра и копирования списков предметов других игроков и создания ссылок на гардеробную Wowhead.";
L["General"] = "Общие";   --General options
L["Interface"] = "Интерфейс";
L["Shortcuts"] = "Доступ";
L["Themes"] = "Темы";
L["Effects"] = "Эффекты";   --UI effect
L["Camera"] = "Камера";
L["Transmog"] = "Трансмог";
L["Credits"] = "Титры";
L["Border Theme Header"] = "Тема Границы";
L["Border Theme Bright"] = "Яркая";
L["Border Theme Dark"] = "Темная";
L["Text Width"] = "Ширина Текста";
L["Truncate Text"] = "Усечение Текста";
L["Stat Sheet"] = "Статический Лист";
L["Minimap Button"] = "Кнопка на Миникарте";
L["Fade Out"] = "Появляется при наведении мыши";
L["Fade Out Description"] = "Кнопка исчезает, когда вы убираете курсор от нее.";
L["Hotkey"] = "Клавиша";
L["Double Tap"] = "Двойное нажатие";
L["Double Tap Description"] = "Дважды коснитесь клавиши, привязанной к панели персонажа, чтобы открыть Narcissus."
L["Show Detailed Stats"] = "Показать Подробную Статистику";
L["Tooltip Color"] = "Цвет Всплывающей Подсказки";
L["Entrance Visual"] = "Визуал Вход";
L["Entrance Visual Description"] = "Воспроизведение визуальных эффектов заклинаний, когда появляется ваша модель.";
L["Panel Scale"] = "Масштаб панели";
L["Exit Confirmation"] = "Подтверждение Выхода";
L["Exit Confirmation Texts"] = "Выйти из группового фото?";
L["Exit Confirmation Leave"] = "Да";
L["Exit Confirmation Cancel"] = "Нет";
L["Ultra-wide"] = "Ультра-широкий";
L["Ultra-wide Optimization"] = "Сверхширокая оптимизация";
L["Baseline Offset"] = "Смещение Базовой Линии";
L["Ultra-wide Tooltip"] = "Вы можете увидеть эту опцию, потому что используете %s:9 монитор.";
L["Interactive Area"] = "Интерактивная Зона";
L["Item Socketing Tooltip"] = "Дважды щелкните, чтобы вставить";
L["No Available Gem"] = "|cffd8d8d8Нет в наличии каменя|r";
L["Use Bust Shot"] = "Эффект Приближения";
L["Use Escape Button"] = "Клавиша Esc";
L["Use Escape Button Description1"] = "Нажмите клавишу Esc, чтобы выйти.";
L["Use Escape Button Description2"] = "Выйдите, нажав скрытую кнопку X в правом верхнем углу экрана.";
L["Show Module Panel Gesture"] = "Показывать панель модуля при наведении курсора мыши";
L["Independent Minimap Button"] = "Не зависит от других аддонов";
L["AFK Screen"] = "АФК-экран";
L["Keep Standing"] = "Продолжай Стоять";
L["Keep Standing Description"] = "Используйте /встать время от времени, когда вы находитесь в АФК. Это не помешает выходу из системы.";
L["None"] = "Нет";
L["NPC"] = "НПС";
L["Database"] = "База данных";
L["Creature Tooltip"] = "Создание всплывающей подсказки";
L["RAM Usage"] = "Использование оперативной памяти";
L["Others"] = "Другие";
L["Find Relatives"] = "Найти Родственников";
L["Find Related Creatures Description"] = "Поиск НПС с одной и той же фамилией.";
L["Find Relatives Hotkey Format"] = "Нажмите %s чтобы найти родственников.";
L["Translate Names"] = "Перевод Имен";
L["Translate Names Description On"] = "Показать переведенное название НПС на...";
L["Translate Names Description Off"] = "";
L["Select A Language"] = "Выбранный язык:";
L["Select Multiple Languages"] = "Выбранные языки:";
L["Load on Demand"] = "Загрузка по требованию";
L["Load on Demand Description On"] = "Не загружайте базу данных до тех пор, пока не воспользуетесь функциями поиска.";
L["Load on Demand Description Off"] = "Загрузите базу данных существ при входе в систему.";
L["Load on Demand Description Disabled"] = NARCI_COLOR_YELLOW.. "Этот переключатель заблокирован, потому что вы включили всплывающую подсказку существа.";
L["Tooltip"] = "Подсказка";
L["Name Plate"] = "Табличка с именем";
L["Y Offset"] = "Смещение Y";
L["Sceenshot Quality"] = "Качество Скриншота";
L["Screenshot Quality Description"] = "Более высокое качество приводит к большему размеру файла.";
L["Camera Movement"] = "Движение камеры";
L["Orbit Camera"] = "Сферическая камера";
L["Orbit Camera Description On"] = "Когда вы откроете этот аддон, камера будет повернута к вам спереди и начнет вращаться по орбите.";
L["Orbit Camera Description Off"] = "Когда вы откроете этот аддон, камера будет увеличена без поворота";
L["Camera Safe Mode"] = "Безопасный Режим Камеры";
L["Camera Safe Mode Description"] = "Полностью отключить экшн-камеру после закрытия этого аддона.";
L["Camera Safe Mode Description Extra"] = "Не используется, потому что вы используете динамическую камеру."
L["Camera Transition"] = "Переход камеры";
L["Camera Transition Description On"] = "Камера плавно переместится в заданное положение, когда вы откроете панель персонажа.";
L["Camera Transition Description Off"] = "Переход камеры становится мгновенным. Начинается со второго использования панели персонажа.\nМгновенный переход отменяет предустановку камеры #4.";
L["Interface Options Tab Description"] = "Вы также можете получить доступ к этой панели, нажав кнопку с шестеренкой рядом с панелью инструментов в левом нижнем углу экрана при использовании Narcissus.";
L["Soulbinds"] = COVENANT_PREVIEW_SOULBINDS;
L["Conduit Tooltip"] = "Поведенческие эффекты более высоких рангов";
L["Domination Indicator"] = "Индикатор господства";

--Model Control--
NARCI_STAND_IDLY = "Без Оружия";
NARCI_RANGED_WEAPON = "Дальний бой";
NARCI_MELEE_WEAPON = "Ближний бой";
NARCI_SPELLCASTING = "Заклинание";
NARCI_ANIMATION_ID = "ID Анимации";
NARCI_LINK_LIGHT_SETTINGS = "Настройки Освещения";
NARCI_LINK_MODEL_SCALE = "Масштаб Модели";
NARCI_GROUP_PHOTO_AVAILABLE = "Теперь доступен в Narcissus";
NARCI_GROUP_PHOTO_NOTIFICATION = "Пожалуйста, выберите цель.";
NARCI_GROUP_PHOTO_STATUS_HIDDEN = "Скрыть";
NARCI_DIRECTIONAL_AMBIENT_LIGHT = "Направленный/Рассеянный Свет";
NARCI_DIRECTIONAL_AMBIENT_LIGHT_TOOLTIP = "Переключение между ними\n- Направленный свет, который может быть заблокирован объектом и отбрасывать тень\n- Рассеянный свет, который влияет на всю модель";

L["Group Photo"] = "Групповое фото";
L["Reset"] = "Сброс";
L["Actor Index"] = "Индекс";
L["Move To Font"] = "|cff40c7ebПеред|r";
L["Actor Index Tooltip"] = "Перетащите кнопку индекса, чтобы изменить слой модели.";
L["Play Button Tooltip"] = "ЛКМ: воспроизвести эту анимацию\nПКМ: Возобновить все модели\' анимации";
L["Pause Button Tooltip"] = "ЛКМ: Приостановите эту анимацию\nПКМ: Приостановка всех моделей\' анимаций";
L["Save Layers"] = "Сохранение Слоев";
L["Save Layers Tooltip"] = "Автоматический захват 6 скриншотов для композиции изображения.\nПожалуйста, не перемещайте курсор и не нажимайте никаких кнопок во время этого процесса. В противном случае ваш персонаж может стать невидимым после выхода из аддона. Если это произойдет, используйте эту команду:\n/console showplayer";
L["Ground Shadow"] = "Тень на Земле";
L["Ground Shadow Tooltip"] = "Добавьте подвижную тень на земле под вашей моделью.";
L["Hide Player"] = "Скрыть Игрока";
L["Hide Player Tooltip"] = "Сделайте своего персонажа невидимым для себя.";
L["Virtual Actor"] = "Виртуальный";
L["Virtual Actor Tooltip"] = "На этой модели видно только визуальное заклинание."
L["Self"] = "Себя";
L["Target"] = "Цель";
L["Compact Mode Tooltip"] = "Используйте только левую часть экрана, чтобы представить свой трансмог.";
L["Toggle Equipment Slots"] = "Отобразить/Скрыть слоты экипировки";
L["Toggle Text Mask"] = "Переключить текстовую маску";
L["Toggle 3D Model"] = "Переключить 3D модель";
L["Toggle Model Mask"] = "Переключить маску модели";
L["Show Color Sliders"] = "Показать цветные ползунки";
L["Show Color Presets"] = "Показать цветовые пресеты";
L["Keep Current Form"] = "Удерживайте "..NARCI_MODIFIER_ALT.." чтобы сохранить форму.";
L["Race Change Tooltip"] = "Переход к другой игровой расе";
L["Sex Change Tooltip"] = "Сменить пол";
L["Show More options"] = "Показать дополнительные параметры";
L["Show Less Options"] = "Показать меньше параметров";
L["Shadow"] = "Тень";
L["Light Source"] = "Источник света";
L["Light Source Independent"] = "Свободный";
L["Light Source Interconnected"] = "Не свободный";


--Animation Browser--
L["Animation"] = "Анимация";
L["Animation Tooltip"] = "Просмотр, поиск анимации";
L["Animation Variation"] = "Вариация";
L["Reset Slider"] = "Reset to zero";    --reset the value of the slider to zero


--Spell Visual Browser--
L["Visuals"] = "Визуал";
L["Visual ID"] = "Визуал ID";
L["Animation ID Abbre"] = "Аним. ID";
L["Category"] = "Категория";
L["Sub-category"] = "Под-Категория";
L["My Favorites"] = "Избранные";
L["Reset Visual Tooltip"] = "Удалить примененные визуальные эффекты";
L["Remove Visual Tooltip"] = "ЛКМ: Удаление выбранного визуального элемента\nЗатяжное нажатие: Удалите все примененные визуальные эффекты";
L["Apply"] = "Применить";
L["Applied"] = "Применены";   --Viusals that were "Applied" to the model
L["Remove"] = "Удалить";
L["Rename"] = "Переименовать";
L["Refresh Model"] = "Обновить Модель";
L["Toggle Browser"] = "Переключить заклинание визуального браузера";
L["Next And Previous"] = NARCI_MOUSE_BUTTON_ICON_1.."Перейти к следующему\n"..NARCI_MOUSE_BUTTON_ICON_2.."Перейти к предыдущему";
L["New Favorite"] = "Новое в избранном";
L["Favorites Add"] = "Добавить в избранное";
L["Favorites Remove"] = "Удалить из избранного";
L["Auto-play"] = "Воспроиз.";   --Auto-play suggested animation
L["Auto-play Tooltip"] = "Автовоспроизведение анимации \n привязаного к выбранному визуалу.";
L["Delete Entry Plural"] = "Удалить запись %s";
L["Delete Entry Singular"] = "Буду удалять запись %s";
L["History Panel Note"] = "Примененные визуальные эффекты";
L["Return"] = "Вернуться";
L["Close"] = "Закрыть";
L["Change Pack"] = "Изменить пакет";

--Dressing Room--
L["Favorited"] = "Избранное";
L["Unfavorited"] = "Удалить из избранного";
L["Item List"] = "Список предметов";
L["Use Target Model"] = "Использовать модель цели";
L["Use Your Model"] = "Используйте вашу модель";
L["Cannot Inspect Target"] = "Невозможно проверить цель"
L["External Link"] = "Внешняя Ссылка";
L["Add to MogIt Wishlist"] = "Добавить в список желаний MogIt";
L["Show Taint Solution"] = "Как решить эту проблему?";
L["Taint Solution Step1"] = "1. Перезагрузите свой интерфейс.";
L["Taint Solution Step2"] = "2. "..NARCI_MODIFIER_CONTROL.." + ЛКМ по предмету, чтобы открыть гардеробную.";

--NPC Browser--
NARCI_NPC_BROWSER_TITLE_LEVEL = ".*%?%?.?";      --Level ?? --Use this to check if the second line of the tooltip is NPC's title or unit type
L["NPC Browser"] = "Выбор НПС";
L["NPC Browser Tooltip"] = "Выбрать персонажа из списка.";
L["Search for NPC"] = "Поиск НПС";
L["Name or ID"] = "Имя или ID";
L["NPC Has Weapons"] = "Имеет собственное оружие";
L["Retrieving NPC Info"] = "Получение информации о НПС";
L["Loading Database"] = "Загрузка Базы Данных...\nВаш экран зависнет на несколько секунд.";
L["Other Last Name Format"] = "Другой "..NARCI_COLOR_GREY_70.."%s(s)|r:\n";
L["Too Many Matches Format"] = "\nБолее %s соответствует.";

--Solving Lower-case or Abbreviation Issue--
NARCI_STAT_STRENGTH = SPEC_FRAME_PRIMARY_STAT_STRENGTH;
NARCI_STAT_AGILITY = SPEC_FRAME_PRIMARY_STAT_AGILITY;
NARCI_STAT_INTELLECT = SPEC_FRAME_PRIMARY_STAT_INTELLECT;
NARCI_CRITICAL_STRIKE = STAT_CRITICAL_STRIKE;


--Equipment Comparison--
NARCI_AZERITE_POWERS = "Сила Азерита";
L["Gem Tooltip Format1"] = "%s и %s";
L["Gem Tooltip Format2"] = "%s, %s и %s больше...";

--Equipment Set Manager
L["Equipped Item Level Format"] = "Экипировано %s";
L["Equipped Item Level Tooltip"] = "Средний уровень предметов вашего надетого снаряжения.";
L["Equipment Manager"] = EQUIPMENT_MANAGER;
L["Toggle Equipment Set Manager"] = NARCI_MOUSE_BUTTON_ICON_1.."Диспетчер комплектов снаряжения.";
L["Duplicated Set"] = "Дублированный Набор";
L["Low Item Level"] = "Низкий уровень предмета";
L["1 Missing Item"] = "1 недостающий предмет";
L["n Missing Items"] = "%s недостающие предметы";
L["Update Items"] = "Обновление Предметов";
L["Don't Update Items"] = "Не обновляйте предметы";
L["Update Talents"] = "Обновление Талантов";
L["Don't Update Talents"] = "Не обновляйте таланты";
L["Old Icon"] = "Старая Иконка";
L["NavBar Saved Sets"] = "Сохранено";   --A Saved Equipment Set
L["NavBar Incomplete Sets"] = INCOMPLETE;
NARCI_ICON_SELECTOR = "Переключатель Иконок";
NARCI_DELETE_SET_WITH_LONG_CLICK = "Удалить Набор\n|cff808080(нажмите и удерживайте кнопку)|r";

--Corruption System
L["Corruption System"] = "Порча";
L["Eye Color"] = "Цвет Глаза";
L["Blizzard UI"] = "Интерфейс Blizzard";
L["Corruption Bar"] = "Ячейка Порчи";
L["Corruption Bar Description"] = "Включите панель порчи рядом с панелью персонажа.";
L["Corruption Debuff Tooltip"] = "Всплывающая Подсказка Дебаффа";
L["Corruption Debuff Tooltip Description"] = "Замените всплывающую подсказку негативных эффектов по умолчанию на ее числовые аналоги.";
L["No Corrupted Item"] = "Порченная экипировка не одета.";

L["Crit Gained"] = CRIT_ABBR.." Приобрел";
L["Haste Gained"] = STAT_HASTE.." Приобрел";
L["Mastery Gained"] = STAT_MASTERY.." Приобрел";
L["Versatility Gained"] = STAT_VERSATILITY.." Приобрел";

L["Proc Crit"] = "Прок "..CRIT_ABBR;
L["Proc Haste"] = "Прок "..STAT_HASTE;
L["Proc Mastery"] = "Прок "..STAT_MASTERY;
L["Proc Versatility"] =  "Прок "..STAT_VERSATILITY;

L["Critical Damage"] = CRIT_ABBR.."DMG";

L["Corruption Effect Format1"] = "Уменьшение скорости на |cffffffff%s%%|r";
L["Corruption Effect Format2"] = "|cffffffff%s|r начальный урон\n|cffffffff%s ярдов|r радиус";
L["Corruption Effect Format3"] = "|cffffffff%s|r повреждение\n|cffffffff%s%%|r вашего HP";
L["Corruption Effect Format4"] = "Поражение потусторонней тварью накладывает другие дебаффы";
L["Corruption Effect Format5"] = "|cffffffff%s%%|r Урон/исцеление пропорционально уровню порчи.";

--Text Overlay Frame
L["Text Overlay Button Tooltip1"] = "Простое облако разговора";
L["Text Overlay Button Tooltip2"] = "Расширенное облако разговора";
L["Text Overlay Button Tooltip3"] = "Говорящая голова";
L["Text Overlay Button Tooltip4"] = "Плавающий субтитр";
L["Text Overlay Button Tooltip5"] = "Субтитры с черной полосой";
L["Visibility"] = "Видимость";

--Achievement Frame--
L["Use Achievement Panel"] = "Использовать в качестве основного";
L["Use Achievement Panel Description"] = "Замените поздравление за достижения по умолчанию. Щелкните отслеживаемые достижения, чтобы открыть эту панель.";
L["Incomplete First"] = "Невыполненные";
L["Earned First"] = "Выполненные";
L["Settings"] = "Настройка";
L["Next Prev Card"] = "Следующее/Предыдущее";
L["Track"] = "Отслеживать";   --Track achievements
L["Show Unearned Mark"] = "Показать незаслуженное достижение";
L["Show Unearned Mark Description"] = "Отметьте достижения, которые были получены не мной, красным крестиком.";
L["Show Dates"] = "Показать даты";
L["Hide Dates"] = "Скрыть даты";

L["Pinned Entries"] = "Закрепленные записи";
L["Pinned Entry Format"] = "Закреплено  %d/%d";


--Barbershop--
L["Save New Look"] = "Сохранить новый вид";
L["No Available Slot"] = "Нет доступного слота";
L["Look Saved"] = "Смотрите Сохранено";
L["Cannot Save Forms"] = "Невозможно сохранить формы";
L["Profiles"] = "Профили";
L["Save Notify"] = "Уведомить вас о сохранении нового внешнего вида";
L["Show Randomize Button"] = "Показать кнопку случайного отображения";
L["Coins Spent"] = "Монеты потрачены";
L["Locations"] = "Локации";
L["Location"] = "Место";
L["Visits"] = "Посещение";     --number of visits
L["Duration"] = "Время";
L["Edit Name"] = "Редактировать";
L["Delete Look"] = "Удалить";

--Tutorial--
L["Alert"] = "Предупреждение";
L["Race Change"] = "Изменение Расы/Пола";
L["Race Change Line1"] = "Вы можете снова изменить свою расу и пол. Но есть некоторые ограничения:\n1. Ваше оружие исчезнет.\n2. Визуальные эффекты заклинаний больше не могут быть удалены.\n3. Он не работает на других игроках или НПС.";
L["Guide Spell Headline"] = "Попробуйте или примените";
L["Guide Spell Criteria1"] = "ЛКМ, чтобы попробовать";
L["Guide Spell Criteria2"] = "ПКМ, чтобы ПРИМЕНИТЬ";
L["Guide Spell Line1"] = "Большинство визуальных эффектов заклинаний, которые вы добавляете, нажимая левую кнопку, исчезнут за считанные секунды, в то время как те, которые вы добавляете, нажимая правую кнопку, не исчезнут.\n\nТеперь перейдите к записи, затем:";
L["Guide Spell Choose Category"] = "Вы можете добавить визуальные эффекты заклинаний в свою модель. Выберите любую категорию, которая вам нравится. Затем выберите подкатегорию.";
L["Guide History Headline"] = "Панель Истории";
L["Guide History Line1"] = "Здесь можно сохранить не более 5 недавно примененных визуальных элементов. Вы можете выбрать один из них и удалить его, нажав кнопку Удалить в правом углу.";
L["Guide Refresh Line1"] = "Используйте эту кнопку, чтобы удалить все неприменимые визуальные эффекты заклинаний. Те, которые были в панели истории, будут применены.";
L["Guide Input Headline"] = "Ручной ввод";
L["Guide Input Line1"] = "Вы также можете ввести SpellVisualKitID самостоятельно. По состоянию на 9.0, его кап составляет около 155,000.\nВращайте колесо мыши, чтобы попробовать следующий/предыдущий ID.\nОчень немногие ID могут привести к сбою игры.";
L["Guide Equipment Manager Line1"] = "Двойной щелчок: использовать набор\nПКМ: изменить набор.\n\nПредыдущая функция этой кнопки была перемещена в Настройки.";
L["Guide Model Control Headline"] = "Модель Управления";
L["Guide Model Control Line1"] = format("Эта модель имеет те же действия мыши, которые вы используете в гардеробной, плюс:\n\n1.Удерживайте %s и левую кнопку: Поверните модель вокруг оси Y.\n2.Удерживайте %s и правую кнопку: выполните увеличение.", NARCI_MODIFIER_ALT, NARCI_MODIFIER_ALT);
L["Guide Minimap Button Headline"] = "Кнопка на Миникарте";
L["Guide Minimap Button Line1"] = "Кнопка Narcissus на миникарте теперь может быть обработана другими аддонами.\nВы можете изменить этот параметр в панели настроек. Это может потребовать перезагрузки интерфейса."
L["Guide NPC Entrance Line1"] = "Доступ к этой новой функции находится здесь."
L["Guide NPC Browser Line1"] = "Известные НПС перечислены в каталоге ниже.\nВы также можете искать любых существ по имени или по ID.\nОбратите внимание, что при первом использовании функции поиска это может занять несколько секунд для построения таблицы поиска, и ваш экран также может зависнуть.\nВы можете отменить \"Загрузка по требованию\" в панели настроек, чтобы база данных была создана сразу после входа в систему.";


--Splash--
NARCI_SPLASH_WHATS_NEW_FORMAT = "Что нового в Narcissus %s";

L["Splash Category1"] = L["Фото Режим"];
L["Splash Content1 Name"] = "Оружие";
L["Splash Content1 Description"] = "-Просматривайте и используйте все оружие в базе данных, в том числе то, которое не может быть получено игроками.";
L["Splash Content2 Name"] = "Экран выбора персонажа";
L["Splash Content2 Description"] = "-Добавьте декоративную рамку для создания (подделки) экрана выбора персонажа.";
L["Splash Content3 Name"] = "Гардеробная";
L["Splash Content3 Description"] = "-Переделан модуль гардероба.\n-Список предметов теперь включает непарные плечи и иллюзии оружия.";
L["Splash Content4 Name"] = "Браузер НПС";
L["Splash Content4 Description"] = "-Обновлена локальная база данных, которая содержит 152 219 существ.";
L["Splash Category2"] = "Окно персонажа";
L["Splash Content5 Name"] = "Осколок господства";
L["Splash Content5 Description"] = "-Индикатор осколков господства появится, если вы наденете соответствующие предметы.\n-Список доступных осколков будет представлен вам, когда вы вставите предметы господства.";
L["Splash Content6 Name"] = "Медиумы";
L["Splash Content6 Description"] = "-Интерфейс медиумов обновлен. Вы можете проверить эффекты канала для более высоких рангов.";
L["Splash Content7 Name"] = "Визуальные эффекты";
L["Splash Content7 Description"] = "-Граница шестиугольника приобретает новый вид. Некоторые предметы имеют уникальный внешний вид.";

--Project Details--
NARCI_ALL_PROJECTS = "Все проекты";
NARCI_PROJECT_DETAILS = "|cFFFFD100Разработчик: Peterodox\nДата выхода: 25 февраль, 2022|r\n\nСпасибо, что используете этот аддон! Если у вас есть какие-либо вопросы, предложения, идеи, пожалуйста, оставьте комментарий на странице curseforge или свяжитесь со мной по адресу...";
NARCI_PROJECT_AAA_TITLE = "|cff008affA|cff0d8ef2z|cff1a92e5e|cff2696d9r|cff339acco|cff409ebft|cff4da1b2h |cff59a5a6A|cff66a999d|cff73ad8cv|cff7fb180e|cff8cb573n|cff99b966t|cffa6bd59u|cffb2c14dr|cffbfc440e |cffccc833A|cffd9cc26l|cffe5d01ab|cfff2d40du|cffffd800m";
NARCI_PROJECT_AAA_SUMMARY = "Исследуйте достопримечательности и собирайте знания и фотографии со всего Азерота.|cff636363";
NARCI_PROJECT_NARCISSUS_SUMMARY = "Захватывающая панель персонажа и ваш лучший скриншот.";


--Credits--
L["Credit List Extra"] = "Marlamin | WoW.tools\nKeyboardturner | Avid Bug Finder(Generator)\nПеревод на русский Хоргул-Гордунни\nMeorawr | Wondrous Wisdomball";

--Conversation--
L["Q1"] = "Что это?";
L["Q2"] = "Я знаю. Но почему он такой огромный?";
L["Q3"] = "Это не смешно. Мне просто нужен обычный.";
L["Q4"] = "Хорошо. Что, если я захочу отключить его?";
L["Q5"] = "И еще одно, не могли бы вы пообещать мне больше никаких шалостей?";
L["A1"] = "По - видимому, это диалог подтверждения выхода. Он появляется, когда вы пытаетесь выйти из режима группового фото, нажав горячую клавишу.";
L["A2"] = "Ха, вот что она сказала.";
L["A3"] = "Ладно...ладно..."
L["A4"] = "Просто откройте Настройки, а затем перейдите в режим фото. Вы не пропустите его.";

--Search--
L["Search Result Singular"] = "%s результат";
L["Search Result Plural"] = "%s результатов";
L["Search Result Overflow"] = "более %s результатов";
L["Search Result None"] = CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS;

--Weapon Browser--
L["Draw Weapon"] = "С Оружием";
L["Unequip Item"] = "Необорудовать";
L["WeaponBrowser Guide Hotkey"] = "Укажите в какой руке держать оружие:";
L["WeaponBrowser Guide ModelType"] = "Некоторые предметы ограничены определенным типом модели:";
L["WeaponBrowser Guide DressUpModel"] = "Это будет тип по умолчанию, если ваша цель - игрок, если вы не удерживаете <%s> при его создании.";
L["WeaponBrowser Guide CinematicModel"] = "Тип модели всегда будет кинематографическим, если существо является НПС. Оружие нельзя вкладывать в ножны.";

--Pet Stables--
L["PetStable Tooltip"] = "Выберите питомца из своей конюшни";
L["PetStable Loading"] = "Получение информации о питомце";

--Domination Item--
L["Item Bonus"] = "Бонус:"  --do NOT re-translate
L["Combat Error"] = NARCI_COLOR_RED_MILD.."Выйти из боя, чтобы продолжить".."|r";
L["Extract Shard"] = "Извлечь осколок";
L["No Service"] = "Нет сети";
L["Shards Disabled"] = "Осколки Господства отключены за пределами Утроба";

--Mythic+ Leaderboard--
L["Mythic Plus"] = "Мифический+";
L["Mythic Plus Abbrev"] = "М+";
L["Total Runs"] = "Всего забегов: ";
L["Complete In Time"] = "Во время";
L["Complete Over Time"] = "Не во время";
L["Runs"] = "Забег";

--Equipment Upgrade--
L["Temp Enchant"] = "Временные чары";       --ERR_TRADE_TEMP_ENCHANT_BOUND
L["Owned"] = "Персональный";                           --Only show owned items
L["At Level"] = "На уровне %d:";      --Enchants scale with player level
L["No Item Alert"] = "Нет совместимых предметов";
L["Click To Insert"] = "Нажмите, чтобы вставить";       --Insert a gem
L["No Socket"] = "Нет гнезд";
L["No Other Item For Slot"] = "Нет другого предмета для %s";       --where %s is the slot name
L["In Bags"] = "В сумках";

--Statistics--
S["Narcissus Played"] = "Общее время, проведенное в Narcissus";
S["Format Since"] = "(на %s)";
S["Screenshots"] = "Скриншоты, сделанные в Narcissus";

--Turntable Showcase--
L["Turntable"] = "Вращение";
L["Picture"] = "Картина";
L["Turntable Tab Animation"] = "Анимация";
L["Turntable Tab Image"] = "Изображение";
L["Turntable Tab Quality"] = "Сглаживание";
L["Turntable Tab Background"] = "Фон";
L["Spin"] = "Повернуть";
L["Sync"] = "Обновлять";
L["Rotation Period"] = "Период";
L["Period Tooltip"] = "Время, необходимое для завершения одного вращения.\nЭто также должно быть |cffccccccпродолжительность|r вашего GIF или видео."
L["MSAA Tooltip"] = "Временно измените сглаживание, чтобы сгладить неровные края ценой снижения производительности.";
L["Image Size"] = "Размер Изображение";
L["Item Name Show"] = "Показать список";
L["Item Name Hide"] = "Скрыть список";
L["Outline Show"] = "Нажмите, чтобы показать схему";
L["Outline Hide"] = "Нажмите, чтобы скрыть контур";
L["Preset"] = "Пресеты";
L["File"] = "Файл";     --File Name
L["File Tooltip"] = "Put your own image under |cffccccccWorld of Warcraft\\retail\\Interface\\AddOns|r and insert the file name in this box.\nThe image must be a |cffcccccc512x512|r or |cffcccccc1024x1024|r |cffccccccJPG|r file";
L["Raise Level"] = "На передний план";
L["Lower Level"] = "Отправить на задний план";
L["Click To Continue"] = "нажмите для продолжения";
L["Showcase Splash 1"] = "Создайте анимацию поворотного стола, чтобы продемонстрировать свою трансмогрификацию с Narcissus и устройством записи экрана.";
L["Showcase Splash 2"] = "Нажмите кнопку ниже, чтобы скопировать предметы из Гардеробной.";
L["Showcase Splash 3"] = "Нажмите кнопку ниже, чтобы вращать своего персонажа.";
L["Showcase Splash 4"] = "Запишите свой экран с помощью программного обеспечения для записи видео, а затем конвертируйте его в GIF.";