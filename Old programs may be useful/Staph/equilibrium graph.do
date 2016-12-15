*****************
*CONCLUSIONS*

**********************

*there is a raw seasonality effect, but it mostly disappears when weight for initial pos/neg at intake
*why?
**********************

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear




/* count the pos/neg states */
keep patid timepoint base2 State
sort timepoint base2 State


by timepoint base2: gen int baseneg=_N if base2==1
by timepoint base2: gen int basepos=_N if base2==0
sort timepoint base2 State
by timepoint base2 State: gen int Statenegbasepos=_N if State==0 &base2==0
by timepoint base2 State: gen int Statenegbaseneg=_N if State==0 &base2==1
by timepoint base2 State: gen int Stateposbaseneg=_N if State==1 &base2==1
by timepoint base2 State: gen int Stateposbasepos=_N if State==1 &base2==0
drop patid

/* drop to one record per timepoint */
sort timepoint baseneg
by timepoint: replace baseneg=baseneg[1]
sort timepoint basepos
by timepoint: replace basepos=basepos[1]
sort timepoint Stateposbaseneg
by timepoint: replace Stateposbaseneg=Stateposbaseneg[1]
sort timepoint Statenegbaseneg
by timepoint: replace Statenegbaseneg=Statenegbaseneg[1]
sort timepoint Stateposbasepos
by timepoint: replace Stateposbasepos=Stateposbasepos[1]
sort timepoint Statenegbasepos
by timepoint: replace Statenegbasepos=Statenegbasepos[1]

/* remove missing values with zero*/
replace Statenegbasepos=0 if Statenegbasepos==.
replace Stateposbaseneg=0 if Stateposbaseneg==.

by timepoint: keep if _n==1

/*construct weighting based on initial sample */
gen int initpos=360
gen int initneg=1123-360
gen float weightpos= initpos/basepos
gen float weightneg= initneg/baseneg

/* find estimated numbers*/

gen float EstimNeg=weightneg*Statenegbaseneg+weightpos*Statenegbasepos
gen float EstimPos=weightneg*Stateposbaseneg+weightpos*Stateposbasepos

gen EstimPospc=EstimPos/1123*100
line EstimPospc timepoint

graph export E:\users\amy.mason\Staph\Graph_Attempt2\equilibrium.png, replace
******************************************************************
* equilibrium  of MRSA
******************************************************************

use "E:\users\amy.mason\Staph\DataWithNewBurp2", clear

/* count the pos/neg states */
keep patid timepoint base2 State result
gen MRSA=1 if result=="MRSA"
replace MRSA=0 if MRSA==.
sort timepoint base2 MRSA

by timepoint base2: gen int baseneg=_N if base2==1
by timepoint base2: gen int basepos=_N if base2==0


sort timepoint base2 MRSA
by timepoint base2 MRSA: gen int MRSAnegbasepos=_N if MRSA==0 &base2==0
by timepoint base2 MRSA: gen int MRSAnegbaseneg=_N if MRSA==0 &base2==1
by timepoint base2 MRSA: gen int MRSAposbaseneg=_N if MRSA==1 &base2==1
by timepoint base2 MRSA: gen int MRSAposbasepos=_N if MRSA==1 &base2==0
drop patid


/* drop to one record per timepoint */
sort timepoint baseneg
by timepoint: replace baseneg=baseneg[1]
sort timepoint basepos
by timepoint: replace basepos=basepos[1]
sort timepoint MRSAposbaseneg
by timepoint: replace MRSAposbaseneg=MRSAposbaseneg[1]
sort timepoint MRSAnegbaseneg
by timepoint: replace MRSAnegbaseneg=MRSAnegbaseneg[1]
sort timepoint MRSAposbasepos
by timepoint: replace MRSAposbasepos=MRSAposbasepos[1]
sort timepoint MRSAnegbasepos
by timepoint: replace MRSAnegbasepos=MRSAnegbasepos[1]

