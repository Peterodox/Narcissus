--Localization kindly provided by onizenos

if not (GetLocale() == "ptBR") then
    return;
end
local L = Narci.L;
local S = Narci.L.S;

NARCI_GRADIENT = "|cffA236EFN|r|cff9448F1a|r|cff865BF2r|r|cff786DF4c|r|cff6A80F6i|r|cff5D92F7s|r|cff4FA4F9s|r|cff41B7FAu|r|cff33C9FCs|r"

L["Developer Info"] = "Desenvolvido por Peterodox";

NARCI_MODIFIER_CONTROL = "CTRL";
NARCI_MODIFIER_ALT = "ALT";   --Windows
NARCI_SHORTCUTS_COPY = "CTRL + C";

NARCI_MOUSE_BUTTON_ICON_1 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:0:16:0:16|t";   --Botão esquerdo
NARCI_MOUSE_BUTTON_ICON_2 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:16:32:0:16|t";   --Botão direito
NARCI_MOUSE_BUTTON_ICON_3 = "|TInterface\\AddOns\\Narcissus\\Art\\Keyboard\\Mouse-Small:16:16:0:0:64:16:32:48:0:16|t";   --Botão do meio

if IsMacClient() then
    --Mac OS
    NARCI_MODIFIER_CONTROL = "COMMAND";
    NARCI_MODIFIER_ALT = "OPTION";
    NARCI_SHORTCUTS_COPY = "COMMAND + C";
end

NARCI_WORDBREAK_COMMA = ", ";

--Data
L["Today"] = COMMUNITIES_CHAT_FRAME_TODAY_NOTIFICATION;
L["Yesterday"] = COMMUNITIES_CHAT_FRAME_YESTERDAY_NOTIFICATION;
L["Format Days Ago"] = "%d dias atrás";
L["A Month Ago"] = "1 mês atrás";
L["Format Months Ago"] = "%d meses atrás";
L["A Year Ago"] = "1 ano atrás";
L["Format Years Ago"] = "%d anos atrás";
L["Version Colon"] = (GAME_VERSION_LABEL or "Versão")..": ";
L["Date Colon"] = "Data: ";
L["Day Plural"] = "dias";
L["Day Singular"] = "dia";
L["Hour Plural"] = "horas";
L["Hour Singular"] = "hora";

L["Swap items"] = "Trocar itens";
L["Press Copy"] = NARCI_COLOR_GREY_70.. "Aperte |r".. NARCI_SHORTCUTS_COPY.. NARCI_COLOR_GREY_70 .." para copiar";
L["Copied"] = NARCI_COLOR_GREEN_MILD.. "Link copiado";
L["Movement Speed"] = "VdM";
L["Damage Reduction Percentage"] = "%RdD";
L["Advanced Info"] = "Clique com o botão esquerdo para alternar as informações avançadas.";
L["Restore On Exit"] = "\nSuas configurações serão restauradas ao sair.";

L["Photo Mode"] = "Modo Foto";
L["Photo Mode Tooltip Open"] = "Abre as dicas de captura de tela.";
L["Photo Mode Tooltip Close"] = "Fecha as dicas de captura de tela.";
L["Photo Mode Tooltip Special"] = "Suas capturas de tela na pasta WoW Screenshots não incluirão estas dicas.";

L["Toolbar Mog Button"] = "Modo Foto";
L["Toolbar Mog Button Tooltip"] = "Mostre seu transmog ou crie um estande de fotos onde você pode adicionar outros jogadores e PNJs.";

L["Toolbar Emote Button"] = "Expressões";
L["Toolbar Emote Button Tooltip"] = "Utilize expressões com animações exclusivas.";
L["Auto Capture"] = "Captura automática";

L["Toolbar HideTexts Button"] = "Ocultar Textos";
L["Toolbar HideTexts Button Tooltip"] = "Oculte todos os nomes, balões de bate-papo e textos de combate." ..L["Restore On Exit"];

L["Toolbar TopQuality Button"] = "Qualidade Máxima";
L["Toolbar TopQuality Button Tooltip"] = "Defina todas as configurações de qualidade gráfica para o máximo." ..L["Restore On Exit"];

L["Toolbar Location Button"] = "Localização do Jogador";
L["Toolbar Location Button Tooltip"] = "Mostra o nome da zona atual e as coordenadas do jogador."

L["Toolbar Camera Button"] = "Câmera";
L["Toolbar Camera Button Tooltip"] = "Altera temporariamente as configurações da câmera."

L["Toolbar Preferences Button Tooltip"] = "Painel de opções";

--Origem especial
L["Heritage Armor"] = "Armadura Tradicional";
L["Secret Finding"] = "Descoberta Secreta";

L["Heart Azerite Quote"] = "o que é essencial é invisível aos olhos.";

--Gerenciador de Títulos
L["Open Title Manager"] = "Abrir gerenciador de Títulos";
L["Close Title Manager"] = "Fechar gerenciador de Títulos";

--Nome alternativo
L["Use Alias"] = "Mudar para Nome Alternativo";
L["Use Player Name"] = "Mudar para "..CALENDAR_PLAYER_NAME;

L["Minimap Tooltip Double Click"] = "Clique duplo";
L["Minimap Tooltip Left Click"] = "Botão esquerdo|r";
L["Minimap Tooltip To Open"] = "|cffffffffAbrir "..CHARACTER_INFO;
L["Minimap Tooltip Module Panel"] = "|cffffffffAbrir painel do módulo";
L["Minimap Tooltip Right Click"] = "Botão direito";
L["Minimap Tooltip Shift Left Click"] = "SHIFT + Botão esquerdo";
L["Minimap Tooltip Shift Right Click"] = "SHIFT + Botão direito";
L["Minimap Tooltip Hide Button"] = "|cffffffffOcultar este botão|r"
L["Minimap Tooltip Middle Button"] = "|CFFFF1000Botão do meio |cffffffffRedefinir câmera";
L["Minimap Tooltip Set Scale"] = "Definir escala: |cffffffff/narci [escala 0,8~1,2]";
L["Corrupted Item Parser"] = "|cffffffffAlternar analisador de itens corrompidos|r";
L["Toggle Dressing Room"] = "|cffffffffAlternar "..DRESSUP_FRAME.."|r";

