#SpellEffect effectID 252 (TELEPORT_UNITS) or 50 (TRANS_DOOR)  --SpellID-->  ItemEffect  --ItemEffectID-->  ItemXItemEffect  -->  ItemID

import csv

dataSourcePath = 'G:\\Peter\\Narci UI\\Python\\Source\\'
outPutPath = 'G:\\Peter\\Narci UI\\Python\\Output\\'

sourceData1 = open(dataSourcePath + 'spelleffect.csv', encoding = 'UTF-8')
r_SpellEffect = csv.reader(sourceData1)

sourceData2 = open(dataSourcePath + 'itemeffect.csv', encoding = 'UTF-8')
r_ItemEffect = csv.reader(sourceData2)

sourceData3 = open(dataSourcePath + 'itemxitemeffect.csv', encoding = 'UTF-8')
r_ItemXEffectItem = csv.reader(sourceData3)


IsTeleSpell = {}
isfirstline = True
for row in r_SpellEffect:
    if isfirstline:
        isfirstline = False
    else:
        spellID = row[35]
        spellEffectID = row[4]
        if spellEffectID == "252" or spellEffectID == "50":
            IsTeleSpell[spellID] = spellEffectID


IsItemEffectTele = {}
isfirstline = True
for row in r_ItemEffect:
    if isfirstline:
        isfirstline = False
    else:
        itemEffectID = row[0]
        triggerType = row[2]
        spellID = row[7]

        if triggerType == "0" and IsTeleSpell.get(spellID):
            IsItemEffectTele[itemEffectID] = IsTeleSpell.get(spellID)


TeleItems = {}
isfirstline = True
for row in r_ItemXEffectItem:
    if isfirstline:
        isfirstline = False
    else:
        itemEffectID = row[1]
        itemID = row[2]

        if IsItemEffectTele.get(itemEffectID):
            spellEffectID =IsItemEffectTele.get(itemEffectID)
            if spellEffectID == "50":
                print(itemID)
            else:
                TeleItems[itemID] = True

totalItems = 0
for itemID, state in TeleItems.items():
    #print(itemID)
    totalItems += 1

print("teleport items: " + str(totalItems))


newData = open(outPutPath + 'TeleportationItems.lua','w',newline='', encoding = 'UTF-8')
w_Lua = csv.writer(newData)

w_Lua.writerow( ['local TeleItems_Generated = {'] )

for itemID, state in TeleItems.items():
    w_Lua.writerow( [itemID, None] )

w_Lua.writerow(['}'])