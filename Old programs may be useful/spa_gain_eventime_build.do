
*********************************************************************************
*Playing with spa gain survival times and stmix
*********************************************************************************
*want to create a set for first gain of new spa type.


/* use two week differences instead */
/* make survival time set for gain of first new staph carriage*/
use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear

rename baseline_age age
rename baseline_male male
gen anti6mon=  patient_prev_anti_6mon
gen antiprev= patient_prev_anti_swob
replace n_spatypeid=0 if n_spatypeid==.
sort patid timepoint
by patid: gen spa_no_last= n_spatypeid[_n-1]
by patid: replace spa_no_last=n_spatypeid if _n==1
 
/* fix timepoint == 1 */
* consider BURPprev, antiprev, 
* currently impossible to have event at timepoint 1 -> earliest is timepoint==2 so no worries there
* BURPprev not problem

gen antiprev2= antiprev
by patid: replace antiprev2=1 if timepoint[_n-1]==1 & antiprev[_n-1]==1 


drop if timepoint==1


/* mark even if new infection at least two different from previous 2 swabs */
 gen byte event =(BurpPrev>=2&BurpPrev!=.)

  
* add event if no initial carriage 
 replace event =1 if (base2==1 & State==1 &timepoint>=2)
 
 by patid: drop if _N<2
 
 
  /* create set */
 drop if age==.
 stset timepoint, fail(event) id(patid)
 
save "E:\users\amy.mason\Staph\Sept03\evengainbuild1.dta", replace
 
 *****************************
 *Analysis*
 
***************************

*Kaplan-Meier graph

sts graph, by(base2)

* log-cumulative graph of survival

stphplot, by(base2)

* lines pretty straight, let's try Weibull to fit

streg base2, distribution(weibull)
sts generate km=s
generate double H=-ln(km)
predict double cs, csnell
line H cs cs, sort

drop H km cs


*** stick with Weibull for the moment

*null
streg, distribution(weibull)

estimates store null


* try all variables one by one

* check individual variables

generate byte agecat=recode(age,40,55,67,75)
gen byte age55=(agecat>55)
gen spacat= (spa_no_last>1)+ (spa_no_last>0)
gen carriage = (spa_no_last>0)
gen month = month(BestDate)
sort patid timepoint
gen baseline_n2 = baseline_no
replace baseline_n2=4 if baseline_n2>3

gen ethnic = "White British" if baseline_ethnic == 1
replace ethnic="Other White" if inlist(baseline_ethnic, 2, 3)
replace ethnic="Other" if ethnic==""


gen str200 name=""

foreach aaa in  "" "i.month" "i.base2" "i.degrade" "c.age" "i.agecat" "i.age55" "i.spacat" "i.carriage" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.anti6mon" "i.antiprev" {
	capture streg `aaa', dist(weibull) 
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display name
				estat ic
				}

	}	



	
	
	* comparing to 1140.63
* significant:  age/ agecat/age55 (c.age best) , spacat/carriage (carriage best) , student, 
* not: base2, month, degrade, male, ethnic, currempploy, hcremploy, antiprev, anti6mon, no members, 
*ethnic will not run


foreach aaa in  "" "i.month" "i.base2" "i.degrade" "c.age" "i.agecat" "i.age55" "i.spacat" "i.carriage" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.anti6mon" "i.antiprev" {
	capture streg , dist(weibull) anc(`aaa')
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display name
				estat ic
				}

	}	

* significant = anti6mon, student, carriage, age

* put them all in together and remove one by one

qui streg  c.age i.carriage i.baseline_student i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* AIC = 1054.915

*1 parameter
* AGE 
qui streg  i.carriage i.baseline_student i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
*1060.046

*CARRIAGE
qui streg  c.age  i.baseline_student i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* 1053.836 

*STUDENT
qui streg  c.age i.carriage  i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* 1053.563 

* ANTI
qui streg  c.age i.carriage i.baseline_student, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* 1052.942 



*2nd para
*AGE
qui streg  c.age i.carriage i.baseline_student i.anti6mon, dist(weibull)  anc(i.anti6mon i.baseline_student i.carriage)
estat ic
* 1054.519  


*STUDENT
qui streg  c.age i.carriage i.baseline_student i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.carriage)
estat ic
*1054.011 

*CARRIAGE
qui streg  c.age i.carriage i.baseline_student i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student)
estat ic
* 1057.25 


*ANTI
qui streg  c.age i.carriage i.baseline_student i.anti6mon, dist(weibull)  anc(c.age i.baseline_student i.carriage)
estat ic
* 1054.123


***** remove: 1P STUDENT: 1053.563 


