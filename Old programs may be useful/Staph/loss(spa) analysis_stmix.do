
*looking at significance of known vs. unknown on whole set
 postutil clear
*********************************************************************************
*Playing with spa loss survival times and stmix
*********************************************************************************
/* make survival data for time to loss of single spa-type */

/* options: 1) time from known gain to loss (i.e. 1 record per spa seen gained, keep those with two neg only)*/
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
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithNewBurp2_v2.dta", update
/* merge problems are those who had double record problems in data creation: see Make Staph Data */
drop if _merge==1
assert _merge==3

rename baseline_age age
rename baseline_male male
gen anti6mon=  patient_prev_anti_6mon
gen antiprev= patient_prev_anti_swob
sort patid2 timepoint
replace n_spatypeid=0 if n_spatypeid==.
by patid2: gen spa_no_last= n_spatypeid[_n-1]


gsort patid2 timepoint

/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte lossevent=0 if value!=""
by patid2: replace lossevent=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]==""
by patid2: drop if _n==_N & value[_n]==""

gen byte gainevent=0
by patid2: replace gainevent=1 if  value[_n]!=""& value[_n-1]=="" &value[_n-2]=="" & _n>2

gen knownaquis=0 
replace knownaquis=1 if gainevent==1
by patid2: replace knownaquis=1 if knownaquis[_n-1]==1

label define base2 0 recruit_pos 1 recruit_neg
label define knownaquis 0 no 1 yes
label values base2 base2
label values knownaquis knownaquis

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
assert knownaquis==0 if inlist(t0start,0,1)
*drop if t0start==0 
gen patid3=patid2*10+runningtotal 
gsort patid3 -lossevent timepoint

by patid3: drop if _n>1 & lossevent[1]==1
by patid3: drop if _n<_N & lossevent[1]==0
by patid3: assert _N==1


*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(lossevent) id(patid3) origin(t0start)
drop if _st==0
stset timepoint, fail(lossevent) id(patid3) origin(t0start)


*stcox base2 knownaquis Followed 
/* so knownaquis gets significant when add extra length of data*/
gen x= base2*knownaquis

save "E:\users\amy.mason\Staph\stset_data(spa).dta", replace

******************
*mixture model
*****************
* try to make this systematic

use "E:\users\amy.mason\Staph\stset_data(spa).dta", clear

*******************
*too many to do individually; try capture?

************************************

gen str200 name=""
tempname sim
postfile sim int rc str200 name byte convergence int df float loglik using results, replace
****
	

	

foreach aaa in "" "knownaquis" "base2" "knownaquis base2" {
	foreach baa in "" "knownaquis" "base2" "knownaquis base2"{
		foreach caa in "" "knownaquis" "base2" "knownaquis base2"{
			foreach daa in "" "knownaquis" "base2" "knownaquis base2"{
				foreach eaa in "" "knownaquis" "base2" "knownaquis base2" {
					capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa') iterate(300) dist(ww)
					quietly replace name =" pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
									}
					capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa') dist(ww) iterate(300) noinit
					quietly replace name ="INIT pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name		
									}
					capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa') dist(ww) iterate(300) difficult
					quietly replace name ="DIFF pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
									}
					capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa') dist(ww) noinit iterate(300) difficult
					quietly replace name ="DIFF INIT pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name		
									}				
					else{
						post sim (_rc) (name) (.) (.) (.)
						display _rc		
									}
									}
	}
	}
	}
	}


postclose sim
use results, clear

gen AIC=2*df-2*loglik

save "E:\users\amy.mason\Staph\subset(spaloss)_mix_results2.dta", replace
* commented to prevent override of data by accident, as this takes 24 hours to run

***********************************************
*investigate results
use "E:\users\amy.mason\Staph\subset(spaloss)_mix_results.dta", clear
sort rc convergence AIC
plot AIC df if rc==0 & convergence==1
drop if rc!=0 | convergence!=1
sort AIC

* best is pmix(base2) lambda1() lambda2() gamma1(knownaquis) gamma2(knownaquis base2)
*so let's have a look at that



DIFF pmix() lambda1() lambda2(knownaquis base2) gamma1(knownaquis base2) gamma2(knownaquis base2)
DIFF pmix() lambda1(base2) lambda2(base2) gamma1(knownaquis base2) gamma2(knownaquis base2)
DIFF pmix() lambda1() lambda2() gamma1(knownaquis base2) gamma2(knownaquis)
pmix() lambda1() lambda2() gamma1(base2) gamma2(base2)
DIFF pmix() lambda1() lambda2() gamma1(base2) gamma2(base2)
pmix() lambda1() lambda2(base2) gamma1(base2) gamma2(base2)
DIFF pmix() lambda1() lambda2(base2) gamma1(base2) gamma2(base2)

