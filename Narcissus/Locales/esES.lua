if not (GetLocale() == "esES") then
    return
end

local L = Narci.L
local S = Narci.L.S;

NARCI_GRADIENT = "|cffA236EFN|r|cff9448F1a|r|cff865BF2r|r|cff786DF4c|r|cff6A80F6i|r|cff5D92F7s|r|cff4FA4F9s|r|cff41B7FAu|r|cff33C9FCs|r"
MYMOG_GRADIENT = "|cffA236EFM|cff9448F1y |cff865BF2T|cff786DF4r|cff6A80F6a|cff5D92F7n|cff4FA4F9s|cff41B7FAm|cff33C9FCo|cff32c9fbg|r"

NARCI_VERSION_INFO = "1.2.0";
NARCI_DEVELOPER_INFO = "Diseñado por Peterodox";

NARCI_NEW_ENTRY_PREFIX = "|cff40C7EB";
NARCI_COLOR_GREY_85 = "|cffd8d8d8";
NARCI_COLOR_GREY_70 = "|cffb3b3b3";
NARCI_COLOR_RED_MILD = "|cffff5050";
NARCI_COLOR_GREEN_MILD = "|cff7cc576";
NARCI_COLOR_YELLOW = "|cfffced00";
NARCI_COLOR_CYAN_DARK = "5385a5";
NARCI_COLOR_PINK_DARK = "da9bc3";

NARCI_MODIFIER_CONTROL = "Ctrl";
NARCI_MODIFIER_ALT = "Alt";   --Windows
NARCI_SHORTCUTS_COPY = "Ctrl+C";

NARCI_MOUSE_BUTTON_ICON_1 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:0:16:0:16|t";   --Left Button
NARCI_MOUSE_BUTTON_ICON_2 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:16:32:0:16|t";   --Right Button
NARCI_MOUSE_BUTTON_ICON_3 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:32:48:0:16|t";   --Middle Button

if IsMacClient() then
    --Mac OS
    NARCI_MODIFIER_CONTROL = "Command";
    NARCI_MODIFIER_ALT = "Option";
    NARCI_SHORTCUTS_COPY = "Command+C";
end

NARCI_WORDBREAK_COMMA = ", ";

--Date--
L["Today"] = COMMUNITIES_CHAT_FRAME_TODAY_NOTIFICATION;
L["Yesterday"] = COMMUNITIES_CHAT_FRAME_YESTERDAY_NOTIFICATION;
L["Format Days Ago"] = "%d days ago";
L["A Month Ago"] = "1 month ago";
L["Format Months Ago"] = "%d months ago";
L["A Year Ago"] = "1 year ago";
L["Format Years Ago"] = "%d years ago";


L["Swap items"] = "Intercambiar items";
L["Press Copy"] = NARCI_COLOR_GREY_70.. "Presiona |r".. NARCI_SHORTCUTS_COPY.. NARCI_COLOR_GREY_70 .." para copiar";
L["Copied"] = NARCI_COLOR_GREEN_MILD.. "Enlace copiado";

L["Movement Speed"] = "MSPD";
L["Damage Reduction Percentage"] = "DR%";

L["Advanced Info"] = "Clic con el botón izquierdo para activar la información avanzada.";

L["Photo Mode"] = "Modo foto";
L["Photo Mode Tooltip Open"] = "Abrir la caja de herramientas de captura de pantalla.";
L["Photo Mode Tooltip Close"] = "Cerrar la caja de herramientas de captura de pantalla.";
L["Photo Mode Tooltip Special"] = "Tus capturas de pantalla guardadas en la carpeta de capturas de pantalla de WoW no incluirán este widget.";

L["Xmog Button"] = "Compartir transfiguración";
L["Xmog Button Tooltip Open"] = "Mostrar los items transfigurados en lugar del equipo real.";
L["Xmog Button Tooltip Close"] = "Mostrar los items reales en las ranuras de equipo.";
L["Xmog Button Tooltip Special"] = "Puedes probar diferentes diseños.";

L["Emote Button"] = "Hacer emote";
L["Emote Button Tooltip Open"] = "Tu personaje hace emociones con animaciones únicas.";
L["Auto Capture"] = "Captura automática";

L["HideTexts Button"] = "Ocultar textos";
L["HideTexts Button Tooltip Open"] = "Ocultar todos los nombres de las unidades, las burbujas de chat y los textos de combate.";
L["HideTexts Button Tooltip Close"] = "Restaurar los nombres de las unidades, las burbujas de chat y los textos de combate.";
L["HideTexts Button Tooltip Special"] = "La configuración anterior se restaurará cuando salgas.";

L["TopQuality Button"] = "Calidad superior";
L["TopQuality Button Tooltip Open"] = "Establecer todas las opciones de calidad de gráficos al máximo.";
L["TopQuality Button Tooltip Close"] = "Restaurar la configuración de gráficos.";

--Special Source--
L["Heritage Armor"] = "Armadura dinástica";
L["Secret Finding"] = "Hallazgo secreto";

NARCI_HEART_QUOTE_1 = "Lo esencial es invisible a los ojos.";

