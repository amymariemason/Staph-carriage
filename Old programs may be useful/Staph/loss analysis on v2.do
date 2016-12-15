*********************************************************************************
*Playing with spa loss survival times and stmix
*********************************************************************************
/* make survival data for time to loss of single spa-type */

/* options: 1) time from known gain to loss (i.e. 1 record per spa seen gained, keep those with two neg only)*/
/*          2) time from known gain or study start to loss, adding known/unknown gain as covariate, and indicating left censoring - enter */

***** FIRST ONE******
/*steal 1 record per patid-spa from R */
use "E:\users\amy.mason\Staph\recordperspa.dta", clear

compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1
rename State spaState
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithNewBurp2_v2.dta", update
/* merge problems are those who had double record problems in data creation: see Make Staph Data */
drop if _merge==1
assert _merge==3




/* reduce to records who were negative on first visit */
/* NOTE THIS THEN DOES INCLUDE SPA TYPES SEEN ON FIRST VISIT, LOST AND THEN GAINED AGAIN */
/* SHOULD I BE INSISTING ON NEG FOR FIRST TWO WEEKS (confirmed neg) for consistent definition*/
gsort patid2 day_no
by patid2: drop if value[1]!=""|value[2]!=""

/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte event2=0 if value!=""
by patid2: replace event2=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]==""
by patid2: drop if _n==_N & value[_n]=="" 

/*some patients gain and lose multiple times for the same spa type. Create multiple records?*/
order patid patid2 timepoint event2 value
sort patid2 day_no
*drop if patid!=1248
gen int runningtotal=1
drop if event2==.
by patid2: replace runningtotal=runningtotal[_n-1]+event2[_n-1]  if _n>1

/*replacement timepoint */

sort patid day_no
by patid: gen swobno=_n-1

/* add t0 = first postive test */
gsort patid2 runningtotal day_no 
by patid2 runningtotal: gen int t0start=day_no[1]

by patid2 runningtotal: drop if _n>1 & event2[1]==1
by patid2 runningtotal: drop if _n<_N & event2[1]==0
by patid2 runningtotal: assert _N==1
gen patid3=patid2*10+runningtotal 


*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset day_no, fail(event2) id(patid3) origin(t0start)
/*assert _st==1 */
/* some _st==0 (ie. irrelevant data) as only single observation of postive before right censored */
*LR test
sts test base2
sts test degrade

***************************
*** stmix
 /* tried to use stmix - could not calculate numerical derivatives -- discontinuous region with missing values
encountered
 error*/
 stmix, dist(ww) 
 stmix, dist(we) noinit
 
 ****this works,
  stmix, dist(ww) noinit
 
ereturn list
mat B=e(b)
mat list B

*** est p_mix when base2==1
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))

****** so pmix is 

**** est  lambda1
nlcom exp(_b[ln_lambda1:_cons])

**** est  gamma1
  nlcom exp(_b[ln_gamma1:_cons])
 
 ***est lambda2 if base 2==0
nlcom exp(_b[ln_lambda2:_cons])

**** est  gamma2
  nlcom exp(_b[ln_gamma2:_cons])

/* doesn't make sense as a model - lambda 2~0, so makes second graph constantly 1???? */


 *** adding in variables _>
 stmix base2, dist(ww) noinit
***could not calculate numerical derivatives -- discontinuous region with missing values encountered
 stmix, dist(ww) noinit pmix(base2) /* nope */


************************
/* Try option 2 */

/*2)  time from known gain or study start to loss, adding known/unknown gain as covariate, and indicating left censoring - enter */

***** FIRST ONE******
/*steal 1 record per patid-spa from R */
use "E:\users\amy.mason\Staph\recordperspa.dta", clear

compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1
rename State spaState
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithNewBurp2.dta", update
/* merge problems are those who had double record problems in data creation: see Make Staph Data */
drop if _merge==1
assert _merge==3


/* add entry time for those needing left censoring */

/*Say that we have multiple-record data recording “came at risk” (mycode == 1), “enrolled in our study” (mycode == 2), and “failed due to risk” (mycode == 3). We stset this dataset by typing */
/* stset time, id(id) origin(mycode==1) enter(mycode==2) failure(mycode==3) */
gsort patid2 timepoint
by patid2: gen entrytime=timepoint[1] if value[1]!=""|value[2]!=""
gen unknown_start="known"
by patid2: replace unknown_start="unknown" if value[1]!=""|value[2]!=""

*************test from here
/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte lossevent=0 if value!=""
by patid2: replace lossevent=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]==""
by patid2: drop if _n==_N & value[_n]=="" 

/*some patients gain and lose multiple times for the same spa type. Create multiple records?*/
order patid patid2 timepoint lossevent value
sort patid2 timepoint
*drop if patid!=1248
gen int runningtotal=1
drop if lossevent==.
by patid2: replace runningtotal=runningtotal[_n-1]+lossevent[_n-1]  if _n>1


/* add t0 = first postive test */
gsort patid2 runningtotal timepoint 
by patid2 runningtotal: gen int t0start=timepoint[1]
*replace t0start=-100 if entrytime!=.
replace entrytime=t0start if entrytime==.
by patid2 runningtotal: drop if _n>1 & lossevent[1]==1
by patid2 runningtotal: drop if _n<_N & lossevent[1]==0
by patid2 runningtotal: assert _N==1
gen patid3=patid2*10+runningtotal 


*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(lossevent) id(patid3) origin(t0start) entry(entrytime)


*testing

sts test base2
sts test unknown_start

*both significant

 ****this doesn't works,
  stmix, dist(ww) noinit
  *** variables: still doesn't work
    stmix base2, dist(ww) noinit
	stmix, dist(ww) noinit pmix(base2)

	    stmix, dist(ww) noinit pmix(unknown_start) 	/* complains no data  - huh? */
		
gen alt = 1 if unknown_start=="known"
replace alt =1 if alt==.	
 stmix alt, dist(ww) noinit /* will run, but cannot find solution */

 stmix days_since_last_anti, dist(ww) noinit /* nope */
 
 ***********************************************************
 *All staph loss 
 ************************************************************
 /* since that is going nowhere, let's stop looking at individual spa types and look at loss instead
 
 