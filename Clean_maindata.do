* Cleans up main dataset
* creates cleandata.dta

set li 130

cap log close
log using clean_maindata.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"


use "E:\users\amy.mason\staph_carriage\Datasets\raw_input.dta", clear
bysort patid: gen first=(_n==1)
summ first
noi di  " starting with " _N " records from " r(sum) " paticipants" 
drop first

*******************************************************************	
* add updates swab data
******************************************************************

merge m:1 patid timepoint using "E:\users\amy.mason\staph_carriage\Datasets\spa_update2.dta", update
assert inlist(_merge,1,3)
assert spatype=="" if _merge==3
gen count =1 if spatype=="" & spa_update!=""
summ count
noi di r(sum) " spa-types updates with Nov 2016 spa check"

gen prob = strpos(spa_update, "tx") | strpos(spa_update, "undet")
summ prob if count==1
noi di r(sum) " of " r(N) " of these updates are unknown in Ridom (tx) or were unable to be determined from lab results"
sort patid timepoint
noi list patid timepoint spa_update if prob ==1

replace spatype = spa_update if count==1
drop count prob spa_update _merge

*******************************************************************	
*1 drop people outside of study scope, or who didn't return swabs

* drop people who were recruited in hospital / non nasal swabs
noi di _n(5) _dup(80) "=" _n "(1) DROP NON-NASAL/ NON-GP RECRUITMENT PEOPLE" _n _dup(80) "=" 
* merge with group records
merge m:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\groups", update

assert _merge==3
drop _merge
noi tab StudyGroup
gen flag =1 if StudyGroup!="C3 GP"
summ flag if flag==1
noi di "drop " r(N) " records where either not from nose, or from hospital recuitement"
drop if flag ==1
bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop flag first



noi di _n(5) _dup(80) "=" _n "(2)REMOVE SWABS NOT RETURNED" _n _dup(80) "=" 
* Drop swabs that were not returned
gen flag = (Result==""| Result=="swab number created in error")
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
drop if flag==1
drop flag


*drop people who only returns a single swab

noi di _n(5) _dup(80) "=" _n "(3) DROP SINGLE SWAB ONLY PEOPLE" _n _dup(80) "=" 
bysort patid: gen flag= 1 if _N==1
noi summ flag if flag==1
noi di "drop " r(N) " participants who only returned single swab"
drop if flag ==1
bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop flag first

* drop timepoint 0 people
noi di _n(5) _dup(80) "=" _n "(4) DROP TIMEPOINT 0 in 2015 Swabs" _n _dup(80) "=" 
gen year= year(Sent)
bysort patid: gen flag= 1 if timepoint==0 & year==2014
noi summ flag
noi di "drop " r(N) " swabs  -  additional check swab in 2014 (not spa-typed)"
drop if flag ==1
bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop flag first


****************************************************************		
save "E:\users\amy.mason\staph_carriage\Datasets\input1.dta", replace	

use "E:\users\amy.mason\staph_carriage\Datasets\input1.dta", clear



****************************************************************************
*  4 : clean up dates
****************************************************************************
* Create Best Date = best guess at when swab was taken.
sort patid time

gen BestDate=DateTaken
replace BestDate=Received if BestDate==.
replace BestDate=Sent if BestDate==.
format BestDate %td
assert BestDate!=.

noi di _n(5) _dup(80) "=" _n "(5) EVALUATE DUBIOUS BEST DATES" _n _dup(80) "=" 
gen flag = (BestDate<Sent & Sent!=.)| (BestDate> Received) | (Received<Sent &Sent!=.)
noi summ flag if flag!=0
assert Sent!=. & Received!=. if flag==1
noi di r(N) " disputed dates  - no chronological order of Sent, Taken, Received" 
noi list patid timepoint Sent DateTaken  Received if flag!=0, sepby(patid)

* if can find a pair of dates in Sent, Taken, Received in correct order + within 30 days of each other -> accept as correct.
gen Diff_S_T =  DateTaken-Sent if DateTaken!=.
gen Diff_T_R =  Received - DateTaken if DateTaken!=.
gen Diff_S_R =  Received-Sent

foreach var of varlist Diff_S_T  Diff_T_R Diff_S_R{
replace `var'=. if `var'<0
}

