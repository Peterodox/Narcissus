if not (GetLocale() == "frFR") then
    return;
end

local L = Narci.L

local L = Narci.L;
local S = Narci.L.S;

NARCI_GRADIENT = "|cffA236EFN|r|cff9448F1a|r|cff865BF2r|r|cff786DF4c|r|cff6A80F6i|r|cff5D92F7s|r|cff4FA4F9s|r|cff41B7FAu|r|cff33C9FCs|r"
MYMOG_GRADIENT = "|cffA236EFM|cff9448F1y |cff865BF2T|cff786DF4r|cff6A80F6a|cff5D92F7n|cff4FA4F9s|cff41B7FAm|cff33C9FCo|cff32c9fbg|r"

NARCI_DEVELOPER_INFO = "Developed by Peterodox";

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
L["Heritage Armor"] = "Armure Ancestrale";

--Model Control--
NARCI_GROUP_PHOTO = "Photo de Groupe";

--NPC Browser--
NARCI_NPC_BROWSER_TITLE_LEVEL = ".iveau.*"

L["No Service"] = "Aucun service";
L["Shards Disabled"] = "Éclat de domination sont désactivés en dehors de Antre";

--Date--
L["Today"] = COMMUNITIES_CHAT_FRAME_TODAY_NOTIFICATION;
L["Yesterday"] = COMMUNITIES_CHAT_FRAME_YESTERDAY_NOTIFICATION;
L["Format Days Ago"] = "Il y a %d jours";
L["A Month Ago"] = "Il y a 1 mois";
L["Format Months Ago"] = "Il y a %d mois";
L["A Year Ago"] = "Il y a 1 an";
L["Format Years Ago"] = "Il y a %d ans";
L["Version Colon"] = (GAME_VERSION_LABEL or "Version")..": ";
L["Date Colon"] = "Date : ";
L["Day Plural"] = "Jours";
L["Day Singular"] = "Jour";
L["Hour Plural"] = "Heures";
L["Hour Singular"] = "Heure";

L["Swap items"] = "Échanger les objets";
L["Press Copy"] = NARCI_COLOR_GREY_70.. "Appuyez sur |r".. NARCI_SHORTCUTS_COPY.. NARCI_COLOR_GREY_70 .." pour copier";
L["Copied"] = NARCI_COLOR_GREEN_MILD.. "Lien copié|r";
L["Movement Speed"] = "Vitesse de déplacement";
L["Damage Reduction Percentage"] = "Réduction des dégâts %";
L["Advanced Info"] = "Cliquez gauche pour afficher les infos avancées.";
L["Restore On Exit"] = "\nVos paramètres précédents seront restaurés après la sortie.";

L["Photo Mode"] = "Mode Photo";
L["Photo Mode Tooltip Open"] = "Ouvrir la boîte à outils de capture d'écran.";
L["Photo Mode Tooltip Close"] = "Fermer la boîte à outils de capture d'écran.";
L["Photo Mode Tooltip Special"] = "Les captures d'écran enregistrées dans le dossier Screenshots de WoW ne comprendront pas ce widget.";

L["Toolbar Mog Button"] = "Mode Photo";
L["Toolbar Mog Button Tooltip"] = "Présentez votre transmogrification ou créez un studio photo où vous pouvez ajouter d'autres joueurs et PNJ.";

L["Toolbar Emote Button"] = "Faire une émote";
L["Toolbar Emote Button Tooltip"] = "Utilisez les émotes avec des animations uniques.";
L["Auto Capture"] = "Capture Automatique";

L["Toolbar HideTexts Button"] = "Cacher les textes";
L["Toolbar HideTexts Button Tooltip"] = "Cacher tous les noms, bulles de discussion et textes de combat." .. L["Restore On Exit"];

L["Toolbar TopQuality Button"] = "Qualité maximale";
L["Toolbar TopQuality Button Tooltip"] = "Définir toutes les options des paramètres graphiques au maximum." .. L["Restore On Exit"];

L["Toolbar Location Button"] = "Localisation du joueur";
L["Toolbar Location Button Tooltip"] = "Afficher le nom de la zone actuelle et les coordonnées du joueur.";

L["Toolbar Camera Button"] = "Caméra";
L["Toolbar Camera Button Tooltip"] = "Modifier temporairement les paramètres de la caméra.";

L["Toolbar Preferences Button Tooltip"] = "Ouvrir le panneau de préférences.";

--Special Source--
L["Heritage Armor"] = "Heritage Armor";
L["Secret Finding"] = "Secret Finding";

NARCI_HEART_QUOTE_1 = "what is essential is invisible to the eye.";

--Title Manager--
L["Open Title Manager"] = "Ouvrir le gestionnaire de titres";
L["Close Title Manager"] = "Fermer le gestionnaire de titres";

--Alias--
L["Use Alias"] = "Passer à l'alias";
L["Use Player Name"] = "Passer à "..CALENDAR_PLAYER_NAME;

L["Minimap Tooltip Double Click"] = "Double-tap";
L["Minimap Tooltip Left Click"] = "Clic gauche|r";
L["Minimap Tooltip To Open"] = "|cffffffffOuvrir "..CHARACTER_INFO;
L["Minimap Tooltip Module Panel"] = "|cffffffffOuvrir le panneau des modules";
L["Minimap Tooltip Right Click"] = "Clic droit";
L["Minimap Tooltip Shift Left Click"] = "Shift + Clic gauche";
L["Minimap Tooltip Shift Right Click"] = "Shift + Clic droit";
L["Minimap Tooltip Hide Button"] = "|cffffffffCacher ce bouton|r";
L["Minimap Tooltip Middle Button"] = "|CFFFF1000Clic bouton du milieu |cffffffffRéinitialiser la caméra";
L["Minimap Tooltip Set Scale"] = "Définir l'échelle : |cffffffff/narci [échelle 0.8~1.2]";
L["Corrupted Item Parser"] = "|cffffffffActiver/Désactiver l'analyseur d'objets corrompus|r";
L["Toggle Dressing Room"] = "|cffffffffActiver/Désactiver "..DRESSUP_FRAME.."|r";

