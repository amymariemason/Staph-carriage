
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




****graph these


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
