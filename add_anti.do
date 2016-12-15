************************************************
*add_spa.DO
************************************************
** add antibiotics usage indicators to main dataset and merge in baseline data
* one to indicate antibiotics taken between this swab and last, 
* one to indicate antibiotics taken in last 6 months
* INPUTS:   clean_data2 (from add_spa), antistaph_antibiotics_nooverlap (from antibiotics)
*OUTPUTS : clean_data3
* written by Amy Mason


set li 130

cap log close
log using addanti.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

************** integrate with cleaned swab data
*data from antibiotics.do
use "E:\users\amy.mason\staph_carriage\Datasets\antistaph_antibiotics_nooverlap", clear
noi di "Integrate with swab data"

gen diff = DateEnded-DateStarted +1
assert diff>=0
expand diff
sort patid DateStarted True
by patid DateStarted True: gen newDate = DateStarted +_n -1
format newDate %td

keep patid newDate 
duplicates drop

rename newDate BestDate
gen antistaph=1

summ patid
noi di r(N) " antibiotic days in all participants"

append using "E:\users\amy.mason\staph_carriage\Datasets\clean_data2.dta"
keep patid timepoint BestDate antistaph
replace antistaph=0 if antistaph==.
format BestDate %td

gsort patid -BestDate
by patid: replace timepoint = timepoint[_n-1] if timepoint==.

* set of antibiotic results with missing timepoint: these are all the dates extending past the last swab. 
* just drop, don't need results past last swab on record
drop if timepoint==.

* keep only the latest antibiotic taking before each swab
gsort patid timepoint -antistaph
by patid timepoint: drop if _n>1 & antistaph==1

* reshape to ease comparing dates
reshape wide BestDate, i(patid timepoint) j(antistaph)
rename BestDate0 BestDate
rename BestDate1 LastAntiDate

sort patid timepoint
by patid: replace LastAntiDate = Last[_n-1] if Last==.

* add days since first swab for antibiotics/further swabs *

gsort patid timepoint 
by patid: gen day_no = BestDate-BestDate[1]


* add days since antibiotic last taken 
gen days_since_anti = BestDate - LastAntiDate
gsort patid timepoint
by patid: gen last_anti_day = LastAnti-BestDate[1]
label variable last_anti_day "last antibiotics taken by patient"

************ add markers 
* since last swab indicator
noi di "swabs with antibiotics taken between previous swab and current one"
gen prev_anti= (LastAntiDate>BestDate[_n-1] & LastAntiDate!=.)
label variable prev_anti "staph antibiotics taken since last swob"
noi tab prev_anti

* 6 month indicator 
noi display "swabs with antibiotics taken in previous 6 months"
gen prev_anti_6mon =0
replace prev_anti_6mon =1 if days_since<180 
label variable prev_anti_6mon "staph antibiotics taken last six months"
noi tab prev_anti_6mon

* tidy up working variables

keep patid timepoint prev_anti prev_anti_6mon

save  "E:\users\amy.mason\staph_carriage\Datasets\AntiStaph_markers", replace

* merge into data + spatypes from add_spa.do
merge 1:1 patid timepoint using "E:\users\amy.mason\staph_carriage\Datasets\clean_data2.dta", update
assert _merge==3
drop _merge


* merge in the baseline data from baseline.do
noi di "add baseline data"

merge m:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\baseline_data", update
assert _merge==3
drop _merge

* save the data
noi save "E:\users\amy.mason\staph_carriage\Datasets\clean_data3.dta", replace