egen closest = rowmin(Diff*)
summ flag if flag == 1 & closest <30
noi di r(N) " have a pair of dates in the correct order, within 30 days of each other."
noi di "If DateTaken is part of the optimal pair, keep BestDate as Date taken." 
summ flag if flag == 1 & (closest >=30| closest==.)
noi di r(N) "do not have pair in correct order"
gen BestPair =  "S_T" if closest==Diff_S_T & closest< 30
replace BestPair =  "T_R" if closest==Diff_T_R & closest< 30
replace BestPair =  "S_R" if closest==Diff_S_R & closest< 30
assert BestDate==DateTaken if inlist(BestPair, "T_R", "S_T")==1
summ flag if BestPair=="S_R" &flag==1
noi di r(N) " disordered date swabs with Sent/Recieved best pair, replace with Recieved)"
replace BestDate = Received if flag==1 & BestPair =="S_R"
replace flag=0 if BestPair!=""
summ flag if flag==1
noi di r(N) "disordered dates still remaining"
noi list patid timepoint Sent DateTaken  Received Diff* if flag!=0, sepby(patid)
drop Diff* closest BestPair

* 9 remaining: examine these nine in more detail
bysort patid: egen flagmax=max(flag)
replace flag=. if flag==0
sort patid timepoint
noi list SwabID patid timepoint Sent DateTaken  Received flag BestDate if flagmax!=0, sepby(patid)

*clear year typos
replace BestDate=d(19dec2011) if SwabID==9880
replace BestDate=d(27nov2009) if SwabID==2309
replace BestDate=d(03feb2015) if SwabID==13812
replace BestDate=d(14jan2012) if SwabID==10883
summ flag if inlist(SwabID, 9880, 2309, 13812, 10883)
noi di r(N) " disordered date swabs with clear year typos (usually in dec-> jan - replace with correct year"
replace flag=. if inlist(SwabID, 9880, 2309, 13812, 10883)

* impossible to determine accurate date between Sent/Received (Date Taken missing)
summ flag if flag==1
noi di r(N) "disordered dates swabs still remaining; impossible to decide on correct date leave as current best guess"
noi list patid timepoint Sent DateTaken  Received BestDate if flag==1, sepby(patid)
drop flag*

********************************************************************************

* SORT AMBIGUOUS RESULTS

*******************************************************************************
noi di _n(5) _dup(80) "=" _n "(5b)  people missing spatype data or mismatched result data" _n _dup(80) "=" 


* NOTE: this is an ongoing problem to be resolved; currently dropping unclear results so could start trying analysis
* in particular: of missing spatypes - 1261 is the only one pre 68 months where loss affected if reclassified from pos to neg

* some people have "Result" as MRSA and MSSA but no spatypes

gen carriage = "defpos" if inlist(Result, "MRSA", "MSSA") & spatype!=""
replace carriage ="defneg" if Result=="No growth" & spatype==""
replace carriage = "conflict: missing spatype" if Result!="No growth" & spatype==""
replace carriage = "conflict: incorrect Result/spa match" if Result=="No growth" & spatype!="" 
replace carriage = "Result missing" if Result ==""
assert carriage!=""
noi tab carriage

* conflict: missing spatype

gen missingspatype=1 if inlist(Result, "MRSA", "MSSA") & spatype==""
summ missingspatype
noi di r(sum) "drop: records with result says MRSA MSSA, but who have missing spatypes"
noi tab timepoint if missingspatype==1
noi list patid SwabID timepoint Result spatype  if missingspatype==1, sepby(patid)
noi drop if missingspa==1
noi drop missing*
*

* people where we could not determine spatype from result
gen missingspatype=1 if inlist(Result, "MRSA", "MSSA") & (strpos(spatype,"undet") | strpos(spatype, "contam"))
summ missingspatype
noi di r(sum) "drop: records with result says MRSA MSSA, but whose spatypes could not be determined"
noi tab timepoint if missingspatype==1
noi list patid SwabID timepoint Result spatype  if missingspatype==1, sepby(patid)
drop if missing==1
drop missing

* No growth, but have spatype

