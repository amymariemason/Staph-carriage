


* small program to visualise main spline effects to add model fitting
cap prog drop PlotSpline
prog def PlotSpline
qui {
   syntax, varstub(string) knots(integer)
   preserve
   bysort `varstub': drop if _n>1
   if `knots'==3 gen plot = `varstub'C_1*_b[`varstub'C_1]+`varstub'C_2*_b[`varstub'C_2]
   else if `knots'==4 gen plot = `varstub'c_1*_b[`varstub'c_1]+`varstub'c_2*_b[`varstub'c_2]+`varstub'c_3*_b[`varstub'c_3]
   else if `knots'==5 gen plot = `varstub'd_1*_b[`varstub'd_1]+`varstub'd_2*_b[`varstub'd_2]+`varstub'd_3*_b[`varstub'd_3]+`varstub'd_4*_b[`varstub'd_4]
   else if `knots'==6 gen plot = `varstub'e_1*_b[`varstub'e_1]+`varstub'e_2*_b[`varstub'e_2]+`varstub'e_3*_b[`varstub'e_3]+`varstub'e_4*_b[`varstub'e_4]+`varstub'e_5*_b[`varstub'e_5]
   else err 666
   scatter plot `varstub', sort
}
end


set li 130

cap log close
log using gain_analysis2.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

************ create analysis set for gain of new spatype


noi di "gain of spatype distinct from previous spatypes"

use "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
assert _N==8949

gsort patid -newspa_prev timepoint
by patid: gen firstevent = timepoint[1] if newspa_p[1]==1
by patid: replace firstevent = timepoint[_N] if newspa_p[1]==0
assert firstevent!=.
drop if timepoint > firstevent
drop if timepoint==0
stset timepoint, fail(newspa_prev) id(patid)
* NOTE GAIN MARKER = newspa_prev; it is not single failure per person, but stata deals with that
assert _st==1

*** 
noi di "Kaplan-Meier"

sts graph, by(Follow) risktable failure
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\KM_gain2.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\KM_gain2.tif", as(tif) replace

* log-cumulative graph of survival
noi di "Log-cumulative graph of survival"

stphplot, by(Follow)
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\log_cum_gain2.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\log_cum_gain2.tif", as(tif)  replace



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
forval i=3(3)6{
   noi di _c "..`i'"
   *qui stpm2 Follow, scale(hazard) df(`i') cure
   *qui est store stpm_`i'_cure
   forval j=2(1)`i' {
      qui stpm2 Follow, scale(hazard) df(`i') tvc(Follow) dftvc(`j') cure
      qui est store stpm_`i'_`j'_cure
   }
   *noi est stats _all
}   

noi est stats _all
noi di _n "- AIC minimum at df=5 dftvc=1"
