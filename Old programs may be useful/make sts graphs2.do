/* make survival time set for gain of first new staph carriage*/
use "E:\users\amy.mason\Staph\DataWithNewBurp2", clear
/* mark even if new infection at least two different from recruitment */
 gen byte event =(BurpStart>=2&BurpStart!=.)
 
 replace event =1 if (base2==1 & State==1 &timepoint>=2)
 
 /*drop to one record per patient */
 
 gsort patid -event timepoint
 by patid: drop if _n>1 & event[1]==1
 by patid: drop if _n<_N & event[1]==0
 by patid:assert _N==1
 
 /*alter records for patients who were seen only one */
 replace timepoint =0.1 if timepoint <=1 & event ==0
 
 /* create set */
 
 stset timepoint, fail(event) id(patid)
 
 assert _st==1
  /* LR test */

sts test base2
 
 /* tried to use stmix - not-concave error*/
 stmix, dist(ww) 
 **** or backup error
 stmix, dist(we)
 
 ****this works, but I don't understand why
  stmix, dist(ww) noinit
 
 *** adding in variables _>
 stmix baseline_male, dist(ww) noinit
***could not calculate numerical derivatives -- discontinuous region with missing values encountered

 /* make failure graphs */
#delimit ;
sts graph, by(base2) 
risktable(,fail order(1 "Recruitment Postive" 2 "Recruitment Negative")) 
title(log rank test p = 0.12,) fail ylabel(0 (0.1) 0.6, format(%3.1f) angle(0)) yscale(range(0,0.6)) ymtick(#6) xlabel(0 (6) 48)
ytitle("Proportion with a S. Aureus spa" "type not present at recruitment" " ") 
 legend( rows(2) order(1 "Recruitment Postive" "new spa differences >2 from recruitment" 2 "Recruitment Negative, and S.aureus"));
#delimit cr

graph export E:\users\amy.mason\Staph\Graph_Attempt2\spa_gain_recruit.png, replace

/*play with rates, split and stpm2*/

stsplit new1, at (6 24)
strate new1
strate base2
strate base2 new1, per(1000)

gen float exposure=_t-_t0
poisson event i.base2, exposure(exposure)
poisson event baseline_age, exposure(exposure)


stpm2, df(3) scale(hazard)
predict s0, surv
line s0 _t, sort connect (stepstair)

predict h0, hazard ci
line h0 _t, sort connect (d)
*twoway rline h0_lci h0_uci _t, sort  color(gs14) connect(d) ||
line h0 _t, sort ||line h0_lci h0_uci _t, sort 


stpm2 base2, df(3) scale(hazard)
predict hbase0 if base2==0, hazard ci
predict hbase1 if base2==1, hazard ci
line hbase0 hbase1 _t, sort connect (d)
graph export E:\users\amy.mason\Staph\Graph_Attempt2\spa_gain_recruit_hazardbase.png, replace


drop new1 exposure
stjoin

/* use two week differences instead */
/* make survival time set for gain of first new staph carriage*/
use "E:\users\amy.mason\Staph\DataWithNewBurp2", clear
/* mark even if new infection at least two different from previous 2 weeks */
 gen byte event =(BurpPrev>=2&BurpPrev!=.)
 
 replace event =1 if (base2==1 & State==1 &timepoint>=2)
 
 /*drop to one record per patient */
 
 gsort patid-event timepoint
 by patid: drop if _n>1 & event[1]==1
 by patid: drop if _n<_N & event[1]==0
 by patid:assert _N==1
 
 /*alter records for patients who were seen only one */
 replace timepoint =0.1 if timepoint <=1 & event ==0
 
 /* create set */
 
 stset timepoint, fail(event) id(patid)
 
 assert _st==1
 
 **************************************************************
 /* tried to use stmix - worked!*/
 stmix, dist(ww) 
 
 stmix, dist(ww) pmix(base2)
 ******* extract variables and graph rates ****
 
 ereturn list
mat B=e(b)
mat list B

 *** est p_mix when base2==0
nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]))

*** est p_mix when base2==1
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))

****** so pmix becomes 0.03 if base2==1 and 0.10 if base2==0

