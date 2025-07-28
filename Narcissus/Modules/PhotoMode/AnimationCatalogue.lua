NarciAnimationInfo = {};

local find = string.find;
local gsub = string.gsub;
local sub = string.sub;
local lower = string.lower;
local trim = strtrim;

local function split(str)
	return strsplit(" ", str)
end

local officialAnimationName = {
	"Death", -- [1]
	"Spell", -- [2]
	"Stop", -- [3]
	"Walk", -- [4]
	"Run", -- [5]
	"Dead", -- [6]
	"Rise", -- [7]
	"StandWound", -- [8]
	"CombatWound", -- [9]
	"CombatCritical", -- [10]
	"ShuffleLeft", -- [11]
	"ShuffleRight", -- [12]
	"WalkBackwards", -- [13]
	"Stun", -- [14]
	"HandsClosed", -- [15]
	"AttackUnarmed", -- [16]
	"Attack1H", -- [17]
	"Attack2H", -- [18]
	"Attack2HL", -- [19]
	"ParryUnarmed", -- [20]
	"Parry1H", -- [21]
	"Parry2H", -- [22]
	"Parry2HL", -- [23]
	"ShieldBlock", -- [24]
	"ReadyUnarmed", -- [25]
	"Ready1H", -- [26]
	"Ready2H", -- [27]
	"Ready2HL", -- [28]
	"ReadyBow", -- [29]
	"Dodge", -- [30]
	"SpellPrecast", -- [31]
	"SpellCast", -- [32]
	"SpellCastArea", -- [33]
	"NPCWelcome", -- [34]
	"NPCGoodbye", -- [35]
	"Block", -- [36]
	"JumpStart", -- [37]
	"Jump", -- [38]
	"JumpEnd", -- [39]
	"Fall", -- [40]
	"SwimIdle", -- [41]
	"Swim", -- [42]
	"SwimLeft", -- [43]
	"SwimRight", -- [44]
	"SwimBackwards", -- [45]
	"AttackBow", -- [46]
	"FireBow", -- [47]
	"ReadyRifle", -- [48]
	"AttackRifle", -- [49]
	"Loot", -- [50]
	"ReadySpellDirected", -- [51]
	"ReadySpellOmni", -- [52]
	"SpellCastDirected", -- [53]
	"SpellCastOmni", -- [54]
	"BattleRoar", -- [55]
	"ReadyAbility", -- [56]
	"Special1H", -- [57]
	"Special2H", -- [58]
	"ShieldBash", -- [59]
	"EmoteTalk", -- [60]
	"EmoteEat", -- [61]
	"EmoteWork", -- [62]
	"EmoteUseStanding", -- [63]
	"EmoteTalkExclamation", -- [64]
	"EmoteTalkQuestion", -- [65]
	"EmoteBow", -- [66]
	"EmoteWave", -- [67]
	"EmoteCheer", -- [68]
	"EmoteDance", -- [69]
	"EmoteLaugh", -- [70]
	"EmoteSleep", -- [71]
	"EmoteSitGround", -- [72]
	"EmoteRude", -- [73]
	"EmoteRoar", -- [74]
	"EmoteKneel", -- [75]
	"EmoteKiss", -- [76]
	"EmoteCry", -- [77]
	"EmoteChicken", -- [78]
	"EmoteBeg", -- [79]
	"EmoteApplaud", -- [80]
	"EmoteShout", -- [81]
	"EmoteFlex", -- [82]
	"EmoteShy", -- [83]
	"EmotePoint", -- [84]
	"Attack1HPierce", -- [85]
	"Attack2HLoosePierce", -- [86]
	"AttackOff", -- [87]
	"AttackOffPierce", -- [88]
	"Sheath", -- [89]
	"HipSheath", -- [90]
	"Mount", -- [91]
	"RunRight", -- [92]
	"RunLeft", -- [93]
	"MountSpecial", -- [94]
	"Kick", -- [95]
	"SitGroundDown", -- [96]
	"SitGround", -- [97]
	"SitGroundUp", -- [98]
	"SleepDown", -- [99]
	"Sleep", -- [100]
	"SleepUp", -- [101]
	"SitChairLow", -- [102]
	"SitChairMed", -- [103]
	"SitChairHigh", -- [104]
	"LoadBow", -- [105]
	"LoadRifle", -- [106]
	"AttackThrown", -- [107]
	"ReadyThrown", -- [108]
	"HoldBow", -- [109]
	"HoldRifle", -- [110]
	"HoldThrown", -- [111]
	"LoadThrown", -- [112]
	"EmoteSalute", -- [113]
	"KneelStart", -- [114]
	"KneelLoop", -- [115]
	"KneelEnd", -- [116]
	"AttackUnarmedOff", -- [117]
	"SpecialUnarmed", -- [118]
	"StealthWalk", -- [119]
	"StealthStand", -- [120]
	"Knockdown", -- [121]
	"EatingLoop", -- [122]
	"UseStandingLoop", -- [123]
	"ChannelCastDirected", -- [124]
	"ChannelCastOmni", -- [125]
	"Whirlwind", -- [126]
	"Birth", -- [127]
	"UseStandingStart", -- [128]
	"UseStandingEnd", -- [129]
	"CreatureSpecial", -- [130]
	"Drown", -- [131]
	"Drowned", -- [132]
	"FishingCast", -- [133]
	"FishingLoop", -- [134]
	"Fly", -- [135]
	"EmoteWorkNoSheathe", -- [136]
	"EmoteStunNoSheathe", -- [137]
	"EmoteUseStandingNoSheathe", -- [138]
	"SpellSleepDown", -- [139]
	"SpellKneelStart", -- [140]
	"SpellKneelLoop", -- [141]
	"SpellKneelEnd", -- [142]
	"Sprint", -- [143]
	"InFlight", -- [144]
	"Spawn", -- [145]
	"Close", -- [146]
	"Closed", -- [147]
	"Open", -- [148]
	"Opened", -- [149]
	"Destroy", -- [150]
	"Destroyed", -- [151]
	"Rebuild", -- [152]
	"Custom0", -- [153]
	"Custom1", -- [154]
	"Custom2", -- [155]
	"Custom3", -- [156]
	"Despawn", -- [157]
	"Hold", -- [158]
	"Decay", -- [159]
	"BowPull", -- [160]
	"BowRelease", -- [161]
	"ShipStart", -- [162]
	"ShipMoving", -- [163]
	"ShipStop", -- [164]
	"GroupArrow", -- [165]
	"Arrow", -- [166]
	"CorpseArrow", -- [167]
	"GuideArrow", -- [168]
	"Sway", -- [169]
	"DruidCatPounce", -- [170]
	"DruidCatRip", -- [171]
	"DruidCatRake", -- [172]
	"DruidCatRavage", -- [173]
	"DruidCatClaw", -- [174]
	"DruidCatCower", -- [175]
	"DruidBearSwipe", -- [176]
	"DruidBearBite", -- [177]
	"DruidBearMaul", -- [178]
	"DruidBearBash", -- [179]
	"DragonTail", -- [180]
	"DragonStomp", -- [181]
	"DragonSpit", -- [182]
	"DragonSpitHover", -- [183]
	"DragonSpitFly", -- [184]
	"EmoteYes", -- [185]
	"EmoteNo", -- [186]
	"JumpLandRun", -- [187]
	"LootHold", -- [188]
	"LootUp", -- [189]
	"StandHigh", -- [190]
	"Impact", -- [191]
	"LiftOff", -- [192]
	"Hover", -- [193]
	"SuccubusEntice", -- [194]
	"EmoteTrain", -- [195]
	"EmoteDead", -- [196]
	"EmoteDanceOnce", -- [197]
	"Deflect", -- [198]
	"EmoteEatNoSheathe", -- [199]
	"Land", -- [200]
	"Submerge", -- [201]
	"Submerged", -- [202]
	"Cannibalize", -- [203]
	"ArrowBirth", -- [204]
	"GroupArrowBirth", -- [205]
	"CorpseArrowBirth", -- [206]
	"GuideArrowBirth", -- [207]
	"EmoteTalkNoSheathe", -- [208]
	"EmotePointNoSheathe", -- [209]
	"EmoteSaluteNoSheathe", -- [210]
	"EmoteDanceSpecial", -- [211]
	"Mutilate", -- [212]
	"CustomSpell01", -- [213]
	"CustomSpell02", -- [214]
	"CustomSpell03", -- [215]
	"CustomSpell04", -- [216]
	"CustomSpell05", -- [217]
	"CustomSpell06", -- [218]
	"CustomSpell07", -- [219]
	"CustomSpell08", -- [220]
	"CustomSpell09", -- [221]
	"CustomSpell10", -- [222]
	"StealthRun", -- [223]
	"Emerge", -- [224]
	"Cower", -- [225]
	"Grab", -- [226]
	"GrabClosed", -- [227]
	"GrabThrown", -- [228]
	"FlyStand", -- [229]
	"FlyDeath", -- [230]
	"FlySpell", -- [231]
	"FlyStop", -- [232]
	"FlyWalk", -- [233]
	"FlyRun", -- [234]
	"FlyDead", -- [235]
	"FlyRise", -- [236]
	"FlyStandWound", -- [237]
	"FlyCombatWound", -- [238]
	"FlyCombatCritical", -- [239]
	"FlyShuffleLeft", -- [240]
	"FlyShuffleRight", -- [241]
	"FlyWalkbackwards", -- [242]
	"FlyStun", -- [243]
	"FlyHandsClosed", -- [244]
	"FlyAttackUnarmed", -- [245]
	"FlyAttack1H", -- [246]
	"FlyAttack2H", -- [247]
	"FlyAttack2HL", -- [248]
	"FlyParryUnarmed", -- [249]
	"FlyParry1H", -- [250]
	"FlyParry2H", -- [251]
	"FlyParry2HL", -- [252]
	"FlyShieldBlock", -- [253]
	"FlyReadyUnarmed", -- [254]
	"FlyReady1H", -- [255]
	"FlyReady2H", -- [256]
	"FlyReady2HL", -- [257]
	"FlyReadyBow", -- [258]
	"FlyDodge", -- [259]
	"FlySpellPrecast", -- [260]
	"FlySpellCast", -- [261]
	"FlySpellCastArea", -- [262]
	"FlyNPCWelcome", -- [263]
	"FlyNPCGoodbye", -- [264]
	"FlyBlock", -- [265]
	"FlyJumpStart", -- [266]
	"FlyJump", -- [267]
	"FlyJumpEnd", -- [268]
	"FlyFall", -- [269]
	"FlySwimIdle", -- [270]
	"FlySwim", -- [271]
	"FlySwimLeft", -- [272]
	"FlySwimRight", -- [273]
	"FlySwimBackwards", -- [274]
	"FlyAttackBow", -- [275]
	"FlyFireBow", -- [276]
	"FlyReadyRifle", -- [277]
	"FlyAttackRifle", -- [278]
	"FlyLoot", -- [279]
	"FlyReadySpellDirected", -- [280]
	"FlyReadySpellOmni", -- [281]
	"FlySpellCastDirected", -- [282]
	"FlySpellCastOmni", -- [283]
	"FlyBattleRoar", -- [284]
	"FlyReadyAbility", -- [285]
	"FlySpecial1H", -- [286]
	"FlySpecial2H", -- [287]
	"FlyShieldBash", -- [288]
	"FlyEmoteTalk", -- [289]
	"FlyEmoteEat", -- [290]
	"FlyEmoteWork", -- [291]
	"FlyEmoteUseStanding", -- [292]
	"FlyEmoteTalkExclamation", -- [293]
	"FlyEmoteTalkQuestion", -- [294]
	"FlyEmoteBow", -- [295]
	"FlyEmoteWave", -- [296]
	"FlyEmoteCheer", -- [297]
	"FlyEmoteDance", -- [298]
	"FlyEmoteLaugh", -- [299]
	"FlyEmoteSleep", -- [300]
	"FlyEmoteSitGround", -- [301]
	"FlyEmoteRude", -- [302]
	"FlyEmoteRoar", -- [303]
	"FlyEmoteKneel", -- [304]
	"FlyEmoteKiss", -- [305]
	"FlyEmoteCry", -- [306]
	"FlyEmoteChicken", -- [307]
	"FlyEmoteBeg", -- [308]
	"FlyEmoteApplaud", -- [309]
	"FlyEmoteShout", -- [310]
	"FlyEmoteFlex", -- [311]
	"FlyEmoteShy", -- [312]
	"FlyEmotePoint", -- [313]
	"FlyAttack1HPierce", -- [314]
	"FlyAttack2HLoosePierce", -- [315]
	"FlyAttackOff", -- [316]
	"FlyAttackOffPierce", -- [317]
	"FlySheath", -- [318]
	"FlyHipSheath", -- [319]
	"FlyMount", -- [320]
	"FlyRunRight", -- [321]
	"FlyRunLeft", -- [322]
	"FlyMountSpecial", -- [323]
	"FlyKick", -- [324]
	"FlySitGroundDown", -- [325]
	"FlySitGround", -- [326]
	"FlySitGroundUp", -- [327]
	"FlySleepDown", -- [328]
	"FlySleep", -- [329]
	"FlySleepUp", -- [330]
	"FlySitChairLow", -- [331]
	"FlySitChairMed", -- [332]
	"FlySitChairHigh", -- [333]
	"FlyLoadBow", -- [334]
	"FlyLoadRifle", -- [335]
	"FlyAttackThrown", -- [336]
	"FlyReadyThrown", -- [337]
	"FlyHoldBow", -- [338]
	"FlyHoldRifle", -- [339]
	"FlyHoldThrown", -- [340]
	"FlyLoadThrown", -- [341]
	"FlyEmoteSalute", -- [342]
	"FlyKneelStart", -- [343]
	"FlyKneelLoop", -- [344]
	"FlyKneelEnd", -- [345]
	"FlyAttackUnarmedOff", -- [346]
	"FlySpecialUnarmed", -- [347]
	"FlyStealthWalk", -- [348]
	"FlyStealthStand", -- [349]
	"FlyKnockdown", -- [350]
	"FlyEatingLoop", -- [351]
	"FlyUseStandingLoop", -- [352]
	"FlyChannelCastDirected", -- [353]
	"FlyChannelCastOmni", -- [354]
	"FlyWhirlwind", -- [355]
	"FlyBirth", -- [356]
	"FlyUseStandingStart", -- [357]
	"FlyUseStandingEnd", -- [358]
	"FlyCreatureSpecial", -- [359]
	"FlyDrown", -- [360]
	"FlyDrowned", -- [361]
	"FlyFishingCast", -- [362]
	"FlyFishingLoop", -- [363]
	"FlyFly", -- [364]
	"FlyEmoteWorkNoSheathe", -- [365]
	"FlyEmoteStunNoSheathe", -- [366]
	"FlyEmoteUseStandingNoSheathe", -- [367]
	"FlySpellSleepDown", -- [368]
	"FlySpellKneelStart", -- [369]
	"FlySpellKneelLoop", -- [370]
	"FlySpellKneelEnd", -- [371]
	"FlySprint", -- [372]
	"FlyInFlight", -- [373]
	"FlySpawn", -- [374]
	"FlyClose", -- [375]
	"FlyClosed", -- [376]
	"FlyOpen", -- [377]
	"FlyOpened", -- [378]
	"FlyDestroy", -- [379]
	"FlyDestroyed", -- [380]
	"FlyRebuild", -- [381]
	"FlyCustom0", -- [382]
	"FlyCustom1", -- [383]
	"FlyCustom2", -- [384]
	"FlyCustom3", -- [385]
	"FlyDespawn", -- [386]
	"FlyHold", -- [387]
	"FlyDecay", -- [388]
	"FlyBowPull", -- [389]
	"FlyBowRelease", -- [390]
	"FlyShipStart", -- [391]
	"FlyShipMoving", -- [392]
	"FlyShipStop", -- [393]
	"FlyGroupArrow", -- [394]
	"FlyArrow", -- [395]
	"FlyCorpseArrow", -- [396]
	"FlyGuideArrow", -- [397]
	"FlySway", -- [398]
	"FlyDruidCatPounce", -- [399]
	"FlyDruidCatRip", -- [400]
	"FlyDruidCatRake", -- [401]
	"FlyDruidCatRavage", -- [402]
	"FlyDruidCatClaw", -- [403]
	"FlyDruidCatCower", -- [404]
	"FlyDruidBearSwipe", -- [405]
	"FlyDruidBearBite", -- [406]
	"FlyDruidBearMaul", -- [407]
	"FlyDruidBearBash", -- [408]
	"FlyDragonTail", -- [409]
	"FlyDragonStomp", -- [410]
	"FlyDragonSpit", -- [411]
	"FlyDragonSpitHover", -- [412]
	"FlyDragonSpitFly", -- [413]
	"FlyEmoteYes", -- [414]
	"FlyEmoteNo", -- [415]
	"FlyJumpLandRun", -- [416]
	"FlyLootHold", -- [417]
	"FlyLootUp", -- [418]
	"FlyStandHigh", -- [419]
	"FlyImpact", -- [420]
	"FlyLiftOff", -- [421]
	"FlyHover", -- [422]
	"FlySuccubusEntice", -- [423]
	"FlyEmoteTrain", -- [424]
	"FlyEmoteDead", -- [425]
	"FlyEmoteDanceOnce", -- [426]
	"FlyDeflect", -- [427]
	"FlyEmoteEatNoSheathe", -- [428]
	"FlyLand", -- [429]
	"FlySubmerge", -- [430]
	"FlySubmerged", -- [431]
	"FlyCannibalize", -- [432]
	"FlyArrowBirth", -- [433]
	"FlyGroupArrowBirth", -- [434]
	"FlyCorpseArrowBirth", -- [435]
	"FlyGuideArrowBirth", -- [436]
	"FlyEmoteTalkNoSheathe", -- [437]
	"FlyEmotePointNoSheathe", -- [438]
	"FlyEmoteSaluteNoSheathe", -- [439]
	"FlyEmoteDanceSpecial", -- [440]
	"FlyMutilate", -- [441]
	"FlyCustomSpell01", -- [442]
	"FlyCustomSpell02", -- [443]
	"FlyCustomSpell03", -- [444]
	"FlyCustomSpell04", -- [445]
	"FlyCustomSpell05", -- [446]
	"FlyCustomSpell06", -- [447]
	"FlyCustomSpell07", -- [448]
	"FlyCustomSpell08", -- [449]
	"FlyCustomSpell09", -- [450]
	"FlyCustomSpell10", -- [451]
	"FlyStealthRun", -- [452]
	"FlyEmerge", -- [453]
	"FlyCower", -- [454]
	"FlyGrab", -- [455]
	"FlyGrabClosed", -- [456]
	"FlyGrabThrown", -- [457]
	"ToFly", -- [458]
	"ToHover", -- [459]
	"ToGround", -- [460]
	"FlyToFly", -- [461]
	"FlyToHover", -- [462]
	"FlyToGround", -- [463]
	"Settle", -- [464]
	"FlySettle", -- [465]
	"DeathStart", -- [466]
	"DeathLoop", -- [467]
	"DeathEnd", -- [468]
	"FlyDeathStart", -- [469]
	"FlyDeathLoop", -- [470]
	"FlyDeathEnd", -- [471]
	"DeathEndHold", -- [472]
	"FlyDeathEndHold", -- [473]
	"Strangulate", -- [474]
	"FlyStrangulate", -- [475]
	"ReadyJoust", -- [476]
	"LoadJoust", -- [477]
	"HoldJoust", -- [478]
	"FlyReadyJoust", -- [479]
	"FlyLoadJoust", -- [480]
	"FlyHoldJoust", -- [481]
	"AttackJoust", -- [482]
	"FlyAttackJoust", -- [483]
	"ReclinedMount", -- [484]
	"FlyReclinedMount", -- [485]
	"ToAltered", -- [486]
	"FromAltered", -- [487]
	"FlyToAltered", -- [488]
	"FlyFromAltered", -- [489]
	"InStocks", -- [490]
	"FlyInStocks", -- [491]
	"VehicleGrab", -- [492]
	"VehicleThrow", -- [493]
	"FlyVehicleGrab", -- [494]
	"FlyVehicleThrow", -- [495]
	"ToAlteredPostSwap", -- [496]
	"FromAlteredPostSwap", -- [497]
	"FlyToAlteredPostSwap", -- [498]
	"FlyFromAlteredPostSwap", -- [499]
	"ReclinedMountPassenger", -- [500]
	"FlyReclinedMountPassenger", -- [501]
	"Carry2H", -- [502]
	"Carried2H", -- [503]
	"FlyCarry2H", -- [504]
	"FlyCarried2H", -- [505]
	"EmoteSniff", -- [506]
	"EmoteFlySniff", -- [507]
	"AttackFist1H", -- [508]
	"FlyAttackFist1H", -- [509]
	"AttackFist1HOff", -- [510]
	"FlyAttackFist1HOff", -- [511]
	"ParryFist1H", -- [512]
	"FlyParryFist1H", -- [513]
	"ReadyFist1H", -- [514]
	"FlyReadyFist1H", -- [515]
	"SpecialFist1H", -- [516]
	"FlySpecialFist1H", -- [517]
	"EmoteReadStart", -- [518]
	"FlyEmoteReadStart", -- [519]
	"EmoteReadLoop", -- [520]
	"FlyEmoteReadLoop", -- [521]
	"EmoteReadEnd", -- [522]
	"FlyEmoteReadEnd", -- [523]
	"SwimRun", -- [524]
	"FlySwimRun", -- [525]
	"SwimWalk", -- [526]
	"FlySwimWalk", -- [527]
	"SwimWalkBackwards", -- [528]
	"FlySwimWalkBackwards", -- [529]
	"SwimSprint", -- [530]
	"FlySwimSprint", -- [531]
	"MountSwimIdle", -- [532]
	"FlyMountSwimIdle", -- [533]
	"MountSwimBackwards", -- [534]
	"FlyMountSwimBackwards", -- [535]
	"MountSwimLeft", -- [536]
	"FlyMountSwimLeft", -- [537]
	"MountSwimRight", -- [538]
	"FlyMountSwimRight", -- [539]
	"MountSwimRun", -- [540]
	"FlyMountSwimRun", -- [541]
	"MountSwimSprint", -- [542]
	"FlyMountSwimSprint", -- [543]
	"MountSwimWalk", -- [544]
	"FlyMountSwimWalk", -- [545]
	"MountSwimWalkBackwards", -- [546]
	"FlyMountSwimWalkBackwards", -- [547]
	"MountFlightIdle", -- [548]
	"FlyMountFlightIdle", -- [549]
	"MountFlightBackwards", -- [550]
	"FlyMountFlightBackwards", -- [551]
	"MountFlightLeft", -- [552]
	"FlyMountFlightLeft", -- [553]
	"MountFlightRight", -- [554]
	"FlyMountFlightRight", -- [555]
	"MountFlightRun", -- [556]
	"FlyMountFlightRun", -- [557]
	"MountFlightSprint", -- [558]
	"FlyMountFlightSprint", -- [559]
	"MountFlightWalk", -- [560]
	"FlyMountFlightWalk", -- [561]
	"MountFlightWalkBackwards", -- [562]
	"FlyMountFlightWalkBackwards", -- [563]
	"MountFlightStart", -- [564]
	"FlyMountFlightStart", -- [565]
	"MountSwimStart", -- [566]
	"FlyMountSwimStart", -- [567]
	"MountSwimLand", -- [568]
	"FlyMountSwimLand", -- [569]
	"MountSwimLandRun", -- [570]
	"FlyMountSwimLandRun", -- [571]
	"MountFlightLand", -- [572]
	"FlyMountFlightLand", -- [573]
	"MountFlightLandRun", -- [574]
	"FlyMountFlightLandRun", -- [575]
	"ReadyBlowDart", -- [576]
	"FlyReadyBlowDart", -- [577]
	"LoadBlowDart", -- [578]
	"FlyLoadBlowDart", -- [579]
	"HoldBlowDart", -- [580]
	"FlyHoldBlowDart", -- [581]
	"AttackBlowDart", -- [582]
	"FlyAttackBlowDart", -- [583]
	"CarriageMount", -- [584]
	"FlyCarriageMount", -- [585]
	"CarriagePassengerMount", -- [586]
	"FlyCarriagePassengerMount", -- [587]
	"CarriageMountAttack", -- [588]
	"FlyCarriageMountAttack", -- [589]
	"BarTendStand", -- [590]
	"FlyBarTendStand", -- [591]
	"BarServerWalk", -- [592]
	"FlyBarServerWalk", -- [593]
	"BarServerRun", -- [594]
	"FlyBarServerRun", -- [595]
	"BarServerShuffleLeft", -- [596]
	"FlyBarServerShuffleLeft", -- [597]
	"BarServerShuffleRight", -- [598]
	"FlyBarServerShuffleRight", -- [599]
	"BarTendEmoteTalk", -- [600]
	"FlyBarTendEmoteTalk", -- [601]
	"BarTendEmotePoint", -- [602]
	"FlyBarTendEmotePoint", -- [603]
	"BarServerStand", -- [604]
	"FlyBarServerStand", -- [605]
	"BarSweepWalk", -- [606]
	"FlyBarSweepWalk", -- [607]
	"BarSweepRun", -- [608]
	"FlyBarSweepRun", -- [609]
	"BarSweepShuffleLeft", -- [610]
	"FlyBarSweepShuffleLeft", -- [611]
	"BarSweepShuffleRight", -- [612]
	"FlyBarSweepShuffleRight", -- [613]
	"BarSweepEmoteTalk", -- [614]
	"FlyBarSweepEmoteTalk", -- [615]
	"BarPatronSitEmotePoint", -- [616]
	"FlyBarPatronSitEmotePoint", -- [617]
	"MountSelfIdle", -- [618]
	"FlyMountSelfIdle", -- [619]
	"MountSelfWalk", -- [620]
	"FlyMountSelfWalk", -- [621]
	"MountSelfRun", -- [622]
	"FlyMountSelfRun", -- [623]
	"MountSelfSprint", -- [624]
	"FlyMountSelfSprint", -- [625]
	"MountSelfRunLeft", -- [626]
	"FlyMountSelfRunLeft", -- [627]
	"MountSelfRunRight", -- [628]
	"FlyMountSelfRunRight", -- [629]
	"MountSelfShuffleLeft", -- [630]
	"FlyMountSelfShuffleLeft", -- [631]
	"MountSelfShuffleRight", -- [632]
	"FlyMountSelfShuffleRight", -- [633]
	"MountSelfWalkBackwards", -- [634]
	"FlyMountSelfWalkBackwards", -- [635]
	"MountSelfSpecial", -- [636]
	"FlyMountSelfSpecial", -- [637]
	"MountSelfJump", -- [638]
	"FlyMountSelfJump", -- [639]
	"MountSelfJumpStart", -- [640]
	"FlyMountSelfJumpStart", -- [641]
	"MountSelfJumpEnd", -- [642]
	"FlyMountSelfJumpEnd", -- [643]
	"MountSelfJumpLandRun", -- [644]
	"FlyMountSelfJumpLandRun", -- [645]
	"MountSelfStart", -- [646]
	"FlyMountSelfStart", -- [647]
	"MountSelfFall", -- [648]
	"FlyMountSelfFall", -- [649]
	"Stormstrike", -- [650]
	"FlyStormstrike", -- [651]
	"ReadyJoustNoSheathe", -- [652]
	"FlyReadyJoustNoSheathe", -- [653]
	"Slam", -- [654]
	"FlySlam", -- [655]
	"DeathStrike", -- [656]
	"FlyDeathStrike", -- [657]
	"SwimAttackUnarmed", -- [658]
	"FlySwimAttackUnarmed", -- [659]
	"SpinningKick", -- [660]
	"FlySpinningKick", -- [661]
	"RoundHouseKick", -- [662]
	"FlyRoundHouseKick", -- [663]
	"RollStart", -- [664]
	"FlyRollStart", -- [665]
	"Roll", -- [666]
	"FlyRoll", -- [667]
	"RollEnd", -- [668]
	"FlyRollEnd", -- [669]
	"PalmStrike", -- [670]
	"FlyPalmStrike", -- [671]
	"MonkOffenseAttackUnarmed", -- [672]
	"FlyMonkOffenseAttackUnarmed", -- [673]
	"MonkOffenseAttackUnarmedOff", -- [674]
	"FlyMonkOffenseAttackUnarmedOff", -- [675]
	"MonkOffenseParryUnarmed", -- [676]
	"FlyMonkOffenseParryUnarmed", -- [677]
	"MonkOffenseReadyUnarmed", -- [678]
	"FlyMonkOffenseReadyUnarmed", -- [679]
	"MonkOffenseSpecialUnarmed", -- [680]
	"FlyMonkOffenseSpecialUnarmed", -- [681]
	"MonkDefenseAttackUnarmed", -- [682]
	"FlyMonkDefenseAttackUnarmed", -- [683]
	"MonkDefenseAttackUnarmedOff", -- [684]
	"FlyMonkDefenseAttackUnarmedOff", -- [685]
	"MonkDefenseParryUnarmed", -- [686]
	"FlyMonkDefenseParryUnarmed", -- [687]
	"MonkDefenseReadyUnarmed", -- [688]
	"FlyMonkDefenseReadyUnarmed", -- [689]
	"MonkDefenseSpecialUnarmed", -- [690]
	"FlyMonkDefenseSpecialUnarmed", -- [691]
	"MonkHealAttackUnarmed", -- [692]
	"FlyMonkHealAttackUnarmed", -- [693]
	"MonkHealAttackUnarmedOff", -- [694]
	"FlyMonkHealAttackUnarmedOff", -- [695]
	"MonkHealParryUnarmed", -- [696]
	"FlyMonkHealParryUnarmed", -- [697]
	"MonkHealReadyUnarmed", -- [698]
	"FlyMonkHealReadyUnarmed", -- [699]
	"MonkHealSpecialUnarmed", -- [700]
	"FlyMonkHealSpecialUnarmed", -- [701]
	"FlyingKick", -- [702]
	"FlyFlyingKick", -- [703]
	"FlyingKickStart", -- [704]
	"FlyFlyingKickStart", -- [705]
	"FlyingKickEnd", -- [706]
	"FlyFlyingKickEnd", -- [707]
	"CraneStart", -- [708]
	"FlyCraneStart", -- [709]
	"CraneLoop", -- [710]
	"FlyCraneLoop", -- [711]
	"CraneEnd", -- [712]
	"FlyCraneEnd", -- [713]
	"Despawned", -- [714]
	"FlyDespawned", -- [715]
	"ThousandFists", -- [716]
	"FlyThousandFists", -- [717]
	"MonkHealReadySpellDirected", -- [718]
	"FlyMonkHealReadySpellDirected", -- [719]
	"MonkHealReadySpellOmni", -- [720]
	"FlyMonkHealReadySpellOmni", -- [721]
	"MonkHealSpellCastDirected", -- [722]
	"FlyMonkHealSpellCastDirected", -- [723]
	"MonkHealSpellCastOmni", -- [724]
	"FlyMonkHealSpellCastOmni", -- [725]
	"MonkHealChannelCastDirected", -- [726]
	"FlyMonkHealChannelCastDirected", -- [727]
	"MonkHealChannelCastOmni", -- [728]
	"FlyMonkHealChannelCastOmni", -- [729]
	"Torpedo", -- [730]
	"FlyTorpedo", -- [731]
	"Meditate", -- [732]
	"FlyMeditate", -- [733]
	"BreathOfFire", -- [734]
	"FlyBreathOfFire", -- [735]
	"RisingSunKick", -- [736]
	"FlyRisingSunKick", -- [737]
	"GroundKick", -- [738]
	"FlyGroundKick", -- [739]
	"KickBack", -- [740]
	"FlyKickBack", -- [741]
	"PetBattleStand", -- [742]
	"FlyPetBattleStand", -- [743]
	"PetBattleDeath", -- [744]
	"FlyPetBattleDeath", -- [745]
	"PetBattleRun", -- [746]
	"FlyPetBattleRun", -- [747]
	"PetBattleWound", -- [748]
	"FlyPetBattleWound", -- [749]
	"PetBattleAttack", -- [750]
	"FlyPetBattleAttack", -- [751]
	"PetBattleReadySpell", -- [752]
	"FlyPetBattleReadySpell", -- [753]
	"PetBattleSpellCast", -- [754]
	"FlyPetBattleSpellCast", -- [755]
	"PetBattleCustom0", -- [756]
	"FlyPetBattleCustom0", -- [757]
	"PetBattleCustom1", -- [758]
	"FlyPetBattleCustom1", -- [759]
	"PetBattleCustom2", -- [760]
	"FlyPetBattleCustom2", -- [761]
	"PetBattleCustom3", -- [762]
	"FlyPetBattleCustom3", -- [763]
	"PetBattleVictory", -- [764]
	"FlyPetBattleVictory", -- [765]
	"PetBattleLoss", -- [766]
	"FlyPetBattleLoss", -- [767]
	"PetBattleStun", -- [768]
	"FlyPetBattleStun", -- [769]
	"PetBattleDead", -- [770]
	"FlyPetBattleDead", -- [771]
	"PetBattleFreeze", -- [772]
	"FlyPetBattleFreeze", -- [773]
	"MonkOffenseAttackWeapon", -- [774]
	"FlyMonkOffenseAttackWeapon", -- [775]
	"BarTendEmoteWave", -- [776]
	"FlyBarTendEmoteWave", -- [777]
	"BarServerEmoteTalk", -- [778]
	"FlyBarServerEmoteTalk", -- [779]
	"BarServerEmoteWave", -- [780]
	"FlyBarServerEmoteWave", -- [781]
	"BarServerPourDrinks", -- [782]
	"FlyBarServerPourDrinks", -- [783]
	"BarServerPickup", -- [784]
	"FlyBarServerPickup", -- [785]
	"BarServerPutDown", -- [786]
	"FlyBarServerPutDown", -- [787]
	"BarSweepStand", -- [788]
	"FlyBarSweepStand", -- [789]
	"BarPatronSit", -- [790]
	"FlyBarPatronSit", -- [791]
	"BarPatronSitEmoteTalk", -- [792]
	"FlyBarPatronSitEmoteTalk", -- [793]
	"BarPatronStand", -- [794]
	"FlyBarPatronStand", -- [795]
	"BarPatronStandEmoteTalk", -- [796]
	"FlyBarPatronStandEmoteTalk", -- [797]
	"BarPatronStandEmotePoint", -- [798]
	"FlyBarPatronStandEmotePoint", -- [799]
	"CarrionSwarm", -- [800]
	"FlyCarrionSwarm", -- [801]
	"WheelLoop", -- [802]
	"FlyWheelLoop", -- [803]
	"StandCharacterCreate", -- [804]
	"FlyStandCharacterCreate", -- [805]
	"MountChopper", -- [806]
	"FlyMountChopper", -- [807]
	"FacePose", -- [808]
	"FlyFacePose", -- [809]
	"CombatAbility2HBig01", -- [810]
	"FlyCombatAbility2HBig01", -- [811]
	"CombatAbility2H01", -- [812]
	"FlyCombatAbility2H01", -- [813]
	"CombatWhirlwind", -- [814]
	"FlyCombatWhirlwind", -- [815]
	"CombatChargeLoop", -- [816]
	"FlyCombatChargeLoop", -- [817]
	"CombatAbility1H01", -- [818]
	"FlyCombatAbility1H01", -- [819]
	"CombatChargeEnd", -- [820]
	"FlyCombatChargeEnd", -- [821]
	"CombatAbility1H02", -- [822]
	"FlyCombatAbility1H02", -- [823]
	"CombatAbility1HBig01", -- [824]
	"FlyCombatAbility1HBig01", -- [825]
	"CombatAbility2H02", -- [826]
	"FlyCombatAbility2H02", -- [827]
	"ShaSpellPrecastBoth", -- [828]
	"FlyShaSpellPrecastBoth", -- [829]
	"ShaSpellCastBothFront", -- [830]
	"FlyShaSpellCastBothFront", -- [831]
	"ShaSpellCastLeftFront", -- [832]
	"FlyShaSpellCastLeftFront", -- [833]
	"ShaSpellCastRightFront", -- [834]
	"FlyShaSpellCastRightFront", -- [835]
	"ReadyCrossbow", -- [836]
	"FlyReadyCrossbow", -- [837]
	"LoadCrossbow", -- [838]
	"FlyLoadCrossbow", -- [839]
	"AttackCrossbow", -- [840]
	"FlyAttackCrossbow", -- [841]
	"HoldCrossbow", -- [842]
	"FlyHoldCrossbow", -- [843]
	"CombatAbility2HL01", -- [844]
	"FlyCombatAbility2HL01", -- [845]
	"CombatAbility2HL02", -- [846]
	"FlyCombatAbility2HL02", -- [847]
	"CombatAbility2HLBig01", -- [848]
	"FlyCombatAbility2HLBig01", -- [849]
	"CombatUnarmed01", -- [850]
	"FlyCombatUnarmed01", -- [851]
	"CombatStompLeft", -- [852]
	"FlyCombatStompLeft", -- [853]
	"CombatStompRight", -- [854]
	"FlyCombatStompRight", -- [855]
	"CombatLeapLoop", -- [856]
	"FlyCombatLeapLoop", -- [857]
	"CombatLeapEnd", -- [858]
	"FlyCombatLeapEnd", -- [859]
	"ShaReadySpellCast", -- [860]
	"FlyShaReadySpellCast", -- [861]
	"ShaSpellPrecastBothChannel", -- [862]
	"FlyShaSpellPrecastBothChannel", -- [863]
	"ShaSpellCastBothUp", -- [864]
	"FlyShaSpellCastBothUp", -- [865]
	"ShaSpellCastBothUpChannel", -- [866]
	"FlyShaSpellCastBothUpChannel", -- [867]
	"ShaSpellCastBothFrontChannel", -- [868]
	"FlyShaSpellCastBothFrontChannel", -- [869]
	"ShaSpellCastLeftFrontChannel", -- [870]
	"FlyShaSpellCastLeftFrontChannel", -- [871]
	"ShaSpellCastRightFrontChannel", -- [872]
	"FlyShaSpellCastRightFrontChannel", -- [873]
	"PriReadySpellCast", -- [874]
	"FlyPriReadySpellCast", -- [875]
	"PriSpellPrecastBoth", -- [876]
	"FlyPriSpellPrecastBoth", -- [877]
	"PriSpellPrecastBothChannel", -- [878]
	"FlyPriSpellPrecastBothChannel", -- [879]
	"PriSpellCastBothUp", -- [880]
	"FlyPriSpellCastBothUp", -- [881]
	"PriSpellCastBothFront", -- [882]
	"FlyPriSpellCastBothFront", -- [883]
	"PriSpellCastLeftFront", -- [884]
	"FlyPriSpellCastLeftFront", -- [885]
	"PriSpellCastRightFront", -- [886]
	"FlyPriSpellCastRightFront", -- [887]
	"PriSpellCastBothUpChannel", -- [888]
	"FlyPriSpellCastBothUpChannel", -- [889]
	"PriSpellCastBothFrontChannel", -- [890]
	"FlyPriSpellCastBothFrontChannel", -- [891]
	"PriSpellCastLeftFrontChannel", -- [892]
	"FlyPriSpellCastLeftFrontChannel", -- [893]
	"PriSpellCastRightFrontChannel", -- [894]
	"FlyPriSpellCastRightFrontChannel", -- [895]
	"MagReadySpellCast", -- [896]
	"FlyMagReadySpellCast", -- [897]
	"MagSpellPrecastBoth", -- [898]
	"FlyMagSpellPrecastBoth", -- [899]
	"MagSpellPrecastBothChannel", -- [900]
	"FlyMagSpellPrecastBothChannel", -- [901]
	"MagSpellCastBothUp", -- [902]
	"FlyMagSpellCastBothUp", -- [903]
	"MagSpellCastBothFront", -- [904]
	"FlyMagSpellCastBothFront", -- [905]
	"MagSpellCastLeftFront", -- [906]
	"FlyMagSpellCastLeftFront", -- [907]
	"MagSpellCastRightFront", -- [908]
	"FlyMagSpellCastRightFront", -- [909]
	"MagSpellCastBothUpChannel", -- [910]
	"FlyMagSpellCastBothUpChannel", -- [911]
	"MagSpellCastBothFrontChannel", -- [912]
	"FlyMagSpellCastBothFrontChannel", -- [913]
	"MagSpellCastLeftFrontChannel", -- [914]
	"FlyMagSpellCastLeftFrontChannel", -- [915]
	"MagSpellCastRightFrontChannel", -- [916]
	"FlyMagSpellCastRightFrontChannel", -- [917]
	"LocReadySpellCast", -- [918]
	"FlyLocReadySpellCast", -- [919]
	"LocSpellPrecastBoth", -- [920]
	"FlyLocSpellPrecastBoth", -- [921]
	"LocSpellPrecastBothChannel", -- [922]
	"FlyLocSpellPrecastBothChannel", -- [923]
	"LocSpellCastBothUp", -- [924]
	"FlyLocSpellCastBothUp", -- [925]
	"LocSpellCastBothFront", -- [926]
	"FlyLocSpellCastBothFront", -- [927]
	"LocSpellCastLeftFront", -- [928]
	"FlyLocSpellCastLeftFront", -- [929]
	"LocSpellCastRightFront", -- [930]
	"FlyLocSpellCastRightFront", -- [931]
	"LocSpellCastBothUpChannel", -- [932]
	"FlyLocSpellCastBothUpChannel", -- [933]
	"LocSpellCastBothFrontChannel", -- [934]
	"FlyLocSpellCastBothFrontChannel", -- [935]
	"LocSpellCastLeftFrontChannel", -- [936]
	"FlyLocSpellCastLeftFrontChannel", -- [937]
	"LocSpellCastRightFrontChannel", -- [938]
	"FlyLocSpellCastRightFrontChannel", -- [939]
	"DruReadySpellCast", -- [940]
	"FlyDruReadySpellCast", -- [941]
	"DruSpellPrecastBoth", -- [942]
	"FlyDruSpellPrecastBoth", -- [943]
	"DruSpellPrecastBothChannel", -- [944]
	"FlyDruSpellPrecastBothChannel", -- [945]
	"DruSpellCastBothUp", -- [946]
	"FlyDruSpellCastBothUp", -- [947]
	"DruSpellCastBothFront", -- [948]
	"FlyDruSpellCastBothFront", -- [949]
	"DruSpellCastLeftFront", -- [950]
	"FlyDruSpellCastLeftFront", -- [951]
	"DruSpellCastRightFront", -- [952]
	"FlyDruSpellCastRightFront", -- [953]
	"DruSpellCastBothUpChannel", -- [954]
	"FlyDruSpellCastBothUpChannel", -- [955]
	"DruSpellCastBothFrontChannel", -- [956]
	"FlyDruSpellCastBothFrontChannel", -- [957]
	"DruSpellCastLeftFrontChannel", -- [958]
	"FlyDruSpellCastLeftFrontChannel", -- [959]
	"DruSpellCastRightFrontChannel", -- [960]
	"FlyDruSpellCastRightFrontChannel", -- [961]
	"ArtMainLoop", -- [962]
	"FlyArtMainLoop", -- [963]
	"ArtDualLoop", -- [964]
	"FlyArtDualLoop", -- [965]
	"ArtFistsLoop", -- [966]
	"FlyArtFistsLoop", -- [967]
	"ArtBowLoop", -- [968]
	"FlyArtBowLoop", -- [969]
	"CombatAbility1H01Off", -- [970]
	"FlyCombatAbility1H01Off", -- [971]
	"CombatAbility1H02Off", -- [972]
	"FlyCombatAbility1H02Off", -- [973]
	"CombatFuriousStrike01", -- [974]
	"FlyCombatFuriousStrike01", -- [975]
	"CombatFuriousStrike02", -- [976]
	"FlyCombatFuriousStrike02", -- [977]
	"CombatFuriousStrikes", -- [978]
	"FlyCombatFuriousStrikes", -- [979]
	"CombatReadySpellCast", -- [980]
	"FlyCombatReadySpellCast", -- [981]
	"CombatShieldThrow", -- [982]
	"FlyCombatShieldThrow", -- [983]
	"PalSpellCast1HUp", -- [984]
	"FlyPalSpellCast1HUp", -- [985]
	"CombatReadyPostSpellCast", -- [986]
	"FlyCombatReadyPostSpellCast", -- [987]
	"PriReadyPostSpellCast", -- [988]
	"FlyPriReadyPostSpellCast", -- [989]
	"DHCombatRun", -- [990]
	"FlyDHCombatRun", -- [991]
	"CombatShieldBash", -- [992]
	"FlyCombatShieldBash", -- [993]
	"CombatThrow", -- [994]
	"FlyCombatThrow", -- [995]
	"CombatAbility1HPierce", -- [996]
	"FlyCombatAbility1HPierce", -- [997]
	"CombatAbility1HOffPierce", -- [998]
	"FlyCombatAbility1HOffPierce", -- [999]
	"CombatMutilate", -- [1000]
	"FlyCombatMutilate", -- [1001]
	"CombatBladeStorm", -- [1002]
	"FlyCombatBladeStorm", -- [1003]
	"CombatFinishingMove", -- [1004]
	"FlyCombatFinishingMove", -- [1005]
	"CombatLeapStart", -- [1006]
	"FlyCombatLeapStart", -- [1007]
	"GlvThrowMain", -- [1008]
	"FlyGlvThrowMain", -- [1009]
	"GlvThrownOff", -- [1010]
	"FlyGlvThrownOff", -- [1011]
	"DHCombatSprint", -- [1012]
	"FlyDHCombatSprint", -- [1013]
	"CombatAbilityGlv01", -- [1014]
	"FlyCombatAbilityGlv01", -- [1015]
	"CombatAbilityGlv02", -- [1016]
	"FlyCombatAbilityGlv02", -- [1017]
	"CombatAbilityGlvOff01", -- [1018]
	"FlyCombatAbilityGlvOff01", -- [1019]
	"CombatAbilityGlvOff02", -- [1020]
	"FlyCombatAbilityGlvOff02", -- [1021]
	"CombatAbilityGlvBig01", -- [1022]
	"FlyCombatAbilityGlvBig01", -- [1023]
	"CombatAbilityGlvBig02", -- [1024]
	"FlyCombatAbilityGlvBig02", -- [1025]
	"ReadyGlv", -- [1026]
	"FlyReadyGlv", -- [1027]
	"CombatAbilityGlvBig03", -- [1028]
	"FlyCombatAbilityGlvBig03", -- [1029]
	"DoubleJumpStart", -- [1030]
	"FlyDoubleJumpStart", -- [1031]
	"DoubleJump", -- [1032]
	"FlyDoubleJump", -- [1033]
	"CombatEviscerate", -- [1034]
	"FlyCombatEviscerate", -- [1035]
	"DoubleJumpLandRun", -- [1036]
	"FlyDoubleJumpLandRun", -- [1037]
	"BackFlipStart", -- [1038]
	"FlyBackFlipStart", -- [1039]
	"BackFlipLoop", -- [1040]
	"FlyBackFlipLoop", -- [1041]
	"FelRushLoop", -- [1042]
	"FlyFelRushLoop", -- [1043]
	"FelRushEnd", -- [1044]
	"FlyFelRushEnd", -- [1045]
	"DHToAlteredStart", -- [1046]
	"FlyDHToAlteredStart", -- [1047]
	"DHToAlteredEnd", -- [1048]
	"FlyDHToAlteredEnd", -- [1049]
	"DHGlide", -- [1050]
	"FlyDHGlide", -- [1051]
	"FanOfKnives", -- [1052]
	"FlyFanOfKnives", -- [1053]
	"SingleJumpStart", -- [1054]
	"FlySingleJumpStart", -- [1055]
	"DHBladeDance1", -- [1056]
	"FlyDHBladeDance1", -- [1057]
	"DHBladeDance2", -- [1058]
	"FlyDHBladeDance2", -- [1059]
	"DHBladeDance3", -- [1060]
	"FlyDHBladeDance3", -- [1061]
	"DHMeteorStrike", -- [1062]
	"FlyDHMeteorStrike", -- [1063]
	"CombatExecute", -- [1064]
	"FlyCombatExecute", -- [1065]
	"ArtLoop", -- [1066]
	"FlyArtLoop", -- [1067]
	"ParryGlv", -- [1068]
	"FlyParryGlv", -- [1069]
	"CombatUnarmed02", -- [1070]
	"FlyCombatUnarmed02", -- [1071]
	"CombatPistolShot", -- [1072]
	"FlyCombatPistolShot", -- [1073]
	"CombatPistolShotOff", -- [1074]
	"FlyCombatPistolShotOff", -- [1075]
	"Monk2HLIdle", -- [1076]
	"FlyMonk2HLIdle", -- [1077]
	"ArtShieldLoop", -- [1078]
	"FlyArtShieldLoop", -- [1079]
	"CombatAbility2H03", -- [1080]
	"FlyCombatAbility2H03", -- [1081]
	"CombatStomp", -- [1082]
	"FlyCombatStomp", -- [1083]
	"CombatRoar", -- [1084]
	"FlyCombatRoar", -- [1085]
	"PalReadySpellCast", -- [1086]
	"FlyPalReadySpellCast", -- [1087]
	"PalSpellPrecastRight", -- [1088]
	"FlyPalSpellPrecastRight", -- [1089]
	"PalSpellPrecastRightChannel", -- [1090]
	"FlyPalSpellPrecastRightChannel", -- [1091]
	"PalSpellCastRightFront", -- [1092]
	"FlyPalSpellCastRightFront", -- [1093]
	"ShaSpellCastBothOut", -- [1094]
	"FlyShaSpellCastBothOut", -- [1095]
	"AttackWeapon", -- [1096]
	"FlyAttackWeapon", -- [1097]
	"ReadyWeapon", -- [1098]
	"FlyReadyWeapon", -- [1099]
	"AttackWeaponOff", -- [1100]
	"FlyAttackWeaponOff", -- [1101]
	"SpecialDual", -- [1102]
	"FlySpecialDual", -- [1103]
	"DKCast1HFront", -- [1104]
	"FlyDKCast1HFront", -- [1105]
	"CastStrongRight", -- [1106]
	"FlyCastStrongRight", -- [1107]
	"CastStrongLeft", -- [1108]
	"FlyCastStrongLeft", -- [1109]
	"CastCurseRight", -- [1110]
	"FlyCastCurseRight", -- [1111]
	"CastCurseLeft", -- [1112]
	"FlyCastCurseLeft", -- [1113]
	"CastSweepRight", -- [1114]
	"FlyCastSweepRight", -- [1115]
	"CastSweepLeft", -- [1116]
	"FlyCastSweepLeft", -- [1117]
	"CastStrongUpLeft", -- [1118]
	"FlyCastStrongUpLeft", -- [1119]
	"CastTwistUpBoth", -- [1120]
	"FlyCastTwistUpBoth", -- [1121]
	"CastOutStrong", -- [1122]
	"FlyCastOutStrong", -- [1123]
	"DrumLoop", -- [1124]
	"FlyDrumLoop", -- [1125]
	"ParryWeapon", -- [1126]
	"FlyParryWeapon", -- [1127]
	"ReadyFL", -- [1128]
	"FlyReadyFL", -- [1129]
	"AttackFL", -- [1130]
	"FlyAttackFL", -- [1131]
	"AttackFLOff", -- [1132]
	"FlyAttackFLOff", -- [1133]
	"ParryFL", -- [1134]
	"FlyParryFL", -- [1135]
	"SpecialFL", -- [1136]
	"FlySpecialFL", -- [1137]
	"PriHoverForward", -- [1138]
	"FlyPriHoverForward", -- [1139]
	"PriHoverBackward", -- [1140]
	"FlyPriHoverBackward", -- [1141]
	"PriHoverRight", -- [1142]
	"FlyPriHoverRight", -- [1143]
	"PriHoverLeft", -- [1144]
	"FlyPriHoverLeft", -- [1145]
	"RunBackwards", -- [1146]
	"FlyRunBackwards", -- [1147]
	"CastStrongUpRight", -- [1148]
	"FlyCastStrongUpRight", -- [1149]
	"WAWalk", -- [1150]
	"FlyWAWalk", -- [1151]
	"WARun", -- [1152]
	"FlyWARun", -- [1153]
	"WADrunkStand", -- [1154]
	"FlyWADrunkStand", -- [1155]
	"WADrunkShuffleLeft", -- [1156]
	"FlyWADrunkShuffleLeft", -- [1157]
	"WADrunkShuffleRight", -- [1158]
	"FlyWADrunkShuffleRight", -- [1159]
	"WADrunkWalk", -- [1160]
	"FlyWADrunkWalk", -- [1161]
	"WADrunkWalkBackwards", -- [1162]
	"FlyWADrunkWalkBackwards", -- [1163]
	"WADrunkWound", -- [1164]
	"FlyWADrunkWound", -- [1165]
	"WADrunkTalk", -- [1166]
	"FlyWADrunkTalk", -- [1167]
	"WATrance01", -- [1168]
	"FlyWATrance01", -- [1169]
	"WATrance02", -- [1170]
	"FlyWATrance02", -- [1171]
	"WAChant01", -- [1172]
	"FlyWAChant01", -- [1173]
	"WAChant02", -- [1174]
	"FlyWAChant02", -- [1175]
	"WAChant03", -- [1176]
	"FlyWAChant03", -- [1177]
	"WAHang01", -- [1178]
	"FlyWAHang01", -- [1179]
	"WAHang02", -- [1180]
	"FlyWAHang02", -- [1181]
	"WASummon01", -- [1182]
	"FlyWASummon01", -- [1183]
	"WASummon02", -- [1184]
	"FlyWASummon02", -- [1185]
	"WABeggarTalk", -- [1186]
	"FlyWABeggarTalk", -- [1187]
	"WABeggarStand", -- [1188]
	"FlyWABeggarStand", -- [1189]
	"WABeggarPoint", -- [1190]
	"FlyWABeggarPoint", -- [1191]
	"WABeggarBeg", -- [1192]
	"FlyWABeggarBeg", -- [1193]
	"WASit01", -- [1194]
	"FlyWASit01", -- [1195]
	"WASit02", -- [1196]
	"FlyWASit02", -- [1197]
	"WASit03", -- [1198]
	"FlyWASit03", -- [1199]
	"WACrierStand01", -- [1200]
	"FlyWACrierStand01", -- [1201]
	"WACrierStand02", -- [1202]
	"FlyWACrierStand02", -- [1203]
	"WACrierStand03", -- [1204]
	"FlyWACrierStand03", -- [1205]
	"WACrierTalk", -- [1206]
	"FlyWACrierTalk", -- [1207]
	"WACrateHold", -- [1208]
	"FlyWACrateHold", -- [1209]
	"WABarrelHold", -- [1210]
	"FlyWABarrelHold", -- [1211]
	"WASackHold", -- [1212]
	"FlyWASackHold", -- [1213]
	"WAWheelBarrowStand", -- [1214]
	"FlyWAWheelBarrowStand", -- [1215]
	"WAWheelBarrowWalk", -- [1216]
	"FlyWAWheelBarrowWalk", -- [1217]
	"WAWheelBarrowRun", -- [1218]
	"FlyWAWheelBarrowRun", -- [1219]
	"WAHammerLoop", -- [1220]
	"FlyWAHammerLoop", -- [1221]
	"WACrankLoop", -- [1222]
	"FlyWACrankLoop", -- [1223]
	"WAPourStart", -- [1224]
	"FlyWAPourStart", -- [1225]
	"WAPourLoop", -- [1226]
	"FlyWAPourLoop", -- [1227]
	"WAPourEnd", -- [1228]
	"FlyWAPourEnd", -- [1229]
	"WAEmotePour", -- [1230]
	"FlyWAEmotePour", -- [1231]
	"WARowingStandRight", -- [1232]
	"FlyWARowingStandRight", -- [1233]
	"WARowingStandLeft", -- [1234]
	"FlyWARowingStandLeft", -- [1235]
	"WARowingRight", -- [1236]
	"FlyWARowingRight", -- [1237]
	"WARowingLeft", -- [1238]
	"FlyWARowingLeft", -- [1239]
	"WAGuardStand01", -- [1240]
	"FlyWAGuardStand01", -- [1241]
	"WAGuardStand02", -- [1242]
	"FlyWAGuardStand02", -- [1243]
	"WAGuardStand03", -- [1244]
	"FlyWAGuardStand03", -- [1245]
	"WAGuardStand04", -- [1246]
	"FlyWAGuardStand04", -- [1247]
	"WAFreezing01", -- [1248]
	"FlyWAFreezing01", -- [1249]
	"WAFreezing02", -- [1250]
	"FlyWAFreezing02", -- [1251]
	"WAVendorStand01", -- [1252]
	"FlyWAVendorStand01", -- [1253]
	"WAVendorStand02", -- [1254]
	"FlyWAVendorStand02", -- [1255]
	"WAVendorStand03", -- [1256]
	"FlyWAVendorStand03", -- [1257]
	"WAVendorTalk", -- [1258]
	"FlyWAVendorTalk", -- [1259]
	"WALean01", -- [1260]
	"FlyWALean01", -- [1261]
	"WALean02", -- [1262]
	"FlyWALean02", -- [1263]
	"WALean03", -- [1264]
	"FlyWALean03", -- [1265]
	"WALeanTalk", -- [1266]
	"FlyWALeanTalk", -- [1267]
	"WABoatWheel", -- [1268]
	"FlyWABoatWheel", -- [1269]
	"WASmithLoop", -- [1270]
	"FlyWASmithLoop", -- [1271]
	"WAScrubbing", -- [1272]
	"FlyWAScrubbing", -- [1273]
	"WAWeaponSharpen", -- [1274]
	"FlyWAWeaponSharpen", -- [1275]
	"WAStirring", -- [1276]
	"FlyWAStirring", -- [1277]
	"WAPerch01", -- [1278]
	"FlyWAPerch01", -- [1279]
	"WAPerch02", -- [1280]
	"FlyWAPerch02", -- [1281]
	"HoldWeapon", -- [1282]
	"FlyHoldWeapon", -- [1283]
	"WABarrelWalk", -- [1284]
	"FlyWABarrelWalk", -- [1285]
	"WAPourHold", -- [1286]
	"FlyWAPourHold", -- [1287]
	"CastStrong", -- [1288]
	"FlyCastStrong", -- [1289]
	"CastCurse", -- [1290]
	"FlyCastCurse", -- [1291]
	"CastSweep", -- [1292]
	"FlyCastSweep", -- [1293]
	"CastStrongUp", -- [1294]
	"FlyCastStrongUp", -- [1295]
	"WABoatWheelStand", -- [1296]
	"FlyWABoatWheelStand", -- [1297]
	"WASmithStand", -- [1298]
	"FlyWASmithStand", -- [1299]
	"WACrankStand", -- [1300]
	"FlyWACrankStand", -- [1301]
	"WAPourWalk", -- [1302]
	"FlyWAPourWalk", -- [1303]
	"FalconerStart", -- [1304]
	"FlyFalconerStart", -- [1305]
	"FalconerLoop", -- [1306]
	"FlyFalconerLoop", -- [1307]
	"FalconerEnd", -- [1308]
	"FlyFalconerEnd", -- [1309]
	"WADrunkDrink", -- [1310]
	"FlyWADrunkDrink", -- [1311]
	"WAStandEat", -- [1312]
	"FlyWAStandEat", -- [1313]
	"WAStandDrink", -- [1314]
	"FlyWAStandDrink", -- [1315]
	"WABound01", -- [1316]
	"FlyWABound01", -- [1317]
	"WABound02", -- [1318]
	"FlyWABound02", -- [1319]
	"CombatAbility1H03Off", -- [1320]
	"FlyCombatAbility1H03Off", -- [1321]
	"CombatAbilityDualWield01", -- [1322]
	"FlyCombatAbilityDualWield01", -- [1323]
	"WACradle01", -- [1324]
	"FlyWACradle01", -- [1325]
	"LocSummon", -- [1326]
	"FlyLocSummon", -- [1327]
	"LoadWeapon", -- [1328]
	"FlyLoadWeapon", -- [1329]
	"ArtOffLoop", -- [1330]
	"FlyArtOffLoop", -- [1331]
	"WADead01", -- [1332]
	"FlyWADead01", -- [1333]
	"WADead02", -- [1334]
	"FlyWADead02", -- [1335]
	"WADead03", -- [1336]
	"FlyWADead03", -- [1337]
	"WADead04", -- [1338]
	"FlyWADead04", -- [1339]
	"WADead05", -- [1340]
	"FlyWADead05", -- [1341]
	"WADead06", -- [1342]
	"FlyWADead06", -- [1343]
	"WADead07", -- [1344]
	"FlyWADead07", -- [1345]
	"GiantRun", -- [1346]
	"FlyGiantRun", -- [1347]
	"BarTendEmoteCheer", -- [1348]
	"FlyBarTendEmoteCheer", -- [1349]
	"BarTendEmoteTalkQuestion", -- [1350]
	"FlyBarTendEmoteTalkQuestion", -- [1351]
	"BarTendEmoteTalkExclamation", -- [1352]
	"FlyBarTendEmoteTalkExclamation", -- [1353]
	"BarTendWalk", -- [1354]
	"FlyBarTendWalk", -- [1355]
	"BartendShuffleLeft", -- [1356]
	"FlyBartendShuffleLeft", -- [1357]
	"BarTendShuffleRight", -- [1358]
	"FlyBarTendShuffleRight", -- [1359]
	"BarTendCustomSpell01", -- [1360]
	"FlyBarTendCustomSpell01", -- [1361]
	"BarTendCustomSpell02", -- [1362]
	"FlyBarTendCustomSpell02", -- [1363]
	"BarTendCustomSpell03", -- [1364]
	"FlyBarTendCustomSpell03", -- [1365]
	"BarServerEmoteCheer", -- [1366]
	"FlyBarServerEmoteCheer", -- [1367]
	"BarServerEmoteTalkQuestion", -- [1368]
	"FlyBarServerEmoteTalkQuestion", -- [1369]
	"BarServerEmoteTalkExclamation", -- [1370]
	"FlyBarServerEmoteTalkExclamation", -- [1371]
	"BarServerCustomSpell01", -- [1372]
	"FlyBarServerCustomSpell01", -- [1373]
	"BarServerCustomSpell02", -- [1374]
	"FlyBarServerCustomSpell02", -- [1375]
	"BarServerCustomSpell03", -- [1376]
	"FlyBarServerCustomSpell03", -- [1377]
	"BarPatronEmoteDrink", -- [1378]
	"FlyBarPatronEmoteDrink", -- [1379]
	"BarPatronEmoteCheer", -- [1380]
	"FlyBarPatronEmoteCheer", -- [1381]
	"BarPatronCustomSpell01", -- [1382]
	"FlyBarPatronCustomSpell01", -- [1383]
	"BarPatronCustomSpell02", -- [1384]
	"FlyBarPatronCustomSpell02", -- [1385]
	"BarPatronCustomSpell03", -- [1386]
	"FlyBarPatronCustomSpell03", -- [1387]
	"HoldDart", -- [1388]
	"FlyHoldDart", -- [1389]
	"ReadyDart", -- [1390]
	"FlyReadyDart", -- [1391]
	"AttackDart", -- [1392]
	"FlyAttackDart", -- [1393]
	"LoadDart", -- [1394]
	"FlyLoadDart", -- [1395]
	"WADartTargetStand", -- [1396]
	"FlyWADartTargetStand", -- [1397]
	"WADartTargetEmoteTalk", -- [1398]
	"FlyWADartTargetEmoteTalk", -- [1399]
	"BarPatronSitEmoteCheer", -- [1400]
	"FlyBarPatronSitEmoteCheer", -- [1401]
	"BarPatronSitCustomSpell01", -- [1402]
	"FlyBarPatronSitCustomSpell01", -- [1403]
	"BarPatronSitCustomSpell02", -- [1404]
	"FlyBarPatronSitCustomSpell02", -- [1405]
	"BarPatronSitCustomSpell03", -- [1406]
	"FlyBarPatronSitCustomSpell03", -- [1407]
	"BarPianoStand", -- [1408]
	"FlyBarPianoStand", -- [1409]
	"BarPianoEmoteTalk", -- [1410]
	"FlyBarPianoEmoteTalk", -- [1411]
	"WAHearthSit", -- [1412]
	"FlyWAHearthSit", -- [1413]
	"WAHearthSitEmoteCry", -- [1414]
	"FlyWAHearthSitEmoteCry", -- [1415]
	"WAHearthSitEmoteCheer", -- [1416]
	"FlyWAHearthSitEmoteCheer", -- [1417]
	"WAHearthSitCustomSpell01", -- [1418]
	"FlyWAHearthSitCustomSpell01", -- [1419]
	"WAHearthSitCustomSpell02", -- [1420]
	"FlyWAHearthSitCustomSpell02", -- [1421]
	"WAHearthSitCustomSpell03", -- [1422]
	"FlyWAHearthSitCustomSpell03", -- [1423]
	"WAHearthStand", -- [1424]
	"FlyWAHearthStand", -- [1425]
	"WAHearthStandEmoteCheer", -- [1426]
	"FlyWAHearthStandEmoteCheer", -- [1427]
	"WAHearthStandEmoteTalk", -- [1428]
	"FlyWAHearthStandEmoteTalk", -- [1429]
	"WAHearthStandCustomSpell01", -- [1430]
	"FlyWAHearthStandCustomSpell01", -- [1431]
	"WAHearthStandCustomSpell02", -- [1432]
	"FlyWAHearthStandCustomSpell02", -- [1433]
	"WAHearthStandCustomSpell03", -- [1434]
	"FlyWAHearthStandCustomSpell03", -- [1435]
	"WAScribeStart", -- [1436]
	"FlyWAScribeStart", -- [1437]
	"WAScribeLoop", -- [1438]
	"FlyWAScribeLoop", -- [1439]
	"WAScribeEnd", -- [1440]
	"FlyWAScribeEnd", -- [1441]
	"WAEmoteScribe", -- [1442]
	"FlyWAEmoteScribe", -- [1443]
	"Haymaker", -- [1444]
	"FlyHaymaker", -- [1445]
	"HaymakerPrecast", -- [1446]
	"FlyHaymakerPrecast", -- [1447]
	"ChannelCastOmniUp", -- [1448]
	"FlyChannelCastOmniUp", -- [1449]
	"DHJumpLandRun", -- [1450]
	"FlyDHJumpLandRun", -- [1451]
	"Cinematic01", -- [1452]
	"FlyCinematic01", -- [1453]
	"Cinematic02", -- [1454]
	"FlyCinematic02", -- [1455]
	"Cinematic03", -- [1456]
	"FlyCinematic03", -- [1457]
	"Cinematic04", -- [1458]
	"FlyCinematic04", -- [1459]
	"Cinematic05", -- [1460]
	"FlyCinematic05", -- [1461]
	"Cinematic06", -- [1462]
	"FlyCinematic06", -- [1463]
	"Cinematic07", -- [1464]
	"FlyCinematic07", -- [1465]
	"Cinematic08", -- [1466]
	"FlyCinematic08", -- [1467]
	"Cinematic09", -- [1468]
	"FlyCinematic09", -- [1469]
	"Cinematic10", -- [1470]
	"FlyCinematic10", -- [1471]
	"TakeOffStart", -- [1472]
	"FlyTakeOffStart", -- [1473]
	"TakeOffFinish", -- [1474]
	"FlyTakeOffFinish", -- [1475]
	"LandStart", -- [1476]
	"FlyLandStart", -- [1477]
	"LandFinish", -- [1478]
	"FlyLandFinish", -- [1479]
	"WAWalkTalk", -- [1480]
	"FlyWAWalkTalk", -- [1481]
	"WAPerch03", -- [1482]
	"FlyWAPerch03", -- [1483]
	"CarriageMountMoving", -- [1484]
	"FlyCarriageMountMoving", -- [1485]
	"TakeOffFinishFly",	-- [1486] 	
	"FlyTakeOffFinishFly",	-- [1487]
	"CombatAbility2HBig02",	-- [1488]
	"FlyCombatAbility2HBig02",	-- [1489]
	"MountWide" ,	-- [1490]
	"FlyMountWide",	-- [1491]
	"EmoteTalkSubdued",	-- [1492]
	"FlyEmoteTalkSubdued",	-- [1493]
	"WASit04",	-- [1494]
	"FlyWASit04",	-- [1495]
	"MountSummon",	-- [1496]
	"FlyMountSummon",	-- [1497]
	"EmoteSelfie",	--[1498]
	"FlyEmoteSelfie", --[1499]
	"CustomSpell11",		--1500
	"FlyCustomSpell11",
	"CustomSpell12",
	"FlyCustomSpell12",
	"CustomSpell13",
	"FlyCustomSpell13",		--1505
	"CustomSpell14",
	"FlyCustomSpell14",
	"CustomSpell15",
	"FlyCustomSpell15",
	"CustomSpell16",		--1510
	"FlyCustomSpell16",
	"CustomSpell17",
	"FlyCustomSpell17",
	"CustomSpell18",
	"FlyCustomSpell18",		--1515
	"CustomSpell19",
	"FlyCustomSpell19",
	"CustomSpell20",
	"FlyCustomSpell20",
	"AdvFlyLeft",			--1520
	"FlyAdvFlyLeft",
	"AdvFlyRight",
	"FlyAdvFlyRight",
	"AdvFlyForward",
	"FlyAdvFlyForward",		--1525
	"AdvFlyBackward",
	"FlyAdvFlyBackward",
	"AdvFlyUp",
	"FlyAdvFlyUp",
	"AdvFlyDown",			--1530
	"FlyAdvFlyDown",
	"AdvFlyForwardGlide",
	"FlyAdvFlyForwardGlide",
	"AdvFlyRoll",
	"FlyAdvFlyRoll",		--1535
	"ProfCookingLoop",
	"FlyProfCookingLoop",
	"ProfCookingStart",
	"FlyProfCookingStart",
	"ProfCookingEnd",		--1540
	"FlyProfCookingEnd",
	"WACurious",
	"FlyWACurious",
	"WAAlert",
	"FlyWAAlert",			--1545
	"WAInvestigate",
	"FlyWAInvestigate",
	"WAInteraction",
	"FlyWAInteraction",
	"WAThreaten",			--1550
	"FlyWAThreaten",
	"WAReact01",
	"FlyWAReact01",
	"WAReact02",
	"FlyWAReact02",			--1555
	"AdvFlyRollStart",
	"FlyAdvFlyRollStart",
	"AdvFlyRollEnd",
	"FlyAdvFlyRollEnd",
	"EmpBreathPrecast",		--1560
	"FlyEmpBreathPrecast",
	"EmpBreathPrecastChannel",
	"FlyEmpBreathPrecastChannel",
	"EmpBreathSpellCast",
	"FlyEmpBreathSpellCast",	--1565
	"EmpBreathSpellCastChannel",
	"FlyEmpBreathSpellCastChannel",
	"DracFlyBreathTakeoffStart",
	"FlyDracFlyBreathTakeoffStart",
	"DracFlyBreathTakeoffFinish",	--1570
	"FlyDracFlyBreathTakeoffFinish",
	"DracFlyBreath",
	"FlyDracFlyBreath",
	"DracFlyBreathLandStart",
	"FlyDracFlyBreathLandStart",	--1575
	"DracFlyBreathLandFinish",
	"FlyDracFlyBreathLandFinish",
	"DracAirDashLeft",
	"FlyDracAirDashLeft",
	"DracAirDashForward",		--1580
	"FlyDracAirDashForward",
	"DracAirDashBackward",
	"FlyDracAirDashBackward",
	"DracAirDashRight",
	"FlyDracAirDashRight",		--1585
	"LivingWorldProximityEnter",
	"FlyLivingWorldProximityEnter",
	"AdvFlyDownEnd",
	"FlyAdvFlyDownEnd",
	"LivingWorldProximityLoop",	--1590
	"FlyLivingWorldProximityLoop",
	"LivingWorldProximityLeave",
	"FlyLivingWorldProximityLeave",
	"EmpAirBarragePrecast",
	"FlyEmpAirBarragePrecast",	--1595
	"EmpAirBarragePrecastChannel",
	"FlyEmpAirBarragePrecastChannel",
	"EmpAirBarrageSpellCast",
	"FlyEmpAirBarrageSpellCast",
	"DracClawSwipeLeft",		--1600
	"FlyDracClawSwipeLeft",
	"DracClawSwipeRight",
	"FlyDracClawSwipeRight",
	"DracHoverIdle",
	"FlyDracHoverIdle",			--1605
	"DracHoverLeft",
	"FlyDracHoverLeft",
	"DracHoverRight",
	"FlyDracHoverRight",
	"DracHoverBackward",		--1610
	"FlyDracHoverBackward",
	"DracHoverForward",
	"FlyDracHoverForward",
	"DracAttackWings",
	"FlyDracAttackWings",		--1615
	"DracAttackTail",
	"FlyDracAttackTail",
	"AdvFlyStart",
	"FlyAdvFlyStart",
	"AdvFlyLand",				--1620
	"FlyAdvFlyLand",
	"AdvFlyLandRun",
	"FlyAdvFlyLandRun",
	"AdvFlyStrafeLeft",
	"FlyAdvFlyStrafeLeft",		--1625
	"AdvFlyStrafeRight",
	"FlyAdvFlyStrafeRight",
	"AdvFlyIdle",
	"FlyAdvFlyIdle",
	"AdvFlyRollRight",			--1630
	"FlyAdvFlyRollRight",
	"AdvFlyRollRightEnd",
	"FlyAdvFlyRollRightEnd",
	"AdvFlyRollLeft",
	"FlyAdvFlyRollLeft",		--1635
	"AdvFlyRollLeftEnd",
	"FlyAdvFlyRollLeftEnd",
	"AdvFlyFlap",
	"FlyAdvFlyFlap",
	"DracHoverDracClawSwipeLeft",	--1640
	"FlyDracHoverDracClawSwipeLeft",
	"DracHoverDracClawSwipeRight",
	"FlyDracHoverDracClawSwipeRight",
	"DracHoverDracAttackWings",
	"FlyDracHoverDracAttackWings",	--1645
	"DracHoverReadySpellOmni",
	"FlyDracHoverReadySpellOmni",
	"DracHoverSpellCastOmni",
	"FlyDracHoverSpellCastOmni",
	"DracHoverChannelSpellOmni",	--1650
	"FlyDracHoverChannelSpellOmni",
	"DracHoverReadySpellDirected",
	"FlyDracHoverReadySpellDirected",
	"DracHoverChannelSpellDirected",
	"FlyDracHoverChannelSpellDirected",	--1655
	"DracHoverSpellCastDirected",
	"FlyDracHoverSpellCastDirected",
	"DracHoverCastOutStrong",
	"FlyDracHoverCastOutStrong",
	"DracHoverBattleRoar",				--1660
	"FlyDracHoverBattleRoar",
	"DracHoverEmpBreathSpellCast",
	"FlyDracHoverEmpBreathSpellCast",
	"DracHoverEmpBreathSpellCastChannel",
	"FlyDracHoverEmpBreathSpellCastChannel",	--1665
	"LivingWorldTimeOfDayEnter",
	"FlyLivingWorldTimeOfDayEnter",
	"LivingWorldTimeOfDayLoop",
	"FlyLivingWorldTimeOfDayLoop",
	"LivingWorldTimeOfDayLeave",		--1670
	"FlyLivingWorldTimeOfDayLeave",
	"LivingWorldWeatherEnter",
	"FlyLivingWorldWeatherEnter",
	"LivingWorldWeatherLoop",
	"FlyLivingWorldWeatherLoop",		--1675
	"LivingWorldWeatherLeave",
	"FlyLivingWorldWeatherLeave",
	"AdvFlyDownStart",
	"FlyAdvFlyDownStart",
	"AdvFlyFlapBig",					--1680
	"FlyAdvFlyFlapBig",
	"DracHoverReadyUnarmed",
	"FlyDracHoverReadyUnarmed",
	"DracHoverAttackUnarmed",
	"FlyDracHoverAttackUnarmed",		--1685
	"DracHoverParryUnarmed",
	"FlyDracHoverParryUnarmed",
	"DracHoverCombatWound",
	"FlyDracHoverCombatWound",
	"DracHoverCombatCritical",			--1690
	"FlyDracHoverCombatCritical",
	"DracHoverAttackTail",
	"FlyDracHoverAttackTail",
	"Glide",
	"FlyGlide",							--1695
	"GlideEnd",
	"FlyGlideEnd",
	"DracClawSwipe",
	"FlyDracClawSwipe",
	"DracHoverDracClawSwipe",			--1700
	"FlyDracHoverDracClawSwipe",
	"AdvFlyFlapUp",
	"FlyAdvFlyFlapUp",
	"AdvFlySlowFall",
	"FlyAdvFlySlowFall",				--1705
	"AdvFlyFlapFoward",
	"FlyAdvFlyFlapFoward",
	"DracSpellCastWings",
	"FlyDracSpellCastWings",
	"DracHoverDracSpellCastWings",		--1710
	"FlyDracHoverDracSpellCastWings",
	"DracAirDashVertical",
	"FlyDracAirDashVertical",
	"DracAirDashRefresh",
	"FlyDracAirDashRefresh",			--1715
	"SkinningLoop",
	"FlySkinningLoop",
	"SkinningStart",
	"FlySkinningStart",
	"SkinningEnd",						--1720
	"FlySkinningEnd",
	"AdvFlyForwardGlideSlow",
	"FlyAdvFlyForwardGlideSlow",
	"AdvFlyForwardGlideFast",
	"FlyAdvFlyForwardGlideFast",		--1725
	"AdvFlySecondFlapUp",
	"FlyAdvFlySecondFlapUp",
	"FloatIdle",
	"FlyFloatIdle",
	"FloatWalk",						--1730
	"FlyFloatWalk",
	"CinematicTalk",
	"FlyCinematicTalk",
	"CinematicWAGuardEmoteSlam01",
	"FlyCinematicWAGuardEmoteSlam01",	--1735
	"WABlowHorn",
	"FlyWABlowHorn",
	"Mount",
	nil,
	nil,	--1740
	nil,
	"HerbGathering",	--1742
	nil,
	"Cooking",	--1744
	nil,	--1745
	nil,
	nil,
	nil,
	nil,
	nil,	--1750
	nil,
	nil,
	nil,
	nil,
	nil,	--1755
	nil,
	nil,
	nil,
	nil,
	nil,	--1760
	nil,
	nil,
	nil,
	nil,
	nil,	--1765
	nil,
	nil,
	nil,
	nil,
	"Prowl",	--1770
	nil,
	"Shovel",	--1772
	nil,
	nil,
	nil,	--1775
	"Mount",	--1776

	[0] = "Stand",
};

