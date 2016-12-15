*load staph carriage data, built to use even times only
* see sap_loss_eventime_build to see how this is created

use "E:\users\amy.mason\Staph\Sept03\eventimebuild.dta", clear

*  basic stmix model
quietly stmix, dist(ww)
estimates store novar


* consider the effect of adding single variables
* knownaquis
stmix, pmix(knownaquis) dist(ww)
estimates store known
lrtest novar known
*yes

stmix, lambda1(knownaquis) dist(ww) difficult noinit
estimates store l1base
lrtest novar l1base, stats
* won't run

stmix, lambda2(knownaquis) dist(ww)
estimates store l2base
lrtest novar l2base, stats
*won't run



* base2
stmix, pmix(base2) dist(ww)
estimates store base
lrtest novar base
*yup

stmix, lambda1(base2) dist(ww)
estimates store l1base
lrtest novar l1base, stats
*not relevant (prob>chi2=0.9)

stmix, lambda2(base2) dist(ww)
estimates store l2base
lrtest novar l2base, stats
*won't converge




*okay, ignore gamma/ lambda  for the moment. find all variables that improve at LR test
* get things into catagories
sort value2
by value2: replace value2="other" if _N<100

gen t002=(value2=="t002")
gen t005=(value2=="t005")
gen t012=(value2=="t012")
gen t084=(value2=="t084")
gen t127=(value2=="t127")


generate byte agecat=recode(age,40,55,67,75)
gen byte age55=(agecat>55)
gen spacat= (spa_no_last>1)


gen str200 name=""