NARCI_CLIPBOARD = "Presse-papiers";
L["Layout"] = "Disposition";
L["Symmetry"] = "Symétrie";
L["Asymmetry"] = "Asymétrie";
L["Copy Texts"] = "Copier la liste des objets";
L["Syntax"] = "Syntaxe";
L["Plain Text"] = "Texte brut";
L["BB Code"] = "BB Code";
L["Markdown"] = "Markdown";
L["Export Includes"] = "L'exportation inclut...";
NARCI_ITEM_ID = "ID de l'objet";

L["3D Model"] = "Modèle 3D";
NARCI_EQUIPMENTSLOTS = "Emplacements d'équipement";

--Preferences--

NARCI_PHOTO_MODE = L["Photo Mode"];
NARCI_OVERRIDE = "Remplacer";
NARCI_INVALID_KEY = "Combinaison de touches invalide.";
NARCI_REQUIRE_RELOAD = NARCI_COLOR_RED_MILD.. "Un rechargement de l'interface est nécessaire.|r";

L["Preferences"] = "Préférences";
L["Preferences Tooltip"] = "Cliquez pour ouvrir le panneau des préférences.";
L["Extensions"] = "Extensions";
L["About"] = "À propos";
L["Image Filter"] = "Filtres";    --Filtre d'image
L["Image Filter Description"] = "Tous les filtres sauf le vignettage seront désactivés en mode transmog.";
L["Grain Effect"] = "Effet de grain";
L["Fade Music"] = "Fondu de la musique";
L["Vignette Strength"] = "Intensité du vignettage";
L["Weather Effect"] = "Effet météo";
L["Letterbox"] = "Bandeau cinéma";
L["Letterbox Ratio"] = "Ratio";
L["Letterbox Alert1"] = "Le format de votre écran dépasse le ratio sélectionné !"
L["Letterbox Alert2"] = "Il est recommandé de régler l'échelle de l'interface utilisateur à %0.1f\n(l'échelle actuelle est de %0.1f)"
L["Default Layout"] = "Disposition par défaut";
L["Transmog Layout1"] = "Symétrie, 1 modèle";
L["Transmog Layout2"] = "2 modèles";
L["Transmog Layout3"] = "Mode compact";
L["Always Show Model"] = "Afficher le modèle 3D en mode symétrie";
L["AFK Screen Description"] = "Ouvrir Narcissus lorsque vous êtes AFK";
L["AFK Screen Description Extra"] = "Cela remplacera le mode AFK d'ElvUI.";
L["AFK Screen Delay"] = "Après un délai annulable";
L["Item Names"] = "Noms des objets";
L["Open Narcissus"] = "Ouvrir Narcissus";
L["Character Panel"] = "Panneau de personnage";
L["Screen Effects"] ="Effets d'écran";

L["Gemma"] = "\"Gemma\"";   --Ne pas traduire
L["Gemma Description"] = "Afficher une liste de gemmes lors de l'insertion dans un objet.";
L["Gem Manager"] = "Gestionnaire de gemmes";
L["Dressing Room"] = "Cabine d'essayage";
L["Dressing Room Description"] = "Cabine d'essayage plus grande avec la possibilité de voir et copier les listes d'objets d'autres joueurs et de générer des liens de cabine d'essayage Wowhead.";
L["General"] = "Général";   --Options générales
L["Interface"] = "Interface";
L["Shortcuts"] = "Raccourcis";
L["Themes"] = "Thèmes";
L["Effects"] = "Effets";   --Effet de l'UI
L["Camera"] = "Caméra";
L["Transmog"] = "Transmog";
L["Credits"] = "Crédits";
L["Border Theme Header"] = "Thème de bordure";
L["Border Theme Bright"] = "Clair";
L["Border Theme Dark"] = "Sombre";
L["Text Width"] = "Largeur du texte";
L["Truncate Text"] = "Tronquer le texte";
L["Stat Sheet"] = "Fiche de statistiques";
L["Minimap Button"] = "Bouton de la minicarte";
L["Fade Out"] = "Disparition au survol de la souris";
L["Fade Out Description"] = "Disparaît au survol de la souris";
L["Hotkey"] = "Touches de raccourci";
L["Double Tap"] = "Ouvrir Narcissus en double-tap";
L["Double Tap Description"] = "Double-tapez la touche assignée au panneau de personnage pour ouvrir Narcissus.";
L["Show Detailed Stats"] = "Statistiques détaillées";
L["Tooltip Color"] = "Couleur de l'infobulle";
L["Entrance Visual"] = "Visuel d'entrée";
L["Entrance Visual Description"] = "Jouer les effets de sort lorsque votre modèle apparaît.";
L["Panel Scale"] = "Échelle du panneau";
L["Exit Confirmation"] = "Confirmation de sortie";
L["Exit Confirmation Texts"] = "Quitter la photo de groupe ?";
L["Exit Confirmation Leave"] = "Oui";
L["Exit Confirmation Cancel"] = "Non";
L["Ultra-wide"] = "Ultra-large";
L["Ultra-wide Optimization"] = "Optimisation ultra-large";
L["Baseline Offset"] = "Décalage ultra-large";
L["Ultra-wide Tooltip"] = "Vous pouvez voir cette option car vous utilisez un moniteur %s:9.";
L["Interactive Area"] = "Zone interactive";
L["Use Bust Shot"] = "Zoom sur le haut du corps";
L["Use Escape Button"] = "Quitter Narcissus en appuyant sur |cffffdd10(Esc)|r";
L["Use Escape Button Description"] = "Alternativement, vous pouvez cliquer sur le bouton X caché en haut à droite de votre écran pour quitter.";
L["Show Module Panel Gesture"] = "Afficher le panneau des modules au survol de la souris";
L["Independent Minimap Button"] = "Indépendant des autres add-ons";
L["AFK Screen"] = "Écran AFK";
L["Keep Standing"] = "Rester debout";
L["Keep Standing Description"] = "Lancer /stand de temps en temps lorsque vous êtes AFK. Cela n'empêchera pas la déconnexion AFK.";

