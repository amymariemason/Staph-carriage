* project: staph carriage analysis
* author: Amy Mason
* loss analysis

set li 130

cap log close
log using loss_analysis.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

************ create analysis set for loss of all spatypes


noi di "loss of all spatypes"

use "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
assert _N==8949

* drop if the person is not carrying any spatypes at start
sort patid timepoint
by patid: drop if confirmedneg[1]==1 & timepoint[1]==0
assert _N==5785
noi tab Follow if timepoint==0
no di "note some people initially recruited as negative had positive swabs at 1 month"

gsort patid -confirmedneg timepoint
by patid: gen firstevent = timepoint[1] if confirmedneg[1]==1
by patid: replace firstevent = timepoint[_N] if confirmedneg[1]==0
assert firstevent!=.
drop if timepoint > firstevent
drop if timepoint==0
stset timepoint, fail(confirmedneg) id(patid)
assert _st==1

*** 
noi di "Kaplan-Meier"

sts graph, risktable ci
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\KM_loss1.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\KM_loss1.tif", replace

*****

