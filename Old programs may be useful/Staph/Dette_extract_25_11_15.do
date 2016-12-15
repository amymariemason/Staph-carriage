* import requested patids data

import delimited E:\users\amy.mason\Staph\Oxf_gp_patids.txt, clear
save "E:\users\amy.mason\Staph\gp_patid.dta", replace


* get requested data (sex, age)
use  "E:\users\sarahw\small\miller\riskfactors_baseline.dta", clear

keep patid age male
duplicates drop
merge 1:m patid using "E:\users\amy.mason\Staph\gp_patid.dta", update
drop if _merge==1
sort patid

export delimited using "E:\users\amy.mason\Staph\Dette_extract_25_11_15.csv", replace