gen incorrect_result_query = 1 if Result=="No growth" & spatype!="" 
summ incorrect_result
noi di r(sum) "drop : records with result says No Growth, but who have spatypes"
noi tab timepoint if incorrect_result==1
noi list patid SwabID timepoint Result spatype if incorrect_result==1, sepby(patid)
by patid: egen incorrectmax=max(incorrect)
noi di "detail of those patids over time: in both cases spatypes not otherwise seen in those patid. Not first new spatype for either"
noi list patid SwabID timepoint Result spatype incorrect_result if incorrectmax==1, sepby(patid) // list out those with missing spatypes before 68 months
drop if incorrect_result==1
drop incorrect*

* Result value missing altogether
gen missing =1 if Result==""
summ missing
noi di r(sum) " drop: missing Result"
noi list patid SwabID timepoint Result spatype if Result==""
by patid: egen missingmax=max(missing)
noi di "detail of those patids over time: "
noi list patid SwabID timepoint Result spatype missing if missingmax==1, sepby(patid) // list out those with missing spatypes before 68 months
drop if missing==1
drop missing*

* check all odd results gone
noi assert inlist(Result, "MRSA", "MSSA", "No growth")
noi assert spatype!="" if Result!="No growth"
noi assert spatype=="" if Result=="No growth"
drop carriage

bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop first 


****************************************************************************
*  5 : problem of in accurate timepoint/ duplicate swabs
****************************************************************************
noi di _n(5) _dup(80) "=" _n "(6) SORT MULTIPLE BEST DATES" _n _dup(80) "=" 
* look at spread of results
by patid: gen days_since_first=BestDate-BestDate[1]
 
gen accuracy = abs(days/(30.44) -timepoint )

noi di "accuracy of timeperiod"
noi summ accuracy



duplicates tag patid BestDate, gen (multiple)
noi summ multiple if multiple!=0
noi di r(N) " duplicated swabs" 
noi list patid timepoint Sent DateTaken Received BestDate accuracy spatype if multiple!=0, sepby(patid)

* if identical in spatype, drop copies
sort patid BestDate spa accuracy
by patid BestDate spa: gen flag=1 if _n>1

* keep record of worst of no result/MSSA/MRSA
gen result_severity = 2 if Result == "MRSA"
replace result_severity = 1 if Result == "MSSA"
replace result_s = 0 if Result == "No growth"
assert result!=.
bysort patid BestDate spa: egen Result_max= max(result_severity) 

summ flag
noi di "drop " r(N) " swabs  -  multiple taken at same date, same spa, drop duplicates"
drop if flag ==1

* count how many left
bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop flag first multiple

* if non-identical in spatype, keep all spa-types
duplicates tag patid BestDate, gen (multiple)
noi summ multiple if multiple!=0
by patid BestDate: gen flag= (_n!=1)
summ flag if multiple!=0
noi di "combines " r(N) " swabs  -  multiple returned at same date, keep all spa-types"
noi list patid timepoint spatype BestDate if multiple!=0
drop flag


* create blended list of spa-types found
preserve
keep if multiple!=0
keep patid BestDate spatype Result result_s
bysort patid BestDate: egen mixed_Result_max = max(result_severity)
drop Result result_s
drop if spatype==""
by patid BestDate: gen count=_n
reshape wide spatype, i(patid BestDate mixed_Result_max) j(count)
split spatype1, parse(/) gen(spatype3)
split spatype2, parse(/) gen(spatype4)
drop spatype1 spatype2
rename spatype3* spatype*
rename spatype41 spatype4
rename spatype42 spatype5
reshape long
drop if spatype==""
drop count
duplicates drop
sort patid BestDate spatype
by patid BestDate: gen count=_n
assert count <=3
reshape wide
gen spatype= spatype1
replace spatype=spatype1+"/"+spatype2 if spatype2!=""
replace spatype=spatype1+"/"+spatype2+"/"+spatype3 if spatype3!=""
drop  spatype1 spatype2 spatype3
tempfile temp
save temp, replace
restore

rename spatype oldspa

merge m:1 patid BestDate using temp, update
assert inlist(_merge,1,3)
gen flag=1 if spatype!=oldspa & spatype!=""
bysort patid BestDate: egen maxflag= max(flag)
summ flag
noi di r(N) " changed spatypes by merging multiple spa results"
noi list patid timepoint BestDate spatype oldspa if maxflag==1
replace oldspa = spatype if flag==1
replace Result_max = mixed_Result if flag==1
drop flag mixed_Result 



