******************MAKE GRAPH FROM STMIX****************
 
 
 *** est p_mix when knownaq==0


nlcom exp(_b[logit_p_mix:_cons])/(1+ exp(_b[logit_p_mix:_cons]))
mat pmix_k01_b = r(b) 
mat pmix_k01_V = r(V)
local pmix_k01 = pmix_k01_b[1,1]
local pmix_k01_upper = pmix_k01_b[1,1] + 1.96*sqrt(pmix_k01_V[1,1])
local pmix_k01_lower = pmix_k01_b[1,1] - 1.96*sqrt(pmix_k01_V[1,1])





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
mat lambda2_b = r(b) 
mat lambda2_V = r(V)
local lambda2 = lambda2_b[1,1]
local lambda2_upper = lambda2_b[1,1] + 1.96*sqrt(lambda2_V[1,1])
local lambda2_lower = lambda2_b[1,1] - 1.96*sqrt(lambda2_V[1,1])

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
note("p(mix)= `pmix_k01'");

#delimit cr
graph save E:\users\amy.mason\Staph\stmixgraph\temp\spatemp1.gph, replace
graph export E:\users\amy.mason\Staph\Sept03\stmixgraph\stmix_test.png, replace
