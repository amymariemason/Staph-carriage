/* Makes 4 sets of equilibruim data: */
/*1: never gain/ one spa/ multi spa vs. persistance (mult, non-persist absorbing) */
/*2: never gain/ one spa/ multi spa vs. persistance (no absorbing state)*/
/*3: no spa/transient/permanent*/
/*1: no spa/transient/permanent/permement+/permement ++*/

/* there are some problem double datapoints, need to get out of my set */

use "E:\users\amy.mason\Staph\DataWithCovariates.dta", clear
keep patid timepoint returndate
gsort patid -timepoint
duplicates tag patid returndate, gen(flag)
drop if flag==0
gsort patid returndate -timepoint
by patid returndate: drop if _n==1
keep patid timepoint
save "E:\users\amy.mason\Staph\problemswobs", replace


/*Set 1*/

use "E:\users\amy.mason\Staph\recordperspa.dta", clear
compress
destring State, replace

rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1

merge m:1 patid timepoint using "E:\users\amy.mason\Staph\problemswobs", update
drop if _merge==3
drop _merge

save "E:\users\amy.mason\Staph\recordperspa2", replace

sort patid2 timepoint
by patid2: drop if State[1]==0&State[2]==0
gen persistmarker =0
sort patid2 timepoint
by patid2: replace persistmarker=1 if State[_n-1]==0&  State[_n]==0 &_n>=2

gsort patid2 -persistmarker timepoint
 by patid2: drop if _n>1 & persistmarker[1]==1
 by patid2: drop if _n<_N & persistmarker[1]==0
 by patid2:assert _N==1
 
gsort patid persistmarker -timepoint
by patid: drop if _n >1

drop patid2 State value uniquetype
rename timepoint persisttime

save "E:\users\amy.mason\Staph\persistworking", replace

/* first randomness marker*/
use "E:\users\amy.mason\Staph\recordperspa.dta", clear
compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1

sort patid2 timepoint
gen notpersistmarker =0
*by patid2: replace notpersistmarker=1 if (State[_n-2]==1&  State[_n-1]==0 &State[_n]==0) &_n>=2
by patid2: replace notpersistmarker=1 if (State[_n-2]==0&  State[_n-1]==0 &State[_n]==1) &_n>=2

gsort patid2 -notpersistmarker timepoint
by patid2: drop if _n>1 & notpersistmarker[1]==1
by patid2: drop if _n<_N & notpersistmarker[1]==0
by patid2:assert _N==1
 
gsort patid -notpersistmarker timepoint
by patid: drop if _n >1

drop patid2 State value uniquetype
rename timepoint notpersisttime

merge 1:1 patid  using "E:\users\amy.mason\Staph\persistworking", update
rename _merge persistmerge
merge 1:m patid  using "E:\users\amy.mason\Staph\DataWithNewBurp2", update
drop _merge
/* split into types */


gen int Group=.
label variable Group "grouping for equilibrium graph"
label define Groupl 0 "never gain" 1 "one spa non-persistant"  2 "multi non-persistant" 3 "never lost &random"  4 "never lost & never random"
label values Group Groupl


/* by patient, count number of spatypes seen to date */
reshape long spatypeid, i(patid timepoint)
drop if spatypeid=="" & _j>1
sort patid spatypeid (timepoint)
by patid spatypeid: gen int newspa=_n==1
replace newspa=0 if spatypeid==""
sort patid timepoint
by patid: gen spa_sofar=sum(newspa)
gsort patid timepoint -spa_sofar
by patid timepoint: replace spa_sofar=spa_sofar[1]
drop newspa
reshape wide


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\PersistBurpOnly"
*this just drops those know to be incorrect from double results date records etc.
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2

assert _merge==3
drop _merge

merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\InitialBurpOnly"
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2

assert _merge==3
drop _merge



merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\NewBurpOnly"
rename BurpMax2time2 BurpInitMax
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2

assert _merge==3
drop _merge




