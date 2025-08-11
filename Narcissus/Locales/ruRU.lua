--Coutesy of ZamestoTV. Thank you!    --Translator: ZamestoTV as of 1.8.2 b

if not (GetLocale() == "ruRU") then
    return;
end

local L = Narci.L;
local S = Narci.L.S;

NARCI_GRADIENT = "|cffA236EFN|r|cff9448F1a|r|cff865BF2r|r|cff786DF4c|r|cff6A80F6i|r|cff5D92F7s|r|cff4FA4F9s|r|cff41B7FAu|r|cff33C9FCs|r";

L["Developer Info"] = "Developed by Peterodox";

NARCI_MODIFIER_CONTROL = "Ctrl";
NARCI_MODIFIER_ALT = "Alt";   --Windows
NARCI_SHORTCUTS_COPY = "Ctrl+C";

NARCI_MOUSE_BUTTON_ICON_1 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:0:16:0:16|t";   --Left Button
NARCI_MOUSE_BUTTON_ICON_2 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:16:32:0:16|t";   --Right Button
NARCI_MOUSE_BUTTON_ICON_3 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:32:48:0:16|t";   --Middle Button

if IsMacClient() then
    --Mac OS
	NARCI_MODIFIER_CONTROL = "Команды";
    NARCI_MODIFIER_ALT = "Вариант";
    NARCI_SHORTCUTS_COPY = "Команда+C";
end

NARCI_WORDBREAK_COMMA = ", ";
BINDING_HEADER_NARCISSUS = "Narcissus";

--Date--
L["Today"] = COMMUNITIES_CHAT_FRAME_TODAY_NOTIFICATION;
L["Yesterday"] = COMMUNITIES_CHAT_FRAME_YESTERDAY_NOTIFICATION;
L["Format Days Ago"] = "%d дней назад";
L["A Month Ago"] = "1 месяц назад";
L["Format Months Ago"] = "%d месяца назад";
L["A Year Ago"] = "1 год назад";
L["Format Years Ago"] = "%d года назад";
L["Version Colon"] = (GAME_VERSION_LABEL or "Версия")..": ";
L["Date Colon"] = "Дата: ";
L["Day Plural"] = "д.";
L["Day Singular"] = "д.";
L["Hour Plural"] = "ч.";
L["Hour Singular"] = "ч.";

L["Swap items"] = "Менять предметы";
L["Press Copy"] = NARCI_COLOR_GREY_70.. "Нажмите |r".. NARCI_SHORTCUTS_COPY.. NARCI_COLOR_GREY_70 .." чтобы скопировать";
L["Copied"] = NARCI_COLOR_GREEN_MILD.. "Ссылка Скопирована";
L["Movement Speed"] = "СД";
L["Damage Reduction Percentage"] = "СУ%";
L["Advanced Info"] = "Щелкните ЛКМ для переключения расширенной информации.";
L["Restore On Exit"] = "\nВаши предыдущие настройки будут восстановлены после выхода.";

L["Photo Mode"] = "Фото Режим";
L["Photo Mode Tooltip Open"] = "Откройте Панель инструментов скриншоты.";
L["Photo Mode Tooltip Close"] = "Закройте панель инструментов скриншотов.";
L["Photo Mode Tooltip Special"] = "Ваши захваченные скриншоты в папке WoW Screenshots не будут включать этот виджет.";

L["Toolbar Mog Button"] = "Фото Режим";
L["Toolbar Mog Button Tooltip"] = "Продемонстрируйте свою трансмогрификацию или создайте фотобудку, куда вы сможете добавить других игроков и НПС.";

L["Toolbar Emote Button"] = "Сделать эмоцию";
L["Toolbar Emote Button Tooltip"] = "Используйте эмоции с уникальной анимацией.";
L["Auto Capture"] = "Автоматический захват";

L["Toolbar HideTexts Button"] = "Скрыть тексты";
L["Toolbar HideTexts Button Tooltip"] = "Скрыть все имена, чаты и тексты боя." ..L["Restore On Exit"];

L["Toolbar TopQuality Button"] = "Высшее качество";
L["Toolbar TopQuality Button Tooltip"] = "Установите все параметры в настройках графики на максимум." ..L["Restore On Exit"];

L["Toolbar Location Button"] = "Местоположение игрока";
L["Toolbar Location Button Tooltip"] = "Показать название текущей территории и координаты игрока."

L["Toolbar Camera Button"] = "Камера";
L["Toolbar Camera Button Tooltip"] = "Временно изменить настройки камеры."

L["Toolbar Preferences Button Tooltip"] = "Открыть панель настроек.";