L["Layout"] = "Layout";
L["Symmetry"] = "Simétrico";
L["Asymmetry"] = "Assimétrico";
L["Copy Texts"] = "Copiar textos";
L["Syntax"] = "Sintaxe";
L["Plain Text"] = "Texto simples";
L["BB Code"] = "BB Code";
L["Markdown"] = "Remarcação";
L["Export Includes"] = "Exportação inclui...";

L["3D Model"] = "Modelo 3D";
L["Equipment Slots"] = "Espaços de Equipamento";

--Opções
L["Override"] = "Sobrepor";
L["Invalid Key"] = "Combinação de teclas inválida.";

L["Preferences"] = "Preferências";
L["Preferences Tooltip"] = "Clique para abrir o Painel de Opções.";
L["Extensions"] = "Extensões";
L["About"] = "Sobre";
L["Image Filter"] = "Filtros";    --Filtro de imagem
L["Image Filter Description"] = "Todos os filtros, exceto vinheta, serão desabilitados no modo transmogrificação.";
L["Grain Effect"] = "Efeito de Granulação";
L["Fade Music"] = "Aparecimento/desaparecimento de música";
L["Vignette Strength"] = "Intensidade da vinheta";
L["Weather Effect"] = "Efeitos climáticos";
L["Letterbox"] = "Efeito Letterbox";
L["Letterbox Ratio"] = "Proporção";
L["Letterbox Alert1"] = "A proporção do seu monitor excede a proporção selecionada!"
L["Letterbox Alert2"] = "É recomendável definir a escala da interface do usuário para %0,1f\n(a escala atual é %0,1f)"
L["Default Layout"] = "Layout padrão";
L["Transmog Layout1"] = "Simétrico, 1 Modelo";
L["Transmog Layout2"] = "2 Modelos";
L["Transmog Layout3"] = "Modo compacto";
L["Always Show Model"] = "Mostrar modelo 3D ao usar o layout de simetria";
L["AFK Screen Description"] = "Abrir o Narcissus quando estiver ausente";
L["AFK Screen Description Extra"] = "Isso substituirá o modo ausente do ElvUI.";
L["AFK Screen Delay"] = "Abrir alguns segundos após se ausentar";
L["Item Names"] = "Nome do Item";
L["Open Narcissus"] = "Abrir o Narcissus";
L["Character Panel"] = "Painel do Personagem";
L["Screen Effects"] ="Efeitos de Tela";