--Title Manager--
L["Open Title Manager"] = "Abir administrador de titulos";
L["Close Title Manager"] = "Cerrar administrador de titulos";

--Alias--
L["Use Alias"] = "Cambiar a alias";
L["Use Player Name"] = "Cambiar a "..CALENDAR_PLAYER_NAME;

L["Minimap Tooltip Double Click"] = "Double-tap";
L["Minimap Tooltip Left Click"] = "Left-click|r";
L["Minimap Tooltip To Open"] = "|cffffffffOpen "..CHARACTER_INFO;
L["Minimap Tooltip Module Panel"] = "|cffffffffOpen Module Panel";
L["Minimap Tooltip Right Click"] = "Right-click";
L["Minimap Tooltip Shift Left Click"] = "Shift + Left-click";
L["Minimap Tooltip Shift Right Click"] = "Shift + Right-click";
L["Minimap Tooltip Hide Button"] = "|cffffffffHide this button|r"
L["Minimap Tooltip Middle Button"] = "|CFFFF1000Middle button |cffffffffReset camera";
L["Minimap Tooltip Set Scale"] = "Set Scale: |cffffffff/narci [scale 0.8~1.2]";
L["Corrupted Item Parser"] = "|cffffffffToggle Corrupted Item Parser|r";
L["Toggle Dressing Room"] = "|cffffffffToggle "..DRESSUP_FRAME.."|r";

NARCI_CLIPBOARD = "Portapapeles";
L["Layout"] = "Diseño";
L["Symmetry"] = "Simetrico";
L["Asymmetry"] = "Asimetrico";
L["Copy Texts"] = "Copiar textos";
L["Syntax"] = "Sintaxis";
L["Plain Text"] = "Texto sin formato";
L["BB Code"] = "BB Code";
L["Markdown"] = "Markdown";
L["Export Includes"] = "Exportación incluye...";
NARCI_ITEM_ID = "Item ID";

L["3D Model"] = "Modelo 3D";
NARCI_EQUIPMENTSLOTS = "Ranuras de equipo";

--Preferences--

NARCI_PHOTO_MODE = L["Modo foto"];
NARCI_OVERRIDE = "Anular";
NARCI_INVALID_KEY = "Combinación de teclas no válida.";
NARCI_REQUIRE_RELOAD = NARCI_COLOR_RED_MILD.. "Es necesario recargar la UI.|r";

