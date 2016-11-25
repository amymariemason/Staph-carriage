
* NEWSPA.DO

* add in late checked spatypes -> creates spa_update2


set li 130

cap log close
log using newspa.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

*************************************************************************************************************
cd "E:\users\amy.mason\staph_carriage\Datasets"


import excel "E:\users\amy.mason\staph_carriage\Inputs\spa_types_donaby.xlsx", sheet("Sheet2") cellrange(B1:D86) clear
drop C
rename B spatype
split D, parse("-")
rename D1 patid
rename D2 timepoint
drop D
save "E:\users\amy.mason\staph_carriage\Datasets\spa_update.dta", replace

import excel "E:\users\amy.mason\staph_carriage\Inputs\spa_types_donaby.xlsx", sheet("repeats for 'new' types") clear
rename A spatype
rename B repeats
rename C spa_lookup

merge 1:m spatype using spa_update, update
drop if _merge==1
assert _merge ==2 | _merge==3

replace spatype=spa_lookup if _merge==3 & !inlist(spa_lookup, "unknown", "")
replace spatype="undeterminable" if spatype==""
* note this is not always the case, but was in these two cases.
keep patid timepoint spatype
rename spatype spa_update
destring patid, replace
destring timepoint, replace
save "E:\users\amy.mason\staph_carriage\Datasets\spa_update2.dta", replace