qui streg  c.age i.carriage i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* AIC =  1053.563  

*1 parameter
* AGE 
qui streg  i.carriage  i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
*1071.579 

*CARRIAGE
qui streg  c.age  i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* 1052.39 


* ANTI
qui streg  c.age i.carriage , dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* 1051.65 


*2nd para
*AGE
qui streg  c.age i.carriage  i.anti6mon, dist(weibull)  anc(i.anti6mon i.baseline_student i.carriage)
estat ic
*  1057.387 


*STUDENT
qui streg  c.age i.carriage  i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.carriage)
estat ic
*1052.213 

*CARRIAGE
qui streg  c.age i.carriage  i.anti6mon, dist(weibull)  anc(c.age i.anti6mon i.baseline_student)
estat ic
* 1055.805 


*ANTI
qui streg  c.age i.carriage  i.anti6mon, dist(weibull)  anc(c.age i.baseline_student i.carriage)
estat ic
* 1052.516 



***REMOVE ANTI from 1st Parameter

qui streg  c.age i.carriage, dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* AIC =   1051.65 

*1 parameter
* AGE 
qui streg  i.carriage , dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
* 1069.77 

*CARRIAGE
qui streg  c.age , dist(weibull)  anc(c.age i.anti6mon i.baseline_student i.carriage)
estat ic
*   1050.4 


*2nd para
*AGE
qui streg  c.age i.carriage  , dist(weibull)  anc(i.anti6mon i.baseline_student i.carriage)
estat ic
* 1055.428 


*STUDENT
qui streg  c.age i.carriage  , dist(weibull)  anc(c.age i.anti6mon i.carriage)
estat ic
*1050.298 

*CARRIAGE
qui streg  c.age i.carriage  , dist(weibull)  anc(c.age i.anti6mon i.baseline_student)
estat ic
*  1053.822  


*ANTI
qui streg  c.age i.carriage , dist(weibull)  anc(c.age i.baseline_student i.carriage)
estat ic
*  1059.68  

*** remove student from 2nd para

qui streg  c.age i.carriage, dist(weibull)  anc(c.age i.anti6mon i.carriage)
estat ic
* AIC =1050.298     

*1 parameter
* AGE 
qui streg  i.carriage , dist(weibull)  anc(c.age i.anti6mon i.carriage)
estat ic
*   1068.335  

*CARRIAGE
qui streg  c.age , dist(weibull)  anc(c.age i.anti6mon i.carriage)
estat ic
*   1049.12 


*2nd para
*AGE
qui streg  c.age i.carriage  , dist(weibull)  anc(i.anti6mon  i.carriage)
estat ic
*  1054.88



*CARRIAGE
qui streg  c.age i.carriage  , dist(weibull)  anc(c.age i.anti6mon )
estat ic
*   1052.484


*ANTI
qui streg  c.age i.carriage , dist(weibull)  anc(c.age i.carriage)
estat ic
*  1058.05  


***** remove 1st parameter: CARRIAGE


qui streg  c.age, dist(weibull)  anc(c.age i.anti6mon i.carriage)
estat ic
* AIC =  1049.12 

*1 parameter
* AGE 
qui streg  , dist(weibull)  anc(c.age i.anti6mon i.carriage)
estat ic
*    1067.201 

*2nd para
*AGE
qui streg  c.age   , dist(weibull)  anc(i.anti6mon  i.carriage)
estat ic
*  1052.905  



*CARRIAGE
qui streg  c.age   , dist(weibull)  anc(c.age i.anti6mon )
estat ic
* 1059.741 


*ANTI
qui streg  c.age  , dist(weibull)  anc(c.age i.carriage)
estat ic
*     1056.943  


***DONE: Check no terms will go back in


foreach aaa in  "" "i.month" "i.base2" "i.degrade" "i.carriage" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.anti6mon" "i.antiprev" {
	capture streg  c.age `aaa', dist(weibull)  anc(c.age i.anti6mon i.carriage)
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display "all and 1P " name
				estat ic
				}

	}	

* to beat: AIC =  1049.12
* sig = 1p  i.base2, baseline_iscurremp, i.antiprev
	
	



foreach aaa in  "" "i.month" "i.base2" "i.degrade" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.antiprev" {
	capture streg  c.age , dist(weibull)  anc(c.age i.anti6mon i.carriage `aaa')
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display "all and 2P " name
				estat ic
				}

	}	
* sig: i. antiprev, is, base2,

**** OKAY, all in and let's go again (wtf?)


qui streg  c.age i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc(i.base2 i.antiprev c.age i.baseline_iscurremp  i.anti6mon i.carriage)
estat ic
*AIC:  1041.92  