use "E:\users\amy.mason\Staph\stset_data(spa).dta", replace

stmix, pmix() lambda1() lambda2(knownaquis) gamma1() gamma2(knownaquis) difficult dist(ww)
estimates store results
*extract variables
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])


*stupid values

use "E:\users\amy.mason\Staph\stset_data(spa).dta", replace

stmix, pmix(base2) lambda1() lambda2() gamma1(base2) gamma2(base2) dist(ww) iterate(100)
estimates store results
*extract variables
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda2:_cons])

* same problem 

*skip to sensible looking AIC values
use "E:\users\amy.mason\Staph\stset_data(spa).dta", replace

stmix, pmix(base2) lambda1() lambda2(knownaquis base2) gamma1(knownaquis) gamma2(knownaquis) difficult dist(ww) iterate(100)
estimates store results
*extract variables
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2]+_b[ln_lambda2:knownaquis])
*YES!!!!!!

*will not converge with interaction term

 *** est p_mix when base2==1 
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]))
 * attempt to get variables saved
mat pmix_b1_b = r(b) 
mat pmix_b1_V = r(V)
local pmix_b1 = pmix_b1_b[1,1]
local pmix_b1_upper = pmix_b1_b[1,1] + 1.96*sqrt(pmix_b1_V[1,1])
local pmix_b1_lower = pmix_b1_b[1,1] - 1.96*sqrt(pmix_b1_V[1,1])


*** est p_mix when base2==0 
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
mat pmix_b0_b = r(b) 
mat pmix_b0_V = r(V)
local pmix_b0 = pmix_b0_b[1,1]
local pmix_b0_upper = pmix_b0_b[1,1] + 1.96*sqrt(pmix_b0_V[1,1])
local pmix_b0_lower = pmix_b0_b[1,1] - 1.96*sqrt(pmix_b0_V[1,1])


******

 ***est lambda1

nlcom exp(_b[ln_lambda1:_cons])
mat lambda1_b = r(b) 
mat lambda1_V = r(V)
local lambda1 = lambda1_b[1,1]
local lambda1_upper = lambda1_b[1,1] + 1.96*sqrt(lambda1_V[1,1])
local lambda1_lower = lambda1_b[1,1] - 1.96*sqrt(lambda1_V[1,1]) 


**** est  lambda2
nlcom exp(_b[ln_lambda2:_cons])
mat lambda2_b0_k0_b = r(b) 
mat lambda2_b0_k0_V = r(V)
local lambda2_b0_k0 = lambda2_b0_k0_b[1,1]
local lambda2_b0_k0_upper = lambda2_b0_k0_b[1,1] + 1.96*sqrt(lambda2_b0_k0_V[1,1])
local lambda2_b0_k0_lower = lambda2_b0_k0_b[1,1] - 1.96*sqrt(lambda2_b0_k0_V[1,1])
* base2==1
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
mat lambda2_b1_k0_b = r(b) 
mat lambda2_b1_k0_V = r(V)
local lambda2_b1_k0 = lambda2_b1_k0_b[1,1]
local lambda2_b1_k0_upper = lambda2_b1_k0_b[1,1] + 1.96*sqrt(lambda2_b1_k0_V[1,1])
local lambda2_b1_k0_lower = lambda2_b1_k0_b[1,1] - 1.96*sqrt(lambda2_b1_k0_V[1,1])

*knownaquis=1
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
mat lambda2_b0_k1_b = r(b) 
mat lambda2_b0_k1_V = r(V)
local lambda2_b0_k1 = lambda2_b0_k1_b[1,1]
local lambda2_b0_k1_upper = lambda2_b0_k1_b[1,1] + 1.96*sqrt(lambda2_b0_k1_V[1,1])
local lambda2_b0_k1_lower = lambda2_b0_k1_b[1,1] - 1.96*sqrt(lambda2_b0_k1_V[1,1])

*base2, knownaquis=1
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2]+_b[ln_lambda2:knownaquis])
mat lambda2_b1_k1_b = r(b) 
mat lambda2_b1_k1_V = r(V)
local lambda2_b1_k1 = lambda2_b1_k1_b[1,1]
local lambda2_b1_k1_upper = lambda2_b1_k1_b[1,1] + 1.96*sqrt(lambda2_b1_k1_V[1,1])
local lambda2_b1_k1_lower = lambda2_b1_k1_b[1,1] - 1.96*sqrt(lambda2_b1_k1_V[1,1])