L["Preferences"] = "Preferencias";
L["Preferences Tooltip"] = "Click para abrir el panel de preferencias.";
L["Extensions"] = "Extensiones";
L["About"] = "Acerca de";
L["Image Filter"] = "Filtros";    --Image filter
L["Image Filter Description"] = "Todos los filtros, excepto la viñeta, se desactivarán en el modo de transfiguración.";
L["Grain Effect"] = "Efecto de grano";
L["Fade Music"] = "Fundido de entrada/salida de música";
L["Vignette Strength"] = "Fuerza de la viñeta";
L["Weather Effect"] = "Efecto meteorológico";
L["Letterbox"] = "Buzón";
L["Letterbox Ratio"] = "Ratio";
L["Letterbox Alert1"] = "¡La relación de aspecto de su monitor excede la relación seleccionada!"
L["Letterbox Alert2"] = "It is recommend to set the UI Scale to %0.1f\n(the current scale is %0.1f)"
L["Default Layout"] = "Diseño predeterminado";
L["Transmog Layout1"] = "Simetría, 1 modelo";
L["Transmog Layout2"] = "2 modelos";
L["Transmog Layout3"] = "Modo compacto";
L["Always Show Model"] = "Mostrar modelo 3D mientras se usa el diseño de simetría";
L["AFK Screen Description"] = "Abrir Narcissus automáticamente cuando estes ausente.";
L["AFK Screen Description Extra"] = "This will override ElvUI AFK Mode.";
L["Gemma"] = "\"Gemma\"";   --Don't translate
L["Gemma Description"] = "Muestra una lista de gemas al engarzar un item.";
L["Dressing Room"] = "Probador"
L["Dressing Room Description"] = "Panel de probador más grande con la capacidad de ver y copiar las listas de items de otros jugadores y generar enlaces de probador en Wowhead.";
L["General"] = "General";   --General options
L["Interface"] = "Interfaz";
L["Shortcuts"] = "Atajos";
L["Themes"] = "Temas";
L["Effects"] = "Efectos";   --UI effect
L["Camera"] = "Cámara";
L["Transmog"] = "Transfiguración";
L["Credits"] = "Créditos";
L["Border Theme Header"] = "Borde del tema";
L["Border Theme Bright"] = "Brillante";
L["Border Theme Dark"] = "Obscuro";
L["Text Width"] = "Ancho del texto";
L["Truncate Text"] = "Truncar texto";
L["Stat Sheet"] = "Hoja de estadísticas";
L["Minimap Button"] = "Botón del minimapa";
L["Fade Out"] = "Desvanecer al alejar el cursor";
L["Fade Out Description"] = "El botón se desvanece cuando se mueve el cursor fuera de él.";
L["Hotkey"] = "Hotkey";
L["Double Tap"] = "Habilitar doble toque";
L["Double Tap Description"] = "Toca dos veces la tecla vinculada al Panel de caracteres para abrir Narcissus.";
L["Show Detailed Stats"] = "Mostrar estadísticas detalladas";
L["Tooltip Color"] = "Aspecto del tema";
L["Entrance Visual"] = "Entrada Visual";
L["Entrance Visual Description"] = "Reproducir efectos visuales de hechizos cuando aparezca tu modelo.";
L["Panel Scale"] = "Escala de panel";
L["Exit Confirmation"] = "Confirmación de salida";
L["Exit Confirmation Texts"] = "¿Salir de la foto de grupo?";
L["Exit Confirmation Leave"] = "Si";
L["Exit Confirmation Cancel"] = "No";
L["Ultra-wide"] = "Ultra-wide";
L["Ultra-wide Optimization"] = "Optimización Ultra-wide";
L["Baseline Offset"] = "Baseline Offset";
L["Ultra-wide Tooltip"] = "Puedes ver esta opción porque estás utilizando un monitor %s:9.";
L["Interactive Area"] = "Área interactiva";
L["Item Socketing Tooltip"] = "Click and hold to embed";
L["No Available Gem"] = "|cffd8d8d8No available gem|r";
L["Use Bust Shot"] = "Usar plano busto";
L["Use Escape Button"] = "Tecla Esc";
L["Use Escape Button Description1"] = "Presiona la tecla Escape para salir.";
L["Use Escape Button Description2"] = "Salir haciendo click en el botón X oculto en la parte superior derecha de la pantalla.";
L["Show Module Panel Gesture"] = "Mostrar panel de módulo al pasar el cursor";
L["Independent Minimap Button"] = "No se ve afectado por otros Addons";
L["AFK Screen"] = "AFK pantalla";
L["Keep Standing"] = "Mantenerse de pie";
L["Keep Standing Description"] = "Castear/pararse de vez en cuando cuando estes AFK. Esto no evitará el cierre de sesión de AFK.";
L["None"] = "Ninguno";
L["NPC"] = "NPC";
L["Database"] = "Base de datos";
L["Creature Tooltip"] = "Información sobre la criatura";
L["RAM Usage"] = "Uso de RAM";
L["Others"] = "Otros";
L["Find Relatives"] = "Encontrar parientes";
L["Find Related Creatures Description"] = "Busca criaturas con el mismo apellido.";
L["Find Relatives Hotkey Format"] = "Presiona %s para buscar parientes.";
L["Translate Names"] = "Traducir nombres";
L["Translate Names Description On"] = "Mostrar el nombre traducido de la unidad(es) en...";
L["Translate Names Description Off"] = "";
L["Select A Language"] = "Idioma seleccionado:";
L["Select Multiple Languages"] = "Seleccionar idioma:";
L["Load on Demand"] = "Cargar bajo demanda";
L["Load on Demand Description On"] = "No carga la base de datos hasta que se usen las funciones de búsqueda.";
L["Load on Demand Description Off"] = "Cargar la base de datos de criaturas cuando se inicie sesión.";
L["Load on Demand Description Disabled"] = NARCI_COLOR_YELLOW.. "Esta palanca está bloqueada porque has habilitado la información sobre herramientas de la criatura.";
L["Tooltip"] = "Descripción emergente";
L["Name Plate"] = "Placa de nombre";
L["Y Offset"] = "Y Offset";
L["Sceenshot Quality"] = "Calidad de la captura de pantalla";
L["Screenshot Quality Description"] = "Mayor calidad da como resultado un tamaño de archivo más grande.";
L["Camera Movement"] = "Movimiento de la cámara";
L["Orbit Camera"] = "Cámara orbital";
L["Orbit Camera Description On"] = "Cuando abras este panel de personajes, la cámara girará hacia tu frente y comenzará a orbitar.";
L["Orbit Camera Description Off"] = "Cuando abras este panel de personajes, la cámara se acercará sin rotación.";
L["Camera Safe Mode"] = "Modo seguro de la cámara";
L["Camera Safe Mode Description"] = "Deshabilitar completamente la función ActionCam después de cerrar este complemento.";
L["Camera Safe Mode Description Extra"] = "No se ha activado porque se está utilizando DynamicCam."
L["Camera Transition"] = "Transición de cámara";
L["Camera Transition Description On"] = "La cámara se moverá suavemente a la posición predeterminada cuando abras este panel de personajes.";
L["Camera Transition Description Off"] = "La transición de la cámara se vuelve instantánea. Comienza desde la segunda vez que usas este panel de caracteres.\nLa transición instantánea anulará el ajuste preestablecido de la cámara #4.";
L["Interface Options Tab Description"] = "También puedes acceder a este panel haciendo click en el botón de engranaje junto a la barra de herramientas en la parte inferior izquierda de su pantalla mientras usa Narcissus.";
L["Soulbinds"] = COVENANT_PREVIEW_SOULBINDS;
L["Conduit Tooltip"] = "Efectos de conducto de rangos superiores";
L["Paperdoll Widget"] = "Artilugio de muñeca de papel";
L["Item Tooltip"] = "Item Tooltip";
L["Style"] = "Estilo";
L["Tooltip Style 1"] = "Próxima generación";
L["Tooltip Style 2"] = "Original";
L["Addtional Info"] = "Información adicional";
L["Item ID"] = "Item ID";

