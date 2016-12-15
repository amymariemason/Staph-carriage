*********************************************************************************
*Equilibrium Mixing LossMarkers
*********************************************************************************

******************************************************************
/* equilibrium graph 2 */
*******************************************************************
/* need a loss of persistance markers.*/

use "E:\users\amy.mason\Staph\recordperspa.dta", clear
compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1

sort patid2 timepoint
gen int PersistMarker=0
gen int LossMarker=0
by patid2: replace LossMarker=1 if LossMarker[_n+1]==0 &LossMarker[_n]==0
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0&LossMarker[_n-2]==0&LossMarker[_n-3]==0
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0&LossMarker[_n-2]==0 &_n<4
by patid2: replace PersistMarker=1 if LossMarker[_n]==0&LossMarker[_n-1]==0 & _n<3
by patid2: replace PersistMarker=1 if LossMarker[_n]==0 & _n<2

sort patid timepoint patid2
by patid timepoint: egen int Persist= max(PersistMarker)
by patid timepoint: egen int StateMarker= max(State)
keep patid timepoint Persist StateMarker
duplicates drop patid timepoint, force 


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\PersistBurpOnly"
drop if inlist(patid,1101,1102,801,1401)==1
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\InitialBurpOnly"
drop if inlist(patid,1101,1102,801,1401)==1
assert _merge==3
drop _merge
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\NewBurpOnly"
rename BurpMax2time2 BurpInitMax
drop if inlist(patid,1101,1102,801,1401)==1
assert _merge==3
drop _merge

gen MultMarker=0
bysort patid: replace MultMarker=1 if (BurpPrev2[_n]>2 |BurpPrev2[_n-1]>2 |BurpPrev2[_n-2]>2 |BurpPrev2[_n-3]>2) &_n>3
bysort patid: replace MultMarker=1 if (BurpPrev2[_n]>2 |BurpPrev2[_n-1]>2 |BurpPrev2[_n-2]>2) &_n>2

gen NeverGainStart=0
bysort patid: replace NeverGain=1 if (BurpPrev2[_n]>2 |BurpPrev2[_n-1]>2 |BurpPrev2[_n-2]>2 |BurpPrev2[_n-3]>2) &_n>3
bysort patid: replace MultMarker=1 if (BurpPrev2[_n]>2 |BurpPrev2[_n-1]>2 |BurpPrev2[_n-2]>2) &_n>2


gen Group=0
label variable Group "grouping for equilibrium graph"
label define Groupl 0 "never gain" 1 "one spa non-persistant"  2 "multi non-persistant" 3 "never lost &random"  4 "never lost & never random"
label values Group Groupl

by patid: replace Group=1 if Persist==0& MultMarker==0 