local NUM_ANIMATIONS = #officialAnimationName;

local synonyms = {
	--key must be capitalized
	["Rifle"] = "gun crossbow",
	["Art"] = "artifact",
	["DH"] = "demon hunter",
	["Glv"] = "glaive",
	["Mag"] = "mage",
	["Sha"] = "shaman",
	["Pri"] = "priest",
	["Dru"] = "druid",
	["Loc"] = "warlock",
	["Pal"] = "paladin",
	["Thrown"] = "dart",
	["Read"] = "map book",
	["Flying"] = "monk",	--Flying Kick
	["Off"] = "offhand",
	["Sleep"] = "lie lying",
	["Use"] = "craft make",
	["Work"] = "smith mine mining",
	["Wave"] = "hello hi",
	["Hover"] = "float",
	["Server"] = "waitor waitress",
	["Tend"] = "bartender",
	["Offsense"] = "windwalker",
	["Defense"] = "brewmaster",
	["Heal"] = "mistweaver",
	["Parry"] = "doge",
	["Run"] = "sprint",
	["Mount"] = "ride",
	["Cat"] = "form",
	["Bear"] = "form",
	["Falconer"] = "hawk",
	["Death"] = "dead",
	["Pierce"] = "stab",
	["Roar"] = "yell",
}