--Model Control--
NARCI_STAND_IDLY = "Permanecer inactivo";
NARCI_RANGED_WEAPON = "Arma a distancia";
NARCI_MELEE_WEAPON = "Arma cuerpo a cuerpo";
NARCI_SPELLCASTING = "Lanzamiento de hechizos";
NARCI_ANIMATION_ID = "Animation ID";
NARCI_LINK_LIGHT_SETTINGS = "Link fuentes de luz";
NARCI_LINK_MODEL_SCALE = "Link escalas de modelo";
NARCI_GROUP_PHOTO_AVAILABLE = "Ahora disponible en Narcissus";
NARCI_GROUP_PHOTO_NOTIFICATION = "Por favor, selecciona un objetivo.";
NARCI_GROUP_PHOTO_STATUS_HIDDEN = "Oculto";
NARCI_DIRECTIONAL_AMBIENT_LIGHT = "Luz direccional/ambiental";
NARCI_DIRECTIONAL_AMBIENT_LIGHT_TOOLTIP = "Cambia entre:\n- luz direccional que puede ser bloqueada por un objeto y proyectar sombras\n- luz ambiental que influye en todo el modelo";

L["Group Photo"] = "Foto de grupo";
L["Reset"] = "Reiniciar";
L["Actor Index"] = "Índice";
L["Move To Font"] = "|cff40c7ebFront|r";
L["Actor Index Tooltip"] = "Arrastre un botón de índice para cambiar la capa del modelo.";
L["Play Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Reproducir esta animación\n"..NARCI_MOUSE_BUTTON_ICON_2.."Reanudar todos los modelos\animaciones";
L["Pause Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Pausar esta animación\n"..NARCI_MOUSE_BUTTON_ICON_2.."Pausar todos los modelos\animaciones";
L["Save Layers"] = "Guardar capas";
L["Save Layers Tooltip"] = "Captura automáticamente 6 capturas de pantalla para la composición de imágenes.\nNo mueva el cursor ni haga clic en ningún botón durante este proceso. De lo contrario, tu personaje podría volverse invisible después de salir del complemento. Si eso sucediera, usa este comando:\n/console showplayer";
L["Ground Shadow"] = "Sombra del suelo";
L["Ground Shadow Tooltip"] = "Agrega una sombra de suelo móvil debajo de tu modelo.";
L["Hide Player"] = "Ocultar jugador";
L["Hide Player Tooltip"] = "Hace que tu personaje sea invisible para ti.";
L["Virtual Actor"] = "Virtual";
L["Virtual Actor Tooltip"] = "Only the spell visual on this model is visible."
L["Self"] = "Self";
L["Target"] = "Objetivo";
L["Compact Mode Tooltip"] = "Solo usa la parte izquierda de la pantalla para presentar tu transfiguración.";
L["Toggle Equipment Slots"] = "Alternar ranuras de equipo";
L["Toggle Text Mask"] = "Alternar máscara de texto";
L["Toggle 3D Model"] = "Alternar modelo 3D";
L["Toggle Model Mask"] = "Alternar máscara de modelo";
L["Show Color Sliders"] = "Mostrar controles deslizantes de color";
L["Show Color Presets"] = "Mostrar ajustes preestablecidos de color";
L["Keep Current Form"] = "Mantener"..NARCI_MODIFIER_ALT.."para mantener la forma de cambio de forma.";
L["Race Change Tooltip"] = "Cambiar a otra raza jugable";
L["Sex Change Tooltip"] = "Cambiar género";
L["Show More options"] = "Mostrar más opciones";
L["Show Less Options"] = "Mostrar menos opciones";
L["Shadow"] = "Sombra";
L["Light Source"] = "Fuente de luz";
L["Light Source Independent"] = "Independiente";
L["Light Source Interconnected"] = "Interconectado";


--Animation Browser--
L["Animation"] = "Animación";
L["Animation Tooltip"] = "Navegar, buscar animaciones";
L["Animation Variation"] = "Variación de animación";
L["Reset Slider"] = "Restablecer a cero";


--Spell Visual Browser--
L["Visuals"] = "Visuales";
L["Visual ID"] = "Visual ID";
L["Animation ID Abbre"] = "Anim. ID";
L["Category"] = "Categoría";
L["Sub-category"] = "Subcategoría";
L["My Favorites"] = "Mis favoritos";
L["Reset Visual Tooltip"] = "Eliminar elementos visuales no aplicados";
L["Remove Visual Tooltip"] = "Left-click: Remove a selected visual\nLong-click: Remove all applied visuals";
L["Apply"] = "Apply";
L["Applied"] = "Applied";   --Viusals that were "Applied" to the model
L["Remove"] = "Eliminar";
L["Rename"] = "Renombrar";
L["Refresh Model"] = "Actualizar modelo";
L["Toggle Browser"] = "Toggle spell visual browser";
L["Next And Previous"] = NARCI_MOUSE_BUTTON_ICON_1.."Ir al siguiente\n"..NARCI_MOUSE_BUTTON_ICON_2.."Ir al anterior";
L["New Favorite"] = "Nuevo favorito";
L["Favorites Add"] = "Agregar a mis favoritos";
L["Favorites Remove"] = "Quitar de favoritos";
L["Auto-play"] = "Auto-play";   --Auto-play suggested animation
L["Auto-play Tooltip"] = "Auto-play the animation\nthat is tied to the selected visual.";
L["Delete Entry Plural"] = "Will delete %s entries";
L["Delete Entry Singular"] = "Will delete %s entry";
L["History Panel Note"] = "Applied visuals will be shown here";
L["Return"] = "Return";
L["Close"] = "Cerrar";
L["Change Pack"] = "Cambiar paquete";

--Dressing Room--
L["Undress"] = "Desvestir";
L["Favorited"] = "Favorito";
L["Unfavorited"] = "No favorito";
L["Item List"] = "Lista de items";
L["Use Target Model"] = "Usar modelo del objetivo";
L["Use Your Model"] = "Usar tu modelo";
L["Cannot Inspect Target"] = "No se puede inspeccionar al objetivo"
L["External Link"] = "Enlace externo";
L["Add to MogIt Wishlist"] = "Añadir a la lista de deseos de MogIt";
L["Show Taint Solution"] = "How to solve this issue?";
L["Taint Solution Step1"] = "1. Reload your UI.";
L["Taint Solution Step2"] = "2. "..NARCI_MODIFIER_CONTROL.." + Left-click en un item para abrir el probador.";

--NPC Browser--
NARCI_NPC_BROWSER_TITLE_LEVEL = ".*%?%?.?";      --Level ?? --Use this to check if the second line of the tooltip is NPC's title or unit type
L["NPC Browser"] = "Buscador NPC";
L["NPC Browser Tooltip"] = "Elige un NPC de la lista.";
L["Search for NPC"] = "Buscar NPC";
L["Name or ID"] = "Nombre o ID";
L["NPC Has Weapons"] = "Tiene armas exclusivas";
L["Retrieving NPC Info"] = "Recuperando información de NPC";
L["Loading Database"] = "Cargando base de datos...\nLa pantalla podría congelarse durante unos segundos.";
L["Other Last Name Format"] = "Otro "..NARCI_COLOR_GREY_70.."%s(s)|r:\n";
L["Too Many Matches Format"] = "\nOver %s matches.";

--Solving Lower-case or Abbreviation Issue--
NARCI_STAT_STRENGTH = SPEC_FRAME_PRIMARY_STAT_STRENGTH;
NARCI_STAT_AGILITY = SPEC_FRAME_PRIMARY_STAT_AGILITY;
NARCI_STAT_INTELLECT = SPEC_FRAME_PRIMARY_STAT_INTELLECT;
NARCI_CRITICAL_STRIKE = STAT_CRITICAL_STRIKE;


--Equipment Comparison--
NARCI_AZERITE_POWERS = "Poderes de azerita";
L["Gem Tooltip Format1"] = "%s and %s";
L["Gem Tooltip Format2"] = "%s, %s and %s more...";

--Equipment Set Manager
L["Equipped Item Level Format"] = "Equipado %s";
L["Equipped Item Level Tooltip"] = "El nivel de objeto medio de los items equipados actualmente.";
L["Equipment Manager"] = EQUIPMENT_MANAGER;
L["Toggle Equipment Set Manager"] = NARCI_MOUSE_BUTTON_ICON_1.."Gestor de conjuntos de equipo.";
L["Duplicated Set"] = "Conjunto duplicado";
L["Low Item Level"] = "Nivel de item bajo";
L["1 Missing Item"] = "1 item perdido";
L["n Missing Items"] = "%s items perdidos";
L["Update Items"] = "Actualizar items";
L["Don't Update Items"] = "No actualizar items";
L["Update Talents"] = "Actualizar talentos";
L["Don't Update Talents"] = "No actualizar talentos";
L["Old Icon"] = "Icono antiguo";
L["NavBar Saved Sets"] = "Guardado:";   --A Saved Equipment Set
L["NavBar Incomplete Sets"] = INCOMPLETE;
NARCI_ICON_SELECTOR = "Selector de iconos";
NARCI_DELETE_SET_WITH_LONG_CLICK = "Eliminar conjunto\n|cff808080(click and hold)|r";

--Corruption System
L["Corruption System"] = "Corruption";
L["Eye Color"] = "Eye Color";
L["Blizzard UI"] = "Blizzard UI";
L["Corruption Bar"] = "Corruption Bar";
L["Corruption Bar Description"] = "Enable the corruption bar next to the Character Pane.";
L["Corruption Debuff Tooltip"] = "Debuff Tooltip";
L["Corruption Debuff Tooltip Description"] = "Replace the default negative effects tooltip with its numeric counterpart.";
L["No Corrupted Item"] = "You haven't equipped any corrupted item.";

L["Crit Gained"] = CRIT_ABBR.." Gained";
L["Haste Gained"] = STAT_HASTE.." Gained";
L["Mastery Gained"] = STAT_MASTERY.." Gained";
L["Versatility Gained"] = STAT_VERSATILITY.." Gained";

L["Proc Crit"] = "Proc "..CRIT_ABBR;
L["Proc Haste"] = "Proc "..STAT_HASTE;
L["Proc Mastery"] = "Proc "..STAT_MASTERY;
L["Proc Versatility"] =  "Proc "..STAT_VERSATILITY;

L["Critical Damage"] = CRIT_ABBR.."DMG";

L["Corruption Effect Format1"] = "|cffffffff%s%%|r speed reduced";
L["Corruption Effect Format2"] = "|cffffffff%s|r initial damage\n|cffffffff%s yd|r radius";
L["Corruption Effect Format3"] = "|cffffffff%s|r damage\n|cffffffff%s%%|r of your HP";
L["Corruption Effect Format4"] = "Struck by the Thing From Beyond triggers other debuffs";
L["Corruption Effect Format5"] = "|cffffffff%s%%|r damage\\healing taken modified";

--Text Overlay Frame
L["Text Overlay Button Tooltip1"] = "Globo de diálogo simple";
L["Text Overlay Button Tooltip2"] = "Globo de diálogo avanzado";
L["Text Overlay Button Tooltip3"] = "Globo de diálogo en la cabeza";
L["Text Overlay Button Tooltip4"] = "Subtítulo flotante";
L["Text Overlay Button Tooltip5"] = "Subtítulo de barra negra";
L["Visibility"] = "Visibilidad";

--Achievement Frame--
L["Use Achievement Panel"] = "Use As Primary Achievement Panel";
L["Use Achievement Panel Description"] = "Replace the default achievement toast. Enable tooltip enhancement. Click tracked achievements to open this panel.";
L["Incomplete First"] = "Incomplete First";
L["Earned First"] = "Earned First";
L["Settings"] = "Ajustes";
L["Next Prev Card"] = "Next/Prev Card";
L["Track"] = "Track";   --Track achievements
L["Show Unearned Mark"] = "Show Unearned Mark";
L["Show Unearned Mark Description"] = "Mark the achievements that were not earned by me with a red X.";
L["Show Dates"] = "Mostrar fecha";
L["Hide Dates"] = "Ocultar fecha";
L["Pinned Entries"] = "Pinned Entries";
L["Pinned Entry Format"] = "Pinned  %d/%d";


--Barbershop--
L["Save New Look"] = "Guardar el nuevo aspecto";
L["No Available Slot"] = "No hay ranura disponible";
L["Look Saved"] = "Apariencia guardada";
L["Cannot Save Forms"] = "No se pueden guardar los formularios";
L["Profiles"] = "Perfiles";
L["Save Notify"] = "Notificación para guardar la nueva apariencia";
L["Show Randomize Button"] = "Mostrar botón de apariencia aleatoria";
L["Coins Spent"] = "Monedas gastadas";
L["Locations"] = "Ubicaciones";
L["Location"] = "Ubicación";
L["Visits"] = "Visitas ";     --number of visits
L["Duration"] = "Duración";
L["Edit Name"] = "Editar nombre";
L["Delete Look"] = "Borrar aspecto\n(Pinchar y mantener)";

--Tutorial--
L["Alert"] = "Advertencia";
L["Race Change"] = "Cambio de raza/género";
L["Race Change Line1"] = "Puedes volver a cambiar tu raza y género. Pero hay algunas limitaciones:\n1. Tus armas desaparecerán.\n2. Los efectos de hechizos ya no se pueden eliminar..\n3. No funciona con otros jugadores o NPC.";
L["Guide Spell Headline"] = "Try or Apply";
L["Guide Spell Criteria1"] = "Left-click to TRY";
L["Guide Spell Criteria2"] = "Right-click to APPLY";
L["Guide Spell Line1"] = "Most spell visuals that you add by clicking left button will fade away in seconds, while those you add by clicking right button will not.\n\nNow please move to an entry then:";
L["Guide Spell Choose Category"] = "You can add spell visuals to your model. Choose any category you like. Then choose a subcategory.";
L["Guide History Headline"] = "History Panel";
L["Guide History Line1"] = "At most 5 recently applied visuals can retain here. You can select one and delete it by clicking the Remove button on the right end.";
L["Guide Refresh Line1"] = "Use this button to remove all unapplied spell visuals. Those that were in the history panel will be reapplied.";
L["Guide Input Headline"] = "Manual Input";
L["Guide Input Line1"] = "You may also input a SpellVisualKitID yourself. As of 9.0, Its cap is around 155,000.\nYou can use your mousewheel to try the next/previous ID.\nVery few IDs can crash the game.";
L["Guide Equipment Manager Line1"] = "Double-click: Use a set\nRight-click: Edit a set.\n\nThis button's previous function has been moved to Preferences.";
L["Guide Model Control Headline"] = "Control de modelo";
L["Guide Model Control Line1"] = format("Este modelo comparte las mismas acciones del mouse que usas en el probador, plus:\n\n1.Hold %s and Left Button: Girar el modelo alrededor Y-axis.\n2.Hold %s and Right Button: Ejecutar zoom de barrido.", NARCI_MODIFIER_ALT, NARCI_MODIFIER_ALT);
L["Guide Minimap Button Headline"] = "Botón Minimapa";
L["Guide Minimap Button Line1"] = "El botón del minimapa de Narcissus ahora puede ser manejado por otros complementos.\nPuedes cambiar esta opción en el Panel de Preferencias. Puede requerir una recarga de UI."
L["Guide NPC Entrance Line1"] = "Puedes agregar cualquier NPC a tu escena."
L["Guide NPC Browser Line1"] = "Notable NPCs are listed in the catalog below.\nYou can also search for ANY creatures by name or ID.\nNotice that the first time you use the search function this login, it could take a few seconds to build the search table and your screen might freeze as well.\nYou may untoggle the \"Load on Demand\" option in the Preference Pane so that the database will be constructed right after you log in.";

    
--Splash--
NARCI_SPLASH_WHATS_NEW_FORMAT = "Novedades en Narcissus %s";
L["See Ads"] = "Ver los anuncios de nuestro auténtico patrocinador";    --Not real ads!
L["Splash Category1"] = L["Modo foto"];
L["Splash Content1 Name"] = "Buscador de armas";
L["Splash Content1 Description"] = "-Ver y utilizar todas las armas de la base de datos, incluidas las que no pueden ser obtenidas por los jugadores.";
L["Splash Content2 Name"] = "Pantalla de selección de personajes";
L["Splash Content2 Description"] = "-Añade un marco decorativo para crear (falsamente) tu propia pantalla de selección de personajes.";
L["Splash Content3 Name"] = "Probador";
L["Splash Content3 Description"] = "-El módulo del probador ha sido rediseñado.\n-La lista de objetos ahora incluye hombros sin pareja e ilusiones de armas.";
L["Splash Content4 Name"] = "Establo de mascotas";
L["Splash Content4 Description"] = "-Los cazadores pueden seleccionar y añadir mascotas mediante una nueva interfaz de usuario estable en el modo de foto de grupo.";
L["Splash Category2"] = "Marco de personaje";
L["Splash Content5 Name"] = "Fragmento de dominación";
L["Splash Content5 Description"] = "-El indicador del fragmento de dominación aparecerá si equipas los items pertinentes.\n-A list of available shards will be presented to you when you socket domination items.\n-Extract shards with a single click.";
L["Splash Content6 Name"] = "Nexo de almas";
L["Splash Content6 Description"] = "-Se ha actualizado la interfaz de usuario de los nexos de almas. Puedes comprobar los efectos de los conductos de los rangos superiores.";
L["Splash Content7 Name"] = "Visuals";
L["Splash Content7 Description"] = "-El borde del elemento hexagonal adquiere un nuevo aspecto. Ciertos items tienen apariencias únicas.";

--Project Details--
NARCI_ALL_PROJECTS = "Todos los proyectos:";
NARCI_PROJECT_DETAILS = "|cFFFFD100Desarrollador: Peterodox\nFecha de lanzamiento: Junio 2, 2022|r\n\n¡Gracias por probar este complemento! Si tienes algún problema, sugerencia o idea, deja un comentario en la página de Curseforge o contáctame en...";
NARCI_PROJECT_AAA_TITLE = "|cff008affA|cff0d8ef2z|cff1a92e5e|cff2696d9r|cff339acco|cff409ebft|cff4da1b2h |cff59a5a6A|cff66a999d|cff73ad8cv|cff7fb180e|cff8cb573n|cff99b966t|cffa6bd59u|cffb2c14dr|cffbfc440e |cffccc833A|cffd9cc26l|cffe5d01ab|cfff2d40du|cffffd800m|r";
NARCI_PROJECT_AAA_SUMMARY = "Explora lugares de interés, recopila historias y fotos de todo Azeroth.|cff636363";
NARCI_PROJECT_NARCISSUS_SUMMARY = "Un panel de personajes inmersivo y tu herramienta de captura de pantalla definitiva.";


--Credits--
L["Credit List Extra"] = "Marlamin | WoW.tools\nKeyboardturner | Avid Bug Finder(Generator)\nHubbotu | Translator - Russian\nRomanv  | Translator - Spanish\nMeorawr | Wondrous Wisdomball";

--Conversation--
L["Q1"] = "¿Que es esto?";
L["Q2"] = "Lo sé. Pero, ¿por qué es tan grande?";
L["Q3"] = "Eso no es gracioso. Sólo necesito uno normal.";
L["Q4"] = "Bueno. ¿Qué pasa si quiero desactivarlo?";
L["Q5"] = "Una cosa más, ¿podrías prometerme que no habrá más bromas?";
L["A1"] = "Aparentemente, este es un cuadro de diálogo de confirmación de salida. Aparece cuando intentas salir del modo de foto de grupo presionando la tecla de acceso rápido.";
L["A2"] = "Ja, eso es lo que ella dijo";
L["A3"] = "Bien... bien..."
L["A4"] = "Lo siento, no puedes. Es por seguridad, ya sabes.";

--Search--
L["Search Result Singular"] = "%s resultado";
L["Search Result Plural"] = "%s resultados";
L["Search Result Overflow"] = "%s+ resultados";
L["Search Result None"] = CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS;

--Weapon Browser--
L["Draw Weapon"] = "Equipar arma";
L["Unequip Item"] = "Desequipar";
L["WeaponBrowser Guide Hotkey"] = "Especificar qué mano debe sostener el arma:";
L["WeaponBrowser Guide ModelType"] = "Algunos items están limitados a cierto tipo de modelo:";
L["WeaponBrowser Guide DressUpModel"] = "Este será el tipo predeterminado si tu objetivo es un jugador, a menos que estés sosteniendo <%s> mientras lo creas.";
L["WeaponBrowser Guide CinematicModel"] = "El tipo de modelo siempre será Cinemático si la criatura es un NPC. No puedes enfundar armas.";

--Pet Stables--
L["PetStable Tooltip"] = "Elige una mascota de tu establo";
L["PetStable Loading"] = "Recuperando información de la mascota";

--Domination Item--
L["Item Bonus"] = "Bonus:";
L["Combat Error"] = NARCI_COLOR_RED_MILD.."Abandonar combate para seguir".."|r";
L["Extract Shard"] = "Extraer fragmento";
L["No Service"] = "Sin servicio";
L["Shards Disabled"] = "Los fragmentos de Dominación están desactivados fuera de las Fauces.";

--Mythic+ Leaderboard--
L["Mythic Plus"] = "Mítica+";
L["Mythic Plus Abbrev"] = "M+";
L["Total Runs"] = "Total de Runs: ";
L["Complete In Time"] = "En tiempo";
L["Complete Over Time"] = "Fuera de tiempo";
L["Runs"] = "Runs";

--Equipment Upgrade--
L["Temp Enchant"] = "Temporary Enchants";       --ERR_TRADE_TEMP_ENCHANT_BOUND
L["Owned"] = "Owned";                           --Only show owned items
L["At Level"] = "At level %d:";                 --Enchants scale with player level
L["No Item Alert"] = "No compatible items";
L["Click To Insert"] = "Click to Insert";       --Insert a gem
L["No Socket"] = "No socket";
L["No Other Item For Slot"] = "No other item for %s";       --where %s is the slot name
L["In Bags"] = "En bolsas";

--Statistics--
S["Narcissus Played"] = "Tiempo total gastado en Narcissus";
S["Format Since"] = "(since %s)";
S["Screenshots"] = "Capturas de pantalla tomadas con Narcissus";

--Turntable Showcase--
L["Turntable"] = "Base giratoria";
L["Picture"] = "Imagen";
L["Elapse"] = "Transcurrir";
L["Turntable Tab Animation"] = "Animación";
L["Turntable Tab Image"] = "Imagen";
L["Turntable Tab Quality"] = "Calidad";
L["Turntable Tab Background"] = "Fondo";
L["Spin"] = "Girar";
L["Sync"] = "Sync";
L["Rotation Period"] = "Período";
L["Period Tooltip"] = "El tiempo que tarda en completar un giro.\nTambién debería ser el |cffccccccla duración del corte|r de tu GIF o video.";
L["MSAA Tooltip"] = "Modifica temporalmente el suavizado para suavizar los bordes irregulares a costa del rendimiento.";
L["Image Size"] = "Tamaño de la imagen";
L["Font Size"] = FONT_SIZE;
L["Item Name Show"] = "Mostrar nombres de los items";
L["Item Name Hide"] = "Ocultar nombres de los items";
L["Outline Show"] = "Click para mostrar el esquema";
L["Outline Hide"] = "Click para ocultar el esquema";
L["Preset"] = "Preestablecido";
L["File"] = "Archivo";     --File Name
L["File Tooltip"] = "Pon tu propia imagen debajo |cffccccccWorld of Warcraft\\retail\\Interface\\AddOns|r e inserte el nombre del archivo en este cuadro.\nLa imagen debe ser |cffcccccc512x512|r o |cffcccccc1024x1024|r |cffccccccJPG|r file";
L["Raise Level"] = "Traer al frente";
L["Lower Level"] = "Enviar hacia atras";
L["Click To Continue"] = "click para continuar";
L["Showcase Splash 1"] = "Crea animaciones en movimiento para enseñar tu transfiguración con Narcissus y la grabadora de pantalla.";
L["Showcase Splash 2"] = "Click en el botón de abajo para copiar elementos del probador.";
L["Showcase Splash 3"] = "Click en el botón de abajo para girar tu personaje.";
L["Showcase Splash 4"] = "Graba la pantalla con el software de grabación de video y luego conviértela a GIF.";

--Item Sets--
L["Cycle Spec"] = "Presiona Tab para recorrer las especificaciones";
L["Paperdoll Splash 1"] = "¿Habilitar el indicador de conjunto de clases?";
L["Paperdoll Splash 2"] = "Elige un tema";

--Outfit Select--
L["Outfit"] = "Atuendo";
L["Models"] = "Modelos";
L["Origin Outfits"] = "Atuendos originales";
L["Outfit Owner Format"] = "Atuendos de %s";
L["SortMethod Recent"] = "Reciente";
L["SortMethod Name"] = "Nombre";