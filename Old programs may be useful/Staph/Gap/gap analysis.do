******
* assessing whether post 48 week swab are worth continuing after large gap in results
*****

cd "E:\users\amy.mason\Staph\Gap\"

* new swab results
import excel "E:\users\amy.mason\Staph\Gap\Spa-types_MixedBox56.xlsx", sheet("Sheet1") clear firstrow
replace  StrainIsolateID = subinstr( StrainIsolateID, "MixedBox56", "",.)
replace  StrainIsolateID = subinstr( StrainIsolateID, "_", "",.)
rename StrainIsolateID OurSwabID
split  OurSwabID, p("-")
rename OurSwabID1 patid
rename OurSwabID2 timepoint 
*keep patid timepoint SpatypeID
destring patid, replace
destring timepoint, replace
save new_spatypes, replace


**** match to known data

import excel "E:\users\amy.mason\Staph\Gap\Amy Gap Check Update.xlsx", sheet("Sheet1") firstrow clear
duplicates drop  OurSwabID Result, force
gen growth = 1 if spatype!=""
gsort -growth
duplicates drop  OurSwabID, force
merge 1:1  OurSwabID using new_spatypes
gen new= inlist(_merge, 2,3)
replace  FollowupMonth= timepoint if  FollowupMonth==.
replace  ParticipantID= patid if  ParticipantID==.
replace  spatype =  SpatypeID if spatype==""
replace  growth=1 if  spatype!=""
replace  growth=0 if  spatype==""
drop patid timepoint SpatypeID _merge
* get rid of duplicate swabs
drop if FollowupMonth==999
drop if strpos(Our, "-")==0
drop if Our=="100412-60" 

gen post48 = ( FollowupMonth>48)


* only look at the people we are still following after 48 weeks
bysort Part  : egen marker=total(post48)
drop if marker==0

* classify them by always keep, never gain, mixed

gen lossmarker =0
sort Part Foll
by Part: replace lossmarker=1 if spatype[_n]==""&  spatype[_n+1]=="" & spatype[_n-1]!="" &_n>=1 & _n <_N
gen lossmarkerpre = lossmarker if Foll <=48
replace lossmarker = 0 if Foll <=48
rename lossmarker lossmarkerpost
by Part: egen losspre=total(lossmarkerpre)
by Part: egen losspost=total(lossmarkerpost)

gen changemarker =0
sort Part Foll
by Part: replace changemarker=1 if spatype[_n-1]!=spatype & spatype[_n-1]!="" & spatype!="" &_n>=2
by Part: replace changemarker=1 if spatype[_n-2]!=spatype & spatype[_n-2]!="" & spatype!="" &_n>=2
gen changemarkerpre = changemarker if Foll <=48
replace changemarker = 0 if Foll <=48
rename changemarker changemarkerpost
by Part: egen changepre=total(changemarkerpre)
by Part: egen changepost=total(changemarkerpost)


gen gainmarker =0
sort Part Foll
by Part: replace gainmarker = 1 if spatype[_n-1]==""&  spatype[_n-2]=="" & spatype!="" & _n>2
gen gainmarkerpre = gainmarker if Foll <=48
replace gainmarker = 0 if Foll <=48
rename gainmarker gainmarkerpost
by Part: egen gainpre=total(gainmarkerpre)
by Part: egen gainpost=total(gainmarkerpost)

*** use loss/ no of spatypes to classify these?

sort Part Foll
by Part: gen keyloss = lossmarkerpost if Foll[_n-1]==48
by Part: gen keygain = gainmarkerpost if Foll[_n-1]==48
by Part: gen keychange = changemarkerpost if Foll[_n-1]==48
by Part: gen unconfirmedloss = 1 if Foll[_n-1]==48 & spatype[_n-1]!="" &spatype=="" & _n==_N


**** classify what people where like before break: no carriage, persistant, mixed

gen type=""
sort Part Foll
by Part: replace type="no carriage before 48" if spatype[1]=="" &spatype[2]=="" & gainpre==0

by Part: replace type="persistant carriage before 48" if (spatype[1]!="" |spatype[2]!="") & losspre==0 & changepre==0

replace type = "other" if type==""


*****

bysort type: tab keygain keychange, m
bysort type: tab keyloss unconfirmedloss, m
*****

/* Summary of staph carriage data:

64 people are followed past 48 weeks.


Of those: 23 have never carried, 13 have carried a single spa consistently, and 28 "other" do all sorts of wacky things.

Immediately after the gap post 48 weeks:

The 23 never carried still do not carry.

4/28 of the other type swap spatype. 6 has lost carriage over the gap. 1 has "unconfirmed loss" (has sent in only one swab since 48 weeks, which was negative)

2 of the persistent carriage people have lost carriage. 1 of the persistent carriers has "unconfirmed loss". All others (10/13) still carry the same spatype. */