/* pick out those who carry at most one spatype non-persistently */
/*  if patid has confirmed loss of all spatype: so max n_spatype = 1, negative two in a row */
gen lossmarker =0
sort patid timepoint
by patid: replace lossmarker=1 if n_spatypeid[_n-1]==.&  n_spatypeid[_n]==. &_n>=2
by patid: replace lossmarker=sum(lossmarker)

/* if patid has changed spatype, i.e. confirmed loss of persistance*/
gen changemarker =0
sort patid timepoint
by patid: replace changemarker=1 if PersistBurp[_n-1]>2&  PersistBurp[_n]>2 &_n>=2
by patid: replace changemarker=sum(changemarker)

/* if patid has randomness - spatype going in and out that are not initial spatype */
gen randommarker =0
sort patid timepoint
by patid: gen initspa= spa_sofar[2]
by patid: replace randommarker=1 if (n_spatypeid>initspa & n_spatypeid!=. &BurpPrev2>2) | (PersistBurp>2 & PersistBurp<1000) & _n>2
by patid: replace randommarker=sum(randommarker)





/* Persistant carriage, no randomness */
sort patid timepoint
replace Group=4 if lossmarker==0 & randommarker==0 & changemarker==0 & initspa>0

/*Persistant carriage, with randomness */


replace Group=3 if lossmarker==0 & randommarker>0 & changemarker==0 & initspa>0 



/*multi non-persistent*/
replace Group=2 if spa_sofar>1 & (lossmarker>=1| changemarker>=1)


/*Non-persistant carraige of one spa type*/

replace Group=1 if spa_sofar==1 & lossmarker>=1 
sort patid timepoint
gen BurpMaxSoFar = BurpInitMax
by patid: replace BurpMaxSoFar=max(BurpInitMax[1],BurpInitMax[_n],BurpMaxSoFar[_n-1])

by patid:replace Group=1 if lossmarker>=1 & BurpMaxSoFar<=2



/* never gained */
replace Group=0 if base2==1&spa_sofar==0



/* add last end of persistance and first gain of spa type markers)*/


order Group persistmarker persisttime notpersistmarker notpersisttime lossmarker changemarker randommarker
gen int Pmark=0 if persisttime==timepoint & persistmarker==0
replace Pmark=1 if persisttime==timepoint & persistmarker==1
gen int Rmark=0 if notpersisttime==timepoint & notpersistmarker==0
replace Rmark=1 if notpersisttime==timepoint & notpersistmarker==1
order Pmark Rmark

sort patid timepoint
by patid: replace Rmark=1 if Rmark[_n-1]==1
by patid: replace Pmark=1 if Pmark[_n-1]==1
/* alter based on Pmark/Rmark*/


replace Group=2 if Group==4 &Rmark==1&Pmark==1&InitialBurp>2

replace Group=3 if Group==4 &Rmark==1&InitialBurp>2
replace Group=1 if Group==4 &Pmark==1&InitialBurp>2

replace Group=2 if Group==3 &Pmark==1&InitialBurp>2

sort patid timepoint
by patid: replace Group=2 if Group[_n-1]==2

order patid timepoint
by patid: gen SwabNo=_n

save "E:\users\amy.mason\Staph\equilibDATA2", replace
saveold "E:\users\amy.mason\Staph\equilibDATA2", replace


/* ##############################################################*/
/*Data set2 add */

* loss = second of two negative results
*persistance = no losses in previous four swobs
* multiple = more than one spa >2 BURP apart  (matches to spa in previous two swobs excluded)
*return to never gained if 4 negative results in a row.

use "E:\users\amy.mason\Staph\recordperspa2.dta", clear
compress


sort patid2 timepoint
gen int PersistMarker=0
gen int LossMarker=0
by patid2: replace LossMarker=1 if State[_n-1]==0 &State[_n]==0 & _n>1
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0&LossMarker[_n-2]==0&LossMarker[_n-3]==0
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0&LossMarker[_n-2]==0 &_n<4
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0 & _n<3
by patid2: replace PersistMarker=1 if LossMarker[_n]==0 & _n<2