--Special Source--
L["Heritage Armor"] = "Традиционные Доспехи";
L["Secret Finding"] = "Секретная Находка"

L["Heart Azerite Quote"] = "то, что существенно, невидимо для глаза.";

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
L["MinimapButton Enable Instruction"] = "|cffffd100Вы отключили кнопку миникарты Narcissus. Вы можете ввести|r |cffffffff/narci minimap|r |cffffd100чтобы снова включить ее.|r";
L["MinimapButton Reenabled"] = "|cffffd100Вы включили кнопку миникарты Narcissus.|r";
L["MinimapButton LibDBIcon"] = "Использовать LibDBIcon";
L["MinimapButton LibDBIcon Desc"] = "Используйте LibDBIcon для создания кнопки мини-карты.\nВы видите эту опцию, потому что у вас установлена ​​библиотека LibDBIcon-1.0 или дополнение, интегрирующее эту библиотеку.";
L["MinimapButton LibDBIcon Hide"] = "Скрыть кнопку";
L["Corrupted Item Parser"] = "|cffffffffПереключить парсер порченого предмета|r";
L["Toggle Dressing Room"] = "|cffffffffПереключить на "..DRESSUP_FRAME.."|r";
L["Reset Camera"] = "Сбросить камеру";
L["Character UI"] = "Интерфейс персонажа";
L["Module Menu"] = "Меню модуля";

L["Layout"] = "Место";
L["Symmetry"] = "Симметрия";
L["Asymmetry"] = "Асимметрия";
L["Copy Texts"] = "Скопировать Текст";
L["Syntax"] = "Синтаксис";
L["Plain Text"] = "Обычный Текст";
L["BB Code"] = "BB Code";
L["Markdown"] = "Снижение";
L["Export Includes"] = "Экспорт Включает В Себя...";

L["3D Model"] = "3D Модель";
L["Equipment Slots"] = "Слоты Экипировки";

--Preferences--
L["Override"] = "Переопределение";
L["Invalid Key"] = "Недопустимая комбинация клавиш.";

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
L["AFK Screen Delay"] = "После отменяемой задержки";
L["Item Names"] = "Название предмета";
L["Open Narcissus"] = "Открыть Narcissus";
L["Character Panel"] = "Панель персонажей";
L["Screen Effects"] ="Экранные эффекты";

L["Gem List"] = "Список камней";
L["Gemma"] = "\"Камни\"";   --Don't translate
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
L["Show Minimap Button"] = "Кнопка - Показать миникарту";
L["Add To AddOn Compartment"] = "Добавить в Аддон";
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
L["Use Bust Shot"] = "Эффект Приближения";
L["Use Escape Button"] = "Выйдите из Narcissus, нажав |cffffdd10(Esc)|r";
L["Use Escape Button Description"] = "Кроме того, вы можете нажать скрытую кнопку X в правом верхнем углу экрана, чтобы выйти.";
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
L["Translate Names Description"] = "Показывать переведенные имена вкл.";
L["Translate Names Languages"] = "Перевести на";
L["Select Language Single"] = "Выберите один язык для отображения на табличках с именами";
L["Select Language Multiple"] = "Выберите языки для отображения во всплывающей подсказке";
L["Load on Demand"] = "Загрузка по требованию";
L["Load on Demand Description On"] = "Не загружайте базу данных до тех пор, пока не воспользуетесь функциями поиска.";
L["Load on Demand Description Off"] = "Загрузите базу данных существ при входе в систему.";
L["Load on Demand Description Disabled"] = NARCI_COLOR_YELLOW.. "Этот переключатель заблокирован, потому что вы включили всплывающую подсказку существа.";
L["Tooltip"] = "Подсказка";
L["Name Plate"] = "Табличка с именем";
L["Offset Y"] = "Смещение Y";
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
L["Paperdoll Widget"] = "Виджет Бумажная кукла";
L["Item Tooltip"] = "Подсказка к предметам";
L["Style"] = "Стиль";
L["Tooltip Style 1"] = "Следующее поколение";
L["Tooltip Style 2"] = "Оригинал";
L["Addtional Info"] = "Дополнительная информация";
L["Item ID"] = "ID предмета";
L["Camera Reset Notification"] = "Смещение камеры было сброшено до нуля. Если вы хотите отключить эту функцию, перейдите в Настройки — Камера и отключите безопасный режим камеры.";
L["Binding Name Open Narcissus"] = "Открыть панель персонажей Narcissus";
L["Developer Colon"] = "Разработчик: ";
L["Project Page"] = "Страница проекта";
L["Press Copy Yellow"] = "Нажмите |cffffd100".. NARCI_SHORTCUTS_COPY .."|r для копирования";
L["New Option"] = NARCI_NEW_ENTRY_PREFIX.." НОВЫЙ".."|r"												  
L["Expansion Features"] = "Возможности дополнения";	
L["LFR Wing Details"] = "Детали крыла ЛФР";
L["LFR Wing Details Description"] = "Показывать имена боссов, когда вы разговариваете с ЛФР НПС в одиночной очереди.";	
L["Speedy Screenshot Alert"] = "Ускорить исчезновение сообщения со снимком экрана";									   

