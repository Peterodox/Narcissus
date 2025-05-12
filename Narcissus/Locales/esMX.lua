--Translator: HectorZaGa

if not (GetLocale() == "esMX") then
    return;
end

local L = Narci.L;
local S = Narci.L.S;

NARCI_GRADIENT = "|cffd177ffN|cffc480fba|cffb787f6r|cffa98ef2c|cff9a94edi|cff8a9ae9s|cff789fe5s|cff63a4e0u|cff48a8dcs|r";

L["Developer Info"] = "Desarrolado por Peterodox";

NARCI_MODIFIER_CONTROL = "Ctrl";
NARCI_MODIFIER_ALT = "Alt";   --Windows
NARCI_SHORTCUTS_COPY = "Ctrl+C";

NARCI_MOUSE_BUTTON_ICON_1 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:0:16:0:16|t";   --Botón Izquierdo
NARCI_MOUSE_BUTTON_ICON_2 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:16:32:0:16|t";   --Botón Derecho
NARCI_MOUSE_BUTTON_ICON_3 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:32:48:0:16|t";   --Botón Central

if IsMacClient() then
    --Mac OS
    NARCI_MODIFIER_CONTROL = "Command";
    NARCI_MODIFIER_ALT = "Option";
    NARCI_SHORTCUTS_COPY = "Command+C";
end

NARCI_WORDBREAK_COMMA = ", ";

--Fecha--
L["Today"] = COMMUNITIES_CHAT_FRAME_TODAY_NOTIFICATION;
L["Yesterday"] = COMMUNITIES_CHAT_FRAME_YESTERDAY_NOTIFICATION;
L["Format Days Ago"] = "%d días atrás";
L["A Month Ago"] = "Hace 1 mes";
L["Format Months Ago"] = "%d meses atrás";
L["A Year Ago"] = "Hace 1 año";
L["Format Years Ago"] = "%d años atrás";
L["Version Colon"] = (GAME_VERSION_LABEL or "Versión")..": ";
L["Date Colon"] = "Fecha: ";
L["Day Plural"] = "Días";
L["Day Singular"] = "Día";
L["Hour Plural"] = "Horas";
L["Hour Singular"] = "Hora";

L["Swap items"] = "Intercambiar objetos";
L["Press Copy"] = NARCI_COLOR_GREY_70.. "Presiona |r".. NARCI_SHORTCUTS_COPY.. NARCI_COLOR_GREY_70 .." para copiar";
L["Copied"] = NARCI_COLOR_GREEN_MILD.. "Enlace copiado|r";
L["Movement Speed"] = "Vel. Mov.";
L["Damage Reduction Percentage"] = "Reducción de daño %";
L["Advanced Info"] = "Haz clic izquierdo para alternar información avanzada.";
L["Restore On Exit"] = "\nSe restaurarán tus configuraciones anteriores al salir.";

L["Photo Mode"] = "Modo foto";
L["Photo Mode Tooltip Open"] = "Abre la caja de herramientas para capturar pantalla.";
L["Photo Mode Tooltip Close"] = "Cierra la caja de herramientas para capturar pantalla.";
L["Photo Mode Tooltip Special"] = "Las capturas de pantalla en la carpeta de capturas de pantalla de wow no incluirán este widget.";

L["Toolbar Mog Button"] = "Modo foto";
L["Toolbar Mog Button Tooltip"] = "Muestra tu transfiguración o crea una cabina de fotos donde puedas agregar otros jugadores y PNJs.";

L["Toolbar Emote Button"] = "Hacer emote";
L["Toolbar Emote Button Tooltip"] = "Usa los emotes con animaciones únicas.";
L["Auto Capture"] = "Captura automática";

L["Toolbar HideTexts Button"] = "Ocultar textos";
L["Toolbar HideTexts Button Tooltip"] = "Oculta todos los nombres, bocadillos de chat y textos de combate." ..L["Restore On Exit"];

L["Toolbar TopQuality Button"] = "Calidad máxima";
L["Toolbar TopQuality Button Tooltip"] = "Ajusta todas las opciones en la configuración de gráficos al máximo." ..L["Restore On Exit"];

L["Toolbar Location Button"] = "Ubicación del jugador";
L["Toolbar Location Button Tooltip"] = "Muestra el nombre de la zona actual y las coordenadas del jugador."

L["Toolbar Camera Button"] = "Cámara";
L["Toolbar Camera Button Tooltip"] = "Cambia temporalmente la configuración de la cámara."

L["Toolbar Preferences Button Tooltip"] = "Abre el panel de preferencias.";

--Fuente Especial--
L["Heritage Armor"] = "Armadura de legado";
L["Secret Finding"] = "Hallazgo secreto";

L["Heart Azerite Quote"] = "Lo esencial es invisible a los ojos.";

--Gestor de Títulos--
L["Open Title Manager"] = "Abrir gestor de títulos";
L["Close Title Manager"] = "Cerrar gestor de títulos";

--Alias--
L["Use Alias"] = "Cambiar a alias";
L["Use Player Name"] = "Cambiar a "..CALENDAR_PLAYER_NAME;

L["Minimap Tooltip Double Click"] = "Doble clic";
L["Minimap Tooltip Left Click"] = "Clic izquierdo";
L["Minimap Tooltip To Open"] = "|cffffffffabrir "..CHARACTER_INFO;
L["Minimap Tooltip Module Panel"] = "|cffffffffabrir panel del módulo";
L["Minimap Tooltip Right Click"] = "Clic derecho";
L["Minimap Tooltip Shift Left Click"] = "Mayús + Clic izquierdo";
L["Minimap Tooltip Shift Right Click"] = "Mayús + Clic derecho";
L["Minimap Tooltip Hide Button"] = "|cffffffffocultar este botón|r"
L["Minimap Tooltip Middle Button"] = "|cffff1000botón central |cffffffffrestablecer cámara";
L["Minimap Tooltip Set Scale"] = "Establecer escala: |cffffffff/narci [escala 0.8~1.2]";
L["Corrupted Item Parser"] = "|cffffffffalternar analizador de objetos corruptos|r";
L["Toggle Dressing Room"] = "|cffffffffalternar "..DRESSUP_FRAME.."|r";

L["Layout"] = "Diseño";
L["Symmetry"] = "Simetría";
L["Asymmetry"] = "Asimetría";
L["Copy Texts"] = "Copiar lista de objetos";
L["Syntax"] = "Sintaxis";
L["Plain Text"] = "Texto sin formato";
L["BB Code"] = "BB Code";
L["Markdown"] = "Markdown";
L["Export Includes"] = "Exportación incluye...";

L["3D Model"] = "Modelo 3D";
L["Equipment Slots"] = "Ranuras de equipo";

--Preferencias--
L["Override"] = "Anular";
L["Invalid Key"] = "Combinación de teclas inválida.";