**** est  gamma1
 nlcom exp(_b[ln_gamma1:_cons])
 mat gamma1_k0_b = r(b) 
mat gamma1_k0_V = r(V)
local gamma1_k0 = gamma1_k0_b[1,1]
local gamma1_k0_upper = gamma1_k0_b[1,1] + 1.96*sqrt(gamma1_k0_V[1,1])
local gamma1_k0_lower = gamma1_k0_b[1,1] - 1.96*sqrt(gamma1_k0_V[1,1])

 nlcom exp(_b[ln_gamma1:_cons]+_b[ln_gamma1:knownaquis])
 mat gamma1_k1_b = r(b) 
mat gamma1_k1_V = r(V)
local gamma1_k1 = gamma1_k1_b[1,1]
local gamma1_k1_upper = gamma1_k1_b[1,1] + 1.96*sqrt(gamma1_k1_V[1,1])
local gamma1_k1_lower = gamma1_k1_b[1,1] - 1.96*sqrt(gamma1_k1_V[1,1])




**** est  gamma2
 nlcom exp(_b[ln_gamma2:_cons])
 mat gamma2_k0_b = r(b) 
mat gamma2_k0_V = r(V)
local gamma2_k0 = gamma2_k0_b[1,1]
local gamma2_k0_upper = gamma2_k0_b[1,1] + 1.96*sqrt(gamma2_k0_V[1,1])
local gamma2_k0_lower = gamma2_k0_b[1,1] - 1.96*sqrt(gamma2_k0_V[1,1])
*knownaquis=1
 nlcom exp(_b[ln_gamma2:_cons]+_b[ln_gamma1:knownaquis])
 mat gamma2_k1_b = r(b) 
mat gamma2_k1_V = r(V)
local gamma2_k1 = gamma2_k1_b[1,1]
local gamma2_k1_upper = gamma2_k1_b[1,1] + 1.96*sqrt(gamma2_k1_V[1,1])
local gamma2_k1_lower = gamma2_k1_b[1,1] - 1.96*sqrt(gamma2_k1_V[1,1])


****graph these
*null
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k0')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_b0_k0_lower'*x^`gamma2_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_b0_k0_upper'*x^(`gamma2_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2_b0_k0'*x^(`gamma2_k0')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note("pos at entry, unknown aquisition.  p(mix)=`pmix_b0'");

#delimit cr
graph save E:\users\amy.mason\Staph\stmixgraph\temp\spatemp1.gph, replace
graph export E:\users\amy.mason\Staph\stmixgraph\spa_nullpairNEW.png, replace




* base2 ==1
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k0')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_b1_k0_lower'*x^`gamma2_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_b1_k0_upper'*x^(`gamma2_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2_b1_k0'*x^(`gamma2_k0')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note("neg at entry, unknown aquisition.  p(mix)=`pmix_b1'");

#delimit cr
graph save E:\users\amy.mason\Staph\stmixgraph\temp\spatemp2.gph, replace
graph export E:\users\amy.mason\Staph\stmixgraph\spa_base2NEW.png, replace


*knownaquis ==1 
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k1')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_b0_k1_lower'*x^`gamma2_k1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_b0_k1_upper'*x^(`gamma2_k1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2_b0_k1'*x^(`gamma2_k1')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note("pos at entry, known aquisition.  p(mix)=`pmix_b0'");

#delimit cr
graph save E:\users\amy.mason\Staph\stmixgraph\temp\spatemp3.gph, replace
graph export E:\users\amy.mason\Staph\stmixgraph\spa_kaNEW.png, replace

*knownaquis ==1 & base2 ==1
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k1')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_b1_k1_lower'*x^`gamma2_k1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_b1_k1_upper'*x^(`gamma2_k1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2_b1_k1'*x^(`gamma2_k1')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note("neg at entry, known aquisition.  p(mix)=`pmix_b1'");

#delimit cr
graph save E:\users\amy.mason\Staph\stmixgraph\temp\spatemp4.gph, replace
graph export E:\users\amy.mason\Staph\stmixgraph\spa_base2kaNEW.png, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\spatemp1.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\spatemp2.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\spatemp3.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\spatemp4.gph",
row(2) col(2) graphregion(color(white)) xsize(7) ysize(4);
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\spatemp5.gph, replace
graph export E:\users\amy.mason\Staph\stmixgraph\spa_allNEW.png, replace

*********************************************************************
*would like to incorperate some other variables. look at individual effects

use "E:\users\amy.mason\Staph\stset_data(spa).dta", clear

*******************
*too many to do individually; try capture?