**** est  lambda1
nlcom exp(_b[ln_lambda1:_cons])

**** est  gamma1
  nlcom exp(_b[ln_gamma1:_cons])
 
 ***est lambda2
nlcom exp(_b[ln_lambda2:_cons])


**** est  gamma2
  nlcom exp(_b[ln_gamma2:_cons])

****graph these
#delimit ;
twoway   function exp(0), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-0.05*x^(4.56)), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-0.018*x^(2.97)), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\Graph_Attempt2\temp\temp.gph, replace
#delimit ;

twoway function exp(-0.0017*x^(1.04)), range (0 30) lcolor(white*0.5)  recast(area) fcolor(gs11*0.5) ylabel(0(0.2)1)
|| function exp(-0.013*x^(1.44)), range (0 30) lcolor(white*0.5)  recast(area) fcolor(white*0.5) ylabel(0(0.2)1)
|| function exp(-0.007*x^(1.25)), range(0 30) lcolor(black) legend(order(3 "Rate 2")) ylabel(0(0.2)1)
text(1 20 "p(rate1)=0.03 if base2=1 & 0.10 if base2=0");

#delimit cr

graph save E:\users\amy.mason\Staph\Graph_Attempt2\temp\temp2.gph, replace

#delimit ;
graph combine 
"E:\users\amy.mason\Staph\Graph_Attempt2\temp\temp.gph"
"E:\users\amy.mason\Staph\Graph_Attempt2\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4);
#delimit cr

graph export E:\users\amy.mason\Staph\Graph_Attempt2\rate_spa_gain_previous.png, replace


 

 ********************************************************
 
 
 
 /* LR test */

sts test base2
 
 /* make failure graphs */
#delimit ;
sts graph, by(base2) 
risktable(,fail order(1 "Recruitment Postive" 2 "Recruitment Negative")) 
title("log rank test p = 0.70",)  fail ylabel(0 (0.1) 0.6,format(%3.1f) angle(0)) yscale(range(0,0.6)) ymtick(#6) xlabel(0 (6) 48)
ytitle("Proportion with a S. Aureus spa" "type not present in previous 2 weeks" " ") 
 legend( rows(2) order(1 "Recruitment Postive" "new spa differences >2 from previous two weeks" 2 "Recruitment Negative, and S.aureus"));
#delimit cr

graph export E:\users\amy.mason\Staph\Graph_Attempt2\spa_gain_previous.png, replace





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
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithNewBurp2.dta"
assert _merge==3


/* reduce to records who were negative on first visit */
/* NOTE THIS THEN DOES INCLUDE SPA TYPES SEEN ON FIRST VISIT, LOST AND THEN GAINED AGAIN */
/* SHOULD I BE INSISTING ON NEG FOR FIRST TWO WEEKS (confirmed neg) for consistent definition*/
gsort patid2 timepoint
*by patid2: drop if value[1]!=""|value[2]!=""

/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte event2=0 if value!=""
by patid2: replace event2=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]==""
by patid2: drop if _n==_N & value[_n]=="" 

/*some patients gain and lose multiple times for the same spa type. Create multiple records?*/
order patid patid2 timepoint event2 value
sort patid2 timepoint
*drop if patid!=1248
gen int runningtotal=1
drop if event2==.
by patid2: replace runningtotal=runningtotal[_n-1]+event2[_n-1]  if _n>1


/* add t0 = first postive test */
gsort patid2 runningtotal timepoint 
by patid2 runningtotal: gen int t0start=timepoint[1]
drop if t0start==1 
drop if t0start==0 
by patid2 runningtotal: drop if _n>1 & event[1]==1
by patid2 runningtotal: drop if _n<_N & event[1]==0
by patid2 runningtotal: assert _N==1
gen patid3=patid2*10+runningtotal 


*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(event2) id(patid3) origin(t0start)
*LR test
sts test base2