L["Preferences"] = "Preferencias";
L["Preferences Tooltip"] = "Haz clic para abrir el panel de preferencias.";
L["Extensions"] = "Extensiones";
L["About"] = "Acerca de";
L["Image Filter"] = "Filtros";    --Filtro de imagen
L["Image Filter Description"] = "Todos los filtros, excepto el viñeteado, se desactivarán en el modo de transfiguración.";
L["Grain Effect"] = "Efecto granulado";
L["Fade Music"] = "Desvanecer música";
L["Vignette Strength"] = "Intensidad del viñeteado";
L["Weather Effect"] = "Efecto climático";
L["Letterbox"] = "Buzón";
L["Letterbox Ratio"] = "Ratio";
L["Letterbox Alert1"] = "¡La relación de aspecto de tu monitor supera la relación seleccionada!"
L["Letterbox Alert2"] = "Se recomienda ajustar la escala de la UI a %0.1f\n(la escala actual es %0.1f)"
L["Default Layout"] = "Diseño predeterminado";
L["Transmog Layout1"] = "Simetría, 1 modelo";
L["Transmog Layout2"] = "2 modelos";
L["Transmog Layout3"] = "Modo compacto";
L["Always Show Model"] = "Mostrar modelo 3D mientras usas el diseño de simetría";
L["AFK Screen Description"] = "Abre Narcissus cuando estés AFK";
L["AFK Screen Description Extra"] = "Esto anulará el modo AFK de ElvUI.";
L["AFK Screen Delay"] = "Después de un retraso cancelable";
L["Item Names"] = "Nombres de objetos";
L["Open Narcissus"] = "Abrir Narcissus";
L["Character Panel"] = "Panel de personaje";
L["Screen Effects"] ="Efectos de Pantalla";

L["Gem List"] = "Lista de gemas";
L["Gemma"] = "\"Gemma\"";   --No traducir
L["Gemma Description"] = "Muestra una lista de gemas al engarzar un objeto.";
L["Dressing Room"] = "Probador";
L["Dressing Room Description"] = "Probador más grande con la capacidad de ver y copiar las listas de objetos de otros jugadores y generar enlaces de probador de wowhead.";
L["General"] = "General";   --Opciones generales
L["Interface"] = "Interfaz";
L["Shortcuts"] = "Atajos";
L["Themes"] = "Temas";
L["Effects"] = "Efectos";   --Efectos de UI
L["Camera"] = "Cámara";
L["Transmog"] = "Transfiguración";
L["Credits"] = "Créditos";
L["Border Theme Header"] = "Borde del tema";
L["Border Theme Bright"] = "Brillante";
L["Border Theme Dark"] = "Oscuro";
L["Text Width"] = "Ancho del texto";
L["Truncate Text"] = "Truncar texto";
L["Stat Sheet"] = "Hoja de estadísticas";
L["Minimap Button"] = "Botón del minimapa";
L["Fade Out"] = "Desvanecer el cursor";
L["Fade Out Description"] = "El botón se desvanece cuando se aleja el cursor.";
L["Hotkey"] = "Atajos de teclado";
L["Double Tap"] = "Abrir Narcissus con doble clic";
L["Double Tap Description"] = "Haz doble clic en la tecla asignada al panel de personaje para abrir Narcissus.";
L["Show Detailed Stats"] = "Estadísticas detalladas";
L["Tooltip Color"] = "Color del tooltip";
L["Entrance Visual"] = "Entrada visual";
L["Entrance Visual Description"] = "Reproducir efectos de hechizos cuando tu modelo aparece.";
L["Panel Scale"] = "Escala de panel";
L["Exit Confirmation"] = "Confirmación de salida";
L["Exit Confirmation Texts"] = "¿Salir de la foto grupal?";
L["Exit Confirmation Leave"] = "Sí";
L["Exit Confirmation Cancel"] = "No";
L["Ultra-wide"] = "Ultra-wide";
L["Ultra-wide Optimization"] = "Optimización para Ultra-wide";
L["Baseline Offset"] = "Desplazamiento de Ultra-wide";
L["Ultra-wide Tooltip"] = "Puedes ver esta opción porque estás usando un monitor %s:9.";
L["Interactive Area"] = "Área interactiva";
L["Use Bust Shot"] = "Usar plano busto";
L["Use Escape Button"] = "Salir de Narcissus pulsando |cffffdd10(Esc)|r";
L["Use Escape Button Description"] = "Alternativamente, puedes hacer clic en el botón x oculto en la esquina superior derecha de tu pantalla para salir.";
L["Show Module Panel Gesture"] = "Mostrar panel de módulo al pasar el cursor";
L["Independent Minimap Button"] = "No afectado por otros AddOns";
L["AFK Screen"] = "Pantalla AFK";
L["Keep Standing"] = "Mantenerse de pie";
L["Keep Standing Description"] = "Lanza /estar en pie de vez en cuando cuando te vayas AFK. Esto no evitará la desconexión por inactividad.";
L["None"] = "Ninguno";
L["NPC"] = "PNJ";
L["Database"] = "Base de datos";
L["Creature Tooltip"] = "Información sobre la criatura";
L["RAM Usage"] = "Uso de RAM";
L["Others"] = "Otros";
L["Find Relatives"] = "Buscar parientes";
L["Find Related Creatures Description"] = "Busca criaturas con el mismo apellido.";
L["Find Relatives Hotkey Format"] = "Presiona %s para buscar parientes.";
L["Translate Names"] = "Traducir nombres";
L["Translate Names Description"] = "Mostrar nombres traducidos en";
L["Translate Names Languages"] = "Traducir al";
L["Select Language Single"] = "Selecciona un idioma para mostrar en las placas de nombre";
L["Select Language Multiple"] = "Selecciona idiomas para mostrar en el tooltip";
L["Load on Demand"] = "Cargar a demanda";
L["Load on Demand Description On"] = "No cargar la base de datos hasta usar las funciones de búsqueda.";
L["Load on Demand Description Off"] = "Cargar la base de datos de criaturas cuando inicias sesión.";
L["Load on Demand Description Disabled"] = NARCI_COLOR_YELLOW.. "Este interruptor está bloqueado porque has habilitado el tooltip de criaturas.";
L["Tooltip"] = "Tooltip";
L["Name Plate"] = "Placa de nombre";
L["Offset Y"] = "Desplazamiento en Y";
L["Sceenshot Quality"] = "Calidad de captura de pantalla";
L["Screenshot Quality Description"] = "Mayor calidad resulta en archivos más grandes.";
L["Camera Movement"] = "Movimiento de la cámara";
L["Orbit Camera"] = "Cámara orbitante";
L["Orbit Camera Description On"] = "Cuando abres este panel de personaje, la cámara se rotará hacia ti y comenzará a orbitar.";
L["Orbit Camera Description Off"] = "Cuando abres este panel de personaje, la cámara se acercará sin rotación.";
L["Camera Safe Mode"] = "Modo de cámara seguro";
L["Camera Safe Mode Description"] = "Deshabilita completamente la función de actioncam después de cerrar el panel de personaje.";
L["Camera Safe Mode Description Extra"] = "Esta opción está bloqueada porque estás usando dynamiccam.";
L["Camera Transition"] = "Transición de la cámara";
L["Camera Transition Description On"] = "La cámara se moverá suavemente a la posición predeterminada cuando abres este panel de personaje.";
L["Camera Transition Description Off"] = "La transición de la cámara será instantánea. Comenzará desde la segunda vez que uses este panel de personaje.\nLa transición instantánea anulará la configuración de cámara predeterminada #4.";
L["Interface Options Tab Description"] = "También puedes acceder a este panel haciendo clic en el botón de engranaje junto a la barra de herramientas en la esquina inferior izquierda de tu pantalla mientras usas Narcissus.";
L["Soulbinds"] = COVENANT_PREVIEW_SOULBINDS;
L["Conduit Tooltip"] = "Efectos del conducto de rangos superiores";
L["Paperdoll Widget"] = "Artilugio de modelo de personaje";
L["Item Tooltip"] = "Tooltip de objeto";
L["Style"] = "Estilo";
L["Tooltip Style 1"] = "Siguiente generación";
L["Tooltip Style 2"] = "Original";
L["Addtional Info"] = "Información adicional";
L["Item ID"] = "ID del objeto";
L["Camera Reset Notification"] = "El desplazamiento de la cámara se ha restablecido a cero. Si deseas deshabilitar esta función, ve a preferencias - cámara, luego desactiva el modo de cámara seguro.";
L["Binding Name Open Narcissus"] = "Abrir panel de personaje de Narcissus";
L["Developer Colon"] = "Desarrollador: ";
L["Project Page"] = "Página del proyecto";
L["Press Copy Yellow"] = "Presiona |cffffd100".. NARCI_SHORTCUTS_COPY .."|r para Copiar";
L["New Option"] = NARCI_NEW_ENTRY_PREFIX.." NUEVO".."|r"
L["Expansion Features"] = "Características de la expansión";
L["LFR Wing Details"] = "Detalles del ala de Buscador de Bandas";
L["LFR Wing Details Description"] = "Mostrar los nombres de los jefes y los bloqueos cuando hables con los PNJs de la cola individual para Buscador de Bandas.";
L["Speedy Screenshot Alert"] = "El mensaje de captura de pantalla desaparece más rápido";