* if identical in spatype, drop copies
sort patid BestDate spa accuracy
by patid BestDate spa: gen flag=1 if _n>1
by patid BestDate: egen mixed_Result_max = max(result_severity)
assert mixed_Result_max == result_severity
drop mixed_Result_max
summ flag
noi di "drop " r(N) " swabs  -  multiple identical combined spatype swabs, drop duplicates"
drop if flag ==1
bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 

drop flag maxflag spatype _merge multiple first
rename oldspa spatype

* recheck multiple
duplicates tag patid BestDate, gen (multiple)
noi assert multiple==0
drop multiple

**************************************
******  6 inaccuracy of "timepoint" timing: keep all spatypes found within 30.44 days of a timepoint, combine onto single result.
*****************************************
noi di _n(5) _dup(80) "=" _n "(7) SORT INACCURATE TIMINGS" _n _dup(80) "=" 
bysort patid: egen max_accuracy = max(accuracy)
gen flag = 1 if accuracy>1
summ accuracy if flag==1
noi di r(N) " swabs further than 30 days from desired swab time" 
gen ideal_days = 30.44*timepoint
gen closest_timepoint = round(days_since/30.44)
replace closest_timepoint = round(days_since/30.44,2)
noi list patid Sent DateTaken Received timepoint closest BestDate spa flag if max>1, sepby(patid)
drop flag

* create working timepoint 
rename timepoint org_timepoint
rename closest_timepoint timepoint

*calc accuracy to new timepoint
rename accuracy org_accuracy
rename max_accuracy org_max_accuracy
gen accuracy = abs(days/(30.44) -timepoint )
bysort patid: egen max_accuracy = max(accuracy)
gen flag =1 if timepoint!=org_timepoint
summ flag
noi di r(N) " renumbered timepoints to timepoint closest to when swab was taken"
noi summ accuracy max org_acc org_max
noi list patid Sent DateTaken Received org_time BestDate timepoint acc spa if flag==1
drop flag org_acc org_max

* reorder by new timepoint
noi di _n(5) _dup(80) "=" _n "(8) SORT MULTIPLE TIMEPOINTS" _n _dup(80) "=" 
duplicates tag patid timepoint, gen (multiple)
noi summ multiple if multiple!=0
noi di r(N) " duplicated swabs" 
noi list patid Sent DateTaken Received org_time BestDate timepoint acc spa if multiple!=0, sepby(patid)

* where spa type is the same, remove further from ideal time swab
sort patid timepoint spatype accuracy
by patid timepoint spa: gen flag=1 if _n>1
by patid timepoint spa: egen mixed_Result_max = max(result_severity)
assert mixed_Result_max == result_severity
drop mixed_Result_max
summ flag
noi di "drop " r(N) " swabs  -  multiple in same time period, same spa, drop furthest from ideal, keep max of {MRSA, MSSA, No Growth)"


drop if flag ==1
bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop flag first
drop multiple

* recheck multiple

duplicates tag patid timepoint, gen (multiple)
noi summ multiple if multiple!=0
noi di r(N) " duplicated swabs" 
noi list patid org_timepoint timepoint BestDate accuracy spatype Result if multiple!=0, sepby(patid)

******** ideally at this point, want to keep all the spa-types on the two swabs.
* create blended list of spa-types found
preserve
keep if multiple!=0
keep patid timepoint spatype Result result_s
bysort patid timepoint: egen mixed_Result_max = max(result_severity)
drop Result result_s
drop if spatype==""
bysort patid timepoint: gen count=_n
reshape wide spatype, i(patid timepoint mixed_Result_max) j(count)
split spatype1, parse(/) gen(spatype3)
split spatype2, parse(/) gen(spatype4)
drop spatype1 spatype2
rename spatype3* spatype*
rename spatype41 spatype5
rename spatype42 spatype6
rename spatype43 spatype7
reshape long
drop if spatype==""
drop count
duplicates drop
sort patid timepoint spatype
by patid timepoint: gen count=_n
reshape wide
gen spatype= spatype1
replace spatype=spatype1+"/"+spatype2 if spatype2!=""
replace spatype=spatype1+"/"+spatype2+"/"+spatype3 if spatype3!=""
replace spatype=spatype1+"/"+spatype2+"/"+spatype3+"/"+spatype4 if spatype4!=""
replace spatype=spatype1+"/"+spatype2+"/"+spatype3+"/"+spatype4+"/"+spatype5  if spatype5!=""
drop  spatype1 spatype2 spatype3 spatype4 spatype5
tempfile temp
save temp, replace
restore

