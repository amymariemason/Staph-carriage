* GAIN_ANALYSIS.DO

* project: staph carriage analysis
* author: Amy Mason


* small program to visualise main spline effects to add model fitting
cap prog drop PlotSpline
prog def PlotSpline
qui {
   syntax, var(string) varstub(string) knots(integer)
   preserve
   bysort `varstub': drop if _n>1
   if `knots'==3 gen plot = `var'C_1*_b[`varstub'C_1]+`var'C_2*_b[`varstub'C_2]
   *else if `knots'==4 gen plot = `var'c_1*_b[`varstub'c_1]+`varstub'c_2*_b[`varstub'c_2]+`varstub'c_3*_b[`varstub'c_3]
   *else if `knots'==5 gen plot = `var'd_1*_b[`varstub'd_1]+`varstub'd_2*_b[`varstub'd_2]+`varstub'd_3*_b[`varstub'd_3]+`varstub'd_4*_b[`varstub'd_4]
   *else if `knots'==6 gen plot = `var'e_1*_b[`varstub'e_1]+`varstub'e_2*_b[`varstub'e_2]+`varstub'e_3*_b[`varstub'e_3]+`varstub'e_4*_b[`varstub'e_4]+`varstub'e_5*_b[`varstub'e_5]
   else err 666
   scatter plot `varstub', sort
}
end


set li 130

cap log close
log using gain_analysis.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

************ create analysis set for gain of new spatype


noi di "gain of spatype distinct from initial spatypes"

use "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
assert _N==8949

gsort patid -newspa_init timepoint
by patid: gen firstevent = timepoint[1] if newspa_i[1]==1
by patid: replace firstevent = timepoint[_N] if newspa_i[1]==0
assert firstevent!=.
drop if timepoint > firstevent
drop if timepoint==0
stset timepoint, fail(newspa_init) id(patid)
* NOTE GAIN MARKER = newspa_init; it is not single failure per person, but stata deals with that
assert _st==1

*** 
noi di "Kaplan-Meier"

sts graph, by(Follow) risktable failure
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\KM_gain.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\KM_gain.tif", replace

* log-cumulative graph of survival
noi di "Log-cumulative graph of survival"

stphplot, by(Follow)
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\log_cum_gain.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\log_cum_gain.tif", replace

* linear in log-log graph? less so than shorter estimates (though not parellel)


* look at stpm2

foreach var of varlist Sex Ethnic_group residence_group CurrentlyEm HealthcareR SportsActivity LookAfter VascularAccess Catheter inpatient inpatient_summ household_group districtnurse DistrictNurse_summ skin surgery surgery_summ GP GP_summ {
di "`var'"
encode `var', gen(`var'_cat)
drop `var'
rename `var'_cat `var'
}

* identify df using aIC
cap est drop _all
* test different df for baseline and tvc hazard with adm_we
forval i=1(1)6{
   noi di _c "..`i'"
   qui stpm2 Follow, scale(hazard) df(`i')
   qui est store stpm_`i'
   forval j=1(1)`i' {
      qui stpm2 Follow, scale(hazard) df(`i') tvc(Follow) dftvc(`j')
      qui est store stpm_`i'_`j'
   }
   *noi est stats _all
}   
* test different df for baseline and tvc hazard with adm_we
forval i=3(1)6{
   noi di _c "..`i'"
   qui stpm2 Follow, scale(hazard) df(`i') cure
   qui est store stpm_`i'_cure
   forval j=1(1)`i' {
      qui stpm2 Follow, scale(hazard) df(`i') tvc(Follow) dftvc(`j') cure
      qui est store stpm_`i'_`j'_cure
   }
   *noi est stats _all
}   

noi est stats _all
noi di _n "- AIC minimum at df=5 dftvc=1"

* plot this