L["None"] = "Aucun";
L["NPC"] = "PNJ";
L["Database"] = "Base de données";
L["Creature Tooltip"] = "Infobulle de créature";
L["RAM Usage"] = "Utilisation de la RAM";
L["Others"] = "Autres";
L["Find Relatives"] = "Trouver des proches";
L["Find Related Creatures Description"] = "Rechercher des créatures avec le même nom de famille.";
L["Find Relatives Hotkey Format"] = "Appuyez sur %s pour trouver des proches.";
L["Translate Names"] = "Traduire les noms";
L["Translate Names Description"] = "Afficher les noms traduits sur";
L["Translate Names Languages"] = "Traduire en";
L["Select Language Single"] = "Sélectionnez une langue à afficher sur les plaques de nom";
L["Select Language Multiple"] = "Sélectionnez les langues à afficher sur l'infobulle";
L["Load on Demand"] = "Charger à la demande";
L["Load on Demand Description On"] = "Ne chargez pas la base de données tant que les fonctions de recherche ne sont pas utilisées.";
L["Load on Demand Description Off"] = "Charger la base de données des créatures lorsque vous vous connectez.";
L["Load on Demand Description Disabled"] = NARCI_COLOR_YELLOW.. "Ce paramètre est verrouillé car vous avez activé l'infobulle de créature.";
L["Tooltip"] = "Infobulle";
L["Name Plate"] = "Plaque de nom";
L["Offset Y"] = "Décalage Y";
L["Screenshot Quality"] = "Qualité des captures d'écran";
L["Screenshot Quality Description"] = "Une qualité supérieure entraîne une taille de fichier plus grande.";
L["Camera Movement"] = "Mouvement de la caméra";
L["Orbit Camera"] = "Caméra orbitale";
L["Orbit Camera Description On"] = "Lorsque vous ouvrez ce panneau de personnage, la caméra sera tournée vers l'avant et commencera à orbiter.";
L["Orbit Camera Description Off"] = "Lorsque vous ouvrez ce panneau de personnage, la caméra sera zoomée sans rotation.";
L["Camera Safe Mode"] = "Mode sécurisé de la caméra";
L["Camera Safe Mode Description"] = "Désactivez complètement la fonctionnalité ActionCam après avoir fermé le panneau de personnage.";
L["Camera Safe Mode Description Extra"] = "Cette option est verrouillée car vous utilisez DynamicCam.";
L["Camera Transition"] = "Transition de la caméra";
L["Camera Transition Description On"] = "La caméra se déplacera en douceur vers la position prédéterminée lorsque vous ouvrez ce panneau de personnage.";
L["Camera Transition Description Off"] = "La transition de la caméra devient instantanée. À partir de la deuxième fois que vous utilisez ce panneau de personnage.\nLa transition instantanée remplacera le préréglage de la caméra #4.";
L["Interface Options Tab Description"] = "Vous pouvez également accéder à ce panneau en cliquant sur le bouton en forme de roue dentée à côté de la barre d'outils en bas à gauche de votre écran en utilisant Narcissus.";
L["Soulbinds"] = COVENANT_PREVIEW_SOULBINDS;
L["Conduit Tooltip"] = "Effets des conduits de rang supérieur";
L["Paperdoll Widget"] = "Widget Paper Doll";
L["Item Tooltip"] = "Infobulle d'objet";
L["Style"] = "Style";
L["Tooltip Style 1"] = "Nouvelle génération";
L["Tooltip Style 2"] = "L'original";
L["Addtional Info"] = "Infos supplémentaires";
L["Item ID"] = "ID de l'objet";
L["Camera Reset Notification"] = "Le décalage de la caméra a été réinitialisé à zéro. Si vous souhaitez désactiver cette fonctionnalité, allez dans Préférences - Caméra, puis désactivez le mode sécurisé de la caméra.";
L["Binding Name Open Narcissus"] = "Ouvrir le panneau de personnage Narcissus";

L["Developer Colon"] = "Développeur : ";
L["Project Page"] = "Page du projet";
L["Press Copy Yellow"] = "Appuyez sur |cffffd100".. NARCI_SHORTCUTS_COPY .."|r pour copier";
L["New Option"] = NARCI_NEW_ENTRY_PREFIX.." NOUVEAU".."|r"

--Contrôle du modèle--
NARCI_STAND_IDLY = "Rester immobile";
NARCI_RANGED_WEAPON = "Arme à distance";
NARCI_MELEE_WEAPON = "Arme de mêlée";
NARCI_SPELLCASTING = "Lancer de sort";
NARCI_ANIMATION_ID = "ID d'animation";
NARCI_LINK_LIGHT_SETTINGS = "Lier les sources de lumière";
NARCI_LINK_MODEL_SCALE = "Lier les échelles des modèles";
NARCI_GROUP_PHOTO_AVAILABLE = "Désormais disponible dans Narcissus";
NARCI_GROUP_PHOTO_NOTIFICATION = "Veuillez sélectionner une cible.";
NARCI_GROUP_PHOTO_STATUS_HIDDEN = "Caché";
NARCI_DIRECTIONAL_AMBIENT_LIGHT = "Lumière directionnelle/ambiante";
NARCI_DIRECTIONAL_AMBIENT_LIGHT_TOOLTIP = "Basculer entre\n- Lumière directionnelle qui peut être bloquée par des objets et projeter des ombres\n- Lumière ambiante qui influence l'ensemble du modèle";

