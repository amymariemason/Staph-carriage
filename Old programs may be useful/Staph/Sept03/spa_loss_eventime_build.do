use "E:\users\amy.mason\Staph\recordperspa.dta", clear


******

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
by patid2: replace spa_no_last=n_spatypeid if _n==1

******************
*dropping those with <3 swabs, as impossible to record loss on them
***********************


gsort patid2 timepoint
by patid2: drop if _N<3

/*mark patient-spas who gained then confirmed loss (2 neg tests) */
gen byte lossevent=0 if value!=""
by patid2: replace lossevent=1 if value[_n-1]!=""& value[_n]=="" &value[_n+1]=="" & _n>1 
*by patid2: drop if _n==_N & value[_n]==""


* fix because we are going to be amagamating t=1 and t=2
gen time2=timepoint
gen problem=(timepoint==1)

****** some people have not t=2 data. in which case just replace the t=1 data as t=2 data. 
 by patid2: replace time2=2 if timepoint==1& timepoint[_n+1]>2
  by patid2: replace problem=0 if timepoint==1& timepoint[_n+1]>2
 order patid2 time2 timepoint
 
* yup this works 

gen byte gainevent=0
by patid2: replace gainevent=1 if  value[_n]!=""& value[_n-1]=="" &value[_n-2]=="" & _n>2

gen knownaquis=0 
replace knownaquis=1 if gainevent==1
by patid2: replace knownaquis=1 if knownaquis[_n-1]==1

label define base2 0 recruit_pos 1 recruit_neg
label define knownaquis 0 no 1 yes
label values base2 base2
label values knownaquis knownaquis

*fix gainevent
* 37 people who gain at t==1, pull back to gain event at t=0 (i.e. initial negative swab in error. however keep other parts of t=0 record)
by patid2: gen gainprob = 1 if timepoint==1& spaState==1&spaState[_n-1]==0
by patid2: gen gainzero=1 if timepoint==0 & gainprob[_n+1]==1
gen spaState2=spaState
gen value2=value
gen uniquetype2=uniquetype
by patid2: replace spaState2=spaState2[2] if gainzero==1
by patid2: replace value2=value2[2] if gainzero==1
by patid2: replace uniquetype2=uniquetype2[2] if gainzero==1


*fix loss event, if loss at t=1 pull forward to t=2.
* (if patient does 0=pos, 1=neg, 2=neg, current assigning loss to t=1, set to t=2 instead, but accept as genuine neg)

by patid2: replace lossevent=1 if timepoint[_n-1]==1 & lossevent[_n-1]==1 & problem[_n-1]==1


*fix antibiotic records
* only going to fix anti6mon antiprev, as they are most accurate (based on patient data only)

**** anti6mon =  time based, does not need changing
**** antiprev = needs correction if antibiotics between t=0 and t=1
gen antiprev2= antiprev
by patid2: replace antiprev2=1 if timepoint[_n-1]==1 & antiprev[_n-1]==1 & problem[_n-1]==1


* fix number of spatypes

*only one I think I need to fix if have moved lossevent to t=2, need to change no spatypes on previous swob to that of  t=0 (otherwise having loss events with no spatypes on previous swob!)
gen spa_no_last2= spa_no_last
sort patid2 timepoint
by patid2: replace spa_no_last2=n_spatypeid[1] if timepoint[_n-1]==1 & lossevent[_n-1]==1

drop if timepoint==1 & time2!=2

/*some patients gain and lose multiple times for the same spa type. Create multiple records?*/
order patid patid2 timepoint lossevent value
sort patid2 timepoint
*drop if patid!=1248
gen int runningtotal=1
drop if lossevent==.
* not this drops people before gain, single negs and after loss (i.e. all negatives that are not loss events. this is equivalent to assuming those negative were false and the previous swab dominates)
by patid2: replace runningtotal=runningtotal[_n-1]+lossevent[_n-1]  if _n>1


/* add t0 = first postive test */
gsort patid2 runningtotal timepoint 
by patid2 runningtotal: gen int t0start=timepoint[1]
assert knownaquis==0 if inlist(t0start,0,1)
*drop if t0start==0 
gen patid3=patid2*10+runningtotal 

stset timepoint, fail(lossevent) id(patid3) origin(t0start)
drop if _st==0
stset time2, fail(lossevent) id(patid3) origin(t0start)
gen odd = mod(_t,2)
*gen time2 =timepoint
assert odd!=1

stset time2, fail(lossevent) id(patid3) origin(t0start)



save "E:\users\amy.mason\Staph\Sept03\eventimebuild.dta", replace
