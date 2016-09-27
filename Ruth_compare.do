use "E:\users\sarahw\small\miller\original\carriageALL.dta" , clear
rename id patid
keep patid
gen Ruth = 1
duplicates drop
save temp, replace

* now run cleaning data merged with this 

use "E:\users\amy.mason\staph_carriage\Datasets\raw_input.dta", clear
merge m:1 patid using temp, update


preserve
bysort patid: keep if _n==1
tab Ruth _merge, m
restore
drop _merge

* drop people who were recruited in hospital / non nasal swabs
noi di _n(5) _dup(80) "=" _n "(2) DROP NON-NASAL/ NON-GP RECRUITMENT PEOPLE" _n _dup(80) "=" 
* merge with group records
merge m:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\groups", update
assert _merge==3
drop _merge

preserve
bysort patid: keep if _n==1
tab Ruth Study, m
restore

drop if  StudyGroup!="C3 GP"

***********************

noi di _n(5) _dup(80) "=" _n "(3)REMOVE SWABS NOT RETURNED" _n _dup(80) "=" 
* Drop swabs that were not returned
gen flag = (Result=="")
noi summ flag if flag==1
noi di r(N) " swabs where no result entered on system"
noi tab spa if flag==1, m
noi summ flag if spa!="" & flag==1
noi di r(N) " missing result but have a spatype -> must have been returned, so keep"
replace flag=0 if spa!="" & flag==1
noi tab Received DateTaken if flag==1, m
noi summ flag if  flag==1 & (Rece!=. |DateT!=.)
noi di r(N) " missing result but have a received or taken date -> must have been returned, so keep"
replace flag=0 if  flag==1 & (Rece!=. |DateT!=.)
summ flag if flag==1
noi di r(N) " drop swabs where no result, return date, taken date OR spatype entered on system - not returned by partipant"


preserve
bysort patid flag: drop if _n>1
bysort patid: gen count = _N
bysort count: tab Ruth flag, m
* so no swabs drop an entire person
restore

bysort patid: gen count =_N
tab patid  if  flag==1 & Ruth==.
list if patid ==364
noi display "364:  only 2 swabs, second does not appear returned" 

drop if flag==1
drop flag count

preserve
bysort patid: keep if _n==1
tab Ruth Study, m
restore

*1123


noi di _n(5) _dup(80) "=" _n "(3) DROP SINGLE SWAB ONLY PEOPLE" _n _dup(80) "=" 
bysort patid: gen flag= 1 if _N==1


preserve
bysort patid: keep if _n==1
tab Ruth flag, m
restore


********** THIS IS THE DIFFERENCE  - Ruth also found 25 dropped out post-baseline = agreement on figures

571 -25 = 546

Then lose extra people because insisting on more records postbaseline
 -> 525 total.