/* remove missing values with zero*/
replace MRSAnegbasepos=0 if MRSAnegbasepos==.
replace MRSAposbaseneg=0 if MRSAposbaseneg==.
replace MRSAnegbaseneg=0 if MRSAnegbaseneg==.
replace MRSAposbasepos=0 if MRSAposbasepos==.


by timepoint: keep if _n==1

/*construct weighting based on initial sample */
gen int initpos=360
gen int initneg=1123-360
gen float weightpos= initpos/basepos
gen float weightneg= initneg/baseneg

/* find estimated numbers*/

gen float EstimNeg=weightneg*MRSAnegbaseneg+weightpos*MRSAnegbasepos
gen float EstimPos=weightneg*MRSAposbaseneg+weightpos*MRSAposbasepos

gen EstimPospc=EstimPos/1123*100
line EstimPospc timepoint

graph export E:\users\amy.mason\Staph\Graph_Attempt2\equilibriumMRSA.png, replace
************************************
* seasonal problems

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear
gen bestmonth= month(BestDate)
gen bestyear= year(BestDate)


tab bestmonth State, expected chi2
gen DecProb= (bestmonth==12)
tab DecProb State, expected chi2
tab bestmonth degrade, expected chi2

tabstat State diff, by(bestmonth)
 graph bar (mean) State, over(bestmonth)
 
 
graph export E:\users\amy.mason\Staph\Graph_Attempt2\meanpos_bymonth.png, replace

 graph bar (mean) diff, over(bestmonth)
 
 
graph export E:\users\amy.mason\Staph\Graph_Attempt2\meandelay_bymonth.png, replace


* spatype over time

 *move long?
 
use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear
reshape long spatypeid, i(patid timepoint)
tab spatypeid
sort spatypeid
by spatypeid: gen spacount=_N
table spacount
replace spatypeid="negative" if spatypeid==""
gen spagraph= spatypeid
replace spagraph="other spa" if spacount<70
sort patid timepoint spatypeid
gsort patid timepoint -spatypeid
by patid timepoint: drop if spatypeid=="negative" & _n>1
tab spagraph
gen bestmonth= month(BestDate)
gen bestyear= year(BestDate)
drop if bestyear==2008
gen evdate_r = mdy(month(BestDate), 1, year(BestDate))
gen evdate_2 = mdy(round(month(BestDate),2), 1, year(BestDate))
gen evdate_3 = mdy(round(month(BestDate)+1,3), 1, year(BestDate))

merge m:1 spatypeid using "E:\users\amy.mason\Staph\CC.dta"

replace CC = spatypeid if _merge==1
drop if _merge==2

gen CCgroup = CC
replace CCgroup = "negative" if spatypeid=="negative"
sort CC
by CC: gen CCcount=_N
replace CCgroup = "otherspa" if CCcount <100
drop if spatype=="negative"

catplot spagraph, percent(bestyear) by(bestyear)
graph export E:\users\amy.mason\Staph\seasonality\spa_by_year.png, replace


catplot CCgroup, percent(bestyear) by(bestyear)
graph export E:\users\amy.mason\Staph\seasonality\CC_by_year.png, replace

catplot spagraph, percent(bestmonth) by(bestmonth)
graph export E:\users\amy.mason\Staph\seasonality\spa_by_month.png, replace


catplot CCgroup, percent(bestmonth) by(bestmonth)
graph export E:\users\amy.mason\Staph\seasonality\CC_by_month.png, replace



* move back to wide?????

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear
gen quarter = quarter(BestDate)
tab quarter State, chi2 expected
gen evdate_r = mdy(month(BestDate), 1, year(BestDate))
gen evdate_2 = mdy(round(month(BestDate),2), 1, year(BestDate))
gen evdate_3 = mdy(round(month(BestDate)+1,3), 1, year(BestDate))
gen bestmonth= month(BestDate)
gen bestyear= year(BestDate)
drop if bestyear==2008


*catplot State, percent(bestmonth) by(bestmonth)
*graph export E:\users\amy.mason\Staph\seasonality\pos_by_month.png, replace