local extraKeywords = {
	[0]    = "idle",
	[70]   = "lol",
	[82]   = "strong",
	[107]  = "wand",
	[108]  = "wand",
	[126]  = "rotate spin",
	[180]  = "swipe",	--tail swipe
	[185]  = "nod",
	[225]  = "fear frightened",
	[503]  = "carry",
	[730]  = "chi rotate spin",	--Chi Torpedo
	[1002] = "rotate spin",
	[1004] = "shadow strike",
	[1034] = "finishing",
	[1042] = "DH demon hunter",
	[1044] = "DH demon hunter",
	[1050] = "fly",
	[1104] = "death knight",
	[1134] = "block",
	[1202] = "bell",
	[1206] = "read",
	[1210] = "shoulder",
	[1212] = "shoulder",
	[1303] = "hold",
	[1324] = "hold",
	[1330] = "heart azeroth",
}

local colorizedName = {};

--Format Name
local colorsPatterns = {
	["Loc"] = "8787ed",		--Warlock
	["Mag"] = "40c7eb",		--Mage
	["Pri"] = "ffffff",		--Priest
	["Dru"] = "ff7d0a",		--Druid
	["Sha"] = "0070de",		--Shaman
	["Monk"]= "00ff96",		--Monk
	["Pal"] = "f58cba",		--Paladin
	["DH"]  = "a330c9",		--Demon Hunter
	["DK"]  = "C41F3B",		--Death Knight
	["Art"] = "e6cc80",		--Artifact
	["Emote"] = "ffd200",	--Emote
}

