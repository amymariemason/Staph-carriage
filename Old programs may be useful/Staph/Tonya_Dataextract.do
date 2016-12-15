**************************************************************
* extract of patients who are known to aquire carriage in study
**************************************************************

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear

sort patid timepoint
gen byte gainevent=0
by patid: replace gainevent=1 if State[_n]==1&State[_n-1]==0&State[_n-2]==0 &_n>=2
egen KnownAquisition = max(gainevent), by(patid)

keep patid timepoint State spatype* gainevent KnownAquisition


gen byte gainevent_three=0
by patid: replace gainevent_three=1 if State[_n-3]==0&State[_n]==1&State[_n-1]==0&State[_n-2]==0 &_n>=3
egen KnownAquisition_three = max(gainevent_three), by(patid)

drop if  KnownAquisition==0

save  "E:\users\amy.mason\Staph\Tanya_extraction", replace

export delimited using "E:\users\amy.mason\Staph\Tanya_extraction", quote replace