***************************
*** stmix
 /* tried to use stmix - could not calculate numerical derivatives -- discontinuous region with missing values
encountered
 error*/
 stmix, dist(ww) 
 **** or could not calculate numerical derivatives -- discontinuous region with missing valuesencounterederror
 stmix, dist(we)
 
 ****this works, but I don't understand why
  stmix, dist(ww) noinit
 
 *** adding in variables _>
 stmix base2, dist(ww) noinit
***could not calculate numerical derivatives -- discontinuous region with missing values encountered
************************

*make graph
#delimit ;
sts graph, by(base2) 
risktable(,fail order(1 "Recruitment Postive" 2 "Recruitment Negative")) 
title("Confirmed loss of spa type" "aquired during the study" " ",) 
ytitle("Proportion still carrying S. aureus" " ") ylabel(,format(%3.1f) angle(0))
xtitle("Months since acquisition")
 legend( rows(2) order(1 "Recruitment Postive" 2 "Recruitment Negative"))
 text(1 20 "log rank test p=0.04");
#delimit cr

graph export E:\users\amy.mason\Staph\Graph_Attempt2\spa_loss.png, replace


/*play with rates, split and stpm2*/

stsplit new1, at (5 10 15)
strate new1
strate base2
strate base2 new1, per(1000)

gen float exposure=_t-_t0
poisson event i.base2, exposure(exposure)
poisson event baseline_age, exposure(exposure)
 drop exposure

stpm2, df(3) scale(hazard)
predict s0, surv
line s0 _t, sort connect (stepstair)

predict h0, hazard ci
line h0 _t, sort connect (d)
*twoway rline h0_lci h0_uci _t, sort  color(gs14) connect(d) ||
line h0 _t, sort ||rcap h0_lci h0_uci _t, sort 


stpm2 base2, df(3) scale(hazard)
predict hbase0 if base2==0, hazard ci
predict hbase1 if base2==1, hazard ci
line hbase0 hbase1 _t, sort connect (d)
graph export E:\users\amy.mason\Staph\Graph_Attempt2\spa_gain_recruit_hazardbase.png, replace


drop new1 
stjoin



/* get back all records, make survival set for loss of all spa type*/

use "E:\users\amy.mason\Staph\recordperspa.dta", clear

compress
destring State, replace
rename State spaState
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithNewBurp2.dta"
assert _merge==3

/* want to ensure that do not count spa type starting at 1, as no double neg before???*/

sort patid2 timepoint

by patid2: gen nval=spaState[1]+10*spaState[2]
by patid2: replace State=1 if _n==1 & nval==10
by patid2: replace spaState=1 if _n==1 & nval==10
by patid2: replace value=value[2] if  _n==1 & nval==10

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

/*WORKING want to keep either last time measured positive state, or first time measured neg as long as followed by neg result*/
 gsort patid2 timepoint
 gen confirmedloss=0
 by patid2: replace confirmedloss=1 if lossallevent[_n]==1&lossallevent[_n+1]==1
 gsort patid patid2-confirmedloss timepoint 
 by patid: drop if _n>1 &confirmedloss[1]==1 
 by patid: drop if _n==_N & confirmedloss[_n]==0
 by patid: drop if _n<_N &confirmedloss[1]==0
 by patid:assert _N==1
 
 
 /*okay, this gives us to complete loss, but not first spa loss*/
 
 
*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(confirmedloss) id(patid) origin(gain_t0)


***************************
*** stmix
 /* tried to use stmix - works!*/
 
 stmix, dist(ww) 



 
 *** adding in variables _>

 stmix , dist(ww) noinit pmix(base2) nohr
 ereturn list
mat B=e(b)
mat list B

 nlcom exp(_b[logit_p_mix:base2])
 *** est p_mix when base2==0
nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]))

*** est p_mix when base2==1
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))


*** put these constants into a graph

twoway function exp(-0.16*x^(1.43)), range(0 30) lcolor(black) || function exp(-0.22*x^(1.73)), range (0 30) lcolor(black) lpattern(dash) || function exp(-0.09*x^(1.12)), range (0 30) lcolor(black) lpattern(dash)|| function exp(-0.02*x^(0.99)), range(0 30) lcolor(green) || function exp(-0.04*x^(1.35)), range (0 30) lcolor(green) lpattern(dash) || function exp(0.01*x^(0.62)), range (0 30) lcolor(green) lpattern(dash)