L["Group Photo"] = "Photo de groupe";
L["Reset"] = "Réinitialiser";
L["Actor Index"] = "Index";
L["Move To Front"] = "|cff40c7ebAvant|r";
L["Actor Index Tooltip"] = "Faites glisser un bouton d'index pour changer la couche du modèle.";
L["Play Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Jouer cette animation\n"..NARCI_MOUSE_BUTTON_ICON_2.."Reprendre les animations de tous les modèles";
L["Pause Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Pause cette animation\n"..NARCI_MOUSE_BUTTON_ICON_2.."Mettre en pause les animations de tous les modèles";
L["Save Layers"] = "Enregistrer les calques";
L["Save Layers Tooltip"] = "Capture automatiquement 6 captures d'écran pour la composition d'images.\nVeuillez ne pas bouger votre curseur ni cliquer sur aucun bouton pendant ce processus. Sinon, votre personnage pourrait devenir invisible après avoir quitté l'addon. Si cela se produit, utilisez cette commande :\n/console showplayer";
L["Ground Shadow"] = "Ombre au sol";
L["Ground Shadow Tooltip"] = "Ajoute une ombre mobile au sol sous votre modèle.";
L["Hide Player"] = "Cacher le joueur";
L["Hide Player Tooltip"] = "Rendre votre personnage invisible pour vous-même.";
L["Virtual Actor"] = "Virtuel";
L["Virtual Actor Tooltip"] = "Seul l'effet visuel du sort sur ce modèle est visible.";
L["Self"] = "Soi-même";
L["Target"] = "Cible";
L["Compact Mode Tooltip"] = "Utilisez uniquement la partie gauche de votre écran pour présenter votre transmog.";
L["Toggle Equipment Slots"] = "Basculer les emplacements d'équipement";
L["Toggle Text Mask"] = "Basculer le masque de texte";
L["Toggle 3D Model"] = "Basculer le modèle 3D";
L["Toggle Model Mask"] = "Basculer le masque de modèle";
L["Show Color Sliders"] = "Afficher les curseurs de couleur";
L["Show Color Presets"] = "Afficher les préréglages de couleur";
L["Keep Current Form"] = "Maintenez "..NARCI_MODIFIER_ALT.." pour garder la forme de métamorphose.";
L["Race Change Tooltip"] = "Changer pour une autre race jouable";
L["Sex Change Tooltip"] = "Changer de sexe";
L["Show More options"] = "Afficher plus d'options";
L["Show Less Options"] = "Afficher moins d'options";
L["Shadow"] = "Ombre";
L["Light Source"] = "Source de lumière";
L["Light Source Independent"] = "Indépendante";
L["Light Source Interconnected"] = "Interconnectée";


--Animation Browser--
L["Animation"] = "Animation";
L["Animation Tooltip"] = "Parcourir, rechercher des animations";
L["Animation Variation"] = "Variation";
L["Reset Slider"] = "Réinitialiser à zéro";

--Navigateur de visuels de sorts--
L["Visuals"] = "Visuels";
L["Visual ID"] = "ID visuel";
L["Animation ID Abbre"] = "ID anim.";
L["Category"] = "Catégorie";
L["Sub-category"] = "Sous-catégorie";
L["My Favorites"] = "Mes favoris";
L["Reset Visual Tooltip"] = "Supprimer les visuels non appliqués";
L["Remove Visual Tooltip"] = "Clic gauche : Supprimer un visuel sélectionné\nClic long : Supprimer tous les visuels appliqués";
L["Apply"] = "Appliquer";
L["Applied"] = "Appliqué";   --Visuels qui ont été "appliqués" au modèle
L["Remove"] = "Supprimer";
L["Rename"] = "Renommer";
L["Refresh Model"] = "Rafraîchir le modèle";
L["Toggle Browser"] = "Basculer le navigateur de visuels de sorts";
L["Next And Previous"] = NARCI_MOUSE_BUTTON_ICON_1.."Aller au suivant\n"..NARCI_MOUSE_BUTTON_ICON_2.."Aller au précédent";
L["New Favorite"] = "Nouveau favori";
L["Favorites Add"] = "Ajouter à mes favoris";
L["Favorites Remove"] = "Retirer des favoris";
L["Auto-play"] = "Lecture automatique";   --Lecture automatique de l'animation suggérée
L["Auto-play Tooltip"] = "Lecture automatique de l'animation\nassociée au visuel sélectionné.";
L["Delete Entry Plural"] = "Supprimera %s entrées";
L["Delete Entry Singular"] = "Supprimera %s entrée";
L["History Panel Note"] = "Les visuels appliqués seront affichés ici";
L["Return"] = "Retour";
L["Close"] = "Fermer";
L["Change Pack"] = "Changer de pack";

--Dressing Room--
L["Undress"] = "Déshabiller";
L["Favorited"] = "Favori";
L["Unfavorited"] = "Non favori";
L["Item List"] = "Liste des objets";
L["Use Target Model"] = "Utiliser le modèle de la cible";
L["Use Your Model"] = "Utiliser votre modèle";
L["Cannot Inspect Target"] = "Impossible d'inspecter la cible";
L["External Link"] = "Lien externe";
L["Add to MogIt Wishlist"] = "Ajouter à la liste de souhaits MogIt";
L["Show Taint Solution"] = "Comment résoudre ce problème ?";
L["Taint Solution Step1"] = "1. Rechargez votre interface utilisateur.";
L["Taint Solution Step2"] = "2. "..NARCI_MODIFIER_CONTROL.." + Clic gauche sur un objet pour ouvrir la cabine d'essayage.";

--NPC Browser--
NARCI_NPC_BROWSER_TITLE_LEVEL = ".*%?%?.?";      --Level ?? --Use this to check if the second line of the tooltip is NPC's title or unit type
L["NPC Browser"] = "Navigateur de PNJ";
L["NPC Browser Tooltip"] = "Choisissez un PNJ dans la liste.";
L["Search for NPC"] = "Rechercher un PNJ";
L["Name or ID"] = "Nom ou ID";
L["NPC Has Weapons"] = "Possède des armes caractéristiques";
L["Retrieving NPC Info"] = "Récupération des informations sur le PNJ";
L["Loading Database"] = "Chargement de la base de données...\nVotre écran pourrait se figer pendant quelques secondes.";
L["Other Last Name Format"] = "Autres "..NARCI_COLOR_GREY_70.."%s(s)|r:\n";
L["Too Many Matches Format"] = "\nPlus de %s correspondances.";

--Solving Lower-case or Abbreviation Issue--
NARCI_STAT_STRENGTH = SPEC_FRAME_PRIMARY_STAT_STRENGTH;
NARCI_STAT_AGILITY = SPEC_FRAME_PRIMARY_STAT_AGILITY;
NARCI_STAT_INTELLECT = SPEC_FRAME_PRIMARY_STAT_INTELLECT;
NARCI_CRITICAL_STRIKE = STAT_CRITICAL_STRIKE;


--Equipment Comparison--
L["Azerite Powers"] = "Azerite Powers";
L["Gem Tooltip Format1"] = "%s and %s";
L["Gem Tooltip Format2"] = "%s, %s and %s more...";

--Equipment Set Manager
L["Equipped Item Level Format"] = "Équipé %s";
L["Equipped Item Level Tooltip"] = "Le niveau moyen des objets actuellement équipés.";
L["Equipment Manager"] = EQUIPMENT_MANAGER;
L["Toggle Equipment Set Manager"] = NARCI_MOUSE_BUTTON_ICON_1.."Gestionnaire de sets d'équipement.";
L["Duplicated Set"] = "Set dupliqué";
L["Low Item Level"] = "Niveau d'objet bas";
L["1 Missing Item"] = "1 objet manquant";
L["n Missing Items"] = "%s objets manquants";
L["Update Items"] = "Mettre à jour les objets";
L["Don't Update Items"] = "Ne pas mettre à jour les objets";
L["Update Talents"] = "Mettre à jour les talents";
L["Don't Update Talents"] = "Ne pas mettre à jour les talents";
L["Old Icon"] = "Ancienne icône";
L["NavBar Saved Sets"] = "Enregistré";   --Un set d'équipement enregistré
L["NavBar Incomplete Sets"] = INCOMPLETE;
NARCI_ICON_SELECTOR = "Sélecteur d'icône";
NARCI_DELETE_SET_WITH_LONG_CLICK = "Supprimer le set\n|cff808080(cliquer et maintenir)|r";


--Corruption System
L["Corruption System"] = "Corruption";
L["Eye Color"] = "Couleur des yeux";
L["Blizzard UI"] = "Interface Blizzard";
L["Corruption Bar"] = "Barre de corruption";
L["Corruption Bar Description"] = "Activer la barre de corruption à côté du panneau de personnage.";
L["Corruption Debuff Tooltip"] = "Infobulle de debuff";
L["Corruption Debuff Tooltip Description"] = "Remplace l'infobulle des effets négatifs par défaut par son équivalent numérique.";
L["No Corrupted Item"] = "Vous n'avez équipé aucun objet corrompu.";

L["Crit Gained"] = CRIT_ABBR.." gagné";
L["Haste Gained"] = STAT_HASTE.." gagné";
L["Mastery Gained"] = STAT_MASTERY.." gagné";
L["Versatility Gained"] = STAT_VERSATILITY.." gagné";

L["Proc Crit"] = "Proc "..CRIT_ABBR;
L["Proc Haste"] = "Proc "..STAT_HASTE;
L["Proc Mastery"] = "Proc "..STAT_MASTERY;
L["Proc Versatility"] =  "Proc "..STAT_VERSATILITY;

L["Critical Damage"] = CRIT_ABBR.."DMG";

L["Corruption Effect Format1"] = "|cffffffff%s%%|r vitesse réduite";
L["Corruption Effect Format2"] = "|cffffffff%s|r dégâts initiaux\n|cffffffff%s m|r de rayon";
L["Corruption Effect Format3"] = "|cffffffff%s|r dégâts\n|cffffffff%s%%|r de vos PV";
L["Corruption Effect Format4"] = "Être frappé par la Chose d'au-delà déclenche d'autres debuffs";
L["Corruption Effect Format5"] = "|cffffffff%s%%|r dégâts/soins reçus modifiés";

--Cadre de superposition de texte
L["Text Overlay Button Tooltip1"] = "Bulle de dialogue simple";
L["Text Overlay Button Tooltip2"] = "Bulle de dialogue avancée";
L["Text Overlay Button Tooltip3"] = "Tête parlante";
L["Text Overlay Button Tooltip4"] = "Sous-titre flottant";
L["Text Overlay Button Tooltip5"] = "Sous-titre avec barre noire";
L["Visibility"] = "Visibilité";

--Achievement Frame--
L["Use Achievement Panel"] = "Utiliser comme panneau de hauts faits principal";
L["Use Achievement Panel Description"] = "Cliquez sur les notifications ou les hauts faits suivis pour ouvrir ce panneau.";
L["Incomplete First"] = "Incomplets en premier";
L["Earned First"] = "Accomplis en premier";
L["Settings"] = "Paramètres";
L["Next Prev Card"] = "Carte Suiv/Préc";
L["Track"] = "Suivre";   --Suivre les hauts faits
L["Show Unearned Mark"] = "Afficher la marque non acquise";
L["Show Unearned Mark Description"] = "Marquer les hauts faits que je n'ai pas réalisés avec un X rouge.";
L["Show Dates"] = "Afficher les dates";
L["Hide Dates"] = "Cacher les dates";
L["Pinned Entries"] = "Entrées épinglées";
L["Pinned Entry Format"] = "Épinglé  %d/%d";


--Barbershop--
L["Save New Look"] = "Enregistrer le nouveau look";
L["No Available Slot"] = "Aucun emplacement de sauvegarde disponible";
L["Look Saved"] = "Look enregistré";
L["Cannot Save Forms"] = "Impossible d'enregistrer les formes";
L["Profiles"] = SOCIAL_SHARE_TEXT or "Partager";
L["Share"] = "Partager";
L["Save Notify"] = "Notifier pour enregistrer la nouvelle apparence";
L["Save Notify Tooltip"] = "Vous notifier d'enregistrer la personnalisation après avoir cliqué sur le bouton Accepter.";
L["Show Randomize Button"] = "Afficher le bouton de randomisation de l'apparence";
L["Coins Spent"] = "Pièces dépensées";
L["Locations"] = "Lieux";
L["Location"] = "Lieu";
L["Visits"] = "Visites";     --nombre de visites
L["Duration"] = "Durée";
L["Edit Name"] = "Modifier le nom";
L["Delete Look"] = "Supprimer le look\n(Cliquer et maintenir)";
L["Export"] = "Exporter";
L["Import"] = "Importer";
L["Paste Here"] = "Coller ici";
L["Press To Copy"] = "Appuyez sur |cffcccccc".. NARCI_SHORTCUTS_COPY.."|r pour copier";
L["String Copied"] = NARCI_COLOR_GREEN_MILD.. "Copié".."|r";
L["Failure Reason Unknown"] = "Erreur inconnue";
L["Failure Reason Decode"] = "Échec du décodage.";
L["Failure Reason Wrong Character"] = "La race/le genre/la forme actuelle ne correspond pas au profil importé.";
L["Failure Reason Dragonriding"] = "Ce profil est pour le Vol à dos de dragon.";
L["Wrong Character Format"] = "Requiert %s %s."; --ex. Requiert Homme Humain
L["Import Lack Option"] = "%d |4option:options; non trouvée(s).";
L["Import Lack Choice"] = "%d |4choix:choix; non trouvée(s).";
L["Decode Good"] = "Décodé avec succès.";
L["Barbershop Export Tooltip"] = "Encode la personnalisation actuellement utilisée en une chaîne de caractères qui peut être partagée en ligne.\n\nVous pouvez modifier tous les textes avant les deux-points (:).";
L["Settings And Share"] = (SETTINGS or "Paramètres") .." & ".. (SOCIAL_SHARE_TEXT or "Partager");
L["Loading Portraits"] = "Chargement des portraits";

--Tutorial--
L["Alert"] = "Alerte";
L["Race Change"] = "Changement de race/genre";
L["Race Change Line1"] = "Vous pouvez à nouveau changer de race et de genre. Mais il y a quelques limitations :\n1. Vos armes disparaîtront.\n2. Les effets visuels des sorts ne pourront plus être supprimés.\n3. Cela ne fonctionne pas sur les autres joueurs ou PNJ.";
L["Guide Spell Headline"] = "Essayer ou Appliquer";
L["Guide Spell Criteria1"] = "Clic gauche pour ESSAYER";
L["Guide Spell Criteria2"] = "Clic droit pour APPLIQUER";
L["Guide Spell Line1"] = "La plupart des effets visuels de sorts que vous ajoutez en cliquant sur le bouton gauche s'estomperont en quelques secondes, tandis que ceux que vous ajoutez en cliquant sur le bouton droit ne s'estomperont pas.\n\nDéplacez maintenant votre curseur vers une entrée ci-dessous puis :";
L["Guide Spell Choose Category"] = "Vous pouvez ajouter des effets visuels de sorts à votre modèle. Choisissez une catégorie qui vous plaît. Ensuite, choisissez une sous-catégorie.";
L["Guide History Headline"] = "Panneau d'historique";
L["Guide History Line1"] = "Au maximum, 5 effets visuels récemment appliqués peuvent être conservés ici. Vous pouvez en sélectionner un et le supprimer en cliquant sur le bouton Supprimer à l'extrémité droite.";
L["Guide Refresh Line1"] = "Utilisez ce bouton pour supprimer tous les effets visuels de sorts non appliqués. Ceux qui étaient dans le panneau d'historique seront réappliqués.";
L["Guide Input Headline"] = "Entrée manuelle";
L["Guide Input Line1"] = "Vous pouvez également entrer un SpellVisualKitID vous-même. Depuis la version 9.0, son plafond est d'environ 155 000.\nVous pouvez utiliser la molette de votre souris pour essayer l'ID suivant/précédent.\nTrès peu d'IDs peuvent faire planter le jeu.";
L["Guide Equipment Manager Line1"] = "Double-cliquez : Utiliser un set\nClic droit : Modifier un set.\n\nLa fonction précédente de ce bouton a été déplacée vers les Préférences.";
L["Guide Model Control Headline"] = "Contrôle du modèle";
L["Guide Model Control Line1"] = format("Ce modèle partage les mêmes actions de souris que vous utilisez dans la cabine d'essayage, plus :\n\n1. Maintenez %s et clic gauche : Faites pivoter le modèle autour de l'axe Y.\n2. Maintenez %s et clic droit : Effectuez un zoom progressif.", NARCI_MODIFIER_ALT, NARCI_MODIFIER_ALT);
L["Guide Minimap Button Headline"] = "Bouton de la minicarte";
L["Guide Minimap Button Line1"] = "Le bouton de la minicarte de Narcissus peut maintenant être géré par d'autres addons.\nVous pouvez modifier cette option dans le panneau des Préférences. Cela peut nécessiter un rechargement de l'interface utilisateur.";
L["Guide NPC Entrance Line1"] = "Vous pouvez ajouter n'importe quel PNJ dans votre scène.";
L["Guide NPC Browser Line1"] = "Les PNJ notables sont listés dans le catalogue ci-dessous.\nVous pouvez également rechercher TOUTES les créatures par nom ou ID.\nNotez que la première fois que vous utilisez la fonction de recherche lors de cette connexion, cela peut prendre quelques secondes pour construire la table de recherche et votre écran pourrait également se figer.\nVous pouvez désactiver l'option \"Charger à la demande\" dans le panneau des Préférences afin que la base de données soit construite dès que vous vous connectez.";

--Splash--
NARCI_SPLASH_WHATS_NEW_FORMAT = "Quoi de neuf dans Narcissus %s";
L["See Ads"] = "Voir les publicités de notre sponsor authentique";    --Pas de vraies publicités !
L["Splash Category1"] = L["Photo Mode"];
L["Splash Content1 Name"] = "Navigateur d'armes";
L["Splash Content1 Description"] = "-Visualisez et utilisez toutes les armes de la base de données, y compris celles qui ne sont pas obtenables par les joueurs.";
L["Splash Content2 Name"] = "Écran de sélection de personnage";
L["Splash Content2 Description"] = "-Ajoutez un cadre décoratif pour créer (faussement) votre propre écran de sélection de personnage.";
L["Splash Content3 Name"] = "Cabine d'essayage";
L["Splash Content3 Description"] = "-Le module de la cabine d'essayage a été redessiné.\n-La liste des objets inclut désormais des épaulières dépareillées et des illusions d'arme.";
L["Splash Content4 Name"] = "Étable à familiers";
L["Splash Content4 Description"] = "-Les chasseurs peuvent sélectionner et ajouter des familiers en utilisant une nouvelle interface d'étable en mode photo de groupe.";
L["Splash Category2"] = "Cadre de personnage";
L["Splash Content5 Name"] = "Éclat de domination";
L["Splash Content5 Description"] = "-L'indicateur d'éclat de domination apparaîtra si vous équipez des objets pertinents.\n-Une liste d'éclats disponibles vous sera présentée lorsque vous insérez des objets de domination.\n-Extrayez les éclats en un seul clic.";
L["Splash Content6 Name"] = "Liens d'âme";
L["Splash Content6 Description"] = "-L'interface des liens d'âme a été mise à jour. Vous pouvez vérifier les effets des conduits de rang supérieur.";
L["Splash Content7 Name"] = "Visuels";
L["Splash Content7 Description"] = "-La bordure hexagonale des objets a un nouveau look. Certains objets ont des apparences uniques.";

--Project Details--
NARCI_ALL_PROJECTS = "Tous les projets";
NARCI_PROJECT_AAA_TITLE = "|cff008affA|cff0d8ef2z|cff1a92e5e|cff2696d9r|cff339acco|cff409ebft|cff4da1b2h |cff59a5a6A|cff66a999d|cff73ad8cv|cff7fb180e|cff8cb573n|cff99b966t|cffa6bd59u|cffb2c14dr|cffbfc440e |cffccc833A|cffd9cc26l|cffe5d01ab|cfff2d40du|cffffd800m|r";
NARCI_PROJECT_AAA_SUMMARY = "Explorez des lieux d'intérêt et collectez des histoires et des photos à travers tout Azeroth.|cff636363";
NARCI_PROJECT_NARCISSUS_SUMMARY = "Un panneau de personnage immersif et votre outil ultime de capture d'écran.";

L["AboutTab Developer Note"] = "Merci d'essayer cet add-on ! Si vous avez des problèmes, des suggestions ou des idées, veuillez laisser un commentaire sur la page curseforge ou me contacter sur...";


--Conversation--
L["Q1"] = "Qu'est-ce que c'est ?";
L["Q2"] = "Je sais. Mais pourquoi est-ce si grand ?";
L["Q3"] = "Ce n'est pas drôle. J'ai juste besoin d'un message normal.";
L["Q4"] = "Bien. Que faire si je veux le désactiver ?";
L["Q5"] = "Encore une chose, pourrais-tu me promettre plus de blagues ?";
L["A1"] = "Apparemment, c'est une boîte de dialogue de confirmation de sortie. Elle s'affiche lorsque vous essayez de quitter le mode photo de groupe en appuyant sur la touche de raccourci.";
L["A2"] = "Ha, c'est ce qu'elle a dit.";
L["A3"] = "D'accord... d'accord..."
L["A4"] = "Désolé, vous ne pouvez pas. C'est pour la sécurité, vous savez.";


--Search--
L["Search Result Singular"] = "%s résultat";
L["Search Result Plural"] = "%s résultats";
L["Search Result Overflow"] = "%s+ résultats";
L["Search Result None"] = CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS;

--Weapon Browser--
L["Draw Weapon"] = "Dégainer l'arme";
L["Unequip Item"] = "Déséquiper";
L["WeaponBrowser Guide Hotkey"] = "Spécifiez dans quelle main tenir l'arme :";
L["WeaponBrowser Guide ModelType"] = "Certains objets sont limités à un certain type de modèle :";
L["WeaponBrowser Guide DressUpModel"] = "Cela sera le type par défaut si votre cible est un joueur, sauf si vous tenez <%s> lors de sa création.";
L["WeaponBrowser Guide CinematicModel"] = "Le type de modèle sera toujours cinématographique si la créature est un PNJ. Vous ne pouvez pas rengainer les armes.";
L["Weapon Browser Specify Hand"] = "|cffffd100"..NARCI_MODIFIER_CONTROL.." + Clic gauche|r pour équiper l'objet dans la main principale.\n|cffffd100"..NARCI_MODIFIER_ALT.." + Clic gauche|r pour la main secondaire.";

--Pet Stables--
L["PetStable Tooltip"] = "Choisissez un familier dans votre étable";
L["PetStable Loading"] = "Récupération des informations sur le familier";

--Objet de domination--
L["Item Bonus"] = "Bonus :";
L["Combat Error"] = NARCI_COLOR_RED_MILD.."Quittez le combat pour continuer".."|r";
L["Extract Shard"] = "Extraire l'éclat";
L["No Service"] = "Pas de service";
L["Shards Disabled"] = "Les éclats de domination sont désactivés en dehors de l'Antre.";


--Mythic+ Leaderboard--
L["Mythic Plus"] = "Mythique+";
L["Mythic Plus Abbrev"] = "M+";
L["Total Runs"] = "Total des courses : ";
L["Complete In Time"] = "Dans les temps";
L["Complete Over Time"] = "Hors délai";
L["Runs"] = "Courses";


--Equipment Upgrade--
L["Temp Enchant"] = "Enchantements temporaires";       --ERR_TRADE_TEMP_ENCHANT_BOUND
L["Owned"] = "Possédé";                           --Afficher uniquement les objets possédés
L["At Level"] = "Au niveau %d :";                 --Les enchantements évoluent avec le niveau du joueur
L["No Item Alert"] = "Aucun objet compatible";
L["Click To Insert"] = "Cliquer pour insérer";       --Insérer une gemme
L["No Socket"] = "Pas de châsse";
L["No Other Item For Slot"] = "Aucun autre objet pour %s";       --où %s est le nom de l'emplacement
L["In Bags"] = "Dans les sacs";
L["Item Socketing Tooltip"] = "Cliquez et maintenez pour incruster";
L["No Available Gem"] = "|cffd8d8d8Aucune gemme disponible|r";
L["Missing Enchant Alert"] = "Alerte d'enchantement manquant";
L["Missing Enchant"] = NARCI_COLOR_RED_MILD.."Pas d'enchantement".."|r";


--Statistics--
S["Narcissus Played"] = "Temps total passé dans Narcissus";
S["Format Since"] = "(depuis %s)";
S["Screenshots"] = "Captures d'écran prises dans Narcissus";

--Turntable Showcase--
L["Turntable"] = "Plateau tournant";
L["Picture"] = "Image";
L["Elapse"] = "Écoulé";
L["Turntable Tab Animation"] = "Animation";
L["Turntable Tab Image"] = "Image";
L["Turntable Tab Quality"] = "Qualité";
L["Turntable Tab Background"] = "Arrière-plan";
L["Spin"] = "Tourner";
L["Sync"] = "Synchroniser";
L["Rotation Period"] = "Période";
L["Period Tooltip"] = "Le temps nécessaire pour effectuer une rotation complète.\nCela devrait également correspondre à la |cffccccccdurée de découpe|r de votre GIF ou vidéo.";
L["MSAA Tooltip"] = "Modifier temporairement l'anti-aliasing pour lisser les bords irréguliers au détriment des performances.";
L["Image Size"] = "Taille de l'image";
L["Font Size"] = FONT_SIZE;
L["Item Name Show"] = "Afficher les noms des objets";
L["Item Name Hide"] = "Cacher les noms des objets";
L["Outline Show"] = "Cliquez pour afficher le contour";
L["Outline Hide"] = "Cliquez pour cacher le contour";
L["Preset"] = "Préréglage";
L["File"] = "Fichier";     --Nom du fichier
L["File Tooltip"] = "Mettez votre propre image sous |cffccccccWorld of Warcraft\\retail\\Interface\\AddOns|r et insérez le nom du fichier dans cette case.\nL'image doit être un fichier |cffcccccc512x512|r ou |cffcccccc1024x1024|r |cffccccccJPG|r";
L["Raise Level"] = "Mettre au premier plan";
L["Lower Level"] = "Envoyer à l'arrière-plan";
L["Show Mount"] = "Afficher la monture";
L["Hide Mount"] = "Cacher la monture";
L["Loop Animation On"] = "Boucle";
L["Click To Continue"] = "cliquez pour continuer";
L["Showcase Splash 1"] = "Créez des animations sur plateau tournant pour présenter votre transmogrification avec Narcissus et un enregistreur d'écran.";
L["Showcase Splash 2"] = "Cliquez sur le bouton ci-dessous pour copier les objets depuis la cabine d'essayage.";
L["Showcase Splash 3"] = "Cliquez sur le bouton ci-dessous pour faire tourner votre personnage.";
L["Showcase Splash 4"] = "Enregistrez l'écran avec un logiciel d'enregistrement vidéo, puis convertissez-le en GIF.";


--Item Sets--
L["Cycle Spec"] = "Appuyez sur Tab pour parcourir les spécialisations";
L["Paperdoll Splash 1"] = "Activer l'indicateur de set de classe ?";
L["Paperdoll Splash 2"] = "Choisir un thème";

--Sélection de tenue--
L["Outfit"] = "Tenue";
L["Models"] = "Modèles";
L["Origin Outfits"] = "Tenues originales";
L["Outfit Owner Format"] = "Tenues de %s";
L["SortMethod Recent"] = "Récents";
L["SortMethod Name"] = "Nom";

--Format de correspondance d'infobulle--
L["Find Cooldown"] = " temps de recharge";
L["Find Recharge"] = " rechargement";

--Arbre de talents--
L["Mini Talent Tree"] = "Mini arbre de talents";
L["Show Talent Tree When"] = "Afficher l'arbre de talents lorsque vous...";
L["Show Talent Tree Paperdoll"] = "Ouvrez le mannequin";
L["Show Talent Tree Inspection"] = "Inspectez d'autres joueurs";
L["Truncate Talent Description"] = "Tronquer la description du talent";
L["Appearance"] = "Apparence";
L["Use Class Background"] = "Utiliser l'arrière-plan de classe";
L["Empty Loadout Name"] = "Nom";
L["No Save Slot Red"] = NARCI_COLOR_RED_MILD.. "Pas d'emplacement de sauvegarde" .."|r";
L["Save"] = "Sauvegarder";

L["Day Plural"] = "jours";
L["Day Singular"] = "jour";
L["Hour Plural"] = "heures";
L["Hour Singular"] = "heure";
