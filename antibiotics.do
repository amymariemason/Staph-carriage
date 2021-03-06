************************************************
*ANTIBIOTICS.DO
************************************************
* cleans up the antibiotic data keeping only reports relevant to staph, and removing overlaps in reports
* INPUTS:   raw_antbiotics, (from inputs.do), patid (from clean_maindata.do),raw_druglist (from inputs.do)
*OUTPUTS : antistaph_antibiotics_nooverlap
* written by Amy Mason


set li 130

cap log close
log using antibiotics.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

***********************************************************************************
* load in data
***************************************************************************
use  "E:\users\amy.mason\staph_carriage\Datasets\raw_antibiotics", clear
noi merge m:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\patid.dta", update
* no interest in patients outside of patid list
noi drop if _merge==1
*no interest in patients with no antibiotic record
noi drop if _merge==2
noi assert inlist(_merge, 3)
drop _merge

replace Antimicrobial="Unknown" if Antimicrobial=="? - could not get in contact with patient to ask"
replace Antimicrobial = lower(Antimicrobial )

******************************************************************
/*work out if antibiotics taken are relevant to staph by merging with Nicki's list*/
******************************************************************************* 
merge m:1 Antimicrobial using "E:\users\amy.mason\staph_carriage\Datasets\raw_druglist", update
drop if _merge==2
assert _merge==3
drop _merge

/* consider only things active against staph */
keep if antistaph==1

noi display _N " reports of taking antibiotics active against staph"

* create report of current number of records
preserve
gen count =1 
collapse (sum) count, by(patid)
noi dis _N " participants reported taking antibiotics at some point in study"
restore
preserve
gen count =1 
collapse (sum) count, by(TrueName)
noi dis _N " distinct antibiotics reported"

***************************************
* sort missing dates in antibiotic reports, by supplementing with reports on when the swab was taken
***************************************************

restore
summ patid if DateStarted==.
noi di r(N) " antibiotic reports are missing the date started"

summ patid if DateEnded==.
noi di r(N) " antibiotic reports are missing the date ended"

summ patid if DateEnded==. & DateStarted==.
noi di r(N) " antibiotic reports are missing the date started and  ended"

* create variable to pull out people who say they are still taking the drug
gen stilltaking= 1 if strpos(lower(Amount), "still taking")

summ patid if still==1 & DateEnded==. & DateTaken!=.
noi di r(N) " people whose extra info says still taking drug and are missing endpoint (replace with DateTaken)"
noi list patid timepoint Date* Amount if still==1 & DateEnded==. & DateTaken!=.
replace DateEnded= DateTaken if still==1 & DateEnded==.

summ patid if still==1 & DateEnded==. & Received!=.
noi di r(N) " people whose extra info says still taking drug and are missing endpoint (Date Taken also missing, replace with Date Received)"
noi list patid timepoint Date* Amount if still==1 & DateEnded==.
replace DateEnded= Received if still==1 & DateEnded==.

noi assert DateEnded!=. if still==1
drop still

*************************
* people whose data still has missing dates
************************************

sort patid timepoint
summ patid if DateEnded==. | DateStart==.
noi di r(N) " antibiotic reports are still missing one or more dates"
duplicates tag patid timepoint Anti, gen(multiple)
noi display "Missing end dates"
noi list Swab patid timepoint Date*  multiple Antimicrobial True Amount  if DateEnded==.

****************************************************
* use the free text box to update dates, but be careful to check for duplicates
gen altDateEnd =.
replace altDateEnd = DateStarted +4 if SwabID==2769 
replace altDateEnd = DateStarted if SwabID==379 
replace altDateEnd = DateTaken-8 if SwabID==2223 
replace altDateEnd  = DateStarted +7 if SwabID==3115 
summ patid if DateEnded==. & altDateEnd!=.
noi di r(N) " antibiotic reports enddates updated based on text box"
noi replace DateEnded=altDateEnd if DateEnded==.
summ patid if DateEnded==. & DateTaken!=.
noi di r(N) " antibiotic reports enddates replaced with Date Taken"
noi replace DateEnded=DateTaken if DateEnded==.
summ patid if DateEnded==. & Received!=.

* if no enddate given, replace with date the swab was received
noi di r(N) " antibiotic reports enddates replaced with Received"
noi replace DateEnded=Received if DateEnded==.

assert DateEnded!=.

*****************************
**** start date still missing


noi display "Missing start date"
noi list Swab patid timepoint Date*  multiple Antimicrobial True Amount  if DateS==.
noi tab patid if DateStarted==.
gen altDateStart=.
gen missing =(DateStarted==.)
sort patid timepoint
by patid: egen misstot= total(missing) 
sort True patid timepoint
noi list patid timepoint DateTaken DateStarted DateEnded True Amount if misstot>0,sepby(patid True)