foreach aaa in "value2" "degrade" "age" "male" "baseline_student" "baseline_ethnic" "baseline_iscurremp" "baseline_hcrelemp" "baseline_nomembers" "anti6mon" "antiprev" "spa_no_last"{
	capture stmix, pmix(`aaa') dist(ww) 
	quietly replace name= "pmix(`aaa')"
	if _rc==0{ 
				display name
				estimates store `aaa'
				*lrtest novar `aaa'
				}
	if _rc!=0{
	display _rc
	}
	}	
	
*
* so antiprev, anti6mon not significant
* base2 knownaquis  spa_no_last significant
* agecat degrade, male, student, ethnic, current employment/hcl emply/ family/ won't run, even as binary cat



stmix, pmix(base2 knownaquis spacat) dist(ww)
estimates store all


stmix, pmix(base2 knownaquis) dist(ww)
estimates store baseknow
lrtest baseknow all
*all better


* stmix, pmix(base2 spacat) dist(ww) noinit difficult
* won't run

stmix, pmix(spacat) dist(ww)
estimates store spa
lrtest all spa
* all better

stmix, pmix(base2) dist(ww)
estimates store base2
lrtest all base2
*all better

stmix, pmix(knownaquis spacat) dist(ww)
estimates store knowncat
lrtest knowncat all
*all better


gen x = (base2==1)*(knownaquis==1)
gen y = (base2==1)*(spacat==1)
gen z = (knownaquis==1)*(spacat==1)


stmix, pmix(base2 knownaquis spacat x) dist(ww)
estimates store interx

*stmix, pmix(base2 knownaquis spacat y) dist(ww) noinit
*will not converge

stmix, pmix(base2 knownaquis spacat z) dist(ww)
estimates store interz

lrtest interx all
lrtest interz all/
* all better than either model

***
* assuming, we want all of those catagories in


foreach aaa in "value2" "degrade" "age" "male" "baseline_student" "baseline_ethnic" "baseline_iscurremp" "baseline_hcrelemp" "baseline_nomembers" "anti6mon" "antiprev" "spa_no_last"{
	capture stmix, pmix(base2 knownaquis spacat `aaa') dist(ww) iterate(100)
	quietly replace name= "all + pmix(`aaa')"
	if _rc==0{ 
				display name
				estimates store `aaa'
				lrtest novar `aaa'
				}
	if _rc!=0{
	display _rc
	}
	}	
	


***

*Okay, working and interesting is 

stmix, pmix(base2 knownaquis) lambda1( anti6mon spacat) lambda2( anti6mon spacat) dist(ww)

* adding interaction (base2, knownaquis) or (anti6mon, spacat) term is not a improvement
* adding male, age, currentemply, baselinehcr, baseline_no will not run
* t012, degrade, ethnic , student,             no sig improvement


* what about dropping variables?
* no improvement: base2, knownaquis, anti(both), spa(both)
* improvement: anti (1), 
* won't run: anti (2), spa (1) spA(2)
*so best becomes 


stmix, pmix(base2 knownaquis) lambda1(spacat) lambda2( anti6mon spacat) dist(ww)


* no improvement: base2, knownaquis, anti(2)
* won't run: spa (1), spa (2), spa(both)

*adding: 
* no improvement t012, degrade
* won't run: male, age, ethnic, currently employed, hcl emplyed, baseline_no  





****************************


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
					if _rc!=0{				
					capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa') dist(ww) iterate(300) noinit
					quietly replace name ="INIT pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa')"
						if _rc==0{
							post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
							display name		
									}
						if _rc!=0{			
							capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa') dist(ww) iterate(300) difficult
							quietly replace name ="DIFF pmix(`aaa') lambda1(`baa') lambda2(`caa') gamma1(`daa') gamma2(`eaa')"
							if _rc==0{
								post sim (_rc) (name) (e(converged)) (e(rank)) (e(ll))
								display name
										}
							else{
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
	}
	}
	}


postclose sim
use results, clear

gen AIC=2*df-2*loglik
save "E:\users\amy.mason\Staph\Sept03\investigate1.dta",


*********

*results = not worth looking at, all extremal silly answers - stick to analysis in 
*rc	name	convergence	df	loglik	AIC
*
*0	DIFF pmix(base2) lambda1() lambda2(knownaquis) gamma1() gamma2(knownaquis)	1	8	-817.5618	1651.124
*0	DIFF pmix() lambda1() lambda2(base2) gamma1() gamma2(knownaquis base2)	1	8	-822.1166	1660.233
*0	DIFF INIT pmix() lambda1(base2) lambda2(base2) gamma1() gamma2(knownaquis)	1	8	-822.1254	1660.251
*0	DIFF INIT pmix() lambda1(base2) lambda2(knownaquis base2) gamma1() gamma2(base2)	1	9	-823.2503	1664.501
*0	DIFF INIT pmix() lambda1(knownaquis) lambda2() gamma1() gamma2(base2)	1	7	-837.2697	1688.539
*0	DIFF pmix() lambda1(knownaquis) lambda2(base2) gamma1() gamma2()	1	7	-837.8405	1689.681
*0	DIFF INIT pmix() lambda1(knownaquis base2) lambda2() gamma1() gamma2(base2)	1	8	-837.2697	1690.539
*0	DIFF INIT pmix(knownaquis) lambda1(knownaquis base2) lambda2(knownaquis) gamma1(base2) gamma2(base2)	1	9	-1350.626	2719.252
*0	pmix(knownaquis) lambda1() lambda2(knownaquis) gamma1(knownaquis base2) gamma2(base2)	1	10	-1571.112	3162.224




use "E:\users\amy.mason\Staph\Sept03\eventimebuild.dta", clear
gen spacat= (spa_no_last>1)

gen str200 name=""
tempname sim2
postfile sim2 int rc str200 name byte convergence int df float loglik using results, replace
****
	

	

foreach aaa in "" "knownaquis" "base2" "knownaquis base2" "spacat" "spacat base2" "spacat knownaquis" "spacat base2 knownaquis"{
	foreach baa in "" "knownaquis" "base2" "knownaquis base2" "spacat" "spacat base2" "spacat knownaquis"{
		foreach caa in "" "knownaquis" "base2" "knownaquis base2" "spacat" "spacat base2" "spacat knownaquis"{
				capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') iterate(100) dist(ww)
					quietly replace name =" pmix(`aaa') lambda1(`baa') lambda2(`caa')"
					if _rc==0{
						post sim2 (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
									}
					if _rc!=0{				
					capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa') dist(ww) iterate(100) noinit
					quietly replace name ="INIT pmix(`aaa') lambda1(`baa') lambda2(`caa') "
						if _rc==0{
							post sim2 (_rc) (name) (e(converged)) (e(rank)) (e(ll))
							display name		
									}
						if _rc!=0{			
							capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa')  dist(ww) iterate(100) difficult
							quietly replace name ="DIFF pmix(`aaa') lambda1(`baa') lambda2(`caa') "
							if _rc==0{
								post sim2 (_rc) (name) (e(converged)) (e(rank)) (e(ll))
								display name
										}
							else{
								capture stmix, pmix(`aaa') lambda1(`baa') lambda2(`caa')  dist(ww) noinit iterate(100) difficult
								quietly replace name ="DIFF INIT pmix(`aaa') lambda1(`baa') lambda2(`caa') "
								if _rc==0{
									post sim2 (_rc) (name) (e(converged)) (e(rank)) (e(ll))
									display name
									}				
								else{
									post sim2 (_rc) (name) (.) (.) (.)
									quietly replace name ="failed: pmix(`aaa') lambda1(`baa') lambda2(`caa') "
									display name
									display _rc		
									}
									}
									}
	}
	}
	}
	}
	


postclose sim2
use results, clear

gen AIC=2*df-2*loglik
save "E:\users\amy.mason\Staph\Sept03\investigate2.dta",


******************
*check working




use "E:\users\amy.mason\Staph\Sept03\eventimebuild.dta", clear
gen spacat= (spa_no_last>1)

gen str200 name=""
tempname sim2
postfile sim2 int rc str200 name byte convergence int df float loglik using results, replace
****
	
	

	
foreach bbb in "" "value2" "age" "male" "baseline_student" "baseline_ethnic" "baseline_iscurremp" "baseline_hcrelemp" "baseline_nomembers" {
foreach aaa in "" "base2" "knownaquis" "value2" "degrade" "age" "male" "baseline_student" "baseline_ethnic" "baseline_iscurremp" "baseline_hcrelemp" "baseline_nomembers" "anti6mon" "antiprev" "spa_no_last" {
					capture stmix, pmix(base2 knownaquis `baa') lambda1(`aaa') lambda2(`aaa')  iterate(300) dist(ww)
					quietly replace name ="  pmix(`bbb') lambda1(`aaa')"
					if _rc==0{
						post sim2 (_rc) (name) (e(converged)) (e(rank)) (e(ll))
						display name
						}
					if _rc!=0{
					display _rc
						post sim2 (_rc) (name) (0) (0) (0)
						display _rc
											
							}
						}
	
	}
	



postclose sim2
use results, clear

gen AIC=2*df-2*loglik
save "E:\users\amy.mason\Staph\Sept03\investigate2.dta", replace


