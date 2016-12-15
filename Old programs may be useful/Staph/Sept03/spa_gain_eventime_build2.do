
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
gen startprobs = inlist(patid, 1228, 1248, 1262, 1285,1289, 1326, 1335, 1341, 2003, 2009, 2023, 2033, 2047, 2052, 2059, 2079, 2081, 2083, 2092, 2100, 2106, 2109, 2121)


generate byte agecat=recode(age,40,55,67,75)
gen byte age55=(agecat>55)

gen month = month(BestDate)
sort patid timepoint
gen baseline_n2 = baseline_no
replace baseline_n2=4 if baseline_n2>3

gen ethnic = 1 if baseline_ethnic == 1
replace ethnic=2 if inlist(baseline_ethnic, 2, 3)
replace ethnic=3 if ethnic==""


 
/* fix timepoint == 1 */
* consider BURPprev, antiprev, carriage, spa_no_last 
* currently impossible to have event at timepoint 1 -> earliest is timepoint==2 so no worries there
* BURPprev not problem, because difference from last two
* what about carriage - if carrying at 1, pull it back to zero.

gen antiprev2= antiprev
by patid: replace antiprev2=1 if timepoint[_n-1]==1 & antiprev[_n-1]==1 

sort patid timepoint
by patid: replace n_spatypeid=n_spatypeid[_n+1] if timepoint[_n]==0 & n_spatypeid< n_spatypeid[_n+1]

drop if timepoint==1

drop spa_no_last
by patid: gen spa_no_last= n_spatypeid[_n-1]
by patid: replace spa_no_last=n_spatypeid if _n==1


by patid: gen spa2 = max(spa_no_last[_n],spa_no_last[_n-1])
gen carriage = spa2>0
gen spacat= (spa2>1)+ (spa2>0)


/* mark even if new infection at least two different from previous 2 swabs */
 gen byte event =(BurpPrev>=2&BurpPrev!=.)

* dont have to worry about timepoint==1 stuff because it is comparing to past 2
 
 by patid: drop if _N<2
 
 
  /* create set */
 drop if age==.
 stset timepoint, fail(event) id(patid)
 
save "E:\users\amy.mason\Staph\Sept03\evengainbuild1.dta", replace
 
 *****************************
 *Analysis*
 
***************************
use "E:\users\amy.mason\Staph\Sept03\evengainbuild1.dta", clear
 
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


gen str200 name=""

foreach aaa in  "" "i.base2" "i.degrade" "c.age" "i.agecat" "i.age55" "i.spacat" "i.ethnic" "i.carriage" "i.male" "i.baseline_student" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.anti6mon" "i.antiprev" {
	capture streg `aaa', dist(weibull) 
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display name
				estat ic
				}

	if _rc!=0{
				display name
				display _rc
	}
	}	



	
	
	* comparing to 1081.725 
* significant:  ethnic c.age (as best of three), spacat (better than carraige, student, baseline_n2, anti6mon
*not: base2 degrade male employ hcr antiprev
*will not run: 


foreach aaa in  "" "i.base2" "i.degrade" "c.age" "i.agecat" "i.age55" "i.spacat" "i.carriage" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.anti6mon" "i.antiprev" {
	capture streg , dist(weibull) anc(`aaa')
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display name
				estat ic
				}

	if _rc!=0{
				display name
				display _rc
	}
	}	

* significant = c.age, spacat, ethnic, baseline_n2, anti6mon, baseline_is, baseline_student
* won't run ethnic
* put them all in together and remove one by one

qui streg  c.age i.ethnic i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* AIC =1022.445 

*1 parameter
* AGE_1
qui streg  i.ethnic i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* 1024.523 

* Ethnic _1
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* 1038.604

* spa_cat _1
qui streg  c.age i.ethnic i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*1018.85

* student_1
qui streg  c.age i.ethnic i.spacat i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1020.534   

* n2_1
qui streg  c.age i.ethnic i.spacat i.baseline_student i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* 1015.615 


*anti_1
qui streg  c.age i.ethnic i.spacat i.baseline_student i.baseline_n2, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* 1020.457 

* age_2
qui streg  c.age i.ethnic i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* 1021.575  

*spacat_2
qui streg  c.age i.ethnic i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*1019.705  