* infer missing start date from free text box
replace altDateStart=d(1/4/2012) if patid==482 &True=="Doxycycline" & DateS==.
replace altDateStart=d(1/10/2009) if patid==2088 & True=="Erythromycin" & DateS==.
replace altDateS=d(24/10/2009) if patid== 1240 & True== "Lymecycline" & DateS==.
replace altDateS=d(1/08/2007) if patid==366 & True=="Ciprofloxacin" 
summ patid if DateS==. & altDateS!=.
noi di r(N) " antibiotic reports startdates updated based on text box"
noi replace DateS=altDateS if DateS==.


* in the absense of any other data, set start date to the end date
summ patid if DateS==. & DateE!=.
noi di r(N) " antibiotic reports startdates replaced with DateEnded"
noi replace DateS=DateE if DateS==.

assert DateS!=.

drop missing misstot alt*

********************************************************
* Date order problems
***************************************************
* ie date the drug was finished is before the start date

summ patid if DateE< DateS
noi di r(N) " reports have date ended before date start"
noi list if DateE < DateS

* replace based on belief that these were typos
noi replace DateS=d(24/6/2013) if patid==1226 & True==  "Cefalexin"  & timepoint==46
noi replace DateE=d(4/7/2013) if patid==1314 & True == "Ciprofloxacin"  & timepoint==44
noi replace DateE= d(2/3/2015) if patid==1244 & True== "Clarithromycin" & timepoint==64
noi replace DateS = DateE if patid== 1307 & timepoint==1& True == "Naseptin topical"

noi assert DateS<=DateE<=DateTaken
******************************************************
* keep only relevant data
keep patid True DateS DateE



*****************************************************
* overlapping reports
*****************************************************

noi di "overlapping reports"
sort patid True DateStarted DateEnded
by patid True: gen overlap = (DateStarted< DateEnded[_n-1] & _n>1)
by patid True: egen overmax = total(overlap)
summ patid if overlap==1
noi di r(N) " reports overlap with previous report"
list patid True DateS DateE overlap if overmax>0, sepby(patid True)
by patid True: replace DateSt=DateS[_n-1] if _n!=1 & overlap==1
gsort patid True DateS -DateE
by patid True DateS: replace DateE=DateE[1]
drop over*
bysort patid True DateS DateE: gen dup = 1 if _n>1
summ patid if dup==1
noi di r(N) " reports redundant due to multiple overlapping reports"
drop if dup ==1
drop dup


* repeat to check for further overlaps,

sort patid True DateStarted DateEnded
by patid True: gen overlap = (DateStarted< DateEnded[_n-1] & _n>1)
by patid True: egen overmax = total(overlap)
summ patid if overlap==1
noi di r(N) " reports overlap with previous report"
list patid True DateS DateE overlap if overmax>0, sepby(patid True)
by patid True: replace DateSt=DateS[_n-1] if _n!=1 & overlap==1
gsort patid True DateS -DateE
by patid True DateS: replace DateE=DateE[1]
drop over*
bysort patid True DateS DateE: gen dup = 1 if _n>1
summ patid if dup==1
noi di r(N) " reports redundant due to multiple overlapping reports"
drop if dup ==1
drop dup

* once more repeat

sort patid True DateStarted DateEnded
by patid True: gen overlap = (DateStarted< DateEnded[_n-1] & _n>1)
by patid True: egen overmax = total(overlap)
summ patid if overlap==1
noi di r(N) " reports overlap with previous report"
list patid True DateS DateE overlap if overmax>0, sepby(patid True)
by patid True: replace DateSt=DateS[_n-1] if _n!=1 & overlap==1
gsort patid True DateS -DateE
by patid True DateS: replace DateE=DateE[1]
drop over*
bysort patid True DateS DateE: gen dup = 1 if _n>1
summ patid if dup==1
noi di r(N) " reports redundant due to multiple overlapping reports"
drop if dup ==1
drop dup

* assert all overlaps have now gone

sort patid True DateStarted DateEnded
by patid True: gen overlap = (DateStarted< DateEnded[_n-1] & _n>1)
assert overlap==0
drop overlap

* summerise and save the data

summ patid
noi di r(N) " unique reports of antibiotics remain"
save  "E:\users\amy.mason\staph_carriage\Datasets\antistaph_antibiotics_nooverlap", replace

exit
*******************************************************************************
We are only using antibiotic data that the patient reported here - I ran a simple regression prediction of loss of carriage based on GP reports
of staph sensitive antibiotics, patient reports and combined reports (at end of two years). The patient reports were the most predictive. 
Given that getting more GP reports also came at increased cost it was decided that we would only use patient reports of antibiotics for the study.