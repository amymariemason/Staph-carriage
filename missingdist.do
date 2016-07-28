* check for missing spatypes in cost matrix

set li 130

cap log close
log using clean_maindata.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

**************

use "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", replace	
keep patid timepoint spatype
split spatype, p(/)
duplicates drop
drop spatype
reshape long spatype, i(patid timepoint) j(count)
keep spatype
duplicates drop

save "E:\users\amy.mason\staph_carriage\Datasets\allspas", replace

rename spatype spatype1
merge 1:m spatype1 using "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP", update
 keep if _merge==1
 keep spatype1
rename spatype1 spatype2
merge 1:m spatype2 using "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP", update
 keep if _merge==1
 keep spatype2
  rename spatype2 spatype
  drop if inlist(spatype, "", "contaminated")
 save "E:\users\amy.mason\staph_carriage\Datasets\missingfromBURPspas", replace
 

use "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", clear
keep patid spatype timepoint
split spatype, p(/)
drop spatype
reshape long spatype, i(patid timepoint) j(count)
merge m:1 spatype using "E:\users\amy.mason\staph_carriage\Datasets\missingfromBURPspas", update
 