--Control de Modelo--
L["Ranged Weapon"] = "A distancia";
L["Melee Animation"] = "Cuerpo a cuerpo";
L["Spellcasting"] = "Conjuración";
L["Link Light Sources"] = "Fuentes de luz";
L["Link Model Scales"] = "Escalas de modelo";
L["Hidden"] = "Oculto";
L["Light Types"] = "Luces direccionales/ambientales";
L["Light Types Tooltip"] = "Cambiar entre\n- luz direccional que puede ser bloqueada por objetos y lanzar sombras\n- luz ambiental que influye en todo el modelo";

L["Group Photo"] = "Foto grupal";
L["Reset"] = "Restablecer";
L["Actor Index"] = "Índice";
L["Move To Font"] = "|cff40c7ebDelante|r";
L["Actor Index Tooltip"] = "Arrastra un botón de índice para cambiar la capa del modelo.";
L["Play Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Reproducir esta animación\n"..NARCI_MOUSE_BUTTON_ICON_2.."Reanudar todas las animaciones de los modelos";
L["Pause Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Pausar esta animación\n"..NARCI_MOUSE_BUTTON_ICON_2.."Pausar todas las animaciones de los modelos";
L["Save Layers"] = "Guardar capas";
L["Save Layers Tooltip"] = "Capturar automáticamente 4 capturas de pantalla para la composición de imágenes.\nPor favor, no muevas el cursor ni hagas clic en ningún botón durante este proceso. De lo contrario, tu personaje podría volverse invisible después de salir del complemento. Si eso sucede, usa este comando:\n/console showplayer";
L["Ground Shadow"] = "Sombra en el suelo";
L["Ground Shadow Tooltip"] = "Agregar una sombra en el suelo móvil debajo de tu modelo.";
L["Hide Player"] = "Ocultar jugador";
L["Hide Player Tooltip"] = "Hacer que tu personaje sea invisible para ti mismo.";
L["Virtual Actor"] = "Virtual";
L["Virtual Actor Tooltip"] = "Solo la visualización de hechizos en este modelo es visible.";
L["Self"] = "Propio";
L["Target"] = "Objetivo";
L["Compact Mode Tooltip"] = "Usar solo la parte izquierda de tu pantalla para presentar tu transfiguración.";
L["Toggle Equipment Slots"] = "Alternar ranuras de equipo";
L["Toggle Text Mask"] = "Alternar máscara de texto";
L["Toggle 3D Model"] = "Alternar modelo 3D";
L["Toggle Model Mask"] = "Alternar máscara de modelo";
L["Show Color Sliders"] = "Mostrar controles de color";
L["Show Color Presets"] = "Mostrar preajustes de color";
L["Keep Current Form"] = "Mantén "..NARCI_MODIFIER_ALT.." para mantener la forma de cambio de forma.";
L["Race Sex Change Bug"] = NARCI_COLOR_RED_MILD.."\nEsta característica tiene un error que no se puede corregir en este momento.|r";
L["Race Change Tooltip"] = "Cambiar a otra raza jugable"..L["Race Sex Change Bug"];
L["Sex Change Tooltip"] = "Cambiar género"..L["Race Sex Change Bug"];
L["Show More options"] = "Más opciones";
L["Show Less Options"] = "Menos opciones";
L["Shadow"] = "Sombra";
L["Light Source"] = "Fuente de luz";
L["Light Source Independent"] = "Independiente";
L["Light Source Interconnected"] = "Interconectado";
L["Adjustment"] = "Ajuste";

--Navegador de Animaciones--
L["Animation"] = "Animación";
L["Animation Tooltip"] = "Navegar, buscar animaciones";
L["Animation Variation"] = "Variación";
L["Reset Slider"] = "Restablecer a cero";


--Navegador de Efectos de Hechizos--
L["Visuals"] = "Visuales";
L["Visual ID"] = "ID Visual";
L["Animation ID Abbre"] = "ID de Anim.";
L["Category"] = "Categoría";
L["Sub-category"] = "Subcategoría";
L["My Favorites"] = "Mis favoritos";
L["Reset Visual Tooltip"] = "Eliminar elementos visuales no aplicados";
L["Remove Visual Tooltip"] = "Clic izquierdo: eliminar un visual seleccionado\nClic prolongado: eliminar todos los visuales aplicados";
L["Apply"] = "Aplicar";
L["Applied"] = "Aplicado";   --Visuales que fueron "Aplicados" al modelo
L["Remove"] = "Eliminar";
L["Rename"] = "Renombrar";
L["Refresh Model"] = "Actualizar modelo";
L["Toggle Browser"] = "Alternar navegador de efectos de hechizos";
L["Next And Previous"] = NARCI_MOUSE_BUTTON_ICON_1.."Ir al siguiente\n"..NARCI_MOUSE_BUTTON_ICON_2.."Ir al anterior";
L["New Favorite"] = "Nuevo favorito";
L["Favorites Add"] = "Agregar a mis favoritos";
L["Favorites Remove"] = "Quitar de favoritos";
L["Auto-play"] = "Reproducción automática";   --Auto-play suggested animation
L["Auto-play Tooltip"] = "Reproducir automáticamente la animación\nQue está vinculada al visual seleccionado.";
L["Delete Entry Plural"] = "Se eliminarán %s entradas";
L["Delete Entry Singular"] = "Se eliminará %s entrada";
L["History Panel Note"] = "Los visuales aplicados se mostrarán aquí";
L["Return"] = "Regresar";
L["Close"] = "Cerrar";
L["Change Pack"] = "Cambiar paquete";
L["FindVisual Tooltip"] = "Muéstrame cómo encontrar el SpellVisualKitID";
L["FindVisual Guide 1"] = "Encuentra el SpellID usando el nombre del hechizo.";
L["FindVisual Guide 2"] = "Encuentra el SpellVisualID usando el SpellID en:";
L["FindVisual Guide 3"] = "Encuentra |cffccccccSpellVisualKitID|r usando el SpellVisualID en:";
L["FindVisual Guide 4"] = "Ingresa el |cffccccccSpellVisualKitID|r en la caja de edición visual de Narcissus. No se garantiza que encuentres una coincidencia en los pasos 2 o 3, y la visualización no siempre se muestra correctamente.";


--Probador de Vestimenta--
L["Undress"] = "Desvestir";
L["Favorited"] = "Favorito";
L["Unfavorited"] = "No favorito";
L["Item List"] = "Lista de objetos";
L["Use Target Model"] = "Usar modelo del objetivo";
L["Use Your Model"] = "Usar tu modelo";
L["Cannot Inspect Target"] = "No se puede inspeccionar el objetivo";
L["External Link"] = "Enlace externo";
L["Add to MogIt Wishlist"] = "Agregar a lista de deseos de MogIt";
L["Show Taint Solution"] = "¿Cómo resolver este problema?";
L["Taint Solution Step1"] = "1. Recargar UI.";
L["Taint Solution Step2"] = "2. "..NARCI_MODIFIER_CONTROL.." + Clic izquierdo en un objeto para abrir el probador de vestimenta.";
L["Switch Form To Visage"] = "Cambiar a la forma|cffffffff Humanoide|r";
L["Switch Form To Dracthyr"] = "Cambiar a la forma|cffffffff Dracthyr|r";
L["Switch Form To Worgen"] = "Cambiar a la forma|cffffffff Huargen|r";
L["Switch Form To Human"] = "Cambiar a la forma|cffffffff Humana|r";
L["InGame Command"] = "Comando en juego";

--Navegador de PNJs--
NARCI_NPC_BROWSER_TITLE_LEVEL = ".*%?%?.?";      --Nivel ?? --Usa esto para verificar si la segunda línea de la información sobre herramientas es el título del PNJ o el tipo de unidad
L["NPC Browser"] = "Buscar PNJs";
L["NPC Browser Tooltip"] = "Elige un PNJ de la lista.";
L["Search for NPC"] = "Buscar PNJ";
L["Name or ID"] = "Nombre o ID";
L["NPC Has Weapons"] = "Tiene armas exclusivas";
L["Retrieving NPC Info"] = "Recuperando información del PNJ";
L["Loading Database"] = "Cargando base de datos...\nTu pantalla podría congelarse por unos segundos.";
L["Other Last Name Format"] = "Otro(s) "..NARCI_COLOR_GREY_70.."%s(s)|r:\n";
L["Too Many Matches Format"] = "\nMás de %s coincidencias.";

--Solución de Problemas con Minúsculas o Abreviaturas--
NARCI_STAT_STRENGTH = SPEC_FRAME_PRIMARY_STAT_STRENGTH;
NARCI_STAT_AGILITY = SPEC_FRAME_PRIMARY_STAT_AGILITY;
NARCI_STAT_INTELLECT = SPEC_FRAME_PRIMARY_STAT_INTELLECT;
NARCI_CRITICAL_STRIKE = STAT_CRITICAL_STRIKE;


--Comparación de Equipamiento--
L["Azerite Powers"] = "Poderes de azerita";
L["Gem Tooltip Format1"] = "%s y %s";
L["Gem Tooltip Format2"] = "%s, %s y %s más...";

--Gestor de Conjuntos de Equipamiento
L["Equipped Item Level Format"] = "Equipado %s";
L["Equipped Item Level Tooltip"] = "El nivel de objeto promedio de los objetos actualmente equipados.";
L["Equipment Manager"] = EQUIPMENT_MANAGER;
L["Toggle Equipment Set Manager"] = NARCI_MOUSE_BUTTON_ICON_1.."Gestor de conjuntos de equipamiento.";
L["Duplicated Set"] = "Conjunto duplicado";
L["Low Item Level"] = "Nivel de objeto bajo";
L["1 Missing Item"] = "Falta 1 objeto";
L["n Missing Items"] = "%s objetos faltantes";
L["Update Items"] = "Actualizar objetos";
L["Don't Update Items"] = "No actualizar objetos";
L["Update Talents"] = "Actualizar talentos";
L["Don't Update Talents"] = "No actualizar talentos";
L["Old Icon"] = "Ícono antiguo";
L["NavBar Saved Sets"] = "Guardado";   --Un Conjunto de Equipamiento Guardado
L["NavBar Incomplete Sets"] = INCOMPLETE;
L["Icon Selector"] = "Selector de íconos";
L["Delete Equipment Set Tooltip"] = "Eliminar conjunto\n|cff808080(Clic y mantener)|r";

--Sistema de Corrupción
L["Corruption System"] = "Corrupción";
L["Eye Color"] = "Color de ojos";
L["Blizzard UI"] = "Interfaz de blizzard";
L["Corruption Bar"] = "Barra de corrupción";
L["Corruption Bar Description"] = "Habilita la barra de corrupción junto al panel de personaje.";
L["Corruption Debuff Tooltip"] = "Información de desventajas";
L["Corruption Debuff Tooltip Description"] = "Reemplaza la información predeterminada de efectos negativos con su contraparte numérica.";
L["No Corrupted Item"] = "No has equipado ningún objeto corrupto.";

L["Crit Gained"] = CRIT_ABBR.." Ganado";
L["Haste Gained"] = STAT_HASTE.." Ganada";
L["Mastery Gained"] = STAT_MASTERY.." Ganada";
L["Versatility Gained"] = STAT_VERSATILITY.." Ganada";

L["Proc Crit"] = "Procs de "..CRIT_ABBR;
L["Proc Haste"] = "Procs de "..STAT_HASTE;
L["Proc Mastery"] = "Procs de "..STAT_MASTERY;
L["Proc Versatility"] =  "Procs de "..STAT_VERSATILITY;

L["Critical Damage"] = CRIT_ABBR.."DAÑO";

L["Corruption Effect Format1"] = "|cffffffff%s%%|r velocidad reducida";
L["Corruption Effect Format2"] = "|cffffffff%s|r daño inicial\n|cffffffff%s yd|r de radio";
L["Corruption Effect Format3"] = "|cffffffff%s|r de daño\n|cffffffff%s%%|r de tu vida";
L["Corruption Effect Format4"] = "Ser golpeado por la cosa del más allá desencadena otras desventajas";
L["Corruption Effect Format5"] = "|cffffffff%s%%|r de daño\\sanación recibido modificado";

--Marco de Superposición de Texto
L["Text Overlay"] = "Superposición de texto";
L["Text Overlay Button Tooltip1"] = "Globo de diálogo simple";
L["Text Overlay Button Tooltip2"] = "Globo de diálogo avanzado";
L["Text Overlay Button Tooltip3"] = "Tarjeta de diálogo";
L["Text Overlay Button Tooltip4"] = "Subtítulo flotante";
L["Text Overlay Button Tooltip5"] = "Subtítulo con barra negra";
L["Visibility"] = "Visibilidad";
L["Photo Mode Frame"] = "Marco";    --Marco para foto

--Marco de Logros
L["Use Achievement Panel"] = "Usar como panel principal de logros";
L["Use Achievement Panel Description"] = "Haz clic en avisos o logros seguidos para abrir este panel.";
L["Incomplete First"] = "Incompletos primero";
L["Earned First"] = "Conseguidos primero";
L["Settings"] = "Ajustes";
L["Next Prev Card"] = "Siguiente/anterior tarjeta";
L["Track"] = "Seguir";   --Seguir logros
L["Show Unearned Mark"] = "Mostrar marca de no conseguidos";
L["Show Unearned Mark Description"] = "Marca los logros que no fueron conseguidos por mí con una x roja.";
L["Show Dates"] = "Mostrar fechas";
L["Hide Dates"] = "Ocultar fechas";
L["Pinned Entries"] = "Entradas fijadas";
L["Pinned Entry Format"] = "Fijado %d/%d";
L["Create A New Entry"] = "Crear una nueva entrada";
L["Custom Achievement"] = "Logro personalizado";
L["Custom Achievement Description"] = "Esta es la descripción.";
L["Custom Achievement Select And Edit"] = "Selecciona una entrada para editar.";
L["Cancel"] = "Cancelar";
L["Color"] = "Color";
L["Icon"] = "Ícono";
L["Description"] = "Descripción";
L["Points"] = "Puntos";
L["Reward"] = "Recompensa";
L["Date"] = "Fecha";
L["Click And Hold"] = "Clic y mantener";
L["To Do List"] = "Por hacer";
L["Error Alert Bookmarks Too Many"] = "Solo puedes marcar %d logros a la vez.";
L["Instruction Add To To Do List"] = string.format("Haz %s clic izquierdo en un logro no ganado para agregarlo a tu lista de por hacer.", NARCI_MODIFIER_ALT);

--Barbería--
L["Save New Look"] = "Guardar nuevo aspecto";
L["No Available Slot"] = "No hay espacio disponible";
L["Look Saved"] = "Aspecto guardado";
L["Cannot Save Forms"] = "No se pueden guardar los formularios";
L["Profiles"] = SOCIAL_SHARE_TEXT or "Compartir";
L["Share"] = "Compartir";
L["Save Notify"] = "Notificar para guardar nueva apariencia";
L["Save Notify Tooltip"] = "Te notifica para guardar la personalización después de hacer clic en el botón de aceptar.";
L["Show Randomize Button"] = "Mostrar botón de aleatorizar apariencia";
L["Coins Spent"] = "Monedas gastadas";
L["Locations"] = "Ubicaciones";
L["Location"] = "Ubicación";
L["Visits"] = "Visitas";     --número de visitas
L["Duration"] = "Duración";
L["Edit Name"] = "Editar nombre";
L["Delete Look"] = "Eliminar aspecto\n(Clic y mantener)";
L["Export"] = "Exportar";
L["Import"] = "Importar";
L["Paste Here"] = "Pegar aquí";
L["Press To Copy"] = "Presiona |cffcccccc".. NARCI_SHORTCUTS_COPY.."|r para copiar";
L["String Copied"] = NARCI_COLOR_GREEN_MILD.. "Copiado".."|r";
L["Failure Reason Unknown"] = "Error desconocido";
L["Failure Reason Decode"] = "Error al decodificar.";
L["Failure Reason Wrong Character"] = "La raza/género/forma actual no coincidía con el perfil importado.";
L["Failure Reason Dragonriding"] = "Este perfil es para montar dragones.";
L["Wrong Character Format"] = "Requiere %s %s."; --por ejemplo, Requiere Hombre Humano
L["Import Lack Option"] = "%d |4option:opciones; no se encontraron.";
L["Import Lack Choice"] = "%d |4choice:elecciones; no se encontraron.";
L["Decode Good"] = "Decodificado exitosamente.";
L["Barbershop Export Tooltip"] = "Codifica la personalización utilizada actualmente en una cadena que se puede compartir en línea.\n\npuedes cambiar cualquier texto antes de los dos puntos (:)";
L["Settings And Share"] = (SETTINGS or "Ajustes") .." & ".. (SOCIAL_SHARE_TEXT or "Compartir");
L["Loading Portraits"] = "Cargando retratos";
L["Private Profile"] = "Privado";   --usado por el personaje actual
L["Public Profile"] = "Público";     --compartido entre todos tus personajes
L["Profile Type Tooltip"] = "Selecciona el perfil a usar en este personaje.\n\nPrivado:|cffedd100 Perfil creado por el personaje actual|r\n\nPúblico:|cffedd100 Perfil compartido entre todos tus personajes|r";
L["No Saves"] = "Sin guardados";
L["Profile Migration Tooltip"] = "Puedes copiar ajustes existentes al perfil público.";
L["Profile Migration Okay"] = "Okay";

--Tutorial--
L["Alert"] = "Advertencia";
L["Race Change"] = "Cambio de raza/género";
L["Race Change Line1"] = "Puedes volver a cambiar tu raza y género. Pero hay algunas limitaciones:\n1. Tus armas desaparecerán.\n2. Los efectos visuales de los hechizos ya no se pueden quitar.\n3. No funciona en otros jugadores o PNJs.";
L["Guide Spell Headline"] = "Probar o aplicar";
L["Guide Spell Criteria1"] = "Clic izquierdo para PROBAR";
L["Guide Spell Criteria2"] = "Clic derecho para APLICAR";
L["Guide Spell Line1"] = "La mayoría de los efectos visuales de los hechizos que agregues haciendo clic en el botón izquierdo se desvanecerán en segundos, mientras que los que agregues haciendo clic en el botón derecho no lo harán.\n\nahora, mueve tu cursor a una entrada a continuación:";
L["Guide Spell Choose Category"] = "Puedes agregar efectos visuales de hechizos a tu modelo. Elige cualquier categoría que desees. Luego elige una subcategoría.";
L["Guide History Headline"] = "Panel de historial";
L["Guide History Line1"] = "Aquí pueden conservarse como máximo 5 efectos visuales aplicados recientemente. Puedes seleccionar uno y eliminarlo haciendo clic en el botón eliminar en el extremo derecho.";
L["Guide Refresh Line1"] = "Utiliza este botón para eliminar todos los efectos visuales de hechizos no aplicados. Aquellos que estaban en el panel de historial se volverán a aplicar.";
L["Guide Input Headline"] = "Entrada manual";
L["Guide Input Line1"] = "También puedes ingresar un ID de SpellVisualKit tú mismo. A partir de la versión 9.0, su límite es de alrededor de 155,000.\nPuedes usar la rueda del cursor para probar el siguiente/anterior ID.\nMuy pocos ids pueden bloquear el juego.";
L["Guide Equipment Manager Line1"] = "Doble clic: usar un conjunto\nClic derecho: editar un conjunto.\n\nla función anterior de este botón se ha trasladado a preferencias.";
L["Guide Model Control Headline"] = "Control de modelo";
L["Guide Model Control Line1"] = string.format("Este modelo comparte las mismas acciones del cursor que usas en el vestuario, además de:\n\n1.Mantén %s y clic izquierdo: Girar el modelo alrededor del eje Y.\n2.Mantén %s y clic derecho: Ejecutar acercamiento suave.", NARCI_MODIFIER_ALT, NARCI_MODIFIER_ALT);
L["Guide Minimap Button Headline"] = "Botón de minimapa";
L["Guide Minimap Button Line1"] = "El botón de minimapa de narciso ahora puede ser manejado por otros complementos.\nPuedes cambiar esta opción en el panel de preferencias. Puede requerir una recarga de la UI."
L["Guide NPC Entrance Line1"] = "Puedes agregar cualquier PNJ a tu escena."
L["Guide NPC Browser Line1"] = "Los PNJs destacados se enumeran en el catálogo a continuación.\nTambién puedes buscar cualquier criatura por nombre o ID.\nTen en cuenta que la primera vez que uses la función de búsqueda en este inicio de sesión, podría tardar unos segundos en construir la tabla de búsqueda y tu pantalla podría congelarse también.\nPuedes desactivar la opción \"Cargar a Pedido\" en el Panel de Preferencias para que la base de datos se construya justo después de iniciar sesión.";

--Splash--
L["Splash Whats New Format"] = "¿Qué hay de nuevo en Narcissus %s";
L["See Ads"] = "Ver anuncios de nuestro auténtico patrocinador";    --¡No son anuncios reales!
L["Splash Category1"] = L["Modo de Foto"];
L["Splash Content1 Name"] = "Navegador de armas";
L["Splash Content1 Description"] = "-Ver y usar todas las armas en la base de datos, incluyendo aquellas que no son obtenibles por los jugadores.";
L["Splash Content2 Name"] = "Pantalla de selección de personaje";
L["Splash Content2 Description"] = "-Agrega un marco decorativo para crear (falsos) tu propia pantalla de selección de personaje.";
L["Splash Content3 Name"] = "Probador";
L["Splash Content3 Description"] = "-El módulo del probador ha sido rediseñado.\n-la lista de objetos ahora incluye hombreras desparejadas e ilusiones de armas.";
L["Splash Content4 Name"] = "Establo de mascotas";
L["Splash Content4 Description"] = "-Los cazadores pueden seleccionar y añadir mascotas usando una nueva UI de establo en el modo de foto grupal.";
L["Splash Category2"] = "Marco de personaje";
L["Splash Content5 Name"] = "Fragmento de dominación";
L["Splash Content5 Description"] = "-El indicador de fragmento de dominación aparecerá si equipas objetos relevantes.\n-se te presentará una lista de fragmentos disponibles cuando insertes objetos de dominación.\n-Extrae fragmentos con un solo clic.";
L["Splash Content6 Name"] = "Lazos de alma";
L["Splash Content6 Description"] = "-La UI de lazos de alma ha sido actualizada. Puedes verificar los efectos de los conductos de rangos superiores.";
L["Splash Content7 Name"] = "Visuales";
L["Splash Content7 Description"] = "-El borde hexagonal del objeto tiene un nuevo aspecto. Algunos objetos tienen apariencias únicas.";

--Detalles del Proyecto--
L["AboutTab Developer Note"] = "¡Gracias por probar este complemento! Si tienes algún problema, sugerencia o idea, por favor deja un comentario en la página de curseforge o contáctame en...";

--Conversación--
L["Q1"] = "¿Qué es esto?";
L["Q2"] = "Lo sé. Pero ¿Por qué es tan grande?";
L["Q3"] = "Eso no es gracioso. Solo necesito uno normal.";
L["Q4"] = "Bueno. ¿Qué pasa si quiero desactivarlo?";
L["Q5"] = "Una cosa más, ¿Podrías prometerme que no habrá más bromas?";
L["A1"] = "Aparentemente, este es un diálogo de confirmación de salida. Aparece cuando intentas salir del modo de foto grupal presionando una tecla de acceso rápido.";
L["A2"] = "Ja, eso es lo que ella dijo.";
L["A3"] = "Bien... bien..."
L["A4"] = "Lo siento, no puedes. Es por seguridad, ya sabes.";

--Buscar--
L["Search Result Singular"] = "%s resultado";
L["Search Result Plural"] = "%s resultados";
L["Search Result Overflow"] = "%s+ resultados";
L["Search Result None"] = CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS;

--Navegador de Armas--
L["Draw Weapon"] = "Equipar arma";
L["Unequip Item"] = "Desequipar";
L["WeaponBrowser Guide Hotkey"] = "Especifica qué mano sostiene el arma:";
L["WeaponBrowser Guide ModelType"] = "Algunos objetos están limitados a cierto tipo de modelo:";
L["WeaponBrowser Guide DressUpModel"] = "Este será el tipo predeterminado si tu objetivo es un jugador a menos que estés sosteniendo <%s> mientras lo creas.";
L["WeaponBrowser Guide CinematicModel"] = "El tipo de modelo siempre será cinemático si la criatura es un PNJ. No puedes envainar armas.";
L["Weapon Browser Specify Hand"] = "|cffffd100"..NARCI_MODIFIER_CONTROL.." + Clic izquierdo|r para equipar el objeto en la mano principal.\n|cffffd100"..NARCI_MODIFIER_ALT.." + Clic izquierdo|r para la mano secundaria.";

--Establo de Mascotas--
L["PetStable Tooltip"] = "Elige una mascota de tu establo";
L["PetStable Loading"] = "Recuperando información de mascotas";

--Objeto de Dominación--
L["Item Bonus"] = "Bonificación:";
L["Combat Error"] = NARCI_COLOR_RED_MILD.."Abandona el combate para continuar".."|r";
L["Extract Shard"] = "Extraer fragmento";
L["No Service"] = "Sin servicio";
L["Shards Disabled"] = "Los fragmentos de dominación están desactivados fuera de Las Fauces.";
L["Unsocket Gem"] = "Extraer gema";

--Tabla de Clasificación Míticas+
L["Mythic Plus"] = "Míticas+";
L["Mythic Plus Abbrev"] = "M+";
L["Total Runs"] = "Total de carreras: ";
L["Complete In Time"] = "A tiempo";
L["Complete Over Time"] = "Fuera de tiempo";
L["Runs"] = "Carreras";

--Actualización de Equipamiento--
L["Temp Enchant"] = "Encantamientos temporales";       --ERR_TRADE_TEMP_ENCHANT_BOUND
L["Owned"] = "Poseído";                           --Solo mostrar objetos poseídos
L["At Level"] = "A nivel %d:";                 --Los encantamientos escalan con el nivel del jugador
L["No Item Alert"] = "No hay objetos compatibles";
L["Click To Insert"] = "Clic para insertar";       --Insertar una gema
L["No Socket"] = "No hay ranura";
L["No Other Item For Slot"] = "No hay otro objeto para %s";       --donde %s es el nombre de la ranura
L["In Bags"] = "En bolsas";
L["Item Socketing Tooltip"] = "Clic y mantener para incrustar";
L["No Available Gem"] = "|cffd8d8d8No hay gema disponible|r";
L["Missing Enchant Alert"] = "Alerta de encantamiento faltante";
L["Missing Enchant"] = NARCI_COLOR_RED_MILD.."Sin encantamiento".."|r";
L["Socket Occupied"] = "Ranura ocupada";       --Indica que hay una gema (importante) en la ranura y que primero necesitas quitarla
    
--Estadísticas--
S["Narcissus Played"] = "Tiempo total invertido en Narcissus";
S["Format Since"] = "(desde %s)";
S["Screenshots"] = "Capturas de pantalla tomadas con Narcissus";
S["Shadowlands Quests"] = "Misiones de shadowlands";
S["Quest Text Reading Speed Format"] = "Completado: %s (%s palabras)  Lectura: %s (%s wpm)";

--Base Giratoria--
L["Turntable"] = "Base giratoria";
L["Picture"] = "Imagen";
L["Elapse"] = "Transcurrir";
L["Turntable Tab Animation"] = "Animación";
L["Turntable Tab Image"] = "Imagen";
L["Turntable Tab Quality"] = "Calidad";
L["Turntable Tab Background"] = "Fondo";
L["Spin"] = "Girar";
L["Sync"] = "Sincronizar";
L["Rotation Period"] = "Período";
L["Period Tooltip"] = "El tiempo que tarda en completarse un giro.\nTambién debería ser la |cffccccccduración de corte|r de tu gif o video.";
L["MSAA Tooltip"] = "Modifica temporalmente el anti-aliasing para suavizar los bordes dentados a costa del rendimiento.";
L["Image Size"] = "Tamaño de la imagen";
L["Font Size"] = FONT_SIZE;
L["Item Name Show"] = "Mostrar nombres de objetos";
L["Item Name Hide"] = "Ocultar nombres de objetos";
L["Outline Show"] = "Haz clic para mostrar el contorno";
L["Outline Hide"] = "Haz clic para ocultar el contorno";
L["Preset"] = "Predefinido";
L["File"] = "Archivo";     
L["File Tooltip"] = "Coloca tu propia imagen bajo |cffccccccWorld of Warcraft\\retail\\Interface\\AddOns|r e inserta el nombre del archivo en este cuadro.\nLa imagen debe ser un archivo |cffccccccjpg|r de |cffcccccc512x512|r o |cffcccccc1024x1024|r";
L["Raise Level"] = "Traer al frente";
L["Lower Level"] = "Enviar al fondo";
L["Show Mount"] = "Mostrar montura";
L["Hide Mount"] = "Ocultar montura";
L["Loop Animation On"] = "Bucle";
L["Click To Continue"] = "Haz clic para continuar";
L["Showcase Splash 1"] = "Crea animaciones giratorias para mostrar tu transfiguración con Narcissus y grabador de pantalla.";
L["Showcase Splash 2"] = "Haz clic en el botón de abajo para copiar objetos desde el probador.";
L["Showcase Splash 3"] = "Haz clic en el botón de abajo para girar tu personaje.";
L["Showcase Splash 4"] = "Graba la pantalla con software de grabación de video y luego conviértelo a gif.";
L["Loop Animation Alert Kultiran"] = "Bucle - actualmente no funciona en masculinos kultiranos";
L["Loop Animation"] = "Animación en bucle";

--Conjuntos de Objetos--
L["Class Set Indicator"] = "Indicador de conjunto de clase";
L["Cycle Spec"] = "Desplazarse para cambiar de especialización";
L["Paperdoll Splash 1"] = "¿Activar indicador de conjunto de clase?";
L["Paperdoll Splash 2"] = "Elige un tema";
L["Theme Changed"] = "Tema cambiado";

--Selección de Equipo--
L["Outfit"] = "Equipo";
L["Models"] = "Modelos";
L["Origin Outfits"] = "Conjuntos originales";
L["Outfit Owner Format"] = "Conjuntos de %s";
L["SortMethod Recent"] = "Reciente";
L["SortMethod Name"] = "Nombre";

--Formato de Coincidencia de Información en Herramienta de Consejo--
L["Find Cooldown"] = " tiempo de reutilización";
L["Find Recharge"] = " recarga";


--Árbol de Talentos--
L["Mini Talent Tree"] = "Mini árbol de talentos";
L["Show Talent Tree When"] = "Mostrar árbol de talentos cuando...";
L["Show Talent Tree Paperdoll"] = "Abrir modelo de personaje";
L["Show Talent Tree Inspection"] = "Inspeccionas a otros jugadores";
L["Show Talent Tree Equipment Manager"] = "Gestor de equipamiento";
L["Appearance"] = "Apariencia";
L["Use Class Background"] = "Fondo de clase";
L["Use Bigger UI"] = "Usar UI grande";
L["Empty Loadout Name"] = "Nombre";
L["No Save Slot Red"] = NARCI_COLOR_RED_MILD.. "Sin espacio para guardar" .."|r";
L["Save"] = "Guardar";
L["Create Macro Wrong Spec"] = "¡Este conjunto ha sido asignado a otra especialización!";
L["Create Marco No Slot"] = "No se pueden crear más macros de carácter específico.";
L["Create Macro Instruction 1"] = "Suelta el conjunto en el cuadro de abajo para combinarlo con \n|cffebebeb%s|r";
L["Create Macro Instruction Edit"] = "Suelta el conjunto en el cuadro de abajo para editar el macro\n|cffebebeb%s|r";
L["Create Macro Instruction 2"] = "Selecciona un |cff53a9fficono secundario|r para este macro.";
L["Create Macro Instruction 3"] = "Nombra este macro\n ";
L["Create Macro Instruction 4"] = "Arrastra este macro a tu barra de acción.";
L["Create Macro In Combat"] = "No se puede crear un macro durante el combate.";
L["Create Macro Next"] = "Siguiente";
L["Create Marco Created"] = "Creado";
L["Place UI"] = "Coloca la UI...";
L["Place Talent UI Right"] = "A la derecha del modelo";
L["Place Talent UI Bottom"] = "Debajo del modelo";
L["Loadout"] = "Configuración";
L["No Loadout"] = "Sin configuración";
L["PvP"] = "JcJ";


--Filtro de Objetos de Bolsa--
L["Bag Item Filter"] = "Filtro de objetos de bolsa";
L["Bag Item Filter Enable"] = "Habilitar sugerencias de búsqueda y filtro automático";
L["Place Window"] = "Coloca la ventana...";
L["Below Search Box"] = "Debajo de la caja de búsqueda";
L["Above Search Box"] = "Encima de la caja de búsqueda";
L["Auto Filter Case"] = "Filtra automáticamente los objetos cuando...";
L["Send Mails"] = "Enviar correos";
L["Create Auctions"] = "Crear subastas";
L["Socket Items"] = "Objetos con ranura";
L["Item Type Mailable"] = MAIL_LABEL or "Se puede enviar por correo";
L["Item Type Auctionable"] = AUCTIONS or "Subastable";
L["Item Type Teleportation"] = TUTORIAL_TITLE35 or "Viaje";
L["Item Type Gems"] = AUCTION_CATEGORY_GEMS or "Gemas";
L["Item Type Reagent"] = PROFESSIONS_MODIFIED_CRAFTING_REAGENT_BASIC or "Reactivo de creación";


--Programa de Ventajas--
L["Perks Program Unclaimed Tender Format"] = "- Tienes |cffffffff%s|r cupones sin reclamar en el alijo del coleccionista.";     
L["Perks Program Unearned Tender Format"] = "- Tienes |cffffffff%s|r cupones sin ganar del registro de viajeros.";     
L["Perks Program Item Added In Format"] = "Añadido en %s";
L["Perks Program Item Unavailable"] = "Este objeto no está disponible actualmente.";
L["Perks Program See Wares"] = "Ver articulos";
L["Perks Program No Cache Alert"] = "Habla con los vendedores de los puestos de intercambio para ver la mercancía de este mes.";
L["Perks Program Using Cache Alert"] = "Usando la caché de tu última visita. Los datos de precio pueden no ser precisos.";
L["Modify Default Pose"] = "Modificar pose por defecto";
L["Include Header"] = "Incluye:";  --El conjunto de transfiguración incluye...
L["Auto Try On All Items"] = "Probar automáticamente todos los objetos";
L["Full Set Cost"] = "Costo del conjunto completo";   --Comprar el conjunto completo te costará x moneda de tendero
L["You Will Receive One Item"] = "Recibirás |cffffffffUN|r objeto:";
L["Format Item Belongs To Set"] = "Este objeto pertenece al conjunto de transfiguración |cffffffff[%s]|r";


--Misión--
L["Auto Display Quest Item"] = "Mostrar descripciones de objetos de misión\nautomáticamente";
L["Drag To Move"] = "Arrastra para mover";
L["Middle Click Reset Position"] = "Haz clic central para restablecer la posición."
L["Change Position"] = "Cambiar posición";


--Timerunning--
L["Primary Stat"] = "Estadística principal";
L["Stamina"] = ITEM_MOD_STAMINA_SHORT or "Aguante";
L["Crit"] = ITEM_MOD_CRIT_RATING_SHOR or "Golpe crítico";
L["Haste"] = ITEM_MOD_HASTE_RATING_SHORT or "Celeridad";
L["Mastery"] = ITEM_MOD_MASTERY_RATING_SHORT or "Maestría";
L["Versatility"] = ITEM_MOD_VERSATILITY or "Versatilidad";

L["Leech"] = ITEM_MOD_CR_LIFESTEAL_SHORT or "Absorción";
L["Speed"] = ITEM_MOD_CR_UNUSED_3_SHORT or "Velocidad";
L["Format Stat EXP"] = "+%d%% Ganancia de EXP";
L["Format Rank"] = AZERITE_ESSENCE_RANK or "Rango %d";
L["Cloak Rank"] = "Rango de capa";


--Gestor de Gemas--
L["Gem Manager"] = "Gestor de gemas";
L["Pandamonium Gem Category 1"] = "Engranaje";      --Habilidades de Enfriamiento de Engranaje
L["Pandamonium Gem Category 2"] = "Artilugio";     --Gema de Artilugio
L["Pandamonium Gem Category 3"] = PRISMATIC_GEM or "Prismática";
L["Pandamonium Slot Category 1"] = (INVTYPE_CHEST or "Pecho")..", "..(INVTYPE_LEGS or "Piernas");
L["Pandamonium Slot Category 2"] = INVTYPE_TRINKET or "Abalorio";
L["Pandamonium Slot Category 3"] = (INVTYPE_NECK or "Cuello")..", "..(INVTYPE_FINGER or "Dedo");
L["Gem Removal Instruction"] = "<Haz clic derecho para quitar esta gema>";
L["Gem Removal No Tool"] = "No tienes la herramienta para quitar esta gema intacta.";
L["Gem Removal Bag Full"] = "Libera espacio en la bolsa antes de quitar esta gema.";
L["Gem Removal Combat"] = "No se puede cambiar la gema mientras estás en combate.";
L["Gemma Click To Activate"] = "<Haz clic izquierdo para activar>";
L["Gemma Click To Insert"] = "<Haz clic izquierdo para insertar>";
L["Gemma Click Twice To Insert"] = "<Haz clic izquierdo |cffffffffDOS VECES|r para insertar>";
L["Gemma Click To Select"] = "<Clic izquierdo para seleccionar>";
L["Gemma Click To Deselect"] = "<Clic derecho para deseleccionar>";
L["Stat Health Regen"] = "Regeneración de salud";
L["Gem Uncollected"] = FOLLOWERLIST_LABEL_UNCOLLECTED or "No recolectado";
L["No Sockets Were Found"] = "No se encontraron ranuras compatibles.";
L["Click To Show Gem List"] = "<Haz clic para mostrar la lista de gemas>";
L["Remix Gem Manager"] = "Administrador de Gemas Remix";
L["Select A Loadout"] = "Seleccionar un conjunto";
L["Loadout Equipped"] = "Equipado";
L["Loadout Equipped Partially"] = "Parcialmente Equipado";
L["Last Used Loadout"] = "Último Usado";
L["New Loadout"] = TALENT_FRAME_DROP_DOWN_NEW_LOADOUT or "Nuevo Conjunto";
L["New Loadout Blank"] = "Crear un Conjunto en Blanco";
L["New Loadout From Equipped"] = "Usar Configuración Actual";
L["Edit Loadout"] = EDIT or "Editar";
L["Delete Loadout One Click"] = DELETE or "Eliminar";
L["Delete Loadout Long Click"] = "|cffff4800"..(DELETE or "Eliminar").."|r\n|cffcccccc(clic y mantén presionado)|r";
L["Select Gems"] = LFG_LIST_SELECT or "Seleccionar";
L["Equipping Gems"] = "Equipando...";
L["Pandamonium Sockets Available"] = "Puntos Disponibles";
L["Click To Open Gem Manager"] = "Clic izquierdo para abrir el administrador de gemas";
L["Loadout Save Failure Incomplete Choices"] = "|cffff4800Tienes gemas no seleccionadas.|r";
L["Loadout Save Failure Dupe Loadout Format"] = "|cffff4800Este conjunto es el mismo que|r %s";
L["Loadout Save Failure Dupe Name Format"] = "|cffff4800Ya existe un conjunto con ese nombre.|r";
L["Loadout Save Failure No Name"] = "|cffff4800".. (TALENT_FRAME_DROP_DOWN_NEW_LOADOUT_PROMPT or "Introduce un nombre para el nuevo conjunto") .."|r";

L["Format Equipping Progress"] = "Equipando %d/%d";
L["Format Click Times To Equip Singular"] = "Clic |cff19ff19%d|r vez para Equipar";
L["Format Click Times To Equip Plural"] = "Clic |cff19ff19%d|r veces para Equipar";   --|4vez:veces; ¿no puede coexistir con el código de color?
L["Format Free Up Bag Slot"] = "Libera %d espacios en el inventario primero";
L["Format Number Items Selected"] = "%d Seleccionado(s)";
L["Format Gem Slot Stat Budget"] = "Las gemas en %s son %s%% efectivas."  --ej. Las gemas en el abalorio son un 75% efectivas