*catplot State, percent(bestyear) by(bestyear)
*graph export E:\users\amy.mason\Staph\seasonality\pos_by_year.png, replace
* Tim says look at antibiotic use before this swab/ taking account of drops in number.
gen State2="positive" if State==1
replace State2="negative" if State==0 
*Antibiotic use
*catplot State2 patient_prev_anti_6mon, percent(bestmonth) by(bestmonth)  asyvars 
*graph export E:\users\amy.mason\Staph\seasonality\pos_by_month_anti.png, replace

*catplot State2 patient_prev_anti_swob, percent(bestmonth) by(bestmonth)  asyvars 
*graph export E:\users\amy.mason\Staph\seasonality\pos_by_month_anti6.png, replace


*merge with monthly weights (see below)

merge m:1 bestmonth using "E:\users\amy.mason\Staph\seasonality\intakeweights_month.dta", update keepusing(bestmonth weightpos weightneg)

gen weight= weightpos if base2==0
replace weight=weightneg if base2==1


catplot State2  [aweight=weight], percent(bestmonth) by(bestmonth)  asyvars 

********
*weight monthly/year by pos/neg at state



/* count the pos/neg states */

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear
keep patid BestDate base2 State
gen bestmonth= month(BestDate)
gen evdate_2 = mdy(round(month(BestDate),2), 1, year(BestDate))
sort bestmonth base2 State


by bestmonth base2: gen int baseneg=_N if base2==1
by bestmonth base2: gen int basepos=_N if base2==0
sort bestmonth base2 State
by bestmonth base2 State: gen int Statenegbasepos=_N if State==0 &base2==0
by bestmonth base2 State: gen int Statenegbaseneg=_N if State==0 &base2==1
by bestmonth base2 State: gen int Stateposbaseneg=_N if State==1 &base2==1
by bestmonth base2 State: gen int Stateposbasepos=_N if State==1 &base2==0
drop patid

/* drop to one record per month */
sort bestmonth baseneg
by bestmonth: replace baseneg=baseneg[1]
sort bestmonth basepos
by bestmonth: replace basepos=basepos[1]
sort bestmonth Stateposbaseneg
by bestmonth: replace Stateposbaseneg=Stateposbaseneg[1]
sort bestmonth Statenegbaseneg
by bestmonth: replace Statenegbaseneg=Statenegbaseneg[1]
sort bestmonth Stateposbasepos
by bestmonth: replace Stateposbasepos=Stateposbasepos[1]
sort bestmonth Statenegbasepos
by bestmonth: replace Statenegbasepos=Statenegbasepos[1]

/* remove missing values with zero*/
replace Statenegbasepos=0 if Statenegbasepos==.
replace Stateposbaseneg=0 if Stateposbaseneg==.

by bestmonth: keep if _n==1

/*construct weighting based on initial sample */
gen int initpos=360
gen int initneg=1123-360
gen float weightpos= initpos/basepos
gen float weightneg= initneg/baseneg

/* find estimated numbers*/

gen float EstimNeg=weightneg*Statenegbaseneg+weightpos*Statenegbasepos
gen float EstimPos=weightneg*Stateposbaseneg+weightpos*Stateposbasepos

gen EstimPospc=EstimPos/1123*100
line EstimPospc bestmonth, yscale(range(0 100)) ylabel(0(10)100)

graph export E:\users\amy.mason\Staph\seasonality\weightedstate_month.png, replace

save "E:\users\amy.mason\Staph\seasonality\intakeweights_month.dta", replace

/* count the pos/neg states by two months */

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear
keep patid BestDate base2 State
gen bestmonth= month(BestDate)
gen evdate_2 = mdy(round(month(BestDate),2), 1, year(BestDate))
sort evdate_2 base2 State


by evdate_2 base2: gen int baseneg=_N if base2==1
by evdate_2 base2: gen int basepos=_N if base2==0
sort evdate_2 base2 State
by evdate_2 base2 State: gen int Statenegbasepos=_N if State==0 &base2==0
by evdate_2 base2 State: gen int Statenegbaseneg=_N if State==0 &base2==1
by evdate_2 base2 State: gen int Stateposbaseneg=_N if State==1 &base2==1
by evdate_2 base2 State: gen int Stateposbasepos=_N if State==1 &base2==0
drop patid

