* clean up spa data

set li 130

cap log close
log using spaclean.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"


* create list of all spatypes
use "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", clear
keep patid timepoint spatype
split spatype, parse(/)
drop spatype
reshape long spatype, i(patid timepoint) j(spanum)
drop if spatype==""

* merge with CC groups data
merge m:1 spatype using "E:\users\amy.mason\staph_carriage\Datasets\CC", update

replace CCname="new " + spatype if _merge==1 & strpos(spatype, "tx")
replace CC="999" if strpos(CCname, "new")
noi di "new spatypes that were not on Ridom database"
noi list if CC=="999"
assert CC!="" if _merge==1
drop if _merge==2
assert inlist(_merge, 1,3)
drop _merge

* save matching of spatypes to CC
preserve
keep spatype CC CCname
duplicates drop
save "E:\users\amy.mason\staph_carriage\Datasets\CCnames", replace
restore

* start counting types
sort spatype CC 
noi by spatype: assert CC[_n]==CC[1]
gen count=1

collapse (sum) count, by(spatype CC CCname)
summ count
noi di "Number of distinct spatypes seen " r(N)
noi di "list of spatypes where more than 100 samples seens"
noi list spatype CC* count if count> 100 

summ count if strpos(CC, "#")
noi display r(N) " distinct standalone spatypes found in " r(sum) " samples"
noi di "stand alone samples"
sort CC
noi list spatype CC if  strpos(CC, "#")

summ count if strpos(CCname, "no")
noi display r(N) " distinct spatypes in CC with no founder, found in " r(sum) " samples"
noi list spatype CC* count if strpos(CCname, "no")

summ count if strpos(CC, "Ex")
noi display r(N) " distinct spatypes excluded, found in " r(sum) " samples"
noi list spatype CC* count if  strpos(CC, "Ex")

collapse (sum) count, by(CC CCname)
summ count if !strpos(CCname, "new")
noi di "Number of distinct CC seen (including standalones, excluding new) " r(N)
gsort count
noi di "CC with more than 200 samples seen" 
noi list CC* count if count >200

collapse (sum) count, by (CCname)
drop if CCname=="" | strpos(CCname, "new")
summ count
noi di "Number of distinct CC seen (excluding standalones and new) " r(N)


******************************************************************************************************
*distances of spatypes

use "E:\users\amy.mason\staph_carriage\Datasets\BURP", clear

* extract sample names
gen sample1= strpos( species1, "t")
assert sample1!=0 & sample1!=.
gen sub1= substr( species1, sample1,.)
drop sample1
gen sample1= strpos(sub1, " ")
gen subsub1 = sub1 if sample1==0
replace subsub1= substr(sub1,1, sample1-1) if sample1!=0
drop sample1
gen sample1= strpos(subsub1, " ")
assert sample1==0
drop sample1 sub1 species1
rename subsub1 spatype1

gen sample2= strpos( species2, "t")
assert sample2!=0 & sample2!=.
gen sub2= substr( species2, sample2,.)
drop sample2
gen sample2= strpos(sub2, " ")
gen subsub2 = sub2 if sample2==0
replace subsub2= substr(sub2,1, sample2-1) if sample2!=0
drop sample2
gen sample2= strpos(subsub2, " ")
assert sample2==0
drop sample2 sub2 species2
rename subsub2 spatype2

save "E:\users\amy.mason\staph_carriage\Datasets\spa_BURP", replace
*
**************************************************************


cd "E:\users\amy.mason\staph_carriage\Programs"