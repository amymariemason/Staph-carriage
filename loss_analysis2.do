* project: staph carriage analysis
* author: Amy Mason
* loss analysis

set li 130

cap log close
log using loss_analysis2.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

************ create analysis set for loss of all spatypes


noi di "loss of spatypes from timepoint==0"

use "E:\users\amy.mason\staph_carriage\Datasets\record_per_spa.dta", clear
sort patid this_spa timepoint

* drop all spatypes not kept at start
by patid this_spa: keep if carriage_this_spa[1]==1| carriage_this_spa[2]==1
assert _N ==6120

* find when first loss of initial spatypes occurs
sort patid timepoint
by patid timepoint: egen carriage = max(carriage_this_spa)

duplicates drop patid timepoint, force

sort patid timepoint
by patid: gen confirmed_loss = (carriage[_n]==0 & carriage[_n+1]==0 & carriage[_n-1]>0 ) & _n!=_N & _n!=1 

gsort patid -confirmed_loss timepoint
by patid: gen firstevent = timepoint[1] if confirmed_loss[1]==1
by patid: replace firstevent = timepoint[_N] if confirmed_loss[1]==0
assert firstevent!=.
drop if timepoint > firstevent
drop if timepoint==0
stset timepoint, fail(confirmed_loss) id(patid)
assert _st==1

*** 
noi di "Kaplan-Meier"

sts graph, risktable ci
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\KM_loss2.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\KM_loss2.tif", replace


*****