* only predict for one observation per _t
bysort _t: gen time=_t if _n==1
predict h0, hazard   at(Follow 0) zeros timevar(time)
predict h1, hazard   at(Follow 1) zeros timevar(time)
predict s0, survival at(Follow 0) zeros timevar(time)
predict s1, survival at(Follow 1) zeros timevar(time)
predict hdiff,   hdiff1(Follow 0) hdiff2(Follow 1) ci  timevar(time)
predict sdiff,   sdiff1(Follow 0) sdiff2(Follow 1) ci  timevar(time)
noi di _n "On per 1 day scale"
noi summ h0 h1 s0 s1 sdiff
* rescale hazards per 100 rather than per 1 person-day(s)
for var h0 h1 hdiff*: replace X=X*100
noi di _n "Rescaling hazards per 100 days"
noi summ h0 h1 s0 s1 sdiff

scatter h0 h1 time, sort c(l l) s(i i) color(blue red) graphregion(color(white)) /*
*/  ytitle(Gain of Spa-type risk per 100 person-days) /*
*/  xtitle(Days from first swab, size(medlarge))  /*
*/  legend(order( 1 "Carriage at t=0" 2 "No carriage at t=0"))
*graph export graphs/figure4_modelA_abshaz.tif, replace
*graph export graphs/figure4_modelA_abshaz.eps, replace
scatter s0 s1 time, sort c(l l) s(i i) color(blue red) graphregion(color(white)) /*
*/  ytitle(Survival)  /*
*/  xtitle(Days from admission, size(medlarge))/*
*/  legend(order( 1 "No carriage at t=0" 2 "Carriage at t=0"))
*graph export graphs/figure4_modelA_abssurv.tif, replace
gen yline=0
twoway rarea hdiff_uci hdiff_lci time, c(i) s(i) color(red*0.25) || /*
*/     scatter hdiff time, s(i) c(l) color(maroon) || /*
*/     scatter yline time, s(i) c(l) color(black) || /*
*/   , graphregion(color(white)) legend(off) /*
*/     xtitle(Days from admission, size(medlarge)) xlabel(0(7)21 30)  /*
*/     ytitle(Risk difference per 100 person-days) ylabel(-0.01(.01).03, angle(0)) yscale(range(-0.01 0.03))
*graph export graphs/figure4_modelA_diffhaz.tif, replace
*graph export graphs/figure4_modelA_diffhaz.eps, replace
twoway rarea sdiff_uci sdiff_lci time, c(i) s(i) color(red*0.25) || /*
*/     scatter sdiff time, s(i) c(l) color(maroon) || /*
*/     scatter yline time, s(i) c(l) color(black) || /*
*/   , graphregion(color(white)) legend(off) /*
*/     xtitle(Days from admission, size(medlarge)) xlabel(0(7)21 30)  /*
*/     ytitle(Survival difference per 100 person-days) ylabel(#6, angle(0)) 
*graph export graphs/figure4_modelA_diffsurv.tif, replace


* add cure












*look at cumh plot
sts generate cumh = na cumh_se = se(na)
gen upper = cumh+1.96*cumh_se
gen lower = cumh-1.96*cumh_se
graph twoway  rarea upper lower timepoint  if timepoint>2, yscale(log) xscale(log)|| line cumh timepoint if timepoint>2, yscale(log) xscale(log)

*consider a Weibull model
streg, distribution(weibull)
stcurve, name("surv1") outfile(stcurve1.dta, replace) cumhaz
preserve
rename t t_A 
append using stcurve1.dta
graph twoway  rarea upper lower timepoint  if cumh>0 , yscale(log) xscale(log) color(gs10) || line cumh timepoint if cumh>0, yscale(log) xscale(log) lwidth(medthick) || line cumha1 _t, yscale(log) xscale(log) lwidth(medthick) 

graph export "E:\users\amy.mason\staph_carriage\Graphs\weibull_cum_haz_gain1.tif", replace

restore

* NOT VERY CONVINCED, but start up weibull for practise

**********************************************************************************************************
* main categorical effects



foreach var of varlist prev_anti prev_anti_6mon prev_n_spa Sex Ethnic_group residence_group CurrentlyEm HealthcareR SportsActivity LookAfter VascularAccess Catheter inpatient inpatient_summ Follow household_group districtnurse DistrictNurse_summ skin surgery surgery_summ GP GP_summ LTI {
   noi di _n _dup(80) "=" _n "`var'" _n _dup(80) "=" 
   noi tab `var' newspa_init, row nokey m
   qui streg i.`var',distribution(weibull) 
   assert e(N)==6603
   noi streg
    qui streg ,distribution(weibull) anc(i.`var')
   noi streg
}

*  age

***************************************************************************************************
* truncate continuous predictors and create splines
***************************************************************************************************
* truncate continuous vars based on fat tails
noi tabstat age , c(s) s(n median iqr  min p75 p90 p95 p99 max)
* creat splines 
foreach var of varlist age{
   centile `var', normal centile(50)
   gen `var'c=`var'-r(c_1)
   cap mkspline `var'C_=`var'c, cubic nknots(3) 
   cap mkspline `var'c_=`var'c, cubic nknots(4) 
    cap mkspline `var'd_=`var'c, cubic nknots(5) 
	cap mkspline `var'e_=`var'c, cubic nknots(6)
   
   * variable indexed _1 is identical to agec, so can drop agec, so variables indexed _X are the spline terms
   drop `var'c
   noi summ `var'*
}  

* main continuous effects
cd "E:\users\amy.mason\staph_carriage\Graphs"
* age, nprioradm: test 3-6 knot splines, 7 only for age
foreach var of varlist age {
   noi di _n _dup(80) "=" _n "`var'" _n _dup(80) "=" 
   noi tabstat `var', by(newspa_init) c(s) s(n median p25 p75 min max)

   qui streg c.`var',distribution(weibull) 
   noi streg
   est store uv_`var'lin
   scalar biclin=-2*e(ll)+e(df_m)*2
   qui streg ,distribution(weibull) anc(c.`var')
   noi streg
   est store uv_`var'lin_anc
   scalar biclin_anc=-2*e(ll)+e(df_m)*2
   
   qui streg  c.`var'C_1 c.`var'C_2,distribution(weibull) 
   noi streg
   est store uv_`var'3k
   scalar bic3k=-2*e(ll)+e(df_m)*2
   PlotSpline, var(`var') varstub(`var') knots(3)
   graph export uv_`var'3k.tif, replace
   
   qui streg ,distribution(weibull) anc( c.`var'C_1 c.`var'C_2)
   noi streg
   est store uv_`var'3k_anc
   scalar bic3k_anc=-2*e(ll)+e(df_m)*2
   PlotSpline, var(`var')  varstub("ln_p:`var'") knots(3)
   ************* NOT CURRENTLY WORKING - doesn't like the varstub entry
   graph export uv_`var'3k_anc.tif, replace
   
   }
   
   
   
   qui streg c.`var'C_1 c.`var'C_2 ,distribution(weibull) 
   qui stcox 
   noi stcox
   est store uv_`var'3k
   scalar bic3k=-2*e(ll)+e(df_m)*2
   PlotSpline, varstub(`var') knots(3)
   graph export uv_`var'3k.tif, replace
   
   qui stcox c.`var'c_1 c.`var'c_2 c.`var'c_3
   noi stcox
   est store uv_`var'4k
   scalar bic4k=-2*e(ll)+e(df_m)*2
   PlotSpline, varstub(`var') knots(4)
   graph export uv_`var'4k.tif, replace
   
   qui stcox c.`var'd_1 c.`var'd_2 c.`var'd_3 c.`var'd_4
   noi stcox
   est store uv_`var'5k
   scalar bic5k=-2*e(ll)+e(df_m)*2
   PlotSpline, varstub(`var') knots(5)
   graph export uv_`var'5k.tif, replace
   

   
  assert bic3k<biclin & bic3k<bic4k & bic3k<bic5k 
   
}

}