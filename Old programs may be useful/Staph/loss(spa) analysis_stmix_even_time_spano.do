
*looking at significance of number of current spatypes
*********************************************************************************
*Playing with spa loss survival times and stmix
*********************************************************************************
/* make survival data for time to loss of single spa-type */


/*steal 1 record per patid-spa from R */
use "E:\users\amy.mason\Staph\recordperspa.dta", clear

compress
destring State, replace
rename patid patid2
rename id patid
destring patid, replace
drop baseline_followupneg
drop if inlist(patid,1101,1102,801,1401)==1
rename State spaState
merge m:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithNewBurp2_v2.dta", update
/* merge problems are those who had double record problems in data creation: see Make Staph Data */
drop if _merge==1
assert _merge==3

rename baseline_age age
rename baseline_male male
gen anti6mon=  patient_prev_anti_6mon
gen antiprev= patient_prev_anti_swob
sort patid2 timepoint
replace n_spatypeid=0 if n_spatypeid==.
by patid2: gen spa_no_last= n_spatypeid[_n-1]


gsort patid2 timepoint

/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte lossevent=0 if value!=""
by patid2: replace lossevent=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]==""
by patid2: drop if _n==_N & value[_n]==""

gen byte gainevent=0
by patid2: replace gainevent=1 if  value[_n]!=""& value[_n-1]=="" &value[_n-2]=="" & _n>2

gen knownaquis=0 
replace knownaquis=1 if gainevent==1
by patid2: replace knownaquis=1 if knownaquis[_n-1]==1

label define base2 0 recruit_pos 1 recruit_neg
label define knownaquis 0 no 1 yes
label values base2 base2
label values knownaquis knownaquis

/*some patients gain and lose multiple times for the same spa type. Create multiple records?*/
order patid patid2 timepoint lossevent value
sort patid2 timepoint
*drop if patid!=1248
gen int runningtotal=1
drop if lossevent==.
by patid2: replace runningtotal=runningtotal[_n-1]+lossevent[_n-1]  if _n>1


/* add t0 = first postive test */
gsort patid2 runningtotal timepoint 
by patid2 runningtotal: gen int t0start=timepoint[1]
assert knownaquis==0 if inlist(t0start,0,1)
*drop if t0start==0 
gen patid3=patid2*10+runningtotal 
gsort patid3 -lossevent timepoint

*split by number of spa types in last swab
sort patid3 timepoint
gen spabinary = ( spa_no_last >1)& spa_no_last!=.
by patid3: gen changes=(spabinary!=spabinary[_n-1]) & spa_no_last[_n-1]!=.
gen running=1
by patid3: replace running=running[_n-1]+changes[_n-1] if _n>1
gen patid4 = patid3*10+running

sort patid4 timepoint
by patid4: gen newstart=timepoint[1]
*by patid4: replace newstart=timepoint[1]-2 if timepoint[1]>1 &changes==1

gsort patid4 -lossevent timepoint

by patid4: drop if _n>1 & lossevent[1]==1
by patid4: drop if _n<_N & lossevent[1]==0
by patid4: assert _N==1

by patid3: gen newstart2=0
by patid3: replace newstart2=timepoint[_n-1] if _n>1

*stset timepoint, fail(event2) id(patid2) origin(t0start) exit(time.)
stset timepoint, fail(lossevent) id(patid3) origin(newstart2)
drop if _st==0
stset timepoint, fail(lossevent) id(patid3) origin(newstart2)
gen odd = mod(_t,2)
gen time2 =timepoint

replace time2=time2+1 if odd==1

stset time2, fail(lossevent) id(patid3) origin(newstart2)



*stcox base2 knownaquis Followed 
/* so knownaquis gets significant when add extra length of data*/
gen x= base2*knownaquis

save "E:\users\amy.mason\Staph\stset_data(spa)_even_spano.dta", replace


* can get stmix, pmix(knownaquis) to converge, but graph unconvincing (suggests no mix if knownaqs, faster is unknown)