local function ColorizeString(str)
	for keyword, color in pairs(colorsPatterns) do
		if find(str, keyword.." ") then
			str = gsub(str, keyword, "|cff".. color .."%1" .. "|r");
			break
		end
	end
	return str
end

local function ConcatenateKeyword(str)
	local names = { split(str) };

	for i = 1, #names do
		if synonyms[ names[i] ] then
			return str .." ".. synonyms[ names[i] ]
		end
	end

	return str
end

---------------------------------
-----Process animation names-----
---------------------------------
for id, name in pairs(officialAnimationName) do
	name = gsub(name, "%u%l", " %1");
	name = gsub(name, "(%l)(%d)", "%1 %2");
	name = gsub(name, "(%u)(%d)", "%1 %2");
	name = trim(name);

	--Colorize
	colorizedName[id] = ColorizeString(name);
	
	--Concatenate Synonyms
	local names = { split(name) };
	for i = 1, #names do
		if synonyms[ names[i] ] then
			name = name .." ".. synonyms[ names[i] ];
			break
		end
	end
	officialAnimationName[id] = ConcatenateKeyword(name);
end

for id, keyword in pairs(extraKeywords) do
	officialAnimationName[id] = officialAnimationName[id] .." ".. keyword;
end


---------------------------------
local FavoriteAnimationIDs;
local IsFavorite = {};