rename spatype oldspa

merge m:1 patid timepoint using temp, update
assert inlist(_merge,1,3)
gen flag=1 if spatype!=oldspa & spatype!=""
bysort patid timepoint: egen maxflag= max(flag)
summ flag
noi di r(N) " changed spatypes by merging multiple spa results"
noi list patid timepoint spatype oldspa if maxflag==1
replace oldspa = spatype if flag==1
replace Result_max = mixed_Result if flag==1
assert Result_max==mixed_Result if maxflag==1
drop mixed_Result 
drop flag maxflag spatype _merge multiple
rename oldspa spatype

* recheck for similar multiples 
duplicates tag patid timepoint, gen (multiple)
noi summ multiple if multiple!=0
noi di r(N) " duplicated swabs" 
noi list patid org_timepoint timepoint BestDate accuracy spatype Result Result_max if multiple!=0, sepby(patid)

* where combined spa type is the same, remove further from ideal time swab
sort patid timepoint spatype accuracy
by patid timepoint spa: gen flag=1 if _n>1
by patid timepoint spa: egen mixed_Result_max = max(result_severity)
assert mixed_Result_max == Result_max
drop mixed_Result_max
summ flag
noi di "drop " r(N) " swabs  -  multiple in same time period, same combined spa types, drop furthest from ideal"
drop if flag ==1
bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop flag first
drop multiple

* recheck there are no duplicate timepoints
duplicates tag patid timepoint, gen (multiple)
noi assert multiple==0
drop multiple

* replace Result to take account of merged spatypes
replace Result="MRSA" if Result_max==2
replace Result="MSSA" if Result_max==1
tab Result, m

* add count of number of spatypes
gen nspatypes= length(spatype) - length(subinstr(spatype, "/", "", .)) + 1
replace nspatypes=0 if spatype==""

* check everyone returned at least one swab
noi di _n(5) _dup(80) "=" _n "(9) At least 2 Swabs & timepoint 0" _n _dup(80) "=" 
noi di "check everyone returned at least 2 swabs post baseline ( 3 total)"
by patid: gen count=_N
gen flag =1 if count<3
noi list patid timepoint if flag==1
* note patid==2116 has only two swabs originallly - 0 and 1 < 30 days apart.
summ flag
noi di "drop " r(N) " swabs  - after cleaning only single record"
drop if flag==1
bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop flag first
noi assert count!=1


* check everyone has timepoint 0
sort patid timepoint
by patid: gen PROBLEM =1 if _n==1 & timepoint!=0
noi di "check everyone has timepoint 0"
noi assert PROBLEM!=1 
drop PROBLEM


* people missing GP data
noi di _n(5) _dup(80) "=" _n "(10) people missing GP data" _n _dup(80) "=" 

merge m:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\GP_org", update
 drop if _merge==2
 assert inlist(_merge,1,3)
 noi di "missing GP data; remove from study"
 noi tab patid if _merge==1
 gen GPmissing = 1 if _merge==1
 bysort patid: gen count2 =1 if _n==1
 replace count2= 0 if count2==.
 summ count2 if GPmissing==1
 noi di r(N) " records dropped from " r(sum) "people due to lack of GP records"
drop if GPmissing==1
drop GPmissing count 
drop _merge
 
*******************************************************************
*save final data sets
*****************************************************************

noi di "NO TIMEPOINT CUTOFF"
* based on when swabs stop being spa-type
*drop if timepoint >80

bysort patid: gen first=(_n==1)
summ first
noi di  " - leaving " _N " records from " r(sum) " paticipants" 
drop first

save "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", replace	

keep patid timepoint BestDate

save "E:\users\amy.mason\staph_carriage\Datasets\minimal.dta", replace

keep patid
duplicates drop

save "E:\users\amy.mason\staph_carriage\Datasets\patid.dta", replace


*
cd "E:\users\amy.mason\staph_carriage\Programs"