*n2_2
qui streg  c.age i.ethnic i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*1015.404 

* is_2
qui streg  c.age i.ethnic i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.anti6mon i.baseline_student)
estat ic
* 1022.64 

* anti_2
qui streg  c.age i.ethnic i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.baseline_student)
estat ic
*1021.203

*student_2
qui streg  c.age i.ethnic i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon)
estat ic
*1020.558 


***** remove: 1P ETHNIC 1038.604

* spacat
qui streg  c.age i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1035.135  

* age
qui streg  i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* 1041.134 

* student
qui streg  c.age i.spacat  i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* 1036.759  


* n2
qui streg  c.age i.spacat i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1031.448  

* anti6mon
qui streg  c.age i.spacat i.baseline_student i.baseline_n2, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1036.624 

* 2.age
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1037.868 
* 2.spacat
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age  i.baseline_n2 i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1036.058 
* 2.n2
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1031.339  
* 2.student
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.anti6mon )
estat ic
*  1036.771 
* 2.is
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2  i.anti6mon i.baseline_student)
estat ic
*  1038.357 

* 2.6mon
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_n2 i.baseline_iscurremp i.baseline_student)
estat ic
*  1037.336

**** REMOVE: 2.n2  : 1031.339  

*age
qui streg   i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1035.384  

*spcat
qui streg  c.age  i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1028.067 

*student
qui streg  c.age i.spacat  i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1029.659 

*n2
qui streg  c.age i.spacat i.baseline_student i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1024.363 

* anti6mon
qui streg  c.age i.spacat i.baseline_student i.baseline_n2, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1029.528  

* 2.age
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1031.495 

* 2.spacat
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age   i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
* 1029.017 

* 2.student
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.anti6mon )
estat ic
* 1029.674 

* 2.is
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.anti6mon i.baseline_student)
estat ic
*   1031.323   

* 2.6mon
qui streg  c.age i.spacat i.baseline_student i.baseline_n2 i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.baseline_student)
estat ic 
*   1029.834


***REMOVE n2: 1024.363 


*age
qui streg   i.spacat i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1028.336

*spcat
qui streg  c.age  i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*    1021.025  

*student
qui streg  c.age i.spacat   i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*    1022.638 


* anti6mon
qui streg  c.age i.spacat i.baseline_student , dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*    1022.531

* 2.age
qui streg  c.age i.spacat i.baseline_student  i.anti6mon, dist(weibull)  anc(i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1024.345  

* 2.spacat
qui streg  c.age i.spacat i.baseline_student i.anti6mon, dist(weibull)  anc(c.age   i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1021.88 

* 2.student
qui streg  c.age i.spacat i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.anti6mon )
estat ic
*  1022.663 

* 2.is
qui streg  c.age i.spacat i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.anti6mon i.baseline_student)
estat ic
*  1024.126 

* 2.6mon
qui streg  c.age i.spacat i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.baseline_student)
estat ic
*  1022.865 

*** REMOVE: spacat : 1021.025 


*age
qui streg    i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*    1025.324 



*student
qui streg  c.age   i.anti6mon, dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*    1019.318 


* anti6mon
qui streg  c.age i.baseline_student , dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1019.163 

* 2.age
qui streg  c.age i.baseline_student  i.anti6mon, dist(weibull)  anc(i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*    1020.899  

* 2.spacat
qui streg  c.age  i.baseline_student i.anti6mon, dist(weibull)  anc(c.age   i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1029.84 

* 2.student
qui streg  c.age  i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.anti6mon )
estat ic
* 1019.338 

* 2.is
qui streg  c.age  i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.anti6mon i.baseline_student)
estat ic
*  1020.804

* 2.6mon
qui streg  c.age  i.baseline_student  i.anti6mon, dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.baseline_student)
estat ic
*   1019.571  

***REMOVE anti6mon :  1019.163 


*age
qui streg    i.baseline_student  , dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*     1023.324 



*student
qui streg  c.age   , dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  


