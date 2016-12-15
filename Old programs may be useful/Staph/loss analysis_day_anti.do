*********************************************************************************
*Playing with all spa loss survival times and stmix
*********************************************************************************
use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear

/* initially just do first event, and all spa */

/* worry about the recruitment pos people first. Mark first time clear of all spa-types */

gen byte lossallevent=0
sort patid day_no
by patid: replace lossallevent=1 if State[_n-2]==1&State[_n]==0&State[_n-1]==0 
gen byte gainevent=0
by patid: replace gainevent=1 if State[_n]==1&State[_n-1]==0&State[_n-2]==0
by patid: replace gainevent=1 if State[_n]==1& _n==1
by patid: replace gainevent=1 if State[_n]+State[_n+1]>0 &_n==1
gen knownaquis=0 
by patid: replace knownaquis=1 if gainevent==1 & _n>2
by patid: replace knownaquis=1 if knownaquis[_n-1]==1

gen t0start=day_no if gainevent==1
replace t0start=t0start[_n-1] if t0start==.


sort patid t0start day_no
by patid t0start: gen dropmarker=1 if lossallevent[_n-1]==1
by patid t0start: replace dropmarker=1 if dropmarker[_n-1]==1
drop if dropmarker==1


/* split into multiple events */
sort patid day_no
gen runningtot=0
by patid: replace runningtot=1 if _n==1&gainevent==1
by patid:replace runningtot=runningtot[_n-1]+gainevent[_n] if _n>1
gen patid2=patid*10+runningtot

/* set as survival */
/*NOTE: not currently accurate as don't have correct aquisition time of second spa type)*/

stset day_no, id(patid2) failure(lossallevent) origin(t0start)

stcox base2 knownaquis, tvc(days_since_last_anti)

stcox base2  knownaquis, tvc(GP_days_last_anti)

stcox base2  knownaquis, tvc(patient_days_last_anti)

stcox degrade base2 knownaquis

*****
*mixture models : Nope, won't fint
*****

 stmix base2 knownaquis, dist(we) noinit


*******************
*by timepoint instead
********************

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear

/* initially just do first event, and all spa */

/* worry about the recruitment pos people first. Mark first time clear of all spa-types */

gen byte lossallevent=0
sort patid timepoint
by patid: replace lossallevent=1 if State[_n-2]==1&State[_n]==0&State[_n-1]==0 
gen byte gainevent=0
by patid: replace gainevent=1 if State[_n]==1&State[_n-1]==0&State[_n-2]==0
by patid: replace gainevent=1 if State[_n]==1& _n==1
by patid: replace gainevent=1 if State[_n]+State[_n+1]>0 &_n==1
gen knownaquis=0 
by patid: replace knownaquis=1 if gainevent==1 & _n>2
by patid: replace knownaquis=1 if knownaquis[_n-1]==1

order patid timepoint
by patid: gen SwabNo=_n
order patid BestDate
by patid: gen SwabOrder=_n
assert SwabNo==SwabOrder

label define base2 0 recruit_pos 1 recruit_neg
label define knownaquis 0 no 1 yes
label values base2 base2
label values knownaquis knownaquis

gen t0start=timepoint if gainevent==1
bysort patid: replace t0start=t0start[_n-1] if t0start==.

/* drop those who never gain */
drop if t0start==.

*drop records between two risk times (i.e. after one loss, but before next gain)

sort patid t0start timepoint
by patid t0start: gen dropmarker=1 if lossallevent[_n-1]==1
by patid t0start: replace dropmarker=1 if dropmarker[_n-1]==1
drop if dropmarker==1



/* split into multiple events */
sort patid timepoint
gen runningtot=0
by patid: replace runningtot=1 if _n==1&gainevent==1
by patid:replace runningtot=runningtot[_n-1]+gainevent[_n] if _n>1
gen patid2=patid*10+runningtot


/* drop "first record" for each patid*/

drop if t0start==timepoint

/* drop post 24 months */
drop if timepoint>24

/* set as survival */

