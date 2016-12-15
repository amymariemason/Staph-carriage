		
			
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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')), range(0 50) lcolor(edkblue)  title(" 1- Survival curve for gain of staph carriage") subtitle("Age 55; Recruitment positive; No carriage; No Antibiotics in last 6months") legend(off) ylabel(0(0.2)1);
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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')),  range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age `age'") legend(off) ylabel(0(0.2)1);
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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')),  range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Age `age'") legend(off) ylabel(0(0.2)1);
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
 graph export "E:\users\amy.mason\Staph\stmixgraph\Gain\minus_age_effect.tif", as(tif)	replace		


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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')),  range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Recruitment Pos") legend(off) ylabel(0(0.2)1);
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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')),  range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Recruitment Neg" ) legend(off) ylabel(0(0.2)1);
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
 graph export "E:\users\amy.mason\Staph\stmixgraph\Gain\minus_base2_effect.tif", as(tif)	replace		

	

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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')),  range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("No carriage") legend(off) ylabel(0(0.2)1);
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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')),  range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("One Spa Type") legend(off) ylabel(0(0.2)1);
#delimit cr
********
graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph", replace
	
*** Combine

#delimit ;
graph combine "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph" "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp2.gph"
,  title("Effect of current carriage of spa types on gain of new staph carriage") subtitle(" Age 55, Recruitment Pos, No Antibiotics in last 6months or since last swab");
#delimit cr

graph save "E:\users\amy.mason\Staph\stmixgraph\Gain\carriage_effect.gph", replace
 graph export "E:\users\amy.mason\Staph\stmixgraph\Gain\minus_carriage_effect.tif", as(tif)	replace		


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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')),  range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("No Antibiotics") legend(off) ylabel(0(0.2)1);
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
twoway   function 1- exp(-`lam_upper'*x^(`p_upper')), range (0 50) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function 1- exp(-`lam_lower'*x^`p_lower'), range (0 50) lcolor(white) recast(area) fcolor(white) 
||function 1- exp(-`lam'*x^(`p')),  range(0 50) lcolor(edkblue)  title("Survival curve for gain of staph carriage") subtitle("Antibiotics in last 6 mons but not since last swab") legend(off) ylabel(0(0.2)1);
#delimit cr

graph save "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp3.gph", replace
		

***** combine


#delimit ;
graph combine "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp1.gph" "E:\users\amy.mason\Staph\stmixgraph\temp\gaintemp3.gph"
,  title("Effect of antibiotics on gain of new staph carriage") subtitle(" Age 55, Recruitment Pos, No Antibiotics in last 6months or since last swab");
#delimit cr

graph save "E:\users\amy.mason\Staph\stmixgraph\Gain\anti_effect.gph", replace
 graph export "E:\users\amy.mason\Staph\stmixgraph\Gain\minus_anti_effect.tif", as(tif)	replace		

	
	