* 2.age
qui streg  c.age i.baseline_student  , dist(weibull)  anc(i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*     1018.909 

* 2.spacat
qui streg  c.age  i.baseline_student , dist(weibull)  anc(c.age   i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*  1027.888 

* 2.student
qui streg  c.age  i.baseline_student  , dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.anti6mon )
estat ic
*   1017.413  

* 2.is
qui streg  c.age  i.baseline_student, dist(weibull)  anc(c.age i.spacat  i.anti6mon i.baseline_student)
estat ic
*   1018.879

* 2.6mon
qui streg  c.age  i.baseline_student, dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.baseline_student)
estat ic
*     1027.019   



*** REMOVE STUDENT :  1017.393 



*age
qui streg   , dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*      1025.083 


* 2.age
qui streg  c.age   , dist(weibull)  anc(i.spacat i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*       1017.294 

* 2.spacat
qui streg  c.age   , dist(weibull)  anc(c.age   i.baseline_iscurremp i.anti6mon i.baseline_student)
estat ic
*   1025.953  

* 2.student
qui streg  c.age    , dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.anti6mon )
estat ic
*    1015.414  

* 2.is
qui streg  c.age , dist(weibull)  anc(c.age i.spacat  i.anti6mon i.baseline_student)
estat ic
*   1016.987  

* 2.6mon
qui streg  c.age  , dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp i.baseline_student)
estat ic
*   1025.437        

*REMOVE  2.student :  1015.414 

*age
qui streg    , dist(weibull)  anc(c.age i.spacat i.baseline_iscurremp i.anti6mon )
estat ic
*      1023.199  

* 2.age
qui streg  c.age   , dist(weibull)  anc(i.spacat i.baseline_iscurremp i.anti6mon )
estat ic
*     1015.298   

* 2.spacat
qui streg  c.age   , dist(weibull)  anc(c.age   i.baseline_iscurremp i.anti6mon )
estat ic
*    1023.977 


* 2.is
qui streg  c.age , dist(weibull)  anc(c.age i.spacat  i.anti6mon )
estat ic
*    1015.313 

* 2.6mon
qui streg  c.age  , dist(weibull)  anc(c.age i.spacat  i.baseline_iscurremp )
estat ic
*    1023.578   



*** REMOVE 2.age: 1015.298 

*age
qui streg    , dist(weibull)  anc( i.spacat i.baseline_iscurremp i.anti6mon )
estat ic
*      1060.146   

 

* 2.spacat
qui streg  c.age   , dist(weibull)  anc(  i.baseline_iscurremp i.anti6mon )
estat ic
*   1023.135 


* 2.is
qui streg  c.age , dist(weibull)  anc( i.spacat  i.anti6mon )
estat ic
*    1015.047

* 2.6mon
qui streg  c.age  , dist(weibull)  anc( i.spacat  i.baseline_iscurremp )
estat ic
*  1024.016   

*** REMOVE 2.is:  1015.047
*age
qui streg    , dist(weibull)  anc( i.spacat  i.anti6mon )
estat ic
* 1062      

 

* 2.spacat
qui streg  c.age   , dist(weibull)  anc(  i.anti6mon )
estat ic
*  1021



* 2.6mon
qui streg  c.age  , dist(weibull)  anc( i.spacat  )
estat ic
* 1024

***DONE: Check no terms will go back in

gen name=""
foreach aaa in  "" "c.age" "i.month" "i.base2" "i.degrade" "i.carriage" "i.spacat" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.anti6mon" "i.antiprev" {
	capture streg  c.age `aaa', dist(weibull)  anc( i.anti6mon i.spacat)
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display "all and 1P " name
				estat ic
				}

	}	

* to beat: AIC =  1015.047
* sig = 1p antiprev, base2 ethnic - wtf? 
	
	



foreach aaa in  "" "c.age" "i.month" "i.base2" "i.degrade" "i.male" "i.spacat" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.antiprev" {
	capture streg  c.age , dist(weibull)  anc(i.anti6mon i.spacat `aaa')
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display "all and 2P " name
				estat ic
				}

	}	
* sig: i. antiprev,  base2,

**** OKAY, all in and let's go again (wtf?)


qui streg  c.age i.base2 ethnic i.antiprev, dist(weibull)  anc(i.base2 i.antiprev i.anti6mon i.spacat)
estat ic
*AIC:   991.1248 

