
*looking at significance of known vs. unknown on whole set
 postutil clear
use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear


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

save "E:\users\amy.mason\Staph\stset_data.dta", replace

******************
*mixture model
*****************
* try to make this systematic



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
					capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa') iterate(100) dist(ww)
					quietly replace name =" pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa')"
					if _rc==0&e(converged)==1{
						post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
						}
					capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa') dist(ww) iterate(100) difficult
					quietly replace name ="DIFF pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa')"
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
	}

postclose sim
use results, clear

gen AIC=2*df-2*loglik

*save "E:\users\amy.mason\Staph\subset_mix_results.dta", replace
* commented to prevent override of data by accident, as this takes 24 hours to run

***********************************************
*investigate results
use "E:\users\amy.mason\Staph\subset_mix_results.dta", clear
sort rc convergence AIC
plot AIC df if rc==0 & convergence==1
drop if rc!=0 | convergence!=1
sort AIC

* best is pmix(base2) lambda1() lambda2() gamma1(knownaquis) gamma2(knownaquis base2)
*so let's have a look at that


use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix, pmix(base2) lambda1() lambda2() gamma1(knownaquis) gamma2(knownaquis base2) dist(ww)
estimates store results
*extract variables

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

****** so pmix becomes 0.55 [0.34-0.67] if base2==1 and 0.9 if base2==0 [0.89-0.94]

**** est  lambda1
nlcom exp(_b[ln_lambda1:_cons])
mat lambda1_b = r(b) 
mat lambda1_V = r(V)
local lambda1 = lambda1_b[1,1]
local lambda1_upper = lambda1_b[1,1] + 1.96*sqrt(lambda1_V[1,1])
local lambda1_lower = lambda1_b[1,1] - 1.96*sqrt(lambda1_V[1,1])


**** est  gamma1
*if knownaquis==1
  nlcom exp(_b[ln_gamma1:_cons]+_b[ln_gamma1:knownaquis])
mat gamma1_k1_b = r(b) 
mat gamma1_k1_V = r(V)
local gamma1_k1 = gamma1_k1_b[1,1]
local gamma1_k1_upper = gamma1_k1_b[1,1] + 1.96*sqrt(gamma1_k1_V[1,1])
local gamma1_k1_lower = gamma1_k1_b[1,1] - 1.96*sqrt(gamma1_k1_V[1,1])


 *if knownaquis==0
 nlcom exp(_b[ln_gamma1:_cons])
 mat gamma1_k0_b = r(b) 
mat gamma1_k0_V = r(V)
local gamma1_k0 = gamma1_k0_b[1,1]
local gamma1_k0_upper = gamma1_k0_b[1,1] + 1.96*sqrt(gamma1_k0_V[1,1])
local gamma1_k0_lower = gamma1_k0_b[1,1] - 1.96*sqrt(gamma1_k0_V[1,1])


 
 ***est lambda2
 * NOTE: this is a problem, as it crosses the boundary
nlcom exp(_b[ln_lambda2:_cons])
mat lambda2_b = r(b) 
mat lambda2_V = r(V)
local lambda2 = lambda2_b[1,1]
local lambda2_upper = lambda2_b[1,1] + 1.96*sqrt(lambda2_V[1,1])
local lambda2_lower = 0 /*lambda2_b[1,1] - 1.96*sqrt(lambda2_V[1,1]) */


**** est  gamma2
*base2==0, knownaquis==0
  nlcom exp(_b[ln_gamma2:_cons])
mat gamma2_b0_k0_b = r(b) 
mat gamma2_b0_k0_V = r(V)
local gamma2_b0_k0 = gamma2_b0_k0_b[1,1]
local gamma2_b0_k0_upper = gamma2_b0_k0_b[1,1] + 1.96*sqrt(gamma2_b0_k0_V[1,1])
local gamma2_b0_k0_lower = gamma2_b0_k0_b[1,1] - 1.96*sqrt(gamma2_b0_k0_V[1,1])


 *knownaquis==1 &base2==0 
  nlcom exp(_b[ln_gamma2:_cons]+_b[ln_gamma2:knownaquis])