sort patid timepoint patid2
by patid timepoint: egen int Persist= max(PersistMarker)
by patid timepoint: egen int StateMarker= max(State)
keep patid timepoint Persist StateMarker
duplicates drop patid timepoint, force 
rename StateMarker State


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\PersistBurpOnly", update
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\InitialBurpOnly", update
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\NewBurpOnly", update
rename BurpMax2time2 BurpInitMax
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2
assert _merge==3
drop _merge

replace BurpPrev2=0.5 if BurpPrev2==1000 

gen MultMarker=0
bysort patid: replace MultMarker=1 if (BurpPrev2[_n]>2 |BurpPrev2[_n-1]>2 |BurpPrev2[_n-2]>2 |BurpPrev2[_n-3]>2) &_n>3
bysort patid: replace MultMarker=1 if (BurpPrev2[_n]>2 |BurpPrev2[_n-1]>2 |BurpPrev2[_n-2]>2) &_n>2

gen NeverGain=0
bysort patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0 &State[_n-2]==0&State[_n-3]==0) &_n>3
by patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0 &State[_n-2]==0) &_n==3
by patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0) &_n==2
by patid: replace NeverGain=1 if (State[_n]==0 &_n==1)

gen Groupt=.
label variable Groupt "grouping for equilibrium graph"
label define Grouptl 0 "never gain" 1 "one spa non-persistant"  2 "multi non-persistant" 3 "never lost &random"  4 "never lost & never random"
label values Groupt Groupl



by patid: replace Groupt=0 if NeverGain==1
by patid: replace Groupt=1 if Persist==0& MultMarker==0 &NeverGain==0
by patid: replace Groupt=2 if Persist==0 &MultMarker==1 &NeverGain==0
by patid: replace Groupt=3 if Persist==1 & MultMarker==1 &NeverGain==0
by patid: replace Groupt=4 if Persist==1 & MultMarker==0 & NeverGain==0

rename Groupt GroupTim
keep patid timepoint GroupTim


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\equilibDATA2", update
drop if _merge==1
drop _merge
save "E:\users\amy.mason\Staph\equilibDATA3", replace
saveold "E:\users\amy.mason\Staph\equilibDATA3", replace


/*############################################################################*/
/* Third set */



use "E:\users\amy.mason\Staph\recordperspa2.dta", clear
compress


sort patid2 timepoint
gen int PersistMarker=0
gen int LossMarker=0
by patid2: replace LossMarker=1 if State[_n+1]==0 &State[_n]==0 |State[_n-1]==0 &State[_n]==0
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0&LossMarker[_n-2]==0&LossMarker[_n-3]==0
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0&LossMarker[_n-2]==0 &_n<4
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0 & _n<3
by patid2: replace PersistMarker=1 if LossMarker[_n]==0 & _n<2

sort patid timepoint patid2
by patid timepoint: egen int Persist= max(PersistMarker)
by patid timepoint: egen int StateMarker= max(State)
keep patid timepoint Persist StateMarker
duplicates drop patid timepoint, force 
rename StateMarker State


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\PersistBurpOnly", update
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\InitialBurpOnly", update
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\NewBurpOnly", update
rename BurpMax2time2 BurpInitMax
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2
assert _merge==3
drop _merge

replace BurpPrev2=0.5 if BurpPrev2==1000 

gen NeverGain=0
bysort patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0 &State[_n-2]==0&State[_n-3]==0) &_n>3
by patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0 &State[_n-2]==0) &_n==3
by patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0) &_n==2
by patid: replace NeverGain=1 if (State[_n]==0 &_n==1)

gen Group2=.
label variable Group2 "grouping for equilibrium graph"
label define Group_l 0 "never gain" 1 "non-persistant"  2 "persistant" 
label values Group2 Group_l



by patid: replace Group2=0 if NeverGain==1
by patid: replace Group2=1 if Persist==0&NeverGain==0
by patid: replace Group2=2 if Persist==1 & NeverGain==0

rename Group2 GroupTimSimple

keep patid timepoint GroupTimSimple
 
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\equilibDATA3"
drop if _merge==1
assert _merge==3
drop _merge