stset timepoint, id(patid2) failure(lossallevent) origin(t0start)

stcox base2 knownaquis degrade days_since_last_anti

stcox base2  knownaquis degrade GP_days_last_anti

stcox base2  knownaquis degrade patient_days_last_anti

stcox base2  knownaquis degrade patient_days_last_anti GP_days_last_anti

stcox base2  knownaquis degrade patient_days_last_anti GP_days_last_anti days_since_last_anti

stcox base2  knownaquis degrade patient_days_last_anti  days_since_last_anti

/* or do I want just 6 mon indicator?*/

stcox base2 knownaquis degrade 
*LL= -1163.4646,  base2 sig
stcox base2 knownaquis degrade prev_anti_6mon
*LL= -1158.5215, all base2 sig
stcox base2  knownaquis degrade GP_prev_anti_6mon
*LL= -1159.0192, GP base2 sig
stcox base2  knownaquis degrade patient_prev_anti_6mon
*LL= -1154.93, patient base2 sig
stcox base2  knownaquis degrade patient_prev_anti_6mon GP_prev_anti_6mon
*LL= -1154.6806, patient base2 sig

stcox base2  knownaquis degrade patient_prev_anti_6mon GP_prev_anti_6mon prev_anti_6mon
*LL= -1154.2083, patient base2 sig
stcox base2  knownaquis degrade patient_prev_anti_6mon  prev_anti_6mon
*LL= -1154.9299, patient base2 sig

/* dropping non sig variables -> same results*/

********************************************************
*looking at significance of known vs. unknown on whole set

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear



/* initially just do first event, and all spa */

/* worry about the recruitment pos people first. Mark first time clear of all spa-types */

gen byte lossallevent=0
sort patid timepoint
by patid: replace lossallevent=1 if State[_n-2]==1&State[_n]==0&State[_n-1]==0 
gen byte gainevent=0
by patid: replace gainevent=1 if State[_n]==1&State[_n-1]==0&State[_n-2]==0
by patid: replace gainevent=1 if State[_n]==1& _n==1
by patid: replace gainevent=1 if State[_n]+State[_n+1]>0 &_n==1
gen knownaquis=0 
by patid: replace knownaquis=1 if gainevent==1 & _n>2
by patid: replace knownaquis=1 if knownaquis[_n-1]==1

order patid timepoint
by patid: gen SwabNo=_n
order patid BestDate
by patid: gen SwabOrder=_n
assert SwabNo==SwabOrder

label define base2 0 recruit_pos 1 recruit_neg
label define knownaquis 0 no 1 yes
label values base2 base2
label values knownaquis knownaquis

gen t0start=timepoint if gainevent==1
bysort patid: replace t0start=t0start[_n-1] if t0start==.

/* drop those who never gain */
drop if t0start==.

*drop records between two risk times (i.e. after one loss, but before next gain)

sort patid t0start timepoint
by patid t0start: gen dropmarker=1 if lossallevent[_n-1]==1
by patid t0start: replace dropmarker=1 if dropmarker[_n-1]==1
drop if dropmarker==1



/* split into multiple events */
sort patid timepoint
gen runningtot=0
by patid: replace runningtot=1 if _n==1&gainevent==1
by patid:replace runningtot=runningtot[_n-1]+gainevent[_n] if _n>1
gen patid2=patid*10+runningtot


/* drop "first record" for each patid*/

drop if t0start==timepoint

* compare base2 vs unknown


stset timepoint, id(patid2) failure(lossallevent) origin(t0start)

sort patid
by patid: gen byte Followed=(_t>24)


*stcox base2 knownaquis Followed 
/* so knownaquis gets significant when add extra length of data*/
gen x= base2*knownaquis

stcox base2 knownaquis x


stcox base2 knownaquis x Followed patient_prev_anti_6mon 


stcox base2 knownaquis x Followed patient_prev_anti_6mon baseline_ethnic baseline_age baseline_male baseline_iscurremp baseline_hcrelemp baseline_nomembers