************************************
gen str200 name=""
tempname sim
postfile sim int rc str200 name byte convergence int df float loglik using results, replace
****
	
foreach aaa in "" "age" "male" "anti6mon" "antiprev" "spa_no_last" "degrade" {
	
					capture stmix, pmix(`aaa') iterate(100) dist(ww)
					quietly replace name =" pmix(`aaa') "
					if _rc==0&e(converged)==1{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
						}
					capture stmix, pmix(`aaa') dist(ww) iterate(100) difficult
					quietly replace name ="DIFF pmix(`aaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name		
									}
					else{
						post sim (_rc) (name) (.) (.) (.)
						display _rc		
									}
					capture stmix, lambda1(`aaa') iterate(100) dist(ww)
					quietly replace name ="lambda1(`aaa') "
					if _rc==0&e(converged)==1{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
						}
					capture stmix, lambda1(`aaa') dist(ww) iterate(100) difficult
					quietly replace name ="DIFF lambda1(`aaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name		
									}
					else{
						post sim (_rc) (name) (.) (.) (.)
						display _rc		
									}
									capture stmix, lambda2(`aaa') iterate(100) dist(ww)
					quietly replace name =" lambda2(`aaa') "
					if _rc==0&e(converged)==1{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
						}
					capture stmix, lambda2(`aaa') dist(ww) iterate(100) difficult
					quietly replace name ="DIFF lambda2(`aaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name		
									}
					else{
						post sim (_rc) (name) (.) (.) (.)
						display _rc		
									}
					capture stmix, gamma1(`aaa') iterate(100) dist(ww)
					quietly replace name =" gamma1(`aaa') "
					if _rc==0&e(converged)==1{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
						}
					capture stmix, gamma1(`aaa') dist(ww) iterate(100) difficult
					quietly replace name ="DIFF gamma1(`aaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name		
									}
					else{
						post sim (_rc) (name) (.) (.) (.)
						display _rc		
									}
					capture stmix, gamma2(`aaa') iterate(100) dist(ww)
					quietly replace name ="gamma2(`aaa') "
					if _rc==0&e(converged)==1{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
						}
					capture stmix, gamma2(`aaa') dist(ww) iterate(100) difficult
					quietly replace name ="DIFF gamma2(`aaa')"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name		
									}
					else{
						post sim (_rc) (name) (.) (.) (.)
						display _rc		
									}
									}
		



	
	
    

foreach aaa in "" "age" "male" "anti6mon" "antiprev" "spa_no_last" "degrade"  "age male" "age anti6mon" "age antiprev" "age spa_no_last" "age degrade" "male anti6mon" "male antiprev" "male spa_no_last" "male degrade" "anti6mon antiprev" "anti6mon spa_no_last" "anti6mon degrade""antiprev spa_no_last" "antiprev degrade" "spa_no_last degrade" {

	foreach baa in "" "age" "male" "anti6mon" "antiprev" "spa_no_last" "degrade"  "age male" "age anti6mon" "age antiprev" "age spa_no_last" "age degrade" "male anti6mon" "male antiprev" "male spa_no_last" "male degrade" "anti6mon antiprev" "anti6mon spa_no_last" "anti6mon degrade""antiprev spa_no_last" "antiprev degrade" "spa_no_last degrade" {

		foreach caa in "" "age" "male" "anti6mon" "antiprev" "spa_no_last" "degrade"  "age male" "age anti6mon" "age antiprev" "age spa_no_last" "age degrade" "male anti6mon" "male antiprev" "male spa_no_last" "male degrade" "anti6mon antiprev" "anti6mon spa_no_last" "anti6mon degrade""antiprev spa_no_last" "antiprev degrade" "spa_no_last degrade" {

			foreach daa in "" "age" "male" "anti6mon" "antiprev" "spa_no_last" "degrade"  "age male" "age anti6mon" "age antiprev" "age spa_no_last" "age degrade" "male anti6mon" "male antiprev" "male spa_no_last" "male degrade" "anti6mon antiprev" "anti6mon spa_no_last" "anti6mon degrade""antiprev spa_no_last" "antiprev degrade" "spa_no_last degrade" {

				foreach eaa in "" "age" "male" "anti6mon" "antiprev" "spa_no_last" "degrade"  "age male" "age anti6mon" "age antiprev" "age spa_no_last" "age degrade" "male anti6mon" "male antiprev" "male spa_no_last" "male degrade" "anti6mon antiprev" "anti6mon spa_no_last" "anti6mon degrade""antiprev spa_no_last" "antiprev degrade" "spa_no_last degrade" {

					capture stmix, pmix(`aaa' base2 knownaquis) lambda1(`baa' base2) lambda2(`caa') gamma1(`daa') gamma2(`eaa' base2) iterate(100) dist(ww)
					quietly replace name =" pmix(`aaa' base2 knownaquis) lambda1(`baa' base2) lambda2(`caa') gamma1(`daa') gamma2(`eaa' base2)"
					if _rc==0&e(converged)==1{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
						}
					capture stmix, pmix(`aaa' base2 knownaquis) lambda1(`baa' base2) lambda2(`caa') gamma1(`daa') gamma2(`eaa' base2) dist(ww) iterate(100) difficult
					quietly replace name ="DIFF pmix(`aaa' base2 knownaquis) lambda1(`baa' base2) lambda2(`caa') gamma1(`daa') gamma2(`eaa' base2)"
					if _rc==0{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name		
									}
					else{
						post sim (_rc) (name) (.) (.) (.)
						display _rc		
									}
									}
	}
	}
	}
	}


postclose sim
use results, clear

gen AIC=2*df-2*loglik

save "E:\users\amy.mason\Staph\subsetBIG(spaloss)_mix_results.dta", replace




***************** not working

*Try base2 and knownaquis as a single variable
use "E:\users\amy.mason\Staph\stset_data(spa).dta", clear
egen baseaquis = group(base2 knownaquis)
tabulate baseaquis, gen(start)
table baseaquis base2 knownaquis
rename start1 recruit_pos_no
rename start2 recruit_pos_yes
rename start3 recruit_neg_no
rename start4 recruit_neg_yes

stset timepoint if(recruit_neg_no!=1), fail(lossevent) id(patid3) origin(t0start)




**************** generic graph


*** est p_mix when base2==0 
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
mat pmix_b0_b = r(b) 
mat pmix_b0_V = r(V)
local pmix_b0 = pmix_b0_b[1,1]
local pmix_b0_upper = pmix_b0_b[1,1] + 1.96*sqrt(pmix_b0_V[1,1])
local pmix_b0_lower = pmix_b0_b[1,1] - 1.96*sqrt(pmix_b0_V[1,1])


******

 ***est lambda1

nlcom exp(_b[ln_lambda1:_cons])
mat lambda1_b = r(b) 
mat lambda1_V = r(V)
local lambda1 = lambda1_b[1,1]
local lambda1_upper = lambda1_b[1,1] + 1.96*sqrt(lambda1_V[1,1])
local lambda1_lower = lambda1_b[1,1] - 1.96*sqrt(lambda1_V[1,1]) 


**** est  lambda2
nlcom exp(_b[ln_lambda2:_cons])
mat lambda2_b0_k0_b = r(b) 
mat lambda2_b0_k0_V = r(V)
local lambda2_b0_k0 = lambda2_b0_k0_b[1,1]
local lambda2_b0_k0_upper = lambda2_b0_k0_b[1,1] + 1.96*sqrt(lambda2_b0_k0_V[1,1])
local lambda2_b0_k0_lower = lambda2_b0_k0_b[1,1] - 1.96*sqrt(lambda2_b0_k0_V[1,1])


**** est  gamma1
 nlcom exp(_b[ln_gamma1:_cons])
 mat gamma1_k0_b = r(b) 
mat gamma1_k0_V = r(V)
local gamma1_k0 = gamma1_k0_b[1,1]
local gamma1_k0_upper = gamma1_k0_b[1,1] + 1.96*sqrt(gamma1_k0_V[1,1])
local gamma1_k0_lower = gamma1_k0_b[1,1] - 1.96*sqrt(gamma1_k0_V[1,1])




**** est  gamma2
 nlcom exp(_b[ln_gamma2:_cons])
 mat gamma2_k0_b = r(b) 
mat gamma2_k0_V = r(V)
local gamma2_k0 = gamma2_k0_b[1,1]
local gamma2_k0_upper = gamma2_k0_b[1,1] + 1.96*sqrt(gamma2_k0_V[1,1])
local gamma2_k0_lower = gamma2_k0_b[1,1] - 1.96*sqrt(gamma2_k0_V[1,1])


****graph these
*null
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k0')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_b0_k0_lower'*x^`gamma2_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_b0_k0_upper'*x^(`gamma2_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2_b0_k0'*x^(`gamma2_k0')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note(" p(mix)=`pmix_b0'");

#delimit cr
graph save E:\users\amy.mason\Staph\stmixgraph\temp\emptyset.gph, replace
graph export E:\users\amy.mason\Staph\stmixgraph\emptyset.png, replace