/* drop to one record per month */
sort evdate_2 baseneg
by evdate_2: replace baseneg=baseneg[1]
sort evdate_2 basepos
by evdate_2: replace basepos=basepos[1]
sort evdate_2 Stateposbaseneg
by evdate_2: replace Stateposbaseneg=Stateposbaseneg[1]
sort evdate_2 Statenegbaseneg
by evdate_2: replace Statenegbaseneg=Statenegbaseneg[1]
sort evdate_2 Stateposbasepos
by evdate_2: replace Stateposbasepos=Stateposbasepos[1]
sort evdate_2 Statenegbasepos
by evdate_2: replace Statenegbasepos=Statenegbasepos[1]

/* remove missing values with zero*/
replace Statenegbasepos=0 if Statenegbasepos==.
replace Stateposbaseneg=0 if Stateposbaseneg==.

by evdate_2: keep if _n==1

/*construct weighting based on initial sample */
gen int initpos=360
gen int initneg=1123-360
gen float weightpos= initpos/basepos
gen float weightneg= initneg/baseneg


/* find estimated numbers*/

gen float EstimNeg=weightneg*Statenegbaseneg+weightpos*Statenegbasepos
gen float EstimPos=weightneg*Stateposbaseneg+weightpos*Stateposbasepos

gen EstimPospc=EstimPos/1123*100
line EstimPospc evdate_2, yscale(range(0 100)) ylabel(0(10)100)

graph export E:\users\amy.mason\Staph\seasonality\weightedstate_2month.png, replace



/* count the pos/neg states by year */

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear
keep patid BestDate base2 State
gen bestmonth= year(BestDate)
drop if bestmonth==2008
sort bestmonth base2 State


by bestmonth base2: gen int baseneg=_N if base2==1
by bestmonth base2: gen int basepos=_N if base2==0
sort bestmonth base2 State
by bestmonth base2 State: gen int Statenegbasepos=_N if State==0 &base2==0
by bestmonth base2 State: gen int Statenegbaseneg=_N if State==0 &base2==1
by bestmonth base2 State: gen int Stateposbaseneg=_N if State==1 &base2==1
by bestmonth base2 State: gen int Stateposbasepos=_N if State==1 &base2==0
drop patid

/* drop to one record per month */
sort bestmonth baseneg
by bestmonth: replace baseneg=baseneg[1]
sort bestmonth basepos
by bestmonth: replace basepos=basepos[1]
sort bestmonth Stateposbaseneg
by bestmonth: replace Stateposbaseneg=Stateposbaseneg[1]
sort bestmonth Statenegbaseneg
by bestmonth: replace Statenegbaseneg=Statenegbaseneg[1]
sort bestmonth Stateposbasepos
by bestmonth: replace Stateposbasepos=Stateposbasepos[1]
sort bestmonth Statenegbasepos
by bestmonth: replace Statenegbasepos=Statenegbasepos[1]

/* remove missing values with zero*/
replace Statenegbasepos=0 if Statenegbasepos==.
replace Stateposbaseneg=0 if Stateposbaseneg==.

by bestmonth: keep if _n==1

/*construct weighting based on initial sample */
gen int initpos=360
gen int initneg=1123-360
gen float weightpos= initpos/basepos
gen float weightneg= initneg/baseneg

/* find estimated numbers*/

gen float EstimNeg=weightneg*Statenegbaseneg+weightpos*Statenegbasepos
gen float EstimPos=weightneg*Stateposbaseneg+weightpos*Stateposbasepos

gen EstimPospc=EstimPos/1123*100
rename bestmonth bestyear
line EstimPospc bestyear, yscale(range(0 100)) ylabel(0(10)100)

graph export E:\users\amy.mason\Staph\seasonality\weightedstate_year.png, replace

save "E:\users\amy.mason\Staph\seasonality\intakeweights_year.dta", replace