*** shaded graph

twoway   function exp(0.01*x^(0.62)), range (0 30) lcolor(ltblue) lpattern(dash)recast(area) fcolor(ltblue)||function exp(-0.04*x^(1.35)), range (0 30) lcolor(ltblue) lpattern(dash) recast(area) fcolor(white)||function exp(-0.02*x^(0.99)), range(0 30) lcolor(edkblue)||function exp(-0.09*x^(1.12)), range (0 30) lcolor(black) lpattern(dash) recast(area) fcolor(gs11) || function exp(-0.22 *x^(1.73)), range (0 30) lcolor(black) lpattern(dash) recast(area) fcolor(white) || function exp(-0.16*x^(1.43)), range(0 30) lcolor(black)

graph export E:\users\amy.mason\Staph\Graph_Attempt2\rate_allspaloss.png, replace

********************************
*stmix on weibull-exponential insteal
stmix, dist(we) 
stmix, dist(we) pmix(base2) 

 *** est p_mix when base2==0
nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]))

*** est p_mix when base2==1
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))

****** so pmix becomes 0.16 if base2==1 and 0.67 if base2==0

**** est  lambda1
nlcom exp(_b[ln_lambda1:_cons])

**** est  gamma1
  nlcom exp(_b[ln_gamma1:_cons])
 
 ***est lambda2 if base 2==0
nlcom exp(_b[ln_lambda2:_cons])

****graph these
#delimit ;
twoway   function exp(-0.011*x), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-0.019*x), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-0.015*x), range(0 30) lcolor(edkblue)
||function exp(-0.09*x^(1.13)), range (0 30) lcolor(white)  recast(area) fcolor(gs11) 
|| function exp(-0.22*x^(1.71)), range (0 30) lcolor(white)  recast(area) fcolor(white) 
|| function exp(-0.16*x^(1.43)), range(0 30) lcolor(black) legend(order(3 "Rate 2" 6 "Rate 1")) 
text(1 20 "p(rate1)=0.16 if base2=1 & 0.67 if base2=0");

#delimit cr

graph export E:\users\amy.mason\Staph\Graph_Attempt2\rate_allspaloss_we.png, replace


****************************************************************
****IGNORE BELOW -Error bounds make prediction stupid
* this is a better fit - check to see if effects other variables still
stmix, dist(we) pmix(base2) lambda2(base2) 
**note: this is the only additional variable could get to converge. log-likelihood increased by adding this variable.  sketching graph under this model
 *** est p_mix when base2==0
nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]))

*** est p_mix when base2==1
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))

****** so pmix becomes 0.84 if base2==1 and 0.2 if base2==0

**** est  lambda1
nlcom exp(_b[ln_lambda1:_cons])

**** est  gamma1
  nlcom exp(_b[ln_gamma1:_cons])
 
 ***est lambda2 if base 2==0
nlcom exp(_b[ln_lambda2:_cons])
***est lambda2 if base 2==1
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])

  
*** use nlcom to fill in values here - first = upper bound, then lower, then actual.
***if base2==0
#delimit ;
twoway  function exp(0.007*x^(0.65)), range (0 30) lcolor(white)  recast(area) fcolor(gs11) 
|| function exp(-0.0366*x^(1.36)), range (0 30) lcolor(white)  recast(area) fcolor(white) 
|| function exp(-0.015*x^(1)), range(0 30) lcolor(black) legend(order(3 "Rate 1" 6 "Rate 2")) 
||  function exp(-0.059*x), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-0.66*x), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-0.36*x), range(0 30) lcolor(blue)
text(1 20 "p(rate1)= 0.2; base2=0");

#delimit cr
graph save E:\users\amy.mason\Staph\Graph_Attempt2\rate_allspaloss_lambdawe1.gph, replace