mat gamma2_b0_k1_b = r(b) 
mat gamma2_b0_k1_V = r(V)
local gamma2_b0_k1 = gamma2_b0_k1_b[1,1]
local gamma2_b0_k1_upper = gamma2_b0_k1_b[1,1] + 1.96*sqrt(gamma2_b0_k1_V[1,1])
local gamma2_b0_k1_lower = gamma2_b0_k1_b[1,1] - 1.96*sqrt(gamma2_b0_k1_V[1,1])

*base2==1 &knownaquis==0
  nlcom exp(_b[ln_gamma2:_cons]+_b[ln_gamma2:base2])
mat gamma2_b1_k0_b = r(b) 
mat gamma2_b1_k0_V = r(V)
local gamma2_b1_k0 = gamma2_b1_k0_b[1,1]
local gamma2_b1_k0_upper = gamma2_b1_k0_b[1,1] + 1.96*sqrt(gamma2_b1_k0_V[1,1])
local gamma2_b1_k0_lower = gamma2_b1_k0_b[1,1] - 1.96*sqrt(gamma2_b1_k0_V[1,1])

*base2==1 & knownaquis==1
  nlcom exp(_b[ln_gamma2:_cons]+_b[ln_gamma2:knownaquis] + _b[ln_gamma2:base2])
mat gamma2_b1_k1_b = r(b) 
mat gamma2_b1_k1_V = r(V)
local gamma2_b1_k1 = gamma2_b1_k1_b[1,1]
local gamma2_b1_k1_upper = gamma2_b1_k1_b[1,1] + 1.96*sqrt(gamma2_b1_k1_V[1,1])
local gamma2_b1_k1_lower = gamma2_b1_k1_b[1,1] - 1.96*sqrt(gamma2_b1_k1_V[1,1])


****graph these
*null
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k0')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_lower'*x^`gamma2_b0_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_upper'*x^(`gamma2_b0_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2'*x^(`gamma2_b0_k0')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1)
text(1 20 "pos at entry, unknown aquisition.  p(mix)=`pmix_b0'");

#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4);
#delimit cr

graph export E:\users\amy.mason\Staph\stmixgraph\nullpair.png, replace



* knownaquis==1
  
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k1')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_lower'*x^`gamma2_b0_k1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_upper'*x^(`gamma2_b0_k1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2'*x^(`gamma2_b0_k1')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1)
text(1 20 "pos at entry, known aquisition.  p(mix)=`pmix_b0'");

#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4);
#delimit cr

graph export E:\users\amy.mason\Staph\stmixgraph\knownaquis.png, replace



* base2 ==1
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k0')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_lower'*x^`gamma2_b1_k0_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_upper'*x^(`gamma2_b1_k0_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2'*x^(`gamma2_b1_k0')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1)
text(1 20 "neg at entry, unknown aquisition.  p(mix)=`pmix_b1'");

#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4);
#delimit cr

graph export E:\users\amy.mason\Staph\stmixgraph\base2.png, replace


* base2& knownsaquis==1
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_k1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_k1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1_k1')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_lower'*x^`gamma2_b1_k1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_upper'*x^(`gamma2_b1_k1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2'*x^(`gamma2_b1_k1')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1)
text(1 20 "neg at entry, known aquisition.  p(mix)=`pmix_b1'");

#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4);
#delimit cr

graph export E:\users\amy.mason\Staph\stmixgraph\base2knownaquis.png, replace


/* SO the problem here is lambda2 is taking silly values, so what other models had particularly low results 
Two others worth considering:
name
Model 2: pmix(knownaquis) lambda1() lambda2(knownaquis) gamma1(knownaquis base2) gamma2(knownaquis base2)
Model 3: pmix(knownaquis base2) lambda1() lambda2(base2) gamma1(base2) gamma2(knownaquis base2)
*/