******************************************************************
/* equilibrium graph 2 */
*******************************************************************
/* need a loss of persistance markers.*/

use "E:\users\amy.mason\Staph\recordperspa.dta", clear
compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1

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

/*add antibiotic data */ 

gen antiTaken =0
replace antiTaken= 1 if  anti_antibioticsform=="Antibiotics taken" | anti_antibibefore==1 | anti_antistaph==1
gen antiTakenprev4 = 0
sort patid timepoint
by patid : replace antiTakenprev4= 1 if (antiTaken[_n-1]==1 |antiTaken[_n-2]==1|antiTaken[_n-3]==1 |antiTaken[_n-4]==1) &_n>5
by patid : replace antiTakenprev4= 1 if antiTaken[_n-1]==1|antiTaken[_n-2]==1|antiTaken[_n-3]==1 & _n==4
by patid : replace antiTakenprev4= 1 if antiTaken[_n-1]==1|antiTaken[_n-2]==1 & _n==3
by patid : replace antiTakenprev4= 1 if antiTaken[_n-1]==1 & _n==2



by patid timepoint: replace antiTakenprev4= 1 if (antiTaken[_n-1]==1)

/* split into four types */
keep patid timepoint base2 State spatypeid1 spatypeid2 spatypeid3 spatypeid4 spatypeid5 n_spatypeid persisttime persistmarker persistmerge notpersisttime notpersistmarker



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
drop if inlist(patid,1101,1102,801,1401)==1

assert _merge==3
drop _merge

merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\InitialBurpOnly"
drop if inlist(patid,1101,1102,801,1401)==1

assert _merge==3
drop _merge



merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\NewBurpOnly"
rename BurpMax2time2 BurpInitMax
drop if inlist(patid,1101,1102,801,1401)==1

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

save "E:\users\amy.mason\Staph\equilibDATA", replace

saveold "E:\users\amy.mason\Staph\equilibDATA2", replace

/* make graph */
*********************look at percentage numbers
use "E:\users\amy.mason\Staph\equilibDATA", clear
gen byte n=1
collapse (sum) n, by(timepoint Group)
reshape wide n, i(timepoint) j(Group)
for var n*: replace X=0 if X==.

egen total=rsum(n*)
gen p0=n0/total
gen p1=(n0+n1)/total
gen p2=(n0+n1+n2)/total
gen p3=(n0+n1+n2+n3)/total
gen p4=(n0+n1+n2+n3+n4)/total

twoway (rarea p4 p3 timepoint) (rarea p3 p2 timepoint) (rarea p2 p1 timepoint)(rarea p1 p0 timepoint)(area p0 timepoint),  legend( rows(3) order(1 "Never lost &Never Random" 2 "Never lost & Random" 3 "multiple spa types, not persistant" 4 " one spa type, non persistant" 5 "never gained"))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\equilibrium2_correct.png, replace
******************** look at absolute numbers

gen t0=n0
gen t1=(n0+n1)
gen t2=(n0+n1+n2)
gen t3=(n0+n1+n2+n3)
gen t4=(n0+n1+n2+n3+n4)

twoway (rarea t4 t3 timepoint) (rarea t3 t2 timepoint) (rarea t2 t1 timepoint)(rarea t1 t0 timepoint)(area t0 timepoint),  legend( rows(3) order(1 "Never lost &Never Random" 2 "Never lost & Random" 3 "multiple spa types, not persistant" 4 " one spa type, non persistant" 5 "never gained"))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\equilibrium2_correctabs.png, replace

******** lok at 2-24 weeks only
twoway (rarea p4 p3 timepoint) (rarea p3 p2 timepoint) (rarea p2 p1 timepoint)(rarea p1 p0 timepoint)(area p0 timepoint) if timepoint<24&timepoint>2,  legend( order(1 "Never lost &Never Random" 2 "Never lost & Random" 3 "multiple spa types, not persistant" 4 " one spa type, non persistant" 5 "never gained"))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\equilibrium2_timerestricted.png, replace



********************************check identity of patients followed post 24 weeks