****ANTIPREV 1P
qui streg  c.age i.base2 baseline_iscurremp, dist(weibull)  anc(i.base2 i.antiprev c.age i.baseline_iscurremp  i.anti6mon i.carriage)
estat ic
*AIC:  1040.146 

****ANTIPREV 2P
qui streg  c.age  i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc( i.base2 c.age i.baseline_iscurremp  i.anti6mon i.carriage)
estat ic
*AIC:  1039.922 

***BASE2 1p
qui streg  c.age  baseline_iscurremp i.antiprev, dist(weibull)  anc(i.base2 i.antiprev c.age i.baseline_iscurremp i.anti6mon i.carriage)
estat ic
*AIC:  1039.997  

****BASE2 2p
qui streg  c.age i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc(i.antiprev c.age i.baseline_iscurremp  i.anti6mon i.carriage)
estat ic
*AIC:     1042.966

**** IS 1p

qui streg  c.age i.base2 i.antiprev, dist(weibull)  anc(i.base2 i.antiprev c.age i.baseline_iscurremp  i.anti6mon i.carriage)
estat ic
*AIC:  1040.021 


**IS 2p
qui streg  c.age i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc(i.base2 i.antiprev c.age  i.anti6mon i.carriage)
estat ic
*AIC:   1039.92 

*DROP: IS 2P

qui streg  c.age i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc(i.base2 i.antiprev c.age  i.anti6mon i.carriage)
estat ic
*AIC:    1039.92 

****ANTIPREV 1P
qui streg  c.age i.base2 baseline_iscurremp, dist(weibull)  anc(i.base2 i.antiprev c.age  i.anti6mon i.carriage)
estat ic
*AIC:   1038.147

****ANTIPREV 2P
qui streg  c.age  i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc( i.base2 c.age   i.anti6mon i.carriage)
estat ic
*AIC:  1037.922 

***BASE2 1p
qui streg  c.age  baseline_iscurremp i.antiprev, dist(weibull)  anc(i.base2 i.antiprev c.age  i.anti6mon i.carriage)
estat ic
*AIC: 1038 

****BASE2 2p
qui streg  c.age i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc(i.antiprev c.age   i.anti6mon i.carriage)
estat ic
*AIC:      1041.082  
**** IS 1p

qui streg  c.age i.base2 i.antiprev, dist(weibull)  anc(i.base2 i.antiprev c.age   i.anti6mon i.carriage)
estat ic
*AIC: 1038.795

* DROP : ANTIPREV 2p


qui streg  c.age  i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc( i.base2 c.age   i.anti6mon i.carriage)
estat ic
*AIC:  1037.922 


****ANTIPREV 1P
qui streg  c.age i.base2 baseline_iscurremp, dist(weibull)  anc(i.base2  c.age  i.anti6mon i.carriage)
estat ic
*AIC:    1038.147 



***BASE2 1p
qui streg  c.age  baseline_iscurremp i.antiprev, dist(weibull)  anc(i.base2 c.age  i.anti6mon i.carriage)
estat ic
*AIC:   1036 

****BASE2 2p
qui streg  c.age i.base2 baseline_iscurremp i.antiprev, dist(weibull)  anc(c.age   i.anti6mon i.carriage)
estat ic
*AIC:   1039.091     
**** IS 1p

qui streg  c.age i.base2 i.antiprev, dist(weibull)  anc(i.base2  c.age   i.anti6mon i.carriage)
estat ic
*AIC:  1036.795

* DROP: BASE2 1p

qui streg  c.age  baseline_iscurremp i.antiprev, dist(weibull)  anc(i.base2 c.age  i.anti6mon i.carriage)
estat ic
*AIC:   1036 

****ANTIPREV 1P
qui streg  c.age  baseline_iscurremp, dist(weibull)  anc(i.base2  c.age  i.anti6mon i.carriage)
estat ic
*AIC:    1036.238  




****BASE2 2p
qui streg  c.age baseline_iscurremp i.antiprev, dist(weibull)  anc(c.age   i.anti6mon i.carriage)
estat ic
*AIC:    1048.435
**** IS 1p

qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2  c.age   i.anti6mon i.carriage)
estat ic
*AIC:   1034.861  

*** DROP IS 2P


qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2  c.age   i.anti6mon i.carriage)
estat ic
*AIC:   1034.861 


****ANTIPREV 1P
qui streg  c.age, dist(weibull)  anc(i.base2  c.age  i.anti6mon i.carriage)
estat ic
*AIC:     1035.107 