function NarciAnimationInfo.GetOfficialName(id)
    return colorizedName[id] or "|cffff5050Undefined|r";
end

function NarciAnimationInfo.IsFavorite(id)
	return IsFavorite[id]
end

function NarciAnimationInfo.GetInfo(id)
	return colorizedName[id] or "|cffff5050Undefined|r", IsFavorite[id]
end

function NarciAnimationInfo.AddFavorite(id)
	IsFavorite[id] = true;
	FavoriteAnimationIDs[id] = true;
end

function NarciAnimationInfo.RemoveFavorite(id)
	IsFavorite[id] = nil;
	FavoriteAnimationIDs[id] = nil;
end

function NarciAnimationInfo.LoadFavorites()
    if not NarcissusDB then
        return 0;
    end

    NarcissusDB.Favorites = NarcissusDB.Favorites or {};
    NarcissusDB.Favorites.FavoriteAnimationIDs = NarcissusDB.Favorites.FavoriteAnimationIDs or {};
    FavoriteAnimationIDs = NarcissusDB.Favorites.FavoriteAnimationIDs;

    local sum = 0;
    for id, isFav in pairs(FavoriteAnimationIDs) do
        if isFav then
            IsFavorite[id] = true;
            sum = sum +1;
        end
    end

    return sum;