****** if base2==1
#delimit ;
twoway  function exp(0.007*x^(0.65)), range (0 30) lcolor(white)  recast(area) fcolor(gs11) 
|| function exp(-0.0366*x^(1.36)), range (0 30) lcolor(white)  recast(area) fcolor(white) 
|| function exp(-0.015*x^(1)), range(0 30) lcolor(black) legend(order(3 "Rate 1" 6 "Rate 2")) 
|| function exp(-0.11*x), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-0.24*x), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-0.17*x), range(0 30) lcolor(blue)
text(1 20 "p(rate1)=0.84; base2=1");

#delimit cr
graph save E:\users\amy.mason\Staph\Graph_Attempt2\rate_allspaloss_lambdawe2.gph, replace

#delimit ;
graph combine 
"E:\users\amy.mason\Staph\Graph_Attempt2\rate_allspaloss_lambdawe2.gph"
"E:\users\amy.mason\Staph\Graph_Attempt2\rate_allspaloss_lambdawe1.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4);
#delimit cr

graph export E:\users\amy.mason\Staph\Graph_Attempt2\rate_allspalosslambda.png, replace

*************************************





sts test base2
*make graph
#delimit ;
sts graph, by(base2) 
risktable(,fail order(1 "Recruitment Postive" 2 "Recruitment Negative")) 
title("Confirmed loss of all carriage" " ",) 
ytitle("Proportion still carrying S. aureus" " ") ylabel(,format(%3.1f) angle(0))
xtitle("Months since acquisition/recruitment")
 legend( rows(2) order(1 "Recruitment Postive" 2 "Recruitment Negative"))
 text(1 20 "log rank test p=0.0000");
#delimit cr

graph export E:\users\amy.mason\Staph\Graph_Attempt2\all_spa_loss.png, replace



/*same as above, but with additional line for loss of first spa type*/

use "E:\users\amy.mason\Staph\recordperspa.dta", clear

compress
destring State, replace
rename State spaState
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithNewBurp2.dta"
assert _merge==3

/* want to duplicate the positive recruitment set, and mark as third set of patients. We will give these a time to first confirmed spa loss */
 expand 2 if base2==0, generate(dupflag)
 replace base2=2 if dupflag==1
 replace patid=patid+3000 if base2==2
 replace patid2=patid2+30000 if base2==2


order patid patid2 timepoint State spaState

/* worry about the recruitment pos people first. Mark first time clear of all spa-types */

gen byte lossallevent=0
replace lossallevent=1 if base2==0 & State==0

/*sort out neg people */
gen runningtotal=0 
sort patid2 timepoint
by patid2: replace runningtotal=1 if State[1]==1 &base2!=2
by patid2: replace runningtotal=runningtotal[_n-1]+State[_n]  if _n>1 &base2!=2
drop if runningtotal==0 & base2!=2
/* note this means have dropped all people who are always neg, but that's fine cause they are never at risk for loss */
replace lossallevent=1 if base2==1 & State==0
sort patid timepoint
by patid: gen gain_t0=timepoint[1] if base2==1
by patid: replace gain_t0 =0 if base2==0
by patid: replace gain_t0=0 if base2==1 & gain_t0==1

/*WORKING want to keep either last time measured positive state, or first time measured neg as long as followed by neg result*/
 gsort patid2 timepoint
 gen confirmedloss=0
 by patid2: replace confirmedloss=1 if lossallevent[_n]==1&lossallevent[_n+1]==1 &base2!=2
 gsort patid patid2-confirmedloss timepoint 
 by patid: drop if _n>1 &confirmedloss[1]==1 & base2!=2
 by patid: drop if _n==_N & confirmedloss[_n]==0 & base2!=2
 by patid: drop if _n<_N &confirmedloss[1]==0 & base2!=2

 

/* now sort out the base2==2, i.e. duplicate of positive people */
gsort patid2 timepoint

/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte event2=0 if value!="" &base2==2
gsort patid2 timepoint
by patid2: drop if spaState[1]==0 & base2==2
by patid2: replace event2=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]=="" &base2==2
by patid2: drop if _n==_N & value[_n]=="" & base2==2

/*some patients gain and lose multiple times for the same spa type. Create multiple records?*/
order patid patid2 timepoint event2 value
sort patid2 timepoint
*drop if patid!=1248
drop if event2==.&base2==2
gen int runningtotal2=1 if base2==2 
sort patid2
by patid2: replace runningtotal2=runningtotal2[_n-1]+event2[_n-1]  if _n>1 & base2==2
drop if runningtotal2>1 &base2==2