L["Gemma"] = "\"Gemma\"";   --NÃO TRADUZA
L["Gemma Description"] = "Mostra uma lista de gemas ao engastar um item.";
L["Gem Manager"] = "Gerenciador de gemas";
L["Dressing Room"] = "Provador"
L["Dressing Room Description"] = "Aumenta o tamanho do provador adicionando a capacidade de visualizar e copiar itens de outros jogadores e gerar links para o provador do Wowhead.";
L["General"] = "Geral";   --Opções gerais
L["Interface"] = "Interface";
L["Shortcuts"] = "Atalhos";
L["Themes"] = "Temas";
L["Effects"] = "Efeitos";   --Efeitos de IU
L["Camera"] = "Câmera";
L["Transmog"] = "Transmogrificação";
L["Credits"] = "Créditos";
L["Border Theme Header"] = "Tema de borda";
L["Border Theme Bright"] = "Claro";
L["Border Theme Dark"] = "Escuro";
L["Text Width"] = "Largura do texto";
L["Truncate Text"] = "Reduzir texto";
L["Stat Sheet"] = "Planilha de Estatísticas";
L["Minimap Button"] = "Botão Minimapa";
L["Fade Out"] = "Desaparecer no Mouseout";
L["Fade Out Description"] = "Ocultar o botão ao mover o cursor para fora";
L["Hotkey"] = "Tecla de Atalho";
L["Double Tap"] = "Ativar clique duplo";
L["Double Tap Description"] = "Clique duas vezes na tecla vinculada ao Painel do Personagem para abrir o Narcissus.";
L["Show Detailed Stats"] = "Mostrar estatísticas detalhadas";
L["Tooltip Color"] = "Cor das dicas";
L["Entrance Visual"] = "Visual de entrada";
L["Entrance Visual Description"] = "Reproduza o visual de feitiços quando seu modelo aparecer.";
L["Panel Scale"] = "Escala do painel";
L["Exit Confirmation"] = "Confirmação de saída";
L["Exit Confirmation Texts"] = "Sair da foto em grupo?";
L["Exit Confirmation Leave"] = "Sim";
L["Exit Confirmation Cancel"] = "Não";
L["Ultra-wide"] = "Ultrawide";
L["Ultra-wide Optimization"] = "Otimização para Ultrawide";
L["Baseline Offset"] = "Deslocamento da linha de base";
L["Ultra-wide Tooltip"] = "Você pode ver esta opção porque está usando um monitor %s:9.";
L["Interactive Area"] = "Área de interação";
L["Use Bust Shot"] = "Focar no peito do personagem";
L["Use Escape Button"] = "Tecla ESC";
L["Use Escape Button Description"] = "Clique no botão X oculto no canto superior direito da tela para fechar o Narcissus.";
L["Show Module Panel Gesture"] = "Mostrar o menu do Addon ao passar o mouse";
L["Independent Minimap Button"] = "Impedir modificações feitas por outros AddOns";
L["AFK Screen"] = "Tela LDT";
L["Keep Standing"] = "Continuar de pé";
L["Keep Standing Description"] = "Usa /stand de vez em quando quando você estiver ausente. Isso não impedirá que você saia do jogo por estar ausente.";
L["None"] = "Nenhum";
L["NPC"] = "PNJ";
L["Database"] = "Base de dados";
L["Creature Tooltip"] = "Dicas de criaturas";
L["RAM Usage"] = "Uso de RAM";
L["Others"] = "Outros";
L["Find Relatives"] = "Localizar semelhantes";
L["Find Related Creatures Description"] = "Procure por criaturas com o mesmo segundo nome.";
L["Find Relatives Hotkey Format"] = "Pressione %s para encontrar semelhantes.";
L["Translate Names"] = "Traduzir nomes";
L["Translate Names Description"] = "Mostrar nomes traduzidos nas...";
L["Translate Names Languages"] = "Traduzir para";
L["Select Language Single"] = "Selecione um idioma para mostrar nas placas de identificação";
L["Select Language Multiple"] = "Selecione os idiomas para mostrar nas dicas";
L["Load on Demand"] = "Carregar sob demanda";
L["Load on Demand Description On"] = "Não carregue o banco de dados antes de usar as funções de pesquisa.";
L["Load on Demand Description Off"] = "Carregue o banco de dados de criaturas ao fazer login.";
L["Load on Demand Description Disabled"] = NARCI_COLOR_YELLOW.. "Este botão está bloqueado porque você ativou a caixa de texto de criaturas.";
L["Tooltip"] = "Dicas";
L["Name Plate"] = "Placas de identificação";
L["Offset Y"] = "Deslocamento vertical";
L["Sceenshot Quality"] = "Qualidade da captura de tela";
L["Screenshot Quality Description"] = "Uma qualidade maior resultará em arquivos maiores.";
L["Camera Movement"] = "Movimento da câmera";
L["Orbit Camera"] = "Câmera orbital";
L["Orbit Camera Description On"] = "Quando você abrir este Painel do Personagem, a câmera irá girar para sua frente e começará a lhe orbitar.";
L["Orbit Camera Description Off"] = "A câmera será ampliada sem rotação ao abrir este Painel do Personagem.";
L["Camera Safe Mode"] = "Modo seguro da câmera";
L["Camera Safe Mode Description"] = "Desativa completamente o recurso ActionCam após fechar o AddOn.";
L["Camera Safe Mode Description Extra"] = "Desativado porque você está usando DynamicCam."
L["Camera Transition"] = "Transição da câmera";
L["Camera Transition Description On"] = "A câmera se moverá suavemente para a posição predeterminada quando você abrir este Painel do Personagem.";
L["Camera Transition Description Off"] = "O movimento da câmera se torna instantâneo. Começa a partir da segunda vez que você usa este Painel do Personagem.\nA transição instantânea substituirá a predefinição #4 da câmera.";
L["Interface Options Tab Description"] = "Você também pode acessar este painel clicando no botão de engrenagem ao lado da barra de ferramentas no canto inferior esquerdo da tela enquanto estiver usando o Narcissus.";
L["Soulbinds"] = COVENANT_PREVIEW_SOULBINDS;
L["Conduit Tooltip"] = "Efeitos de Conduíte classificados por níveis";
L["Paperdoll Widget"] = "Indicador de Conjunto de Classe";
L["Item Tooltip"] = "Dicas de Itens";
L["Style"] = "Estilo";
L["Tooltip Style 1"] = "Novo";
L["Tooltip Style 2"] = "Original";
L["Addtional Info"] = "Informação adicional";
L["Item ID"] = "ID do Item";
L["Camera Reset Notification"] = "O deslocamento da câmera foi redefinido para zero. Se você deseja desativar esse recurso, vá para Preferências - Câmera e desative o Modo de segurança da câmera.";
L["Binding Name Open Narcissus"] = "Abra o Painel do Personagem do Narcissus";
L["Developer Colon"] = "Desenvolvedor: ";
L["Project Page"] = "Página do projeto";
L["Press Copy Yellow"] = "Aperte |cffffd100".. NARCI_SHORTCUTS_COPY .."|r para copiar";
L["New Option"] = NARCI_NEW_ENTRY_PREFIX.." NOVO".."|r"
L["Expansion Features"] = "Características da expansão";

--Controle de Modelo
L["Ranged Weapon"] = "Arma de longo alcance";
L["Melee Animation"] = "Arma corpo a corpo";
L["Spellcasting"] = "Conjuração";
L["Link Light Sources"] = "Vincular Fontes de Luz";
L["Link Model Scales"] = "Vincular Escalas de Modelo";
L["Hidden"] = "Esconder";
L["Light Types"] = "Luz direcional/ambiente";
L["Light Types Tooltip"] = "Alterne entre...\n- Luz direcional: Pode ser bloqueada por objetos e projetar sombras.\n- Luz ambiente: Impacta todo o modelo.";

