/* adds BURP distances to first recorded carriage (see R file) to set*/

use "E:\users\amy.mason\Staph\DataWithCovariates.dta", clear
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\DatawithBURP.dta"
drop if _merge==2
assert _merge==1 | _merge==3
/* all matched correctly */ 

save "E:\users\amy.mason\Staph\DatawithBURP2.dta", replace

 
 /* some follow_up_neg missing - fix with extra info on followupneg */
 gen byte prob=1 if (followupneg!=baseline_followupneg & followupneg!=.)
 replace baseline_followupneg = followupneg if (prob==1 & baseline_followupneg==.)
 drop prob
 gen byte prob=1 if (followupneg!=baseline_followupneg & followupneg!=.)
 assert prob==.
 
 drop _merge
save  "E:\users\amy.mason\Staph\DatawithBURP2.dta", replace

/* Start here unless have to rebuild BURP Set*/

use  "E:\users\amy.mason\Staph\DatawithBURP2.dta", clear
drop base2
gen byte base2=1
by patid: replace base2=0 if State[1]==1
* drop 1101 as unable to culture original sample, 801,1102 only 1/2 swabs returned, 1401 skin and soft tissue analysis dropped from main analysis
drop if inlist(patid,1101,1102,801,1401)==1
save  "E:\users\amy.mason\Staph\DatawithBURP3.dta", replace

/* make survival time set for gain of first new staph carriage*/
use "E:\users\amy.mason\Staph\DatawithBURP3.dta", clear
/* mark even if new infection at least two different from previous */
 gen byte event =(BurpSpaMax>2 & BurpSpaMax!=.)
 
 replace event =1 if (base2==1 & State==1)
 
 /*drop to one record per patient */
 
 gsort patid-event timepoint
 by patid: drop if _n>1 & event[1]==1
 by patid: drop if _n<_N & event[1]==0
 by patid:assert _N==1
 
 /*alter records for patients who were seen only one */
 replace timepoint =0.1 if timepoint <=0 & event ==0
 
 /* create set */
 
 stset timepoint, fail(event) id(patid)
 
 assert _st==1
 
 /* make failure graphs */
#delimit ;
sts graph, by(base2) 
risktable(,fail order(1 "Recruitment Postive" 2 "Recruitment Negative")) 
title(" ",) fail ylabel(0 (0.1) 0.6) yscale(range(0,0.6)) ymtick(#6) xlabel(0 (6) 48)
ytitle("Proportion with a S. Aureus spa" "type not present at recruitment" " ") 
 legend( rows(2) order(1 "Recruitment Postive" "new spa differences >2 from recruitment" 2 "Recruitment Negative, and S.aureus"));
#delimit cr

/* LR test */

sts test base2
#delimit ;
sts graph, by(base2) 
risktable(,fail order(1 "Recruitment Postive" 2 "Recruitment Negative")) 
title("log rank test p = 0.0007",) fail ylabel(0 (0.1) 0.6) yscale(range(0,0.6)) ymtick(#6)
ytitle("Proportion with a S. Aureus spa" "type not present at recruitment" " ") 
 legend( rows(2) order(1 "Recruitment Postive" "new spa differences >=2 from recruitment" 2 "Recruitment Negative, and S.aureus"));
#delimit cr


/* make survival data for time to first loss */
/*steal 1 record per patid-spa from R */
use "E:\users\amy.mason\Staph\recordperspa.dta", clear

compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DatawithBURP3.dta"
assert _merge==3


/* reduce to records who were negative on first visit */
gsort patid2 timepoint
by patid2: drop if value[1]!=""

/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte event2=0 if value!=""
by patid2: replace event2=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]==""
by patid2: drop if _n==_N & value[_n]=="" 

/*some patients gain and lose multiple times for the same spa type. Create multiple records?*/
order patid patid2 timepoint event2 value
sort patid2 timepoint
*drop if patid!=1248
*snapspan patid2 timepoint event2, generate(newt0) replace
gen int runningtotal=1
drop if event2==.
by patid2: replace runningtotal=runningtotal[_n-1]+event2[_n-1]  if _n>1


/* add t0 = first postive test */
gsort patid2 runningtotal timepoint 
by patid2 runningtotal: gen int t0start=timepoint[1]
by patid2 runningtotal: drop if _n>1 & event[1]==1
by patid2 runningtotal: drop if _n<_N & event[1]==0
by patid2 runningtotal: assert _N==1
gen patid3=patid2*10+runningtotal 


*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(event2) id(patid3) origin(t0start)
*make graph
#delimit ;
sts graph, by(base2) 
risktable(, order(1 "Recruitment Postive" 2 "Recruitment Negative")) 
title("Confirmed loss of spa type" "aquired during the study" " ",) 
ytitle("Proportion still carrying S. aureus" " ") 
xtitle("Months since acquisition")
 legend( rows(2) order(1 "Recruitment Postive" 2 "Recruitment Negative"))
 text(1 20 "log rank test p=0.02");
#delimit cr

sts test base2

/* get back all records, make survival set for loss of all spa type*/

use "E:\users\amy.mason\Staph\recordperspa.dta", clear

compress
destring State, replace
rename State spaState
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DatawithBURP2.dta"
assert _merge==3

order patid patid2 timepoint State spaState

/* worry about the recruitment pos people first. Mark first time clear of all spa-types */

gen byte lossallevent=0
replace lossallevent=1 if base2==0 & State==0

/*sort out neg people */
gen runningtotal=0 
sort patid2 timepoint
by patid2: replace runningtotal=1 if State[1]==1
by patid2: replace runningtotal=runningtotal[_n-1]+State[_n]  if _n>1
drop if runningtotal==0
/* note this means have dropped all people who are always neg, but that's fine cause they are never at risk for loss */
replace lossallevent=1 if base2==1 & State==0
sort patid timepoint
by patid: gen gain_t0=timepoint[1] if base2==1
by patid: replace gain_t0 =0 if base2==0

/*WORKING want to keep either last time measured positive state, or second tie measured neg after a positive state*/
 gsort patid2 timepoint
 gen confirmedloss=0
 by patid2: replace confirmedloss=1 if lossallevent[_n]==1&lossallevent[_n-1]==1
 gsort patid patid2-confirmedloss timepoint 
 by patid: drop if _n>1 &confirmedloss[1]==1 
 by patid: drop if _n==_N & confirmedloss[_n]==0
 by patid: drop if _n<_N &confirmedloss[1]==0
 by patid:assert _N==1
 
 
 /*okay, this gives us to complete loss, but not first spa loss*/
 
 
*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(confirmedloss) id(patid) origin(gain_t0)
*make graph
#delimit ;
sts graph, by(base2) 
risktable(, order(1 "Recruitment Postive" 2 "Recruitment Negative")) 
title("Confirmed loss of all carriage" " ",) 
ytitle("Proportion still carrying S. aureus" " ") 
xtitle("Months since acquisition/recruitment")
 legend( rows(2) order(1 "Recruitment Postive" 2 "Recruitment Negative"))
 text(1 20 "log rank test p=0.0000");
#delimit cr

sts test base2

/* combining graphs (side by side) */
sts graph if baseline_age < 55, by(base2) title("Young", box bfcolor(white)) saving("young", replace )
sts graph if baseline_age >= 55, by(base2) title("Old", box bfcolor(white)) saving("old", replace )
graph combine young.gph old.gph, rows(2) cols(2) iscale(0.5) title(Survival by Age Group)
 
 

/* swap to long data */
 reshape long spatypeid, i(id) j(j)

gsort patid timepoint
gen byte event2==0
by patid: if n_spatypeid[1]==1 