use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix, pmix(knownaquis) lambda1() lambda2(knownaquis) gamma1(knownaquis base2) gamma2(knownaquis base2)dist(ww)
estimates store results2


 *** est p_mix when knownaquis==1
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis]))
 * attempt to get variables saved
mat pmix_k1_b = r(b) 
mat pmix_k1_V = r(V)
local pmix_k1 = pmix_b1_b[1,1]
local pmix_k1_upper = pmix_k1_b[1,1] + 1.96*sqrt(pmix_k1_V[1,1])
local pmix_k1_lower = pmix_k1_b[1,1] - 1.96*sqrt(pmix_k1_V[1,1])


*** est p_mix when base2==0
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
mat pmix_k0_b = r(b) 
mat pmix_k0_V = r(V)
local pmix_k0 = pmix_k0_b[1,1]
local pmix_k0_upper = pmix_k0_b[1,1] + 1.96*sqrt(pmix_k0_V[1,1])
local pmix_k0_lower = pmix_k0_b[1,1] - 1.96*sqrt(pmix_k0_V[1,1])

****** so pmix becomes 0.55 [0.34-0.67] if base2==1 and 0.9 if base2==0 [0.89-0.94]

**** est  lambda1
nlcom exp(_b[ln_lambda1:_cons])
mat lambda1_b = r(b) 
mat lambda1_V = r(V)
local lambda1 = lambda1_b[1,1]
local lambda1_upper = lambda1_b[1,1] + 1.96*sqrt(lambda1_V[1,1])
local lambda1_lower = lambda1_b[1,1] - 1.96*sqrt(lambda1_V[1,1])

* again, this because a nonsense model - lambda1 = 3.77e-43  !!!!
*Look at model 3

stmix, pmix(knownaquis base2) lambda1() lambda2(base2) gamma1(base2) gamma2(knownaquis base2)dist(ww)
estimates store results3


 *** est p_mix when knownaquis==1 &base2==1
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis]+_b[logit_p_mix:base2]))
 * attempt to get variables saved
mat pmix_b1_k1_b = r(b) 
mat pmix_b1_k1_V = r(V)
local pmix_b1_k1 = pmix_b1_k1_b[1,1]
local pmix_b1_k1_upper = pmix_b1_k1_b[1,1] + 1.96*sqrt(pmix_b1_k1_V[1,1])
local pmix_b1_k1_lower = pmix_b1_k1_b[1,1] - 1.96*sqrt(pmix_b1_k1_V[1,1])


*** est p_mix when base2==1
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]))
mat pmix_b1_k0_b = r(b) 
mat pmix_b1_k0_V = r(V)
local pmix_b1_k0 = pmix_b1_k0_b[1,1]
local pmix_b1_k0_upper = pmix_b1_k0_b[1,1] + 1.96*sqrt(pmix_b1_k0_V[1,1])
local pmix_b1_k0_lower = pmix_b1_k0_b[1,1] - 1.96*sqrt(pmix_b1_k0_V[1,1])

* knownaquis==1

 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis]))
mat pmix_b0_k1_b = r(b) 
mat pmix_b0_k1_V = r(V)
local pmix_b0_k1 = pmix_b0_k1_b[1,1]
local pmix_b0_k1_upper = pmix_b0_k1_b[1,1] + 1.96*sqrt(pmix_b0_k1_V[1,1])
local pmix_b0_k1_lower = pmix_b0_k1_b[1,1] - 1.96*sqrt(pmix_b0_k1_V[1,1])

* null

nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
mat pmix_b0_k0_b = r(b) 
mat pmix_b0_k0_V = r(V)
local pmix_b0_k0 = pmix_b0_k0_b[1,1]
local pmix_b0_k0_upper = pmix_b0_k0_b[1,1] + 1.96*sqrt(pmix_b0_k0_V[1,1])
local pmix_b0_k0_lower = pmix_b0_k0_b[1,1] - 1.96*sqrt(pmix_b0_k0_V[1,1])


**** est  lambda1
nlcom exp(_b[ln_lambda1:_cons])
mat lambda1_b = r(b) 
mat lambda1_V = r(V)
local lambda1 = lambda1_b[1,1]
local lambda1_upper = lambda1_b[1,1] + 1.96*sqrt(lambda1_V[1,1])
local lambda1_lower = lambda1_b[1,1] - 1.96*sqrt(lambda1_V[1,1])


**** est  lambda2
*base2 ==0
nlcom exp(_b[ln_lambda2:_cons])
mat lambda2_b0_b = r(b) 
mat lambda2_b0_V = r(V)
local lambda2_b0 = lambda2_b0_b[1,1]
local lambda2_b0_upper = lambda2_b0_b[1,1] + 1.96*sqrt(lambda2_b0_V[1,1])
local lambda2_b0_lower = lambda2_b0_b[1,1] - 1.96*sqrt(lambda2_b0_V[1,1])

* base2==1
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
mat lambda2_b1_b = r(b) 
mat lambda2_b1_V = r(V)
local lambda2_b1 = lambda2_b1_b[1,1]
local lambda2_b1_upper = lambda2_b1_b[1,1] + 1.96*sqrt(lambda2_b1_V[1,1])
local lambda2_b1_lower = lambda2_b1_b[1,1] - 1.96*sqrt(lambda2_b1_V[1,1])
*PROBLEM - cross 0 mark again. BAH!

/* Next options choice

rc	name	convergence	df	loglik	AIC
0	pmix(knownaquis base2) lambda1(knownaquis) lambda2(knownaquis base2) gamma1(knownaquis) gamma2(base2)	1	12	-1138.177	2300.354
0	pmix() lambda1(knownaquis base2) lambda2(knownaquis) gamma1() gamma2(knownaquis base2)	1	10	-1140.593	2301.187
0	pmix(knownaquis) lambda1(knownaquis) lambda2(knownaquis) gamma1() gamma2()	1	8	-1143.091	2302.183
0	pmix() lambda1(base2) lambda2(knownaquis base2) gamma1(knownaquis) gamma2(knownaquis base2)	1	11	-1140.474	2302.948
0	pmix() lambda1(base2) lambda2(knownaquis) gamma1(knownaquis base2) gamma2(knownaquis base2)	1	11	-1141.007	2304.015
 */

 
 
use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix,pmix(knownaquis base2) lambda1(knownaquis) lambda2(knownaquis base2) gamma1(knownaquis) gamma2(base2) dist(ww) iterate(100)
estimates store results4

 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis]+_b[logit_p_mix:base2]))
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]))
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis]))
nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis])
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2]+_b[ln_lambda2:knownaquis])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])

* nope, loads of the values cross axis

 
 
use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix,pmix() lambda1(knownaquis base2) lambda2(knownaquis) gamma1() gamma2(knownaquis base2) dist(ww) iterate(100)
estimates store results4


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2]+_b[ln_lambda2:knownaquis])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis])

*nope stupid numbers

 
use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix,pmix(knownaquis) lambda1(knownaquis) lambda2(knownaquis) gamma1() gamma2() dist(ww) iterate(100)
estimates store results4


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis])

*same prob


use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix, pmix() lambda1(base2) lambda2(knownaquis base2) gamma1(knownaquis) gamma2(knownaquis base2) dist(ww) iterate(100)
estimates store results4


nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2]+_b[ln_lambda2:knownaquis])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])

*silly numbers



use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix, pmix() lambda1(base2) lambda2(knownaquis) gamma1(knownaquis base2) gamma2(knownaquis base2) dist(ww) iterate(100)
estimates store results4


nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])

*same problem

*Option not tried - does it need interation term to work?

*Go back to original"best" model, add interaction term

use "E:\users\amy.mason\Staph\stset_data.dta", replace


stmix, pmix(base2) lambda1() lambda2() gamma1(knownaquis) gamma2(knownaquis base2) dist(ww)
estimates store results

stmix, pmix(base2) lambda1() lambda2() gamma1(knownaquis) gamma2(knownaquis base2 x) iterate(2000) dist(ww)
estimates store resultsx

stmix, pmix(base2) lambda1() lambda2() gamma1(knownaquis) gamma2(knownaquis base2 x) iterate(2000) dist(ww) difficult
estimates store resultsx2

nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda1:_cons])

* nope, even worse. Change confidence interval? Nope, even 90% still gives stupid answers.



************************************RERUN checking diff for every set ******************

*DIFF pmix(knownaquis) lambda1(knownaquis base2) lambda2(knownaquis) gamma1(base2) gamma2(knownaquis base2)

use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix, pmix(knownaquis) lambda1(knownaquis base2) lambda2(knownaquis) gamma1(base2) gamma2(knownaquis base2)dist(ww) iterate(100) difficult
estimates store results5


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda2:_cons])
* too small
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
*too small
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis]+_b[ln_lambda1:base2])


*DIFF pmix(knownaquis base2) lambda1(knownaquis base2) lambda2(knownaquis base2) gamma1(knownaquis base2) gamma2(base2)

use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix,pmix(knownaquis base2) lambda1(knownaquis base2) lambda2(knownaquis base2) gamma1(knownaquis base2) gamma2(base2) dist(ww) iterate(100) difficult
estimates store results5


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda2:_cons])
* too small
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
*too small
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis]+_b[ln_lambda2:base2])

nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis]+_b[ln_lambda1:base2])



*DIFF pmix(knownaquis base2) lambda1(knownaquis) lambda2(knownaquis base2) gamma1(knownaquis) gamma2(base2)

use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix,  pmix(knownaquis base2) lambda1(knownaquis) lambda2(knownaquis base2) gamma1(knownaquis) gamma2(base2) dist(ww) iterate(100) difficult
estimates store results5


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis]+_b[ln_lambda2:base2])
* nope
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis]+_b[ln_lambda1:base2])


*DIFF pmix() lambda1(base2) lambda2(knownaquis base2) gamma1(knownaquis) gamma2(knownaquis base2)
use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix,  pmix() lambda1(base2) lambda2(knownaquis base2) gamma1(knownaquis) gamma2(knownaquis base2) dist(ww) iterate(100) difficult


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
* cannot calc
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
*crosses axis
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis]+_b[ln_lambda2:base2])
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis]+_b[ln_lambda1:base2])


* DIFF pmix(knownaquis) lambda1(knownaquis) lambda2(base2) gamma1() gamma2()
use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix,  pmix(knownaquis) lambda1(knownaquis) lambda2(base2) gamma1() gamma2() dist(ww) iterate(100) difficult


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda2:_cons])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:base2])
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis]+_b[ln_lambda2:base2])
nlcom exp(_b[ln_lambda1:_cons])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis])
*goes negative :(
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:knownaquis]+_b[ln_lambda1:base2])


*DIFF pmix() lambda1(base2) lambda2(knownaquis) gamma1(knownaquis base2) gamma2(knownaquis base2)
use "E:\users\amy.mason\Staph\stset_data.dta", replace

stmix,  pmix() lambda1(base2) lambda2(knownaquis) gamma1(knownaquis base2) gamma2(knownaquis base2) dist(ww) iterate(100) difficult


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
nlcom exp(_b[ln_lambda2:_cons])
* can't calc
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:knownaquis])

nlcom exp(_b[ln_lambda1:_cons])

*goes negative :(
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:base2])



*same problems.