L["Group Photo"] = "Foto em Grupo";
L["Reset"] = "Redefinir";
L["Actor Index"] = "Índice";
L["Move To Font"] = "|cff40c7ebFrente|r";
L["Actor Index Tooltip"] = "Arraste um botão de índice para alterar a camada do modelo.";
L["Play Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Reproduzir esta animação\n"..NARCI_MOUSE_BUTTON_ICON_2.."Retomar todos os modelos\' animações";
L["Pause Button Tooltip"] = NARCI_MOUSE_BUTTON_ICON_1.."Pausar esta animação\n"..NARCI_MOUSE_BUTTON_ICON_2.."Pausar todos os modelos\' animações";
L["Save Layers"] = "Salvar camadas";
L["Save Layers Tooltip"] = "Faça automaticamente 6 capturas de tela para composição de imagem.\nNão mova o cursor nem clique em nenhum botão durante este processo. Caso contrário, seu personagem pode ficar invisível após sair do AddOn. Caso isso aconteça, use este comando:\n/console showplayer";
L["Ground Shadow"] = "Sombra no solo";
L["Ground Shadow Tooltip"] = "Adiciona uma sombra de solo móvel abaixo do seu modelo.";
L["Hide Player"] = "Ocultar jogador";
L["Hide Player Tooltip"] = "Torne seu personagem invisível para você mesmo.";
L["Virtual Actor"] = "Virtual";
L["Virtual Actor Tooltip"] = "Apenas o visual de feitiço neste modelo é visível."
L["Self"] = "Você";
L["Target"] = "Alvo";
L["Compact Mode Tooltip"] = "Use apenas a parte esquerda da tela para apresentar seu transmog.";
L["Toggle Equipment Slots"] = "Alternar espaços de equipamentos";
L["Toggle Text Mask"] = "Alternar máscara de texto";
L["Toggle 3D Model"] = "Alternar modelo 3D";
L["Toggle Model Mask"] = "Alternar máscara de modelo";
L["Show Color Sliders"] = "Mostrar painel de cores";
L["Show Color Presets"] = "Mostrar cores predefinidas";
L["Keep Current Form"] = "Segure "..NARCI_MODIFIER_ALT.." para manter a forma metamorfoseada.";
L["Race Sex Change Bug"] = NARCI_COLOR_RED_MILD.."\nEste recurso possui um erro que não pode ser corrigido no momento.|r";
L["Race Change Tooltip"] = "Mudar para outra raça jogável";
L["Sex Change Tooltip"] = "Alternar corpo";
L["Show More options"] = "Mostrar mais opções";
L["Show Less Options"] = "Mostrar menos opções";
L["Shadow"] = "Sombra";
L["Light Source"] = "Fonte de luz";
L["Light Source Independent"] = "Independente";
L["Light Source Interconnected"] = "Interconectada";
L["Adjustment"] = "Ajuste";

--Navegador de Animações
L["Animation"] = "Animação";
L["Animation Tooltip"] = "Procurar animações";
L["Animation Variation"] = "Variação";
L["Reset Slider"] = "Redefinir para zero";


--Navegador visual de feitiços
L["Visuals"] = "Visuais";
L["Visual ID"] = "ID de Visuais";
L["Animation ID Abbre"] = "ID de Animações";
L["Category"] = "Categoria";
L["Sub-category"] = "Subcategoria";
L["My Favorites"] = "Meus favoritos";
L["Reset Visual Tooltip"] = "Remover visuais não aplicados";
L["Remove Visual Tooltip"] = "Clique esquerdo: Remove um visual selecionado\nClique longo: Remove todos os visuais aplicados";
L["Apply"] = "Aplicar";
L["Applied"] = "Aplicado";   --Visuais que foram "aplicados" ao modelo
L["Remove"] = "Remover";
L["Rename"] = "Renomear";
L["Refresh Model"] = "Atualizar modelo";
L["Toggle Browser"] = "Navegador de visuais de feitiços";
L["Next And Previous"] = NARCI_MOUSE_BUTTON_ICON_1.."Vá para o próximo\n"..NARCI_MOUSE_BUTTON_ICON_2.."Vá para o anterior";
L["New Favorite"] = "Novos favoritos";
L["Favorites Add"] = "Adicionar aos favoritos";
L["Favorites Remove"] = "Remover dos favoritos";
L["Auto-play"] = "Reprodução automática";   --Animação sugerida para reproduzir automaticamente
L["Auto-play Tooltip"] = "Reproduzir automaticamente a animação\nque está vinculado ao visual selecionado.";
L["Delete Entry Plural"] = "Irá excluir %s entradas";
L["Delete Entry Singular"] = "Irá excluir %s entrada";
L["History Panel Note"] = "Os visuais aplicados serão mostrados aqui";
L["Return"] = "Retornar";
L["Close"] = "Fechar";
L["Change Pack"] = "Alterar pacote";

--Provador
L["Undress"] = "Despir";
L["Favorited"] = "Favoritar";
L["Unfavorited"] = "Desfavoritar";
L["Item List"] = "Lista de Itens";
L["Use Target Model"] = "Usar modelo do alvo";
L["Use Your Model"] = "Usar seu modelo";
L["Cannot Inspect Target"] = "Não é possível inspecionar o alvo"
L["External Link"] = "Link externo";
L["Add to MogIt Wishlist"] = "Adicionar à lista de desejos do MogIt";
L["Show Taint Solution"] = "Como resolver este problema?";
L["Taint Solution Step1"] = "1. Recarregue sua IU.";
L["Taint Solution Step2"] = "2. "..NARCI_MODIFIER_CONTROL.." + Clique Esquerdo em um item para abrir o provador.";
L["Switch Form To Visage"] = "Trocar para|cffffffff forma paisana|r";
L["Switch Form To Dracthyr"] = "Trocar para|cffffffff forma Dracthyr|r";
L["Switch Form To Worgen"] = "Trocar para|cffffffff forma Worgen|r";
L["Switch Form To Human"] = "Trocar para|cffffffff forma Humana|r";
L["InGame Command"] = "Comando no jogo";

--Navegador de PNJ
NARCI_NPC_BROWSER_TITLE_LEVEL = ".Nível %?%?.?";      --Nível ?? --Use isso para verificar se a segunda linha da caixa de texto é o título ou o tipo de unidade do PNJ
L["NPC Browser"] = "Navegador de PNJ";
L["NPC Browser Tooltip"] = "Escolha um PNJ da lista.";
L["Search for NPC"] = "Procure por PNJs";
L["Name or ID"] = "ID ou Nome";
L["NPC Has Weapons"] = "Tem armas exclusivas";
L["Retrieving NPC Info"] = "Recuperando informações do PNJ";
L["Loading Database"] = "Carregando banco de dados...\nSua tela pode congelar por alguns segundos.";
L["Other Last Name Format"] = "Outro "..NARCI_COLOR_GREY_70.."%s(s)|r:\n";
L["Too Many Matches Format"] = "\nMais de %s combinações.";

--Resolvendo problemas de letras minúsculas ou abreviações
NARCI_STAT_STRENGTH = SPEC_FRAME_PRIMARY_STAT_STRENGTH;
NARCI_STAT_AGILITY = SPEC_FRAME_PRIMARY_STAT_AGILITY;
NARCI_STAT_INTELLECT = SPEC_FRAME_PRIMARY_STAT_INTELLECT;
NARCI_CRITICAL_STRIKE = STAT_CRITICAL_STRIKE;


--Comparação de Equipamentos
L["Azerite Powers"] = "Poderes de Azerita";
L["Gem Tooltip Format1"] = "%s e %s";
L["Gem Tooltip Format2"] = "%s, %s e %s mais...";

--Gerenciador de conjunto de equipamentos
L["Equipped Item Level Format"] = "Equipado %s";
L["Equipped Item Level Tooltip"] = "A média de Nível de Item dos seus itens atualmente equipados.";
L["Equipment Manager"] = EQUIPMENT_MANAGER;
L["Toggle Equipment Set Manager"] = NARCI_MOUSE_BUTTON_ICON_1.."Gerenciador de equipamentos.";
L["Duplicated Set"] = "Conjunto duplicado";
L["Low Item Level"] = "Nível de item baixo";
L["1 Missing Item"] = "1 item ausente";
L["n Missing Items"] = "%s itens ausentes";
L["Update Items"] = "Atualizar itens";
L["Don't Update Items"] = "Não atualizar itens";
L["Update Talents"] = "Atualizar talentos";
L["Don't Update Talents"] = "Não atualizar talentos";
L["Old Icon"] = "Ícone antigo";
L["NavBar Saved Sets"] = "Salvo";   --Um conjunto de equipamentos salvo
L["NavBar Incomplete Sets"] = INCOMPLETE;
L["Icon Selector"] = "Seletor de Ícones";
L["Delete Equipment Set Tooltip"] = "Excluir conjunto\n|cff808080(clique e segure)|r";

--Sistema de corrupção
L["Corruption System"] = "Corrupção";
L["Eye Color"] = "Cor do Olho";
L["Blizzard UI"] = "IU da Blizzard";
L["Corruption Bar"] = "Barra de Corrupção";
L["Corruption Bar Description"] = "Ative a barra de corrupção ao lado do Painel do Personagem.";
L["Corruption Debuff Tooltip"] = "Dicas de penalidades";
L["Corruption Debuff Tooltip Description"] = "Substitua as dicas de penalidades padrão por sua contraparte numérica.";
L["No Corrupted Item"] = "Você não equipou nenhum item corrompido.";

L["Crit Gained"] = CRIT_ABBR.." ganho";
L["Haste Gained"] = STAT_HASTE.." ganha";
L["Mastery Gained"] = STAT_MASTERY.." ganha";
L["Versatility Gained"] = STAT_VERSATILITY.." ganha";

L["Proc Crit"] = "Proc "..CRIT_ABBR;
L["Proc Haste"] = "Proc "..STAT_HASTE;
L["Proc Mastery"] = "Proc "..STAT_MASTERY;
L["Proc Versatility"] =  "Proc "..STAT_VERSATILITY;

L["Critical Damage"] = CRIT_ABBR.."DANO";

L["Corruption Effect Format1"] = "|cffffffff%s%%|r velocidade reduzida";
L["Corruption Effect Format2"] = "|cffffffff%s|r dano inicial\n|cffffffff%s m|r raio";
L["Corruption Effect Format3"] = "|cffffffff%s|r dano\n|cffffffff%s%%|r do seu PdV";
L["Corruption Effect Format4"] = "Atingido pela Coisa do Além desencadeia outras penalidades";
L["Corruption Effect Format5"] = "|cffffffff%s%%|r dano\\cura recebida modificada";

--Quadro de sobreposição de texto
L["Text Overlay"] = "Sobreposição de texto";
L["Text Overlay Button Tooltip1"] = "Balão de fala simples";
L["Text Overlay Button Tooltip2"] = "Balão de fala avançado";
L["Text Overlay Button Tooltip3"] = "Cabeça Falante";
L["Text Overlay Button Tooltip4"] = "Legenda flutuante";
L["Text Overlay Button Tooltip5"] = "Legenda da barra preta";
L["Visibility"] = "Visibilidade";
L["Photo Mode Frame"] = "Quadro";    --Quadro para foto

--Quadro de conquistas
L["Use Achievement Panel"] = "Usar como painel de conquista principal";
L["Use Achievement Panel Description"] = "Clique em uma conquista obtida ou em conquistas rastreadas para abrir este painel.";
L["Incomplete First"] = "Incompletas primeiro";
L["Earned First"] = "Obtidas primeiro";
L["Settings"] = "Configurações";
L["Next Prev Card"] = "Próximo/Anterior";
L["Track"] = "Listar";   --Acompanhar conquistas
L["Show Unearned Mark"] = "Mostrar incompletas";
L["Show Unearned Mark Description"] = "Marque as conquistas que este personagem pode obter com um X vermelho.";
L["Show Dates"] = "Mostrar datas";
L["Hide Dates"] = "Ocultar datas";
L["Pinned Entries"] = "Entradas Fixas";
L["Pinned Entry Format"] = "Fixar  %d/%d";
L["Create A New Entry"] = "Criar uma nova conquista";
L["Custom Achievement"] = "Conquista personalizada";
L["Custom Achievement Description"] = "Esta é a descrição.";
L["Custom Achievement Select And Edit"] = "Selecione para editar.";
L["Cancel"] = "Cancelar";
L["Color"] = "Cor";
L["Icon"] = "Ícone";
L["Description"] = "Descrição";
L["Points"] = "Pontos";
L["Reward"] = "Recompensa";
L["Date"] = "Data";
L["Click And Hold"] = "Clique e Segure";


--Barbearia
L["Save New Look"] = "Salvar nova aparência";
L["No Available Slot"] = "Nenhum espaço disponível";
L["Look Saved"] = "Aparência salva";
L["Cannot Save Forms"] = "Não é possível salvar a aparência";
L["Share"] = "Compartilhar";
L["Save Notify"] = "Notificá-lo ao salvar a nova aparência";
L["Save Notify Tooltip"] = "Você será notificado para salvar a personalização depois de clicar no botão Aceitar.";
L["Show Randomize Button"] = "Mostrar botão de aparência aleatória";
L["Coins Spent"] = "Dinheiro gasto";
L["Locations"] = "Localizações";
L["Location"] = "Localização";
L["Visits"] = "Visitas";     --Número de visitas
L["Duration"] = "Duração";
L["Edit Name"] = "Editar nome";
L["Delete Look"] = "Excluir aparência\n(Clique e segure)";
L["Export"] = "Exportar";
L["Import"] = "Importar";
L["Paste Here"] = "Cole aqui";
L["Press To Copy"] = "Aperte |cffcccccc".. NARCI_SHORTCUTS_COPY.."|r para copiar";
L["String Copied"] = NARCI_COLOR_GREEN_MILD.. "Copiado";
L["Failure Reason Unknown"] = "Erro desconhecido";
L["Failure Reason Decode"] = "Falha ao decodificar.";
L["Failure Reason Wrong Character"] = "Raça/gênero/forma atuais não correspondem ao perfil importado.";
L["Failure Reason Dragonriding"] = "Este perfil é para Cavalgar Dragões.";
L["Wrong Character Format"] = "Requer %s %s."; --Por exemplo: Requer Humano Masculino
L["Import Lack Option"] = "%d |4opção:opções; não foram encontrados.";
L["Import Lack Choice"] = "%d |4escolha:escolhas; não foram encontrados.";
L["Decode Good"] = "Decodificado com sucesso.";
L["Barbershop Export Tooltip"] = "Codifica a personalização atualmente usada em uma string que pode ser compartilhada online.\n\nVocê pode alterar qualquer texto antes dos dois pontos (:)";
L["Settings And Share"] = (SETTINGS or "Configurações") .." & ".. (SOCIAL_SHARE_TEXT or "Compartilhar");
L["Loading Portraits"] = "Carregando retratos";

--Tutorial
L["Alert"] = "Aviso";
L["Race Change"] = "Troca de Raça/Gênero";
L["Race Change Line1"] = "Você pode novamente mudar sua raça e gênero. Mas existem algumas limitações:\n1. Suas armas vão desaparecer.\n2. Os visuais de feitiços não podem mais ser removidos.\n3. Não funciona em outros jogadores ou PNJs.";
L["Guide Spell Headline"] = "Experimente ou aplique";
L["Guide Spell Criteria1"] = "Clique Esquerdo para EXPERIMENTAR";
L["Guide Spell Criteria2"] = "Clique Direito para APLICAR";
L["Guide Spell Line1"] = "A maioria dos visuais de feitiços que você adiciona clicando no botão esquerdo desaparecerá em segundos, enquanto aqueles que você adiciona clicando no botão direito não.\n\nAgora, por favor, mova o cursor para uma entrada abaixo:";
L["Guide Spell Choose Category"] = "Você pode adicionar visuais de feitiços ao seu modelo. Escolha uma categoria que você goste. Em seguida, escolha uma subcategoria.";
L["Guide History Headline"] = "Painel Histórico";
L["Guide History Line1"] = "No máximo 5 visuais aplicados recentemente podem ser mantidos aqui. Você pode selecionar um e excluí-lo clicando no botão Remover na extremidade direita.";
L["Guide Refresh Line1"] = "Use este botão para remover todos os visuais de feitiços não aplicados. Aqueles que estavam no painel de histórico serão reaplicados.";
L["Guide Input Headline"] = "Entrada manual";
L["Guide Input Line1"] = "Você também pode inserir um SpellVisualKitID. A partir de 9.0, seu limite é de cerca de 155.000.\nVocê pode usar a roda do mouse para tentar o ID seguinte/anterior.\nMuito poucos IDs podem travar o jogo.";
L["Guide Equipment Manager Line1"] = "Clique duas vezes: use um conjunto\nClique com o botão direito do mouse: edite um conjunto.\n\nA função anterior deste botão foi movida para Preferências.";
L["Guide Model Control Headline"] = "Controle de Modelo";
L["Guide Model Control Line1"] = format("Este modelo compartilha as mesmas ações do mouse que você usa no provador, além de:\n\n1.Segurar %s e Clique Esquerdo: Girar o modelo em torno do eixo Y.\n2.Segurar %s e Botão Direito: Executar zoom deslizante.", NARCI_MODIFIER_ALT, NARCI_MODIFIER_ALT);
L["Guide Minimap Button Headline"] = "Botão no Minimapa";
L["Guide Minimap Button Line1"] = "O botão do minimapa do Narcissus agora pode ser manipulado por outros AddOns.\nVocê pode alterar esta opção no Painel de Preferências. Pode exigir um recarregamento da interface do usuário."
L["Guide NPC Entrance Line1"] = "Você pode adicionar qualquer PNJ em sua cena."
L["Guide NPC Browser Line1"] = "PNJs notáveis estão listados no catálogo abaixo.\nVocê também pode pesquisar QUALQUER criatura por nome ou ID.\nObserve que na primeira vez que você usar a função de pesquisa nesta sessão, pode levar alguns segundos para construir a tabela de pesquisa e sua tela pode congelar também.\nVocê pode desmarcar a opção \"Carregar Sob Demanda\" no Painel de Preferências para que o banco de dados seja construído logo após o login.";

--Splash
L["Splash Whats New Format"] = "O que há de novo em Narcissus %s";
L["See Ads"] = "Veja os anúncios do nosso autêntico patrocinador";    --Não são anúncios reais!
L["Splash Category1"] = L["Photo Mode"];
L["Splash Content1 Name"] = "Navegador de armas";
L["Splash Content1 Description"] = "-Veja e use todas as armas no banco de dados, incluindo aquelas que não podem ser obtidas pelos jogadores.";
L["Splash Content2 Name"] = "Tela de seleção de personagem";
L["Splash Content2 Description"] = "-Adicione uma moldura decorativa para criar sua própria tela de seleção de personagem (falsa).";
L["Splash Content3 Name"] = "Provador";
L["Splash Content3 Description"] = "-O módulo do Provador foi redesenhado.\n-A lista de itens agora inclui ombros não pareados e ilusões de armas.";
L["Splash Content4 Name"] = "Estábulo para ajudantes";
L["Splash Content4 Description"] = "-Os caçadores podem selecionar e adicionar ajudantes usando uma nova IU de Estábulo no modo de foto de grupo.";
L["Splash Category2"] = "Quadro do Personagem";
L["Splash Content5 Name"] = "Fragmento de Dominação";
L["Splash Content5 Description"] = "-O indicador Fragmento de Dominação aparecerá se você equipar itens relevantes.\n-Uma lista de fragmentos disponíveis será apresentada a você quando você engastar itens de dominação.\n-Extraia fragmentos com um único clique.";
L["Splash Content6 Name"] = "Vínculo de Almas";
L["Splash Content6 Description"] = "-A interface de Vínculo de Almas foi atualizada. Você pode verificar os efeitos de conduíte de classificações mais altas.";
L["Splash Content7 Name"] = "Visuais";
L["Splash Content7 Description"] = "-A borda do item hexagonal ganha um novo visual. Certos itens têm aparências únicas.";

--Detalhes do Projeto
L["AboutTab Developer Note"] = "Obrigado por experimentar este AddOn! Se você tiver algum problema, sugestão, ideia, por favor, deixe um comentário na página do CurseForge ou entre em contato comigo em...";

--Conversação
L["Q1"] = "O que é isto?";
L["Q2"] = "Eu sei. Mas por que isso é tão grande?";
L["Q3"] = "Isso não é engraçado. Só preciso de um normal.";
L["Q4"] = "Bom. E se eu quiser desativá-lo?";
L["Q5"] = "Mais uma coisa, você poderia me prometer que não haverá mais pegadinhas?";
L["A1"] = "Aparentemente, esta é uma caixa de diálogo de confirmação de saída. Ela aparece quando você tenta sair do modo de foto de grupo pressionando a tecla de atalho.";
L["A2"] = "Há, foi o que ela disse.";
L["A3"] = "Bem... bem..."
L["A4"] = "Desculpe, você não pode. É por segurança, você sabe.";

--Pesquisa
L["Search Result Singular"] = "%s resultado";
L["Search Result Plural"] = "%s resultados";
L["Search Result Overflow"] = "%s+ resultados";
L["Search Result None"] = CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS;

--Navegador de armas
L["Draw Weapon"] = "Equipar Arma";
L["Unequip Item"] = "Desequipar";
L["WeaponBrowser Guide Hotkey"] = "Especifique qual mão segura a arma:";
L["WeaponBrowser Guide ModelType"] = "Alguns itens são limitados a determinados modelos:";
L["WeaponBrowser Guide DressUpModel"] = "Este será o modelo padrão se o seu alvo for um jogador, a menos que você esteja segurando %s ao criá-lo.";
L["WeaponBrowser Guide CinematicModel"] = "O modelo sempre será de cinemática se a criatura for um PNJ. Você não pode embainhar armas.";
L["Weapon Browser Specify Hand"] = "|cffffd100"..NARCI_MODIFIER_CONTROL.." + Clique Esquerdo|r para equipar o item na mão principal.\n|cffffd100"..NARCI_MODIFIER_ALT.." + Clique Esquerdo|r para mão secundária.";

--Estábulos de Ajudantes
L["PetStable Tooltip"] = "Escolha um ajudante do seu estábulo";
L["PetStable Loading"] = "Recuperando informações do ajudante";

--Item de Dominação
L["Item Bonus"] = "Bônus:";
L["Combat Error"] = NARCI_COLOR_RED_MILD.."Saia de combate para continuar".."|r";
L["Extract Shard"] = "Extrair fragmento";
L["No Service"] = "Sem serviço";
L["Shards Disabled"] = "Fragmentos de Dominação são desabilitados fora da Gorja.";
L["Unsocket Gem"] = "Desengastar Gema";

--Tabela de classificação Mítica+
L["Mythic Plus"] = "Mítica+";
L["Mythic Plus Abbrev"] = "M+";
L["Total Runs"] = "Séries totais: ";
L["Complete In Time"] = "Dentro do Tempo";
L["Complete Over Time"] = "Fora do Tempo";
L["Runs"] = "Séries";

--Atualização de equipamento
L["Temp Enchant"] = "Encantamentos Temporários";                --ERR_TRADE_TEMP_ENCHANT_BOUND
L["Owned"] = "Obtido";                                          --Mostrar apenas itens obtidos
L["At Level"] = "No nível %d:";                                 --Encantamento escala com o nível do jogador
L["No Item Alert"] = "Nenhum item compatível";
L["Click To Insert"] = "Clique para inserir";                   --Insira uma gema
L["No Socket"] = "Sem engaste";
L["No Other Item For Slot"] = "Nenhum outro item para %s";      --onde %s é o nome do espaço
L["In Bags"] = "Nas bolsas";
L["Item Socketing Tooltip"] = "Clique e segure para incorporar";
L["No Available Gem"] = "|cffd8d8d8Nenhuma gema disponível|r";
L["Missing Enchant Alert"] = "Sinalizar itens não encantados";
L["Missing Enchant"] = NARCI_COLOR_RED_MILD.."Sem encantamento".."|r";
L["Socket Occupied"] = "Engaste ocupado";                       --Indica que há uma gema (importante) no engaste e você precisa removê-la primeiro

--Estatisticas
S["Narcissus Played"] = "Tempo total gasto com Narcissus";
S["Format Since"] = "(desde %s)";
S["Screenshots"] = "Capturas de tela feitas com Narcissus";
S["Shadowlands Quests"] = "Missões das Terras Sombrias";
S["Quest Text Reading Speed Format"] = "Concluído: %s (%s palavras)  Leitura: %s (%s ppm)";

--Mostruário do Quadro Rotativo
L["Turntable"] = "Quadro Rotativo";
L["Picture"] = "Foto";
L["Elapse"] = "Decorrido";
L["Turntable Tab Animation"] = "Animação";
L["Turntable Tab Image"] = "Imagem";
L["Turntable Tab Quality"] = "Qualidade";
L["Turntable Tab Background"] = "Plano de fundo";
L["Spin"] = "Rotacionar";
L["Sync"] = "Sincronizar";
L["Rotation Period"] = "Duração";
L["Period Tooltip"] = "O tempo necessário para completar uma rotação.\nDeve ser também a |cffccccccduração do clipe|r do seu GIF ou vídeo.";
L["MSAA Tooltip"] = "Altera temporariamente o Anti-Aliasing para suavizar o serrilhado das bordas. |cffccccccUtilizar esta opção poderá reduzir o desempenho|r.";
L["Image Size"] = "Tamanho da imagem";
L["Font Size"] = FONT_SIZE;
L["Item Name Show"] = "Mostrar nomes dos itens";
L["Item Name Hide"] = "Ocultar nomes dos itens";
L["Outline Show"] = "Mostrar borda";
L["Outline Hide"] = "Ocultar borda";
L["Preset"] = "Predefinição";
L["File"] = "Arquivo";     --Nome do Arquivo
L["File Tooltip"] = "Adicione sua própria imagem em |cffccccccWorld of Warcraft\\retail\\Interface\\AddOns|r e insira o nome do arquivo neste campo.\nA imagem deve ser um arquivo |cffccccccJPG|r |cffcccccc512x512|r ou |cffcccccc1024x1024|r";
L["Raise Level"] = "Colocar para frente";
L["Lower Level"] = "Colocar para trás";
L["Show Mount"] = "Mostrar montaria";
L["Hide Mount"] = "Ocultar montaria";
L["Loop Animation On"] = "Loop";
L["Click To Continue"] = "clique para continuar";
L["Showcase Splash 1"] = "Crie animações no Quadro Rotativo para mostrar seu transmog com gravador de tela e Narcissus.";
L["Showcase Splash 2"] = "Clique no botão abaixo para copiar itens do provador.";
L["Showcase Splash 3"] = "Clique no botão abaixo para rotacionar seu personagem.";
L["Showcase Splash 4"] = "Grave a tela com um software de gravação de vídeo e converta-o para GIF.";
L["Loop Animation Alert Kultiran"] = "Loop - atualmente não funciona no kultireno corpo 1";
L["Loop Animation"] = "Animação em Loop";

--Conjuntos de itens
L["Cycle Spec"] = "Pressione TAB para navegar pelas especificações";
L["Paperdoll Splash 1"] = "Ativar indicador de conjunto de classes?";
L["Paperdoll Splash 2"] = "Escolha um tema";

--Seleção de roupa
L["Outfit"] = "Roupa";
L["Models"] = "Modelos";
L["Origin Outfits"] = "Roupas originais";
L["Outfit Owner Format"] = "Roupas de %s";
L["SortMethod Recent"] = "Recente";
L["SortMethod Name"] = "Nome";

--Formato de combinação das dicas
L["Find Cooldown"] = " recarga";
L["Find Recharge"] = " recarga";


--Árvore de talentos
L["Mini Talent Tree"] = "Mini árvore de talentos";
L["Show Talent Tree When"] = "Mostrar a árvore de talentos quando você...";
L["Show Talent Tree Paperdoll"] = "Abrir o Painel do Personagem";
L["Show Talent Tree Inspection"] = "Inspecionar outros jogadores";
L["Show Talent Tree Equipment Manager"] = "Abrir o Gerenciador de Equipamento"; 
L["Appearance"] = "Aparência";
L["Use Class Background"] = "Usar imagem de fundo da classe";
L["Use Bigger UI"] = "IU maior";
L["Empty Loadout Name"] = "Nome";
L["No Save Slot Red"] = NARCI_COLOR_RED_MILD.. "Sem espaço para salvar" .."|r";
L["Save"] = "Salvar";
L["Create Macro Wrong Spec"] = "Este conjunto foi atribuído a outra especialização!";
L["Create Marco No Slot"] = "Não é possível criar mais macros específicas por personagens.";
L["Create Macro Instruction 1"] = "Solte o conjunto na caixa abaixo para combiná-lo com \n|cffebebeb%s|r";
L["Create Macro Instruction Edit"] = "Solte o conjunto na caixa abaixo para editar a macro \n|cffebebeb%s|r";
L["Create Macro Instruction 2"] = "Selecione um |cff53a9ffícone secundário|r para esta macro.";
L["Create Macro Instruction 3"] = "Nomeie esta macro\n ";
L["Create Macro Instruction 4"] = "Arraste esta macro para sua barra de ação.";
L["Create Macro In Combat"] = "Não é possível criar macro durante o combate.";
L["Create Macro Next"] = "PRÓXIMO";
L["Create Marco Created"] = "CRIADO";
L["Place UI"] = "Coloque a IU...";
L["Place Talent UI Right"] = "Ao lado direito do Painel do Personagem";
L["Place Talent UI Bottom"] = "Abaixo do Painel do Personagem";
L["Loadout"] = "Equipamento";
L["No Loadout"] = "Sem equipamento";
L["PvP"] = "JxJ";


--Filtro de itens na mochila
L["Bag Item Filter"] = "Filtro de itens na mochila";
L["Bag Item Filter Enable"] = "Ativar sugestão de pesquisa e filtro automático";
L["Place Window"] = "Posicionar a janela...";
L["Below Search Box"] = "Abaixo da caixa de pesquisa";
L["Above Search Box"] = "Acima da caixa de pesquisa";
L["Auto Filter Case"] = "Filtrar itens automaticamente quando você...";
L["Send Mails"] = "Enviar cartas";
L["Create Auctions"] = "Criar leilões";
L["Socket Items"] = "Engastar itens";

--Posto Comercial
L["Perks Program Unclaimed Tender Format"] = "- Você tem |cffffffff%s|r créditos não coletados no Baú do Coletor";      --PERKS_PROGRAM_UNCOLLECTED_TENDER
L["Perks Program Unearned Tender Format"] = "- Você possui |cffffffff%s|r créditos a conquistar no Diário do Viajante";     --PERKS_PROGRAM_ACTIVITIES_UNEARNED
L["Perks Program Item Added In Format"] = "Adicionado em %s";
L["Perks Program Item Unavailable"] = "Este item não está disponível no momento.";
L["Perks Program See Wares"] = "Ver ofertas do mês";
L["Perks Program No Cache Alert"] = "Fale com os vendedores do Posto Comercial para ver as ofertas do mês.";
L["Perks Program Using Cache Alert"] = "Utilizando as ofertas salvas em sua última visita. Os dados de preço e itens comprados podem não ser precisos.";

--Missões
L["Auto Display Quest Item"] = "Exibir automaticamente a descrição dos itens de missões";
L["Drag To Move"] = "Arraste para mover";
L["Middle Click Reset Position"] = "Use o botão do meio do mouse para reiniciar a posição."
L["Change Position"] = "Mudar posição";