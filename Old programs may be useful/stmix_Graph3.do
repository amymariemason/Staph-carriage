******************MAKE GRAPH FROM STMIX****************
 

 nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]))
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]+_b[logit_p_mix:knownaquis])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:base2]+_b[logit_p_mix:knownaquis]))
 nlcom exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis])/(1+ exp(_b[logit_p_mix:_cons]+_b[logit_p_mix:knownaquis]))
 
******

 ***est lambda1

nlcom exp(_b[ln_lambda1:_cons])
mat lambda1_b = r(b) 
mat lambda1_V = r(V)
local lambda1 = lambda1_b[1,1]
local lambda1_upper = lambda1_b[1,1] + 1.96*sqrt(lambda1_V[1,1])
local lambda1_lower = lambda1_b[1,1] - 1.96*sqrt(lambda1_V[1,1]) 


*if  spacat =1
nlcom exp(_b[ln_lambda1:_cons]+_b[ln_lambda1:spacat])
mat lambda1_b1 = r(b) 
mat lambda1_V1 = r(V)
local lambda11 = lambda1_b1[1,1]
local lambda11_upper = lambda1_b1[1,1] + 1.96*sqrt(lambda1_V1[1,1])
local lambda11_lower = lambda1_b1[1,1] - 1.96*sqrt(lambda1_V1[1,1]) 




**** est  lambda2
nlcom exp(_b[ln_lambda2:_cons])
mat lambda2_b = r(b) 
mat lambda2_V = r(V)
local lambda2 = lambda2_b[1,1]
local lambda2_upper = lambda2_b[1,1] + 1.96*sqrt(lambda2_V[1,1])
local lambda2_lower = lambda2_b[1,1] - 1.96*sqrt(lambda2_V[1,1])


*if antiprev=1
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:anti6mon])
mat lambda2_b1 = r(b) 
mat lambda2_V1 = r(V)
local lambda21 = lambda2_b1[1,1]
local lambda21_upper = lambda2_b1[1,1] + 1.96*sqrt(lambda2_V1[1,1])
local lambda21_lower = lambda2_b1[1,1] - 1.96*sqrt(lambda2_V1[1,1]) 

*if antiprev=1 & spacat=1
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:anti6mon]+_b[ln_lambda2:spacat])
mat lambda2_b3 = r(b) 
mat lambda2_V3 = r(V)
local lambda23 = lambda2_b3[1,1]
local lambda23_upper = lambda2_b3[1,1] + 1.96*sqrt(lambda2_V3[1,1])
local lambda23_lower = lambda2_b3[1,1] - 1.96*sqrt(lambda2_V3[1,1]) 


*if spacat=1
nlcom exp(_b[ln_lambda2:_cons]+_b[ln_lambda2:spacat])
mat lambda2_b4 = r(b) 
mat lambda2_V4 = r(V)
local lambda24 = lambda2_b4[1,1]
local lambda24_upper = lambda2_b4[1,1] + 1.96*sqrt(lambda2_V4[1,1])
local lambda24_lower = lambda2_b4[1,1] - 1.96*sqrt(lambda2_V4[1,1]) 




**** est  gamma1
 nlcom exp(_b[ln_gamma1:_cons])
 mat gamma1_b = r(b) 
mat gamma1_V = r(V)
local gamma1 = gamma1_b[1,1]
local gamma1_upper = gamma1_b[1,1] + 1.96*sqrt(gamma1_V[1,1])
local gamma1_lower = gamma1_b[1,1] - 1.96*sqrt(gamma1_V[1,1])

**** est  gamma2
 nlcom exp(_b[ln_gamma2:_cons])
 mat gamma2_b = r(b) 
mat gamma2_V = r(V)
local gamma2 = gamma2_b[1,1]
local gamma2_upper = gamma2_b[1,1] + 1.96*sqrt(gamma2_V[1,1])
local gamma2_lower = gamma2_b[1,1] - 1.96*sqrt(gamma2_V[1,1])




****graph these
*null
#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda2_lower'*x^`gamma2_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda2_upper'*x^(`gamma2_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda2'*x^(`gamma2')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace

#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note(" no antibiotics, single spa");
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\join1.gph, replace

* anti yes, spa <=1

#delimit ;
twoway function exp(-`lambda11_lower'*x^`gamma1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda11_upper'*x^(`gamma1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda11'*x^(`gamma1')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda21_lower'*x^`gamma2_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda21_upper'*x^(`gamma2_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda21'*x^(`gamma2')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace

#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note(" antibiotics, single spa");
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\join2.gph, replace

* anti yes, spa >1

#delimit ;
twoway function exp(-`lambda11_lower'*x^`gamma1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda11_upper'*x^(`gamma1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda11'*x^(`gamma1')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda23_lower'*x^`gamma2_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda23_upper'*x^(`gamma2_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda23'*x^(`gamma2')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace

#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note(" antibiotics, multiple spa");
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\join4.gph, replace

* anti no, spa >1

#delimit ;
twoway function exp(-`lambda1_lower'*x^`gamma1_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda1_upper'*x^(`gamma1_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda1'*x^(`gamma1')), range(0 30) lcolor(edkblue) legend(order(3 "Rate 1"));
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph, replace

#delimit ;
twoway   function exp(-`lambda24_lower'*x^`gamma2_lower'), range (0 30) lcolor(ltblue) recast(area) fcolor(ltblue) 
||function exp(-`lambda24_upper'*x^(`gamma2_upper')), range (0 30) lcolor(white) recast(area) fcolor(white) 
||function exp(-`lambda24'*x^(`gamma2')), range(0 30) lcolor(edkblue)  legend(order(3 "Rate 2")) ylabel(0(0.2)1);


#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph, replace

#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\temp.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\temp2.gph",
row(1) graphregion(color(white)) xsize(7) ysize(4)
note(" no antibiotics, multiple spa");
#delimit cr

graph save E:\users\amy.mason\Staph\stmixgraph\temp\join3.gph, replace


#delimit ;
graph combine 
"E:\users\amy.mason\Staph\stmixgraph\temp\join1.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\join2.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\join3.gph"
"E:\users\amy.mason\Staph\stmixgraph\temp\join4.gph",
row(2) graphregion(color(white)) xsize(7) ysize(4)
note("pmix = 0.173 if recruit pos and unknown aquisition" "pmix = 0.277 if recruitment neg and unknown aquisition" "pmix=0.608 if recruitment neg and known aquisition" "pmix = 0.458 if recruitment pos and known aquisition" );

#delimit cr
graph save E:\users\amy.mason\Staph\stmixgraph\temp\spatemp1.gph, replace
graph export E:\users\amy.mason\Staph\Sept03\stmix_all.png, replace