end

function NarciAnimationInfo.RemoveFromFavorites(IDsToBeDeleted)
    if not IDsToBeDeleted then return; end;

    local ShouldBeDeleted = {};
    local IDType = type(IDsToBeDeleted);
    if IDType == "number" then
        ShouldBeDeleted[ IDsToBeDeleted ] = true;
    elseif IDType == "table" then
        for i = 1, #IDsToBeDeleted do
            ShouldBeDeleted[ IDsToBeDeleted[i] ] = true;
        end
    end

    local numFavorites = 0;
    for id, v in pairs(FavoriteAnimationIDs) do
        if not ShouldBeDeleted[id] then
            numFavorites = numFavorites + 1;
        else
			IsFavorite[id] = nil;
			FavoriteAnimationIDs[id] = nil;
        end
    end
    
    return numFavorites, #IDsToBeDeleted
end


-----------------Construct Search Table-----------------
local textLocale = "enUS" --GetLocale();
local GetInitial;
local searchTable = {};
local sort = table.sort;

if textLocale == "zhCN" or textLocale == "zhTW" or textLocale == "koKR" then
    function GetInitial(str)
        return lower(sub(str, 1, 3))
    end
elseif textLocale == "ruRU" then
    function GetInitial(str)
        return lower(sub(str, 1, 2))
    end