*************************************************************************
use "E:\users\amy.mason\Staph\DataWithNewBurp2", clear
sort patid timepoint
by patid: gen int final=timepoint[_N]

merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\equilibDATA"
keep if final>24
sort patid timepoint
by patid: gen at24=Group[_n] if timepoint==24
by patid: egen copy24=min(at24)
drop if copy24==4 |copy24==3| copy24==0

*************** nope gibberish!
****10, 334, 482 = mixed spatypes, no continous carriage
****21,44, 407  = clear post intake until t= 24, bu carried at start
****42, 301, 448 =  non-persistant carriage (double neg at 14/16, but picked up immediately again)
****50, 137, 416, 464, 471 = picks up continuous spa
****68,53,90, 107, 123 157, 160, 193, 305, 311, 354, 412, 472,484, 486, 786  = lose prior to t=24 and clear afterwards until post t=24
***123 = lose prior to t=24 and random  until post t=24



*********************************************************************************
*Equilibrium Mixing States
*********************************************************************************

******************************************************************
/* equilibrium graph 2 */
*******************************************************************
/* need a loss of persistance markers.*/

use "E:\users\amy.mason\Staph\recordperspa.dta", clear
compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1

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


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\PersistBurpOnly"
drop if inlist(patid,1101,1102,801,1401)==1
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\InitialBurpOnly"
drop if inlist(patid,1101,1102,801,1401)==1
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\NewBurpOnly"
rename BurpMax2time2 BurpInitMax
drop if inlist(patid,1101,1102,801,1401)==1
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

gen Group=.
label variable Group "grouping for equilibrium graph"
label define Groupl 0 "never gain" 1 "one spa non-persistant"  2 "multi non-persistant" 3 "never lost &random"  4 "never lost & never random"
label values Group Groupl



by patid: replace Group=0 if NeverGain==1
by patid: replace Group=1 if Persist==0& MultMarker==0 &NeverGain==0
by patid: replace Group=2 if Persist==0 &MultMarker==1 &NeverGain==0
by patid: replace Group=3 if Persist==1 & MultMarker==1 &NeverGain==0
by patid: replace Group=4 if Persist==1 & MultMarker==0 & NeverGain==0

rename Group GroupTim


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\equilibDATA"

order patid timepoint spa* Group*


order patid timepoint
by patid: gen SwabNo=_n

save "E:\users\amy.mason\Staph\equilibDATA_Tim", replace

saveold "E:\users\amy.mason\Staph\equilibDATA_Tim", replace


/* make graph */
*********************look at percentage numbers
use "E:\users\amy.mason\Staph\equilibDATA_Tim", clear
gen byte n=1
collapse (sum) n, by(timepoint GroupTim)
reshape wide n, i(timepoint) j(GroupTim)
for var n*: replace X=0 if X==.

egen total=rsum(n*)
gen p0=n0/total
gen p1=(n0+n1)/total
gen p2=(n0+n1+n2)/total
gen p3=(n0+n1+n2+n3)/total
gen p4=(n0+n1+n2+n3+n4)/total

twoway (rarea p4 p3 timepoint) (rarea p3 p2 timepoint) (rarea p2 p1 timepoint)(rarea p1 p0 timepoint)(area p0 timepoint),  legend( rows(3) order(1 "Never lost &Never Random" 2 "Never lost & Random" 3 "multiple spa types, not persistant" 4 " one spa type, non persistant" 5 "never gained"))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\Tim_equilibrium2_correct.png, replace
******************** look at absolute numbers

gen t0=n0
gen t1=(n0+n1)
gen t2=(n0+n1+n2)
gen t3=(n0+n1+n2+n3)
gen t4=(n0+n1+n2+n3+n4)

twoway (rarea t4 t3 timepoint) (rarea t3 t2 timepoint) (rarea t2 t1 timepoint)(rarea t1 t0 timepoint)(area t0 timepoint),  legend( rows(3) order(1 "Never lost &Never Random" 2 "Never lost & Random" 3 "multiple spa types, not persistant" 4 " one spa type, non persistant" 5 "never gained"))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\Tim_equilibrium2_correctabs.png, replace