****ANTIPREV 1P
qui streg  c.age i.base2 ethnic , dist(weibull)  anc(i.base2 i.antiprev i.anti6mon i.spacat)
estat ic
*   989.6298 

****ANTIPREV 2P
qui streg  c.age i.base2 ethnic i.antiprev, dist(weibull)  anc(i.base2 i.anti6mon i.spacat)
estat ic
*  989.222    

***BASE2 1p
 qui streg  c.age  ethnic i.antiprev, dist(weibull)  anc(i.base2 i.antiprev i.anti6mon i.spacat)
estat ic
*  989.6635

****BASE2 2p
qui streg  c.age i.base2 ethnic i.antiprev, dist(weibull)  anc( i.antiprev i.anti6mon i.spacat)
estat ic
* 989.399

***ETHNIC 1p
qui streg  c.age i.base2 i.antiprev, dist(weibull)  anc(i.base2 i.antiprev i.anti6mon i.spacat)
estat ic
*  1008.06 

*DROP: ANTIPREV 2P : 989.222   

****ANTIPREV 1P
qui streg  c.age i.base2 ethnic , dist(weibull)  anc(i.base2  i.anti6mon i.spacat)
estat ic
*  989.5516  


***BASE2 1p
 qui streg  c.age  ethnic i.antiprev, dist(weibull)  anc(i.base2  i.anti6mon i.spacat)
estat ic
*  987.6996 

****BASE2 2p
qui streg  c.age i.base2 ethnic i.antiprev, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic
*987.5536 

***ETHNIC 1p
qui streg  c.age i.base2 i.antiprev, dist(weibull)  anc(i.base2  i.anti6mon i.spacat)
estat ic
*   1006.141 


*********************
* DROP : Base2 2p : 987.5536 


****ANTIPREV 1P
qui streg  c.age i.base2 ethnic , dist(weibull)  anc( i.anti6mon i.spacat)
estat ic
*  987.9529 


***BASE2 1p
 qui streg  c.age  ethnic i.antiprev, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic
*  998

***ETHNIC 1p
qui streg  c.age i.base2 i.antiprev, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic
*   1004


*********** CHECK OTHER VARIABLES  
***Age
qui streg   i.base2 i.antiprev i.ethnic, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic
*   1035

** 2.anti6mon
qui streg  c.age i.base2 i.antiprev i.ethnic, dist(weibull)  anc( i.spacat)
estat ic
*997

*** 2. spacat
qui streg  c.age i.base2 i.antiprev i.ethnic, dist(weibull)  anc( i.anti6mon )
estat ic
*1006


**** OKAY now check higher order terms: target = 1034.861


qui streg  c.age i.base2 i.antiprev i.ethnic, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic
*  987.5536  

**compare to:

qui streg   c.age#i.base2 c.age i.antiprev i.ethnic, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic

qui streg   c.age#i.antiprev c.age i.base2 i.antiprev i.ethnic, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic

qui streg   c.age#i.base2 c.age i.base2 i.antiprev i.ethnic, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic

qui streg   c.age#i.ethnic c.age i.base2 i.antiprev i.ethnic, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic

**** sig! 

qui streg   c.age i.base2 i.antiprev i.ethnic, dist(weibull)  anc( i.anti6mon#i.spacat i.anti6mon i.spacat)
estat ic


*** removing nothing improves the model at this point

**** had a rethink: can't justify grouping of ethnicity  --talk to sarah
**If can model above, if not this one

****** what about adding?

* 1004.333


foreach aaa in  "" "i.month" "i.base2" "i.degrade" "i.carriage" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.anti6mon" "i.antiprev" {
	capture streg  c.age i.base2 i.antiprev `aaa', dist(weibull)  anc(i.anti6mon i.spacat)
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display "all and 1P " name
				estat ic
				}

	}	


	



foreach aaa in  "" "i.month" "i.degrade" "i.male" "i.baseline_student" "i.ethnic" "baseline_iscurremp" "baseline_hcrelemp" "i.baseline_n2" "i.antiprev" {
	capture streg  c.age i.base2 i.antiprev, dist(weibull)  anc( `aaa' i.anti6mon i.spacat)
	quietly replace name= "`aaa'"
	if _rc==0{ 
				display "all and 2P " name
				estat ic
				}

	}	