save "E:\users\amy.mason\Staph\equilibDATA4", replace
saveold "E:\users\amy.mason\Staph\equilibDATA4", replace



/*############################################################################*/
/* Fourth set */

* loss = second of two negative results
*persistance = no losses in previous four swobs
*persistant2 = no losses in previous 8 swobs
*persistance3= no losses in previous 12 swobs
*return to never gained if 4 negative results in a row.



use "E:\users\amy.mason\Staph\recordperspa2.dta", clear
compress


sort patid2 timepoint
gen int PersistMarker=0
gen int PersistMarker2=0
gen int PersistMarker3=0
gen int LossMarker=0

by patid2: replace LossMarker=1 if State[_n+1]==0 &State[_n]==0 |State[_n-1]==0 &State[_n]==0
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0&LossMarker[_n-2]==0&LossMarker[_n-3]==0 &_n>=4

*by patid2: replace PersistMarker2=1 if PersistMarker==1 & LossMarker[_n-4]==0&LossMarker[_n-5]==0&LossMarker[_n-6]==0&LossMarker[_n-7]==0 & _n>=8
*by patid2: replace PersistMarker3=1 if PersistMarker2==1 & LossMarker[_n-8]==0&LossMarker[_n-9]==0&LossMarker[_n-10]==0&LossMarker[_n-11]==0 & _n>=11


by patid2: replace PersistMarker2=1 if PersistMarker==1 & LossMarker[_n-4]==0&LossMarker[_n-5]==0 & _n>=6
by patid2: replace PersistMarker3=1 if PersistMarker2==1 & LossMarker[_n-6]==0&LossMarker[_n-7]==0& _n>=8



sort patid timepoint patid2
by patid timepoint: egen int Persist= max(PersistMarker)
by patid timepoint: egen int Persist2= max(PersistMarker2)
by patid timepoint: egen int Persist3= max(PersistMarker3)
by patid timepoint: egen int StateMarker= max(State)
keep patid timepoint Persist Persist2 Persist3 StateMarker
duplicates drop patid timepoint, force 
rename StateMarker State

gen NeverGain=0
bysort patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0 &State[_n-2]==0&State[_n-3]==0) &_n>3
by patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0 &State[_n-2]==0) &_n==3
by patid: replace NeverGain=1 if (State[_n]==0 &State[_n-1]==0) &_n==2
by patid: replace NeverGain=1 if (State[_n]==0 &_n==1)

gen Group3=.
label variable Group3 "grouping for equilibrium graph"
label define Group_2 0 "never gain" 1 "non-persistant"  2 "persistant1" 3 "persistant2" 4 "persistant3" 
label values Group3 Group_2



by patid: replace Group3=0 if NeverGain==1
by patid: replace Group3=1 if Persist==0&NeverGain==0
by patid: replace Group3=2 if Persist==1 & NeverGain==0
by patid: replace Group3=3 if Persist2==1 & NeverGain==0
by patid: replace Group3=4 if Persist3==1 & NeverGain==0

rename Group3 GroupPersist

keep patid timepoint GroupPersist
 
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\equilibDATA4"
drop if _merge==1
assert _merge==3


save "E:\users\amy.mason\Staph\equilibDATA5", replace
saveold "E:\users\amy.mason\Staph\equilibDATA5", replace



/*
gen byte n=1
collapse (sum) n, by(timepoint GroupPersist)
reshape wide n, i(timepoint) j(GroupPersist)
for var n*: replace X=0 if X==.

egen total=rsum(n*)
gen p0=n0/total
gen p1=(n0+n1)/total
gen p2=(n0+n1+n2)/total
gen p3=(n0+n1+n2+n3)/total
gen p4=(n0+n1+n2+n3+n4)/total

twoway (rarea p4 p3 timepoint)(rarea p3 p2 timepoint)(rarea p2 p1 timepoint)(rarea p1 p0 timepoint)(area p0 timepoint),  legend( rows(3) order(1 "Persist >12" 2 "Persist >8" 3 "Persistant" 4 "Transient" 5 "Clear" ))