******** lok at 2-24 weeks only
twoway (rarea p4 p3 timepoint) (rarea p3 p2 timepoint) (rarea p2 p1 timepoint)(rarea p1 p0 timepoint)(area p0 timepoint) if timepoint<24&timepoint>2,  legend( order(1 "Never lost &Never Random" 2 "Never lost & Random" 3 "multiple spa types, not persistant" 4 " one spa type, non persistant" 5 "never gained"))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\Tim_equilibrium2_timerestricted.png, replace

**********************************************************************************
 *Attempt 3: clear, persistant, transient only
***********************************************************************************


use "E:\users\amy.mason\Staph\recordperspa.dta", clear
compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1

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


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\PersistBurpOnly"
drop if inlist(patid,1101,1102,801,1401)==1
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\InitialBurpOnly"
drop if inlist(patid,1101,1102,801,1401)==1
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\NewBurpOnly"
rename BurpMax2time2 BurpInitMax
drop if inlist(patid,1101,1102,801,1401)==1
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

gen Group=.
label variable Group "grouping for equilibrium graph"
label define Groupl 0 "never gain" 1 "non-persistant"  2 "persistant - " 
label values Group Groupl



by patid: replace Group=0 if NeverGain==1
by patid: replace Group=1 if Persist==0&NeverGain==0
by patid: replace Group=2 if Persist==1 & NeverGain==0

rename Group GroupTimSimple


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\equilibDATA"

order patid timepoint spa* Group*


save "E:\users\amy.mason\Staph\equilibDATA_TimSimple", replace

saveold "E:\users\amy.mason\Staph\equilibDATA_TimSimple", replace


/* make graph */
*********************look at percentage numbers
use "E:\users\amy.mason\Staph\equilibDATA_TimSimple", clear
gen byte n=1
collapse (sum) n, by(timepoint GroupTimSimple)
reshape wide n, i(timepoint) j(GroupTimSimple)
for var n*: replace X=0 if X==.

egen total=rsum(n*)
gen p0=n0/total
gen p1=(n0+n1)/total
gen p2=(n0+n1+n2)/total

twoway (rarea p2 p1 timepoint)(rarea p1 p0 timepoint)(area p0 timepoint),  legend( rows(3) order(1 "Persistant" 2 "Transient" 3 "Clear" ))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\Tim_equilibriumSimple.png, replace
******************** look at absolute numbers

gen t0=n0
gen t1=(n0+n1)
gen t2=(n0+n1+n2)

twoway (rarea t2 t1 timepoint)(rarea t1 t0 timepoint)(area t0 timepoint),  legend( rows(3) order(1 "Persistant" 2 "Transient" 3 "Clear" ))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\Tim_equilibriumSimpleABS.png, replace

******** lok at 2-24 weeks only
twoway (rarea p2 p1 timepoint)(rarea p1 p0 timepoint)(area p0 timepoint) if timepoint<24&timepoint>2,  legend(order(1 "Persistant" 2 "Transient" 3 "Clear" ))

graph export E:\users\amy.mason\Staph\Graph_Attempt2\Tim_equilibriumSimple_restricted.png, replace



gen byte n=1
collapse (sum) n, by(timepoint GroupTim)
reshape wide n, i(timepoint) j(GroupTim)
for var n*: replace X=0 if X==.

egen total=rsum(n*)
gen p0=n0/total
gen p1=(n0+n1)/total
gen p2=(n0+n1+n2)/total
gen p3=(n0+n1+n2+n3)/total
gen p4=(n0+n1+n2+n3+n4)/total

twoway (rarea p4 p3 timepoint) (rarea p3 p2 timepoint) (rarea p2 p1 timepoint)(rarea p1 p0 timepoint)(area p0 timepoint),  legend( rows(3) order(1 "Never lost &Never Random" 2 "Never lost & Random" 3 "multiple spa types, not persistant" 4 " one spa type, non persistant" 5 "never gained"))
