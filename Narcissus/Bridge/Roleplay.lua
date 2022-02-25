------------------------------------------------------------------
---------------------------MyRoleplay-----------------------------
------------------------------------------------------------------
--[[
Saved Variable: mrpSaved
Namespace:
    NA ~ Name       NI ~ Nickname       AG ~ Age        RA ~ Race       RC ~ Class      nameColour
    NT ~ Title      NH ~ House          RS ~ Relationship Status    *1 Single   2 Taken  3 Married  4 Divorced  5 Widowed
    eyeColour       AH ~ Height(cm)     AW ~ Weight(kg)
    CU ~ Currently
    HH ~ Home       HB ~ Birthplace
    MO ~ Motto
    DE ~ Description    HI ~ History
ProfileName = mrpSaved["SelectedProfile"]
Profile = mrpSaved["Profiles"][ProfileName]
-]]


------------------------------------------------------------------
---------------------------Total RP3------------------------------
------------------------------------------------------------------
--[[
API: TRP3_API.profile.getPlayerCurrentProfile().player
Namespace:
    FN ~ First Name      LN ~ Last Name      AG ~ Age      TI ~ Title      FI ~ Full Title      CL ~ Class
    HE ~ Height          WE ~ Body Shape     EC ~ Eye Color                EH ~ Eye Hue? *Hex   
    RE ~ Home            BP ~ Birthplace

    misc.PE["1","2",...]: AC ~ Bool     TI ~ Attribute Name     TX ~ Description    IC ~ Icon

    PS(Personality Trait)[1,2,...]:     ID      VA???     V2 ~ Weight(0~20)
--]]