/* add t0 = first postive test */
gsort patid2 timepoint 
by patid2: gen int t0start=timepoint[1] if base2==2
assert t0start==0 | t0start==.
by patid2: drop if _n>1 & event2[1]==1 & base2==2
by patid2: drop if _n<_N & event2[1]==0 & base2==2
sort patid timepoint
by patid: drop if _n>1 & base2==2
by patid:assert _N==1


 
 /*rename some shit to get all to same labels*/
 
 replace confirmedloss=event2 if base2==2
 replace gain_t0=t0start if base2==2
 replace timepoint=0.1 if timepoint==0
 
 
*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(confirmedloss) id(patid) origin(gain_t0)


sts test base2
*make graph
#delimit ;
sts graph, by(base2) 
risktable(,fail order(1 "Recruitment Postive" 2 "Recruitment Negative" 3 "Recruitment Postive (first spatype)")) 
title("Confirmed loss of all carriage" " ",) 
ytitle("Proportion still carrying S. aureus" " ") ylabel(,format(%3.1f) angle(0))
xtitle("Months since acquisition/recruitment") plot3opts(lpattern(-) lcolor(black))
 legend( rows(3) order(1 "Recruitment Postive" 2 "Recruitment Negative" 3 "Recruitment Postive (first spatype)"))
 text(1 20 "log rank test p=0.0000");
#delimit cr

graph export E:\users\amy.mason\Staph\Graph_Attempt2\all_spa_loss_extraline.png, replace


*******************************************************************************************
*Investigate whether can model each spatype loss as normal variation from a standard model
*******************************************************************************************
/* use one record per spatype*/

use "E:\users\amy.mason\Staph\recordperspa.dta", clear

compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithNewBurp2.dta"
assert _merge==3

/* find the most common "n" spatypes, list others as other */

sort value
by value: gen int valuemarker=_n if value!=""
gsort value -valuemarker
by value: replace valuemarker=valuemarker[1] if value!=""

gen str6 group= value
replace group="other" if valuemarker<40
gsort patid2 -group
by patid2: replace group=group[1]

/*mark losses, each spatype as seperate patient */

gsort patid2 timepoint

/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte event2=0 if value!=""
by patid2: replace event2=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]==""
by patid2: drop if _n==_N & value[_n]=="" 

/*some patients gain and lose multiple times for the same spa type. Create multiple records?*/
order patid patid2 timepoint event2 value
sort patid2 timepoint
*drop if patid!=1248
gen int runningtotal=1
drop if event2==.
by patid2: replace runningtotal=runningtotal[_n-1]+event2[_n-1]  if _n>1


/* add t0 = first postive test */
gsort patid2 runningtotal timepoint 
by patid2 runningtotal: gen int t0start=timepoint[1]
drop if t0start==1 
drop if t0start==0 
by patid2 runningtotal: drop if _n>1 & event[1]==1
by patid2 runningtotal: drop if _n<_N & event[1]==0
by patid2 runningtotal: assert _N==1
gen patid3=patid2*10+runningtotal 


*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(event2) id(patid3) origin(t0start)




/*model using group as covariate */
encode group, gen(groupno)
stpm2 i.groupno, df(1) scale(hazard)

stpm2 i.groupno, df(2) scale(hazard)
/* yikes - this doesn't seem to be working well - complaint about convergent and degrees of freedom?!?


/* comands to play with */

help gllamm
help xtpois
stsplit temp, at(2(2)28)
strate temp
replace temp=18 if temp<. & temp>=18
egen max=max(timepoint), by(patid)
gen byte followed=(max>24)

tab Group followed if timepoint==24, row



stpm2 i.groupno, knots(10) scale(hazard)

predict h0, hazard
line h0 _t, sort 

/* swap to long data */
 reshape long spatypeid, i(id) j(j)

gsort patid timepoint
gen byte event2==0
by patid: if n_spatypeid[1]==1 
