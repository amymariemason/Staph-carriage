
set li 130

cap log close
log using loss_analysis2.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

************ create analysis set for loss of all spatypes


noi di "loss of spatypes where gain seen in the study"

use "E:\users\amy.mason\staph_carriage\Datasets\record_per_spa.dta", clear
sort patid this_spa timepoint

* drop all spatypes that are present at timepoint ==0 or timepoint ==2
by patid this_spa: keep if carriage_this_spa[1]==0 & carriage_this_spa[2]==0
assert _N ==8612

* when to start counting
gen spaid = 10*patid+spacount
gsort spaid  -carriage_this_spa timepoint
by spaid: gen startevent = timepoint[1] if carriage_this_spa[1]>0
by spaid: drop if carriage_this_spa[1]==0
assert startevent!=.
assert _N==6944

* when event occurs
by spaid: gen confirmed_loss = (carriage_this[_n]==0 & carriage_this[_n+1]==0 & carriage_this[_n-1]>0 ) & _n!=_N & _n!=1 
gsort spaid -confirmed_loss timepoint
by spaid: gen firstevent = timepoint[1] if confirmed_loss[1]==1
by spaid: replace firstevent = timepoint[_N] if confirmed_loss[1]==0
assert firstevent!=.

* drop irrelevant records
drop if timepoint > firstevent
drop if timepoint<= startevent

stset timepoint, fail(confirmed_loss) id(spaid) origin(startevent)
assert _st==1

*** 
noi di "Kaplan-Meier"

sts graph, risktable ci
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\KM_loss3.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\KM_loss3.tif", replace


*****