****BASE2 2p
qui streg  c.age i.antiprev, dist(weibull)  anc(c.age   i.anti6mon i.carriage)
estat ic
*AIC:   1048.538

**** OKAY now check higher order terms: target = 1034.861

 qui streg  c.age i.antiprev c.age#i.antiprev, dist(weibull)  anc(i.base2  c.age   i.anti6mon i.carriage)
estat ic
*1096.78


 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2#c.age i.base2  c.age  i.anti6mon i.carriage)
estat ic
*1036.841 

 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2#i.anti6mon i.base2  c.age   i.anti6mon i.carriage)
estat ic
*1035.761 

 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2#i.carriage i.base2  c.age   i.anti6mon i.carriage)
estat ic
* 1003.514  

 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2  c.age#i.anti6mon c.age   i.anti6mon i.carriage)
estat ic
* 1036.83 

 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2  c.age#i.carriage c.age i.anti6mon i.carriage)
estat ic
*1031.621  

 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2  c.age i.anti6mon#i.carriage  i.anti6mon i.carriage)
estat ic

*1035.833  

*base2#carriage and age#carriage give improvements. try both


 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2  c.age#i.anti6mon i.base2#i.carriage  c.age   i.anti6mon i.carriage)
estat ic
* 1005.497 

* what about taking things out/ testing previously rejected variables: to beat 1003.514  
**OUT : 
 qui streg   i.antiprev, dist(weibull)  anc(i.base2  i.base2#i.carriage  c.age   i.anti6mon i.carriage)
estat ic
 qui streg  c.age , dist(weibull)  anc(i.base2   i.base2#i.carriage  c.age   i.anti6mon i.carriage)
estat ic
* 1003.224 
 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2   i.base2#i.carriage  i.anti6mon i.carriage)
estat ic
 qui streg  c.age i.antiprev, dist(weibull)  anc(i.base2   i.base2#i.carriage  c.age    i.carriage)
 estat ic
 *REMOVE antiprev from 1p
 
 **** AGAIn: 1003.224 
 
  qui streg   , dist(weibull)  anc(i.base2   i.base2#i.carriage  c.age   i.anti6mon i.carriage)
estat ic
 qui streg  c.age , dist(weibull)  anc(i.base2    c.age   i.anti6mon i.carriage)
estat ic
 qui streg  c.age , dist(weibull)  anc(i.base2   i.base2#i.carriage    i.anti6mon i.carriage)
estat ic

 qui streg  c.age , dist(weibull)  anc(i.base2   i.base2#i.carriage  c.age    i.carriage)
estat ic

*** NO IMPROVEMENT

 
 *****IN
 qui streg  c.age , dist(weibull)  anc(i.base2   i.base2#i.carriage  c.age   i.anti6mon i.carriage)
estat ic

* to beat:  1003.224 
*




foreach aaa in  "" "i.month" "i.base2" "i.degrade" "i.carriage" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.anti6mon" "i.antiprev" {
	capture streg  c.age `aaa', dist(weibull)  anc(i.base2   i.base2#i.carriage  c.age   i.anti6mon i.carriage)
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display "all and 1P " name
				estat ic
				}

	}	


	



foreach aaa in  "" "i.month" "i.degrade" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.antiprev" {
	capture streg  c.age `aaa', dist(weibull)  anc(i.base2   i.base2#i.carriage  c.age   i.anti6mon i.carriage)
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display "all and 2P " name
				estat ic
				}

	}	
* sig: NONE!


********
*Best model*
*******

streg  c.age, dist(weibull)  anc(i.base2#i.carriage i.base2  c.age   i.anti6mon i.carriage)



save "E:\users\amy.mason\Staph\Sept03\evengainmodel1.dta", replace
* age
 *percentiles:        10%       25%       50%       75%       90
			*		19.0418   37.5661    55.729   65.8645    75.102
			
			
****************************GRAPH***************
use "E:\users\amy.mason\Staph\Sept03\evengainmodel1.dta", clear	
	
streg  c.age, dist(weibull)  anc(i.base2#i.carriage i.base2  c.age   i.anti6mon i.carriage)

			
replace age =55
replace carriage=0
replace base2=0
replace anti6mon=0
predict h, hazard
line h _t, c(1) sort ytitle("baseline hazard")

predict sur, csurv

*confidence interval
predict err, stdp 
gen sur_upper = sur+ 1.96*err
gen sur_lower = sur-1.96*err
	
twoway rarea sur_upper sur_lower _t, sort ||line sur _t, c(1) sort ytitle("baseline survival")	


**** don't like the graph this is producing - se seems wacky. try previous method.

* wish to estimate survival curve when age == 55, carriage = 0, base2=0, anti6mon=0

*** estimate p
nlcom exp(_b[ln_p:_cons]+55*_b[ln_p:age])
mat temp = r(b)
mat temp2 = r(V)
local p = temp[1,1]
local p_upper = temp[1,1]+1.96*sqrt(temp2[1,1])
local p_lower = temp[1,1]-1.96*sqrt(temp2[1,1])


*** estimate lambda
nlcom exp(_b[_t:_cons]+55*_b[_t:age])
mat temp3 = r(b)
mat temp4 = r(V)
local lam = temp3[1,1]
local lam_upper = temp3[1,1]+1.96*sqrt(temp4[1,1])
local lam_lower = temp3[1,1]-1.96*sqrt(temp4[1,1])




**** create graph of main line exp(-lambda t^p)



#delimit ;
twoway   function exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age 55; Recruitment positive; No carriage; No Antibiotics in last 6months") legend(order(3 "Rate 2")) ylabel(0(0.2)1);
#delimit cr
graph save E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph, replace




* wish to estimate survival curve when age == 25, carriage = 0, base2=0, anti6mon=0

local age=25

*** estimate p
nlcom exp(_b[ln_p:_cons]+`age'*_b[ln_p:age])
mat temp = r(b)
mat temp2 = r(V)
local p = temp[1,1]
local p_upper = temp[1,1]+1.96*sqrt(temp2[1,1])
local p_lower = temp[1,1]-1.96*sqrt(temp2[1,1])


*** estimate lambda
nlcom exp(_b[_t:_cons]+`age'*_b[_t:age])
mat temp3 = r(b)
mat temp4 = r(V)
local lam = temp3[1,1]
local lam_upper = temp3[1,1]+1.96*sqrt(temp4[1,1])
local lam_lower = temp3[1,1]-1.96*sqrt(temp4[1,1])




**** create graph of main line exp(-lambda t^p)



#delimit ;
twoway   function exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age `age'; Recruitment positive; No carriage; No Antibiotics in last 6months") legend(order(3 "Rate 2")) ylabel(0(0.2)1);
#delimit cr
********
graph save E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph, replace
			


* wish to estimate survival curve when age == 70, carriage = 0, base2=0, anti6mon=0

local age=75

*** estimate p
nlcom exp(_b[ln_p:_cons]+`age'*_b[ln_p:age])
mat temp = r(b)
mat temp2 = r(V)
local p = temp[1,1]
local p_upper = temp[1,1]+1.96*sqrt(temp2[1,1])
local p_lower = temp[1,1]-1.96*sqrt(temp2[1,1])


*** estimate lambda
nlcom exp(_b[_t:_cons]+`age'*_b[_t:age])
mat temp3 = r(b)
mat temp4 = r(V)
local lam = temp3[1,1]
local lam_upper = temp3[1,1]+1.96*sqrt(temp4[1,1])
local lam_lower = temp3[1,1]-1.96*sqrt(temp4[1,1])




**** create graph of main line exp(-lambda t^p)



#delimit ;
twoway   function exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age `age'; Recruitment positive; No carriage; No Antibiotics in last 6months") legend(order(3 "Rate 2")) ylabel(0(0.2)1);
#delimit cr
********
graph save E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp3.gph, replace

* combine age graphs	
graph combine temp1 temp2


****** RECRUITMENT/CURRENT CARRIAGE


* RECRUITMENT NEG


* wish to estimate survival curve when age == 55, carriage = 0, base2=1, anti6mon=0

*** estimate p
nlcom exp(_b[ln_p:_cons]+55*_b[ln_p:age]+_b[ln_p:1.base2])
mat temp = r(b)
mat temp2 = r(V)
local p = temp[1,1]
local p_upper = temp[1,1]+1.96*sqrt(temp2[1,1])
local p_lower = temp[1,1]-1.96*sqrt(temp2[1,1])


*** estimate lambda
nlcom exp(_b[_t:_cons]+55*_b[_t:age])
mat temp3 = r(b)
mat temp4 = r(V)
local lam = temp3[1,1]
local lam_upper = temp3[1,1]+1.96*sqrt(temp4[1,1])
local lam_lower = temp3[1,1]-1.96*sqrt(temp4[1,1])




**** create graph of main line exp(-lambda t^p)



#delimit ;
twoway   function exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age 55; Recruitment negative; No carriage; No Antibiotics in last 6months") legend(order(3 "Rate 2")) ylabel(0(0.2)1);
#delimit cr
********
graph save E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph, replace



* POSTIVE CARRIAGE


* POSTIVE CARRIAGE AND RECRUITMENT NEG