* sig: Only i.ethnic (not i.baseline_ethnic) see discuss point above



**********************************************
**Nearly there - one more discussion with Sarah.
**********************************************


qui streg   c.age i.base2 i.antiprev, dist(weibull)  anc( i.anti6mon i.spacat)
estat ic


* after discussion with Sarah: yes ignore ethnic, move everything to lambda if pos, reduce spacat to carriage

*swapping to carriage

qui streg   c.age i.base2 i.antiprev, dist(weibull)  anc( i.anti6mon i.carriage)
estat ic

*<3 AIC diff

* swapping everything to lambda

qui streg   c.age i.base2 i.antiprev i.anti6mon i.carriage, dist(weibull)
estat ic

* diff < 1 AIC

* try without i.antiprev


qui streg   c.age i.base2  i.anti6mon i.carriage, dist(weibull)
estat ic

* diff < 1 AIC

* at which point this agrees with model choice.

stepwise, pr(0.05) : streg age base2 antiprev anti6mon month degrade male baseline* carriage , dist(weibull)


**********************************************
***FINAL MODEL****
**********************************************
use "E:\users\amy.mason\Staph\Sept03\evengainbuild1.dta", clear
 

 streg   c.age i.base2 i.anti6mon i.carriage, dist(weibull)


save "E:\users\amy.mason\Staph\Sept03\evengainmodel1.dta", replace
* age
 *percentiles:        10%       25%       50%       75%       90
			*		19.0418   37.5661    55.729   65.8645    75.102
			
			
			
			
****************************GRAPH***************
use "E:\users\amy.mason\Staph\Sept03\evengainmodel1.dta", clear	
	
 streg   c.age i.base2 i.anti6mon i.carriage, dist(weibull)


* wish to estimate survival curve when age == 55, carriage = 0, base2=0, anti6mon=0

*** estimate p
nlcom exp(_b[ln_p:_cons])
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
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age 55; Recruitment positive; No carriage; No Antibiotics in last 6months") legend(off) ylabel(0(0.2)1);
#delimit cr
graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph", replace


* wish to estimate survival curve when age == 25, carriage = 0, base2=0, anti6mon=0

local age=25

*** estimate p
nlcom exp(_b[ln_p:_cons])
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
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age `age'") legend(off) ylabel(0(0.2)1);
#delimit cr
********
graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph", replace
 graph export "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.tif", as(tif)	replace		


* wish to estimate survival curve when age == 70, carriage = 0, base2=0, anti6mon=0

local age=70

*** estimate p
nlcom exp(_b[ln_p:_cons])
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
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age `age'") legend(off) ylabel(0(0.2)1);
#delimit cr
********
graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp3.gph", replace
 graph export "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp3.tif", as(tif) replace
* combine age graphs	

#delimit ;
graph combine "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph" "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp3.gph"
,  title("Effect of age on gain of staph carriage") subtitle( "Recruitment positive; No carriage; No Antibiotics in last 6months");
#delimit cr

graph save "E:\users\amy.mason\Staph\stmixgraph\Gain\age_effect.gph", replace
 graph export "E:\users\amy.mason\Staph\stmixgraph\Gain\age_effect.tif", as(tif)	replace		


****** RECRUITMENT

* RECRUITMENT POS
* wish to estimate survival curve when age == 55, spacat = 0, base2=0, anti6mon/antiprev=0

local age=55

*** estimate p
nlcom exp(_b[ln_p:_cons])
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
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Recruitment Pos") legend(off) ylabel(0(0.2)1);
#delimit cr
********
graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph", replace
	
	
*RECRUITMENT NEG


local age=55

*** estimate p
nlcom exp(_b[ln_p:_cons])
mat temp = r(b)
mat temp2 = r(V)
local p = temp[1,1]
local p_upper = temp[1,1]+1.96*sqrt(temp2[1,1])
local p_lower = temp[1,1]-1.96*sqrt(temp2[1,1])