else
    function GetInitial(str)
        return lower(sub(str, 1, 2))
    end 
end

local function DivideListByInitials()
    local find = string.find;

    local dividedName, initial;
    local names = {};

    local uniqueEntryTable = {};

    local function ShouldSkip(str)
        --Skip if including following words
		--if not str or find(str, "Fly ") or find(str, "FlyWA") then
		--	return true
		--else
		return false
		--end
    end

    for id, name in pairs(officialAnimationName) do
        if name then
            if not ShouldSkip(name) then
                names = { split(name) };
                for i = 1, #names do
                    dividedName = names[i];
					initial = GetInitial(dividedName);
					if initial then
						if not uniqueEntryTable[initial] then
							uniqueEntryTable[initial] = { [id] = true };
						else
							uniqueEntryTable[initial][id] = true;
						end
					end
                end
            end
        end
    end
    
    --print(numIgnored)
    --Flaten Search Table
    for initial, subTable in pairs(uniqueEntryTable) do
        searchTable[initial] = {};
        for id, _ in pairs(subTable) do
            tinsert(searchTable[initial], id)
        end
    end
end

DivideListByInitials();


function NarciAnimationInfo.SearchByName(str)
    if not str or str == "" or IsKeyDown("BACKSPACE") then return {}, 0 end

	--str = gsub(str, "^%s+", "");	--trim left	--Already processed from input

    local initial = GetInitial(str);
    local subTable = searchTable[initial];
	local model = Narci:GetActiveActor();

    if not subTable or not model then
        --print("Couldn't find any animation that begins with "..initial);
        return {}, 0
    end

    local find = find;
    local lower = lower;
	local tinsert = table.insert;
    local name, id;
    local nameTemp;
    local matchedIDs = {};
    local numMatches = 0;

    str = lower(str);
    local str2 = " "..str;
    --print("I: "..initial.."  Total: "..#subTable);

    for i = 1, #subTable do
		id = subTable[i];
		if id <= NUM_ANIMATIONS then
			name = officialAnimationName[id];
			if model:HasAnimation(id) then
				nameTemp = lower(name);
				if find(nameTemp, str, 1, true) or find(nameTemp, str2, 1, true) then
					tinsert(matchedIDs, {id, IsFavorite[id]} );
					numMatches = numMatches + 1;
				end
			end
		end
    end

    return matchedIDs, numMatches
end

--------------------------------------------------
local function SimplifyFavorites()
    local newList = {};
    local oldList = FavoriteAnimationIDs;
    local sum = 0;
    for id, isFav in pairs(oldList) do
        if isFav then
            newList[id] = true;
        end
    end
    NarcissusDB.Favorites.FavoriteAnimationIDs = newList;
end

local Initialize = CreateFrame("Frame")
Initialize:RegisterEvent("PLAYER_ENTERING_WORLD");
Initialize:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD");
		NarciAnimationInfo.LoadFavorites();
	end
end)