--Model Control--
L["Ranged Weapon"] = "Дальний бой";
L["Melee Animation"] = "Ближний бой";
L["Spellcasting"] = "Заклинание";
L["Link Light Sources"] = "Настройки Освещения";
L["Link Model Scales"] = "Масштаб Модели";
L["Hidden"] = "Скрыть";
L["Light Types"] = "Направленный/Рассеянный Свет";
L["Light Types Tooltip"] = "Переключение между ними\n- Направленный свет, который может быть заблокирован объектом и отбрасывать тень\n- Рассеянный свет, который влияет на всю модель";

L["Group Photo"] = "Групповое фото";
L["Reset"] = "Сброс";
L["Actor Index"] = "Индекс";
L["Move To Font"] = "|cff40c7ebПеред|r";
L["Actor Index Tooltip"] = "Перетащите кнопку индекса, чтобы изменить слой модели.";
L["Play Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Воспроизвести эту анимацию\n"..NARCI_MOUSE_BUTTON_ICON_2.."Возобновить все модели\' анимации";
L["Pause Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Приостановить эту анимацию\n"..NARCI_MOUSE_BUTTON_ICON_2.."Приостановить все модели\' анимации";
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
L["Race Sex Change Bug"] = NARCI_COLOR_RED_MILD.."\nЭта функция имеет ошибку, которую нельзя исправить в данный момент.|r";
L["Race Change Tooltip"] = "Переход к другой игровой расе";
L["Sex Change Tooltip"] = "Сменить пол";
L["Show More options"] = "Показать дополнительные параметры";
L["Show Less Options"] = "Показать меньше параметров";					   
L["Shadow"] = "Тень";
L["Light Source"] = "Источник света";
L["Light Source Independent"] = "Свободный";
L["Light Source Interconnected"] = "Не свободный";
L["Adjustment"] = "Корректирование";
								 						   
--Animation Browser--
L["Animation"] = "Анимация";
L["Animation Tooltip"] = "Просмотр, поиск анимации";
L["Animation Variation"] = "Вариация";
L["Reset Slider"] = "Сбросить до нуля";    --reset the value of the slider to zero
L["Available Count"] = "%d доступно";

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
L["FindVisual Tooltip"] = "Покажите мне, как найти SpellVisualKitID";
L["FindVisual Guide 1"] = "Найти SpellID, используя Spell Name.";
L["FindVisual Guide 2"] = "Найдите SpellVisualID, используя SpellID на:";
L["FindVisual Guide 3"] = "Найти |cffccccccSpellVisualKitID|r используя SpellVisualID на:";
L["FindVisual Guide 4"] = "Введите |cffccccccSpellVisualKitID|r в поле визуального редактирования Narcissus. Вы не гарантированно найдете совпадение на шагах 2 или 3, и визуальное отображение не всегда корректно.";


--Dressing Room--
L["Undress"] = "Без одежды";
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
L["Switch Form To Visage"] = "Переключить на форму |cffffffff Лицо|r";
L["Switch Form To Dracthyr"] = "Переключить на форму |cffffffff Драктир|r";
L["Switch Form To Worgen"] = "Переключить на форму |cffffffff Ворген|r";
L["Switch Form To Human"] = "Переключить на форму |cffffffff Человек|r";
L["InGame Command"] = "Внутриигровая команда";	
L["Hide Player Items"] = "Скрыть предметы игрока";
L["Hide Player Items Tooltip"] = "Скрыть все, что не относится к этому набору предметов.";															 

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
L["Azerite Powers"] = "Сила Азерита";
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
L["Icon Selector"] = "Переключатель Иконок";
L["Delete Equipment Set Tooltip"] = "Удалить Набор\n|cff808080(нажмите и удерживайте кнопку)|r";
L["New Set"] = PAPERDOLL_NEWEQUIPMENTSET or "Новый набор";

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

L["Corruption Effect Format1"] = "|cffffffff%s%%|r Уменьшение скорости на";
L["Corruption Effect Format2"] = "|cffffffff%s|r начальный урон\n|cffffffff%s ярдов|r радиус";
L["Corruption Effect Format3"] = "|cffffffff%s|r повреждение\n|cffffffff%s%%|r вашего HP";
L["Corruption Effect Format4"] = "Поражение потусторонней тварью накладывает другие дебаффы";
L["Corruption Effect Format5"] = "|cffffffff%s%%|r Урон/исцеление пропорционально уровню порчи.";

--Text Overlay Frame
L["Text Overlay"] = "Наложение текста";
L["Text Overlay Button Tooltip1"] = "Простое облако разговора";															
L["Text Overlay Button Tooltip2"] = "Расширенное облако разговора";
L["Text Overlay Button Tooltip3"] = "Говорящая голова";
L["Text Overlay Button Tooltip4"] = "Плавающий субтитр";
L["Text Overlay Button Tooltip5"] = "Субтитры с черной полосой";
L["Visibility"] = "Видимость";
L["Photo Mode Frame"] = "Рамка";    --Frame for photo													 

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
L["Create A New Entry"] = "Создать новую запись";
L["Custom Achievement"] = "Пользовательское достижение";
L["Custom Achievement Description"] = "Это описание.";
L["Custom Achievement Select And Edit"] = "Выберите запись для редактирования.";
L["Cancel"] = "Отмена";
L["Color"] = "Цвет";
L["Icon"] = "Иконка";
L["Description"] = "Описание";
L["Points"] = "Точки";
L["Reward"] = "Вознаграждение";
L["Date"] = "Дата";
L["Click And Hold"] = "Нажмите и удерживайте";								   
L["To Do List"] = "Список дел";
L["Error Alert Bookmarks Too Many"] = "Вы можете добавить в список только %d достижений одновременно.";
L["Instruction Add To To Do List"] = string.format("%s Щелкните ЛКМ по незаработанному достижению, чтобы добавить его в список дел.", NARCI_MODIFIER_ALT);	
L["Instruction Remove From To Do List"] = string.format("%s ЛКМ, чтобы удалить из списка дел.", NARCI_MODIFIER_ALT);
L["DIY"] = "Сделай сам";
L["DIY Tab Tooltip"] = "Создайте пользовательское достижение для создания скриншотов."		
L["Binding Name Open Achievement"] = "Включить/выключить интерфейс достижений Narcissus";										 

--Barbershop--
L["Save New Look"] = "Сохранить новый вид";
L["No Available Slot"] = "Нет доступного слота";
L["Look Saved"] = "Смотрите Сохранено";
L["Cannot Save Forms"] = "Невозможно сохранить формы";
L["Profile"] = "Профиль";
L["Share"] =  SOCIAL_SHARE_TEXT or "Поделиться";
L["Save Notify"] = "Уведомить вас о сохранении нового внешнего вида";
L["Save Notify Tooltip"] = "Уведомление о сохранении настройки после нажатия кнопки Принять.";
L["Show Randomize Button"] = "Показать кнопку случайного отображения";
L["Coins Spent"] = "Монеты потрачены";
L["Locations"] = "Локации";
L["Location"] = "Место";
L["Visits"] = "Посещение";     --number of visits
L["Duration"] = "Время";
L["Edit Name"] = "Редактировать";
L["Delete Look"] = "Удалить";
L["Export"] = "Экспорт";
L["Import"] = "Импорт";
L["Paste Here"] = "Вставить сюда";
L["Press To Copy"] = "Press |cffcccccc".. NARCI_SHORTCUTS_COPY.."|r копировать";
L["String Copied"] = NARCI_COLOR_GREEN_MILD.. "Скопировано";
L["Failure Reason Unknown"] = "Неизвестная ошибка";
L["Failure Reason Decode"] = "Не удалось расшифровать.";
L["Failure Reason Wrong Character"] = "Текущая раса/пол/форма не соответствует импортированному профилю.";
L["Failure Reason Dragonriding"] = "Этот профиль для Dragonriding.";
L["Wrong Character Format"] = "Требует %s %s."; --e.g. Rquires Male Human
L["Import Lack Option"] = "%d |4option:options; не были найдены.";
L["Import Lack Choice"] = "%d |4choice:choices; не были найдены.";
L["Decode Good"] = "Декодировано успешно.";
L["Barbershop Export Tooltip"] = "Кодирует текущую настройку в строку, которой можно поделиться в Интернете.\n\nВы можете изменить любой текст перед двоеточием (:)";
L["Settings And Share"] = (SETTINGS or "Настройки") .." & ".. (SOCIAL_SHARE_TEXT or "Поделиться");
L["Loading Portraits"] = "Загрузка портретов";
L["Private Profile"] = "Частный";   --used by the current character
L["Public Profile"] = "Публичный";     --shared among all your characters
L["Profile Type Tooltip"] = "Выберите профиль, который будет использоваться для этого персонажа.\n\nЧастный:|cffedd100 Профиль, созданный текущим персонажем|r\n\nПубличный:|cffedd100 Профиль общий для всех ваших персонажей|r";
L["No Saves"] = "Нет сохранений";
L["Profile Migration Tooltip"] = "Вы можете скопировать существующие пресеты в общедоступный профиль.";
L["Profile Migration Okay"] = "Оки Доки";
L["Profile Migration CopyButton Tooltip"] = "Скопируйте этот пресет в свой публичный профиль.";

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
L["Splash Whats New Format"] = "Что нового в Narcissus %s";
L["See Ads"] = "Смотрите рекламу от нашего подлинного спонсора";    --Not real ads!
L["Splash Category1"] = L["Фото Режим"];
L["Splash Content1 Name"] = "Оружие";
L["Splash Content1 Description"] = "-Просматривайте и используйте все оружие в базе данных, в том числе то, которое не может быть получено игроками.";
L["Splash Content2 Name"] = "Экран выбора персонажа";
L["Splash Content2 Description"] = "-Добавьте декоративную рамку для создания (подделки) экрана выбора персонажа.";
L["Splash Content3 Name"] = "Гардеробная";
L["Splash Content3 Description"] = "-Переделан модуль гардероба.\n-Список предметов теперь включает непарные плечи и иллюзии оружия.";
L["Splash Content4 Name"] = "Браузер НПС";
L["Splash Content4 Description"] = "-Охотники могут выбирать и добавлять питомцев с помощью нового стабильного пользовательского интерфейса в режиме группового фото.";
L["Splash Category2"] = "Окно персонажа";
L["Splash Content5 Name"] = "Осколок господства";
L["Splash Content5 Description"] = "-Индикатор осколков господства появится, если вы наденете соответствующие предметы.\n-Список доступных осколков будет представлен вам, когда вы вставите предметы господства.";
L["Splash Content6 Name"] = "Медиумы";
L["Splash Content6 Description"] = "-Интерфейс медиумов обновлен. Вы можете проверить эффекты канала для более высоких рангов.";
L["Splash Content7 Name"] = "Визуальные эффекты";
L["Splash Content7 Description"] = "-Граница шестиугольника приобретает новый вид. Некоторые предметы имеют уникальный внешний вид.";

--Project Details--
L["AboutTab Developer Note"] = "Спасибо, что попробовали этот аддон! Если у вас есть какие-либо вопросы, предложения, идеи, оставьте комментарий на странице curseforge или свяжитесь со мной по...";

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
L["Search Result Overflow"] = "%s+ результатов";
L["Search Result None"] = CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS;

--Weapon Browser--
L["Draw Weapon"] = "С Оружием";
L["Unequip Item"] = "Необорудовать";
L["WeaponBrowser Guide Hotkey"] = "Укажите в какой руке держать оружие:";
L["WeaponBrowser Guide ModelType"] = "Некоторые предметы ограничены определенным типом модели:";
L["WeaponBrowser Guide DressUpModel"] = "Это будет тип по умолчанию, если ваша цель - игрок, если вы не удерживаете <%s> при его создании.";
L["WeaponBrowser Guide CinematicModel"] = "Тип модели всегда будет кинематографическим, если существо является НПС. Оружие нельзя вкладывать в ножны.";
L["Weapon Browser Specify Hand"] = "|cffffd100"..NARCI_MODIFIER_CONTROL.." + ЛКМ|r экипировать оружие в основную руку.\n|cffffd100"..NARCI_MODIFIER_ALT.." + ЛКМ|r для левой руки.";

--Pet Stables--
L["PetStable Tooltip"] = "Выберите питомца из своей конюшни";
L["PetStable Loading"] = "Получение информации о питомце";

--Domination Item--
L["Item Bonus"] = "Бонус:"  --do NOT re-translate
L["Combat Error"] = NARCI_COLOR_RED_MILD.."Выйти из боя, чтобы продолжить".."|r";
L["Extract Shard"] = "Извлечь осколок";
L["No Service"] = "Нет сети";
L["Shards Disabled"] = "Осколки Господства отключены за пределами Утроба";
L["Unsocket Gem"] = "Разблокировать камень";								   

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
L["Item Socketing Tooltip"] = "Нажмите и удерживайте, чтобы вставить";
L["No Available Gem"] = "|cffd8d8d8Нет доступных камней|r";
L["Missing Enchant Alert"] = "Предупреждение об отсутствии чар";
L["Missing Enchant"] = NARCI_COLOR_RED_MILD.."Без чар".."|r";													 
L["Socket Occupied"] = "Гнездо занято";       --Indicates that there is an (important) gem in the socket and you need to remove it first																																		  

--Statistics--
S["Narcissus Played"] = "Общее время, проведенное в Narcissus";
S["Format Since"] = "(на %s)";
S["Screenshots"] = "Скриншоты, сделанные в Narcissus";
L["Shadowlands Quests"] = "Миссии Темных земель";
S["Quest Text Reading Speed Format"] = "Завершенно: %s (%s слова)  Чтение: %s (%s слов в минуту)";

--Turntable Showcase--
L["Turntable"] = "Вращение";
L["Picture"] = "Картина";
L["Elapse"] = "Идуший";
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
L["Font Size"] = FONT_SIZE;
L["Item Name Show"] = "Показать список";
L["Item Name Hide"] = "Скрыть список";
L["Outline Show"] = "Нажмите, чтобы показать схему";
L["Outline Hide"] = "Нажмите, чтобы скрыть контур";
L["Preset"] = "Пресеты";
L["File"] = "Файл";     --File Name
L["File Tooltip"] = "Поместите собственное изображение под |cffccccccWorld of Warcraft\\retail\\Interface\\AddOns|r и впишите имя файла в это поле.\nИзображение должно быть |cffcccccc512x512|r или |cffcccccc1024x1024|r |cffccccccJPG|r";
L["Raise Level"] = "На передний план";
L["Lower Level"] = "Отправить на задний план";
L["Show Mount"] = "Показать средство передвижения";
L["Hide Mount"] = "Скрыть средство передвижения";
L["Loop Animation On"] = "Виток";
L["Click To Continue"] = "нажмите для продолжения";
L["Showcase Splash 1"] = "Создайте анимацию поворотного стола, чтобы продемонстрировать свою трансмогрификацию с Narcissus и устройством записи экрана.";
L["Showcase Splash 2"] = "Нажмите кнопку ниже, чтобы скопировать предметы из Гардеробной.";
L["Showcase Splash 3"] = "Нажмите кнопку ниже, чтобы вращать своего персонажа.";
L["Showcase Splash 4"] = "Запишите свой экран с помощью программного обеспечения для записи видео, а затем конвертируйте его в GIF.";
L["Loop Animation Alert Kultiran"] = "Виток - в настоящее время сломана на Культирасце мужчине.";																				
L["Loop Animation"] = "Циклическая анимация";									   

--Item Sets--
L["Class Set Indicator"] = "Индикатор набора классов";
L["Cycle Spec"] = "Нажмите Tab, чтобы посмотреть специализацию";
L["Paperdoll Splash 1"] = "Включить индикатор классовых наборов?";
L["Paperdoll Splash 2"] = "Выберите тему";
L["Theme Changed"] = "Тема изменена";   --the color theme has been changed

--Outfit Select--
L["Outfit"] = "Одежда";
L["Models"] = "Модели";
L["Origin Outfits"] = "Оригинальные наряды";
L["Outfit Owner Format"] = "%s's наряды";
L["SortMethod Recent"] = "Недавний";
L["SortMethod Name"] = "Название";

--Tooltip Match Format--
L["Find Cooldown"] = " время восстановления";
L["Find Recharge"] = " перезарядка";


--Talent Tree--
L["Mini Talent Tree"] = "Мини-дерево талантов";
L["Show Talent Tree When"] = "Показать дерево талантов, когда вы...";
L["Show Talent Tree Paperdoll"] = "Открыть бумажную куклу";
L["Show Talent Tree Inspection"] = "Осмотреть других игроков";
L["Truncate Talent Description"] = "Сокращенное описание таланта";
L["Appearance"] = "вид";
L["Use Class Background"] = "Использовать фон класса";
								 
L["Empty Loadout Name"] = "Имя";
L["No Save Slot Red"] = NARCI_COLOR_RED_MILD.. "Нет слота для сохранения" .."|r";
L["Save"] = "Сохранить";		
L["Create Macro Wrong Spec"] = "Этот набор был закреплен за другой специализацией!";
L["Create Marco No Slot"] = "Невозможно создать больше макросов для персонажей.";
L["Create Macro Instruction 1"] = "Поместите набор в поле ниже, чтобы объединить его с \n|cffebebeb%s|r";
L["Create Macro Instruction Edit"] = "Перетащите набор в поле ниже, чтобы изменить макрос\n|cffebebeb%s|r";
L["Create Macro Instruction 2"] = "Выберите |cff53a9ffвторичный значок|r для этого макроса.";
L["Create Macro Instruction 3"] = "Назовите этот макрос\n ";
L["Create Macro Instruction 4"] = "Перетащите этот макрос на панель действий.";
L["Create Macro In Combat"] = "Невозможно создать макрос во время боя.";
L["Create Macro Next"] = "СЛЕДУЮЩИЙ";
L["Create Marco Created"] = "СОЗДАННЫЙ";
L["Place UI"] = "Разместите UI...";
L["Place Talent UI Right"] = "справа от бумажной куклы";
L["Place Talent UI Bottom"] = "Под бумажной куклой";
L["Loadout"] = "Выгрузка";
L["No Loadout"] = "Нет загрузки";
L["PvP"] = "PvP";


--Bag Item Filter--
L["Bag Item Filter"] = "Фильтр предметов сумки";
L["Bag Item Filter Enable"] = "Включить предложение поиска и автоматический фильтр";
L["Place Window"] = "Поместите окно...";
L["Below Search Box"] = "Ниже окна поиска";
L["Above Search Box"] = "Над окном поиска";
L["Auto Filter Case"] = "Автоматически фильтрует предметы, когда вы...";
L["Send Mails"] = "Отправляете почту";
L["Create Auctions"] = "Создаете аукцион";
L["Socket Items"] = "Сокеты";
L["Item Type Mailable"] = MAIL_LABEL or "Почта";
L["Item Type Auctionable"] = AUCTIONS or "Аукцион";
L["Item Type Teleportation"] = TUTORIAL_TITLE35 or "Путешествие";
L["Item Type Gems"] = AUCTION_CATEGORY_GEMS or "Камни";
L["Item Type Reagent"] = PROFESSIONS_MODIFIED_CRAFTING_REAGENT_BASIC or "Реагент для профессии";


--Perks Program--
L["Perks Program Unclaimed Tender Format"] = "- У вас есть |cffffffff%s|r несобранные Торговые жетоны в сундуке коллекционера.";     --PERKS_PROGRAM_UNCOLLECTED_TENDER
L["Perks Program Unearned Tender Format"] = "- У вас есть |cffffffff%s|r незаработанные Торговые жетоны в журнале путешественника.";     --PERKS_PROGRAM_ACTIVITIES_UNEARNED
L["Perks Program Item Added In Format"] = "Добавлено в %s";
L["Perks Program Item Unavailable"] = "Этот товар в настоящее время недоступен.";
L["Perks Program See Wares"] = "Показать товары";
L["Perks Program No Cache Alert"] = "Поговорите с продавцами торговой лавки, чтобы увидеть товары этого месяца.";
L["Perks Program Using Cache Alert"] = "Использование кеша с вашего последнего посещения. Данные о цене могут быть неточными.";
L["Modify Default Pose"] = "Изменить позу по умолчанию";   --Change the default pose/animation/camera yaw when viewing transmog items
L["Modify Default Pose Tooltip"] = "При включении измените стандартную анимацию боя или анимацию средства передвижения в WoW на \"Стоять\" и отрегулируйте вращение, чтобы лучше представить предмет.";
L["Include Header"] = "Включает:";  --The transmog set includes...
L["Auto Try On All Items"] = "Автоматическая примерка всех предметов";
L["Full Set Cost"] = "Стоимость полного комплекта";   --Purchasing the full set will cost you x Trader's Tender
L["You Will Receive One Item"] = "Вы получите |cffffffffОДИН|r предмет:";
L["Format Item Belongs To Set"] = "Этот предмет входит в набор трансмогрификации |cffffffff[%s]|r";
L["Default Animation"] = "Анимация по умолчанию";


--Quest--
L["Auto Display Quest Item"] = "Автоматическое отображение описаний предметов заданий";
L["Drag To Move"] = "Перетаскивать";
L["Middle Click Reset Position"] = "Щелкните средней кнопкой мыши, чтобы сбросить положение."
L["Change Position"] = "Изменить позицию";


--Timerunning--
L["Primary Stat"] = "Первичная статистика";
L["Stamina"] = ITEM_MOD_STAMINA_SHORT or "Выносливость";
L["Crit"] = ITEM_MOD_CRIT_RATING_SHOR or "Критический удар";
L["Haste"] = ITEM_MOD_HASTE_RATING_SHORT or "Скорость";
L["Mastery"] = ITEM_MOD_MASTERY_RATING_SHORT or "Искусность";
L["Versatility"] = ITEM_MOD_VERSATILITY or "Универсальность";

L["Leech"] = ITEM_MOD_CR_LIFESTEAL_SHORT or "Самоисцеление";
L["Speed"] = ITEM_MOD_CR_UNUSED_3_SHORT or "Скорость передвижения";
L["Format Stat EXP"] = "+%d%% EXP Прирост";
L["Format Rank"] = AZERITE_ESSENCE_RANK or "Ранг %d";
L["Cloak Rank"] = "Ранг плаща";


--Gem Manager--
L["Gem Manager"] = "Управлять камнями";
L["Pandamonium Gem Category 1"] = "Главный";      --Major Cooldown Abilities
L["Pandamonium Gem Category 2"] = "Гаджет";     --Tinker Gem
L["Pandamonium Gem Category 3"] = PRISMATIC_GEM or "Радужный";
L["Pandamonium Slot Category 1"] = (INVTYPE_CHEST or "Грудь")..", "..(INVTYPE_LEGS or "Ноги");
L["Pandamonium Slot Category 2"] = INVTYPE_TRINKET or "Аксессуары";
L["Pandamonium Slot Category 3"] = (INVTYPE_NECK or "Шея")..", "..(INVTYPE_FINGER or "Кольца");
L["Gem Removal Instruction"] = "Щелкните ПКМ, чтобы удалить этот камень";
L["Gem Removal No Tool"] = "У вас нет инструмента, чтобы удалить этот камень целиком.";
L["Gem Removal Bag Full"] = "Освободите место в сумке, прежде чем вынимать этот камень!";
L["Gem Removal Combat"] = "Невозможно сменить драгоценный камень во время боя.";
L["Gemma Click To Activate"] = "Щелкните ЛКМ, чтобы активировать";
L["Gemma Click To Insert"] = "Щелкните ЛКМ, чтобы вставить";
L["Gemma Click Twice To Insert"] = "<ЛКМ |cffffffffДВАЖДЫ|r чтобы вставить>";
L["Gemma Click To Select"] = "<ЛКМ, чтобы выбрать>";
L["Gemma Click To Deselect"] = "<ПКМ, чтобы отменить выбор>";
L["Stat Health Regen"] = "Регенерация здоровья";
L["Gem Uncollected"] = FOLLOWERLIST_LABEL_UNCOLLECTED or "Несобранный";
L["No Sockets Were Found"] = "Совместимые камни не найдены.";
L["Click To Show Gem List"] = "<Нажмите, чтобы показать список камней>";
L["Remix Gem Manager"] = "Remix Управление камнями";
L["Select A Loadout"] = "Выберите загрузку";
L["Loadout Equipped"] = "Экипировано";
L["Loadout Equipped Partially"] = "Частично экипировано";
L["Last Used Loadout"] = "Последний используемый";
L["New Loadout"] = TALENT_FRAME_DROP_DOWN_NEW_LOADOUT or "Новая загрузка";
L["New Loadout Blank"] = "Создайте пустую загрузку";
L["New Loadout From Equipped"] = "Использовать текущую настройку";
L["Edit Loadout"] = EDIT or "Редактировать";
L["Delete Loadout One Click"] = DELETE or "Удалить";
L["Delete Loadout Long Click"] = "|cffff4800"..(DELETE or "Удалить").."|r\n|cffcccccc(нажмите и удерживайте)|r";
L["Select Gems"] = LFG_LIST_SELECT or "Выбирать";
L["Equipping Gems"] = "Экипировано...";
L["Pandamonium Sockets Available"] = "Доступные пункты";
L["Click To Open Gem Manager"] = "ЛКМ, чтобы открыть управление камней.";
L["Loadout Save Failure Incomplete Choices"] = "|cffff4800У вас есть невыбранные камни.|r";
L["Loadout Save Failure Dupe Loadout Format"] = "|cffff4800Эта загрузка такая же, как|r %s";
L["Loadout Save Failure Dupe Name Format"] = "|cffff4800Загрузка с таким названием уже существует.|r";
L["Loadout Save Failure No Name"] = "|cffff4800".. (TALENT_FRAME_DROP_DOWN_NEW_LOADOUT_PROMPT or "Введите название для новой загрузки") .."|r";
L["Empty Socket"] = GLYPH_EMPTY or "Пустой";

L["Format Equipping Progress"] = "Экипировано %d/%d";
L["Format Click Times To Equip Singular"] = "Нажмите |cff19ff19%d|r Время экипироваться";
L["Format Click Times To Equip Plural"] = "Нажмите |cff19ff19%d|r Время для экипировки";   --|4Time:Times; cannot coexist with color code?
L["Format Free Up Bag Slot"] = "Освободить %d слоты для сумки в первую очередь";
L["Format Number Items Selected"] = "%d Выбрано";
L["Format Gem Slot Stat Budget"] = "Камни в %s являются %s%% эффективными."  --e.g. Gems in trinket are 75% effective


--Game Pad--
L["GamePad Select"] = "Выбрать";
L["GamePad Cancel"] = "Отмена";
L["GamePad Use"] = "Использовать";
L["GamePad Equip"] = "Экипировка";