*** estimate lambda
nlcom exp(_b[_t:_cons]+`age'*_b[_t:age] +_b[_t:1.base2])
mat temp3 = r(b)
mat temp4 = r(V)
local lam = temp3[1,1]
local lam_upper = temp3[1,1]+1.96*sqrt(temp4[1,1])
local lam_lower = temp3[1,1]-1.96*sqrt(temp4[1,1])




**** create graph of main line exp(-lambda t^p)



#delimit ;
twoway   function exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Recruitment Neg" ) legend(off) ylabel(0(0.2)1);
#delimit cr
********
graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph", replace


* combine them

* combine base2 graphs	

#delimit ;
graph combine "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph" "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph"
,  title("Effect of recruitment status on gain of staph carriage") subtitle(" Age 55 No carriage; No Antibiotics in last 6months or since last swab");
#delimit cr

graph save "E:\users\amy.mason\Staph\stmixgraph\Gain\base2_effect.gph", replace
 graph export "E:\users\amy.mason\Staph\stmixgraph\Gain\base2_effect.tif", as(tif)	replace		

	

***** CARRIAGE ****

local age=55

*** estimate p
nlcom exp(_b[ln_p:_cons])
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
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("No carriage") legend(off) ylabel(0(0.2)1);
#delimit cr
********

graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph", replace
	
*one spa type

local age=55

*** estimate p
nlcom exp(_b[ln_p:_cons])
mat temp = r(b)
mat temp2 = r(V)
local p = temp[1,1]
local p_upper = temp[1,1]+1.96*sqrt(temp2[1,1])
local p_lower = temp[1,1]-1.96*sqrt(temp2[1,1])


*** estimate lambda
nlcom exp(_b[_t:_cons]+`age'*_b[_t:age]+_b[_t:1.carriage])
mat temp3 = r(b)
mat temp4 = r(V)
local lam = temp3[1,1]
local lam_upper = temp3[1,1]+1.96*sqrt(temp4[1,1])
local lam_lower = temp3[1,1]-1.96*sqrt(temp4[1,1])




**** create graph of main line exp(-lambda t^p)



#delimit ;
twoway   function exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("One Spa Type") legend(off) ylabel(0(0.2)1);
#delimit cr
********
graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph", replace
	
*** Combine

#delimit ;
graph combine "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph" "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph"
,  title("Effect of current carriage of spa types on gain of new staph carriage") subtitle(" Age 55, Recruitment Pos, No Antibiotics in last 6months or since last swab");
#delimit cr

graph save "E:\users\amy.mason\Staph\stmixgraph\Gain\carriage_effect.gph", replace
 graph export "E:\users\amy.mason\Staph\stmixgraph\Gain\carriage_effect.tif", as(tif)	replace		


***** Effect of antibiotics

 **** no anti
 
 local age=55

*** estimate p
nlcom exp(_b[ln_p:_cons])
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
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("No Antibiotics") legend(off) ylabel(0(0.2)1);
#delimit cr
********

graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph", replace
	

* anti 6mon


 local age=55

*** estimate p
nlcom exp(_b[ln_p:_cons])
mat temp = r(b)
mat temp2 = r(V)
local p = temp[1,1]
local p_upper = temp[1,1]+1.96*sqrt(temp2[1,1])
local p_lower = temp[1,1]-1.96*sqrt(temp2[1,1])


*** estimate lambda
nlcom exp(_b[_t:_cons]+`age'*_b[_t:age]+_b[_t:1.anti6mon])
mat temp3 = r(b)
mat temp4 = r(V)
local lam = temp3[1,1]
local lam_upper = temp3[1,1]+1.96*sqrt(temp4[1,1])
local lam_lower = temp3[1,1]-1.96*sqrt(temp4[1,1])


**** create graph of main line exp(-lambda t^p)



#delimit ;
twoway   function exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Antibiotics in last 6 mons but not since last swab") legend(off) ylabel(0(0.2)1);
#delimit cr

graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp3.gph", replace
		

***** combine


#delimit ;
graph combine "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph" "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp3.gph"
,  title("Effect of antibiotics on gain of new staph carriage") subtitle(" Age 55, Recruitment Pos, No Antibiotics in last 6months or since last swab");
#delimit cr

graph save "E:\users\amy.mason\Staph\stmixgraph\Gain\anti_effect.gph", replace
 graph export "E:\users\amy.mason\Staph\stmixgraph\Gain\anti_effect.tif", as(tif)	replace		

	
	