* add initial and ongoing burp distances to data

set li 130

cap log close
log using addspa.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

noi di "INITIAL DISTANCES"
* compared to timepoint 0,2

use "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", clear	

keep patid timepoint spatype
order patid timepoint spatype
replace spatype= subinstr(spatype, "contaminated", "",.)
bysort patid timepoint: assert _n==1
by patid: gen initialspa = spatype[1]
by patid: gen secondspa = spatype[2]
save temp, replace

use temp, clear
split spatype, p(/)
drop spatype
reshape long spatype, i(patid timepoint) j(current)

split initialspa, p(/)
split secondspa, p(/)
drop initialspa secondspa
rename secondspa1 initialspa6
rename secondspa2 initialspa7
rename secondspa3 initialspa8
rename secondspa4 initialspa9
rename secondspa5 initialspa10
reshape long initialspa, i(patid timepoint current) j(start)

rename spatype spatype1
rename initial spatype2

merge m:1 spatype1 spatype2 using "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP", update
drop if _merge==2
assert inlist(_merge,1,3)

rename _merge _merge1
rename dist dist1
rename spatype1 spatype_temp
rename spatype2 spatype1
rename spatype_temp spatype2

merge m:1 spatype1 spatype2 using "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP", update
drop if _merge==2
assert inlist(_merge,1,3)

assert dist==. if dist1!=.
assert dist1==. if dist!=.

gen masterdist = min(dist1, dist)
replace masterdist=0 if spatype1==spatype2
replace masterdist=1000 if spatype1=="" & spatype2!=""
replace masterdist=1000 if spatype2=="" & spatype1!=""

assert masterdist!=.
keep patid timepoint masterdist current start spa*
sort patid timepoint current start

* first find minimum distance between each current spatype and the initial set 
by patid timepoint current: egen minCOST = min(masterdist)

* then find the maximum of these over the various current spatypes
by patid timepoint: egen maxCOST_init = max(minCOST)

keep patid timepoint maxCOST
duplicates drop

save "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP_init", replace

********************************************************************
* BURP costs for  previous spa types (compare to n-1, n-2)

noi di "PREVIOUS SWAB DISTANCES"
* compared to timepoint 0,2

use "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", clear	

keep patid timepoint spatype
order patid timepoint spatype
replace spatype= subinstr(spatype, "contaminated", "",.)
bysort patid timepoint: assert _n==1
by patid: gen onebehindspa = spatype[_n-1] if _n>1
by patid: replace onebehindspa = spatype[1] if _n==1
by patid: gen twobehingsspa =spatype[_n-2] if _n>2
by patid: replace twobehingsspa =spatype[2] if _n<=2
save temp, replace

use temp, clear
split spatype, p(/)
drop spatype
reshape long spatype, i(patid timepoint) j(current)

split onebehindspa, p(/)
split twobehingsspa, p(/)
drop onebehindspa twobehingsspa
rename twobehingsspa1 onebehindspa6
rename twobehingsspa2 onebehindspa7
rename twobehingsspa3 onebehindspa8
rename twobehingsspa4 onebehindspa9
rename twobehingsspa5 onebehindspa10
reshape long onebehindspa, i(patid timepoint current) j(start)

rename spatype spatype1
rename onebehind spatype2

merge m:1 spatype1 spatype2 using "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP", update
drop if _merge==2
assert inlist(_merge,1,3)

rename _merge _merge1
rename dist dist1
rename spatype1 spatype_temp
rename spatype2 spatype1
rename spatype_temp spatype2

merge m:1 spatype1 spatype2 using "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP", update
drop if _merge==2
assert inlist(_merge,1,3)

assert dist==. if dist1!=.
assert dist1==. if dist!=.

gen masterdist = min(dist1, dist)
replace masterdist=0 if spatype1==spatype2
replace masterdist=1000 if spatype1=="" & spatype2!=""
replace masterdist=1000 if spatype2=="" & spatype1!=""
assert masterdist!=.
keep patid timepoint masterdist current start 
sort patid timepoint current start

* first find minimum distance between each current spatype and the initial set 
by patid timepoint current: egen minCOST = min(masterdist)

* then find the maximum of these over the various current spatypes
by patid timepoint: egen maxCOST_prev = max(minCOST)

keep patid timepoint maxCOST
duplicates drop

save "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP_prev", replace
merge 1:1 patid timepoint using "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP_init", update
assert _merge==3
drop _merge

merge 1:1 patid timepoint using "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", update
assert _merge==3
drop _merge

save "E:\users\amy.mason\staph_carriage\Datasets\clean_data2.dta", replace